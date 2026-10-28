# Auditoría de reconciliación integral de Flutter dev

## A. Identificación y alcance

- Inicio y cierre: **2026-10-26**, zona **America/Tijuana**. Cierre documental: 22:23–22:30 local.
- Repositorio: https://github.com/CarlosAM03/saas-platform-client.
- Rama intervenida: **fix/f5-foundation**, ya existente. No se creó otra rama ni worktree.
- HEAD encontrado al inicio: dev `c7dee664cbdda85d38d896ce3103d8fc6319f0af`, árbol limpio, sin archivos no rastreados ni operación Git pendiente.
- Punta inicial de fix/f5-foundation: `dd9e95b2a4e71afc98662ed4250312a615b7915a`.
- Referencia origin/main: `a85a99678101b3f5562f66d7dd1c1c454b1d20cb`.
- Referencia origin/dev: `c7dee664cbdda85d38d896ce3103d8fc6319f0af`.
- Recuperación contrastada: `9dd9b577db667c31ad75b9faec158bf74a21ad90`; aportaciones `fe9e32f` y `e225e6a`.
- SHA final de la revisión auditada, antes de añadir este informe: **943eb5a7f9b990d29f5f32a9585abd435bba414e**. Código funcional en **8564af9cdebe3745799ee094399db7019c348216** y build/CI en **39ac48b74ceae406d6600a8e905dda04a91e4eb2**.
- El SHA del commit que contiene el informe se obtiene con `git log -1 --format=%H -- Docs/Auditorias/Auditoria_Reconciliacion_Dev_2026-10-26.md`. No se incrusta su propio hash para evitar autorreferencia; la respuesta de entrega identifica ese HEAD final.

Se verificó la raíz mediante git rev-parse, remoto oficial, ramas, HEAD, status, untracked,
worktrees y estado de Git. Se ejecutó git fetch origin. fix/f5-foundation era ancestro de
origin/dev (0 commits exclusivos frente a 28); se cambió a ella y se aplicó exclusivamente
`git merge --ff-only origin/dev`. No hubo reset, descarte de cambios ajenos ni integración
remota. main local permaneció en dd9e95b; dev local permaneció en c7dee66.

