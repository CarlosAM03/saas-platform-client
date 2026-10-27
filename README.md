# Plataforma SaaS - Cliente Flutter

Cliente Flutter multiplataforma de la Plataforma SaaS universitaria para gestion de campanas y prospeccion automatizada.

## Despliegue productivo en Vercel

Producción usa `Dockerfile.vercel`; desarrollo conserva `Dockerfile.dev` y
`docker compose up --build` en el puerto 4200. `Dockerfile.vercel` usa por defecto
`API_BASE_URL=https://saas-platform-backend-l55n.onrender.com`: una URL pública,
no una credencial. `--build-arg API_BASE_URL=...` permite sobrescribirla;
un valor explícito vacío o no HTTPS se rechaza. El deployment observado de
Vercel no propaga automáticamente Project Environment como Docker build arg,
por lo que omitir el argumento usa el default productivo. Flujo:
`ARG API_BASE_URL → flutter build --dart-define → bundle Web`.
Cambiar una variable runtime de Nginx no cambia esa URL: requiere reconstruir.
El frontend no necesita credenciales de base de datos.

El backend debe permitir el dominio Vercel en su configuración CORS.
`.vercel/` no se versiona. Las instrucciones operativas están en
[PlanDeployVercel](Docs/Planeacion/PlanDeployVercel.md); Preview, CORS y Production
se configuran manualmente después de integrar. HSTS supone HTTPS gestionado
por Vercel; CSP queda pendiente de evaluar scripts y CanvasKit de Flutter.

## Estado

Foundation y Auth se conservan. Tenants, Users, Campaigns y Prospects no-CSV usan API real, con listados, detalles, formularios, permisos visibles y estado por sesión/tenant.

Estado MVP del 27-10-2026: Backend **b6cd40f** ofrece creación condicionada, callbacks y resultados temporales de Jobs (TTL una hora). Flutter verifica capacidades del tenant antes de habilitar generación; mantiene cancel/persist/export deshabilitados. CSV existe en Backend **main y dev** y conserva su flujo independiente. Auth, arquitectura tipada, sesión/tenant y dashboard se mantienen. [Reporte y evidencia](Docs/Auditorias/Paridad_Flutter_Backend_Prospector_MVP.md), [contrato](Docs/Contracts/README.md) y [configuración Web](Docs/Despliegue-Web.md). Ningún entorno productivo fue desplegado.

## Papel de Flutter

Flutter es exclusivamente un cliente API del SaaS Backend NestJS.

```text
Usuario
  |
Flutter Client
  | HTTPS / REST / JWT
SaaS Backend NestJS
  |-- PostgreSQL
  `-- Prospector Service FastAPI
        `-- Prospector Engine Python
```

Flutter no se conecta directamente a PostgreSQL, Prospector Service ni Prospector Engine. Tampoco ejecuta scraping, resuelve reglas de negocio, decide autorizacion real ni realiza deduplicacion definitiva.

El backend es la autoridad para tenant context, autorizacion, persistencia, reglas de negocio, exportaciones y deduplicacion definitiva.

## Alcance funcional

- Auth: login, restauración, sesión expirada, logout y JWT en `flutter_secure_storage`.
- Tenants: listado, detalle, creación ADMIN y cambio de organización desde Perfil.
- Users: listado/búsqueda/paginación/orden, detalle, creación, edición y desactivación ADMIN. La creación omite `roleId`; backend asigna MEMBER. Sin selector de roles inventado.
- Campaigns: listado/búsqueda/paginación/orden, creación, detalle, edición/estado, archivo, eliminación permanente ADMIN confirmada y prospectos por campaña.
- Prospects: listado/búsqueda/paginación, detalle, edición y creación manual ADMIN/OWNER. Sources persistidos: `google_maps`, `manual`, `csv`.
- CSV: selector de archivo, vista previa, decisiones por fila, confirmación y resumen.
- Dashboard: totales de meta.total, campañas, prospectos y trabajos recientes del tenant.
- Jobs: listar y consultar registros; polling cada 4 segundos sin solapamiento. Cliente preparado para otras operaciones, con acciones deshabilitadas hasta verificar una implementación Backend compatible.

Las rutas CRUD manejan carga, vacíos, errores y permisos. Los datos y formularios se reinician al cambiar sesión o tenant. Backend sigue autorizando cada operación.

## Decisiones tecnicas vigentes

- Dio es el motor HTTP interno, encapsulado en `ApiClient`.
- Solo `lib/core/network` puede usar Dio.
- Features, providers y widgets no usan Dio ni hacen HTTP directo.
- Los repositories de features consumen `PlatformApi`; éste encapsula `ApiClient`.
- Riverpod gestiona estado.
- `go_router` gestiona rutas.
- `json_serializable` modela DTOs.
- `API_BASE_URL` se configura con `--dart-define`; `.env.example` es referencia documental y no se carga automaticamente. La dependencia `envied` permanece instalada, pero no se usa para esta configuracion F5.
- `logger` se usa para logs seguros.
- No hay refresh token, OAuth ni self-register publico.
- Jobs monitorea cada 4 segundos y limpia estado por sesión/tenant. Backend actual conserva respuestas 503 para mutaciones; configurar variables no las habilita.
- No hay WebSocket, SSE, workers Flutter, background tasks u offline avanzado.

## Tenant y roles

`currentTenantId` puede ser `null`. ADMIN puede autenticarse sin tenant seleccionado y no entra automaticamente a rutas tenant-aware. OWNER opera dentro de su tenant. MEMBER puede gestionar campañas y editar prospectos; creación manual/import CSV y gestión de usuarios requieren OWNER/ADMIN. La matriz completa está en `FEATURE-DEVELOPMENT.md`.

