# Adapter: Pi

**Entry:** load [AGENTS.md](../AGENTS.md), then this file.

## Skills / rigor

- Copy pstack skills into `~/.pi/agent/skills` (diff before overwrite).
- In `poteto-mode/SKILL.md`, remove `disable-model-invocation: true` **only in that file** so Pi can auto-discover the entry skill. Leave other pstack skill flags alone; reach them by direct path.
- **Pi has no subagent tool.** Where pstack asks for parallel agents (arena, swarm, interrogate panels, parallel how/why explorers), run the single-agent sequential version and say so plainly in your report. Ignore `setup-pstack` and Cursor-only references (cursor-team-kit, deslop, create-skill, Cursor Automations / cloud agents).

## Delivery

- Stay inside your worktree. Reading `~/.pi/agent/skills/<name>/SKILL.md` is the allowed exception for pstack.
- Never open/merge PRs or create/clean worktrees unless the brief's Definition of Done allows it. When no-mistakes owns delivery, the pipeline handles review, push, PR, and CI.
- Keep any `show-me-your-work` decision log in the worktree, uncommitted, unless the brief asks to commit it.

## Verification

- Use the project's verification skill wherever pstack says control-app / control-ui.

## Dispatch tips

- Strong fit: Next.js / stack-routed work, well-specified feature implementation, simple bugs via fallback chains in `crew-dispatch.json`.
