#!/bin/bash
# Render one journal.pl page: render-one.sh <outroot> <type> <date> <print>
# stdout -> <outroot>/out/journal/<type>/<name>.html
# stderr -> <outroot>/stderr/journal/<type>/<name>.err (removed if empty)
# Expects env.sh already sourced (render.sh does; by hand, source it first).
outroot=$1; type=$2; date=$3; print=$4

case "$date" in
    nil)    name=nil;     dateparam=() ;;
    ../etc) name=invalid; dateparam=("date=$date") ;;
    *)      name=${date//\//-}; dateparam=("date=$date") ;;
esac
[ "$print" = 1 ] && name="$name.print"

out="$outroot/out/journal/$type/$name.html"
err="$outroot/stderr/journal/$type/$name.err"
mkdir -p "$(dirname "$out")" "$(dirname "$err")"

cd "$REPO"
faketime -f "$FAKE" "$PERL" journal.pl "type=$type" "${dateparam[@]}" "print=$print" \
    </dev/null >"$out" 2>"$err"
[ -s "$err" ] || rm -f "$err"
