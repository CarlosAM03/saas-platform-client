# Contrato implementado — backend `3b5eec6`

- Backend SHA: `3b5eec6fa99f846e853794fc8aedff2c4353c269`
- Rama: `feat/sprint-campana-prospector`
- Documento servido de referencia: `openapi-served-3b5eec6.json` (39 rutas / 77 esquemas; 162 688 bytes; SHA256 `e73bb1e924a1e956d20567768e63861552d9799c51170257b1098f424384e14c`), generado con el mismo `deploymentDocument()` que sirve `GET /api/docs-json`.
- Fuente contractual: `Docs/Contracts/platform-api.v1.yaml` en ese SHA.
- Swagger UI: `GET /api/docs`; JSON: `GET /api/docs-json` (no `api/docs/json` en la app principal).

Este documento describe **lo implementado**, no lo aspiracional del SPEC. Si algo del SPEC no está aquí, no está disponible para el frontend.

## 1. Autenticación y tenant

1. `POST /api/v1/auth/login` con `{email, password}` → `data.accessToken` y `data.tenants[]`. Sin refresh token; JWT de 8 h. Máximo 5 intentos por 60 s por IP (429).
2. `POST /api/v1/auth/select-tenant` con `{tenantId}` → nuevo `accessToken` con el tenant en el token. Valida membresía activa; un ADMIN global conserva `tenantRole: null` pero requiere tenant seleccionado.
3. Todas las rutas de Campañas/Prospectos exigen `Authorization: Bearer <token>` **con tenant seleccionado**. No hay cabecera de tenant: el tenant vive en el JWT. Para cambiar de organización hay que repetir `select-tenant`.
4. `GET /api/v1/auth/me` devuelve el contexto actual sin renovar el token.

Roles efectivos en este sprint: `ADMIN`, `OWNER`, `MEMBER` (rol de tenant) + `ADMIN` de plataforma. Restricciones específicas:

| Ruta | Roles admitidos |
|---|---|
| Campañas y participación (C1/C2/C3/C4/C6/C8) | ADMIN, OWNER, MEMBER con tenant |
| `POST/PATCH /prospects`, `POST /prospects/match`, `POST /prospects/resolve` (P1/P3) | ADMIN, OWNER |
| `POST /prospects/import/preview|confirm` (P4) | ADMIN, OWNER |
| Lecturas de prospecto y P2/P3 GET | ADMIN, OWNER, MEMBER con tenant |

Un `MEMBER` que intente alta/importación recibe `403`. Ningún endpoint expone datos de otro tenant: las entidades ajenas responden `404`, no `403`.

## 2. Envoltura y errores

- Éxito: `{ "success": true, "data": <payload>, "meta"?: PaginationMeta }`.
- Error: `{ "success": false, "error": { "code", "message", "details", "timestamp" } }`.
- Códigos usados: `400` validación/DTO, `401` sin sesión o token inválido, `403` rol insuficiente o sin tenant, `404` inexistente **o de otro tenant** (ocultación deliberada), `409` conflicto de identidad/candidato/confirmación, `413` archivo mayor a 5 MB, `429` límite de intentos de login, `503` integraciones pendientes (Jobs/Prospector; no aplica a Campañas/Prospectos).

## 3. Paginación

`page=1`, `limit=20` (máximo `100`). `meta = {page, limit, total, totalPages}`. `sortBy ∈ {name, email, status, createdAt, updatedAt}`, `sortOrder ∈ {asc, desc}`; desempate estable por `id` ascendente. Las actividades y la procedencia tienen **orden fijo** (ver abajo) y no se reordenan con `sortBy`.

## 4. Operaciones por feature

La matriz completa (roles, request, response, errores, ejemplo, pantalla, prueba) está en `02_MATRIZ_API_FLUTTER.csv`. Resumen de semántica que no se deduce del schema:

### C1 — Etapa comercial
`PATCH /campaigns/{campaignId}/prospects/{prospectId}/stage` con `{stage}`. Etapas: `SIN_GESTIONAR`, `EN_INVESTIGACION`, `CONTACTADO`, `EN_SEGUIMIENTO`, `OPORTUNIDAD`, `CERRADO`. Transiciones libres y reversibles; cada cambio efectivo registra exactamente un `STAGE_CHANGE`. Un no-op no escribe evento. `status` del prospecto maestro es independiente. `commercialStage` vive en `participation`.

### C2 — Evaluación
`PATCH .../evaluation` con `{evaluation, reason?}`. `NO_APTO` exige `reason` (400 sin él). El motivo se conserva en `evaluationReason` y en el evento `EVALUATION_CHANGE`; al pasar a `APTO` el evento siguiente conserva el motivo anterior en su historial. No cambia etapa ni dispara Jobs.

### C3 — Bitácora
- `GET .../activities?page&limit` → `data: CampaignActivity[]` + `meta`. Orden fijo `recordedAt desc, id desc`.
- `POST .../activities` con `{type ∈ NOTE|CALL|EMAIL|MEETING|OTHER, content, declaredAt?, correctsId?}`. Si llega `correctsId` el tipo resultante es `CORRECTION` y el original **no se modifica**. `recordedAt` lo pone el servidor; `declaredAt` es la fecha declarada por el humano.
- Tipos automáticos (`ASSOCIATION`, `STAGE_CHANGE`, `EVALUATION_CHANGE`, `RESPONSIBLE_CHANGE`) y `MASTER_UPDATE` **no se aceptan** en el alta manual (400).
- La UI debe distinguir declaración humana (`NOTE/CALL/EMAIL/MEETING/OTHER/CORRECTION`) de evento automático (`ASSOCIATION/STAGE_CHANGE/EVALUATION_CHANGE/RESPONSIBLE_CHANGE`). `CORRECTION` es **manual**.

### C4 — Responsable
- `GET .../responsibles` → sólo usuarios activos con membresía actual del tenant; `eligible: true`. Orden por nombre e id.
- `PUT .../responsible` con `{responsibleId}` valida elegibilidad en servidor (400 si inactivo o sin membresía). Registra `RESPONSIBLE_CHANGE` sólo si cambia.
- `DELETE .../responsible` desasigna y deja `responsibleId: null`.
- Si un usuario pierde elegibilidad después, la asignación **no se borra**: la lectura devuelve `responsible.eligible: false` y la UI debe pedir reasignación humana.
- `GET .../participation` devuelve el contexto completo (etapa, evaluación, motivo, responsable, `addedAt`, `updatedAt`).

### C6 — Filtros de la lista de campaña
`GET /campaigns/{id}/prospects` combina filtros con **AND**: `category`/`address` (texto contenido, sin distinguir mayúsculas), `source` (exacto), `search` (name o email), `stage`, `evaluation`, `responsibleId` o `UNASSIGNED`, `addedFrom/addedTo`, `activityFrom/activityTo` (ISO 8601 **con zona**, rangos inclusivos). Los campos maestros vienen de `Prospect` y la etapa/evaluación/responsable de `participation`. `status` del maestro no es la etapa comercial.

### C8 — Dashboard de campaña
`GET /campaigns/{id}/dashboard` → `data`:
- `total` de participaciones;
- `stages` y `evaluations` (partición exhaustiva, suma = `total`);
- `responsibility`: `SIN_ASIGNAR`, `NO_ELEGIBLE:{userId}` o `userId`;
- `activity`: `{total, manual, events}` con `total = manual + events`; `manual` = NOTE/CALL/EMAIL/MEETING/OTHER + **CORRECTION**; `events` = ASSOCIATION/STAGE_CHANGE/EVALUATION_CHANGE/RESPONSIBLE_CHANGE;
- `incorporation`: `{new, reused, unknownLegacy}`, suma = `total`.
Todos los agregados provienen de una sola instantánea. No es el dashboard global del tenant: no lo sustituyas.

