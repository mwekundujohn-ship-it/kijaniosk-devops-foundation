#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:-kijani-staging}"
EXPECTED_VERSION="${2:-}"
SERVICE="${SERVICE:-kk-payments-service}"
LOCAL_PORT="${LOCAL_PORT:-18001}"
PF_LOG="$(mktemp)"
PF_PID=""

cleanup() {
  if [[ -n "$PF_PID" ]]; then
    kill "$PF_PID" >/dev/null 2>&1 || true
  fi
  rm -f "$PF_LOG"
}
trap cleanup EXIT

kubectl -n "$NAMESPACE" get service "$SERVICE" >/dev/null
kubectl -n "$NAMESPACE" port-forward "service/$SERVICE" "${LOCAL_PORT}:3001" >"$PF_LOG" 2>&1 &
PF_PID=$!

READY=0
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${LOCAL_PORT}/health" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 1
done

if [[ "$READY" -ne 1 ]]; then
  cat "$PF_LOG"
  echo "FAIL: port-forward did not become ready for ${NAMESPACE}/${SERVICE}" >&2
  exit 1
fi

HEALTH=""
for _ in $(seq 1 30); do
  if HEALTH="$(curl -fsS "http://127.0.0.1:${LOCAL_PORT}/health" 2>/dev/null)"; then
    if [[ -z "$EXPECTED_VERSION" ]]; then
      break
    fi
    if python3 -c 'import json,sys; sys.exit(0 if json.loads(sys.argv[1]).get("version") == sys.argv[2] else 1)' "$HEALTH" "$EXPECTED_VERSION" 2>/dev/null; then
      break
    fi
  fi
  sleep 1
done

if [[ -z "$HEALTH" ]]; then
  echo "FAIL: /health did not return a response" >&2
  exit 1
fi

python3 - "$HEALTH" "$EXPECTED_VERSION" <<'PY'
import json
import sys

health = json.loads(sys.argv[1])
expected = sys.argv[2]
assert health.get("status") == "ok", health
assert health.get("service") == "kk-payments", health
if expected:
    assert health.get("version") == expected, (health, expected)
print("PASS health:", json.dumps(health, sort_keys=True))
PY

TOTAL="$(curl -fsS -X POST -H 'content-type: application/json' \
  -d '[{"unitPrice":10,"quantity":2},{"unitPrice":5.5,"quantity":4}]' \
  "http://127.0.0.1:${LOCAL_PORT}/total")"
python3 - "$TOTAL" <<'PY'
import json
import sys

body = json.loads(sys.argv[1])
assert body.get("total") == 42, body
print("PASS total:", json.dumps(body, sort_keys=True))
PY

echo "PASS smoke test: ${NAMESPACE}/${SERVICE}"
