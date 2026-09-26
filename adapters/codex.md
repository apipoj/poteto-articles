# Adapter: Codex

**Entry:** load [AGENTS.md](../AGENTS.md), then this file.

## Skills / rigor

- Install pstack skills under `~/.codex/skills`. Diff before overwrite.
- For non-trivial ship/scout: load `poteto-mode` and follow the matching playbook; other pstack skills via direct path under `~/.codex/skills/<name>/SKILL.md`.
- Ignore Cursor-only setup steps in pstack docs; map control-app language to the project's verification skill.

## Delivery

- Delivery contract in the orchestrator brief wins. Do not open/merge PRs or manage worktrees unless Definition of Done says Codex owns that step.
- When a validation pipeline owns delivery, stop at "verified in worktree" and hand off.

## Verification

- Runtime evidence required on every PR (screenshots/video from the project verification skill).

## Dispatch tips

- Strong fit: image generation tasks and profiles listed for Codex in `crew-dispatch.json`; also appears in planning fallback chains.
