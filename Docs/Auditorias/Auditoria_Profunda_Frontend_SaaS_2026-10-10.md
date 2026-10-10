# Auditoría profunda — SaaS Platform Client (Flutter)

**Proyecto:** Sistema de Prospección Automatizada y Gestión de Campañas de Marketing  
**Repositorio auditado:** `CarlosAM03/saas-platform-client`  
**Rama principal de auditoría:** `dev`  
**HEAD auditado:** `90e38656e1aafd3c81e8d639e6b17f973f81aff8`  
**Fecha del corte:** 10 de octubre de 2026  
**Backend de compatibilidad:** `CarlosAM03/saas-platform-backend` — `main` @ `ab53272f531d15e6c4dcc9df8c1d6dca8601e87a`

---

## 1. Propósito y alcance

Esta auditoría revisa el estado real de la rama `dev` del cliente Flutter después de reconciliar el trabajo que había quedado dividido entre `dev` y `main`.

El objetivo es determinar:

1. qué existe realmente en el código;
2. qué parte puede conservarse;
3. qué parte está fuera de contrato o de governance;
4. qué regresiones se introdujeron en Flutter Foundation;
5. qué tan compatible es el cliente con el backend NestJS actual;
6. qué falta para poder llamar al cliente una beta funcional del primer avance;
7. qué debe validar posteriormente Codex mediante ejecución local, análisis estático, tests y pruebas reales contra el backend.

Esta revisión es principalmente estática. No declara `flutter analyze`, `flutter test`, build ni flujos E2E como exitosos. Esas comprobaciones forman parte del handoff de ejecución local incluido al final.

---

# 2. Snapshot real del repositorio

## 2.1 Ramas Flutter

Al momento de la auditoría:

| Rama | HEAD | Estado |
|---|---|---|
| `dev` | `90e3865` | rama de integración unificada |
| `main` | `a663003` | beta publicada accidentalmente por André |
| `fix/f5-foundation` | `dd9e95b` | baseline histórico de Flutter Foundation |

`dev` contiene actualmente todo lo que existe en `main` más el trabajo visual que estaba previamente en `dev`.

Por tanto, **`dev @ 90e3865` es el mejor candidato actual para continuar el hardening**.

No se recomienda promoverlo todavía a `main`.

## 2.2 Backend

El backend sí tuvo cambios después del corte anterior.

`main` y `dev` se encuentran en:

```text
ab53272f531d15e6c4dcc9df8c1d6dca8601e87a
```

Los nuevos cambios se concentran en:

- entorno reproducible con Docker Compose;
- PostgreSQL local;
- `seed_dev`;
- shared-dev;
- CI;
- calidad;
- build de Docker.

No se detectó una redefinición importante de los CRUD que Flutter debe consumir.

El backend actual ofrece funcionalmente:

- Auth;
- Tenants;
- Users;
- Campaigns;
- Prospects persistidos;
- consulta read-only de Prospecting Jobs;
- PostgreSQL;
- Swagger;
- health/readiness.

La integración con Prospector Service/Engine sigue deliberadamente pendiente.

---

# 3. Governance documental

El propio repositorio define una jerarquía explícita en `Docs/CONTRIBUTING.md`.

Orden de autoridad:

1. ADR-004 del backend.
2. `platform-api.v1.yaml`.
3. `FormularioDecisionesFase5.md`.
4. ADR-005 Flutter Foundation.
5. `FEATURE-DEVELOPMENT.md`.

Los documentos conceptuales, históricos y UI/UX aportan contexto y diseño, pero no pueden sustituir el contrato ni las decisiones arquitectónicas.

Esto permite clasificar los hallazgos con bastante precisión.

## 3.1 Ownership

La documentación establece:

### Protegido por Carlos

- `lib/app`;
- `lib/core`;
- `lib/routes`;
- AuthState;
- networking;
- ApiClient;
- storage;
- DTOs transversales;
- decisiones de sesión y arquitectura.

### Responsabilidad de André

- features;
- pantallas;
- repositories por feature;
- providers;
- state por feature;
- widgets;
- tests de features.

André modificó `AuthState` y `app_router.dart`.

El cambio de routing para conectar el nuevo Dashboard es pequeño y comprensible, pero formalmente requiere revisión.

El cambio de Auth sí alteró comportamiento transversal y produjo una regresión confirmada estáticamente.

---

# 4. Arquitectura esperada vs arquitectura real

La arquitectura normativa por feature es:

```text
Screen / Widget
        ↓
Provider / State
        ↓
Repository interface
        ↓
API Repository
        ↓
ApiClient
        ↓
SaaS Backend NestJS
```

Estado real:

```text
Auth UI
   ↓
AuthController
   ↓
AuthRepository
   ↓
ApiClient
   ↓
NestJS
```

Auth sí utiliza la arquitectura real.

Las demás áreas se encuentran aproximadamente así:

```text
Dashboard UI
   ↓
FutureProvider
   ↓
hard-coded mocks
```

y:

```text
CampaignsPage
ProspectsPage
AdminPage
GeneratePage
   ↓
placeholder
```

No existen todavía capas funcionales:

```text
CampaignsApiRepository
ProspectsApiRepository
UsersApiRepository
TenantsApiRepository
JobsApiRepository
```

Tampoco existen los providers/state completos de esas features.

## Dictamen

**El cliente no está conectado funcionalmente al backend salvo por Auth Foundation.**

La UI nueva de André no debe confundirse con integración SaaS.

---

# 5. Qué trabajo de André sí debe conservarse

La auditoría no recomienda desechar el avance visual.

Hay elementos útiles que deben reutilizarse después del hardening.

## 5.1 Dashboard responsive

`lib/features/dashboard/presentation/dashboard_page.dart`

Aspectos positivos:

- widget separado de routing;
- Riverpod;
- layout responsive;
- 1/2/3 columnas;
- estados loading/empty/error;
- reutilización de `AsyncStateView`;
- navegación desacoplada mediante callback.

Es una buena base de presentación.

## 5.2 CampaignCard

`lib/features/campaigns/widgets/campaign_card.dart`

La card tiene una estructura visual útil:

- nombre;
- status badge;
- información secundaria;
- CTA;
- layout reutilizable.

Puede conservarse el diseño, pero su modelo de entrada debe cambiar.

## 5.3 CampaignStatusBadge

`campaign_status_badge.dart`

La idea es correcta:

- color;
- texto;
- icono;
- no depende exclusivamente del color para comunicar estado.

Puede mantenerse tras alinear las etiquetas y mover tokens de diseño.

## 5.4 AsyncStateView

La idea transversal de manejar:

- loading;
- empty;
- error;
- success;

es compatible con las reglas del repositorio.

Deberá evolucionar a mensajes y acciones específicas, pero no hace falta desecharlo.

## 5.5 ApiClient y AuthRepository

La Foundation original sigue teniendo piezas valiosas:

- Dio centralizado;
- Bearer automático;
- manejo global de 401;
- `flutter_secure_storage`;
- `--dart-define=API_BASE_URL`;
- AuthRepository;
- restauración mediante `/auth/me`.

El problema es una regresión posterior, no que la Foundation original sea incorrecta.

---

# 6. Hallazgos críticos de Flutter Foundation

## FND-01 — Logout roto

**Severidad:** P0 / bloqueante para beta.

En `AuthController.logout()` el código original que:

- llama al backend;
- tolera error de red;
- limpia JWT;
- pasa a `unauthenticated`;

fue comentado.

La implementación actual únicamente evita llamar al backend para `DevUser` y llama `/logout` para un usuario real.

No ejecuta:

```text
clearToken()
AuthStatus.unauthenticated
```

Consecuencia:

- el usuario puede pulsar cerrar sesión y seguir autenticado;
- el JWT sigue persistido;
- la restauración puede volver a levantar la sesión.

Además, el test existente:

```text
logout clears local session even if backend fails
```

exige exactamente el comportamiento que el código actual ya no implementa.

### Acción

Restaurar el patrón:

```text
try backend logout
catch ApiException
finally:
  clear local JWT
  AuthState = unauthenticated
```

El logout del backend es stateless; la terminación local es indispensable.

---

## FND-02 — `sessionExpired` crea un flujo sin salida

**Severidad:** P1.

Router:

```text
AuthStatus.sessionExpired
→ /session-expired
```

La pantalla ofrece:

```text
context.go('/login')
```

pero el estado sigue siendo `sessionExpired`.

El redirect vuelve a enviar al usuario a:

```text
/session-expired
```

### Acción

Agregar transición explícita de sesión expirada a estado no autenticado antes de volver a Login.

Debe probarse el flujo completo, no únicamente la función de redirect.

---

## FND-03 — DevUser está acoplado al AuthController productivo

**Severidad:** P1.

Existe un usuario:

```text
frontend / frontend
```

