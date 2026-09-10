# ADR-004 — Implementación de infraestructura transversal y módulos base

> **Gobierno F4 cerrado:** este ADR es la autoridad consolidada del baseline. Las decisiones anteriores compatibles se conservan; cualquier texto de F1/F2/F3 que contradiga este documento queda superseded y debe adaptarse. La secuencia normativa es: F4 CLOSED -> decisiones finales consolidadas -> documentación anterior adaptada -> implementación alineada.

**Estado:** ACEPTADO / CERRADO
**Fase:** Fase 4 — Implementación de infraestructura y baseline
**Fecha:** 2026-09-09
**Ámbito:** Platform Backend
**Proyecto:** Plataforma SaaS
**Tecnología:** NestJS + TypeScript + Prisma + PostgreSQL

---

# 1. Contexto

Las fases anteriores establecieron las bases funcionales y arquitectónicas de la Plataforma SaaS:

* **Fase 1 — Diseño del dominio**
* **Fase 2 — Contratos y comportamiento de la API**
* **Fase 3 — Seguridad y arquitectura transversal**

La arquitectura definida comprende:

```text
Flutter Client
      │
      │ HTTPS / JWT Bearer
      ▼
Platform Backend
NestJS + TypeScript + Prisma
      │
      │ HTTP + X-API-Key
      ▼
Prospector Service
Python + FastAPI
      │
      ▼
Prospector Engine
Python
```

La Fase 4 tiene como propósito convertir las decisiones previamente aprobadas en una implementación concreta del Platform Backend.

F4 no constituye una nueva fase de diseño funcional ni pretende rediseñar las decisiones de F1–F3.

Su responsabilidad es construir el **baseline técnico transversal** sobre el cual podrán implementarse posteriormente los módulos funcionales.

---

# 2. Decisión

Se implementará el Platform Backend como un **monolito modular NestJS**, utilizando:

```text
NestJS
TypeScript
Prisma
PostgreSQL
Passport + JWT
Pino
class-validator
class-transformer
Helmet
AsyncLocalStorage
```

La infraestructura transversal será implementada durante F4 y los módulos funcionales quedarán preparados para su posterior implementación.

El resultado deberá ser:

```text
concreto
consistente
reutilizable
seguro
testeable
documentado
AI-friendly
```

La implementación deberá respetar las decisiones arquitectónicas establecidas en F1–F3 y las precisiones cerradas durante la auditoría final de F4.

---

# 3. Principio rector

La Fase 4 se regirá por el siguiente principio:

> **F4 no introduce nuevas capacidades de negocio. F4 convierte las decisiones de F1–F3 y los contratos de F2 en una infraestructura NestJS concreta, consistente, reutilizable y documentada, de manera que los módulos funcionales puedan implementarse posteriormente sin reinterpretar la arquitectura.**

Por lo tanto, la infraestructura desarrollada en F4 deberá evitar que los futuros implementadores tengan que volver a decidir sobre:

* autenticación;
* autorización;
* roles;
* contexto tenant;
* aislamiento multi-tenant;
* estructura de respuestas;
* estructura de errores;
* validación;
* logging;
* requestId;
* configuración;
* acceso común a Prisma;
* reglas transversales de seguridad.

---

# 4. Jerarquía de fuentes de verdad

Para la implementación se establece la siguiente jerarquía:

```text
1. ADR-004: decisiones F4 cerradas
2. Registro de decisiones Fase 4
3. Prisma y migraciones alineados con F4
4. OpenAPI/Swagger alineados con F4
5. Código y tests alineados con F4
6. Documentación anterior reconciliada
7. Planes, handoffs y auditorías como evidencia histórica
```

Esta jerarquía no autoriza a ocultar contradicciones.

Si F1/F2/F3 o la implementación contradicen F4, se aplica F4 y se reconcilia la fuente anterior. Solo decisiones nuevas no resueltas por F4 requieren validación humana.

El código no podrá utilizarse como mecanismo para ocultar o reinterpretar una contradicción arquitectónica.

---

# 5. Alcance de Fase 4

## 5.1 Incluido

F4 incluye:

* configuración base;
* `main.ts`;
* `AppModule`;
* Prisma base;
* Common;
* Auth;
* Users;
* Health;
* logging;
* manejo global de errores;
* manejo global de respuestas;
* validación;
* seguridad transversal;
* TenantContext;
* guards;
* decorators;
* rate limiting de autenticación;
* password hashing;
* seed inicial;
* pruebas mínimas de infraestructura;
* documentación técnica;
* guía de desarrollo de módulos;
* estructura NestJS de módulos funcionales futuros.

---

## 5.2 Fuera de alcance

F4 no implementará:

* funcionalidad completa de Tenants;
* funcionalidad completa de Campaigns;
* funcionalidad completa de Prospects;
* funcionalidad completa de ProspectingJobs;
* cliente real de Prospector Service;
* integración funcional con Prospector Service;
* Flutter;
* Docker;
* Redis;
* queues;
* workers;
* observabilidad avanzada;
* auditoría completa;
* CI/CD;
* deployment;
* infraestructura productiva.

Estas capacidades podrán ser definidas posteriormente mediante decisiones independientes.

---

# 6. Arquitectura modular

El Platform Backend utilizará una arquitectura modular orientada a dominio.

La estructura base será:

```text
src/
├── main.ts
├── app.module.ts
│
├── common/
├── auth/
├── users/
├── tenants/
├── campaigns/
├── prospects/
├── prospecting-jobs/
├── prospector-client/
│
└── prisma/
```

Cada módulo mantendrá separación por responsabilidad.

Dependiendo de sus necesidades podrá contener:

```text
module
controller
service
dto
guards
strategies
services
```

No se introducirán abstracciones únicamente por aplicar patrones arquitectónicos.

La complejidad deberá estar justificada por una necesidad real.

---

