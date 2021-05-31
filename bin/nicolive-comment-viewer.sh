#!/bin/bash
set -eu

nicolive-comments -j -f "$@" \
    | tee \
        >(jq --unbuffered -r .chat.content \
            | ruby -ple '
                $stdout.sync = true
                $_.gsub!(/[^\p{In_Hiragana}\p{In_Katakana}\p{In_CJK_Unified_Ideographs}\p{Number}\p{Letter}$＄%％&＆~\/〜\-=＝]/, " ")
                $_.gsub!(/・| +/, " ")
            ' \
            | rg -o --line-buffered '^.{0,30}' \
            | tts -l ja-JP --voice ja-JP-Wavenet-B -s 1.2 --pitch 2.5 -g 10.0 \
        ) \
    | jq -r '"\(.chat.date): \(.chat.user_id): \(.chat.content)"'
