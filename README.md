# Plataforma SaaS - Cliente Flutter

Cliente Flutter multiplataforma de la Plataforma SaaS universitaria para gestion de campanas y prospeccion automatizada.

## Estado

Este repositorio corresponde a Fase 5 - Flutter Foundation.

Fase 5 no es el frontend completo ni el MVP completo. Su objetivo es dejar una base estable para que Andre implemente features y Angeles disene UI/UX sin redisenar la arquitectura transversal.

El cierre esperado es:

```text
F5 CLOSED AS FLUTTER FOUNDATION / READY FOR FEATURE DEVELOPMENT
```

## Papel de Flutter

Flutter es exclusivamente un cliente API del SaaS Backend NestJS.

```text
Usuario
  |
Flutter Client
  | HTTPS / REST / JWT
SaaS Backend NestJS
  |-- PostgreSQL
  `-- Prospector Service FastAPI
        `-- Prospector Engine Python
```

Flutter no se conecta directamente a PostgreSQL, Prospector Service ni Prospector Engine. Tampoco ejecuta scraping, resuelve reglas de negocio, decide autorizacion real ni realiza deduplicacion definitiva.

El backend es la autoridad para tenant context, autorizacion, persistencia, reglas de negocio, exportaciones y deduplicacion definitiva.

## Alcance funcional de Fase 5

La unica funcionalidad completa obligatoria es Auth Foundation:

- Login mediante `POST /api/v1/auth/login`.
- Restauracion mediante `GET /api/v1/auth/me`.
- Seleccion y cambio de tenant mediante `POST /api/v1/auth/select-tenant`.
- Logout mediante `POST /api/v1/auth/logout`.
- JWT en `flutter_secure_storage`.
- AuthState con Riverpod.
- Rutas protegidas con `go_router`.
- Estados de carga, vacio, error y exito.

Campaigns, Prospects y ProspectingJobs pueden existir como placeholders o mocks alineados al OpenAPI. No se consideran features completas de Fase 5.

La administracion completa de usuarios no bloquea Fase 5. La administracion de tenants permanece como placeholder o postergada hasta que exista un endpoint operativo suficiente.

## Decisiones tecnicas vigentes

- Dio es el motor HTTP interno, encapsulado en `ApiClient`.
- Solo `lib/core/network` puede usar Dio.
- Features, providers y widgets no usan Dio ni hacen HTTP directo.
- Los repositories consumen `ApiClient`.
- Riverpod gestiona estado.
- `go_router` gestiona rutas.
- `json_serializable` modela DTOs.
- `envied` gestiona configuracion.
- `logger` se usa para logs seguros.
- No hay refresh token, OAuth ni self-register publico.
- Jobs son asincronos y el MVP usa polling de 3 a 5 segundos.
- No hay WebSocket, SSE, workers Flutter, background tasks u offline avanzado.

## Tenant y roles

`currentTenantId` puede ser `null`. ADMIN puede autenticarse sin tenant seleccionado y no entra automaticamente a rutas tenant-aware. OWNER opera dentro de su tenant. MEMBER es un rol operativo limitado para el MVP inicial.

La UI solo controla visibilidad y experiencia. El backend conserva la autorizacion real y puede responder 403 aunque una accion haya sido visible.

## Estructura logica

```text
lib/
  app/
  core/
    config/
    network/
    storage/
    errors/
    theme/
  shared/
    models/
    widgets/
  features/
    auth/
    campaigns/
    prospects/
    prospecting_jobs/
    profile/
    admin/
  routes/
test/
docs/
```

## Documentacion normativa

La documentacion vigente del cliente vive dentro de `Docs/`:

- `Docs/ADRs/ADR-005-FlutterFoundation.md`
- `Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md`
- `Docs/Flutter-Foundation.md`
- `Docs/LineamientosUI-UX.md`

La fuente contractual HTTP es `platform-api.v1.yaml` del backend. La autoridad de las decisiones de F4 es `ADR-004-CommonBaseline.md` del backend.

Los documentos conceptuales e historicos no sustituyen estas fuentes.

## Ownership

- Carlos: Flutter Foundation, arquitectura, integracion, ApiClient, Auth, routing, DTOs base y documentacion tecnica.
- Andre: features Flutter, pantallas, repositories, providers, widgets y tests de features.
- Angeles: UI/UX, wireframes, componentes, estados visuales y documentacion visual/academica.
- Angel: backend NestJS, Prisma, PostgreSQL, OpenAPI y endpoints funcionales.

Para reglas de trabajo consultar `CONTRIBUTING.md` y `FEATURE-DEVELOPMENT.md`.

