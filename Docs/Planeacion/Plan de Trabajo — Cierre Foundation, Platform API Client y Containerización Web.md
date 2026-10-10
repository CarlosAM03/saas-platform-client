# Plan de Trabajo — Cierre Foundation, Platform API Client y Containerización Web

**Proyecto:** Plataforma SaaS de Prospección Automatizada y Gestión de Campañas

**Repositorio:** `CarlosAM03/saas-platform-client`

**Rama de integración:** `dev`

**Baseline inicial:** `d4c846fa7494a98d74e3fcfb36c7517a8dbecb4d`

**Backend de autoridad:** `CarlosAM03/saas-platform-backend` @ `ab53272f531d15e6c4dcc9df8c1d6dca8601e87a`

**Fecha:** 10 de octubre de 2026

---

# 1. Propósito

Este plan define tres bloques consecutivos de trabajo antes de continuar el desarrollo funcional de las features Flutter.

Cada bloque deberá terminar en **un commit independiente y auditable**.

```text
Bloque 1
Cierre definitivo de Flutter Foundation
        ↓
Commit 1
        ↓
Auditoría

Bloque 2
Platform API Client completo
        ↓
Commit 2
        ↓
Auditoría

Bloque 3
Containerización Flutter Web
        ↓
Commit 3
        ↓
Auditoría
```

Después de auditar los tres bloques, la integración final a `main` se realizará manualmente mediante Pull Request.

No se realizará un único commit acumulativo.

---

# 2. Estado de partida

El hardening anterior dejó disponibles y validados:

```text
Auth real contra NestJS
JWT mediante secure storage
logout local robusto
sessionExpired recovery
routing tenant-aware
ADMIN tenant discovery
ApiClient centralizado
structured errors
object parsing
list parsing
pagination parsing
DELETE con query parameters
31 tests locales
Flutter analyze PASS
Flutter build web PASS
GitHub Actions Linux PASS
```

La ejecución remota de GitHub Actions correspondiente a:

```text
d4c846fa7494a98d74e3fcfb36c7517a8dbecb4d
```

finalizó correctamente.

Por tanto, este nuevo plan **no rehace el hardening anterior**.

Trabaja sobre él.

---

# 3. Objetivo global

Al finalizar los tres bloques se busca obtener:

```text
FLUTTER FOUNDATION
        +
COMPLETE PLATFORM API CLIENT
        +
REPRODUCIBLE WEB CONTAINER
```

de forma que André pueda recibir el repositorio bajo la regla:

```text
NO modificar:
Auth
Session
Storage
ApiClient transport
Platform API layer
Parsing transversal
Errors
Routing transversal
Tenant lifecycle
Container/runtime base
```

y concentrarse exclusivamente en:

```text
Feature UI
Feature state
Providers
Feature repositories/adapters
Screens
Widgets
Feature tests
```

---

# 4. Regla de commits

Codex realizará exactamente tres commits.

## Commit 1

```text
fix: close Flutter foundation hardening
```

## Commit 2

```text
feat: complete platform API client
```

## Commit 3

```text
chore: containerize Flutter web development
```

No mezclar trabajo de un bloque dentro de otro salvo una corrección estrictamente necesaria para que el bloque actual compile.

---

# BLOQUE 1 — CIERRE DEFINITIVO DE FLUTTER FOUNDATION

# 5. Objetivo del Bloque 1

Cerrar todos los hallazgos residuales derivados de la auditoría post-hardening y convertir Foundation en una capa definitivamente estable.

Estado objetivo:

```text
FLUTTER FOUNDATION HARDENED
ARCHITECTURALLY APPROVED
READY FOR API CLIENT EXPANSION
```

Este bloque no desarrolla features.

---

# 6. FND-PH-01 — `selectTenant()` + 401

Este es el hallazgo funcional principal pendiente.

Actualmente puede ocurrir:

