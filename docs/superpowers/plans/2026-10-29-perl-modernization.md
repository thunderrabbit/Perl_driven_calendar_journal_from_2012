# Perl Modernization (light touch) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every `.pl` in the journal engine strict-clean and perlcritic-gentle-clean on perl 5.38.2 with byte-identical rendered output, and leave behind a render-and-diff harness plus a lint script.

**Architecture:** The engine stays a set of `require`d script fragments sharing `package main` globals. Three environment-variable seams make it runnable locally; a bash harness under `t/` renders the whole output matrix into `~/.cache/journal-harness/render/<name>/` under a frozen clock and `diff -r`s snapshots. Each code commit is followed by a smoke render whose diff against the baseline must be empty.

**Tech Stack:** perlbrew perl-5.38.2 at `~/perl5/perlbrew/perls/perl-5.38.2/bin/perl` (call it `$PERL` below), cpanm modules listed in Task 1, `faketime` (apt), `perltidy` (perlbrew copy), `perlcritic`, bash, rsync, xargs, curl.

**Spec:** `docs/superpowers/specs/2026-10-29-perl-modernization-design.md`

**Conventions in this plan:** `$PERL` is the perlbrew perl above. `$SCRATCH` is the session scratchpad directory. Any step that uses `$HARNESS`, `$FAKE`, `$JOURNAL_*` or `$PERL5LIB` assumes `source t/env.sh` was run in that shell first (Task 3 creates it). `<repo>` is `~/work/rob/robnugen.com/journal`.

## Global Constraints

- Server perl is 5.38.2; local system perl 5.34 is never used for anything in this plan.
- Rendered output must be byte-identical to the baseline across the full matrix. The harness decides, not a reader.
- Warnings are collected and reported, never silenced: no `no warnings`, no defined-guards added to quiet a warning.
- No variable is renamed and no value changes. `local`→`my` or global→`my` only where the name appears in exactly one file (verify with `grep -l '\$name\b' *.pl`).
- Nothing changes in the rendered HTML, including the duplicated `$printer_version` block and the duplicated charset branch. Note, don't fix.
- The entries repo (`journal/journal/`) is never committed to and never written to by the harness. Harness output lives only in `~/.cache/journal-harness/`.
- The harness refuses to run while the deploy watcher is running.
- Source whitespace: four-space indentation, no tab indentation, no trailing whitespace, newline at end of file, for `*.pl *.sh t/ docs/ *.md *.txt`. Served static files are excluded by explicit list.
- Git: branch `get-modern`, inside the open bubble whose BEGIN commit is a71779f1. Claude never commits on master. Commit subjects ≤50 chars, imperative; body explains why; multiple `-m` flags, never a heredoc. Commits end with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.
- Perl style for new code: `use strict; use warnings;`, three-argument lexical opens, four-space indent.

## Review Focus

Inputs the spec implies but no task's tests cover directly. Each has a pinning test in the owning task.

1. **faketime clock advancing instead of frozen** (RSS `lastbuilddate` has minute resolution, so a 45-minute render that drifts across minutes would differ between runs). Pinned in Task 1 Step 6.
2. **The index writer's five-second rate gate under a frozen clock** (`iMayRunYet` compares `time` to the last-run file; a frozen clock makes the second run print "Wait an hour" and exit). Pinned in Task 3 Step 7.
3. **`open(my $fh, '<', undef)` opens an anonymous temp file** (perlfunc "open" special case, any mode). The print-mode block in journal.pl opens `$ls1rfile`, which is always undef there. A naive three-arg conversion would silently create a temp file per print-mode request and hide the warning the spec wants reported. Pinned in Task 6 Step 3.
4. **perltidy changing anything other than leading whitespace** (intra-line spacing, heredoc bodies, `qw()` lists). Pinned in Task 4 Step 4 with a stripped-line diff.
5. **`our $year` followed by `my ... $year` in the index writer** (line 135 declares a file-scope lexical `$year` from `localtime`; an `our $year` above it fires `"my" variable $year masks earlier declaration` on every run). Pinned in Task 5 Step 7.
6. **The lint `find` descending into the inner entries repo** (109 MB, 16k files, not ours). Pinned in Task 7 Step 6.

---

### Task 1: Toolchain on Lemur 13

No commit. Everything lands outside the repo.

**Files:**
- Create: `~/perl5/perlbrew/` (perlbrew root, default location)
- Create: `~/work/rob/Text-RobMiniMarkdown/` (git clone)

**Interfaces:**
- Produces: `$PERL` = `~/perl5/perlbrew/perls/perl-5.38.2/bin/perl`; `~/perl5/perlbrew/perls/perl-5.38.2/bin/{perlcritic,perltidy,cpanm}`; `PERL5LIB=~/work/rob/Text-RobMiniMarkdown/lib`; `faketime` on PATH.

