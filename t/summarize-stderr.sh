#!/bin/bash
# Summarize the stderr captured by render.sh <name>; writes and prints
# $HARNESS/render/<name>/stderr-report.txt.
set -euo pipefail
source "$(dirname "$0")/env.sh"
root="$HARNESS/render/${1:?usage: summarize-stderr.sh <name>}"
report="$root/stderr-report.txt"

pages=$(wc -l < "$root/matrix.txt")
errfiles=$(find "$root/stderr" -name '*.err' | sort)
pageerr=$(find "$root/stderr/journal" -name '*.err' 2>/dev/null | wc -l)
nerr=$(printf '%s\n' "$errfiles" | grep -c . || true)
{
    echo "stderr report for $1 ($(sed -n 's/^head: //p' "$root/meta.txt"))"
    echo "pages with stderr: $pageerr of $pages (+ index writer: $([ -f "$root/stderr/index-writer.err" ] && echo yes || echo no))"
    if [ "$nerr" -gt 0 ]; then
        echo "total stderr lines: $(cat $errfiles | wc -l)"
        echo
        echo "unique messages (count, message):"
        cat $errfiles | sort | uniq -c | sort -rn
        echo
        echo "example pages for the top 10 messages:"
        cat $errfiles | sort | uniq -c | sort -rn | head -10 | sed 's/^ *[0-9]* //' | while IFS= read -r msg; do
            echo "  $msg"
            grep -lF -- "$msg" $errfiles | head -3 | sed "s!^$root/stderr/!    !"
        done
    fi
} > "$report"
cat "$report"