con un token ficticio `dev-ui-token`, activado en debug.

Aunque está condicionado por `kDebugMode`, el bypass se encuentra dentro del controlador real de autenticación.

Esto mezcla:

```text
Auth real
+
Auth mock
```

en la misma implementación transversal.

### Acción

Para la beta integrada, remover este bypass del flujo normal.

Si se necesita desarrollo UI aislado:

- usar repository sustituible;
- Provider override;
- fixture/test harness;
- flavor de desarrollo explícito.

No contaminar el AuthController principal.

---

## FND-04 — Self-register público contradice governance

**Severidad:** P1.

Se añadieron:

- `register_dialog.dart`;
- CTA “Regístrate” en Login.

Sin embargo:

- `CONTRIBUTING.md`: prohíbe self-register;
- `FEATURE-DEVELOPMENT.md`: prohíbe self-register;
- ADR-005: fuera de alcance;
- backend: no tiene endpoint de self-registration;
- tenant onboarding no está definido.

### Acción

Retirar el registro público del flujo de beta.

No convertirlo en endpoint ni inventar comportamiento desde Flutter.

---

## FND-05 — Login y errores todavía son demasiado genéricos

**Severidad:** P2.

Existe `ErrorMapper`, pero Login sólo muestra:

```text
No se pudo iniciar sesión.
```

Se pierden distinciones importantes:

- 401;
- backend caído;
- error de red;
- validación;
- 429.

No es un blocker arquitectónico, pero la beta debe presentar estados coherentes.

---

# 7. Hallazgos de networking y parsing

## NET-01 — Sólo Auth consume el ApiClient

**Severidad:** P0 para la beta funcional.

Los únicos endpoints de negocio realmente consumidos son de autenticación.

No existen API repositories para:

- tenants;
- users;
- campaigns;
- prospects;
- jobs.

Por tanto, ninguna pantalla de negocio opera contra PostgreSQL.

---

## NET-02 — `unwrapData()` sólo sirve correctamente para objetos Map

**Severidad:** P1.

El helper actual convierte `data` a:

```dart
Map<String, dynamic>
```

Esto funciona para `AuthContext`.

Pero varios endpoints regresan:

```text
data: [...]
```

y los paginados regresan:

```text
data: [...]
meta:
  page
  limit
  total
  totalPages
```

Ejemplos:

- GET `/tenants`;
- GET `/campaigns`;
- GET `/prospects`;
- GET `/users`;
- GET `/prospecting-jobs`.

### Acción

Implementar parsing de wrappers adecuado:

```text
Object response
→ success
→ data object/list
→ optional meta
```

No intentar reutilizar `unwrapData()` actual para listas.

---

## NET-03 — ApiException define `code` pero ApiClient no lo popula

**Severidad:** P2.

El backend usa respuestas:

```json
{
  "success": false,
  "error": {
    "code": "...",
    "message": "...",
    "details": {...},
    "timestamp": "..."
  }
}
```

`ApiClient` extrae `message`, pero no asigna correctamente:

- `code`;
- `error.details`;

a los campos correspondientes de `ApiException`.

Actualmente `details` recibe el body completo.

### Impacto

Dificulta manejar de forma precisa:

```text
PROSPECTOR_INTEGRATION_PENDING
```

y otros errores contractuales.

### Acción

Normalizar el parser transversal de error antes de construir features.

---

## NET-04 — `delete()` no soporta query parameters

**Severidad:** P2/P1 para Campaigns.

Campaigns soporta:

```http
DELETE /campaigns/:id
DELETE /campaigns/:id?permanent=true
```

`ApiClient.delete()` sólo recibe path.

André no debería cambiar `lib/core` unilateralmente.

### Acción

Durante hardening transversal, ampliar de forma controlada:

```dart
delete(path, {queryParameters})
```

o definir una abstracción equivalente.

---

# 8. Compatibilidad local con backend actual

## INT-01 — El backend local ahora es reproducible

El backend `main @ ab53272` puede iniciarse con:

```powershell
docker compose up --build
```

Expone:

```text
API       http://localhost:3000/api/v1
Swagger   http://localhost:3000/api/docs
Ready     http://localhost:3000/api/v1/health/ready
```

Incluye dataset demo reproducible con:

- 2 tenants;
- ADMIN;
- OWNER;
- MEMBER;
- campañas;
- prospectos;
- jobs históricos.

Esto es ideal para probar el frontend real.

---

