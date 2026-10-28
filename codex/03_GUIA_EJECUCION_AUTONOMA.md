# GUÍA DE EJECUCIÓN AUTÓNOMA — Sprint Flutter Core V1.0.0 / paridad 1:1 / E2E

**Proyecto:** PROSPECTOR SaaS — Segundo Avance 2026  
**Estado:** APROBADO POR EL OWNER; ejecución pendiente  
**Referencia:** 27 de octubre de 2026, America/Tijuana  
**Repositorio de trabajo:** `CarlosAM03/saas-platform-client`  
**Backend de autoridad:** `CarlosAM03/saas-platform-backend`  
**Rama prevista:** `sprint/frontend-core-v1-parity`, solo si su creación es segura  
**Aprobación, integración, QA final y despliegue:** Carlos, owner técnico  
**Carril paralelo no incluido en este encargo:** Ángel desarrolla Backend ADR-006; posteriormente adaptará Flutter bajo otra autorización.

> **Esta es la pieza 03 del harness.** Ejecutar subordinándose, en este orden, a `01_PLAN_RECTOR_SPRINT_FRONTEND_1A1.md` aprobado y `02_NORMATIVA_CODEX.md` aprobada. Esta guía **no concede permisos nuevos**. Sus comandos son ejemplos sujetos a la inspección de checkout, plataforma, credenciales y permisos reales. No interpretar una instrucción de prueba como autorización para operar servicios productivos o modificar el Backend.

---

## E00. Contrato de ejecución del agente

### E00.1. Resultado esperado

Trabajar de modo autónomo, **en la rama Flutter autorizada**, hasta obtener:

1. Diagnóstico reproducible, inventario 1:1 y correcciones mínimas de los hallazgos incluidos en el plan rector.
2. Pruebas unitarias, widget, contrato y de regresión actualizadas, sin alterar el comportamiento Backend 1.0.0.
3. Suite de integración P2C y suite adicional con navegador real → `PlatformApi`/`ApiClient` → NestJS → Prisma/PostgreSQL 16 local dedicado, con evidencia de la cadena y comprobación de relectura.
4. Validación remota **solo en el alcance expresamente autorizado**, con limitaciones reportadas honestamente.
5. Evidencia sanitizada, evaluación de gates G0–G5 y handoff para revisión del owner; preparación de PR únicamente cuando exista permiso para publicarlo.
6. Registro de preparación ADR-006 como dependencia futura; **ninguna ruta, pantalla o migración ADR-006 se implementa en este carril**.

### E00.2. Reglas de autonomía

**Autónomo:** inspeccionar, reproducir, editar Flutter en su rama segura, crear pruebas, ejecutar validaciones locales autorizadas, documentar evidencia, corregir errores de su propia implementación y proponer una entrega. **Condicionado:** dependencias nuevas, cambios de CI, uso de infraestructura adicional, push normal o creación de PR requieren autorización conforme a N03/N14. **Reservado al owner:** cambios arquitectónicos/contractuales, Backend, merges, despliegues, flags, cuentas productivas, acceso SQL remoto, escrituras remotas y aceptación final.

Si un paso está bloqueado, registrar `BLOCKED`, **seguir solo con pasos independientes permitidos** y no fabricar resultados ni pedir al owner que resuelva problemas ya documentados. Una contradicción contractual/material exige decisión humana antes de modificar la superficie afectada.

### E00.3. Orden obligatorio de documentos

1. `codex/01_PLAN_RECTOR_SPRINT_FRONTEND_1A1.md` — alcance, decisiones, gates.
2. `codex/02_NORMATIVA_CODEX.md` — autoridad, permisos, seguridad y bloqueos.
3. **Este documento** — procedimiento de ejecución.
4. En repo Flutter: posibles `AGENTS.md` vigentes, `README.md`, `Docs/ADRs/ADR-005-FlutterFoundation.md`, `FEATURE-DEVELOPMENT.md`, `Docs/Contracts/README.md`, `Docs/Contracts/Platform_API_Client.md`, `Docs/Despliegue-Web.md`, `Docs/Auditorias/Cierre_MVP_Seguridad_2026-10-27.md`.
5. En repo Backend (solo lectura): `Docs/ADRs/ADR-004-CommonBaseline.md`, `ADR-003-AuthSecureTransversal.md`, `MODULE-DEVELOPMENT.md`, `Docs/Contracts/platform-api.v1.yaml`, `src/common/openapi/deployment-document.ts`, `Docs/Avance2/CORE_V1_VALIDATION.md`, código y tests.
6. ADR-006 y YAML aprobados: **solo** para registrar la frontera de integración futura.

**Atención al drift documental:** algunas notas Flutter del 26 de octubre afirman un `main` Backend anterior, mientras el plan rector congela la auditoría del 27 de octubre. Ningún documento histórico demuestra por sí solo el HEAD actual ni el commit desplegado. Resolverlo mediante Git y fuentes vivas, no editando los históricos para que coincidan.

### E00.4. Árbol lógico y ubicaciones

El harness estará en `saas-platform-client/codex/` y se trata como documentación del encargo. Su carpeta `evidencias/` inicia únicamente con `README.md` cuando se entregue la pieza 04. Codex podrá producir ahí artefactos sanitizados **durante la ejecución**, distinguiendo los versionables de trazas temporales y secretos que deben permanecer fuera del repositorio.

Las rutas `lib/`, `test/`, `tool/`, `Docs/`, `.github/` son relativas a la **raíz Flutter**. `ops/avance2/` está en la raíz del **Backend**, no en Flutter. No inventar una raíz común ni asumir un nombre de checkout hermano.

---

## E01. Fase P0, paso 1 — Preflight seguro y repositorios

**Objetivo:** establecer dónde se ejecuta Codex, qué versión existe y si puede trabajar sin afectar a terceros. **No editar código hasta terminar E01–E03 y cumplir G0.**

