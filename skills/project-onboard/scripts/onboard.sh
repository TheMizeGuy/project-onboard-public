#!/usr/bin/env bash
# project-onboard scaffolder — the mechanical phase (Phase A) of the project-onboard skill.
# Judgment work (CLAUDE.md fill-in, stack scaffold, serena
# onboarding) is Phase B in SKILL.md — this script never attempts it.
#
# Usage:
#   onboard.sh --name <Name> [--desc "one-liner"] [--stack web-ts|node-ts|ios|python|generic]
#              [--adopt] [--public] [--no-github] [--dev-root DIR] [--owner GITHUB_LOGIN]
#
# Modes: default creates <dev-root>/<Name> and refuses if it exists; --adopt onboards an
# EXISTING directory instead — gap-fills missing scaffold files only, never overwrites a
# file, never touches history/branches/remotes, stages only what it created.
#
# Defaults: private GitHub repo under the authenticated gh user, dev root = $PWD,
# stack generic. Git identity is read from your global git config and pinned
# per-repo. Exit codes: 0 ok, 1 preflight/collision failure, 2 bad arguments.
set -euo pipefail

DEV_ROOT="${DEV_ROOT:-$PWD}"
NAME=""
DESC=""
STACK="generic"
MODE="new"
VISIBILITY="private"
DO_GITHUB=1
GH_OWNER="${GH_OWNER:-}"

usage() {
  sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --name)      NAME="${2:?--name needs a value}"; shift 2 ;;
    --desc)      DESC="${2:?--desc needs a value}"; shift 2 ;;
    --stack)     STACK="${2:?--stack needs a value}"; shift 2 ;;
    --adopt)     MODE="adopt"; shift ;;
    --public)    VISIBILITY="public"; shift ;;
    --no-github) DO_GITHUB=0; shift ;;
    --dev-root)  DEV_ROOT="${2:?--dev-root needs a value}"; shift 2 ;;
    --owner)     GH_OWNER="${2:?--owner needs a value}"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "ERROR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$NAME" ] || { echo "ERROR: --name is required" >&2; exit 2; }
case "$NAME" in
  *[!A-Za-z0-9._-]*) echo "ERROR: --name must match [A-Za-z0-9._-]+" >&2; exit 2 ;;
esac
case "$STACK" in
  web-ts|node-ts|ios|python|generic) ;;
  *) echo "ERROR: --stack must be web-ts|node-ts|ios|python|generic" >&2; exit 2 ;;
esac
[ -n "$DESC" ] || DESC="$NAME"

TARGET="$DEV_ROOT/$NAME"
TODAY="$(date +%Y-%m-%d)"

# ---------- Preflight ----------
[ -d "$DEV_ROOT" ] || { echo "ERROR: dev root $DEV_ROOT does not exist" >&2; exit 1; }
if [ "$MODE" = "adopt" ]; then
  [ -d "$TARGET" ] || { echo "ERROR: $TARGET does not exist — nothing to adopt (drop --adopt to create a new project)" >&2; exit 1; }
else
  [ ! -e "$TARGET" ] || { echo "ERROR: $TARGET already exists — refusing to touch it (use --adopt to onboard the existing directory)" >&2; exit 1; }
fi

GIT_NAME="$(git config --global user.name || true)"
GIT_EMAIL="$(git config --global user.email || true)"
if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
  echo "ERROR: set git identity first: git config --global user.name / user.email" >&2; exit 1
fi

# An adopted repo that already has an origin remote needs nothing from gh.
HAS_ORIGIN=0
if [ "$MODE" = "adopt" ] && git -C "$TARGET" remote get-url origin >/dev/null 2>&1; then
  HAS_ORIGIN=1
fi

REPO_EXISTS_NO_ORIGIN=0
if [ "$DO_GITHUB" -eq 1 ] && [ "$HAS_ORIGIN" -eq 0 ]; then
  gh auth status >/dev/null 2>&1 || { echo "ERROR: gh is not authenticated (gh auth status failed)" >&2; exit 1; }
  if [ -z "$GH_OWNER" ]; then
    GH_OWNER="$(gh api user -q .login)"
  fi
  if gh repo view "$GH_OWNER/$NAME" >/dev/null 2>&1; then
    if [ "$MODE" = "adopt" ]; then
      # The repo exists remotely but this checkout isn't wired to it. Which history
      # wins is a judgment call — Phase B, not a script guess.
      REPO_EXISTS_NO_ORIGIN=1
    else
      echo "ERROR: github.com/$GH_OWNER/$NAME already exists — pick another name" >&2; exit 1
    fi
  fi
