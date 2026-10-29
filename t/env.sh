#!/bin/bash
# Shared environment for the render harness. Source this; do not run it.
#
# Everything the harness writes lives under $HARNESS, never in the repo
# tree: the deploy watcher copies every closed file in the tree to the
# server.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HARNESS="$HOME/.cache/journal-harness"
PERL="$HOME/perl5/perlbrew/perls/perl-5.38.2/bin/perl"   # the server's perl version
PERLBIN="$(dirname "$PERL")"
JOBS=14

export REPO HARNESS PERL PERLBIN JOBS

# Rob's shell configures local::lib (~/perl5) for system perl. Those
# variables would redirect cpanm installs and module lookups away from
# the perlbrew perl, so they are cleared here. PERL5LIB is set, not
# appended: journal.pl has a `use lib` for the server's checkout of
# Text::RobMiniMarkdown, and this is the local clone.
unset PERL_MB_OPT PERL_MM_OPT PERL_LOCAL_LIB_ROOT
export PERL5LIB="$HOME/work/rob/Text-RobMiniMarkdown/lib"

# Determinism. TZ: the index writer adds 16 hours to reach Tokyo, so the
# server is Pacific. LC_ALL: `ls -1R` sort order feeds RSS item order.
export TZ=America/Los_Angeles
export LC_ALL=C
export PERL_HASH_SEED=0
export PERL_PERTURB_KEYS=0

# Pinned clock. `faketime -f '<absolute>'` freezes; the plain form advances.
export FAKE='2026-10-29 12:00:00'

# The three path seams (see setup_journal.pl, single_navigation_bar.pl,
# preformatted_journal_index_writer.pl).
export JOURNAL_BASE="$HARNESS/entries"
export JOURNAL_NAV_FILE="$REPO/navigation_definitions.txt"
export JOURNAL_LASTRUN_FILE="$HARNESS/lastrun.txt"

# Exit 2 if the deploy watcher is running: anything written inside the
# tree while it runs is copied to the server.
refuse_if_watcher_running() {
    if pgrep -f scp_modified_files_to_perlrobnugencom.sh >/dev/null; then
        echo "refusing: scp_modified_files_to_perlrobnugencom.sh is running" >&2
        exit 2
    fi
    local pid
    for pid in $(pgrep -x inotifywait); do
        if [ "$(readlink "/proc/$pid/cwd" 2>/dev/null)" = "$REPO" ]; then
            echo "refusing: inotifywait is watching $REPO (pid $pid)" >&2
            exit 2
        fi
    done
}
