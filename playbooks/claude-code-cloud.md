# Playbook: a Claude-only factory on Claude Code cloud

This is the procedure for putting a new project on the cloud factory, in the order that works. The
[adapter](../adapters/claude-code-cloud.md) explains why each piece is built the way it is; the
[templates](../templates/claude-code-cloud/) are the files you copy. The reference implementation
is TimeFlow (`apipoj/timesheet-app`, `docs/factory/`), which ran through every step below in
September 2026.

Expect one sitting to set it up, then a day of light watching before you leave it alone.

## Who does what

| Role | What it is | What it does |
| --- | --- | --- |
| **Owner** | You | Decisions, `GO`, merges, production, secrets, attestations |
| **Operator session** | A Claude Code cloud session you talk to | Sets the factory up, changes its config through PRs, relays your `GO`, fixes the factory when it breaks |
| **Orchestrator** | A persistent Sonnet session, woken hourly by a Routine | Reads issues, posts holds, dispatches workers and reviewers, writes the monitor snapshot. Never writes code or merges |
| **Workers** | One cloud session per issue | Build, verify in the running app, open the PR, drive CI to green |
| **Reviewer** | One session per PR head, on a different model from the author | Posts a `pass` or `changes` verdict |
| **Maintenance** | A persistent session, woken daily | Keeps the project's verification skill working |

## Phase 0: owner prerequisites (human-only, about 10 minutes)

1. **Create a Claude Code environment for this project** on claude.ai, named after it. Give it no
   production secrets, and network access that allows the package registry. Don't reuse `Default`
   or another project's environment: secrets and settings leak across projects.
2. **GitHub:** the Claude GitHub App is installed on the repo, and the repo is in the operator
   session's scope.
3. **Enforce the human merge gate before enabling the factory.** The kit cannot change GitHub
   repository settings. Configure branch protection or a ruleset to require human approval and
   checks on the default branch. Restrict merge or bypass rights to human maintainers. For
   label-driven merges, make the workflow verify that an approved human applied the label. Require
   tests to pass on the exact PR head. Use a separate automation identity without merge authority
   when possible. Test these controls in a test repository, including a blocked automation merge.
   The [worker-only PreToolUse example](../templates/claude-code-cloud/worker-settings.example.json)
   is defense in depth. Test its denials if the Environment supports a worker-only settings
   profile. Do not add it to shared operator settings.
