# Adapter: Claude Code on the web (cloud, Claude models only)

**Entry:** load [AGENTS.md](../AGENTS.md), then this file. Templates live in
[templates/claude-code-cloud/](../templates/claude-code-cloud/).

Use this when the whole factory runs inside Claude Code on the web (claude.ai/code): no firstmate,
no Pi or Codex, no local machine. Every role is a cloud session, and every model is a Claude model.
It can run alongside a firstmate factory on the same repo; see "Coexisting with firstmate".

## Mapping

| Kit piece | Claude Code cloud |
| --- | --- |
| Claude Code Environment | **One per project** (e.g. `timeflow`). The orchestrator and maintenance sessions are created in it, and every worker and reviewer inherits it |
| Orchestrator (firstmate) | A **Routine** that fires hourly into a persistent orchestrator session created with the repo attached and runs one orchestrator pass ([orchestrator.md](../templates/claude-code-cloud/orchestrator.md)), in the project's Environment |
| `factory-intake.check.sh` + `gh` | The orchestrator lists issues labeled `factory-cloud` with the **GitHub MCP tools** (cloud sessions have no `gh`) |
| `state/.factory-intake-seen` | `<!-- factory:... -->` **marker comments** on the issue. The `factory:` prefix is a shared protocol marker, not the Environment name. Each Routine firing is a fresh container, so state must live on GitHub |
| Worker in an isolated worktree | One **cloud session per issue** (`create_session`, `outcome_branch: factory-cloud/issue-<N>`). The container is the isolation |
| `crew-dispatch.json` | [crew-dispatch.json](../templates/claude-code-cloud/crew-dispatch.json): Claude models, fallback chains in order |
| no-mistakes pipeline | The worker runs the checks and verification, opens the PR, then **subscribes to the PR's activity** and drives CI and review comments to green |
| Cross-family reviewer | A separate reviewer session on a **different Claude model** ([reviewer-brief.md](../templates/claude-code-cloud/reviewer-brief.md)) |
| `verify-maintain.check.sh` | A second Routine, daily, running the project's `maintain-verification` pass |
| Stuck worker, swap model | New session with the next model in the chain, same `factory-cloud/issue-<N>` branch as `source_revision` and `outcome_branch` |

## Deviations from the contract (say them out loud)

1. **Cross-model, not cross-family, review.** With Claude only, the reviewer is a different Claude
   model from the author, in a fresh session with no author context. Same-lineage models can share
   blind spots, so keep a human merge unless you add a non-Claude reviewer.
2. **`create_session` takes `model`.** The call in
   [orchestrator.md](../templates/claude-code-cloud/orchestrator.md) passes `source_url`,
   `outcome_branch`, `model`, `tags`, `title`, and `prompt`. A replacement also passes
   `source_revision`. The call has no `effort` argument. The Messages API field
   `output_config.effort` is a different API and does not set a Claude Code session's effort.
   Unattended cloud sessions use the project's default effort configuration. Do not claim a
   role-specific effort level. The template leaves `effortLevel` and `modelSettings` unset. A retry
   changes `model` only. Copy [templates/effort.md](../templates/effort.md) to
   `docs/factory/effort.md` for general guidance; the cloud default policy takes precedence.
3. **Workers own delivery.** No separate pipeline exists, so the worker opens its PR and drives it
   green. It never merges, tags, deploys, or touches production.
4. **Lower concurrency.** Start at 3 workers: each is a container plus model spend.

## Human merge gate