```text
authenticated
    ↓
selectTenant()
    ↓
backend responde 401
    ↓
ApiClient elimina JWT
    ↓
sessionExpired
    ↓
selectTenant catch restaura previousContext
    ↓
authenticated + JWT null
```

Ese estado es inválido.

## Corrección

Un `401` durante `selectTenant()` debe tener prioridad sobre la conservación del contexto anterior.

Resultado obligatorio:

```text
401
↓
token eliminado
↓
context eliminado
↓
AuthStatus.sessionExpired
```

Mientras que errores no relacionados con autenticación pueden conservar la sesión anterior cuando sea seguro.

Ejemplos:

```text
403
404
409
503
network
```

no deberán transformarse automáticamente en pérdida de sesión.

---

# 7. Tests nuevos para selección de tenant

Agregar cobertura explícita para:

```text
selectTenant → 200
selectTenant → 401
selectTenant → 403
selectTenant → network failure
```

Caso crítico:

```text
authenticated
→ selectTenant
→ 401
→ token == null
→ context == null
→ sessionExpired
```

Caso de preservación:

```text
authenticated
→ selectTenant
→ error no-401
→ previous context preservado
→ sesión preservada
```

---

# 8. Rutas ocultas heredadas

Actualmente:

```text
/generate
/admin
```

siguen existiendo aunque hayan sido retiradas de la navegación.

No representan un P0.

Durante este bloque se debe tomar una decisión mínima y explícita.

Preferencia:

```text
mantener archivos y rutas como placeholders de desarrollo
pero impedir que se presenten como funcionalidad disponible
```

No eliminar trabajo visual de André.

Documentar que deep-link a estas rutas no representa feature soportada.

---

# 9. Actualizar validación post-hardening

El documento:

```text
Docs/Auditorias/Validacion_PostHardening_FlutterFoundation_2026-10-10.md
```

todavía indica que GitHub Actions remoto estaba:

```text
NOT VERIFIED
```

Esto ya no es cierto.

Actualizarlo con:

```text
commit:
d4c846fa7494a98d74e3fcfb36c7517a8dbecb4d

workflow:
Flutter Foundation CI

resultado:
SUCCESS
```

y registrar el nuevo test/corrección `selectTenant + 401`.

---

# 10. Branch protection

## Estado actual

Actualmente:

```text
main → unprotected
dev  → unprotected
```

El primer objetivo obligatorio es proteger:

```text
main
```

## Política mínima recomendada

Configurar GitHub para que `main` requiera:

```text
Pull Request obligatorio
no push directo
required status check:
Flutter Foundation CI / foundation
branch up-to-date antes de merge cuando sea viable
```

Opcionalmente:

```text
1 approval
```

si el modelo de colaboración académico lo permite.

## Importante

La protección real de rama **NO forma parte del commit Git**, porque es configuración del repositorio.

Por tanto el Bloque 1 tendrá dos resultados:

```text
A. Commit versionable
B. Configuración GitHub de branch protection
```

Codex podrá aplicar B únicamente si dispone de permisos/herramienta apropiados.

En caso contrario deberá documentar exactamente los parámetros para que Carlos los configure.

---

# 11. Governance

Actualizar la documentación sólo si resulta necesario para expresar claramente:

```text
main protegida
dev integración
feature/* trabajo
PR → dev
dev validado → PR → main
```

No reescribir toda la documentación.

---

# 12. Validación del Bloque 1

Ejecutar:

```text
flutter analyze
flutter test
flutter build web --no-wasm-dry-run
```

Todos deben pasar.

La suite deberá superar los 31 tests actuales al incorporar los nuevos casos.

Después del push deberá comprobarse:

```text
GitHub Actions → SUCCESS
```

---

# 13. Definition of Done — Bloque 1

Se considera terminado únicamente si:

