# GATES DE ACEPTACIÓN — Segundo Avance v1.0.0

Fecha: 27 de octubre de 2026.

Autoridad: Plan de TrabajoAvance2.md del owner, leído íntegramente (435 líneas; SHA256 df1552887869b3a79d87034b135022c2df265c399ce4c777a654601b5e445f09). Copia congelada: [plan rector](evidencias/PLAN_RECTOR_SNAPSHOT.md). Esta entrega ejecuta exclusivamente Fase 0; G0 pendiente de autorización explícita. Los cambios de implementación descritos son futuros, no aplicados.

Entregables relacionados: [plan de ejecución](PLAN_EJECUCION_CIERRE_AVANCE_2.md), [matriz de cambios](MATRIZ_CAMBIOS_AUTORIZADOS.md), [baselines y ramas](BASELINES_Y_RAMAS.md), [gates](GATES_DE_ACEPTACION.md).

## 1. Reglas de autorización

La tabla G0–G6 del §4 del plan es la autoridad para las transiciones. Las ocho fases canónicas del §3 y las siete agrupaciones del prompt maestro §5/6 se corresponden en el plan de ejecución. Se respeta la acción más restrictiva: G0 permite preparar ramas; G1 implementar; G2 probar; G3 proponer PR dev; G4 proponer promoción main; G5 desplegar; G6 iniciar el tramo experimental aprobado.

Un dictamen técnico GO no es una aprobación del owner. El paso del tiempo, CI verde, mergeable=true, autor Git o aprobación histórica de otro alcance no abren una puerta. Toda autorización debe indicar gate, componentes, SHA o diff y acciones permitidas. Un permiso para proponer un PR no autoriza fusionarlo; merges, pushes y despliegues requieren inclusión expresa conforme a las restricciones del encargo.

## 2. Matriz G0–G6

|Gate|Condición rectora|Evidencia exigida|Único tramo habilitable tras aprobación|No autoriza|Estado al cierre de F0|
|---|---|---|---|---|---|
|G0|Baselines y worktrees verificados; trabajo útil protegido|Inventario inicial/final; copias con hashes; contrato público y plan exacto de ramas|Preparar únicamente dos ramas locales y sus worktrees aislados descritos en evidencia14|Código, instalaciones, pruebas, commits, PR, merges, pushes, producción o Service|GO TÉCNICO; OWNER PENDIENTE; DETENIDO|
|G1|Plan de cambios Backend y Frontend revisado|Ramas/worktrees recién preparados; matriz revisada por hunk/método; exclusiones; diseño demo y criterios negativos|Implementar localmente solo los cambios revisados y autorizados|Ejecutar suites/DB antes de G2; commits/push/PR/merge/deploy; ampliar schema/JWT/negocio|PENDIENTE / NO INICIADO|
|G2|Código implementado y diff inspeccionado|Diff final con decisión por cambio; Prisma/JWT/Jobs invariantes; revisión de efectos y entorno desechable concreto|Ejecutar pruebas aisladas expresamente delimitadas; build/análisis en checkout candidato|Escrituras en Supabase/DB compartida; migración P2; scraping real; promoción/deploy|PENDIENTE / NO INICIADO|
|G3|E2E, seguridad y contrato aceptados|Resultados nuevos del candidato; PG core real, dos tenants, CSV/dashboard/jobs/sesión; cero egress P2; CI y limitaciones|Proponer PR hacia dev; crear/publicar PR o rama solo si la aprobación incluye esas mutaciones|Merge automático, push protegido, promoción main, deploy o activar P2|PENDIENTE / NO INICIADO|
|G4|dev validado y revisión aprobada|Merge a dev autorizado por separado; SHA integrado, checks y smoke de aceptación; dependencias PR resueltas sin pérdida|Proponer promoción a main con release/rollback revisables|Merge a main, despliegue, cambios de configuración/secretos/DB sin aprobación específica|PENDIENTE / NO INICIADO|
|G5|Release aprobado y rollback preparado|SHA/artefactos/configuración verificados; backup/restore y reversión; riesgo Node 20 diferido documentado; plan de gasto cero; permiso concreto|Desplegar únicamente los componentes/commits/orígenes expresamente aprobados; Backend solo si los fixes lo requieren|Migración productiva o cambio Supabase implícito; Service; comandos no incluidos en autorización|PENDIENTE / NO INICIADO|
|G6|v1.0.0 consolidado|Aceptación productiva, trazabilidad de release, separación de P2 y cierre de pendientes del core|Iniciar tramo experimental 1.1.0 específicamente aprobado; primero definir alcance y entorno|Autorizar por inferencia TTL/persistencia/idempotencia/Maps/Service productivo o gastos|PENDIENTE / NO INICIADO|

