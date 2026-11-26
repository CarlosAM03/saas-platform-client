# MATRIZ DE CAMBIOS AUTORIZADOS — Segundo Avance v1.0.0

27 de octubre de 2026.

Autoridad: Plan de TrabajoAvance2.md del owner, leído íntegramente (435 líneas; SHA256 df1552887869b3a79d87034b135022c2df265c399ce4c777a654601b5e445f09). Copia congelada: [plan rector](evidencias/PLAN_RECTOR_SNAPSHOT.md). Esta entrega ejecuta exclusivamente Fase 0; G0 pendiente de autorización explícita. Los cambios de implementación descritos son futuros, no aplicados.

Entregables relacionados: [plan de ejecución](PLAN_EJECUCION_CIERRE_AVANCE_2.md), [matriz de cambios](MATRIZ_CAMBIOS_AUTORIZADOS.md), [baselines y ramas](BASELINES_Y_RAMAS.md), [gates](GATES_DE_ACEPTACION.md).

## 1. Decisiones y precedencia

El archivo rector declara “26 decisiones recibidas” y cita A4/C5 y E1/E3, pero **no transcribe las26respuestas ni todos sus identificadores**. Se leyó íntegro. D01–D18 son agrupaciones operativas de instrucciones expresas; no se presentan como las respuestas originales ni como nuevas aprobaciones. La ausencia del cuestionario original es un límite de trazabilidad, sin impedir esta Fase 0 claramente delimitada.

El plan actual prevalece sobre recomendaciones de la auditoría anterior: JWT snapshot confirmado, migración P2 excluida del core/Supabase y Node 20 diferido. No se modificaron los informes históricos. El alcance aprobado no equivale a permiso para implementar antes de G1.

|ID operativo|Instrucción expresa|Fuente en plan congelado|Estado|
|---|---|---|---|
|D01|Backend main desplegado y contrato público son autoridad de v1.0.0|§5/1–2|Resuelto; el owner confirma estabilidad. La atestación independiente del binario se registra aparte.|
|D02|Backend3a33093 y Foundation 095e899 son las bases|§3 F1/F2 y §5/2|Resuelto; referencias remotas sin deriva.|
|D03|Seleccionar SEC-01 sin copiar el commit mixto 42b96|§1 condición1 y §5/4|Resuelto en alcance; selección exacta pendiente de G1.|
|D04|Conservar JWT snapshot y roles actuales|§1 condición1 y §5/4; ADR-004§31|Resuelto; excluir revalidación viva.|
|D05|Conservar schema baseline, sin tablas ni migración P2|§1 condición2 y §5/4|Resuelto; Supabase no se modifica.|
|D06|Excluir PR #6 Backend y PR #8 Flutter del producto|§3 F1/F5/F7 y §5/4/6|Resuelto; conservar ramas experimentales.|
|D07|Preservar PR #5, UI útil de André, Foundation y SDK tipado|§2 y §5/5|Resuelto; main/PR #5 y dev son ancestros de Foundation.|
|D08|Auth, tenants, usuarios, RBAC, campañas y prospectos reales|§2 matriz y §5/3/5|Resuelto; sin endpoints ni reglas inventados.|
|D09|CSV existente con preview/confirm y decisiones por fila|§2 y §3 F3|Resuelto; no segundo importador.|
|D10|Dashboard real y aislado por tenant|§2 y §5/3|Resuelto; meta.total de listas existentes.|
|D11|Jobs reales solo de lectura|§2 y §5/3/4|Resuelto; registros existentes, sin ejecuciones ficticias.|
|D12|Demo visual identificada y aislada de SDK/negocio|§1 A4+C5 y §5/3/5|Alcance aprobado; implementación sujeta a G1.|
|D13|No acciones externas, callbacks productivos, Flutter→FastAPI ni secretos Service en cliente|§5/3/4|Resuelto; validación negativa prevista.|
|D14|Diferir Node 20 inmediatamente después del cierre|§1 condición3 y §5/4|Resuelto como secuencia; deuda y riesgo residual, sin upgrade ahora.|
|D15|dev acepta primero v1; después podrá avanzar a1.1|§1 E1+E3 y §3 F5–F7|Resuelto; no mezclar P2 en el cierre.|
|D16|PG desechable con migraciones core, nunca solo una DB ya migrada P2|§3 F4 y §5/7|Plan de validación aprobado; ejecución futura y explícitamente delimitada.|
|D17|Promoción/despliegue con aprobación separada y rollback|§4 G3–G5 y §5/8–9|Permisos operativos pendientes.|
|D18|Fase 0 exclusiva y parada G0 antes de ramas|§4 y §5/6/9; encargo actual|Esta entrega termina sin implementación.|

