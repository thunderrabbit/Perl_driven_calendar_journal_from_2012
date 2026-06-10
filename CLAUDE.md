# CLAUDE.md - Journal System

Perl CGI static-site generator for Rob's personal journal (1985–present),
served at https://robnugen.com/journal/

## Commit guard
Claude CANNOT commit/merge/push on `master` — a git wrapper blocks it
(exit 77). Do work on a feature branch; Rob integrates to master.

## Two nested `journal/` directories — TWO SEPARATE GIT REPOS

The inner `journal/` is the **content**: decades of Rob's actual journal
entries, kept in their own repo so the writing lives independently of the Perl
engine that renders it. Its history is long and personal — alongside ordinary
entry commits, recent history is a voice-transcription practice where Rob
dictates and **each spoken word is its own commit** (hence thousands of them;
read HEAD backward and the commit subjects form sentences). The outer
`journal/` is that rendering engine. Two `journal/` levels, two repos:

```
robnugen.com/journal/          ← OUTER repo: the Perl display engine
                                  remote: Perl_driven_calendar_journal_from_2012.git
                                  (.gitignore lists `journal/`, so it ignores the inner repo)
└── journal/                   ← INNER repo: the actual entries (content)
    ├── .git/                    remote: robnugen-journal-entries.git
    ├── 1985/ … 2026/            chronological entry tree (YYYY/MM/)
    └── css/                     journal.css (has .claude/.chatgpt classes), style.css
```

- The **absolute path to entries is `…/robnugen.com/journal/journal/YYYY/MM/`** —
  `journal` appears twice on purpose. From the OUTER repo root descend **one**
  more `journal/` (`journal/2000/05/…`); `journal/journal/…` is one level too many.
- Entries are **gitignored by the outer repo** and tracked only in the inner
  repo, so the outer `git status` never shows entry files — expected, not "empty."
- Keep code (outer) and content (inner) histories separate — never `git add`
  entries from the outer repo.
- Deploy host path: `/home/barefoot_rob/robnugen.com/journal/journal/`.

## Scripts
- `journal.pl` — main CGI entry point (served at `/journal.pl`; `.htaccess` in
  the doc root rewrites to `/journal/journal.pl`).
- `preformatted_journal_index_writer.pl` — generates HTML indexes + RSS feeds.
- `setup_journal.pl` — config: paths, URLs, and the `%journal_regex_type` patterns.
- Other `.pl` (mainbar, sidebar, draw_*, displayFile) are display helpers.

## Deploy
Run `scp_modified_files_to_perlrobnugencom.sh`: `inotifywait` watches the tree
and scp's each changed file to `barefoot_rob@drc:…/robnugen.com/journal/`
(ssh alias `drc`). No build step.

## Entry Type Patterns
Defined in `setup_journal.pl` via `%journal_regex_type`:
- `all` — `^\d\d.*?`
- `dreams` — `^\d\d.*?dream.*`
- `sleepy` — `^\d\dzz.*?`
- `excited` — `^\d\d.*?!.*`
- `SoML` (State of My Life) — `^\d\d.*?(?:soml|state.*?(?:of|my).*?life).*`
