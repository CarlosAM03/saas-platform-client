# Plan de Trabajo — Primer Avance Funcional del Cliente Flutter

**Proyecto:** Plataforma SaaS de Prospección Automatizada y Gestión de Campañas de Marketing  
**Repositorio:** `CarlosAM03/saas-platform-client`  
**Rama de trabajo:** `dev`  
**Responsable de implementación:** André Gael Rodríguez Sánchez  
**Responsable de arquitectura, integración y aprobación:** Carlos Benjamín Armenta Márquez  
**Fecha de corte:** 27 de septiembre de 2026

---

## 1. Objetivo

El objetivo de este avance es llevar el cliente Flutter al mismo alcance funcional que actualmente ofrece el backend NestJS después de su hardening.

El Flutter Foundation ya se encuentra operativo y validado para continuar desarrollo de features. Por lo tanto, este trabajo **no consiste en rehacer la arquitectura del cliente ni reparar nuevamente Fase 5**, sino en implementar sobre dicha base las funcionalidades de negocio que ya están disponibles en el backend.

Al terminar este trabajo, la plataforma Flutter debe permitir utilizar desde interfaz las capacidades actualmente funcionales de:

- autenticación;
- contexto de tenant;
- tenants;
- usuarios;
- campañas;
- prospectos;
- perfil;
- dashboard básico;
- consulta de Prospecting Jobs existentes.

Las capacidades que dependen de Prospector Service/FastAPI permanecen fuera de alcance.

---

# 2. Baseline de trabajo

## Cliente Flutter

La rama oficial de desarrollo es:

```text
dev
```

Baseline funcional de Flutter Foundation:

```text
dd9e95b2a4e71afc98662ed4250312a615b7915a
```

Antes de comenzar:

```powershell
git fetch origin
git switch dev
git pull --ff-only origin dev
```

Todo el trabajo debe realizarse directamente sobre `dev`.

No crear ramas adicionales.

No realizar merge a `main`.

El merge a `main` será realizado exclusivamente por Carlos después de revisar y validar el resultado completo.

---

## Backend NestJS de referencia

Repositorio:

```text
CarlosAM03/saas-platform-backend
```

Rama:

```text
dev
```

Estado auditado:

```text
d539a82043a817d216500045f354cbece35eb0be
```

El backend es la autoridad respecto a:

- disponibilidad real de endpoints;
- reglas de negocio;
- autorización;
- tenant isolation;
- persistencia;
- validaciones;
- respuestas HTTP.

Flutter debe adaptarse al backend y no al contrario.

---

# 3. Autoridad de implementación

André tiene autoridad para implementar, modificar, refactorizar y probar las features Flutter que le corresponden.

Puede crear dentro de las features:

- pantallas;
- widgets;
- repositories;
- providers;
- state;
- DTOs específicos;
- mocks temporales cuando estén permitidos;
- tests;
- componentes reutilizables de presentación.

Esta autoridad es de **implementación**, no de decisión arquitectónica.

André NO debe modificar por iniciativa propia:

- contratos HTTP;
- reglas de negocio;
- modelos del backend;
- RBAC;
- tenant isolation;
- estrategia global de autenticación;
- manejo transversal de sesión;
- arquitectura de networking;
- decisiones todavía pendientes del Prospector Service.

Ante una contradicción o decisión no documentada:

1. no inventar una solución;
2. conservar el baseline;
3. documentar el punto;
4. continuar con el resto del trabajo;
5. escalarlo a Carlos si bloquea realmente la implementación.

---

# 4. Documentación obligatoria

Antes de implementar una feature se debe consultar:

```text
FEATURE-DEVELOPMENT.md
Docs/ADRs/ADR-005-FlutterFoundation.md
Docs/Flutter-Foundation.md
Docs/Contracts/platform-api.v1.yaml
```

`FEATURE-DEVELOPMENT.md` define las reglas permanentes para desarrollo de features y debe considerarse guía principal de implementación Flutter.

