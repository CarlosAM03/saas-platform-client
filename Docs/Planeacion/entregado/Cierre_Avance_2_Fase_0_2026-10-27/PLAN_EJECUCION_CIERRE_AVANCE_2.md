# PLAN DE EJECUCIÓN DEL CIERRE — AVANCE 2

Fecha: 27 de octubre de 2026.

Autoridad: Plan de TrabajoAvance2.md del owner, leído íntegramente (435 líneas; SHA256 df1552887869b3a79d87034b135022c2df265c399ce4c777a654601b5e445f09). Copia congelada: [plan rector](evidencias/PLAN_RECTOR_SNAPSHOT.md). Esta entrega ejecuta exclusivamente Fase 0; G0 pendiente de autorización explícita. Los cambios de implementación descritos son futuros, no aplicados.

Entregables relacionados: [plan de ejecución](PLAN_EJECUCION_CIERRE_AVANCE_2.md), [matriz de cambios](MATRIZ_CAMBIOS_AUTORIZADOS.md), [baselines y ramas](BASELINES_Y_RAMAS.md), [gates](GATES_DE_ACEPTACION.md).

## 1. Resumen ejecutivo

**GO técnico para solicitar G0 y preparar dos ramas core en worktrees aislados. Autorización G0 PENDIENTE; ejecución detenida.** No se implementó Fase 1 ni posteriores.

Backend base: origin/main 3a3309398458ab333d7b00f16e9c2df6a09ef734. Flutter base: Foundation PR #7 095e899ace31acf17d97bbe945c118c1a5d88682. Los remotos y heads de PR siguen iguales a la auditoría. Backend main/dev tienen árbol idéntico y ya incluyen CSV. Foundation conserva main/PR #5 y aportaciones útiles de André; dev actual tiene162marcadores en15archivos y CI rojo. La prioridad es consolidar Frontend con el parche mínimo de seguridad Backend, sin completar Python.

El owner confirma Backend main/Render y PostgreSQL/Supabase estables como autoridad funcional. Se comprobó independientemente salud200 y OpenAPI 1.0.0 con33operaciones, semánticamente idéntico a deploymentDocument del main en openapi/info/paths/components/tags/servers. SHA256 canónico compartido: 2d256a417394c2641266326f654bd2b2e58ac26a51185f2f444e9e87edf8c7a1. Igualdad del documento no identifica por sí sola el binario desplegado ni las migraciones aplicadas; se mantiene esa limitación sin contradecir la autoridad declarada por el owner.

La web pública responde200. El preview indicado responde302 SSO y Render no devuelve ACAO para su origen en el sondeo. Si ese browser llama directamente a Render, CORS impediría esa lectura; no se probó el flujo privado/proxy del preview ni se cambió infraestructura. E2E aislada permite validar core sin depender de ese acceso.

Dos decisiones antes pendientes ya están resueltas: **JWT snapshot y schema baseline**. P2 queda excluido y Node 20 diferido como deuda prioritaria. La copia YAML de Foundation todavía describe Snapshot PG/TTL de una hora: corregir documentación y consumidores afectados sin ampliar Backend. La matriz delimita esa selección.

## 2. Alcance y fuentes

Objetivo: FlutterWeb/Vercel → API existente NestJS/Render → PostgreSQL/Supabase. Auth, sesión, tenants, usuarios/RBAC, campañas, prospectos manuales, CSV, dashboard y lectura de Jobs son reales. Service/Engine quedan fuera del cierre y no son dependencia operativa.

Las acciones externas siguen deshabilitadas/503. La demo visual está aprobada en alcance, con rótulo **DEMO — SIN EJECUCIÓN REAL**, estado local y separación del SDK, negocio, conteos e historial. No habilitar create ni simular respuestas HTTP productivas.

Se leyó el plan completo,435 líneas, y se congeló con su hash. Declara26decisiones recibidas, pero no incluye el cuestionario original; D01–D18 de la matriz son agrupaciones de instrucciones expresas y no sustituyen sus IDs. Se consultaron auditoría, anexos de ramas/clasificación/hallazgos/contrato y ADR pertinentes. ADR-003/004 confirman snapshot; ADR-005Jobs está marcado histórico/propuesta. FlutterADR-005 está aceptado. ServiceS-01…08 siguen siendo decisiones P2 pendientes.

Las instrucciones actuales del owner prevalecen sobre propuestas históricas: no upgrade de Node ahora, no migración P2, no JWT vivo ni contratos nuevos para satisfacer pantallas. No modificar los informes antiguos para aparentar unanimidad retrospectiva.