- [ ] **Step 1: Install perlbrew**

Download `https://install.perlbrew.pl` to the scratchpad, read it, then run it with bash. Expected: `~/perl5/perlbrew/bin/perlbrew` exists. Do not add anything to Rob's shell rc files (the installer offers to; decline or skip).

- [ ] **Step 2: Build perl 5.38.2**

Run: `~/perl5/perlbrew/bin/perlbrew install -j 14 -n perl-5.38.2`
Expected: `$PERL -e 'print $]'` prints `5.038002`.

- [ ] **Step 3: Install cpanm and modules into that perl**

Run: `~/perl5/perlbrew/bin/perlbrew install-cpanm`, then
`$PERL ~/perl5/perlbrew/bin/cpanm -n CGI XML::RSS Date::Manip DateTime DateTime::Format::Strptime Number::Format HTML::Entities Perl::Critic PPI Perl::Tidy`
Expected: `$PERL -MCGI -MXML::RSS -MDate::Manip -MDateTime -MDateTime::Format::Strptime -MNumber::Format -MHTML::Entities -MPerl::Critic -MPPI -MPerl::Tidy -e 'print "ok\n"'` prints `ok`.

- [ ] **Step 4: Clone Text-RobMiniMarkdown**

Run: `git clone https://github.com/thunderrabbit/Text-RobMiniMarkdown ~/work/rob/Text-RobMiniMarkdown`
Expected: `git -C ~/work/rob/Text-RobMiniMarkdown rev-parse --short HEAD` prints `269ada4f`. Then `PERL5LIB=~/work/rob/Text-RobMiniMarkdown/lib $PERL -MText::RobMiniMarkdown -e 'print "ok\n"'` prints `ok`. If it fails on a missing module, cpanm that module into the perlbrew perl and record it in `t/README.md` (Task 3).

- [ ] **Step 5: faketime**

Run: `which faketime`. If missing, stop and ask Rob to run `! sudo apt install faketime`, then continue.

- [ ] **Step 6: Prove the clock freezes (Review Focus 1)**

Run: `faketime -f '2026-10-29 12:00:00' $PERL -e 'print time, "\n"; sleep 2; print time, "\n"'`
Expected: two identical numbers. If they differ, use `faketime -f '@2026-10-29 12:00:00 x0'` instead and carry that form into `t/env.sh`.

---

### Task 2: Path overrides (three env seams)

**Files:**
- Modify: `setup_journal.pl:6`
- Modify: `single_navigation_bar.pl:7`
- Modify: `preformatted_journal_index_writer.pl:30`

**Interfaces:**
- Produces: env vars `JOURNAL_BASE`, `JOURNAL_NAV_FILE`, `JOURNAL_LASTRUN_FILE`, each read with `$ENV{NAME} // "<today's hardcoded value>"`. Defaults are the current literals, unchanged.

- [ ] **Step 0: Commit this plan**

```bash
git add docs/superpowers/plans/2026-10-29-perl-modernization.md
git commit -m "Add implementation plan for the light-touch pass" -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

- [ ] **Step 1: Edit the three lines**

Each becomes `... = $ENV{JOURNAL_X} // "<existing literal>";` on the same line, same comment kept. No other change.

- [ ] **Step 2: Verify defaults are untouched**

Run: `git diff | grep '^[-+]' | grep -v '^[-+][-+]'`
Expected: exactly six lines, three `-` and three `+`, and each `+` line contains the same literal string as its `-` line.

- [ ] **Step 3: Verify the seams work**

Run: `cd <repo> && JOURNAL_BASE=/tmp/x $PERL -e 'require "./setup_journal.pl"; print "$journal_base\n"'`
Expected: `/tmp/x`. Unset: prints `/home/barefoot_rob/robnugen.com/journal/journal`.

- [ ] **Step 4: Commit**

