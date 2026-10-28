# PLAN RECTOR — Sprint de estabilización Flutter y paridad 1:1 con Platform Backend

**Proyecto:** PROSPECTOR SaaS — Segundo Avance / Core V1 y ampliación ADR-006  
**Estado:** Plan formal del sprint; ejecución y aceptación pendientes  
**Fecha de corte:** 27 de octubre de 2026 (America/Tijuana)  
**Responsable de arquitectura, integración, QA y promoción:** Carlos, owner técnico  
**Responsable del módulo Backend ADR-006 y posterior adaptación Flutter:** Ángel  
**Repositorio de ejecución primaria:** `CarlosAM03/saas-platform-client`  
**Repositorio de autoridad de API:** `CarlosAM03/saas-platform-backend`  
**Naturaleza del documento:** Plan rector; no constituye evidencia de pruebas realizadas ni autorización de merge/despliegue.

## 1. Propósito

Restablecer y demostrar **paridad funcional, contractual y de seguridad 1:1** entre el cliente Flutter Web y el comportamiento **implementado** del Platform Backend NestJS V1.0.0, manteniendo intactas las capacidades del core que ya funcionan. El sprint añade una suite E2E trazable de **interfaz real → estado y repositorio Flutter → `PlatformApi`/`ApiClient` → NestJS → Prisma → PostgreSQL**, con ejecución local integral y remota dentro de las autorizaciones y posibilidades del entorno.

Después de cerrar el core 1.0.0, se integrará mediante una línea de trabajo **separada** la ampliación aprobada ADR-006 de registro asistido de tenant, activación del primer OWNER por enlace y administración de acceso, sin mezclar su desarrollo inicial con el hardening del frontend actual.

**Definición operativa de 1:1:** cada operación consumida en la UI debe coincidir con ruta, método, validación, autorización, DTO, estados HTTP y disponibilidad real de la API Backend desplegada. No significa que todas las capacidades del contrato objetivo futuro estén implementadas, ni que Flutter deba reproducir decisiones de autorización que pertenecen a NestJS.

## 2. Referencias y jerarquía de autoridad

Referencias verificadas el 27 de octubre de 2026:

| Orden | Fuente | Uso obligatorio |
|---|---|---|
| 1 | Código efectivo Backend `main` **`b51b265f1a545fa915f1dd1c57ef2f5858ec6492`** y pruebas de su repositorio | Verdad del comportamiento V1.0.0; validar SHA real del deployment antes de llamar algo «productivo» |
| 2 | Backend `Docs/Contracts/platform-api.v1.yaml` y `src/common/openapi/deployment-document.ts` (`/api/docs-json`) | Distinguir contrato **objetivo** y **documento implementado**: este último muestra Jobs no disponibles |
| 3 | Backend `Docs/ADRs/ADR-004-CommonBaseline.md`, `ADR-003-AuthSecureTransversal.md`, `MODULE-DEVELOPMENT.md`, `Docs/Avance2/CORE_V1_VALIDATION.md` | Seguridad, JWT, aislamiento, responsabilidades y limitaciones aprobadas |
| 4 | Flutter `main` **`7731649a2c69b45cb9776d02de4a6105d6fd9886`** y su código efectivo | Línea base de estabilización del cliente |
| 5 | Flutter `Docs/ADRs/ADR-005-FlutterFoundation.md`, `FEATURE-DEVELOPMENT.md`, `Docs/Contracts/*`, `Docs/Despliegue-Web.md` y pruebas | Convenciones del cliente, ownership, contrato local y límites operativos |
| 6 | `ADR-006-TenantRegistration-APROBADO.md` y `platform-api.tenant-registration.approved.yaml` aprobados por el owner y entregados a Ángel | **Autoridad futura** exclusiva de la ampliación; aún no implementación ni disponibilidad productiva |
| 7 | Informes y auditorías históricas | Evidencia contextual fechada, **no** reemplazan un SHA actual ni el código observado |

