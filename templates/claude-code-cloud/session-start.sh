#!/usr/bin/env bash
# Claude Code on the web: prepare the container for the project's verification skill.
# Copy to .claude/hooks/cloud-session-start.sh (chmod +x) and register it with settings.json.
# No-op on local machines. Delete the blocks your project does not need.
set -u
[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# Database: the container is already disposable, so use its built-in Postgres instead of Docker.
# Your verification skill should create one database per run on this URL and drop it on teardown.
pg_ctlcluster 16 main start 2>/dev/null
sudo -u postgres psql -qtAc "SELECT 1 FROM pg_roles WHERE rolname = 'verify'" | grep -q 1 ||
  sudo -u postgres psql -qc "CREATE ROLE verify LOGIN SUPERUSER PASSWORD 'verify'"

# Dependencies (edit for your package manager).
[ -d node_modules ] || corepack pnpm install --frozen-lockfile >/tmp/deps-install.log 2>&1

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  # Rename to whatever your verification skill reads.
  echo "export VERIFY_NATIVE_PG=postgresql://verify:verify@127.0.0.1:5432/postgres" >> "$CLAUDE_ENV_FILE"
  # Preinstalled Chromium; pass it as Playwright's executablePath if the pinned build is missing.
  [ -x /opt/pw-browsers/chromium ] && echo "export VERIFY_CHROMIUM=/opt/pw-browsers/chromium" >> "$CLAUDE_ENV_FILE"
fi
exit 0
