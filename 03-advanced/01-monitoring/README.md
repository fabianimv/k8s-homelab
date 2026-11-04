# Lab 01: Monitoring (Prometheus + Grafana)

## 🎯 Objetivos
- Desplegar Prometheus y Grafana usando Helm
- Acceder a dashboards
- Crear alertas básicas

## 📝 Ejercicios

### Ejercicio 1: Instalar Stack de Monitoreo
```bash
# Usando Makefile
make monitoring

# O manualmente:
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set grafana.adminPassword=admin

# Opcional: -f custom-values.yaml para persistencia y recursos
```

### Ejercicio 2: Acceder a Grafana
```bash
# Port-forward Grafana
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring

# Abrir http://localhost:3000
# Usuario: admin
# Password: admin
```

### Ejercicio 3: Acceder a Prometheus
```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090 -n monitoring

# Abrir http://localhost:9090
# Probar query: up
```

### Ejercicio 4: Explorar Dashboards
En Grafana:
1. Ir a Dashboards > Browse
2. Explorar dashboards pre-instalados:
   - Kubernetes / Compute Resources / Cluster
   - Kubernetes / Compute Resources / Node
   - Kubernetes / Networking / Cluster

### Ejercicio 5: Alertas
```bash
# Requiere el stack instalado (crea el CRD PrometheusRule)
kubectl apply -f alertmanager-config.yaml

# Ver alertas activas
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093 -n monitoring
```

## 🧹 Limpieza
```bash
helm uninstall monitoring -n monitoring
kubectl delete ns monitoring
```