fi

# ---------- Directory + git identity ----------
ADOPT_BASE="none"
BRANCH_NOTE="kept as found"
if [ "$MODE" = "adopt" ]; then
  cd "$TARGET"
  TOPLEVEL="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ "$TOPLEVEL" = "$(pwd -P)" ]; then
    # A mid-merge/rebase repo can't take a partial (pathspec) commit — finish or abort first.
    GITDIR="$(git rev-parse --git-dir)"
    if [ -e "$GITDIR/MERGE_HEAD" ] || [ -d "$GITDIR/rebase-merge" ] || [ -d "$GITDIR/rebase-apply" ]; then
      echo "ERROR: $TARGET is mid-merge/rebase — finish or abort it, then re-run --adopt" >&2; exit 1
    fi
    if git rev-parse -q --verify HEAD >/dev/null 2>&1; then
      ADOPT_BASE="$(git rev-parse HEAD)"   # history before this sha is immutable
    else
      git symbolic-ref HEAD refs/heads/main   # repo has no commits yet — naming the unborn branch is safe
      BRANCH_NOTE="unborn — named main by adopt"
    fi
  else
    git init -b main -q   # not a repo of its own (bare dir, or nested under some parent repo)
    BRANCH_NOTE="new repo — initialized by adopt"
    if [ -n "$TOPLEVEL" ]; then
      echo "note: directory sat inside the repo at $TOPLEVEL — it now has its own nested repo" >&2
    fi
  fi
else
  mkdir -p "$TARGET"
  cd "$TARGET"
  git init -b main -q
fi
BRANCH="$(git branch --show-current)"
[ -n "$BRANCH" ] || BRANCH="detached"
DIRTY_BEFORE="$(git status --porcelain | grep -c . || true)"   # counted before scaffold files land
# Pin identity per-repo so global config drift can never mis-attribute commits.
git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"

# ---------- Scaffold files (gap-fill: each lands only where nothing exists) ----------
CREATED=()
KEPT=()

if [ ! -e README.md ]; then
  CREATED+=("README.md")
  if [ "$MODE" = "adopt" ]; then STATUS_LINE="Status: adopted to standard $TODAY, resuming."
  else STATUS_LINE="Status: bootstrapped $TODAY, pre-feature."; fi
  cat > README.md <<EOF
# $NAME

$DESC

$STATUS_LINE

## Commands

See CLAUDE.md once the stack scaffold lands.
EOF
else
  KEPT+=("README.md")
fi

if [ ! -e CHANGELOG.md ]; then
  CREATED+=("CHANGELOG.md")
  if [ "$MODE" = "adopt" ]; then EVENT="adopt — brought to standard"; else EVENT="bootstrap"; fi
  cat > CHANGELOG.md <<EOF
# Changelog

## [Unreleased]

- $TODAY: $EVENT ($STACK) via project-onboard.
EOF
else
  KEPT+=("CHANGELOG.md")
fi

# ---------- .gitignore (per stack; agent state dirs always ignored) ----------
AGENT_IGNORES=".claude/ .serena/"
if [ ! -e .gitignore ]; then
  CREATED+=(".gitignore")
  {
    cat <<'EOF'
.DS_Store
*.log
.env
.env.*
!.env.example
.claude/
.serena/
EOF
    case "$STACK" in
      web-ts|node-ts)
        cat <<'EOF'
node_modules/
dist/
coverage/
test-results/
playwright-report/
EOF
        ;;
      ios)
        cat <<'EOF'
build/
DerivedData/
xcuserdata/
*.xcresult
*.ipa
*.dSYM.zip
.swiftpm/
EOF
        ;;
      python)
        cat <<'EOF'
__pycache__/
*.pyc
.venv/
venv/
dist/
*.egg-info/
.pytest_cache/
.mypy_cache/
.ruff_cache/
EOF
        ;;
    esac
  } > .gitignore
else
  KEPT+=(".gitignore")
  MISSING_IGNORES=""
  for entry in $AGENT_IGNORES; do
    grep -qF "${entry%/}" .gitignore || MISSING_IGNORES="$MISSING_IGNORES $entry"
  done