### P1 — Alta y coincidencias
- `POST /prospects` crea o reutiliza. Con identidad fuerte (`identitySource: google_maps` + `identityIdentifier` no vacío, trim sin cambiar mayúsculas/minúsculas, único por tenant) reutiliza el maestro y asegura la asociación sin actualizarlo. Sin identidad externa, `source = manual`.
- `POST /prospects/match` evalúa sin escribir: `{strongProspect|null, candidates[], resolutionRequired}`. Los candidatos son sólo del tenant.
- `POST /prospects/resolve` decide `CREATE | LINK_EXISTING | SKIP` (con `candidateId` en `LINK_EXISTING`). Si el candidato cambió, responde `409` **sin escribir**; hay que repetir la verificación.
- Coincidencia fuerte = fuente confiable + identificador válido. Coincidencia débil exige decisión humana; no hay auto-merge.

### P2 — Campañas asociadas al maestro
`GET /prospects/{id}/campaigns?page&limit` → `data.{originCampaignId, meta, campaigns[]}`. Cada fila: `campaign{id, name, status}`, `isOrigin`, `stage`, `evaluation`, `responsible|null` (con `eligible`), `latestActivity|null`, `addedAt`. Orden `addedAt desc, campaignId asc`. La campaña de origen aparece una sola vez.

### P3 — Procedencia global
- `GET /prospects/{id}/provenance?page&limit` → `data: ProspectProvenanceEvent[]`, `meta` en el nivel superior. Sólo eventos confirmados (`CREATED`, `LINKED`, `REAPPEARED`, `MASTER_UPDATED`); nunca previews, omisiones ni eventos inventados. Orden `recordedAt desc, id desc`.
- `PATCH /prospects/{id}` actualiza el maestro compartido. Con `contextCampaignId` de una participación del mismo tenant registra `MASTER_UPDATED` de procedencia en esa campaña y **no** altera el historial comercial de otras campañas. Sólo `contextCampaignId` sin campo maestro devuelve 400.
- No confundir `MASTER_UPDATED` (procedencia) con `MASTER_UPDATE` (tipo de actividad documentado por paridad, hoy **no emitido**).

### P4 — Importación CSV
- Caracteres: CSV `UTF-8`, delimitador `,` o `;` (se acepta el que parsee completo y sin ambigüedad), máximo **5 MB** y **1000 filas**. Cabeceras admitidas: `name, category, address, phone, email, website, language, status`; `name` obligatorio; cabeceras desconocidas o repetidas → 400.
- `POST /prospects/import/preview` (multipart `campaignId`, `file`) → `rows[]` clasificados `NEW | MATCH | INVALID | CONFLICT`, `summary` y `previewReference` firmada + `expiresAt` (15 minutos). No escribe nada.
- `POST /prospects/import/confirm` (multipart `campaignId`, `file`, `previewReference`, `decisions`) → `summary {total, created, linked, updated, skipped, rejected}` y `rows[{record, action, prospectId, errors}]`. `action` ∈ `CREATE | LINK_EXISTING | UPDATE_EXISTING | SKIP | REJECTED`. Es atómica: si falla, no deja procedencia ni actividades durables (rollback). Confirmar dos veces o con una referencia vencida/cambiada → 409/400; hay que repetir el preview.
- Con candidatos débiles/múltiples la única decisión segura es `CREATE` o `SKIP`; `LINK_EXISTING`/`UPDATE_EXISTING` requieren candidato único revalidado.
- No existe endpoint para deshacer una importación; la reversión es por rollback transaccional (ratificado por el owner).

## 5. Estados de disponibilidad

- Todas las operaciones de la matriz marcadas `AVAILABLE` tienen prueba ejecutada en este SHA (unit/HTTP/PostgreSQL) y están en el contrato servido.
- Las rutas baseline de Campañas/Prospectos no llevan `x-contract-status` en el YAML por convención del encabezado; están implementadas y cubiertas por las suites baseline.
- Las rutas de Jobs y Prospector siguen con `503 PROSPECTOR_INTEGRATION_PENDING`; no forman parte de este handoff.
