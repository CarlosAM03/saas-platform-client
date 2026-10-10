# Plan de Implementación — Hardening de Flutter Foundation

**Proyecto:** Plataforma SaaS de Prospección Automatizada y Gestión de Campañas  
**Componente:** Cliente Flutter  
**Baseline:** `dev @ 90e38656e1aafd3c81e8d639e6b17f973f81aff8`  
**Backend compatible:** `ab53272f531d15e6c4dcc9df8c1d6dca8601e87a`  
**Estado de entrada:** `BASELINE REQUIRES REPAIR BEFORE FEATURE DEVELOPMENT`

---

# 1. Objetivo

El objetivo de este hardening no es implementar Campaigns, Prospects, Users, Dashboard ni Jobs.

El objetivo es transformar la Flutter Foundation actual en una base suficientemente robusta, estable, testeada y contractual para que André pueda desarrollar features sin necesidad de modificar componentes transversales.

El resultado esperado es:

```text
FLUTTER FOUNDATION HARDENED
READY FOR FEATURE DEVELOPMENT
```

Al terminar esta fase deberán quedar estabilizados:

```text
Auth
JWT
Session lifecycle
Tenant context
Routing
ApiClient
API response parsing
API error parsing
Base DTOs
Secure storage
Environment configuration
Shared async/error infrastructure
CI / validation baseline
```

---

# 2. Principios del hardening

## 2.1 No expandir alcance funcional

Durante este bloque no se implementarán:

- Campaigns real.
- Prospects real.
- Users.
- Admin.
- Dashboard real.
- Jobs read-only.
- Profile completo.
- Prospector Service.
- Prospector Engine.

Pueden modificarse componentes visuales existentes únicamente si interfieren con la Foundation o presentan capacidades falsas.

---

## 2.2 Backend como autoridad

Flutter continuará siendo exclusivamente:

```text
Flutter
  ↓
NestJS SaaS Backend
  ↓
PostgreSQL
```

No se añadirá:

- lógica de negocio;
- autorización definitiva;
- acceso directo a PostgreSQL;
- llamadas directas a FastAPI;
- scraping;
- refresh token;
- OAuth;
- self-register.

---

## 2.3 No diseñar infraestructura para necesidades hipotéticas

La Foundation sólo debe resolver necesidades demostradas por:

- OpenAPI vigente;
- backend actual;
- primer avance;
- features próximas.

No se introducirán:

- generic repositories excesivamente abstractos;
- service locators;
- event buses;
- offline-first;
- caching complejo;
- retry automático global;
- WebSockets;
- interceptores adicionales sin necesidad actual.

El objetivo es robustez proporcional al proyecto.

---

# 3. Alcance técnico del hardening

El trabajo se divide en ocho bloques.

```text
H1  Auth lifecycle
H2  Session / Routing
H3  API transport and errors
H4  Response / Pagination contracts
H5  Tenant context
H6  Foundation UI / false capabilities
H7  Platform configuration / hygiene
H8  Tests + CI + validation
```

---

# 4. H1 — Auth lifecycle

## Problema

La auditoría ejecutable confirmó que Logout es el blocker principal.

Actualmente:

```text
POST /auth/logout → 200
JWT permanece
AuthState permanece autenticado
reload
GET /auth/me → 200
sesión restaurada
```

Además:

```text
flutter test
15 PASS
1 FAIL
```

y el fallo corresponde exactamente al logout.

## Implementación

Restaurar la semántica original:

```dart
Future<void> logout() async {
  try {
    if (state.context != null) {
      await authRepository.logout();
    }
  } on ApiException {
    // El logout remoto no debe impedir terminar
    // la sesión local.
  } finally {
    await storage.clearToken();
    state = unauthenticated;
  }
}
```

### Invariantes

Después de ejecutar logout:

```text
JWT local = null
AuthContext = null
AuthStatus = unauthenticated
ruta = /login
```

independientemente de:

```text
backend 200
backend 401
backend 503
network error
timeout
```

## Tests obligatorios

Agregar o conservar pruebas para:

```text
logout backend 200
logout backend network failure
logout backend 401
JWT eliminado
AuthState unauthenticated
reload no restaura sesión
```

