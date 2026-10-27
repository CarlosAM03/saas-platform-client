# FEATURE-DEVELOPMENT.md

## Plataforma SaaS — Cliente Flutter

> Estado reconciliado 26-10-2026: CSV UI y dashboard usan Backend dev 967044e2. Jobs conserva historial/detalle/polling; crear/cancelar/persistir/exportar están deshabilitados por 503 PROSPECTOR_INTEGRATION_PENDING. Configurar Prospector no activa el adaptador NestJS. Ver Docs/Funciones-Pendientes-Implementadas.md y la auditoría de reconciliación. No se declara E2E.

> Registro del sprint anterior: Foundation/Auth preservados; Tenants, Users, Campaigns y Prospects no-CSV implementados con API real. CSV PlatformApi está completo; CSV UI/file picker, Jobs UI, Prospector, polling/results cache y Dashboard real están diferidos deliberadamente. Autoridad: código de backend/main, su OpenAPI sincronizado y ADR-004; después código/ADRs frontend. El encargo de paridad core autoriza los cambios transversales del sprint.


Guía para desarrollo de features sobre el baseline Flutter Foundation.

Regla de integración vigente: conservar PlatformApi, DTOs, repositorios por feature,
TenantPermissions y sessionScopeProvider. No introducir repositorios dinámicos paralelos,
providers duplicados ni un router alternativo. Los componentes visuales se adaptan a
las interfaces tipadas. Las respuestas objetivo de Jobs se documentan únicamente en
x-target-responses del OpenAPI; las pruebas con fixtures comprueban preparación del
cliente, sin certificar la ejecución real. Las pruebas de permisos no reemplazan al Backend.

---

# 1. Propósito

Este documento define cómo desarrollar nuevas features dentro del cliente Flutter de la Plataforma SaaS.

Su objetivo es permitir que André implemente funcionalidades de forma ordenada, sin romper la arquitectura base definida en:

* FormularioDecisionesFase5.md
* Docs/ADRs/ADR-005-FlutterFoundation.md
* OpenAPI del SaaS Backend NestJS
* ADR-004-CommonBaseline.md del backend

Este documento no reemplaza el contrato OpenAPI ni las decisiones del backend.

El frontend es un cliente API.

El backend es la fuente de verdad para autorización, tenant context, reglas de negocio, persistencia, deduplicación definitiva y exportaciones.

---

# 2. Principio rector

Flutter no implementa lógica de negocio que ya resuelve el backend.

Flutter se encarga de:

* Mostrar pantallas.
* Capturar formularios.
* Validar entradas básicas de UI.
* Consumir el SaaS Backend.
* Manejar sesión.
* Manejar navegación.
* Mostrar estados de carga, vacío, error y éxito.
* Mantener caché temporal no crítica.
* Mostrar retroalimentación del usuario.
* Descargar archivos cuando el backend los expone.

Flutter no debe:

* Conectarse directamente a PostgreSQL.
* Comunicarse directamente con Prospector Service.
* Comunicarse directamente con Prospector Engine.
* Ejecutar scraping.
* Resolver autorización real.
* Persistir datos definitivos por su cuenta.
* Deduplicar datos de forma definitiva.
* Tratar mocks como fuente de verdad.
* Inventar campos que no existan en OpenAPI.
* Guardar secretos reales.
* Imprimir tokens en logs.

---

# 3. Estructura general del repositorio

La estructura base del cliente será:

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

---

# 4. Ownership de carpetas

## Carlos protege

Estas áreas no deben modificarse sin coordinación directa con Carlos:

```text
lib/app/
lib/core/config/
lib/core/network/
lib/core/storage/
lib/core/errors/
lib/routes/
lib/features/auth/
lib/shared/models/ modelos base
```

Incluye:

* ApiClient.
* Configuración de entorno.
* Manejo global de sesión.
* Secure storage.
* Manejo global de errores.
* Routing global.
* Guards.
* AuthState.
* AuthService.
* DTOs base.
* Contrato de respuesta estándar.
* Comportamiento de 401 y 403.

## André trabaja principalmente en

