local wezterm = require "wezterm"
local act = wezterm.action

local config = wezterm.config_builder()

config.font = wezterm.font("Moralerspace Krypton HWNF")
config.font_size = 9.0
config.color_scheme = "nord"
config.warn_about_missing_glyphs = false

config.initial_cols = 400
config.initial_rows = 80

config.enable_tab_bar = false
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.scrollback_lines = 100000

config.max_fps = 120
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

config.default_prog = { "wsl.exe", "-u", "youxkei", "--cd", "~", "-e", "zsh", "-l", "-c", "nvim" }

config.keys = {
  { key = "c", mods = "CTRL", action = act.SendKey { key = "c", mods = "CTRL" } },
  { key = "v", mods = "CTRL", action = act.SendKey { key = "v", mods = "CTRL" } },
  { key = "c", mods = "CTRL|SHIFT", action = act.SendKey { key = "c", mods = "CTRL|SHIFT" } },
  { key = "v", mods = "CTRL|SHIFT", action = act.SendKey { key = "v", mods = "CTRL|SHIFT" } },

  { key = "0", mods = "CTRL", action = act.ResetFontSize },
  { key = "=", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
  { key = "=", mods = "CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },

  { key = "t", mods = "CTRL|SHIFT", action = act.SpawnWindow },

  { key = "Tab", mods = "CTRL", action = act.SendString "\x11\t" },
  { key = "Tab", mods = "CTRL|SHIFT", action = act.SendString "\x11s\t" },

  { key = "1", mods = "CTRL", action = act.SendString "\x111" },
  { key = "2", mods = "CTRL", action = act.SendString "\x112" },
  { key = "3", mods = "CTRL", action = act.SendString "\x113" },
  { key = "4", mods = "CTRL", action = act.SendString "\x114" },
  { key = "5", mods = "CTRL", action = act.SendString "\x115" },
  { key = "6", mods = "CTRL", action = act.SendString "\x116" },
  { key = "7", mods = "CTRL", action = act.SendString "\x117" },
  { key = "8", mods = "CTRL", action = act.SendString "\x118" },
  { key = "9", mods = "CTRL", action = act.SendString "\x119" },
}

return config
