#SingleInstance Force

Komorebic(args) {
    Run komorebic.exe %args%, , Hide
}

KomorebicTwice(args) {
    Run komorebic.exe %args%, , Hide
    Run komorebic.exe %args%, , Hide
}

Komorebic("focus-follows-mouse enable -i windows")
Komorebic("window-hiding-behaviour hide")

Komorebic("ensure-workspaces 0 9")
Komorebic("ensure-workspaces 1 6")
;Komorebic("ensure-workspaces 0 14")

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

$!a::   KomorebicTwice("focus-monitor-workspace 1 0")
$!o::   KomorebicTwice("focus-monitor-workspace 1 1")
$!e::   KomorebicTwice("focus-monitor-workspace 1 2")
$!VKBA::KomorebicTwice("focus-monitor-workspace 1 3")
$!VKBC::KomorebicTwice("focus-monitor-workspace 1 4")
$!VKBE::KomorebicTwice("focus-monitor-workspace 1 5")
$!1::   KomorebicTwice("focus-monitor-workspace 1 6")
$!2::   KomorebicTwice("focus-monitor-workspace 1 7")
$!3::   KomorebicTwice("focus-monitor-workspace 1 8")

$!u::KomorebicTwice("focus-monitor-workspace 0 0")
$!i::KomorebicTwice("focus-monitor-workspace 0 1")
$!p::KomorebicTwice("focus-monitor-workspace 0 2")
$!y::KomorebicTwice("focus-monitor-workspace 0 3")
$!4::KomorebicTwice("focus-monitor-workspace 0 4")
$!5::KomorebicTwice("focus-monitor-workspace 0 5")

;$!a::   KomorebicTwice("focus-monitor-workspace 0 0")
;$!o::   KomorebicTwice("focus-monitor-workspace 0 1")
;$!e::   KomorebicTwice("focus-monitor-workspace 0 2")
;$!VKBA::KomorebicTwice("focus-monitor-workspace 0 3")
;$!VKBC::KomorebicTwice("focus-monitor-workspace 0 4")
;$!VKBE::KomorebicTwice("focus-monitor-workspace 0 5")
;$!1::   KomorebicTwice("focus-monitor-workspace 0 6")
;$!2::   KomorebicTwice("focus-monitor-workspace 0 7")
;$!3::   KomorebicTwice("focus-monitor-workspace 0 8")
;$!u::   KomorebicTwice("focus-monitor-workspace 0 9")
;$!i::   KomorebicTwice("focus-monitor-workspace 0 10")
;$!p::   KomorebicTwice("focus-monitor-workspace 0 11")
;$!y::   KomorebicTwice("focus-monitor-workspace 0 12")
;$!4::   KomorebicTwice("focus-monitor-workspace 0 13")
;$!5::   KomorebicTwice("focus-monitor-workspace 0 14")

$!+a::   Komorebic("send-to-monitor-workspace 1 0")
$!+o::   Komorebic("send-to-monitor-workspace 1 1")
$!+e::   Komorebic("send-to-monitor-workspace 1 2")
$!+VKBA::Komorebic("send-to-monitor-workspace 1 3")
$!+VKBC::Komorebic("send-to-monitor-workspace 1 4")
$!+VKBE::Komorebic("send-to-monitor-workspace 1 5")
$!+1::   Komorebic("send-to-monitor-workspace 1 6")
$!+2::   Komorebic("send-to-monitor-workspace 1 7")
$!+3::   Komorebic("send-to-monitor-workspace 1 8")

$!+u::Komorebic("send-to-monitor-workspace 0 0")
$!+i::Komorebic("send-to-monitor-workspace 0 1")
$!+p::Komorebic("send-to-monitor-workspace 0 2")
$!+y::Komorebic("send-to-monitor-workspace 0 3")
$!+4::Komorebic("send-to-monitor-workspace 0 4")
$!+5::Komorebic("send-to-monitor-workspace 0 5")

;$!+a::   Komorebic("send-to-monitor-workspace 0 0")
;$!+o::   Komorebic("send-to-monitor-workspace 0 1")
;$!+e::   Komorebic("send-to-monitor-workspace 0 2")
;$!+VKBA::Komorebic("send-to-monitor-workspace 0 3")
;$!+VKBC::Komorebic("send-to-monitor-workspace 0 4")
;$!+VKBE::Komorebic("send-to-monitor-workspace 0 5")
;$!+1::   Komorebic("send-to-monitor-workspace 0 6")
;$!+2::   Komorebic("send-to-monitor-workspace 0 7")
;$!+3::   Komorebic("send-to-monitor-workspace 0 8")
;$!+u::   Komorebic("send-to-monitor-workspace 0 9")
;$!+i::   Komorebic("send-to-monitor-workspace 0 10")
;$!+p::   Komorebic("send-to-monitor-workspace 0 11")
;$!+y::   Komorebic("send-to-monitor-workspace 0 12")
;$!+4::   Komorebic("send-to-monitor-workspace 0 13")
;$!+5::   Komorebic("send-to-monitor-workspace 0 14")

$!+Enter::Komorebic("toggle-float")

$!r::Komorebic("reload-configuration")
$!+r::Komorebic("retile")