## 3. Trabajo realizado en Fase 0

1. Verificar cuatro raíces Git/origin, HEAD/rama, status, refs/upstreams, fechas/autores, worktrees, stashes y commits no publicados. Consultar ls-remote sin fetch ni actualización de referencias.
2. Reconsultar PR #5 Backend/Flutter, PR #6 Backend, PR #6/7/8 Flutter y ServicePR1. Enumeración pública de abiertos:1 Backend,3 Flutter,0 Service/Engine. Reviews formales vacías. Consultar CI y deployments existentes, sin disparar workflows.
3. Confirmar ancestry main/dev→Foundation y PR #8 apilado; schema core/main/dev; diff selectivo SEC-01/config y módulos de Foundation sin aplicar parches.
4. Preservar los dos documentos Flutter sin seguimiento y el blob publicado del plan eliminado mediante copias nuevas y hashes. Avance1 conserva el mismo texto del plan anterior al normalizar CRLF/LF; los bytes difieren y se preservan ambas versiones. No restaurar, mover, stagear o decidir el rename.
5. Comparar contrato público con función pura deploymentDocument revisada y YAML inmutable, evaluados en memoria sin arrancar Nest ni conectar DB. Sondear GET/OPTIONS de salud, web y CORS, sin login/escrituras. El acceso web genérico falló; HTTP directo permitió completar la comprobación sin eludir autenticación.
6. Definir cambios, pruebas y ramas concretos, y generar los cuatro informes en un directorio nuevo fuera de los repositorios. Verificar integridad final frente al inicio.

**Pruebas funcionales nuevas: NINGUNA.** Diffs, hashes, evaluación pura del documento y sondeos readonly son comprobaciones preparatorias. La CI consultada y los tests de la auditoría anterior no se presentan como ejecuciones de Fase 0. No se instalaron dependencias, ejecutaron builds/migraciones ni arrancaron servicios.

## 4. Ocho fases canónicas y puertas

Se conservan F0–F7 del §3 del documento. El prompt maestro §5/6 las agrupa en F0–F6; esta correspondencia evita perder CSV/Dashboard/Jobs o saltar controles.

|Fase|Objetivo|Salida|Equivalencia interna|Puerta|Estado|
|---|---|---|---|---|---|
|F0|Congelación y trazabilidad|Baselines, trabajo protegido, contrato, matriz y ramas propuestas|Maestra F0|G0 antes de crear ramas|PREPARACIÓN COMPLETA; DETENIDA|
|F1|Hardening selectivo Backend|SEC-01/config/tests, con snapshot y schema baseline|Maestra F1|G1 código; G2 pruebas|NO INICIADA|
|F2|Consolidación Flutter|Foundation + PR #5 + UI válida de André; contrato1.0.0|Maestra F2|G1/G2|NO INICIADA|
|F3|CSV, Dashboard, Jobs y demo|Operaciones reales y demo visual aislada sin efectos|Maestra F2 y validación posterior|G1/G2; aceptación G3|NO INICIADA|
|F4|E2E del núcleo|PG core desechable, dos tenants, sesión/CSV/contrato y cero P2|Maestra F3|G2/G3|NO INICIADA|
|F5|Integración y aceptación dev|PR propuestos, dependencias resueltas y commits recertificados|Maestra F4|G3 propuesta; merge expreso; G4|NO INICIADA|
|F6|Main y despliegue|Release, atestación, rollback; Backend solo si necesario|Maestra F5|G4 propuesta; G5 despliegue|NO INICIADA|
|F7|Preparación posterior1.1|Preservación P2, contratos Service/Engine y propuesta Compose|Maestra F6|G6 y alcance experimental específico|NO INICIADA|

La tabla de gates gobierna las acciones: G0 ramas; G1 implementación; G2 pruebas aisladas; G3 propuesta PR dev; G4 propuesta main; G5 despliegue; G6 tramo experimental. Una fase que mencione implementar no salta G1. Aprobar una propuesta tampoco autoriza automáticamente merge/push.

## 5. Dependencias y orden mínimo

Baselines congelados → G0 → dos ramas/worktrees → revisión G1 de selección/diseño → implementación local → diffG2 → pruebas aisladas/E2E → aceptaciónG3 → propuesta dev → merge expreso y checks del integrado → G4 → propuesta main/release/rollback → G5 → verificación productiva → eventualG6.