El PR [#6](https://github.com/CarlosAM03/saas-platform-client/pull/6) está abierto, con
base main y head dev; no fue modificado ni fusionado. El [run inicial 40438948365](https://github.com/CarlosAM03/saas-platform-client/actions/runs/40438948365)
falló en foundation/build_runner y ambos builds container/production-container. Los
checks posteriores del job foundation y el smoke productivo no llegaron a ejecutarse.
El CI exitoso de 9dd9b57 procede de la referencia histórica aportada: el conector que
filtra ejecuciones por PR no devolvió runs para ese SHA, por lo que no se recertifica aquí.
No se ejecutó CI remoto para los commits nuevos porque no se hizo push.

## B. Diagnóstico con evidencia

### Conflictos incorporados al historial

Los marcadores estaban **versionados en c7dee66**, aunque el índice Git no estaba en
conflicto. Se confirmaron 132 líneas de marcadores en 12 Dart y se encontraron otras
30 en README y web: **162 líneas en 15 archivos**.

| Archivo | Líneas con marcador | Procedencia contrastada |
|---|---:|---|
| lib/core/errors/error_mapper.dart | 3 | Propietario 02985b7; main y 9dd9b57 |
| lib/core/network/api_client.dart | 9 | Propietario 02985b7; mejora válida de comparación JWT en c7dee66 |
| lib/features/admin/presentation/admin_page.dart | 6 | Propietario a110e44; alternativa beta c7dee66 |
| lib/features/auth/presentation/auth_pages.dart | 21 | Propietario 6cb8472; login visual c7dee66 |
| lib/features/auth/state/auth_state.dart | 18 | Hardening propietario 492160f; duplicaciones c7dee66 |
| lib/features/campaigns/presentation/campaigns_page.dart | 3 | CRUD b3bcbdf/95e7092; UI beta c7dee66 |
| lib/features/dashboard/presentation/dashboard_page.dart | 6 | UI histórica André 3ed1860; API tipada fe9e32f/9dd9b57 |
| lib/features/profile/presentation/profile_page.dart | 6 | Propietario 6cb8472; alternativa beta c7dee66 |
| lib/features/prospecting_jobs/presentation/generate_page.dart | 6 | Placeholder propietario 75b4e94; formulario tipado 9dd9b57; beta c7dee66 |
| lib/features/prospects/presentation/prospects_page.dart | 6 | CRUD propietario a110e44; CSV 9dd9b57; alternativa beta c7dee66 |
| lib/routes/app_router.dart | 27 | Scope/guards 95e7092; CSV/Jobs 9dd9b57; router alternativo c7dee66 |
| test/foundation_auth_test.dart | 21 | Hardening propietario 492160f; alternativas de integración c7dee66 |
| README.md | 18 | 95e7092/9dd9b57 y texto beta posterior |
| web/index.html | 9 | Contenedor 372a16d; metadatos beta c7dee66 |
| web/manifest.json | 3 | Contenedor 372a16d; identidad beta c7dee66 |

Se compararon responsabilidades e interfaces de main, 9dd9b57 y c7dee66 usando objetos
Git, log y diffs por archivo. La atribución de la tabla identifica referencias de código;
no adjudica todos los contenidos a la persona del último commit. Foundation, Auth,
red y pruebas de main coinciden con 9dd9b57 en los archivos contrastados; sus diferencias
funcionales de routing son las rutas CSV/Jobs. No se seleccionó automáticamente una mitad.

### Causas y regresiones

1. Los marcadores y las declaraciones anidadas/duplicadas impedían parsear Dart y generar código; esto reproduce el punto de fallo del CI original.
2. La capa dinámica lib/features/workspace/data/platform_repository.dart replicaba consultas, providers de dashboard y permisos ya tipados. Tenía un cálculo de OWNER que no contrastaba tenantId del rol, frente al fail-closed de TenantPermissions original.
3. Había dos estrategias de router y formas de mantener estado. La variante posterior perdía scope por sesión y parte de CRUD manual/rutas existentes.
4. Las resoluciones propuestas de red perdían downloadBytes, timeouts send/receive y detalles contractuales de error. Se conservaron las capacidades del propietario y la mejora válida de c7dee66 para JWT rotado.
5. Jobs UI preparado habilitaba operaciones que el Backend oficial rechaza. El texto “configurar Prospector” tampoco reflejaba que assertAvailable() está deshabilitado por código.
6. La fuente Inter estaba declarada, pero assets no atravesaba la allow-list Docker ni los COPY. Se corrigieron ambos Dockerfiles sin abrir el contexto a secretos.
7. README y OpenAPI mezclaban estado actual y respuestas futuras; la documentación beta negaba altas manuales que el Backend sí permite.
8. La configuración Web necesitaba validar origen y distinguir build-time de runtime; no se atribuyó un ajuste de Project Environment de Vercel al bundle ya compilado.

## C. Matriz de reconciliación

| Módulo | Implementación del propietario conservada | Aportación de André conservada | Código retirado o sustituido | Justificación |
|---|---|---|---|---|
| Foundation/red | ApiClient/Dio, Bearer, timeouts, binario, multipart y errores tipados; 02985b7/main | Comparación del JWT enviado y actual de c7dee66 | Mitades que eliminaban funciones/detalles y marcadores de api_client.dart/error_mapper.dart | Un único cliente contractual; se agregó revisión de sesión y serialización para las carreras restantes |
| Auth/storage | auth_repository.dart, contexto tipado, selección, recuperación, logout y expiración; 492160f/6cb8472 | Login visual, validaciones, mostrar contraseña y bloqueo de acciones | AuthController/selectTenant duplicados, busy como segundo modelo independiente | busy deriva de loading; respuestas antiguas no restauran sesiones; logout no borra un login posterior |
| Permisos | tenant_permissions.dart y rol cuyo tenantId coincide con scope | Visibilidad de acciones y selector de organización | canManageUsersProvider dinámico y membresía genérica | ADMIN/OWNER/MEMBER conforme a controladores; Backend mantiene autoridad |
| Routing | GoRouter único, guards y ScopedFeaturePage de 95e7092 | CSV/Jobs de 9dd9b57, navegación responsiva, organización activa y enlaces filtrados por campaña | Router paralelo y sustitución de rutas CRUD por pantallas beta limitadas | Se reinician providers/formularios al reemplazar sesión; se conserva /organizations como alias al selector |
| Campañas | CampaignsApi, DTO, repositorios/providers, CRUD, prospectos asociados, búsqueda y paginación; b3bcbdf/95e7092 | CampaignCard/estado visual, cuadrícula, filtro explícito de página actual y confirmación de creación | CRUD dinámico y lib/features/campaigns/models/campaign.dart sin consumidores activos | La tarjeta y CampaignStatusBadge usan el DTO canónico; no se inventa filtro Backend |
| Prospectos | Altas ADMIN/OWNER, edición changed-only, FieldUpdate/null, metadata y relación con campaña; a110e44 | Contactos y validaciones de correo/URL, acceso desde campaña e importación | Reemplazo que perdía alta manual y formularios tipados; EntityFormDialog paralelo | Validación/superficie útiles migradas a EntityEditor y pantallas tipadas antes de retirar el archivo |
| CSV | ProspectsApi/DTOs y el cliente multipart contractual | Repositorio/UI/file_picker/plantilla de fe9e32f/e225e6a/9dd9b57 | No se retiró la funcionalidad; se reforzó tamaño, scope y confirmación incierta | Mismos bytes/previewReference/decisions; ninguna reejecución automática ni actualización compartida silenciosa |
| Dashboard | PlatformApi y scope original | DashboardRepository/Data/provider tipados, meta.total, campañas/prospectos/Jobs reales y enlaces | dashboardProvider y agregación dinámicos | Una sola fuente por responsabilidad, sin conversiones ficticias ni datos de otro tenant |
| Jobs | ProspectingJobsApi/DTO/errores de main | Historial, detalle, polling secuencial, formulario/idempotencia y presentación de resultados preparados | Acciones operativas sin Backend compatible y afirmaciones de éxito E2E | Capacidades false por defecto y sin flag de entorno; fixture futura se distingue de API actual |
| Admin/perfil/usuarios | Pantallas y repositorios tipados 6cb8472/a110e44, permisos, creación/desactivación admitidas | Tema Inter, navegación y formularios con superficies | Formularios y consultas de PlatformRepository | Se preservan operaciones compatibles sin debilitar permisos ni introducir endpoints |
| Assets/web/CI | Etapas Nginx, cabeceras, fallback, versiones y checksum Docker; 372a16d | Inter.ttf/OFL e identidad web c7dee66 | Marcadores HTML/JSON y contexto sin assets | Inter y licencia llegan al build; secretos/caches permanecen excluidos |
| Tests | Todos los archivos de cobertura existentes | Casos beta y de funcionalidades pendientes, migrados a APIs tipadas | Acoplamiento de tests al repositorio dinámico | Se añadieron regresiones sin borrar archivos de tests ni simular disponibilidad productiva |

Antes de retirar PlatformRepository, el modelo Campaign anterior y entity_form.dart
se migraron sus consumidores y capacidades útiles; se comprobó ausencia de referencias.
Se mantienen una sola declaración de AuthController, dashboardProvider y appRouterProvider.
Los ADR-004/005 fueron revisados y conservados; no se reescribió su historia ni se adoptó
una nueva decisión sobre Service, Engine, cuotas, durabilidad o infraestructura.

## D. Cambios y protecciones verificadas

- SecureTokenStorage coordina operaciones de token. ApiClient captura la revisión antes de despachar, evita adjuntar un JWT nuevo a una petición anterior y sólo invalida el Bearer/revisión vigente. Revalida también después de una eliminación asíncrona del token.
- AuthController usa una generación de operación; login, restore, cambio de tenant y logout atrasados no repueblan el contexto. La expiración limpia el estado y la limpieza pendiente no borra otra sesión. Se conservan los errores recuperables y el logout local aun ante fallo remoto.
- Providers conservan sessionScopeProvider; la UI no usa valores anteriores de permisos/organizaciones mientras se recarga. El árbol de formularios queda bajo scope. Los tests ejercitan futuros tardíos de campañas, dashboard y CSV.
- CSV valida 5*1024*1024 bytes tanto declarados como efectivos. Preview/confirm usan el mismo ApiUploadFile inmutable; confirmación expirada/409 obliga otra preview. Ante respuesta incierta se ofrece revisar la campaña y se bloquea nueva preview hasta revisión manual.
- El formulario preparado de Jobs calcula firma con el payload tipado normalizado. Una respuesta perdida conserva clave y payload; rechazo definitivo reinicia la clave. Ninguna acción se activa por configurar una URL o por obtener resultsAvailable de una fixture.
- Los repositorios productivos sólo consumen PlatformApi/NestJS. No se añadieron mocks, métricas sintéticas, credenciales, secretos, conexiones Python directas ni autorización por tenantId libre.
- CI conserva generación, análisis, tests, Web y ambos contenedores; agrega rechazo temprano de marcadores y compila con un origen HTTPS explícito de prueba. No se omitieron checks para resolver fallos.
- pubspec conserva Inter y su licencia. Se alinearon mínimos SDK >=3.8 y json_annotation ^4.12 con los requisitos del generador ya resuelto. No se cambió Flutter 3.47.5 ni se actualizó indiscriminadamente la toolchain. pub get ajustó los cuatro pins de flutter_test/SDK: matcher 0.12.20, meta 1.19.0, test_api 0.7.12 y vector_math 2.4.4. Se mantuvo el override preexistente path_provider_foundation 2.5.1.

## E. Matriz contractual actual

Fuentes oficiales verificadas mediante remotos y git ls-remote, sin modificarlas:
Backend main **3a3309398458ab333d7b00f16e9c2df6a09ef734**, dev
**967044e2dc7d10ea91d7d78a86e1ea6fe2accd1a**; Service main
**566bbbe67a59a0fda307ea7d8c5f6bf46fd93aab**; Engine main
**70f6081688db5c5bc5ea612f5fabd5724aab0b20**.
Service local está en **69c54a15601d238638610d0a5c08af46e3da7f14**; su src/Dockerfile/
pyproject no difieren de origin/main. Backend local está en dev 967044e2.

| Funcionalidad | Flutter | Backend actual | Service actual | Resultado |
|---|---|---|---|---|
| Login/me/select-tenant/logout | Cliente tipado y pantallas | Implementados | No interviene | Unit/contratos aprobados; sin E2E |
| Tenants/usuarios y permisos | CRUD admitido y guards | ADMIN global; OWNER/MEMBER por contexto | No interviene | UI conforme a código; autorización real sólo servidor |
| Campañas | CRUD/estados/archivo/borrado autorizado y asociación | Implementados | No interviene | Conservado; sin E2E |
| Prospectos manuales/edición | DTOs y campos opcionales/null | Implementados; alta ADMIN/OWNER | No interviene | Conservado; sin endpoint de borrado inventado |
| POST prospects/import/preview | Multipart file + campaignId; sin escritura | Implementado en dev; 5 MiB, filas/clasificación y referencia firmada | No interviene | Integrado y probado con fixtures; main no contiene esta implementación CSV |
| POST prospects/import/confirm | file + campaignId + previewReference + decisions JSON textual | Implementado en dev, revalidación/transacción; no idempotencia durable | No interviene | Confirmación explícita, advertencia compartidos y revisión de respuesta incierta |
| Dashboard | meta.total y registros de APIs existentes | Conteos por listados, sin endpoint/métricas inventadas | No interviene | Implementado y probado; limpieza por scope |
| GET prospecting-jobs y /{id} | Historial/detalle/polling 4 s | Consulta registros, resultsAvailable=false/results=null/progress=null | No HTTP de lectura pública de Jobs | Operativo como cliente de lectura; no simula scraping |
| POST prospecting-jobs | Formulario y clave preparados; acción deshabilitada | 503 por assertAvailable(), sin asignar Job | POST /api/v1/prospecting/jobs existe, pero no integrado por NestJS | Pendiente Backend; no E2E |
| POST /{id}/cancel | Cliente preparado; deshabilitado | 503 | Sin cancelación HTTP pública | Pendiente Backend/Service |
| POST /{id}/persist | Cliente preparado; deshabilitado | 503 | Sin capacidad HTTP integrada | Pendiente Backend |
| GET /{id}/export | Binario tipado preparado; deshabilitado | 503 | Adaptador Python interno; sin exportación HTTP pública | Pendiente Backend/Service |
| Callback interno /events | Nunca se invoca desde Flutter | Guard/DTO y 503 | Callback autenticado, sin entrega durable garantizada | Pendiente integración; sin secretos en Flutter |

OpenAPI describe las respuestas actuales bajo responses. Los éxitos previstos de Jobs
se conservan explícitamente en **x-target-responses** y las pruebas de parsers futuros
los validan como tales. No se alteró Backend para justificar respuestas del cliente.
Configurar PROSPECTOR_SERVICE_URL/API_KEY no activa su adaptador deshabilitado por código.

El reinicio del scraping debe mostrarse como fallo y repetirse manualmente; no se añadió
reanudación. Bloquear nuevas búsquedas al agotar cuota gratuita requiere soporte real de
Backend/Service. La generación actualmente deshabilitada no anuncia cuotas ni escalado pagado.

## F. Validación ejecutada

SDK del workspace: **Flutter 3.47.5**, framework **6a19cca564**, **Dart 3.13.4**.
Se usaron rutas cortas Q: para SDK/proyecto; C:\w es una junction preexistente conservada.
No se modificaron Developer Mode, configuración global de Git ni versiones de Flutter.

| Comando/comprobación | Resultado efectivo |
|---|---|
| flutter --version | Verificado; versión coincidente con CI/Docker |
| flutter pub get | Primer intento falló por symlinks Windows; repetición desde ruta corta aprobada, exit 0 |
| dart pub get | Aprobado, sin actualización general de dependencias |
| dart run build_runner build --delete-conflicting-outputs | Aprobado, exit 0; 221 s en la repetición completa; dos salidas generadas ignoradas |
| flutter analyze --no-pub, estado final | **Aprobado, exit 0, No issues found**, 6 s |
| flutter test --no-pub --dart-define=BETA_SCREENSHOTS=true --reporter expanded | **252 aprobadas, 0 fallidas**, 25 s en ejecución final |
| flutter build web --release --no-pub --no-wasm-dry-run --dart-define=API_BASE_URL=https://api.example.invalid | **Aprobado, exit 0**, 52.3 s, bundle en build/web |
| dart format sobre Dart modificados | Aplicado; no se impuso formato a código ajeno sin cambios funcionales |
| dart run tool/check_merge_markers.dart y búsqueda global | Aprobado; cero marcadores pendientes |
| Validador de API_BASE_URL | Aceptó origen HTTPS y rechazó /api/v1 con exit no cero, como se esperaba |
| JSON de web/manifest.json y inputs Docker | Aprobados; fuente y licencia existentes, ambos COPY assets presentes |
| docker compose config --quiet | **Aprobado, exit 0** |
| docker compose build | **No completado por entorno**: Docker Desktop Linux Engine no estable/disponible |
| docker build -f Dockerfile.vercel --build-arg API_BASE_URL=https://api.example.invalid -t saas-platform-client:prod . | **No ejecutado hasta compilación**, exit 1 por named pipe del motor ausente |
| Smoke de imagen productiva/Nginx | **No ejecutado**, depende de imagen y motor Docker |
| GET público /api/v1/health/live del dominio ya documentado | HTTP 200; no certifica revisión desplegada, login, CORS ni CSV |
| E2E / P2C real / scraping / Android / iOS | **No ejecutados**; no se levantó Backend ni se utilizaron cuentas/datos reales; Docker no estable |
| git diff --check y límites Git | Aprobados; sin cambios en main/dev ni otros repositorios |

La suite conserva cobertura de Auth/Bearer/logout disponible y caído, expiración,
ADMIN/OWNER/MEMBER, DTO/null/errores 400/401/403/404/409, búsquedas/paginación y CRUD.
Amplía carreras de login/restore/tenant/logout, mismo JWT reutilizado, 401 durante borrado
asíncrono, petición en cola, aislamiento de dashboard/CSV, selección/límite exacto de
archivo y stream, compartidos, expiración/409/confirmación incierta, Jobs 503, paginación,
capacidad deshabilitada, polling lento/terminal/disposal y claves ante incertidumbre/rechazo.
Los casos beta existentes se portaron, incluyendo confirmación y refresco tras archivado.

Se revisaron visualmente seis PNG de fixtures: dashboard desktop/mobile, login mobile,
confirmación y detalle de campaña desktop, y generación deshabilitada mobile. Tamaños
390x844 y 1280x900; sin errores de overflow en las pruebas. Permanecen en build/beta-qa,
ignorados por Git. Los tests móviles de CRUD también comprueban 360x640.

### Fallos intermedios y límites del entorno

- La primera suite reconciliada tuvo 214 aprobadas/5 fallidas. Se corrigieron limpieza de expiración simulada, overflow del encabezado y fixtures/asserts migrados a contratos tipados. Nuevos tests se ajustaron a plugins sin registro nativo y animaciones indeterminadas: no se sustituyeron fallos productivos por éxito simulado.
- Un lint restante de llaves se corrigió; no se cambió el nivel de severidad ni se excluyó código del análisis.
- Con el SDK por la ruta larga/no ASCII, Windows falló al enumerar un directorio del SDK y al resolver flutter/runtime_effect.glsl en impellerc. Se reprodujo y luego se compiló satisfactoriamente usando el SDK por Q:, sin desactivar shaders ni cambiar código para ocultarlo.
- Docker CLI 29.8.1 está instalado. Estaba apagado; se intentó iniciarlo. Un intento alcanzó la descarga del SDK en el builder, pero no produjo imagen. Los intentos definitivos de ambos builds fallaron por `npipe:////./pipe/dockerDesktopLinuxEngine` ausente. No se informan como builds aprobados. El helper oculto terminó y dejó exit 1 para ambos.
- build_runner avisa que --delete-conflicting-outputs fue retirado/ignorado y que analyzer conoce Dart 3.12 frente al SDK 3.13. No impidió generación/análisis/tests. Se mantuvo la toolchain existente para no introducir una actualización ajena.
- Web emite advertencia por familia CupertinoIcons no incluida; no hay uso directo de CupertinoIcons en lib ni error de compilación. Inter y MaterialIcons se incluyeron. No se añadió una dependencia sólo para silenciarla.

Los logs se mantuvieron en el temporal del usuario; builds/caches/registrants/logs y
capturas no forman parte de los commits. Se restauraron exclusivamente los archivos
generados por estas comprobaciones y el formato incidental del script P2C preexistente.

## G. Riesgos y deuda pendiente

### Bloqueantes de una aceptación sin limitaciones

- Ejecutar ambos builds y el smoke productivo con Docker Linux Engine estable. Aquí no existe evidencia de aprobación de contenedores finales.
- Validar Preview/Production con su API_BASE_URL de build, dominio CORS exacto y revisión Backend desplegada. Cambiar variables de runtime no cambia el bundle.
- Ejecutar el recorrido real con cuentas/datos de prueba autorizados y revisiones concretas. Backend main no incluye el CSV de dev; un health 200 no demuestra esa disponibilidad.

### Errores menores y mejoras posteriores

- Advertencias de analyzer/generador y familia CupertinoIcons, sin fallos actuales.
- Mantener y repetir QA visual al ampliar formularios; no reintroducir el repositorio dinámico para acelerar UI.
- El script P2C histórico está preservado, pero no ejecutado; sus escrituras SQL temporales y cleanup no se usaron ni certificaron en esta entrega.

### Dependencias de Backend

- Adaptador real de inicio/cancelación/persistencia/exportación/callbacks de Jobs; contrato y permisos verificables antes de activar capacidades Flutter.
- Política efectiva de rechazo por cuotas gratuitas, si se habilita generación.
- Configuración externa CORS y comprobación de revisión del despliegue; no se alteraron desde Flutter.

### Dependencias de Service y decisiones del propietario

- Estado de Jobs en memoria/single-process, sin recuperación durable ni HA validada.
- Cancelación/exportación HTTP y entrega durable de callbacks pendientes; el adaptador interno no equivale a un endpoint.
- Infraestructura/quotas/browser productivo y políticas pendientes permanecen bajo su ADR/propietario. Flutter no decide escalamiento pagado, reanudación automática ni secretos internos.

## H. Dictamen

**APTO CON LIMITACIONES DOCUMENTADAS**.

El código reconciliado no tiene conflictos pendientes y aprueba generación, análisis,
252 pruebas y Web release. Conserva hardening, arquitectura tipada y aportaciones
compatibles de André. Jobs refleja explícitamente la indisponibilidad real.

No se emite “APTO PARA REVISIÓN Y MERGE” sin reservas: contenedores/smoke, CORS y E2E
siguen sin validación final. Tampoco se autoriza ni ejecuta el merge: el propietario
revisará los commits y decidirá la integración. Las condiciones ambientales incompletas
están identificadas; no se declara el cumplimiento íntegro de toda la aceptación E2E.

## I. Registro Git y revisión controlada

| Commit | Bloque |
|---|---|
| 8564af9cdebe3745799ee094399db7019c348216 | Reconciliación funcional de los conflictos interdependientes, interfaces tipadas, seguridad, CSV/Jobs, contrato y cobertura |
| 39ac48b74ceae406d6600a8e905dda04a91e4eb2 | Assets/licencia, validación del origen, CI y metadatos web |
| 943eb5a7f9b990d29f5f32a9585abd435bba414e | Estado documental, alcance real y configuración externa |
| Commit contenedor de este informe, identificable con git log indicado en A | Evidencia, matrices, limitaciones y dictamen |

Los cambios de código se agruparon porque las pantallas, router, providers y sus tests
estaban en conflicto simultáneamente; separar mitades inválidas habría dejado etapas
incoherentes. El detalle exacto de archivos por bloque se obtiene con git show --stat.
Respecto a dev c7dee66, los archivos intervenidos abarcan:

- lib/core/{config,errors,network,storage}; auth, campañas/widgets, dashboard, prospectos/CSV, Jobs/capacidades, admin/perfil; routes/app_router.dart; shared/feature_widgets y file_service.
- Retirados: lib/features/workspace/data/platform_repository.dart, lib/features/campaigns/models/campaign.dart y lib/shared/widgets/entity_form.dart, después de migrar consumidores y funcionalidades útiles.
- pubspec.yaml/lock; tests existentes de Foundation, beta, campañas, core flows, pending features, contratos y antiguo PlatformRepository; nuevos csv_file_service_test.dart, dashboard_session_test.dart y reconciliation_hardening_test.dart.
- .dockerignore, Dockerfile.dev/vercel, .github/workflows/ci.yml, web/index.html/manifest.json y tool/check_merge_markers.dart/validate_api_origin.dart.
- README, FEATURE-DEVELOPMENT, Foundation, beta, funciones, Contracts, Despliegue-Web y este informe. ADR e informes históricos no se alteraron.

Estado final comprobado después del commit del informe: `git status --porcelain=v1` sin salida; árbol limpio en fix/f5-foundation. La rama contiene cuatro commits nuevos sobre dev c7dee66. main local dd9e95b, dev
local/origin c7dee66 y origin/main a85a996 se comprobaron intactos. Backend, Service y
Engine conservan sus HEAD y status limpios. No se hizo push, merge remoto, despliegue,
modificación de Vercel/CORS ni comunicación a terceros.

Revisión sugerida, sin ejecutarla sobre dev:

```powershell
git status --short --branch
git log --oneline origin/dev..fix/f5-foundation
git diff --stat origin/dev...fix/f5-foundation
git diff origin/dev...fix/f5-foundation -- lib test Docs/Contracts
```

Tras aprobación explícita del propietario y sólo si dev no avanzó, la incorporación
local puede verificarse con:

```powershell
git fetch origin
git switch dev
git merge --ff-only fix/f5-foundation
flutter analyze
flutter test
```

Si no es fast-forward o existen cambios locales, detener esa incorporación y revisar
el nuevo historial; nunca forzar ni descartar trabajo. Push, PR y despliegue requieren
la autorización posterior indicada por el propietario. Ninguno se realizó aquí.
