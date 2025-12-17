#!/usr/bin/env bash
set -euo pipefail
. /etc/profile.d/prplos_env.sh || true
WS="${PRPLOS_WORKSPACE:-/home/kavia/workspace/code-generation/prpl-sdk-testgeorge-query-3135-3091/prplos}"
cd "$WS"
ver_ge(){ [ "$(printf '%s\n%s' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }
# Prefer system packages; upgrade into user site only when needed
REQ_PYTEST="7"
INST_PYTEST=$(python3 -m pip show pytest 2>/dev/null | awk '/Version:/{print $2}' || echo "0")
if ! ver_ge "$INST_PYTEST" "$REQ_PYTEST"; then python3 -m pip install --user --upgrade "pytest>=$REQ_PYTEST"; fi
REQ_INVOKE="1.7"
INST_INVOKE=$(python3 -m pip show invoke 2>/dev/null | awk '/Version:/{print $2}' || echo "0")
if ! ver_ge "$INST_INVOKE" "$REQ_INVOKE"; then python3 -m pip install --user --upgrade "invoke>=$REQ_INVOKE"; fi
# mkdocs only if missing
if ! python3 -m pip show mkdocs >/dev/null 2>&1; then python3 -m pip install --user mkdocs; fi
# Node deps: deterministic install
if [ -f package.json ]; then
  set +e
  if [ -f package-lock.json ]; then
    npm ci --no-audit --no-fund 2> .npm_error.log || {
      tail -n +1 .npm_error.log | sed -n '1,40p' >&2
      echo "npm ci failed (truncated output above)" >&2
      rm -f .npm_error.log
      npm ci --no-audit --no-fund || true
    }
  else
    npm i --no-audit --no-fund 2> .npm_error.log || {
      tail -n +1 .npm_error.log | sed -n '1,40p' >&2
      echo "npm i failed (truncated output above)" >&2
      rm -f .npm_error.log
      npm i --no-audit --no-fund || true
    }
  fi
  set -e
fi
# Print concise versions for observability
python3 --version || true
python3 -m pip --version || true
python3 -m pytest --version 2>/dev/null || true
node -v 2>/dev/null || true
npm -v 2>/dev/null || true
