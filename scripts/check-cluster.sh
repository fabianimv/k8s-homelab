#!/usr/bin/env bash

# Verificar estado del cluster aislado de Kubernetes
# Uso: ./check-cluster.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_homelab_context

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "🔍 Kubernetes Cluster Health Check"
echo "===================================="
echo ""

echo -e "${YELLOW}0. Contexto${NC}"
echo "  $(kubectl config current-context) -> $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
echo ""

# Check cluster
echo -e "${YELLOW}1. Cluster Info${NC}"
if ! kubectl cluster-info; then
    echo -e "${RED}✗ Cannot connect to cluster${NC}"
    exit 1
fi
echo ""

# Check nodes
echo -e "${YELLOW}2. Nodes${NC}"
kubectl get nodes
echo ""

# Check system pods
echo -e "${YELLOW}3. System Pods${NC}"
if ! SYSTEM_PODS=$(kubectl get pods -n kube-system \
    --field-selector=status.phase!=Running,status.phase!=Succeeded \
    --no-headers 2>/dev/null); then
    echo -e "${RED}✗ Cannot list kube-system pods${NC}"
elif [ -n "${SYSTEM_PODS}" ]; then
    echo "${SYSTEM_PODS}"
    echo -e "${RED}⚠ Some system pods are not running${NC}"
else
    echo -e "${GREEN}✓ All system pods are running${NC}"
fi
echo ""

# Resource usage
echo -e "${YELLOW}4. Resource Usage${NC}"
kubectl top nodes 2>/dev/null || echo "Metrics server not installed"
echo ""

# Storage
echo -e "${YELLOW}5. Storage${NC}"
kubectl get pv,pvc -A 2>/dev/null || echo "No persistent volumes"
echo ""

echo -e "${GREEN}✓ Health check complete${NC}"
