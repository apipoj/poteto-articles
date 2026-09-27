#!/usr/bin/env bash
set -Eeuo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

fail() {
  printf 'cloud-session-start: %s\n' "$1" >&2
  exit 1
}

trap 'status=$?; printf "cloud-session-start: command failed at line %s (exit %s)\n" "$LINENO" "$status" >&2' ERR

[ -n "${CLAUDE_ENV_FILE:-}" ] || fail "CLAUDE_ENV_FILE is not set"

project_dir=${CLAUDE_PROJECT_DIR:-.}
cd "$project_dir" || fail "could not enter project directory: $project_dir"

if ! pg_ctlcluster 16 main status >/dev/null 2>&1; then
  pg_ctlcluster 16 main start || fail "could not start PostgreSQL 16 main cluster"
fi

if ! role_exists=$(sudo -u postgres psql -v ON_ERROR_STOP=1 -qtAc "SELECT 1 FROM pg_roles WHERE rolname = 'verify'"); then
  fail "could not check for the verify database role"
fi
if [ "$role_exists" != "1" ]; then
  sudo -u postgres psql -v ON_ERROR_STOP=1 -qc "CREATE ROLE verify LOGIN SUPERUSER PASSWORD 'verify'" ||
    fail "could not create the verify database role"
fi

if ! login_result=$(PGPASSWORD=verify psql -h 127.0.0.1 -U verify -d postgres -v ON_ERROR_STOP=1 -qtAc 'SELECT 1'); then
  fail "could not connect to PostgreSQL as verify"
fi
[ "$login_result" = "1" ] || fail "PostgreSQL login as verify returned an unexpected result"

install_log=${TMPDIR:-/tmp}/deps-install.log
# Replace this command with the project's lockfile-verified dependency install.
if ! corepack pnpm install --frozen-lockfile >"$install_log" 2>&1; then
  printf 'cloud-session-start: pnpm install failed; last lines of %s follow\n' "$install_log" >&2
  tail -n 40 "$install_log" >&2 || true
  fail "dependency installation failed"
fi

printf '%s\n' 'export VERIFY_NATIVE_PG=postgresql://verify:verify@127.0.0.1:5432/postgres' >> "$CLAUDE_ENV_FILE" ||
  fail "could not export VERIFY_NATIVE_PG to CLAUDE_ENV_FILE"
if [ -x /opt/pw-browsers/chromium ]; then
  printf '%s\n' 'export VERIFY_CHROMIUM=/opt/pw-browsers/chromium' >> "$CLAUDE_ENV_FILE" ||
    fail "could not export VERIFY_CHROMIUM to CLAUDE_ENV_FILE"
fi

printf '%s\n' 'cloud-session-start: database login and dependency install verified' >&2
