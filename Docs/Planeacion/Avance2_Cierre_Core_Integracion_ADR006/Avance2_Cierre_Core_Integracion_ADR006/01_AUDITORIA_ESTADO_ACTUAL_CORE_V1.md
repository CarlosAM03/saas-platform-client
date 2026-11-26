# AUD-AV2-01 — Auditoría técnica del estado integrado de Frontend Core 1.0.0

**Proyecto:** PROSPECTOR SaaS multi-tenant  
**Corte:** 28 de octubre de 2026, hora de Tijuana  
**Estado:** auditoría de código, documentación, CI y evidencias locales, complementada con validación visual del owner; **no constituye certificación de producción sin ejecutar pruebas adicionales**.  
**Ámbito:** Flutter `CarlosAM03/saas-platform-client`, comparado con NestJS `CarlosAM03/saas-platform-backend`.  
**Responsable de aceptación:** owner técnico. **Este documento no modifica código ni autoriza merge o deploy.**

## 1. Identidad del baseline auditado

| Componente | Fuente / revisión | Estado verificado |
| --- | --- | --- |
| Flutter `main` | `e752f6ca692d2840263cd9e59e0927c56aa129ec` | PR #10 integrado conscientemente por el owner |
| Código funcional probado del PR | `7b5320c2a61e2f4170f23f5637cf630a9902de7d` | Referencia reportada en evidencias del sprint |
| Commit documental del PR | `469677d88339157379d28f1dd883f6af0626d981` | Evidencias/handoff integrados |
| Backend `main` | `b51b265f1a545fa915f1dd1c57ef2f5858ec6492` | Autoridad del Core 1.0.0; sin ADR-006 implementado en `main` al corte |
| Flutter CI del merge | https://github.com/CarlosAM03/saas-platform-client/actions/runs/40674754139 | `foundation`, `container`, `production-container`: success |
| Deploys | Vercel Flutter, Render NestJS, Supabase PostgreSQL | Owner confirma promoción automática desde `main`; las capturas prueban operación observable, no exponen SHA de infraestructura |

