#!/usr/bin/env bash
set -euo pipefail
. /etc/profile.d/prplos_env.sh || true
WS="${PRPLOS_WORKSPACE:-/home/kavia/workspace/code-generation/prpl-sdk-testgeorge-query-3135-3091/prplos}"
cd "$WS"
mkdir -p "$WS/.logs"
LOG="$WS/.logs/prplos_http_server.log"
META="$WS/.init/.server.meta"
mkdir -p "$(dirname "$META")"
# start server in new process group and capture pid/pgid
setsid sh -c 'npm run start --silent' >"$LOG" 2>&1 &
SERVER_PID=$!
# derive PGID, fallback to PID
PGID=$(ps -o pgid= "$SERVER_PID" | tr -d ' ' || true)
[ -n "$PGID" ] || PGID=$SERVER_PID
# persist metadata for stop/validation
printf "%s\n%s\n" "$SERVER_PID" "$PGID" >"$META"
# print a concise status
echo "server started: PID=$SERVER_PID PGID=$PGID LOG=$LOG"
