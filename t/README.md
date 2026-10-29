# Render harness

Renders every output the engine can produce, before and after a change,
and diffs the two byte for byte. Nothing here writes inside the repo
tree: the deploy watcher copies every closed file in the tree to the
server, so all output goes to `~/.cache/journal-harness/`. Every script
refuses to start while the watcher is running.

Design: `docs/superpowers/specs/2026-10-29-perl-modernization-design.md`.

## Prerequisites (Lemur 13)

- perlbrew perl 5.38.2 at `~/perl5/perlbrew/perls/perl-5.38.2/bin/perl`
  (the server's version), with CGI, XML::RSS, Date::Manip, DateTime,
  DateTime::Format::Strptime, Number::Format, HTML::Entities,
  Perl::Critic, PPI, Perl::Tidy installed via perlbrew's cpanm. Rob's
  shell exports local::lib variables for system perl; run cpanm with
  them cleared or the modules land in `~/perl5/lib` instead:

      env -u PERL5LIB -u PERL_MB_OPT -u PERL_MM_OPT -u PERL_LOCAL_LIB_ROOT \
          ~/perl5/perlbrew/perls/perl-5.38.2/bin/perl ~/perl5/perlbrew/bin/cpanm -n <modules>
- `~/work/rob/Text-RobMiniMarkdown` cloned from GitHub (reached via
  `PERL5LIB`; its only non-core dependency is HTML::Entities).
- `faketime` from apt.

All of this is set by `t/env.sh`; source it for any by-hand run.

## Scripts

| script | does |
|---|---|
| `env.sh` | paths, pinned clock (`FAKE`), `TZ`, `LC_ALL=C`, hash seed, the three `JOURNAL_*` seams, `refuse_if_watcher_running` |
| `snapshot-entries.sh` | one-time rsync of the entries tree to `~/.cache/journal-harness/entries/`; refuses if it exists |
| `matrix.sh [--full]` | prints `type date print` lines; smoke by default |
| `render-one.sh <outroot> <type> <date> <print>` | one `journal.pl` page (used by `render.sh` via xargs) |
| `render.sh <name> [--full]` | index writer, then the matrix, into `render/<name>/{out,stderr}` plus `meta.txt`, `matrix.txt`, `stderr-report.txt` |
| `summarize-stderr.sh <name>` | counts, unique messages, example pages |
| `compare.sh <before> <after>` | `diff -r` of the two `out/` trees; exit 0 iff identical |
| `live-check.sh` | fetches each query in `live-urls.txt` from robnugen.com and compares to a local render after normalizing the known time-dependent lines |
| `reindent.pl ORIGINAL TIDIED` | applies only the leading whitespace of a perltidy result to the original |

## Tiers

- smoke: all 13 types for every year and month page, `type=all` for every
  entry day, both print modes, plus `date` missing and `date=../etc` once
  per type.
- full (`--full`): all 13 types for everything.

Snapshot of 2026-10-29: 40 years, 381 months, 6,526 entry days. Smoke is
24,024 pages, full is 180,648. Wall times are recorded below.

## Typical use

    t/snapshot-entries.sh            # once
    t/render.sh before --full        # baseline
    ...change code...
    t/render.sh after --full
    t/compare.sh before after        # exit 0 means byte-identical
    cat ~/.cache/journal-harness/render/after/stderr-report.txt

stderr is captured per page under `stderr/` and summarized, never diffed,
so adding `use warnings` cannot break the comparison.

## Live cross-check normalizations

Exactly these, applied to both sides: the "Rob is N days old" line, the
"run on yyyy/mm/dd" line, the date in the sidebar's "most recent entry"
link, the date in the redirect page's meta-refresh and script lines, the
copyright year, and any `lastBuildDate` line. Anything else that differs
is printed as a DIFF. No RSS URL is checked: the feed is the newest 15
entries by design.

## Lint

`./lint.sh` at the repo root runs perlcritic (severity 5, `.perlcriticrc`)
and the whitespace rules. To run it before every commit:

    ln -s ../../lint.sh .git/hooks/pre-commit

## Wall times (14 jobs, Lemur 13)

| tier | pages | wall time | measured |
|---|---|---|---|
| smoke | 24,024 | 12 min 20 s | 2026-10-29, two runs, byte-identical |
| full | 180,648 | (filled in after the baseline) | |