Si una guía histórica de Flutter afirma que el YAML local es idéntico al Backend mientras otro documento lo niega, **no elegir una afirmación por antigüedad o conveniencia**: comparar los archivos y la vista desplegada, documentar el diff y preservar por separado las respuestas objetivo de Jobs (`x-target-responses`) y su indisponibilidad efectiva (`503`).

**Precondición de ejecución:** revalidar con Git los SHA, estado de ramas, PRs abiertos, árbol limpio, acceso y pipelines. Los SHA anteriores son referencias congeladas del análisis, no una afirmación sobre un nuevo despliegue. El PR #8 de Flutter y el PR #6 de Backend están vinculados con Prospector experimental y **no forman parte del sprint** salvo autorización posterior.

## 3. Decisiones aprobadas y límites arquitectónicos

1. Flutter es un **cliente HTTP**; no accede directamente a PostgreSQL, FastAPI/Prospector Service ni al Engine. No ejecuta scraping, no toma decisiones definitivas de autorización y no fabrica resultados de Jobs.
2. Mantener `lib/core/network/api_client.dart` (Dio encapsulado), `lib/platform_api`, DTO tipados, repositorios por feature, Riverpod, `sessionScopeProvider`, `TenantPermissions` y el router existente. No introducir un segundo cliente HTTP, un segundo router ni repositorios duplicados.
3. Multi-tenant: **Shared Database + Shared Schema + tenantId**. El tenant operativo procede del JWT/contexto autenticado; ningún tenantId de formulario puede convertirse en autoridad. `ADMIN` es global; `OWNER` y `MEMBER` son roles del tenant.
4. JWT HS256 de ocho horas y **snapshot** de membresía/rol. La revocación inmediata por cambio de rol es deuda aceptada del Backend 1.0.0; Flutter no debe aparentar que la corregirá con otra política de autorización.
5. `SEC-01`: la identidad `User` es global. Un `OWNER` no puede modificar atributos globales de una identidad compartida entre tenants; cambios locales de membresía siguen su regla específica. Las actualizaciones UI enviarán **solo campos realmente modificados**.
6. Jobs de Core V1: **GET lista/detalle disponibles**; inicio, cancelación, persistencia y exportación reales **no disponibles**, con 503 y `details.reason=PROSPECTOR_INTEGRATION_PENDING` según endpoint. No activar Service ni resultados simulados como éxito.
7. Backend V1.0.0 permanece congelado como contrato de estabilización. No cambiarlo para ocultar un defecto del frontend ni actualizar V1 para incorporar ADR-006 prematuramente.
8. ADR-006 aprobado **solo como ampliación posterior**: ADMIN registra tenant y primer OWNER; enlace de activación de 24 h, canje por desafío de 15 min y establecimiento de contraseña; proveedor de correo sin costo y feature flag desactivado por defecto; no pagos, membresías comerciales, cuotas MEMBER ni registro público.
9. El owner técnico autoriza cambios de arquitectura, contrato, merge, configuración productiva y despliegue. Codex ejecuta solamente el trabajo explícitamente autorizado en su rama y entrega evidencia.
10. No redefinir responsabilidades, reglas existentes ni formularios en función de hipótesis; toda divergencia material pasa a registro de hallazgos y decisión humana.

## 4. Alcance del sprint

### 4.1 Incluido — Estabilización Core V1.0.0

- Autenticación: login, `me`, restauración de sesión, expiración, logout, rutas protegidas, manejo correcto de 401 y conservación de 403.
- Tenants: descubrimiento ADMIN incluso cuando tiene membresías; selección y cambio; invalidación de estado, formularios y solicitudes tardías.
- Usuarios **existentes**: listado, detalle, edición mínima PATCH, status, permisos y SEC-01; validación del comportamiento ya contratado de creación de usuario sin **rediseñar** el flujo de alta ni implementar el nuevo onboarding.
- Campaigns: CRUD autorizado, paginación, filtros, cambio de estado, archivo, eliminación permanente únicamente ADMIN.
- Prospects: listado/detalle, alta manual autorizada, edición, null frente a omitted, aislamiento entre campañas/tenants.
- CSV: selector, preview/confirm utilizando bytes originales, cuatro decisiones contractuales, límites, errores, resultados y persistencia.
- Dashboard: datos reales y estados de error. Evitar que una consulta no crítica inutilice innecesariamente el conjunto cuando sea seguro hacerlo; no inventar métricas.
- Jobs: solo lectura real de registros; 503 explícito para operaciones deshabilitadas; mantener distinción del source contractual de Jobs frente a fixtures históricos.
- Seguridad transversal: roles, sesión, diálogos, almacenamiento de token, logs sanitizados, CORS y configuración de API base.
- Tests unitarios/widget/contrato, P2C, suite UI→API→PostgreSQL local, smoke remoto autorizado, CI, evidencias y documentación ajustada.