Cloud sessions use the connected GitHub identity. A prompt cannot enforce the rule that only a
human merges. Complete the GitHub controls in [phase 0 of the cloud playbook](../playbooks/claude-code-cloud.md#phase-0-owner-prerequisites-human-only-about-10-minutes).
Do this before enabling a Routine:

- Configure branch protection or a ruleset to require human approval and checks on the default
  branch. Restrict merge and bypass rights to human maintainers.
- If a label triggers a merge, make the workflow verify that an approved human applied the label
  and that tests passed on the exact PR head.
- Use a separate automation identity without merge authority when possible.
- Test a blocked automation merge in a test repository before enabling the factory.

For defense in depth, apply
[`worker-settings.example.json`](../templates/claude-code-cloud/worker-settings.example.json) only
to worker sessions. It denies matching GitHub MCP merge and label-write tools through
[`PreToolUse`](https://code.claude.com/docs/en/hooks#pretooluse-decision-control). Replace its
matcher names with the exact tool names exposed in your environment, then test each denial. The
example blocks every call to its listed label tools, not only merge labels. Add every label-writing
tool your integration exposes. Do not add it to the shared project
`.claude/settings.json` or another settings profile used by the operator. The `create_session` call
in this kit does not select a settings file. Apply this example only if your Environment can load a
separate worker-only profile. Otherwise, leave it unapplied rather than adding it to shared
settings. GitHub must enforce the merge gate even if a session hook is missing or bypassed.

## Skills

A cloud session cannot use the operator's local `~/.claude/skills/`. Commit required skills under
the project's `.claude/skills/` or provision account-synced skills for the Environment. Follow
[runbook §2](../factory/runbook.md#2-install-pstack-for-workers) to keep automatic entry skills
visible and verify discovery in a fresh cloud session.

## Environment setup

Give each project its **own Claude Code Environment** (named after the project, e.g. `timeflow`).
Don't share the `Default` one, or one environment across projects:

- **Secrets and environment variables leak across projects.** Anything added to a shared
  environment for project A is visible to every factory worker of project B.
- **One project's changes break another's factory.** Tightening a shared environment's network
  policy or setup script for one project can silently stop another project's workers.
- Keep the factory's environment free of production secrets: workers need only GitHub (through
  the connected tools) and a disposable local database.

Sessions inherit the environment of the session that creates them. So create the orchestrator and
maintenance sessions with `environment_id` set to the project's environment (look it up with
`list_environments`; a person creates the environment on claude.ai). Every worker and reviewer the
orchestrator spawns then lands there without further configuration.

**Moving an existing factory to a new environment:** create new orchestrator and maintenance
sessions in it (run a no-write setup check in each first: GitHub read, and the SessionStart hook's
database), then create new Routines pointing at them and disable the old ones. `update_trigger`
cannot repoint a Routine to another session. Workers already running finish where they are.

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

- **Fire into a session created with the repo attached, not a fresh session per firing.** A
  fresh Routine session starts with no repo, and `add_repo` is refused by the auto-mode permission
  check when no human is watching. The pass then runs (~76 s, ~$0.45) without ever reaching GitHub:
  no holds, no dispatch, no error you can see. Create the orchestrator session once with
  `create_session` and `source_url` (sparse checkout of `docs/factory`, depth 1, to keep the clone
  small) and create the Routine with `persistent_session_id` pointing at it. Do the same for the
  maintenance session (full clone: it runs the app). The conversation continues across firings;
  when its context gets large, create a new session the same way and repoint the Routine.
- **Keep the orchestrator's checkout small.** A full clone loads the project's `CLAUDE.md` /
  `AGENTS.md` and more into context: in our test an idle pass used ~99k tokens and cost ~$0.57,
  ~$14/day hourly. Read the factory docs with `get_file_contents`. Workers do clone fully: they
  need the code.
- **Fired sessions default to Sonnet**, which suits the orchestrator (it dispatches; it doesn't
  build). Workers get their model from `crew-dispatch.json` via `create_session`.
- **Routines created from a session may store no connectors.** The factory needs only GitHub and
  the Claude Code Remote tools, not claude.ai connectors (Slack, Linear, ...). If you add a
  connector-dependent step, create the Routine from the claude.ai Routines page instead.
- **Guard every Routine prompt** with "if that file does not exist yet, reply factory-cloud not set up yet",
  so Routines can be created before the setup PR merges.
- **"Run now" ignores the persistent session.** `fire_trigger` (and the Routines page's run
  button) starts a fresh session in the default environment with no repo, so the pass does
  nothing, exactly like the fresh-session failure above. To run a pass now, create a one-shot
  Routine (`run_once_at` a minute or two ahead) with the same `persistent_session_id`: scheduled
  firings do land in the persistent session.
- **Fire it once by hand** before trusting the schedule, and check its effect on GitHub (hold
  markers on the issues). You may not be able to read a fired session's transcript, so judge it by
  what it wrote.

## Monitoring page (optional)

A private claude.ai page (an Artifact) gives the owner one place to watch the factory. The page
**cannot call Claude Code Remote** (it is not a connector a page can use), and it only reads GitHub
if the owner has a GitHub connector on claude.ai. So have the orchestrator write a snapshot at the
end of each pass instead: one `ArtifactData` `set` of a single document (issues with hold reasons,
open factory PRs with CI and review state, agents from `list_sessions`, the two Routines from
`get_trigger`, the 5-hour limit from `get_session`'s `rate_limit_info`, and a "needs you" list).
The page subscribes to that document, so it updates when the pass lands, and flags the snapshot as
stale when it is over 2 hours old. Declare the page's database with root `write: "admin"`, so only
the owner (and Claude, acting as the owner) writes it.

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

## Auto-merge labels

Cloud sessions post to GitHub as the account owner. If the project auto-merges on a label (e.g.
`merge-approved`), any session could merge its own PR by adding it. The templates forbid every
factory role from touching such a label; keep that line if you customise them.

## Coexisting with firstmate

Firstmate polls the label `factory`. This cloud factory polls `factory-cloud`. Two orchestrators on one label dispatch the same issue twice.

## Setup checklist

1. Build the project's verification skill (runbook §5) and prove its full cycle inside a cloud
   session: start, health check, one screenshot, one scripted flow, teardown.
2. Copy the templates into the project (`docs/factory/`, `.claude/`, and
   `pull_request_template.md` into `.github/`), fill the placeholders, and point the project's
   `CLAUDE.md` at them in one line.
3. Create the GitHub intake label `factory-cloud`.
4. Create the orchestrator and maintenance sessions with the repo attached, then the two Routines
   (hourly intake, daily maintenance) pointing at them with the prompts at the end of
   [orchestrator.md](../templates/claude-code-cloud/orchestrator.md), both sessions in the
   project's own Environment (a person creates it on claude.ai first). Any cloud session can do the
   rest with `create_session` (`environment_id`) and `create_trigger`.
5. Dry-run one orchestrator pass by hand (no writes) against the open issues, then fire the intake
   Routine once and check the hold markers it posts. Label one small issue and watch the first real
   pass before leaving it unattended.