```text
lib/features/campaigns/
lib/features/prospects/
lib/features/prospecting_jobs/
lib/features/profile/
lib/features/admin/
lib/shared/widgets/
test/features/
```

André puede crear:

* Screens.
* Widgets de feature.
* Providers de feature.
* States de feature.
* Repositories de feature.
* DTOs específicos de feature.
* Mocks específicos de feature.
* Tests de feature.

## Ángeles aporta principalmente en

```text
docs/
lib/shared/widgets/
lib/core/theme/
```

Pero cualquier cambio real en tema global o componentes transversales debe coordinarse con Carlos y André.

---

# 5. Regla principal para crear features

Toda feature debe seguir esta regla:

La UI no llama HTTP directamente.

El flujo correcto es:

```text
Screen / Widget
  ↓
Provider / State
  ↓
Repository interface
  ↓
Repository implementation
  ↓
Platform API Client tipado
  ↓
ApiClient
  ↓
SaaS Backend NestJS
```

No se permite este flujo:

```text
Screen / Widget
  ↓
Dio directo
```

Tampoco se permite:

```text
Provider
  ↓
Dio directo
```

Dio existe únicamente dentro de `lib/core/network/`.

---

# 6. Estructura recomendada por feature

Cada feature debe organizarse de forma similar a esto:

```text
lib/features/<feature>/
  data/
    <feature>_repository.dart
    api_<feature>_repository.dart
    mock_<feature>_repository.dart
  models/
    <feature>_dto.dart
  providers/
    <feature>_providers.dart
  state/
    <feature>_state.dart
  screens/
    <feature>_screen.dart
  widgets/
    <feature>_widget.dart
```

Ejemplo para campaigns:

```text
lib/features/campaigns/
  data/
    campaigns_repository.dart
    api_campaigns_repository.dart
    mock_campaigns_repository.dart
  models/
    campaign.dart
    create_campaign_request.dart
    update_campaign_request.dart
  providers/
    campaigns_providers.dart
  state/
    campaigns_state.dart
  screens/
    campaigns_list_screen.dart
    campaign_detail_screen.dart
    create_campaign_screen.dart
  widgets/
    campaign_card.dart
    campaign_status_badge.dart
```

---

# 7. Pasos para crear una feature nueva

Antes de implementar una feature, seguir este orden:

1. Revisar el endpoint en OpenAPI.
2. Confirmar si el endpoint ya está implementado en backend.
3. Identificar request DTOs.
4. Identificar response DTOs.
5. Identificar posibles errores.
6. Identificar si requiere tenant seleccionado.
7. Identificar roles visibles en UI.
8. Crear modelos/DTOs alineados al OpenAPI.
9. Crear repository interface.
10. Crear API repository.
11. Crear mock repository si el backend aún no está disponible.
12. Crear provider Riverpod.
13. Crear state con loading, empty, error y success.
14. Crear screens.
15. Crear widgets.
16. Agregar tests mínimos.
17. Documentar cualquier endpoint faltante o contradicción.

---

# 8. Estados obligatorios por feature

Cada feature debe modelar explícitamente sus estados.

Estados mínimos:

```text
initial
loading
empty
success
error
```

Para jobs también deben considerarse:

```text
queued
running
completed
failed
cancelled
```

No se debe dejar una pantalla sin estado vacío o sin estado de error.

Cada pantalla debe poder responder a:

* Backend no disponible.
* Sesión expirada.
* Falta de permisos.
* Falta de tenant seleccionado.
* Lista vacía.
* Operación exitosa.
* Error de validación.
* Error inesperado.

---

# 9. Manejo de errores

Los errores del backend deben convertirse a `ApiException`.

Formato esperado desde backend:

```text
success: false
error:
  code
  message
  details
  timestamp
```

La UI no debe parsear errores manualmente en cada pantalla.

Cada repository debe dejar que ApiClient centralice:

* Parsing de errores.
* Códigos HTTP.
* Timeouts.
* Errores de red.
* 401.
* 403.
* 429.
* 503.

## Comportamiento obligatorio

401:

* Detener polling activo.
* Limpiar token.
* Limpiar AuthState.
* Limpiar caché temporal.
* Redirigir a Login.
* Mostrar sesión expirada.