### 4.2 Incluido — Preparación de integración ADR-006 (sin implementarla en este sprint de frontend)

Preparar una frontera de integración: inventario del contrato aprobado, puntos de extensión en Auth/Router/API Client y casos E2E futuros. **No** anticipar pantallas de activación ni emitir llamadas a endpoints inexistentes en Backend `main`. Al recibir PRs y evidencia de Ángel, abrir una fase independiente con su propia revisión/QA y gate de compatibilidad, antes de habilitar la función.

### 4.3 Excluido

Prospector Service real, búsqueda/scraping, Jobs mutantes, outbox de Jobs, cuotas y facturación, pagos, suscripciones, registro público, PEM/CER, OAuth, refactorización mayor de Foundation, migraciones Backend durante fase Core, cambios directos al Backend, nuevas funcionalidades no documentadas, integración de PRs experimentales. No aceptar operaciones «simuladas» como funcionamiento real.

## 5. Hallazgos priorizados que guían el trabajo

| ID | Prioridad | Evidencia en Flutter `main` | Resultado esperado |
|---|---|---|---|
| FE-01 | P1, confirmado | `lib/features/users/presentation/users_pages.dart`: edición envía `name`, `email` y `status` aun sin cambios | `PATCH` diferencial; respetar SEC-01, evitar falsas mutaciones globales; pruebas de identidades compartidas |
| FE-02 | P1, condicionado | `lib/features/auth/presentation/auth_pages.dart`: discovery ADMIN solo si `context.tenants` está vacío | ADMIN puede descubrir tenants globales independientemente de sus propias membresías; no alterar autoridad ni contexto |
| FE-03 | P1, riesgo de consistencia | `lib/features/auth/state/tenant_permissions.dart`: lee rol actual desde `/users/{id}` mientras Backend autoriza por JWT snapshot | Política visual explícita, compatible con token vigente; no prometer revocación inmediata ni relajar guards Backend |
| FE-04 | P2, capacidad expuesta incompleta | UI de edición de usuario no ofrece el `roleId` ya admitido por API | Evaluar con owner: cubrir contrato existente solo si no amplía alcance ni colisiona con onboarding |
| FE-05 | P2, resiliencia | Dashboard usa `Future.wait` para campañas/prospectos/Jobs | Distinguir fallo de sección del fallo general; diseñar sin falsear datos ni silenciar errores |
| FE-06 | P2, UX/paginación | Filtro de estado de campañas aplicado a página actual | No presentarlo como filtrado global; corregir si API admite semántica necesaria sin crear endpoint |
| FE-07 | P2, fixture heredado | Seed local de Jobs con `query.source="demo"` frente al enum contractual `google_maps` | Mantener evidencia del drift; no convertir `demo` en source público válido para ocultarlo |
| FE-08 | P2, diagnósticos | Errores de parser/`FormatException` llegan a mensajes genéricos | Registrar diagnósticos sanitizados con diferenciación observable; no exponer datos sensibles |

**Clasificación:** FE-01 es discrepancia de comportamiento demostrada por código. FE-02/03 requieren escenarios reproduci­bles para fijar el impacto efectivo; FE-04–08 son candidatos y deuda menor, no fallos productivos certificados. Codex no marcará nada como corregido sin prueba antes/después.

