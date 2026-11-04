# Lab 03: Security (RBAC y Network Policies)

## 🎯 Objetivos
- Configurar RBAC (Role-Based Access Control)
- Crear ServiceAccounts
- Implementar Network Policies

## 📝 Ejercicios

### Ejercicio 1: ServiceAccount
```bash
kubectl apply -f serviceaccount.yaml
kubectl get serviceaccount
kubectl describe serviceaccount app-service-account
```

### Ejercicio 2: Role y RoleBinding
```bash
kubectl apply -f rbac.yaml

# Probar permisos
kubectl auth can-i get pods --as=system:serviceaccount:homelab:app-service-account
kubectl auth can-i delete pods --as=system:serviceaccount:homelab:app-service-account
```

### Ejercicio 3: ClusterRole
```bash
kubectl apply -f clusterrole.yaml

# Ver roles del cluster
kubectl get clusterrole | grep cluster-viewer
```

### Ejercicio 4: Network Policies
```bash
kubectl apply -f network-policy.yaml

# Nota: Docker Desktop con el CNI por defecto no aplica NetworkPolicies.
# El bloqueo de tráfico solo se observa con un CNI que las soporte.
# Las pruebas asumen un Service llamado nginx en homelab
# (por ejemplo, el del lab 02-intermediate/04-statefulsets).

# deny-all-ingress bloquea todo el ingress en homelab, incluido nginx.
# Las reglas allow-* solo aplican a pods con label app=api.

# Probar que el tráfico a nginx queda bloqueado (con CNI compatible)
kubectl run curl --image=curlimages/curl:8.10.1 --rm -it --restart=Never -- \
  curl http://nginx

# Probar desde otro namespace (también bloqueado)
kubectl create ns other
kubectl run curl --image=curlimages/curl:8.10.1 -n other --rm -it --restart=Never -- \
  curl http://nginx.homelab
```

La policy `deny-all-ingress` aplica a todos los pods de `homelab`.
Elimínala al terminar el ejercicio para no bloquear otros labs.

## 🧹 Limpieza
```bash
kubectl delete -f .
kubectl delete ns other
```

## 📚 Conceptos

| Recurso | Scope | Uso |
|---------|-------|-----|
| ServiceAccount | Namespace | Identidad para pods |
| Role | Namespace | Permisos en un namespace |
| ClusterRole | Cluster | Permisos cluster-wide |
| NetworkPolicy | Namespace | Control de tráfico |
