# Validación post-hardening de Flutter Foundation — 2026-10-10

## A. Baseline

| Elemento | Evidencia |
| --- | --- |
| Rama | `dev` |
| HEAD inicial | `90e38656e1aafd3c81e8d639e6b17f973f81aff8` |
| Backend | `CarlosAM03/saas-platform-backend`, `main` y `dev` en `ab53272f531d15e6c4dcc9df8c1d6dca8601e87a`; coincide con el checkout local |
| Flutter / Dart | Flutter 3.47.5 stable; Dart 3.13.4, Windows x64 |
| Entorno | Windows, PowerShell, Flutter desde `C:\f`, cliente mediante junction `C:\w` para evitar el límite de longitud de rutas; Docker Compose con API y PostgreSQL locales |

Antes de modificar existían cambios del usuario: traslado de `Docs/Fase_5-PlanDeImplementacion.md` a `Docs/Planeacion/` y dos auditorías sin seguimiento (`Auditoria_Profunda_Frontend_SaaS_2026-10-10.md` y `Auditoria_Ejecutable_Frontend_PostMerge_2026-10-10.md`). Se preservaron. No se hizo reset, limpieza global, commit, push, merge ni PR.

## B. Cambios implementados

| Área | Resultado |
| --- | --- |
| Auth | Logout remoto de mejor esfuerzo con limpieza local obligatoria; login y restore sin `DevUser`; eliminación del registro público falso. La selección de tenant sustituye JWT y contexto sólo desde la respuesta contractual, y conserva la sesión previa si falla. |
| Session | `acknowledgeSessionExpired()` limpia el token y contexto, pasa a `unauthenticated` y permite Login. 401 y 403 mantienen semánticas distintas. |
| Routing | Dashboard y rutas tenant-aware requieren `currentTenantId`; ADMIN global sin tenant va a selección. El router sólo reacciona al estado. |
| Networking | `ApiClient.delete` acepta query parameters; error contractual descompuesto en `kind`, HTTP status, code, message y `error.details`; red y timeouts se clasifican como `network`. |
| Parsing | Helpers estrictos para objeto, lista y lista paginada; `PaginatedResult<T>` y `PaginationMeta` validado sin valores inventados. |
| Tenant context | Repository mínimo para `GET /api/v1/tenants`; discovery ADMIN con carga, error y reintento en `SelectTenantPage`. |
| Navigation | Retiradas las entradas de `Generar` y `Administración` de la navegación funcional. Se conservaron los prototipos visuales. |
| Platform/config | Permiso Android `INTERNET`; exclusiones de análisis de plataformas generadas; artefactos iOS/macOS generados verificados, ignorados y retirados del índice sin borrar los archivos locales. |
| CI | Workflow Flutter con versión fijada, generación, analyze, test y build web; sin backend, despliegue ni publicación. |
| Tests | Cobertura Foundation ampliada a Auth, sesión, router, red, parsing y tenant discovery. |
| Docs | Rutas vigentes de `LineamientosUI-UX.md` y comando de generación corregidos. |

## C. Archivos modificados

- `lib/features/auth/state/auth_state.dart`, `lib/features/auth/presentation/auth_pages.dart`, `lib/app/app_providers.dart`: lifecycle de Auth, sesión expirada, selección y discovery.
- `lib/core/network/api_client.dart`, `lib/core/errors/error_mapper.dart`, `lib/shared/models/api_models.dart`, `lib/features/tenants/data/tenants_repository.dart`: HTTP, mensajes seguros y parsing contractual.
- `lib/routes/app_router.dart`: redirects tenant-aware y navegación disponible.
- `test/foundation_auth_test.dart`, `test/foundation_network_test.dart`, `test/api_models_test.dart`, `test/tenant_foundation_test.dart`: pruebas de las rutas críticas.
- `android/app/src/main/AndroidManifest.xml`, `.github/workflows/ci.yml`, `.gitignore`, `analysis_options.yaml`, `pubspec.lock`: plataforma, CI y generación. `flutter pub get` actualizó cuatro dependencias transitivas del lockfile; no se cambiaron restricciones directas.
- `README.md` y tres documentos bajo `Docs/ADRs` y `Docs/DocsTeam`: comandos y enlaces actuales.
- Eliminados `lib/features/auth/data/dev_user.dart` y `lib/features/auth/presentation/register_dialog.dart` por ausencia de uso productivo.
- Retirados del índice seis archivos generados: `ios/Flutter/Generated.xcconfig`, `ios/Flutter/flutter_export_environment.sh`, dos de `ios/Flutter/ephemeral/` y dos de `macos/Flutter/ephemeral/`. Flutter los regenera y sus encabezados indican no incluirlos en control de versiones; los archivos locales permanecen.