```text
selectTenant + 401 corregido
test específico agregado
401 y 403 mantienen semánticas distintas
session lifecycle coherente
informe post-hardening actualizado
flutter analyze PASS
flutter test PASS
flutter build web PASS
GitHub Actions PASS
main protegida o configuración preparada/documentada
```

---

# 14. Commit 1

Mensaje:

```text
fix: close Flutter foundation hardening
```

No incluir trabajo de Platform API Client completo.

---

# BLOQUE 2 — PLATFORM API CLIENT COMPLETO

# 15. Objetivo del Bloque 2

Este bloque deja de ser Foundation.

Su objetivo es construir **la capa cliente completa y tipada del backend actualmente desplegado**, de modo que André no tenga que:

```text
inventar paths
crear requests HTTP
decidir query parameters
parsear envelopes
mapear responses
manejar exports
manejar códigos HTTP
modelar DTOs contractuales desde cero
```

Después de este bloque se podrá establecer:

```text
EL BACKEND ACTUAL YA TIENE CLIENTE FLUTTER COMPLETO
```

---

# 16. Distinción arquitectónica

No se debe inflar la clase transversal `ApiClient`.

Se mantendrán dos niveles.

## Nivel 1 — Transport

Ya existente:

```text
ApiClient
```

Responsable de:

```text
HTTP
Bearer
timeouts
status mapping
structured errors
response transport
```

## Nivel 2 — Platform API

Nuevo:

```text
Platform API Client
```

Responsable de representar los endpoints reales del backend.

Conceptualmente:

```text
PlatformApi
├── health
├── auth
├── tenants
├── users
├── campaigns
├── prospects
└── prospectingJobs
```

La implementación exacta puede dividirse en clientes especializados:

```text
HealthApi
AuthApi
TenantsApi
UsersApi
CampaignsApi
ProspectsApi
ProspectingJobsApi
```

o una composición equivalente.

No crear una clase monolítica inmanejable.

---

# 17. Regla para André después del Bloque 2

André NO deberá construir requests REST manualmente.

El flujo será:

```text
Feature
   ↓
Feature Repository / Provider
   ↓
Platform API Client tipado
   ↓
ApiClient transport
   ↓
NestJS
   ↓
PostgreSQL
```

André podrá construir lógica de feature alrededor de esa API, pero no redefinir:

```text
endpoint
HTTP method
query parameters
request DTO
response DTO
parsing
error envelope
```

---

# 18. Autoridad de alcance

La autoridad funcional será el backend realmente desplegado:

```text
saas-platform-backend
ab53272f531d15e6c4dcc9df8c1d6dca8601e87a
```

El README actual del backend establece:

## Operativo

```text
Health
Auth
Tenants
Users
Campaigns
Prospects persistidos
Jobs list
Jobs detail
```

## Deliberadamente pendiente

```text
Job create
Job cancel
Job persist
Job export
operational callbacks
Prospector Service
Prospector Engine
```

Las operaciones dependientes de Prospector actualmente responden:

```text
503
error.details.reason =
PROSPECTOR_INTEGRATION_PENDING
```

---

# 19. Alcance exacto del Platform API Client

## Health

Implementar cliente tipado para:

```http
GET /api/v1/health
GET /api/v1/health/live
GET /api/v1/health/ready
```

---

# 20. Auth

La funcionalidad ya existe.

Integrarla o adaptarla a la nueva capa sin romper Foundation:

```http
POST /api/v1/auth/login
GET  /api/v1/auth/me
POST /api/v1/auth/select-tenant
POST /api/v1/auth/logout
```

Auth sigue siendo ownership protegido.

No rehacer el lifecycle.

---

# 21. Tenants

Implementar cliente completo para:

```http
GET  /api/v1/tenants
POST /api/v1/tenants
GET  /api/v1/tenants/:id
```

DTOs:

```text
Tenant
CreateTenantRequest
```

No implementar UI.

---

# 22. Users

Implementar:

```http
GET    /api/v1/users
POST   /api/v1/users
GET    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id
```

Soportar:

```text
page
limit
search
sortBy
sortOrder
```

DTOs:

```text
User
Role
CreateUserRequest
UpdateUserRequest
```

DELETE representa desactivación, no borrado físico.

---

# 23. Campaigns

Implementar:

```http
GET    /api/v1/campaigns
POST   /api/v1/campaigns
GET    /api/v1/campaigns/:id
PATCH  /api/v1/campaigns/:id
DELETE /api/v1/campaigns/:id
GET    /api/v1/campaigns/:id/prospects
```

Query soportado:

```text
page
limit
search
sortBy
sortOrder
permanent
```

DTOs:

```text
Campaign
CreateCampaignRequest
UpdateCampaignRequest
```

La respuesta real deberá representar correctamente `createdBy` cuando el backend lo emita.

No reutilizar un view model visual como DTO HTTP.

---

# 24. Prospects

Implementar:

```http
GET   /api/v1/prospects
GET   /api/v1/prospects/:id
PATCH /api/v1/prospects/:id
```

y el acceso de campaña:

```http
GET /api/v1/campaigns/:id/prospects
```

DTOs:

```text
Prospect
UpdateProspectRequest
```

Soportar paginación, búsqueda y ordenamiento.

---

# 25. Prospecting Jobs

La capa cliente debe representar el backend desplegado, no fingir disponibilidad.

## Operativo

Implementar plenamente:

```http
GET /api/v1/prospecting-jobs
GET /api/v1/prospecting-jobs/:id
```

DTOs:

```text
ProspectingJobSummary
ProspectingJobDetail
ProspectingQuery
PipelineProgress
BusinessResult
```

---

# 26. Operaciones Jobs deliberadamente no disponibles

El backend expone rutas para:

```text
create
cancel
persist
export
```

pero actualmente devuelve `503` porque Prospector está pendiente.

La capa API puede representar estos endpoints si ello permite cubrir el contrato desplegado, pero deberá hacerlo bajo una regla explícita:

```text
NO presentarlos como funcionalidad disponible
NO convertir 503 en éxito
NO mockear resultados
NO ocultar PROSPECTOR_INTEGRATION_PENDING
```

Los tests deberán comprobar el manejo correcto del 503.

Las features del primer avance continuarán usando Jobs **read-only**.

---

# 27. DTOs

Completar todos los DTOs requeridos por el alcance desplegado.

Separar:

```text
DTO HTTP
ViewModel/UI model
```

No reutilizar modelos visuales de Dashboard como contrato API.

Los DTOs deben respetar:

```text
required
nullable
enum
DateTime
pagination
nested objects
```

del contrato vigente.

---

# 28. Query objects

Evitar repetir mapas libres por toda la aplicación.

Para recursos paginados puede definirse una abstracción pequeña equivalente a:

```text
PaginationQuery
page
limit
search
sortBy
sortOrder
```

No crear un query framework genérico complejo.

---

# 29. Tests unitarios/contractuales del Platform API

La suite debe crecer significativamente.

Por cada grupo de endpoints probar:

```text
HTTP method
path
query parameters
request body
headers especiales
DTO serialization
DTO parsing
object response
paginated response
EmptySuccess
error propagation
```

---

# 30. Tests Health

Cubrir:

```text
health
liveness
readiness
```

incluyendo respuesta 503 de readiness si corresponde.

---

# 31. Tests Tenants

Cubrir:

```text
list
get
create
400
401
403
409
```

según contrato.

---

# 32. Tests Users

Cubrir:

```text
list pagination
search
sort
get
create
update
deactivate
400
401
403
404
409
```

---

# 33. Tests Campaigns

Cubrir:

```text
list
pagination
search
sort
get
create
update
archive
permanent delete query
campaign prospects
401
403
404
409
```

---

# 34. Tests Prospects

Cubrir:

```text
list
pagination
search
sort
get
update
campaign-specific list
401
404
409
```

---

# 35. Tests Jobs

Cubrir:

```text
list
detail
pagination
status DTOs
503 pending integration
PROSPECTOR_INTEGRATION_PENDING
```

No declarar como funcional create/cancel/persist/export.

---

# 36. API contract tests

Agregar una suite específicamente destinada a detectar drift entre:

```text
Platform API Client
y
contrato/backend actual
```

El objetivo es que un cambio accidental de:

```text
path
method
query
wrapper
DTO
```

rompa tests antes de llegar a André.

---

# 37. P2C — prueba punta a punta del cliente API

Agregar una prueba de integración real que recorra:

```text
Flutter/Dart Platform API Client
        ↓
ApiClient
        ↓
NestJS real
        ↓
Prisma
        ↓
PostgreSQL
```

En este plan llamaremos esta prueba:

```text
P2C
Platform-to-Cloud/Client end-to-end
```

operacionalmente:

```text
cliente API → backend → base de datos
```

---

# 38. Alcance mínimo del P2C

Utilizando el backend local reproducible y su seed:

```text
docker compose up --build
```

probar al menos:

```text
health ready
login OWNER
auth/me
list campaigns
get campaign
list prospects
list users
list jobs
```

y un flujo de persistencia reversible o controlado.

Ejemplo preferido:

```text
crear Campaign
↓
consultarla
↓
actualizarla
↓
archivarla
↓
confirmar estado por GET/list
```

Esto demuestra:

```text
cliente
→ backend
→ PostgreSQL write
→ PostgreSQL read
→ cliente
```

No probar destructivamente sobre producción.

Usar exclusivamente entorno local/test.

---

# 39. Independencia del P2C

La suite P2C no debe depender del backend de producción.

Debe utilizar:

```text
backend Docker local
PostgreSQL local/test
seed reproducible
```

Puede requerir checkout adyacente del backend o una variable que apunte a él.

---

# 40. P2C y CI

La CI normal del frontend debe validar completamente:

```text
DTOs
Platform API
transport
contract behavior
flutter analyze
flutter test
flutter build web
```

El P2C real puede quedar inicialmente:

```text
manual
local
workflow_dispatch
o job separado no bloqueante
```

si integrar dos repositorios y Docker dentro de la CI principal añade complejidad innecesaria.

No sacrificar la reproducibilidad del CI principal sólo por forzar P2C remoto.

---

# 41. GitHub Actions después del Bloque 2

Actualizar CI para incluir las nuevas suites de Platform API.

El check requerido de `main` deberá seguir pasando.

Resultado esperado:

```text
foundation tests
+
Platform API tests
+
contract tests
+
build web
```

todo verde.

---

# 42. Qué NO se implementa en Bloque 2

No implementar:

```text
Campaigns UI
Prospects UI
Users UI
Admin UI
Dashboard real
Jobs UI
providers de feature completos
feature state
feature navigation
```

El bloque construye **la infraestructura API completa**, no las features.

---

# 43. Definition of Done — Bloque 2

Debe cumplirse:

```text
todos los endpoints activos del backend tienen cliente tipado
DTOs alineados
query params alineados
errores alineados
Jobs pendientes representan correctamente 503
suite Platform API completa
contract tests PASS
P2C local PASS
flutter analyze PASS
flutter test PASS
flutter build web PASS
GitHub Actions PASS
```

---

# 44. Resultado arquitectónico del Bloque 2

Después de este bloque se podrá entregar a André esta regla:

```text
No construyas HTTP.

No modifiques ApiClient.

No inventes endpoints.

No hagas parsing manual.

Consume Platform API.

Construye únicamente tu feature.
```

---

# 45. Commit 2

Mensaje:

```text
feat: complete platform API client
```

No incluir containerización Web.

---

# BLOQUE 3 — CONTAINERIZACIÓN FLUTTER WEB

