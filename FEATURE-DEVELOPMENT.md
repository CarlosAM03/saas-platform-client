# FEATURE-DEVELOPMENT.md

## Plataforma SaaS — Cliente Flutter

Guía para desarrollo de features sobre el baseline Flutter Foundation.

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

La UI puede ocultar o deshabilitar acciones según rol.

Pero la autorización real siempre la decide el backend.

## ADMIN

Puede:

* Iniciar sesión.
* Seleccionar tenant.
* Cambiar tenant.
* Operar dentro de cualquier tenant autorizado.
* Administrar usuarios con tenant seleccionado.
* Administrar tenants cuando el endpoint esté operativo.

ADMIN sin tenant es un estado válido.

ADMIN sin tenant no debe entrar automáticamente a rutas tenant-aware como campañas, prospectos, users o jobs.

## OWNER

Puede operar funcionalmente dentro de su tenant.

Puede:

* Ver dashboard.
* Gestionar campañas.
* Gestionar prospectos.
* Generar jobs.
* Cancelar jobs.
* Persistir resultados.
* Exportar resultados.
* Descartar resultados.
* Administrar usuarios del tenant si backend lo permite.

## MEMBER

Para MVP inicial, MEMBER es rol operativo limitado.

Puede:

* Ver dashboard.
* Ver campañas.
* Ver prospectos.
* Filtrar prospectos.
* Descartar resultados temporales locales.

No puede por default inicial:

* Administrar usuarios.
* Administrar tenants.
* Crear campañas.
* Editar campañas.
* Archivar campañas.
* Generar jobs.
* Cancelar jobs.
* Persistir resultados.
* Exportar resultados.

Si backend o producto cambia esta regla, debe actualizarse OpenAPI, ADR o formulario correspondiente.

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

Consume ApiClient.

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

Los mocks están permitidos en Fase 5 y desarrollo posterior, pero con límites.

Se permiten para:

* Dashboard.
* Campaigns.
* Prospects.
* ProspectingJobs.
* Admin tenants si el endpoint aún no está operativo.
* Estados de UI.

No se deben usar para:

* Auth real de Fase 5.
* Login final.
* Tenant context real.
* Autorización real.
* Deducir reglas de negocio no documentadas.
* Inventar datos fuera del contrato.

## Regla

Si el mock contradice OpenAPI, el mock está mal.

Si la UI necesita datos que OpenAPI no tiene, se reporta.

---

# 17. Campaigns

Campaigns será feature posterior al foundation.

En Fase 5 puede existir como placeholder o mock.

En MVP funcional, Campaigns será el eje del flujo.

Reglas:

* El usuario debe crear o seleccionar campaña antes de generar prospectos.
* No se debe permitir generación de prospectos sin campaignId si el contrato requiere campaignId.
* Campaigns debe manejar estados loading, empty, error y success.
* Campaigns debe respetar paginación si el endpoint la define.
* Campaigns debe respetar permisos visibles por rol.

Pantallas esperadas:

* Lista de campañas.
* Crear campaña.
* Detalle de campaña.
* Editar campaña.
* Archivar campaña si backend lo permite.

---

# 18. Prospects

Prospects será feature posterior al foundation.

En Fase 5 puede existir como placeholder o mock.

En MVP funcional debe permitir:

* Listar prospectos.
* Ver detalle de prospecto.
* Filtrar prospectos.
* Consultar prospectos por campaña.
* Mostrar estados vacíos.
* Mostrar duplicados o advertencias si backend lo informa.
* Gestionar información permitida por backend.

Flutter no decide deduplicación definitiva.

Flutter no elimina prospectos por considerarlos duplicados sin confirmación/backend.

---

# 19. ProspectingJobs

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

## Mobile

Mobile-first.

Bottom navigation para secciones principales:

```text
Dashboard
Campañas
Prospectos
Generar
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
* Tenant actual si aplica.
* Lista o cambio de tenant si aplica.
* Logout.
* Estado de sesión.

Cambio de contraseña queda postergado salvo que backend lo implemente y se cierre decisión nueva.

---

# 27. Administración

## Administración de usuarios

No bloquea Fase 5.

Puede implementarse después como feature.

Aunque backend Users esté operativo, no es requisito de cierre del foundation.

## Administración de tenants

Queda como placeholder o postergada hasta que backend tenga endpoint operativo suficiente.

ADMIN puede tener acceso visual futuro, pero no se debe fingir funcionalidad real si el backend no está disponible.

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
