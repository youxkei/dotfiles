#!/bin/sh
jack_control start
sleep 1s
jack_disconnect 'PulseAudio JACK Sink:front-left' system:playback_1
jack_disconnect 'PulseAudio JACK Sink:front-right' system:playback_2
jack_disconnect system:capture_1 'PulseAudio JACK Source:front-left'
jack_disconnect system:capture_2 'PulseAudio JACK Source:front-right'

pacmd unload-module module-virtual-surround-sink
pacmd load-module module-virtual-surround-sink sink_name=surround sink_properties=device.description=surround master=jack_out hrir=$HOME/repo/dotfiles/jack/hrir-1003.wav
pacmd set-default-sink surround
pacmd set-default-source jack_in

chrt 95 carla ~/repo/dotfiles/jack/patch.carxp
