#!/bin/sh
#
# ZFS rewrite runner with time window
# -----------------------------------
# Requirements:
#   - Create a list of directories to process:
#       sudo find /mnt/Data -mindepth 2 -maxdepth 2 -type d | sort > /root/rewrite_targets.txt
#
# Behavior:
#   - Loops indefinitely
#   - Each run takes the first directory from the list, rewrites it, logs progress
#   - Removes that directory from the list
#   - Only runs between 03:00–06:00 (local time)
#

LIST="/root/rewrite_targets.txt"
LOG="/root/zfs-rewrite.log"
POOL="Data"                  # ZFS pool/dataset name
MOUNTPOINT="/mnt/Data"       # mountpoint of the pool/dataset
WINDOW_START=3               # hour (inclusive)
WINDOW_END=6                 # hour (exclusive)

while true; do
    # stop if list is empty
    if [ ! -s "$LIST" ]; then
        echo "[`date -Is`] List is empty, exiting." | tee -a "$LOG"
        exit 0
    fi

    HOUR=$(date +%H)

    if [ "$HOUR" -ge "$WINDOW_START" ] && [ "$HOUR" -lt "$WINDOW_END" ]; then
        DIR=$(head -n1 "$LIST")

        echo "[`date -Is`] START rewriting $DIR" | tee -a "$LOG"
        zfs rewrite -rv "$DIR" 2>&1 | tee -a "$LOG"

        echo "[`date -Is`] zfs list ($POOL):" | tee -a "$LOG"
        zfs list | awk -v pool="$POOL" '$1 == pool {print}' | tee -a "$LOG"

        echo "[`date -Is`] zpool list ($POOL):" | tee -a "$LOG"
        zpool list | awk -v pool="$POOL" '$1 == pool {print}' | tee -a "$LOG"

        echo "[`date -Is`] DONE $DIR" | tee -a "$LOG"

        # remove first line from list
        tail -n +2 "$LIST" > "$LIST.tmp" && mv "$LIST.tmp" "$LIST"
    else
        echo "[`date -Is`] Outside time window (allowed ${WINDOW_START}:00–${WINDOW_END}:00), sleeping 5m" | tee -a "$LOG"
        sleep 300
    fi
done
