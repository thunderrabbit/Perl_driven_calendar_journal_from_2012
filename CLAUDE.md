# CLAUDE.md - Journal System

This file provides guidance to Claude Code when working with the journal generation system.

## Project Overview

This is a Perl-based static site generator that processes decades of personal journal entries (1985-2025) and creates organized HTML indexes and RSS feeds. The system generates the public-facing journal at https://robnugen.com/journal/

## ⚠️ Two nested `journal/` directories — TWO SEPARATE GIT REPOS

This trips up navigation. There are **two** `journal/` levels, and the inner one is its
own repository:

```
robnugen.com/journal/          ← OUTER repo: the Perl display engine
                                  remote: Perl_driven_calendar_journal_from_2012.git
                                  (.gitignore lists `journal/`, so it ignores the inner repo)
└── journal/                   ← INNER repo: the actual entries (content)
    ├── .git/                    remote: robnugen-journal-entries.git  (2460+ commits)
    ├── 1985/ … 2026/            chronological entry tree (YYYY/MM/)
    ├── css/
    └── transcriptions/
```

- The **absolute path to entries is `…/robnugen.com/journal/journal/YYYY/MM/`** — `journal`
  appears twice on purpose. From the OUTER repo root you descend **one** more `journal/`
  (`journal/2000/05/…`); writing `journal/journal/…` from there is one level too many.
- Entries are **gitignored by the outer repo** and tracked only in the inner repo, so the
  outer `git status` never shows entry files — that's expected, not "the tree is empty."
- The inner repo has its own multi-year history (e.g. a 1,900+ commit, one-word-per-commit
  voice-transcription "interview" running 2017→present). Keep code (outer) and content
  (inner) histories separate — never `git add` entries from the outer repo.
- On the deploy host this lives at `/home/barefoot_rob/robnugen.com/journal/journal/`.

## Key Architecture

### Core Components

- **Entry Storage**: Raw journal files in `/journal/journal/YYYY/MM/` organized chronologically
- **Static Generator**: Perl scripts that scan entries and generate HTML indexes
- **RSS Generation**: Creates RSS feeds for different entry types (all, dreams, etc.)
- **URL Rewriting**: `.htaccess` redirects for cleaner URLs

### Main Scripts

- `journal.pl` - Main journal display script
- `preformatted_journal_index_writer.pl` - Generates HTML indexes and RSS feeds
- `setup_journal.pl` - Configuration file with paths and regex patterns
- `mainbar.pl`, `sidebar.pl` - Navigation and content display

## Recent Updates (August 2025)

### RSS Feed Improvements ✅

Fixed multiple issues in `preformatted_journal_index_writer.pl`:

1. **URL Structure**: Updated `setup_journal.pl` to use `/journal.pl` instead of `/journal/journal.pl`
2. **Copyright**: Changed from hardcoded years list to "Copyright 1985-2025, Rob Nugen"
3. **Date Filtering**: Fixed year filtering to include all entries through current date (not just ≤2016)
4. **Content Descriptions**: Added file content reading to generate 200-character previews in RSS items

### URL Rewriting Setup ✅

Created `.htaccess` in document root (`/home/thunderrabbit/work/rob/robnugen.com/.htaccess`) with:
```apache
RewriteEngine On
RewriteRule ^journal\.pl$ /journal/journal.pl [L,QSA]
```

**⚠️ IMPORTANT**: This `.htaccess` file needs to be copied to a `static/` directory so Hugo can include it in the generated site. Without this, the URL rewriting won't work in production.

### Pending Issues

- **RSS Regeneration**: RSS feeds still show old URLs (`/journal/journal.pl`) because the generation script needs to run again to pick up configuration changes
- **Hugo Integration**: The `.htaccess` file needs to be moved to Hugo's static directory for deployment

## Entry Type Patterns

Defined in `setup_journal.pl` via `%journal_regex_type`:
- `all` - All entries: `^\d\d.*?`
- `dreams` - Dream entries: `^\d\d.*?dream.*`
- `sleepy` - Sleep entries: `^\d\dzz.*?`
- `excited` - Excited entries: `^\d\d.*?!.*`
- `SoML` - State of My Life: `^\d\d.*?(?:soml|state.*?(?:of|my).*?life).*`

## File Structure

```
journal/                    # Perl script repository
├── journal.pl             # Main display script  
├── setup_journal.pl       # Configuration
├── preformatted_journal_index_writer.pl  # Generator
├── journal/               # Raw entry storage
│   ├── 1985/06/          # Chronological organization
│   ├── 1987/03/          
│   ├── ...
│   └── 2025/08/
└── css/
    └── journal.css        # Includes .claude and .chatgpt styling
```

## Integration with Dreams Analysis

The dreams.robnugen.com project will use this journal data for AI-powered dream analysis:
- Source entries identified by `*dream*.html` or `*dream*.md` filename pattern
- RSS feeds provide structured access to dream content
- 16,738+ total files spanning 40 years of personal journaling

## Development Notes

- RSS generation is throttled (currently 1 minute between runs)
- File content is read during RSS generation for descriptions
- The system handles both HTML and Markdown entry formats
- CSS classes `.claude` and `.chatgpt` available for AI assistant styling