---

# 5. H2 — Session lifecycle y routing

## 5.1 SessionExpired

Actualmente existe:

```text
401
→ sessionExpired
→ /session-expired
```

pero la pantalla sólo hace:

```text
context.go('/login')
```

sin cambiar AuthState.

Debe existir una acción explícita del controlador:

```dart
clearExpiredSession()
```

o equivalente.

Semántica:

```text
sessionExpired
    ↓
usuario reconoce expiración
    ↓
clear token defensivamente
    ↓
AuthState.unauthenticated
    ↓
/login
```

No permitir que routing sea quien intente corregir AuthState.

---

## 5.2 Responsabilidad del router

El router sólo debe decidir navegación en función de un estado ya correcto.

No debe:

- limpiar tokens;
- llamar repositories;
- cambiar tenant;
- reparar AuthState;
- implementar business logic.

---

## 5.3 Estados definitivos de Auth

Mantener un conjunto pequeño:

```text
unknown
loading
authenticated
unauthenticated
sessionExpired
backendUnavailable
failure
```

No agregar estados mientras no exista una necesidad concreta.

### Semántica

`unknown`
: aplicación todavía no ha restaurado sesión.

`loading`
: operación Auth activa.

`authenticated`
: existe AuthContext válido.

`unauthenticated`
: no existe sesión.

`sessionExpired`
: el backend rechazó un Bearer que previamente representaba una sesión.

`backendUnavailable`
: no se pudo verificar una sesión existente por indisponibilidad del servidor.

`failure`
: error de autenticación que no corresponde a los anteriores.

---

# 6. H3 — Eliminar bypasses y capacidades falsas

## 6.1 DevUser

Eliminar el bypass:

```text
frontend / frontend
dev-ui-token
```

del `AuthController`.

La Foundation funcional debe probar exclusivamente Auth real.

Si más adelante se necesita UI aislada, se hará mediante:

```text
Provider override
FakeRepository
fixtures de tests
```

Nunca mediante una excepción dentro del controlador productivo.

`dev_user.dart` puede eliminarse si deja de tener consumidores.

---

## 6.2 Public registration

Eliminar del runtime:

```text
¿No tienes cuenta?
Regístrate
register_dialog.dart
```

El backend actual no implementa self-registration y governance lo prohíbe.

No sustituirlo por ningún endpoint nuevo.

---

# 7. H4 — ApiClient y errores

ApiClient debe convertirse en la interfaz HTTP estable que André pueda utilizar sin modificar.

## 7.1 Mantener

```text
GET
POST
PATCH
DELETE
download
Bearer automático
timeout
401 interceptor
error mapping
```

---

## 7.2 DELETE con query parameters

Modificar:

```dart
delete(String path)
```

a:

```dart
delete(
  String path, {
  Map<String, dynamic>? queryParameters,
})
```

Esto es necesario para:

```http
DELETE /campaigns/:id?permanent=true
```

La modificación debe ser backward-compatible.

---

## 7.3 Error envelope

El backend utiliza:

```json
{
  "success": false,
  "error": {
    "code": "...",
    "message": "...",
    "details": {},
    "timestamp": "..."
  }
}
```

ApiClient deberá extraer correctamente:

```text
statusCode
kind
code
message
details
```

`details` debe representar:

```text
error.details
```

no el envelope completo.

### ApiException estable

```text
kind
statusCode
code
message
details
```

No es necesario agregar más abstracciones en este momento.

---

## 7.4 HTTP status mapping

Mantener como mínimo:

```text
400 badRequest
401 unauthorized
403 forbidden
404 notFound
409 conflict
429 rateLimited
503 serviceUnavailable
network
unknown
```

Agregar timeout a `network` si actualmente queda en `unknown`.

---

# 8. H5 — Response parsing contractual

La infraestructura actual sólo maneja adecuadamente:

```text
data: object
```

Debe soportar los tres tipos reales del backend.

## Tipo A — objeto

```json
{
  "success": true,
  "data": {}
}
```

## Tipo B — lista simple

```json
{
  "success": true,
  "data": []
}
```

Ejemplo:

```http
GET /tenants
```

## Tipo C — lista paginada

```json
{
  "success": true,
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 10,
    "totalPages": 1
  }
}
```

Ejemplos:

```text
Users
Campaigns
Prospects
Prospecting Jobs
```

---

# 9. Diseño del parsing base

No implementar un sistema genérico excesivamente complejo.

La Foundation debe ofrecer helpers pequeños y previsibles.

Conceptualmente:

```text
unwrapObject(response)
unwrapList(response)
unwrapPaginated(response)
```

o una solución equivalente.

### Resultado paginado

Definir una estructura reutilizable:

```dart
class PaginatedResult<T> {
  final List<T> items;
  final PaginationMeta meta;
}
```

`PaginationMeta` existente puede conservarse y endurecerse.

---

## Reglas de parsing

Si:

```text
success != true
```

el response exitoso no debe aceptarse silenciosamente.

Si:

```text
data
```

no tiene el tipo esperado, generar una excepción de parsing detectable.

No devolver:

```text
{}
[]
```

silenciosamente ante una respuesta estructuralmente inválida.

Eso ocultaría drift contractual.

---

# 10. H6 — Tenant context

Este es el cambio transversal más importante después de Auth.

## 10.1 Caso OWNER/MEMBER

El AuthContext puede seguir siendo suficiente cuando contiene sus memberships.

---

## 10.2 Caso ADMIN global

Se confirmó:

```text
ADMIN login
currentTenantId = null
AuthContext.tenants = []
```

pero:

```http
GET /tenants
→ todos los tenants
```

Por tanto, `AuthContext.tenants` no puede considerarse el único mecanismo universal de discovery.

---

# 11. Separar AuthContext de tenant discovery

AuthContext mantiene:

```text
user
accessToken
tenants entregados por Auth
currentTenantId
```

No modificar artificialmente esa respuesta.

Añadir una capa específica para tenants:

```text
TenantsRepository
```

con capacidad mínima:

```text
GET /tenants
```

Esta es la única feature-level excepción incluida en Foundation porque es necesaria para resolver correctamente el lifecycle de autenticación de ADMIN.

No implementar todavía administración completa de tenants.

---

# 12. SelectTenantPage

Debe obtener las opciones utilizando una política clara.

## Usuario normal

Puede utilizar memberships del AuthContext cuando sean suficientes.

## ADMIN sin tenant

Debe consultar:

```http
GET /tenants
```

y mostrar tenants accesibles.

Al seleccionar:

```http
POST /auth/select-tenant
```

Después:

```text
reemplazar JWT
reemplazar AuthContext
currentTenantId != null
```

---

# 13. Dashboard y tenant-awareness

Decisión:

**El Dashboard funcional del primer avance será tenant-aware.**

Por tanto:

```text
/dashboard
/campaigns
/prospects
/jobs
/users
```

requieren tenant operativo.

ADMIN sin tenant debe:

```text
Login
  ↓
Select Tenant
  ↓
Dashboard
```

No habrá un Dashboard global de plataforma en este avance.

Esto evita dos semánticas diferentes para el mismo screen.

---

# 14. Admin global vs Admin tenant

No implementar todavía Admin, pero fijar desde Foundation la separación conceptual.

```text
Platform administration
→ tenants

Tenant administration
→ users
```

Cuando André implemente Admin deberá construir la UI sobre estas dos capacidades sin mezclarlas.

---

# 15. H7 — Navegación y visibilidad base

## 15.1 `_requiresTenant`

Actualizar la lógica para reflejar que Dashboard también requiere tenant.

Como mínimo:

```text
/dashboard
/campaigns
/prospects
/jobs
```

Las rutas finales podrán cambiar cuando André implemente las features, pero la regla debe quedar centralizada.

---

## 15.2 `/generate`

La Foundation no debe anunciar una capacidad inexistente.

Decisión:

Eliminar temporalmente `Generate` de la navegación funcional.

No convertirlo todavía en Jobs durante este hardening.

La feature Jobs será implementada posteriormente por André como read-only.

Esto mantiene separación de responsabilidades.

---

## 15.3 Admin visibility