## INT-02 — Posible CORS inmediato en Flutter Web

**Severidad:** P1 para pruebas locales.

Backend Compose permite:

```text
http://localhost:4200
http://localhost:3000
```

El README Flutter indica:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

pero no fija el puerto web.

Flutter Web puede usar un puerto dinámico.

Ese origin no estaría incluido en CORS.

### Comando recomendado para prueba integrada

```powershell
flutter run -d chrome --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000
```

Este punto debe comprobarse localmente.

---

## INT-03 — Android requiere configuración adicional

El permiso `INTERNET` aparece en manifest debug/profile, pero no en:

```text
android/app/src/main/AndroidManifest.xml
```

Debe revisarse antes de considerar Android release.

Además, para emulador:

```text
localhost
```

no representa al host.

Habitualmente será necesario usar la dirección del host del emulador y resolver HTTP cleartext o usar HTTPS.

Para el primer hardening puede priorizarse Web si esa es la plataforma de presentación, pero no debe declararse Android funcional sin probarlo.

---

# 9. Campaigns

## Estado actual

Existe:

- modelo UI;
- CampaignCard;
- CampaignStatusBadge;
- dashboard mock.

No existe:

- CampaignsRepository;
- ApiCampaignsRepository;
- parsing;
- provider real;
- state;
- pantalla list;
- detalle;
- create;
- edit;
- archive;
- search;
- pagination.

`CampaignsPage` sigue siendo:

```text
Campañas — placeholder Fase 5
```

## Backend disponible

```http
GET    /api/v1/campaigns
POST   /api/v1/campaigns
GET    /api/v1/campaigns/:id
PATCH  /api/v1/campaigns/:id
DELETE /api/v1/campaigns/:id
GET    /api/v1/campaigns/:id/prospects
```

Por tanto no existe un bloqueo backend.

## CMP-01 — Modelo incompleto respecto al backend real

El backend retorna:

```text
id
name
description
status
createdBy
createdAt
updatedAt
```

El modelo de André omite `createdBy`.

OpenAPI no lo marca como required en la lista, aunque el DTO real del backend sí lo emite.

No necesariamente bloquea la UI, pero el modelo no representa completamente la respuesta desplegada.

## CMP-02 — No existe serialización de Campaign

`Campaign` es una clase UI manual.

No existe:

```text
fromJson
toJson
DTO Request
```

No puede conectarse al backend en su forma actual sin una capa adicional.

## CMP-03 — Dependencia invertida entre Campaign y Dashboard

Actualmente:

```text
CampaignCard
    ↓ importa
dashboard_mock_data.dart
```

y:

```text
dashboard_mock_data.dart
    ↓ importa
Campaign
```

Esto genera acoplamiento circular entre features.

Una CampaignCard no debería depender de un mock del Dashboard.

### Acción

`CampaignCard` debe depender de:

- Campaign;
- o un CampaignCardViewModel neutral.

Dashboard puede componer estadísticas opcionales por encima.

---

# 10. Dashboard

## Lo conservable

Visualmente el Dashboard representa un avance real:

- responsive;
- cards;
- loading;
- empty;
- error.

## Lo no aceptable para beta

Los datos son completamente ficticios.

Ejemplos:

```text
Campaña Verano 2026
1,240 prospectos
380 contactados
12.4% conversión
```

No provienen de NestJS.

La propia documentación de André reconoce que Contactados y Conversión no existen en OpenAPI.

## DSH-01 — Estadísticas inventadas

**Severidad:** P0 si se presenta como datos reales.

No se debe presentar:

- Contactados;
- Conversión;

como información funcional.

### Decisión recomendada

Para la primera beta:

- conservar la card;
- consumir campañas reales;
- mostrar nombre;
- estado;
- descripción;
- fecha de actualización;
- quizá cantidad de prospectos sólo si se obtiene contractualmente.

`GET /campaigns/:id/prospects` expone paginación y `meta.total`, por lo que un conteo podría obtenerse, aunque hacerlo para cada campaña produciría múltiples requests.

No inventar un aggregate endpoint únicamente para sostener un mock visual.

## DSH-02 — El comentario “DTO real cuando exista” está obsoleto

El DTO real de Campaign ya existe.

También existe:

```http
GET /campaigns/:id
```

El comentario de que el backend no tiene detalle es incorrecto.

Lo que falta es la implementación Flutter de la ruta de detalle.

## DSH-03 — Diseño incompleto respecto a Lineamientos UI/UX

