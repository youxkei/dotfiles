#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)

# Default XDG_CONFIG_HOME when unset (e.g. macOS does not set it by default).
: ${XDG_CONFIG_HOME:=$HOME/.config}

# Detect environment. These dotfiles target macOS, WSL and native Windows through
# Git Bash. The WSL-only entries wrap Windows executables (ssh.exe, pwsh.exe) and
# the Wayland clipboard, so they must not be installed on plain Linux.
case "$(uname -s)" in
MINGW* | MSYS* | CYGWIN*) IS_WINDOWS=1 ;;
*) IS_WINDOWS=0 ;;
esac

IS_WSL=0
if ((!IS_WINDOWS)) && { grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease 2>/dev/null || [[ -n "${WSL_DISTRO_NAME:-}" ]]; }; then
    IS_WSL=1
fi

# Windows differs in more than adding entries: Neovim reads %LOCALAPPDATA%\nvim and
# jj reads %APPDATA%\jj\config.toml there rather than the XDG paths. Git Bash also
# copies the target of an `ln -s` unless told otherwise, and Neovim and Neovide
# read these paths through Windows, where an MSYS copy is not a symlink.
if ((IS_WINDOWS)); then
    export MSYS=winsymlinks:nativestrict
    LOCALAPPDATA=$(cygpath -u "$LOCALAPPDATA")
    APPDATA=$(cygpath -u "$APPDATA")
    NVIM_DIR=$LOCALAPPDATA/nvim
    JJ_CONFIG=$APPDATA/jj/config.toml
else
    NVIM_DIR=$XDG_CONFIG_HOME/nvim
    JJ_CONFIG=$XDG_CONFIG_HOME/jj/config.toml
fi

# Link $1 (relative to $SCRIPT_DIR) to $2, replacing an existing symlink.
# Everything the script does to one entry happens here, so the list below reads as
# the entries it installs.
link() {
    local src=$SCRIPT_DIR/$1 dst=$2
    if [[ ! -e $src ]]; then
        echo "Error: $1 does not exist in $SCRIPT_DIR" >&2
        exit 1
    fi

    if [[ -e $dst || -L $dst ]]; then
        if [[ ! -L $dst ]]; then
            echo "Error: $dst exists and is not a symlink" >&2
            exit 1
        fi
        rm "$dst"
    else
        mkdir -p "$(dirname "$dst")"
    fi

    echo "Link $dst -> $src"
    ln -s "$src" "$dst"
}

# Entries every platform gets.
link git "$XDG_CONFIG_HOME/git"
link starship.toml "$XDG_CONFIG_HOME/starship.toml"
link katnas "$XDG_CONFIG_HOME/katnas"
link nvim "$NVIM_DIR"

# config.toml alone, not the whole jj directory: jj puts repo-level config in
# <jj config dir>/repos/<hash>/config.toml, keyed by workspace path, and that
# belongs to the individual repo rather than to these dotfiles. Anything
# host-specific goes in <jj config dir>/conf.d/, which jj reads on top of the
# file linked here.
link jj/config.toml "$JJ_CONFIG"

# One entry per skill rather than a link to $HOME/.claude/skills itself: Claude
# installs skills of its own into that same directory, and a link from here
# would leave them nowhere to live. Nothing else under ~/.claude is a candidate
# either, being session state and credentials rather than configuration — the
# same reason the jj repo-level config stays out above.
link claude/skills/jj "$HOME/.claude/skills/jj"
link claude/skills/jj-open "$HOME/.claude/skills/jj-open"
link claude/skills/jj-move-diff "$HOME/.claude/skills/jj-move-diff"

# One entry per hook too, and for a reason of its own beside the one above: the guard keeps the files it
# copies before each Bash call in $HOME/.claude/hooks/state, which a link to the whole directory would put
# inside this repository. Its tests are run from here and need no link.
link claude/hooks/guard-unrecoverable.sh "$HOME/.claude/hooks/guard-unrecoverable.sh"

link bin/claude-jj-snapshot "$HOME/bin/claude-jj-snapshot"

if ((IS_WINDOWS)); then
    link neovide "$APPDATA/neovide"

    link bash/.bashrc "$HOME/.bashrc"
    link bash/.bash_profile "$HOME/.bash_profile"

    # Git Bash puts ~/bin on PATH and runs bin/trash, which finds bin/trash.ps1 through this link.
    # PowerShell and cmd cannot run that extensionless script, and prefer bin/trash.cmd, which runs
    # trash.ps1 beside itself; both are linked into the same directory for that reason.
    link bin/trash "$HOME/bin/trash"
    link bin/trash.cmd "$HOME/bin/trash.cmd"
    link bin/trash.ps1 "$HOME/bin/trash.ps1"
