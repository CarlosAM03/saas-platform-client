# Plan de Implementación — Fase 5 Flutter Foundation

## Plataforma SaaS — Cliente Flutter

Repositorio:

```text
PlataformaFlutter/saas-platform-client
```

Estado documental previo:

```text
DOCUMENTATION RECONCILED / READY FOR IMPLEMENTATION PLAN
```

Objetivo de este documento:

Definir el plan técnico de implementación para construir el baseline Flutter Foundation sin convertir Fase 5 en frontend completo.

---

# 1. Objetivo de Fase 5

Fase 5 debe construir el foundation técnico del cliente Flutter.

El resultado esperado es:

```text
F5 CLOSED AS FLUTTER FOUNDATION / READY FOR FEATURE DEVELOPMENT
```

Esto significa que el repositorio debe quedar listo para que André pueda desarrollar features y Ángeles pueda trabajar UI/UX sobre una base estable.

Fase 5 no significa:

* Frontend completo.
* MVP completo.
* Sistema listo para producción.
* Integración completa con Prospector Service.
* Implementación completa de Campaigns, Prospects o ProspectingJobs.

---

# 2. Alcance obligatorio de implementación

La implementación debe incluir:

* Inicialización del proyecto Flutter.
* Estructura de carpetas aprobada.
* Configuración base del proyecto.
* Dependencias aprobadas.
* Tema visual inicial.
* Configuración de ambientes.
* ApiClient con Dio encapsulado.
* Manejo estándar de respuestas.
* Manejo estándar de errores.
* Secure storage para JWT.
* AuthService.
* AuthState con Riverpod.
* Routing protegido con go_router.
* Splash / sesión inicial.
* Login funcional contra backend.
* Restauración de sesión con `/auth/me`.
* Selección de tenant con `/auth/select-tenant`.
* Logout con `/auth/logout`.
* Perfil mínimo.
* Pantalla de backend no disponible.
* Pantalla o estado de sesión expirada.
* Placeholders para Dashboard, Campaigns, Prospects, ProspectingJobs y Admin.
* Mocks controlados por feature.
* Tests mínimos del foundation.
* README actualizado.
* FEATURE-DEVELOPMENT actualizado.
* CONTRIBUTING actualizado.
* Auditoría final del baseline.

---

# 3. Fuera de alcance de implementación

No implementar en Fase 5:

* Campaigns completas.
* Prospects completos.
* ProspectingJobs completos.
* Administración completa de usuarios.
* Administración completa de tenants.
* Integración real con Prospector Service.
* Integración real con Prospector Engine.
* Scraping en Flutter.
* Workers Flutter.
* Background tasks.
* WebSocket.
* SSE.
* Offline avanzado.
* Base local.
* Refresh token.
* OAuth.
* Self-register público.
* Invitaciones.
* Cambio de contraseña.
* Analytics.
* Push notifications.
* Deep linking.
* Tema oscuro obligatorio.
* Publicación en stores.
* Exportación local CSV/XLSX.
* Deduplicación definitiva en Flutter.

---

# 4. Dependencias aprobadas

Dependencias base:

```text
dio
flutter_riverpod
go_router
flutter_secure_storage
json_annotation
envied
logger
```

Dependencias de desarrollo:

```text
flutter_lints
build_runner
json_serializable
envied_generator
mockito o alternativa equivalente
```

Las versiones exactas se definen durante implementación con base en compatibilidad estable actual.

---

# 5. Estructura de carpetas a crear

La estructura base será:

```text
lib/
  main.dart
  app/
    app.dart
    app_providers.dart
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

Estructura interna recomendada por feature:

```text
lib/features/<feature>/
  data/
  models/
  providers/
  state/
  screens/
  widgets/
