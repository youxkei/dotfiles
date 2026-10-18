#Requires -Version 7
# install.sh's counterpart for native Windows: links this repository's configuration into place.
$ErrorActionPreference = 'Stop'

# source path (relative to this script) -> destination path
$links = [ordered]@{
    'nvim'                       = "$env:LOCALAPPDATA\nvim"
    'neovide'                    = "$env:APPDATA\neovide"
    'jj\config.toml'             = "$env:APPDATA\jj\config.toml"
    'git'                        = "$HOME\.config\git"
    'starship.toml'              = "$HOME\.config\starship.toml"
    'bash\.bashrc'               = "$HOME\.bashrc"
    'bash\.bash_profile'         = "$HOME\.bash_profile"
    # Git Bash puts ~/bin on PATH, and bin/trash finds bin/trash.ps1 through this link.
    'bin\trash'                  = "$HOME\bin\trash"
    'bin\claude-jj-snapshot'     = "$HOME\bin\claude-jj-snapshot"

    # One entry per hook, as in install.sh: the guard keeps its state in ~/.claude/hooks/state.
    'claude\hooks\guard-unrecoverable.sh' = "$HOME\.claude\hooks\guard-unrecoverable.sh"

    # One entry per skill, as in install.sh: Claude installs skills of its own into the same directory.
    'claude\skills\jj'           = "$HOME\.claude\skills\jj"
    'claude\skills\jj-open'      = "$HOME\.claude\skills\jj-open"
    'claude\skills\jj-move-diff' = "$HOME\.claude\skills\jj-move-diff"
}

# source path (relative to this script) -> PowerShell profile that dot-sources it
#
# Dot-sourced rather than linked: Documents, where the profile lives, is often moved to a drive that cannot
# hold a symbolic link — OneDrive, or an exFAT one.
$sourced = [ordered]@{
    'profile.ps1' = $PROFILE.CurrentUserCurrentHost
}

# source path (relative to this script) -> destination path, copied once and then edited for this host
$templates = [ordered]@{
    'git\config_host.windows' = "$PSScriptRoot\git\config_host"
}

foreach ($src in @($links.Keys) + @($sourced.Keys)) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $src))) {
        throw "$src does not exist in $PSScriptRoot"
    }
}

foreach ($src in $links.Keys) {
    $target = Join-Path $PSScriptRoot $src
    $dst = $links[$src]
    $existing = Get-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if (-not $existing.LinkType) {
            throw "$dst exists and is not a symbolic link"
        }
        # The link's own Delete(), which removes the link and never what a directory link points at.
        $existing.Delete()
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
    }
    Write-Host "Link $dst -> $target"
    New-Item -ItemType SymbolicLink -Path $dst -Target $target | Out-Null
}

foreach ($src in $sourced.Keys) {
    $line = ". '$(Join-Path $PSScriptRoot $src)'"
    $dst = $sourced[$src]
    if (Test-Path -LiteralPath $dst) {
        if ((Get-Content -Raw -LiteralPath $dst).Trim() -ne $line) {
            throw "$dst exists and does not just dot-source $src"
        }
        Write-Host "$dst already sources $src"
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dst) | Out-Null
        Write-Host "Source $src from $dst"
        Set-Content -LiteralPath $dst -Value $line
    }
}

foreach ($src in $templates.Keys) {
    $dst = $templates[$src]
    if (Test-Path -LiteralPath $dst) {
        Write-Host "$dst already exists. Skip copying"
    } else {
        Write-Host "Copy $src -> $dst"
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $src) -Destination $dst
    }
}
