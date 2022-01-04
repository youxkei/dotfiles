#!/bin/sh
set -x
pactl unload-module module-null-sink

pactl load-module module-null-sink sink_name=sink        object.linger=1 media.class=Audio/Sink           channel_map=FL,FR
pactl load-module module-null-sink sink_name=direct_sink object.linger=1 media.class=Audio/Sink           channel_map=FL,FR
pactl load-module module-null-sink sink_name=tts_sink    object.linger=1 media.class=Audio/Sink           channel_map=FL,FR
pactl load-module module-null-sink sink_name=stream_sink object.linger=1 media.class=Audio/Sink           channel_map=FL,FR
pactl load-module module-null-sink sink_name=discord_sink object.linger=1 media.class=Audio/Sink           channel_map=FL,FR

pactl load-module module-null-sink sink_name=source        object.linger=1 media.class=Audio/Source/Virtual channel_map=FL,FR
pactl load-module module-null-sink sink_name=stream_source object.linger=1 media.class=Audio/Source/Virtual channel_map=FL,FR
pactl load-module module-null-sink sink_name=discord_source object.linger=1 media.class=Audio/Source/Virtual channel_map=FL,FR

pactl set-default-sink sink
pactl set-default-source source

if [ -f ~/pCloudDrive/carla/patch_linux_"$USER".carxp ]; then
    PIPEWIRE_LATENCY=64/48000 pw-jack carla ~/pCloudDrive/carla/patch_linux_"$USER".carxp
fi
