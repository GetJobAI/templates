// GetJobAI resume template — three styles, single template.
// See README.md for full usage, data schema, and credits.

#let resume(data) = {
  let style-name = sys.inputs.at(
    "style", // cmd arg precedence: --input style=X
    default: data.at("style", default: "professional"),
  )

  // TODO: theme looks weird... extract it? Or extract everything after
  // it in a function with all those args and put 3 calls here with all the args?

  // All visual differences between styles live here.
  // Layout functions below are style-agnostic.
  let theme = if style-name == "minimal" {
    (
      font: ("New Computer Modern", "Libertinus Serif"),
      accent: black,
      muted: luma(100),
      rule-stroke: 0.4pt + luma(180),
      name-size: 20pt,
      section-size: 10.5pt,
      body-size: 10pt,
      entry-gap: 6pt,
      section-above: 10pt,
      section-below: 4pt,
      margin-x: 1.8cm,
      contact-sep: "  ·  ",
    )
  } else if style-name == "technical" {
    (
      // mono body — wider margins eat into line length, so pull them in a bit
      font: ("JetBrains Mono", "Libertinus Serif"),
      accent: rgb("#005f87"),
      muted: rgb("#555555"),
      rule-stroke: 1pt + rgb("#005f87"),
      name-size: 13pt,
      section-size: 9.5pt,
      body-size: 9pt,
      entry-gap: 4pt,
      section-above: 7pt,
      section-below: 3pt,
      margin-x: 1.2cm,
      contact-sep: " · ", // single-space as monospace makes double-space very wide
    )
  } else {
    (
      // professional
      font: ("Libertinus Serif",),
      accent: rgb("#1a3a5c"),
      muted: luma(80),
      rule-stroke: 0.6pt + rgb("#1a3a5c"),
      name-size: 24pt,
      section-size: 11pt,
      body-size: 10.5pt,
      entry-gap: 7pt,
      section-above: 12pt,
      section-below: 3pt,
      margin-x: 1.8cm,
      contact-sep: "  ·  ",
    )
  }

  set page(
    paper: "a4",
    margin: (
      x: theme.margin-x,
      y: 2cm,
    ),
  )

  set text(
    font: theme.font,
    size: theme.body-size,
    lang: "en",
    hyphenate: false,
  )

  set par(
    justify: false, // justified text can confuse some parsers with uneven spacing
    leading: 0.75em,
    spacing: 0em,
  )

  set list(
    indent: 0pt,
    marker: [•],
    body-indent: 0.6em,
  )
  show list: set block(
    above: 4pt,
    below: 0pt,
  )
  show list: set par(
    leading: 0.6em,
  )

  // Diff view markers — no-ops when not in a diff preview.
  let diff-added(it) = text(
    fill: rgb("#15803d"),
    underline(it),
  )
  let diff-deleted(it) = text(
    fill: rgb("#b91c1c"),
    strike(it),
  )

  // TODO: extract as function?
  // Section heading with a rule underneath. Always use standard English names
  // ("Experience", "Education", etc.) so ATS classifies sections correctly.
  let section(title) = {
    v(theme.section-above)

    text(
      size: theme.section-size,
      weight: "bold",
      fill: theme.accent,
      upper(title),
    )

    v(2pt)

    line(
      length: 100%,
      stroke: theme.rule-stroke,
    )

    v(theme.section-below)
  }

  // TODO: extract as function or inline (used only once)?
  // Contact block — lives at the top of the body, not in a PDF header/footer,
  // so parsers don't skip or misattribute it. All fields except name are optional.
  let contact-block(contacts) = {
    text(
      size: theme.name-size,
      weight: "bold",
      fill: theme.accent,
      contacts.name,
    )

    v(7pt)

    // box() prevents line breaks inside URLs (Typst breaks at '/' in links by default)
    let parts = ()

    if contacts.at("location", default: none) != none {
      parts.push(box(contacts.location))
    }
    if contacts.at("email", default: none) != none {
      parts.push(box(link(
        "mailto:" + contacts.email,
        contacts.email,
      )))
    }
    if contacts.at("phone", default: none) != none {
      parts.push(box(contacts.phone))
    }
    if contacts.at("linkedin", default: none) != none {
      parts.push(box(link(
        "https://" + contacts.linkedin,
        contacts.linkedin,
      )))
    }
    if contacts.at("github", default: none) != none {
      parts.push(box(link(
        "https://" + contacts.github,
        contacts.github,
      )))
    }

    // TODO: other contacts. Should let the user to specify whatsapp, signal, etc.

    text(
      size: theme.body-size - 0.5pt,
      parts.join(theme.contact-sep),
    )

    v(theme.section-above * 0.6)
  }

  // TODO: extract as function or inline (used once but in a loop)?
  // Work experience entry.
  // company and title are optional — omit both for a career-gap entry
  // (e.g. company: none, title: "Career Break — independent study").
  // Set hide: true to suppress an entry without removing it from the data.
  let work-entry(entry) = {
    if entry.at("hide", default: false) {
      return
    }

    // TODO: rewrite as code {} block? looks horrible
    block(below: theme.entry-gap)[
      #if entry.at("company", default: none) != none [
        #strong(entry.company) #h(1fr) #entry.dates \
      ] else [
        #h(1fr) #entry.dates \
      ]
      #if entry.at("title", default: none) != none {
        emph(entry.title)
      }
      #if entry.at("location", default: none) != none [
        #h(1fr) #text(
          size: theme.body-size - 0.5pt,
          fill: theme.muted,
        )[#entry.location]
      ]
      #v(3pt)
      #list(..entry.bullets)
    ]
  }

  // TODO: extract as function or inline (used once but in a loop)?
  // Education entry.
  // grade is a free-form string — "5.0 / 5.0", "1.3 (DE)", "94 / 100" — not assumed to be 4.0 GPA.
  // Set hide: true to suppress without removing from data.
  let edu-entry(entry) = {
    if entry.at("hide", default: false) {
      return
    }

    // TODO: this reads horribly
    block(below: theme.entry-gap)[
      #strong(entry.institution) #h(1fr) #entry.dates \
      #emph(entry.degree)#if entry.at("location", default: none) != none [
        #h(1fr) #text(
          size: theme.body-size - 0.5pt,
          fill: theme.muted,
        )[#entry.location]
      ]
      #if entry.at("grade", default: none) != none [
        \ #text(size: theme.body-size - 0.5pt)[Grade: #entry.grade]
      ]
    ]
  }

  // Skills as "Category: item, item, item" — linear text, no columns or tables.
  let skills-section(groups) = {
    for group in groups {
      block(below: 3pt)[#strong(group.category + ": ")#group.items.join(", ")]
    }
  }

  // Single certification on one line.
  let cert-entry(c) = block(below: 3pt)[
    #strong(c.name) · #c.issuer #h(1fr) #c.date
  ]

  // TODO: the spacing here is utter horror
  // Project entry.
  let project-entry(p) = block(below: theme.entry-gap)[
    #strong(p.name)#if p.at("url", default: none) != none [
      #text(fill: theme.muted)[ — ]#link("https://" + p.url)[#text(
        size: theme.body-size - 0.5pt,
      )[#p.url]]
    ] \
    #p.description
  ]

  // Languages as a single readable line.
  let lang-line(langs) = langs.map(l => l.language + " — " + l.level).join("  ·  ")

  // Document body — sections are omitted when their data arrays are empty or absent.

  contact-block(data.contact)

  if data.at("summary", default: none) != none {
    section("Summary")
    data.summary
  }

  let experience = data.at("experience", default: ())
  if experience.len() > 0 {
    section("Experience")
    for exp in experience {
      work-entry(exp)
    }
  }

  let education = data.at("education", default: ())
  if education.len() > 0 {
    section("Education")
    for edu in education {
      edu-entry(edu)
    }
  }

  let skills = data.at("skills", default: ())
  if skills.len() > 0 {
    section("Skills")
    skills-section(skills)
  }

  let certifications = data.at("certifications", default: ())
  if certifications.len() > 0 {
    section("Certifications")
    for cert in certifications {
      cert-entry(cert)
    }
  }

  let projects = data.at("projects", default: ())
  if projects.len() > 0 {
    section("Projects")
    for project in projects {
      project-entry(project)
    }
  }

  let languages = data.at("languages", default: ())
  if languages.len() > 0 {
    section("Languages")
    lang-line(languages)
  }
}