## 2. Cambios elegibles y exclusiones

Todos están **NO APLICADOS**. Las filas candidatas requieren justificación y revisión del diff en G1; ningún archivo se copia completo por pertenecer a un commit del owner. La implementación necesita G1 y las pruebas G2.

|ID|Archivo/componente|Cambio permitido en alcance|Exclusiones obligatorias|Decisión|Tramo futuro|Validación prevista, NO EJECUTADA|
|---|---|---|---|---|---|---|
|B01|UsersService.update/findUserInTenant|Seleccionar protección de identidad global compartida/ADMIN y lectura transaccional. Preservar self-edit y rol tenant según contrato.|Excluir helpers de autenticación para JWT vivo y el cherry-pick completo42b96.|D03–D05|F1; después de G1|Shared A/B, ADMIN ajeno403, self/local permitidos, atomicidad y fallo de serialización.|
|B02|configuration.ts + tests|Seleccionar JWT fuerte y CORS HTTPS explícito; comprobar core sin claves Service.|No editar secretos ni configuración Render/Vercel/Supabase.|D01/D03/D13|F1; después de G1|Config válida/inválida y arranque core sin Service.|
|B03|config.module.ts|Seleccionar ignoreEnvFile en NODE_ENV=test para aislar suites.|No leer .env privados ni cambiar configuración productiva.|D03/D16|F1; después de G1|Tests independientes de archivos locales.|
|B04|main.ts|Seleccionar solo trim de orígenes CORS si el diff G1 confirma utilidad.|Excluir parser especial/ampliación de payload callback; no copiar bootstrap completo.|D01/D03/D13|F1; después de G1|Origen permitido/ajeno; resto del bootstrap baseline.|
|B05|GlobalExceptionFilter|Candidato a conservar entity.too.large→413 y código de error coherente.|Sin ampliar cuerpos ni incorporar política callback.|D01/D03|Revisión G1|Payload excesivo413, sin stacks/secretos.|
|B06|package.json/package-lock.json|Revisar overrides de seguridad independientes de la auditoría.|Candidato sujeto a justificación G1; sin Node upgrade, scripts Python/P2 o actualización general.|D03/D14|Revisión G1, no permiso por arrastre|Dependencias y regresión; lock coherente.|
|B07|Tests core/Auth/aislamiento|Seleccionar casos útiles de SEC-01 y dos tenants, adaptados al schema core y snapshot.|No copiar assertions401 de autorización viva ni fixtures Event/Snapshot; no excluir suites fallidas.|D03/D04/D16|F1/F4; después de G1/G2|Snapshot hasta nuevo token, usuario inactivo401, IDs tenant y transacciones.|
|B08|Prisma/JWT/Jobs/cliente/OpenAPI|Mantener schema, autenticación snapshot, Jobs lectura y503 del baseline.|Sin migraciones, Event/Snapshot, reconcile, callbacks, cuotas, TTL o deploymentDocument1.1.|D01/D04–D06/D11/D13|Invariante F1–F6|Diff Prisma vacío y contrato core sin campos P2.|
|F01|Docs/Contracts y documentación Flutter|Corregir afirmaciones Snapshot PG/TTL de una hora y restricciones P2 heredadas; reflejar contrato disponible1.0.0.|No cambiar Backend para satisfacer la copia ni traer YAML1.1 dePR8.|D01/D05/D11/D13|F2; después de G1|Resolver discrepancias semánticas aplicables; no exigir igualdad de bytes de YAML.|
|F02|SDK/DTO/repositorios HTTP|Preservar API tipada; adaptar solo discrepancias demostradas de rutas, tipos, envelopes, errores y paginación.|Sin APIs paralelas, GETroles/dashboard/capabilities nuevos o mocks productivos. Métodos preparados no se habilitan.|D01/D07/D08/D11/D13|F2; después de G1|Contrato servido, nullables/enums y estados HTTP por operación.|
|F03|Auth/ApiClient/providers/routes/dialogs|Preservar sessionRevision/tokenOperation, scope, limpieza y descarte de respuestas tardías.|No refresh ni revocación viva nuevos; un401 antiguo no cierra otra sesión.|D04/D07/D08|F2; después de G1|Cambio tenant/logout/login, diálogos/pickers/CSV y solicitudes diferidas.|
|F04|Gestión SaaS/tema/layouts|Consolidar pantallas, navegación, responsive y componentes útiles de André/PR #5 sobre repositorios reales.|No reemplazar módulos estables ni inventar roles/operaciones; OWNER status y DELETE ADMIN según contrato.|D07/D08|F2; después de G1|CRUD positivo/negativo A/B, vacíos/errores y revisión visual acotada.|
|F05|CSV/page/repository/file_service|Conservar bytes, referencia y decisiones, conflictos/duplicados/resultado por fila y protección del scope.|No nuevo importador XLSX ni importar contactos reales por inferencia.|D09/D13|F3; después de G1|CREATE/LINK/UPDATE/SKIP,409 stale/replay, archivo/campaña/tenant incorrectos,413 y shared updates.|
|F06|Dashboard|Conservar tres listas reales, meta.total, recientes y actualización del tenant activo.|No métricas inventadas, globales o demo; no endpoint nuevo.|D10/D11|F3; después de G1|n>límite de página, refresh tras CSV y cambio A→B.|
|F07|Jobs/capabilities|GET listado/detalle reales, vacío legítimo y resultados/progreso null baseline; cuatro flags false.|No GETcapabilities, creación/polling/generation/quota/retry/snapshots1.1.|D11/D13|F3; después de G1|GET únicamente,200/404/cruce tenant y ningún job ficticio.|
|F08|Componentes de demo por definir en G1|Presentación local rotulada DEMO — SIN EJECUCIÓN REAL, sintética, aislada y reiniciable.|No SDK/repositorios reales, mutaciones, callbacks, export/persist ni contaminación de conteos/historial.|D12/D13|F3; después de G1|Cero tráfico/efectos de negocio; rótulo visible en todos los estados; logout limpia.|
|F09|Assets/containerización/build|Preservar Foundation y corregir solo defectos demostrados de assets/build/SPA.|No workflows/harness P2 dePR8 ni artefacto API loopback desplegado en Vercel.|D07/D13|F2/F4; después de G1/G2|Build/analyze/tests/imagen SPA, API correcta y sin secretos en bundle.|
|V01|E2E core|Preparar prueba real Flutter→Nest→PG desechable con solo init core.|No usar DB demo P2 como evidencia única ni escribir en Supabase; ninguna migración ahora.|D16|F4; después de G2 explícita|Dos tenants y fixtures sintéticos; schema de 8 modelos y rutas reales.|
|V02|Ausencia de tráfico externo|Instrumentar node:http(s), Dio y canario local; separar tráfico core permitido.|No contar solo fetch; no scraping o proveedores externos.|D13/D16|F4; después de G2|Cero rutas P2/Service/callback, incluso al interactuar con demo.|
|R01|dev/main/PR/release|Planificar aceptación dev, release y rollback sobre los SHA candidatos.|Ninguna escritura PR/Git/producción por aprobar G0; permisos posteriores separados.|D15/D17/D18|F5/G3–G4; F6/G5|Checks del integrado, atestación de artefactos/config y reversión.|
|P01|Service/Engine/P2/Compose|Preservar referencias y decisiones pendientes fuera de v1.0.0.|No desplegar, activar o definir por arrastre almacenamiento/TTL/cuotas/alcance1.1.|D06/D13/D18|F7; solo G6 futuro|Propuesta separada; sin promesa de Maps real ni recuperación durable.|