else
    link .profile "$HOME/.profile"
    link .zprofile "$HOME/.zprofile"

    link zsh "$XDG_CONFIG_HOME/zsh"
    link nix "$XDG_CONFIG_HOME/nix"
    link tig "$XDG_CONFIG_HOME/tig"
    link tmux "$XDG_CONFIG_HOME/tmux"
    link procs "$XDG_CONFIG_HOME/procs"
    link sheldon "$XDG_CONFIG_HOME/sheldon"
    link ghostty "$XDG_CONFIG_HOME/ghostty"

    link bin/nvr "$HOME/bin/nvr"
    link bin/notify "$HOME/bin/notify"
    link bin/jj-push "$HOME/bin/jj-push"
    link bin/jj-open "$HOME/bin/jj-open"
fi

# WSL-only entries: bin scripts that wrap Windows executables (ssh.exe, pwsh.exe)
# or the Wayland clipboard (wl-copy), plus the gnome-keyring-start helper and the
# systemd drop-in that auto-unlock the login keyring. bin/pbcopy is here because
# macOS already provides a native pbcopy.
if ((IS_WSL)); then
    link bin/ssh "$HOME/bin/ssh"
    link bin/ssh-add "$HOME/bin/ssh-add"
    link bin/pbcopy "$HOME/bin/pbcopy"
    link bin/wslview "$HOME/bin/wslview"

    link bin/gnome-keyring-start "$HOME/bin/gnome-keyring-start"
    link systemd/user/gnome-keyring-daemon.service.d/unlock.conf "$XDG_CONFIG_HOME/systemd/user/gnome-keyring-daemon.service.d/unlock.conf"
fi

# Copy $1 (relative to $SCRIPT_DIR) to $2 once, to be edited for this host.
copied_templates=()
copy_template() {
    local src=$SCRIPT_DIR/$1 dst=$2
    if [[ -e $dst ]]; then
        echo "$dst already exists. Skip copying"
        return
    fi

    echo "Copy $src -> $dst"
    cp "$src" "$dst"
    copied_templates+=("$dst")
}

if ((IS_WINDOWS)); then
    # The Windows git config lives inside the repository (and is git-ignored) because
    # git/config includes it by a relative path.
    copy_template git/config_host.windows "$SCRIPT_DIR/git/config_host"
else
    copy_template .profile_host.template "$HOME/.profile_host"
fi

if ((${#copied_templates[@]} > 0)); then
    echo
    echo "Please edit following config files for this host:"
    for copied_template in "${copied_templates[@]}"; do
        echo "$copied_template"
    done
fi

# Windows: PowerShell's profile dot-sources profile.ps1 rather than being a link,
# because Documents, where the profile lives, is often moved to a drive that
# cannot hold a symbolic link — OneDrive, or an exFAT one.
if ((IS_WINDOWS)); then
    pwsh_profile=$(pwsh -NoProfile -Command '$PROFILE.CurrentUserCurrentHost')
    line=". '$(cygpath -w "$SCRIPT_DIR/profile.ps1")'"
    if [[ -e $pwsh_profile ]]; then
        existing=$(<"$pwsh_profile")
        existing=${existing#"${existing%%[![:space:]]*}"}
        existing=${existing%"${existing##*[![:space:]]}"}
        if [[ $existing != "$line" ]]; then
            echo "Error: $pwsh_profile exists and does not just dot-source profile.ps1" >&2
            exit 1
        fi
        echo "$pwsh_profile already sources profile.ps1"
    else
        mkdir -p "$(dirname "$pwsh_profile")"
        printf '%s\n' "$line" >"$pwsh_profile"
        echo "Source profile.ps1 from $pwsh_profile"
    fi
fi

# WSL: when the gnome-keyring-daemon user unit is available, enable linger and
# wire it into default.target so the login keyring is unlocked automatically by
# the systemd user service (bin/gnome-keyring-start). Skipped when gnome-keyring
# is not installed here (the unlock.conf drop-in has no base unit to extend).
if ((IS_WSL)) && systemctl --user cat gnome-keyring-daemon.service >/dev/null 2>&1; then
    if [[ "$(loginctl show-user "$USER" --property=Linger 2>/dev/null)" != "Linger=yes" ]]; then
        echo "Enable linger for $USER (requires sudo)"
        sudo loginctl enable-linger "$USER"
    else
        echo "Linger already enabled for $USER"
    fi

    echo "Reload systemd user manager"
    systemctl --user daemon-reload

    echo "Wire gnome-keyring-daemon.service into default.target"
    systemctl --user add-wants default.target gnome-keyring-daemon.service
fi