# 7. Módulos funcionales preparados

Durante F4 se crearán físicamente los siguientes módulos:

```text
tenants/
campaigns/
prospects/
prospecting-jobs/
prospector-client/
```

Cada uno tendrá al menos:

```text
<module>.module.ts
```

y será registrado en `AppModule`.

Estos módulos no recibirán implementación funcional durante F4.

No serán simples carpetas vacías.

Su objetivo es proporcionar un esqueleto NestJS real para la siguiente fase de implementación.

Excepción autorizada por Carlos: se conservan los READMEs locales de tenants, campaigns, prospects, prospecting-jobs y prospector-client como contexto subordinado a este ADR.

La documentación general estará centralizada en:

```text
MODULE-DEVELOPMENT.md
```

---

# 8. `main.ts`

Swagger sirve el YAML Platform en `/api/docs`; utiliza el origen actual como servidor y conserva `/api/v1` en las rutas. Los contratos funcionales F5+ no implican endpoints implementados en F4.

`main.ts` será responsable exclusivamente del bootstrap y de la configuración transversal.

Se configurarán:

* bootstrap de NestJS;
* prefijo global `/api/v1`;
* `ValidationPipe`;
* filtros globales;
* interceptores globales;
* CORS;
* Helmet;
* shutdown hooks;
* configuración necesaria para el arranque.

No se colocará lógica de negocio en `main.ts`.

---

# 9. `AppModule`

`AppModule` será el módulo raíz de composición de la aplicación.

Registrará:

```text
Common
Auth
Users
Prisma
Tenants
Campaigns
Prospects
ProspectingJobs
ProspectorClient
```

Los módulos funcionales podrán encontrarse registrados aunque inicialmente no contengan lógica funcional.

---

# 10. Configuración

Se utilizará:

```text
@nestjs/config
```

La configuración de la aplicación estará centralizada.

No se permitirán:

* credenciales hardcodeadas;
* secretos dentro del código fuente;
* API keys dentro del repositorio;
* contraseñas administrativas dentro del código.

La aplicación realizará validación estricta de las variables necesarias durante el arranque.

Si falta una variable crítica, la aplicación deberá impedir el inicio.

---

# 11. Variables de entorno

Las variables iniciales requeridas son:

```text
NODE_ENV
PORT
DATABASE_URL

JWT_SECRET
JWT_EXPIRES_IN

PROSPECTOR_SERVICE_URL
PROSPECTOR_API_KEY

CORS_ORIGINS

ADMIN_NAME
ADMIN_EMAIL
ADMIN_PASSWORD
```

Las variables:

```text
ADMIN_NAME
ADMIN_EMAIL
ADMIN_PASSWORD
```

se utilizarán para el seed del administrador global inicial.

Las credenciales y secretos deberán permanecer fuera del repositorio.

---

# 12. Prisma

Se utilizará:

```text
PrismaService
```

basado en:

```text
PrismaClient
```

La aplicación utilizará una única instancia lógica de Prisma durante el MVP.

No se utilizará:

```text
una instancia por tenant
una instancia por request
una instancia por módulo
```

El modelo de persistencia es:

```text
Shared Database
+
Shared Schema
+
tenantId
```

Los tenants se aislarán lógicamente mediante el contexto tenant y las restricciones correspondientes en las consultas.

---

# 13. Acceso a Prisma

El acceso directo a Prisma estará restringido a los Services responsables de las operaciones de persistencia.

La dirección principal será:

```text
Controller
    ↓
Service
    ↓
PrismaService
    ↓
PostgreSQL
```

Los siguientes componentes no accederán directamente a Prisma:

* Controllers;
* DTOs;
* interceptors;
* decoradores.

Los Guards tampoco realizarán acceso arbitrario a Prisma; cuando una validación requiera persistencia, utilizarán el servicio responsable correspondiente.

No se establecerá un Repository Pattern obligatorio.

Un Repository Layer únicamente podrá introducirse si una necesidad real lo justifica y no contradice esta arquitectura.

---

# 14. Modelo multi-tenant

La estrategia de multi-tenancy será:

```text
Shared Database
+
Shared Schema
+
Tenant ID
```

Las entidades que pertenezcan a un tenant deberán quedar asociadas al tenant correspondiente.

El cliente no tendrá autoridad para definir libremente el tenant sobre el cual se ejecuta una operación protegida.

El tenant operativo será determinado por el contexto autenticado.

---

# 15. TenantContext

Se establece `TenantContext` como infraestructura transversal.

Su función es proporcionar a las operaciones internas el contexto tenant de la request autenticada.

El contexto podrá contener:

```typescript
{
  userId: string;
  tenantId: string | null;
  tenantRole: RoleName | null;
  platformRole: PlatformRole | null;
}
```

El contexto distingue explícitamente entre:

```text
Platform Role
```

y:

```text
Tenant Role
```

Esto permite representar correctamente tanto usuarios tenant-scoped como administradores globales.

---

# 16. Implementación de TenantContext

Se utilizará:

```text
AsyncLocalStorage
```

para propagar el contexto de la request sin obligar a pasar manualmente el `tenantId` a través de todas las capas de la aplicación.

La utilización de AsyncLocalStorage deberá mantenerse deliberadamente simple.

No se utilizará como sustituto de autorización.

Tampoco se utilizará para permitir que el cliente modifique el contexto.

El contexto:

* será creado a partir de información autenticada;
* será válido únicamente durante la request;
* no será estado global mutable;
* no será modificable arbitrariamente por código de negocio;
* deberá quedar correctamente aislado entre requests.

Intentar obtener un contexto tenant inexistente cuando una operación lo requiere deberá producir un comportamiento explícito de error.

Las operaciones globales de `ADMIN` deberán poder operar con:

```text
tenantId = null
```

cuando no exista un tenant seleccionado.

---

# 17. Tenant Isolation

