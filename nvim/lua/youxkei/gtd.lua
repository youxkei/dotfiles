-- Each open gtd task is a jj change checked out in its own workspace
-- (~/repo/gtd/.claude/workspaces/<task>/), with clones + scratch under that workspace's
-- tasks/<task>/ (main repo in repo/, reference clones in ref/, raw data in data/, all gitignored).
-- /add creates the workspace; nvim enters it via <leader>dt (cd into tasks/<task>/ + possession
-- session); the current task is identified by cwd, so <leader>df/<leader>dF/<leader>dg/<leader>dG search it with
-- ignored files included (.git excluded; <leader>df/<leader>dg also exclude ref/).
local M = {}

local function wt_root()
  return vim.fn.expand("~/repo/gtd/.claude/workspaces")
end

-- task -> its work dir inside its workspace (.claude/workspaces/<task>/tasks/<task>/, or the
-- workspace root if absent).
local function wt_task_dir(root, slug)
  local wt = root .. "/" .. slug
  local td = wt .. "/tasks/" .. slug
  if vim.fn.isdirectory(td) == 1 then return td end
  return wt
end

-- The current task's work dir, derived from cwd: if we're inside a task workspace, return its
-- tasks/<task>/ (or the workspace root). Otherwise nil.
local function cwd_task_dir()
  local root = wt_root()
  local slug = vim.fn.getcwd():match("^" .. vim.pesc(root) .. "/([^/]+)")
  if not slug then return nil end
  return wt_task_dir(root, slug)
end

-- <leader>df/<leader>dF/<leader>dg/<leader>dG: search the current task (resolved from cwd). kind = "files" | "grep".
-- with_ref=false → main repo + notes (exclude ref/); true → everything (main + ref + notes).
function M.search(kind, with_ref)
  local dir = cwd_task_dir()
  if not dir then
    return vim.notify("not in a gtd task workspace — ,dt first", vim.log.levels.WARN)
  end
  require("snacks").picker[kind] {
    cwd = dir,
    hidden = true,
    ignored = true,
    exclude = with_ref and { ".git" } or { ".git", "ref" },
  }
end

-- An open task's task.md lives only in its own workspace. Used for the picker preview and the
-- "what is this task doing now?" summary below.
local function task_md_path(slug)
  return wt_root() .. "/" .. slug .. "/tasks/" .. slug .. "/task.md"
end

-- The frontmatter of a task.md as a table of raw string values (nil when it has none).
local function frontmatter(path)
  local f = io.open(path, "r")
  if not f then return nil end
  if f:read("l") ~= "---" then f:close(); return nil end -- task.md always opens with frontmatter
  local fm = {}
  for line in f:lines() do
    if line == "---" then break end -- end of frontmatter
    local k, v = line:match("^([%w_]+):%s*(.-)%s*$")
    if k then fm[k] = v:gsub('^"(.*)"$', "%1") end
  end
  f:close()
  return fm
end

-- The open tasks, in priority order: those with a deadline first, earliest deadline first, then
-- the rest by added_at. Every workspace also checks out the completed tasks under its tasks/, so
-- only <workspace>/tasks/<same name>/task.md counts; workspaces without one (a review skill's
-- scratch workspace) are not tasks. Returns an array of {title, slug}.
local function list_tasks()
  local tasks = {}
  for _, wt in ipairs(vim.fn.glob(wt_root() .. "/*", false, true)) do
    local slug = vim.fn.fnamemodify(wt, ":t")
    local fm = frontmatter(task_md_path(slug))
    if fm then
      tasks[#tasks + 1] = {
        title = (fm.title ~= nil and fm.title ~= "") and fm.title or slug,
        slug = slug,
        deadline = fm.deadline or "",
        added_at = fm.added_at or "",
      }
    end
  end
  -- ISO 8601 dates and timestamps in one timezone compare correctly as strings.
  table.sort(tasks, function(a, b)
    if (a.deadline ~= "") ~= (b.deadline ~= "") then return a.deadline ~= "" end
    if a.deadline ~= b.deadline then return a.deadline < b.deadline end
    if a.added_at ~= b.added_at then return a.added_at < b.added_at end
    return a.slug < b.slug
  end)
  return tasks
end

-- Trim a summary to `max` display columns (multibyte-safe), adding an ellipsis when cut.
local function truncate(s, max)
  if vim.fn.strdisplaywidth(s) <= max then return s end
  while vim.fn.strchars(s) > 0 and vim.fn.strdisplaywidth(s) > max - 1 do
    s = vim.fn.strcharpart(s, 0, vim.fn.strchars(s) - 1)
  end
  return s .. "…"