1. Identificar ruta absoluta de Flutter, raíz Git y remoto. Comprobar que apunta a `CarlosAM03/saas-platform-client`; registrar URL saneada si contiene información sensible.
2. Inspeccionar rama, HEAD, estado de índice y working tree, conflictos, no rastreados, stashes y ramas existentes sin cambiar nada.
3. Inspeccionar reglas de contribución/`AGENTS.md`, protección de ramas y estado de los PRs. Registrar especialmente PR Flutter #8 y cualquier trabajo concurrente de André o Ángel que toque Auth/router/contrato.
4. Identificar repositorio Backend por su ubicación real y confirmar `CarlosAM03/saas-platform-backend`, HEAD y fuente `main`; verificar que es **solo lectura para este agente**.
5. Confirmar disponibilidad de Flutter/Dart SDK, Git, Docker Desktop y Compose, Node para scripts, PowerShell/pwsh, navegador accesible y acceso de lectura GitHub/CI. No instalar nada todavía.
6. Consultar fecha, zonas y SHA del deployment remoto **solo si hay acceso y una razón válida**; si no, dejar `UNVERIFIED`.

**Comandos de inspección (PowerShell; ejecutar desde raíz Flutter):**

```powershell
Get-Location
git rev-parse --show-toplevel
git remote -v
git branch --show-current
git rev-parse HEAD
git status --porcelain=v1
git branch -vv
git diff --stat
git diff --cached --stat
flutter --version
dart --version
docker version
docker compose version
```

No registrar en evidencias el resultado sin sanear de `git remote -v` si incluye credenciales. Los comandos que dependan de herramientas ausentes se documentan como requisito faltante, no como fallo de la aplicación.

**Condición de bloqueo:** checkout incorrecto, cambios ajenos no autorizados, merge/rebase en curso, historia difícil de reconciliar, falta de permiso para modificar la rama o divergencia de Backend que pueda invalidar el alcance. No usar `reset --hard`, `clean`, `stash`, `rebase` ni `push --force` para solucionarlo.

**Evidencia requerida:** `baseline.json` con repos, commits, rama, working tree, fecha y origen de cada referencia; `preflight.md` con condiciones verificadas, accesos y bloqueos.

### E01.1. Decisión de rama

Si el workspace está limpio y la rama no existe, crearla desde el `origin/main` **del frontend**, tras confirmar SHA y autorización de trabajo en rama:

```powershell
# Inspeccionar el fetch y confirmar que origin corresponde al repositorio esperado.
git fetch origin main
# Ejecutar solo si sprint/frontend-core-v1-parity aún NO existe y el árbol está limpio.
git switch -c sprint/frontend-core-v1-parity origin/main
```

Si la rama ya existe, **no volver a crearla**: inspeccionar ancestro, commits y diferencias; continuar solo si la procedencia es consistente y no hay cambios ajenos. No usar `dev` ni PR #8 como base automáticamente. El SHA `7731649a2c69b45cb9776d02de4a6105d6fd9886` es referencia histórica congelada, no HEAD garantizado.

**Gate intermedio:** `branch_verified = true`; en caso contrario, investigación exclusivamente read-only.

---

## E02. Fase P0, paso 2 — Inventario de contratos y autoridad Backend

**Objetivo:** construir una matriz comprobable, no asumir que dos YAML con nombre similar son equivalentes.

1. Identificar Backend `main` real y el commit de auditoría `b51b265f1a545fa915f1dd1c57ef2f5858ec6492`. Comparar, si difieren, las superficies de Auth, Tenants, Users, Campaigns, Prospects/CSV, Jobs, seguridad y Swagger. Elevar cambios materiales.
2. Leer Backend `Docs/Contracts/platform-api.v1.yaml` como **objetivo**, `deployment-document.ts` como adaptación de **disponibilidad** y `/api/docs-json` únicamente si hay backend local/remoto autorizado en ejecución.
3. Leer Flutter `Docs/Contracts/platform-api.v1.yaml`, `lib/platform_api/*`, `lib/core/network/api_client.dart`, repositories y widgets de cada feature.
4. Para cada ruta del alcance capturar: método, path, request/response, código(s) HTTP, rol, contexto tenant, headers, error esperado, disponibilidad, origen de evidencia y consumidor UI.
5. Clasificar `AVAILABLE`, `DISABLED_503`, `TARGET_ONLY`, `DRIFT` o `UNVERIFIED`. En Jobs distinguir GET list/detail reales de POST create/cancel/persist y GET export indisponibles, sin confundir fixtures de éxito futuro con producción.
6. Resolver las diferencias deliberadas `x-target-responses` del Flutter YAML. **No reemplazar** automáticamente el contrato local con el objetivo Backend ni reescribir el Backend.
7. Al detectar discrepancia aprobada-vs-código, crear `CONTRACT_DRIFT` con propuestas, no decidir unilateralmente una nueva semántica de producto.

**Rutas de inspección imprescindibles:**

```text
Flutter:
  lib/platform_api/{auth_api,tenants_api,users_api,campaigns_api,prospects_api,prospecting_jobs_api}.dart
  lib/platform_api/{models,requests,prospect_import_models}.dart
  lib/core/network/api_client.dart
  lib/features/*/{data,state,presentation}/
  test/platform_api/platform_api_contract_test.dart
Backend:
  Docs/Contracts/platform-api.v1.yaml
  src/common/openapi/deployment-document.ts
  src/{auth,tenants,users,campaigns,prospects,prospecting-jobs}/
  test/*e2e-spec.ts; test/*postgres-spec.ts
```

**Precisión:** usar los nombres reales observados con `git ls-files`; las rutas entre llaves son agrupaciones de lectura, no comandos shell literales. El contrato base del análisis tenía **33 operaciones públicas**, pero el recuento debe comprobarse de nuevo en la revisión concreta. ADR-006 aprobado no se añade como disponible al Core.

**Salidas:** `matriz-contrato-1a1.md`/`.csv` y `contract-diff.md`. Un test cuyo oráculo es solo el YAML copiado dentro de Flutter **no certifica** la API de NestJS.

---

## E03. Fase P0, paso 3 — Matriz de escenarios y baseline de pruebas