403:

* Mantener sesión.
* No borrar token.
* Mostrar error contextual.
* Si falta tenant, redirigir a Select Tenant.

429:

* Mostrar mensaje de demasiados intentos.
* No reintentar automáticamente de forma agresiva.

503:

* Mostrar backend o servicio no disponible.
* Permitir reintento manual.
* No asumir que una operación fue creada.

---

# 10. Auth y sesión

La autenticación se implementa contra el backend NestJS.

Endpoints obligatorios:

```text
POST /api/v1/auth/login
GET /api/v1/auth/me
POST /api/v1/auth/select-tenant
POST /api/v1/auth/logout
```

## Reglas

* El JWT se guarda en flutter_secure_storage.
* No se guarda JWT en SharedPreferences.
* No se guarda JWT en localStorage.
* No se imprime JWT en logs.
* No se implementa refresh token.
* No se implementa OAuth en MVP.
* No se implementa self-register público.

## Restauración de sesión

Al iniciar app:

```text
Buscar token local.
Si no existe, ir a Login.
Si existe, llamar /auth/me.
Si /auth/me responde 200, restaurar sesión.
Si /auth/me responde 401, limpiar sesión e ir a Login.
```

---

# 11. Tenant context

Los providers de listas/detalles observan sesión/tenant y se invalidan durante loading, logout, 401, selección/cambio y nueva sesión, incluso para el mismo tenant. Las respuestas tardías no repueblan el estado. ScopedFeaturePage aplica una clave por contexto dentro del Navigator, reiniciando formularios y filtros locales. No basta con cambiar la clave alrededor del Navigator, porque su GlobalKey puede preservar páginas.

El tenant actual vive en AuthState.

`currentTenantId` puede ser null.

ADMIN puede autenticarse sin tenant seleccionado.

OWNER y MEMBER operan dentro de tenant.

Flutter no debe mandar `tenantId` arbitrario en requests normales.

La única operación donde el usuario selecciona tenant explícitamente es:

```text
POST /api/v1/auth/select-tenant
```

Después de seleccionar tenant, Flutter debe reemplazar el contexto anterior por el contexto devuelto por backend.

---

# 12. Reglas para ADMIN, OWNER y MEMBER

La matriz sigue los controllers de backend/main `3a3309398458ab333d7b00f16e9c2df6a09ef734`, y reemplaza la política MEMBER inicial.

| Acción | ADMIN | OWNER | MEMBER |
|---|---|---|---|
| Tenants list/detail/select | Sí | Accesibles | Accesibles |
| Tenant create | Sí | No | No |
| Users list/detail | Sí | Sí | Sí |
| Users create/update | Sí | Sí | No |
| User deactivate | Sí | No | No |
| Campaign list/detail/create/update/archive | Sí | Sí | Sí |
| Campaign permanent delete | Sí | No | No |
| Prospects list/detail/update | Sí | Sí | Sí |
| Prospect manual create / CSV API | Sí | Sí | No |

Las operaciones tenant-scoped requieren organización seleccionada, incluido ADMIN. ADMIN sin tenant es válido para discovery, tenant create y Perfil.

`currentTenantPermissionsProvider` reconoce ADMIN desde AuthContext. Para OWNER/MEMBER consulta UsersApi.get(currentUserId) y usa sólo el role del tenant actual; no decodifica JWT ni inventa autorización. Una consulta fallida cierra acciones. Los formularios verifican permisos también por ruta directa; backend conserva autoridad y cualquier 403 debe mostrarse.

---

# 13. ApiClient

ApiClient vive en:

```text
lib/core/network/
```

Dio vive únicamente dentro de ApiClient o clases internas de network.

Las features no deben importar Dio.

ApiClient debe centralizar:

* baseUrl.
* Authorization Bearer.
* Headers comunes.
* Timeouts.
* Parsing de respuesta exitosa.
* Parsing de respuesta de error.
* Logging seguro.
* Descargas binarias.
* Cancelación de requests si aplica.
* Manejo de 401.
* Manejo de 403.
* Manejo de 429.
* Manejo de 503.

## Respuesta exitosa estándar

El backend responde:

```text
success
data
meta
```

