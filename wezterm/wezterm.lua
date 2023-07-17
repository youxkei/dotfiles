local wezterm = require("wezterm")

return {
  default_prog = { "/Windows/System32/wsl.exe", "-u", "youxkei", "--cd", "~", "-e", "zsh", "-l", "-c", "nvim" },
  font = wezterm.font("UDEV Gothic NF"),
  font_size = 8.5,
  -- cell_width = 0.9,
  -- line_height = 0.95,

  enable_tab_bar = false,

  key_map_preference = "Physical",
  keys = {
    -- disable default assignments
    { mods = "CTRL", key = "C", action = wezterm.action.DisableDefaultAssignment },
    { mods = "CTRL", key = "V", action = wezterm.action.DisableDefaultAssignment },
    { mods = "CTRL|SHIFT", key = "C", action = wezterm.action.DisableDefaultAssignment },
    { mods = "CTRL|SHIFT", key = "V", action = wezterm.action.DisableDefaultAssignment },

    -- font size change
    { mods = "CTRL", key = "0", action = wezterm.action.ResetFontSize },
    { mods = "CTRL", key = "=", action = wezterm.action.IncreaseFontSize },
    { mods = "CTRL|SHIFT", key = "=", action = wezterm.action.IncreaseFontSize },
    { mods = "CTRL", key = "-", action = wezterm.action.DecreaseFontSize },

    -- for neovim
    { mods = "CTRL", key = "Tab", action = wezterm.action.SendString("\x11\x09") },
    { mods = "CTRL|SHIFT", key = "Tab", action = wezterm.action.SendString("\x11s\x09") },
    { mods = "CTRL", key = "1", action = wezterm.action.SendString("\x111") },
    { mods = "CTRL", key = "2", action = wezterm.action.SendString("\x112") },
    { mods = "CTRL", key = "3", action = wezterm.action.SendString("\x113") },
    { mods = "CTRL", key = "4", action = wezterm.action.SendString("\x114") },
    { mods = "CTRL", key = "5", action = wezterm.action.SendString("\x115") },
    { mods = "CTRL", key = "6", action = wezterm.action.SendString("\x116") },
    { mods = "CTRL", key = "7", action = wezterm.action.SendString("\x117") },
    { mods = "CTRL", key = "8", action = wezterm.action.SendString("\x118") },
    { mods = "CTRL", key = "9", action = wezterm.action.SendString("\x119") },
  },
}