1. Crear una fila por escenario con ID estable, requisito, pantalla, rol, tenant sintético, secuencia UI, método/ruta, campos, respuesta esperada, prueba existente, prueba faltante, necesidad SQL, impacto y severidad.
2. Ejecutar **sin editar** checks de Flutter disponibles para registrar su baseline y distinguir fallos previos de nuevas regresiones.
3. Marcar explícitamente los límites de disponibilidad del ambiente (`PASS`, `FAIL`, `BLOCKED`, `NOT RUN`). Los resultados de CI histórico no sustituyen ejecución sobre el SHA actual.
4. Verificar que los tests existentes no fuerzan un contrato accidental contra el documento del propio frontend; identificar mocks válidos, P2C verdadero y smoke parcial UI.
5. Revisar el baseline de seguridad de sesión: `showSessionDialog` y pruebas de cambio de tenant/logout. No introducir regresiones P0 ya corregidas.

**Comandos de calidad inicial (raíz Flutter, sin modificar código de negocio):**

```powershell
dart run tool/check_merge_markers.dart
flutter pub get
dart run build_runner build
flutter analyze
flutter test
```

`build_runner` puede regenerar archivos: comprobar `git status` **antes y después** y no descartar cambios preexistentes. Si el proyecto exige herramientas locales adicionales, documentarlo; no agregar paquetes por impulso.

**Salida G0:** `baseline.json`, `preflight.md`, `matriz-contrato-1a1.md`, `matriz-e2e.md`, `test-baseline.md` y `hallazgos.md`. Si G0 no puede cerrarse, no comenzar reparaciones bajo hipótesis.

---

## E04. Fase P1, paso 4 — Reproducir FE-01, FE-02 y FE-03 antes de corregir

### E04.1. FE-01 — PATCH diferencial de User

**Código observado:** `lib/features/users/presentation/users_pages.dart` construye `UpdateUserRequest` con `name`, `email` y `status` aunque el usuario solo haya editado un campo. Backend `UsersService.update()` identifica presencia de campos de identidad global y aplica SEC-01 a cuentas compartidas.

**Pruebas antes del cambio:**

1. OWNER edita un campo permitido de un usuario local: comprobar que el payload conserva únicamente los campos cambiados.
2. OWNER cambia únicamente una propiedad de membresía ya autorizada por contrato: confirmar que no incluye por accidente `name`, `email`, `password` o `status`.
3. Identidad compartida con otro tenant: demostrar el rechazo de mutación global cuando corresponde y evitar rechazo falso provocado por campos sin cambios.
4. Guardar sin cambios: determinar respuesta UX legítima (no-op local, aviso o no envío) sin POST/PATCH espurio; conservar los detalles existentes no editados.
5. Campos `null`, cadenas trim, validación y contraseña opcional: no convertir omisión en limpieza ni enviar contraseña vacía.

**Implementación mínima esperada:** comparar estado inicial normalizado con formulario; construir `UpdateUserRequest` diferencial; preservar validadores y permisos actuales, actualizar widget/estado únicamente cuando sea necesario. No modificar `UsersService` ni añadir ruta.

**Evidencia:** request capturado con campos exactos, prueba fallida previa que detecta el exceso de campos, prueba aprobada posterior y regresión de edición normal/SEC-01.

### E04.2. FE-02 — Descubrimiento ADMIN independiente de memberships

**Código observado:** `lib/features/auth/presentation/auth_pages.dart` condiciona `tenantDiscoveryProvider` a `contextTenants.isEmpty`. ADMIN puede pertenecer a alguna organización y seguir necesitando descubrir organizaciones globalmente.

**Pruebas:** ADMIN sin memberships; ADMIN con una membership y al menos un tenant global ajeno; OWNER/MEMBER con memberships; fallo/recuperación de discovery; cambio de tenant sin mutar `platformRole`; no mostrar por error datos de otro contexto. UI de selector debe listar conforme a consulta Backend, no exclusivamente a `AuthContext.tenants` cuando ADMIN tenga memberships.

**Implementación:** adaptar solo la condición/estado necesario, respetar `TenantContext`, navegación y reglas del Backend. No conceder a OWNER/MEMBER descubrimiento global.

### E04.3. FE-03 — Permisos visibles frente a JWT snapshot

**Código observado:** `lib/features/auth/state/tenant_permissions.dart` consulta `/users/{selfId}` y puede obtener el rol actual de DB, mientras NestJS decide con la instantánea de rol del JWT de hasta ocho horas.

**Pruebas:** rol representado por JWT emitido; rol modificado en DB después de emitir token; 403 real tratado sin logout; tenant seleccionado válido/inválido; ADMIN mantiene privilegio global; estado obsoleto no habilita operaciones no autorizadas ni oculta contradicciones sin explicación.

**Implementación:** seleccionar un criterio de presentación **coherente con el contexto autenticado permitido por el contrato**, reutilizando fuentes existentes del cliente cuando sea posible. No inventar un servicio de revalidación por petición, un endpoint nuevo ni revocación inmediata. Si el DTO/estado vigente no expone la instantánea necesaria sin cambiar el contrato, **registrar el límite y elevar la decisión**, no deducir una supuesta regla del servidor.

### E04.4. Regla común de cierre P1

Para cada hallazgo: **antes → causa concreta → cambio mínimo → tests específicos → regresiones vecinas → después**. No marcar `PASS` por una prueba mock que no cubra el fenómeno reportado. Una P1 reproducida y no corregida impide G2.

---

## E05. Fase P2, paso 5 — Auditoría y reparaciones del Core por dominio

**Objetivo:** completar la matriz sin expandir el producto. Recorrer pantallas y repositorios de manera sistemática, siempre contra Backend implementado.

