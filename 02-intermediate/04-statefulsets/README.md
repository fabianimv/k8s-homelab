# Lab 04: StatefulSets

## 🎯 Objetivos
- Entender diferencias con Deployments
- Manejar aplicaciones stateful
- Persistent storage por pod

## 📝 Ejercicios

### Ejercicio 1: StatefulSet Básico
```bash
kubectl apply -f statefulset-basic.yaml

# Observar orden de creación
kubectl get pods -w

# Ver nombres predecibles
kubectl get pods
# web-0, web-1, web-2...
```

### Ejercicio 2: Headless Service
```bash
# Acceder a pods específicos por DNS
kubectl run curl --image=curlimages/curl:8.10.1 --rm -it --restart=Never -- \
  curl http://web-0.nginx.homelab.svc.cluster.local
```

### Ejercicio 3: Scaling
```bash
# Scale up
kubectl scale statefulset web --replicas=5

# Scale down (orden inverso)
kubectl scale statefulset web --replicas=2
```

### Ejercicio 4: Eliminar pods
```bash
# Eliminar un pod
kubectl delete pod web-0

# Observar que se recrea con el mismo nombre y PVC
kubectl get pods -w
```

## 🧹 Limpieza
```bash
kubectl delete -f .
```

## 📚 Diferencias con Deployment

| Característica | Deployment | StatefulSet |
|---------------|------------|-------------|
| Nombres | Random | Ordenados (web-0, web-1) |
| Creación | Paralela | Secuencial |
| Storage | Compartido | Por pod |
| DNS | Service | Pod DNS |