Lineamientos plantea:

- saludo;
- tenant/organización;
- resumen;
- campañas recientes.

La implementación actual sólo contiene campañas recientes.

No es necesario implementar todas las métricas ficticias para cumplir diseño. Se puede completar el layout con información contractual real.

---

# 11. Prospects

Estado:

```text
ProspectsPage = placeholder
ProspectsMockRepository = []
```

No hay integración.

Backend disponible:

```http
GET   /api/v1/prospects
GET   /api/v1/prospects/:id
PATCH /api/v1/prospects/:id
GET   /api/v1/campaigns/:id/prospects
```

La beta debe implementar:

- list;
- search;
- pagination;
- detail;
- edit;
- filter/status cuando corresponda;
- vista por campaña;
- loading/empty/error/success.

No debe implementar:

- scraping;
- creación manual;
- deduplicación;
- persistencia de resultados temporales.

---

# 12. Users

No existe feature `users/` en el árbol Flutter actual.

Backend disponible:

```http
GET    /api/v1/users
POST   /api/v1/users
GET    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id
```

Permisos reales actuales:

```text
GET       ADMIN OWNER MEMBER
POST      ADMIN OWNER
PATCH     ADMIN OWNER
DELETE    ADMIN
```

La UI puede ocultar acciones conservadoramente, pero debe tratar 403 como autoridad final.

La beta requiere esta feature para poder llamar funcional a Admin.

---

# 13. Tenants

No existe feature funcional de tenants.

El único flujo actual usa `AuthContext.tenants`.

Backend disponible:

```http
GET  /api/v1/tenants
POST /api/v1/tenants
GET  /api/v1/tenants/:id
```

POST es ADMIN-only.

## TNT-01 — ADMIN global puede quedar sin opciones visibles

Un ADMIN puede autenticarse con:

```text
currentTenantId = null
```

El backend puede listar todos los tenants mediante:

```http
GET /tenants
```

Pero `SelectTenantPage` sólo muestra:

```text
AuthContext.tenants
```

Un ADMIN global sin memberships puede recibir una lista vacía en AuthContext aunque el backend le permita operar sobre tenants.

### Acción

Implementar TenantsRepository y usar discovery real cuando corresponda.

---

# 14. Profile

La pantalla actual sólo muestra:

- nombre;
- email;
- platformRole.

El Plan de Trabajo exige:

```text
Profile
└── Tenant / Session
```

Falta:

- tenant actual;
- organización;
- cambio de tenant;
- logout funcional;
- estado de sesión.

La pantalla puede conservarse y extenderse.

---

# 15. Prospecting Jobs y navegación

Este es un punto especialmente importante.

El backend actual **NO permite una prospección funcional**.

Inicio/cancelación/persist/export devuelven 503 tras las validaciones correspondientes.

Sólo están operativos:

```http
GET /prospecting-jobs
GET /prospecting-jobs/:id
```

Sin embargo el AppShell presenta:

```text
Generar
```

y navega a:

```text
/generate
```

La pantalla dice:

```text
Generar prospectos — placeholder Fase 5
```

Esto contradice el alcance del primer avance definido posteriormente:

```text
Jobs read-only
```

### Acción recomendada

Para la beta:

- no presentar “Generar” como funcional;
- reemplazar por “Jobs” / “Historial” / equivalente aprobado;
- implementar list/detail read-only;
- o retirar temporalmente la entrada si no se terminará.

No simular Prospector con mocks.

---

# 16. Roles y navegación

## RBA-01 — Admin siempre aparece en el drawer

La entrada “Administración” aparece para cualquier usuario autenticado.

Eso no crea una vulnerabilidad por sí mismo porque el backend autoriza, pero la UI debería ser conservadora y coherente con rol.

## RBA-02 — Dashboard no está incluido en `_requiresTenant`

El flujo esperado en Plan de Trabajo es:

```text
Login
→ Tenant Context
→ Dashboard
```

Pero `_requiresTenant()` sólo incluye:

```text
/campaigns
/prospects
/generate
```

Por tanto un usuario autenticado sin tenant podría entrar directamente a `/dashboard` mediante ciertos flujos/deep links.

Mientras Dashboard usa mocks no se nota.

Cuando Dashboard consuma Campaigns será tenant-aware.

Debe decidirse:

- Dashboard exige tenant;
- o existe un dashboard global ADMIN diferente.

No inventar ambas semánticas en un mismo screen.

## RBA-03 — `/admin` mezcla potencialmente scopes