```bash
git add setup_journal.pl single_navigation_bar.pl preformatted_journal_index_writer.pl
git commit -m "Read the three server paths from env vars" -m "Defaults are the existing literals, so the server sees no change. With JOURNAL_BASE, JOURNAL_NAV_FILE and JOURNAL_LASTRUN_FILE set, the engine can render on Lemur 13 against a frozen copy of the entries, which the before/after harness needs." -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Harness under `t/`, baseline render, live cross-check

**Files:**
- Create: `t/env.sh`, `t/snapshot-entries.sh`, `t/matrix.sh`, `t/render-one.sh`, `t/render.sh`, `t/summarize-stderr.sh`, `t/compare.sh`, `t/live-check.sh`, `t/live-urls.txt`, `t/reindent.pl`, `t/README.md`
- No `.gitignore` change: nothing the harness writes lives in the repo tree (the spec's "`.render/` ignored" line predates the `~/.cache` decision).

**Interfaces:**
- Produces, for later tasks:
  - `t/render.sh <name> [--full]` → `~/.cache/journal-harness/render/<name>/{out,stderr,meta.txt,stderr-report.txt}`. Smoke tier by default.
  - `t/compare.sh <before> <after>` → `diff -r` of the two `out/` trees; exit 0 iff identical.
  - `t/summarize-stderr.sh <name>` → writes and prints `stderr-report.txt`.
  - `t/live-check.sh` → fetches each line of `t/live-urls.txt`, renders the same locally, normalizes, diffs; exit 0 iff all match.
  - `t/reindent.pl ORIGINAL TIDIED` → stdout: each line of ORIGINAL with its leading whitespace replaced by the leading whitespace of the same-numbered line of TIDIED, tabs in that leading run expanded at 8; dies if line counts differ.
  - All scripts invoke `$PERL` by absolute path and source `t/env.sh`; none depends on the caller's shell.

`t/env.sh` exports (decisions, not options):

| var | value | why |
|---|---|---|
| `REPO` | `$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)` | scripts run from anywhere |
| `HARNESS` | `$HOME/.cache/journal-harness` | spec |
| `PERL` | `$HOME/perl5/perlbrew/perls/perl-5.38.2/bin/perl` | server's perl |
| `PERL5LIB` | `$HOME/work/rob/Text-RobMiniMarkdown/lib` | journal.pl's `use lib` points at a server path |
| `TZ` | `America/Los_Angeles` | the index writer adds 16 h to reach Tokyo, so the server is Pacific |
| `LC_ALL` | `C` | `ls -1R` sort order feeds RSS item order |
| `PERL_HASH_SEED` / `PERL_PERTURB_KEYS` | `0` / `0` | hash order |
| `FAKE` | `2026-10-29 12:00:00` (form proven in Task 1 Step 6) | pinned clock |
| `JOURNAL_BASE` | `$HARNESS/entries` | frozen snapshot; index files land here too |
| `JOURNAL_NAV_FILE` | `$REPO/navigation_definitions.txt` | read-only |
| `JOURNAL_LASTRUN_FILE` | `$HARNESS/lastrun.txt` | deleted before every index-writer run |
| `JOBS` | `14` | nproc |

and defines `refuse_if_watcher_running`: exit 2 with a message if `pgrep -f scp_modified_files_to_perlrobnugencom.sh` matches, or any `inotifywait` pid has `/proc/<pid>/cwd` resolving to `$REPO`.

Matrix (`t/matrix.sh [--full]`, prints `type date print` lines, sorted):
- years: dirs in `$JOURNAL_BASE` matching `^\d{4}$`; months: `YYYY/MM` dirs matching `^\d\d$`; days: distinct `YYYY/MM/DD` from files matching `^\d\d` in month dirs.
- types: the 13 keys of `%journal_regex_type`, read from the file with `$PERL -e 'require "./setup_journal.pl"; print join "\n", sort keys %journal_regex_type'`.
- smoke: all 13 types × {years, months} × print {0,1}; type `all` only × days × print {0,1}; plus `nil` and `../etc` once per type with print 0.
- full: all 13 types × everything.
- On 2026-10-29 the snapshot has 40 years, 381 months, 6,526 days: smoke = 24,024 lines, full = 180,648.

Output naming inside `out/`: `journal/<type>/<date with / → ->.html`, `.print.html` when print=1; `nil.html`, `invalid.html` for the two special dates. stderr to the same path under `stderr/` with `.err`, removed when empty. Index writer: `out/index/preformatted_index_for_<type>_entries.html`, `out/index/<type>_entries.rss`, `out/index/ls-1R.txt`, `out/index/stdout.sorted.txt` (its stdout, sorted); its stderr at `stderr/index-writer.err`.

`t/render-one.sh <outroot> <type> <date> <print>`: `cd $REPO`, run `faketime -f "$FAKE" "$PERL" journal.pl type=<type> [date=<date>] print=<print> </dev/null`, omitting the date argument when `<date>` is `nil`.

`t/render.sh <name> [--full]`: refuse if watcher; refuse if `render/<name>` exists; write `meta.txt` (git HEAD, tier, `date -Is`); delete `$JOURNAL_LASTRUN_FILE`; run the index writer under faketime; copy its products; then `t/matrix.sh | xargs -P $JOBS -L 1 t/render-one.sh <outroot>`; finally `t/summarize-stderr.sh <name>`.

`t/summarize-stderr.sh <name>` report format: count of pages with stderr / total pages; total stderr lines; then `count  message` for every unique line, descending; then for the top 10 messages, up to 3 example page paths.

`t/live-check.sh`: for each query string in `t/live-urls.txt`, `curl -fsS "https://robnugen.com/journal.pl?<q>"` and a local render of the same parameters (strip the local CGI header: everything through the first blank line), both passed through the normalizer, then `diff`. Normalizer, exactly these substitutions:
1. `Rob is [0-9,]+ days old today` → `Rob is N days old today`
2. `run on yyyy/mm/dd: [0-9/]+` → `run on yyyy/mm/dd: D`
3. on lines containing `title='most recent entry'`: `date=[0-9/]+` → `date=LATEST`
4. on lines containing `http-equiv="refresh"` or `window.location.href`: `date=[0-9/%A-F]+` → `date=LATEST` (the redirect target is the newest entry)
5. `Copyright 1985-[0-9]{4}` → `Copyright 1985-YYYY`
6. any line matching `lastbuilddate` case-insensitively → `LASTBUILDDATE`

Print `PASS <q>` or `DIFF <q>` followed by the diff; exit 1 if any DIFF.

`t/live-urls.txt`: 40 query strings, all dates before 2025, verified to exist in the snapshot. Required coverage: 4 year pages (two types), 6 month pages (three types), 20 day pages spanning `.txt` (pre-2000), `.html`, and `.md` eras (2024), at least one with a `.comment` file alongside, at least one `nihongo` day; 6 of those day pages again with `print=1`; one `type=nihongo&...&print=1`; `type=all` with no date (redirect); `type=all&date=../etc`; `type=bogus&date=2001/05/06` (require_reload redirect); `type=all&date=2010/05/10` and `type=all&date=2016/03/24` (the charset branch dates). No RSS URL: the feed is the newest 15 entries by design, pure content drift.

- [ ] **Step 1: Write `t/env.sh` and `t/snapshot-entries.sh`**

`t/snapshot-entries.sh`: refuse if watcher; refuse if `$HARNESS/entries` exists (print "snapshot exists; remove it yourself to retake"); `rsync -a --exclude .git/ "$REPO/journal/" "$HARNESS/entries/"`.

- [ ] **Step 2: Test the watcher refusal**

Run: `bash -c 'exec -a scp_modified_files_to_perlrobnugencom.sh sleep 60' & t/snapshot-entries.sh; echo "exit=$?"; kill %1`
Expected: a refusal message and `exit=2`, no `$HARNESS/entries` created.

- [ ] **Step 3: Take the snapshot**

Run: `t/snapshot-entries.sh && ls $HARNESS/entries | head -3`
Expected: `1985 1986 1987`.

- [ ] **Step 4: Write `t/matrix.sh` and check its counts**

Run: `t/matrix.sh | wc -l; t/matrix.sh --full | wc -l; t/matrix.sh | awk '{print $2}' | grep -c '^[0-9]\{4\}$'`
Expected: `24024`, `180648`, `1040` (40 years × 13 types × 2 prints). If the snapshot differs slightly from 2026-10-29, record the actual numbers in `t/README.md`.

- [ ] **Step 5: Write `t/render-one.sh` and render one page by hand**

Run: `t/render-one.sh $SCRATCH/r all 2001/05/06 0 && head -c 300 $SCRATCH/r/journal/all/2001-05-06.html`
Expected: starts with `Content-type: text/html`, then the XHTML doctype. (Rendering needs the index files; run the index writer by hand first: `cd $REPO && rm -f $JOURNAL_LASTRUN_FILE && faketime -f "$FAKE" $PERL preformatted_journal_index_writer.pl >/dev/null`, then confirm `ls $JOURNAL_BASE/preformatted_index_for_all_entries.html`.)

- [ ] **Step 6: Write `t/render.sh`, `t/summarize-stderr.sh`, `t/compare.sh`**

- [ ] **Step 7: Pin the rate gate (Review Focus 2)**

Run: `t/render.sh gate1 && t/render.sh gate2 && grep -l 'Wait an hour' $HARNESS/render/gate*/out/index/stdout.sorted.txt; echo "grep exit=$?"`
Expected: `grep exit=1` (neither run hit the gate), and `t/compare.sh gate1 gate2` exits 0. This doubles as the determinism check: two smoke renders of the same code are byte-identical. If `compare` shows a diff, the clock, locale or hash seed is leaking; fix `t/env.sh` before going on. Delete `gate1` and `gate2` afterwards.

- [ ] **Step 8: Time the smoke tier and record it**

From `meta.txt` timestamps of gate2 and the summary line of `render.sh`, note smoke wall time in `t/README.md`, with the full-tier estimate (×7.5).

- [ ] **Step 9: Write `t/reindent.pl`**

Signature: `reindent.pl ORIGINAL TIDIED` → stdout. Dies with both line counts if they differ. Test: `t/reindent.pl f f` for any `f` whose indentation is tab-free reproduces `f` byte-for-byte (`cmp`).

- [ ] **Step 10: Write `t/live-check.sh`, `t/live-urls.txt`; run it**

Run: `t/live-check.sh; echo "exit=$?"`
Expected: 40 `PASS` lines, `exit=0`. A `DIFF` here means the local render does not reproduce production; stop and investigate before taking a baseline (likely suspects: TZ, locale, a module version). Rob judges any remaining difference.

- [ ] **Step 11: Write `t/README.md`**

Contents: what each script does, the one-time snapshot, the smoke/full tiers and their run times, the normalizer list, how to compare, the pre-commit one-liner `ln -s ../../lint.sh .git/hooks/pre-commit` (Task 7), and any module added in Task 1 Step 4.

- [ ] **Step 12: Commit the harness**

```bash
git add t/
git commit -m "Add before/after render harness under t/" -m "Renders every page the engine can produce (index writer, then journal.pl for every year, month and entry day, both print modes, all 13 types) into ~/.cache/journal-harness under a frozen clock, fixed TZ, C locale and hash seed 0, and diffs snapshots byte-for-byte. Stderr is captured separately and summarized, never diffed, so adding warnings cannot break the output comparison. Also a live cross-check against robnugen.com and reindent.pl, the indentation-only merge tool for the next commit." -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

