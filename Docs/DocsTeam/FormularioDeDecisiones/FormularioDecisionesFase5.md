# Formulario de decisiones — Fase 5

## Flutter Foundation y baseline del cliente móvil/web

Proyecto: Plataforma SaaS — Cliente Flutter

Fase: Fase 5 — Flutter Foundation

Estado: Decisiones cerradas para implementación del baseline

Repositorio real: PlataformaFlutter/saas-platform-client

Responsable de arquitectura: Carlos Armenta

Responsables involucrados:

Carlos: arquitectura, integración, API client, configuración, routing, DTOs base, Auth foundation, documentación técnica y decisiones transversales.

André: desarrollo de features, pantallas, lógica de UI, repositories por feature, integración progresiva con endpoints y mocks controlados.

Ángeles: UI/UX, wireframes, diseño visual, componentes, estados de pantalla, prototipo y documentación visual/académica.

Ángel: evolución del backend funcional, endpoints de Campaigns, Prospects, ProspectingJobs, Tenants y coordinación de cambios OpenAPI.

---

# 1. Propósito de Fase 5

## Decisión cerrada

Fase 5 no es hacer todo el frontend.

Fase 5 es dejar el repositorio Flutter listo para que André implemente features y Ángeles diseñe UI/UX con límites claros.

La Fase 5 cerrará el foundation técnico del cliente Flutter:

Repositorio.

Estructura base.

Configuración.

Tema inicial.

Cliente API.

Manejo de sesión.

Autenticación.

Selección de tenant.

Routing protegido.

DTOs base.

Manejo estándar de errores.

Manejo de estados UI.

Mocks controlados.

Documentación para desarrollo.

Handoff a André.

Handoff a Ángeles.

Handoff a Ángel para compatibilidad backend/frontend.

## Implicación de implementación

Carlos no implementará todas las features. Carlos entregará la base técnica para que André pueda desarrollar Campaigns, Prospects, ProspectingJobs, Profile y Admin sin rediseñar arquitectura.

## Implicación funcional

El usuario podrá iniciar sesión, restaurar sesión, seleccionar tenant, entrar a una estructura navegable y ver pantallas base o placeholders preparados para integración progresiva.

---

# 2. Repositorio real del cliente Flutter

## Decisión cerrada

El repositorio/carpeta real del cliente Flutter será:

PlataformaFlutter/saas-platform-client

## Estructura documental inicial

El repositorio contendrá:

Docs

Docs/ADRs

Docs/DocsTeam

Docs/DocsTeam/FormularioDeDecisiones

Docs/Flutter-Foundation.md

Docs/LineamientosUI-UX.md

README.md

Posteriormente, cuando se inicialice Flutter, deberá contener también:

pubspec.yaml

lib

test

android

ios

web

analysis_options.yaml

.env.example

## Implicación de implementación

La carpeta PlataformaFlutter deja de ser solo preparación documental. El cliente oficial quedará dentro de PlataformaFlutter/saas-platform-client.

---

# 3. Relación entre Flutter y el sistema completo

## Decisión cerrada

Flutter será exclusivamente un cliente API del SaaS Backend NestJS.

Flutter no se conectará directamente a PostgreSQL.

Flutter no se conectará directamente a Prospector Service.

Flutter no se conectará directamente a Prospector Engine.

Flutter no ejecutará scraping.

Flutter no hará deduplicación definitiva.

Flutter no resolverá autorización real.

Flutter no será fuente de verdad de datos.

## Flujo arquitectónico

Usuario.

Flutter Client.

SaaS Backend NestJS.

PostgreSQL.

Prospector Service FastAPI.

Prospector Engine Python.

Google Maps u otras fuentes externas.

Resultados.

SaaS Backend NestJS.

Flutter Client.

## Implicación de implementación

Todo consumo HTTP desde Flutter deberá pasar por el Platform API del backend NestJS.

---

# 4. Alcance funcional de Fase 5

## Decisión cerrada

La única funcionalidad completa obligatoria para cerrar Fase 5 será Auth foundation.

Debe quedar funcional:

Splash / restauración de sesión.

Login.

Logout.

Auth me.

Select tenant.

Cambio de tenant.

Sesión expirada.

Error de backend no disponible.

Routing protegido.

AuthState.

Secure storage.

ApiClient.

DTOs base.

## No será obligatorio para cerrar Fase 5

Campaigns completas.

Prospects completos.

ProspectingJobs completos.

Administración completa de tenants.

Administración completa de usuarios.

Integración con Prospector Service.

Integración con Prospector Engine.

Exportación real.