Tenants puede consultarse sin tenant seleccionado.

Users requiere tenant seleccionado.

Una sola futura pantalla `/admin` deberá distinguir:

```text
administración global
vs
administración del tenant actual
```

---

# 17. Diseño UI/UX

## Alineaciones positivas

El nuevo trabajo sí respeta varios lineamientos:

- cards;
- status badge;
- responsive layout;
- Material;
- estados async;
- estructura visual reusable;
- CTA hacia detalles.

## Desalineaciones

### UI-01

El Dashboard no incluye:

- identidad del usuario;
- tenant visible;
- bloque resumen.

### UI-02

`CampaignStatusBadge` muestra:

```text
Completada
```

mientras `dashboard-campaign-cards.md` documenta la etiqueta visual:

```text
Finalizada
```

No es un problema de contrato porque el valor API seguirá siendo `COMPLETADA`, pero hay drift entre diseño documentado y widget.

### UI-03

Los colores continúan hardcodeados en widgets.

Lineamientos recomienda evolucionar a Design System.

No es bloqueante para la primera beta, pero debe evitarse proliferar colores repetidos durante las próximas features.

### UI-04

Campaigns real, detalle, crear y editar aún no existen, aunque son Prioridad 1/2 del documento visual y P0 del Plan de Trabajo funcional.

---

# 18. Higiene del repositorio

## REP-01 — Archivos generados versionados

Existen archivos generados por Flutter en iOS/macOS/Linux.

Algunos contienen rutas absolutas del entorno Windows donde fueron generados.

Ejemplos:

```text
ios/Flutter/Generated.xcconfig
ios/Flutter/flutter_export_environment.sh
macos/Flutter/ephemeral/...
```

Deben revisarse y eliminarse del versionado cuando Flutter los regenere.

Actualizar `.gitignore`.

## REP-02 — README contiene referencias desactualizadas

README todavía referencia:

```text
Docs/LineamientosUI-UX.md
```

pero tras el merge el archivo vive en:

```text
Docs/DocsTeam/Documentacion UIUX/LineamientosUI-UX.md
```

También el documento `dashboard-campaign-cards.md` tiene un enlace relativo que debe verificarse después del movimiento.

## REP-03 — README describe correctamente que las features siguen siendo placeholders

Esto es importante:

el propio README actual contradice la etiqueta informal “Beta completa”.

El README dice explícitamente que:

- Dashboard;
- Admin;
- Campaigns;
- Prospects;
- ProspectingJobs;

no tienen CRUD/integración funcional.

La documentación técnica, en ese punto, es más precisa que el mensaje del commit.

---

# 19. Tests

El repositorio conserva tests de Foundation.

No existen tests de feature para el trabajo nuevo.

La suite existente cubre:

- token absent;
- restore;
- 401;
- backend unavailable;
- login;
- select tenant;
- logout;
- routing;
- Bearer;
- 403.

Sin embargo el código actual de logout contradice explícitamente uno de esos tests.

## Requisito para hardening

Después de corregir Foundation:

```text
flutter analyze
flutter test
```

deben pasar antes de continuar.

Después, cada feature debe probar:

- DTO parsing;
- repository;
- query params;
- pagination;
- provider/state;
- success;
- empty;
- error;
- 401;
- 403 relevante;
- 404;
- 409 cuando aplique.

---

# 20. CI

## Backend

El backend ya tiene CI con:

- npm ci;
- Prisma generate;
- lint;
- format check;
- build;
- unit tests;
- E2E;
- PostgreSQL integration;
- npm audit;
- Docker build.

`main` del backend aparece protegido.

## Frontend

En el árbol Flutter auditado **no existe `.github/workflows`**.

Por tanto el frontend todavía no tiene CI equivalente en el repositorio remoto auditado.

Antes de promover la beta a `main`, se recomienda agregar CI que ejecute como mínimo:

```text
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build web
```

La versión de Flutter debe fijarse coherentemente con el proyecto.

Después de validarlo, proteger `main`.

---

# 21. Contrato Flutter ↔ Backend

Un punto muy positivo:

El archivo:

```text
Docs/Contracts/platform-api.v1.yaml
```

de Flutter `dev` y backend `main` tiene el mismo blob SHA:

```text
6214ad7bc633ddc2722bc447776ea21f49e043ec
```

Por tanto, el contrato versionado está sincronizado.

La incompatibilidad actual no viene de dos OpenAPI distintos.