Para conocer qué funcionalidades están realmente disponibles en este avance también debe consultarse el estado actual del backend.

La existencia de una operación en el contrato objetivo OpenAPI no significa necesariamente que esté habilitada operacionalmente en este momento.

---

# 5. Arquitectura que debe conservarse

Toda feature debe mantener el flujo:

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

No está permitido:

```text
Widget → Dio
Provider → Dio
Feature → FastAPI
Feature → PostgreSQL
```

Dio permanece encapsulado en:

```text
lib/core/network/
```

---

# 6. Áreas protegidas del Foundation

Estas áreas ya forman parte del baseline transversal y no deben modificarse salvo que exista un defecto reproducible que impida implementar una feature:

```text
lib/app/
lib/core/config/
lib/core/network/
lib/core/storage/
lib/core/errors/
lib/routes/
lib/features/auth/
lib/shared/models/
```

Incluyen:

- ApiClient;
- JWT;
- secure storage;
- AuthState;
- comportamiento global de 401;
- comportamiento de 403;
- routing;
- guards;
- configuración;
- DTOs base.

Si una feature necesita un cambio transversal, primero debe reportarse.

---

# 7. Prioridad 0 — Campaigns

Campaigns debe pasar de placeholder a feature completamente conectada al backend.

El backend actual permite:

```text
GET    /api/v1/campaigns
POST   /api/v1/campaigns
GET    /api/v1/campaigns/:id
PATCH  /api/v1/campaigns/:id
DELETE /api/v1/campaigns/:id
GET    /api/v1/campaigns/:id/prospects
```

Implementar:

```text
lib/features/campaigns/
```

con una estructura equivalente a:

```text
data/
models/
providers/
state/
screens/
widgets/
```

Debe incluir como mínimo:

- listado de campañas;
- búsqueda;
- paginación;
- detalle;
- creación;
- edición;
- cambio de estado permitido por backend;
- archivado;
- acción de borrado permanente únicamente cuando corresponda;
- acceso a prospectos de una campaña.

Estados mínimos:

```text
loading
empty
success
error
```

Flutter no debe enviar `tenantId` como autoridad.

El backend obtiene tenant y creador desde la sesión.

---

# 8. Prioridad 0 — Prospects

Prospects debe pasar de placeholder a feature funcional.

Backend disponible:

```text
GET   /api/v1/prospects
GET   /api/v1/prospects/:id
PATCH /api/v1/prospects/:id
GET   /api/v1/campaigns/:id/prospects
```

Implementar:

- listado;
- búsqueda;
- paginación;
- detalle;
- edición;
- consulta por campaña;
- estados vacíos;
- manejo de errores.

Los campos editables deben corresponder estrictamente al DTO del backend.

No implementar:

- creación manual no soportada;
- scraping;
- importación de BusinessResult;
- deduplicación;
- persistencia desde resultados temporales.

La feature trabaja únicamente con Prospect ya persistido.

---

# 9. Prioridad 0 — Users

El backend ya dispone de CRUD funcional de usuarios dentro del tenant.

Endpoints:

```text
GET    /api/v1/users
POST   /api/v1/users
GET    /api/v1/users/:id
PATCH  /api/v1/users/:id
DELETE /api/v1/users/:id
```

Implementar:

- listado;
- búsqueda;
- paginación;
- detalle;
- creación;
- edición;
- cambio de rol cuando backend lo permita;
- desactivación lógica.

RBAC actual del backend:

### MEMBER

Puede consultar usuarios.

No puede:

- crear;
- editar;
- desactivar.

### OWNER

Puede:

- consultar;
- crear;
- editar.

No puede eliminar/desactivar.

### ADMIN

Con tenant seleccionado puede realizar las operaciones administrativas permitidas por backend, incluida desactivación.

La UI puede ocultar acciones según rol, pero backend continúa siendo la autoridad real.

---

