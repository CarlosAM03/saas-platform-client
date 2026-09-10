# Contratos API V1

Este directorio contiene el contrato HTTP V1 de la plataforma. Los YAML son la referencia para generar DTOs, clientes y mocks; no son implementación NestJS ni modelos Prisma.

## Archivos

- `platform-api.v1.yaml`: API pública consumida por Flutter y provista por Platform Backend. Incluye autenticación, tenants, usuarios, campañas, prospectos y Jobs.
- `prospector-service-api.v1.yaml`: API interna entre Platform Backend y Prospector Service. Incluye la aceptación de Jobs y el callback Service -> Platform.
- `API_V1_AUDIT.md`: trazabilidad, contradicciones, decisiones y riesgos identificados al contrastar ADRs, dominio y Prisma.

## Límites

Flutter solo consume Platform API mediante `Authorization: Bearer <JWT>`. Flutter no llama directamente a Prospector Service. Platform es dueño del estado persistente de `ProspectingJob`, de los resultados temporales y de la decisión de persistir o exportar.

Platform llama a Prospector Service con `X-API-Key`. El Service llama al callback interno de Platform con `X-API-Key`. La clave concreta proviene del entorno; rotación operativa e implementación de integración quedan fuera del baseline F4.

## Tenant y persistencia

La arquitectura V1 usa Shared Database + Shared Schema + Tenant ID. El tenant de las operaciones de negocio se resuelve desde el contexto autenticado y no se acepta como parámetro arbitrario de Flutter. `tenantId` aparece en el detalle del Job y en el request interno porque forman parte de contratos ya definidos, no porque el cliente pueda elegir libremente el tenant.

Los recursos API son DTOs. `passwordHash` nunca se expone. `BusinessResult`, `PipelineProgress`, `results`, `progress` y `resultsAvailable` son estructuras de integración, computadas o temporales; no crean una tabla `ProspectingResult`.

## Evolución

La versión se expresa en la ruta (`/api/v1`). Cambios incompatibles deben publicarse bajo `/api/v2`; cambios compatibles pueden añadir propiedades opcionales, estados de metadatos o nuevos endpoints tras actualizar la trazabilidad. Antes de cambiar un DTO, actualizar ADR-002 y este directorio, y comprobar el mapping hacia Prisma.

F4 fija JWT HS256 de 8h, sin refresh token ni blacklist, y rate limiting de login 5/60s/IP. El JWT es snapshot; UserTenant se valida al emitir contexto. RLS, TTL/cache, reintentos y cancelación física están fuera del baseline.

Swagger carga platform-api.v1.yaml en /api/docs, con servidor relativo al origen actual. F4 implementa Auth, Users y Health; los demás endpoints conservan su contrato objetivo. meta es opcional, logout y DELETE Users devuelven data: {}. ADMIN es global; OWNER/MEMBER son tenant-scoped. ADR-004 y el registro F4 gobiernan.

## Nota de compatibilidad

ADR-002 define la exportación como `GET /api/v1/prospecting-jobs/{id}/export?format=csv|xlsx`; por eso el contrato V1 usa GET aunque algunos listados preliminares hayan mostrado POST. No se añade un alias POST sin una decisión posterior explícita.