- [ ] **Step 13: Render the baseline, full tier**

Run: `t/render.sh before --full`
Expected: completes; `meta.txt` records the harness commit's HEAD; `stderr-report.txt` exists. Keep this directory for the rest of the pass. Record wall time in `t/README.md` (amend into the next commit that touches `t/`).

---

### Task 4: Indentation normalization

**Files:**
- Modify (indentation only): `journal.pl`, `setup_journal.pl`, `sidebar.pl`, `mainbar.pl`, `draw_header.pl`, `draw_navigation.pl`, `single_navigation_bar.pl`, `displayFile.pl`, `mkdef.pl`, `preformatted_journal_index_writer.pl`, `compare_directories.pl`

- [ ] **Step 1: Produce tidied copies**

For each file: `~/perl5/perlbrew/perls/perl-5.38.2/bin/perltidy -fnl -fbl -i=4 -ci=4 -st FILE > SCRATCH/FILE.tdy` (freeze newlines and blank lines; indentation 4; continuation indentation 4).
Expected: `wc -l FILE SCRATCH/FILE.tdy` equal for every file. If any differ, `diff` them, find the line perltidy split or joined, and report before continuing.

- [ ] **Step 2: Merge indentation only**

For each file: `t/reindent.pl FILE SCRATCH/FILE.tdy > SCRATCH/FILE.new && cp SCRATCH/FILE.new FILE`.

