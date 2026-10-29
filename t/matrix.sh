#!/bin/bash
# Print the render matrix as "type date print" lines, sorted.
#   smoke (default): all types x years x months x both prints,
#                    type=all x days x both prints, nil+invalid per type
#   --full:          all types x everything x both prints
set -euo pipefail
source "$(dirname "$0")/env.sh"

tier=smoke
[ "${1:-}" = "--full" ] && tier=full

types=$(cd "$REPO" && "$PERL" -e 'require "./setup_journal.pl"; print join("\n", sort keys %journal_regex_type), "\n"')

cd "$JOURNAL_BASE"
years=$(ls -1 | grep -E '^[0-9]{4}$')
months=$(find . -mindepth 2 -maxdepth 2 -type d | sed 's!^\./!!' | grep -E '^[0-9]{4}/[0-9]{2}$' | sort)
days=$(find . -mindepth 3 -maxdepth 3 -type f | sed 's!^\./!!' \
       | grep -E '^[0-9]{4}/[0-9]{2}/[0-9]{2}' | cut -c1-10 | sort -u)

{
    for t in $types; do
        for d in $years $months; do
            echo "$t $d 0"; echo "$t $d 1"
        done
        echo "$t nil 0"
        echo "$t ../etc 0"
    done
    if [ "$tier" = full ]; then daytypes=$types; else daytypes=all; fi
    for t in $daytypes; do
        for d in $days; do
            echo "$t $d 0"; echo "$t $d 1"
        done
    done
} | sort
