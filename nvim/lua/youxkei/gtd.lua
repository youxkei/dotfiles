-- gtd /do works inside a per-task worktree (~/repo/gtd/.claude/worktrees/do-<slug>/) and
-- puts clones + scratch under that worktree's todo/<slug>/ (main repo in repo/, reference
-- clones in ref/, both gitignored). nvim enters a worktree via <leader>dt (cd into todo/<slug>/ +
-- possession session); the current task is identified by cwd, so <leader>df/<leader>dF/<leader>dg/<leader>dG search it with
-- ignored files included (.git excluded; <leader>df/<leader>dg also exclude ref/).
local M = {}

local function wt_root()
  return vim.fn.expand("~/repo/gtd/.claude/worktrees")
end

-- slug -> the task work dir inside the worktree
-- (.claude/worktrees/do-<slug>/todo/<slug>/, or the worktree root if absent).
local function wt_task_dir(root, slug)
  local wt = root .. "/do-" .. slug
  local td = wt .. "/todo/" .. slug
  if vim.fn.isdirectory(td) == 1 then return td end
  return wt
end

-- The current task's work dir, derived from cwd: if we're inside a do-<slug> worktree,
-- return its todo/<slug>/ (or the worktree root). Otherwise nil.
local function cwd_task_dir()
  local root = wt_root()
  local slug = vim.fn.getcwd():match("^" .. vim.pesc(root) .. "/do%-([^/]+)")
  if not slug then return nil end
  return wt_task_dir(root, slug)
end

-- <leader>df/<leader>dF/<leader>dg/<leader>dG: search the current task (resolved from cwd). kind = "files" | "grep".
-- with_ref=false → main repo + notes (exclude ref/); true → everything (main + ref + notes).
function M.search(kind, with_ref)
  local dir = cwd_task_dir()
  if not dir then
    return vim.notify("not in a gtd /do worktree — ,dt first", vim.log.levels.WARN)
  end
  require("snacks").picker[kind] {
    cwd = dir,
    hidden = true,
    ignored = true,
    exclude = with_ref and { ".git" } or { ".git", "ref" },
  }
end

-- Parse ~/repo/gtd/list.md and return an array of {title, slug} (higher = higher priority).
local function list_tasks()
  local f = io.open(vim.fn.expand("~/repo/gtd/list.md"), "r")
  if not f then return {} end
  local tasks = {}
  for line in f:lines() do
    local title, slug = line:match("^%-%s*%[(.-)%]%(todo/(.-)/task%.md%)")
    if title and slug then
      tasks[#tasks + 1] = { title = title, slug = slug }
    end
  end
  f:close()
  return tasks
end

-- Freshest task.md for a slug: the /do worktree's copy if it exists (that's where /do writes
-- live progress), otherwise the main checkout's todo/<slug>/task.md. Used for the picker preview
-- and the "what is this task doing now?" summary below.
local function task_md_path(slug)
  local wt_md = wt_root() .. "/do-" .. slug .. "/todo/" .. slug .. "/task.md"
  if vim.fn.filereadable(wt_md) == 1 then return wt_md end
  return vim.fn.expand("~/repo/gtd") .. "/todo/" .. slug .. "/task.md"
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
  local f = io.open(task_md_path(slug), "r")
  if not f then return nil end
  if f:read("l") ~= "---" then f:close(); return nil end -- task.md always opens with frontmatter
  local status = nil
  for line in f:lines() do
    if line == "---" then break end -- end of frontmatter
    local v = line:match("^status:%s*(.-)%s*$")
    if v then
      if v ~= "" then status = v end
      break
    end
  end
  f:close()
  return status
end

-- Picker label: "<title> — <status>" (status omitted when task.md has none).
local function task_label(title, slug)
  local s = task_status(slug)
  if s and s ~= "" then
    return title .. " — " .. truncate(s, 70)
  end
  return title
end

