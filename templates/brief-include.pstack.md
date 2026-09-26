<!-- Append into firstmate config/brief-include.md after the stay-inside-worktree rule -->

pstack (Lauren Tan's rigor skills) is installed for Pi and Codex. For any
non-trivial ship or scout work, load the `poteto-mode` skill first and follow
its matching playbook (bug fix, feature, refactoring, perf issue,
investigation, prototype, visual parity). The other pstack skills it routes to
are hidden from automatic loading; read them directly at
`~/.pi/agent/skills/<name>/SKILL.md` (Codex: `~/.codex/skills/<name>/SKILL.md`) —
reading those two skill folders is an allowed exception to the
stay-inside-your-worktree rule above. Host adaptations, which override pstack
where they conflict:
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
