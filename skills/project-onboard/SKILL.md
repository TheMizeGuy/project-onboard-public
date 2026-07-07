---
name: project-onboard
description: Use when starting a new project in your workspace OR bringing an existing one up to standard — the user says "new project", "bootstrap X", "set up a repo for...", "onboard a project", "revive X", "get X going again", "resume that old project", "X never got set up properly" — BEFORE creating or reworking any directory, git repo, CLAUDE.md, or review config by hand.
---

# Project Onboard

Takes a project to a consistent standard in two phases: a deterministic
scaffolder script (Phase A), then judgment steps you complete and verify (Phase B).
Two modes, one runbook: **new** (the directory doesn't exist yet) and **adopt**
(it does — a stale project being revived, or one that never got properly set up).
Done means every row of the Verification Gate passes — not "the directory exists".

## Inputs (collect before running anything)

| Input | Default | Notes |
|---|---|---|
| Name | — (required) | `[A-Za-z0-9._-]+`; becomes `<dev-root>/<Name>` and `<owner>/<Name>` on GitHub |
| Description | Name | one line |
| Stack | `generic` | `web-ts` \| `node-ts` \| `ios` \| `python` \| `generic` |
| Visibility | **private** | `--public` ONLY when the user explicitly said public |
| Dev root | `$PWD` | `--dev-root` to place the project elsewhere |

## Mode (decide first, by observable state)

`<dev-root>/<Name>` does not exist → **new**. It exists — stale revival,
half-bootstrapped, never-properly-onboarded — → **adopt** (add `--adopt`).
Same phases, same gate; adopt binds four hard rules:

- **History is immutable.** Never rebase/amend/filter/`git replace` existing
  commits — a messy old log is evidence of the project's age, not something
  to clean. No rewrite, with or without a backup. adopt-base is minted ONCE:
  the first adopt run's sha is the permanent gate anchor — never re-run
  `--adopt` for a fresh one after history changed.
- **Never overwrite an existing file.** Phase A gap-fills what's missing;
  pre-existing README/CLAUDE.md/.coderabbit.yaml get reconciled in Phase B.
- **Leave the working tree as found.** Pre-existing dirty/untracked files are
  never staged, stashed, moved, reverted, or deleted — surface them to the
  user instead.
- **Branch names, remotes, and repo visibility are the user's.** Report what
  you find; change none without the user naming the specific change ("rename
  master to main", "make it public") — "clean it up" / "make it like my other
  repos" names nothing. Never force-push, delete remote branches, or
  rename/archive the repo during onboarding.

## Phase A — scaffolder (mechanical)

```bash
"$CLAUDE_PLUGIN_ROOT/skills/project-onboard/scripts/onboard.sh" \
  --name <Name> --desc "<one-liner>" --stack <stack> --dev-root <workspace>
# add --public only on explicit request; --owner to override the gh login
# adopt mode — existing directory:
"$CLAUDE_PLUGIN_ROOT/skills/project-onboard/scripts/onboard.sh" \
  --name <Name> --adopt --stack <stack> --dev-root <workspace>
```

New mode creates the directory, `git init -b main`, pins your global git
identity per-repo (so later global-config drift can't mis-attribute commits),
writes README, CHANGELOG, stack .gitignore, CLAUDE.md skeleton,
.coderabbit.yaml skeleton, makes a plain-message initial commit, creates the
GitHub repo (private default) and pushes. `--no-github` for local-only runs.

Adopt mode pins the same identity, `git init`s only when the directory isn't
already its own repo, creates only the scaffold files that are MISSING,
commits with a pathspec so pre-staged changes stay staged, and skips GitHub
entirely when an origin remote exists.
Record its report: `adopt-base:` (the permanent gate anchor — a later run
printing a different sha means history moved; investigate, never re-anchor),
the audit line (last pre-adopt commit, dirty count), `kept:` files (Phase B
reconciles them), and any missing agent-state .gitignore entries.

## Phase B — judgment steps (in order)

0. **(adopt only) Audit before touching.** Read the existing README/CLAUDE.md/
   docs and recent `git log`; a stale doc describes the project as it WAS —
   verify each claim before reusing it. If a remote exists: `git fetch` and
   note ahead/behind. Check toolchain staleness (lockfile age, EOL runtimes,
   majors behind). LIST the findings for the user; upgrade nothing silently.
1. **Stack scaffold.** Build the real toolchain (package.json/project.yml/pyproject).
   Current majors via context7 (`resolve-library-id` → `query-docs`), never
   hand-pinned from memory. Run build + test + lint green before the scaffold
   commit.
2. **Fill every `TODO(onboard)`** in CLAUDE.md and .coderabbit.yaml — stack
   table, verified commands, BLOCKING review rules, path_filters.
   `grep -rn "TODO(onboard)"` must return nothing when you're done.
   Adopt: files the script reported as `kept:` get RECONCILED to standard
   shape — CLAUDE.md gains the `**Extends ~/.claude/CLAUDE.md**` first line and
   any missing section (Stack/Commands/Conventions/Memory). Reconcile ADDS
   structure; existing content is removed only when the step-0 audit proved it
   false, and each removal is named in the commit message. A kept .gitignore
   gets the missing agent-state entries the script listed appended.
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
6. **Commit + push** the Phase B work. Adopt: if Phase A reported a GitHub
   repo with no origin wired here, compare the two histories WITH the user and
   only then `git remote add origin` + push — the script deliberately doesn't
   guess which history wins.

## Day-2 (list for the user, do NOT do by default)

CI workflow (use your org's standard runners) · PR template · dependabot ·
LICENSE decision · branch protection · deploy target.

## Verification Gate (all REQUIRED — paste actual outputs)

| Check | Command | Expect |
|---|---|---|
| Identity pinned | `git -C <dir> config user.email` | your global git email |
| History intact (adopt only) | `git -C <dir> rev-list --first-parent HEAD \| grep -c ^<adopt-base>` | `1` — adopt-base sits on the first-parent chain (an ancestry-only check can be buried under a merge); adopt-base `none` → N/A |
| Visibility | `gh repo view <owner>/<Name> --json visibility` | `PRIVATE` unless explicitly public; adopt with a pre-existing repo: as found — flipping needs the user's word |
| Remote | `git -C <dir> remote get-url origin` | points at `<owner>/<Name>` (https or ssh; adopted remotes keep their form) |
| CLAUDE.md | `head -1 <dir>/CLAUDE.md` | `**Extends ~/.claude/CLAUDE.md**` |
| CodeRabbit | `test -f <dir>/.coderabbit.yaml` | present, TODOs filled |
| No TODOs left | `grep -rn "TODO(onboard)" <dir>` | empty |
| serena | `list_memories` for the project | ≥ 6 memories (or MCP absent, noted) |
| Workspace row | grep your workspace index | 1 row (or no index kept, noted) |
| Build green | stack test/lint commands | pass, output pasted; adopt: red caused by pre-existing staleness is reported alongside the step-0 findings — fixing it is the user's upgrade decision, not a silent one |

## Common mistakes

| Mistake | Reality |
|---|---|
| Rewriting history to tidy an adopted repo's log | filter-branch/rebase/`git replace` on an adopted repo destroys provenance; a backup does not make it acceptable. The gate checks first-parent reachability of adopt-base instead. |
| Hand-rolling Phase A because the directory exists | That's what `--adopt` is for. Improvised scaffolds drift from standard. |
| Staging, moving, or deleting pre-existing dirty files | Tree as found; the script stages only what it created. Surface the dirt, don't clean it. |
| Renaming the branch or flipping visibility during adopt | Report as found — `master`, ssh remotes, and public repos stay until the user says otherwise. |
| Trusting a stale README/CLAUDE.md as current truth | Step-0 audit first: log age, remote drift, toolchain staleness — then reconcile. |
| Public repo because visibility wasn't stated | Private is the default. Public requires the user's explicit word. |
| Skipping .coderabbit.yaml ("no PRs yet") | It must live on main BEFORE the first PR to take effect. Scaffold ships it. |
| One serena memory "because the project is empty" | All six, always — they seed every future session. |
| Hand-pinning dep versions from memory | context7 or `@latest` resolution — training-data majors are stale. |
| Declaring done at "directory exists" | Done = every Verification Gate row passes with pasted output. |
