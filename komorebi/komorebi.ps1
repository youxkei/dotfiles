stop-process -Name whkd
start-process whkd -WindowStyle hidden

. $PSScriptRoot\komorebi.generated.ps1

$left_monitor = 2
$center_monitor = 0
$right_monitor = 1

komorebic monitor-index-preference -- $center_monitor     0     0 3840 2160
komorebic monitor-index-preference -- $right_monitor   3840     0 3840 2160
komorebic monitor-index-preference -- $left_monitor   -2160 -1680 2160 3840

komorebic ensure-named-workspaces $left_monitor   l0 l1 l2
komorebic ensure-named-workspaces $center_monitor c0 c1 c2 c3 c4 c5 c6 c7
komorebic ensure-named-workspaces $right_monitor  r0 r1 r2 r3 r4 r5

komorebic identify-tray-application exe Carla.exe
komorebic identify-tray-application exe qjackctl.exe
komorebic identify-tray-application exe jackd.exe
komorebic identify-tray-application exe iTunes.exe

komorebic float-rule exe ShellExperienceHost.exe
komorebic float-rule exe komorebi.exe
komorebic float-rule exe DeepL.exe
komorebic float-rule exe steam.exe
komorebic float-rule exe th15.exe
komorebic float-rule exe steamwebhelper.exe

komorebic manage-rule exe VBAudioMatrix_x64.exe

komorebic active-window-border enable
komorebic active-window-border-colour 232 145 45

komorebic mouse-follows-focus enable
komorebic focus-follows-mouse enable -i windows
komorebic window-hiding-behaviour cloak
komorebic cross-monitor-move-behaviour insert

komorebic watch-configuration enable
komorebic complete-configuration
