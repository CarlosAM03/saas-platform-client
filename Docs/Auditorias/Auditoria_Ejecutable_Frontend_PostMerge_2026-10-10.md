# Auditoría ejecutable frontend post merge — 2026-10-10

Documento rector: `Auditoria_Profunda_Frontend_SaaS_2026-10-10.md`. Esta auditoría registra ejecución local y contrasta sus hipótesis; no modifica la implementación. **Veredicto: BASELINE REQUIRES REPAIR BEFORE FEATURE DEVELOPMENT.**

## A. Baseline auditado

| Elemento | Evidencia |
|---|---|
| Flutter | `dev` @ `90e38656e1aafd3c81e8d639e6b17f973f81aff8`, igual al corte estático. `origin/dev` apuntaba al mismo commit. |
| Backend | `dev` @ `ab53272f531d15e6c4dcc9df8c1d6dca8601e87a`, igual al corte estático. |
| Estado inicial | `git status --short --branch`: sólo `?? Docs/Auditorias/Auditoria_Profunda_Frontend_SaaS_2026-10-10.md`, archivo preexistente que se preservó. |
| Historial Flutter | `90e3865` merge `origin/main` en `dev`; `a663003` Beta; `3ed1860` dashboard cards; `4661b3a` merge; `9844eae` plan; `dd9e95b` docs baseline; `f99d409` foundation; `c9408d0` lock; `75b4e94` foundation inicial. |
| Entorno | Windows 11 26H2, PowerShell 7.6.5, Docker Compose con PostgreSQL 16; navegador Edge 154. Chrome y Android SDK ausentes. |
| SDK | Flutter 3.47.5 stable, Dart 3.13.4. SDK local en `.flutter-sdk`. |

`git status` sin elevación devolvió `fatal: this operation must be run in a work tree` por acceso al índice bajo el sandbox; la misma consulta con acceso al checkout devolvió el baseline anterior. Los comandos Flutter requirieron añadir `System32`, PowerShell y Git al `PATH` del proceso para que el SDK encontrase `where.exe`, PowerShell y Git. No se cambió la configuración permanente del equipo.

## B. Resultado de comandos

| Comando | Resultado | Evidencia | Observaciones |
|---|---|---|---|
| `git status`, rama, SHA, `git log -10` | PASS | `dev`, `90e3865`, único archivo no rastreado previo indicado arriba | No hubo diferencia de commit con el documento rector. |
| `flutter --version` | PASS | 3.47.5, Dart 3.13.4 | SDK local. |
| `dart --version` | PASS | 3.13.4 | — |
| `flutter doctor -v` | WARN | Windows, Visual Studio y Edge disponibles; Android SDK y Chrome ausentes | Restricción local para Android/Chrome, no error de Dart. También advierte que Flutter/Dart no están en PATH permanente. |
| `flutter pub get` | PASS | Dependencias resueltas; 4 transitivas cambiaron en `pubspec.lock` | También añadió exclusiones a `analysis_options.yaml`. Ambos cambios automáticos se revirtieron al terminar; no son parte del entregable. |
| `dart run build_runner build --delete-conflicting-outputs` | PASS con workaround | 2 outputs generados en 78 s | En ruta original falló al crear `.dart_tool/pub/bin/build_runner/tmp` (Windows, ruta larga). Ejecutado desde unidad temporal `S:`. La versión instalada ignora la opción `--delete-conflicting-outputs`. Warnings: analyzer 3.12 frente a SDK 3.13 y constraints de `json_annotation`/SDK. |
| `flutter analyze` | PASS con workaround | `No issues found!` desde `S:` | En ruta larga falló antes del análisis al recorrer una ruta interna de `.flutter-sdk`; `dart analyze lib test` también dio `No issues found!`. |
| `flutter test` | FAIL | 15 PASS, 1 FAIL: `logout clears local session even if backend fails`, `test/foundation_auth_test.dart:186`; excepción desde `auth_state.dart:116` | Confirma FND-01. No se alteraron tests. |
| `flutter build web` | PASS con workaround | `√ Built S:\build\web` | En ruta original falló al listar `.dart_tool/flutter_build/...`. En `S:` con `--no-wasm-dry-run` pasó. Warning de fuente Cupertino no incluida. La primera ejecución avisó además que `flutter_secure_storage_web` no soporta Wasm; el build JS sí pasó. |
| `docker compose up --build -d`; `docker compose ps` | PASS | API y PostgreSQL healthy; `db-init` completó | Se usó modo detached para continuar las pruebas. |
| `GET /api/v1/health/ready` y `/api/docs` | PASS | Ambos HTTP 200 | Backend local `localhost:3000`. |
| `flutter run -d edge --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000` | PASS con workaround | Edge sirvió la app en `localhost:4200` y permitió login/reload | Chrome no estaba instalado. En ruta larga falló compilación de shaders del SDK (`flutter/runtime_effect.glsl` no encontrado); desde unidades temporales `S:` (checkout) y `T:` (SDK) arrancó. |

