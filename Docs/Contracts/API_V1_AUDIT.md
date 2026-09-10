# API V1 Audit

> **Trazabilidad histórica F2 reconciliada:** este documento no certifica el cierre operativo F4. La evidencia vigente se registra en `../Auditorias/Fase4-Auditoria-Profunda-PostCodex.md`; ADR-004 y el registro F4 gobiernan.

## Estado general

**DEFINIDA.** Se generó una especificación OpenAPI V1 utilizable para trabajo paralelo entre Flutter, Platform Backend y Prospector Service. ADR-002, aceptado y fechado el 7 de septiembre de 2026, se tomó como fuente normativa para el contrato.

## Fuentes utilizadas

- `Docs/ADRs/ADR-002-ContratoAPI.md`, fuente principal del contrato y decisión más reciente.
- `Docs/ADRs/ADR-001-DecisionesDeDominioMVP.md`, decisiones de dominio y multi-tenancy.
- `Docs/ADRs/ADR_Responsabilidades_Postgre.md`, límites de PostgreSQL y aislamiento.
- `Docs/Analisis/Fase2_ContratoAPI.md`, catálogo, payloads y matriz de decisiones.
- `Docs/Analisis/Fase1_DOMAIN.md`, entidades, relaciones y lifecycle inicial.
- `Prisma/schema.prisma`, fuente de verdad de persistencia.
- `README.md`, contexto y límites del backend.

## Decisiones confirmadas

- Versionado por ruta `/api/v1`, recursos plurales y kebab-case.
- Flutter -> Platform usa JWT Bearer.
- Platform -> Prospector Service usa `X-API-Key`.
- Platform es dueño del `ProspectingJob` persistente.
- Jobs válidos: `QUEUED`, `RUNNING`, `COMPLETED`, `FAILED`, `CANCELLED`.
- Un Job contiene una query con `keyword`, `location`, `source` y `limit`.
- `source` V1 es `google_maps`.
- Callback: `POST /api/v1/internal/prospecting-jobs/{jobId}/events` con `eventId` UUID y `sequence` incremental.
- `BusinessResult` contiene solo `name`, `category`, `address`, `phone`, `email`, `website`, `source`, `sourceIdentifier`, `language` y `metadata`.
- Resultados, progreso y disponibilidad son DTO/cache/computed; no existe `ProspectingResult` persistente.
- Persistencia conceptual: BusinessResult -> duplicate detection -> Prospect + CampaignProspect.
- Paginación: `page` 1-based, `limit` por defecto 20 y máximo 100; metadatos `page`, `limit`, `total`, `totalPages`.
- Respuesta JSON estándar `{ success, data, meta }`; error `{ success, error }`.
- `passwordHash` no forma parte del contrato público.
- JWT distingue `platformRole` (`ADMIN` o `null`) de `tenantRole` (`OWNER`, `MEMBER` o `null`); `tenantId` representa el tenant activo o `null`.
- Creación de Job usa `Idempotency-Key`; misma key y payload repite el Job, payload diferente responde 409.

## Decisiones inferidas

- `tenantId` no se solicita en los requests públicos de campañas, prospectos y Jobs: ADR-001 establece que el tenant se deriva del contexto autenticado.
- El detalle del Job expone `requestedBy` como CUID y no como objeto de usuario, porque el contrato final del ADR contiene el identificador; la implementación puede añadir una proyección compatible después.
- `resultsAvailable` diferencia resultados aún no disponibles (`results: null`) de una ejecución completada sin resultados (`results: []`).
- La aceptación interna del Job responde `202` con estado inicial `QUEUED`.

## Propuestas

- Mantener `callbackUrl` como `uri-reference`, ya que el ADR muestra una ruta relativa y deja el despliegue fuera del contrato.
- Mantener filtros `search`, `sortBy` y `sortOrder` solo en recursos donde la documentación los permite, sin expresar full-text search.
- Tratar la respuesta de cancelación como el detalle del Job tanto para cancelación inmediata como para solicitud en ejecución, dejando el mecanismo físico fuera de V1.

## Contradicciones encontradas

