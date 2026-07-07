---
name: project-onboard
description: Use when starting a new project in your workspace — the user says "new project", "bootstrap X", "set up a repo for...", "onboard a project" — BEFORE creating any directory, git repo, CLAUDE.md, or review config by hand.
---

# Project Onboard

Bootstraps a new project to a consistent standard in two phases: a deterministic
scaffolder script (Phase A), then judgment steps you complete and verify (Phase B).
Done means every row of the Verification Gate passes — not "the directory exists".

## Inputs (collect before running anything)

| Input | Default | Notes |
|---|---|---|
| Name | — (required) | `[A-Za-z0-9._-]+`; becomes `<dev-root>/<Name>` and `<owner>/<Name>` on GitHub |
| Description | Name | one line |
| Stack | `generic` | `web-ts` \| `node-ts` \| `ios` \| `python` \| `generic` |
| Visibility | **private** | `--public` ONLY when the user explicitly said public |
| Dev root | `$PWD` | `--dev-root` to place the project elsewhere |

## Phase A — scaffolder (mechanical)

```bash
"$CLAUDE_PLUGIN_ROOT/skills/project-onboard/scripts/onboard.sh" \
  --name <Name> --desc "<one-liner>" --stack <stack> --dev-root <workspace>
# add --public only on explicit request; --owner to override the gh login
```

Creates the directory, `git init -b main`, pins your global git identity
per-repo (so later global-config drift can't mis-attribute commits), writes
README, CHANGELOG, stack .gitignore, CLAUDE.md skeleton, .coderabbit.yaml
skeleton, makes a plain-message initial commit, creates the GitHub repo
(private default) and pushes. `--no-github` for local-only runs.

## Phase B — judgment steps (in order)

1. **Stack scaffold.** Build the real toolchain (package.json/project.yml/pyproject).
   Current majors via context7 (`resolve-library-id` → `query-docs`), never
   hand-pinned from memory. Run build + test + lint green before the scaffold
   commit.
2. **Fill every `TODO(onboard)`** in CLAUDE.md and .coderabbit.yaml — stack
   table, verified commands, BLOCKING review rules, path_filters.
   `grep -rn "TODO(onboard)"` must return nothing when you're done.
3. **serena onboard** (skip gracefully if the serena MCP isn't connected):
   `initial_instructions` → `activate_project <abs path>` →
   `check_onboarding_performed` → `onboarding`, then `write_memory` for ALL six:
   `project-overview`, `tech-stack`, `suggested-commands`, `code-conventions`,
   `task-completion-checklist`, `directory-layout`. An empty project still gets
   all six — they seed conventions for every future session.
4. **Project memory registration.** If you run a persistent memory system with
   per-project scopes, register the new project there and record the pointer in
   the CLAUDE.md Memory section (otherwise record "serena only").
5. **Workspace docs.** If you keep a workspace-level index of projects (e.g. a
   root CLAUDE.md project map), add the new project's row.
6. **Commit + push** the Phase B work.

## Day-2 (list for the user, do NOT do by default)

CI workflow (use your org's standard runners) · PR template · dependabot ·
LICENSE decision · branch protection · deploy target.

## Verification Gate (all REQUIRED — paste actual outputs)

| Check | Command | Expect |
|---|---|---|
| Identity pinned | `git -C <dir> config user.email` | your global git email |
| Visibility | `gh repo view <owner>/<Name> --json visibility` | `PRIVATE` unless explicitly public |
| Remote | `git -C <dir> remote get-url origin` | `https://github.com/<owner>/<Name>.git` |
| CLAUDE.md | `head -1 <dir>/CLAUDE.md` | `**Extends ~/.claude/CLAUDE.md**` |
| CodeRabbit | `test -f <dir>/.coderabbit.yaml` | present, TODOs filled |
| No TODOs left | `grep -rn "TODO(onboard)" <dir>` | empty |
| serena | `list_memories` for the project | ≥ 6 memories (or MCP absent, noted) |
| Workspace row | grep your workspace index | 1 row (or no index kept, noted) |
| Build green | stack test/lint commands | pass, output pasted |

## Common mistakes

| Mistake | Reality |
|---|---|
| Public repo because visibility wasn't stated | Private is the default. Public requires the user's explicit word. |
| Skipping .coderabbit.yaml ("no PRs yet") | It must live on main BEFORE the first PR to take effect. Scaffold ships it. |
| One serena memory "because the project is empty" | All six, always — they seed every future session. |
| Hand-pinning dep versions from memory | context7 or `@latest` resolution — training-data majors are stale. |
| Declaring done at "directory exists" | Done = every Verification Gate row passes with pasted output. |