```

---

# 6. Fase de implementación 1 — Inicialización del proyecto

## Objetivo

Crear la base Flutter funcional dentro de:

```text
PlataformaFlutter/saas-platform-client
```

## Acciones

* Inicializar proyecto Flutter si aún no existe.
* Verificar que la app arranque.
* Configurar `pubspec.yaml`.
* Configurar `analysis_options.yaml`.
* Agregar dependencias aprobadas.
* Crear `.env.example`.
* Configurar assets si aplica.
* Confirmar ejecución en Android.
* Mantener compatibilidad con Web.

## Resultado esperado

La app debe ejecutar:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

sin errores bloqueantes.

---

# 7. Fase de implementación 2 — Configuración base

## Objetivo

Crear el foundation transversal de configuración.

## Archivos esperados

```text
lib/core/config/
lib/core/theme/
lib/app/
```

## Acciones

* Crear configuración de ambiente.
* Crear acceso tipado a variables no secretas.
* Configurar base URL.
* Crear tema base.
* Crear tokens visuales iniciales.
* Crear `App`.
* Crear composición global con `ProviderScope`.

## Reglas

No guardar secretos reales.

No versionar `.env`.

`.env.example` debe contener solo valores de ejemplo.

---

# 8. Fase de implementación 3 — Network foundation

## Objetivo

Implementar `ApiClient` con Dio encapsulado.

## Archivos esperados

```text
lib/core/network/api_client.dart
lib/core/network/api_response.dart
lib/core/network/api_result.dart
lib/core/network/network_constants.dart
```

Nombres exactos pueden variar, pero la responsabilidad debe quedar dentro de `core/network`.

## Reglas

Dio no debe importarse fuera de `core/network`.

Widgets no hacen HTTP directo.

Providers no hacen HTTP directo.

Features consumen repositories.

Repositories consumen ApiClient.

## ApiClient debe manejar

* Base URL.
* Headers comunes.
* Authorization Bearer.
* Timeouts.
* Respuestas JSON estándar.
* Errores estándar.
* EmptySuccess.
* Respuestas binarias para exportación futura.
* 401.
* 403.
* 429.
* 503.
* Logging seguro sin tokens.

---

# 9. Fase de implementación 4 — Errores

## Objetivo

Centralizar errores de backend y red.

## Archivos esperados

```text
lib/core/errors/api_exception.dart
lib/core/errors/network_exception.dart
lib/core/errors/error_codes.dart
```

## Comportamiento esperado

Los errores del backend deben mapearse a una excepción controlada.

Códigos soportados:

```text
400
401
403
404
409
429
503
```

No incluir `402`.

## Reglas

401 limpia sesión.

403 mantiene sesión.

503 muestra estado recuperable.

---

# 10. Fase de implementación 5 — Storage seguro

## Objetivo

Guardar y recuperar JWT de forma segura.

## Archivos esperados

```text
lib/core/storage/secure_storage_service.dart
```

## Reglas

Usar `flutter_secure_storage`.

No usar SharedPreferences para JWT.

No usar localStorage para JWT.

No imprimir token en logs.

No guardar resultados temporales en secure storage.

---

# 11. Fase de implementación 6 — DTOs base

## Objetivo

Crear modelos base alineados al OpenAPI.

## DTOs obligatorios

```text
ApiResponse
ApiErrorResponse
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

passwordHash no existe en cliente.

Usar `json_serializable`.

No inventar campos fuera de OpenAPI.

---

# 12. Fase de implementación 7 — Auth foundation

## Objetivo

Implementar autenticación real contra backend NestJS.

## Endpoints obligatorios

```text
POST /api/v1/auth/login
GET /api/v1/auth/me
POST /api/v1/auth/select-tenant
POST /api/v1/auth/logout
```

## Archivos esperados

```text
lib/features/auth/data/auth_repository.dart
lib/features/auth/data/api_auth_repository.dart
lib/features/auth/providers/auth_providers.dart
lib/features/auth/state/auth_state.dart
lib/features/auth/screens/login_screen.dart
lib/features/auth/screens/select_tenant_screen.dart
```

## Comportamiento esperado

Login exitoso:

* Guarda JWT.
* Guarda/restaura AuthContext.
* Decide si ir a Select Tenant o Dashboard.

Login 401:

* Muestra credenciales inválidas.

Login 429:

* Muestra rate limit.

auth/me 200:

* Restaura sesión.

auth/me 401:

* Limpia sesión.
* Redirige a Login.

select-tenant 200:

* Actualiza contexto.
* Reemplaza token/contexto si backend lo devuelve.
* Redirige a Dashboard.

