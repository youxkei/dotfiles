#SingleInstance Force

#Include %A_ScriptDir%\komorebi.generated.ahk

Komorebic(args) {
    Run komorebic.exe %args%, , Hide
}

LeftMonitor := "1"
CenterMonitor := "0"
RightMonitor := "2"

Komorebic("ensure-named-workspaces " . LeftMonitor   . " l0 l1 l2")
Komorebic("ensure-named-workspaces " . CenterMonitor . " c0 c1 c2 c3 c4 c5")
Komorebic("ensure-named-workspaces " . RightMonitor  . " r0 r1 r2 r3 r4 r5")

Komorebic("identify-tray-application exe Carla.exe")
Komorebic("identify-tray-application exe qjackctl.exe")
Komorebic("identify-tray-application exe jackd.exe")

Komorebic("mouse-follows-focus enable")
Komorebic("focus-follows-mouse enable -i windows")
Komorebic("window-hiding-behaviour cloak")
Komorebic("cross-monitor-move-behaviour insert")

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

$!a::   Komorebic("focus-named-workspace l0")
$!VKBA::Komorebic("focus-named-workspace l1")
$!1::   Komorebic("focus-named-workspace l2")

$!o::   Komorebic("focus-named-workspace c0")
$!e::   Komorebic("focus-named-workspace c1")
$!VKBC::Komorebic("focus-named-workspace c2")
$!VKBE::Komorebic("focus-named-workspace c3")
$!2::   Komorebic("focus-named-workspace c4")
$!3::   Komorebic("focus-named-workspace c5")

$!u::Komorebic("focus-named-workspace r0")
$!i::Komorebic("focus-named-workspace r1")
$!p::Komorebic("focus-named-workspace r2")
$!y::Komorebic("focus-named-workspace r3")
$!4::Komorebic("focus-named-workspace r4")
$!5::Komorebic("focus-named-workspace r5")

$!+a::   Komorebic("send-to-named-workspace l0")
$!+VKBA::Komorebic("send-to-named-workspace l1")
$!+1::   Komorebic("send-to-named-workspace l2")

$!+o::   Komorebic("send-to-named-workspace c0")
$!+e::   Komorebic("send-to-named-workspace c1")
$!+VKBC::Komorebic("send-to-named-workspace c2")
$!+VKBE::Komorebic("send-to-named-workspace c3")
$!+2::   Komorebic("send-to-named-workspace c4")
$!+3::   Komorebic("send-to-named-workspace c5")

$!+u::Komorebic("send-to-named-workspace r0")
$!+i::Komorebic("send-to-named-workspace r1")
$!+p::Komorebic("send-to-named-workspace r2")
$!+y::Komorebic("send-to-named-workspace r3")
$!+4::Komorebic("send-to-named-workspace r4")
$!+5::Komorebic("send-to-named-workspace r5")

$!+Enter::Komorebic("toggle-float")
$!s::Komorebic("toggle-pause")
$!m::Komorebic("manage")

$!r::Komorebic("retile")
$!+r::Komorebic("reload-configuration")
