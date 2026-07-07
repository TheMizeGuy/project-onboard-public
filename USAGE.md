# Usage

## Typical invocations

- "Create a new project called HarborView — a tide dashboard web app (TypeScript)"
  → Phase A with `--name HarborView --desc "..." --stack web-ts`, then Phase B.
- "New iOS app called Nightlight, make it public"
  → `--name Nightlight --stack ios --public` (public ONLY because it was said
  explicitly).
- "Bootstrap a python scratch project, no repo yet"
  → `--stack python --no-github`; the gate's GitHub rows report as skipped.

## What the agent must NOT do

- Decide visibility itself — private is the default, public needs the user's word.
- Skip the `.coderabbit.yaml` or leave `TODO(onboard)` markers behind.
- Declare done without pasting the Verification Gate outputs.

## Flags

Run `scripts/onboard.sh --help` for the full flag list (`--name`, `--desc`,
`--stack`, `--public`, `--no-github`, `--dev-root`, `--owner`).
