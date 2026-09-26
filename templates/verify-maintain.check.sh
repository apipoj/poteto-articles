#!/usr/bin/env bash
# Daily verify-<app> maintenance trigger.
# Prints one line once per calendar day (in TZ_NAME) at or after 09:00 local,
# and nothing otherwise. The last-fired day lives in state/.verify-maintain-last.
set -u
FM_HOME_DIR=/absolute/path/to/your/firstmate/home  # edit this — checks may not inherit $FM_HOME
TZ_NAME=Asia/Bangkok  # edit this — pick your own timezone
LAST="$FM_HOME_DIR/state/.verify-maintain-last"
today=$(TZ="$TZ_NAME" date +%F)
hour=$(TZ="$TZ_NAME" date +%H)
[ "$hour" -ge 9 ] || exit 0
[ "$(cat "$LAST" 2>/dev/null)" = "$today" ] && exit 0
printf '%s\n' "$today" > "$LAST" || exit 0
printf 'verify-maintain: daily verify-<app> maintenance pass due for %s\n' "$today"
exit 0