Persistencia real de prospectos.

Dashboard con datos reales.

## Implicación funcional

Fase 5 valida que Flutter ya puede hablar correctamente con el backend operativo, pero no exige terminar el producto.

---

# 5. Alcance del MVP frontend

## Decisión cerrada

El flujo mínimo del MVP cliente será:

Login.

Validar sesión.

Seleccionar tenant si aplica.

Entrar a dashboard.

Crear o seleccionar campaña.

Generar prospectos.

Monitorear job asíncrono.

Mostrar progreso.

Cancelar job si aplica.

Ver resultados temporales.

Persistir resultados.

Exportar resultados CSV/XLSX.

Descartar resultados.

Consultar prospectos persistidos.

Gestionar prospectos dentro de campaña.

Gestionar ciclo de vida de campaña.

## Implicación de implementación

Aunque Fase 5 no implementa todo este flujo, sí debe preparar la arquitectura para que este flujo pueda construirse sin rediseñar.

---

# 6. Pantallas funcionales en Fase 5

## Decisión cerrada

Las pantallas funcionales obligatorias de Fase 5 serán:

Splash / Loading inicial.

Login.

Select Tenant.

Perfil mínimo / sesión.

Cambio de tenant.

Sesión expirada.

Backend no disponible.

Home shell después de login.

## Implicación de implementación

Estas pantallas deben consumir endpoints reales de Auth y Health cuando aplique.

---

# 7. Pantallas placeholder en Fase 5

## Decisión cerrada

Las siguientes pantallas pueden existir como shells, placeholders o mocks alineados al OpenAPI:

Dashboard.

Lista de campañas.

Crear campaña.

Detalle de campaña.

Editar campaña.

Lista de prospectos.

Detalle de prospecto.

Generar prospectos.

Progreso de job.

Resultados temporales.

Exportar resultados.

Administración de usuarios.

Administración de tenants.

## Implicación de implementación

Estas pantallas pueden ayudar a André y Ángeles a trabajar flujo y diseño, pero no se considerarán funcionales hasta que consuman backend real o mocks explícitamente marcados.

---

# 8. Pantallas postergadas

## Decisión cerrada

Quedan fuera de Fase 5 y fuera del MVP inicial:

Analytics avanzados.

Dashboards analíticos.

Reporting complejo.

Notificaciones push.

Deep linking.

Offline avanzado.

Cola de requests.

Tema oscuro obligatorio.

Publicación en stores.

OAuth.

Self-service onboarding.

Invitaciones.

Cambio de contraseña.

Configuración avanzada de cuenta.

## Implicación de implementación

No se deben crear rutas ni módulos obligatorios para estas funciones durante Fase 5.

---

# 9. Dirección visual inicial

## Decisión cerrada

La app debe sentirse como un SaaS moderno, comercial, limpio, serio, usable y profesional.

Debe evitar apariencia de proyecto escolar.

## Implicación para Ángeles

Ángeles puede iniciar wireframes y diseño visual con esta intención:

Claridad antes que decoración.

Productividad antes que glamour.

Estados visibles.

Componentes simples.

Flujo entendible.

Diseño viable en Flutter.

## Implicación para implementación

El tema inicial puede ser reemplazable. No congela marca, logo ni identidad visual final.

---

# 10. Navegación móvil

## Decisión cerrada

La navegación móvil será mobile-first con bottom navigation para las secciones principales.

Secciones principales sugeridas:

Dashboard.

Campañas.

Prospectos.

Generar.

## Acciones secundarias

Perfil.

Cambio de tenant.

Administración.

Logout.

Estas acciones no deben ir como pestañas principales. Deben vivir en perfil, drawer, menú secundario o menú de usuario.

## Implicación de implementación

Las rutas deben ser independientes del layout. No se deben duplicar flujos para móvil y web.

---

# 11. Navegación web/tablet

## Decisión cerrada

En pantallas grandes se usará sidebar o NavigationRail.

La navegación debe representar las mismas rutas que móvil, pero adaptadas al espacio disponible.

## Implicación de implementación

No habrá una app distinta para web. Será la misma arquitectura con layout responsive.

---

# 12. Target inicial

## Decisión cerrada

La app será mobile-first.

El primer target de validación será Android.

Web se mantendrá compatible para demo, revisión académica y pruebas rápidas.

## Implicación de implementación

Diseñar primero pensando en móvil, pero sin bloquear ejecución web.

---

# 13. Cliente HTTP

## Decisión cerrada

Se usará Dio como motor HTTP interno del ApiClient.

Dio no será usado directamente por pantallas, widgets, providers ni features.

