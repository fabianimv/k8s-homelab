#!/usr/bin/env bash

# Limpiar todos los recursos del homelab
# Uso: ./cleanup.sh [--all]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_homelab_context

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

echo "🧹 Kubernetes Homelab Cleanup"
echo "=============================="
echo ""

# Parse args
ALL=false
if [ "${1:-}" == "--all" ]; then
    ALL=true
fi

# Cleanup labs
echo -e "${YELLOW}Cleaning up lab resources...${NC}"

# Basic labs
kubectl delete -f 01-basic/ -R --ignore-not-found 2>/dev/null || true
echo -e "${GREEN}✓ Basic labs cleaned${NC}"

# Intermediate labs (03-helm se gestiona con helm uninstall)
kubectl delete -f 02-intermediate/01-ingress/ -R --ignore-not-found 2>/dev/null || true
kubectl delete -f 02-intermediate/02-persistent-storage/ -R --ignore-not-found 2>/dev/null || true
kubectl delete -f 02-intermediate/04-statefulsets/ -R --ignore-not-found 2>/dev/null || true
kubectl delete -f 02-intermediate/05-jobs-cronjobs/ -R --ignore-not-found 2>/dev/null || true
echo -e "${GREEN}✓ Intermediate labs cleaned${NC}"

# Advanced labs
kubectl delete -f 03-advanced/01-monitoring/alertmanager-config.yaml --ignore-not-found 2>/dev/null || true
kubectl delete -f 03-advanced/02-argocd/ -R --ignore-not-found 2>/dev/null || true
kubectl delete -f 03-advanced/03-security/ -R --ignore-not-found 2>/dev/null || true
kubectl delete -f 03-advanced/04-service-mesh/ -R --ignore-not-found 2>/dev/null || true
echo -e "${GREEN}✓ Advanced labs cleaned${NC}"

# Apps
kubectl delete -f apps/ -R --ignore-not-found 2>/dev/null || true
echo -e "${GREEN}✓ Apps cleaned${NC}"

# Delete namespaces
echo ""
echo -e "${YELLOW}Cleaning up namespaces...${NC}"
kubectl delete ns "${HOMELAB_NAMESPACE}" lab-demo lab-dev lab-prod --ignore-not-found 2>/dev/null || true

if [ "$ALL" == true ]; then
    echo ""
    echo -e "${RED}Cleaning up advanced components...${NC}"

    # Monitoring
    helm uninstall monitoring -n monitoring 2>/dev/null || true
    kubectl delete ns monitoring --ignore-not-found 2>/dev/null || true

    # ArgoCD
    kubectl delete ns argocd --ignore-not-found 2>/dev/null || true

    # Ingress
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/cloud/deploy.yaml --ignore-not-found 2>/dev/null || true

    echo -e "${GREEN}✓ Advanced components cleaned${NC}"
fi

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
