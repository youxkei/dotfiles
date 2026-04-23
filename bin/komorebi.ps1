# Generate komorebi.json and komorebi.bar.{0..2}.json from CUE
wsl.exe --shell-type login -- make -C ~/repo/dotfiles komorebi
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to generate komorebi configs from CUE"
    exit 1
}

iwr https://raw.githubusercontent.com/LGUG2Z/komorebi-application-specific-configuration/master/applications.yaml -OutFile "$Env:USERPROFILE\.cache\komorebi\applications.yaml" -ProgressAction "SilentlyContinue"

komorebic start -c "$Env:KOMOREBI_CONFIG_HOME\komorebi.json" --whkd --clean-state
komorebic focus-follows-mouse enable -i windows

$left_monitor = "left"
$center_monitor = "center"
$right_monitor = "right"

$logical_monitors_json = wsl.exe --shell-type login -- make --no-print-directory -C ~/repo/dotfiles komorebi-logical-monitors
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to export logicalMonitors from CUE"
    exit 1
}
$logical_monitors = $logical_monitors_json | ConvertFrom-Json

# Detect connected monitors and classify logical monitors. Collect both device_id
# and (valid) serial_number_id so matches against $logical_monitors.*.device_ids work
# whether the script uses a hardware device_id or a serial_number_id. Do NOT trim
# serial_number_id: komorebi compares display_index_preferences against the raw
# Windows-reported value, so trailing whitespace must be preserved here too.
$monitor_info = komorebic monitor-info | ConvertFrom-Json
$connected_devices = $monitor_info | ForEach-Object {
    $_.device_id
    if ($_.serial_number_id -and $_.serial_number_id.Trim() -ne "0000000000000") {
        $_.serial_number_id
    }
}

$connected_logical_monitors = @()
$disconnected_logical_monitors = @()
foreach ($lm in $logical_monitors.PSObject.Properties.Name) {
    $is_connected = $false
    foreach ($device_id in $logical_monitors.$lm.device_ids) {
        if ($device_id -in $connected_devices) {
            $is_connected = $true
            break
        }
    }
    if ($is_connected) {
        $connected_logical_monitors += $lm
    } else {
        $disconnected_logical_monitors += $lm
    }
}

# If some logical monitors are missing, pile their workspaces onto a primary connected monitor
if ($disconnected_logical_monitors.Count -gt 0) {
    if ($connected_logical_monitors.Count -eq 0) {
        # No known logical monitors connected; fall back to monitor 0 with all workspaces
        $primary_index = 0
        $all_ws = @()
        foreach ($lm in @($center_monitor, $left_monitor, $right_monitor)) {
            $all_ws += $logical_monitors.$lm.workspaces
        }
        Write-Host "No known logical monitors connected, adding all workspaces to monitor 0: $($all_ws -join ', ')"
    } else {
        # Pick primary: prefer center, then left, then right
        $primary = @($center_monitor, $left_monitor, $right_monitor) |
            Where-Object { $_ -in $connected_logical_monitors } |
            Select-Object -First 1

        # Find primary's actual monitor index from monitor-info. Match against both
        # device_id and serial_number_id so a logical monitor defined by its serial
        # (e.g. 207NTCZA4323) still resolves to an index.
        $primary_device_ids = $logical_monitors.$primary.device_ids
        $primary_index = -1
        for ($i = 0; $i -lt $monitor_info.Count; $i++) {
            $ids = @($monitor_info[$i].device_id)
            if ($monitor_info[$i].serial_number_id -and $monitor_info[$i].serial_number_id.Trim() -ne "0000000000000") {
                $ids += $monitor_info[$i].serial_number_id
            }
            $matched = $false
            foreach ($id in $ids) {
                if ($id -in $primary_device_ids) {
                    $matched = $true
                    break
                }
            }
            if ($matched) {
                $primary_index = $i
                break
            }
        }

        # Build the workspace list: primary's + all disconnected monitors'
        $all_ws = @($logical_monitors.$primary.workspaces)
        foreach ($lm in $disconnected_logical_monitors) {
            $ws_names = $logical_monitors.$lm.workspaces
            Write-Host "$lm logical monitor not found, adding workspaces to $primary monitor: $($ws_names -join ', ')"
            $all_ws += $ws_names
        }
    }

    komorebic ensure-named-workspaces $primary_index @all_ws
}

# When the left logical monitor resolves to 207NTCZA4323, use Rows layout for l0-l2
if ("207NTCZA4323" -in $connected_devices) {
    komorebic named-workspace-layout l0 rows
    komorebic named-workspace-layout l1 rows
    komorebic named-workspace-layout l2 rows
}

# Register initial workspace rules dynamically by workspace name so they work
# regardless of which monitors are connected (workspaces may be piled onto a
# primary monitor by ensure-named-workspaces above). enforce-workspace-rules
# clears already_moved_window_handles and re-evaluates existing windows.
komorebic initial-named-workspace-rule exe WindowsTerminal.exe c0
komorebic initial-named-workspace-rule exe alacritty.exe c1
komorebic initial-named-workspace-rule exe obs64.exe l0
komorebic initial-named-workspace-rule exe slack.exe l1
komorebic initial-named-workspace-rule exe Discord.exe l2
komorebic initial-named-workspace-rule exe chrome.exe r0
komorebic initial-named-workspace-rule exe firefox.exe r1
komorebic initial-named-workspace-rule exe Notion.exe r2
komorebic initial-named-workspace-rule exe claude.exe r3
komorebic initial-named-workspace-rule exe Carla.exe r5
komorebic enforce-workspace-rules