Dio vivirá encapsulado dentro de:

lib/core/network

La app expondrá una abstracción propia:

ApiClient

## Regla obligatoria

Widgets no hacen HTTP directo.

Providers no hacen HTTP directo.

Features no consumen Dio directamente.

Repositories consumen ApiClient.

ApiClient usa Dio internamente.

## Implicación de implementación

ApiClient centraliza:

baseUrl.

Authorization Bearer.

Timeouts.

Parsing de success/data/meta.

Parsing de errores.

401.


403.

404.

Logs seguros.

Descarga binaria CSV/XLSX.

Cancelación de requests si aplica.

## Motivo

Dio permite trabajar con un patrón de cliente API más profesional, especialmente para interceptores, cancelación, timeouts, uploads/downloads y exportaciones binarias, sin romper KISS porque queda encerrado en una sola capa.

---

# 14. State management

## Decisión cerrada

Se usará Riverpod.

## Uso esperado

AuthState.

Sesión.

Tenant actual.

Estados de pantalla.

Repositories por feature.

Mocks intercambiables.

Caché temporal de resultados.

## Implicación de implementación

Cada feature debe manejar estados explícitos:

loading.

empty.

error.

success.

---

# 15. Routing

## Decisión cerrada

Se usará go_router con guards.

## Guards requeridos

Usuario no autenticado.

Usuario autenticado.

Tenant requerido.

ADMIN sin tenant.

Sesión expirada.

Backend no disponible.

## Implicación de implementación

El routing debe distinguir entre:

No autenticado.

Autenticado sin tenant.

Autenticado con tenant.

ADMIN global sin tenant.

Usuario con tenant seleccionado.

---

# 16. JWT y secure storage

## Decisión cerrada

El JWT se guardará en flutter_secure_storage.

No se usará SharedPreferences para tokens.

No se usará localStorage para tokens.

No se imprimirán tokens en logs.

No se versionarán secretos reales.

## Implicación de implementación

Al abrir la app:

Se revisa si existe token.

Si existe token, se llama /auth/me.

Si /auth/me responde 200, se restaura sesión.

Si /auth/me responde 401, se limpia sesión y se manda a Login.

---

# 17. Refresh token

## Decisión cerrada

No se implementará refresh token en Fase 5 ni en el MVP.

## Motivo

El backend no lo soporta.

## Implicación de implementación

Cuando expire el JWT, el usuario deberá iniciar sesión de nuevo.

No se deben implementar refresh silencioso ni reintentos inventados.

---

# 18. Login

## Decisión cerrada

El login será con email y contraseña contra:

POST /api/v1/auth/login

## Debe manejar

200: login exitoso.

401: credenciales inválidas.

429: rate limit.

Error de red: backend no disponible.

## Implicación de implementación

Después de login exitoso, Flutter debe guardar el token, cargar AuthContext y decidir la ruta siguiente según tenants y currentTenantId.

---

# 19. Registro público / creación de cuenta

## Decisión cerrada

No habrá registro público de usuarios en el MVP.

La creación de usuarios pertenece al flujo administrativo del SaaS.

## Interpretación del mensaje original

La “creación de perfil” mencionada en la conversación con André no se implementará como self-register público.

Se reinterpretará como:

Perfil de sesión.

Administración de usuarios.

Gestión de usuario desde ADMIN/OWNER cuando corresponda.

## Postergado

OAuth.

Invitaciones.

Self-service onboarding.

Cambio de contraseña.

Creación pública de tenant.

---

# 20. Perfil

## Decisión cerrada

Perfil será una pantalla de sesión y contexto, no una pantalla de registro público.

Debe mostrar:

Datos básicos del usuario autenticado.

Rol global si aplica.

Tenant actual si aplica.

Opción de cambiar tenant.

Opción de logout.

Estado de sesión.

## Implicación de implementación

Perfil puede ser funcional mínimo en Fase 5 porque depende de AuthContext y /auth/me.

---

# 21. Tenant context en cliente

## Decisión cerrada

El tenant activo vive en el AuthState, derivado del JWT y de la respuesta de AuthContext.

Flutter no enviará tenantId arbitrario en requests normales.

La única operación donde el usuario elige tenant explícitamente es:

POST /api/v1/auth/select-tenant

## Implicación de implementación

currentTenantId debe ser nullable.

ADMIN puede tener currentTenantId null.

Las operaciones tenant-aware deben requerir tenant seleccionado desde la experiencia de usuario.

---

# 22. Selección de tenant

## Decisión cerrada

Si el usuario tiene un solo tenant, se puede seleccionar automáticamente.

