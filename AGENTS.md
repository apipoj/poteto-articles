# Software factory — agent entry

You are landing in a **software factory kit**: orchestrator + workers + verification + merge gates, designed so any coding-agent harness can follow the same contract.

This repo is **not** an app. It is the playbook and adapters. Your job when pointed here is to read the contract, follow the runbook for the step you were asked to do, and respect harness-specific notes under `adapters/`.

## Read order (mandatory)

1. This file (`AGENTS.md`)
2. [factory/contract.md](factory/contract.md) — what the factory is and how pieces fit
3. [factory/runbook.md](factory/runbook.md) — how to stand up or operate a separate factory
4. Your harness adapter under [adapters/](adapters/) (Claude / Claude Code cloud / Cursor / Pi / Codex)
5. Only then the foundational reading under [references/poteto/](references/poteto/) if you need pstack vocabulary

## Roles

| Role | Owns | Does not own |
| --- | --- | --- |
| **Orchestrator** (first mate) | Intake, classify, dispatch, supervise, merge policy | App implementation inside a worker worktree |
| **Worker** | Ship or scout work inside one isolated worktree | Opening/merging PRs when a delivery pipeline owns that; orchestrating other workers |
| **Human (captain)** | Product calls, releases, deploys, destructive/security-sensitive changes | Being the every-diff review bottleneck |

## Non-negotiables

1. **Runtime evidence on every PR** — screenshots or video from the project's verification skill, not "tests pass" alone.
2. **Delivery contract wins over pstack defaults** — when pstack playbooks say open/merge PRs, create worktrees, or `/loop` yourself, defer to the orchestrator's delivery mode (e.g. no-mistakes pipeline).
3. **Cross-family review** — the model that reviews must not be the same family that authored the change when the validation pipeline is in play.
4. **Human gate forever** for releases, deploys, and anything destructive, irreversible, or security-sensitive — green CI does not override this.
5. **Declined review findings** get an explicit permanent skip with reason, or the reviewer will re-raise them forever.
6. **Stuck worker → swap model in the same worktree**, do not nudge the same looping plan.

## If you are the orchestrator

- Intake is a GitHub issue labeled `factory` (see runbook §6) unless the human gave you a direct task.
- On Claude Code on the web, the Environment and the intake label are `factory-cloud`. A local or firstmate factory keeps `factory`.
- Classify before dispatch: bug / feature / docs, risk, clarity. Ambiguous → comment questions and wait.
- Dispatch per `crew-dispatch.json` rules (template in [templates/crew-dispatch.example.json](templates/crew-dispatch.example.json)).
- Cap concurrency (default 10 worktrees).
- On review findings: resolve in-scope correctness yourself; escalate only genuine product decisions.

## If you are a worker

- Load `poteto-mode` / pstack rigor for non-trivial ship or scout work when your harness supports it (see your adapter).
- Stay inside your worktree unless the brief explicitly allows skill paths (pstack skill folders are the usual exception).
- Run the project's verification skill before claiming done. Attach evidence to the PR.
- Do not open, merge, babysit, or close PRs unless your Definition of Done says you own delivery.

## Templates

Reusable snippets live in [templates/](templates/): dispatch rules, brief-include block, intake and verify-maintain check scripts.

## Attribution

Prose under `references/poteto/` is © [@poteto](https://x.com/poteto) (Lauren Tan), reformatted for offline/agent use. Factory contract, runbook, adapters, and templates are our own notes building on those ideas.