- [ ] **Step 3: Strip trailing whitespace and ensure a final newline**

`sed -i 's/[ \t]*$//' FILE` for each; append `\n` to any file whose last byte is not `\n` (none expected; check with `tail -c1`).

- [ ] **Step 4: Prove the commit is indentation-only (Review Focus 4)**

Run, for each file: `diff <(git show HEAD:FILE | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//') <(sed -E 's/^[[:space:]]+//' FILE)`
Expected: empty for every file. Then `grep -nP '^ *\t' *.pl` prints nothing, and `git diff --stat` shows every `.pl` with equal insertions and deletions.

- [ ] **Step 5: Compile check and smoke render**

Run: `for f in *.pl; do $PERL -c $f; done` (with `PERL5LIB` from `t/env.sh`; journal.pl will print nothing because `print` is runtime) → every file `syntax OK`.
Run: `t/render.sh indent && t/compare.sh before indent; echo "exit=$?"`
Expected: `exit=0`.

- [ ] **Step 6: Commit**

```bash
git add *.pl
git commit -m "Normalize indentation to four spaces" -m "Mechanical: perltidy -fnl -fbl -i=4 computed the indentation and t/reindent.pl applied only the leading whitespace, so every line's content is unchanged (verified with a stripped-line diff). Trailing whitespace removed. Harness diff against the baseline is empty." -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: `use strict; use warnings;` with `our`, one commit per file group

Every file gets `use strict;` and `use warnings;` as its first statements (after the shebang if present; in journal.pl this means above the `print "Content-type..."` on line 3, since `RequireUseStrict` wants strict before any other statement). Shebang lines are left as they are, including `-w`. Each file declares `our` for every shared global it reads or writes, at file scope, above the first `sub`. Variables that strict flags and that appear in exactly one file become `my` at their first assignment. Loop iterators become `foreach my $x` (also what perlcritic severity 5 `RequireLexicalLoopIterators` wants).

Shared globals and their owners:

| owner | `our` declared there |
|---|---|
| `setup_journal.pl` | `$VERSION $style_css $journal_css $journal_pl $www_journal_pl $journal_base $quicklist_file $journal_log_file $between_file_text %journal_regex_type` |
| `journal.pl` | `$require_reload $debug $date $printer_version $journal_type $indexname $ls1r` |
| `sidebar.pl` | `$ls1rfile $year $month $day $lastday $nextday $more_years_prefix` |

Per file (reads = `our` lines to add; `my` = the one-file variables):

- `setup_journal.pl`: owner list only.
- `mkdef.pl`, `displayFile.pl`: pragmas only.
- `single_navigation_bar.pl`: `local ($param_nav_set, $param_item_name) = @_;` → `my`; `my ($nav_set, $item_name, $on, $off, $url) = split;`.
- `draw_navigation.pl`: `my @param_nav_set`; `for (my $p_count = 0; ...)`.
- `draw_header.pl`: reads `$date $require_reload $indexname $ls1r $style_css $journal_css $printer_version $journal_type`; `my $new_date = $date;`.
- `mainbar.pl`: reads `$debug $journal_base %journal_regex_type $www_journal_pl $between_file_text $year $month $day`; `my` for `@all_files_for_date @files_for_date $matching_file $title_no_spaces $this_entrys_href $this_entrys_title $md $md_text`; `foreach my $full_file_path`, `foreach my $file` (twice). Note `$year $month $day` stay global: journal.pl reads `$day` after `mainbar()` returns.
- `sidebar.pl`: reads `$date $ls1r $debug $journal_pl $journal_type` plus its owner list; `my` for `$years $more_last_years $lastyear $nextyear $more_next_years $months $more_last_months $lastmonth $nextmonth $more_next_months $days $more_last_days $more_next_days $firstmonth_nextyear $finalmonth_lastyear $firstday_nextmonth $finalday_lastmonth $first_entry_date $latest_entry_date`. Declare the list-assigned ones (`my ($more_last_years, $lastyear, $nextyear, $more_next_years);`) on the line before their list assignment; the assignment itself is unchanged.
- `journal.pl`: owner list plus reads `$journal_base $journal_pl %journal_regex_type $ls1rfile $year $month $day $lastday $nextday`.
- `preformatted_journal_index_writer.pl`: reads `$journal_base $journal_pl $www_journal_pl %journal_regex_type`; file-scope `our` for `@month_lengths @month_titles_spaced_for_month_summaries @month_titles_no_spacing $ls1r @pre_month_whitespace @post_month_whitespace $month $files @files_of_this_type @files_of_ANY_type %list_of_years_per_journal_type %list_of_months_per_year %list_of_days_per_year_month $dd $file $title $title_no_spaces $error_message $day_of_week $day`; `foreach my` for `$journal_type` (twice), `$year` (line 299), `$i` (twice), `$yearmonth`; in `setFeb` and `isLeap`, `local($year) = @_;` → `my ($year) = @_;` (nothing reads `$year` dynamically inside them). **Do not declare `our $year`**: line 135's `my (... $year ...) = localtime(...)` is a file-scope lexical that already shadows the global for the rest of the file, and an `our $year` above it would warn on every run (Review Focus 5).

Commit order (each commit: Step A compile, Step B smoke render + compare, Step C commit): 1 `setup_journal.pl`; 2 `mkdef.pl displayFile.pl single_navigation_bar.pl draw_navigation.pl`; 3 `draw_header.pl`; 4 `mainbar.pl`; 5 `sidebar.pl`; 6 `journal.pl`; 7 `preformatted_journal_index_writer.pl`.

- [ ] **Step 1: Commit 1, setup_journal.pl**

A: `$PERL -c setup_journal.pl` → `syntax OK`. B: `t/render.sh s1 && t/compare.sh before s1` → exit 0. C: `git commit -m "Make setup_journal.pl strict" -m "<why>" ...`.

- [ ] **Step 2: Commit 2, the four leaf helpers**

A/B/C as above, snapshot `s2`.

- [ ] **Step 3: Commit 3, draw_header.pl** (snapshot `s3`)

- [ ] **Step 4: Commit 4, mainbar.pl** (snapshot `s4`)

- [ ] **Step 5: Commit 5, sidebar.pl** (snapshot `s5`)

- [ ] **Step 6: Commit 6, journal.pl** (snapshot `s6`)

- [ ] **Step 7: Commit 7, the index writer, and pin Review Focus 5** (snapshot `s7`)

Before committing: `grep -c 'masks earlier declaration' $HARNESS/render/s7/stderr/index-writer.err` → `0` (or the file does not exist).

- [ ] **Step 8: Regenerate and read the warnings report**

Run: `cat $HARNESS/render/s7/stderr-report.txt`. Confirm the spec's known sources appear (undef `$ls1rfile` in print mode, Strptime undef on year/month pages, sidebar `eq ""` family, missing `type` param, the index writer's undef title for `.md` entries). Anything unexpected is reported to Rob, not fixed.

- [ ] **Step 9: Delete the intermediate snapshots `indent`, `s1`..`s7`** (keep `before`).

---

### Task 6: Three-argument lexical opens

**Files:**
- Modify: `journal.pl:79` (print-mode block), `draw_header.pl:10`, `sidebar.pl:9`, `single_navigation_bar.pl:9,11,40`, `mainbar.pl:97-101`, `displayFile.pl:5-9`, `preformatted_journal_index_writer.pl:33-35,39-41,111-112,184` and every `print HTML_OUTPUT` (36 sites) and `close HTML_OUTPUT`. Line numbers are pre-Task-4; find them by handle name.

Conversions:
- Read opens: `open my $lsoner, '<', $ls1rfile;` and `<$lsoner>`; same for `$indexname`, `'ls-1R.txt'`, `$filename` (LASTRUN read), `$nav_settings_file` (`open(my $in, '<', $nav_settings_file) or die ...`; `while (<$in>)`; `close $in or die ...`), `$file` in mainbar (`if (open(my $fh, '<', $file)) { while (<$fh>) { print; } close $fh; }`), `$_[0]` in displayFile.
- Write opens: `open(my $lastrun_fh, '>', $filename); print {$lastrun_fh} $now; close $lastrun_fh;` and `open(my $html_out, '>', $indexname) or die "can't open $indexname: $!";` with every `print HTML_OUTPUT` → `print {$html_out}` and `close HTML_OUTPUT` → `close $html_out`. Parenthesize the open before `or die` so `or` binds to `open`, not to `$indexname`.
- Where the original had no `or die`, add none. No `:encoding` layer anywhere.
- **journal.pl print-mode block (Review Focus 3):** `$ls1rfile` is always undef here, and `open(my $fh, '<', undef)` opens an anonymous temp file instead of failing. Keep it two-argument with a lexical handle: `open my $lsoner, $ls1rfile; ## no critic (InputOutput::ProhibitTwoArgOpen)` with a comment above: deliberately two-arg because `$ls1rfile` is undef here (set only inside `sidebar()`), the three-arg form with undef would open an anonymous temp file and hide the bug; see the spec's non-goals. Rob can veto this in favour of fixing the block in the next pass.

