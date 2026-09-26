#!/usr/bin/env bash
# Software-factory intake poll.
# Prints one line per newly `factory`-labelled open issue in the pilot repos,
# and nothing otherwise. Seen issue keys live in state/.factory-intake-seen.
set -u
FM_HOME_DIR=/absolute/path/to/your/firstmate/home  # edit this — checks may not inherit $FM_HOME
STATE_DIR="$FM_HOME_DIR/state"
SEEN="$STATE_DIR/.factory-intake-seen"
REPOS="<owner>/<repo>"
touch "$SEEN" 2>/dev/null || exit 0
for repo in $REPOS; do
  out=$(timeout 20 gh issue list -R "$repo" --state open --label factory --limit 20 \
    --json number,title -q '.[] | "\(.number)\t\(.title)"' 2>/dev/null) || continue
  [ -n "$out" ] || continue
  while IFS=$'\t' read -r num title; do
    key="$repo#$num"
    grep -qxF "$key" "$SEEN" && continue
    printf '%s\n' "$key" >> "$SEEN"
    found="${found:+$found | }https://github.com/$repo/issues/$num $title"
  done <<< "$out"
done
[ -n "${found:-}" ] && printf 'factory-intake: %s\n' "$found"
exit 0
