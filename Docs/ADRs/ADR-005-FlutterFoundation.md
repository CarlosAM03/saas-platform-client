# ADR-005 — Flutter Foundation

## Estado

Aceptado.

## Fecha

10 de septiembre de 2026.

## Proyecto

Plataforma SaaS — Cliente Flutter.

## Fase relacionada

Fase 5 — Flutter Foundation.

## Fuente principal

FormularioDecisionesFase5.md.

---

# 1. Contexto

El proyecto requiere un cliente multiplataforma desarrollado con Flutter para consumir el SaaS Backend construido en NestJS.

La arquitectura global del sistema establece el siguiente flujo lógico:

Flutter Client.

SaaS Backend NestJS.

PostgreSQL.

Prospector Service FastAPI.

Prospector Engine Python.

Fuentes externas, principalmente Google Maps.

Resultados.

SaaS Backend NestJS.

Flutter Client.

El cliente Flutter no es responsable de ejecutar scraping, conectarse a PostgreSQL, conectarse directamente al Prospector Service, conectarse directamente al Prospector Engine ni resolver reglas de negocio del SaaS.

El backend NestJS es la fuente principal de autorización, tenant context, reglas de negocio, persistencia, deduplicación definitiva, contratos HTTP y estructura de errores.

Fase 4 cerró el baseline del backend. Por lo tanto, Fase 5 debe alinearse estrictamente con las decisiones ya cerradas del backend, especialmente ADR-004, el contrato OpenAPI y el FormularioDecisionesFase5.md.

Fase 5 no tiene como objetivo construir todo el frontend. Su objetivo es dejar un repositorio Flutter preparado para desarrollo funcional progresivo.

---

# 2. Problema

El equipo necesita iniciar el desarrollo del cliente Flutter sin caer en tres riesgos principales:

1. Convertir Fase 5 en el desarrollo completo del frontend.
2. Crear una aplicación cliente que contradiga el backend NestJS.
3. Bloquear a André y Ángeles por falta de estructura, convenciones y límites de ownership.

También se requiere que Carlos mantenga la arquitectura, integración y decisiones transversales, sin convertirse en el único desarrollador de todas las pantallas y features.

Por lo tanto, se necesita definir una base técnica del cliente Flutter que permita:

Autenticación real contra el backend.

Restauración de sesión.

Selección de tenant.

Routing protegido.

Consumo controlado de API.

DTOs alineados al OpenAPI.

Manejo estándar de errores.

Mocks controlados para features no implementadas todavía.

Separación clara entre foundation, features y diseño UI/UX.

---

# 3. Decisión

Se aprueba crear el cliente Flutter bajo el enfoque Flutter Foundation.

La Fase 5 consistirá en construir el baseline técnico del cliente Flutter, no el frontend completo.

El repositorio real del cliente será:

PlataformaFlutter/saas-platform-client

El cliente Flutter será exclusivamente un cliente API del SaaS Backend NestJS.

Flutter consumirá únicamente el Platform API expuesto por el backend NestJS.

Flutter no consumirá directamente Prospector Service.

Flutter no consumirá directamente Prospector Engine.

Flutter no consumirá directamente PostgreSQL.

Flutter no ejecutará scraping.

Flutter no resolverá autorización real.

Flutter no será fuente de verdad de deduplicación.

---

# 4. Alcance aprobado para Fase 5

Fase 5 debe entregar:

Repositorio Flutter funcional.

Estructura base.

Configuración de ambiente.

Tema visual inicial.

Cliente API.

Manejo estándar de errores.

Secure storage.

AuthService.

AuthState.

Routing protegido.

Login real.

Restauración de sesión con auth/me.

Selección de tenant.

Logout.

DTOs base.

Mocks documentados.

README.md.

FEATURE-DEVELOPMENT.md.

CONTRIBUTING.md.

Handoff a André.

Handoff a Ángeles.

Handoff a Ángel.

Fase 5 se considera cerrada cuando el repositorio Flutter queda listo para desarrollo funcional progresivo.

El veredicto esperado de cierre será:

F5 CLOSED AS FLUTTER FOUNDATION / READY FOR FEATURE DEVELOPMENT.

---

# 5. Fuera de alcance de Fase 5

No forman parte obligatoria de Fase 5:

Campaigns completas.

Prospects completos.

ProspectingJobs completos.

Administración completa de usuarios.

Administración completa de tenants.

Integración con Prospector Service.

Integración con Prospector Engine.

Workers en Flutter.

Background tasks en Flutter.

WebSocket.

SSE.

Offline avanzado.

Base local.

