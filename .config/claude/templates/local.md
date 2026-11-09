# Employer defaults

Everything in here is specific to one organisation. `scripts/setup_claude.sh`
copies this template to `~/.claude/local.md` on a new machine, and the tracked
`.config/claude/CLAUDE.md` imports it with `@~/.claude/local.md`.

That copy stays on the machine and is never tracked. This repo is public, so
client names, system names, tracker URLs and colleagues' names do not belong in
it. Fill the copy in, not this file.

Delete the lines that do not apply. An empty heading is better than a wrong
answer, because Claude treats what is written here as true.

## Who and where

- Organisation: {{ORG}}
- Homepage: {{ORG_URL}}
- Repos live in:
- My role on the engagement:

## Tracking work

- Primary tracker (issues, and the org that owns them):
- Second tracker, if work has to be mirrored, and which one wins:
- Branch form, when it differs from `<type>/<issue>-<what>`:

## House style

- Visual work uses the `{{ORG_SLUG}}-style` skill, derived from {{ORG_URL}}.
  `scripts/setup_claude.sh` stubs it in `~/.claude/skills/`; fill in Character
  and Tokens by looking at the site. It stays out of this repo.

## Data

- Systems that carry personal data:
- Special-category data (health, ethnicity, gender, disability and the like),
  where it lives and what has already been decided about it:
- Where redaction or masking happens, and what it does not yet cover:

## People

Names, roles and who decides what. Useful because it stops Claude guessing an
owner, and because "ask the owner" is only actionable if the owner is named.

-

## Anything Claude should not do here

Constraints that come from the organisation rather than from me. Access that is
not mine to grant, systems that are read-only, environments not to be touched.

-