Fuentes técnicas: [PR #10](https://github.com/CarlosAM03/saas-platform-client/pull/10), `codex/evidencias/handoff-qa.md`, `test-resultados.md`, `matriz-e2e.md`, `e2e-local-resumen.md`, `hallazgos.md`, código `main` de ambos repositorios. La auditoría previa a este documento se contrastó nuevamente con esos archivos; no se han descargado ni inspeccionado secretos o tablas productivas.

## 2. Dictamen ejecutivo

**Resultado:** el Core Flutter 1.0.0 dispone de una base sólida, CI verde, regresiones principales corregidas y pruebas E2E locales con PostgreSQL real. **No se declara cerrado sin reservas**, porque el owner identificó una falla reproducible en el listado de usuarios del tenant ACME, mientras que la lista de Empresa B sí funciona. El hallazgo requiere diagnóstico de respuesta HTTP/serialización y, si corresponde, integridad de datos por tenant.

No se atribuirá ese fallo automáticamente a un `roleId` nulo ni a una regresión del merge. La razón exacta sigue **NO DETERMINADA**.

También existe una distancia entre el contrato y la política de negocio declarada sobre OWNER/MEMBER: el backend permite ciertas asignaciones `roleId` por API que no están limitadas a ADMIN y el esquema no garantiza por sí mismo exactamente un OWNER por tenant. Este punto es **independiente** del error de lista pero afecta al siguiente módulo de administración y onboarding.

## 3. Verificación por área

| Área | Estado actual | Evidencia / límite |
| --- | --- | --- |
| Login, sesión y router | **Validado localmente y observado en producción** | Restauración de deep link corregida; sesión y perfil visibles |
| Selección/cambio de tenant | **Validado** | ADMIN selecciona ACME y Empresa B; estado visual segregado |
| Campañas | **Validado en alcance observado** | ACME: dos campañas; Empresa B: una; acciones E2E locales |
| Prospectos | **Validado en alcance observado** | ACME: dashboard/lista muestran 185; Empresa B: dashboard muestra 207; importaciones indicadas por el owner |
| CSV | **E2E local y validación manual informada** | CREATE, LINK_EXISTING, UPDATE_EXISTING, SKIP; owner reporta importación satisfactoria; captura no demuestra por sí sola cada paso |
| Dashboard | **Validado visualmente** | Totales coherentes en capturas; tolera fallo aislado de Jobs en código |
| Jobs | **Validado según alcance Core** | 0 jobs en ambos contextos capturados; consulta habilitada, ejecución/exportación de motor pendientes por contrato |
| Organizaciones | **Validado visualmente** | ADMIN ve ambas organizaciones; botón crear presente |
| Perfil | **Validado visualmente** | Se observa ADMIN global con tenant seleccionado |
| Usuarios — Empresa B | **Operativo en captura** | Lista con un usuario y paginación válida |
| Usuarios — ACME | **FAIL en producción, P1** | `La respuesta del servidor no coincide con el formato esperado` en `/users` |
| Creación de usuarios V1 | **Éxito reportado por owner y E2E local** | Creación/persistencia en Supabase según owner; rol exacto requiere inspección de `UserTenant`, no `User.platformRole` |
| Roles desde Flutter | **Pendiente** | `CreateUserRequest.roleId` está tipado, pero formulario no muestra selector; por omisión se crea MEMBER |
| ADR-006 | **No forma parte del Core** | Cinco operaciones objetivo aprobadas, sin implementación en Backend `main` al corte |

La validación visual detallada y sus limitaciones están en `04_REGISTRO_EVIDENCIAS_CAPTURAS_PRODUCCION.md`.

## 4. Hallazgo P1 — listado de Usuarios en ACME

**Síntoma observado:** `/users` en ACME muestra mensaje de deserialización/formato y botón Reintentar. El mismo cliente, sesión ADMIN y entorno muestran la lista de Empresa B sin error. Esto reduce la plausibilidad de una indisponibilidad global de Render o un fallo general de sesión; **no demuestra qué fila o campo produjo el error**.

**Cadena real en código:**

`UsersPage` → `usersListProvider` → `ApiUsersRepository.list` → `UsersApi.list` → `GET /api/v1/users` → `unwrapPaginated` → `User.fromJson` y `PaginationMeta.fromJson`.

- `lib/platform_api/models.dart`: `User.fromJson` exige `id`, `name`, `email`, `status`, `createdAt`, `updatedAt`, interpreta `platformRole` y `role`, y deserializa la lista `tenants`.
- `lib/shared/models/api_models.dart`: `unwrapPaginated` exige sobre `{success:true,data:[...],meta:{page,limit,total,totalPages}}` con metadatos enteros válidos.
- `src/users/users.service.ts`: la lista aplica `userTenants.some({tenantId})`; construye `role` desde la membresía del tenant activo, y responde además `tenants` filtrados al tenant activo.
- `lib/core/errors/error_mapper.dart`: un `FormatException` o `TypeError` se convierte al mensaje visible; oculta el detalle concreto por protección de información.

**Hipótesis a verificar, NO conclusiones:** una fila con tipo/campo inesperado; un `meta` fuera del contrato; datos inconsistentes en alguna relación; disparidad de implementación/runtime o error transitorio de serialización. Un `role: null` puede ser válido en el DTO; hay que comprobar en qué nivel aparece y qué indica.

### Diagnóstico autorizado sin alterar producción

1. Repetir `GET /api/v1/users?page=1&limit=...` desde el tenant ACME seleccionado y registrar **solo** status, `x-request-id`, presencia y tipos de campos, `meta` y número de filas. No conservar tokens ni emails/nombres reales en archivos de evidencia.
2. Comparar la misma operación al seleccionar Empresa B: URL, `currentTenantId` del contexto (solo valor anonimizado), `meta`, estructura de la respuesta. No suponer que el listado de una empresa debe mostrar usuarios de la otra.
3. Comprobar si el request devuelve HTTP 200 con JSON incompatible o un error HTTP/HTML. Instrumentación de desarrollo temporal puede registrar nombre de campo y posición/índice anonimizado de la fila inválida, **sin payload personal ni tokens**. El mensaje visible del usuario permanecerá seguro.
4. Aislar con fixtures equivalentes en PostgreSQL local: ADMIN global sin membresía; MEMBER nuevo; OWNER; usuario compartido A/B; identidad sin tenant; registros con rol válido por tenant. Reproducir UI→API→SQL.
5. Con acceso autorizado **de solo lectura** en Supabase, revisar pertenencia/rol dentro del tenant que falla. Ejemplo esquemático (nunca integrar datos reales al repositorio):

```sql
SELECT ut.tenant_id, ut.user_id, ut.role_id, r.name AS tenant_role,
       r.tenant_id AS role_tenant_id, u.platform_role, u.status
FROM user_tenants ut
JOIN users u ON u.id = ut.user_id
LEFT JOIN roles r ON r.id = ut.role_id
WHERE ut.tenant_id = :tenant_id_autorizado;
```

   Validar que `r.tenant_id = ut.tenant_id`, que existe un rol por membresía y que los valores son compatibles con el DTO. Usar herramientas de SQL parametrizado y credenciales de lectura fuera del repositorio. No diagnosticar por recuentos de `users` globales: **el listado es de miembros por tenant**.
6. Comprobar `GET /api/v1/users/{id}` solo para identidades del tenant autorizado si hace falta aislar el registro, sin guardar información privada.
7. Corregir en el componente responsable; introducir regresión con fixture causante; repetir suite local y smoke remoto de **solo lectura**. Si requiere saneamiento productivo o migración, detenerse y solicitar aprobación explícita.

**Criterio de cierre P1:** ACME muestra su listado sin excepción, Empresa B continúa correcto, las cantidades coinciden con membresías autorizadas y no se filtran identidades de otro tenant. Ejecutar los flujos con usuarios actuales, recién creados y compartidos; dejar evidencia sanitizada de raíz y prueba.

## 5. Interpretación correcta de `role: null` / `platformRole: null`

En Prisma Core `User.platformRole` es **global** (`ADMIN` o `null`) y `UserTenant.roleId` es la FK tenant-scoped **obligatoria** a `Role` (`OWNER` o `MEMBER`). Por lo tanto:

- Un usuario de negocio con `users.platform_role = NULL` **es normal** y no significa que no tenga rol de su tenant.
- Si se creó mediante `POST /users` sin `roleId`, `UsersService.create` selecciona `RoleName.MEMBER` y escribe `UserTenant.roleId` en la misma transacción.
- `user_tenants.role_id` es un campo requerido en el esquema; si aparece realmente `NULL` en la base productiva, habría deriva del esquema, migración o dato incompatible que exige investigación separada. **No se afirma tal caso** con las capturas.
- Una identidad global que no tenga membresía en ACME no aparecerá en `GET /users` de ACME, aunque exista en `users`.
- Un ADMIN global puede no figurar como miembro; acceso global y membresía son conceptos distintos.

**Verificación mínima:** revisar el registro `UserTenant` del usuario nuevo en el tenant pertinente y comprobar el nombre asociado a su `roleId`. No mostrar contraseñas ni hashes.

## 6. Roles y autorización: discrepancias contra política confirmada por el owner

**Regla comercial confirmada por el owner:** ADMIN es administrador global; un tenant comercial tiene un único OWNER; solo ADMIN asigna/transfiere OWNER; OWNER administra y crea MEMBER de su tenant; MEMBER carece de facultad para administrar identidades. Las membresías de un mismo User en tenants distintos son parte del diseño.

**Implementación examinada:**

- `POST /users` permite `OWNER` y `ADMIN`. Con `roleId` explícito, `RoleService.getRoleById` solo valida pertenencia del rol al tenant; **no comprueba que OWNER esté reservado a ADMIN ni que ya exista OWNER**.
- `PATCH /users/{id}` también acepta `roleId` para OWNER; la protección SEC-01 cubre cambios de identidad global y administradores, pero el cambio de rol local no se restringe por rol destino.
- `Role` tiene `UNIQUE(tenantId,name)` (catálogo), lo cual **no restringe a un único `UserTenant` que use ese rol**.
- `PATCH /users` permite un cambio global de `status` a OWNER bajo condiciones SEC-01; `DELETE /users/{id}` es ADMIN-only pero desactiva globalmente. Debe precisarse semántica de baja por tenant frente a baja global.
- La API dispone de `UserTenantService.addUserToTenant`, pero no expone por sí sola el ciclo público completo para invitar/vincular identidades existentes a otro tenant.
- El esquema permite que un User sea OWNER de A y MEMBER de B, pero el registro ADR-006 devuelve 409 para correo existente; **la vinculación multi-tenant mediante invitación queda fuera del ADR aprobado**.

**Riesgo:** no es un defecto de la interfaz actual ni prueba de que haya privilegios indebidos en producción; sí son rutas backend potenciales para incumplir la regla comercial. Exigir test HTTP/DB de ambas rutas **antes de incorporar un selector de roles**.

## 7. QA de Codex y sus límites

`codex/evidencias/test-resultados.md` reporta `flutter analyze` y compilación Web PASS, 279 tests PASS, P2C real PASS, 32/32 E2E dos veces PASS, 6 negativos HTTP_SQL PASS, y CI de tres jobs PASS. `e2e-local-resumen.md` describe fixtures A/B, interacción UI, HTTP, aserciones SQL, recarga y limpieza con checksum de seed. `runtime-identities.json` fija los SHAs locales de código.

**Alcances no equivalentes:** los 32 escenarios mezclan `UI_TO_DB`, `UI_HTTP`, `UI_TO_DB_READ`, `HTTP_SQL` y otros scopes; no presentar 32 como 32 recorridos UI→DB completos. CI de GitHub no ejecuta todavía toda la suite pesada UI→DB: sus resultados completos se registraron localmente. Los datos y capturas productivos actuales del owner agregan evidencia manual, sin reemplazar la repetición automatizada postintegración.

G2 quedó `BLOCKED` por FE-04 (rol editable desde UI) y FE-07 (`query.source=demo` de seed histórico), y G4 por correlación formal de revisiones servidas. El owner confirma despliegue automático de `main`, pero la evidencia de identidad verificable de artefactos podría mejorarse posteriormente; no hay que afirmar fallo de despliegue a partir de esa observación.

## 8. Seguridad y comportamiento de sesión

- Flutter almacena JWT mediante `flutter_secure_storage`; Dio centraliza transporte; Flutter no accede directamente a PostgreSQL.
- Excepción FE-03 aprobada: leer claims JWT de `sub`, `tenantId`, `tenantRole`, `platformRole`, `exp` **solo como ayuda de presentación**. NestJS valida firma/autenticación/autorización.
- `JwtStrategy` conserva snapshot de rol hasta expiración (8 h por política Core), riesgo residual a vigilar en promociones/revocaciones.
- SEC-01 protege cambios globales a identidades compartidas en casos definidos, pero la regla de roles de destino y la baja de membresías requieren controles adicionales.
- No existe habilitación del Prospector Service en el Core; las rutas de Jobs mutantes y exportación siguen 503. No confundir la importación CSV ya operativa con exportación de Jobs.
- No documentar contraseñas, JWT, emails o prospectos reales en evidencias.

## 9. Registro de hallazgos para seguimiento

| ID | Prioridad | Estado | Acción exigida |
| --- | --- | --- | --- |
| AV2-FE-01 | **P1 / Bloqueante** | FAIL visible | Diagnosticar y corregir lista Users ACME; incluir HTTP/SQL/Flutter |
| AV2-DATA-01 | **P1 / Por verificar** | Abierto | Determinar qué columna se observó `NULL` y validar membresía/rol efectivo del usuario creado |
| AV2-BE-ROLE-01 | **P1 / Bloqueante para nueva administración de roles** | Confirmado en código | Solo ADMIN asigna OWNER, prevenir segundo OWNER con concurrencia |
| AV2-BE-STATUS-01 | P1 antes de administración extendida | Confirmado en código | Separar actualización de identidad global vs baja de membresía local |
| AV2-FE-ROLE-01 | P2 | Diferido | Selector de rol dependiente de restricciones Backend y contrato |
| AV2-BE-SEED-01 | P2 | Diferido | Corregir `query.source=demo` en seed, sin alterar enum contractual |
| AV2-UX-01 | P2 | Mejora | Mensajes de validación por campo y accesibilidad en formularios |
| AV2-CI-01 | P2 | Mejora | Llevar suite E2E UI→PostgreSQL reproducible al CI con runner aislado |
| AV2-DOC-01 | P2 | Mejora | Reconciliar guías de `dev`, `main`, release y disponibilidad Jobs |
| AV2-ADR006-01 | P1 para habilitación | Pendiente entrega | Auditoría PR de Ángel, migraciones, correo, tokens y contrato 5 operaciones |
| AV2-MEMBER-01 | Diseño posterior | No aprobado en ADR-006 | Onboarding/invitación MEMBER y vinculación de cuentas existentes |

## 10. Estado de ramas y estrategia paralela

- Flutter `main` contiene la estabilización. No mezclar `dev`, PR experimentales de Prospector Service ni código de Jobs no habilitado en este cierre.
- Backend `main` es el Core 1.0.0 de referencia. Ángel implementa un incremento en rama aislada partiendo de ese `main`, sin desplazar modificaciones del owner.
- Al recibir su PR: revisar el ancestro real, diff, migraciones y posibles divergencias; después integrar Flutter desde el `main` estabilizado, mediante **otro PR**, sin mezclar deuda anterior.
- Ambas ramas `main` tienen despliegue automático según confirma el owner. Por ello cada merge es una acción de release y requiere gates previos.

## 11. Recomendación de cierre de Core

**Aceptar el resultado de estabilización como baseline técnico integrado, pero mantener abierto AV2-FE-01 hasta resolver el listado ACME y comprobar AV2-DATA-01.** No activar permisos de OWNER nuevos ni presentar la administración de miembros como totalmente consolidada hasta imponer la regla en Backend. Las mejoras de UX y documentación no deben bloquear una demostración existente si los fallos funcionales críticos están resueltos.

Si el hallazgo P1 continúa para la fecha de presentación, usar únicamente un guion que **no afirme que el listado de usuarios está validado en todos los tenants**. Nunca ocultar o modificar datos de producción para aparentar éxito.

## 12. Enlaces de referencia

- Frontend PR #10: https://github.com/CarlosAM03/saas-platform-client/pull/10
- Frontend `main`: https://github.com/CarlosAM03/saas-platform-client/tree/main
- Backend `main`: https://github.com/CarlosAM03/saas-platform-backend/tree/main
- Backend UsersService: `src/users/users.service.ts`, UsersController: `src/users/users.controller.ts`, Prisma: `Prisma/schema.prisma`
- Frontend UsersPage: `lib/features/users/presentation/users_pages.dart`, DTO parser: `lib/platform_api/models.dart`, envelope parser: `lib/shared/models/api_models.dart`
- Pruebas: `codex/evidencias/matriz-e2e.md`, `e2e-local-resumen.md`, `handoff-qa.md`, `hallazgos.md`.