Refresh token.

OAuth.

Self-register público.

Invitaciones.

Cambio de contraseña.

Analytics.

Push notifications.

Deep linking.

Tema oscuro obligatorio.

Publicación en stores.

Dashboards analíticos.

Reporting avanzado.

---

# 6. Arquitectura del cliente Flutter

Se aprueba una arquitectura por features, con separación entre capas transversales y módulos funcionales.

La estructura base será:

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

## Responsabilidades principales

lib/app:

Composición global de la aplicación, configuración principal, ProviderScope y punto de integración de la app.

lib/core/config:

Configuración de ambientes, base URL y variables no secretas.

lib/core/network:

ApiClient, Dio encapsulado, headers, Authorization Bearer, timeouts, parsing HTTP, errores, logs seguros y descargas binarias.

lib/core/storage:

Almacenamiento seguro del JWT mediante flutter_secure_storage.

lib/core/errors:

ApiException, errores de red, errores HTTP y helpers de parsing.

lib/core/theme:

Tema base, colores, tipografía, espaciado y tokens visuales iniciales.

lib/shared/models:

DTOs compartidos y modelos base alineados al OpenAPI.

lib/shared/widgets:

Componentes reutilizables, estados visuales comunes y widgets compartidos.

lib/features/auth:

Login, logout, restauración de sesión, selección de tenant, AuthState, AuthService y pantallas base de autenticación.

lib/features/campaigns:

Feature posterior para campañas.

lib/features/prospects:

Feature posterior para prospectos.

lib/features/prospecting_jobs:

Feature posterior para jobs de prospección.

lib/features/profile:

Perfil de sesión, tenant actual, cambio de tenant y logout.

lib/features/admin:

Administración de usuarios y tenants cuando los endpoints estén disponibles.

lib/routes:

go_router, guards y redirecciones según sesión y tenant context.

---

# 7. Cliente API

Se aprueba usar Dio como motor HTTP interno del cliente API.

Dio será un detalle de infraestructura encapsulado dentro de core/network.

La aplicación expondrá una abstracción propia llamada ApiClient.

Las pantallas no usarán Dio directamente.

Los widgets no usarán Dio directamente.

Los providers de feature no usarán Dio directamente.

Las features consumirán repositories.

Los repositories consumirán ApiClient.

ApiClient consumirá Dio internamente.

## Responsabilidades del ApiClient

ApiClient debe centralizar:

baseUrl.

Authorization Bearer.

Timeouts.

Parsing de success/data/meta.

Parsing de errores.

Manejo de 401.

Manejo de 403.

Manejo de 429.

Manejo de 503.

Logging seguro.

Descarga binaria CSV/XLSX.

Cancelación de requests cuando aplique.

## Justificación

Dio permite manejar interceptores, timeouts, cancelación, upload/download y respuestas binarias de forma adecuada para un cliente API multiplataforma.

El uso de Dio no debe romper KISS porque queda limitado a una capa transversal. El resto de la aplicación no debe acoplarse directamente a Dio.

---

# 8. Estado y navegación

Se aprueba Riverpod como mecanismo de estado.

Se aprueba go_router como sistema de navegación.

Riverpod se usará para:

AuthState.

Tenant actual.

Estado de sesión.

Estados por feature.

Repositories.

Mocks intercambiables.

Caché temporal de resultados.

go_router se usará para:

Rutas públicas.

Rutas protegidas.

Guards de autenticación.

Guards de tenant requerido.

Redirección ante sesión expirada.

Redirección ante ADMIN sin tenant intentando entrar a rutas tenant-aware.

---

# 9. Autenticación y sesión

El cliente Flutter consumirá los endpoints de autenticación del backend NestJS.

Endpoints obligatorios:

POST /api/v1/auth/login.

GET /api/v1/auth/me.

POST /api/v1/auth/select-tenant.

POST /api/v1/auth/logout.

El JWT se almacenará en flutter_secure_storage.

No se usará SharedPreferences para JWT.

No se usará localStorage para JWT.

No se imprimirán tokens en logs.

No se versionarán secretos reales.

## Restauración de sesión

Al iniciar la app:

1. Flutter revisa si existe JWT almacenado.
2. Si no existe JWT, redirige a Login.
3. Si existe JWT, llama a GET /api/v1/auth/me.
4. Si auth/me responde 200, restaura sesión.
5. Si auth/me responde 401, limpia sesión y redirige a Login.

## Refresh token

No se implementará refresh token porque el backend no lo soporta.

Cuando el JWT expire, el usuario deberá iniciar sesión nuevamente.