No implementar RBAC visual completo durante Foundation.

Pero evitar presentar `Administración` como capacidad universal si el destino continúa siendo placeholder.

Opciones aceptables para esta fase:

- retirar temporalmente el acceso;
- o mantenerlo sólo si está marcado claramente como no funcional durante desarrollo.

Preferencia:

```text
retirarlo de navegación hasta la feature Admin
```

---

# 16. H8 — Error UX transversal

No diseñar mensajes específicos de cada feature.

Sí estabilizar `ErrorMapper`.

Debe producir mensajes diferenciados para:

```text
400
401
403
404
409
429
503
network
unknown
```

Ejemplos conceptuales:

```text
401 → Credenciales inválidas o sesión expirada.
403 → No tienes permisos para realizar esta acción.
429 → Demasiadas solicitudes. Intenta nuevamente.
503 → El servicio no está disponible temporalmente.
network → No fue posible conectar con el servidor.
```

El backend sigue siendo la fuente del mensaje cuando éste sea seguro y apropiado.

Login debe dejar de mostrar siempre:

```text
No se pudo iniciar sesión.
```

---

# 17. Shared async state

`AsyncStateView` puede conservarse.

No introducir todavía una state machine genérica.

André debe poder reutilizar posteriormente:

```text
loading
empty
error
success
```

La Foundation sólo debe asegurarse de que:

- no crashee;
- pueda recibir mensaje de error;
- pueda recibir retry opcional si resulta sencillo.

No convertirlo en framework interno.

---

# 18. Environment y configuración

Mantener:

```text
API_BASE_URL
--dart-define
```

No migrar a `.env`.

Actualizar documentación de desarrollo para usar Web con:

```powershell
flutter run -d edge --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000
```

o Chrome si está disponible.

La auditoría demostró que `localhost:4200` funciona correctamente con CORS.

---

# 19. Windows y paths largos

La Foundation no debe modificar código para solucionar la limitación del path largo.

Documentar que el entorno actual requiere:

- checkout corto;
- o junction/unidad temporal;
- SDK en ruta corta.

La validación demostró que:

```text
flutter analyze → PASS
flutter build web → PASS
```

al eliminar la restricción del path.

No clasificarlo como defecto de aplicación.

---

# 20. Android

Añadir al manifest principal:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

porque una release Android requerirá networking.

No declarar Android validado todavía.

La validación Android queda pendiente hasta disponer de Android SDK/emulador o dispositivo.

No introducir configuración HTTP cleartext global sin necesidad demostrada.

---

# 21. Toolchain

Revisar las advertencias:

```text
analyzer conoce Dart 3.12
SDK actual Dart 3.13
build_runner ignora --delete-conflicting-outputs
```

Objetivo:

```text
dependencias compatibles
generación reproducible
sin actualización indiscriminada de majors
```

No realizar upgrades masivos.

Actualizar solamente lo necesario para mantener compatibilidad con Flutter 3.47.5 / Dart 3.13.4 o documentar de forma explícita el warning si no implica un defecto actual.

---

# 22. Higiene del repositorio

Revisar y eliminar del tracking únicamente artefactos generados que Flutter puede reconstruir y que no deben versionarse.

Prioridad:

```text
ios/Flutter/Generated.xcconfig
ios/Flutter/flutter_export_environment.sh
macos/Flutter/ephemeral/*
```

Actualizar `.gitignore`.

No eliminar registrants que Flutter espera versionados sin verificar primero la convención oficial del proyecto/plataforma correspondiente.

Corregir enlaces documentales rotos derivados del movimiento de `LineamientosUI-UX.md`.

---

# 23. CI Flutter

Agregar:

```text
.github/workflows/ci.yml
```

La pipeline mínima debe ejecutar:

```text
checkout
Flutter version fija
flutter pub get
code generation
flutter analyze
flutter test
flutter build web
```

No necesita backend ni PostgreSQL todavía porque estos checks validan Foundation.

Los E2E contra NestJS pueden incorporarse en una fase posterior.

---

# 24. Política sobre generated code

`*.g.dart` continúa ignorado si el proyecto mantiene generación local/CI.