Si el usuario tiene múltiples tenants, debe elegir.

Si el usuario es ADMIN, puede existir sin tenant seleccionado, pero debe seleccionar tenant para operaciones tenant-aware.

## Implicación de implementación

Después de select-tenant, el backend devuelve contexto actualizado y/o JWT actualizado. Flutter debe reemplazar el contexto anterior.

---

# 23. ADMIN sin tenant

## Decisión cerrada

ADMIN sin tenant es un estado válido.

La UI debe soportar ese estado.

ADMIN sin tenant no debe entrar automáticamente a Campaigns, Prospects, Users tenant-aware ni Jobs tenant-aware.

Debe ver un estado global limitado con opción de seleccionar tenant o ir a administración global si el backend lo permite.

## Implicación de implementación

go_router debe poder redirigir a una pantalla de selección/contexto tenant cuando una ruta requiera tenant.

---

# 24. Roles y permisos visibles

## Decisión cerrada

Los roles en Flutter solo controlan visibilidad, habilitación y experiencia de usuario.

No reemplazan autorización real del backend.

## Matriz inicial cerrada para Fase 5/MVP

ADMIN:

Puede iniciar sesión.

Puede seleccionar tenant.

Puede cambiar tenant.

Puede acceder a cualquier tenant permitido por backend.

Puede administrar usuarios si hay tenant seleccionado.

Puede administrar tenants cuando el endpoint esté operativo.

Puede ejecutar acciones completas dentro de tenant.

OWNER:

Puede operar completamente dentro de su tenant.

Puede gestionar campañas.

Puede gestionar prospectos.

Puede generar jobs.

Puede persistir/exportar/descartar resultados.

Puede administrar usuarios del tenant si backend lo permite.

MEMBER:

Rol operativo limitado.

Puede ver dashboard.

Puede ver campañas.

Puede ver prospectos.

Puede filtrar prospectos.

No puede administrar usuarios.

No puede administrar tenants.

No puede crear campañas, generar jobs, persistir o exportar por default inicial, salvo que backend y producto lo habiliten después.

## Implicación

Si el backend permite más o menos acciones, el backend gana.

La UI puede ocultar/deshabilitar, pero debe aceptar 403 como respuesta válida.

---

# 25. Manejo de 401

## Decisión cerrada

401 significa token ausente, inválido o expirado.

Flutter debe:

Detener polling activo.

Limpiar token.

Limpiar AuthState.

Limpiar caché temporal.

Redirigir a Login.

Mostrar mensaje de sesión expirada o acceso requerido.

## Implicación de implementación

No se debe intentar refresh token.

---

# 26. Manejo de 403

## Decisión cerrada

403 significa usuario autenticado sin permiso o sin contexto tenant requerido.

Flutter debe:

Mantener sesión.

No borrar token.

Mostrar error contextual.

Si el error se debe a falta de tenant, redirigir a Select Tenant.

## Implicación

403 no es logout.

---

# 27. Manejo de errores estándar

## Decisión cerrada

Los errores del backend se parsean a ApiException.

Formato esperado:

success false.

error code.

error message.

error details.

error timestamp.

## Códigos relevantes

400: solicitud inválida.

401: sesión inválida.

403: no autorizado.

404: recurso no encontrado.

409: conflicto.

429: rate limit.

503: servicio no disponible.

## Implicación de implementación

Cada feature debe mostrar errores consistentes y no inventar estructuras distintas.

---

# 28. Respuestas exitosas

## Decisión cerrada

El cliente debe respetar el wrapper:

success.

data.

meta opcional.

## EmptySuccess

data vacío no es error.

Debe tratarse como operación exitosa.

Ejemplo conceptual:

logout exitoso.

delete/soft delete exitoso.

operación sin payload relevante.

## Implicación

No se debe asumir que data vacío significa fallo.

---

# 29. DTOs base

## Decisión cerrada

Los DTOs base obligatorios en Fase 5 serán:

ApiResponse.

ApiErrorResponse.

ApiException.

PaginationMeta.

AuthContext.

AuthUser.

AuthTenant.

User.

Role.

Tenant.

## Reglas críticas

AuthUser no es User.

AuthTenant no es Tenant.

role puede ser null.

currentTenantId puede ser null.

passwordHash nunca debe existir en cliente.

Los DTOs deben seguir OpenAPI estrictamente.

## Implicación

json_serializable se usará para reducir errores de parsing.

---

# 30. DTOs de features futuras

## Decisión cerrada

Los DTOs de Campaigns, Prospects y ProspectingJobs se crearán cuando André implemente cada feature.

