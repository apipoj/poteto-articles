<!-- Append into firstmate config/brief-include.md after the stay-inside-worktree rule -->

Install pstack (Lauren Tan's rigor skills) where each harness loads skills. Pi uses
`~/.pi/agent/skills/`. Codex uses `~/.codex/skills/`. Local Claude Code uses
`~/.claude/skills/` or the project's `.claude/skills/`. Cloud Claude sessions need committed
project skills or account-synced skills. They cannot use the operator's local skill folder. Install
these skills before dispatch.

For non-trivial ship or scout work, load `poteto-mode` first and follow its matching playbook (bug
fix, feature, refactoring, perf issue, investigation, prototype, or visual parity). Read the other
pstack skills it routes to directly from `~/.pi/agent/skills/<name>/SKILL.md`,
`~/.codex/skills/<name>/SKILL.md`, `~/.claude/skills/<name>/SKILL.md`, or the project's
`.claude/skills/<name>/SKILL.md`. Reading these skill folders is an allowed exception to the
stay-inside-your-worktree rule above. Host adaptations override pstack where they conflict:
- Pi has no subagent tool: run playbook steps yourself in sequence; where a
  step needs other models or parallel agents (arena, swarm, interrogate
  panels, parallel how/why explorers), do the single-agent version and say so
  in your report. Ignore `setup-pstack` and every Cursor-only reference
  (cursor-team-kit, deslop, create-skill, Cursor Automations or cloud agents).
- Wherever pstack says control-app, control-ui, or a verification skill, use
  the project's own verification skill if it has one (e.g. the app project:
  `verify-<app>`).
- This brief's delivery contract wins: never open, merge, babysit, or close
  PRs, create or clean worktrees, run `/loop`, autopilot, or orchestrate
  playbooks, or push anything outside what this brief's Definition of done
  allows. When no-mistakes is the delivery mode, the pipeline owns review,
  push, PR, and CI.
- Keep any `show-me-your-work` decision log in your worktree, uncommitted,
  unless the brief asks for it.
- Effort, when this harness can set it, follows the factory kit's
  `templates/effort.md`, copied beside your dispatch rules. A higher level
  spends more checking inside the issue. The diff stays on the issue. The
  model stays the one dispatch named. If you repeat the same plan without
  new edits, stop. The orchestrator swaps the model. Do not raise effort
  instead.
