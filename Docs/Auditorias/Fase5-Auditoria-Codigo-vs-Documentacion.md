# Auditoría de código vs documentación — Fase 5 Flutter Foundation

## 1. Veredicto

**CODE MOSTLY CONSISTENT / MINOR FIXES REQUIRED**

El código fuente respeta la arquitectura y el contrato base, pero la aceptación del baseline queda condicionada a validación real con Flutter/Dart y a cerrar cobertura de pruebas/documentación de configuración.

## 2. Resumen ejecutivo

La implementación revisada es consistente con las decisiones principales de Fase 5: Flutter funciona como cliente del SaaS Backend, Dio está encapsulado, JWT usa almacenamiento seguro, Auth Foundation consume los cuatro endpoints contractuales, Riverpod gestiona estado y `go_router` gestiona navegación.

Se realizaron correcciones menores durante esta auditoría para añadir wrappers explícitos de respuesta/error, declarar el `part` de `json_serializable`, modelar estados de sesión expirada/backend no disponible y declarar los estados de job.

No se pudo ejecutar Flutter/Dart en el entorno. Por ello no se puede confirmar compilación, generación, análisis estático ni ejecución de tests. También falta cobertura de pruebas para AuthState, storage, repositorio, guards y códigos 401/403.

## 3. Documentos fuente de verdad revisados

| Documento | Rol | Estado |
|---|---|---|
| `saas-platform-client/README.md` | Alcance y onboarding | Revisado |
| `saas-platform-client/Docs/FEATURE-DEVELOPMENT.md` | Reglas de features | Revisado |
| `saas-platform-client/Docs/CONTRIBUTING.md` | Colaboración y archivos protegidos | Revisado |
| `saas-platform-client/Docs/Flutter-Foundation.md` | Baseline técnico | Revisado |
| `saas-platform-client/Docs/ADRs/ADR-005-FlutterFoundation.md` | Decisiones normativas Flutter | Revisado |
| `saas-platform-client/Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md` | Decisiones cerradas F5 | Revisado mediante búsqueda/ruta efectiva |
| `saas-platform-client/Docs/Fase_5-PlanDeImplementacion.md` | Plan de implementación efectivo | Revisado |
| `Backend_Nestjs/saas-platform-backend/Docs/Contracts/platform-api.v1.yaml` | Contrato HTTP | Revisado |
| `Backend_Nestjs/saas-platform-backend/Docs/ADRs/ADR-004-CommonBaseline.md` | Baseline backend y tenancy | Revisado |

La ruta solicitada `Docs/DocsTeam/PlanImplementacionFase5.md` no existe; el plan efectivo está en `Docs/Fase_5-PlanDeImplementacion.md`. El Formulario F5 existe en `Docs/DocsTeam/FormularioDeDecisiones/`, aunque las comprobaciones directas de PowerShell presentan limitación de rutas largas.

## 4. Archivos/capas auditadas

| Área | Archivos revisados | Estado |
|---|---|---|
| Configuración | `pubspec.yaml`, `.env.example`, `analysis_options.yaml`, `lib/core/config` | Cumple con warning de SDK |
| App | `lib/main.dart`, `lib/app` | Cumple |
| Network | `lib/core/network/api_client.dart` | Cumple |
| Storage | `lib/core/storage/secure_token_storage.dart` | Cumple |
| Errores | `lib/core/errors` | Cumple parcialmente |
| DTOs | `lib/shared/models/api_models.dart`, `.g.dart` | Cumple con generación pendiente |
| Auth | `lib/features/auth` | Cumple foundation |
| Routing | `lib/routes/app_router.dart` | Cumple foundation |
| Features placeholder | campaigns, prospects, prospecting_jobs, admin, profile | Cumple alcance |
| Tests | `test/api_models_test.dart`, `test/api_exception_test.dart` | Insuficiente cobertura |
| Auditoría anterior | `Docs/Auditorias/Fase5-Auditoria-Baseline-FlutterFoundation.md` | Consistente con warning de entorno |

## 5. Matriz de cumplimiento

