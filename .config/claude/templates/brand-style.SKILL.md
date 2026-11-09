---
name: {{ORG_SLUG}}-style
description: {{ORG}}'s visual style (as on {{ORG_URL}}) for any page, artifact, dashboard, slide or diagram made for {{ORG}} work. Use it before designing anything visual, unless the user asks for a different look.
---

# {{ORG}} visual style

Taken from {{ORG_URL}}'s own CSS ({{DATE}}). Use the typography and palette
only; never reproduce the {{ORG}} logo.

<!--
How to fill this in.

Keep the skill in ~/.claude/skills/{{ORG_SLUG}}-style/SKILL.md. It is employer
material, so it does not belong in this public repo.

Work in this order. Character first, because it is the part that decides
whether a page looks right, and the part no scraper can produce.

1. Open the site. Write Character from what you see: two or three sentences in
   plain words. What is the page made of, what is deliberately absent, what is
   the one recurring motif. "Quiet and editorial: white page, black ink, lots
   of space, hairlines instead of boxes and shadows" is doing more work than
   any hex value below it.
2. Read the computed styles for the fonts and the colours actually used, rather
   than whatever a brand PDF claims. Devtools, or `curl` the stylesheet.
3. Fill Tokens with the handful that recur. Six to twelve. A long palette means
   you have copied incidental values rather than found the system.
4. Fill Components only where the site has a real opinion. If it has no cards,
   do not invent a card.
5. Leave Reference empty until the first page is built, then link it.

Delete this comment when the skill is written.
-->

## Character

<Two or three sentences. The register, the motif, what is deliberately absent.>

## Type

- Headings: **<font>**, <weights>, <colour>, <tracking>.
- Body: **<font>**, <weight>, <colour>; muted text in <colour>.
- Where they load from:
  `<Google Fonts or other URL>`
- <Anything to avoid, e.g. no monospace for labels; use tabular-nums for figures.>

## Tokens

```css
:root{
  --bg:<>; --ink:<>; --muted:<>; --faint:<>;
  --rule:<>; --wash:<>;
  /* accents and status fills, named by meaning rather than by hue */
}
```

<Say whether the site has a dark mode. If it does not, say so and set
`color-scheme: light` rather than leaving it to the viewer's theme.>

## Components

- Buttons and chips:
- Cards and tables:
- Status:
- Links:
- Masthead:
- <Anything else the site clearly has an opinion about.>

## Reference

<Link one finished page built in this style, once there is one. It teaches the
next page faster than the tokens above.>
