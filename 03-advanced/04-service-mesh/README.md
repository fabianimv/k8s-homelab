# Lab 04: Service Mesh (Istio Basics)

## 🎯 Objetivos
- Entender qué es un Service Mesh
- Instalar Istio
- Configurar traffic management básico

## ⚠️ Requisitos
Istio requiere recursos significativos. Asegúrate de tener:
- Al menos 8GB RAM asignados a Docker Desktop
- 4 CPUs

## 📝 Ejercicios

### Ejercicio 1: Instalar Istio
```bash
# Descargar istioctl
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Instalar con perfil demo (para desarrollo)
istioctl install --set profile=demo -y

# Verificar instalación
kubectl get pods -n istio-system
```

### Ejercicio 2: Habilitar sidecar injection
```bash
# Habilitar auto-injection para el namespace homelab
kubectl label namespace homelab istio-injection=enabled

# Desplegar aplicación de ejemplo
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.31/samples/bookinfo/platform/kube/bookinfo.yaml

# Verificar sidecars
kubectl get pods
# Cada pod debería tener 2 containers (app + envoy proxy)
```

### Ejercicio 3: Acceder a Kiali (Dashboard)
```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.31/samples/addons/kiali.yaml
kubectl port-forward svc/kiali 20001:20001 -n istio-system

# Abrir http://localhost:20001
```

### Ejercicio 4: Traffic Management
```bash
# Requiere bookinfo desplegado en el ejercicio 2
kubectl apply -f virtual-service.yaml

# Exponer productpage
kubectl port-forward svc/productpage 9080:9080

# En otra terminal, probar routing
for i in {1..10}; do curl -s http://localhost:9080/productpage | grep -o "reviews-v[0-9]"; done
```

## 🧹 Limpieza
```bash
kubectl delete -f virtual-service.yaml --ignore-not-found
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.31/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl label namespace homelab istio-injection-
istioctl uninstall --purge -y
kubectl delete namespace istio-system
```

## 📚 Conceptos

| Componente | Función |
|------------|---------|
| VirtualService | Routing rules |
| DestinationRule | Load balancing, circuit breaker |
| Gateway | Ingress/Egress |
| ServiceEntry | External services |