La ruta extensa del workspace es una **limitación de configuración local**: no se atribuye al código Flutter. La prueba web efectiva usó Edge, no Chrome. La aplicación se compiló para JavaScript; no se verificó Wasm ni Android.

## C. Hallazgos del documento rector

| ID | Estado | Evidencia ejecutable o límite |
|---|---|---|
| FND-01 | **CONFIRMADO** | Test falla; en Edge `POST /auth/logout` fue 200, la ruta permaneció autenticada y tras reload `GET /auth/me` fue 200 para el mismo OWNER. JWT no se eliminó. |
| FND-02 | **PARCIAL** | Router y pantalla forman un ciclo `/session-expired` → intento `/login` → redirect de vuelta; no se provocó 401 en una sesión web real. El test cubre redirect, no recuperación interactiva. |
| FND-03 | **CONFIRMADO** | `DevUser.matches` y `DevUser.isToken` siguen dentro de `AuthController`; login/restore pueden omitir HTTP para el usuario ficticio. No se usó en la prueba integrada. |
| FND-04 | **CONFIRMADO** | CTA `Regístrate` visible en Login. `register_dialog.dart` sólo valida localmente y muestra snackbar; OpenAPI no ofrece self-register. |
| FND-05 | **CONFIRMADO** | Login muestra el mismo `No se pudo iniciar sesión.` para error; el primer submit vacío produjo HTTP 400 y el mismo mensaje. Backend produjo 401 para contraseña inválida en prueba HTTP. |
| NET-01 | **CONFIRMADO** | En la UI observada, sólo login, restore y logout solicitaron API. Campaigns, Prospects, Admin y Generate mostraron placeholders; Dashboard mostró mocks. |
| NET-02 | **CONFIRMADO como limitación de implementación** | Backend devuelve `data: []` para `/tenants` y arrays con `meta` para `/users`, `/campaigns`, `/prospects`, `/prospecting-jobs`; `unwrapData()` convierte `data` a `Map`. No existe feature que lo invoque para listas aún. |
| NET-03 | **CONFIRMADO por código/contrato** | `ApiClient._mapError` construye `ApiException` con `details: body` y no extrae `error.code`; respuesta 403/503 backend conserva wrapper de error. No hay UI de feature que explote el `code`. |
| NET-04 | **CONFIRMADO por código/contrato** | `ApiClient.delete(String path)` carece de query; contrato permite `DELETE /campaigns/{id}?permanent=true`. No se efectuó DELETE destructivo. |
| INT-01 | **CONFIRMADO** | Compose levantó API/PostgreSQL healthy; readiness y Swagger 200; seed devolvió 2 tenants, 6 campañas y 36 prospectos en total (3/18 por tenant). |
| INT-02 | **REFUTADO para el comando fijado; riesgo documental vigente** | Preflight `OPTIONS /auth/login` con origin `localhost:4200` devolvió 204 y `Access-Control-Allow-Origin: http://localhost:4200`; login real desde navegador pasó. El comando sin puerto del README sigue pudiendo usar otro origin. |
| INT-03 | **PARCIAL** | Manifest principal no declara INTERNET; `doctor` no halló Android SDK. No se ejecutó Android. |
| CMP-01/02/03 | **CONFIRMADO por código + UI** | `Campaign` omite `createdBy`, no serializa JSON; backend lo emite. `CampaignCard` importa `dashboard_mock_data.dart`; el CTA real navega a `/campaigns` placeholder, no al detalle. |
| DSH-01/02/03 | **CONFIRMADO** | UI mostró `Campaña Verano 2026`, `Campaña B2B`, `Lanzamiento Otoño` con 1,240/530/860 prospectos, contactados y conversión; backend Norte devuelve `Campaña 1/2/3 Demo Norte`. El comentario `DTO real cuando exista` está obsoleto. No se vio tenant ni resumen contractual. |
| TNT-01 | **CONFIRMADO por backend + código; UI ADMIN no recorrida** | ADMIN inicia sin tenant y sin memberships (`AuthContext.tenants=[]`), pero `GET /tenants` devuelve dos. `SelectTenantPage` sólo lee `AuthContext.tenants`; el router envía al ADMIN sin tenant al Dashboard. Selección ADMIN → Sur por HTTP emitió JWT nuevo. |
| RBA-01/02/03 | **CONFIRMADO / PARCIAL** | Drawer mostró Administración a OWNER; `_requiresTenant` omite Dashboard y Admin. Mezcla de scopes de `/admin` es riesgo de diseño, aún placeholder y por ello no se pudo verificar operación real. |
| UI-01/02/03/04 | **CONFIRMADO por UI/código** | Dashboard sin identidad/tenant/resumen; badge `Completada`; colores hardcoded; Campaigns detalle/CRUD ausentes. UI-02 es drift visual, no contrato API. |
| REP-01/02/03 | **CONFIRMADO por repositorio** | Registrants generados están versionados; README enlaza la ruta anterior de lineamientos y reconoce placeholders. `pub get` reescribió registrants por formato de línea, y se revirtieron. |