Las operaciones tenant-scoped deberán restringirse al tenant obtenido del `TenantContext`.

La fuente de autoridad será:

```text
JWT
 ↓
Authentication
 ↓
TenantContext
 ↓
Service
 ↓
Prisma query
```

El cliente no podrá utilizar un `tenantId` arbitrario para obtener acceso a otro tenant.

Ejemplo conceptual:

```text
TenantContext
      ↓
tenantId
      ↓
Service
      ↓
Prisma
      ↓
WHERE tenantId = authenticatedTenantId
```

---

# 18. Estrategia de mitigación de errores humanos

No se implementará Prisma Middleware o Prisma Extension obligatoria para inyectar automáticamente `tenantId` en todas las consultas.

Tampoco se implementará un Repository Pattern obligatorio únicamente para resolver este problema.

La mitigación se realizará mediante:

* `TenantContext` como fuente única del contexto;
* helpers para obtener o exigir el tenant actual;
* convenciones de consultas tenant-aware;
* documentación en `MODULE-DEVELOPMENT.md`;
* ejemplos de implementación;
* pruebas específicas de aislamiento;
* revisión de operaciones tenant-scoped;
* prohibición de utilizar `tenantId` del cliente como autoridad de seguridad;
* detección y reporte de consultas que no respeten el contexto.

El objetivo es reducir el riesgo de error humano sin introducir una capa automática de aislamiento que añada complejidad innecesaria.

La responsabilidad de construir correctamente las operaciones tenant-scoped permanece en la capa de Service.

---

# 19. Seguridad del TenantContext

El `TenantContext` no será una fuente de autorización independiente.

La autorización se establecerá mediante:

```text
identidad autenticada
+
platformRole
+
tenantId
+
tenantRole
+
reglas del endpoint
```

El contexto nunca podrá construirse directamente a partir de un `tenantId` proporcionado por el cliente sin validación.

Los tests deberán comprobar que:

```text
Tenant A
    X
Tenant B
```

no pueda producir acceso cruzado.

---

# 20. Common

Common contendrá exclusivamente infraestructura transversal.

Podrá incluir:

```text
common/
├── interceptors/
├── guards/
├── decorators/
├── filters/
├── context/
├── config/
├── health/
├── logging/
└── dto/
```

Common podrá ser utilizado por otros módulos.

Common no dependerá de Auth.

La dirección conceptual será:

```text
Common
   ↑
Auth
Users
Tenants
Campaigns
Prospects
ProspectingJobs
ProspectorClient
```

No se permitirán dependencias circulares.

---

# 21. Request ID

Cada request recibirá un `requestId`.

El requestId será utilizado para:

* logging;
* debugging;
* correlación de errores;
* seguimiento de requests.

No se introducirá un identificador de correlación adicional durante F4.

El requestId deberá estar disponible para el mecanismo de logging y para la información técnica asociada a errores.

---

# 22. Logging

Se utilizará Pino como logger de aplicación.

Cuando estén disponibles, los logs podrán incluir:

```text
requestId
method
path
statusCode
duration
userId
tenantId
IP
user-agent
```

Se registrarán eventos relevantes de seguridad:

```text
login exitoso
login fallido
authorization rejection
logout
external service request
```

Nunca se registrarán:

```text
password
passwordHash
JWT
API keys
secrets
```

El logging deberá permitir debugging suficiente sin exponer información sensible.

---

# 23. Error Handling

Se implementará un:

```text
GlobalExceptionFilter
```

Todas las respuestas de error HTTP deberán normalizarse al formato:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "...",
    "details": {},
    "timestamp": "..."
  }
}
```

Los errores inesperados producirán:

```text
500 INTERNAL_SERVER_ERROR
```

Los detalles técnicos deberán permanecer disponibles en los logs.

Durante desarrollo se podrá conservar información adicional para debugging.

En producción no se expondrán:

* stack traces;
* información interna;
* detalles de implementación;
* secretos;
* información sensible.

---

# 24. Response Handling

Las respuestas exitosas utilizarán:

```json
{
  "success": true,
  "data": {},
  "meta": {}
}
```

`meta` será opcional.

Se utilizará cuando exista información adicional relevante, especialmente:

* paginación;
* metadata operacional.

El interceptor global deberá respetar las reglas del protocolo HTTP.

No se generará un body para una respuesta que por especificación HTTP deba ser:

```text
204 No Content
```

Los endpoints que requieran contenido de respuesta utilizarán códigos HTTP compatibles con el wrapper.

---

# 25. Validation

Se utilizará:

```text
class-validator
class-transformer
ValidationPipe
```

La configuración global será:

```text
whitelist: true
forbidNonWhitelisted: true
transform: true
```

Los DTOs estarán separados del modelo Prisma.

La dirección será:

```text
HTTP Request
     ↓
DTO
     ↓
ValidationPipe
     ↓
Controller
     ↓
Service
     ↓