CI debe ejecutar code generation antes de analyze/test/build.

Una build desde checkout limpio debe ser capaz de regenerar los archivos necesarios.

---

# 25. Tests nuevos obligatorios

La suite Foundation actual debe expandirse antes de declararla hardened.

## Auth

```text
startup sin token
restore válido
restore 401
restore network failure
login success
login invalid credentials
select tenant
logout backend success
logout backend failure
logout clears token
logout changes state
```

## Session

```text
401 authenticated request
→ clear token
→ sessionExpired

acknowledge session expired
→ unauthenticated
→ login
```

## Routing

```text
unknown → splash
unauthenticated → login
authenticated without tenant → select tenant
ADMIN without tenant → select tenant
authenticated with tenant → dashboard
tenant-aware route without tenant → select tenant
```

## ApiClient

```text
Bearer attached
401 callback
403 does not clear session
network mapping
timeout mapping
error.code parsing
error.details parsing
DELETE queryParameters
```

## Responses

```text
unwrap object
unwrap list
unwrap paginated
invalid success envelope
invalid object type
invalid list type
pagination parsing
```

## Tenants

```text
ADMIN discovery
select tenant replaces JWT
OWNER forbidden foreign tenant
```

---

# 26. Qué NO debe modificar André después del hardening

Después de aprobar esta fase, los siguientes elementos se consideran API interna estable del frontend:

```text
lib/app/**
lib/core/config/**
lib/core/network/**
lib/core/storage/**
lib/core/errors/**
lib/routes/**
AuthController / AuthState
AuthRepository
ApiException
ErrorMapper
PaginationMeta
response parsing helpers
tenant selection foundation
```

André no deberá modificarlos sin una revisión arquitectónica.

---

# 27. Interfaz que André recibirá

André podrá asumir que existe:

## Networking

```dart
apiClient.get(...)
apiClient.post(...)
apiClient.patch(...)
apiClient.delete(..., queryParameters: ...)
```

## Errores

```dart
ApiException
  .kind
  .statusCode
  .code
  .message
  .details
```

## Parsing

Una API estable equivalente a:

```text
parseObject
parseList
parsePaginated
```

## Estado

```text
AuthState
AuthContext
currentTenantId
```

## Routing

```text
sesión protegida
tenant seleccionado
redirects ya resueltos
```

## Storage

JWT completamente encapsulado.

André no necesita leer ni escribir tokens.

---

# 28. Arquitectura que deberá utilizar André

Después del hardening, cualquier feature debe seguir:

```text
Screen
   ↓
Provider / State
   ↓
Repository
   ↓
ApiClient
   ↓
NestJS
```

No deberá:

```text
import Dio
leer secure storage
manejar JWT
crear interceptors
modificar AuthController
inventar response envelopes
modificar routing transversal
```

---

# 29. Qué sí podrá modificar André

```text
lib/features/<feature>/**
```

Incluyendo:

```text
models específicos
request DTOs específicos
response DTOs específicos
repositories
providers
state
screens
widgets
feature tests
```

También podrá solicitar cambios de Foundation si un endpoint real demuestra que una capacidad transversal falta.

No deberá implementarla unilateralmente.

---

# 30. Orden de implementación del hardening

## Paso 1 — Session safety

```text
logout
sessionExpired
remove DevUser
remove register
```

Gate:

```text
Auth tests PASS
```

---

## Paso 2 — Network contract

```text
ApiException parsing
timeout/network mapping
delete query parameters
response helpers
pagination
```

Gate:

```text
network/parser tests PASS
```

---

## Paso 3 — Tenant foundation

```text
TenantsRepository mínimo
ADMIN discovery
select tenant
dashboard tenant-aware
routing
```

Gate:

```text
ADMIN / OWNER routing tests PASS
```

---

## Paso 4 — Navigation cleanup

```text
remove Generate capability
remove/limit premature Admin navigation
validate drawer/shell
```

Gate:

```text
no false capability exposed
```

---

## Paso 5 — Platform hardening

```text
Android INTERNET
toolchain
generated files
docs
```

---

## Paso 6 — CI

```text
analyze
test
build web
```

Gate:

```text
CI green
```