## 6. Estrategia paralela, ramas y responsabilidades

### Fase Core (actual)

- **Carlos / Codex, Flutter:** rama `sprint/frontend-core-v1-parity` creada desde `origin/main` verificado. Resolver FE-01–FE-03, pruebas, paridad y evidencia. Revisión humana antes de merge; no escribir en Backend remoto.
- **Ángel / Codex, Backend:** rama segura basada en Backend `main` productivo para ADR-006; entrega documentación, cambios, migraciones, pruebas y preferentemente PR abierto. No modifica el Frontend Core que estabilizamos.

### Intercambio posterior

- Carlos revisa y prueba PR Backend ADR-006, migraciones y despliegue controlado.
- Ángel adapta Flutter para las cinco operaciones de activación conforme al YAML aprobado, partiendo **del frontend estabilizado**, no de un HEAD experimental.
- Carlos realiza QA de ambos PRs, promoción autorizada y smoke posterior. El frontend no debe llamar endpoints nuevos antes de que estén disponibles y el feature flag esté habilitado con la versión compatible.
- Promoción recomendada: PR de sprint → `dev` limpio y reconciliado → `main` mediante aprobación, respetando reglas reales del repo. Si `dev` contiene cambios ajenos, detenerse y acordar una ruta de release aislada; no fusionar contaminación experimental ni forzar `main`.

**Autoridad:** Ángel es responsable de implementación y de su diseño técnico en el módulo delegado. Carlos conserva la decisión final sobre arquitectura, contrato, seguridad, integraciones, PRs y despliegues.

## 7. Fases operativas del sprint y entregables

| Fase | Objetivo | Condición de salida |
|---|---|---|
| P0. Inventario y baseline | SHA, ramas, CI, contratos objetivo/implementado, documentación, inventario de casos | `baseline.json` + matriz de operaciones, diferencias y riesgos; sin cambios de código |
| P1. Regresiones prioritarias | Reproducir y corregir FE-01, FE-02 y FE-03 con tests específicos | Tests fallan antes/aprueban después; cambios pequeños sin nuevas API |
| P2. Cobertura Core | Revisar Auth/Tenants/Users/Campaigns/Prospects/CSV/Dashboard/Jobs por operación y rol | Matriz funcional 1:1 con PASS/FAIL/BLOCKED/NOT RUN; P2 separados |
| P3. E2E local integral | Browser Flutter real → API real → Prisma → PostgreSQL16 efímero | Escrituras, lecturas, integridad, negativos y aislamiento comprobados; fixtures limpiados |
| P4. CI y PR Flutter Core | Analyze, build_runner, `flutter test`, build Web, contenedores, P2C/E2E donde CI lo soporte | Checks verdes con SHA del PR; revisión de diff y evidencia de regresiones |
| P5. Smoke remoto Core | Vercel/Render autorizados y SHA real, CORS, Auth, UI, lecturas y escrituras de prueba permitidas | Evidencia de ejecución o bloqueo declarado; no suponer acceso a DB productiva |
| P6. Recepción ADR-006 | Auditoría del PR Backend, migración, seguridad, contrato y test de regresión | Dictamen QA; funciones deshabilitadas hasta el release coordinado |
| P7. Paridad extendida | Flutter de Ángel + nuevo Backend; E2E activación local y remoto autorizado | Dos repositorios y despliegues compatibles; E2E extendida verde |
| P8. Cierre Avance 2 | Reporte, versiones, evidencia, rollback, demo y deuda residual | Aprobación expresa del owner; nunca aceptación implícita de Codex |

Las fases P6–P8 tienen dependencia externa y **no** autorizan a Codex de Flutter Core a implementar ADR-006 mientras P1–P5 estén abiertas.

## 8. Estrategia de pruebas — No negociable

### 8.1 Pirámide y reutilización

