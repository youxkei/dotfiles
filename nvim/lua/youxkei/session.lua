-- Per-possession-session terminals + the possession buffer-protection that keeps them alive.
--
-- toggleterm / Claude / Codex floats are normally destroyed whenever we switch possession
-- sessions (the before_save hook + possession's delete_buffers both wipe terminal buffers).
-- Here we instead keep one set of terminals *per session* (keyed by the possession session
-- name) and protect their buffers from those wipes, so switching sessions hides the current
-- session's terminals and re-shows the target session's still-running ones.
--
-- Marker: every managed terminal buffer carries `vim.b[buf].keep_term = true`. Only file
-- buffers (and other unlisted/terminal buffers) are still cleared per session as before; the
-- keep_term terminals are the sole exception.
local M = {}

-- The key under which the current session's terminals live: the active possession session
-- name, or cwd when no session is current (fresh nvim, or briefly mid-switch between
-- PossessionClose and the next load). Resolved at keypress time, when a session is active.
function M.term_key()
  local ok, name = pcall(function()
    return require("possession.session").get_session_name()
  end)
  if ok and name and name ~= "" then return name end
  return vim.fn.getcwd()
end

--------------------------------------------------------------------------------
-- Possession buffer-protection
--------------------------------------------------------------------------------

-- before_save hook: drop the arglist and strip terminal/unlisted buffers from the soon-to-be
-- saved session, EXCEPT our keep_term terminals — those we only hide (close their windows) so
-- they survive the save but, being hidden + unlisted, are not written into the mksession.
function M.before_save(_name)
  vim.cmd("%argd")
  -- First delete the non-kept terminal/unlisted buffers (as before).
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if not vim.b[buf].keep_term and (vim.bo[buf].buftype == "terminal" or vim.fn.buflisted(buf) == 0) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
  -- Then hide any window still showing a kept terminal (keep the buffer + job alive) so the
  -- saved mksession doesn't serialize it. Guard against closing the last window.
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].keep_term then
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if #vim.api.nvim_list_wins() > 1 then
          pcall(vim.api.nvim_win_close, win, true)
        end
      end
    end
  end
  return {}
end