`meta` es opcional.

## EmptySuccess

Una respuesta con `data: {}` no es error.

Ejemplos:

* logout.
* delete/soft delete.
* operación exitosa sin payload relevante.

## Exportaciones

Las exportaciones CSV/XLSX no usan el wrapper JSON estándar.

Deben manejarse como respuestas binarias.

---

# 14. DTOs

Los DTOs deben seguir OpenAPI estrictamente.

No se deben inventar campos para facilitar UI.

Si la UI requiere un dato que no existe, se reporta a Carlos y Ángel.

## DTOs base

Los DTOs base viven en:

```text
lib/shared/models/
```

DTOs base aprobados:

```text
ApiResponse
ApiErrorResponse
ApiException
PaginationMeta
AuthContext
AuthUser
AuthTenant
User
Role
Tenant
```

## Reglas críticas

AuthUser no es User.

AuthTenant no es Tenant.

role puede ser null.

currentTenantId puede ser null.

passwordHash nunca debe existir en cliente.

## DTOs de feature

Los DTOs específicos de una feature pueden vivir dentro de:

```text
lib/features/<feature>/models/
```

Ejemplos:

```text
Campaign
CreateCampaignRequest
UpdateCampaignRequest
Prospect
ProspectingJob
CreateProspectingJobRequest
```

---

# 15. Repositories

Cada feature debe tener una interfaz de repository.

Ejemplo conceptual:

```text
CampaignsRepository
ApiCampaignsRepository
MockCampaignsRepository
```

La UI y los providers deben depender de la interfaz, no de la implementación concreta.

## Repository interface

Define lo que la feature necesita hacer.

No debe saber si los datos vienen de API real o mock.

## API repository

Consume `PlatformApi` mediante `platformApiProvider`. Paths, métodos, queries, requests y parsing pertenecen a `lib/platform_api`; la feature adapta DTOs a su modelo visual. Ver `Docs/Contracts/Platform_API_Client.md` para uso y P2C.

Debe respetar OpenAPI.

No debe inventar payloads.

No debe resolver reglas de negocio.

## Mock repository

Sirve para desarrollo temporal.

Debe estar alineado al OpenAPI.

Debe estar claramente marcado como mock.

No es fuente de verdad.

Debe poder reemplazarse por API repository sin reescribir toda la UI.

---

# 16. Mocks

Tenants, Users, Campaigns y Prospects productivos usan API real. Sus mocks sólo pueden emplearse en tests/previews/estados UI controlados.

Dashboard demo y ProspectingJobsMockRepository pueden permanecer temporalmente porque sus features reales están fuera de este sprint. No usar mocks para autenticación, tenant context, autorización o reglas de negocio. Si un mock contradice OpenAPI, el mock está mal.

---

# 17. Campaigns

Implementado con CampaignsRepository, ApiCampaignsRepository y providers tenant-aware:

- List/search/pagination/sort contractual.
- Create/detail/edit de name, description y status.
- Archive para ADMIN/OWNER/MEMBER.
- Permanent delete ADMIN, con confirmación explícita y manejo de 409 por dependencias.
- Pestañas Detalle/Prospectos; prospectos de campaña mediante API real y lista paginada.

Manejar loading/empty/error/success y errores backend. No inventar contacted, conversion rate ni analytics.

---

# 18. Prospects

Implementado con ProspectsRepository, ApiProspectsRepository y providers tenant-aware:

- List/search/pagination, detail y update.
- Manual create ADMIN/OWNER con campaña elegida desde lista paginada del tenant actual.
- Integración de campaign prospects.
- Badges source google_maps/manual/csv.

CreateProspectRequest acepta únicamente campos contractuales; nunca tenantId/source/sourceIdentifier. Prospect.source usa PersistedProspectSource; ProspectingQuery/PipelineProgress/BusinessResult usan ProspectingSource, que sólo admite google_maps.

PATCH distingue omitted de explicit null. La UI sólo envía campos modificados y usa FieldUpdate.set(null) para vaciar campos nullable; metadata conserva soporte completo en API y visualización simple de sólo lectura en detalle. No agregar editor JSON complejo.

