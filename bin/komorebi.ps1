# Generate komorebi.json and komorebi.bar.{0..2}.json from CUE
wsl.exe --shell-type login -- make -C ~/repo/dotfiles komorebi
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to generate komorebi configs from CUE"
    exit 1
}

iwr https://raw.githubusercontent.com/LGUG2Z/komorebi-application-specific-configuration/master/applications.yaml -OutFile "$Env:USERPROFILE\.cache\komorebi\applications.yaml" -ProgressAction "SilentlyContinue"

komorebic start -c "$Env:KOMOREBI_CONFIG_HOME\komorebi.json" --whkd --bar --clean-state
komorebic focus-follows-mouse enable -i windows

$left_monitor = "left"
$center_monitor = "center"
$right_monitor = "right"

$logical_monitor_to_named_workspaces = @{
    $left_monitor = @(0..2 | % { "l$_" })
    $center_monitor = @(0..7 | % { "c$_" })
    $right_monitor = @(0..5 | % { "r$_" })
}

$logical_monitor_to_displays = @{
    $center_monitor = @("IOCFFFF-5&2686ec95&0&UID4352", "PHL095C-5&39ed454c&0&UID4354") # , "GSM76F6", "DEL4187", "DEL42A1", "DEL437D", "DELA0F4", "MRG4100"
    $left_monitor   = @("GSM779A-5&2686ec95&0&UID4353", "SDC4178-4&32ada849&0&UID8388688") # , "GSM7799"
    $right_monitor  = @("AUS272A-5&2686ec95&0&UID4355")
}

# Validate consistency between komorebi.json display_index_preferences and script definitions
$komorebi_config = Get-Content "$Env:KOMOREBI_CONFIG_HOME\komorebi.json" | ConvertFrom-Json
$config_device_ids = $komorebi_config.display_index_preferences.PSObject.Properties.Value

# Every device_id in config must match a device name in script
$script_displays = $logical_monitor_to_displays.Values | ForEach-Object { $_ }
foreach ($device_id in $config_device_ids) {
    $matched = $false
    foreach ($display in $script_displays) {
        if ($device_id -eq $display) {
            $matched = $true
            break
        }
    }
    if (-not $matched) {
        Write-Error "device_id $device_id in komorebi.json display_index_preferences does not match any device in logical_monitor_to_displays"
        exit 1
    }
}

# Every device name in script must have a matching device_id in config
foreach ($display in $script_displays) {
    $matched = $false
    foreach ($device_id in $config_device_ids) {
        if ($device_id -eq $display) {
            $matched = $true
            break
        }
    }
    if (-not $matched) {
        Write-Error "Device $display in logical_monitor_to_displays has no matching device_id in komorebi.json display_index_preferences"
        exit 1
    }
}

# Detect connected monitors and classify logical monitors
$monitor_info = komorebic monitor-info | ConvertFrom-Json
$connected_devices = $monitor_info | ForEach-Object { $_.device_id }

$connected_logical_monitors = @()
$disconnected_logical_monitors = @()
foreach ($logical_monitor in $logical_monitor_to_displays.Keys) {
    $is_connected = $false
    foreach ($display in $logical_monitor_to_displays[$logical_monitor]) {
        if ($display -in $connected_devices) {
            $is_connected = $true
            break
        }
    }
    if ($is_connected) {
        $connected_logical_monitors += $logical_monitor
    } else {
        $disconnected_logical_monitors += $logical_monitor
    }
}

# If some logical monitors are missing, pile their workspaces onto a primary connected monitor
if ($disconnected_logical_monitors.Count -gt 0) {
    if ($connected_logical_monitors.Count -eq 0) {
        # No known logical monitors connected; fall back to monitor 0 with all workspaces
        $primary_index = 0
        $all_ws = @()
        foreach ($lm in @($center_monitor, $left_monitor, $right_monitor)) {
            $all_ws += $logical_monitor_to_named_workspaces[$lm]
        }
        Write-Host "No known logical monitors connected, adding all workspaces to monitor 0: $($all_ws -join ', ')"
    } else {
        # Pick primary: prefer center, then left, then right
        $primary = @($center_monitor, $left_monitor, $right_monitor) |
            Where-Object { $_ -in $connected_logical_monitors } |
            Select-Object -First 1

        # Find primary's actual monitor index from monitor-info
        $primary_displays = $logical_monitor_to_displays[$primary]
        $primary_index = -1
        for ($i = 0; $i -lt $monitor_info.Count; $i++) {
            if ($monitor_info[$i].device_id -in $primary_displays) {
                $primary_index = $i
                break
            }
        }

        # Build the workspace list: primary's + all disconnected monitors'
        $all_ws = @($logical_monitor_to_named_workspaces[$primary])
        foreach ($lm in $disconnected_logical_monitors) {
            $ws_names = $logical_monitor_to_named_workspaces[$lm]
            Write-Host "$lm logical monitor not found, adding workspaces to $primary monitor: $($ws_names -join ', ')"
            $all_ws += $ws_names
        }
    }

    komorebic ensure-named-workspaces $primary_index @all_ws
}

# Register initial workspace rules dynamically by workspace name so they work
# regardless of which monitors are connected (workspaces may be piled onto a
# primary monitor by ensure-named-workspaces above). enforce-workspace-rules
# clears already_moved_window_handles and re-evaluates existing windows.
komorebic initial-named-workspace-rule exe WindowsTerminal.exe c0
komorebic initial-named-workspace-rule exe alacritty.exe c1
komorebic initial-named-workspace-rule exe slack.exe l1
komorebic initial-named-workspace-rule exe chrome.exe r0
komorebic initial-named-workspace-rule exe firefox.exe r1
komorebic initial-named-workspace-rule exe Notion.exe r2
komorebic initial-named-workspace-rule exe claude.exe r3
komorebic initial-named-workspace-rule exe Carla.exe r5
komorebic enforce-workspace-rules