Prisma
```

Los DTOs nunca accederán directamente a Prisma.

Los datos inválidos producirán:

```text
HTTP 400
VALIDATION_ERROR
```

---

# 26. CORS

CORS será configurable mediante variables de entorno.

No se hardcodeará un origen de producción como única configuración.

La configuración deberá permitir adaptar los orígenes autorizados entre entornos.

---

# 27. Helmet

Helmet será habilitado globalmente.

Su configuración formará parte de la infraestructura transversal.

---

# 28. Auth

El módulo Auth será responsable de:

* login;
* logout;
* selección de tenant;
* `/auth/me`;
* generación de JWT;
* validación de JWT;
* password verification;
* integración con UserTenant;
* rate limiting de autenticación.

Se utilizará:

```text
Passport
+
JWT Strategy
```

---

# 29. JWT

La autenticación utilizará:

```text
Bearer JWT
Algoritmo: HS256
Expiración: 8 horas
Refresh Token: no
Blacklist: no
OAuth2: no
```

El JWT contendrá el contexto necesario para distinguir autoridad global y contexto tenant-scoped.

Claims:

```text
sub
iat
exp
email
platformRole
tenantId
tenantRole
```

No se utilizará un claim genérico `role` como sustituto ambiguo de los dos niveles de autorización.

---

# 30. Contexto JWT

Para un usuario tenant-scoped:

```text
platformRole = null
tenantId     = tenant seleccionado
tenantRole   = OWNER | MEMBER
```

Para un administrador global sin tenant seleccionado:

```text
platformRole = ADMIN
tenantId     = null
tenantRole   = null
```

Para un administrador global operando sobre un tenant:

```text
platformRole = ADMIN
tenantId     = tenant seleccionado
tenantRole   = null
```

La selección de un tenant no transforma a un `ADMIN` en:

```text
OWNER
```

ni:

```text
MEMBER
```

El usuario mantiene su autoridad global.

---

# 31. JWT como snapshot de autorización

El JWT representa un snapshot del contexto de autorización en el momento de su emisión.

No se realizará una consulta a `UserTenant` en cada request únicamente para verificar nuevamente el rol tenant-scoped.

La validación normal de cada request incluirá:

* firma;
* expiración;
* identidad;
* estado activo del usuario;
* contexto necesario para autorización.

Un cambio de rol o membresía será reflejado al emitir un nuevo JWT.

Esta decisión mantiene el comportamiento stateless establecido para el MVP y evita introducir una consulta transversal obligatoria en cada request.

---

# 32. JWT Strategy

JWT Strategy será responsable de:

1. validar la firma;
2. validar la expiración;
3. validar la identidad;
4. comprobar que el usuario continúe activo;
5. proporcionar el contexto autenticado necesario.

La Strategy no duplicará innecesariamente toda la lógica de negocio de UserTenant.

Las responsabilidades relacionadas con memberships estarán centralizadas en servicios correspondientes.

---

# 33. ADMIN global

`ADMIN` es una autoridad global de plataforma.

No es un rol tenant-scoped.

No se utilizará:

```text
system tenant
```

ni:

```text
isAdmin
```

para representar esta autoridad.

El modelo definitivo distingue:

```text
Platform Role
    ADMIN

Tenant Roles
    OWNER
    MEMBER
```

Un `ADMIN` puede existir sin ninguna relación `UserTenant`.

Un `ADMIN` puede operar globalmente o seleccionar un tenant sin dejar de ser `ADMIN`.

---

# 34. Modelo de roles

La relación definitiva será:

```text
User
 └── platformRole?

UserTenant
 ├── userId
 ├── tenantId
 └── roleId

Role
 ├── tenantId
 └── name
```

`RoleName` será:

```text
OWNER
MEMBER
```

`ADMIN` no pertenecerá a `Role`.

---

# 35. Corrección del modelo Prisma

El modelo Prisma deberá reflejar la semántica anterior.

Por lo tanto:

* `User.roleId` será eliminado;
* `User.platformRole` será agregado como campo nullable;
* `UserTenant.roleId` será el vínculo del rol tenant-scoped;
* `Role.tenantId` permanecerá obligatorio;
* `RoleName` contendrá `OWNER` y `MEMBER`;
* `ADMIN` no tendrá un registro en `Role`;
* no existirá tenant ficticio para administradores globales.

El resultado permitirá:

```text
User A
├── Tenant A → OWNER
├── Tenant B → MEMBER
└── Tenant C → MEMBER
```

y simultáneamente:

```text
User B
└── platformRole = ADMIN
```

sin necesidad de pertenencia a ningún tenant.

---

# 36. UserTenant

`UserTenantService` centralizará las operaciones relacionadas con:

* pertenencia de usuarios a tenants;
* resolución de membership;
* consulta de tenants disponibles;
* rol tenant-scoped;
* validación de relaciones User ↔ Tenant.

Esto evita duplicar las mismas reglas entre Auth, Users y otros módulos.

La consulta de `UserTenant` no será obligatoria en cada request únicamente para reconstruir el rol ya contenido en un JWT válido.

---

# 37. Login multi-tenant

El flujo será:

## Usuario con un tenant

```text
Login
 ↓
validación de credenciales
 ↓
identificación del tenant
 ↓
JWT final
```

El tenant será seleccionado automáticamente.

---

## Usuario con múltiples tenants

```text
Login
 ↓
validación de credenciales
 ↓
identificación de tenants disponibles
 ↓
selección de tenant
 ↓
JWT final
```

El JWT final contendrá el tenant seleccionado.

---

## Usuario sin tenants

Un usuario normal sin ninguna relación `UserTenant` válida no podrá obtener un JWT operativo tenant-scoped.

No podrá acceder al dominio funcional de la plataforma sin un contexto tenant válido.

---

## ADMIN global

Un `ADMIN` puede autenticarse sin tenant seleccionado.

En ese caso:

```text
platformRole = ADMIN
tenantId = null
tenantRole = null
```

También podrá operar con un tenant seleccionado sin perder su autoridad global.

---

# 38. Select Tenant

`POST /auth/select-tenant` permitirá establecer el tenant activo después de la autenticación inicial cuando el flujo requiera selección.

La selección deberá validarse contra `UserTenant`.

No se aceptará un tenant arbitrario únicamente porque el identificador sea válido.

La pertenencia deberá estar respaldada por la relación correspondiente o por la autoridad global de `ADMIN`.

El resultado será un JWT definitivo con el contexto seleccionado.

---

# 39. Usuario sin tenant

Un usuario normal que no tenga ningún tenant válido no recibirá un JWT operativo tenant-scoped.

Si el tenant requerido está suspendido o no es válido para el usuario, el acceso deberá rechazarse.

El código HTTP específico deberá permanecer alineado con F3 y OpenAPI.

---

# 40. RolesGuard

Se utilizará:

```text
@Roles(...)
```

para declarar requisitos de autorización.

Los roles serán:

```text
ADMIN
OWNER
MEMBER
```

La interpretación será contextual:

```text
ADMIN
→ platformRole