1. **Exportación:** algunos listados preliminares solicitan `POST /.../export`, pero ADR-002, que tiene prioridad y es posterior, define `GET /api/v1/prospecting-jobs/{id}/export?format=csv|xlsx`. V1 usa GET.
2. **Estados antiguos:** `RegistroDeDesicionesContratosApi.md` menciona `STARTSOURCEPIPELINE` y fases internas como `RESULTLISTEXTRACTING`; ADR-001 y ADR-002 congelan únicamente los cinco estados del Job. V1 modela esas fases como `PipelineProgress.stage`, no como estados.
3. **Responsable del Job:** documentación de preguntas antiguas atribuye el estado al Service; ADR-002 posterior establece que Platform es propietario del estado persistente. V1 sigue ADR-002.
4. **Tipos ilustrativos:** ADR-001 usa `uuid` en diagramas, mientras Prisma define `String @default(cuid())`. V1 usa CUID para entidades persistentes y UUID solo para `eventId`.
5. **Prospect tenant:** un texto de ADR-001 dice que puede derivarse de Campaign, pero el schema Prisma aprobado contiene `tenantId` explícito. V1 lo trata como contexto persistente interno y no lo hace elegible para Flutter.

## Decisiones postergadas

- Resuelto en F4: HS256, 8h, sin refresh token ni blacklist; snapshot JWT.
- Rotación y mecanismo físico definitivo de API Keys, especialmente callback.
- Resuelto en F4: login 5/60s/IP en memoria.
- RLS/policies PostgreSQL.
- Estrategia concreta de cache y TTL de resultados.
- Reintentos de callbacks, timeout operativo y cancelación física del Service/Engine.
- Columnas exactas de CSV/XLSX.

## Diferencias API vs Prisma

| Contrato API | Prisma | Clasificación |
| --- | --- | --- |
| `User` sin `passwordHash`, con rol proyectado | `User.passwordHash`, `platformRole` y `UserTenant.roleId` | DTO/mapping |
| `Campaign` con `createdBy` y fechas | `Campaign` persistente | Mapping directo, sin exponer `tenantId` en listado |
| `Prospect` con campos de negocio y `campaignId` | `Prospect` más `tenantId`, metadata JSON y estado enum | DTO/mapping |
| `ProspectingJobDetail` con `results`, `progress`, `resultsAvailable` | No existen esas columnas | Cache/computed/transport-only |
| `BusinessResult` | No es modelo Prisma | Integración temporal; mapea a Prospect |
| `ProspectingJob.error` string | Error HTTP estructurado | Mapping de persistencia a DTO |
| `CampaignProspect.status` | String, no enum | El contrato no inventa un enum |

No se agregaron columnas, relaciones ni entidades persistentes. La unicidad usada al persistir es la del schema: `(tenantId, campaignId, source, sourceIdentifier)`. Como `sourceIdentifier` es nullable, PostgreSQL puede permitir múltiples NULL; la aplicación debe resolver esa limitación sin convertir una solución futura en contrato V1.

## Riesgos conocidos

- Resultados temporales pueden perderse según la estrategia de cache aún no definida.
- La API Key de callback está declarada como boundary contractual, pero su implementación de seguridad está postergada.
- La semántica física de cancelación de Jobs RUNNING aún no está definida.
- `requestedBy` y algunos detalles de proyección pueden requerir ajustes de implementación sin cambiar persistencia.
- La deduplicación con `sourceIdentifier: null` no queda garantizada solo por la restricción UNIQUE.

## Cambios recomendados para V2

- Resuelto en F4: claims sub, email, platformRole, tenantId, tenantRole y selección mediante membership o ADMIN global.
- Definir versionado/rotación de credenciales internas y políticas de reintento de callback.
- Establecer contrato de TTL/cache y una política explícita para `results` expirados.
- Formalizar filtros por recurso y columnas de exportación.
- Revisar si se necesita historial persistente de resultados o una deduplicación global; cualquier cambio debe acompañarse de migración y ADR.
- Evaluar proyecciones enriquecidas de `Role`, `requestedBy` y relaciones CampaignProspect como cambios compatibles.

## Conclusión

La V1 es suficientemente estable para que los tres equipos trabajen en paralelo, mantiene separados HTTP DTOs y modelos Prisma, y deja explícitos los puntos postergados. Las contradicciones heredadas se resolvieron aplicando la jerarquía solicitada: ADR-002, ADR-001 y el schema Prisma aprobado.
