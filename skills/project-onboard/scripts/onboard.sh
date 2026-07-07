#!/usr/bin/env bash
# project-onboard scaffolder — the mechanical phase (Phase A) of the project-onboard skill.
# Judgment work (CLAUDE.md fill-in, CodeRabbit instructions, stack scaffold, serena
# onboarding) is Phase B in SKILL.md — this script never attempts it.
#
# Usage:
#   onboard.sh --name <Name> [--desc "one-liner"] [--stack web-ts|node-ts|ios|python|generic]
#              [--public] [--no-github] [--dev-root DIR] [--owner GITHUB_LOGIN]
#
# Defaults: private GitHub repo under the authenticated gh user, dev root = $PWD,
# stack generic. Git identity is read from your global git config and pinned
# per-repo. Exit codes: 0 ok, 1 preflight/collision failure, 2 bad arguments.
set -euo pipefail

DEV_ROOT="${DEV_ROOT:-$PWD}"
NAME=""
DESC=""
STACK="generic"
VISIBILITY="private"
DO_GITHUB=1
GH_OWNER="${GH_OWNER:-}"

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --name)      NAME="${2:?--name needs a value}"; shift 2 ;;
    --desc)      DESC="${2:?--desc needs a value}"; shift 2 ;;
    --stack)     STACK="${2:?--stack needs a value}"; shift 2 ;;
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
[ ! -e "$TARGET" ] || { echo "ERROR: $TARGET already exists — refusing to touch it" >&2; exit 1; }

GIT_NAME="$(git config --global user.name || true)"
GIT_EMAIL="$(git config --global user.email || true)"
if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
  echo "ERROR: set git identity first: git config --global user.name / user.email" >&2; exit 1
fi

if [ "$DO_GITHUB" -eq 1 ]; then
  gh auth status >/dev/null 2>&1 || { echo "ERROR: gh is not authenticated (gh auth status failed)" >&2; exit 1; }
  if [ -z "$GH_OWNER" ]; then
    GH_OWNER="$(gh api user -q .login)"
  fi
  if gh repo view "$GH_OWNER/$NAME" >/dev/null 2>&1; then
    echo "ERROR: github.com/$GH_OWNER/$NAME already exists — pick another name" >&2; exit 1
  fi
fi

# ---------- Directory + git identity ----------
mkdir -p "$TARGET"
cd "$TARGET"
git init -b main -q
# Pin identity per-repo so global config drift can never mis-attribute commits.
git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"

# ---------- README / CHANGELOG ----------
cat > README.md <<EOF
# $NAME

$DESC

Status: bootstrapped $TODAY, pre-feature.

## Commands

See CLAUDE.md once the stack scaffold lands.
EOF

cat > CHANGELOG.md <<EOF
# Changelog

## [Unreleased]

- $TODAY: bootstrap ($STACK) via project-onboard.
EOF

# ---------- .gitignore (per stack; agent state dirs always ignored) ----------
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

# ---------- CLAUDE.md skeleton (Phase B fills every TODO(onboard)) ----------
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

# ---------- .coderabbit.yaml skeleton ----------
cat > .coderabbit.yaml <<EOF
# yaml-language-server: \$schema=https://coderabbit.ai/integrations/schema.v2.json
# NOTE: CodeRabbit reads this file from the DEFAULT branch — it takes effect
# after the first push to main. Validate with \`@coderabbitai configuration\`
# in any PR.

# If your GitHub org keeps a central CodeRabbit baseline repo, uncomment to
# inherit it (scalars below override central; arrays merge with dedupe):
# inheritance: true

language: "en-US"
tone_instructions: >
  Be direct and technical. Skip pleasantries. Focus on bugs, security, and
  correctness over style. TODO(onboard): one sentence of project context.

reviews:
  profile: "assertive"
  request_changes_workflow: true
  high_level_summary: true
  poem: false
  commit_status: true
  fail_commit_status: false
  enable_prompt_for_ai_agents: true
  abort_on_close: true

  instructions: |
    TODO(onboard): 2-4 sentences of project context, then the BLOCKING rules
    (flag as error, not nitpick) and a "Do NOT comment on" list.

  auto_review:
    enabled: true
    auto_incremental_review: true
    drafts: false
    ignore_title_keywords: ["WIP", "DO NOT MERGE", "wip", "[skip ci]"]
    base_branches: ["main"]

  path_filters:
    # TODO(onboard): exclude generated/binary paths for this stack.
    - "!**/node_modules/**"
    - "!**/dist/**"

chat:
  auto_reply: true

knowledge_base:
  opt_out: false
  code_guidelines:
    enabled: true
    filePatterns:
      - "CLAUDE.md"
      - "README.md"
      - "docs/**/*.md"
EOF

# ---------- Initial commit (plain message) ----------
git add README.md CHANGELOG.md .gitignore CLAUDE.md .coderabbit.yaml
git commit -q -m "chore: bootstrap $NAME — $DESC"

# ---------- GitHub ----------
if [ "$DO_GITHUB" -eq 1 ]; then
  gh repo create "$GH_OWNER/$NAME" "--$VISIBILITY" --source . --remote origin --push \
    --description "$DESC" >/dev/null
  echo "github: $(gh repo view "$GH_OWNER/$NAME" --json visibility,defaultBranchRef \
    --template '{{.visibility}} default={{.defaultBranchRef.name}}')"
else
  echo "github: skipped (--no-github)"
fi

# ---------- Report ----------
echo "scaffold: OK — $TARGET ($STACK, $VISIBILITY)"
echo "identity: $(git config user.name) <$(git config user.email)>"
echo "next: SKILL.md Phase B — stack scaffold, fill every TODO(onboard), serena onboarding, verification gate"