Deben seguir OpenAPI.

No se deben inventar campos para acomodar UI.

Si la UI requiere datos que no existen en OpenAPI, se reporta a Carlos y Ángel.

## Implicación

No modelar todo prematuramente en Fase 5 si no es necesario para Auth foundation.

---

# 31. Arquitectura de carpetas Flutter

## Decisión cerrada

Se usará estructura por features con core y shared.

Estructura base:

lib/app

lib/core/config

lib/core/network

lib/core/storage

lib/core/errors

lib/core/theme

lib/shared/models

lib/shared/widgets

lib/features/auth

lib/features/campaigns

lib/features/prospects

lib/features/prospecting_jobs

lib/features/profile

lib/features/admin

lib/routes

test

docs

## Ownership

Carlos protege:

lib/app

lib/core/config

lib/core/network

lib/core/storage

lib/core/errors

lib/routes

DTOs base en lib/shared/models

Auth foundation

André trabaja principalmente en:

lib/features/campaigns

lib/features/prospects

lib/features/prospecting_jobs

lib/features/profile

lib/features/admin

lib/shared/widgets

tests de features

Ángeles aporta a:

docs

wireframes

lineamientos UI/UX

componentes visuales

estados de pantalla

---

# 32. ApiClient y repositories

## Decisión cerrada

La UI no consumirá ApiClient directamente salvo casos justificados del foundation.

Las features deben consumir repositories.

Cada feature puede tener:

Repository interface.

Api repository.

Mock repository.

Providers Riverpod.

State models.

Screens.

Widgets.

## Implicación

Esto permite integración progresiva: primero mock, después API real.

---

# 33. Mocks

## Decisión cerrada

Los mocks se permiten solo como apoyo temporal por feature.

Deben estar alineados al OpenAPI.

Deben estar claramente marcados como mocks.

No son fuente de verdad.

No deben inventar campos fuera del contrato.

La UI debe consumir interfaces para poder cambiar mock por API real.

## Implicación

André puede avanzar aunque Campaigns, Prospects o Jobs todavía no estén implementados en backend.

---

# 34. Campaigns

## Decisión cerrada

Campaigns será feature posterior sobre el foundation.

En Fase 5 puede existir como placeholder o mock.

En MVP funcional, Campaigns será el eje del flujo.

El usuario debe crear o seleccionar campaña antes de generar prospectos.

## Implicación de implementación

No se ofrecerá generación de prospectos sin campaignId si el contrato requiere campaña.

---

# 35. Prospects

## Decisión cerrada

Prospects será feature posterior sobre el foundation.

En Fase 5 puede existir como placeholder o mock.

En MVP funcional, permitirá:

Listar prospectos.

Ver detalle.

Filtrar.

Consultar prospectos por campaña.

Gestionar información permitida por backend.

## Implicación

Flutter no decide deduplicación definitiva ni persistencia real.

---

# 36. ProspectingJobs

## Decisión cerrada

ProspectingJobs será feature posterior sobre el foundation.

En Fase 5 puede existir como placeholder o mock.

En MVP funcional, permitirá:

Crear job.

Consultar job.

Monitorear progreso.

Cancelar job.

Ver resultados temporales.

Persistir resultados.

Exportar resultados.

Descartar resultados temporales.

## Implicación

Flutter no ejecuta el proceso. Solo lo solicita y lo observa.

---

# 37. Jobs asíncronos

## Decisión cerrada

La generación de prospectos se manejará como job asíncrono.

Estados obligatorios:

QUEUED.

RUNNING.

COMPLETED.

FAILED.

CANCELLED.

## Implicación de UI

Cada estado debe tener representación visual clara.

Debe indicarse progreso si el backend lo provee.

Deben habilitarse o deshabilitarse acciones según estado.

---

# 38. Polling

## Decisión cerrada

Para MVP se usará polling.

No se usará WebSocket ni SSE en Fase 5/MVP inicial.

Intervalo inicial:

3 a 5 segundos.

El polling se detiene en estados terminales:

COMPLETED.

FAILED.

CANCELLED.

También se detiene al logout, 401, cambio de tenant o salida del flujo si corresponde.

## Implicación

Menos infraestructura y menor complejidad.

---

# 39. Workers/background tasks en Flutter

## Decisión cerrada

No se implementarán workers ni background tasks en Flutter para MVP.

Los procesos largos viven en backend, Prospector Service y Prospector Engine.

Flutter solo monitorea mediante polling mientras la app está activa.

Si la app se cierra, Flutter no garantiza continuidad local del monitoreo.

