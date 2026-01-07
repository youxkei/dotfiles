iwr https://raw.githubusercontent.com/LGUG2Z/komorebi-application-specific-configuration/master/applications.yaml -OutFile "$Env:USERPROFILE\.cache\komorebi\applications.yaml" -ProgressAction "SilentlyContinue"

komorebic start -c "$Env:KOMOREBI_CONFIG_HOME\komorebi.json" --whkd
komorebic focus-follows-mouse enable -i windows

$left_monitor = 1
$center_monitor = 0
$right_monitor = 2

$monitors = @($left_monitor, $center_monitor, $right_monitor)

$named_workspaces = @{
    $left_monitor = @(0..2 | % { "l$_" })
    $center_monitor = @(0..7 | % { "c$_" })
    $right_monitor = @(0..5 | % { "r$_" })
}

# Display to monitors mapping
$display_monitors = @{
    "IOCFFFF-9&37b11675&0&UID262402" = @($center_monitor)
    "GSM76F6-5&39ed454c&0&UID4354" = @($center_monitor)
    "DEL4187-5&39ed454c&0&UID4354" = @($center_monitor)
    "PHL095C-5&39ed454c&0&UID4354" = @($center_monitor)
    "DEL42A1-5&39ed454c&0&UID4354" = @($center_monitor)
    "DEL437D-5&39ed454c&0&UID4354" = @($center_monitor)
    "DELA0F4-5&39ed454c&0&UID4354" = @($center_monitor)
    "MRG4100-5&39ed454c&0&UID4352" = @($center_monitor)
    "DEL437D-5&39ed454c&0&UID4352" = @($center_monitor)

    "GSM7799-9&37b11675&0&UID262405" = @($left_monitor)
    "SDC4178-4&32ada849&0&UID8388688" = @($left_monitor)

    "AUS272A-9&37b11675&0&UID262406" = @($right_monitor)
}

# Read display indices from komorebi.json
$komorebi_config = Get-Content "$Env:KOMOREBI_CONFIG_HOME\komorebi.json" | ConvertFrom-Json
$display_index_preferences = $komorebi_config.display_index_preferences

# Create display indices mapping from config
$display_indices = @{}
foreach ($index in $display_index_preferences.PSObject.Properties.Name) {
    $display_id = $display_index_preferences.$index
    $display_indices[$display_id] = [int]$index
}

# Get monitor info from komorebic
$monitor_info_json = komorebic monitor-info
$monitor_info = $monitor_info_json | ConvertFrom-Json

# Collect displays that are present and have valid mappings
$present_displays = @()
foreach ($display_id in $monitor_info.PSObject.Properties.Name) {
    if ($display_monitors.ContainsKey($display_id) -and $display_indices.ContainsKey($display_id)) {
        $present_displays += [PSCustomObject]@{
            DisplayId = $display_id
            ConfiguredIndex = $display_indices[$display_id]
        }
    }
}

$present_displays = $present_displays | Sort-Object -Property ConfiguredIndex

# Check which monitor indices are actually used in present displays
$used_monitors = @{}
foreach ($display in $present_displays) {
    $monitor_indices = $display_monitors[$display.DisplayId]
    foreach ($monitor_index in $monitor_indices) {
        $used_monitors[$monitor_index] = $true
    }
}

# Find the first available display for fallback
$fallback_display = $null
if ($present_displays.Count -gt 0) {
    $fallback_display = $present_displays[0].DisplayId
}

foreach ($monitor in $monitors) {
    if (-not $used_monitors.ContainsKey($monitor) -and $fallback_display) {
        # Monitor is not used, assign to fallback display
        $monitor_name = switch ($monitor) {
            $center_monitor { "center monitor" }
            $left_monitor { "left monitor" }
            $right_monitor { "right monitor" }
            default { "monitor index $monitor" }
        }
        Write-Host "$monitor_name not found in connected displays, assigning its workspaces to fallback display $fallback_display"
        $display_monitors[$fallback_display] += $monitor
    }
}

$compacted_index = 0
foreach ($display in $present_displays) {
    $display_id = $display.DisplayId
    $monitor_indices = $display_monitors[$display_id]

    # Collect all workspaces for this display
    $all_workspaces = @()
    foreach ($monitor_index in $monitor_indices) {
        if ($named_workspaces.ContainsKey($monitor_index)) {
            $all_workspaces += $named_workspaces[$monitor_index]
        }
    }

    # Call ensure-named-workspaces once with all workspaces
    if ($all_workspaces.Count -gt 0) {
        Write-Host "Ensuring workspaces for display ${compacted_index}: $($all_workspaces -join ', ')"
        komorebic ensure-named-workspaces $compacted_index $all_workspaces
    }

    $compacted_index++
}