| Requisito | Fuente | Estado | Evidencia | Severidad |
|---|---|---|---|---|
| Auth Foundation única funcional obligatoria | Formulario F5 / ADR-005 | CUMPLE | `features/auth` | — |
| Repo real `saas-platform-client` | README / F5 | CUMPLE | Ruta auditada | — |
| Flutter consume solo SaaS Backend | ADR-004 / OpenAPI | CUMPLE | Solo `ApiClient` HTTP | — |
| Estructura base `lib/core`, `features`, `routes`, `test` | Plan F5 | CUMPLE | Estructura presente | — |
| Dio solo en `core/network` | ADR-005 / Plan | CUMPLE | Único import en `api_client.dart` | — |
| Bearer y timeouts | OpenAPI / ADR-005 | CUMPLE | Interceptor y `BaseOptions` | — |
| Códigos 400/401/403/404/409/429/503 | OpenAPI | CUMPLE | `ApiErrorKind` y mapper | — |
| No HTTP 402 | OpenAPI / F5 | CUMPLE | Sin 402 en código Dart | — |
| JWT en secure storage | ADR-004 / ADR-005 | CUMPLE | `SecureTokenStorage` | — |
| No refresh token/OAuth/self-register | F5 | CUMPLE | No implementado | — |
| `ApiResponse`/`ApiErrorResponse` | OpenAPI / Plan | CUMPLE | DTOs explícitos | — |
| `AuthUser` distinto de `User` | OpenAPI | CUMPLE | Clases separadas | — |
| `AuthTenant` distinto de `Tenant` | OpenAPI | CUMPLE | Clases separadas | — |
| `role` y `currentTenantId` nullable | OpenAPI / ADR-004 | CUMPLE | Tipos nullable | — |
| No `passwordHash` | OpenAPI | CUMPLE | Ausente | — |
| Login/me/select-tenant/logout | OpenAPI | CUMPLE | `AuthRepository` | — |
| 401 limpia/restaura sesión | ADR-005 / Plan | CUMPLE CON WARNING | Restore e interceptor limpian storage; falta notificación global directa a AuthState | Media |
| 403 conserva sesión | OpenAPI / F5 | CUMPLE CON WARNING | Se mapea sin limpiar token; falta test | Media |
| ADMIN sin tenant | ADR-004 / F5 | CUMPLE | Guard y `currentTenantId` nullable | — |
| Rutas mínimas | Plan F5 | CUMPLE | `app_router.dart` | — |
| Jobs asíncronos y estados | OpenAPI / F5 | CUMPLE | Enum declarado; UI placeholder | — |
| Polling 3–5 segundos | F5 | FUERA DE ALCANCE | Solo foundation/documentación | — |
| No workers/WebSocket/SSE | F5 | CUMPLE | No aparecen en Dart | — |
| Mocks por feature | Plan / FEATURE-DEVELOPMENT | CUMPLE | Tres mock repositories | — |
| Tests mínimos foundation | Plan / ADR-005 | CUMPLE CON WARNING | Solo DTOs y ApiException | Media |
| Validación ejecutable | Plan | NO VERIFICABLE POR ENTORNO | Flutter/Dart ausentes | No bloqueante externo |

## 6. Hallazgos críticos

No se encontraron contradicciones críticas contra ADR-004 u OpenAPI en el código revisado.

## 7. Hallazgos altos

No se encontraron hallazgos altos de contrato o arquitectura.

## 8. Hallazgos medios

1. **Cobertura de tests incompleta.** Solo existen pruebas para DTOs y `ApiException`; faltan pruebas de AuthState, secure storage fake, login/me/select-tenant/logout y guards.
2. **401 global no está conectado a AuthState.** La restauración de sesión maneja 401, pero una llamada futura de feature no dispara automáticamente `sessionExpired`; debe resolverse antes de considerar completa la integración transversal.
3. **`envied` no está utilizado por `AppConfig`.** La documentación vigente declara `envied` y `.env` como decisión aprobada. La configuración actual usa `String.fromEnvironment`, que es segura para el baseline, y ahora incluye `.env.example`; debe confirmarse si se requiere generación real de envied antes del cierre formal.
4. **Rutas documentales inconsistentes.** `FEATURE-DEVELOPMENT.md` y `CONTRIBUTING.md` viven dentro de `Docs/`, mientras el README está en raíz; la auditoría debe conservar esa ruta efectiva o normalizarla antes del onboarding definitivo.

## 9. Hallazgos bajos / recomendaciones

- Reemplazar el placeholder manual `api_models.g.dart` por salida real de `build_runner`.
- Añadir una implementación de `NetworkException` solo si el equipo necesita una jerarquía pública distinta de `ApiException(kind: network)`.
- Evitar guardar archivos generados manualmente si el flujo del repositorio decide generarlos en CI.
- Añadir una matriz de estados visuales para placeholders cuando Ángeles inicie UI/UX.

## 10. Validación de estructura

Las carpetas requeridas existen: `lib/app`, `lib/core/config`, `lib/core/network`, `lib/core/storage`, `lib/core/errors`, `lib/core/theme`, `lib/shared/models`, `lib/shared/widgets`, las seis áreas de features requeridas, `lib/routes` y `test`.

No hay código de PostgreSQL, scraping, Prospector directo ni workers Flutter. La inicialización de Android/Web no pudo ejecutarse por ausencia del SDK.

## 11. Validación de dependencias

`pubspec.yaml` declara Dio, Riverpod, go_router, flutter_secure_storage, json_annotation, envied y logger; además declara flutter_lints, build_runner, json_serializable, envied_generator y mockito.

No se consideran instaladas porque `flutter pub get` no pudo ejecutarse. No se observan dependencias ajenas al alcance declarado.

## 12. Validación de Dio encapsulado

La búsqueda de `package:dio/dio.dart` devuelve únicamente `lib/core/network/api_client.dart`. No aparece en features, shared, routes ni app. La restricción se cumple.

## 13. Validación de ApiClient

`ApiClient` cubre base URL, Bearer, timeouts, headers, requests GET/POST/PATCH/DELETE, descarga binaria futura, mapeo de errores estándar y logging sin token. `unwrapData` cubre el wrapper `success/data`; los DTOs agregan `meta` para respuestas tipadas.