# 46. Objetivo del Bloque 3

Permitir que desde un clon limpio del cliente sea suficiente disponer de:

```text
Git
Docker
Docker Compose
```

para levantar Flutter Web.

Objetivo operacional:

```text
git clone
cd saas-platform-client
docker compose up --build
```

y obtener el cliente disponible en navegador.

---

# 47. Alcance

Este bloque es exclusivamente DevOps/runtime de desarrollo Web.

No modifica funcionalidades de negocio.

No implementa despliegue productivo definitivo.

---

# 48. Resultado esperado

Por defecto:

```text
Flutter Web:
http://localhost:4200
```

Backend esperado:

```text
http://localhost:3000
```

La aplicación Web deberá compilarse/servirse con:

```text
API_BASE_URL=http://localhost:3000
```

o un valor configurable equivalente.

---

# 49. Dockerfile

Aunque el requisito mínimo es Compose, se recomienda agregar:

```text
Dockerfile.dev
```

para fijar el SDK Flutter y evitar depender de imágenes/configuraciones implícitas.

Debe utilizar una versión compatible con:

```text
Flutter 3.47.5
Dart 3.13.4
```

o la versión vigente del proyecto si cambia controladamente antes de este bloque.

---

# 50. Docker Compose

Agregar un Compose de desarrollo, por ejemplo:

```text
compose.yaml
```

o equivalente siguiendo la convención actual del repositorio.

Servicio conceptual:

```text
flutter-web
```

Responsabilidades:

```text
instalar/resolver dependencias
ejecutar code generation
servir Flutter Web
escuchar 0.0.0.0
exponer puerto 4200
usar API_BASE_URL configurable
```

---

# 51. Comando único

La experiencia obligatoria debe ser:

```powershell
docker compose up --build
```

No requerir en host:

```text
Flutter
Dart
Node
Chrome
Android SDK
```

para servir Web.

---

# 52. Comunicación con backend

El código ejecutado en el navegador accederá al backend mediante la URL pública para el host:

```text
http://localhost:3000
```

No usar dentro de `API_BASE_URL` el hostname interno del contenedor frontend si el navegador no puede resolverlo.

Recordar:

```text
Flutter Web corre finalmente en el navegador
```

por lo que la URL debe ser accesible desde el navegador del host.

---

# 53. CORS

Mantener como origin esperado de desarrollo:

```text
http://localhost:4200
```

El backend actual ya acepta este origin.

No modificar backend salvo que una prueba real demuestre incompatibilidad.

---

# 54. Hot reload / ciclo de desarrollo

Si resulta razonable con la imagen y filesystem utilizado, Compose podrá montar el repositorio como volumen para desarrollo.

Pero el criterio obligatorio no es hot reload.

El criterio obligatorio es:

```text
clon limpio
+
Docker
+
un comando
=
Web funcional
```

No complicar el bloque sólo para obtener hot reload perfecto.

---

# 55. Cache

Se pueden utilizar volúmenes Docker para:

```text
pub cache
.dart_tool
build artifacts
```

si mejoran significativamente el arranque.

No depender de rutas específicas Windows.

La configuración debe funcionar independientemente del workaround:

```text
C:\w
C:\f
```

utilizado anteriormente.

---

# 56. Tests de containerización

Validar desde un entorno limpio:

```text
docker compose build
docker compose up
```

y comprobar:

```text
HTTP 200 localhost:4200
Flutter bootstrap
Login renderizado
API_BASE_URL correcto
CORS correcto cuando backend está disponible
```

---

# 57. Integración opcional con backend

No unificar obligatoriamente ambos repositorios en un único Compose.

Cada repositorio puede seguir siendo autónomo:

```text
backend repo
docker compose up --build

frontend repo
docker compose up --build
```

Resultado:

```text
Backend → localhost:3000
Frontend → localhost:4200
```