| Orden | Área de inspección | Secuencias obligatorias y anomalías a buscar |
|---|---|---|
| 1 | Auth y sesión | login normal/incorrecto; `/auth/me`; restauración; 401; 403 separado; logout; deep link; peticiones tardías; navegación browser back/forward; no fuga entre sesiones |
| 2 | Tenants | descubrimiento ADMIN; listado/detalle/create V1; tenant seleccionado; cambio A↔B; caches/formularios/dialogos invalidos; error de selección |
| 3 | Users | list/detail/search/page/sort; `PATCH` diferencial; status; SEC-01; desactivación solo ADMIN; creación V1 sin rediseño de onboarding |
| 4 | Campaigns | crear, editar, pausar, completar, archivar, eliminar permanentemente solo ADMIN; filtros, búsqueda y paginación; FE-06 sin falso filtro global |
| 5 | Prospects | listado/detalle, origen `manual`, relación de campaña, edición `FieldUpdate.omitted()` frente a `.set(null)`, permisos y acceso cruzado |
| 6 | CSV | file picker; mismos bytes en preview+confirm; cuatro decisiones; tamaño, clasificación, caducidad, colisiones, confirmación incierta, errores 400/409/413 |
| 7 | Dashboard | conteos reales `meta.total`, errores parciales y totales, cambio de tenant, FE-05 sin inventar ceros ni métricas nuevas |
| 8 | Jobs | lista y detalle de datos persistidos; resultados/progreso ausentes; 503 y reason para mutaciones/export; manejo de `query.source="demo"` de seed **solo como drift de fixture** |
| 9 | Seguridad y UX | administración por rol, sesión, reset de formularios, `showSessionDialog`, mensajes de errores y diagnósticos de parseo sanitizados FE-08 |

**FE-04:** cambio de rol `roleId` existente en API pero ausente en UI: elaborar propuesta/impacto. **No** ampliar el formulario sin autorización cuando implique funcionalidad visible o colisión con diseño de onboarding.

**FE-05 a FE-08:** clasificar mediante tests si son defectos efectivos, limitaciones documentadas o mejoras diferibles. Corregir únicamente lo autorizado y demostrable; un P2 puede quedar con deuda y recomendación expresa.

### E05.1. Aserciones indispensables por pantalla

- Estado inicial/cargando/vacío/error/éxito; componentes no muestran datos del tenant anterior durante transiciones.
- Paginación, orden, filtros y `meta.total` sin inferencias fuera del contrato; no perder cambios de un formulario al refrescar lista si no corresponde.
- Código HTTP/`ApiException`/mensaje UI: no convertir 401, 403, 404, 409, 413, 429 o 503 en éxito o logout universal.
- Permisos visibles alineados con políticas del Backend; el Backend es siempre el árbitro final.
- Si una operación no existe, marcarla como no disponible en vez de añadir un mock de producción.

### E05.2. Estrategia de cambios

Hacer commits lógicos por P1, dominio, tooling E2E y documentos. No reestructurar Foundation, introducir segunda instancia de Dio, nuevo router ni proveedores paralelos. Si aparece una causa compartida, presentar evaluación de impacto antes de una refactorización transversal.

---

## E06. Fase P3, paso 6 — Diseñar la suite E2E verificable

### E06.1. Definición de caso integral

Un escenario `UI_TO_DB` necesita, **todos**:

1. Navegador real interactúa con Flutter Web — acción semántica identificable.
2. Estado Flutter/repository/`PlatformApi`/`ApiClient` hacen una solicitud real a NestJS; capturar evidencia saneada de método/path/status, tenant de sesión y requestId si existe.
3. Backend procesa sus controles de autenticación, DTO, rol, tenant y servicio real; no sustituir por servidor de prueba simulado.
4. PostgreSQL 16 local **de ensayo** se inspecciona directamente por un verificador autorizado y confirma filas, asociaciones, actualización o ausencia de escritura.
5. Flutter muestra el estado correcto después de la respuesta **y tras recargar o iniciar nueva sesión**.
6. Datos creados se identifican por `runId`; existe procedimiento de cleanup acotado, validado y evidenciado.

Si falta algún eslabón, usar etiqueta de menor alcance (`WIDGET`, `CONTRACT`, `P2C`, `API_SMOKE`, `UI_SMOKE`, `REMOTE_OBSERVABLE`) y no declarar `UI_TO_DB` aprobado.

### E06.2. Matriz de IDs mínimos

| Suite | IDs de caso | Acción/criterio principal |
|---|---|---|
| Autenticación | `AUTH-01..06` | login OWNER/MEMBER/ADMIN, invalidez, sesión, 401/403, logout y deep links |
| Contexto multi-tenant | `TEN-01..07` | ADMIN discover, seleccionar, alternar A/B, cache/formularios, lectura cruzada y solicitudes tardías |
| Usuarios | `USR-01..07` | listado, detalle, PATCH diferencial, identidad compartida, restricciones 403, desactivación ADMIN y persistencia |
| Campañas | `CAM-01..09` | crear, buscar, paginar, editar, cambiar estado, archivar, borrar ADMIN y relectura/aislamiento |
| Prospectos | `PRO-01..08` | manual, nulos/omitidos, detalle, filtros, relación campaña, acceso cruzado y persistencia |
| CSV | `CSV-01..10` | upload, preview, CREATE, LINK_EXISTING, UPDATE_EXISTING, SKIP, conflictos, caducidad, 413 y no duplicados |
| Dashboard | `DASH-01..04` | totales, falla parcial, tenant switch y recarga |
| Jobs | `JOB-01..05` | list/detail y cuatro operaciones deshabilitadas verificadas por capa apropiada, sin Service |
| Seguridad y operación | `SEC-01..09` | rol, CORS, token, sanitización, 400/401/403/404/409/413/429/503 y no escritura indebida |

Los rangos son **catálogo inicial para detallar**, no afirmación de que exista una suite implementada o que cada número corresponda ya a una prueba. Crear inventario real con descripciones, prioridad y oráculo. Reusar pruebas existentes en lugar de duplicar mecánicamente todos los casos.

### E06.3. Aislamiento de datos de prueba

- Usar PostgreSQL 16 dedicado o efímero, dos tenants sintéticos A/B y perfiles ADMIN/OWNER/MEMBER. Respetar las reglas de negocio reales para construir fixtures, incluida identidad global.
- Nunca enviar credenciales SQL desde Flutter. El verificador SQL se ejecuta **fuera** de la aplicación, desde tooling local protegido.
- Generar `runId` único; comprobar precondiciones y postcondiciones de cada fixture; disponer cleanup idempotente solo para registros asignados a la ejecución.
- Preferir bases efímeras para escenarios que necesiten mutaciones profundas. Si hay seed, conservarlo y nunca borrar registros ajenos.
- Verificar sin exposición de password, JWT, email real, cookies, `Authorization`, enlaces de activación ni valores de entorno. Capturas/HAR se sanearán antes de guardarse.