Backend B01–B08: protección global SEC-01, configuración/errores/tests independientes. No copiar JwtStrategy vivo, helpers asociados, parser callback, schema, Jobs nuevo o deploymentDocument1.1. Overrides B06 requieren evidencia y selección en G1, sin actualización general ni runtime upgrade.

Flutter F01–F09: Foundation ya recupera el core. Preservar SDK, visual y responsive; corregir documentación de Snapshot PG/TTL y discrepancias demostradas de consumidores. Consolidar CSV/dashboard/Jobs y demo en presentación aislada. No crear endpoints Backend ni reaplicar PR #5 ya integrado.

El plan no depende de PR #6 Backend, PR #8 Flutter, despliegue Service, browser/Maps, almacenamiento nuevo, TTL/cuotas o recuperación automática. Las ramas P2 se conservan, sin retarget/borrado durante esta fase. El alcance definitivo1.1 no se aprueba por existir código.

## 6. Tramo concreto sujeto a G0

Preparar únicamente:

- Backend: fix/avance2-core-security desde 3a3309398458ab333d7b00f16e9c2df6a09ef734.
- Flutter: release/avance2-frontend-v1 desde 095e899ace31acf17d97bbe945c118c1a5d88682.

Destinos absolutos y argumentos revisables en [BASELINES_Y_RAMAS](BASELINES_Y_RAMAS.md) y [evidencia14](evidencias/14_OPERACIONES_PROPUESTAS_G0.json). Las ramas y destinos no existen al preflight. Nuevos checkouts preservan el original P2 y los documentos del usuario; no se crea nada en Service/Engine.

Antes de ejecutar, revalidar remotos, status/copias, destinos y hooks. Detenerse ante deriva; no forzar. Después, registrar HEAD/rama/limpieza y **parar en G1 antes de editar, instalar, compilar, probar, commitear o publicar**. El permiso G0 solicitado no incluye ninguna de esas acciones posteriores.

## 7. Pruebas previstas

Todas **NO EJECUTADAS**; requieren G2 y revisión previa del entorno/efectos. T13 corresponde a gates posteriores de aceptación/release.

|ID|Prueba|Entorno/precondición|Criterio de aprobación|
|---|---|---|---|
|T01|Backend lint:check/format:check, tipos y build|Checkout candidato, sin autofix|Sin errores; outputs aislados; Node 20 del candidato explícito|
|T02|Unit/HTTP de Auth, RBAC y SEC-01|Mocks identificados solo en tests|Shared A/B y ADMIN ajeno403; self/local/roles contractuales; atomicidad|
|T03|PostgreSQL core desechable|Autorización G2 explícita de DB loopback única|Solo init core; ocho modelos; sin tablas/columnas P2|
|T04|E2E Flutter→Nest→PG real|Datos sintéticos, API real y Service ausente|Auth/tenants/users/campaigns/prospects/CSV/dashboard/Jobs lectura en dos tenants|
|T05|CSV por fila y concurrencia|Archivos sintéticos y mismos bytes/referencia|CREATE/LINK/UPDATE/SKIP,409 stale/replay,403/404,413 y rollback íntegro|
|T06|Dashboard y Jobs reales|n>límite de página, refresh CSV y cambio A→B|meta.total real; sin demo en conteos/historial; results/progress null baseline|
|T07|Flutter buildrunner/analyze/tests/build|Solo checkout nuevo; SDK/lock baseline|Sin marcadores; tipos/errores/envelopes; responsive y accesibilidad acotada|
|T08|Sesión y respuestas/diálogos tardíos|Requests diferidos, logout/login y cambio tenant|No datos del scope anterior;401 viejo no cierra nueva sesión; pickers/CSV limpios|
|T09|Demo visual aislada|Componentes locales y captura de efectos/red|Rótulo visible siempre; cero HTTP/mutaciones; sin historial/conteos falsos|
|T10|Ausencia de prospección externa|node:http(s), Dio y canario; sin claves Service|Cero create/cancel/persist/export/callback/capabilities1.1; fetch solo no basta|
|T11|Contrato ejecutable y drift|Comparar candidato, público baseline y DTO/requests|Core preservado; sin1.1/TTL/schema; rutas no disponibles503|
|T12|Imagen/SPA/API_BASE_URL/CORS|Build test local distinto del artefacto productivo|Fallback/headers correctos; sin secretos ni API loopback en bundle productivo|
|T13|Aceptación dev/release/rollback|Después de G4/G5 y permisos concretos|SHA/config/artefactos, backup/restauración, rollback y deuda Node 20 visibles|

