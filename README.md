# 🐳 Kubernetes Homelab

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)

Un laboratorio completo de Kubernetes para práctica diaria usando Docker Desktop.

## 🔒 Aislamiento del entorno

El laboratorio no opera contra `~/.kube/config`. Todos los targets del Makefile y los scripts trabajan contra un kubeconfig local en `./.kube/config`, generado a partir del contexto `docker-desktop` de Docker Desktop. La generación solo lee el kubeconfig global; nunca lo escribe.

- `make kubeconfig` genera `./.kube/config` con un único contexto (`docker-desktop`).
- Antes de ejecutar cualquier comando, los scripts verifican que el contexto sea `docker-desktop` y que el servidor sea local. Si detectan un contexto ajeno al laboratorio, abortan.
- El namespace por defecto del contexto local es `homelab`. Los manifiestos sin `namespace` se despliegan ahí.
- `./.kube/` y `./.helm/` están en `.gitignore`.
- Para usar `kubectl` manualmente, abre una shell aislada con `make shell` o carga el entorno con `source scripts/activate.sh`.
- `make reset` elimina el namespace `homelab` y los add-ons del lab (`monitoring`, `argocd`, `ingress-nginx`).

Docker Desktop puede agregar o actualizar el contexto `docker-desktop` y cambiar el `current-context` global al iniciar. El laboratorio no usa ese archivo. Verifica tu contexto global con `kubectl config current-context` antes de trabajar con otros clusters.

Si usas otro cluster local (por ejemplo kind o minikube), exporta su contexto antes de generar el kubeconfig: `export HOMELAB_CONTEXT=<nombre-del-contexto>`. El guard sigue exigiendo que el servidor sea local.

## 🐚 Shell aislada

`make shell` abre una shell con `KUBECONFIG=./.kube/config`, prompt `[homelab]` y wrappers de `kubectl`/`helm`. Los wrappers verifican que el kubeconfig local siga siendo el único contexto y que el contexto actual sea `docker-desktop`; si no, bloquean el comando. `deactivate_homelab` desactiva el modo. No es una sandbox de seguridad: `command kubectl` omite el wrapper a propósito.

## 📋 Prerequisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) con Kubernetes habilitado
- Provisioner `kubeadm` en Docker Desktop (los labs de `LoadBalancer` quedan en `localhost`; con `kind` usa `kubectl port-forward`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) (para labs intermedios/avanzados)

## 🚀 Quick Start

```bash
# 1. Clonar el repositorio
git clone https://github.com/FabianIMV/k8s-homelab.git
cd k8s-homelab

# 2. Generar el kubeconfig aislado (requiere Kubernetes habilitado en Docker Desktop)
make kubeconfig

# 3. Verificar que el contexto sea el aislado
make check

# 4. Desplegar el primer lab
make pods

# 5. Para usar kubectl manualmente, abre la shell aislada
make shell
kubectl get pods -n homelab
```

## 📚 Estructura del Lab

### 🟢 Basic (01-basic/)
| Lab | Descripción |
|-----|-------------|
| [01-pods](./01-basic/01-pods/) | Ciclo de vida, multi-container, init containers |
| [02-deployments](./01-basic/02-deployments/) | Scaling, rolling updates, rollbacks |
| [03-services](./01-basic/03-services/) | ClusterIP, NodePort, LoadBalancer |
| [04-configmaps-secrets](./01-basic/04-configmaps-secrets/) | Configuración y secretos |
| [05-namespaces](./01-basic/05-namespaces/) | Aislamiento y resource quotas |

### 🟡 Intermediate (02-intermediate/)
| Lab | Descripción |
|-----|-------------|
| [01-ingress](./02-intermediate/01-ingress/) | NGINX Ingress, routing |
| [02-persistent-storage](./02-intermediate/02-persistent-storage/) | PV, PVC, StorageClasses |
| [03-helm](./02-intermediate/03-helm/) | Creación de charts, values |
| [04-statefulsets](./02-intermediate/04-statefulsets/) | Aplicaciones stateful |
| [05-jobs-cronjobs](./02-intermediate/05-jobs-cronjobs/) | Tareas batch y programadas |

### 🔴 Advanced (03-advanced/)
| Lab | Descripción |
|-----|-------------|
| [01-monitoring](./03-advanced/01-monitoring/) | Prometheus + Grafana |
| [02-argocd](./03-advanced/02-argocd/) | GitOps deployment |
| [03-security](./03-advanced/03-security/) | RBAC, NetworkPolicies |
| [04-service-mesh](./03-advanced/04-service-mesh/) | Istio basics |

## 🛠️ Comandos Útiles

```bash
make help             # Ver todos los targets disponibles
make kubeconfig       # Generar el kubeconfig aislado en ./.kube/config
make kubeconfig-force # Regenerar el kubeconfig aislado desde cero
make check-context    # Verificar que el contexto sea el aislado
make check            # Verificar estado del cluster
make namespace        # Crear el namespace homelab
make status           # Ver pods, services y deployments
make clean            # Eliminar los manifiestos de los labs
make reset            # clean + namespaces y add-ons (monitoring, ArgoCD, ingress)

# Labs específicos
make basic            # Desplegar todos los labs básicos
make pods             # Desplegar solo el lab de pods
make deployments      # Desplegar solo el lab de deployments
make services         # Desplegar solo el lab de services
make apps             # Desplegar las apps de ejemplo
make intermediate     # Desplegar labs intermedios (excepto el chart de Helm)
make ingress          # Instalar NGINX Ingress Controller
make monitoring       # Desplegar stack de monitoreo
make argocd           # Instalar ArgoCD

# Port-forward
make forward-grafana
make forward-argocd
```

## 📖 Comandos kubectl Esenciales

Carga el entorno aislado antes de usar `kubectl` manualmente:

```bash
source scripts/activate.sh
```

```bash
# Pods
kubectl get pods -A                    # Ver todos los pods
kubectl describe pod <name>            # Detalles de un pod
kubectl logs <pod> -f                  # Ver logs en tiempo real
kubectl exec -it <pod> -- /bin/sh      # Entrar al pod

# Deployments
kubectl scale deployment <name> --replicas=3
kubectl rollout status deployment <name>
kubectl rollout undo deployment <name>

# Debugging
kubectl get events --sort-by='.lastTimestamp'
kubectl top pods                       # Uso de recursos
```

## 🗂️ Aplicaciones de Ejemplo

En `apps/` encontrarás aplicaciones listas para practicar:
- **nginx-demo**: Servidor web estático
- **flask-api**: API REST en Python
- **redis-cluster**: Aplicación stateful

## 🧹 Limpieza

```bash
# Eliminar recursos de un lab específico
source scripts/activate.sh
kubectl delete -f 01-basic/01-pods/

# Eliminar los manifiestos de todos los labs
make clean

# Eliminar además el namespace homelab y los add-ons (monitoring, ArgoCD, ingress)
make reset
```

## 📝 Tips

1. **Siempre verifica** que Docker Desktop Kubernetes esté habilitado
2. **Usa namespaces** para aislar tus experimentos
3. **Guarda tus cambios** antes de hacer rollback
4. **Monitorea recursos** con `kubectl top nodes`

---

Made with ❤️ for learning Kubernetes