---

# 10. Tenant context

El tenant activo vive en AuthState, derivado del JWT y del AuthContext recibido desde el backend.

Flutter no enviará tenantId arbitrario en requests normales.

La única operación donde el usuario selecciona tenant explícitamente será:

POST /api/v1/auth/select-tenant

currentTenantId debe modelarse como nullable.

ADMIN puede tener currentTenantId null.

Las operaciones tenant-aware deben requerir tenant seleccionado desde la experiencia de usuario.

El backend sigue siendo responsable de validar tenant context y autorización real.

---

# 11. Roles y permisos visibles

Los roles en Flutter solo controlan visibilidad, habilitación y experiencia de usuario.

No reemplazan autorización backend.

La UI debe aceptar respuestas 403 como válidas aunque una acción haya sido visible.

## Matriz inicial

ADMIN:

Puede iniciar sesión.

Puede seleccionar tenant.

Puede cambiar tenant.

Puede operar dentro de cualquier tenant autorizado por backend.

Puede administrar usuarios con tenant seleccionado.

Puede administrar tenants cuando el endpoint esté operativo.

OWNER:

Puede operar funcionalmente dentro de su tenant.

Puede gestionar campañas.

Puede gestionar prospectos.

Puede generar jobs.

Puede persistir, exportar y descartar resultados.

Puede administrar usuarios del tenant si backend lo permite.

MEMBER:

Rol operativo limitado para MVP inicial.

Puede ver dashboard.

Puede ver campañas.

Puede ver prospectos.

Puede filtrar prospectos.

Puede descartar resultados temporales locales.

No puede administrar usuarios.

No puede administrar tenants.

No puede crear campañas, generar jobs, cancelar jobs, persistir resultados o exportar resultados por default inicial, salvo cambio posterior del contrato/producto.

---

# 12. Manejo de errores

Los errores del backend se modelarán como ApiException.

Formato esperado de error:

```text
success: false
error:
  code
  message
  details
  timestamp
```

Códigos relevantes:

400: solicitud inválida.

401: token ausente, inválido o expirado.

403: autenticado sin permisos o sin tenant requerido.

404: recurso no encontrado.

409: conflicto.

429: rate limit.

503: servicio no disponible.

## Comportamiento ante 401

Flutter debe:

Detener polling activo.

Limpiar token.

Limpiar AuthState.

Limpiar caché temporal.

Redirigir a Login.

Mostrar mensaje de sesión expirada o acceso requerido.

## Comportamiento ante 403

Flutter debe:

Mantener sesión.

No borrar token.

Mostrar error contextual.

Redirigir a Select Tenant si el error se debe a falta de tenant.

---

# 13. Respuestas y DTOs

El cliente debe respetar el wrapper estándar del backend:

```text
success
data
meta
```

meta es opcional.

EmptySuccess con data vacío no debe tratarse como error.

Las exportaciones CSV/XLSX no usan el wrapper JSON estándar. Se manejarán como respuestas binarias.

## DTOs base aprobados

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

passwordHash nunca debe existir en el cliente.

Los DTOs deben seguir el OpenAPI estrictamente.

Se usará json_serializable para reducir errores de parsing.

---

# 14. Mocks e integración progresiva

Se aprueba el uso de mocks controlados por feature.

Los mocks deben:

Vivir dentro de la feature correspondiente.

Estar alineados al OpenAPI.

Estar claramente identificados como mocks.

No inventar campos fuera del contrato.

No tratarse como fuente de verdad.

Ser reemplazables por repositories reales.

La UI debe consumir interfaces de repository, no implementaciones concretas.

Esto permite que André avance aunque Campaigns, Prospects o ProspectingJobs todavía no estén implementados en backend.

---

# 15. Jobs asíncronos

La generación de prospectos se modelará como job asíncrono.

Estados obligatorios:

QUEUED.

RUNNING.

COMPLETED.

FAILED.

CANCELLED.

Flutter no ejecuta el job.

Flutter no mantiene workers para ejecutar prospección.

Flutter solo solicita jobs al backend, monitorea estado, muestra progreso, permite cancelar y muestra resultados cuando estén disponibles.

## Polling

Para MVP se usará polling.

No se usará WebSocket ni SSE en Fase 5/MVP inicial.

Intervalo inicial:

3 a 5 segundos.

El polling se detiene en estados terminales:

COMPLETED.

FAILED.

CANCELLED.

También se detiene ante logout, 401, cambio de tenant o salida controlada del flujo.

---

# 16. Caché temporal de resultados

Los resultados temporales vivirán en memoria del cliente usando Riverpod.