# 10. Prioridad 0 — Tenants

El backend permite:

```text
GET  /api/v1/tenants
POST /api/v1/tenants
GET  /api/v1/tenants/:id
```

Implementar en Flutter lo necesario para:

- consultar tenants disponibles;
- visualizar información del tenant;
- seleccionar/cambiar tenant utilizando el flujo Auth existente;
- permitir creación únicamente para ADMIN.

No implementar:

- edición de tenants;
- eliminación de tenants;
- suspensión;
- administración de roles adicional;

porque actualmente el backend no ofrece esas operaciones.

La selección de tenant debe continuar utilizando:

```text
POST /api/v1/auth/select-tenant
```

No duplicar lógica de autenticación.

---

# 11. Prioridad 1 — Admin

La pantalla `Admin` actualmente es un placeholder.

Debe convertirse en la entrada a las capacidades administrativas que realmente existen.

Debe integrar principalmente:

```text
Tenants
Users
```

Las opciones deben depender del contexto y rol disponible.

No implementar funciones no soportadas, incluyendo:

- invitaciones;
- recuperación administrativa de contraseña;
- sistema configurable de permisos;
- eliminación física de usuarios;
- edición/eliminación de tenants;
- nuevas tablas de roles.

---

# 12. Prioridad 1 — Profile

La pantalla Profile debe aprovechar el AuthContext existente.

Mostrar como mínimo:

- nombre;
- correo;
- platformRole;
- tenant actual;
- rol dentro del tenant cuando aplique.

Debe permitir:

- acceder al cambio de tenant;
- cerrar sesión.

No implementar edición de perfil si backend no dispone de una operación específica para el usuario autenticado.

---

# 13. Prioridad 1 — Dashboard

El Dashboard puede dejar de ser placeholder.

Debe utilizar exclusivamente información real disponible mediante las features ya implementadas.

Puede mostrar, por ejemplo:

- campañas disponibles;
- prospectos disponibles;
- estado general de los datos;
- accesos rápidos.

No crear endpoints nuevos.

No inventar métricas empresariales o analíticas que el sistema todavía no calcula.

El Dashboard no debe bloquear la entrega si las features P0 todavía requieren trabajo.

---

# 14. Prioridad 2 — ProspectingJobs

El backend conserva funcional únicamente la lectura de Jobs existentes.

Actualmente están disponibles:

```text
GET /api/v1/prospecting-jobs
GET /api/v1/prospecting-jobs/:id
```

Puede implementarse:

- listado;
- paginación;
- detalle;
- status;
- información persistida del Job.

El backend devuelve actualmente:

```text
resultsAvailable = false
results = null
progress = null
```

aunque exista un registro COMPLETED.

Esto debe representarse correctamente en Flutter.

---

# 15. Funcionalidades de Jobs prohibidas en este avance

NO implementar como funcionales:

```text
POST /api/v1/prospecting-jobs
POST /api/v1/prospecting-jobs/:id/cancel
POST /api/v1/prospecting-jobs/:id/persist
GET  /api/v1/prospecting-jobs/:id/export
```

Estas operaciones actualmente responden:

```text
503
PROSPECTOR_INTEGRATION_PENDING
```

porque Prospector Service todavía no está disponible.

No crear mocks que aparenten que estas operaciones funcionan realmente.

---

# 16. Generate / Prospección

La pantalla de generación puede mantenerse deshabilitada, placeholder o mostrar claramente que la integración se encuentra pendiente.

No implementar:

- búsquedas simuladas como reales;
- scraping;
- progreso ficticio;
- resultados ficticios presentados como reales;
- exportaciones;
- persistencia de resultados;
- llamadas directas a Python.

Flutter nunca debe comunicarse directamente con Prospector Service.

---

# 17. Prospecting Service fuera de alcance

Queda completamente fuera de este avance:

```text
FastAPI
Prospector Engine
Playwright
BeautifulSoup
callbacks
cache real de resultados
exportaciones
deduplicación
importación BusinessResult
idempotencia persistente
cancelación física
retries
timeouts operacionales
```

No tomar decisiones sobre estas áreas.

---

# 18. Paginación y filtros

Campaigns, Prospects, Users y Jobs utilizan paginación real del backend.

Flutter debe trabajar con:

```text
page
limit
total
totalPages
```

No cargar todos los datos para simular paginación local.

Respetar:

```text
search
sortBy
sortOrder
```

únicamente donde el backend los soporte.

El límite máximo de paginación es:

```text
100
```

---

# 19. Manejo de errores

Todas las features deben utilizar el manejo transversal existente.

### 400

Mostrar validación o solicitud inválida.

### 401

Dejar que Foundation invalide sesión y redirija según el comportamiento existente.

### 403

Mantener sesión y mostrar falta de permisos/contexto.

### 404

Mostrar recurso inexistente.

### 409

Mostrar conflicto de dominio.

### 429

Mostrar limitación de solicitudes.

### 503

Mostrar funcionalidad/servicio temporalmente no disponible.

No duplicar parsers de errores en cada pantalla.

---

# 20. Estados obligatorios

Cada feature debe contemplar:

```text
initial
loading
empty
success
error
```

Además debe comportarse correctamente ante:

- backend apagado;
- 401;
- 403;
- tenant faltante;
- listas vacías;
- errores de validación;
- operaciones exitosas.

Una respuesta de error no debe producir red screen.

---

# 21. RBAC y rol MEMBER

Existe documentación histórica del cliente que no coincide completamente con el alcance actualmente aplicado en backend para MEMBER.

André NO debe resolver esa contradicción tomando una nueva decisión.

Regla para este avance:

> La autorización real la determina el backend.

La UI puede ser conservadora respecto a visibilidad, pero nunca debe asumir que sus controles sustituyen la autorización HTTP.

Si una operación visible devuelve 403:

- no borrar sesión;
- mostrar el error correspondiente;
- no cambiar backend;
- documentar si parece existir una contradicción real.

---

# 22. Mocks

Los mocks pueden mantenerse únicamente cuando una feature todavía no se conecta realmente.

Una vez integrada una feature con backend:

- el API Repository debe ser la implementación utilizada para ejecución real;
- mocks pueden permanecer para tests/desarrollo aislado;
- nunca deben convertirse en fuente de verdad.

No utilizar mocks para simular capacidades actualmente deshabilitadas del backend.

---

# 23. Tests

Los 16 tests actuales de Flutter Foundation deben permanecer verdes.

No modificar tests para ocultar regresiones.

Cada feature nueva debe agregar pruebas como mínimo para:

- repository;
- parsing de DTO;
- estados de provider/state;
- success;
- empty;
- error;
- permisos o 403 cuando sea relevante.

Antes de terminar cada bloque:

```powershell
flutter analyze
flutter test
```

Ambos deben pasar.

---

# 24. Forma de trabajo en Git

Todo el equipo trabaja actualmente sobre:

```text
dev
```

No crear ramas adicionales.

Antes de comenzar:

```powershell
git fetch origin
git switch dev
git pull --ff-only origin dev
```

Antes de cada push:

```powershell
git pull --ff-only origin dev
flutter analyze
flutter test
git status
```

Organizar el trabajo mediante commits separados por feature.

Ejemplos:

```text
feat(campaigns): implement campaign management
feat(prospects): implement persisted prospect management
feat(users): implement tenant user management
feat(tenants): implement tenant management
feat(profile): complete profile and tenant context
feat(jobs): implement read-only job views
```

Hacer push únicamente a:

```text
origin/dev
```

Nunca:

```text
main
```

Carlos es el único responsable de validar `dev` y realizar posteriormente el merge a `main`.

---

# 25. No modificar backend

André trabaja exclusivamente en:

```text
saas-platform-client
```

