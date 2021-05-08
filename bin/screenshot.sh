#!/bin/sh
set -e

FILE="$(mktemp --suffix=.png)"
trap 'rm $FILE' EXIT

maim "$@" "$FILE"
gyazo "$FILE"