Al volver, debe recuperar estado consultando backend si el job existe.

## Implicación

No se mete complejidad de ejecución en segundo plano en cliente.

---

# 40. Caché temporal de prospectos

## Decisión cerrada

Los resultados temporales vivirán en memoria del cliente usando Riverpod.

Se organizarán por jobId.

No se usará base local para MVP.

No se usará offline avanzado.

## Se limpia cuando:

Logout.

401.

Cambio de tenant.

Persistir resultados.

Descartar resultados.

Cierre de sesión.

## Implicación

Si la app se cierra, los resultados no persistidos pueden perderse, salvo que backend permita recuperarlos desde Job Detail.

---

# 41. Persistencia de resultados

## Decisión cerrada

Persistir resultados es responsabilidad del backend.

Flutter solo solicita persistencia mediante el endpoint correspondiente.

La deduplicación definitiva ocurre en backend.

## Implicación de UI

Después de persistir, mostrar:

Cantidad persistida.

Cantidad omitida.

Duplicados detectados si backend lo informa.

Errores parciales si backend los informa.

---

# 42. Exportación CSV/XLSX

## Decisión cerrada

Exportar y persistir son acciones separadas.

La exportación se hará desde backend.

Flutter debe manejar respuesta binaria.

Formatos:

CSV.

XLSX.

## Implicación

No generar CSV/XLSX manualmente en Flutter para MVP si backend ya define exportación.

---

# 43. Descarte de resultados

## Decisión cerrada

Descartar resultados significa limpiar resultados temporales locales.

No significa borrar prospectos ya persistidos.

Debe pedirse confirmación antes de descartar.

## Implicación

No se llamará endpoint de borrado si el contrato no lo define para resultados temporales.

---

# 44. Deduplicación

## Decisión cerrada

La deduplicación definitiva pertenece al backend al persistir.

Prospector Engine puede realizar deduplicación técnica durante extracción/normalización.

Flutter puede mostrar advertencias, filtros visuales o conteos, pero no decide la verdad final.

## Implicación

El cliente no debe eliminar silenciosamente resultados como si fueran duplicados definitivos.

---

# 45. Administración de usuarios

## Decisión cerrada

Administración de usuarios no bloquea Fase 5.

Puede existir como placeholder o feature posterior.

Aunque /users ya está operativo en backend, no será requisito para cerrar Flutter Foundation.

## Implicación

Fase 5 no crece innecesariamente.

---

# 46. Administración de tenants

## Decisión cerrada

Administración de tenants queda como placeholder o postergada hasta que el backend tenga endpoint operativo suficiente.

ADMIN debe poder seleccionar tenant y eventualmente administrar tenants, pero no se exige como funcional en Fase 5.

## Implicación

La UI no debe fingir administración real de tenants si el endpoint todavía es objetivo.

---

# 47. Testing

## Decisión cerrada

Fase 5 debe incluir pruebas mínimas del foundation.

Debe cubrir:

ApiClient.

Parsing de ApiResponse.

Parsing de ApiException.

AuthState.

SecureStorageService mock.

go_router guards.

Login flow.

me flow.

select-tenant flow.

logout flow.

401 behavior.

403 behavior.

## Implicación

Las features posteriores tendrán sus propias pruebas por módulo.

---

# 48. Documentación del repo

## Decisión cerrada

El repo deberá incluir:

README.md.

FEATURE-DEVELOPMENT.md.

CONTRIBUTING.md.

.env.example.

analysis_options.yaml.

Docs/Flutter-Foundation.md.

Docs/LineamientosUI-UX.md.

Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md.

La propuesta previa fue absorbida por este formulario; no existe un documento separado de propuesta vigente.

Docs/ADRs/ADR-005-FlutterFoundation.md.

## Implicación

André y Ángeles podrán trabajar sin depender de explicaciones verbales constantes de Carlos.

---

# 49. Git flow

## Decisión cerrada

main será la rama estable.

dev será la rama de integración.

feature/nombre será la rama de trabajo individual.

Toda modificación a core, routing, Auth, ApiClient, DTOs base o contrato debe coordinarse con Carlos.

## Implicación

André puede trabajar features sin romper foundation.

---

# 50. Handoff a André

## Decisión cerrada

André recibirá:

Repo Flutter funcional.

README.

FEATURE-DEVELOPMENT.

CONTRIBUTING.

ApiClient.

AuthService.

AuthState.

Routing protegido.

DTOs base.

Tema inicial.

Pantallas base.

Convención de repositories.

Convención de mocks.

## André puede modificar

features.

shared/widgets.

repositories de features.

providers de features.

