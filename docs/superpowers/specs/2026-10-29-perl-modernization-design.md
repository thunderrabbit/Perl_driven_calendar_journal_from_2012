# Perl modernization, light-touch pass — design

Date: 2026-10-29. Author: Rob Nugen with Claude. Status: builder-checked, awaiting Rob's approval.

## Intent

Nothing is broken. Rob wants this Perl code to keep running indefinitely, the
way he has been bringing his PHP sites up to current versions: regular,
low-drama updates rather than a rescue later. This pass brings the code to an
idiomatic baseline for perl 5.38.2 (the DreamHost server's perl) and leaves
behind the tooling that makes the next pass cheap: a local way to render every
output file and diff it, a perlcritic policy, and a lint script.

Rob chose the light touch deliberately: keep the current structure of
`require`d script fragments sharing globals, make it strict-clean, and defer
turning the helpers into a real package to a later "deeper" pass. The light
touch should make the deeper one easier: once strict passes, every shared
variable is named and visible.

## Goals

1. Every `.pl` file compiles under `use strict; use warnings;` on perl 5.38.2.
2. Rendered output is byte-identical to the pre-change baseline across the full
   matrix (see Harness) under a pinned clock.
3. Every warning `use warnings` surfaces across the full matrix is collected
   and reported (count, unique messages, which pages), NOT silenced. Rob wants
   to see the list before deciding what to do about each one; silencing or
   fixing them is a later pass.
4. perlcritic at severity 5 ("gentle") reports nothing, with a committed
   `.perlcriticrc`.
5. Source files we own (`*.pl`, `*.sh`, `t/`, `docs/`, `*.md`, `*.txt`):
   four-space indentation, no tab indentation, no trailing whitespace, newline
   at end of file. A lint script enforces all of this and perlcritic in one
   command.
6. A reproducible harness that any future pass can run: render before, render
   after, diff.

## Non-goals (deferred to the deeper pass)

- Converting helpers into packages/modules with explicit arguments and tests.
- Replacing CGI.pm. It is on the server and in core-adjacent packaging; swapping
  it is structural work.
- Replacing `system "ls -1R > ls-1R.txt"` in the index writer with File::Find.
  Output-equivalent in theory, but it changes behaviour the HTML diff cannot
  see. Listed as the first candidate for the next pass.
- Full perltidy reformatting (line breaks, spacing, brace style). This pass
  normalizes indentation only.
- Any change to the entries repo (`journal/journal/`). Claude never commits
  there.
- Changing the rendered HTML in any way, including fixing the copy-pasted
  `$printer_version` block in journal.pl or the duplicated charset branch in
  draw_header.pl. Note them, do not fix them.
- Silencing warnings. No `no warnings` blocks, no defined-guards added purely
  to quiet a warning. Known sources the reviewer found, to be reported not
  fixed: `$ls1rfile` is undef in journal.pl's print-mode block (set only
  inside `sidebar()`), draw_header's charset comparison on year and month
  pages (Strptime returns undef), sidebar's `eq ""` family, missing `type`
  param, and the index writer's title regex accepting only html|txt so every
  `.md` entry has an undef title and an RSS link ending in a bare `#` (a real
  bug, noted for the next pass).
- Normalizing whitespace in served static files that are not code:
  `css/example.css` (109 CRLF lines with trailing whitespace),
  `css/m.robnugen.com.j.css`, `japan/dartmouth.edu_kanji.html`, `403.shtml`,
  `500.shtml`, `js/README.ROB`. They are served bytes the harness cannot
  see; the lint script excludes them.

## Anti-goals

- A diff in rendered output that Rob did not explicitly judge a shrug. The
  baseline is the oracle; the harness, not a reviewer's eye, decides.
- Anything that requires a change on the server beyond copying the files.
  The server has no perlcritic, perltidy, faketime or perlbrew and will not
  get them. All tooling runs on Lemur 13.
- Touching system perl on Lemur 13. Everything Perl-side goes into perlbrew.
- Leaving the deploy watcher or the server's path layout different from today.

## Constraints and facts the builder needs

- Repo: `~/work/rob/robnugen.com/journal` (outer, the engine). Entries live in
  the nested inner repo `~/work/rob/robnugen.com/journal/journal` (16,792 entry
  files over 6,520 distinct days, 40 year dirs, 380 month dirs; 12,255 .html,
  4,519 .md, 18 .txt, 183 .comment). The inner repo's `.gitignore` already
  hides `preformat*`, `*.rss` and `ls-1R*`, so the index writer may write into
  it locally.
- Server: perl 5.38.2, modules CGI, XML::RSS, Date::Manip, DateTime,
  Number::Format present. Text::RobMiniMarkdown is at
  `/home/barefoot_rob/dev/Text-RobMiniMarkdown/lib` (journal.pl has a `use lib`
  for it). Source: github.com/thunderrabbit/Text-RobMiniMarkdown (public). The
  server checkout is exactly GitHub HEAD 269ada4f "Parse Clickable image
  thumbnails" with a clean tree (checked 2026-10-29), so a plain clone of
  master reproduces it. It is NOT on Lemur 13 yet.