OWNER / MEMBER
→ tenantRole
```

La selección de tenant no convierte a un ADMIN en un rol tenant-scoped.

Los endpoints sin `@Roles()` no deberán interpretarse automáticamente como pertenecientes a OWNER.

Un endpoint sin roles explícitos podrá requerir únicamente autenticación, según el contrato y la política de seguridad correspondiente.

---

# 41. Decoradores

Se implementarán:

```text
@Public()
@Roles(...)
@CurrentUser()
```

Su objetivo es mantener los controllers declarativos.

Ejemplo conceptual:

```typescript
@Roles(RoleName.OWNER)
@Post()
createCampaign() {}
```

La autorización no deberá implementarse manualmente en cada controller cuando pueda ser expresada mediante los guards y metadata establecidos.

---

# 42. Password Policy

La política mínima será:

```text
mínimo 10 caracteres
al menos una letra
al menos un número
al menos un carácter especial
```

Se permitirán caracteres Unicode.

No se impondrá una restricción artificial a ASCII.

---

# 43. Password Hashing

Se utilizará:

```text
bcrypt
cost factor = 12
```

El hashing y verificación estarán encapsulados mediante:

```text
PasswordService
```

con responsabilidades equivalentes a:

```text
hash()
compare()
```

No se duplicará la lógica de bcrypt en múltiples Services.

---

# 44. Rate Limiting

F4 implementará rate limiting específicamente para autenticación.

Política:

```text
Máximo: 5 intentos
Ventana: 60 segundos
Scope: IP
```

Al superar el límite:

```text
HTTP 429 TOO_MANY_REQUESTS
```

El almacenamiento será:

```text
in-memory
```

No se utilizará Redis.

No se implementará account lockout durante el MVP.

La infraestructura podrá reutilizarse posteriormente para otros endpoints, pero no se exige rate limiting universal en F4.

La implementación concreta podrá utilizar un Guard o mecanismo equivalente siempre que preserve exactamente la política establecida.

---

# 45. Users

Precisión respaldada por el plan ejecutado, bloque 5: roleId es opcional al crear usuario y se resuelve a MEMBER del tenant operativo. ADMIN debe seleccionar tenant antes del CRUD tenant-scoped (403 si falta); Auth permite operaciones globales sin tenant. DELETE devuelve 200 con `{ success: true, data: {} }` y solo desactiva.

Users será responsable de:

* CRUD de usuarios;
* desactivación lógica;
* operaciones relacionadas con UserTenant;
* operaciones relacionadas con roles;
* administración de usuarios.

Endpoints establecidos por F2:

```text
GET    /users
POST   /users
GET    /users/{id}
PATCH  /users/{id}
DELETE /users/{id}
```

DELETE representará desactivación lógica.

El usuario pasará a:

```text
status = INACTIVO
```

No se realizará eliminación física mediante este endpoint.

---

# 46. Seed

Se implementará Prisma Seed.

El seed será idempotente.

La ejecución repetida:

```text
npm run prisma:seed
```

no deberá generar duplicados.

El seed deberá:

1. verificar si el registro ya existe;
2. omitirlo si existe;
3. crearlo si no existe;
4. informar el resultado.

---

# 47. Usuario ADMIN inicial

El seed creará el administrador global inicial utilizando:

```text
ADMIN_NAME
ADMIN_EMAIL
ADMIN_PASSWORD
```

El usuario inicial tendrá:

```text
platformRole = ADMIN
```

No necesitará pertenecer a ningún tenant.

La contraseña será hasheada mediante `PasswordService` o el mecanismo de hashing centralizado equivalente.

No se almacenará la contraseña en texto plano.

El seed deberá informar claramente si:

```text
creó el usuario
```

o:

```text
el usuario ya existía
```

---

# 48. Dependencias entre módulos

Se evitarán dependencias circulares.

La dirección conceptual será:

```text
Common
   ↑
Auth
Users
```

Auth puede utilizar Users.

Users no dependerá de Auth únicamente para realizar operaciones propias.

Las responsabilidades de autenticación y persistencia deberán separarse para evitar ciclos.

Si se requiere compartir lógica, se utilizarán servicios apropiados en lugar de introducir dependencias circulares.

---

# 49. Convenciones de código

Se utilizarán:

```text
ESLint
Prettier
```

Se mantendrá una nomenclatura consistente.

Archivos:

```text
kebab-case
```

Ejemplos:

```text
users.controller.ts
users.service.ts
create-user.request.ts
update-user.request.ts
user.response.ts
```

Los DTOs de request podrán utilizar:

```text
.request.ts
```

cuando corresponda al contrato de entrada.

Las convenciones de naming no constituyen decisiones arquitectónicas y podrán evolucionar mientras se preserve la consistencia del repositorio.

---

# 50. Libertad de implementación de Ángel

Ángel tendrá libertad para decidir la implementación interna de sus módulos dentro de los límites de la arquitectura.

Podrá decidir:

* estructura interna de Services;
* queries específicas de Prisma;
* DTOs funcionales;
* reglas de negocio del módulo;
* pruebas;
* organización interna.

Deberá respetar:

```text
OpenAPI
Prisma
ADRs
Common
TenantContext
autorización
tenant isolation
response wrapper
error wrapper
validation
logging
```

---

# 51. Restricciones para Ángel

Ángel no podrá modificar unilateralmente:

* ADRs;
* decisiones arquitectónicas;
* OpenAPI;
* modelo Prisma establecido;
* JWT;
* AuthGuard;
* RolesGuard;
* TenantContext;
* response wrapper;
* error format;
* ValidationPipe global;
* requestId;
* logging transversal;
* API versioning;
* tenant isolation;
* estados de `ProspectingJob`;
* contratos entre servicios.

Si una funcionalidad requiere modificar alguno de estos elementos, deberá reportarse antes de realizar el cambio.

---

# 52. Documentación

F4 producirá como mínimo:

```text
README.md
MODULE-DEVELOPMENT.md
```

La documentación deberá cubrir:

* arquitectura;
* ejecución local;
* variables de entorno;
* Prisma;
* Common;
* Auth;
* Users;
* TenantContext;
* autenticación;
* autorización;
* roles;
* tenant isolation;
* validación;
* errores;
* responses;
* logging;
* requestId;
* creación de módulos;
* pruebas;
* restricciones para agentes de IA.

Se conservan los cinco READMEs locales por la excepción de la sección 7. AGENTS/ no es requisito del cierre F4.

---

# 53. Module Development Guide

`MODULE-DEVELOPMENT.md` será la guía central para Ángel y futuros agentes.

Deberá explicar:

```text
1. cómo crear un módulo
2. cómo registrarlo
3. cómo estructurarlo
4. cómo crear DTOs
5. cómo utilizar TenantContext
6. cómo utilizar @Roles
7. cómo utilizar @CurrentUser
8. cómo realizar queries tenant-aware
9. cómo devolver responses
10. cómo manejar errores
11. cómo utilizar logging
12. cómo utilizar requestId
13. cómo escribir tests
14. qué decisiones no pueden modificarse
15. cómo reportar contradicciones
```

---

# 54. AI-friendly repository

El repositorio deberá estar preparado para permitir trabajo asistido por agentes de IA.

Un agente deberá poder seguir:

```text
ADRs
 ↓
