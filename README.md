# project-onboard

Claude Code plugin that takes a project to a consistent standard — a
brand-new one, a stale one being revived, or one that never got properly set
up (`--adopt` gap-fills without touching existing files, history, or remotes).
One skill, two phases:

- **Phase A (mechanical)** — `scripts/onboard.sh` creates the directory,
  `git init -b main` with your git identity pinned per-repo, README, CHANGELOG,
  stack `.gitignore`, a CLAUDE.md skeleton, a
  plain-message initial commit, and the GitHub repo — **private unless public
  is explicitly requested**.
- **Phase B (judgment)** — stack scaffold with context7-verified versions,
  fill every `TODO(onboard)`, serena onboarding (all six memories), workspace
  index row, then a quantitative verification gate.

## Install

Add this repository as a Claude Code plugin marketplace, then install the
plugin from it:

```
/plugin marketplace add TheMizeGuy/project-onboard-public
/plugin install project-onboard@project-onboard-public
```

## Use

Say "new project called X" / "bootstrap X" / "set up a repo for X" — or, for
existing directories, "revive X" / "get X going again" / "X never got set up
properly" — the `project-onboard` skill triggers before any directory or repo
is created or reworked by hand. See `USAGE.md` for worked examples.

## Layout

```
.claude-plugin/plugin.json
skills/project-onboard/SKILL.md            # the runbook + verification gate
skills/project-onboard/scripts/onboard.sh  # Phase A scaffolder
```

## Requirements

`git`, `gh` (authenticated), and a global git identity
(`git config --global user.name` / `user.email`). The serena and context7
MCP steps degrade gracefully when those servers aren't connected.
