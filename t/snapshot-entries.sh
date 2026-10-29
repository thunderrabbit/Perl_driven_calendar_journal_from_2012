#!/bin/bash
# Take the one-time frozen copy of the entries tree that every render
# reads from. Taken once so "before" and "after" see the same content.
set -euo pipefail
source "$(dirname "$0")/env.sh"
refuse_if_watcher_running

if [ -e "$HARNESS/entries" ]; then
    echo "snapshot exists at $HARNESS/entries; remove it yourself to retake" >&2
    exit 1
fi
mkdir -p "$HARNESS"
rsync -a --exclude .git/ "$REPO/journal/" "$HARNESS/entries/"
echo "snapshot: $(find "$HARNESS/entries" -type f | wc -l) files in $HARNESS/entries"
