# Commit message convention

Subject lines start with bracketed tags naming the **directory or tool touched**, not the conceptual theme. When a commit touches multiple areas, concatenate all relevant tags.

Examples from history: `[neovim]`, `[nix]` (`flake.nix` / `flake.lock`), `[komorebi]`, `[git]`, `[profile]` (`.profile`), `[bin]` (`bin/*`), `[install]`, `[zsh]`, `[wezterm]`, `[alacritty]`, `[Xresources]`. Combined: `[bin][nix] ...`, `[nix][install][profile] ...`.

Do not invent concept-level tags like `[wsl]`, `[ci]`, `[refactor]`. If unsure, run `git log --oneline` and pick from existing tags.
