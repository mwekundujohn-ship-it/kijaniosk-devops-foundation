#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$ROOT/week5/friday/app"
IMAGE_DIR="$ROOT/week8/friday"
REGISTRY="${REGISTRY:-localhost:5000}"
CLUSTER_REGISTRY="${CLUSTER_REGISTRY:-host.minikube.internal:5000}"
IMAGE="${IMAGE:-kk-payments}"
STAGING_NS="${STAGING_NS:-kijani-staging}"
PRODUCTION_NS="${PRODUCTION_NS:-kijani-production}"
BASE_VERSION="$(python3 -c "import json; print(json.load(open('$IMAGE_DIR/package.json'))['version'])")"
TAG="${TAG:-${BASE_VERSION}-$(git -C "$ROOT" rev-parse --short=7 HEAD)}"
APPROVE_PRODUCTION="${APPROVE_PRODUCTION:-no}"

step() {
  printf '\n=== %s ===\n' "$*"
}

step "Verify Week 5 application"
TMP_APP="$(mktemp -d)"
cp "$APP_DIR/package.json" "$APP_DIR/package-lock.json" "$TMP_APP/"
cp -a "$APP_DIR/src" "$APP_DIR/test" "$APP_DIR/scripts" "$TMP_APP/"
docker run --rm -v "$TMP_APP:/app" -w /app -e npm_config_cache=/tmp/npm-cache \
  node:18.20.4 sh -c 'npm ci --no-audit --no-fund && npm run lint && npm test'
rm -rf "$TMP_APP"

step "Build Week 8 production image"
docker build --no-cache --build-arg APP_VERSION="$TAG" \
  -f "$IMAGE_DIR/Dockerfile.production" -t "$REGISTRY/$IMAGE:$TAG" "$IMAGE_DIR"

step "Push image to $REGISTRY"
docker push "$REGISTRY/$IMAGE:$TAG"

step "Create registry pull secrets"
"$ROOT/capstone/scripts/create-pull-secret.sh" "$STAGING_NS" "$PRODUCTION_NS"

step "Deploy staging"
kubectl apply -k "$ROOT/capstone/k8s/overlays/staging"
kubectl -n "$STAGING_NS" set image deployment/kk-payments kk-payments="$CLUSTER_REGISTRY/$IMAGE:$TAG"
kubectl -n "$STAGING_NS" rollout status deployment/kk-payments --timeout=180s

step "Smoke test staging"
"$ROOT/capstone/scripts/smoke-test.sh" "$STAGING_NS" "$TAG"

step "Production approval gate"
if [[ "$APPROVE_PRODUCTION" != "yes" ]]; then
  echo "APPROVE_PRODUCTION is not 'yes'; stopping before production."
  echo "Re-run with APPROVE_PRODUCTION=yes to deploy production."
  exit 0
fi

step "Deploy production"
kubectl apply -k "$ROOT/capstone/k8s/overlays/production"
kubectl -n "$PRODUCTION_NS" set image deployment/kk-payments kk-payments="$CLUSTER_REGISTRY/$IMAGE:$TAG"
kubectl -n "$PRODUCTION_NS" rollout status deployment/kk-payments --timeout=180s

step "Smoke test production"
"$ROOT/capstone/scripts/smoke-test.sh" "$PRODUCTION_NS" "$TAG"

echo "PASS local pipeline: $TAG"
