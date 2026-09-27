# Adapter: Claude Code

**Entry:** load [AGENTS.md](../AGENTS.md), then this file.

Running the whole factory on Claude Code on the web (Claude models only, no firstmate)? Use [claude-code-cloud.md](claude-code-cloud.md) instead.

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
- Planning still fits an Opus-class profile, and a well-specified bug still fits Sonnet-class, when the dispatch rule says so. That choice is the model. Effort is separate.
- Levels and the escalate loop are in [templates/effort.md](../templates/effort.md). In Claude Code, set the level with `/effort` followed by `low`, `medium`, `high`, `xhigh`, or `max`. Launch flags and `CLAUDE_CODE_EFFORT_LEVEL` are the local equivalents. `max` stays on for one session unless the environment variable sets it. Clear it before the next task.
- `/model` changes the model. `/effort` changes how much verification that same model does. After a model swap, start again at the new profile's effort. Do not keep `max` from the previous model.