logout:

* Llama backend si hay sesión.
* Limpia estado local.
* Limpia token.
* Redirige a Login.

---

# 13. Fase de implementación 8 — Routing

## Objetivo

Implementar navegación protegida con go_router.

## Archivos esperados

```text
lib/routes/app_router.dart
lib/routes/route_names.dart
lib/routes/route_guards.dart
```

## Rutas mínimas

```text
/splash
/login
/select-tenant
/dashboard
/campaigns
/prospects
/generate
/profile
/admin
/session-expired
/backend-unavailable
```

## Guards requeridos

* No autenticado → Login.
* Autenticado sin tenant → Select Tenant si ruta requiere tenant.
* ADMIN sin tenant → estado global limitado o Select Tenant.
* 401 → Login / session expired.
* Backend no disponible → pantalla o estado recuperable.

---

# 14. Fase de implementación 9 — Layout y navegación visual

## Objetivo

Crear navegación base mobile-first.

## Implementar

* Layout principal autenticado.
* Bottom navigation móvil.
* Sidebar o NavigationRail para pantallas amplias si es viable en foundation.
* Menú secundario para perfil, tenant, admin y logout.

## Tabs principales

```text
Dashboard
Campañas
Prospectos
Generar
```

## Acciones secundarias

```text
Perfil
Cambio de tenant
Administración
Logout
```

Logout no debe ser tab principal.

---

# 15. Fase de implementación 10 — Pantallas foundation

## Pantallas funcionales

```text
Splash
Login
Select Tenant
Perfil mínimo
Sesión expirada
Backend no disponible
Dashboard shell
```

## Pantallas placeholder

```text
Campaigns
Prospects
ProspectingJobs / Generar
Admin
```

## Estados obligatorios

Cada pantalla relevante debe contemplar:

```text
loading
empty
error
success
```

---

# 16. Fase de implementación 11 — Mocks controlados

## Objetivo

Permitir desarrollo visual y funcional progresivo sin backend completo.

## Features con mocks permitidos

```text
Dashboard
Campaigns
Prospects
ProspectingJobs
Admin tenants
```

## Reglas

Los mocks deben vivir dentro de cada feature.

Deben estar claramente nombrados como mocks.

Deben seguir OpenAPI.

No deben inventar campos.

No deben reemplazar Auth real.

No son fuente de verdad.

---

# 17. Fase de implementación 12 — Jobs foundation placeholder

## Objetivo

Preparar estructura para jobs sin implementar integración completa.

## Debe existir

* Feature `prospecting_jobs`.
* Modelos base si están claros en OpenAPI.
* Pantalla placeholder de generación.
* Estado visual de job.
* Estructura para polling futuro.
* Documentación de polling 3 a 5 segundos.

## No implementar todavía

* Worker Flutter.
* Background task.
* WebSocket.
* SSE.
* Prospector Service directo.
* Prospector Engine directo.
* Scraping.
* Persistencia real si endpoint no está operativo.
* Exportación real si endpoint no está operativo.

---

# 18. Fase de implementación 13 — Tests mínimos

## Tests obligatorios

Crear pruebas mínimas para:

* Parsing de ApiResponse.
* Parsing de ApiErrorResponse.
* ApiException.
* AuthState.
* SecureStorageService con mock.
* Login flow con repository mock.
* auth/me flow.
* select-tenant flow.
* logout flow.
* 401 behavior.
* 403 behavior.
* Router guards principales.

## Resultado esperado

```bash
flutter test
```

debe ejecutarse sin fallos.

---

# 19. Fase de implementación 14 — Documentación final

## Actualizar o validar

```text
README.md
FEATURE-DEVELOPMENT.md
CONTRIBUTING.md
Docs/Flutter-Foundation.md
Docs/ADRs/ADR-005-FlutterFoundation.md
Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md
```

## Debe quedar claro

* Cómo instalar.
* Cómo correr.
* Cómo configurar `.env`.
* Cómo crear una feature.
* Cómo trabajar con mocks.
* Qué archivos están protegidos.
* Cómo manejar Auth.
* Cómo manejar tenant.
* Cómo manejar errores.
* Qué está fuera de alcance.