La evidencia de código complementa la ejecución donde aún no existe un flujo de UI que pueda ejercer el contrato. `CONFIRMADO` en esas filas no significa que se haya ejecutado un E2E de la feature.

## D. Hallazgos nuevos

| ID | Severidad / clase | Componente | Descripción y evidencia | Impacto | Recomendación |
|---|---|---|---|---|---|
| ENV-01 | P1 / configuración local | Toolchain Windows | Ruta del workspace impidió `build_runner`, `flutter analyze`, `flutter build web` y compilación debug de shaders. Con unidades temporales cortas los cuatro pasaron. | El pipeline local no es reproducible usando el path largo actual. | Documentar checkout/SDK en rutas cortas para Windows; fijar CI en rutas controladas. No clasificar como error de app. |
| QA-01 | P2 / deuda técnica | Generación | `build_runner` ignoró `--delete-conflicting-outputs`; avisó que analyzer soporta lenguaje hasta 3.12 con Dart 3.13 y que constraints de `json_annotation`/SDK son demasiado amplios. | La generación pasa hoy, pero la receta y compatibilidad de paquetes no están fijadas al SDK de uso. | Actualizar receta y versiones de forma coordinada antes del CI. |
| PRF-01 | P2 / error de presentación | Profile | En sesión OWNER, Profile mostró `Rol de plataforma: tenant-scoped`, sin mostrar `OWNER` ni `Demo Norte`, aunque el backend sí conoce membership y tenant. | Puede hacer creer que el rol tenant está ausente o no es visible. | Mostrar rol del tenant y organización desde contexto/contrato real; distinguirlo de platformRole ADMIN. |

No se registran como hallazgos nuevos los placeholders, el CTA de detalle que va al placeholder ni el logout: ya están contemplados por el documento rector.

## E. Matriz funcional real

| Feature | UI observada | Backend conectado desde Flutter | Datos reales en UI | CRUD | Tests | Estado |
|---|---|---|---|---|---|---|
| Dashboard | Cards responsive, loading/success visible | No | No; tres campañas y métricas ficticias | No | Ninguno de feature | Mock funcional sólo como prototipo visual |
| Campaigns | `Campañas — placeholder Fase 5`; CTA dashboard llega aquí | No | No; backend sí lista 3 por tenant | No | Ninguno de feature | Placeholder |
| Prospects | `Prospectos — placeholder Fase 5` | No | No; backend sí lista 18 por tenant | No | Ninguno de feature | Placeholder |
| Admin / Users / Tenants | `Administración — placeholder Fase 5` | No | No | No | Ninguno de feature | Placeholder; entrada visible a OWNER |
| Profile | Nombre, email, platformRole o `tenant-scoped` | Indirectamente vía AuthContext de login/me | Identidad sí; rol tenant/organización no | No | Ninguno de feature | Parcial |
| Prospecting Jobs / Generate | `Generar prospectos — placeholder Fase 5` | No | No; backend sí lista Jobs históricos | No | Ninguno de feature | Placeholder con etiqueta engañosa para capacidad pendiente |
| Auth Foundation | Login, restore, rutas y drawer | Sí | Sí | Login/select/logout | 15 PASS, 1 FAIL en suite total | Parcial; logout bloqueante |

