
# Configuración de variables
$NAMESPACE = "redis-simple"
$SECRET_NAME = "redis-auth"
$APP_NS = "argocd"
$APP_FILE = "argo/redis-app.yaml"

# Genera una contraseña aleatoria si no se define REDIS_PASSWORD
if (-not $env:REDIS_PASSWORD) {
    $bytes = New-Object byte[] 32
    (New-Object System.Security.Cryptography.RNGCryptoServiceProvider).GetBytes($bytes)
    $REDIS_PASSWORD = [Convert]::ToBase64String($bytes).Replace("=", "").Substring(0,32)
} else {
    $REDIS_PASSWORD = $env:REDIS_PASSWORD
}

Write-Host "[1/4] Creando namespace $NAMESPACE si no existe"
kubectl get ns $NAMESPACE *> $null
if ($LASTEXITCODE -ne 0) {
    kubectl create ns $NAMESPACE
}

Write-Host "[2/4] Creando/actualizando Secret $SECRET_NAME"
kubectl -n $NAMESPACE create secret generic $SECRET_NAME `
    --from-literal=redis-password=$REDIS_PASSWORD `
    --dry-run=client -o yaml | kubectl apply -f -

Write-Host "[3/4] Aplicando Application de Argo CD"
kubectl apply -n $APP_NS -f $APP_FILE

Write-Host "[4/4] (Opcional) Sincronizando con Argo CD CLI"
if (Get-Command argocd -ErrorAction SilentlyContinue) {
    argocd app sync redis-simple
    argocd app wait redis-simple --timeout 300
} else {
    Write-Host "Argo CD CLI no detectado. La sincronización será automática."
}

Write-Host "Hecho. Para probar la conexión:"
Write-Host "  kubectl -n $NAMESPACE port-forward svc/redis 6379:6379 &"
Write-Host "  redis-cli -a $REDIS_PASSWORD -h 127.0.0.1 ping"
