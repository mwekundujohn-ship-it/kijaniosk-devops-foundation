# Week 8 Friday - KijaniKiosk Container Delivery Pipeline

Build, publish, deploy, expose and heal the `kk-payments` service.

## Contents

| File | Purpose |
| --- | --- |
| `src/` | TypeScript service: `GET /health`, `POST /total` |
| `Dockerfile.production` | Two-stage build, non-root `kijani` (uid 10001), `HEALTHCHECK` |
| `Dockerfile.baseline` | Monday single-stage comparison image |
| `.dockerignore` | Keeps source-only context (no `node_modules`, `dist`, evidence) |
| `kk-payments-deployment.yaml` | 2 replicas, resources, `imagePullSecrets`, versioned image |
| `kk-payments-service.yaml` | NodePort 30001 -> container port 3001 |
| `build-verification.txt` | Clean build log, size, user, compiler and health checks |
| `registry-push.txt` | Push, delete-local, fresh-pull round trip with digest |
| `deploy-output.txt` | Rollout to 2/2 with pull-secret wiring |
| `service-output.txt` | NodePort and in-cluster DNS responses |
| `self-healing-rerun.txt` | Replica deletion and automatic recovery timing |
| `credential-audit.txt` | Secret scan result |

## Build and tag

```sh
VERSION="$(node -p "require('./package.json').version")"
GITSHA="$(git rev-parse --short=7 HEAD)"
TAG="$VERSION-$GITSHA"

docker build --no-cache \
  --build-arg APP_VERSION="$TAG" \
  -f Dockerfile.production \
  -t "localhost:5000/kk-payments:$TAG" .
```

The runtime image is 80.1 MB (target: under 100 MB), runs as `kijani`, and has
no TypeScript compiler on `PATH`. The Monday baseline is 168.4 MB, so the
two-stage build removes 52.4% of the image.

## Registry

A local `registry:2` container serves `localhost:5000`. The cluster reaches it
as `host.minikube.internal:5000`, which was added to the node's insecure
registry configuration.

```sh
docker push "localhost:5000/kk-payments:$TAG"
docker rmi "localhost:5000/kk-payments:$TAG"
docker pull "localhost:5000/kk-payments:$TAG"
```

The lab registry accepts anonymous pulls. The Deployment still references
`imagePullSecrets: kijani-registry-credentials` so the manifest has the same
shape as a credentialed production registry. Create that secret with your own
values and never commit them:

```sh
kubectl create secret docker-registry kijani-registry-credentials \
  --docker-server=host.minikube.internal:5000 \
  --docker-username="$REGISTRY_USER" \
  --docker-password="$REGISTRY_PASSWORD"
```

## Deploy and verify

```sh
kubectl apply -f kk-payments-deployment.yaml
kubectl rollout status deployment/kk-payments
kubectl apply -f kk-payments-service.yaml

kubectl get pods -l app=kk-payments
kubectl get endpoints kk-payments-service
curl "http://$(minikube ip):30001/health"
```

In-cluster callers use `kk-payments-service.default.svc.cluster.local:3001`
(or the short name `kk-payments-service:3001`).

## Teardown

```sh
kubectl delete -f kk-payments-service.yaml
kubectl delete -f kk-payments-deployment.yaml
minikube stop
docker rm -f kijani-registry
```
