#!/bin/sh
xrandr --output "$(xgetres monitor.center)" --mode 3840x2160 --rate "$(xgetres monitor.center.rate)" --pos 2160x2160 --rotate normal --primary \
       --output "$(xgetres monitor.left)"   --mode 3840x2160 --rate 60                               --pos 0x480     --rotate right \
       --output "$(xgetres monitor.up)"     --mode 3840x2160 --rate 60                               --pos 2160x0    --rotate inverted \
       --output "$(xgetres monitor.right)"  --mode 3840x2160 --rate 60                               --pos 6000x2160 --rotate normal

echo "i3wm.focus_follows_mouse: yes" | xrdb -merge
i3-msg restart
