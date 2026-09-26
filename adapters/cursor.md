# Adapter: Cursor (Cloud Agents / IDE)

**Entry:** load [AGENTS.md](../AGENTS.md), then this file.

## Skills / rigor

- Install or enable [pstack](https://github.com/cursor/plugins/tree/main/pstack) skills for the workspace or user skills folder.
- For non-trivial ship/scout: start with `poteto-mode` and the matching playbook.
- Cursor Cloud Agents and Automations are first-class; use them when the orchestrator dispatches a Cursor worker — do not invent a second orchestration loop inside the agent.

## Delivery

- Orchestrator / firstmate delivery contract wins over pstack's default PR and worktree playbooks.
- Prefer one Cloud Agent per isolated task; report branch + PR URL back to the orchestrator task id.

## Verification

- Map pstack "control-app" / "control-UI" language to the **project's** verification skill.
- Attach runtime evidence (screenshots/video) on every PR.

## Rules file

This repo ships [.cursor/rules/software-factory.mdc](../.cursor/rules/software-factory.mdc) so Cursor sessions in a checkout of this kit load the same entry path.
