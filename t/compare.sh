#!/bin/bash
# Byte-compare two snapshots' out/ trees: compare.sh <before> <after>
set -uo pipefail
source "$(dirname "$0")/env.sh"
a="$HARNESS/render/${1:?usage: compare.sh <before> <after>}/out"
b="$HARNESS/render/${2:?usage: compare.sh <before> <after>}/out"
if diff -r "$a" "$b" > "$HARNESS/render/$2/diff-vs-$1.txt"; then
    echo "identical: $1 vs $2 ($(find "$a" -type f | wc -l) files)"
    exit 0
else
    echo "DIFFERENT: $1 vs $2; see $HARNESS/render/$2/diff-vs-$1.txt"
    head -40 "$HARNESS/render/$2/diff-vs-$1.txt"
    exit 1
fi
