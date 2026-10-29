#!/bin/bash
# Summarize the stderr captured by render.sh <name>; writes and prints
# $HARNESS/render/<name>/stderr-report.txt.
set -euo pipefail
source "$(dirname "$0")/env.sh"
root="$HARNESS/render/${1:?usage: summarize-stderr.sh <name>}"
report="$root/stderr-report.txt"

# With warnings on, most pages write stderr, so the .err list is far too long
# for a command line: it is always streamed through xargs -0.
errs() { find "$root/stderr" -name '*.err' -print0 | sort -z; }
pages=$(wc -l < "$root/matrix.txt")
pageerr=$(find "$root/stderr/journal" -name '*.err' 2>/dev/null | wc -l)
nerr=$(errs | tr -cd '\0' | wc -c)
{
    echo "stderr report for $1 ($(sed -n 's/^head: //p' "$root/meta.txt"))"
    echo "pages with stderr: $pageerr of $pages (+ index writer: $([ -f "$root/stderr/index-writer.err" ] && echo yes || echo no))"
    if [ "$nerr" -gt 0 ]; then
        counts=$(errs | xargs -0 cat | sort | uniq -c | sort -rn)
        echo "total stderr lines: $(errs | xargs -0 cat | wc -l)"
        echo
        echo "unique messages (count, message):"
        echo "$counts"
        echo
        echo "example pages for the top 10 messages:"
        # head closing a pipe early would trip pipefail, so head reads from
        # here-strings and variables, never from a live pipe.
        while IFS= read -r msg; do
            echo "  $msg"
            ex=$(errs | xargs -0 grep -lF -- "$msg" | sort || true)
            head -3 <<< "$ex" | sed "s!^$root/stderr/!    !"
        done < <(head -10 <<< "$counts" | sed 's/^ *[0-9]* //')
    fi
} > "$report"
cat "$report"
