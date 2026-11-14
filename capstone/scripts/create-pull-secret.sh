#!/usr/bin/env bash
set -euo pipefail

NAMESPACES="${*:-${NAMESPACES:-kijani-staging kijani-production}}"
REGISTRY="${REGISTRY:-host.minikube.internal:5000}"
REGISTRY_USER="${REGISTRY_USER:-lab}"
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-lab}"
REGISTRY_EMAIL="${REGISTRY_EMAIL:-lab@example.invalid}"

for ns in $NAMESPACES; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n "$ns" create secret docker-registry kijani-registry-credentials \
    --docker-server="$REGISTRY" \
    --docker-username="$REGISTRY_USER" \
    --docker-password="$REGISTRY_PASSWORD" \
    --docker-email="$REGISTRY_EMAIL" \
    --dry-run=client -o yaml | kubectl apply -f -
done
