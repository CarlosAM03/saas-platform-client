# Sprint Core V1 — verificación reproducible

Requiere Flutter3.47.5/Dart3.13.4, Node22+, Docker Compose y PowerShell7. Reutiliza Playwright y los Dockerfiles de Avance2; no agrega dependencias de producción.

Desde la raíz Flutter, en la rama `sprint/frontend-core-v1-parity`:

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=https://api.example.invalid
node tool/sprint/contract-audit.mjs <checkout-backend> origin/main
pwsh -File tool/sprint/Start-Sprint.ps1 -BackendPath <checkout-backend>
$state = Join-Path ([IO.Path]::GetTempPath()) 'prospector-frontend-sprint'
pwsh -File tool/sprint/Run-P2C.ps1 -StatePath $state
node tool/sprint/e2e.mjs $state codex/evidencias/e2e-local.json
node tool/sprint/api-negative.mjs $state
```

Ejecutar P2C y UI→DB en secuencia: comparten esta DB dedicada. El adaptador P2C valida etiqueta del contenedor, nombre avance2_core y PostgreSQL16; su modo heredado saas_local se conserva. Solo admite HTTP loopback.

El launcher exporta Backend main b51b265 a un temporal y construye desde ese snapshot; nunca usa las fuentes experimentales del checkout Backend ni las modifica. Rechaza otro SHA hasta reauditar. El artefacto Web exige fuentes de aplicación comprometidas; antes de reutilizar imágenes comprobar su revisión. El runner registra SHA de aplicación, SHA del runner y equivalencia de fuentes entre ambos.

Proyecto y volúmenes exclusivos `prospector-frontend-sprint`; API18541, HTTPS18543, PostgreSQL55547, noVNC18550 en loopback. Configuración efímera fuera del repositorio. Verificadores SQL fuera de Flutter. La CA local se confía únicamente en Chromium y en el driver HTTP del contenedor; no se desactiva TLS ni se instala CA en el host.

Cada run usa tenants A/B, actores ADMIN/OWNER/MEMBER e identidad compartida propios. La suite registra acciones UI, HTTP sin cuerpos ni credenciales, campos enviados, SQL, recarga y cleanup. Verifica checksum del seed completo antes/después. Las cuatro decisiones CSV comparan hash de bytes originales. La carrera de usuarios usa dos formularios reales en pestañas del mismo navegador y comprueba una creación201, un conflicto409 y una sola membresía.

Un FAIL, BLOCKED o NOT RUN impide aprobar la suite completa. HTTP_SQL y UI_ACCESS_CONTROL_AND_HTTP_SQL se identifican por su alcance; no se presentan como una mutación UI→DB.

Si se interrumpe el proceso, recuperar solo su runId mostrado en la evidencia o en los tenants de este proyecto:

```powershell
node tool/sprint/e2e.mjs $state codex/evidencias/recovery.json <runId-identificado>
```

Tras actualizar el agente de navegador, copiarlo al StatePath y recrear solo browser con `docker compose ... up -d --force-recreate --no-deps --no-build --wait browser`. El display X se elige dentro del contenedor sin borrar locks.

Parada sin borrar volúmenes:

```powershell
docker compose -p prospector-frontend-sprint --env-file (Join-Path $state 'core.env') -f (Join-Path $state 'compose.yml') stop
```

Smoke remoto público: `node tool/sprint/remote-smoke.mjs https://saas-platform-client-web.vercel.app`. Smoke UI autenticado: `remote-ui.mjs` recibe exclusivamente JSON por stdin protegido; nunca pasar credenciales en argv, guardar ejemplos reales ni activar HAR/traces/screenshots. El runner permite solo GET/HEAD/OPTIONS y POST de login, selección y logout. No registra cuenta, token, organizaciones ni datos de negocio. Requiere autorización explícita para la cuenta y origen; no crea fixtures productivos.

Los SHA desplegados deben probarse mediante metadatos autorizados de hosting. El smoke y Swagger no permiten inferirlos. ADR-006 y Prospector Service quedan fuera de esta suite Core.

Para iteraciones locales puede usarse -CachedToolchain: Dockerfile.e2e verifica Flutter3.47.5/Dart3.13.4 de la imagen existente y compila en /sprint-app vacío, sin reutilizar fuentes de otra rama. El artefacto final contiene solo Nginx y el bundle actual. La validación productiva sigue usando Dockerfile.vercel en CI.
Los negativos HTTP_SQL verifican JWT expirado, CSV expirado/alterado,413,replay409 y429 con SQL y cleanup, sin sustituir los escenarios UI_TO_DB.