CSV preview/confirm están completos en PlatformApi con multipart encapsulado y modelos tipados. ApiUploadFile conserva copia inmutable: reutilizar exactamente los mismos bytes entre preview y confirm. Backend decide deduplicación, clasificación, expiración y concurrencia. HTTP 413 tiene error específico de 5 MB.

CSV UI/file picker/wizard/drag-and-drop no forman parte del sprint. La futura UI deberá regenerar preview en 400 expirado/409 obsoleto y advertir antes de UPDATE_EXISTING compartido. Ver Docs/Contracts/Platform_API_Client.md.

---

# 19. ProspectingJobs

> Implementado en la entrega CSV/Dashboard/Jobs. PlatformApi propaga 503 cuando la integración no está configurada; la UI no inventa una aceptación.

ProspectingJobs será feature posterior al foundation.

En Fase 5 puede existir como placeholder o mock.

En MVP funcional debe permitir:

* Crear job.
* Consultar detalle de job.
* Monitorear progreso.
* Cancelar job.
* Ver resultados temporales.
* Persistir resultados.
* Exportar resultados.
* Descartar resultados temporales.

Flutter no ejecuta el job.

Flutter no hace scraping.

Flutter no llama Prospector Service.

Flutter no llama Prospector Engine.

---

# 20. Jobs asíncronos y polling

> Implementado en la entrega CSV/Dashboard/Jobs. PlatformApi propaga 503 cuando la integración no está configurada; la UI no inventa una aceptación.

Los jobs largos pertenecen al backend, Prospector Service y Prospector Engine.

Flutter solo observa.

Estados obligatorios:

```text
QUEUED
RUNNING
COMPLETED
FAILED
CANCELLED
```

Para MVP se usará polling.

No se usará WebSocket.

No se usará SSE.

No se usarán workers en Flutter.

No se usarán background tasks en Flutter.

## Intervalo inicial

```text
3 a 5 segundos
```

## El polling debe detenerse cuando:

* El job llega a COMPLETED.
* El job llega a FAILED.
* El job llega a CANCELLED.
* El usuario hace logout.
* El backend responde 401.
* El usuario cambia de tenant.
* La pantalla/controlador se destruye.
* La feature decide cancelar monitoreo.

---

# 21. Caché temporal

> Implementado en la entrega CSV/Dashboard/Jobs. PlatformApi propaga 503 cuando la integración no está configurada; la UI no inventa una aceptación.

Los resultados temporales viven en memoria con Riverpod.

Se organizan por jobId.

No se usa base local.

No se usa offline avanzado.

No se usa secure storage para resultados de prospección.

## Se limpia cuando:

* Logout.
* 401.
* Cambio de tenant.
* Persistir resultados.
* Descartar resultados.
* Reinicio de app sin recuperación desde backend.

La caché temporal no es fuente de verdad.

---

# 22. Persistir, exportar y descartar

Estas son tres acciones separadas.

## Persistir

Flutter solicita al backend guardar resultados.

El endpoint actual no define `requestBody` en OpenAPI. Por lo tanto, la persistencia se invoca sin body y no se debe crear un DTO de request para esa operación hasta que el contrato lo defina.

El backend:

* Valida permisos.
* Valida tenant.
* Deduplica.
* Asocia campaña.
* Persiste en PostgreSQL.

Flutter muestra el resultado.

## Exportar

Flutter solicita archivo al backend.

El backend genera CSV/XLSX.

Flutter maneja bytes, nombre de archivo, MIME type y errores.

## Descartar

Flutter limpia resultados temporales locales.

No borra prospectos persistidos.

Debe pedir confirmación.

---

# 23. Deduplicación

La deduplicación definitiva ocurre en backend al persistir.

Prospector Engine puede realizar deduplicación técnica.

Flutter puede:

* Mostrar advertencias.
* Mostrar conteos.
* Mostrar posibles duplicados si backend lo informa.
* Permitir filtros visuales.

Flutter no debe:

* Borrar silenciosamente resultados.
* Decidir duplicados definitivos.
* Cambiar la persistencia real.
* Crear reglas paralelas de deduplicación.

---

# 24. UI/UX al desarrollar features

