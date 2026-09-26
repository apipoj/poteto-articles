# Factory runbook: setting up your own software factory

*Our own notes, not poteto's writing. A companion to [Our software factory](our-software-factory.md) (the concept and architecture) — this is the how-to. Read [How I Use Cursor](../how-i-use-cursor.md), [The Complete Guide to pstack Pt. 1](../the-complete-guide-to-pstack-pt-1.md), and [The Complete Guide to pstack Pt. 2](../the-complete-guide-to-pstack-pt-2.md) first if you haven't; this runbook assumes their vocabulary (verification skills, the "three-minute egg", worker/orchestrator).*

This is written so an agent — another Claude Code session, another firstmate instance, whatever — can pick it up on a fresh machine with a fresh repo and stand up its own, **separate** factory: its own orchestrator, its own workers, its own projects. Nothing here wires you into anyone else's factory. If you're a human handing this off, the agent should be able to follow it with minimal supervision; check in at the "needs-decision" points called out below.

## 1. Prerequisites

Before touching any of this, confirm you have:

- **firstmate installed and bootstrapped** — [github.com/kunchenguid/firstmate](https://github.com/kunchenguid/firstmate). Follow its own setup docs first; this runbook picks up after firstmate exists and can dispatch work.
- **`gh` authenticated** against the GitHub account/org that will own your factory's repos (`gh auth status` should be green).
- **no-mistakes installed** — the validation pipeline (review, tests, lint, docs, push, PR, CI) that gates what workers ship.
- **At least one worker harness**: Claude Code, Pi, or Codex. You can run more than one side by side (that's the point of dispatch rules below), but you need at least one working end to end before you register a project.
- **A model router or provider keys** — either a router that exposes multiple model providers under one interface, or direct API keys for the providers your dispatch rules will target.

Don't proceed past this section until each of these is verifiably working (a real `gh` call, a real no-mistakes dry run, a real harness invocation). A factory built on an unauthenticated `gh` or a daemon that isn't running just fails silently later.

## 2. Install pstack for workers

pstack (Lauren Tan's rigor skills, from the articles above) needs to live where each harness looks for skills:

1. Copy the skills from [github.com/cursor/plugins/tree/main/pstack/skills](https://github.com/cursor/plugins/tree/main/pstack/skills) into `~/.pi/agent/skills` and/or `~/.codex/skills`, depending on which harnesses you're using. Keep any existing same-name skill already installed there — don't overwrite local customizations blindly; diff first.
2. For Pi specifically: open `poteto-mode/SKILL.md` and remove the `disable-model-invocation: true` line, **only in that file**. Pi hides any skill flagged that way from automatic loading, and `poteto-mode` is the entry point workers use to find the rest of pstack — if it stays hidden, workers never discover the playbooks. Leave every other pstack skill's flags alone; workers reach those by direct file path (see the standing rules below), not automatic invocation.

## 3. Standing worker rules

Every worker needs to know pstack is installed, how to use it, and where firstmate's own delivery contract overrides it. Put this block into firstmate's `config/brief-include.md` so it's injected into every crewmate's brief:

```markdown
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
```

The "stay-inside-your-worktree rule above" this block refers to is firstmate's own standing rule already elsewhere in `brief-include.md` — a reader of this runbook alone won't have that "above" in front of them, so make sure the full brief-include file still has that rule stated before this block.

The two callouts worth reading twice: pstack's own defaults assume it's driving PRs and worktrees itself, and in this factory it never does — firstmate's delivery contract always wins that conflict. And "control-app"/"control-UI" in pstack's prose maps to *your* project's verification skill, not a generic tool pstack ships.

## 4. Dispatch rules

`config/crew-dispatch.json` tells firstmate which harness/model/effort to use per project and task type. Shape:

```json
{
 "rules": [
  {
   "when": "The task's project is a Next.js app, for any kind of crewmate or scout work. This project-based rule outranks the task-type rules below; the only exception is image generation.",
   "use": {
    "harness": "pi",
    "model": "router/gcli/grok-4.7",
    "effort": "high",
    "provider": "grok"
   },
   "why": "Captain (2026-09-25)"
  },
  {
   "when": "The task is new feature development with no PRD and no existing plan.",
   "use": {
    "harness": "claude",
    "model": "opus",
    "effort": "xhigh"
   },
   "why": "Captain (2026-09-25)"
  },
  {
   "when": "The task requires generating images.",
   "use": {
    "harness": "codex",
    "model": "gpt-6-sol"
   },
   "why": "Captain (2026-09-25)"
  },
  {
   "when": "The task is technical product design, architecture, or planning. Do not dispatch until the captain approves the chosen profile for this task.",
   "use": [
    {
     "harness": "claude",
     "model": "opus",
     "effort": "xhigh"
    },
    {
     "harness": "pi",
     "model": "router/kimi/kimi-k3",
     "effort": "xhigh",
     "provider": "kimi"
    },
    {
     "harness": "pi",
     "model": "router/cx/gpt-6-astra",
     "effort": "xhigh",
     "provider": "codex"
    }
   ],
   "why": "Captain (2026-09-25)"
  },
  {
   "when": "The task is a simple, well-defined bug fix.",
   "use": [
    {
     "harness": "pi",
     "model": "router/cx/gpt-6-luna",
     "effort": "max",
     "provider": "codex"
    },
    {
     "harness": "pi",
     "model": "router/glm/glm-5.3-flash",
     "provider": "zai"
    },
    {
     "harness": "pi",
     "model": "router/ds/deepseek-flash",
     "provider": "deepseek"
    },
    {
     "harness": "pi",
     "model": "router/gcli/grok-4.7",
     "provider": "grok"
    },
    {
     "harness": "claude",
     "model": "sonnet"
    }
   ],
   "why": "Captain (2026-09-25)"
  },
  {
   "when": "The task is implementing, refreshing, or shipping an already-specified feature: an existing issue, PR, or written plan. Not greenfield without a PRD, not architecture-only planning, and not a simple bug fix.",
   "use": [
    {
     "harness": "pi",
     "model": "router/cx/gpt-6-luna",
     "effort": "max",
     "provider": "codex"
    },
    {
     "harness": "pi",
     "model": "router/glm/glm-5.3-flash",
     "effort": "max",
     "provider": "zai"
    }
   ],
   "why": "Captain (2026-09-25)"
  }
 ],
 "default": [
  {
   "harness": "pi",
   "model": "router/cx/gpt-6-luna",
   "effort": "max",
   "provider": "codex"
  },
  {
   "harness": "pi",
   "model": "router/glm/glm-5.3-flash",
   "effort": "max",
   "provider": "zai"
  },
  {
   "harness": "pi",
   "model": "router/gcli/grok-4.7",
   "provider": "grok"
  }
 ]
}
```

Rules to follow:

- **`use` can be a single object or an array.** An array is a quota-aware fallback chain: firstmate tries entries in order and falls to the next when one is rate-limited or unavailable. A single object means only one profile fits — nowhere in this example does a single object mean "wait for a human"; that gate belongs in the `when` text instead, as the planning rule above shows ("Do not dispatch until the captain approves the chosen profile for this task"), and that rule still carries a 3-entry fallback array for after approval.
- **Project-scoped rules outrank task-type rules**, with named exceptions spelled out in `when` (above, image generation is the one thing that overrides the Next.js project rule). Task-type rules below the project rule only apply when no project rule matches.
- **If your firstmate build has typed dispatch resolution turned on, every multi-provider profile needs an explicit `"provider"` field.** Without it, the resolver can't tell which router/provider a `model` string belongs to when reconciling fallback chains across providers.
- **If you're pointing at a custom router model catalog, every entry needs real context-window and max-output-token limits**, not placeholders. Dispatch and quota logic size prompts and truncate output against these; a wrong or missing limit either wastes context headroom or causes silent truncation mid-task.
- Keep a `default` fallback chain for anything that matches no rule — an empty default means unmatched work has nowhere to go.

## 5. Registering a project

Per project, three things:

1. **Register it with firstmate**: delivery mode (direct-PR vs. no-mistakes-piloted) and whether auto-merge is on. Auto-merge should only ever be on for projects where the validation pipeline (see below) is trusted and where nothing in scope is a release, deploy, or destructive/security-sensitive change.
2. **Build the project's verification skill**, following pstack's `create-verification-skill` method: a disposable database and app instance, seeded demo roles, scripted UI driving end-to-end (Playwright or equivalent), screenshots and video captured as it runs, a Feature Map of the app's surface area, and a JSON-emitting CLI so both humans and agents can invoke it and parse the result. This is the thing every worker's output has to clear before it's considered done — see the "Verification is still the bottleneck" section of [Our software factory](our-software-factory.md) for why it matters.
3. **Add one line to the project's `AGENTS.md`** requiring runtime evidence (screenshots/video from the verification skill, not just "tests pass") in every PR. One line — resist the urge to also document the verification skill's internals there; that belongs in the skill itself, not in the file every agent session loads.

## 6. Intake

Work enters the factory as a GitHub issue carrying a `factory` label. Create that label in each pilot repo before wiring intake up.

Save the poll script as `state/factory-intake.check.sh` under your firstmate home and register it as a firstmate custom check with firstmate's `check-register` helper (adjust `REPOS` to your pilot repos). Firstmate custom checks do not reliably inherit `$FM_HOME` from the environment they run in, so hardcode the absolute path at the top of the script rather than relying on the variable being set for you:

```bash
#!/usr/bin/env bash
# Software-factory intake poll.
# Prints one line per newly `factory`-labelled open issue in the pilot repos,
# and nothing otherwise. Seen issue keys live in state/.factory-intake-seen.
set -u
FM_HOME_DIR=/absolute/path/to/your/firstmate/home  # edit this — checks may not inherit $FM_HOME
STATE_DIR="$FM_HOME_DIR/state"
SEEN="$STATE_DIR/.factory-intake-seen"
REPOS="<owner>/<repo>"
touch "$SEEN" 2>/dev/null || exit 0
for repo in $REPOS; do
  out=$(timeout 20 gh issue list -R "$repo" --state open --label factory --limit 20 \
    --json number,title -q '.[] | "\(.number)\t\(.title)"' 2>/dev/null) || continue
  [ -n "$out" ] || continue
  while IFS=$'\t' read -r num title; do
    key="$repo#$num"
    grep -qxF "$key" "$SEEN" && continue
    printf '%s\n' "$key" >> "$SEEN"
    found="${found:+$found | }https://github.com/$repo/issues/$num $title"
  done <<< "$out"
done
[ -n "${found:-}" ] && printf 'factory-intake: %s\n' "$found"
exit 0
```

On every wake where this check fires, the orchestrator: reads the newly-flagged issue(s); classifies each as bug/feature/docs and how risky; if the issue is ambiguous, asks clarifying questions as a comment on the issue and waits rather than guessing; otherwise files any missing detail and dispatches a worker per the dispatch rules above. Every resulting PR body says "Fixes #N" so intake and delivery stay linked.

## 7. Daily verification maintenance

Verification skills rot as apps grow — new routes and features need new Feature Map entries and new scripted checks. Save this as `state/verify-maintain.check.sh` and register it the same way, with `check-register`, as a second daily trigger. Same caveat as above: firstmate custom checks do not reliably inherit `$FM_HOME`, so hardcode the absolute path.

```bash
#!/usr/bin/env bash
# Daily verify-<app> maintenance trigger.
# Prints one line once per calendar day (in TZ_NAME) at or after 09:00 local,
# and nothing otherwise. The last-fired day lives in state/.verify-maintain-last.
set -u
FM_HOME_DIR=/absolute/path/to/your/firstmate/home  # edit this — checks may not inherit $FM_HOME
TZ_NAME=Asia/Bangkok  # edit this — pick your own timezone
LAST="$FM_HOME_DIR/state/.verify-maintain-last"
today=$(TZ="$TZ_NAME" date +%F)
hour=$(TZ="$TZ_NAME" date +%H)
[ "$hour" -ge 9 ] || exit 0
[ "$(cat "$LAST" 2>/dev/null)" = "$today" ] && exit 0
printf '%s\n' "$today" > "$LAST" || exit 0
printf 'verify-maintain: daily verify-<app> maintenance pass due for %s\n' "$today"
exit 0
```

Pick your own timezone and time-of-day gate — Bangkok/09:00 is just what we run. On each fire, dispatch exactly one `maintain-verification` pass per project (pstack's `maintain-verification-skill` method): update the Feature Map for anything that shipped since the last pass, and open at most one PR containing only proven corrections to the verification skill itself — not new app features, not speculative additions. Keeping this to one bounded PR a day is what keeps it a maintenance task instead of its own unreviewed feature stream.

## 8. Operating rules

These are the guardrails that make unattended operation safe:

- **Auto-merge only fires for green, in-scope work** on projects registered with auto-merge on. Anything ambiguous about scope routes to a human, not a guess.
- **Releases, deploys, and destructive/irreversible/security-sensitive changes always stay human**, regardless of how green the pipeline is or how trusted the project.
- **The orchestrator decides review findings that complete the already-accepted design** (the shape of "should this validation be here" that a spec already implies); it escalates to a human only for genuine product calls (new scope, ambiguous intent, anything not already decided).
- **A deliberately declined review finding must be recorded as an explicit, permanent skip with a reason.** Otherwise the reviewer re-raises it every subsequent round and burns cycles relitigating a decision that was already made.
- **Replace, don't nudge, a worker stuck in a loop.** If a worker repeats the same plan across turns without making edits, swap in a different model in the same worktree rather than re-prompting the same one — a stuck model rarely un-sticks itself with more encouragement.
- **Fire a maintenance pass after any PR that adds a route or feature**, not just on the daily cadence — new surface area should get verification coverage before it accumulates.
- **Cap concurrent workers** (we use 10) — each worker holds an isolated git worktree, and that's real disk and process overhead per lane, not just a scheduling nicety.

## 9. Lessons from day one

Short version of what actually went wrong on our first run (longer version in [Our software factory](our-software-factory.md#what-the-first-day-actually-looked-like)):

- **Two workers on the same model got stuck in visible thinking loops on the same task.** Swapping in a different model in the same worktree unstuck both immediately — don't waste turns re-prompting a looping worker.
- **A single large feature took four rounds of independent review before it was mergeable.** Split big features into smaller PRs up front; review rounds scale with surface area, not effort.
- **The reviewer kept re-raising a finding we'd already decided not to act on**, because we hadn't written the decision down anywhere the reviewer could see it. Record declined findings as explicit skips (rule 8 above) or expect to keep re-litigating them.
- **Registry typos in `crew-dispatch.json`** (a wrong model string, a `when` phrase that didn't quite match how tasks actually get classified, a missing `"provider"` on a multi-provider profile) silently routed work to the wrong rule or fell through to `default` instead of the intended one. Test each new rule against a real classified task before trusting it.
- **Router model catalog entries with wrong or missing context/output limits** caused silent truncation mid-task on at least one run. Verify limits against the provider's actual published numbers, not guesses, before registering a custom catalog.