### E06.4. Automatizador del navegador

Evaluar **primero** la infraestructura del Backend `ops/avance2` y los tests Flutter ya existentes. Si su agente de navegador no puede cubrir un flujo nuevo, diseñar una extensión ejecutable **desde el frontend** o propuesta de herramienta de test, sin editar Backend. Antes de añadir Playwright, dependencias, contenedores o CI, justificar costo, mantenimiento y obtener aprobación conforme a N14.

- Preferir selectores accesibles y robustos; comprobar cómo Flutter Web expone el árbol semántico.
- Esperar estados observables (URL, elemento, respuesta de red), no demoras arbitrarias para forzar un PASS.
- Las credenciales sintéticas se inyectan en ejecución de prueba, nunca en el código, reporte o screenshots.
- Exigir reinicio o relectura comprobable, no solo toast de éxito.
- No inyectar un `POST` directo en lugar de pulsar el formulario: eso sería una prueba HTTP, no UI E2E.

---

## E07. Fase P3, paso 7 — Entorno local y elección del stack correcto

**Advertencia confirmada en código del 27/10:** existen **dos stacks locales diferentes**. No se pueden intercambiar sus datos/puertos/configuraciones sin adaptación y verificación previa.

| Stack | Fuente | DB declarada | Uso previsto |
|---|---|---|---|
| Desarrollo Backend y P2C | Backend `compose.yml` + Flutter `tool/platform_api_p2c_test.dart` | `saas_local` en servicio `db` | `PlatformApi` → NestJS → PostgreSQL local; el test llama `docker compose exec db psql -U saas_local -d saas_local` |
| Core Avance 2 con navegador HTTPS | Backend `ops/avance2/compose.core.yml` + `Start-Core.ps1` | `avance2_core` en servicio `db` | UI navegador aislado `https://localhost:18443`, API local `127.0.0.1:18441`, PostgreSQL en loopback `55447` |

El test P2C **exige host HTTP loopback**, `P2C_PASSWORD` y `P2C_BACKEND_DIR` si el checkout no coincide con la ruta por defecto. El stack Core genera `LOCAL_DEMO_PASSWORD` propio y utiliza otra DB; **no ejecutar P2C apuntando a Core Avance 2 sin crear primero un adaptador aislado y validado**, no reemplazar nombres de base al azar ni dirigir SQL a Supabase/Render.

### E07.1. Vía A: P2C existente, sin UI, sobre Compose normal

1. Comprobar que el Backend checkout es la revisión autorizada y que ningún `compose` comparte recursos con otros procesos. Revisar nombres de proyecto, contenedores, volúmenes y puerto 3000. `compose.yml` tiene credenciales/seed **de desarrollo sintéticas**: nunca usarlo con producción ni publicar credenciales.
2. Levantar solo este stack si el puerto, los volúmenes y el entorno son seguros. **No ejecutar `down -v`.**
3. Comprobar `/api/v1/health/ready`, Swagger disponible y seed de prueba.
4. Ejecutar desde Flutter `tool/platform_api_p2c_test.dart`, usando la ruta real al Backend y la contraseña local del seed exclusivamente en contexto de test. No registrar esa contraseña en shell transcript ni artefactos.
5. Revisar resultado de Postgres, integridad/cleanup, recuento de casos y fuente `demo` histórica de Jobs. Si el fixture de Jobs no respeta contrato, conservar señal de drift; no añadir `demo` al enum público.
6. Parar contenedores con mecanismo no destructivo documentado, si procede.

**Comandos ilustrativos (desde Backend, revisar proyecto/volúmenes antes):**

```powershell
docker compose config --quiet
docker compose ps
# Solo con ambiente dedicado y autorización:
docker compose up --build -d
docker compose ps
# Verificación pública de salud en loopback:
Invoke-WebRequest -Uri 'http://127.0.0.1:3000/api/v1/health/ready' -UseBasicParsing
```

**Invocación P2C — esquema, NO pegar una contraseña en documentación ni logs:**

```text
flutter test tool/platform_api_p2c_test.dart
  --dart-define=P2C_BASE_URL=http://127.0.0.1:3000
  --dart-define=P2C_BACKEND_DIR=<RUTA_ABSOLUTA_BACKEND_REAL>
  --dart-define=P2C_PASSWORD=<PASSWORD_SINTETICO_LOCAL>
```

Un runner propio podrá inyectar valores efímeros de forma controlada, cuidando que las opciones `--dart-define` no aparezcan en logs compartidos, historial de comandos o listados de procesos publicados. Registrar solo el comando **redactado**. Este test no se ejecuta contra Render ni producción.

### E07.2. Vía B: UI HTTPS real con Core Avance 2

1. Leer `ops/avance2/README.md`, `Start-Core.ps1`, `compose.core.yml`, `verify-ui.mjs`, `verify-runtime.mjs` y `verify-contract.mjs`; verificar versiones, propiedad exclusiva de volúmenes y ausencia de colisiones con Vía A.
2. Preparar el checkout Flutter real con la rama Core corregida. Ejecutar el script **desde la raíz Backend**, pasando `-FlutterPath` para evitar su suposición de checkout hermano llamado `flutter-core`.
3. El script construye imágenes Backend/Flutter de test y un navegador aislado con confianza TLS confinada al contenedor. El estado/config privada se crea fuera del repositorio. **No** trasladar ese certificado local al host ni la imagen local a producción.
4. Verificar salud: UI `https://localhost:18443` dentro del navegador aislado, API `http://127.0.0.1:18441` y noVNC `http://127.0.0.1:18450/vnc.html?autoconnect=1&resize=scale` en loopback. No interpretar `localhost` del navegador aislado como dominio público.
5. Ejecutar smokes existentes usando sus argumentos reales y paths de salida sanitizados; `verify-ui.mjs` recibe `(contenedorBrowser, rutaEnvPrivada, salida)` y `verify-runtime.mjs` recibe `(rutaEnvPrivada, salida)`. Verificar primero el nombre/ID real del contenedor con `docker compose ps`; no inventarlo.
6. Ampliar cobertura UI+SQL por herramientas ubicadas en **Flutter** bajo la autorización vigente, sin cambiar fuentes Backend. Construir una **suite separada** que controle navegador, verifique PostgreSQL dedicado, relectura y cleanup. No declarar el smoke actual como E2E completo.
7. Controlar rate limit sin desactivar el guard. El README Core indica espaciar repeticiones de logins; registrar pausas necesarias y evitar bucles de fuerza bruta.