Se organizarán por jobId.

No se usará base local para MVP.

No se usará offline avanzado.

La caché temporal se limpia cuando:

El usuario cierra sesión.

El backend responde 401.

El usuario cambia de tenant.

El usuario persiste resultados.

El usuario descarta resultados.

La app se reinicia y no hay recuperación desde backend.

La caché local no será fuente de verdad.

---

# 17. Persistencia, exportación y descarte

Persistir, exportar y descartar son acciones separadas.

Persistir:

Solicita al backend guardar resultados en PostgreSQL.

El backend decide deduplicación, asociación y persistencia.

Exportar:

Solicita al backend generar CSV/XLSX.

Flutter maneja respuesta binaria.

Descartar:

Limpia resultados temporales locales.

No borra prospectos ya persistidos.

Debe pedir confirmación antes de descartar.

---

# 18. Deduplicación

La deduplicación definitiva pertenece al backend al persistir.

Prospector Engine puede realizar deduplicación técnica durante extracción o normalización.

Flutter puede mostrar advertencias, filtros visuales o conteos recibidos desde backend, pero no decide la verdad final.

Flutter no debe eliminar silenciosamente resultados como si fueran duplicados definitivos.

---

# 19. Registro público y perfil

No habrá self-register público en MVP.

No habrá OAuth en MVP.

No habrá invitaciones en MVP.

No habrá cambio de contraseña en Fase 5.

La creación de usuarios pertenece al flujo administrativo del SaaS.

La pantalla de perfil será una vista de sesión y contexto.

Perfil debe mostrar:

Datos básicos del usuario autenticado.

Rol global si aplica.

Tenant actual si aplica.

Opción de cambiar tenant.

Opción de logout.

Estado de sesión.

---

# 20. UI/UX

La dirección visual inicial será:

SaaS moderno.

Comercial.

Limpio.

Profesional.

Serio.

Usable.

Orientado a productividad.

Debe evitar apariencia de proyecto escolar.

## Estados obligatorios por pantalla

Cada pantalla relevante debe contemplar:

Loading.

Empty.

Error.

Success.

Backend no disponible.

Sesión expirada cuando aplique.

## Navegación móvil

Mobile-first.

Bottom navigation para:

Dashboard.

Campañas.

Prospectos.

Generar.

Perfil, tenant, administración y logout vivirán en menú secundario, drawer o pantalla de perfil.

## Navegación web/tablet

Sidebar o NavigationRail.

Mismas rutas que móvil.

Layout responsive.

No duplicar lógica de navegación.

## Target inicial

Android será el primer target de validación.

Web se mantendrá compatible para demo y revisión académica.

---

# 21. Testing

Fase 5 debe incluir pruebas mínimas del foundation.

Se debe probar:

ApiClient.

Parsing de ApiResponse.

Parsing de ApiException.

AuthState.

SecureStorageService con mock.

go_router guards.

Login flow.

auth/me flow.

select-tenant flow.

logout flow.

401 behavior.

403 behavior.

Las features posteriores tendrán pruebas propias.

---

# 22. Documentación

El repositorio debe incluir:

README.md.

FEATURE-DEVELOPMENT.md.

CONTRIBUTING.md.

.env.example.

analysis_options.yaml.

Docs/Flutter-Foundation.md.

Docs/DocsTeam/Documentacion UIUX/LineamientosUI-UX.md.

Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md.

La propuesta previa de decisiones fue absorbida por `Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md`; no existe un documento normativo separado de propuesta.

Docs/ADRs/ADR-005-FlutterFoundation.md.

## Propósito documental

README.md:

Instalación, ejecución, propósito del cliente y estructura general.

FEATURE-DEVELOPMENT.md:

Cómo crear features, repositories, providers, pantallas, mocks y manejo de errores.

CONTRIBUTING.md:

Flujo Git, ramas, commits, PRs y reglas de ownership.

FormularioDecisionesFase5.md:

Registro completo de decisiones cerradas.

ADR-005:

Decisión arquitectónica resumida y normativa.

---

# 23. Git flow y ownership

main será la rama estable.

dev será la rama de integración.

feature/nombre será la rama de trabajo individual.

## Carlos protege

lib/app.

lib/core/config.

lib/core/network.

lib/core/storage.

lib/core/errors.

lib/routes.

Auth foundation.

ApiClient.

DTOs base.

Manejo global de sesión.

Manejo global de errores.

## André trabaja principalmente en

lib/features/campaigns.

lib/features/prospects.

lib/features/prospecting_jobs.

lib/features/profile.

