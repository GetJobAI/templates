# GetJobAI Resume Template

Typst resume template with three visual styles. ATS compatibility first, aesthetics second.

Requires **typst 0.13+** (developed on 0.14.2).

This repository is the development home of the template: the test files and Justfile here exist to iterate on `template.typ` in isolation and to produce the figures used in the project paper. `template.typ` is the single deliverable — it is copied verbatim into the **`pdf-generator`** service repo, which compiles it in-memory from JSON resume data and serves the resulting PDF over HTTP. Nothing else in this directory ships; only `template.typ` crosses the boundary.

## Files

| File | Purpose |
|---|---|
| `template.typ` | Main deliverable — exports `resume(data)` |
| `tests/*.typ` | Self-contained test files; each imports `template.typ` and calls `resume(data)` |

`template.typ` is a library: it exports a single `resume(data)` function. Test files in `tests/` are the entry points for local dev. In production the `pdf-generator` service builds the `data` dictionary from resume JSON and calls `resume(data)` directly.

Style priority: `--input style=X` > `data.style` > `"professional"`.
The service sets `data.style`; the CLI `--input` flag overrides it for local dev.

## Styles

| Style | Font | Accent | Target |
|---|---|---|---|
| `professional` (default) | Libertinus Serif | Navy `#1a3a5c` | Corporate, Consulting |
| `minimal` | New Computer Modern | Black | Academic, Research |
| `technical` | JetBrains Mono | Steel `#005f87` | Engineering, Open-Source |

## Usage

Test files are the entry points. Compile with `--root .` so Typst can resolve `../template.typ`:

```bash
# Compile a specific test file
typst compile --root . tests/default.typ pdf/default.pdf

# Override style at the CLI (overrides data.style in the file)
typst compile --root . tests/default.typ pdf/default.pdf --input style=minimal

# Watch
typst watch --root . tests/default.typ pdf/default.pdf
```

Or use the Justfile:

```bash
just compile tests/default.typ # compile one file
just watch tests/carpenter.typ # watch one file (defaults to tests/default.typ)
just all                       # compile all tests/*.typ
just all-styles                # compile every test in all three styles
just check                     # compile all + verify every font is embedded
just clean                     # rm -rf pdf/
```

## What's Been Done

**ATS parsing:**
- Single-column layout throughout — no multi-column, tables, or floating objects
- `h(1fr)` for right-aligned dates: looks two-column visually, but is a single text stream in the PDF (verified with `pdftotext -layout`)
- Contact info in the document body, not in PDF header/footer regions (parsers often skip those)
- Standard section names: Experience, Education, Skills, Certifications, Languages, Projects
- `box()` around contact URLs prevents mid-path line breaks (`github.com/` + newline + `janedoe`)
- No icon glyphs — plain Unicode separators only
- Fonts are embedded by default (Typst guarantees this); Libertinus Serif and JetBrains Mono both cover the Cyrillic Unicode block for Cyrillic institution names

**Data handling:**
- All contact fields except `name` are optional and omit cleanly
- Education `grade` is a free-form string — supports `"5.0 / 5.0"` (Ukrainian 5-point), `"1.3 (DE)"` (German inverted scale), `"94 / 100"`, etc.
- Experience `company` and `title` are optional — omit both for career gap entries
- `hide: true` on any experience or education entry suppresses it without removing it from the data (useful for per-application tailoring in the diff view)
- Bullet points are Typst content blocks `[like this]`, so inline `*bold*` works naturally for tech keyword highlighting

**Localisation:**
- Section headings are overridable per-resume via `data.headings` — pass any subset; unset keys fall back to English defaults
- Sample data uses `MM.YYYY` date format
- Language `level` is rendered verbatim as `name — level`, so the caller controls the wording — CEFR codes (`C1`), full text (`Professional Working (C1)`), or `Native` all work. The `pdf-generator` service normalises LinkedIn proficiency strings to CEFR before sending

**Diff view:**
- `#diff-added[…]` and `#diff-deleted[…]` are defined as green-underline / red-strikethrough — no-ops unless a diff tool injects them, compatible with `typdiff` marker style

## What's not Included

- **Colour toggle** — no flag to strip accent colours for a plain-black ATS submission; all three styles render in colour
- **Photo field** — not planned for MVP; the Export Service has no image pipeline
- **Single-page enforcement** — no hard clip at page 1; content overflows naturally (correct for German CVs, which expect 2–3 pages)
- **Formal ATS testing** — `pdftotext -layout` passes cleanly; ATS tests pass with at least 80/100 with the other 20 points being subtracted for contents.

**Known quirk:** In the professional style, `pdftotext` without `-layout` may split "Jane Doe" across two lines due to the large bold font's word spacing. With `-layout` (and in real ATS parsers that read the PDF content stream directly) it's a single text run and parses correctly.

## Data Schema

```typst
#let data = (
  style: "minimal",   // optional — "professional" | "minimal" | "technical"
  headings: (         // optional — override any subset of section headings
    summary: "...",
    experience: "...",
    education: "...",
    skills: "...",
    certifications: "...",
    projects: "...",
    languages: "...",
  ),
  contact: (
    name: "...",      // required
    email: "...",     // optional
    phone: "...",     // optional
    location: "...",  // optional — metro area, not street address
    linkedin: "...",  // optional — without https://
    github: "...",    // optional — without https://
  ),
  summary: [...],     // optional — Typst content block

  experience: (
    (
      company: "...", // optional — omit for gap entries
      title: "...",   // optional
      dates: "MM.YYYY – MM.YYYY",
      location: "...", // optional
      bullets: (
        [Bullet text with optional inline *bold*.],
      ),
      hide: false, // optional — suppresses entry when true
    ),
  ),

  education: (
    (
      institution: "...",
      degree: "...",
      dates: "MM.YYYY – MM.YYYY",
      location: "...", // optional
      grade: "...",    // optional — free-form string
      hide: false,     // optional
    ),
  ),

  skills: (
    (category: "...", items: ("...", "...")),
  ),

  certifications: (
    (name: "...", issuer: "...", date: "MM.YYYY"),
  ),

  languages: (
    // level: rendered verbatim — CEFR code "C1", full text, or "Native"
    (name: "...", level: "..."),
  ),

  projects: (
    (name: "...", description: [...], url: "..."),  // url optional, without https://
  ),
)
```

## ATS Extraction Check

Inspect the extracted text layer to confirm parsers see clean, linear output — section headings in order, dates on the same line as company names, no scrambled text:

```bash
pdftotext -layout pdf/default.pdf -
```

`just check` is the automated guard: it compiles every test file and fails if `pdffonts` reports any unembedded font, since a missing font breaks text extraction. The `pdf-generator` service ships the same recipe.

## Credits

Structure and spacing approach inspired by:

- [clickworthy-resume by Abdullah Hendy (MIT)](https://github.com/AbdullahHendy/clickworthy-resume)
- [guided-resume-starter-cgc (MIT)](https://github.com/typst/packages/tree/main/packages/preview/guided-resume-starter-cgc)