No modificar:

```text
saas-platform-backend
```

Si el cliente encuentra una incompatibilidad:

1. revisar OpenAPI;
2. revisar Swagger del backend ejecutado;
3. revisar README/handoff actual del backend;
4. confirmar el request/response real;
5. documentar la discrepancia.

No adaptar el backend desde Flutter.

---

# 26. Orden de implementación

Trabajar en este orden:

```text
1. Campaigns
2. Prospects
3. Users
4. Tenants
5. Admin
6. Profile
7. Dashboard
8. ProspectingJobs read-only
```

Las primeras cuatro son prioridad principal.

Si el tiempo no permite completar todo, se debe priorizar:

```text
Campaigns + Prospects + Users + Tenants
```

antes de invertir tiempo en Dashboard o Jobs.

---

# 27. Criterio funcional del primer avance

Al finalizar, el usuario debe poder recorrer una plataforma donde:

```text
Login
  ↓
Tenant Context
  ↓
Dashboard
  ├── Campaigns
  │     ├── List
  │     ├── Create
  │     ├── Detail
  │     ├── Edit
  │     └── Archive
  │
  ├── Prospects
  │     ├── List
  │     ├── Search
  │     ├── Detail
  │     └── Edit
  │
  ├── Admin
  │     ├── Users
  │     └── Tenants
  │
  ├── Profile
  │     └── Tenant / Session
  │
  └── Jobs
        └── Read-only
```

Sin depender de:

```text
FastAPI
Prospector Engine
Scraping
```

---

# 28. Definition of Done

El trabajo se considera listo para revisión cuando:

### Foundation

- no se rompió Auth;
- no se rompió routing;
- no se rompió JWT;
- no se rompió tenant context;
- los tests existentes continúan verdes.

### Features

- Campaigns funciona contra API real.
- Prospects funciona contra API real.
- Users funciona contra API real.
- Tenants funciona contra API real.
- Profile representa correctamente el contexto.
- Admin utiliza únicamente capacidades reales.
- Dashboard no depende de datos falsos.
- Jobs, si se implementa, es read-only.

### Calidad

```text
flutter analyze → PASS
flutter test    → PASS
```

### Runtime

La aplicación debe:

- compilar;
- arrancar;
- navegar sin red screens;
- comunicarse con NestJS;
- manejar errores sin crash.

---

# 29. Entrega final de André

Al terminar, reportar a Carlos:

```text
SHA final de dev
```

y un resumen con:

### Implementado

Features terminadas.

### Endpoints utilizados

Endpoints realmente consumidos.

### Tests

Resultado de:

```text
flutter analyze
flutter test
```

### Pruebas manuales

Flujos probados contra backend local.

### Pendientes

Features incompletas o bloqueos reales.

### Contradicciones

Cualquier discrepancia detectada entre:

```text
Flutter
OpenAPI
Swagger
Backend
Documentación
```

No resolver arquitectónicamente esas contradicciones por iniciativa propia.

---

# 30. Resultado esperado

El objetivo final de este trabajo no es completar todavía el sistema de prospección.

El objetivo es obtener:

```text
FLUTTER CLIENT
      +
NESTJS BACKEND
      +
POSTGRESQL
```

con el mismo alcance funcional de gestión para el primer avance:

```text
Auth
Tenants
Users
Campaigns
Prospects
Profile
Admin
Dashboard básico
Jobs read-only
```

y mantener explícitamente pendiente:

```text
Prospector Service / Engine integration
```

para una fase posterior.

---

## Regla final

**Implementa todo lo que el backend actual ya soporta y el cliente todavía no expone.**

**No implementes como funcional nada que el backend actual haya dejado explícitamente pendiente.**

**No cambies decisiones arquitectónicas.**

**Trabaja directamente sobre `dev`.**

**No hagas merge ni push a `main`.**

**Cuando `dev` esté listo, Carlos realizará la validación final, integración y despliegue.**