Cada pantalla debe diseñarse pensando en:

* Claridad.
* Estado actual.
* Acción principal.
* Acción secundaria.
* Errores.
* Vacíos.
* Permisos.
* Tenant actual.
* Carga.
* Confirmaciones.

La app debe sentirse:

* SaaS moderna.
* Comercial.
* Limpia.
* Profesional.
* Seria.
* Usable.
* Orientada a productividad.

Debe evitar:

* Apariencia de proyecto escolar.
* Pantallas saturadas.
* Componentes difíciles de implementar.
* Animaciones complejas innecesarias.
* Datos que no existan en OpenAPI.
* Métricas avanzadas no definidas.
* Flujos que contradigan backend.

---

# 25. Navegación

Rutas actuales: /tenants, /tenants/new, /tenants/:id, /change-tenant, /users, /users/new, /users/:id, /users/:id/edit, /campaigns, /campaigns/new, /campaigns/:id, /campaigns/:id/edit, /prospects, /prospects/new, /prospects/:id, /prospects/:id/edit y /profile. Se preservan splash/login/select-tenant/session-expired/backend-unavailable. Las rutas hijas tenant-scoped también requieren tenant. No agregar Jobs UI ni CSV UI en este sprint.

## Mobile

Mobile-first.

Bottom navigation para secciones principales:

```text
Dashboard
Campañas
Prospectos
```

Acciones secundarias:

```text
Perfil
Cambio de tenant
Administración
Logout
```

Estas acciones secundarias deben ir en perfil, drawer o menú secundario.

Logout no debe ser pestaña principal.

## Web/tablet

Usar sidebar o NavigationRail.

Mismas rutas.

Mismo estado.

Mismo AuthState.

No duplicar lógica.

---

# 26. Perfil

Perfil es una pantalla de sesión y contexto.

No es self-register.

No es onboarding.

No es administración completa de usuario.

Debe mostrar:

* Nombre.
* Email.
* platformRole si aplica.
* Tenant actual y rol de tenant cuando apliquen.
* Acción Cambiar organización y lista de tenants accesibles.
* Logout.
* Estado de sesión.

Cambio de contraseña queda postergado salvo que backend lo implemente y se cierre decisión nueva.

---

# 27. Administración

Tenants tiene interfaz/API repository, providers, list/detail/create ADMIN y selección/cambio desde Perfil. No existen update/delete de tenant: no inventarlos.

Users tiene interfaz/API repository, providers, list/search/pagination/sort/detail/create/update y desactivación ADMIN. DELETE se presenta como “Desactivar usuario”. Crear omite roleId para que backend asigne MEMBER, y la UI lo explica. No hay catálogo público de roles: no inventar IDs ni selector OWNER/MEMBER. Update permite campos contractuales y nueva contraseña opcional, siempre vacía inicialmente.

Admin es un hub de organizaciones y usuarios. Ocultar botones no sustituye autorización ni manejo de 403.

---

# 28. Documentar contradicciones

André debe reportar a Carlos cuando encuentre:

* Endpoint faltante.
* Campo faltante.
* Campo nullable no esperado.
* Código HTTP distinto.
* Error distinto.
* Estado de job distinto.
* Payload que no coincide.
* Necesidad de nueva ruta.
* Necesidad de nuevo permiso.
* UI que requiere datos no existentes.
* Mock que no puede alinearse al OpenAPI.

No se debe resolver unilateralmente inventando campos o reglas.

---

# 29. Testing por feature

Cada feature nueva debe incluir pruebas mínimas según su alcance.

Pruebas recomendadas:

* Repository con mock.
* Parser de DTOs.
* Estado loading.
* Estado empty.
* Estado error.
* Estado success.
* Manejo de 401 si aplica.
* Manejo de 403 si aplica.
* Widget principal.
* Provider principal.

Para ProspectingJobs además:

* Polling se detiene en estado terminal.
* Polling se detiene en 401.
* Cancelación detiene monitoreo.
* Descartar limpia caché temporal.
* Persistir limpia o actualiza estado temporal.
* Exportación maneja binario.

---

# 30. Reglas de commits y PRs

Usar ramas:

```text
main
dev
feature/<nombre>
```