end

-- The task's one-line "what is this doing now?" status, read from the `status:` frontmatter field
-- of its task.md (kept current by /do). This is the single defined slot the picker labels read;
-- the preview pane shows the whole task.md. Returns nil when task.md is missing, has no
-- frontmatter, or `status` is absent/blank.
local function task_status(slug)
  local fm = frontmatter(task_md_path(slug))
  if not fm or not fm.status or fm.status == "" then return nil end
  return fm.status
end

-- Picker label: "<title> — <status>" (status omitted when task.md has none).
local function task_label(title, slug)
  local s = task_status(slug)
  if s and s ~= "" then
    return title .. " — " .. truncate(s, 70)
  end
  return title
end

-- Enter the chosen task: cd into its workspace's tasks/<task>/ work dir and switch the possession
-- session to it. Shared by <leader>dt's picker confirm. The workspace itself is /add's to create
-- (it is the task's jj change), so a missing one is reported rather than made here.
local function act_on_task(choice, on_entered)
  local wt = wt_root() .. "/" .. choice.slug
  if vim.fn.isdirectory(wt) == 0 then
    return vim.notify("gtd: no workspace for " .. choice.slug, vim.log.levels.ERROR)
  end
  local td = wt_task_dir(wt_root(), choice.slug) -- cd target: workspace's tasks/<task>/ (root if absent)
  -- Claude Code reads .claude/settings.json only from the directory it starts in, never from a
  -- parent, so a Claude started in tasks/<task>/ would run without the gtd hooks. Link the
  -- workspace's .claude into the work dir instead of starting Claude at the workspace root, which
  -- would lose the cwd that identifies the task.
  if td ~= wt and not vim.uv.fs_lstat(td .. "/.claude") then
    vim.uv.fs_symlink("../../.claude", td .. "/.claude")
  end
  -- Switch the possession session to the workspace without clobbering the one we leave.
  -- Order matters: save the outgoing session (only if it has real files — see below), then
  -- PossessionClose (clears "current" with no autosave and no cd), and only THEN cd in. If
  -- we cd'd while the outgoing session was still "current", a later autosave (or load's
  -- on_load autosave) would write the workspace's buffers/cwd into that session.
  if require("youxkei.session").has_file_buffer() then -- skip when only a terminal is open, else we'd save an empty session over it
    pcall(function() vim.cmd("silent! PossessionSaveCwd!") end)
  end
  pcall(function() vim.cmd("silent! PossessionClose") end)
  vim.cmd("cd " .. vim.fn.fnameescape(td)) -- global cd into the task work dir (no session is current now)
  local paths = require("possession.paths")
  if paths.session(paths.cwd_session_name()):exists() then
    pcall(function() vim.cmd("silent! PossessionLoadCwd") end) -- existing workspace session → load it (current = this workspace)
  else
    -- First visit: PossessionClose above is a no-op when nothing was "current" (e.g. only a
    -- terminal was open), so the previous task's buffers can linger and no session gets created.
    -- Force a clean slate, then create + activate this workspace's session so it shows up in
    -- possession and future autosaves target it (not the previous task).
    pcall(function() require("possession.utils").delete_all_buffers(true) end)
    pcall(function() vim.cmd("silent! PossessionSaveCwd!") end)
  end
  vim.notify("gtd: entered → " .. choice.title)
  if on_entered then on_entered() end -- now that the session is current, open Claude for the task
end