fi

# ---------- CLAUDE.md skeleton (Phase B fills every TODO(onboard)) ----------
if [ ! -e CLAUDE.md ]; then
  CREATED+=("CLAUDE.md")
  cat > CLAUDE.md <<EOF
**Extends ~/.claude/CLAUDE.md**

# $NAME — Project Rules

$DESC. Bootstrapped $TODAY.

## Stack (load-bearing — do not change without discussion)

TODO(onboard): lock in the stack table (language/runtime versions, framework,
package manager, test runner).

## Commands

TODO(onboard): verified build / test / lint / typecheck commands with expected
output. Verify each by running it before committing this section.

## Conventions

- Before writing code against any external library API: context7
  (\`resolve-library-id\` -> \`query-docs\`, one targeted check) — never trust
  training-data versions.
- Symbol navigation and edits: serena (\`activate_project\` this directory)
  before raw Read/Grep.
- Tests are the spec. Mocks only at system boundaries.
TODO(onboard): project-specific BLOCKING rules (things reviews flag as errors).

## Memory

- Project memory: TODO(onboard) — how this project's durable facts are stored
  (serena memories at minimum; your memory system's project scope if you run one).
- serena: registered at $TARGET.
EOF
else
  KEPT+=("CLAUDE.md")
fi

# ---------- Commit (plain message) ----------
# Pathspec-scoped commit: ONLY files this run created land in it. Anything the
# user had staged before adopt stays staged and uncommitted — tree as found.
if [ "${#CREATED[@]}" -gt 0 ]; then
  git add "${CREATED[@]}"
  if [ "$MODE" = "adopt" ]; then
    git commit -q -m "chore: adopt $NAME — gap-fill to standard" -- "${CREATED[@]}"
  else
    git commit -q -m "chore: bootstrap $NAME — $DESC" -- "${CREATED[@]}"
  fi
fi

# ---------- GitHub ----------
if [ "$HAS_ORIGIN" -eq 1 ]; then
  echo "github: origin already configured — $(git remote get-url origin) (left untouched; push is Phase B)"
elif [ "$DO_GITHUB" -eq 1 ]; then
  if [ "$REPO_EXISTS_NO_ORIGIN" -eq 1 ]; then
    echo "github: $GH_OWNER/$NAME exists remotely but this checkout has no origin — reconcile in Phase B (compare histories before wiring 'git remote add origin')"
  else
    gh repo create "$GH_OWNER/$NAME" "--$VISIBILITY" --source . --remote origin --push \
      --description "$DESC" >/dev/null
    echo "github: $(gh repo view "$GH_OWNER/$NAME" --json visibility,defaultBranchRef \
      --template '{{.visibility}} default={{.defaultBranchRef.name}}')"
  fi
else
  echo "github: skipped (--no-github)"
fi

# ---------- Report ----------
echo "scaffold: OK — $TARGET ($STACK, $VISIBILITY, mode=$MODE)"
echo "identity: $(git config user.name) <$(git config user.email)>"
if [ "$MODE" = "adopt" ]; then
  echo "adopt-base: $ADOPT_BASE"   # gate anchor; history before it is immutable
  echo "branch: $BRANCH ($BRANCH_NOTE)"
  if git rev-parse -q --verify "${ADOPT_BASE}" >/dev/null 2>&1; then
    echo "audit: last pre-adopt commit $(git log -1 --format=%cs "$ADOPT_BASE"); $DIRTY_BEFORE dirty path(s) before adopt — left in place, not staged"
  else
    echo "audit: no pre-adopt commits; $DIRTY_BEFORE dirty path(s) before adopt — left in place, not staged"
  fi
  if [ "${#CREATED[@]}" -gt 0 ]; then echo "created: ${CREATED[*]}"; else echo "created: nothing — scaffold files all present"; fi
  if [ "${#KEPT[@]}" -gt 0 ]; then echo "kept (reconcile in Phase B, never replace): ${KEPT[*]}"; fi
  if [ -n "${MISSING_IGNORES:-}" ]; then echo "gitignore: pre-existing, missing agent-state entries:${MISSING_IGNORES} — add in Phase B"; fi
fi
echo "next: SKILL.md Phase B — stack scaffold, fill every TODO(onboard), serena onboarding, verification gate"