---

# 20. Fase de implementación 15 — Auditoría final del baseline

## Objetivo

Después de implementar, generar una auditoría de baseline.

## Archivo esperado

```text
Docs/Auditorias/Fase5-Auditoria-Baseline-FlutterFoundation.md
```

## Debe revisar

* Estructura del repo.
* Dependencias.
* Configuración.
* Dio encapsulado.
* ApiClient.
* Secure storage.
* DTOs base.
* Auth foundation.
* Routing.
* Guards.
* Pantallas funcionales.
* Placeholders.
* Mocks.
* Tests.
* Documentación.
* Alineación con ADR-005.
* Alineación con FormularioDecisionesFase5.
* Alineación con OpenAPI.
* Alineación con ADR-004.

## Veredicto posible

```text
F5 BASELINE PASSED / READY FOR FEATURE DEVELOPMENT
F5 BASELINE PASSED WITH WARNINGS
F5 BASELINE FAILED / FIX REQUIRED
```

---

# 21. Criterios de aceptación global

Fase 5 puede considerarse implementada cuando:

* El proyecto Flutter arranca.
* La estructura aprobada existe.
* Las dependencias aprobadas están configuradas.
* Dio está encapsulado en ApiClient.
* No hay uso directo de Dio fuera de core/network.
* Auth foundation funciona contra backend real o queda preparado con configuración clara.
* Login está implementado.
* auth/me está implementado.
* select-tenant está implementado.
* logout está implementado.
* JWT se guarda en secure storage.
* 401 limpia sesión.
* 403 conserva sesión.
* currentTenantId nullable está modelado.
* ADMIN sin tenant está soportado.
* OWNER y MEMBER están modelados.
* Mocks están aislados por feature.
* Campaigns, Prospects y Jobs no bloquean cierre.
* No hay self-register.
* No hay OAuth.
* No hay refresh token.
* No hay WebSocket/SSE.
* No hay workers Flutter.
* No hay background tasks.
* No hay offline avanzado.
* No hay secretos reales.
* README está actualizado.
* FEATURE-DEVELOPMENT está actualizado.
* CONTRIBUTING está actualizado.
* Tests mínimos pasan.
* Auditoría final existe.

---

# 22. Orden recomendado para Codex

Codex debe implementar en este orden:

```text
1. Verificar estructura actual.
2. Inicializar Flutter si falta.
3. Configurar dependencias.
4. Crear estructura base.
5. Crear configuración y tema.
6. Crear errores y modelos base.
7. Crear ApiClient con Dio.
8. Crear secure storage.
9. Crear Auth repository/service/state.
10. Crear routing y guards.
11. Crear pantallas Auth.
12. Crear layout autenticado.
13. Crear placeholders de features.
14. Crear mocks mínimos.
15. Crear tests mínimos.
16. Actualizar documentación.
17. Ejecutar validaciones.
18. Generar auditoría final.
```

---

# 23. Comandos de validación esperados

Codex debe intentar ejecutar:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Si un comando falla por entorno, debe documentarlo en la auditoría final con:

* Comando ejecutado.
* Error observado.
* Causa probable.
* Acción recomendada.

---

# 24. Resultado esperado

Al terminar implementación, el repositorio debe quedar en estado:

```text
F5 CLOSED AS FLUTTER FOUNDATION / READY FOR FEATURE DEVELOPMENT
```

Y debe existir una auditoría final con veredicto:

```text
F5 BASELINE PASSED / READY FOR FEATURE DEVELOPMENT
```

o, si hay advertencias no bloqueantes:

```text
F5 BASELINE PASSED WITH WARNINGS
```

---

# 25. Nota final

Este plan no autoriza ampliar alcance.

Si durante implementación aparece una contradicción con OpenAPI, ADR-004, ADR-005 o FormularioDecisionesFase5, debe documentarse y detener el cambio afectado.

No se debe resolver inventando reglas en Flutter.

El frontend debe seguir siendo cliente API del SaaS Backend NestJS.

Estado del plan:

```text
PLAN DE IMPLEMENTACIÓN FASE 5 READY FOR CODEX PROMPT
```