---

## Paso 7 — Integrated validation

Ejecutar backend:

```powershell
docker compose up --build -d
```

Ejecutar Flutter:

```powershell
flutter run -d edge --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000
```

Validar:

```text
OWNER login
restore
logout
reload after logout

ADMIN login
tenant discovery
select tenant
JWT replacement

invalid credentials
401
403
backend unavailable
session recovery
```

---

# 31. Definition of Done — Flutter Foundation Hardened

La Foundation se considerará lista únicamente cuando:

## Static

```text
flutter analyze → PASS
```

## Tests

```text
flutter test → 100% PASS
```

No basta con volver a 16/16.

La suite debe incluir los nuevos escenarios de hardening.

## Build

```text
flutter build web → PASS
```

## Runtime

Comprobados contra NestJS real:

```text
login
restore
logout
session expiry recovery
ADMIN tenant discovery
tenant selection
JWT replacement
OWNER tenant isolation
backend unavailable
```

## Security

```text
JWT sólo secure storage
no DevUser bypass
no public register
401 limpia sesión cuando corresponde
403 conserva sesión
no tokens en logs
```

## Contract

```text
object response parser
list response parser
paginated response parser
structured error parser
```

## Governance

```text
Foundation sólo modificada bajo ownership de Carlos
André recibe interfaz transversal estable
```

## CI

```text
analyze PASS
test PASS
build web PASS
```

---

# 32. Criterio de robustez para este proyecto

No buscamos una Foundation de producto SaaS empresarial completo.

Buscamos una Foundation adecuada para:

```text
proyecto académico
arquitectura multi-tenant real
backend NestJS real
PostgreSQL real
cliente Flutter multiplataforma
primer avance funcional
posterior integración Prospector
```

Por tanto será suficientemente robusta cuando:

1. una falla de backend no rompa la sesión local de forma incoherente;
2. una respuesta inválida no sea aceptada silenciosamente;
3. un 401 y un 403 tengan semánticas distintas;
4. el tenant context sea inequívoco;
5. ADMIN global pueda entrar a un tenant correctamente;
6. las features no necesiten tocar networking/Auth;
7. los contratos HTTP puedan modelarse sin hacks;
8. el proyecto pueda analizarse, testearse y compilarse de forma reproducible;
9. CI impida nuevas regresiones transversales;
10. la UI no anuncie funcionalidades inexistentes.

Nada más complejo es necesario en esta etapa.

---

# 33. Entregables del hardening

Codex deberá producir:

```text
código modificado
tests nuevos/actualizados
CI Flutter
documentación operacional ajustada
```

y un informe:

```text
Docs/Auditorias/Validacion_PostHardening_FlutterFoundation_2026-10-10.md
```

con:

```text
SHA inicial
SHA final o working tree
archivos modificados
decisiones aplicadas
tests agregados
flutter analyze
flutter test
flutter build web
runtime integration
ADMIN
OWNER
session/logout
errores
pendientes
```

---

# 34. Estado de salida esperado

Si todas las gates anteriores pasan:

```text
FLUTTER FOUNDATION HARDENED
READY FOR FEATURE DEVELOPMENT
```

Sólo entonces André debe continuar con:

```text
Campaigns
    ↓
Prospects
    ↓
Users
    ↓
Tenants / Admin
    ↓
Profile
    ↓
Dashboard real
    ↓
Jobs read-only
```

Campaigns será la primera prueba real de que la Foundation endurecida funciona como plataforma de desarrollo de features.

---

# 35. Regla final

Este hardening debe solucionar los problemas transversales demostrados por las auditorías sin adelantar trabajo de las features.

La Foundation resultante debe conseguir que André pueda implementar Campaigns sin preguntarse:

```text
¿Cómo manejo el JWT?
¿Cómo parseo el wrapper?
¿Cómo manejo paginación?
¿Qué hago con 401?
¿Qué hago con 403?
¿Cómo selecciono tenant?
¿Cómo envío DELETE con query?
¿Cómo sé si la sesión existe?
¿Dónde vive Dio?
```

Todas esas respuestas deben quedar resueltas antes de devolverle el repositorio.