#!/bin/bash
i3-msg "$1"
xdotool getactivewindow getwindowgeometry | perl -0ne '/Position: (\d+),(\d+).*Geometry: (\d+)x(\d+)/s; print $1 + $3/2, " ", $2 + $4/2' | xargs -L1 xdotool mousemove
