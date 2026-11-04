#!/usr/bin/env bash

# Port-forward común para servicios
# Uso: ./port-forward.sh <service>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

require_homelab_context

case $1 in
    grafana)
        echo "🔗 Forwarding Grafana to http://localhost:3000"
        echo "   User: admin, Password: admin"
        kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
        ;;
    prometheus)
        echo "🔗 Forwarding Prometheus to http://localhost:9090"
        kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring
        ;;
    argocd)
        echo "🔗 Forwarding ArgoCD to https://localhost:8080"
        echo "   User: admin"
        echo "   Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
        kubectl port-forward svc/argocd-server -n argocd 8080:443
        ;;
    alertmanager)
        echo "🔗 Forwarding Alertmanager to http://localhost:9093"
        kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring
        ;;
    kiali)
        echo "🔗 Forwarding Kiali to http://localhost:20001"
        kubectl port-forward svc/kiali 20001:20001 -n istio-system
        ;;
    *)
        echo "Usage: ./port-forward.sh <service>"
        echo ""
        echo "Available services:"
        echo "  grafana      - Grafana dashboard (port 3000)"
        echo "  prometheus   - Prometheus UI (port 9090)"
        echo "  argocd       - ArgoCD UI (port 8080)"
        echo "  alertmanager - Alertmanager (port 9093)"
        echo "  kiali        - Kiali dashboard (port 20001)"
        ;;
esac
