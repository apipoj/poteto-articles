# Factory runbook: setting up your own software factory

*Our own notes, not poteto's writing. A companion to [Our software factory](contract.md) (the concept and architecture) — this is the how-to. Read [How I Use Cursor](../references/poteto/how-i-use-cursor.md), [The Complete Guide to pstack Pt. 1](../references/poteto/the-complete-guide-to-pstack-pt-1.md), and [The Complete Guide to pstack Pt. 2](../references/poteto/the-complete-guide-to-pstack-pt-2.md) first if you haven't; this runbook assumes their vocabulary (verification skills, the "three-minute egg", worker/orchestrator).*

This is written so an agent — another Claude Code session, another firstmate instance, whatever — can pick it up on a fresh machine with a fresh repo and stand up its own, **separate** factory: its own orchestrator, its own workers, its own projects. Nothing here wires you into anyone else's factory. If you're a human handing this off, the agent should be able to follow it with minimal supervision; check in at the "needs-decision" points called out below.

## 1. Prerequisites

> Running entirely on Claude Code on the web with Claude models only? Skip firstmate, Pi, Codex, and `gh`: follow [adapters/claude-code-cloud.md](../adapters/claude-code-cloud.md), which maps every section below onto cloud sessions and Routines.

Before touching any of this, confirm you have:

- **firstmate installed and bootstrapped** — [github.com/kunchenguid/firstmate](https://github.com/kunchenguid/firstmate). Follow its own setup docs first; this runbook picks up after firstmate exists and can dispatch work.
- **`gh` authenticated** against the GitHub account/org that will own your factory's repos (`gh auth status` should be green).
- **no-mistakes installed** — the validation pipeline (review, tests, lint, docs, push, PR, CI) that gates what workers ship.
- **At least one worker harness**: Claude Code, Pi, or Codex. You can run more than one side by side (that's the point of dispatch rules below), but you need at least one working end to end before you register a project.
- **A model router or provider keys** — either a router that exposes multiple model providers under one interface, or direct API keys for the providers your dispatch rules will target.

Don't proceed past this section until each of these is verifiably working (a real `gh` call, a real no-mistakes dry run, a real harness invocation). A factory built on an unauthenticated `gh` or a daemon that isn't running just fails silently later.

## 2. Install pstack for workers

pstack (Lauren Tan's rigor skills, from the articles above) needs to live where each harness looks for skills:

1. Copy the skills from [the pstack skills directory](https://github.com/cursor/plugins/tree/main/pstack/skills) to each harness's skill location.
   Use `~/.pi/agent/skills` for Pi, `~/.codex/skills` for Codex, and `~/.claude/skills` or the
   project `.claude/skills` for local Claude Code. Keep any existing same-name skill. Diff before
   replacing local changes.
2. For Claude Code on the web, commit required skills under the project's `.claude/skills/` or provision account-synced skills for the Environment. Cloud sessions cannot read the operator's local `~/.claude/skills/`. Keep a `name` and a concrete trigger `description` in each `SKILL.md`.
   For unattended automatic entry, remove `disable-model-invocation: true` from the copied
   `poteto-mode` entry, or tell the worker to read that file by path. Check discovery with `/skills`
   and a nontrivial scout prompt in a local and a fresh cloud session. See the
   [Claude Code skills guide](https://code.claude.com/docs/en/skills) for current locations and frontmatter.
3. For Pi specifically, open `poteto-mode/SKILL.md` and remove the `disable-model-invocation: true` line, **only in that file**. Pi hides any skill flagged that way from automatic loading, and `poteto-mode` is the entry point workers use to find the rest of pstack. Leave every other pstack skill's flags alone; workers reach those by direct file path (see the standing rules below), not automatic invocation.
4. Claude Code can use its subagents for parallel explorer, arena, or swarm steps only when the session exposes those tools. If it does not, run the playbook in sequence and report that no subagents ran. Skip Cursor-only references and tools such as `cursor-team-kit`, `deslop`, `create-skill`, Cursor Automations, and Cursor cloud agents.

## 3. Standing worker rules

Every worker needs to know pstack is installed, how to use it, and where firstmate's own delivery contract overrides it. The only copy of that standing block is [templates/brief-include.pstack.md](../templates/brief-include.pstack.md). Append that file into firstmate's `config/brief-include.md` so it is injected into every crewmate's brief. Read that file when you follow this section.

The effort rule in that file is the one workers follow. When the harness can set effort, use `templates/effort.md`. A higher level spends more checking inside the issue. The diff stays on the issue. The model stays the one dispatch named. If the same plan repeats without new edits, stop. The orchestrator swaps the model. Do not raise effort instead.

The phrase "stay-inside-your-worktree rule above" in that file refers to firstmate's own standing rule, already elsewhere in `brief-include.md`. State that rule in the full brief-include file before the appended block.

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
- **`effort` is optional.** It sets how much checking the worker does inside the issue. The diff stays on the issue. The model stays the one in `model`. Levels and the escalate loop are in [templates/effort.md](../templates/effort.md). Copy that file next to the live dispatch rules. When the harness can set effort, the profile `effort` wins. A new rule uses the levels in `effort.md`. The strings in the example above, and in [templates/crew-dispatch.example.json](../templates/crew-dispatch.example.json), are the captain record. Leave that snapshot alone. Do not copy `max` onto a new rule only because the snapshot has it. A harness that cannot set effort keeps the session default, and the worker writes that on the issue. The stuck-worker rule in §8 still applies.

## 5. Registering a project

Per project, three things:

1. **Register it with firstmate**: delivery mode (direct-PR vs. no-mistakes-piloted) and whether auto-merge is on. Auto-merge should only ever be on for projects where the validation pipeline (see below) is trusted and where nothing in scope is a release, deploy, or destructive/security-sensitive change.
2. **Build the project's verification skill**, following pstack's `create-verification-skill` method: a disposable database and app instance, seeded demo roles, scripted UI driving end-to-end (Playwright or equivalent), screenshots and video captured as it runs, a Feature Map of the app's surface area, and a JSON-emitting CLI so both humans and agents can invoke it and parse the result. This is the thing every worker's output has to clear before it's considered done — see the "Verification is still the bottleneck" section of [Our software factory](contract.md) for why it matters.
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

Short version of what actually went wrong on our first run (longer version in [Our software factory](contract.md#what-the-first-day-actually-looked-like)):

- **Two workers on the same model got stuck in visible thinking loops on the same task.** Swapping in a different model in the same worktree unstuck both immediately — don't waste turns re-prompting a looping worker.
- **A single large feature took four rounds of independent review before it was mergeable.** Split big features into smaller PRs up front; review rounds scale with surface area, not effort.
- **The reviewer kept re-raising a finding we'd already decided not to act on**, because we hadn't written the decision down anywhere the reviewer could see it. Record declined findings as explicit skips (rule 8 above) or expect to keep re-litigating them.
- **Registry typos in `crew-dispatch.json`** (a wrong model string, a `when` phrase that didn't quite match how tasks actually get classified, a missing `"provider"` on a multi-provider profile) silently routed work to the wrong rule or fell through to `default` instead of the intended one. Test each new rule against a real classified task before trusting it.
- **Router model catalog entries with wrong or missing context/output limits** caused silent truncation mid-task on at least one run. Verify limits against the provider's actual published numbers, not guesses, before registering a custom catalog.