## 3. Delimitaciones esenciales

SEC-01 se selecciona por método/hunk desde 42b96: update, lectura transaccional y helper findUserInTenant. Conservar JwtStrategy y helpers de autenticación baseline. No copiar el commit entero ni trasladar consultas de membresía a cada request. Probar atomicidad y fallos de serialización; no introducir una política nueva de reintento externo para resolver ese caso.

El deploymentDocument del PR #6 sirve el contrato1.1 y no es un fix core de configuración a copiar. Se revisó la función: conservar el tratamiento baseline503/null. Un agrupamiento amplio del anexo histórico no sustituye esta comprobación del diff y la decisión actual del owner.

Foundation mantiene el núcleo útil, pero su copia YAML tiene46rutas de diferencia frente al target YAML Backend. Muchas documentan correctamente operaciones deshabilitadas; otras afirman Snapshot PostgreSQL/TTL de una hora y restricciones nuevas de generación. Corregir estas últimas sin habilitar acciones ni cambiar Backend. El contrato público baseline es una transformación explícita de su YAML objetivo; igualdad de bytes entre copias no sustituye compatibilidad funcional.

Los métodos preparados create/cancel/persist/export del SDK pueden permanecer inactivos. Foundation marca sus cuatro capacidades false. La demo aprobada se implementará en presentación aislada: no poner create=true ni sustituir silenciosamente el repositorio HTTP por un mock. Los Jobs reales pueden estar vacíos; no fabricar una búsqueda para llenar el historial.