No ejecutar ahora prisma:migrate:deploy, seed o Compose: escriben. Una autorización G2 futura deberá delimitar explícitamente la DB desechable y la preparación con migración core existente; nunca Supabase o bases compartidas, ni crear una migración nueva. No usar la DB demo previa con P2 como evidencia única.

npm run lint tiene --fix; en validación futura usar lint:check y format:check. Builds/generación y dependencias solo en checkout aislado y con permiso del gate. Diferenciar build de prueba con API local del artefacto productivo compilado para Render.

Instrumentar node:http(s)/Dio/canario para ausencia de tráfico externo. El contador fetch anterior no cubre ese transporte. Capturar por separado el tráfico CRUD/CSV permitido y los efectos de la demo; no ocultar actividad real bajo fixtures.

## 8. Riesgos y tratamiento

|ID|Severidad|Riesgo|Tratamiento|Impacto en gate|
|---|---|---|---|---|
|R01|ALTO|Arrastrar PR #6/42b96 entero|Seleccionar por método/hunk y verificar JWT/Prisma/Jobs contra baseline|Bloquea código si aparece P2; no G0|
|R02|ALTO|Documentos locales y checkout Flutter experimental|Copias exactas y Git publicado; nuevos checkouts sin limpiar el original|Trabajo protegido; versionado documental posterior|
|R03|ALTO|dev Flutter con conflictos y CI rojo|Foundation correctivo; no promover c7 directo a main|No G0; validar candidato después|
|R04|MEDIO|Documentación Foundation de Snapshot PG/TTL|F01 y contrato servido1.0.0 sin ampliar Backend|Cerrar antes de G3|
|R05|MEDIO|Alias/contrato no atestan binario/DB|Registrar confirmación del owner y límites; atestar release al promover|Pendiente G5; no bloqueo de ramas|
|R06|MEDIO|Preview SSO y sin ACAO directo a Render|No bypass/config automática; E2E aislada y origen de aceptación específico|Solo afecta aceptación de ese preview|
|R07|ALTO residual|Node 20 fuera de soporte, diferido|Deuda prioritaria inmediatamente después del cierre; no upgrade ahora|Riesgo visible, secuencia decidida por owner|
|R08|ALTO|DB ya P2 y contador fetch insuficientes|PG core nuevo y transporte real instrumentado en validación|Pendiente G2/G3|
|R09|BAJO documental|Cuestionario26 original no transcrito|Trazar instrucciones expresas sin inventar IDs originales|No bloqueo artificial de G0|

Node 20 no se considera riesgo resuelto: la actualización inmediata posterior al cierre queda visible como deuda prioritaria decidida por el owner. No se transforma la recomendación anterior de actualizarlo antes en un cambio no autorizado. El release posterior debe conservar el riesgo registrado y seguimiento.

No se observó pérdida de datos ni explotación productiva. SHA/config/backups/secretos y migraciones efectivas se atestan al preparar release con el acceso autorizado que corresponda; no acceder a paneles privados para cerrar G0.

## 9. Entregables y pendientes

Directorio nuevo: C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\00-Docs\Analisis\Cierre_Avance_2_Fase_0_2026-10-27.

- PLAN_EJECUCION_CIERRE_AVANCE_2.md: secuencia, alcance, dependencias, riesgos y pruebas futuras.
- MATRIZ_CAMBIOS_AUTORIZADOS.md: instrucciones expresas, selección por componente, exclusiones y contrato.
- BASELINES_Y_RAMAS.md: Git/PR/CI/dependencias, preservación documental y preparación concreta.
- GATES_DE_ACEPTACION.md: criterios G0–G6, permisos habilitables y acta de parada.

Evidencias01–14 registran las comprobaciones y copias;15 conserva integridad Git final;16 QA/fuentes y documentos;17 manifiesto SHA256. No se alteraron fuentes, documentos del usuario ni auditorías anteriores.

Pendientes reales: autorización G0 de los nombres/bases/preparación aislada; G1 de hunks y diseño demo; gates posteriores de pruebas/PR/promoción/despliegue; acceso/origen del preview y atestación de release cuando corresponda; cuestionario de 26 respuestas original si se necesita su numeración. JWT snapshot y exclusión de P2 ya están decididos. Service/Engine/Compose esperan G6.

**DETENIDO EN G0. GO técnico no sustituye autorización del owner.**