- **Unidad/widget:** `flutter test`, pruebas de sesión, permisos, routers, DTO, formularios y errores.
- **Contrato:** `test/platform_api/platform_api_contract_test.dart` y fixtures locales; comparar además con Backend efectivo, pues pruebas contra YAML del mismo frontend pueden pasar con drift.
- **P2C integración:** extender/reutilizar `tool/platform_api_p2c_test.dart` (Flutter `PlatformApi` → NestJS → PostgreSQL local), sin ejecutar sus fixtures SQL contra hosts no locales.
- **HTTP y DB Backend:** aprovechar evidencia del repositorio Backend, sin asumir que certifica el HEAD productivo; no reescribir aquí los tests ajenos.
- **UI E2E real:** reutilizar `ops/avance2/verify-ui.mjs`, `ops/avance2/verify-runtime.mjs` y `ops/avance2/Start-Core.ps1` cuando estén disponibles, complementándolos con escenarios de escritura y verificadores PostgreSQL. Esos scripts existentes son **smoke parciales**, no suite completa UI→DB.

### 8.2 Cadena de aceptación por escenario

1. Navegador interactúa con el control real (no llamadas directas a API en sustitución de la UI).
2. Estado/repository/`PlatformApi` construyen solicitud de acuerdo con DTO y sesión/tenant.
3. NestJS valida JWT/rol/tenant/entrada y produce respuesta conforme al contrato implementado.
4. PostgreSQL local verifica inserción, relación y campos; en errores, ausencia de escritura parcial.
5. Navegador comprueba el estado después de la respuesta y una **recarga o sesión independiente**.
6. Evidencia captura `caseId`, SHA cliente/servidor, entorno, rol, tenant sintético, ruta/método/status, `requestId` si disponible, aserciones DB, cleanup y PASS/FAIL/BLOCKED/NOT RUN.

### 8.3 Matriz mínima de escenarios

| Grupo | Casos obligatorios |
|---|---|
| Auth/session | Login válido/erróneo, ADMIN sin tenant, expiración/401, logout, deep-link protegido, petición tardía tras cambio de cuenta |
| Aislamiento | Dos tenants A/B con ADMIN, OWNER y MEMBER; navegación, búsquedas y detalles cruzados, intentos de mutación indebida, sin filtraciones UI/cache/DB |
| Users | Editar solo campo modificado; identidad compartida y SEC-01; permiso de lectura vs edición; desactivación ADMIN; cambios de rol conforme contrato existente si autorizados |
| Campaigns | Crear/editar/cambiar estado/archivar/borrar ADMIN; buscar/paginar; comprobar tenant y persistence después de recarga |
| Prospects | Creación manual, edición de nullable, fuente persistida, relación campaña, 403/404 inter-tenant |
| CSV | Archivo original preview/confirm; CREATE, LINK_EXISTING, UPDATE_EXISTING, SKIP; conflicto, expiración, 413 y comprobación de no duplicados |
| Dashboard | Totales desde `meta.total`, cambio de tenant y carga/error parcial, sin métricas inventadas |
| Jobs | GET list/detail de fixtures contractuales; cuatro operaciones públicas no disponibles y su 503; no scraping real |
| Security/ops | 400/401/403/404/409/413/429/503, CORS positivo/negativo, tokens no filtrados, API_BASE_URL correcto y logout seguro |

**No forzar expectativas contrarias al Backend:** `OWNER` puede gestionar ciertos usuarios locales bajo SEC-01, pero la identidad global compartida conserva restricciones; permisos de creación de prospectos y eliminación de campañas se toman de los guards reales, no de etiquetas en UI. No interpretar datos seed antiguos fuera de contrato como nueva semántica pública.

### 8.4 Local — Cobertura completa

Ejecutar build Flutter y Backend reales con PostgreSQL16 dedicado, datos sintéticos y Docker Compose aislado. Reutilizar infraestructura `ops/avance2` donde sea apropiado; cualquier nueva automatización debe ser repetible, sin requerir secretos versionados. No usar `docker compose down -v` sobre volúmenes compartidos ni alterar fixtures ajenos. Verificaciones SQL directas exclusivamente en DB de ensayo, preferentemente efímera, con teardown acotado a entidades creadas por la ejecución.

