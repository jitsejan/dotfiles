# Personal defaults

How I want Claude to work in any project. A project's own `CLAUDE.md` wins
where the two differ. Employer-specific defaults (tools, people, house style)
live in an untracked file on each machine:

@~/.claude/local.md

## Writing

- Short and plain. A few lines of why, not essays. No em dashes.
- Write for the person reading it, in the words they use. Outward text (PRs,
  issues, chat) should read like a person wrote it.
- Label every reference: "PR #12", "issue #34", "ticket #56", and name the repo
  or tracker when there is more than one. Never a bare number.
- No AI attribution anywhere: no `Co-Authored-By`, no "Generated with" lines in
  commits, PRs or comments.
- Lead with the answer or the recommendation. When there are options, say
  which one and why, instead of listing them all equally.

## Tracking work

- Every change starts from an issue: issue, then branch, then code. If the
  organisation also uses another tracker, the issue gets a twin there and each
  links to the other.
- Before starting, check the work doesn't already exist on another branch
  (`git log --all -- <path>`) or in another repo.
- Branches say what they do: `<type>/<issue>-<what>` or the project's own form.
- One PR per purpose. When the scope grows mid-way, stop and re-scope with the
  owner rather than extending the PR. Park side-quests as their own issue.
- PR titles are Conventional Commits, `type(scope): what changes`, lowercase,
  no full stop. Types: feat, fix, docs, build, ci, refactor, test, chore. The
  scope is optional. The title is the changelog line.
- PR descriptions: `Closes #N` first (plus the tracker link), then why, what
  changed, how it was checked, and what was left out or not verified.
- Commit messages explain why, state trade-offs and anything that silently
  changes behaviour. Issue references in lowercase: `refs #N`, `closes #N`.
- Labels, at most one per group: source (which system), area (which part),
  state (`blocked`, `parked`). The kind comes from the PR title.
- Record dependencies on the issue: blocked by, blocks, and work that lives on
  an unmerged branch.

## Outward actions

- Anything others see (messages, posts, PRs, issue writes, merges, published
  pages) is drafted first unless I have said to send it. Say where the draft is.
- Nothing outward between 00:00 and 08:00 local time. Check the clock first;
  local work can carry on.
- Pace actions that notify people: merges at least 10 minutes apart with main
  green, status changes a minute apart, replies not seconds after a question.
- Decisions belong to their owner. Prepare the question and the options; don't
  decide for them.
- Never delete or overwrite shared things (labels, tickets, branches, data)
  without saying what goes and keeping a record of it.

## Verifying

- Check what you claim. Before saying a branch is complete, build it from a
  clean checkout; `.gitignore` can silently leave files out.
- Measure, don't guess. If an estimate turns out wrong, say so and correct it.
- Before building infrastructure or a deployment, find out where the thing
  already runs and who owns it.
- Say plainly what was not verified (not run on a cluster, not tested against
  real data).
- Long jobs: know the runner's time limits and run past them detached; check
  progress instead of assuming.

## Secrets and personal data

- Never print, paste or ask for a secret in chat. Point to the file it belongs
  in. If one was pasted, say so and suggest rotating it.
- Secrets in git only when encrypted (SOPS or similar), values only.
- Extract and model the least personal data that does the job. Special-category
  data (health, ethnicity, gender, disability and the like) needs a recorded
  decision before it is touched. When in doubt, leave it out and say what was
  left out.

## Python

- uv for everything: `uv run`, `uv add`, `uv sync`, `uvx` for one-off tools.
  No pip, no manual virtualenvs.
- `pyproject.toml` is the single source: `requires-python`, dependencies, and
  dependency groups for anything not needed at runtime (dev tools, dashboards),
  so deploy images stay lean. Commit `uv.lock`.
- ruff for linting and formatting; run both before committing.
- Small modules with docstrings that say why, not what. Match the surrounding
  code's naming and comment density.
- Configuration comes from one place per concern (env var or config file),
  never hardcoded per call site.

## Testing

- pytest. Every change that alters behaviour comes with a test; every bug fix
  with a test that fails without the fix.
- Unit tests need no network, no credentials and no warehouse. Mock at the
  boundary (the HTTP call, the API client) using the real response shape.
- Isolate the environment: an autouse fixture clears env vars the code reads,
  so a developer's shell can't change the result.
- Fixtures live in the `conftest.py` closest to the tests that use them;
  `parametrize` instead of copy-pasted tests.
- Integration and smoke tests are separate from unit tests: build the real
  artifact (image, package) in CI and check it starts and loads, without
  touching shared environments.
- The full suite passes before pushing.

## Memory

- Save what was learned about how I work, with the reason. Once a lesson holds
  in a second project, it belongs in this file or a skill instead.
- Never store secrets or other people's personal details in memory.