-- Create the do-<slug> worktree from HEAD if it doesn't exist. Returns (path, created) on
-- success, (nil, nil, err) on failure. /do reuses this worktree by path, /done merges and cleans it up.
local function ensure_worktree(slug)
  local gtd = vim.fn.expand("~/repo/gtd")
  local wt = gtd .. "/.claude/worktrees/do-" .. slug
  if vim.fn.isdirectory(wt) == 1 then return wt, false end
  -- Check out the branch if it already exists, otherwise create it fresh from HEAD.
  vim.fn.system({ "git", "-C", gtd, "rev-parse", "--verify", "--quiet", "refs/heads/do-" .. slug })
  local cmd = { "git", "-C", gtd, "worktree", "add", wt }
  if vim.v.shell_error == 0 then
    cmd[#cmd + 1] = "do-" .. slug
  else
    vim.list_extend(cmd, { "-b", "do-" .. slug, "HEAD" })
  end
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then return nil, nil, out end
  return wt, true
end

-- Enter the chosen task: create its do-<slug> worktree if missing, then cd into the worktree's
-- todo/<slug>/ work dir and switch the possession session to it. Shared by <leader>dt's picker confirm.
local function act_on_task(choice, on_entered)
  local wt, created, err = ensure_worktree(choice.slug)
  if not wt then
    return vim.notify("gtd: failed to create worktree → " .. tostring(err), vim.log.levels.ERROR)
  end
  local td = wt_task_dir(wt_root(), choice.slug) -- cd target: worktree's todo/<slug>/ (root if absent)
  -- Switch the possession session to the worktree without clobbering the one we leave.
  -- Order matters: save the outgoing session (only if it has real files — see below), then
  -- PossessionClose (clears "current" with no autosave and no cd), and only THEN cd in. If
  -- we cd'd while the outgoing session was still "current", a later autosave (or load's
  -- on_load autosave) would write the worktree's buffers/cwd into that session.
  if require("youxkei.session").has_file_buffer() then -- skip when only a terminal is open, else we'd save an empty session over it
    pcall(function() vim.cmd("silent! PossessionSaveCwd!") end)
  end
  pcall(function() vim.cmd("silent! PossessionClose") end)
  vim.cmd("cd " .. vim.fn.fnameescape(td)) -- global cd into the task work dir (no session is current now)
  local paths = require("possession.paths")
  if paths.session(paths.cwd_session_name()):exists() then
    pcall(function() vim.cmd("silent! PossessionLoadCwd") end) -- existing worktree session → load it (current = this worktree)
  else
    -- Fresh worktree: PossessionClose above is a no-op when nothing was "current" (e.g. only a
    -- terminal was open), so the previous task's buffers can linger and no session gets created.
    -- Force a clean slate, then create + activate this worktree's session so it shows up in
    -- possession and future autosaves target it (not the previous task).
    pcall(function() require("possession.utils").delete_all_buffers(true) end)
    pcall(function() vim.cmd("silent! PossessionSaveCwd!") end)
  end
  vim.notify((created and "gtd: created + entered → " or "gtd: entered → ") .. choice.title)
  if on_entered then on_entered() end -- now that the session is current, open Claude for the task
end

