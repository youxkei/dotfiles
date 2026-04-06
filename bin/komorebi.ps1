# Generate komorebi.json from CUE
wsl.exe --shell-type login -- cue export ~/repo/dotfiles/komorebi/komorebi.cue -o ~/repo/dotfiles/komorebi/komorebi.json --force
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to generate komorebi.json from CUE"
    exit 1
}

iwr https://raw.githubusercontent.com/LGUG2Z/komorebi-application-specific-configuration/master/applications.yaml -OutFile "$Env:USERPROFILE\.cache\komorebi\applications.yaml" -ProgressAction "SilentlyContinue"

komorebic start -c "$Env:KOMOREBI_CONFIG_HOME\komorebi.json" --whkd --bar --clean-state
komorebic focus-follows-mouse enable -i windows

$left_monitor = 1
$center_monitor = 0
$right_monitor = 2

$logical_monitor_to_named_workspaces = @{
    $left_monitor = @(0..2 | % { "l$_" })
    $center_monitor = @(0..7 | % { "c$_" })
    $right_monitor = @(0..5 | % { "r$_" })
}

$logical_monitor_to_displays = @{
    $center_monitor = @("IOCFFFF-5&2686ec95&0&UID4352") # , "GSM76F6", "DEL4187", "PHL095C", "DEL42A1", "DEL437D", "DELA0F4", "MRG4100"
    $left_monitor   = @("GSM779A-5&2686ec95&0&UID4353") # , "GSM7799", "SDC4178"
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

# Detect connected monitors and fallback missing logical monitors to center display
$monitor_info = komorebic monitor-info | ConvertFrom-Json
$connected_devices = $monitor_info | ForEach-Object { $_.device_id }

$fallback_ws = @()
foreach ($logical_monitor in $logical_monitor_to_displays.Keys) {
    $displays = $logical_monitor_to_displays[$logical_monitor]
    $connected = $false

    foreach ($display in $displays) {
        if ($display -in $connected_devices) {
            $connected = $true
            break
        }
    }

    if (-not $connected) {
        $ws_names = $logical_monitor_to_named_workspaces[$logical_monitor]
        Write-Host "Logical monitor $logical_monitor not found, adding workspaces to fallback display: $($ws_names -join ', ')"
        $fallback_ws += $ws_names
    }
}

if ($fallback_ws.Count -gt 0) {
    $all_ws = $logical_monitor_to_named_workspaces[$center_monitor] + $fallback_ws
    komorebic ensure-named-workspaces 0 @all_ws
}