## 3. G0 — Evaluación concreta

|Criterio|Comprobación de esta fase|Resultado / evidencia|
|---|---|---|
|Raíz y cuatro repositorios|rev-parse/origin y rutas físicas comprobadas|VERIFICADO; evidencia01|
|Baseline Backend main|3a3309398458ab333d7b00f16e9c2df6a09ef734; remoto sin deriva; árbol igual a dev|VERIFICADO;01/07|
|Baseline Flutter Foundation PR #7|095e899ace31acf17d97bbe945c118c1a5d88682; main/PR #5 y dev ancestros|VERIFICADO;02/07|
|Trabajo local protegido|Documentos Flutter copiados con hashes, plan eliminado disponible en Git y copia; sin commits no publicados/stash|VERIFICADO;05/12; no se afirma que el checkout original esté limpio|
|Worktrees y separación|Un checkout activo por repo; nuevos destinos y ramas propuestos ausentes; sin hooks activos reportados|VERIFICADO;01/13/14|
|PR y dependencias|Backend6 y Flutter6/7/8 abiertos; PR #7 precede al8; excluir ambos PR de integración externa|VERIFICADO;02/04/09; reviews formales vacías|
|Contrato público|OpenAPI 1.0.0,33 operaciones, igualdad semántica con main; hash canónico compartido|VERIFICADO;10; no atesta binario/DB por sí mismo|
|Cambios mínimos y pruebas definidos|SEC-01 selectivo, snapshot/schema baseline, Foundation/CSV/dashboard/jobs y demo aislada; plan de regresión|VERIFICADO en los cuatro informes; código y pruebas aún NO EJECUTADOS|
|Fuentes y límites explícitos|Plan leído completo, auditoría y anexos disponibles;26 respuestas originales no transcritas; Node diferido|VERIFICADO en06; límite documental registrado, sin inventar IDs|
|Integridad al terminar|HEAD/refs/status/worktrees/stashes y documentos iguales al inicio|Verificación final en15/16, requerida antes de entregar|

**Dictamen: GO técnico para solicitar G0 y preparar las dos ramas/worktrees previstos. Estado formal: PENDIENTE de autorización explícita del owner. DETENIDO EN G0.**

Los cambios documentales locales no se descartan ni se transportan silenciosamente al candidato. Las copias verificadas y los nuevos checkouts aislados eliminan el riesgo identificado de perder ese trabajo al preparar ramas. Si se detecta cualquier archivo/commit útil sin proteger, cambio de hash o deriva remota antes de ejecutar, el dictamen pasa a NO-GO hasta preservarlo y revisar el plan.

## 4. Tramo exacto propuesto después de G0

1. Releer remotamente main Backend y Foundation Flutter mediante ls-remote; comprobar que mantienen los SHA congelados, sin actualizar refs automáticamente.
2. Comprobar status/copies/hashes, ausencia de nombres y destinos y hooks antes de usar un checkout nuevo.
3. Preparar Backend fix/avance2-core-security desde 3a3309398458ab333d7b00f16e9c2df6a09ef734 y Flutter release/avance2-frontend-v1 desde 095e899ace31acf17d97bbe945c118c1a5d88682, en destinos de BASELINES_Y_RAMAS.md/evidencia14. No cambiar el checkout activo original ni crear ramas Service/Engine.
4. Verificar HEAD, rama, limpieza y worktree de los candidatos. Registrar resultado y **detenerse en G1**, antes de editar, instalar, compilar, probar, commitear o publicar.

No se ejecutó ninguno de esos cuatro pasos mutantes en Fase 0. Solo se verificaron sus precondiciones. Las rutas y argumentos completos están en [evidencia14](evidencias/14_OPERACIONES_PROPUESTAS_G0.json).

## 5. Criterios técnicos de G1/G2

Backend: diff limitado a SEC-01/configuración/errores/tests independientes aceptados. JwtStrategy y helpers de autenticación conservan snapshot baseline. Prisma schema/migraciones idénticos al baseline; ninguna Event/Snapshot, callback, quota, TTL o idempotencia nueva. El bootstrap especial de callbacks y deploymentDocument1.1 no se trasladan como seguridad core. Overrides de dependencias se justifican por separado, sin Node upgrade ni cambios generales de paquetes.

Frontend: Foundation como base, identidad visual y aportaciones útiles preservadas. Adaptar únicamente consumidores/documentos con discrepancias demostradas. Corregir las descripciones de Snapshot PG/TTL de una hora heredadas en YAML. UI real contra API real; cuatro acciones externas bloqueadas. Demo rotulada en cada estado y aislada de SDK, repositorios reales, conteos e historial. No GETcapabilities1.1 ni tráfico directo FastAPI. Sesión/tenant y diálogos no retienen datos anteriores.