**Comando documentado por Backend (raíz Backend, PowerShell/pwsh):**

```powershell
# Resolver primero la ruta real del cliente, estado/volúmenes y build permitido.
pwsh -File ops/avance2/Start-Core.ps1 -FlutterPath '<RUTA_ABSOLUTA_FLUTTER>'
```

Para detener sin pérdida, utilizar los comandos **del README del stack y el envFile realmente creado**, sin `down -v`. El entorno Core usa la base `avance2_core`, no la DB `saas_local` de Vía A. Antes de incorporar SQL directo al runner UI, validar usuario, DB, puerto, identificación del volumen, política de teardown y permisos de lectura/escritura de ensayo.

### E07.3. Gates de ambiente

- **Aprobar Vía A:** health + P2C contra la DB correcta + datos sintéticos + cleanup comprobado.
- **Aprobar Vía B preliminar:** navegador real + Flutter compilado de la rama + HTTP real + casos smoke + TLS de prueba confinado.
- **Aprobar G3 integral:** además de lo anterior, casos `UI_TO_DB` con SQL local y relectura final, completos y evidenciados.
- Si Docker, navegador, puertos o datos impiden la cadena, etiquetar `BLOCKED` con causa; no sustituir PostgreSQL por un mock y declarar G3 verde.

---

## E08. Fase P3, paso 8 — Implementar verificadores E2E sin falsear la cadena

**Orden recomendado, uno a uno:**

1. Definir `runId`, tenant A/B, usuarios sintéticos, matriz de permisos y setup limpio. Comprobar que ningún paso operará fuera del DB objetivo.
2. Crear/verificar desde UI una campaña; capturar `POST /campaigns` y su respuesta; verificar en DB `tenant_id`, `created_by`, nombre y fecha, y luego en UI tras refresh.
3. Editar/archivar la campaña y verificar persistencia y visibilidad; probar eliminación solo con ADMIN y filas relacionadas sin usar limpieza global.
4. Crear prospecto `manual` desde UI; confirmar relación campaña y fuente, PATCH nullable y lectura tras refresh.
5. Importar CSV por UI: seleccionar archivo original, preview, tomar decisiones `CREATE`, `LINK_EXISTING`, `UPDATE_EXISTING`, `SKIP` en escenarios separados; confirmar con bytes originales, verificar filas, deduplicación y relaciones.
6. Verificar usuarios: **incluir expresamente la creación de usuarios mediante el flujo V1.0.0 que ya soporta el Backend**. Desde el formulario real de Flutter, verificar permisos de ADMIN/OWNER/MEMBER según los guards actuales, payload del `PlatformApi`, respuesta HTTP real, creación de `User` y membresía/rol en PostgreSQL del tenant autorizado y relectura desde UI tras refrescar o iniciar otra sesión; cubrir colisiones, rechazos y ausencia de escrituras parciales. Además, validar `PATCH` diferencial desde UI y SQL; identidad compartida y rechazos SEC-01 sin cambios indebidos; desactivación únicamente por ADMIN. No confundir esta alta V1 con el onboarding por enlace ADR-006.
7. Cambiar entre tenants con navegación y acciones pendientes; registrar ausencia de datos filtrados o requests stale en la UI y consultas SQL sin cruce de tenant.
8. Verificar dashboard derivado de datos reales, cambio de tenant, parcialidad de errores y recarga; no crear métricas fuera del contrato.
9. Jobs: verificar lista/detalle reales de fixtures válidas y errores `503` de operaciones indisponibles con tests de API cuando la UI no ofrezca acciones. No forzar scraping ni llamar al Service.
10. Negativos: 400, 401, 403, 404, 409, 413, 429, 503, CORS y expiración. En escenarios que puedan alterar sesión/DB, preservar logs sanitizados y ausencia de escritura.
11. Ejecutar cleanup **solo de entidades con `runId`** y comprobar que seed/otros tenants quedaron intactos. Repetir suite para asegurar idempotencia y no depender del orden de ejecución.

### E08.1. Esquema de evidencia por caso

```json
{
  "caseId": "CAM-01",
  "scope": "UI_TO_DB",
  "environment": "local-isolated",
  "frontendSha": "<sha-verificado>",
  "backendSha": "<sha-verificado>",
  "runId": "<id-sintetico>",
  "role": "OWNER",
  "tenantFixture": "A",
  "uiAction": "Crear campaña desde formulario real",
  "http": { "method": "POST", "path": "/api/v1/campaigns", "status": 201 },
  "dbAssertions": ["campaign.tenant_id == fixture A", "campaign.created_by == actor"],
  "uiReread": "PASS",
  "cleanup": "PASS",
  "status": "PASS",
  "evidence": ["<ruta-relativa-sanitizada>"]
}
```

**Ejemplo de formato, no una prueba realizada.** No introducir contraseñas, JWT, cuerpos sensibles ni `DATABASE_URL`. El resultado `PASS` se asigna únicamente tras ejecutar cada aserción de ese escenario real.

### E08.2. Integridad SQL

Las consultas de prueba deben medir invariantes y no borrar datos indiscriminadamente. Ejemplos de oráculos: fila exacta por ID creado, `tenant_id`, `created_by`, vinculación `user_tenants`, `campaign_prospects`, unicidad y estado. Para errores, contar filas/relaciones **antes y después**. En toda modificación transaccional, confirmar ausencia de registros huérfanos.

La sentencia SQL concreta dependerá del esquema Prisma y nombres físicos confirmados en el Backend auditado; no convertir ejemplos del documento en SQL ejecutable contra una DB desconocida. El test runner necesita abortar si host/DB no corresponde a la lista local autorizada.

