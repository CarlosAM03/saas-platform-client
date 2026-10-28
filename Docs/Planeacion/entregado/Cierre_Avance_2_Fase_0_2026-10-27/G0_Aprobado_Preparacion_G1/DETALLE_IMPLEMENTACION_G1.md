# DETALLE DE IMPLEMENTACIÓN PARA G1 — Entregable A

Estado: **G0 ejecutado; G1 PENDIENTE. Código todavía sin modificar.** Este documento desarrolla la matriz ya revisada, no sustituye el Plan de TrabajoAvance2.md ni repite la auditoría Fase 0.

Referencias: [matriz aprobada de preparación](../MATRIZ_CAMBIOS_AUTORIZADOS.md), [gates rectores](../GATES_DE_ACEPTACION.md), [acta de G0](ACTA_G0_WORKTREES.md), [ampliación propuesta B](AMPLIACION_PROPUESTA_DEMO_COMPOSE_1_1.md). IDs B/F/D conservan el significado de la matriz; los nombres de archivos nuevos siguientes son propuestas revisables.

## 1. Bases listas para implementar después de G1

|Repo|Checkout|Rama|HEAD inicial|
|---|---|---|---|
|Backend|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\backend-core|fix/avance2-core-security|3a3309398458ab333d7b00f16e9c2df6a09ef734|
|Flutter|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\flutter-core|release/avance2-frontend-v1|095e899ace31acf17d97bbe945c118c1a5d88682|

Ambos están limpios y sin commits nuevos, staging o diff frente a su base. Paridad contractual1:1 significa que cada operación real habilitada del Frontend coincide con la operación existente del Backend, incluyendo método, ruta, request, autorización, envelope, tipos, estados y paginación. No se amplía Backend para satisfacer una pantalla.

La prioridad es el core de A. B es un producto de demostración local separado; su objetivo adicional no habilita PR #6 Backend, PR #8 Flutter o migraciones P2 en estos checkouts.

## 2. Backend: selección exacta propuesta

Fuente de conceptos auditados: commit 42b96fefd73cc11b42ecde4df6d5f42393328bfc. Se editarán selectivamente los archivos, sin cherry-pick ni merge. Las referencias de línea y hashes baseline están en evidencia04.

|ID matriz|Archivo/método|Modificación propuesta|Exclusión o compatibilidad|Prueba prevista para G2|
|---|---|---|---|---|
|B01|src/users/users.service.ts|Agregar ForbiddenException; en update releer destinatario dentro de transacción, detectar cambios name/email/password/status y rechazar identidad global ajena compartida o ADMIN; helper findUserInTenant acepta TransactionClient; Serializable.|Excluir cambios de findByIdForAuthentication e isTenantActiveForAuthentication del commit 42b96; no modificar JwtStrategy. Conservar self-edit, identidad local y cambio de rol tenant según contrato.|Compartido A/B y ADMIN ajeno403; self/local permitidos; rol solo A; fallo sin escrituras parciales.|
|B02|src/common/config/configuration.ts; configuration.spec.ts|Seleccionar validación productiva de JWT de32 caracteres mínimo/no muestras y orígenes CORS HTTPS exactos.|No cambiar claves/orígenes reales ni inventar reglas RBAC. Una config productiva que incumpla se registra para release, no se modifica ahora.|Config válida/inválida, TLS/origen, seis variables core sin Service.|
|B03|src/common/config/config.module.ts|ignoreEnvFile cuando NODE_ENV=test.|Configuración productiva y archivos .env privados intactos.|Tests independientes del .env de cada máquina.|
|B04|src/main.ts|Agregar trim a cada origen CORS.|No importar json ni parser/gran límite de callback del PR #6.|Origen autorizado y ajeno; arranque y resto de bootstrap sin cambios.|
|B05|src/common/filters/global-exception.filter.ts|Mapear entity.too.large a413/PAYLOAD_TOO_LARGE con prueba negativa acotada.|No ampliar límites de payload ni publicar cuerpo/stack de excepción.|413 coherente y ausencia de detalles privados.|
|B06|package.json y package-lock.json|Propuesta granular: overrides body-parser2.4.0, multer2.5.0, fast-uri3.1.9 y js-yaml=$js-yaml, que mantiene5.4.1 del baseline. Conservar lodash/tar existentes.|Versiones candidatas del commit auditado, no promesa de ausencia actual de advisories. Sin scripts Python/P2, Node upgrade o actualización general. Regeneración lock solo si G1 aprueba esta fila.|Lock coherente, diff limitado y audit/regresión nuevos en G2.|
|B07|test/platform.e2e-spec.ts; nuevo test/core-isolation.postgres-spec.ts; test/jest-postgres.json|Seleccionar casos de SEC-01 y dos tenants; fixture core sin Event/Snapshot; ampliar regex a jobs\|prospect-imports\|core-isolation sin retirar suites existentes.|No copiar expectations de JWT vivo, callbacks o snapshots; no usar DB ya P2.|Snapshot se mantiene hasta nuevo token; usuario inactivo401; pertenencia/roles/IDs; PG con solo init.|
|B08|Prisma/, src/auth/strategies/jwt.strategy.ts, helpers de autenticación, Jobs/cliente/OpenAPI|Mantener exactamente baseline. Comprobar hashes e inventario de migraciones antes de G2.|Sin nuevas tablas/columnas ni revalidación viva, callbacks, TTL/cuotas/idempotencia o capabilities1.1.|Diff de esos invariantes vacío; creación/cancel/persist/export conservan503.|