OpenAPI
 ↓
Prisma
 ↓
MODULE-DEVELOPMENT.md
 ↓
Implementation Plan
 ↓
Implementación
 ↓
Tests
 ↓
Reporte
```

La documentación deberá distinguir claramente:

```text
decidido
permitido
restringido
pendiente
```

Una IA podrá implementar código dentro de los límites establecidos.

Una IA podrá detectar y reportar inconsistencias.

Una IA no podrá modificar unilateralmente decisiones arquitectónicas.

---

# 55. Regla de contradicciones para agentes

Si durante la implementación un agente encuentra una contradicción real entre:

* código;
* Prisma;
* OpenAPI;
* ADR;
* requerimiento;

aplicará F4 cuando ya resuelva la contradicción; solo detendrá la parte que requiera una nueva decisión arquitectónica.

El reporte deberá incluir:

```text
1. Qué intenta implementar
2. Qué decisión contradice
3. Qué documento establece la decisión
4. Cuál es la diferencia
5. Alternativas válidas
6. Impacto de cada alternativa
7. Recomendación
```

Solo las decisiones nuevas requieren validación del desarrollador; las correcciones autorizadas conforme a F4 continúan.

No podrá resolver una contradicción arquitectónica mediante una modificación silenciosa.

---

# 56. Pruebas de infraestructura

F4 deberá incluir pruebas mínimas para infraestructura crítica.

## Common

Se comprobará:

* requestId;
* response wrapper;
* error wrapper;
* validation.

## Auth

Se comprobará:

* login exitoso;
* login inválido;
* JWT inválido;
* usuario inactivo;
* tenant inválido;
* autorización.

## Multi-tenancy

Se comprobará:

* acceso válido al tenant;
* aislamiento entre tenants;
* intento de acceso cruzado;
* validación de membership;
* comportamiento del TenantContext.

## Rate limiting

Se comprobará:

* cinco intentos permitidos;
* sexto intento rechazado dentro de la ventana.

## Health

Se comprobará:

* `/health`;
* `/health/live`;
* `/health/ready`;
* disponibilidad de PostgreSQL para readiness.

---

# 57. Health

Se implementarán:

```text
GET /health
GET /health/live
GET /health/ready
```

Los endpoints serán públicos.

Conceptualmente:

```text
/health
→ estado general

/health/live
→ proceso vivo

/health/ready
→ aplicación preparada + PostgreSQL disponible
```

Las dependencias externas no serán requisito obligatorio para declarar readiness durante F4.

---

# 58. Scripts oficiales

El `package.json` deberá proporcionar como mínimo:

```text
npm run start:dev
npm run build
npm run start
npm run test
npm run test:e2e
npm run lint
npm run format
npm run prisma:generate
npm run prisma:migrate
npm run prisma:seed
```

`start:prod` no forma parte de la definición de F4.

Su comportamiento definitivo podrá establecerse posteriormente junto con la configuración productiva.

---

# 59. Orden de implementación

El orden previsto será:

```text
F4-S0
Preparación
        ↓
F4-S1
Bootstrap
        ↓
F4-S2
Config + Prisma
        ↓
F4-S3
Common
        ↓
F4-S4
Modelo Auth / Roles / TenantContext
        ↓
F4-S5
Auth
        ↓
F4-S6
Users
        ↓
F4-S7
Módulos funcionales vacíos
        ↓
F4-S8
Pruebas
        ↓
F4-S9
Documentación
        ↓
F4-S10
Auditoría final + handoff
```

La corrección del modelo Prisma relacionada con roles deberá realizarse antes de completar Auth/Users.

---

# 60. Checkpoints

La implementación se ejecutará por bloques.

Cada bloque deberá:

```text
implementar
    ↓
ejecutar pruebas
    ↓
verificar criterios
    ↓
revisar resultado
    ↓
checkpoint
    ↓
