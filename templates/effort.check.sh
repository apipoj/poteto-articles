#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

need_file() {
  [ -f "$1" ] || fail "missing $1"
}

need_phrase() {
  local file=$1
  local phrase=$2
  grep -F -q -- "$phrase" "$file" || fail "$file missing phrase: $phrase"
}

need_absent() {
  local file=$1
  local phrase=$2
  if grep -F -q -- "$phrase" "$file"; then
    fail "$file still has phrase: $phrase"
  fi
}

need_file templates/effort.md
need_file templates/effort.check.sh
need_file templates/crew-dispatch.example.json
need_file templates/claude-code-cloud/crew-dispatch.json
need_file templates/claude-code-cloud/worker-brief.md
need_file templates/claude-code-cloud/orchestrator.md
need_file templates/brief-include.pstack.md
need_file factory/runbook.md
need_file adapters/claude.md
need_file adapters/claude-code-cloud.md
need_file templates/README.md

need_phrase templates/effort.md "does not switch models"
need_phrase templates/effort.md "Do not raise effort"
need_phrase templates/effort.md "https://claude.dev/blog/spending-your-effort/"
need_phrase templates/effort.md "https://x.com/trq212/status/2103576349499855160"
need_phrase templates/effort.md "human gate"
need_phrase templates/effort.md "does not open the human gate"
need_phrase templates/effort.md "/effort auto"
need_phrase templates/effort.md "session default"
need_phrase templates/effort.md "captain record"
need_phrase templates/effort.md "The diff stays on the issue"
need_phrase templates/effort.md "sketch at \`low\`"
need_phrase templates/effort.md "specified build at \`medium\`"
need_absent templates/effort.md "or at \`medium\` when that profile omits it"
need_absent templates/effort.md "start the new model again from its default"
need_absent templates/effort.md "more scope"

need_phrase factory/runbook.md "templates/effort.md"
need_phrase factory/runbook.md "templates/brief-include.pstack.md"
need_phrase factory/runbook.md "The diff stays on the issue"
need_phrase factory/runbook.md "captain record"
need_absent factory/runbook.md "pstack (Lauren Tan's rigor skills) is installed for Pi and Codex."

need_phrase adapters/claude.md "persist into the next session"
need_phrase adapters/claude.md "/effort auto"
need_phrase adapters/claude.md "CLAUDE_CODE_EFFORT_LEVEL"
need_phrase adapters/claude.md "session-only"

need_phrase adapters/claude-code-cloud.md "https://academy.claude.com/tutorials/choosing-the-right-effort-level-in-claude-code"
need_phrase adapters/claude-code-cloud.md "keep the session default"
need_absent adapters/claude-code-cloud.md "https://code.claude.com/docs/en/remote-control"

need_phrase templates/brief-include.pstack.md "The diff stays on the issue"
need_phrase adapters/claude.md "templates/effort.md"
need_phrase adapters/claude-code-cloud.md "templates/effort.md"
need_phrase adapters/claude-code-cloud.md "/effort"
need_phrase templates/brief-include.pstack.md "templates/effort.md"
need_phrase templates/README.md "effort.md"
need_phrase templates/claude-code-cloud/worker-brief.md "/effort"
need_phrase templates/claude-code-cloud/worker-brief.md "factory:stuck"
need_phrase templates/claude-code-cloud/worker-brief.md "Do not raise effort"
need_phrase templates/claude-code-cloud/orchestrator.md "Do not pass \`effort\`"

if grep -F -q 'No `effort` in dispatch' adapters/claude-code-cloud.md; then
  fail "adapters/claude-code-cloud.md still has the old no-effort sentence"
fi

python3 - << 'PY'
import json
from pathlib import Path

allowed = {"low", "medium", "high", "xhigh", "max"}

example = json.loads(Path("templates/crew-dispatch.example.json").read_text())
cloud = json.loads(Path("templates/claude-code-cloud/crew-dispatch.json").read_text())

def profiles(node):
    if isinstance(node, dict) and "model" in node:
        yield node
        return
    if isinstance(node, list):
        for item in node:
            yield from profiles(item)
        return
    if isinstance(node, dict):
        for value in node.values():
            yield from profiles(value)

example_profiles = list(profiles(example))
cloud_profiles = list(profiles(cloud))
if not example_profiles:
    raise SystemExit("FAIL: example dispatch has no profiles")
if not cloud_profiles:
    raise SystemExit("FAIL: cloud dispatch has no profiles")

saw_effort = False
for profile in example_profiles:
    if "model" not in profile:
        raise SystemExit(f"FAIL: example profile missing model: {profile}")
    effort = profile.get("effort")
    if effort is None:
        continue
    saw_effort = True
    if effort not in allowed:
        raise SystemExit(f"FAIL: example effort {effort!r} not in {sorted(allowed)}")

if not saw_effort:
    raise SystemExit("FAIL: example dispatch has no effort field")

for profile in cloud_profiles:
    if "model" not in profile:
        raise SystemExit(f"FAIL: cloud profile missing model: {profile}")
    if "effort" in profile:
        raise SystemExit(
            "FAIL: cloud crew-dispatch profile has effort, but create_session does not take it"
        )

print(f"profiles: example={len(example_profiles)} cloud={len(cloud_profiles)}")
PY

python3 - << 'PY'
import re
from pathlib import Path

roots = [
    Path("templates/effort.md"),
    Path("factory/runbook.md"),
    Path("adapters/claude.md"),
    Path("adapters/claude-code-cloud.md"),
    Path("templates/README.md"),
    Path("templates/brief-include.pstack.md"),
    Path("templates/claude-code-cloud/worker-brief.md"),
    Path("templates/claude-code-cloud/orchestrator.md"),
]
link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
missing = []
for path in roots:
    text = path.read_text()
    for match in link_re.finditer(text):
        target = match.group(1).split()[0]
        if target.startswith(("http://", "https://", "mailto:")):
            continue
        if target.startswith("#"):
            continue
        target = target.split("#", 1)[0]
        if not target:
            continue
        resolved = (path.parent / target).resolve()
        if not resolved.exists():
            missing.append(f"{path}: {target}")
if missing:
    raise SystemExit("FAIL: broken relative links\n" + "\n".join(missing))
print(f"relative links ok in {len(roots)} files")
PY

echo "effort.check: ok"
