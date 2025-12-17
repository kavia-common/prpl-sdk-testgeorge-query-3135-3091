#!/usr/bin/env bash
set -euo pipefail
. /etc/profile.d/prplos_env.sh || true
WS="${PRPLOS_WORKSPACE:-/home/kavia/workspace/code-generation/prpl-sdk-testgeorge-query-3135-3091/prplos}"
mkdir -p "$WS" && cd "$WS"
# helper to write files atomically only when missing
_atomic_write_if_missing(){ local dest="$1"; shift; local tmp; tmp="${dest}.$$.$RANDOM.tmp"; if [ -f "$dest" ]; then return 0; fi; mkdir -p "$(dirname "$dest")"; cat > "$tmp" || (rm -f "$tmp" && return 1); mv -f "$tmp" "$dest"; }
# package.json
if [ ! -f package.json ]; then _atomic_write_if_missing package.json <<'JSON'
{
  "name": "prplos-dev-sample",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "start": "http-server -p 8080 ./public",
    "build": "mkdir -p dist && cp -r public/* dist/",
    "test": "jest"
  },
  "devDependencies": {
    "http-server": "^14.1.1",
    "jest": "^29.0.0"
  }
}
JSON
fi
# public/index.html
mkdir -p public
if [ ! -f public/index.html ]; then _atomic_write_if_missing public/index.html <<'HTML'
<!doctype html><meta charset="utf-8"><title>prplos dev</title><h1>prplos dev workspace</h1>
HTML
fi
# Makefile
if [ ! -f Makefile ]; then _atomic_write_if_missing Makefile <<'MF'
.PHONY: build start test
build:
	npm run build
start:
	npm run start
test:
	npm test
MF
fi
# tasks.py (Invoke)
if [ ! -f tasks.py ]; then _atomic_write_if_missing tasks.py <<'PY'
from invoke import task
@task
def test(c):
    c.run('pytest -q')
PY
fi
# minimal validation: ensure files exist
for f in package.json public/index.html Makefile tasks.py; do
  if [ ! -f "$f" ]; then echo "error: $f not created" >&2; exit 2; fi
done
exit 0
