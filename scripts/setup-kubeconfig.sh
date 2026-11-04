#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

if [[ "${1:-}" == "--force" ]]; then
    rm -f "${HOMELAB_KUBECONFIG}"
fi

require_homelab_context

echo "Kubeconfig local: ${HOMELAB_KUBECONFIG}"
echo "Contexto: $(kubectl config current-context)"
echo "Namespace por defecto: $(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}')"
echo "Servidor: $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
