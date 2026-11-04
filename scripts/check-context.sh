#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_homelab_context

echo "OK: contexto aislado '$(kubectl config current-context)'"
echo "Servidor: $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
echo "Namespace por defecto: $(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}')"