continuar
```

El agente podrá trabajar autónomamente dentro del bloque autorizado.

Los checkpoints permanecerán bajo control del desarrollador.

---

# 61. Criterios de aceptación

La lista siguiente define criterios normativos, no resultados ejecutados. La evidencia y el veredicto se registran en `Docs/Auditorias/Fase4-Auditoria-Profunda-PostCodex.md`. Cerrar decisiones no certifica automáticamente su implementación.

F4 se considerará implementada cuando se cumplan los criterios siguientes.

## Proyecto

```text
[ ] proyecto compila
[ ] lint limpio
[ ] formatting consistente
[ ] Prisma funcional
[ ] configuración validada
[ ] variables obligatorias verificadas
```

## Infraestructura

```text
[ ] health funcionando
[ ] requestId funcionando
[ ] logging funcionando
[ ] errores normalizados
[ ] responses normalizadas
[ ] ValidationPipe funcionando
[ ] CORS funcionando
[ ] Helmet funcionando
[ ] TenantContext funcionando
```

## Autenticación

```text
[ ] JWT funcionando
[ ] login funcionando
[ ] logout funcionando
[ ] select-tenant funcionando
[ ] /auth/me funcionando
[ ] RolesGuard funcionando
[ ] @Public funcionando
[ ] @Roles funcionando
[ ] @CurrentUser funcionando
[ ] password policy funcionando
[ ] bcrypt funcionando
[ ] rate limiting funcionando
```

## Multi-tenancy

```text
[ ] modelo User / UserTenant / Role corregido
[ ] ADMIN global funcionando
[ ] OWNER/MEMBER tenant-scoped funcionando
[ ] TenantContext funcionando
[ ] aislamiento tenant-scoped funcionando
[ ] tests de tenant isolation pasando
[ ] login multi-tenant funcionando
```

## Persistencia

```text
[ ] PrismaService funcionando
[ ] seed funcionando
[ ] seed idempotente
[ ] ADMIN inicial creado correctamente
```

## Users

```text
[ ] CRUD funcionando
[ ] desactivación lógica funcionando
[ ] UserTenant funcionando
[ ] operaciones de roles funcionando
```

## Módulos

```text
[ ] Common terminado
[ ] Auth terminado
[ ] Users terminado
[ ] Tenants creado
[ ] Campaigns creado
[ ] Prospects creado
[ ] ProspectingJobs creado
[ ] ProspectorClient creado
[ ] módulos registrados en AppModule
```

## Testing

```text
[ ] tests unitarios mínimos
[ ] tests de infraestructura
[ ] tests de autenticación
[ ] tests de autorización
[ ] tests de tenant isolation
[ ] tests de validation
[ ] tests de rate limiting
[ ] tests E2E mínimos
```

## Documentación

```text
[ ] README actualizado
[ ] MODULE-DEVELOPMENT.md completo
[ ] Implementation Plan completo
[ ] criterios de aceptación verificados
[ ] handoff preparado
```

---

# 62. Entregables de F4

El Implementation Plan fue un artefacto externo ejecutado; no es obligatorio versionarlo para cerrar F4. La copia disponible está en `Docs/Auditorias/PlanDeImplementacionFase4.md`. Aporta intención y trazabilidad, subordinada a este ADR y al registro F4.

Los entregables mínimos serán:

```text
Platform Backend baseline
        +
Prisma actualizado
        +
Common
        +
Auth
        +
Users
        +
Health
        +
Tests
        +
README
        +
MODULE-DEVELOPMENT.md
        +
Implementation Plan
        +
Handoff
```

Los módulos funcionales que todavía no correspondan a F4 quedarán únicamente preparados.

---

# 63. Handoff a Ángel

El backend deberá quedar preparado para que Ángel pueda comenzar el desarrollo funcional sin reinterpretar la arquitectura.

El handoff deberá proporcionar:

```text
Repositorio
+
ADRs
+
OpenAPI
+
Prisma
+
Implementation Plan
+
MODULE-DEVELOPMENT.md
+
convenciones
+
criterios de aceptación
```

Ángel deberá poder comenzar sobre el baseline existente.

No deberá ser necesario rediseñar:

* autenticación;
* autorización;
* TenantContext;
* Prisma;
* responses;
* errores;
* validation;
* logging;
* estructura modular.

---

# 64. Autonomía del agente de IA

El agente podrá trabajar de forma autónoma dentro de bloques definidos.

El flujo será:

```text
Leer documentación
      ↓
Implementar
      ↓
Ejecutar pruebas
      ↓
Corregir errores técnicos
      ↓
Reportar
      ↓
Checkpoint
      ↓
Continuar
```

El agente podrá corregir errores técnicos propios de la implementación.

No podrá modificar una decisión arquitectónica para conseguir que una implementación compile o pase pruebas.

---

# 65. Decisiones que no deben reabrirse

Las siguientes decisiones quedan cerradas para F4:

```text
JWT Bearer
JWT de 8 horas
HS256
sin refresh token
sin JWT blacklist
sin OAuth2
RBAC
ADMIN global
OWNER/MEMBER tenant-scoped
UserTenant.roleId
User.platformRole
sin User.roleId
sin system tenant
Shared Database
Shared Schema
tenantId
Passport + JWT Strategy
TenantContext
AsyncLocalStorage
JWT como snapshot de autorización
sin consulta UserTenant en cada request
tenant isolation mediante Services
sin Prisma Middleware obligatorio
sin Prisma Extension obligatoria
sin Repository Pattern obligatorio
X-API-Key entre Platform y Prospector
bcrypt cost 12
password policy
rate limiting 5/60s/IP
sin Redis
stateless logout
@Public()
@Roles()
@CurrentUser()
ValidationPipe
whitelist
forbidNonWhitelisted
transform
response wrapper
error normalization
requestId
Pino
ESLint
Prettier
PrismaService singleton
Prisma desde Services
seed idempotente
módulos Nest vacíos
Common independiente de Auth
IA sin autoridad arquitectónica
```

Estas decisiones únicamente podrán reabrirse mediante una nueva decisión formal si aparece:

* una contradicción técnica real;
* un nuevo requerimiento;
* una vulnerabilidad;
* una modificación arquitectónica;
* una limitación comprobada de implementación.

---

# 66. Cambios arquitectónicos derivados de la auditoría de F4

Durante la consolidación final de F4 se identificó una incompatibilidad entre el modelo Prisma inicial y la semántica de roles definida por la arquitectura.

El modelo inicial utilizaba:

```text
User.roleId
```

mientras que la arquitectura requería que un mismo usuario pudiera tener diferentes roles en diferentes tenants.

La resolución aprobada es:

```text
User
└── platformRole?

