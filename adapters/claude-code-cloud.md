# Adapter: Claude Code on the web (cloud, Claude models only)

**Entry:** load [AGENTS.md](../AGENTS.md), then this file. Templates live in
[templates/claude-code-cloud/](../templates/claude-code-cloud/).

Use this when the whole factory runs inside Claude Code on the web (claude.ai/code): no firstmate,
no Pi or Codex, no local machine. Every role is a cloud session, and every model is a Claude model.
It can run alongside a firstmate factory on the same repo; see "Coexisting with firstmate".

## Mapping

| Kit piece | Claude Code cloud |
| --- | --- |
| Orchestrator (firstmate) | A **Routine** that starts a fresh session each firing (hourly) and runs one orchestrator pass ([orchestrator.md](../templates/claude-code-cloud/orchestrator.md)) |
| `factory-intake.check.sh` + `gh` | The orchestrator lists labeled issues with the **GitHub MCP tools** (cloud sessions have no `gh`) |
| `state/.factory-intake-seen` | `<!-- factory:... -->` **marker comments** on the issue. Each Routine firing is a fresh container, so state must live on GitHub |
| Worker in an isolated worktree | One **cloud session per issue** (`create_session`, `outcome_branch: factory/issue-<N>`). The container is the isolation |
| `crew-dispatch.json` | [crew-dispatch.json](../templates/claude-code-cloud/crew-dispatch.json): Claude models, fallback chains in order |
| no-mistakes pipeline | The worker runs the checks and verification, opens the PR, then **subscribes to the PR's activity** and drives CI and review comments to green |
| Cross-family reviewer | A separate reviewer session on a **different Claude model** ([reviewer-brief.md](../templates/claude-code-cloud/reviewer-brief.md)) |
| `verify-maintain.check.sh` | A second Routine, daily, running the project's `maintain-verification` pass |
| Stuck worker, swap model | New session with the next model in the chain, same `factory/issue-<N>` branch as `source_revision` and `outcome_branch` |

## Deviations from the contract (say them out loud)

1. **Cross-model, not cross-family, review.** With Claude only, the reviewer is a different Claude
   model from the author, in a fresh session with no author context. Same-lineage models can share
   blind spots, so keep a human merge unless you add a non-Claude reviewer.
2. **No `effort` in dispatch.** `create_session` takes a model, not an effort level.
3. **Workers own delivery.** No separate pipeline exists, so the worker opens its PR and drives it
   green. It never merges, tags, deploys, or touches production.
4. **Lower concurrency.** Start at 3 workers: each is a container plus model spend.

## Environment setup

Put setup in a **repo SessionStart hook** ([session-start.sh](../templates/claude-code-cloud/session-start.sh)
+ [settings.json](../templates/claude-code-cloud/settings.json)), not only in the environment's setup
script: the hook is version-controlled and runs in every worker the orchestrator spawns. Guard it
with `CLAUDE_CODE_REMOTE=true` so it is a no-op on laptops. Export variables for later commands by
appending `export KEY=value` lines to `$CLAUDE_ENV_FILE`.

What we found on a real cloud container (Sept 2026):

- **You do not need Docker for a disposable database.** The session container is already
  disposable. Containers ship PostgreSQL 16 (`pg_ctlcluster 16 main start`); create one database
  per verification run and drop it on teardown. Check your migrations only need extensions the
  local cluster has (`ls /usr/share/postgresql/16/extension`); `pgvector` is not installed by
  default (`apt` offers `postgresql-16-pgvector`).
- **If you must use Docker:** `dockerd` is installed but not running (start it in the hook), and
  Docker Hub answers `429` to the shared egress. Pull through `mirror.gcr.io/<image>` and retag.
- **Playwright:** Chromium is preinstalled at `/opt/pw-browsers/chromium`. If the project pins a
  different Playwright version, its expected browser build is missing; pass that path as
  `executablePath` rather than running `playwright install`.
- **Port checks:** `lsof` can miss listening sockets in the sandboxed kernel; `fuser -n tcp <port>`
  works.
- **`list_sessions` tag filters** are not available from inside a session. Track workers through
  the session ids in your issue markers plus `get_session`.

## Routines

- **The orchestrator must not clone the repo.** A clone loads the project's `CLAUDE.md` /
  `AGENTS.md` into context: in our test an idle pass (nothing to do) used ~99k tokens and cost
  ~$0.57, which is ~$14/day hourly. Attach the repo with `add_repo` for GitHub tool access and read
  the factory docs with `get_file_contents`. Workers do clone: they need the code.
- **Fired sessions default to Sonnet**, which suits the orchestrator (it dispatches; it doesn't
  build). Workers get their model from `crew-dispatch.json` via `create_session`.
- **Routines created from a session may store no connectors.** The factory needs only GitHub and
  the Claude Code Remote tools, not claude.ai connectors (Slack, Linear, ...). If you add a
  connector-dependent step, create the Routine from the claude.ai Routines page instead.
- **Guard every Routine prompt** with "if the factory docs aren't on the default branch yet, stop",
  so Routines can be created before the setup PR merges.
- **Fire it once by hand** before trusting the schedule, and read that session's last message.

## Issue conventions (firstmate-style issues)

Issues written for firstmate carry `Kind:`, `Gate:` (`held`, `hard GO`, `soft GO`, conditional),
dependency phrases ("after S1", "blocked on the decision ticket"), and ids of reports that live in
firstmate's local home. The template orchestrator handles each: decisions and ops never dispatch,
dependencies wait for the other issue to close, hard and conditional gates wait for a human `GO`
comment, and a referenced report that is not in the repo holds the issue until someone commits it
(cloud workers only see the repo). Each hold is posted once. Dry-run the orchestrator against your
real issue list before enabling it: ours held all nine issues for good reasons, and showed the gate
rules were missing.

## Runtime evidence

Screenshots must reach the PR, and the cloud session cannot upload images to GitHub directly.
Workers commit the PNGs, remove them in the very next commit, push both, and link the images by the
first commit's SHA (`https://github.com/<owner>/<repo>/blob/<sha>/<path>.png?raw=true`). With
squash merges the images never reach the default branch, and `refs/pull/<n>/head` keeps the commit
reachable.

## Coexisting with firstmate

If a firstmate factory already polls the `factory` label, give the cloud factory its own label
(e.g. `factory-cloud`). Two orchestrators on one label dispatch the same issue twice.

## Setup checklist

1. Build the project's verification skill (runbook §5) and prove its full cycle inside a cloud
   session: start, health check, one screenshot, one scripted flow, teardown.
2. Copy the templates into the project (`docs/factory/`, `.claude/`, and
   `pull_request_template.md` into `.github/`), fill the placeholders, and point the project's
   `CLAUDE.md` at them in one line.
3. Create the intake label.
4. Create the two Routines (hourly intake, daily maintenance) with the prompts at the end of
   [orchestrator.md](../templates/claude-code-cloud/orchestrator.md). Ask a cloud session to create
   them; each firing starts a new session in the same environment.
5. Dry-run one orchestrator pass by hand (no writes) against the open issues, then fire the intake
   Routine once and read its session. Label one small issue and watch the first real pass before
   leaving it unattended.