Viene de que Flutter todavía no implementa sus endpoints de negocio.

---

# 22. Matriz de compatibilidad actual

| Área | Backend | Flutter | Estado |
|---|---|---|---|
| Login | Real | Real | requiere hardening |
| `/auth/me` | Real | Real | conservar |
| Select tenant | Real | Parcial | ADMIN incompleto |
| Logout | Real/stateless | Regresionado | bloquear beta |
| Tenants list | Real | No implementado | pendiente |
| Tenant create | Real ADMIN | No implementado | pendiente |
| Users CRUD | Real | No implementado | pendiente |
| Campaigns CRUD | Real | UI mock/placeholder | pendiente |
| Prospects read/edit | Real | placeholder | pendiente |
| Dashboard | Backend permite datos base | ficticio | rehacer data source |
| Jobs list/detail | Real | placeholder | pendiente |
| Job create | 503 pending | UI dice Generar | desalineado |
| Prospector Service | pendiente | no debe integrar | correcto no integrarlo |

---

# 23. Qué se debe conservar, cambiar y desechar

## Conservar

- ApiClient como base.
- AuthRepository.
- flutter_secure_storage.
- Riverpod.
- go_router.
- estructura feature-first.
- AsyncStateView como concepto.
- DashboardPage visual.
- CampaignCard visual.
- CampaignStatusBadge.
- responsive breakpoints como punto de partida.
- OpenAPI sincronizado.
- documentación de governance.
- Plan de Trabajo como backlog funcional.

## Cambiar / hardenizar

- logout;
- session expired recovery;
- error parsing;
- generic response/list parsing;
- tenant discovery;
- rutas tenant-aware;
- AppShell visibility;
- Campaign model/DTO;
- dependency direction CampaignCard/Dashboard;
- dashboard real;
- profile;
- Android networking;
- docs paths;
- generated files;
- CORS local workflow;
- frontend CI.

## Desechar del runtime funcional

- `DevUser` incrustado en AuthController;
- self-register público;
- CampaignStats ficticias como datos de beta;
- Contactados ficticios;
- Conversión ficticia;
- mocks como runtime source de una feature marcada funcional;
- navegación “Generar” como si Prospector estuviera disponible.

Los mocks pueden conservarse exclusivamente como fixtures/tests o prototipos explícitos.

---

# 24. Backlog real para André

## Bloque 0 — Foundation hardening

Este bloque debe realizarse primero, preferentemente coordinado/revisado por Carlos porque toca zonas protegidas.

1. restaurar logout;
2. resolver session-expired;
3. retirar DevUser del AuthController productivo;
4. retirar self-register;
5. corregir parsing transversal de errores;
6. definir parsing de arrays/pagination;
7. resolver delete query params;
8. fijar CORS/puerto local para integración;
9. ejecutar Foundation tests;
10. agregar CI Flutter.

## Bloque 1 — Campaigns

Implementar:

```text
data/
models/
providers/
state/
screens/
widgets/
```

Con:

- list;
- search;
- pagination;
- detail;
- create;
- edit;
- status update;
- archive;
- permanent delete sólo ADMIN;
- campaign prospects.

Reutilizar CampaignCard/Badge.

## Bloque 2 — Prospects

- list;
- search;
- pagination;
- detail;
- edit;
- campaign-specific list.

No crear prospectos manualmente.

## Bloque 3 — Users

- list;
- search;
- detail;
- create OWNER/ADMIN;
- edit OWNER/ADMIN;
- deactivate ADMIN.

## Bloque 4 — Tenants

- list;
- detail;
- create ADMIN;
- selección real;
- cambio de tenant;
- soporte ADMIN global.

## Bloque 5 — Profile/Admin

Profile:

- user;
- tenant;
- role;
- change tenant;
- logout.

Admin:

- Users;
- Tenants;
- role-aware actions.

## Bloque 6 — Dashboard real

Reutilizar UI existente, pero:

```text
Mock Provider
→ Campaigns API Provider
```

Eliminar métricas no contractuales.

## Bloque 7 — Jobs read-only

Implementar únicamente:

```http
GET /prospecting-jobs
GET /prospecting-jobs/:id
```

No fake create/cancel/persist/export.

---

# 25. Definition of Done propuesta para “Beta Primer Avance”

No usar la palabra **beta funcional** hasta que se cumpla todo lo siguiente.

## Foundation

