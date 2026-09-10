# Auditoría de baseline — Fase 5 Flutter Foundation

## Veredicto

F5 BASELINE PASSED WITH WARNINGS — implementación documental y de código fuente preparada, validación ejecutable bloqueada por ausencia de Flutter/Dart en el entorno.

## Alcance implementado

- Proyecto Flutter base con `pubspec.yaml` y reglas de análisis.
- Configuración por `API_BASE_URL`.
- `ApiClient` centralizado con Dio exclusivamente en `lib/core/network`.
- Mapeo de errores HTTP 400, 401, 403, 404, 409, 429 y 503, además de error de red.
- JWT en `flutter_secure_storage`; no se usa `SharedPreferences` ni `localStorage`.
- DTOs base para `AuthContext`, `AuthUser`, `AuthTenant`, `User`, `Role`, `Tenant` y paginación.
- Auth Foundation: login, restauración por `/me`, selección de tenant y logout.
- Estado de sesión con Riverpod.
- Routing con `go_router`, splash, login, selección de tenant, dashboard y rutas de contexto.
- Layout mobile-first con navegación principal y menú secundario.
- Campañas, prospectos, generación y administración como placeholders de Fase 5.
- Mocks aislados por feature; no se creó mock de Auth.
- Pruebas unitarias iniciales para DTOs y `ApiException`.

## Fuera de alcance respetado

No se implementaron persistencia funcional de resultados, exportación funcional, CRUD completo de campañas/prospectos, polling productivo, WebSocket, SSE, workers, background tasks, OAuth, refresh token, self-register, offline avanzado, analytics, push, deep linking, tema oscuro obligatorio ni publicación en stores.

## Archivos creados/modificados

Se crearon los archivos de baseline bajo `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml` y este documento de auditoría. No se modificaron archivos YAML del backend, OpenAPI ni código backend.

## Dependencias instaladas

No fue posible ejecutar `flutter pub get`; por tanto, ninguna dependencia se considera instalada en el entorno. Las dependencias declaradas son Dio, Riverpod, go_router, flutter_secure_storage, json_annotation, envied, logger y sus herramientas de desarrollo indicadas en el plan.

## Estructura final del repo

La implementación sigue `lib/app`, `lib/core/config`, `lib/core/network`, `lib/core/storage`, `lib/core/errors`, `lib/core/theme`, `lib/shared/models`, `lib/shared/widgets`, `lib/features/auth`, `lib/features/campaigns`, `lib/features/prospects`, `lib/features/prospecting_jobs`, `lib/features/profile`, `lib/features/admin`, `lib/routes` y `test`.

## Validación de Dio encapsulado

`ApiClient` es el único punto de acceso HTTP del código creado. Dio se declara como detalle interno de `lib/core/network`; las features dependen del repositorio y no importan Dio.

## Validación de Auth Foundation

Se implementaron las cuatro operaciones contractuales: `POST /api/v1/auth/login`, `GET /api/v1/auth/me`, `POST /api/v1/auth/select-tenant` y `POST /api/v1/auth/logout`. `currentTenantId` es nullable y `AuthUser` es un DTO separado de `User`.

## Validación de routing/guards

Se incluyen estados de splash, autenticación requerida, selección de tenant para rutas tenant-aware y acceso de ADMIN sin tenant a rutas no tenant-aware. La autorización real permanece en backend; un 403 sigue siendo posible.

## Validación de pantallas

Auth, splash, selección de tenant, dashboard, perfil, sesión expirada y backend no disponible tienen pantalla base. Campañas, prospectos, generación y administración están explícitamente marcados como placeholders.

## Validación de mocks

Los mocks están separados por feature y no se presentan como fuente de verdad. Campaigns, Prospects y ProspectingJobs permanecen desacoplados de Auth.

## Resultado de pruebas

También se intentó inicializar las plataformas con `flutter create --platforms=android,web .`; quedó bloqueado porque el ejecutable `flutter` no está disponible.

Los siguientes comandos fueron intentados desde `PlataformaFlutter/saas-platform-client`:

| Comando | Resultado | Causa |
|---|---|---|
| `flutter pub get` | Bloqueado | `flutter` no se reconoce como comando |
| `dart run build_runner build --delete-conflicting-outputs` | Bloqueado | `dart` no se reconoce como comando |
| `flutter analyze` | Bloqueado | `flutter` no se reconoce como comando |
| `flutter test` | Bloqueado | `flutter` no se reconoce como comando |

Acción recomendada: instalar Flutter SDK compatible, agregar `flutter/bin` al PATH, ejecutar `flutter doctor`, luego repetir los cuatro comandos. Los archivos generados por `json_serializable` y `envied` deben producirse en ese entorno.

## Correcciones realizadas

- Se usó Dio encapsulado en `ApiClient`.
- Se mantuvo el contrato de Auth del OpenAPI.
- Se modeló `currentTenantId` como nullable.
- Se evitó `PersistJobResultsRequest` y no se añadió HTTP 402.
- Se mantuvieron jobs y features de negocio como placeholders/mocks.

## Validación contra documentación de Fase 5

La implementación sigue el alcance consolidado de `FormularioDecisionesFase5.md`, `ADR-005-FlutterFoundation.md`, `FEATURE-DEVELOPMENT.md`, `CONTRIBUTING.md` y `README.md`: Auth Foundation es el único cierre funcional obligatorio; el repositorio real es `saas-platform-client`; el backend y OpenAPI son autoridad contractual.

## Validación contra OpenAPI

No se modificó OpenAPI. Se respetan los endpoints de Auth y los wrappers `success/data`. No se inventó request body para persistencia. Los endpoints objetivo de campañas, prospectos y jobs no se tratan como implementados por esta fase.

## Validación contra ADR-004

Se conserva ADMIN global, OWNER/MEMBER tenant-scoped, `currentTenantId` nullable, JWT sin refresh y backend como autoridad de autorización y aislamiento de tenant.

## Restricciones respetadas

No se agregó acceso directo a PostgreSQL, Prospector Service o Prospector Engine; no se agregó scraping, WebSocket/SSE, workers, background tasks, OAuth, refresh token, self-register, offline avanzado ni secretos reales.

## Advertencias no bloqueantes

- Falta ejecutar el SDK real y generar artefactos de código.
- La inicialización de plataformas nativas/web mediante `flutter create` no pudo ejecutarse por la ausencia del SDK.
- La compatibilidad final de versiones declaradas debe confirmarse con `flutter pub get` y `flutter analyze`.
- Los placeholders no representan funcionalidad MVP completa.

## Pendientes posteriores

Instalar/activar Flutter SDK, resolver cualquier diagnóstico de compilación, generar código, ejecutar tests, y posteriormente crear el Plan de Implementación de features. La implementación de Campaigns, Prospects y ProspectingJobs queda fuera del cierre de Foundation.

## Veredicto final

F5 FOUNDATION SOURCE BASELINE READY WITH ENVIRONMENT VALIDATION WARNING. No se declara producción lista ni frontend completo.