No añadir GETroles, PATCH/DELETEtenant, DELETEprospect o endpointdashboard por simetría con pantallas. Preservar roles y operaciones existentes. Las restricciones de OWNER status se mantienen según contrato y la protección SEC-01; no inventar una prohibición adicional.

## 4. Contrato que debe consumir el Frontend

Prefijo /api/v1. Código y CI históricos respaldan el alcance; no se ejecutó smoke autenticado productivo en Fase 0.

|Flujo|Operaciones existentes|Tratamiento core|Validación posterior|
|---|---|---|---|
|Auth|POST /auth/login, GET /auth/me, POST /auth/select-tenant y /auth/logout|Real; snapshot, sesión y errores contractuales|Login/logout/cambio tenant y respuestas tardías|
|Tenants|GET /tenants, GET /tenants/{id}, POST /tenants|Real; POST ADMIN; sin operaciones nuevas|Permisos y visibilidad de IDs|
|Users|GET/POST /users, GET/PATCH/DELETE /users/{id}|Real; MEMBER por defecto y DELETE ADMIN; SEC-01 selectivo|Shared A/B, identidad global, roles y transacciones|
|Campaigns|GET/POST /campaigns, GET/PATCH/DELETE /campaigns/{id}, GET /campaigns/{id}/prospects|Real; archivar/permanent y asociaciones según contrato|RBAC/tenant/estados/conflictos|
|Prospects|GET/POST /prospects, GET/PATCH /prospects/{id}|Real; gestión manual y por campaña|CRUD contractual y cruce tenant|
|CSV|POST /prospects/import/preview y /confirm multipart|Real; mismos bytes/referencia/decisiones y confirmación shared|Filas, duplicados, conflictos,413 y atomicidad|
|Dashboard|GET /campaigns + /prospects + /prospecting-jobs|Real; meta.total y recientes|n>tamaño de página, refresh CSV, A→B|
|Jobs|GET /prospecting-jobs y /{id}|Lectura real; false/null para resultados/progreso baseline|Vacío,200/404 y nullables|
|Generación/cancel/persist/export|Rutas existentes de /prospecting-jobs y /{id}/cancel,/persist,/export|Deshabilitadas;503 tras validar. La UI no las invoca|Ningún fake 2xx ni job creado por demo|
|Capabilities/callbacks/Service|Ninguna capacidad1.1 requerida por el contrato público core|No nuevos flujos ni Flutter→FastAPI|Traces sin P2 y sin claves internas|

Estados HTTP por operación en evidencia10, incluidos400/401/403/404/409/413/429/503 cuando corresponden; no exigir que todas las rutas devuelvan todos los estados. Preservar envelopes success/data/meta, tipos/enums/nullables y paginación del backend.

## 5. Evidencia y pendientes

Verificado ahora: referencias remotas, ancestry, documentos preservados, diffs selectivos,33 operaciones del contrato público y cuatro flags false de Foundation. Las46diferencias YAML están registradas en evidencia11. CI se consultó sin dispararla; ninguna prueba de esta matriz se ejecutó ni se aplicó código.

Pendientes: autorización G0; revisión G1 de hunks, candidatos de configuración/dependencias y diseño demo; G2/G3 para regresión; G4/G5 para promoción/release; G6 para tramo1.1. El preview SSO y su acceso CORS directo a Render requieren una decisión específica solo si se usan para aceptación; no cambiar infraestructura por inferencia. La traza original de26respuestas podrá añadirse sin inventarla. Node 20 permanece deuda prioritaria después del cierre.

**GO técnico para solicitar G0. Ejecución de esta matriz pendiente de gates; DETENIDO.**
