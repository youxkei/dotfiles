# Commit message convention

Subject lines start with bracketed tags naming the **directory or tool touched** — the concrete file area (e.g. `flake.nix` → `[nix]`). When a commit touches multiple areas, concatenate all relevant tags.

Examples from history: `[neovim]`, `[nix]` (`flake.nix` / `flake.lock`), `[git]`, `[profile]` (`.profile`), `[bin]` (`bin/*`), `[install]`, `[zsh]`, `[wezterm]`, `[alacritty]`. Combined: `[bin][nix] ...`, `[nix][install][profile] ...`.

The `nvim/` directory is tagged `[neovim]` — always spell the name out in full. This spelling wins over both the directory name and any `[nvim]` that appears in `git log`.

Keep each tag at the directory or tool level and reuse an existing tag from `git log --oneline`; write `[neovim]` in place of `[nvim]`.
