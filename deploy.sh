
#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="redis-simple"
SECRET_NAME="redis-auth"
APP_NS="argocd"
APP_FILE="argo/redis-app.yaml"

# Genera una contraseña aleatoria si no se define REDIS_PASSWORD
REDIS_PASSWORD=${REDIS_PASSWORD:-"$(head -c 32 /dev/urandom | base64 | tr -d '=
' | cut -c1-32)"}

echo "[1/4] Creando namespace $NAMESPACE si no existe"
kubectl get ns "$NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$NAMESPACE"

echo "[2/4] Creando/actualizando Secret $SECRET_NAME"
kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME"   --from-literal=redis-password="$REDIS_PASSWORD"   --dry-run=client -o yaml | kubectl apply -f -

echo "[3/4] Aplicando Application de Argo CD"
kubectl apply -n "$APP_NS" -f "$APP_FILE"

echo "[4/4] (Opcional) Sincronizando con Argo CD CLI"
if command -v argocd >/dev/null 2>&1; then
  argocd app sync redis-simple || true
  argocd app wait redis-simple --timeout 300 || true
else
  echo "Argo CD CLI no detectado. La sincronización será automática."
fi

echo "Hecho. Para probar la conexión:" 
printf "
  kubectl -n %s port-forward svc/redis 6379:6379 &
" "$NAMESPACE"
printf "  redis-cli -a %s -h 127.0.0.1 ping
" "$REDIS_PASSWORD"
