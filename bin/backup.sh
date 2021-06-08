#!/bin/bash
exec >/tmp/backup.log 2>&1
set -eux

MONTH_AGO=$(date -d "-1 month" +%s)

mnt=$(mktemp -d)
mount /dev/sda3 "$mnt"
cd "$mnt"

trap 'cd / && umount "$mnt" && rmdir "$mnt"' EXIT ERR

btrfs subvolume snapshot @ snapshots/@/"$(date -Is)"

cd snapshots/@
for snapshot in *; do
    if [[ "$(date -d "$snapshot" +%s)" -lt "$MONTH_AGO" ]]; then
        btrfs subvolume delete "$snapshot"
        echo deleted old snapshot: "$snapshot"
    fi
done
