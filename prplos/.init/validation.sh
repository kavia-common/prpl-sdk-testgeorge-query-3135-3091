#!/usr/bin/env bash
set -euo pipefail
. /etc/profile.d/prplos_env.sh || true
WS="${PRPLOS_WORKSPACE:-/home/kavia/workspace/code-generation/prpl-sdk-testgeorge-query-3135-3091/prplos}"
cd "$WS"
PRPLOS_VALIDATION_TIMEOUT=${PRPLOS_VALIDATION_TIMEOUT:-30}
mkdir -p "$WS/.logs" "$WS/.init"
LOG="$WS/.logs/prplos_http_server.log"
META="$WS/.init/.server.meta"
# Build
npm run build --silent || { echo "build failed" >&2; tail -n 200 "$LOG" 2>/dev/null || true; exit 3; }
# Start server in new process group
setsid sh -c 'npm run start --silent' >"$LOG" 2>&1 &
SERVER_PID=$!
PGID=$(ps -o pgid= "$SERVER_PID" | tr -d ' ' || true)
[ -n "$PGID" ] || PGID=$SERVER_PID
printf "%s\n%s\n" "$SERVER_PID" "$PGID" >"$META"
trap 'kill -TERM -"$PGID" >/dev/null 2>&1 || true; wait "$SERVER_PID" 2>/dev/null || true; rm -f "$META" || true' EXIT INT TERM
# readiness probe
URL='http://127.0.0.1:8080/'
START_TS=$(date +%s)
END_TS=$((START_TS + PRPLOS_VALIDATION_TIMEOUT))
while [ "$(date +%s)" -lt "$END_TS" ]; do
  if curl -sS --fail --max-time 3 "$URL" >/dev/null 2>&1; then
    echo "validation: server responded"
    kill -TERM -"$PGID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" 2>/dev/null || true
    trap - EXIT
    rm -f "$META" || true
    exit 0
  fi
  # fail early if server exited
  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    echo "server process exited prematurely" >&2
    if [ -f "$LOG" ]; then echo "--- $LOG (tail) ---" >&2; tail -n 200 "$LOG" >&2 || true; fi
    exit 4
  fi
  sleep 1
done
# timed out: diagnostics
echo "validation: server did not respond within ${PRPLOS_VALIDATION_TIMEOUT}s" >&2
if [ -f "$LOG" ]; then echo "--- $LOG (tail) ---" >&2; tail -n 200 "$LOG" >&2 || true; fi
kill -TERM -"$PGID" >/dev/null 2>&1 || true
wait "$SERVER_PID" 2>/dev/null || true
rm -f "$META" || true
exit 5
