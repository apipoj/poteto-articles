# Templates

Copy these into your firstmate (or equivalent orchestrator) home. Paths and absolute `FM_HOME_DIR` values are yours to fill — see [factory/runbook.md](../factory/runbook.md).

| File | Goes to |
| --- | --- |
| `effort.md` | Effort guide for dispatch rules. Copy to `config/effort.md`, and to `docs/factory/effort.md` on the Claude Code cloud path |
| `brief-include.pstack.md` | Append/merge into `config/brief-include.md` |
| `crew-dispatch.example.json` | Start of `config/crew-dispatch.json` (edit rules) |
| `factory-intake.check.sh` | `state/factory-intake.check.sh` + register via `check-register` |
| `verify-maintain.check.sh` | `state/verify-maintain.check.sh` + register via `check-register` |
| `claude-code-cloud/` | Claude Code on the web variant (no firstmate): orchestrator, briefs, dispatch rules into `docs/factory/`; `session-start.sh` + `settings.json` into `.claude/`; `pull_request_template.md` into `.github/`. See [adapters/claude-code-cloud.md](../adapters/claude-code-cloud.md) |
