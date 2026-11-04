#!/usr/bin/env bash

# Carga el kubeconfig aislado del laboratorio en la shell actual.
# Uso: source scripts/activate.sh

if [ -n "${ZSH_VERSION:-}" ]; then
    case "${ZSH_EVAL_CONTEXT:-}" in
        *:file*)
            HOMELAB_ACTIVATE_SOURCE="${(%):-%N}"
            ;;
        *)
            echo "Este script debe cargarse con: source scripts/activate.sh" >&2
            return 1 2>/dev/null || exit 1
            ;;
    esac
else
    HOMELAB_ACTIVATE_SOURCE="${BASH_SOURCE[0]}"
    if [ "$HOMELAB_ACTIVATE_SOURCE" = "$0" ]; then
        echo "Este script debe cargarse con: source scripts/activate.sh" >&2
        exit 1
    fi
fi

HOMELAB_SCRIPT_DIR="$(cd "$(dirname "$HOMELAB_ACTIVATE_SOURCE")" && pwd)"
source "${HOMELAB_SCRIPT_DIR}/lib.sh"

require_homelab_context

export KUBECONFIG="${HOMELAB_KUBECONFIG}"

echo "KUBECONFIG=${KUBECONFIG}"
echo "Contexto: $(kubectl config current-context)"
echo "Namespace por defecto: $(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}')"