## D. Tests

| Suite/Test | Resultado | Objetivo |
| --- | --- | --- |
| `foundation_auth_test.dart` — startup, restore válido, 401 y backend unavailable | PASS | Estados iniciales y restauración con Bearer |
| `foundation_auth_test.dart` — login correcto/incorrecto y select tenant | PASS | Contexto y JWT contractual; error de selección conserva sesión |
| `foundation_auth_test.dart` — logout 200/fallo, token/contexto y acknowledge | PASS | Terminación local y recuperación de `sessionExpired` |
| `foundation_auth_test.dart` — router y deep links | PASS | Sin tenant no entra a Dashboard ni rutas tenant-aware |
| `foundation_network_test.dart` — Bearer, DELETE query, HTTP/timeout/red | PASS | Transporte y clasificación de errores |
| `foundation_network_test.dart` — 401/403, code/details, ErrorMapper | PASS | 401 expira; 403 conserva token y callback; mensajes seguros |
| `api_models_test.dart` — objeto/lista/paginado e inválidos | PASS | Parsing estricto del sobre y metadata |
| `tenant_foundation_test.dart` — ADMIN discovery y selección | PASS | Pantalla conectada al repository real de Foundation |
| Suite completa | **31/31 PASS** | `flutter test` sin fallos |

## E. Comandos y resultado exacto

Ejecutados desde `C:\w` con Flutter 3.47.5 y el PATH de `C:\f\bin`:

| Comando | Resultado |
| --- | --- |
| `flutter pub get` | PASS; actualizó cuatro dependencias transitivas en `pubspec.lock` |
| `dart run build_runner build` | PASS; escribió 2 outputs, mostró warnings de `json_annotation` y language version |
| `flutter analyze` | **PASS** — `No issues found!` |
| `flutter test` | **PASS** — `All tests passed!` (31) |
| `flutter build web --no-wasm-dry-run` | **PASS** — `Built build\web` |
| `git diff --check` y `git diff --cached --check` | PASS; sin errores de whitespace |

`--delete-conflicting-outputs` fue retirado de la documentación porque el `build_runner` instalado lo ignora. La generación mostró dos warnings conocidos: restricción `json_annotation ^4.9.0` anterior a 4.12.0 y lenguaje mínimo declarado 3.3 frente al rango sugerido `^3.8.0`. No impidieron generación, análisis ni tests; no se aplicó un upgrade indiscriminado. El build Web mostró un aviso de fuente Cupertino no incluida; finalizó correctamente.

## F. Runtime contra backend real

`docker compose up --build -d` levantó API y PostgreSQL sanos; `GET http://localhost:3000/api/v1/health/ready` devolvió **200**. Al cierre se restauró el puerto 3000 y ambos servicios quedaron healthy.

Se intentó `flutter run -d edge --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000`: Flutter no pudo lanzar Edge tras tres intentos. Se ejecutó el equivalente `flutter run -d web-server --web-hostname=127.0.0.1 --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000` y se recorrió la UI en el navegador integrado. Esta sustitución afecta al dispositivo usado, no al código servido.

