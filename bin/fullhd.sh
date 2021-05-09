#!/bin/sh
xrandr --newmode fullhd $(xgetres monitor.center.fullhd_mode_line)
xrandr --addmode "$(xgetres monitor.center)" fullhd
xrandr --output "$(xgetres monitor.center)" --mode fullhd    --rate "$(xgetres monitor.center.rate)" --pos 2160x2160 --rotate normal \
       --output "$(xgetres monitor.left)"   --mode 3840x2160 --rate 60                               --pos 0x480     --rotate right \
       --output "$(xgetres monitor.up)"     --mode 3840x2160 --rate 60                               --pos 2160x0    --rotate inverted \
       --output "$(xgetres monitor.right)"  --mode 3840x2160 --rate 60                               --pos 4080x2160 --rotate normal --primary \
       --output "$(xgetres monitor.hdmi)" --off


echo "i3wm.focus_follows_mouse: no" | xrdb -merge
i3-msg restart
