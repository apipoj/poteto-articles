# Set dispatch effort

Use this when you write a `crew-dispatch.json` rule, and when a worker can change effort during a session.

Copy this file next to the dispatch rules the worker will read. Firstmate uses `config/effort.md`. Claude Code on the web uses `docs/factory/effort.md`.

## What you are setting

`effort` is how much verification and how much of its own judgment the model spends on this task. The model stays the one the rule already named. A higher level spends more checking inside the issue. The diff stays on the issue. Effort does not switch models.

Extra effort reduces misses that come from missing edge cases. It does not repair a wrong approach. Start at `low` or `medium`. Do not default to `max`. Thariq Shihipar, Claude Code, 2026-09-25, [Spending your effort](https://claude.dev/blog/spending-your-effort/) and the [same post on X](https://x.com/trq212/status/2103576349499855160).

## Which level

Claude Code level names are `low`, `medium`, `high`, `xhigh`, and `max`. Put those strings in the profile `effort` field when the harness can apply them. The 2026-09-25 rule of thumb names `low`, `medium`, `high`, and `max`. `xhigh` sits between `high` and `max` in Claude Code and in this kit. That post uses `xhigh` when a `low` run missed edge cases.

**Low.** A sketch, a brainstorm, or an easy change you will review on the next turn.

**Medium.** A specified feature. Start here when the issue already has acceptance criteria.

**High.** The project's verification skill, a bug in an existing codebase, or a change with many edge cases.

**Xhigh.** High still missed edge cases, and the approach is still the right one. Raise once, then read the new evidence before you raise again.

**Max.** The captain asked for an unattended solve of a hard problem. Leave it off a new rule unless that is the task. A stuck worker is not that task.

When the profile omits `effort` and `/effort` is accepted, start a sketch at `low` and a specified build at `medium`.

When the harness has no effort control, or the control rejects the value, keep the session default. Write that on the issue.

When the harness can set effort, the profile `effort` wins. A new rule uses the levels in this file. The strings in [crew-dispatch.example.json](crew-dispatch.example.json) are the captain record of that snapshot. Leave that file alone. Do not copy `max` onto a new rule only because the snapshot has it.

Specified-feature loop. Clarify missing details at `low`. Implement at `low` or `medium`. Review the gist. Run verification at `high`.

## Escalate

1. When you start, use the profile's `effort` if the harness can set it. If the field is omitted and `/effort` is accepted, use `low` for a sketch and `medium` for a specified build. If the harness has no effort control, or the control rejects the value, keep the session default and write that on the issue.
2. If the approach is right and the checks are thin, raise one level. Run the project's verification skill again. Put the new commands and the new evidence on the PR. The diff stays on the issue.
3. If the same plan is repeating and you are not editing, stop. Do not raise effort. Comment what you tried. The orchestrator swaps the model in the same worktree.
4. After a model swap, set effort to the new profile's `effort`. If that profile omits `effort`, run `/effort auto`, which is the model default. [Choosing the right effort level](https://academy.claude.com/tutorials/choosing-the-right-effort-level-in-claude-code).
5. `max` does not open the human gate. Releases, deploys, and destructive, irreversible, or security-sensitive changes still wait for a human. Green verification does not change that.

## Raise effort or swap the model

Raise effort when the model knew enough and did not check. Swap the model when the plan is stuck, or when a higher level still has the wrong approach. A quota retry that walks the `use` array also swaps the model. It does not raise effort.