| Flujo | Evidencia | Resultado |
| --- | --- | --- |
| OWNER login → Dashboard | `POST /auth/login` 200 desde navegador | PASS |
| OWNER reload → restore | `GET /auth/me` 200 con `demo-user-demo-norte-owner` y `demo-tenant-norte`; Dashboard visible | PASS |
| OWNER logout → reload | `POST /auth/logout` 200; Login visible y persistente tras reload | PASS |
| ADMIN sin tenant | Login dirigió a `/select-tenant`, nunca a Dashboard; `GET /tenants` 200 devolvió Norte y Sur | PASS |
| ADMIN selección | `POST /auth/select-tenant` 200; Dashboard; posterior reload hizo `/auth/me` 200 con `tenantId=demo-tenant-sur` | PASS |
| 401 | Con JWT auténtico persistido se detuvo la API y un servidor temporal devolvió 401 contractual a `/auth/me`; apareció `/session-expired`; el botón llevó a Login y reload no repitió el redirect | PASS, simulación controlada del 401 |
| 403 | Proxy temporal inyectó un solo 403 contractual en `GET /tenants` tras login ADMIN real; la UI mantuvo `/select-tenant`, mostró el mensaje de permisos, reintentó contra la API real con el mismo JWT, obtuvo tenants y seleccionó Sur | PASS, simulación controlada del 403 con reintento real |
| 403 backend real | OWNER Norte intentó seleccionar Sur por HTTP: 403; el mismo Bearer permitió después `/auth/me` 200 | PASS |
| Backend unavailable — restore | API detenida, reload mostró `/backend-unavailable`; al reiniciar API, `Reintentar` restauró Dashboard | PASS |
| Backend unavailable — logout | API detenida, `Cerrar sesión` llevó a Login pese al fallo remoto | PASS |
| Backend unavailable — login | API detenida, intento de login mostró indisponibilidad; `Volver a login` permitió abandonar ese estado | PASS |

Los servidores de inyección 401/403 eran temporales, locales y se retiraron; no se modificó el backend. La comprobación de reemplazo del JWT es doble: test del controlador y `/auth/me` real posterior que identifica `demo-tenant-sur`.

## G. Hallazgos residuales

| Prioridad | Hallazgo |
| --- | --- |
| BLOCKER | Ninguno para Foundation. |
| P1 | Ninguno dentro del alcance cerrado. |
| P2 | Warnings de `build_runner` por restricciones de `json_annotation` y SDK mínimo; revisar en una actualización controlada. Aviso de fuente Cupertino en build Web. El launcher Edge falló en este entorno; validación UI se hizo con `web-server` y navegador integrado. |
| DEFERRED | UI de Dashboard y features de negocio siguen siendo prototipos por alcance. `/generate` y `/admin` son placeholders internos sin entradas en navegación normal. |

## H. Alcance explícitamente no implementado

No se implementaron Campaigns, Prospects, Users CRUD, Admin real, Dashboard API/real, Jobs ni Prospector. No se creó un Dashboard global, refresh token, OAuth, registro público, retry global ni abstracciones de repository universales.

## I. Veredicto

```text
FLUTTER FOUNDATION HARDENED
READY FOR FEATURE DEVELOPMENT
```

Las gates locales (`analyze`, `test`, `build web`) y los flujos runtime requeridos se verificaron. GitHub Actions **Flutter Foundation CI** finalizó **SUCCESS** para `d4c846fa7494a98d74e3fcfb36c7517a8dbecb4d`: [run 38060741100](https://github.com/CarlosAM03/saas-platform-client/actions/runs/38060741100).

### Cierre residual — plan de tres bloques

Se corrigió `selectTenant + 401`: el catch ya no restaura el contexto previo después de una expiración; limpia defensivamente el token y deja contexto nulo y `sessionExpired`. Tests específicos cubren 200, 401, 403 y network; errores no-401 conservan la sesión anterior.

Protección de `main` pendiente: GitHub devuelve `protected=false` y el conector devuelve 403 `Resource not accessible by integration` al consultar administración. La herramienta disponible no permite modificar branch protection. Configuración exacta: Require pull request before merging; Require status checks (`foundation`, workflow **Flutter Foundation CI**, mostrado como `Flutter Foundation CI / foundation`); Require branches to be up to date; aplicar a administradores; desactivar force pushes y deletions. Así se bloquea el push directo sin PR/check. No se simula esta configuración mediante código.
