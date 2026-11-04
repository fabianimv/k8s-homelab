# Lab 02: ArgoCD (GitOps)

## 🎯 Objetivos
- Instalar ArgoCD
- Entender GitOps
- Desplegar aplicaciones desde Git

## 📝 Ejercicios

### Ejercicio 1: Instalar ArgoCD
```bash
# Usando Makefile
make argocd

# O manualmente:
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar a que esté listo
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s
```

### Ejercicio 2: Acceder a ArgoCD
```bash
# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Obtener password inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Abrir https://localhost:8080
# Usuario: admin
# Password: <output del comando anterior>
```

### Ejercicio 3: Instalar ArgoCD CLI
```bash
# Mac
brew install argocd

# Login
argocd login localhost:8080 --insecure
```

### Ejercicio 4: Crear una Aplicación
```bash
# Crea las Applications guestbook y apps
kubectl apply -f application.yaml

# O usando CLI:
argocd app create guestbook \
  --repo https://github.com/argoproj/argocd-example-apps \
  --path guestbook \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace homelab
```

### Ejercicio 5: Sync y Rollback
```bash
# Sincronizar
argocd app sync guestbook

# La Application "apps" despliega los manifiestos de apps/ del repo
argocd app sync apps

# Ver estado
argocd app get guestbook

# Rollback
argocd app rollback guestbook
```

## 🧹 Limpieza
```bash
argocd app delete guestbook
argocd app delete apps
kubectl delete ns argocd
```
