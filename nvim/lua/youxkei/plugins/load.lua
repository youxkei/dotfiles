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

  return {
    name = to_name(shortname),
    src = to_src(shortname),
    init = spec.init,
    config = spec.config,
    keys = spec.keys,
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
    else
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
  local merge_fields = { "keys", "deps" }

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

  -- 7. Set up keymaps from keys specs
  for _, plugin in ipairs(plugins) do
    if plugin.keys then
      for _, key in ipairs(plugin.keys) do
        local lhs = key[1]
        local rhs = key[2]
        local mode = key.mode or "n"
        local desc = key.desc
        local ft = key.ft

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
    end
  end
end

return M
