# Adapter: Claude Code

**Entry:** load [AGENTS.md](../AGENTS.md), then this file.

## Skills / rigor

- Prefer Claude Code skills / project instructions for pstack equivalents when installed in the environment.
- If pstack skills are available on disk, load `poteto-mode` first for non-trivial ship/scout work and follow the matching playbook.
- Claude Code can use subagents: when a pstack playbook calls for parallel explorers, arena, or swarm, you may run them; still report what actually ran.

## Delivery

- Default: do **not** open/merge PRs or create worktrees unless the orchestrator brief's Definition of Done says Claude owns delivery.
- When the factory uses a validation pipeline (e.g. no-mistakes), that pipeline owns review → push → PR → CI.

## Verification

- Invoke the **project's** verification skill (not a generic control-app). Attach screenshots/video to the PR.
- One line in the project's `AGENTS.md` must require runtime evidence; do not dump skill internals there.

## Dispatch tips

- Strong fit: greenfield features without a PRD, architecture/planning (after captain profile approval), deep refactors.
- Prefer high-effort Opus-class profiles for planning; Sonnet-class for well-specified bugs when dispatch rules say so.