- Lemur 13: system perl 5.34 (do not use), perltidy 20250711 already on PATH,
  gcc/make present, no perlbrew, no cpanm, no Perl::Critic, no PPI, no CGI, no
  XML::RSS, no Date::Manip, no Number::Format, no faketime. `bwrap` exists but
  is not needed.
- The code cannot run locally today. Three hardcoded server paths:
  `$journal_base` and friends in `setup_journal.pl`, `$nav_settings_file` in
  `single_navigation_bar.pl`, and the rate-limit file
  `/home/barefoot_rob/preformatted_last_run.txt` in
  `preformatted_journal_index_writer.pl` (`iMayRunYet`).
- Time-dependent output: "Rob is N days old today" (draw_navigation.pl,
  DateTime->now Asia/Tokyo), "run on yyyy/mm/dd" and future-entry exclusion
  and copyright year in the index writer (localtime + 16h), RSS lastbuilddate
  (Date::Manip "Now").
- Hash-order dependence: the index writer loops `foreach $journal_type (keys
  %journal_regex_type)`. Perl randomizes hash order per process, so the
  script's own stdout (the link listing) varies run to run. Per-type output
  files do not.
- CGI.pm command-line mode: `perl journal.pl type=all date=2001/05/06` takes
  parameters from @ARGV. With NO arguments it reads parameters from STDIN and
  blocks, so every invocation passes at least one parameter or redirects
  stdin from /dev/null.
- Git: work happens on branch `get-modern` inside the already-open bubble
  `BEGIN modernating code` (8ef94d62 before the history rewrite, a71779f1
  after). Claude cannot commit on master; Rob integrates. Commit style: short
  imperative subjects, body explains why, atomic commits split by layer. Close
  the bubble with `git close-bubble` from the topic branch when done.
- Deploy: `scp_modified_files_to_perlrobnugencom.sh` watches the WHOLE outer
  tree (only `.git/*` excluded), including the inner entries repo, and copies
  every closed file to the server. No build step. Nothing new is needed on the
  server because the path overrides default to today's values. Two
  consequences for the harness: (a) anything written inside the outer tree
  while the watcher runs is deployed, so the harness must never write there;
  (b) entries reach the server the moment Rob saves them, so for old dates the
  server's entries tree and the local working tree are the same content.

## Decisions Rob made

- Light touch now; deeper restructure later.
- Four-space indentation. Indentation only for this pass; no other perltidy
  reformatting.
- Source whitespace rules: no trailing spaces, newline at end of file.
- Rendered HTML: indentation and attribute order are a "shrug" if they change;
  anything else is a regression. (In practice this pass expects zero diff; the
  shrug only licenses a canonicalizer if one is ever needed. See Harness.)
- perlbrew 5.38.2 from the start, matching the server exactly.
- Warnings are to be seen, not silenced, in this pass (2026-10-29).

## Decisions Claude made (Rob can veto)

- perlbrew lives in the default `~/perl5/perlbrew`; the build is named
  `perl-5.38.2`. Harness and lint scripts call that perl by absolute path so
  nothing depends on the user's shell. Modules installed with perlbrew's
  cpanm: CGI, XML::RSS, Date::Manip, DateTime, DateTime::Format::Strptime,
  Number::Format, HTML::Entities, Perl::Critic, PPI, Perl::Tidy.
- faketime from apt (`faketime`, 0.9.8). Rob runs the apt install.
- Text-RobMiniMarkdown cloned to `~/work/rob/Text-RobMiniMarkdown` (sibling of
  robnugen.com), reached via `PERL5LIB`, no code change for it.
- Path overrides are environment variables read in the three places listed
  above, defaulting to the current hardcoded values:
  `JOURNAL_BASE`, `JOURNAL_NAV_FILE`, `JOURNAL_LASTRUN_FILE`. This is the first
  code commit of the bubble and the baseline is rendered with it in place.
  To prove the baseline is really "before", the harness fetches a sample of
  pages from the live site and compares them to the local render of the same
  URLs (see Harness, "live cross-check").
- Nothing the harness produces lives inside the outer repo tree. Working
  directory is `~/.cache/journal-harness/`: `entries/` is a frozen rsync
  snapshot of the inner repo's working tree (taken once, so "before" and
  "after" render the same content and untracked drafts cannot drift between
  runs), and `render/<name>/` holds snapshots such as `before` and `after`.
  `JOURNAL_BASE` points at the frozen `entries/`, so the index writer's
  `preformatted_index_*`, `*.rss` and `ls-1R.txt` land there too. The harness
  refuses to start if the deploy watcher (`inotifywait` from
  `scp_modified_files_to_perlrobnugencom.sh`) is running. Harness scripts live
  in `t/` (Perl convention) with a short README.