El Dashboard mostró success mock. No se forzaron empty/error en UI; existen ramas de presentación, pero no se consideran validadas. Las otras features carecen de esos estados de datos porque son placeholders.

## F. Matriz de integración

| Flutter → endpoint | HTTP | Resultado observado | Contrato correcto |
|---|---:|---|---|
| Login OWNER Norte → `POST /auth/login` | 200 | Dashboard; token almacenado. Backend registró User-Agent de navegador. | Sí, `success/data` AuthContext. |
| Login con password inválida → `POST /auth/login` (prueba HTTP) | 401 | Error backend; UI sólo mensaje genérico (submit vacío produjo 400). | Sí para backend; UX insuficiente. |
| Reload OWNER → `GET /auth/me` | 200 | Dashboard restaurado; Bearer confirmado por `userId`/`tenantId` en log del backend. | Sí. |
| Logout OWNER → `POST /auth/logout` | 200 | Backend respondió, Flutter retuvo sesión y JWT; nuevo reload → `/auth/me` 200. | Respuesta backend sí; efecto local Flutter no. |
| ADMIN sin tenant → `GET /tenants` (prueba HTTP) | 200 | 2 tenants; `AuthContext.tenants=[]`. Flutter no hace discovery. | Backend sí; flujo UI incompleto. |
| ADMIN → `POST /auth/select-tenant` (prueba HTTP) | 200 | Tenant Sur y JWT distinto; `/campaigns` pasa de 403 a 200. | Sí. |
| OWNER Norte → `POST /auth/select-tenant` Sur (prueba HTTP) | 403 | Aislamiento efectivo en backend. | Sí. |
| MEMBER Norte → `POST /users` (prueba HTTP) | 403 | Backend bloquea operación; Flutter no ofrece CRUD todavía. | Sí. |
| Bearer inválido → `GET /auth/me` (prueba HTTP) | 401 | Backend rechaza. Interceptor Flutter cubierto por test para limpiar token en 401 autenticado. | Sí; recuperación UI `sessionExpired` pendiente. |
| Backend → listas `GET /users`, `/campaigns`, `/prospects`, `/prospecting-jobs` | 200 | `data` array + `meta(page,limit,total,totalPages)`; 2, 3, 18, 5 elementos para tenant Norte. Flutter no solicita estas rutas. | Sí backend; parser Flutter actual no sirve para array. |
| Backend → `GET /tenants` | 200 | `data` array sin meta. Flutter no lo solicita. | Sí. |
| Backend → Jobs `cancel`, `persist`, `export` | 503 | Integración Prospector pendiente; no hubo cambios de datos. | Sí. `create` no verificado a 503: el payload de prueba devolvió 400 por validación previa. |
| Browser CORS → `OPTIONS /auth/login` | 204 | Origin 4200 permitido y login real completado. | Sí. |

Las filas marcadas *prueba HTTP* ejercieron el backend real, **no** una request originada por Flutter. La comparación de datos con PostgreSQL se hizo mediante API respaldada por PostgreSQL y seed documentado; no se ejecutó una consulta SQL directa. Las respuestas de campañas reales (`Campaña 1/2/3 Demo Norte`) contradicen las cards ficticias de Dashboard.

## G. Resultados por rol

| Rol | Backend real | Flutter |
|---|---|---|
| ADMIN | Login 200 sin tenant; `/tenants` devuelve Norte y Sur; Campaigns 403 hasta seleccionar tenant; selección Sur reemplaza JWT y habilita Campaigns/Users/Jobs. | UI no recorrida como ADMIN en esta sesión; el código redirige a Dashboard sin tenant y `SelectTenantPage` usa memberships vacíos. No se atribuye validación E2E. |
| OWNER | Norte y Sur inician con su propio tenant; Norte ve 3 campañas/18 prospectos/5 Jobs; selección Sur desde Norte da 403. | OWNER Norte inicia, restaura y ve mocks; navega por placeholders, Profile y Admin. Logout no termina sesión. |
| MEMBER | Norte consulta Users y Campaigns; POST Users devuelve 403. | UI no recorrida como MEMBER; drawer contiene Admin sin condición de rol, comprobado en código. |

El backend aísla datos por tenant. Flutter todavía no ofrece cambio de tenant ni pantallas de negocio para demostrar aislamiento visual. Tampoco se encontró usuario demo multi-tenant; se usaron dos tenants con cuentas separadas y ADMIN global para la selección.

## H. Foundation: estado real