UserTenant
└── roleId

Role
└── tenantId
```

Esta corrección no constituye una nueva capacidad de negocio.

Constituye la adecuación del modelo de persistencia a una decisión de autorización ya establecida.

---

# 67. Decisión final de autorización

El modelo definitivo de autorización es:

```text
                    User
                     │
             ┌───────┴────────┐
             │                │
       platformRole       UserTenant
             │                │
           ADMIN        ┌─────┴─────┐
                        │           │
                     tenantId    roleId
                                    │
                                  Role
                                    │
                              OWNER | MEMBER
```

Por lo tanto:

```text
ADMIN
→ autoridad global

OWNER
→ rol tenant-scoped

MEMBER
→ rol tenant-scoped
```

La plataforma no utilizará un único campo `role` para representar ambos niveles de autoridad.

---

# 68. Decisión final de contexto

El contexto autenticado se representa conceptualmente como:

```text
AuthenticatedContext
├── userId
├── email
├── platformRole?
├── tenantId?
└── tenantRole?
```

Ejemplo de usuario normal:

```text
userId       = user-123
platformRole = null
tenantId     = tenant-a
tenantRole   = OWNER
```

Ejemplo de ADMIN global:

```text
userId       = user-999
platformRole = ADMIN
tenantId     = null
tenantRole   = null
```

Ejemplo de ADMIN operando sobre un tenant:

```text
userId       = user-999
platformRole = ADMIN
tenantId     = tenant-a
tenantRole   = null
```

Esta representación evita mezclar autoridad global con rol tenant-scoped.

---

# 69. Decisión final de aislamiento

La estrategia definitiva será:

```text
JWT
 ↓
Authentication
 ↓
TenantContext
 ↓
Tenant-aware Service
 ↓
Prisma query
 ↓
PostgreSQL
```

No se delegará completamente el aislamiento a una capa automática de Prisma.

La prevención del error humano se realizará mediante:

```text
TenantContext
+
helpers
+
conventions
+
MODULE-DEVELOPMENT.md
+
tests
+
review
```

La solución se considera suficiente para el MVP y consistente con el principio de mínima ingeniería.

---

# 70. Resultado esperado

Al finalizar F4, el Platform Backend deberá disponer de una infraestructura estable:

```text
                 Platform Backend
                        │
                 ┌──────▼──────┐
                 │    Common   │
                 └──────┬──────┘
                        │
              ┌─────────┴─────────┐
              │                   │
             Auth               Users
              │                   │
              └─────────┬─────────┘
                        │
                 Infraestructura
                        │
       ┌────────────────┼────────────────┐
       │                │                │
    Tenants         Campaigns        Prospects
       │                │                │
       └────────────────┼────────────────┘
                        │
                ProspectingJobs
                        │
                ProspectorClient
```

Los módulos funcionales serán implementados posteriormente sobre este baseline.

---

# 71. Resultado de Fase 4

F4 establece definitivamente:

```text
F1 = qué existe
F2 = cómo se comporta
F3 = cómo se protege
F4 = cómo se implementa
```

El resultado de F4 será un Platform Backend preparado para que los módulos funcionales puedan ser implementados por otros desarrolladores o agentes de IA sin reinterpretar las decisiones arquitectónicas transversales.

---

# 72. Cierre formal

Con la resolución de las decisiones F4-C01 a F4-C07:

```text
F4-C01 → ADMIN global
F4-C02 → roles por tenant
F4-C03 → contexto JWT
F4-C04 → login multi-tenant
F4-C05 → snapshot de autorización
F4-C06 → AsyncLocalStorage
F4-C07 → tenant isolation con mitigaciones
```

se consideran cerradas las decisiones arquitectónicas pendientes identificadas durante la auditoría de Fase 4.

En consecuencia:

* `F4-ARCH-01` queda resuelto.
* `F4-ARCH-02` queda resuelto.
* No existe un `system tenant`.
* `User.roleId` queda eliminado.
* `User.platformRole` queda establecido.
* `UserTenant.roleId` queda establecido.
* `RoleName` queda limitado a `OWNER` y `MEMBER`.
* `ADMIN` queda fuera del modelo `Role`.
* `TenantContext` utilizará AsyncLocalStorage.
* Tenant isolation utilizará consultas tenant-aware desde Services.
* Prisma Middleware/Extension no es obligatorio.
* Repository Pattern no es obligatorio.
* El JWT será snapshot del contexto de autorización.
* No se consultará `UserTenant` en cada request únicamente para reconstruir el rol.

Los detalles internos restantes de código, nombres concretos de helpers, organización de archivos y mecanismos equivalentes de implementación podrán resolverse durante la ejecución de F4 siempre que respeten este ADR.

---

# 73. Estado final del ADR

**Estado:** ACEPTADO / CERRADO

**Fase:** Fase 4 — Implementación de infraestructura y baseline

**Resultado:** APROBADO PARA IMPLEMENTACIÓN

El ADR-004 queda cerrado como referencia arquitectónica de la infraestructura transversal y baseline del Platform Backend.

A partir de este punto, la actividad principal pasa de:

```text
diseño y decisión
```

a:

```text
implementación
+
testing
+
documentación
+
auditoría
+
handoff
```

Cualquier modificación posterior que contradiga este ADR deberá tratarse como una nueva decisión arquitectónica y no como una modificación silenciosa durante la implementación.
