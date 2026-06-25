-- gtd /do works inside a per-task worktree (~/repo/gtd/.claude/worktrees/do-<slug>/) and
-- puts clones + scratch under that worktree's todo/<slug>/ (main repo in repo/, reference
-- clones in ref/, both gitignored). nvim enters a worktree via ,dt (cd + possession session);
-- the current task is identified by cwd, so ,df/,dF/,dg/,dG search the cwd's worktree with
-- ignored files included (.git excluded; ,df/,dg also exclude ref/).
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

-- ,df/,dF/,dg/,dG: search the current task (resolved from cwd). kind = "files" | "grep".
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

-- True if any real, named file buffer is open (not a terminal / scratch). Used to decide
-- whether saving the outgoing possession session is worthwhile: the before_save hook strips
-- terminal buffers, so saving a terminal-only view (e.g. just the Claude terminal) would
-- overwrite that session with an empty one.
local function has_file_buffer()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.fn.buflisted(b) == 1 and vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b) ~= "" then
      return true
    end
  end
  return false
end

-- ,dt: pick a gtd task from list.md (priority order), create its do-<slug> worktree if
-- missing, then cd into the worktree root and switch the possession session to it. The task
-- is identified by cwd afterward, so a Claude launched here runs inside the worktree.
function M.enter_task()
  local tasks = list_tasks()
  if #tasks == 0 then
    return vim.notify("no gtd tasks in list.md", vim.log.levels.WARN)
  end
  vim.ui.select(tasks, {
    prompt = "gtd task: ",
    format_item = function(t) return t.title end,
  }, function(choice)
    if not choice then return end
    local wt, created, err = ensure_worktree(choice.slug)
    if not wt then
      return vim.notify("gtd: failed to create worktree → " .. tostring(err), vim.log.levels.ERROR)
    end
    -- Switch the possession session to the worktree without clobbering the one we leave.
    -- Order matters: save the outgoing session (only if it has real files — see below), then
    -- PossessionClose (clears "current" with no autosave and no cd), and only THEN cd in. If
    -- we cd'd while the outgoing session was still "current", a later autosave (or load's
    -- on_load autosave) would write the worktree's buffers/cwd into that session.
    if has_file_buffer() then -- skip when only a terminal is open, else we'd save an empty session over it
      pcall(function() vim.cmd("silent! PossessionSaveCwd!") end)
    end
    pcall(function() vim.cmd("silent! PossessionClose") end)
    vim.cmd("cd " .. vim.fn.fnameescape(wt)) -- global cd into the worktree root (no session is current now)
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
  end)
end

-- Called by /done (via $NVIM RPC) right after it removes a do-<slug> worktree. If this nvim
-- was inside that worktree, tear the finished task's session down IN PLACE: do NOT switch to
-- another session (that would reload main's session and close /done's own terminal), and do NOT
-- PossessionClose it (close keeps the session file and wipes file buffers / stops LSP). Instead
-- wipe this session's claudecode/codex/toggleterm terminals, then DELETE the session. Deleting
-- the current session also clears it as current (possession's delete sets session_name = nil),
-- so autosave can't resurrect it. The cwd stays the now-removed worktree dir (getcwd() == "") —
-- that's fine, the session is gone either way.
function _G.GtdDoneCleanup(slug)
  local wt = wt_root() .. "/do-" .. slug
  local wt_name = vim.fn.fnamemodify(wt, ":~") -- == paths.cwd_session_name() when cwd == wt
  local paths = require("possession.paths")
  local function drop()
    if paths.session(wt_name):exists() then
      require("possession.session").delete(wt_name, { no_confirm = true })
    end
  end
  -- /done removes the worktree before calling this, so if the host nvim was sitting in it,
  -- getcwd() now returns "" (its dir is gone). Treat empty cwd + missing worktree as "was here".
  local cwd = vim.fn.getcwd()
  if cwd:sub(1, #wt) == wt or (cwd == "" and vim.fn.isdirectory(wt) == 0) then
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

return M
