#!/bin/bash
# Fetch each query in live-urls.txt from robnugen.com, render the same
# parameters locally, normalize the known time-dependent lines, diff.
# A sanity check that the local render reproduces production; the
# oracle for the pass is still before/after.
set -uo pipefail
T="$(cd "$(dirname "$0")" && pwd)"
source "$T/env.sh"
refuse_if_watcher_running
[ -d "$JOURNAL_BASE/." ] || { echo "no snapshot at $JOURNAL_BASE" >&2; exit 1; }
[ -f "$JOURNAL_BASE/preformatted_index_for_all_entries.html" ] || {
    echo "no index files in $JOURNAL_BASE; run t/render.sh once first" >&2; exit 1; }

work="$HARNESS/live/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$work"

normalize() {
    sed -E \
        -e 's/Rob is [0-9,]+ days old today/Rob is N days old today/' \
        -e 's!run on yyyy/mm/dd: [0-9/]+!run on yyyy/mm/dd: D!' \
        -e "/title='most recent entry'/ s!date=[0-9/]+!date=LATEST!" \
        -e '/http-equiv="refresh"|window\.location\.href/ s!date=[0-9/%A-Fa-f]+!date=LATEST!g' \
        -e 's/Copyright 1985-[0-9]{4}/Copyright 1985-YYYY/' \
        -e '/[Ll]ast[Bb]uild[Dd]ate/ s/.*/LASTBUILDDATE/'
}

fail=0; n=0
while IFS= read -r q; do
    case "$q" in ''|'#'*) continue ;; esac
    n=$((n+1))
    slug=$(printf '%s' "$q" | tr -c 'A-Za-z0-9' '_')
    curl -fsSL --compressed "https://robnugen.com/journal.pl?$q" | normalize > "$work/$slug.live" \
        || { echo "FETCH-FAIL $q"; fail=1; continue; }
    # journal.pl's query parsing on the command line: one name=value per argument.
    args=(); IFS='&' read -ra kv <<< "$q"
    for a in "${kv[@]}"; do args+=("$a"); done
    ( cd "$REPO" && faketime -f "$FAKE" "$PERL" journal.pl "${args[@]}" </dev/null 2>/dev/null ) \
        | sed '1,/^$/d' | normalize > "$work/$slug.local"
    if diff "$work/$slug.live" "$work/$slug.local" > "$work/$slug.diff"; then
        echo "PASS $q"
    else
        echo "DIFF $q"; sed 's/^/    /' "$work/$slug.diff" | head -20; fail=1
    fi
done < "$T/live-urls.txt"
echo "checked $n urls; details in $work"
exit $fail
