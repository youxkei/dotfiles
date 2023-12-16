iwr https://raw.githubusercontent.com/LGUG2Z/komorebi-application-specific-configuration/master/applications.yaml -OutFile "$Env:USERPROFILE\.cache\komorebi\applications.yaml" -ProgressAction "SilentlyContinue"

komorebic start -c "$Env:KOMOREBI_CONFIG_HOME\komorebi.json" --whkd
komorebic focus-follows-mouse enable -i windows

$left_monitor = 1
$center_monitor = 0
$right_monitor = 2

$named_workspaces = @{
    $left_monitor = @(0..2 | % { "l$_" })
    $center_monitor = @(0..7 | % { "c$_" })
    $right_monitor = @(0..5 | % { "r$_" })
}

$monitor_count = gcim -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams | measure | % count

if ($monitor_count -ge 3) {
    foreach ($monitor in $named_workspaces.Keys) {
        komorebic ensure-named-workspaces $monitor $named_workspaces[$monitor]
    }
} else {
    komorebic ensure-named-workspaces $center_monitor $named_workspaces.Values
}