La conversión de respuesta binaria queda preparada, pero no hay exportación funcional, correctamente fuera de Fase 5.

## 14. Validación de Auth Foundation

`AuthRepository` usa los endpoints contractuales de login, me, select-tenant y logout. El login y select-tenant guardan el nuevo token; restore consulta `/me`; 401 durante restore limpia el storage; logout llama al backend cuando existe sesión y siempre limpia el storage local.

El flujo de credenciales inválidas queda en estado `failure`; backend no disponible puede representarse como `backendUnavailable`. Falta probar estos escenarios en entorno real.

## 15. Validación de routing/guards

Existen `/splash`, `/login`, `/select-tenant`, `/dashboard`, `/campaigns`, `/prospects`, `/generate`, `/profile`, `/admin`, `/session-expired` y `/backend-unavailable`.

El guard manda usuarios no autenticados a login, distingue sesión expirada/backend no disponible y exige tenant para rutas tenant-aware. ADMIN sin tenant no entra automáticamente a esas rutas. No se observan loops evidentes en el flujo principal.

## 16. Validación de DTOs/OpenAPI

Se modelan `ApiResponse`, `ApiErrorResponse`, `PaginationMeta`, `AuthContext`, `AuthUser`, `AuthTenant`, `User`, `Role` y `Tenant`. `role`, `platformRole` y `currentTenantId` respetan nullability; `passwordHash` no existe.

No existe `PersistJobResultsRequest`, no existe HTTP 402 y no se inventó body para persistencia. Los endpoints Campaigns/Prospects/Jobs no se presentan como implementados.

## 17. Validación de restricciones

No aparecen OAuth, refresh token, self-register, workers, background tasks, WebSocket, SSE, scraping, acceso a PostgreSQL, acceso directo a Prospector Service/Engine ni deduplicación definitiva en Flutter. Tampoco hay tokens hardcodeados.

## 18. Validación de tests

| Test/Área | Existe | Ejecutado | Resultado | Observación |
|---|---:|---:|---|---|
| DTOs base | Sí | No | No verificable | `api_models_test.dart` |
| ApiException | Sí | No | No verificable | `api_exception_test.dart` |
| AuthState | No | No | Pendiente | Falta cobertura |
| Secure storage fake | No | No | Pendiente | Falta cobertura |
| Login flow | No | No | Pendiente | Falta cobertura |
| `/auth/me` | No | No | Pendiente | Falta cobertura |
| select-tenant | No | No | Pendiente | Falta cobertura |
| logout | No | No | Pendiente | Falta cobertura |
| 401/403 | No | No | Pendiente | Falta cobertura |
| Router guards | No | No | Pendiente | Falta cobertura |

## 19. Comandos ejecutados

| Comando | Resultado | Error observado | Acción recomendada |
|---|---|---|---|
| `flutter create --platforms=android,web .` | Bloqueado | `flutter` no se reconoce | Instalar Flutter SDK y agregarlo al PATH |
| `flutter pub get` | Bloqueado | `flutter` no se reconoce | Instalar Flutter SDK y ejecutar en el cliente |
| `dart run build_runner build --delete-conflicting-outputs` | Bloqueado | `dart` no se reconoce | Instalar Dart mediante Flutter SDK |
| `flutter analyze` | Bloqueado | `flutter` no se reconoce | Ejecutar análisis real después de instalar SDK |
| `flutter test` | Bloqueado | `flutter` no se reconoce | Ejecutar tests reales después de instalar SDK |

## 20. Correcciones realizadas durante auditoría

- Añadidos `ApiResponse`, `ApiErrorResponse` y `ApiErrorBody`.
- Añadido `part` y placeholder de generación para `json_serializable`.
- Añadidos estados `sessionExpired` y `backendUnavailable` a `AuthStatus`.
- Añadido `ProspectingJobStatus` con los cinco estados contractuales.
- Añadidas redirecciones explícitas para sesión expirada y backend no disponible.

No se modificaron backend, OpenAPI ni funcionalidades de negocio.

## 21. Pendientes para validación en entorno Flutter real

1. Instalar Flutter/Dart y ejecutar `flutter doctor`.
2. Ejecutar `flutter pub get`.
3. Ejecutar `build_runner` y revisar el código generado.
4. Ejecutar `flutter analyze` y corregir diagnósticos reales si aparecen.
5. Ejecutar `flutter test`.
6. Añadir tests de AuthState, storage, repositorio, 401/403 y guards.
7. Confirmar la decisión documental de `envied`/`.env.example` frente a `String.fromEnvironment`.

## 22. Veredicto final

**CODE MOSTLY CONSISTENT / MINOR FIXES REQUIRED**

El baseline fuente está arquitectónicamente alineado y no muestra contradicciones contractuales críticas. No se debe declarar `F5 CLOSED AS FLUTTER FOUNDATION / READY FOR FEATURE DEVELOPMENT` hasta ejecutar validación real con Flutter/Dart y cerrar la cobertura mínima de pruebas indicada.