Esto mantiene separación limpia entre repositorios.

---

# 58. CI de containerización

Agregar al CI como mínimo una comprobación:

```text
docker build
```

si existe Dockerfile.

Opcionalmente:

```text
docker compose config
```

para validar sintaxis del Compose.

No es obligatorio arrancar navegador E2E dentro del CI de este bloque si no aporta valor suficiente.

---

# 59. Documentación

Actualizar README con una sección:

```text
Inicio con Docker
```

que permita ejecutar:

```powershell
git clone ...
cd saas-platform-client
docker compose up --build
```

y acceder:

```text
http://localhost:4200
```

Documentar también cómo cambiar:

```text
API_BASE_URL
```

---

# 60. Definition of Done — Bloque 3

Debe cumplirse:

```text
Dockerfile/dev image reproducible
Compose válido
clon limpio funciona
un solo comando levanta Web
host no necesita Flutter
localhost:4200 responde
API_BASE_URL configurable
backend localhost:3000 interoperable
README actualizado
flutter analyze PASS
flutter test PASS
flutter build web PASS
docker build PASS
GitHub Actions PASS
```

---

# 61. Commit 3

Mensaje:

```text
chore: containerize Flutter web development
```

---

# 62. Auditoría entre bloques

Después de cada commit debe detenerse el desarrollo.

Secuencia:

```text
Codex implementa Bloque N
        ↓
Codex ejecuta pruebas
        ↓
Commit N
        ↓
Push dev
        ↓
GitHub Actions
        ↓
Auditoría Carlos + ChatGPT
        ↓
APPROVED
        ↓
Bloque N+1
```

No comenzar automáticamente el siguiente bloque antes de auditar el commit anterior.

---

# 63. Política de rama durante el trabajo

Los tres commits vivirán inicialmente en:

```text
dev
```

`main` continuará estable hasta terminar los tres bloques.

No hacer merge parcial a `main`.

---

# 64. Integración final

Una vez aprobados:

```text
Commit 1
Commit 2
Commit 3
```

Carlos realizará manualmente:

```text
PR dev → main
```

Se verificará:

```text
required checks PASS
diff esperado
3 commits auditados
sin cambios adicionales
```

y después se realizará el merge.

---

# 65. Estado esperado antes de Campaigns

Una vez completado este plan:

```text
Flutter Foundation
        CLOSED

Platform API Client
        COMPLETE FOR CURRENT BACKEND

Frontend Web Runtime
        DOCKERIZED
```

Entonces André podrá comenzar Campaigns.

---

# 66. Contrato de trabajo para André

A partir de ese momento:

## No tocar

```text
lib/core/network/**
lib/core/storage/**
lib/core/errors/**
Auth lifecycle
tenant lifecycle
routing transversal
Platform API clients
base DTOs
Docker runtime base
CI transversal
```

## Sí trabajar

```text
lib/features/campaigns/**
feature repositories/adapters
providers
state
screens
widgets
feature-specific tests
```

---

# 67. Flujo esperado para Campaigns

André deberá implementar:

```text
Campaigns Screen
        ↓
Campaigns State / Provider
        ↓
Campaigns Feature Repository
        ↓
Campaigns Platform API Client
        ↓
ApiClient
        ↓
NestJS
        ↓
PostgreSQL
```

No deberá escribir:

```text
Dio.get(...)
'/api/v1/campaigns'
json['data']
Authorization header
tenantId manual
```

dentro de la feature.

---

# 68. Criterio final del plan

El éxito de estos tres bloques no se mide por cantidad de código.

Se mide por que, al entregarle el repositorio a André, pueda concentrarse exclusivamente en comportamiento y UI de features sobre una plataforma ya resuelta.

Resultado deseado:

```text
Infrastructure decisions
        CLOSED

Backend integration surface
        CLOSED

Local Web runtime
        CLOSED

Feature development
        OPEN
```
