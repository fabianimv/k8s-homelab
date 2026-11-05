SHELL := /bin/bash

ROOT_DIR := $(CURDIR)
LOCAL_KUBECONFIG := $(ROOT_DIR)/.kube/config
HOMELAB_CONTEXT ?= docker-desktop
HOMELAB_NAMESPACE ?= homelab

export KUBECONFIG := $(LOCAL_KUBECONFIG)
export HOMELAB_CONTEXT
export HOMELAB_NAMESPACE
export HELM_REPOSITORY_CONFIG := $(ROOT_DIR)/.helm/repositories.yaml
export HELM_REPOSITORY_CACHE := $(ROOT_DIR)/.helm/cache

.PHONY: help kubeconfig kubeconfig-force check-context namespace shell check clean reset basic pods deployments services apps intermediate ingress monitoring argocd status forward-grafana forward-argocd

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-18s$(NC) %s\n", $$1, $$2}'

kubeconfig: ## Create the isolated local kubeconfig
	@scripts/setup-kubeconfig.sh

kubeconfig-force: ## Recreate the isolated local kubeconfig
	@scripts/setup-kubeconfig.sh --force

check-context: ## Verify the isolated local context
	@scripts/check-context.sh

namespace: check-context ## Create the lab namespace
	@kubectl apply -f 00-namespace.yaml

shell: check-context ## Open an isolated shell with [homelab] prompt
	@scripts/shell.sh

check: check-context ## Check cluster status
	@scripts/check-cluster.sh

clean: check-context ## Remove all lab manifests
	@echo -e "$(YELLOW)Cleaning up all lab resources...$(NC)"
	kubectl delete -f 01-basic/ -R --ignore-not-found || true
	kubectl delete -f 02-intermediate/01-ingress/ -R --ignore-not-found || true
	kubectl delete -f 02-intermediate/02-persistent-storage/ -R --ignore-not-found || true
	kubectl delete -f 02-intermediate/04-statefulsets/ -R --ignore-not-found || true
	kubectl delete -f 02-intermediate/05-jobs-cronjobs/ -R --ignore-not-found || true
	kubectl delete -f 03-advanced/01-monitoring/alertmanager-config.yaml --ignore-not-found 2>/dev/null || true
	kubectl delete -f 03-advanced/02-argocd/ -R --ignore-not-found 2>/dev/null || true
	kubectl delete -f 03-advanced/03-security/ -R --ignore-not-found || true
	kubectl delete -f 03-advanced/04-service-mesh/ -R --ignore-not-found 2>/dev/null || true
	kubectl delete -f apps/ -R --ignore-not-found || true
	@echo -e "$(GREEN)✓ Cleanup complete$(NC)"

reset: clean ## Reset cluster (clean + delete namespaces and add-ons)
	@echo -e "$(YELLOW)Resetting cluster...$(NC)"
	helm uninstall monitoring -n monitoring 2>/dev/null || true
	kubectl delete ns $(HOMELAB_NAMESPACE) lab-demo lab-dev lab-prod monitoring argocd ingress-nginx --ignore-not-found || true
	@echo -e "$(GREEN)✓ Reset complete$(NC)"

# Basic Labs
basic: namespace ## Deploy all basic labs
	@echo -e "$(YELLOW)Deploying basic labs...$(NC)"
	kubectl apply -f 01-basic/ -R
	@echo -e "$(GREEN)✓ Basic labs deployed$(NC)"

pods: namespace ## Deploy pods lab
	kubectl apply -f 01-basic/01-pods/

deployments: namespace ## Deploy deployments lab
	kubectl apply -f 01-basic/02-deployments/

services: namespace ## Deploy services lab
	kubectl apply -f 01-basic/03-services/

apps: namespace ## Deploy sample apps
	kubectl apply -f apps/ -R

# Intermediate Labs
intermediate: namespace ## Deploy all intermediate labs (except Helm chart)
	@echo -e "$(YELLOW)Deploying intermediate labs...$(NC)"
	kubectl apply -f 02-intermediate/01-ingress/ -R
	kubectl apply -f 02-intermediate/02-persistent-storage/ -R
	kubectl apply -f 02-intermediate/04-statefulsets/ -R
	kubectl apply -f 02-intermediate/05-jobs-cronjobs/ -R
	@echo -e "$(YELLOW)Skipping 03-helm: install it with helm (see 02-intermediate/03-helm/README.md)$(NC)"
	@echo -e "$(GREEN)✓ Intermediate labs deployed$(NC)"

ingress: check-context ## Install NGINX Ingress Controller
	@echo -e "$(YELLOW)Installing NGINX Ingress Controller...$(NC)"
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.15.1/deploy/static/provider/cloud/deploy.yaml
	@echo -e "$(GREEN)✓ Ingress Controller installed$(NC)"

# Advanced Labs
monitoring: check-context ## Deploy Prometheus + Grafana
	@echo -e "$(YELLOW)Installing monitoring stack...$(NC)"
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
		--namespace monitoring --create-namespace \
		--set grafana.adminPassword=admin
	@echo -e "$(GREEN)✓ Monitoring stack installed$(NC)"
	@echo -e "$(YELLOW)Grafana: kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring$(NC)"

argocd: check-context ## Install ArgoCD
	@echo -e "$(YELLOW)Installing ArgoCD...$(NC)"
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@echo -e "$(GREEN)✓ ArgoCD installed$(NC)"
	@echo -e "$(YELLOW)Get password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d$(NC)"
	@echo -e "$(YELLOW)Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443$(NC)"

# Utilities
status: check-context ## Show status of all resources
	@echo -e "$(YELLOW)=== Pods ===$(NC)"
	@kubectl get pods -A --field-selector=status.phase!=Succeeded
	@echo ""
	@echo -e "$(YELLOW)=== Services ===$(NC)"
	@kubectl get svc -A
	@echo ""
	@echo -e "$(YELLOW)=== Deployments ===$(NC)"
	@kubectl get deployments -A

forward-grafana: check-context ## Port-forward Grafana
	kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring

forward-argocd: check-context ## Port-forward ArgoCD
	kubectl port-forward svc/argocd-server -n argocd 8080:443
