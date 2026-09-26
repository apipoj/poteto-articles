# Our software factory

*Our own notes, not poteto's writing. Inspired by and building on [How I Use Cursor](../references/poteto/how-i-use-cursor.md), [The Complete Guide to pstack Pt. 1](../references/poteto/the-complete-guide-to-pstack-pt-1.md), and [The Complete Guide to pstack Pt. 2](../references/poteto/the-complete-guide-to-pstack-pt-2.md) — read those first; this is a companion write-up of what we actually built, over one weekend (2026-09-25/26), by applying their ideas.*

## What we built

A small "software factory": one supervising agent (we call it the orchestrator, or "first mate") that takes in work, assigns it to worker agents, watches their output, and merges what's good. The goal was the same one poteto describes — get an agent to verify its own work well enough that a human doesn't have to be the bottleneck on every change — and then stack supervision and dispatch on top of that so the factory could run mostly unattended.

pstack gave us the verification method (`create-verification-skill` and `maintain-verification-skill`) and the rigor playbooks; the isolated worktree per worker and the validation pipeline with a cross-family reviewer come from our own orchestration tooling. What we added is the layer above pstack: an orchestrator that decides *what* work happens, *who* does it, and *whether it's good enough to ship*, so a small team can run several agents at once without babysitting each one.

## Architecture

```
                    GitHub issue, labeled "factory"
                                |
                                v
                    +----------------------+
                    |     orchestrator     |   <- the "first mate"
                    |  (intake, dispatch,  |
                    |  supervision, merge) |
                    +----------------------+
                        |     |     |
             dispatches to worker agents,
             one per isolated git worktree
                        |     |     |
              +---------+     |     +---------+
              v               v               v
        worker (harness A) worker (B)   worker (harness C)
        model per rules    ...          ...
              |               |               |
              v               v               v
        verification skill for that project (disposable
        db + app, seeded data, scripted UI driving,
        screenshots/video as evidence)
              |
              v
        validation pipeline (review by a *different*
        model family, tests, lint, docs)  -> PR -> CI
              |
              v
        auto-merge (trusted projects, green pipeline)
        or human approval (releases, deploys, anything
        destructive/irreversible/security-sensitive)
```

## Intake

Work starts as a GitHub issue labeled `factory`. A poll wakes the orchestrator, which reads the issue and classifies it: bug, feature, or docs; how risky; and whether it's clear enough to hand to a worker right away. If it's ambiguous, the orchestrator comments questions on the issue and waits for a human rather than guessing. Once it's clear, the orchestrator files any missing detail and dispatches a worker. Every resulting PR says "Fixes #N" so the link back to intake is never lost. We cap concurrency at 10 workers at a time, mostly for the same resource reasons poteto flags about worktrees — each worker gets an isolated git worktree, and that's real disk and process overhead per lane.

## Dispatch: different harnesses, different models, by rule

Workers aren't one agent — they're several different coding-agent harnesses running side by side, each picking a model per a small set of natural-language dispatch rules keyed on project and task type. A Next.js frontend task might go to one model that's strong on that stack; a design or planning task goes to a stronger, slower model; routine, well-specified work goes to a cheap, fast model. The rules also carry quota-aware fallbacks, so if a preferred model is rate-limited or unavailable, the dispatcher falls back to an alternative rather than stalling the queue. This is the part of the factory that's most different from the single-bot-plus-cloud-agents picture in the pstack articles: we're explicitly routing across harness *and* model, not just spinning up more of the same agent.

## Verification is still the bottleneck — in a good way

Every worker's output has to clear a project-specific verification skill, built the way pstack's `create-verification-skill` describes: a small JSON-emitting CLI that stands up a disposable database and app instance with seeded demo data, logs in as each relevant user role, drives the app's pages end-to-end (we use Playwright for this), and captures screenshots and video as it goes. Alongside the CLI sits a Feature Map — a living catalog of every area of the app and how to reach and exercise it — which we keep current with a daily "maintain verification" pass, same cadence poteto recommends.

The rule we enforce hardest: **every PR must carry runtime evidence.** Not "tests pass" — actual screenshots or video of the feature working, produced by the verification skill, attached to the PR. This is poteto's "three-minute egg" idea in practice: verification has to be fast and reliable enough that agents actually run it every time, or it doesn't get used.

## The gate before merge

Once a worker believes its change is done and verified, it goes through an automated validation pipeline: independent review, tests, lint, and docs, then push, PR, and CI. The reviewer in that pipeline is deliberately a different model family than the one that did the work — the point is to avoid a model reviewing (and rubber-stamping) its own reasoning. When the reviewer raises something it isn't confident enough to resolve on its own, that finding routes back to the orchestrator, which makes the in-scope correctness or scope call itself and only escalates to a human when it's a genuine product decision. On trusted projects, a fully green pipeline auto-merges. Releases and deploys always get a human sign-off regardless of how green the pipeline is, and anything destructive, hard to reverse, or security-sensitive always stops for a human, no exceptions.

## Adopting pstack across harnesses

We installed pstack's rigor skills for the harnesses that support it and adapted where a host couldn't do exactly what the articles describe:

- One harness has no subagent support, so where pstack calls for parallel sub-agents (an arena of competing approaches, a swarm confirming a fix, parallel explorers), that harness runs the steps in sequence itself instead, and says so plainly in its report rather than pretending it ran in parallel.
- Wherever pstack's playbooks reference a generic "control-app" or control-UI, we point at the project's own verification skill instead — same shape, project-specific tool.
- Our own delivery contract (how a worker gets from a diff to a merged PR) takes precedence over pstack's default PR, worktree, and looping playbooks, since those assume a different supervision setup than ours.

## What the first day actually looked like

Real numbers from 2026-09-25/26: the verification skill found bugs that turned into 7 filed issues plus 1 feature request, and 5 of those were merged within hours, each with screenshot proof attached. The independent review step earned its keep — it caught scope creep twice, and once caught a real data-loss bug before merge: an edit dialog that would have silently wiped a record's assigned people. On the harder side, a single fast worker assigned a large feature needed four rounds of review before it was mergeable, and two workers running the same model got stuck in visible thinking loops on the same task; the fix was simply swapping in a different model in the same worktree, which unstuck both. We also learned that a review finding that keeps coming back has to be written down as an explicit, permanent skip — otherwise the reviewer just re-raises it every round and wastes cycles relitigating a decision that was already made.

## What's next

- A "reproduce-first" gate that can stop the line entirely if a bug can't be reproduced before a fix is attempted — cheaper to catch a bad repro than a bad fix.
- Verification that runs again after merge, against `main`, not just pre-merge in the worktree.
- Intake straight from chat, not only from a labeled GitHub issue.
- A factory scoreboard — a running view of issues in, PRs out, review catches, and time-to-merge, mostly so we can tell if the numbers above were a good weekend or the normal rate.

None of this replaces good engineering judgment — it just moves the bottleneck from "can a human review every diff" to "can the verification and review steps be trusted," which is exactly the bet poteto's articles make. So far, for us, that bet is paying off.
