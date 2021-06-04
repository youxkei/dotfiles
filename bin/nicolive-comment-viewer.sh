#!/bin/bash
set -eu

nicolive-comments -j -f "$@" \
    | tee \
        >(jq --unbuffered -r .chat.content \
            | ruby -r json -ple '
                $stdout.sync = true
                _, command, body = /^\/(\w+)(?: (.+))?$/.match($_).to_a

                if command then
                    $_ = body

                    case command
                    when "nicoad" then
                        $_ = JSON.parse(body)["message"]
                    when "spi" then
                        $_ = JSON.parse(body)
                    when "info" then
                        _, body = /^\d+ (.+)$/.match(body).to_a
                        $_ = body
                    when "clear" then
                        $_ = ""
                    end
                else
                    $_.gsub!(/[^\p{In_Hiragana}\p{In_Katakana}\p{In_CJK_Unified_Ideographs}\p{Number}\p{Letter}$＄%％&＆~\/〜\-=＝]/, " ")
                    $_.gsub!(/・| +/, " ")
                end
            ' \
            | rg -o --line-buffered '^.{0,30}' \
            | tts --player "mpv --audio-device=pulse/tts_sink" -l ja-JP --voice ja-JP-Wavenet-B -s 1.2 --pitch 2.5 -g 10.0 \
        ) \
    | jq -r '"\(.chat.date): \(.chat.user_id): \(.chat.content)"'