- [ ] **Step 1: Convert the ten opens and the HTML_OUTPUT prints**

- [ ] **Step 2: Compile check**

Run: `for f in *.pl; do $PERL -c $f; done` → all `syntax OK`. Then `grep -nE 'open *\(? *[A-Z_]+[, ]' *.pl` → only the `## no critic` line in journal.pl.

- [ ] **Step 3: Pin Review Focus 3**

Run: `t/render.sh opens && t/compare.sh before opens` → exit 0. Then `grep -c 'uninitialized value \$ls1rfile in open' $HARNESS/render/opens/stderr/journal/all/2001-05-06.print.err` → `1`, same count as in `before`. An anonymous temp file would make that warning disappear, so an unchanged count is the proof.

- [ ] **Step 4: Commit**

```bash
git add *.pl
git commit -m "Use three-argument lexical opens" -m "Ten bareword two-argument opens become lexical three-argument opens; or-die is kept exactly where it was and silent failure is kept where it was, so output and the warnings report are unchanged. The one exception is the print-mode block in journal.pl, where the filename is always undef: the three-argument form would open an anonymous temp file there, so it stays two-argument with a no-critic marker and a comment." -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: perlcritic gate and `lint.sh`

**Files:**
- Modify: `mainbar.pl` (the two `my $x = 1 if (...)` lines in the entry loop)
- Create: `.perlcriticrc`, `lint.sh`

**Interfaces:**
- Produces: `./lint.sh` exits 0 iff perlcritic severity 5 reports nothing over all `.pl` outside `journal/` and `.git/`, and no trailing whitespace, no tab indentation, final newline present in the code-file set. Prints the severity-4 violation count as information.

`.perlcriticrc`:
```
severity = 5
# The engine is a set of require'd script fragments ("setup_journal.pl")
# sharing package main. Turning them into modules is the deeper pass.
[-Modules::RequireBarewordIncludes]
```
Add further exclusions only if `perlcritic --severity 5` still reports after the code fix below, each with a comment saying which structural fact forces it.

Code fix for `Variables::ProhibitConditionalDeclarations` (severity 5) in mainbar.pl: `my $istext = 1 if ($file =~ m/\.txt$/i);` → `my $istext = ($file =~ m/\.txt$/i) ? 1 : 0;` and the same for `$ismd`. Both are only ever tested for truth.

`lint.sh` (bash, repo root, `cd "$(dirname "$0")"`):
- file set: `find . \( -path ./journal -o -path ./.git \) -prune -o -type f \( -name '*.pl' -o -name '*.sh' -o -name '*.md' -o -name '*.txt' -o -path './t/*' -o -path './docs/*' \) -print`, minus the explicit exclude list: `./keybase.txt` (served Keybase proof, bytes must not change), `./css/example.css`, `./css/m.robnugen.com.j.css`, `./japan/dartmouth.edu_kanji.html`, `./403.shtml`, `./500.shtml`, `./js/README.ROB`.
- checks, each printing `file:line:` hits: trailing whitespace `grep -nP '[ \t]+$'`; tab indentation `grep -nP '^ *\t'`; missing final newline (`tail -c1`).
- `$PERL`'s `perlcritic --profile .perlcriticrc --severity 5` over the `.pl` files; then `--severity 4 | wc -l` printed as `info: severity-4 violations: N`.
- exit 1 on any hit.

- [ ] **Step 1: Apply the mainbar.pl fix, compile, smoke render**

`$PERL -c mainbar.pl`; `t/render.sh crit && t/compare.sh before crit` → exit 0.

- [ ] **Step 2: Commit the fix**

```bash
git add mainbar.pl
git commit -m "Declare istext/ismd unconditionally" -m "my \$x = 1 if COND leaves \$x in an unspecified state when COND is false; perlcritic severity 5 forbids it. Both variables are only tested for truth, so ternary 1/0 renders identically." -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

