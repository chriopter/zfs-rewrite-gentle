#!/bin/sh
#
# ZFS rewrite runner with time window (KISS)
#
# Requirements:
#   sudo find /mnt/Data -mindepth 2 -maxdepth 2 -type d | sort > /root/rewrite_targets.txt
#
# Behavior:
#   - Loops indefinitely
#   - Each run takes the first directory from the list, rewrites it, logs progress
#   - Removes that directory from the list
#   - Only runs between 03:00–06:00 (local time)
#

set -eu
PATH=/usr/sbin:/usr/bin:/sbin:/bin

LIST="/root/rewrite_targets.txt"
LOG="/root/zfs-rewrite.log"
POOL="Data"
MOUNTPOINT="/mnt/Data"
WINDOW_START=3   # inclusive
WINDOW_END=6     # exclusive

ts(){ date '+%Y-%m-%d %H:%M:%S'; }
log(){ printf '[%s] %s\n' "$(ts)" "$*" >>"$LOG" 2>/dev/null || printf '[%s] %s\n' "$(ts)" "$*"; }
in_window(){ H="$(date +%H 2>/dev/null || echo 99)"; case "$H" in ''|*[!0-9]*) return 1;; esac; [ "$H" -ge "$WINDOW_START" ] && [ "$H" -lt "$WINDOW_END" ]; }

while :; do
    # stop if list is empty
    if [ ! -s "$LIST" ]; then
        log "List is empty, exiting."
        exit 0
    fi

    if in_window; then
        DIR="$(head -n1 "$LIST")"

        log "START rewriting $DIR"
        OUT="$(zfs rewrite -rv "$DIR" 2>&1 || true)"
        log "$OUT"

        # retry once if EINTR
        echo "$OUT" | grep -q 'Interrupted system call' && {
            log "Retry EINTR $DIR"
            OUT="$(zfs rewrite -rv "$DIR" 2>&1 || true)"
            log "$OUT"
        }

        log "zfs list ($POOL):"
        zfs list -o name,used,avail,refer,mountpoint 2>/dev/null | awk -v p="$POOL" '$1==p{print}' | while read -r l; do log "$l"; done

        log "zpool list ($POOL):"
        zpool list 2>/dev/null | awk -v p="$POOL" '$1==p{print}' | while read -r l; do log "$l"; done

        log "DONE $DIR"

        # remove first line from list
        tail -n +2 "$LIST" > "$LIST.tmp" && mv "$LIST.tmp" "$LIST"
    else
        log "Outside time window (${WINDOW_START}:00–${WINDOW_END}:00), sleeping 5m"
        sleep 300
    fi
done