- Auth real.
- logout real.
- restore real.
- 401 coherente.
- 403 no destruye sesión.
- tenant selection funcional.
- no DevUser en flujo normal.
- no self-register falso.

## Features mínimas

- Campaigns real.
- Prospects real.
- Users real.
- Tenants real.
- Profile funcional.
- Admin funcional.
- Dashboard sin datos inventados.
- Jobs read-only o explícitamente omitido.

## Calidad

```text
flutter analyze → PASS
flutter test → PASS
flutter build web → PASS
```

## Integración

Backend:

```text
docker compose up --build
```

Frontend:

```powershell
flutter run -d chrome --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000
```

Probar:

- ADMIN;
- OWNER;
- MEMBER;
- al menos dos tenants;
- aislamiento;
- 401;
- 403;
- 404;
- 409;
- backend down;
- listas vacías.

## Git

- CI Flutter verde.
- PR `dev` → `main`.
- revisión Carlos.
- `main` protegida.
- no push directo de feature work.

---

# 26. Plan de pruebas para Codex local

Codex debe trabajar sobre el checkout local ya reconciliado, sin asumir que el código funciona.

## 26.1 Registrar baseline

Ejecutar y guardar:

```powershell
git status
git branch --show-current
git log -10 --oneline --decorate
git rev-parse HEAD
```

Confirmar que HEAD corresponde al merge auditado o documentar cualquier diferencia local.

## 26.2 Validación Flutter limpia

Ejecutar:

```powershell
flutter --version
dart --version
flutter doctor -v
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build web
```

No corregir tests para hacerlos pasar sin entender el fallo.

## 26.3 Backend

En otro checkout/terminal:

```powershell
docker compose up --build
docker compose ps
```

Verificar:

```text
GET /api/v1/health/ready → 200
```

## 26.4 Flutter Web integrado

Ejecutar con origin permitido:

```powershell
flutter run -d chrome --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000
```

Si se usa Edge mediante alias de Chrome, documentarlo.

## 26.5 Flujos manuales obligatorios

### Auth

- login correcto;
- login incorrecto;
- restore tras refresh;
- logout;
- JWT expirado/401;
- backend apagado;
- reintento.

### Tenant

- OWNER single tenant;
- usuario multi-tenant;
- ADMIN;
- select tenant;
- cambio tenant;
- tenant isolation.

### Features

Por cada feature implementada:

- success;
- empty;
- loading;
- API error;
- 403;
- not found;
- conflict si aplica;
- pagination;
- search.

## 26.6 Prueba específica de regresión de logout

Debe comprobarse:

```text
Login
→ JWT almacenado
→ Logout
→ JWT eliminado
→ AuthState unauthenticated
→ Login visible
→ refresh no restaura sesión
```

También repetir con backend detenido durante logout.

## 26.7 Evidencia final que Codex debe producir

Un reporte con:

```text
SHA auditado
flutter analyze
flutter test
flutter build web
tests fallidos iniciales
tests finales
backend readiness
flujos manuales ejecutados
requests HTTP observadas
errores encontrados
cambios propuestos
cambios aplicados
pendientes
```

No declarar una feature funcional sólo porque renderiza una pantalla.

---

# 27. Dictamen final

El merge actual de `dev` recupera correctamente el trabajo visual que estaba separado entre ramas y es una base mejor que cualquiera de los dos estados anteriores.

Sin embargo:

```text
NO ES TODAVÍA UNA BETA FUNCIONAL DEL PRIMER AVANCE
```

El estado real es:

```text
Flutter Foundation
    +
Dashboard/UI prototype
    +
Campaign cards
    +
mocks
    +
placeholders
```

con una regresión importante en Auth.

El backend ya está suficientemente preparado para avanzar. No existe un bloqueo técnico de Ángel que obligue a esperar para desarrollar:

- Campaigns;
- Prospects;
- Users;
- Tenants;
- Profile/Admin;
- Jobs read-only.

La prioridad inmediata debe ser:

```text
1. Hardening Foundation
2. Pruebas locales
3. Campaigns real
4. Prospects real
5. Users real
6. Tenants real
7. Profile/Admin
8. Dashboard real
9. Jobs read-only
10. CI + revisión + merge a main
```

El trabajo visual de André **sí es reutilizable**, pero debe tratarse como prototipo de presentación hasta sustituir los mocks por repositories reales y cerrar los flujos funcionales definidos en el Plan de Trabajo.

**Recomendación de release:** NO MERGE A `main` como beta antes del hardening y de la ejecución del plan de pruebas local.
