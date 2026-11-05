#!/usr/bin/env bash

# Abre una shell aislada con el kubeconfig del laboratorio.
# Uso: make shell

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_homelab_context
export KUBECONFIG="${HOMELAB_KUBECONFIG}"

detect_shell() {
    if [ -n "${HOMELAB_SHELL:-}" ]; then
        printf '%s\n' "${HOMELAB_SHELL}"
        return
    fi

    if [ "$(uname -s)" = "Darwin" ] && command -v dscl >/dev/null 2>&1; then
        local shell_path
        shell_path="$(dscl . -read "/Users/${USER}" UserShell 2>/dev/null | awk '{print $2}' | head -1)"
        if [ -n "${shell_path}" ]; then
            printf '%s\n' "${shell_path}"
            return
        fi
    fi

    if command -v getent >/dev/null 2>&1; then
        local shell_path
        shell_path="$(getent passwd "${USER}" | cut -d: -f7)"
        if [ -n "${shell_path}" ]; then
            printf '%s\n' "${shell_path}"
            return
        fi
    fi

    printf '%s\n' "${SHELL:-/bin/bash}"
}

SHELL_BIN="$(detect_shell)"

case "${SHELL_BIN}" in
    *zsh)
        tmpdir="$(mktemp -d)"
        cat > "${tmpdir}/.zshrc" <<EOF
ZDOTDIR="\${HOMELAB_ORIG_ZDOTDIR:-${HOME}}"
[[ -f "\${ZDOTDIR}/.zshrc" ]] && source "\${ZDOTDIR}/.zshrc"
source "${SCRIPT_DIR}/activate.sh"
EOF
        HOMELAB_ORIG_ZDOTDIR="${ZDOTDIR:-${HOME}}" ZDOTDIR="${tmpdir}" "${SHELL_BIN}" -i
        status=$?
        rm -rf "${tmpdir}"
        exit "${status}"
        ;;
    *bash)
        rcfile="$(mktemp)"
        cat > "${rcfile}" <<EOF
[[ -f "${HOME}/.bashrc" ]] && source "${HOME}/.bashrc"
source "${SCRIPT_DIR}/activate.sh"
EOF
        "${SHELL_BIN}" --rcfile "${rcfile}" -i
        status=$?
        rm -f "${rcfile}"
        exit "${status}"
        ;;
    *)
        echo "Shell no soportada: ${SHELL_BIN}. Usa bash o zsh." >&2
        exit 1
        ;;
esac