- Determinism: harness sets `PERL_HASH_SEED=0 PERL_PERTURB_KEYS=0` and a fixed
  `TZ`, and runs everything under `faketime '2026-10-29 12:00:00'`.
- Comparison is `diff -r` byte-for-byte. An HTML canonicalizer (sort
  attributes, collapse whitespace outside `<pre>`, `<textarea>`, `<script>`) is
  NOT built unless a diff appears that Rob judges a shrug. `<pre>` content
  is meaningful: the calendar and .txt entries render inside it.
- perlcritic: `.perlcriticrc` committed with `severity = 5` as the gate for
  this pass. The lint script also prints the severity-4 count as information
  so the next pass has a baseline, without failing on it.
- Lint script `lint.sh` at repo root: perlcritic over all `.pl`, plus trailing
  whitespace, missing end-of-file newline, and tab-indentation checks over the
  code files listed in goal 5, with the served static files excluded by an
  explicit list in the script. Exit non-zero on any hit. Optional one-liner in the
  README to install it as `.git/hooks/pre-commit`; not installed
  automatically.
- Strict conversion technique: shared globals get `our` declarations in the
  file that owns them (setup_journal.pl for config; sidebar.pl for
  `$year/$month/$day/$lastday/$nextday`; journal.pl for request state such as
  `$date`, `$journal_type`, `$debug`, `$printer_version`, `$require_reload`,
  `$indexname`). Every other file declares `our` for what it reads. Locals that
  were accidentally global become `my`. No variable is renamed and no value
  changes.
- Opens: the ten bareword two-argument opens become lexical three-argument
  opens. Where the original had `or die`, keep it. Where the original silently
  continued on failure (and in the print-mode block, where the filename is
  undef), keep continuing silently so behaviour and output are unchanged; the
  resulting warnings are part of the report, not something to suppress. Reads stay byte-oriented; no `:encoding`
  layer is added, since the output must stay byte-identical.
- The `local $/` slurp idioms are kept where they are; only the filehandle
  style changes.

## Harness

Purpose: render every output the engine can produce, before and after, and
diff. Scripts under `t/`, invoked with the perlbrew perl.

Inputs and matrix:

- Index writer once per run (it loops all 13 types itself). Produces
  `preformatted_index_for_<type>_entries.html` and `<type>_entries.rss` in
  `$JOURNAL_BASE`, plus `ls-1R.txt`. The harness copies these into the snapshot
  directory. Its stdout listing is sorted or ignored (hash order).
- journal.pl for each of: every year page, every month page, every entry day
  (6,520), each with `print=0` and `print=1`. Smoke tier: `type=all` only for
  days, all 13 types for year and month pages. Full tier: all 13 types for
  everything, roughly 170,000 invocations, run with `xargs -P`.
- Output file naming encodes the parameters, e.g.
  `journal/all/2001-05-06.html` and `journal/all/2001-05-06.print.html`.
  stdout and stderr captured separately; stderr summarized at the end (count
  of lines, unique messages).
- `date=nil` (no date) and an invalid date are included once per type to
  cover the redirect header path.

Live cross-check: a list of ~40 URLs (mix of years, types, print mode, .md and
.html and .txt days, the redirect case) fetched from https://robnugen.com and
compared to the local render of the same parameters. It is a sanity check that
the local render reproduces production, not the oracle; the oracle is
before/after. To keep content drift out of it, every URL uses a date before
2025 and the check normalizes exactly these known lines: the "days old" line,
the "run on" line, RSS/lastbuild dates, the copyright year, and the sidebar
link to the newest entry (which depends on whatever was written most
recently). Anything else differing is reported. Run once to validate the
baseline and once after deploy.

Acceptance for the pass: full tier `diff -r before after` empty; the stderr
report exists and is attached to the bubble's closing commit body (counts and
unique messages); `lint.sh` exits 0; live cross-check passes after deploy.

## Commit shape (inside the open bubble on get-modern)

1. This design document.
2. Path overrides (three env seams, defaults unchanged).
3. Harness scripts, `.render/` ignored, `t/README`.
   (Baseline rendered here. Not a commit; evidence in the PR/bubble body.)
4. Indentation normalization, one commit, mechanical, no other change.
   (Re-render, diff empty.)
5. strict + warnings + `our`, one commit per file or per natural group.
   (Re-render after each, diff empty; warnings report regenerated.)
6. Three-argument lexical opens.
7. `.perlcriticrc` and `lint.sh`.
8. Close the bubble.

Steps 4 to 7 can be reordered by the builder if it reduces churn, but each
commit must leave the harness diff empty.

## Left to the builder

- Exact perltidy flags that change indentation only (e.g. freezing newlines
  and whitespace) and how to verify the commit is indentation-only.
- Harness implementation language (bash or Perl) and layout under `t/`.
- Which perlcritic policies, if any, to disable at severity 5 to fit the
  `require`-fragment structure, with a comment per exclusion.
- Order of the strict conversion across files.
- The 40-URL cross-check list.
