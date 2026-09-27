# omarchy-plugin-publish

An agent skill that gets an [Omarchy](https://omarchy.org) plugin through marketplace
submission with fewer review round-trips.

Publishing to the [plugin marketplace](https://plugins.omarchy.org/publish.html) means
opening an issue, passing automated validation, and then passing a human security review
that asks for things the automated checks never mention — secrets that leak through a
subprocess argument, output buffered before it is bounded, a filename trusted as an
identity, a dependency that can change after it was reviewed. Each missed item costs
another review cycle.

This skill front-loads that. It audits the plugin against the marketplace's machine-enforced
rules **and** the blockers maintainers actually raise, fixes what you authorize, and
assembles a submission tied to one exact commit.

It does not get anything approved. Approval is a maintainer's decision, and the skill will
not claim otherwise, promise a response time, or present its own audit as a security
clearance.

## Install

No clone needed for the agents with a plugin system — point them at this repository.

### Claude Code

```
/plugin marketplace add ayandexyz/omarchy-publishing-skill
/plugin install omarchy-plugin-publish@omarchy-publishing-skill
```

### Codex

```
codex plugin marketplace add ayandexyz/omarchy-publishing-skill
codex plugin install omarchy-plugin-publish@omarchy-publishing-skill
```

Or from inside the CLI with `/plugin marketplace add …`.

### Cursor

Dashboard → **Plugins & MCPs** → **Team Marketplaces** → **Add Marketplace** → **Import
from Repo**, and paste `https://github.com/ayandexyz/omarchy-publishing-skill`. Turn on
**Enable Auto Refresh** to track pushes.

### opencode, or any agent, without a plugin system

opencode installs plugins as git-backed npm packages, which is more machinery than one
skill needs. Copy the skill directory instead:

```bash
git clone https://github.com/ayandexyz/omarchy-publishing-skill
cd omarchy-publishing-skill
./install.sh
```

With no arguments it installs into every agent it finds on your machine. This is also the
fallback if any of the plugin installs above misbehave.

```bash
./install.sh --agent opencode  # just one: claude | codex | opencode | cursor
./install.sh --all             # all four, detected or not
./install.sh --project         # into the current repo instead of $HOME
./install.sh --list            # where it would go, and what is installed
./install.sh --uninstall       # remove it again
./install.sh --link            # symlink instead of copy, for editing the skill
```

### Or by hand

All four agents read the same `SKILL.md` standard, so installing is just putting
`skills/omarchy-plugin-publish/` in the right place:

| Agent | User-level path | Project-level path |
| --- | --- | --- |
| [Claude Code](https://code.claude.com/docs/en/skills) | `~/.claude/skills/omarchy-plugin-publish/` | `.claude/skills/` |
| [Codex](https://learn.chatgpt.com/docs/build-skills) | `~/.agents/skills/omarchy-plugin-publish/` | `.agents/skills/` |
| [opencode](https://opencode.ai/docs/skills/) | `~/.config/opencode/skills/omarchy-plugin-publish/` | `.opencode/skills/` |
| [Cursor](https://cursor.com/docs/skills) | `~/.cursor/skills/omarchy-plugin-publish/` | `.cursor/skills/` |

Codex, Cursor and opencode all also read `~/.agents/skills/`, and Cursor and opencode read
`~/.claude/skills/` for compatibility — so one or two locations usually cover everything.

Whichever route you take, start a new agent session afterwards; skills are discovered at
startup.

## Use

Claude Code and opencode load the skill on their own when what you ask matches it. In Codex
type `$` to pick it; in Cursor `@`-mention it. Or just ask:

```
Is my Omarchy plugin at ~/code/omarchy-weather ready to publish?
Audit this plugin for the marketplace security review and fix what you find.
Reviewer asked for changes on issue #7396 — work through the feedback.
Prepare the submission issue for the current commit.
```

### Readiness check on its own

The structural half runs without an agent, offline, read-only:

```bash
skills/omarchy-plugin-publish/scripts/readiness-check.sh ~/code/omarchy-weather
skills/omarchy-plugin-publish/scripts/readiness-check.sh --json ~/code/my-plugin  # exit 1 if blocked
```

It checks manifest validity and field limits, plugin-id syntax and the reserved
`omarchy.*` namespace, that every declared kind has an entry point and every entry point
is a tracked file, root README and license, symlinks, preview format and size, agent-control
files in the payload, patterns matching the five deterministic security findings, which
review capabilities your plugin will trigger, and whether your HEAD is actually committed
and pushed. It also notes translation readiness — inline QML strings, a missing `i18n/en.json`
catalog, translations with drifted keys — as notes only, never blockers. Needs `jq`.

This is a first sweep, not a verdict. It reproduces the marketplace's structural rules —
it is not the marketplace scanner, it produces nothing a reviewer will accept as evidence,
and the review failures that cost the most cycles are data-flow problems it cannot see. The
agent audit is what covers those.

## What's in here

Everything the agent uses lives under `skills/omarchy-plugin-publish/`:

| Path | |
| --- | --- |
| `SKILL.md` | The skill: how to audit, fix, package and submit. |
| `references/requirements.md` | Machine-enforced contract — manifest schema, ids, entry points, baseline policy, validation commands. |
| `references/review-patterns.md` | Blockers maintainers actually raise, each linked to the review comment it came from. |
| `references/i18n.md` | How to make a plugin translatable so a fork can add a language with one file. |
| `references/research-coverage.md` | Which issue threads were read, and the limits of that sample. |
| `scripts/readiness-check.sh` | Offline structural preflight. |
| `assets/submission-body.md` | The submission issue template, headings and checklist intact. |
| `assets/translating.md` | `TRANSLATING.md` template for plugin repos, with a ready-made AI translation prompt. |

The `.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/` and `.agents/plugins/` manifests
at the repository root are what let each agent install this as a plugin.

## Translation readiness

Every plugin the skill prepares should be ready for i18n. All user-visible text goes into an
`i18n/en.json` catalog, loaded with a locale-aware English fallback, using named
placeholders and plural keys. Then anyone can fork the plugin, tell their AI agent
"translate this into Portuguese", and get a working `i18n/pt.json` without touching any code.
The skill audits this on every pass and, when you authorize fixes, externalizes the
strings and adds a `TRANSLATING.md` to your plugin.

This is the skill's own recommendation, not a marketplace rule. It is reported separately
from review findings and never blocks a submission.

## Where the rules come from

`references/` was built by reading the marketplace's own implementation — the manifest
validator, intake parser, security baseline policy and scanner, and the validation,
routing and approval workflows — together with 41 complete submission threads sampled
from the 100 most recently updated submission issues. Every review pattern links to the
comment it is drawn from, so you can check it yourself.

Marketplace source read at commit `3382370f` on 2026-09-23; security baseline v3, marker
protocol v4, selective enforcement. **Policy moves.** The skill is instructed to re-read the
live sources before finalizing a submission, and you should treat anything here older than
your submission date as a starting point rather than the current rule.

A sampled set of public threads is not the complete review policy, and no private reviewer
criteria are reconstructed here.

## Scope

The skill will not post anything without your say-so. Creating an issue or editing one is an
external write; it asks first, shows you the completed body, and confirms the ownership and
rights declarations with you rather than inferring them from your repository. It won't open a
duplicate submission, change a plugin id to dodge a review, or quietly weaken a protection to
turn a check green.

Keep this skill out of the plugin you publish. Reviewers have repeatedly rejected
`AGENTS.md`, `CLAUDE.md` and `.claude/` content shipped inside plugin payloads — the
readiness check flags it as a blocker. This is an authoring tool; it belongs in your agent's
skill directory, not in your plugin repository.

## License

MIT
