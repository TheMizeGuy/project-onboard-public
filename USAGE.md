# Usage

## Typical invocations

- "Create a new project called HarborView — a tide dashboard web app (TypeScript)"
  → Phase A with `--name HarborView --desc "..." --stack web-ts`, then Phase B.
- "New iOS app called Nightlight, make it public"
  → `--name Nightlight --stack ios --public` (public ONLY because it was said
  explicitly).
- "Bootstrap a python scratch project, no repo yet"
  → `--stack python --no-github`; the gate's GitHub rows report as skipped.
- "Let's get StaleTracker going again — it's been dead for two years"
  → `--name StaleTracker --adopt`; Phase B starts with the audit step (log
  age, remote drift, toolchain staleness), history and dirty files stay
  untouched.
- "Onboard Scratchpad properly, it never really got set up"
  → `--name Scratchpad --adopt --stack <stack>`; the script gap-fills the
  missing scaffold files only, `kept:` files get reconciled in Phase B.

## What the agent must NOT do

- Decide visibility itself — private is the default, public needs the user's word.
- Leave `TODO(onboard)` markers behind.
- Declare done without pasting the Verification Gate outputs.
- In adopt mode: rewrite history, overwrite existing files, touch pre-existing
  dirty files, or rename branches / flip visibility uninvited.

## Flags

Run `scripts/onboard.sh --help` for the full flag list (`--name`, `--desc`,
`--stack`, `--adopt`, `--public`, `--no-github`, `--dev-root`, `--owner`).