UI automatizada mediante navegador real: selectores semánticos estables disponibles en Flutter Web, espera de estados observable y capturas sanitizadas en fallos. Si automatización web no puede interactuar con un control por limitación de semántica, marcar `BLOCKED` y agregar prueba complementaria; no contabilizar como E2E aprobada. Configuración TLS de prueba no debe debilitar la validación productiva.

### 8.5 Remoto — Alcance permitido

Apuntar al **URL exacto desplegado de Vercel** y comprobar origen HTTPS de Render configurado en el artefacto real (`API_BASE_URL` se fija en build; no basta modificar variables runtime). Confirmar SHA desplegados y CORS antes de atribuir resultados a `main`. Ejecutar primero health/read-only y navegaciones autenticadas con cuentas autorizadas. Escrituras, reenvíos de correo o alteración de estado solo en staging dedicado o con permiso explícito, fixtures marcados y cleanup verificado. **Nunca** montar el usuario DB administrativo en el navegador ni usar SQL destructivo sobre PostgreSQL de producción.

La verificación de persistencia mediante recarga + GET autenticado remota es evidencia **indirecta**; solo declarar «SQL/PostgreSQL remoto verificado» cuando exista una conexión read-only autorizada y la consulta SQL haya sido efectivamente ejecutada. Si Vercel/Render/Supabase no son accesibles desde el ejecutor, marcar `BLOCKED` con causa reproducible, no `PASS` ni `FAIL` del producto por inferencia.

### 8.6 ADR-006 — E2E extendida tras recibir PR Backend

En una fase separada: ADMIN registra Tenant + OWNER; se verifica atomicidad; buzón gratuito/de pruebas acepta enlace de 24h sin contraseña; canje produce desafío de 15 min; nuevo password; `LOGIN_REQUIRED`; login normal; invalidación de enlace/desafío; reenvío, límites y fallos SMTP; ausencia de JWT previo; SEC-01 y no regresión de usuarios previos. La adaptación Flutter se ejecuta **después** del core estable y la disponibilidad backend comprobada; jamás presentar estos endpoints como funcionando cuando están solo en el YAML aprobado.

## 9. Reglas de calidad, seguridad y operación

- No modificar backend, schema Prisma, migraciones, contratos activos de Backend ni infraestructura Vercel/Render/Supabase desde este sprint de código cliente.
- No hacer merges, push forzado, tags, releases, habilitación de flags o despliegues sin aprobación humana.
- Cada cambio requiere `antes → causa → corrección mínima → test de regresión → después`.
- Protección de datos: secretos, contraseñas, JWT, enlaces de activación, datos reales de clientes y correos privados **nunca** en logs, screenshots o commits. Redactar también los fixtures de email y cabeceras HTTP.
- No agregar dependencias de prueba, paquetes de producción, interceptores globales o navegadores alternativos sin justificación, riesgo y registro de aprobación del owner.
- No comprometer seguridad para hacer pasar un test: no desactivar guards, validaciones, throttling, CORS o TLS de forma global.
- Documentación nueva en archivos vivos dedicados; los históricos conservan su fecha y naturaleza. Una contradicción documental se reporta y se corrige únicamente si entra en la autorización de esta fase.

## 10. Gates de salida y severidades

**Gate G0 — Evidencia de baseline:** SHAs, matriz objetivo/implementado, operación disponible/no disponible y estado de despliegues explicitados.

**Gate G1 — Calidad estática:** `flutter pub get`, `dart run build_runner build`, `flutter analyze`, `flutter test`, `flutter build web --release` y checks del CI que apliquen. Sin introducir conflictos/markers, nuevas warnings ni fallos existentes no clasificados.

**Gate G2 — Paridad y seguridad:** FE-01–FE-03 evaluados con pruebas; toda capacidad Core incluida responde al contrato real; negativa entre tenants y permisos; 503 Jobs visible y sin falsa ejecución.

**Gate G3 — Local E2E completa:** UI → API → PostgreSQL con evidencia de persistencia/ausencia de escrituras indebidas; repetición limpia; pruebas bajo rol/tenant correctos. Fallos P0/P1 = BLOQUEO.