### E08.3. Manejo de fallos en navegador

Capturar URL y control afectado, árbol semántico disponible, consola, status HTTP sanitizado, screenshot sanitizada y motivo. Si el árbol Flutter no permite seleccionar un control fiable, registrar `ENV_BLOCKER`, investigar un selector accesible dentro del alcance y **no** aprobar el escenario sustituyéndolo por una llamada `curl`.

---

## E09. Fase P4, paso 9 — Calidad, CI y PR

Ejecutar sobre el SHA corregido y registrar códigos de salida; no atribuir resultados anteriores a commits nuevos.

**Secuencia mínima de calidad Flutter:**

```powershell
dart run tool/check_merge_markers.dart
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=https://api.example.invalid
```

`https://api.example.invalid` es un **placeholder de compilación CI**, no un origen para probar conexión. La compilación productiva de Vercel utiliza un `API_BASE_URL` público HTTPS real fijado **durante build**, sin `/api/v1`, credenciales ni paths; no cambiarlo en el cliente mediante variables runtime y afirmar que la aplicación recompiló.

**Verificaciones de entorno y contenedores:** revisar y ejecutar, donde se permita, los checks existentes de `.github/workflows/ci.yml` (build Compose y build del `Dockerfile.vercel` con smoke Nginx). Un build verde solo valida el artefacto, no un login real ni persistencia.

**Revisión final antes de publicar:**

```powershell
git status --porcelain=v1
git diff --check
git diff --stat
git log --oneline -n 10
```

1. Inspeccionar todos los archivos nuevos/cambiados para detectar secretos, rutas locales absolutas, screenshots identificables, artefactos de Docker, caches, builds y documentos históricos accidentalmente alterados.
2. Exigir tests antes/después de FE-01–FE-03. Revisar ausencia de cambios no relacionados, renombrados masivos y dependencias no autorizadas.
3. Comparar código contra matriz contrato una vez más; verificar que Jobs 503 y SEC-01 no regresaron.
4. Si autorizados, hacer commits temáticos y push **ordinario únicamente a la rama propia**. Preparar PR sin merge hacia la base aprobada por el owner; si `dev` contiene commits experimentales, bloquear promoción y documentar opciones.
5. Registrar SHA final, URL de PR cuando exista, checks por SHA y deuda/pendientes. No inventar links a PRs o CI.

**Gate G1:** análisis/tests/build aplicables PASS. **Gate G2:** paridad y seguridad PASS. **Gate G3:** suite UI→DB local PASS. **Gate G5:** handoff + PR autorizado o estado `PR_NOT_PUBLISHED` documentado. Si un gate no pasa, no declarar release listo.

---

## E10. Fase P5, paso 10 — Smoke remoto autorizado (no despliegue)

Este paso **no concede** permiso de despliegue, administración de infraestructura o escritura. Codex puede preparar y ejecutar solo lo que el owner haya autorizado según N12 y el acceso disponible.

1. Obtener URL exacta de Vercel, identificar si apunta a Preview o Production y confirmar fecha/artefacto/SHA, sin deducirlo de `main`.
2. Confirmar origen de API embebido en el build Flutter (`API_BASE_URL` de compilación), dominio HTTPS real Render y allowlist CORS correspondiente. No confundir una variable de entorno editada después del build con cambio del bundle.
3. Correlacionar Backend desplegado con revisión conocida cuando exista evidencia de despliegue, logs o metadata autorizada; comparar `/api/docs-json` con estado esperado. Health `200` no demuestra SHA ni paridad completa.
4. Ejecutar orden: health/read-only → login con credenciales de ensayo expresamente autorizadas → selección de tenant → navegación por campaña/prospecto/CSV/JOBS permitidos → logout → consola/red saneadas.
5. **Solo** en staging dedicado o con autorización explícita adicional: escrituras sintéticas identificables y limpieza controlada. Nunca usar DB admin ni fixtures con datos reales; reenvíos de email, altas, bajas y operaciones masivas requieren su propia autorización.
6. Comprobar persistencia remota por nueva consulta autenticada y refresh si fue autorizada una escritura: etiquetar `REMOTE_OBSERVABLE`. No llamar a ello «PostgreSQL remoto probado por SQL» sin conexión read-only autorizada y consulta efectuada.
7. Si acceso remoto, browser, CORS, creds o cuota impiden la operación, marcar `BLOCKED`, registrar pasos e impacto y dejar G4 sin certificación productiva.

**Reporte remoto obligatorio:** URL pública, rol de cuenta de ensayo (sin credencial), revisión Flutter, revisión Backend si comprobada, CORS, método/ruta/status, qué fue read-only o escritura autorizada, tiempo, evidencia saneada, rollback si aplicaba y `PASS/FAIL/BLOCKED/NOT RUN` por escenario.

---

## E11. Preparación posterior y frontera con ADR-006 (no implementar aquí)

**Responsable Backend ADR-006:** Ángel; su rama y PR propios. **Responsable integración y QA:** Carlos. **Responsable posterior UI ADR-006:** Ángel, partiendo del Flutter Core ya estabilizado y aprobado.

Durante este sprint, producir solamente una `matriz-integracion-adr006.md` que recoja:

1. Los cinco endpoints nuevos aprobados y sus DTO/respuestas, **sin marcarlos disponibles** en Backend 1.0.0.
2. Los puntos de extensión futuros en `lib/platform_api/auth_api.dart`, providers Auth, router, pantallas de registro/activación y navegación.
3. El orden de dependencia: PR Backend probado → migración/release controlado deshabilitado → adaptación Flutter → E2E extendida → autorización para habilitar flag → pruebas remoto autorizadas.
4. Casos de prueba futuros: ADMIN crea tenant/OWNER de manera atómica; enlace 24 h; canje seguro; desafío 15 min; contraseña definitiva; `LOGIN_REQUIRED`; login normal; reenvío invalida generación; fallos de correo; rate limit; SQL y SEC-01.
5. Límites: no pagos, cuota MEMBER, membresías comerciales, auto-registro, PEM, OAuth ni Prospector real. El formulario de usuario V1 existente no se convierte tácitamente en onboarding.