4. **Decide four things up front** (you can change each later by telling the operator session):
   - who merges: you do. An auto-merge label, if any, is applied only by a person;
   - the worker cap: start at 3;
   - the model policy (see [Models](#models));
   - whether a `GO` you give in chat counts (see [Day to day](#day-to-day)).

## Phase 1: make the project factory-ready (operator session, through PRs)

- **CI on GitHub-hosted runners, tiered by what changed.** A docs-only PR should finish in about
  20 seconds and a code PR runs the full suite. Don't depend on a self-hosted runner: a job queued
  for a missing runner holds its concurrency group for up to 24 hours and blocks the default
  branch.
- **Merges stay human.** Apply the branch protection and actor checks from phase 0. A label-driven
  `auto-merge.yml` must verify an approved human applied the label and that Tests passed on the
  exact head. Merges made with `GITHUB_TOKEN` do not trigger CI on the default branch.
- **A verification skill proven inside a cloud session** ([runbook §5](../factory/runbook.md)):
  start the app, check health, take one screenshot, run one scripted flow, tear down. Its setup
  lives in a repo SessionStart hook ([session-start.sh](../templates/claude-code-cloud/session-start.sh)),
  so every worker gets it.
- If the project pins a Playwright version, pass the container's Chromium path as
  `executablePath` instead of running `playwright install`.

## Phase 2: install the kit (operator session, one PR)

1. Copy `templates/claude-code-cloud/` into the project: the orchestrator, the briefs, and
   `crew-dispatch.json` into `docs/factory/`; `settings.json` into `.claude/settings.json`;
   `session-start.sh` into `.claude/hooks/cloud-session-start.sh` and make it executable with
   `chmod +x`; and `pull_request_template.md` into `.github/`. Point `CLAUDE.md` at
   `docs/factory/` in one line.
2. Before enabling a Routine, check `test -x .claude/hooks/cloud-session-start.sh` in the project
   repo, then start a fresh cloud session and complete the worker preflight in the brief. The hook
   prepares the container but does not block a session when setup fails.
3. Fill the placeholders:
   - `<owner>/<repo>`, `<verify-skill>`, `<check command>`, `<cap>`, `<floor rules>`;
   - `<operator-session-id>`, only if relayed GO is on;
   - `<monitor-url>` and the two trigger ids after phase 3, or delete the monitor paragraph.
4. Write the project's floor rules into the worker and reviewer briefs: the few things v1 must
   never break (TimeFlow's are private memory never visible to managers, money data admin-only,
   and no unnamed external model provider receiving real employee data). Everything else starts
   simple, and hardening goes under "Noticed, not fixed".
5. Create the GitHub label `factory-cloud`. Merge the PR.

## Phase 3: start the factory (operator session)

1. **Orchestrator session:** `create_session` with these settings:
   - `environment_id` = the project's environment;
   - `source_url` = the repo, sparse checkout of `docs/factory`, depth 1;
   - model `claude-sonnet-5`, `permission_mode: auto`, tag `factory:orchestrator`.

   Its first prompt is a no-write setup check: read `orchestrator.md` with `get_file_contents`,
   list the intake issues, and report its environment id.
2. **Maintenance session:** the same, but with a full clone and tag `factory:maintenance`. Its
   setup check runs the SessionStart hook and `pnpm install` (or the project's equivalent), and
   confirms the database answers.
3. **Routines**, both with `persistent_session_id`:
   - **intake:** hourly on an off-minute (for example `37 * * * *`);
   - **maintenance:** daily at a jittered time (for example `CRON_TZ=Asia/Bangkok 52 8 * * *`).

   Use the prompts at the end of the template orchestrator.
4. **Monitor page (optional):** publish [monitor.html](../templates/claude-code-cloud/monitor.html)
   as an Artifact.
   - Set `PROJECT` and `OWNER/REPO` first.
   - Capabilities: `{db: {rules: [{path: "", read: "view", write: "admin"}]}}`.
   - Seed `factory/board` once, then put the page URL and both trigger ids into `orchestrator.md`.
5. **First pass:** don't use "run now". Create a one-shot Routine (`run_once_at` two minutes
   ahead) on the orchestrator session. Then check GitHub: every intake issue should carry exactly
   one hold or dispatch marker, and the monitor snapshot should say `source: orchestrator pass`.

## Phase 4: feed it issues

Write issues the orchestrator can route:
- `Kind:`: `decision` or `ops` issues never dispatch.
- `Gate:`: `soft GO`, `hard GO`, or a condition.
- Dependencies in plain words ("after S1", "blocked on #620").
- Acceptance criteria a worker can check.

A decision issue that is still open also holds any issue whose change it is still asking about.
Start with one small, doc-only issue and watch it go through dispatch, PR, review and merge before
labeling more.

## How a worker works

Every worker runs the same gated pipeline, the way
[no-mistakes](https://github.com/kunchenguid/no-mistakes) does for a local push:

1. intent, with the scenarios that prove the change;
2. build;
3. rebase on the default branch;
4. self-review;
5. test, including a **Live validation** table (Scenario | Result | Live | Evidence);
6. docs;
7. evidence and PR, ending with a `factory:pipeline` attestation;
8. CI.

Mechanical findings get fixed. A question that changes what the product does becomes a draft PR
with a **Needs owner decision** section, and it shows up in your needs-you list. Nothing is
guessed. The reviewer blocks behaviour that wasn't driven live.

The tool itself isn't installed in cloud sessions: it wants an interactive owner for escalations
and runs a nested agent. The brief carries its discipline instead.

## Day to day

- **Watch the monitor page's "Needs you" box.** That list is the owner's whole job.
- **Give a GO:** comment `GO` on the issue. If relayed GO is on, you can instead tell the operator
  session "GO #624 #625": it posts the GO with a `factory:go relayed-by=<its session id>` marker,
  and the orchestrator counts only that session's marker.
- **Run a pass now:** ask the operator session. It creates a one-shot Routine, because "run now"
  starts a fresh session without the repo.
- **Change the cap or the models:** tell the operator session. It edits `orchestrator.md` or
  `crew-dispatch.json` in a PR and merges it once CI is green.
- **Merge:** review the PR and merge it, or apply your auto-merge label.
- **Move environments:** create new sessions and new Routines, then disable the old Routines.
  Workers already running finish where they are.

## Models

- **No Haiku.** It can't run in auto mode, so an unattended Haiku session stops at a permission
  prompt that nobody answers.
- **Kit default:** Opus 5.5 for design and security-sensitive work, Sonnet 5 for building from a
  written spec, and Sonnet for the orchestrator and maintenance.
- **All development on Opus** (TimeFlow's choice): put Opus 5.5 first in every build rule and
  keep Sonnet as the fallback. The reviewer is still the first model that differs from the
  author, so Sonnet reviews Opus work. This uses more of the 5-hour limit, which the monitor page
  shows.
- **Effort uses the project default.** Unattended cloud sessions use the project's default effort
  configuration. Do not claim a role-specific level. The shipped `.claude/settings.json` leaves
  `effortLevel` and `modelSettings` unset, and `create_session` has no effort field. Use the
  reviewer brief and the project's verification skill when a task needs more scrutiny.

## Known failures

| Symptom | Cause | Fix |
| --- | --- | --- |
| The Routine runs but nothing appears on GitHub | A fresh session per firing has no repo, and `add_repo` is refused unattended | Fire into a persistent session created with the repo attached |
| "Run now" does nothing | `fire_trigger` ignores `persistent_session_id` | Create a one-shot Routine on the same session |
| A worker sits waiting for approval | Haiku, or another permission prompt in auto mode | No Haiku; the orchestrator replaces `blocked` workers |
| A finished worker gets replaced | A worker waiting for merge also reads as `blocked` | Leave a worker whose PR is green with no `changes` verdict |
| A worker built what a decision issue was still asking | The open decision wasn't treated as a dependency | Hold issues whose change an open decision still asks about |
| Every idle pass is expensive | The orchestrator cloned the whole repo | Sparse-checkout `docs/factory`, depth 1, and read with `get_file_contents` |
| The monitor page says a call is blocked | A page can't call Claude Code Remote | The orchestrator writes a snapshot; the page reads only that |
| A Routine's prompt can't be edited | A prompt can only be changed from the session it fires into | Create a new Routine, delete the old one, and update its id in `orchestrator.md` |
| Default-branch CI is stuck for hours | A job waits for a missing self-hosted runner | GitHub-hosted runners |
| One project's secret appears in another's worker | A shared environment | One environment per project |
| Playwright can't find its browser | The pinned version expects a different Chromium build | `executablePath` from the SessionStart hook |
| PR screenshots don't show | A cloud session can't upload images | Commit, link by SHA, remove in the next commit ([adapter](../adapters/claude-code-cloud.md#runtime-evidence)) |

## Tools considered

- **[no-mistakes](https://github.com/kunchenguid/no-mistakes):** its discipline is in the worker
  pipeline above. The tool itself suits a person pushing from their own machine.
- **[gh-axi](https://github.com/kunchenguid/gh-axi):** a token-efficient wrapper over the `gh` CLI
  for agents. It needs `gh` logged in with a GitHub token. Cloud sessions have no `gh`, and a token
  in the environment would be readable by every session's processes and would bypass the session's
  repo scope. So keep the GitHub MCP tools in the cloud. It's a good fit for local harnesses
  (Claude Code on a laptop, Cursor, firstmate) where `gh` is already authenticated.

## Kickoff prompt for a new project

Open a Claude Code cloud session on the new repo, in its own environment, and paste:

> Set up the Claude-only cloud software factory for `<owner>/<repo>`, following
> `apipoj/software-factory` `playbooks/claude-code-cloud.md` phases 1 to 3. Use environment
> `<environment name>`. Model policy: `<kit default | all development on Opus>`. Worker cap:
> `<n>`. Review: `<cross-model only | cross-model plus a second review on risky PRs (Fable)>`. Floor rules:
> `<the few things v1 must never break>`. Relayed GO in chat: `<yes | no>`. Monitor page:
> `<yes | no>`. Work through PRs, merge your own green docs and CI PRs, and ask me only for what
> is human-only. Finish with a first pass on the open `factory-cloud` issues and tell me what
> needs my GO.
