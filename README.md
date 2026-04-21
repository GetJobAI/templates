# GetJobAI Resume Template

Typst resume template with three visual styles. ATS compatibility first, aesthetics second.

Requires **typst 0.13+** (developed on 0.14.2).

## Files

| File | Purpose |
|---|---|
| `template.typ` | Main deliverable — exports `resume(data)` |
| `tests/*.typ` | Self-contained test files; each imports `template.typ` and calls `resume(data)` |

`template.typ` is a library: it exports a single `resume(data)` function. Test files in `tests/` are the entry points for local dev. In production the Export Service (and typst.ts) calls `resume(data)` directly with data from `resumes.parsed_data` JSONB.

Style priority: `--input style=X` > `data.style` > `"professional"`.
The Export Service sets `data.style`; the CLI `--input` flag overrides it.

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
just tests                     # compile all tests/*.typ
just check                     # compile all + pdftotext -layout on each
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

**German market:**
- Sample data uses `MM.YYYY` date format
- Language levels render as full CEFR text ("Elementary (A2)") rather than bare codes — A1/B1/C1 are also German driving licence categories, bare codes are ambiguous

**Diff view:**
- `#diff-added[…]` and `#diff-deleted[…]` are defined as green-underline / red-strikethrough — no-ops unless a diff tool injects them, compatible with `typdiff` marker style

## What's not Included

- **Colour toggle** — no flag to strip accent colours for a plain-black ATS submission; all three styles render in colour
- **Photo field** — not planned for MVP; the Export Service has no image pipeline
- **German-language headings** — section names are English; a Lebenslauf variant would need Berufserfahrung / Ausbildung / Kenntnisse etc.
- **Single-page enforcement** — no hard clip at page 1; content overflows naturally (correct for German CVs, which expect 2–3 pages)
- **Formal ATS testing** — `pdftotext -layout` passes cleanly; not yet run through Jobscan or Affinda with a real job posting

**Known quirk:** In the professional style, `pdftotext` without `-layout` may split "Jane Doe" across two lines due to the large bold font's word spacing. With `-layout` (and in real ATS parsers that read the PDF content stream directly) it's a single text run and parses correctly.

## Data Schema

```typst
#let data = (
  style: "minimal",   // optional — "professional" | "minimal" | "technical"
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
    // level: full CEFR text preferred — "Native", "Professional Working (C1)", etc.
    (name: "...", level: "..."),
  ),

  projects: (
    (name: "...", description: [...], url: "..."),  // url optional, without https://
  ),
)
```

## Planned

- **Colour toggle:** add a `monochrome` sys input; wrap accent colors in a helper `if monochrome { black } else { theme.accent }`. Useful for ATS submissions where colour can confuse older parsers.
- **Affinda smoke test in CI:** Affinda has a free tier (50 req/month) with a REST API — piping `resume.pdf` through it produces structured JSON that can catch extraction regressions automatically.
- **German headings:** a `--input lang=de` input could swap section titles; should map them in a dict `("Experience": "Berufserfahrung", …)` keyed by the lang input.
- **Photo field:** render an optional `contact.photo` path as a right-floated image at the top of the contact block. Verify the text stream order is unaffected before shipping.
- **`pdftotext` as a CI smoke test:** already works locally (`just check`); worth running in a GitHub Actions step to catch layout regressions across commits.

## ATS Extraction Check

```bash
pdftotext -layout pdf/default.pdf -
# or run all at once:
just check
```

All styles produce clean linear output: section headings in order, dates on the same line as company names, no scrambled text.

## Credits

Structure and spacing approach inspired by:

- [clickworthy-resume by Abdullah Hendy (MIT)](https://github.com/AbdullahHendy/clickworthy-resume)
- [guided-resume-starter-cgc (MIT)](https://github.com/typst/packages/tree/main/packages/preview/guided-resume-starter-cgc)
