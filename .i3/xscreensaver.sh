#!/bin/bash
exec >/tmp/xscreen.log
exec 2>&1
xscreensaver-command --restart && sleep 1s && xscreensaver-command --lock
