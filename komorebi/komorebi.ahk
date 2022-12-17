#SingleInstance Force

Komorebic(args) {
    Run komorebic.exe %args%, , Hide
}

KomorebicTwice(args) {
    Run komorebic.exe %args%, , Hide
    Run komorebic.exe %args%, , Hide
}

LeftMonitor := "1"
CenterMonitor := "0"
RightMonitor := "2"

Komorebic("ensure-workspaces " . LeftMonitor   . " 3")
Komorebic("ensure-workspaces " . CenterMonitor . " 9")
Komorebic("ensure-workspaces " . RightMonitor  . " 15")

Komorebic("mouse-follows-focus enable")
Komorebic("window-hiding-behaviour minimize")
Komorebic("focus-follows-mouse enable -i windows")

Komorebic("watch-configuration enable")
Komorebic("complete-configuration")

$!h::Komorebic("focus left")
$!j::Komorebic("focus down")
$!k::Komorebic("focus up")
$!l::Komorebic("focus right")

$!+h::Komorebic("move left")
$!+j::Komorebic("move down")
$!+k::Komorebic("move up")
$!+l::Komorebic("move right")

$!a::   KomorebicTwice("focus-monitor-workspace " . LeftMonitor . " 0")
$!VKBA::KomorebicTwice("focus-monitor-workspace " . LeftMonitor . " 1")
$!1::   KomorebicTwice("focus-monitor-workspace " . LeftMonitor . " 2")

$!o::   KomorebicTwice("focus-monitor-workspace " . CenterMonitor . " 3")
$!e::   KomorebicTwice("focus-monitor-workspace " . CenterMonitor . " 4")
$!VKBC::KomorebicTwice("focus-monitor-workspace " . CenterMonitor . " 5")
$!VKBE::KomorebicTwice("focus-monitor-workspace " . CenterMonitor . " 6")
$!2::   KomorebicTwice("focus-monitor-workspace " . CenterMonitor . " 7")
$!3::   KomorebicTwice("focus-monitor-workspace " . CenterMonitor . " 8")

$!u::KomorebicTwice("focus-monitor-workspace " . RightMonitor . " 9")
$!i::KomorebicTwice("focus-monitor-workspace " . RightMonitor . " 10")
$!p::KomorebicTwice("focus-monitor-workspace " . RightMonitor . " 11")
$!y::KomorebicTwice("focus-monitor-workspace " . RightMonitor . " 12")
$!4::KomorebicTwice("focus-monitor-workspace " . RightMonitor . " 13")
$!5::KomorebicTwice("focus-monitor-workspace " . RightMonitor . " 14")

$!+a::   Komorebic("send-to-monitor-workspace " . LeftMonitor . " 0")
$!+VKBA::Komorebic("send-to-monitor-workspace " . LeftMonitor . " 1")
$!+1::   Komorebic("send-to-monitor-workspace " . LeftMonitor . " 2")

$!+o::   Komorebic("send-to-monitor-workspace " . CenterMonitor . " 3")
$!+e::   Komorebic("send-to-monitor-workspace " . CenterMonitor . " 4")
$!+VKBC::Komorebic("send-to-monitor-workspace " . CenterMonitor . " 5")
$!+VKBE::Komorebic("send-to-monitor-workspace " . CenterMonitor . " 6")
$!+2::   Komorebic("send-to-monitor-workspace " . CenterMonitor . " 7")
$!+3::   Komorebic("send-to-monitor-workspace " . CenterMonitor . " 8")

$!+u::Komorebic("send-to-monitor-workspace " . RightMonitor . " 9")
$!+i::Komorebic("send-to-monitor-workspace " . RightMonitor . " 10")
$!+p::Komorebic("send-to-monitor-workspace " . RightMonitor . " 11")
$!+y::Komorebic("send-to-monitor-workspace " . RightMonitor . " 12")
$!+4::Komorebic("send-to-monitor-workspace " . RightMonitor . " 13")
$!+5::Komorebic("send-to-monitor-workspace " . RightMonitor . " 14")

$!+Enter::Komorebic("toggle-float")

$!r::Komorebic("retile")
$!+r::Komorebic("reload-configuration")