screens de features.

tests de features.

## André no debe modificar sin Carlos

core/network.

core/config.

core/storage.

core/errors.

routes.

AuthState.

AuthService.

ApiClient.

DTOs base.

OpenAPI.

headers.

manejo global de errores.

manejo global de sesión.

## Implicación

André tiene ownership real de features, pero no de la infraestructura transversal.

---

# 51. Handoff a Ángeles

## Decisión cerrada

Ángeles recibirá:

Lineamientos UI/UX.

Lista de pantallas.

Flujo MVP.

Restricciones de backend.

Estados de UI requeridos.

Tema base inicial.

## Ángeles debe diseñar primero

Splash.

Login.

Select Tenant.

Dashboard.

Campañas lista.

Crear campaña.

Detalle de campaña.

Prospectos lista.

Generar prospectos.

Progreso de job.

Resultados temporales.

Perfil.

Estados Loading, Empty, Error, Success.

Backend no disponible.

Sesión expirada.

## Ángeles debe evitar

Diseñar contra datos inexistentes.

Diseñar métricas avanzadas como MVP.

Hacer obligatorio tema oscuro.

Hacer obligatorio analytics.

Hacer obligatorio push.

Diseñar componentes difíciles de implementar en Flutter.

Tratar permisos visuales como seguridad real.

## Implicación

El diseño apoya el desarrollo, no impone una arquitectura distinta.

---

# 52. Handoff a Ángel

## Decisión cerrada

Ángel debe evolucionar backend manteniendo compatibilidad con Flutter.

Prioridad backend para habilitar MVP:

Campaigns.

Prospects.

ProspectingJobs create/detail.

Job cancel.

Job progress.

Job results.

Persist results.

Export CSV/XLSX.

Tenants admin si entra al flujo.

## Cambios que requieren coordinación

OpenAPI.

Nombres de campos.

Nullability.

Códigos HTTP.

Estados de job.

Reglas de permisos.

Formato de errores.

Paginación.

Formato de exportación.

## Implicación

Flutter se construye contra contrato, no contra detalles internos de NestJS.

---

# 53. Scaffold externo / starters de Flutter

## Decisión cerrada

No se usará un scaffold genérico de auth como fuente de verdad.

Se pueden consultar starters o templates solo como referencia visual o estructural.

No se usará Firebase Auth.

No se usará Supabase Auth.

No se usará OAuth en MVP.

No se usará self-register público.

## Implicación

El Auth real se implementa contra la API NestJS existente.

---

# 54. Paquetes técnicos aprobados

## Decisión cerrada

Paquetes aprobados para Fase 5:

Dio para HTTP interno.

Riverpod para estado.

go_router para navegación.

flutter_secure_storage para JWT.

json_annotation y json_serializable para DTOs.

envied para configuración.

logger para logs seguros.

flutter_lints para linting.

mockito o alternativa equivalente para testing/mocks.

## Nota

Las versiones exactas se decidirán al momento de implementar pubspec.yaml.

---

# 55. Fuera de alcance técnico

## Decisión cerrada

No se implementará en Fase 5:

OAuth.

Refresh token.

WebSocket.

SSE.

Workers Flutter.

Background tasks Flutter.

Offline avanzado.

Base local.

Push notifications.

Analytics.

Deep linking.

Tema oscuro obligatorio.

Publicación en stores.

Generación local de exportaciones.

Scraping en Flutter.

Comunicación directa con Prospector Service.

Comunicación directa con Prospector Engine.

---

# 56. Matriz de pantallas

| Pantalla                   | Estado Fase 5          | Responsable  | Backend real | Notas                                |
| -------------------------- | ---------------------- | ------------ | ------------ | ------------------------------------ |
| Splash                     | Funcional              | Carlos       | Parcial      | Restaura sesión con token y /auth/me |
| Login                      | Funcional              | Carlos       | Sí           | Usa /auth/login                      |
| Select Tenant              | Funcional              | Carlos       | Sí           | Usa /auth/select-tenant              |
| Sesión expirada            | Funcional              | Carlos       | Sí           | Responde a 401                       |
| Backend no disponible      | Funcional              | Carlos/André | Sí           | Manejo de error/health/fallo HTTP    |
| Perfil mínimo              | Funcional mínimo       | Carlos/André | Sí           | Muestra AuthContext                  |
| Cambio de tenant           | Funcional              | Carlos/André | Sí           | Usa select-tenant                    |
| Dashboard                  | Placeholder            | André        | Parcial      | Shell inicial                        |
| Lista de campañas          | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Crear campaña              | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Detalle de campaña         | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Editar campaña             | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Lista de prospectos        | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Detalle de prospecto       | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Generar prospectos         | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Progreso de job            | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Resultados temporales      | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Exportar resultados        | Placeholder            | André        | Objetivo     | Mock o shell                         |
| Administración de usuarios | Placeholder            | André        | Parcial/Sí   | Backend existe, pero no bloquea F5   |
| Administración de tenants  | Placeholder/Postergada | André/Ángel  | Objetivo     | Depende de endpoint real             |

