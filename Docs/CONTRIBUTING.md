# Contributing - Cliente Flutter

## Alcance

Este repositorio implementa el cliente Flutter de la Plataforma SaaS universitaria. Fase 5 entrega el foundation; no declara el frontend completo ni el MVP completo.

## Fuentes de verdad

En orden de autoridad:

1. ADR-004 del backend.
2. `platform-api.v1.yaml`.
3. `Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md`.
4. `Docs/ADRs/ADR-005-FlutterFoundation.md`.
5. `FEATURE-DEVELOPMENT.md`.

Los documentos historicos o conceptuales solo aportan contexto.

## Ownership

- Carlos protege `lib/app`, `lib/core`, `lib/routes`, AuthState, AuthService, ApiClient y DTOs base.
- Andre desarrolla `lib/features`, repositories de features, providers, widgets especificos y tests de features.
- Angeles mantiene wireframes, especificaciones visuales, componentes de diseno y documentacion visual.
- Angel mantiene backend, Prisma, PostgreSQL, OpenAPI y endpoints funcionales.

Los cambios en red, configuracion, storage, errores, routing, autenticacion, DTOs base o contrato requieren coordinacion con Carlos.

## Flujo Git

- `main`: rama estable.
- `dev`: rama de integracion.
- `feature/<nombre>`: trabajo individual.

Los cambios deben integrarse mediante pull request hacia `dev`. La rama `main` recibe cambios validados desde `dev`.

## Reglas de arquitectura

- Flutter consume unicamente SaaS Backend NestJS.
- No hay acceso directo a PostgreSQL, Prospector Service o Prospector Engine.
- Dio vive unicamente dentro de `lib/core/network`, encapsulado por `ApiClient`.
- Features, providers y widgets no usan Dio ni hacen HTTP directo.
- Los repositories consumen `ApiClient`.
- Riverpod gestiona estado y `go_router` gestiona rutas.
- El JWT se guarda unicamente en `flutter_secure_storage`.
- No se imprimen tokens ni secretos en logs.
- La UI no reemplaza autorizacion backend.
- Los mocks no son fuente de verdad.

## Contratos y DTOs

Toda request, response, campo, nullability, estado y codigo HTTP debe verificarse contra `platform-api.v1.yaml`.

No se debe crear un DTO de request para persistencia mientras el endpoint no defina `requestBody`. La persistencia se invoca sin body segun el contrato actual.

Fase 5 usa unicamente los codigos definidos por OpenAPI.

## Seguridad

- No guardar JWT en SharedPreferences o localStorage.
- No agregar refresh token.
- No agregar OAuth ni self-register publico.
- No enviar `tenantId` arbitrario como autoridad de seguridad.
- No implementar autorizacion real en Flutter.

## Validaciones antes de integrar

- Analisis estatico sin errores.
- Tests relevantes ejecutados.
- DTOs alineados con OpenAPI.
- Mocks claramente marcados.
- Estados Loading, Empty, Error y Success presentes.
- Sin llamadas HTTP desde widgets.
- Sin uso de Dio fuera de `lib/core/network`.
- Sin cambios no coordinados a foundation.

## Cambios de contrato

Si una feature requiere un campo, endpoint, permiso o codigo HTTP que no existe en OpenAPI, detener la implementacion de ese punto y reportarlo a Carlos y Angel. No modificar el contrato desde Flutter.
