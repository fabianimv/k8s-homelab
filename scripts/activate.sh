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

if [ -z "${HOMELAB_ACTIVE:-}" ]; then
    HOMELAB_OLD_KUBECONFIG="${KUBECONFIG:-}"
    HOMELAB_OLD_PS1="${PS1:-}"
fi

export KUBECONFIG="${HOMELAB_KUBECONFIG}"

echo "KUBECONFIG=${KUBECONFIG}"
echo "Contexto: $(kubectl config current-context)"
echo "Namespace por defecto: $(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}')"

if [ -z "${HOMELAB_ACTIVE:-}" ]; then
    if [ -n "${HOMELAB_OLD_PS1}" ]; then
        PS1="[homelab] ${HOMELAB_OLD_PS1}"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        PS1='[homelab] %~ %# '
    else
        PS1='[homelab] \w \$ '
    fi
    export HOMELAB_ACTIVE=1
fi

homelab_assert_context() {
    if [ "${KUBECONFIG:-}" != "${HOMELAB_KUBECONFIG}" ]; then
        homelab_err "Bloqueado: KUBECONFIG no apunta al kubeconfig del laboratorio."
        homelab_err "Activa el entorno con: source scripts/activate.sh"
        return 1
    fi
    local contexts current
    contexts="$(command kubectl config get-contexts -o name 2>/dev/null || true)"
    if [ "${contexts}" != "${HOMELAB_CONTEXT}" ]; then
        homelab_err "Bloqueado: el kubeconfig local debe contener solo '${HOMELAB_CONTEXT}'."
        return 1
    fi
    current="$(command kubectl config current-context 2>/dev/null || true)"
    if [ "${current}" != "${HOMELAB_CONTEXT}" ]; then
        homelab_err "Bloqueado: contexto actual '${current:-ninguno}' distinto de '${HOMELAB_CONTEXT}'."
        return 1
    fi
}

homelab_reject_flags() {
    local flag
    for flag in "$@"; do
        case "${flag}" in
            --kubeconfig|--kubeconfig=*|--context|--context=*|--server|--server=*|--cluster|--cluster=*|--user|--user=*|--kube-context|--kube-context=*|--kube-apiserver|--kube-apiserver=*|--kube-token|--kube-token=*|--kube-ca-file|--kube-ca-file=*)
                homelab_err "Bloqueado: no uses '${flag}' dentro de la shell homelab."
                return 1
                ;;
        esac
    done
}

kubectl() {
    homelab_reject_flags "$@" || return 1
    homelab_assert_context || return 1
    command kubectl "$@"
}

helm() {
    homelab_reject_flags "$@" || return 1
    homelab_assert_context || return 1
    command helm "$@"
}

deactivate_homelab() {
    unset -f kubectl helm homelab_assert_context homelab_reject_flags
    if [ -n "${HOMELAB_OLD_KUBECONFIG:-}" ]; then
        export KUBECONFIG="${HOMELAB_OLD_KUBECONFIG}"
    else
        unset KUBECONFIG
    fi
    if [ -n "${HOMELAB_OLD_PS1:-}" ]; then
        PS1="${HOMELAB_OLD_PS1}"
    elif [ -n "${ZSH_VERSION:-}" ]; then
        PS1='%~ %# '
    else
        PS1='\w \$ '
    fi
    unset HOMELAB_OLD_KUBECONFIG HOMELAB_OLD_PS1 HOMELAB_ACTIVE
    echo "Entorno homelab desactivado."
}

echo "Modo homelab activo. Prompt [homelab]. Usa 'deactivate_homelab' para salir."
