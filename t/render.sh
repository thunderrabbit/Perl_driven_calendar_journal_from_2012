#!/bin/bash
# Render the whole matrix into $HARNESS/render/<name>/.
#   render.sh <name> [--full]
# out/     byte-compared by compare.sh
# stderr/  summarized by summarize-stderr.sh, never diffed
set -euo pipefail
T="$(cd "$(dirname "$0")" && pwd)"
source "$T/env.sh"
refuse_if_watcher_running

name=${1:?usage: render.sh <name> [--full]}
tier=${2:-}
root="$HARNESS/render/$name"
if [ -e "$root" ]; then
    echo "$root exists; pick another name or remove it yourself" >&2
    exit 1
fi
[ -d "$JOURNAL_BASE" ] || { echo "no snapshot at $JOURNAL_BASE; run t/snapshot-entries.sh" >&2; exit 1; }

mkdir -p "$root/out/index" "$root/stderr"
{
    echo "name: $name"
    echo "tier: ${tier:-smoke}"
    echo "head: $(git -C "$REPO" rev-parse HEAD) $(git -C "$REPO" status --porcelain | grep -q . && echo dirty || echo clean)"
    echo "started: $(date -Is)"
} > "$root/meta.txt"

# Index writer. Its rate gate compares time() to this file; under a frozen
# clock a second run would say "Wait an hour", so the file goes first.
rm -f "$JOURNAL_LASTRUN_FILE"
( cd "$REPO" && faketime -f "$FAKE" "$PERL" preformatted_journal_index_writer.pl \
      </dev/null 2>"$root/stderr/index-writer.err" | sort > "$root/out/index/stdout.sorted.txt" )
[ -s "$root/stderr/index-writer.err" ] || rm -f "$root/stderr/index-writer.err"
cp "$JOURNAL_BASE"/preformatted_index_for_*_entries.html "$JOURNAL_BASE"/*_entries.rss \
   "$JOURNAL_BASE"/ls-1R.txt "$root/out/index/"

# journal.pl matrix.
"$T/matrix.sh" $tier > "$root/matrix.txt"
xargs -P "$JOBS" -L 1 "$T/render-one.sh" "$root" < "$root/matrix.txt"

echo "finished: $(date -Is)" >> "$root/meta.txt"
echo "pages: $(wc -l < "$root/matrix.txt")" >> "$root/meta.txt"
"$T/summarize-stderr.sh" "$name" > /dev/null
echo "rendered $(wc -l < "$root/matrix.txt") pages into $root"
sed -n 's/^started: //p; s/^finished: //p' "$root/meta.txt"