**Prohibido en este carril:** importar el YAML ADR-006 como si fuera Swagger implementado, introducir rutas activas en UI, inventar mocks productivos de activación, modificar contratos Backend o resolver PRs de Ángel sin recibir su entrega.

---

## E12. Cierre de fase, reporte de QA y handoff

### E12.1. Matriz de gates

| Gate | Qué registrar | Autoridad de aceptación |
|---|---|---|
| `G0` | Repositorios, SHAs, branch, baseline, contraste objetivo/implementado, inventario | Codex prepara; owner revisa discrepancias |
| `G1` | Flutter analyze/test/build/CI en SHA actual, resultados exactos | Owner revisa |
| `G2` | FE-01–FE-03, paridad, permisos y 503 Jobs | Owner revisa |
| `G3` | `UI_TO_DB` local con UI, HTTP, aserción SQL, relectura, cleanup | Owner revisa |
| `G4` | Remoto autorizado con URL, CORS, SHA y límites explícitos | Owner decide si puede declararse productivo |
| `G5` | Commits/PR autorizado, diff, matriz, instrucciones QA/rollback, deuda | Owner decide merge |
| `G6` | **Futuro:** QA Backend ADR-006 + Flutter nuevo + E2E extendida | Fuera de este carril; solo owner |

**Estados:** `PASS`, `FAIL`, `BLOCKED`, `NOT RUN`. Un gate `BLOCKED`/`NOT RUN` no autoriza «100%» ni equivale a éxito. P0/P1 abiertos impiden aceptar el alcance afectado; P2 requiere decisión explícita de diferimiento. Riesgo residual JWT snapshot de hasta ocho horas debe seguir documentado aun si pasa la suite.

### E12.2. Artefactos de la carpeta `evidencias/`

Producir conforme a la pieza 04 del harness, como mínimo:

```text
baseline.json
preflight.md
matriz-contrato-1a1.md
matriz-e2e.md
hallazgos.md
test-baseline.md
test-resultados.md
e2e-local-resumen.md
remoto-resumen.md
matriz-integracion-adr006.md
handoff-qa.md
```

Los nombres son **plantilla de resultados**, no archivos que deban existir antes de ejecutar. Logs, HAR, vídeo y screenshots crudos que contengan credenciales deben permanecer fuera del repo y no adjuntarse; incorporar solo versiones sanitizadas con trazabilidad suficiente. La carpeta comienza vacía de evidencia salvo su único `README.md` declarativo.

### E12.3. Formato obligatorio de respuesta por fase

```text
FASE / GATE:
REPOSITORIO / RAMA / SHA VERIFICADOS:
ALCANCE REALMENTE EJECUTADO:
CAMBIOS Y ARCHIVOS AFECTADOS:
CONTRATO UTILIZADO (OBJETIVO / IMPLEMENTADO / RUNTIME):
PRUEBAS (COMANDO SANITIZADO / EXIT CODE / TOTAL / ESTADO):
E2E LOCAL (CASE IDs / NAVEGADOR / HTTP / POSTGRES / RELECTURA / CLEANUP):
REMOTO (URL / SHAs / AUTORIZACIÓN / RESULTADO / LÍMITES):
EVIDENCIAS (RUTAS RELATIVAS):
HALLAZGOS, BLOQUEOS Y DEUDA:
DECISIÓN O APROBACIÓN SOLICITADA AL OWNER:
SIGUIENTE TAREA SEGURA:
```

### E12.4. Checklist final del agente

- [ ] Trabajé únicamente sobre checkout/ramas verificados y respeté cambios ajenos.
- [ ] Leí y apliqué los documentos 01, 02 y 03 y las reglas del proyecto.
- [ ] Registré SHA, estado Git, versiones del contrato y disponibilidad de Jobs.
- [ ] FE-01–FE-03 tienen reproducción, corrección mínima y pruebas antes/después, o bloqueo documentado.
- [ ] El Core está contrastado por operación, rol y tenant, sin inventar capacidades.
- [ ] Pruebas unitarias/widget/contrato y builds se ejecutaron o quedaron con estado verificable.
- [ ] P2C ejecutó contra su stack PostgreSQL correcto, con limpieza de ensayo.
- [ ] La suite `UI_TO_DB` usa Flutter real, NestJS real, PostgreSQL local, relectura y limpieza verificadas.
- [ ] El remoto se probó solo dentro del alcance autorizado, sin atribuir SHA por suposición.
- [ ] Documenté riesgos de JWT snapshot, Jobs 503, FE-04–FE-08 y la frontera ADR-006.
- [ ] No modifiqué Backend, migraciones, ADRs aprobados, flags productivos ni contratos Backend.
- [ ] No hice merges, despliegues o push/PR fuera de permisos expresos.
- [ ] Evidencias sanitizadas y handoff permiten a Carlos reproducir y decidir el merge.

**Condición de entrega:** se publica una **propuesta revisable de frontend Core 1.0.0 estable**, jamás una autodeclaración de QA final. Codex concluye en su rama con sus pruebas, hallazgos, artefactos y PR si está autorizado. Carlos conserva la decisión final de aceptación, integración y despliegue. Después, Ángel podrá basar su adaptación Flutter ADR-006 en el commit Core que Carlos haya aprobado.

---

## E13. Criterio último: ejecución segura y evidencia comprobable

Ningún paso debe entenderse como una obligación de **forzar** ejecución cuando faltan permisos o infraestructura. La autonomía esperada consiste en terminar todo lo que sea seguro, no invadir otras ramas o entornos. No ocultar fallos, no confundir contratos futuros con endpoints existentes, no contabilizar mocks como E2E y no afirmar validación productiva sin URL, versión y pruebas reales.

**Estado de entrega:** documentos 01, 02 y 03 aprobados expresamente por el owner, con una aclaración de cobertura E2E para creación de usuarios V1 incorporada al entregar el ZIP. Este harness es una instrucción de trabajo, no una evidencia de implementación, pruebas, merge ni despliegue realizados.
