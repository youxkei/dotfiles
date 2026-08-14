local M = {}

local disabled_builtins = {
  "gzip", "matchit", "matchparen", "netrwPlugin",
  "tarPlugin", "tohtml", "tutor", "zipPlugin",
}

-- Parser helpers

local function to_src(shortname)
  return "https://github.com/" .. shortname
end

local function to_name(shortname)
  return shortname:match("[^/]+$") or shortname
end

local function normalize(spec)
  if type(spec) == "string" then
    return {
      name = to_name(spec),
      src = spec:find("/") and to_src(spec) or nil,
    }
  end

  local shortname = spec[1]
  local raw_deps = spec.dependencies or spec.requires
  local deps = {}

  if raw_deps then
    if type(raw_deps) == "string" then
      deps = { to_name(raw_deps) }
    elseif type(raw_deps) == "table" then
      for _, dep in ipairs(raw_deps) do
        if type(dep) == "string" then
          table.insert(deps, to_name(dep))
        elseif type(dep) == "table" then
          table.insert(deps, to_name(dep[1]))
        end
      end
    end
  end

  local version = spec.version
  if version == "*" then
    version = nil
  end
  -- vim.pack has no separate `branch` field; a branch is just a version ref, so
  -- fold spec.branch into version (an explicit version wins if both are set).
  version = version or spec.branch

  return {
    name = to_name(shortname),
    src = to_src(shortname),
    init = spec.init,
    config = spec.config,
    keys = spec.keys,
    leader_keys = spec.leader_keys,
    build = spec.build,
    version = version,
    enabled = spec.enabled,
    deps = #deps > 0 and deps or nil,
  }
end

local function flatten(raw_specs)
  local result = {}

  for _, spec in ipairs(raw_specs) do
    if type(spec) == "string" then
      if spec:find("/") then
        table.insert(result, normalize(spec))
      end
    elseif spec.enabled ~= false then
      -- Skip a disabled spec *and* its dependency subtree here, before its deps
      -- get appended as standalone entries. Deps shared with an enabled plugin
      -- are still pulled in via that plugin, so only deps exclusive to the
      -- disabled plugin are dropped.
      local raw_deps = spec.dependencies or spec.requires
      if raw_deps then
        if type(raw_deps) == "string" then
          if raw_deps:find("/") then
            table.insert(result, normalize(raw_deps))
          end
        elseif type(raw_deps) == "table" then
          local flattened_deps = flatten(raw_deps)
          for _, dep in ipairs(flattened_deps) do
            table.insert(result, dep)
          end
        end
      end

      table.insert(result, normalize(spec))
    end
  end

  return result
end

local function deduplicate(specs)
  local index = {}
  local result = {}
  local unique_fields = { "config", "init", "build", "version", "enabled" }
  local merge_fields = { "keys", "leader_keys", "deps" }

  for _, spec in ipairs(specs) do
    local pos = index[spec.name]
    if pos then
      local existing = result[pos]

      for _, k in ipairs(unique_fields) do
        if spec[k] ~= nil then
          if existing[k] ~= nil then
            vim.notify(("duplicate field '%s' for plugin '%s'"):format(k, spec.name), vim.log.levels.WARN)
          end
          existing[k] = spec[k]
        end
      end

      for _, k in ipairs(merge_fields) do
        if spec[k] then
          if existing[k] then
            vim.list_extend(existing[k], spec[k])
          else
            existing[k] = spec[k]
          end
        end
      end
    else
      index[spec.name] = #result + 1
      table.insert(result, spec)
    end
  end

  return result
end

local function topo_sort(specs)
  local by_name = {}
  for _, spec in ipairs(specs) do
    by_name[spec.name] = spec
  end

  local result = {}
  local visited = {}
  local in_stack = {}

  local function visit(spec)
    if visited[spec.name] then return end
    if in_stack[spec.name] then return end

    in_stack[spec.name] = true

    if spec.deps then
      for _, dep_name in ipairs(spec.deps) do
        if by_name[dep_name] then
          visit(by_name[dep_name])
        end
      end
    end

    in_stack[spec.name] = nil
    visited[spec.name] = true
    table.insert(result, spec)
  end

  for _, spec in ipairs(specs) do
    visit(spec)
  end

  return result
end

local function parse(raw_specs)
  local specs = flatten(raw_specs)

  specs = vim.tbl_filter(function(spec)
    return spec.enabled ~= false
  end, specs)

  specs = deduplicate(specs)
  specs = topo_sort(specs)

  return specs
end

-- Loader