- [ ] **Step 3: Write `.perlcriticrc` and run perlcritic by hand**

Run: `~/perl5/perlbrew/perls/perl-5.38.2/bin/perlcritic --profile .perlcriticrc *.pl t/*.pl`
Expected: `... source OK` for every file. Any remaining violation: fix it in the code if it is a one-line value-preserving change, otherwise add an exclusion with a comment and tell Rob.

- [ ] **Step 4: Write `lint.sh`; run it**

Run: `./lint.sh; echo "exit=$?"` → `exit=0` and one `info: severity-4 violations: N` line. Record N in `t/README.md`.

- [ ] **Step 5: Prove the checks fire**

Append a tab-indented line with trailing spaces to a copy of `mkdef.pl` named `zz_lint_probe.pl`, run `./lint.sh` → exit 1 naming `zz_lint_probe.pl` for both checks and for perlcritic (no `use strict`). Delete the probe.

- [ ] **Step 6: Pin Review Focus 6**

Run: `time ./lint.sh` → under 10 seconds. Then run lint.sh's `find` command on its own and pipe it to `grep -c '^\./journal/'` → `0` (it never lists an entries path).

- [ ] **Step 7: Commit**

```bash
git add .perlcriticrc lint.sh t/README.md
git commit -m "Add perlcritic policy and lint.sh" -m "Severity 5 is the gate for this pass; RequireBarewordIncludes is excluded because the engine is require'd fragments by design. lint.sh also enforces four-space indentation, no trailing whitespace and a final newline over the code files, excluding served static files by name, and prints the severity-4 count so the next pass starts with a baseline." -m "Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: Acceptance, close the bubble, hand off

- [ ] **Step 1: Full-tier render and compare**

Run: `t/render.sh after --full && t/compare.sh before after; echo "exit=$?"`
Expected: `exit=0`. If not, re-render `--full` at the midpoint commit (`git stash` is not needed; check out the commit in place, render, return to the branch tip) and bisect.

- [ ] **Step 2: Lint and compile**

`./lint.sh` → exit 0; `for f in *.pl t/*.pl; do $PERL -c $f; done` → all OK.

- [ ] **Step 3: Compose the closing message**

Write `SCRATCH/close-msg.txt`: first line is the closing subject (Rob's words if he gave them, else `DONE modernating code`), blank line, then: baseline and after snapshot names with their `meta.txt` HEADs, "full tier 180,648 pages, diff -r empty", lint exit 0, live cross-check result from Task 3, and the complete `stderr-report.txt` from `after` (counts and unique messages; trim example pages to 3 each).

- [ ] **Step 4: Close the bubble**

Follow the `close-bubble` skill: `git branch --show-current` → `get-modern`; `git close-bubble --dry-run` → names a71779f1 `BEGIN modernating code`; then `git close-bubble "$(cat SCRATCH/close-msg.txt)"`; then `git push`.

- [ ] **Step 5: Tell Rob**

Report: bubble closed and pushed on `get-modern`; master untouched; the deploy watcher will copy the `.pl` files when he runs it (or `scp` them); nothing else needed on the server; the warnings report headline counts; the two vetoable decisions (journal.pl two-arg open with no-critic; RSS left out of the live cross-check).

---

### Task 9: After Rob deploys

- [ ] **Step 1: Live cross-check against the deployed code**

Run: `t/live-check.sh; echo "exit=$?"` → 40 `PASS`, `exit=0`. Report any `DIFF` with its diff to Rob.

- [ ] **Step 2: Note the next-pass candidates**

Append to `t/README.md` (plain commit, not part of the bubble): replace `system "ls -1R"` with File::Find; the index writer's title regex missing `md` (every `.md` entry gets an undef title and an RSS link ending in `#`); the duplicated `$printer_version` block; the duplicated charset branch; `new CGI` indirect syntax; the severity-4 count.