-- <leader>dt: pick a gtd task from list.md (priority order) via a snacks picker whose rows read
-- "<title> — <status>" (status = the task.md `status:` field, i.e. what it's doing now) and whose
-- preview shows the whole task.md. On confirm, create its do-<slug> worktree if missing, cd into
-- the worktree's todo/<slug>/ work dir, and switch the possession session to it — so a Claude
-- launched here runs inside the worktree. on_entered (optional) runs once the session is current.
function M.enter_task(on_entered)
  local tasks = list_tasks()
  if #tasks == 0 then
    return vim.notify("no gtd tasks in list.md", vim.log.levels.WARN)
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

-- <leader>dn: a derivative of <leader>dt. Instead of picking a task from list.md and creating/entering
-- its worktree, list (in a snacks picker, same "<title> — <status>" rows in the same list.md priority
-- order, but previewing each session's live Claude terminal instead of <leader>dt's task.md) the possession
-- sessions that already have a live Claude terminal running, and jump to the chosen one,
-- then run on_entered (e.g. to reveal Claude) once it's current. Only sessions other than the current
-- one that exist as loadable named sessions are offered (the gtd flow keys each session's Claude
-- terminal by its possession session name).
function M.enter_claudecode_session(on_entered)
  local session = require("youxkei.session")
  local psession = require("possession.session")
  local paths = require("possession.paths")
  local current = psession.get_session_name()
  -- slug -> {title, rank} from list.md: the title labels each session with its task title (like <leader>dt)
  -- instead of the raw session path, and the rank (list.md line order = priority) orders the rows.
  -- Sessions that aren't task worktrees (or whose task is no longer in list.md) have neither.
  local tasks = {}
  for i, t in ipairs(list_tasks()) do
    tasks[t.slug] = { title = t.title, rank = i }
  end
  local choices = {}
  for _, key in ipairs(session.active_session_keys("claudecode.server.init")) do
    if key ~= current and paths.session(key):exists() then
      local slug = key:match("worktrees/do%-([^/]+)")
      local task = slug and tasks[slug]
      local title = (task and task.title) or vim.fn.fnamemodify(key, ":t")
      choices[#choices + 1] = {
        key = key,
        title = title,
        -- list.md position, or math.huge for anything list.md doesn't cover (see the sort below).
        rank = task and task.rank or math.huge,
        -- status row (title — status) for real task worktrees; bare sessions show the title.
        text = slug and task_label(title, slug) or title,
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
  -- Sessions list.md doesn't rank (non-task worktrees, or tasks already dropped from list.md) go to the
  -- tail rather than being dropped from the picker: their Claude is running, so they must stay reachable.
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
-- worktrees that are already removed, and anything touching the disk would come back empty. The "/"
-- boundary is what keeps do-foo from matching do-foo-bar's sessions.
local function session_under(name, dir)
  return name ~= nil and (name == dir or name:sub(1, #dir + 1) == dir .. "/")
end

-- Delete every possession session saved at or under a do-<slug> worktree. Walks the whole session
-- list instead of the one path <leader>dt cd's into (the worktree's todo/<slug>/), because the user can cd
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

-- Called by /done (via $NVIM RPC) right after it removes a do-<slug> worktree. If this nvim
-- was inside that worktree, tear the finished task's session down IN PLACE: do NOT switch to
-- another session (that would reload main's session and close /done's own terminal), and do NOT
-- PossessionClose it (close keeps the session file and wipes file buffers / stops LSP). Instead
-- wipe this session's claudecode/toggleterm terminals, then DELETE the session. Deleting
-- the current session also clears it as current (possession's delete sets session_name = nil),
-- so autosave can't resurrect it.
--
-- msg (optional) is /done's one-line completion report, notified once the teardown is done. It stays
-- optional because worktrees created before it existed carry a /done that calls this with one arg.
function _G.GtdDoneCleanup(slug, msg)
  local wt = wt_root() .. "/do-" .. slug
  local prefix = vim.fn.fnamemodify(wt, ":~")
  local session = require("possession.session")
  local function drop()
    drop_sessions_under(wt)
    -- The terminal that printed /done's report is one of the ones this cleanup wipes, so the report
    -- itself is not a durable channel: re-surface it through the notifier, whose history survives.
    if msg and msg ~= "" then vim.notify(msg) end
  end
  -- "Was this nvim in the finished task?" is answered by the current session's name as well as by
  -- cwd, because /done removes the worktree before calling and getcwd() is therefore already ""
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

-- Delete the sessions of do-<slug> worktrees that no longer exist. GtdDoneCleanup above only runs
-- when /done remembers to fire it, and /done's own spec tells the /refresh · /sync path not to fire
-- it at all, so sessions outlive their worktrees; gtd's Stop hook catches that at the end of a Claude
-- turn and this catches what happened while no nvim was up. A missing worktree is the whole test: a
-- task whose worktree stands is live even if its todo/<slug>/ was never created.
--
-- Unlike the Stop hook's reaper this needs no commit-lock check. It deletes session files and never
-- wipes a terminal, so it cannot cut short a /done sitting between removing the worktree (step 6.3)
-- and committing (step 8) — the case that rules out reaping from a timer.
function M.reap_stale_task_sessions()
  local root = wt_root()
  local root_pat = "^" .. vim.pesc(vim.fn.fnamemodify(root, ":~")) .. "/(do%-[^/]+)"
  local session = require("possession.session")
  local stale = {}
  for _, data in pairs(session.list()) do
    local slug = data.name and data.name:match(root_pat)
    if slug and vim.fn.isdirectory(root .. "/" .. slug) == 0 then
      session.delete(data.name, { no_confirm = true })
      stale[slug] = true -- a slug can hold several sessions (worktree root, task dir, a clone)
    end
  end
  local reaped = vim.tbl_keys(stale)
  if #reaped > 0 then
    table.sort(reaped)
    vim.notify("gtd: reaped stale session(s) for " .. table.concat(reaped, ", "))
  end
end

return M
