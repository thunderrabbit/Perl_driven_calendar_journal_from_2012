#!/bin/bash
# Lint gate for the journal engine: perlcritic severity 5 over the .pl files,
# plus four-space indentation, no trailing whitespace and a final newline over
# the code files. Exit 1 on any hit. Never looks inside journal/ (the entries)
# or .superpowers/ (git-ignored plan scratch).
# readlink -f so the script still finds the repo when run through a symlink
# such as .git/hooks/pre-commit.
cd "$(dirname "$(readlink -f "$0")")" || exit 2

PERLBIN="$HOME/perl5/perlbrew/perls/perl-5.38.2/bin"
unset PERL_MB_OPT PERL_MM_OPT PERL_LOCAL_LIB_ROOT

# Served static files whose bytes must not change (Keybase proof, vendored CSS,
# third-party HTML, Apache error pages, a file with its own conventions).
EXCLUDE='^\./(keybase\.txt|css/example\.css|css/m\.robnugen\.com\.j\.css|japan/dartmouth\.edu_kanji\.html|403\.shtml|500\.shtml|js/README\.ROB)$'

list_files() {
    find . \( -path ./journal -o -path ./.git -o -path ./.superpowers \) -prune -o -type f \
        \( -name '*.pl' -o -name '*.sh' -o -name '*.md' -o -name '*.txt' \
           -o -path './t/*' -o -path './docs/*' \) -print \
        | grep -Ev "$EXCLUDE" | sort
}

status=0
mapfile -t FILES < <(list_files)
mapfile -t PL < <(printf '%s\n' "${FILES[@]}" | grep '\.pl$')
if [ "${#PL[@]}" -eq 0 ]; then
    echo "lint.sh: no .pl files found under $PWD"
    exit 2
fi

hits=$(grep -nP '[ \t]+$' "${FILES[@]}" /dev/null)
if [ -n "$hits" ]; then echo "trailing whitespace:"; echo "$hits"; status=1; fi

hits=$(grep -nP '^ *\t' "${FILES[@]}" /dev/null)
if [ -n "$hits" ]; then echo "tab indentation:"; echo "$hits"; status=1; fi

for f in "${FILES[@]}"; do
    if [ -s "$f" ] && [ "$(tail -c1 "$f" | od -An -c | tr -d ' ')" != '\n' ]; then
        echo "missing final newline: $f"; status=1
    fi
done

if ! "$PERLBIN/perlcritic" --profile .perlcriticrc --severity 5 --quiet "${PL[@]}"; then
    echo "perlcritic severity 5 reported violations"; status=1
fi

n=$("$PERLBIN/perlcritic" --profile .perlcriticrc --severity 4 --quiet "${PL[@]}" | wc -l)
echo "info: severity-4 violations: $n"

exit $status
