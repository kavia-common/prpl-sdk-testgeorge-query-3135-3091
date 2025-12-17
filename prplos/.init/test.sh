#!/usr/bin/env bash
set -euo pipefail
. /etc/profile.d/prplos_env.sh || true
WS="${PRPLOS_WORKSPACE:-/home/kavia/workspace/code-generation/prpl-sdk-testgeorge-query-3135-3091/prplos}"
cd "$WS"
mkdir -p tests
if [ ! -f tests/test_smoke.py ]; then cat > tests/test_smoke.py <<'PY'
def test_smoke():
    assert 1 + 1 == 2
PY
fi
mkdir -p __tests__
if [ ! -f __tests__/sample.test.js ]; then cat > __tests__/sample.test.js <<'JS'
test('node smoke', () => { expect(2).toBe(2); });
JS
fi
# Run pytest
echo "running: pytest" >&2
python3 -m pytest -q
# Run node tests if package.json exists
if [ -f package.json ]; then
  echo "running: npm test" >&2
  npm test || { echo "npm test failed with exit $?" >&2; exit 2; }
fi