- **Auth/JWT:** login y restauración reales funcionan en Web, incluido Bearer en `/auth/me`. Selección de tenant funciona por API con nuevo JWT; falta recorrido UI ADMIN global. Logout no limpia token ni AuthState, incluso con backend 200; con backend caído el test falla por excepción.
- **Routing:** `/dashboard` acepta ADMIN sin tenant y depende hoy de mocks. `/session-expired` carece de transición a `unauthenticated`; no se ejecutó el ciclo completo en browser. CTA de card llega a placeholder general, no a detalle.
- **Tenant/roles:** backend aplica 403; la UI no descubre tenants ADMIN ni ajusta visibilidad de Admin por rol. Profile omite tenant y rol tenant.
- **Errores:** Login usa mensaje genérico. `ApiClient` distingue status básicos, pero descarta `error.code` y `error.details` estructurados. El 403 no debe cerrar sesión; test unitario lo confirma, sin flujo de feature UI disponible.
- **Networking:** CORS en 4200 funciona. `unwrapData` sólo permite object; arrays y paginación requieren parser. `delete` no acepta query. Android release/networking no verificado, falta Android SDK y manifest principal sin INTERNET.
- **Runtime:** no hubo red screen ni excepción visible en el flujo OWNER con backend sano. La primera prueba de formulario vacío dio HTTP 400 y mensaje genérico. No hubo requests de negocio desde widgets/placeholders. Logs del navegador sólo mostraron bootstrap e inicio; logs NestJS confirmaron login, `/auth/me` y logout. No se inspeccionó el contenido de secure storage ni se imprimieron JWT; persistencia se comprobó por `/auth/me` tras reload.

## I. Estado de la supuesta beta

**No cumple la Definition of Done de beta funcional.** De siete áreas del primer avance (Auth, Campaigns, Prospects, Users/Tenants/Admin, Profile, Dashboard y Jobs read-only), sólo Auth efectúa requests reales desde Flutter, y su logout falla. Profile muestra datos del contexto de Auth de forma parcial. Las cinco áreas de negocio restantes son mocks o placeholders. La calidad de compilación/análisis web pasa con workaround local, pero la suite tiene 1 fallo y no hay pruebas de features. No se asigna un porcentaje numérico porque contar pantallas renderizadas no mide los flujos exigidos por la Definition of Done.

## J. Bloqueadores antes de hardening y desarrollo

| Prioridad | Bloqueador |
|---|---|
| P0 | Restaurar logout local incondicional y cerrar regresión de test; no presentar Dashboard ficticio como datos reales de beta. |
| P0 | Establecer baseline de Foundation con `flutter analyze`, `flutter test`, `flutter build web` reproducibles en CI y entorno Windows documentado. |
| P1 | Resolver `sessionExpired`, DevUser y self-register; parser genérico de `success/data/meta` y error estructurado; discovery ADMIN y rutas tenant-aware. |
| P1 | Implementar Campaigns, Prospects, Users/Tenants/Admin y Jobs read-only contra API real, con permisos y estados completos. |
| P2 | Completar Profile, visibilidad de navegación por rol, `delete` con query, Android networking, warnings de generación, docs y registrants versionados. |

## K. Siguiente fase recomendada

1. Reparar Foundation bajo ownership de Carlos: logout, sesión expirada, Auth real sin bypass, registro público, errores/parsing y contexto tenant; añadir pruebas que ejerzan esos flujos completos.
2. Fijar toolchain y comandos CI; repetir analyze/test/build desde checkout corto o runner con rutas controladas.
3. Conectar Campaigns y Prospects; luego Users/Tenants/Admin, Profile y Dashboard con datos contractuales; finalmente Jobs read-only. Cada feature debe probar DTO, permisos, paginación y estados loading/empty/error/success con backend demo.
4. Repetir E2E Web por ADMIN, OWNER y MEMBER en dos tenants, incluyendo 401/403/404/409, backend caído, logout/reload y consola. Verificar SQL directamente si se requiere prueba independiente de PostgreSQL.

**Veredicto: BASELINE REQUIRES REPAIR BEFORE FEATURE DEVELOPMENT.**

### Higiene de esta auditoría

No se cambiaron código, tests, ramas ni commits. Los cambios automáticos de `pub get`/Flutter en `pubspec.lock`, `analysis_options.yaml` y registrants se revirtieron. Se preservó el documento rector preexistente sin seguimiento. Los directorios ignorados `.dart_tool`/`build` contienen artefactos de ejecución. El informe es el único archivo nuevo intencional.