Ejemplos:

```text
feature/campaigns-list
feature/prospects-filters
feature/prospecting-jobs-flow
feature/profile-screen
feature/admin-users
```

Antes de abrir PR:

* Ejecutar análisis/lints.
* Ejecutar tests aplicables.
* Verificar que no se modificaron archivos protegidos sin autorización.
* Verificar que no se agregaron secretos.
* Verificar que los mocks estén marcados.
* Verificar que DTOs sigan OpenAPI.
* Documentar endpoints faltantes si aplica.

---

# 31. Checklist para agregar una feature

Antes de desarrollar:

```text
[ ] Revisé OpenAPI.
[ ] Confirmé si el endpoint existe.
[ ] Identifiqué si requiere tenant.
[ ] Identifiqué roles visibles.
[ ] Identifiqué request DTO.
[ ] Identifiqué response DTO.
[ ] Identifiqué errores relevantes.
[ ] Identifiqué estado empty.
[ ] Identifiqué estado loading.
[ ] Identifiqué estado success.
[ ] Identifiqué estado error.
[ ] Definí repository interface.
[ ] Definí si necesito mock.
```

Durante desarrollo:

```text
[ ] No usé Dio directamente fuera de core/network.
[ ] No hice HTTP directo desde widgets.
[ ] No inventé campos fuera de OpenAPI.
[ ] No implementé lógica de negocio del backend.
[ ] No envié tenantId arbitrario.
[ ] No guardé secretos.
[ ] No imprimí token.
[ ] Manejo 401.
[ ] Manejo 403.
[ ] Manejo backend no disponible.
```

Antes del PR:

```text
[ ] La feature respeta estructura por carpetas.
[ ] La UI consume repository.
[ ] Los mocks están marcados.
[ ] Los DTOs siguen OpenAPI.
[ ] Hay estado loading.
[ ] Hay estado empty.
[ ] Hay estado error.
[ ] Hay estado success.
[ ] Hay tests mínimos.
[ ] No modifiqué archivos protegidos sin avisar.
[ ] Documenté pendientes o contradicciones.
```

---

# 32. Criterio de aceptación de una feature

Una feature puede considerarse aceptable cuando:

* Respeta el OpenAPI.
* No rompe AuthState.
* No rompe routing global.
* No rompe ApiClient.
* No introduce lógica de negocio indebida.
* Maneja loading, empty, error y success.
* Maneja permisos visibles según rol.
* Maneja tenant requerido si aplica.
* Tiene repository interface.
* Tiene API repository o mock repository según estado del backend.
* Tiene tests mínimos.
* Está documentada si introduce comportamiento relevante.

---

# 33. Fuera de alcance para André en features iniciales

No implementar sin nueva decisión:

* OAuth.
* Self-register.
* Refresh token.
* WebSocket.
* SSE.
* Workers en Flutter.
* Background tasks.
* Offline avanzado.
* Base local.
* Push notifications.
* Analytics.
* Deep linking.
* Tema oscuro obligatorio.
* Publicación en stores.
* Comunicación directa con Prospector Service.
* Comunicación directa con Prospector Engine.
* Scraping en Flutter.
* Exportación local si backend ya provee exportación.
* Deduplicación definitiva en cliente.

---

# 34. Regla final

Cuando exista duda entre avanzar rápido o respetar el contrato, gana el contrato.

Cuando exista duda entre inventar en Flutter o pedir ajuste de backend, se consulta con Carlos y Ángel.

Cuando exista duda entre mock y API real, OpenAPI define la forma y backend operativo define la verdad.

Cuando exista duda entre diseño visual y arquitectura, se coordina con Carlos antes de cambiar el flujo.

Fase 5 no busca terminar todo el frontend.

Fase 5 busca dejar una base estable para que el frontend pueda crecer sin romper la arquitectura.

---

# 35. Veredicto

Este documento queda alineado con:

FormularioDecisionesFase5.md.

Docs/ADRs/ADR-005-FlutterFoundation.md.

OpenAPI del SaaS Backend.

ADR-004-CommonBaseline.md.

Estado:

FEATURE DEVELOPMENT GUIDE READY.
