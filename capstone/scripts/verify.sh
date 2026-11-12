#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ANSIBLE_BIN="${ANSIBLE_BIN:-$HOME/.local/share/pipx/venvs/ansible/bin/ansible-playbook}"

terraform -chdir="$ROOT/capstone/terraform" init -backend=false -input=false >/dev/null
terraform -chdir="$ROOT/capstone/terraform" fmt -check
terraform -chdir="$ROOT/capstone/terraform" validate

kubectl kustomize "$ROOT/capstone/k8s/overlays/staging" >/tmp/capstone-staging.yaml
kubectl kustomize "$ROOT/capstone/k8s/overlays/production" >/tmp/capstone-production.yaml

python3 - <<'PY'
import yaml

for path in ["/tmp/capstone-staging.yaml", "/tmp/capstone-production.yaml", "capstone/monitoring/kk-payments-alerts.yaml"]:
    with open(path, encoding="utf-8") as handle:
        docs = list(yaml.safe_load_all(handle))
    assert docs and all(isinstance(doc, dict) for doc in docs), path
    print("PASS yaml:", path, len(docs), "documents")
PY

for script in "$ROOT"/capstone/scripts/*.sh; do
  bash -n "$script"
  echo "PASS bash: ${script#$ROOT/}"
done

"$ANSIBLE_BIN" -i "$ROOT/capstone/ansible/inventory.ini" --syntax-check "$ROOT/capstone/ansible/staging.yml"
"$ANSIBLE_BIN" -i "$ROOT/capstone/ansible/inventory.ini" --syntax-check "$ROOT/capstone/ansible/production.yml"