lib/features/admin.

lib/shared/widgets.

tests de features.

## Ángeles trabaja principalmente en

docs.

wireframes.

lineamientos UI/UX.

componentes visuales.

estados de pantalla.

## Ángel coordina

OpenAPI.

Endpoints backend.

Nullability.

Códigos HTTP.

Estados de job.

Reglas de permisos.

Paginación.

Formato de errores.

Exportaciones.

Cualquier cambio transversal requiere coordinación con Carlos.

---

# 24. Consecuencias

## Consecuencias positivas

El frontend queda alineado con el backend real.

André puede desarrollar features sin rediseñar arquitectura.

Ángeles puede diseñar pantallas con límites claros.

Carlos mantiene control de integración sin implementar todo.

El cliente puede avanzar aunque algunos endpoints todavía no estén implementados.

Se reduce el riesgo de falta de integración vertical.

Se evita introducir complejidad innecesaria en Fase 5.

Dio permite construir un cliente API más robusto sin acoplar las features al motor HTTP.

## Consecuencias negativas

Fase 5 no entregará frontend completo.

Algunas pantallas serán placeholders.

Campaigns, Prospects y ProspectingJobs dependerán de implementación posterior del backend.

Los resultados temporales pueden perderse si la app se cierra antes de persistir.

No habrá refresh token.

No habrá offline avanzado.

No habrá workers en Flutter.

No habrá WebSocket/SSE inicialmente.

Algunas capacidades visuales o de UX quedarán postergadas.

## Riesgos aceptados

El MVP dependerá de integración progresiva con backend.

Los mocks deberán mantenerse estrictamente alineados al OpenAPI.

La gestión de permisos MEMBER podrá requerir ajuste posterior si el backend/producto cambia.

La administración de tenants dependerá de endpoint real.

La exportación real dependerá del endpoint binario del backend.

---

# 25. Alternativas consideradas

## Usar http simple en lugar de Dio

Ventaja:

Menor dependencia y mayor simplicidad inicial.

Desventaja:

Menos soporte directo para interceptores, cancelación, timeouts avanzados y descargas binarias.

Resultado:

Rechazada para este proyecto. Se aprueba Dio encapsulado porque el cliente será API-oriented y requiere un foundation profesional sin exponer Dio al resto de la app.

## Usar Dio directamente desde features

Ventaja:

Implementación rápida al inicio.

Desventaja:

Acopla pantallas y features al transporte HTTP, dificulta testing y rompe separación de responsabilidades.

Resultado:

Rechazada. Dio solo puede usarse dentro de core/network.

## Usar scaffold externo de auth

Ventaja:

Podría acelerar pantallas base.

Desventaja:

Puede imponer Firebase, Supabase, OAuth, self-register o flujos incompatibles con el backend NestJS multi-tenant.

Resultado:

Rechazada como fuente de verdad. Puede consultarse solo como referencia visual o estructural.

## Implementar self-register público

Ventaja:

Experiencia más familiar para apps SaaS públicas.

Desventaja:

Requiere decisiones no cerradas sobre tenant, roles, invitaciones, aprobación y onboarding.

Resultado:

Rechazada para MVP. La creación de usuarios queda como administración interna.

## Usar WebSocket/SSE para jobs

Ventaja:

Feedback en tiempo real más elegante.

Desventaja:

Requiere infraestructura y soporte adicional no necesario para MVP.

Resultado:

Postergada. Se usará polling.

## Implementar offline avanzado

Ventaja:

Mayor resiliencia del cliente.

Desventaja:

Agrega sincronización, almacenamiento local, conflictos y complejidad multi-tenant.

Resultado:

Postergada.

---

# 26. Criterio de aceptación del ADR

Este ADR se considera aceptado cuando:

FormularioDecisionesFase5.md queda actualizado con decisiones cerradas.

El repositorio PlataformaFlutter/saas-platform-client adopta esta arquitectura.

El README referencia este ADR.

FEATURE-DEVELOPMENT.md respeta este ADR.

CONTRIBUTING.md respeta el ownership definido.

La implementación de Fase 5 no contradice ADR-004 ni OpenAPI.

---

# 27. Veredicto

ADR-005 ACCEPTED — FLUTTER FOUNDATION APPROVED.

Fase 5 queda autorizada para implementación del baseline Flutter.

El cierre esperado de la fase será:

F5 CLOSED AS FLUTTER FOUNDATION / READY FOR FEATURE DEVELOPMENT.

Este ADR no declara el frontend completo.

Este ADR no declara el MVP completo.

Este ADR no declara producción lista.