SEC-01 parte de User global y membresías tenant-scoped. No revelar las otras membresías en el403. La transacción debe mantener coherencia entre comprobar destinatario y actualizarlo; un fallo de serialización no puede dejar cambios parciales. No introducir reintento externo automático ni ampliar reglas de roles por conveniencia.

Los tests heredados de autorización snapshot se conservan. Verificar usuario activo en cada request ya pertenece al baseline; no confundirlo con revalidar rol/membresía/tenant vivo. La protección de identidad global no necesita enriquecer findByIdForAuthentication.

## 3. Flutter: consolidación sin arrastre1.1

|ID matriz|Archivos/componentes|Cambio o conservación propuesta|Límite|
|---|---|---|---|
|F01|Docs/Contracts/platform-api.v1.yaml; Docs/Contracts/README.md; documentación Foundation afectada|Corregir textos Snapshot PG/TTL de una hora. Alinear restricciones de ProspectingQuery y campaignId con contrato disponible; separar operaciones objetivo deshabilitadas de comportamiento servido.|No importar YAML1.1 ni cambiar Backend. Usar evidencia11 de F0 como listado de46rutas de diferencia, no como46bugs funcionales.|
|F02|lib/platform_api/* y test/platform_api/platform_api_contract_test.dart|Preservar SDK tipado y añadir comprobaciones del contrato servido/goldens sanitizados. Tocar DTO/repositorio solo ante discrepancia concreta demostrada.|Paridad1:1 de cada operación habilitada: método/ruta/request/auth/envelope/tipos/errores/paginación. No requiere una pantalla por endpoint ni endpoints nuevos.|
|F03|Auth, ApiClient, providers, rutas y session_dialog; tests existentes de sesión|Conservar sessionRevision/tokenOperation, scope y limpieza. Ampliar casos si falta cubrir algún flujo habilitado.|No reemplazo completo de módulos, refresh/JWT vivo ni persistencia de datos sensibles entre tenants.|
|F04|Usuarios/tenants/campañas/prospectos, tema/assets/layouts|Conservar aportaciones visuales válidas de André y PR #5 ya heredadas en Foundation; corregir únicamente diferencias demostradas.|Ningún rediseño global ni rol/endpoint inventado. Mantener MEMBER por defecto y permisos actuales.|
|F05|CSV page/repository/file_service/campaign_picker; test/platform_api/prospect_import_test.dart; tests CSV/core existentes|Mantener bytes+referencia+decisiones, confirmación shared y limpieza de scope; cubrir conflictos/errores/duplicados.|No segundo importador, XLSX automático, datos reales ni importar archivos del usuario por inferencia.|
|F06|Dashboard repository/providers/page; test/dashboard_session_test.dart|Conservar tres listas reales y meta.total, recientes y refresh tras CSV; validar A/B y n>límite.|No mocks de producción, métricas inventadas/globales o endpoint dashboard.|
|F07|Jobs repository/providers/pages/capabilities; tests core/pending|GET list/detail reales y cuatro flags false. Aclarar el acceso visual para que no prometa búsqueda real.|Conservar monitor GET existente si corresponde: su polling secuencial de lectura cada4s no es creación P2. No añadir capabilities, polling de admisión, cuotas, generación o snapshots1.1.|
|F08|Nuevos prospecting_demo_panel.dart y test/features/prospecting_demo_test.dart; generate_page.dart; posible etiqueta en jobs_pages.dart|Panel local dentro de la vista /generate ya existente, abierto como demostración explícita; sin nueva ruta necesaria. Rótulo DEMO — SIN EJECUCIÓN REAL visible en todos los pasos, datos sintéticos y estado local reiniciable.|El panel no importa PlatformApi, repositorios HTTP ni modelos persistidos de Job. No habilita create=true. No invalida dashboard/historial, no guarda/descarga resultados ni llama redes.|
|F09|SDK/build/assets/containerización existente y tests|Preservar el conjunto Foundation; ampliar regresión visual/accesibilidad de los flujos tocados.|No workflows/harness P2 del PR #8 ni reutilizar artefacto compilado para API loopback en producción.|

Para F08 propongo un solo archivo nuevo en lib/features/prospecting_jobs/presentation/prospecting_demo_panel.dart y un test específico, enlazado desde la rama deshabilitada de GeneratePage. Se conservan /generate y los guards existentes; el estado local vive en la página con scope y se destruye al cambiar sesión/tenant. La demo puede enseñar entradas y pasos visuales, siempre identificados, sin usar nombres/IDs de campañas o prospectos productivos ni generar progreso que parezca medido por Service.

El botón de Jobs puede decir “Ver demostración de búsqueda” o “Generación no disponible” según el diseño final acotado, conservando “Ver trabajos” como lectura real. No poblar el historial para hacer la pantalla más vistosa. El polling GET ya existente para registros QUEUED/RUNNING es lectura real; se conserva su cancelación por dispose/scope y no se añade seguimiento de una creación experimental.

F01 debe distinguir el YAML objetivo histórico del documento servido: el último contiene las respuestas503 y resultados/progreso null. Corregir las afirmaciones Snapshot PG/TTL y restricciones no respaldadas, sin borrar operaciones objetivo solo por ser preparadas ni afirmar que están disponibles. No se promete igualdad byte por byte de las copias YAML.

## 4. Harness y casos de aceptación concretos

Backend: modificar test/platform.e2e-spec.ts solo para añadir SEC-01/config/413 manteniendo snapshot. Añadir test/core-isolation.postgres-spec.ts con fixtures sintéticos core y ampliar test/jest-postgres.json sin excluir jobs/prospect-imports. No copiar la suite P2 completa: contiene snapshots, callbacks y expectativas401 por revocación viva.

Para E2E real de A, proponer un harness nuevo y acotado (test/scripts/core-v1-stack.ts y test/support/core-v1-fixture.ts en Backend; test/integration/core_v1_stack_test.dart en Flutter). No copiar core-stack/mvp-stack P2 sin revisión: crean/limpian fixtures y algunas pruebas anteriores instrumentan fetch en vez del transporte real. Este harness debe exigir URL de DB desechable y ownership del fixture antes de cualquier escritura/limpieza. No se implementa ni ejecuta en este turno.

Casos mínimos: OWNER A no cambia identidad global ajena compartida con B ni ADMIN; identidad local y propia según contrato; rol membershipA no modificaB; rollback atómico; JWT snapshot hasta nuevo token; usuario inactivo401; IDs de otros tenants ocultos. Auth/tenants/CRUD/CSV real; CSV decisiones/duplicados/conflictos/stale/replay/413; dashboard meta.total con más filas que una página y refresco; Jobs vacío/detalle y nullables. Sesión/logout/cambio tenant, diálogos y respuestas tardías no contaminan B. Cada demo debe dejar cero tráfico y cero cambios en conteos/historial; el shell puede hacer sus GET reales normales, que se capturan separadamente.

Instrumentar node:http(s), Dio y un canario local. No usar global.fetch=0 como única prueba. La ejecución de A no necesita URL ni credenciales Service y ninguna operación real habilitada puede depender de FastAPI.

## 5. Comandos futuros y efectos, NO EJECUTADOS

G1 propone editar source/tests/docs únicamente en estos candidatos. Para B06, si el owner acepta esa fila, incluir de forma expresa la regeneración acotada del lock con npm install --package-lock-only --ignore-scripts --no-audit --no-fund después de fijar los overrides; no npm update ni instalación general. Requiere runtime/npm compatible y revisión de diff del lock. Si no se incluye B06, registrar su exclusión y evaluar el riesgo de dependencias antes del release; no omitirla silenciosamente.

Antes de G2 solo se inspeccionará el diff/invariantes. Los siguientes comandos dependen de G2 y del entorno de pruebas aprobado:

|Área|Comando previsto|Efecto/precondición|
|---|---|---|
|Inspección|git diff --stat; git diff --check; git diff -- Prisma src/auth/strategies/jwt.strategy.ts|Lectura; revisar toda modificación y confirmar invariantes. El conjunto prohibido completo incluye helpers/Jobs/OpenAPI.|
|Backend deps|npm ci|Instala y puede ejecutar scripts; solo checkout candidato, runtime Node 20 aprobado o contenedor equivalente. No ejecutar bajo G0.|
|Cliente Prisma|npm run prisma:generate|Genera cliente local; no aplica migración, pero escribe outputs. Solo después de G2.|
|Calidad Backend|npm run lint:check; npm run format:check; npx tsc --noEmit --incremental false; npm run build|Checks sin autofix; build genera dist. No usar npm run lint con --fix.|
|Tests Backend|npm run test:unit:ci; npm run test:e2e:ci|Unit/HTTP identificados; comprobar env test antes de correr.|
|PG core|npm run prisma:migrate:deploy; npm run test:postgres|SOLO si G2 autoriza explícitamente DB efímera recién creada con init core y URL verificada. Ninguna Supabase/shared/DBprevia P2 ni migración nueva.|
|Dependencias|npm audit --omit=dev --audit-level=high; npm audit --audit-level=high|Consulta nueva en G2; no afirmar resultado anterior como vigente.|
|Flutter deps/modelos|flutter pub get; dart run build_runner build|SDK3.47.5/lock baseline; escribe .dart_tool/modelos solo en candidato. No upgrade general.|
|Flutter calidad/tests|dart run tool/check_merge_markers.dart; flutter analyze; flutter test|Suites existentes más nuevas; ninguna suite omitida para esconder fallos.|
|Flutter E2E|flutter test test/integration/core_v1_stack_test.dart con manifiesto efímero del harness|Archivo aún propuesto; necesita ABackend real+PGcore y argumentos definidos por el nuevo harness. No es comando disponible ya.|
|Web test|flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=<origen_local_autorizado>|Artefacto de prueba aislado, nunca subirlo como build productivo.|
|Web release|flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=https://saas-platform-backend-l55n.onrender.com|Build posterior con G2; despliegue requiere G5 por separado.|
|Imagen/SPA|docker build -f Dockerfile.vercel --build-arg API_BASE_URL=<origen_autorizado> -t prospector-client:avance2-core .|Solo G2; construcción consume recursos/red. Smoke posterior sin infraestructura productiva.|

“flutter”/“dart” denotan ejecutables del SDK verificado, no instalación nueva: existe .flutter-sdk con versión cacheada3.47.5/Dart 3.13.4; no están en PATH actual. Node del host es22.16.0, distinto del engines20.x aprobado: validar bajo Node 20 en entorno aislado sin actualizar runtime del producto. Docker 29.9.2/Compose 5.6.1 y daemon Linux responden; no se construyó ni arrancó contenedor. No inicializar SDK/paquetes por verificar una versión ahora.

No existe todavía la orquestación de prueba específica A ni el nuevo harness. Su preparación local es código sujeto a G1, y su ejecución a G2. Nunca usar el Compose baseline sin revisar: su db-init ya contiene migración+seed y puede escribir.

## 6. Salida que se presentará para G2

Diff revisable por fila B/F; lista exacta de archivos/justificación; schema/migraciones y hashes invariantes; sin endpoints1.1/secretos internos; SDK/HTTP real; demo aislada; tests escritos y no ejecutados antes del permiso. Registro de Node 20 diferido y selección B06. Candidato listo para pruebas, sin commits/push/PR automáticos.

Los criterios de aceptación funcional y seguridad no se debilitan para obtener verde. Si aparece una incompatibilidad contractual real, se documenta antes de ampliar alcance. El Backend productivo sigue siendo autoridad; no se modifica Render o Supabase para adaptarlo a Flutter.

## 7. Autorizaciones adicionales

|Gate|Estado|Qué requiere permiso explícito|
|---|---|---|
|G0|APROBADO Y EJECUTADO|Dos ramas/worktrees exactos; integridad verificada. Ningún cambio de implementación.|
|G1|PENDIENTE|Autorizar cambios locales A de las filas B01–B08/F01–F09 y test/harness core delimitado; decidir B06/lock explícitamente. No ejecutar pruebas ni construir B.|
|G2|PENDIENTE|Revisar diff final e invariantes; autorizar instalaciones/build/tests en candidatos y preparación de PostgreSQL core desechable concreto. Sin Supabase/migración P2.|
|G3|PENDIENTE|Aceptar contrato/E2E/seguridad nuevos; autorizar publicación/propuesta PRdev con SHA/ramas precisos. Merges y pushes requieren inclusión expresa.|
|G4|PENDIENTE|Aceptar dev integrado/CI y revisión; autorizar propuesta/promoción main concretas, sin despliegue implícito.|
|G5|PENDIENTE|Autorizar release y despliegue Render/Vercel concretos, backup/rollback/atestación/config. Backend solo si las correcciones lo requieren.|
|G6|PENDIENTE|Tras A consolidado, ratificar ampliación B, variante de integración, almacenamiento local, red/perfiles y límites. Autorizar por tramos construcción/validación de Compose. Scraping real requiere permiso específico.|

B no forma parte de la implementación A que se propone abrir con G1. Su ampliación y criterios están en el documento separado; el alcance arquitectónico definitivo1.1 permanece pendiente. La urgencia de presentación no salta G6 ni permite merges, pushes, Supabase, despliegues, migración P2 o scraping.

**Dictamen: GO técnico para solicitar revisión/autorización G1 del Entregable A descrito. G1 NO APROBADO; DETENIDO ANTES DE MODIFICAR CÓDIGO.**