Antes de G2, la revisión debe identificar exactamente DB desechable/puertos/variables sin secretos, carpetas de outputs y efectos de cada script. El inventario de migraciones del checkout candidato debe contener solo init core. **Actualmente no se autoriza ninguna migración Prisma.** Si G2 futura incluye preparar el esquema de una DB efímera, deberá autorizarlo de forma expresa y limitada a ese entorno; nunca Supabase o bases compartidas. No crear una migración nueva para ejecutar tests.

Comandos futuros de validación deben usar lint:check/format:check y no scripts con --fix o --write por conveniencia. Builds/generación de cliente y dependencias solo en nuevos checkouts y dentro del alcance autorizado. No instalar o ejecutar herramientas desconocidas sin revisar efectos.

## 6. Criterios técnicos de G3/G4

- Tests reales y nuevos del candidato, distinguidos de la CI histórica. No sustituir PG core por fakes o una DB previamente migrada P2.
- Casos negativos de identidad compartida A/B, ADMIN/OWNER/MEMBER, pertenencia de IDs, transacciones y snapshot conforme al ADR.
- CSV preview/confirm y decisiones/duplicados/conflictos/errores por fila; dashboard meta.total y refresh reales; Jobs solo lectura con nulls baseline y estado vacío legítimo.
- Logout, cambio tenant, diálogos/pickers, formularios, providers, solicitudes tardías y401 antiguo sin contaminar sesión nueva.
- Ausencia de operaciones externas instrumentada en node:http(s)/Dio/canario. Un contador global.fetch=0 no basta.
- Contrato/envelopes/tipos/paginación/estados HTTP coincidentes con backend disponible; no nuevas capacidades para completar pantallas.
- Revisión visual/responsive y accesibilidad acotada con limitaciones explícitas; no declarar validación humana/dispositivos no realizada.
- PRs/dependencias resueltos con conservación de trabajo. No promover dev Flutter roto ni PR #8. Verificar de nuevo los SHA integrados antes de main.

## 7. Criterios técnicos de G5/G6

Atestar el release efectivo de Frontend/Backend y su configuración de API/CORS. El owner confirma Backend main/Render/Supabase como autoridad actual, pero la igualdad OpenAPI observada no identifica de manera independiente el binario ni las migraciones. Registrar evidencia concreta de SHA/config/rollback en release sin exponer secretos. Verificar backup restaurable y procedimiento de reversión adecuado al core, sin migración P2.

Node 20 permanece riesgo residual y deuda prioritaria inmediatamente después del cierre según decisión expresa, sin tratarlo como resuelto ni actualizarlo dentro de esta ejecución. No convertir esa recomendación anterior de la auditoría en un upgrade no autorizado. La aceptación de release debe mantener visible ese riesgo y el seguimiento posterior.

El preview indicado responde302 SSO y Render no devuelve ACAO para su origen en el preflight consultado. Si la aceptación requiere que ese browser llame directamente a Render, resolver origen/acceso de forma específica; no inferir permiso para abrir CORS, cambiar VercelSSO o modificar Render. E2E local aislada sigue siendo una opción previa, sin infraestructura productiva.

Service/Engine y Compose de cuatro servicios se consideran solo después de G6 y de un tramo experimental aprobado. Persistencia/idempotencia/TTL/cuotas/reintentos y alcance definitivo1.1 siguen sin autorización; no inferirlos de ramas existentes. Scraping real requiere permiso separado y límites económicos verificados. No desplegar Service ni compartir credenciales/datos productivos con demos.

## 8. Acta de cierre Fase 0 y pendientes

- Ejecutado: lectura y diagnóstico readonly, copias documentales nuevas, inventarios, diff/contrato/CI/PR/dependencias y estos entregables.
- No ejecutado: creación de ramas/worktrees, fuente/config existente, instalaciones, tests funcionales/builds, migraciones, datos, PR/reviews/push/merge, Render/Vercel/Supabase o Service.
- Pendiente del owner ahora: **aprobar G0 exclusivamente para las dos ramas y worktrees propuestos**, con parada en G1. La pregunta final de esta entrega tiene ese alcance y deriva del plan rector §4, filaG0, y §5/9.
- Pendiente después: revisión G1 del cambio exacto/demos; gates sucesivos; infraestructura/release cuando corresponda; recuperar cuestionario de 26 respuestas original si se requiere traza por sus IDs. JWT snapshot y exclusión de P2 ya están decididos.

La autorización no se presume ni se obtiene por omisión. Hasta recibir respuesta explícita, no se realiza el siguiente tramo.
