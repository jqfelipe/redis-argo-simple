
# Redis simple via Argo CD

Manifiestos mínimos (sin Helm) para desplegar Redis como cache y una `Application` de Argo CD para gestionarlo.

## Pasos
1. Sube el directorio `manifests/` a tu repo Git y ajusta `repoURL` y `targetRevision` en `argo/redis-app.yaml`.
2. Ejecuta el script `deploy.sh` para crear el Secret y la Application.
3. Argo CD sincronizará los manifiestos.

## Prueba
```bash
kubectl -n redis-simple port-forward svc/redis 6379:6379 &
redis-cli -a <tu-contraseña> -h 127.0.0.1 ping
```
