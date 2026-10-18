# Git Bash on native Windows, where nvim's terminal runs bash in place of zsh.

# Claude Code's Bash tool runs commands in Git Bash too, and a prompt is no use to it.
[[ $- == *i* ]] || return

command -v starship >/dev/null && eval "$(starship init bash)"