-- <leader>dt: pick an open gtd task (priority order) via a snacks picker whose rows read
-- "<title> — <status>" (status = the task.md `status:` field, i.e. what it's doing now) and whose
-- preview shows the whole task.md. On confirm, cd into the task workspace's tasks/<task>/ work
-- dir and switch the possession session to it — so a Claude launched here runs inside the
-- workspace. on_entered (optional) runs once the session is current.
function M.enter_task(on_entered)
  local tasks = list_tasks()
  if #tasks == 0 then
    return vim.notify("no open gtd tasks", vim.log.levels.WARN)
  end
  require("snacks").picker.pick {
    source = "gtd_tasks",
    title = "gtd task",
    format = "text",
    finder = function()
      return vim.tbl_map(function(t)
        -- text: matched + rendered row; title: preview header; file: task.md for the preview pane.
        return { text = task_label(t.title, t.slug), title = t.title, slug = t.slug, file = task_md_path(t.slug) }
      end, tasks)
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then return end
      vim.schedule(function() act_on_task({ title = item.title, slug = item.slug }, on_entered) end)
    end,
  }
end

-- Switch to the chosen session: session.load autosaves the outgoing session and restores the
-- chosen one's cwd/buffers; our keep_term guards keep both sessions' Claude terminals alive across
-- the switch. Shared by <leader>dn's picker confirm.
local function act_on_session(choice, on_entered)
  require("possession.session").load(choice.key)
  vim.notify("gtd: switched to → " .. choice.label)
  if on_entered then on_entered() end -- now current → reveal this session's Claude
end

-- <leader>dn: a derivative of <leader>dt. Instead of picking a task and entering its workspace, list
-- (in a snacks picker, same "<title> — <status>" rows in the same priority order, but previewing
-- each session's live Claude terminal instead of <leader>dt's task.md) the possession
-- sessions that already have a live Claude terminal running, and jump to the chosen one,
-- then run on_entered (e.g. to reveal Claude) once it's current. Only sessions other than the current
-- one that exist as loadable named sessions are offered (the gtd flow keys each session's Claude
-- terminal by its possession session name).
function M.enter_claudecode_session(on_entered)
  local session = require("youxkei.session")
  local psession = require("possession.session")
  local paths = require("possession.paths")
  local current = psession.get_session_name()
  -- task -> {title, rank} from list_tasks: the title labels each session with its task title (like <leader>dt)
  -- instead of the raw session path, and the rank (priority order) orders the rows.
  -- Sessions that aren't open task workspaces have neither.
  local tasks = {}
  for i, t in ipairs(list_tasks()) do
    tasks[t.slug] = { title = t.title, rank = i }
  end
  local choices = {}
  for _, key in ipairs(session.active_session_keys("claudecode.server.init")) do
    if key ~= current and paths.session(key):exists() then
      local slug = key:match("/%.claude/workspaces/([^/]+)")
      local task = slug and tasks[slug]
      local title = (task and task.title) or vim.fn.fnamemodify(key, ":t")
      choices[#choices + 1] = {
        key = key,
        title = title,
        -- priority position, or math.huge for anything that isn't an open task (see the sort below).
        rank = task and task.rank or math.huge,
        -- status row (title — status) for open tasks; other sessions show the title.
        text = task and task_label(title, slug) or title,
        -- preview target: this session's live Claude terminal buffer (see the picker's preview).
        buf = session.session_bufnr("claudecode.server.init", key),
      }
    end
  end
  if #choices == 0 then
    return vim.notify("no other session has an active Claude", vim.log.levels.WARN)
  end
  -- Order the rows here rather than leaving it to the picker: with an empty prompt snacks does not sort
  -- (matcher.sort_empty = false) and renders the finder's order as-is, and that order is the terminal
  -- provider's `pairs` order over its live terminals — arbitrary, and different from one run to the next.
  -- Sessions without a rank (a review skill's workspace, the default checkout, a task already done) go to
  -- the tail rather than being dropped from the picker: their Claude is running, so they must stay reachable.
  -- Tie-break on the session key, not the displayed label, because keys are unique (active_session_keys
  -- dedupes) while labels are not, so a label tie-break would leave same-titled tail rows in that same
  -- arbitrary `pairs` order.
  table.sort(choices, function(a, b)
    if a.rank ~= b.rank then return a.rank < b.rank end
    return a.key < b.key
  end)
  require("snacks").picker.pick {
    source = "gtd_sessions",
    title = "Claude session",
    format = "text",
    finder = function()
      return vim.tbl_map(function(c)
        return { text = c.text, title = c.title, key = c.key, buf = c.buf }
      end, choices)
    end,
    -- Preview each session's live Claude terminal instead of <leader>dt's task.md. item.buf is the terminal
    -- buffer, so the default file previewer renders it (and titles it with item.title); we then scroll
    -- to the bottom so the preview shows the terminal's tail (latest output) like the live float would.
    preview = function(ctx)
      require("snacks").picker.preview.file(ctx)
      if ctx.item.buf and ctx.preview.win:win_valid() then
        vim.api.nvim_win_call(ctx.preview.win.win, function() vim.cmd("normal! G") end)
      end
    end,
    confirm = function(picker, item)
      picker:close()
      if not item then return end
      vim.schedule(function() act_on_session({ key = item.key, label = item.title }, on_entered) end)
    end,
  }
end

-- Is a possession session saved at or under `dir` (both in possession's ":~" name form)?
-- Membership is decided as pure string work rather than by resolving the paths: callers ask about
-- workspaces that are already removed, and anything touching the disk would come back empty. The "/"
-- boundary is what keeps foo from matching foo-bar's sessions.
local function session_under(name, dir)
  return name ~= nil and (name == dir or name:sub(1, #dir + 1) == dir .. "/")
end

-- Delete every possession session saved at or under a task workspace. Walks the whole session
-- list instead of the one path <leader>dt cd's into (the workspace's tasks/<task>/), because the user can cd
-- deeper — into a clone under repo/, say — and a session is named after whatever dir was current
-- when it was saved, so those deeper ones would outlive a fixed candidate list.
local function drop_sessions_under(wt)
  local prefix = vim.fn.fnamemodify(wt, ":~")
  local session = require("possession.session")
  for _, data in pairs(session.list()) do
    if session_under(data.name, prefix) then
      session.delete(data.name, { no_confirm = true }) -- delete, not raw unlink: this clears session_name when it's current
    end
  end
end

-- Called by /done (via $NVIM RPC) right after it removes a task workspace. If this nvim
-- was inside that workspace, tear the finished task's session down IN PLACE: do NOT switch to
-- another session (that would reload main's session and close /done's own terminal), and do NOT
-- PossessionClose it (close keeps the session file and wipes file buffers / stops LSP). Instead
-- wipe this session's claudecode/toggleterm terminals, then DELETE the session. Deleting
-- the current session also clears it as current (possession's delete sets session_name = nil),
-- so autosave can't resurrect it.
--
-- msg (optional) is /done's one-line completion report, notified once the teardown is done.
function _G.GtdDoneCleanup(slug, msg)
  local wt = wt_root() .. "/" .. slug
  local prefix = vim.fn.fnamemodify(wt, ":~")
  local session = require("possession.session")
  local function drop()
    drop_sessions_under(wt)
    -- The terminal that printed /done's report is one of the ones this cleanup wipes, so the report
    -- itself is not a durable channel: re-surface it through the notifier, whose history survives.
    if msg and msg ~= "" then vim.notify(msg) end
  end
  -- "Was this nvim in the finished task?" is answered by the current session's name as well as by
  -- cwd, because /done removes the workspace before calling and getcwd() is therefore already ""
  -- in the very instance we most need to recognize. Reading that empty cwd as "was here" instead
  -- would wipe the terminals of an nvim whose cwd vanished for an unrelated reason.
  local cwd = vim.fn.getcwd()
  if cwd == wt or cwd:sub(1, #wt + 1) == wt .. "/" or session_under(session.get_session_name(), prefix) then
    -- Defer so this RPC returns to /done before we wipe its own terminal. Wipe the terminals
    -- first (term_key still resolves to this session's name), then delete the session.
    vim.schedule(function()
      require("youxkei.session").wipe_current_session_terminals()
      drop()
    end)
  else
    drop()
  end
end

-- Delete the sessions of task workspaces that no longer exist. GtdDoneCleanup above only runs
-- when /done remembers to fire it, so sessions outlive their workspaces; gtd's Stop hook catches
-- that at the end of a Claude turn and this catches what happened while no nvim was up. A missing
-- workspace is the whole test: a task whose workspace stands is live even if its tasks/<task>/ was
-- never created.
--
-- Unlike the Stop hook's reaper this needs no commit-lock check. It deletes session files and never
-- wipes a terminal, so it cannot cut short a /done in the middle of moving its clones out — the case
-- that rules out reaping from a timer.
function M.reap_stale_task_sessions()
  local root = wt_root()
  local root_pat = "^" .. vim.pesc(vim.fn.fnamemodify(root, ":~")) .. "/([^/]+)"
  local session = require("possession.session")
  local stale = {}
  for _, data in pairs(session.list()) do
    local slug = data.name and data.name:match(root_pat)
    if slug and vim.fn.isdirectory(root .. "/" .. slug) == 0 then
      session.delete(data.name, { no_confirm = true })
      stale[slug] = true -- a task can hold several sessions (workspace root, task dir, a clone)
    end
  end
  local reaped = vim.tbl_keys(stale)
  if #reaped > 0 then
    table.sort(reaped)
    vim.notify("gtd: reaped stale session(s) for " .. table.concat(reaped, ", "))
  end
end

return M