**Gate G4 — Remoto autorizado:** URL de Vercel, origen Render, CORS y versiones confirmados; smoke ejecutado o declaradamente `BLOCKED`, con política de escrituras seguras.

**Gate G5 — Entrega:** PR sin merge, diff legible, changelog, matriz de tests, evidencias sanitizadas, deuda residual, instrucciones para QA y rollback; aprobación humana explícita.

**Gate G6 — Extensión ADR-006:** solo después de QA backend, integración Flutter y suite E2E extendida: revisión de migración, correo, seguridad de enlaces y pruebas cruzadas locales y remotas autorizadas.

Clasificación del reporte: `PASS` (ejecutado y aprobado), `FAIL` (ejecutado y fallido), `BLOCKED` (limitación de infraestructura/permisos), `NOT RUN` (no ejecutado). Ninguno de los dos últimos equivale a aprobado. P0/P1 abiertos bloquean aceptación; P2 documentados requieren decisión de owner para diferir. El riesgo residual de JWT snapshot **no desaparece** por pasar las pruebas.

## 11. Evidencias y trazabilidad requeridas

Generar evidencia dentro de un espacio aislado dedicado a Codex (definido en el documento normativo posterior), con IDs estables y sin secretos:

- Inventario baseline: SHA/fecha/branch, `git status`, workflow/CI, contrato objetivo y Swagger implementado.
- Matriz requisito → operación HTTP → pantalla → clase cliente → prueba → evidencia → estado.
- Informe de hallazgos FE-01–FE-08: causa, prioridad, reproducción, archivos, commit correctivo o decisión explícita.
- Artefactos de tests: comandos, código de salida, totales, tiempos, logs sanitizados, screenshot/video si aplicable.
- E2E local: `caseId`, identidad sintética, requests/responses, aserción SQL (sin credenciales), teardown.
- E2E remoto: URL de origen, fecha/hora, versión verificada, método de prueba y límites de autorización.
- Reporte de release: diferencias entre los contratos, PR, CI, pendientes, pruebas bloqueadas y propuesta de rollback.

**No declarar «100% funcional», «validado en producción» o «E2E completo» hasta que la matriz correspondiente esté cerrada y firmada por QA.** Para la presentación se demostrará solo lo que se haya verificado en la revisión desplegada.

## 12. Matriz de responsabilidad y traspaso

| Trabajo | Responsable principal | Aprobación final |
|---|---|---|
| Diagnóstico, correcciones Core Flutter y E2E local | Carlos con Codex | Carlos |
| Contrato y Backend ADR-006, migraciones y correo | Ángel con Codex | Carlos (arquitectura, seguridad, contrato y merge) |
| Integración UI Flutter de ADR-006 | Ángel | Carlos (paridad y QA) |
| CI, PRs, documentación y evidencias por cada línea | Quien desarrolla la línea | Carlos |
| Integración, E2E cruzada, despliegue y demo | Carlos | Carlos |

Los desarrollos paralelos parten de un **baseline `main` conocido**. El contrato aprobado de ADR-006 es su punto común, pero no debe confundirse con disponibilidad de endpoint. Cualquier conflicto funcional, cambio de contrato o refactor transversal se escala **antes** de programarse.

## 13. Orden de lectura del harness completo

1. **Este plan rector:** qué se busca, alcance, fases, QA y condiciones de éxito.
2. **Documento normativo para Codex (por entregar):** jerarquía de instrucciones, límites, permisos, contratos, seguridad, estructura y reglas de evidencias.
3. **Guía de ejecución autónoma (por entregar):** pasos verificables, comandos, checkpoints, decisiones de bloqueo y formato de handoff.
4. **Espacio `evidencias/` (por entregar):** único `README.md` inicial que declara su propósito como carpeta de resultados y materiales auxiliares generados durante la ejecución.

**Estado al publicar este plan:** solo especificación. Ninguna prueba, corrección, merge ni despliegue se presume ejecutado por su existencia.