function M.setup()
  -- 1. Disable built-in plugins
  for _, name in ipairs(disabled_builtins) do
    vim.g["loaded_" .. name] = 1
  end

  -- 2. Parse specs
  local raw_specs = require("youxkei.plugins.spec")
  local plugins = parse(raw_specs)

  -- 3. Build vim.pack spec list
  local pack_specs = {}
  for _, plugin in ipairs(plugins) do
    table.insert(pack_specs, {
      src = plugin.src,
      name = plugin.name,
      version = plugin.version,
    })
  end

  -- 4. Track changed plugins for build commands
  local changed = {}
  vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
      local pname = ev.data.spec.name
      local kind = ev.data.kind
      if kind == "install" or kind == "update" then
        changed[pname] = ev.data.path
      end
    end,
  })

  -- 5. Install and add all plugins to rtp (load defaults to false during init)
  vim.pack.add(pack_specs, { confirm = false })

  -- 6. For each plugin: init, packadd, config, build
  for _, plugin in ipairs(plugins) do
    if plugin.init then
      local ok, err = pcall(plugin.init)
      if not ok then
        vim.notify("[load] init FAILED: " .. plugin.name .. ": " .. err, vim.log.levels.ERROR)
      end
    end

    local ok, err = pcall(vim.cmd.packadd, plugin.name)
    if not ok then
      vim.notify("[load] packadd FAILED: " .. plugin.name .. ": " .. err, vim.log.levels.ERROR)
    end

    if plugin.config then
      local ok2, err2 = pcall(plugin.config)
      if not ok2 then
        vim.notify("[load] config FAILED: " .. plugin.name .. ": " .. err2, vim.log.levels.ERROR)
      end
    end

    if plugin.build and changed[plugin.name] then
      local build = plugin.build
      if type(build) == "string" and build:sub(1, 1) == ":" then
        vim.cmd(build:sub(2))
      elseif type(build) == "function" then
        build()
      end
    end
  end

  -- 7. PackUpdate command: update plugins and remove inactive ones from disk
  vim.api.nvim_create_user_command("PackUpdate", function()
    local inactive = vim.iter(vim.pack.get())
      :filter(function(x) return not x.active end)
      :map(function(x) return x.spec.name end)
      :totable()

    if #inactive > 0 then
      vim.pack.del(inactive)
    end

    vim.pack.update()
  end, {})

  -- 8. Set up keymaps. `keys` entries carry a full lhs; `leader_keys` entries carry only the
  -- suffix after <leader> (so { "tf", ... } binds <leader>tf). Every leader_keys entry is ALSO
  -- reachable via the <C-,> ctrl-leader chord in normal AND insert mode, as an alternate to the
  -- literal <leader> (","): <C-,>tf does the same as ",tf". An entry flagged `term = true` also
  -- binds the same <C-,> variants in terminal mode, where a literal <leader> map is impossible
  -- (<leader> is "," and would eat comma input in :terminal / Claude floats). You may keep
  -- ctrl held across the whole suffix (see ctrl_leader_variants) EXCEPT on a key that resolves to
  -- <C-c>: in Normal/Insert mode <C-c> interrupts the pending mapping (|map_CTRL-C|) and cannot be
  -- caught, so no leader suffix ends in "c". Neovide and Alacritty (kitty keyboard protocol) both
  -- deliver <C-,> and the held <C-x> chords to nvim as real chords.
  local function set_key(mode, lhs, rhs, desc, ft)
    if rhs == nil then
      pcall(function()
        require("which-key").add { { lhs, group = desc } }
      end)
    elseif ft then
      vim.api.nvim_create_autocmd("FileType", {
        pattern = ft,
        callback = function(ev)
          vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
        end,
      })
    else
      vim.keymap.set(mode, lhs, rhs, { desc = desc })
    end
  end

  -- <C-,> leader variants for a suffix: ctrl may stay held for any leading run of
  -- the suffix keys and then be released for the rest (you never re-press it mid-sequence). So
  -- suffix "dt" yields <C-,>dt, <C-,><C-d>t and <C-,><C-d><C-t>. A held uppercase char is ctrl+shift
  -- (<C-S-x>), keeping e.g. "tF" distinct from "tf" (whose held form is <C-f>).
  local function ctrl_leader_variants(suffix)
    local variants = {}
    for held = 0, #suffix do
      local lhs = "<C-,>"
      for i = 1, #suffix do
        local c = suffix:sub(i, i)
        if i > held then
          lhs = lhs .. c
        elseif c:match("%u") then
          lhs = lhs .. "<C-S-" .. c:lower() .. ">"
        else
          lhs = lhs .. "<C-" .. c .. ">"
        end
      end
      variants[#variants + 1] = lhs
    end
    return variants
  end

  for _, plugin in ipairs(plugins) do
    if plugin.keys then
      for _, key in ipairs(plugin.keys) do
        set_key(key.mode or "n", key[1], key[2], key.desc, key.ft)
      end
    end
    if plugin.leader_keys then
      for _, key in ipairs(plugin.leader_keys) do
        local base = key.mode or "n"
        set_key(base, "<leader>" .. key[1], key[2], key.desc, key.ft)
        -- The <C-,> ctrl-leader chord reaches every leader_key in normal + insert mode; term = true
        -- exposes it in terminal mode too.
        local modes = { base, "i" }
        if key.term then modes[#modes + 1] = "t" end
        for _, clhs in ipairs(ctrl_leader_variants(key[1])) do
          set_key(modes, clhs, key[2], key.desc, key.ft)
        end
      end
    end
  end
end

return M