-- Teach possession's buffer-wiping plugins to leave keep_term terminals alone, so our
-- per-session terminals survive session save/load while file buffers stay per-session exactly
-- as before. Two plugins wipe buffers:
--   * delete_buffers      (before_load)  -> possession.utils.delete_all_buffers
--   * delete_hidden_buffers(before_save+before_load, on by default) -> deletes every hidden
--     buffer; without this guard it hits our (hidden) terminals and, since a terminal can't be
--     deleted without force, errors ("Cannot delete buffer with unsaved changes") and aborts.
function M.install_possession_guards()
  local utils = require("possession.utils")

  -- delete_buffers: skip keep_term (also covers gtd.enter_task's fresh-worktree call).
  if not utils.__keep_term_guarded then
    utils.__keep_term_guarded = true
    utils.delete_all_buffers = function(force)
      -- Delete the current buffer last (mirrors the original) to avoid a BufEnter cascade.
      local current = vim.api.nvim_get_current_buf()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and buf ~= current and not vim.b[buf].keep_term then
          pcall(vim.api.nvim_buf_delete, buf, { force = force })
        end
      end
      if vim.api.nvim_buf_is_valid(current) and not vim.b[current].keep_term then
        pcall(vim.api.nvim_buf_delete, current, { force = force })
      end
    end
  end

  -- delete_hidden_buffers: re-implement to skip keep_term, otherwise keep its behavior (incl.
  -- aborting the save/load if a genuine unsaved FILE buffer can't be deleted).
  local ok, dhb = pcall(require, "possession.plugins.delete_hidden_buffers")
  if ok and not dhb.__keep_term_guarded then
    dhb.__keep_term_guarded = true
    local function delete_hidden(opts)
      local visible = {}
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        visible[vim.api.nvim_win_get_buf(win)] = true
      end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if not visible[buf] and not vim.b[buf].keep_term then
          local force = opts.force
          if type(force) == "function" then force = force(buf) end
          if not pcall(vim.api.nvim_buf_delete, buf, { force = force }) then
            utils.error('Cannot delete buffer with unsaved changes: "%s"', vim.api.nvim_buf_get_name(buf))
            return false
          end
        end
      end
      return true
    end
    for hook, fn in pairs(require("possession.plugins").implement_basic_hooks(delete_hidden)) do
      dhb[hook] = fn
    end
  end
end

--------------------------------------------------------------------------------
-- toggleterm: one floating terminal id per session
--------------------------------------------------------------------------------

local toggleterm_ids = {}
local toggleterm_next_id = 0

local function toggleterm_id(key)
  if not toggleterm_ids[key] then
    toggleterm_next_id = toggleterm_next_id + 1
    toggleterm_ids[key] = toggleterm_next_id
  end
  return toggleterm_ids[key]
end

-- Toggle the current session's toggleterm (creating it in the current cwd if absent). Used by
-- the global <c-t> and by the in-float <c-t> of Claude/Codex.
function M.toggle_term()
  require("toggleterm").toggle(toggleterm_id(M.term_key()), nil, vim.fn.getcwd())
end

--------------------------------------------------------------------------------
-- Claude / Codex: per-session snacks terminal provider (custom table provider)
--------------------------------------------------------------------------------

-- Resolve snacks lazily: this module is required from spec.lua's top during load.lua's parse
-- step, which runs BEFORE vim.pack.add/packadd, so snacks isn't on the rtp at module-load time.
local function get_snacks()
  local ok, Snacks = pcall(require, "snacks")
  if ok then return Snacks end
  return nil
end

local function normalize_focus(focus)
  if focus == nil then return true end
  return focus
end

-- Mirrors claudecode/terminal/snacks.lua build_opts: position/size + a <S-CR> newline key,
-- merged with the user's snacks_win_opts (which add the <c-l>/<c-t>/<c-g> float keys).
local function build_opts(config, env_table, focus)
  focus = normalize_focus(focus)
  return {
    env = env_table,
    cwd = config.cwd,
    start_insert = focus,
    auto_insert = focus,
    auto_close = false,
    win = vim.tbl_deep_extend("force", {
      position = config.split_side,
      width = config.split_width_percentage,
      height = 0,
      relative = "editor",
      keys = {
        claude_new_line = {
          "<S-CR>",
          function()
            vim.api.nvim_feedkeys("\\", "t", true)
            vim.defer_fn(function()
              vim.api.nvim_feedkeys("\r", "t", true)
            end, 10)
          end,
          mode = "t",
          desc = "New line",
        },
      },
    }, config.snacks_win_opts or {}),
  }
end

-- Build a per-session terminal provider for an MCP-style agent plugin (claudecode / codex).
-- opts.server_module is that plugin's "<plugin>.server.init" module, used to target a sent
-- @mention at only the current session's agent instead of broadcasting to every live one.
function M.make_provider(opts)
  opts = opts or {}
  local server_module = opts.server_module

  local terminals = {}      -- session key -> snacks terminal instance
  local session_client = {} -- session key -> WS client.id of that session's agent
  local pending_key = nil   -- session whose agent is about to connect (set just before spawn)

  -- Install (once) a hook on the running tcp server's on_connect/on_disconnect so we can learn
  -- which client.id belongs to which session. The server is already up by the time a terminal
  -- spawns (the agent needs the port from env), so we install lazily from open().
  local function install_connect_hook()
    if not server_module then return end
    local ok, server = pcall(require, server_module)
    if not ok then return end
    local tcp = server.state and server.state.server
    if not tcp or tcp.__session_hooked then return end
    tcp.__session_hooked = true

    local orig_connect = tcp.on_connect
    tcp.on_connect = function(client)
      if pending_key ~= nil then
        session_client[pending_key] = client.id
        pending_key = nil
      end
      if orig_connect then return orig_connect(client) end
    end

    local orig_disconnect = tcp.on_disconnect
    tcp.on_disconnect = function(client, code, reason)
      for key, cid in pairs(session_client) do
        if cid == client.id then session_client[key] = nil end
      end
      if orig_disconnect then return orig_disconnect(client, code, reason) end
    end
  end

  -- Install (once) a wrap on the module-level broadcast so an at_mentioned goes only to the
  -- current session's agent when we know its (still-connected) client; else fall back to the
  -- original broadcast (i.e. today's behavior — never an error).
  local function install_broadcast_wrap()
    if not server_module then return end
    local ok, server = pcall(require, server_module)
    if not ok or server.__session_send_wrapped then return end
    server.__session_send_wrapped = true
    local orig_broadcast = server.broadcast
    server.broadcast = function(method, params)
      if method == "at_mentioned" then
        local cid = session_client[M.term_key()]
        local tcp = server.state and server.state.server
        if cid and tcp and tcp.clients and tcp.clients[cid] then
          return server.send({ id = cid }, method, params)
        end
      end
      return orig_broadcast(method, params)
    end
  end
  install_broadcast_wrap()

  local function cur()
    return terminals[M.term_key()]
  end

  -- Show a hidden terminal / focus a visible one (mirrors the reuse branch of the upstream
  -- snacks provider). Assumes `t:buf_valid()`.
  local function reveal(t, focus)
    if not t.win or not vim.api.nvim_win_is_valid(t.win) then
      t:toggle()
    end
    if focus then
      t:focus()
      if t.win and vim.api.nvim_win_is_valid(t.win) and t.buf and vim.bo[t.buf].buftype == "terminal" then
        vim.api.nvim_win_call(t.win, function() vim.cmd("startinsert") end)
      end
    end
  end

  local provider = {}

  function provider.is_available()
    local Snacks = get_snacks()
    return Snacks ~= nil and Snacks.terminal ~= nil
  end

  function provider.setup() end

  function provider.open(cmd_string, env_table, config, focus)
    local Snacks = get_snacks()
    if not (Snacks and Snacks.terminal) then
      vim.notify("Snacks.nvim terminal provider not available.", vim.log.levels.ERROR)
      return
    end
    focus = normalize_focus(focus)
    local key = M.term_key()
    local t = terminals[key]
    if t and t:buf_valid() then
      reveal(t, focus)
      return
    end

    install_connect_hook()
    pending_key = key -- the agent we are about to spawn will be this session's
    local term = Snacks.terminal.open(cmd_string, build_opts(config, env_table, focus))
    if term and term:buf_valid() then
      terminals[key] = term
      if term.buf then vim.b[term.buf].keep_term = true end
      if config.auto_close then
        term:on("TermClose", function()
          terminals[key] = nil
          vim.schedule(function()
            term:close({ buf = true })
            vim.cmd.checktime()
          end)
        end, { buf = true })
      end
      term:on("BufWipeout", function()
        terminals[key] = nil
      end, { buf = true })
    else
      terminals[key] = nil
      pending_key = nil
      vim.notify("Failed to open terminal via Snacks.", vim.log.levels.ERROR)
    end
  end

  function provider.close()
    local t = cur()
    if t and t:buf_valid() then t:close() end
  end

  function provider.simple_toggle(cmd_string, env_table, config)
    local t = cur()
    if t and t:buf_valid() then
      t:toggle() -- visible -> hide, hidden -> show
    else
      provider.open(cmd_string, env_table, config)
    end
  end

  function provider.focus_toggle(cmd_string, env_table, config)
    local t = cur()
    if t and t:buf_valid() and not t:win_valid() then
      t:toggle() -- hidden -> show
    elseif t and t:buf_valid() and t:win_valid() then
      if t.win == vim.api.nvim_get_current_win() then
        t:toggle() -- focused -> hide
      else
        reveal(t, true) -- visible but not focused -> focus
      end
    else
      provider.open(cmd_string, env_table, config)
    end
  end

  function provider.get_active_bufnr()
    local t = cur()
    if t and t:buf_valid() and t.buf and vim.api.nvim_buf_is_valid(t.buf) then
      return t.buf
    end
    return nil
  end

  function provider._get_terminal_for_test()
    return cur()
  end

  return provider
end

return M
