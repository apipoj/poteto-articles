# software-factory

Harness-agnostic **software factory** kit: orchestrator + workers + verification + merge gates.

Clone this repo into any AI coding agent (Claude Code, Cursor, Pi, Codex, or another firstmate instance) and follow [AGENTS.md](AGENTS.md).

## Quick start for agents

1. Read **[AGENTS.md](AGENTS.md)** (universal entry).
2. Read **[factory/contract.md](factory/contract.md)** (architecture and operating principles).
3. Read **[factory/runbook.md](factory/runbook.md)** when standing up or operating a factory.
4. Open your harness file under **[adapters/](adapters/)** (`claude`, `claude-code-cloud`, `cursor`, `pi`, `codex`).
5. Copy templates from **[templates/](templates/)** into your firstmate (or equivalent) home as the runbook describes.

## Layout

```
AGENTS.md                 Universal agent entry (start here)
CLAUDE.md                 Thin Claude Code pointer → AGENTS.md
adapters/                 Thin per-harness notes
factory/
  contract.md             What we built and how it fits together
  runbook.md              How to stand up your own separate factory
templates/                Dispatch rules, brief-include, intake scripts
  claude-code-cloud/      Claude-only factory on Claude Code on the web (no firstmate)
references/poteto/        Foundational pstack articles (© @poteto)
.cursor/rules/            Cursor always-on pointer into this kit
```

## Foundational reading (pstack)

Markdown conversions of [@poteto](https://x.com/poteto) (Lauren Tan) X Articles — reformatted for offline/agent use. Images and video stay on the source posts.

Suggested order:

1. [How I Use Cursor](references/poteto/how-i-use-cursor.md) — [source](https://x.com/poteto/status/2058975157503570132)
2. [The Complete Guide to pstack Pt. 1](references/poteto/the-complete-guide-to-pstack-pt-1.md) — [source](https://x.com/poteto/status/2094457600259842065)
3. [The Complete Guide to pstack Pt. 2](references/poteto/the-complete-guide-to-pstack-pt-2.md) — [source](https://x.com/poteto/status/2097732320606507506)

Factory contract and runbook are **our own notes**, not poteto's writing. They assume the vocabulary above (verification skills, three-minute egg, worker/orchestrator).

## License / courtesy

- `references/poteto/` — content © original author; keep source links and attribution; prefer linking the X Articles when sharing publicly.
- Everything else in this repo — use freely for standing up your own separate factory; no warranty.
