-- Carries a question from a gtd /pr-review page (review.html, opened over file://) to the Claude
-- Code session that generated it. A page cannot open the session's inbox socket, so nvim listens on
-- a localhost port and forwards each POST into that session's cross-session messaging socket.
--
-- Any web page the browser has open can POST to localhost, and a forwarded message starts a turn in
-- a Claude that can run tools. So every request carries a token that only local files can read:
-- ~/.config/gtd/review-bridge.js, which review.html loads with <script src="file://...">. The token
-- is not baked into review.html because task files are tracked by jj and pushed with the gtd repo.
--
-- Whichever nvim holds the port serves every page: the target session is looked up from
-- ~/.claude/sessions/*.json on each request, not from this nvim's own terminals. A second nvim that
-- finds the port taken retries on a timer, so the bridge survives the first one quitting.
local M = {}

local uv = vim.uv
local PORT = 47823
local RETRY_MS = 30000
local MAX_REQUEST = 2 * 1024 * 1024

local home = uv.os_homedir()
local token_path = home .. "/.config/gtd/review-bridge.js"
local sessions_dir = home .. "/.claude/sessions"

local function read_file(path)
  local fd = uv.fs_open(path, "r", 384)
  if not fd then return nil end
  local stat = uv.fs_fstat(fd)
  local data = stat and uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data
end

-- The token is kept across nvim restarts: a review.html opened before a restart still has the old
-- value loaded and would otherwise fail until it is reloaded.
local function load_token()
  local data = read_file(token_path)
  local token = data and data:match('"token":"(%x+)"')
  if token then return token end
  token = (uv.random(16):gsub(".", function(c) return string.format("%02x", c:byte()) end))
  uv.fs_mkdir(home .. "/.config/gtd", 448)
  local fd = assert(uv.fs_open(token_path, "w", 384))
  uv.fs_write(fd, string.format('window.GTD_REVIEW_BRIDGE = {"port":%d,"token":"%s"};\n', PORT, token))
  uv.fs_close(fd)
  return token
end

local function alive(pid)
  return type(pid) == "number" and uv.kill(pid, 0) == 0
end

-- cwd alone can't pick the session: two sessions started in the same task dir share it. It is the
-- fallback for a page whose generating session is gone, and then the most recently active one wins.
local function find_session(want_id, want_cwd)
  local by_id, by_cwd
  local iter = uv.fs_scandir(sessions_dir)
  while iter do
    local name, kind = uv.fs_scandir_next(iter)
    if not name then break end
    if kind == "file" and name:match("^%d+%.json$") then
      local ok, d = pcall(vim.json.decode, read_file(sessions_dir .. "/" .. name) or "")
      if ok and type(d) == "table" and d.messagingSocketPath and alive(d.pid) then
        local newer = function(cur) return not cur or (d.updatedAt or 0) > (cur.updatedAt or 0) end
        if want_id and d.sessionId == want_id and newer(by_id) then by_id = d end
        if want_cwd and d.cwd == want_cwd and newer(by_cwd) then by_cwd = d end
      end
    end
  end
  return by_id or by_cwd
end

local function deliver(sock_path, text, done)
  local pipe = uv.new_pipe(false)
  local line = vim.json.encode { type = "user", message = { role = "user", content = text } } .. "\n"
  pipe:connect(sock_path, function(err)
    if err then
      pipe:close()
      return done(err)
    end
    pipe:write(line, function(werr)
      pipe:shutdown(function() pipe:close() end)
      done(werr)
    end)
  end)
end

-- A file:// page sends `Origin: null`, so that is the origin allowed to read the reply. The JSON
-- body makes the browser preflight; the last header is for a browser that also gates requests to
-- localhost behind a private network access preflight.
local CORS = table.concat({
  "Access-Control-Allow-Origin: null",
  "Access-Control-Allow-Methods: POST",
  "Access-Control-Allow-Headers: content-type",
  "Access-Control-Allow-Private-Network: true",
}, "\r\n")

local function respond(client, status, body)
  local reason = ({ [200] = "OK", [204] = "No Content", [400] = "Bad Request", [403] = "Forbidden",
    [404] = "Not Found", [413] = "Payload Too Large", [502] = "Bad Gateway" })[status] or "Error"
  body = body and vim.json.encode(body) or ""
  client:write(string.format(
    "HTTP/1.1 %d %s\r\n%s\r\nContent-Type: application/json\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s",
    status, reason, CORS, #body, body), function() client:close() end)
end

local function handle(client, token, method, body)
  if method == "OPTIONS" then return respond(client, 204) end
  if method ~= "POST" then return respond(client, 400, { error = "POST only" }) end
  local ok, req = pcall(vim.json.decode, body)
  if not ok or type(req) ~= "table" or type(req.text) ~= "string" then
    return respond(client, 400, { error = "body must be JSON with text" })
  end
  if req.token ~= token then return respond(client, 403, { error = "bad token" }) end
  local s = find_session(req.session_id, req.cwd)
  if not s then return respond(client, 404, { error = "no live Claude Code session for this page" }) end
  deliver(s.messagingSocketPath, req.text, function(err)
    if err then return respond(client, 502, { error = tostring(err) }) end
    respond(client, 200, { ok = true, session = s.name })
  end)
end

local function on_client(client, token)
  local buf = ""
  client:read_start(function(err, chunk)
    if err or not chunk then
      client:close()
      return
    end
    buf = buf .. chunk
    if #buf > MAX_REQUEST then
      client:read_stop()
      return respond(client, 413, { error = "too large" })
    end
    local head_end = buf:find("\r\n\r\n", 1, true)
    if not head_end then return end
    local head = buf:sub(1, head_end - 1)
    local length = tonumber(head:lower():match("\r\ncontent%-length:%s*(%d+)")) or 0
    local body = buf:sub(head_end + 4)
    if #body < length then return end
    client:read_stop()
    handle(client, token, head:match("^(%u+) "), body:sub(1, length))
  end)
end

function M.start()
  local token = load_token()
  local timer = uv.new_timer()
  local function try_listen()
    local server = uv.new_tcp()
    local ok = server:bind("127.0.0.1", PORT)
    if ok then
      ok = server:listen(16, function(err)
        if err then return end
        local client = uv.new_tcp()
        server:accept(client)
        on_client(client, token)
      end)
    end
    if ok then
      timer:stop()
      timer:close()
    else
      server:close()
    end
  end
  timer:start(0, RETRY_MS, try_listen)
end

return M
