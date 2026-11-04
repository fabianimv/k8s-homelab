#!/usr/bin/env bash

# Utilidades compartidas para aislar el laboratorio del kubeconfig global.
# Uso: source scripts/lib.sh

if [ -n "${BASH_SOURCE:-}" ]; then
    HOMELAB_LIB_SOURCE="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
    HOMELAB_LIB_SOURCE="${(%):-%N}"
else
    HOMELAB_LIB_SOURCE="$0"
fi

HOMELAB_ROOT="$(cd "$(dirname "${HOMELAB_LIB_SOURCE}")/.." && pwd)"
HOMELAB_KUBECONFIG="${HOMELAB_ROOT}/.kube/config"
HOMELAB_CONTEXT="${HOMELAB_CONTEXT:-docker-desktop}"
HOMELAB_NAMESPACE="${HOMELAB_NAMESPACE:-homelab}"
HOMELAB_GLOBAL_KUBECONFIG="${HOME}/.kube/config"

export HOMELAB_ROOT
export HOMELAB_KUBECONFIG
export HOMELAB_CONTEXT
export HOMELAB_NAMESPACE
export HELM_REPOSITORY_CONFIG="${HOMELAB_ROOT}/.helm/repositories.yaml"
export HELM_REPOSITORY_CACHE="${HOMELAB_ROOT}/.helm/cache"

homelab_err() {
    printf 'ERROR: %s\n' "$*" >&2
}

ensure_homelab_kubeconfig() {
    mkdir -p "$(dirname "${HOMELAB_KUBECONFIG}")"

    if [[ ! -f "${HOMELAB_KUBECONFIG}" ]]; then
        if [[ ! -f "${HOMELAB_GLOBAL_KUBECONFIG}" ]]; then
            homelab_err "No existe ${HOMELAB_GLOBAL_KUBECONFIG}."
            return 1
        fi

        if ! kubectl --kubeconfig "${HOMELAB_GLOBAL_KUBECONFIG}" config get-contexts "${HOMELAB_CONTEXT}" >/dev/null 2>&1; then
            homelab_err "No existe el contexto '${HOMELAB_CONTEXT}' en ${HOMELAB_GLOBAL_KUBECONFIG}."
            homelab_err "Habilita Kubernetes en Docker Desktop y vuelve a ejecutar 'make kubeconfig'."
            return 1
        fi

        kubectl --kubeconfig "${HOMELAB_GLOBAL_KUBECONFIG}" config view \
            --raw --flatten --minify --context "${HOMELAB_CONTEXT}" \
            > "${HOMELAB_KUBECONFIG}"
        chmod 600 "${HOMELAB_KUBECONFIG}"
    fi

    kubectl --kubeconfig "${HOMELAB_KUBECONFIG}" config set-context "${HOMELAB_CONTEXT}" \
        --namespace="${HOMELAB_NAMESPACE}" >/dev/null

    export KUBECONFIG="${HOMELAB_KUBECONFIG}"
}

require_homelab_context() {
    ensure_homelab_kubeconfig || return 1

    local contexts current_context server namespace
    contexts="$(kubectl config get-contexts -o name 2>/dev/null || true)"

    if [[ "${contexts}" != "${HOMELAB_CONTEXT}" ]]; then
        homelab_err "El kubeconfig local debe contener solo el contexto '${HOMELAB_CONTEXT}'."
        homelab_err "Contextos encontrados: ${contexts:-ninguno}"
        homelab_err "Regenera el archivo con: rm -f .kube/config && make kubeconfig"
        return 1
    fi

    current_context="$(kubectl config current-context 2>/dev/null || true)"
    if [[ "${current_context}" != "${HOMELAB_CONTEXT}" ]]; then
        homelab_err "Contexto actual '${current_context:-ninguno}' distinto de '${HOMELAB_CONTEXT}'."
        return 1
    fi

    server="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null || true)"
    case "${server}" in
        https://kubernetes.docker.internal:*|https://host.docker.internal:*|https://127.0.0.1:*|https://localhost:*|https://0.0.0.0:*)
            ;;
        *)
            homelab_err "El servidor '${server:-desconocido}' no parece un cluster local de Docker Desktop."
            homelab_err "Abortando para no tocar contextos ajenos al laboratorio."
            return 1
            ;;
    esac

    namespace="$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}' 2>/dev/null || true)"
    if [[ "${namespace}" != "${HOMELAB_NAMESPACE}" ]]; then
        homelab_err "El namespace por defecto del contexto es '${namespace:-ninguno}', se esperaba '${HOMELAB_NAMESPACE}'."
        return 1
    fi
}
