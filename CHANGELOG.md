# Changelog

## 0.2.0 — 2026-07-07

- Adopt mode (`--adopt`): onboard an EXISTING directory — stale revivals and
  never-properly-set-up projects. Script gap-fills missing scaffold files
  only, commits with a pathspec (pre-staged changes stay staged), `git init`s
  only when the dir isn't already its own repo, refuses mid-merge/rebase
  repos, skips GitHub when an origin remote exists, prints `adopt-base:` plus
  a stale-audit line. SKILL.md: mode decision by observable state, four adopt
  hard rules (history immutable incl. `git replace` / never overwrite a file /
  working tree as found / branch, remote, visibility need the user to name
  the change), an audit-before-touch Phase B step, and an adopt-aware
  verification gate (first-parent history-intact row, staleness carve-out on
  Build green). Behaviorally tested: the baseline agent planned a
  history-rewrite cleanup on a stale repo; the adversarial pass on the new
  wording closed 10 further loopholes.

## 0.1.1 — 2026-07-06

- Version-parity release with the source plugin's environment-resilience pass.
  The public variant was already environment-generic; no functional change.

## 0.1.0 — 2026-07-06

- Initial release: `project-onboard` skill — Phase A scaffolder script +
  Phase B judgment runbook + quantitative verification gate. Behaviorally
  tested (RED baseline without the skill showed missing CodeRabbit config,
  unpinned git identity, and partial project-memory onboarding; GREEN run
  with the skill covered all required elements).