La UI solo controla visibilidad y experiencia. El backend conserva la autorizacion real y puede responder 403 aunque una accion haya sido visible.

## Estructura logica

```text
lib/
  app/
  core/
    config/
    network/
    storage/
    errors/
    theme/
  shared/
    models/
    widgets/
  features/
    auth/
    campaigns/
    prospects/
    prospecting_jobs/
    profile/
    admin/
  routes/
test/
docs/
```

## Documentacion normativa

La documentacion vigente del cliente vive dentro de `Docs/`:

- `Docs/ADRs/ADR-005-FlutterFoundation.md`
- `Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md`
- `Docs/Flutter-Foundation.md`
- `Docs/DocsTeam/Documentacion UIUX/LineamientosUI-UX.md`

La fuente contractual HTTP es `platform-api.v1.yaml` del backend. La autoridad de las decisiones de F4 es `ADR-004-CommonBaseline.md` del backend.

Los documentos conceptuales e historicos no sustituyen estas fuentes.

## Ownership

- Carlos: Flutter Foundation, arquitectura, integracion, ApiClient, Auth, routing, DTOs base y documentacion tecnica.
- Andre: features Flutter, pantallas, repositories, providers, widgets y tests de features.
- Angeles: UI/UX, wireframes, componentes, estados visuales y documentacion visual/academica.
- Angel: backend NestJS, Prisma, PostgreSQL, OpenAPI y endpoints funcionales.

Para reglas de trabajo consultar `Docs/CONTRIBUTING.md` y `FEATURE-DEVELOPMENT.md`.

## Reproducir F5 en VS Code (Windows)

Abrir este repositorio en VS Code y usar una terminal PowerShell. En esta maquina existen dos alias de ruta corta: `C:\w` apunta a este checkout y `C:\f` al SDK de `.flutter-sdk` (Flutter 3.47.5, Dart 3.13.4). Son enlaces al mismo contenido, no copias. Edge se usa como destino `chrome` porque Chrome no esta instalado.

```powershell
Set-Location C:\w
$env:Path = "C:\f\bin;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\v1.0;$env:Path"
$env:CHROME_EXECUTABLE = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
flutter --version
dart --version
flutter doctor -v
flutter devices
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter run -d edge --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000
```

Tras `flutter clean`, este Windows requiere recrear el enlace de `.dart_tool` a la caché corta antes de `flutter pub get` (el comando `clean` retira el enlace):

```powershell
Set-Location C:\w
flutter clean
New-Item -ItemType Junction -Path .dart_tool -Target C:\f5-dart-tool | Out-Null
flutter pub get
dart run build_runner build
flutter analyze
flutter test
```

Si `.dart_tool` ya existe, no recrear el enlace. `lib/shared/models/api_models.g.dart` es salida ignorada de `build_runner`, nunca un archivo escrito a mano. Para cambiar de backend, sustituir la URL en `--dart-define`. El backend NestJS debe estar disponible por separado para probar login real; sin backend, el cliente Web aun debe compilar y arrancar.

El alcance funcional y la matriz MEMBER vigente están descritos arriba y en `FEATURE-DEVELOPMENT.md`. El alcance de CSV, dashboard y consulta de Jobs se detalla en Docs/Funciones-Pendientes-Implementadas.md; no hay validación E2E contra despliegues.
## Inicio con Docker

Requisitos en host: Git, Docker y Docker Compose. El SDK Linux oficial está fijado en Flutter 3.47.5 / Dart 3.13.4 y se verifica mediante SHA-256 dentro de la imagen.

```powershell
git clone https://github.com/CarlosAM03/saas-platform-client.git
cd saas-platform-client
git switch dev
docker compose up --build
```

Abrir `http://localhost:4200`. El build resuelve dependencias, genera código y compila Flutter Web; Nginx sirve los archivos. Para aplicar cambios de código se vuelve a ejecutar `docker compose up --build`; no se promete hot reload.

El backend se levanta por separado desde su repositorio con `docker compose up --build`. Por defecto la app usa `http://localhost:3000`, accesible desde el navegador. Para cambiarlo:

```powershell
$env:API_BASE_URL='http://localhost:3001'
docker compose up --build
```

`API_BASE_URL` es un argumento de compilación; requiere reconstrucción. El backend debe permitir CORS para `http://localhost:4200`. Para detener el frontend: `docker compose down`.

---

### Credenciales locales de desarrollo

El entorno Docker local utiliza credenciales deliberadamente exclusivas de
desarrollo. No corresponden a producción ni a shared-dev.

#### Usuarios demo

Todas las cuentas utilizan:

Password: `DevOnlyPass123!`

| Rol | Email |
| --- | --- |
| ADMIN | `admin@demo.example` |
| OWNER Demo Norte | `owner.demo-norte@demo.example` |
| MEMBER Demo Norte | `member.demo-norte@demo.example` |
| OWNER Demo Sur | `owner.demo-sur@demo.example` |
| MEMBER Demo Sur | `member.demo-sur@demo.example` |

Para una prueba rápida del frontend se recomienda:

`owner.demo-norte@demo.example` / `DevOnlyPass123!`

La operación de PostgreSQL, migraciones y restauración del dataset pertenece al [backend](https://github.com/CarlosAM03/saas-platform-backend/blob/main/Docs/DevelopmentEnvironment.md). El cliente no necesita credenciales de base de datos.
