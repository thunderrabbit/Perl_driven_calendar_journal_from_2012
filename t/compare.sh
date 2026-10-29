#!/bin/bash
# Byte-compare two snapshots' out/ trees: compare.sh <before> <after>
# Every file in <after> must exist in <before> with identical bytes. When both
# snapshots are the same tier, <before> may not hold extra files either; a
# smoke <after> against a full <before> compares only the pages smoke renders.
set -uo pipefail
source "$(dirname "$0")/env.sh"
a="$HARNESS/render/${1:?usage: compare.sh <before> <after>}"
b="$HARNESS/render/${2:?usage: compare.sh <before> <after>}"
report="$b/diff-vs-$1.txt"
: > "$report"
n=0
while IFS= read -r -d '' f; do
    n=$((n + 1))
    rel="${f#"$b"/out/}"
    if [ ! -f "$a/out/$rel" ]; then
        echo "only in $2: $rel" >> "$report"
    elif ! cmp -s "$a/out/$rel" "$f"; then
        { echo "differs: $rel"; diff "$a/out/$rel" "$f"; } >> "$report"
    fi
done < <(find "$b/out" -type f -print0)
tier_a=$(sed -n 's/^tier: //p' "$a/meta.txt" 2>/dev/null)
tier_b=$(sed -n 's/^tier: //p' "$b/meta.txt" 2>/dev/null)
if [ "$tier_a" = "$tier_b" ]; then
    while IFS= read -r -d '' f; do
        rel="${f#"$a"/out/}"
        [ -f "$b/out/$rel" ] || echo "only in $1: $rel" >> "$report"
    done < <(find "$a/out" -type f -print0)
fi
if [ ! -s "$report" ]; then
    echo "identical: $1 vs $2 ($n files)"
    exit 0
else
    echo "DIFFERENT: $1 vs $2; see $report"
    head -40 "$report"
    exit 1
fi