---

# 57. Matriz de permisos UI inicial

Esta matriz solo controla visibilidad y experiencia de usuario. No reemplaza autorización backend.

| Acción               | ADMIN | OWNER                    | MEMBER          | Requiere tenant | Estado                                      |
| -------------------- | ----- | ------------------------ | --------------- | --------------- | ------------------------------------------- |
| Login                | Sí    | Sí                       | Sí              | No              | Cerrada                                     |
| Logout               | Sí    | Sí                       | Sí              | No              | Cerrada                                     |
| Ver dashboard        | Sí    | Sí                       | Sí              | Sí              | Cerrada                                     |
| Seleccionar tenant   | Sí    | Si aplica                | Si aplica       | No              | Cerrada                                     |
| Cambiar tenant       | Sí    | Si tiene varios          | Si tiene varios | No              | Cerrada                                     |
| Ver campañas         | Sí    | Sí                       | Sí              | Sí              | Cerrada                                     |
| Crear campaña        | Sí    | Sí                       | No inicial      | Sí              | Cerrada para MVP inicial                    |
| Editar campaña       | Sí    | Sí                       | No inicial      | Sí              | Cerrada para MVP inicial                    |
| Archivar campaña     | Sí    | Sí                       | No inicial      | Sí              | Cerrada para MVP inicial                    |
| Ver prospectos       | Sí    | Sí                       | Sí              | Sí              | Cerrada                                     |
| Filtrar prospectos   | Sí    | Sí                       | Sí              | Sí              | Cerrada                                     |
| Generar prospectos   | Sí    | Sí                       | No inicial      | Sí              | Cerrada para MVP inicial                    |
| Cancelar job         | Sí    | Sí                       | No inicial      | Sí              | Cerrada para MVP inicial                    |
| Persistir resultados | Sí    | Sí                       | No inicial      | Sí              | Cerrada para MVP inicial                    |
| Exportar resultados  | Sí    | Sí                       | No inicial      | Sí              | Cerrada para MVP inicial                    |
| Descartar resultados | Sí    | Sí                       | Sí              | Sí              | Cerrada                                     |
| Administrar usuarios | Sí    | Sí si backend lo permite | No              | Sí              | Cerrada                                     |
| Administrar tenants  | Sí    | No                       | No              | No/parcial      | Cerrada como postergada hasta endpoint real |

---

# 58. Criterio de cierre Fase 5

## Decisión cerrada

Fase 5 se considera cerrada cuando exista:

Repositorio Flutter creado en PlataformaFlutter/saas-platform-client.

Flutter app arranca.

pubspec.yaml configurado.

Estructura base creada.

Tema base configurado.

Dio encapsulado en ApiClient.

ApiClient funcional.

Manejo estándar de errores.

SecureStorageService funcional.

AuthService funcional.

AuthState con Riverpod.

Routing protegido con go_router.

Login funcional contra backend.

auth/me funcional.

select-tenant funcional.

logout funcional.

DTOs base implementados.

README.md completo.

FEATURE-DEVELOPMENT.md completo.

CONTRIBUTING.md completo.

.env.example sin secretos reales.

Mocks documentados.

Handoff a André.

Handoff a Ángeles.

Handoff a Ángel.

## Veredicto esperado

F5 CLOSED AS FLUTTER FOUNDATION / READY FOR FEATURE DEVELOPMENT.

## Aclaración

No significa frontend completo.

No significa MVP completo.

No significa producción lista.

Significa que el repo Flutter queda listo para desarrollo funcional progresivo.

---

# 59. Estado final del formulario

Todas las decisiones necesarias para iniciar implementación de Fase 5 quedan cerradas.

Las decisiones marcadas como postergadas no quedan abiertas: quedan cerradas como fuera de alcance para Fase 5/MVP inicial.

Las features completas se implementarán después sobre el foundation.

La implementación concreta de archivos, clases, paquetes y versiones se decidirá durante la construcción del repositorio, respetando este formulario.

Estado:

F5 DECISIONS CLOSED / READY FOR FLUTTER FOUNDATION IMPLEMENTATION.
