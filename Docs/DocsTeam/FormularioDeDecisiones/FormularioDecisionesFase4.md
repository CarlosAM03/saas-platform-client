# Registro de decisiones — Fase 4

> Nota de vigencia: este documento es histórico o conceptual. No sustituye ADR-004, el contrato OpenAPI, FormularioDecisionesFase5.md ni ADR-005-FlutterFoundation.md. En caso de contradicción, prevalecen los documentos normativos vigentes.

## Implementación de infraestructura y baseline del Platform Backend

**Proyecto:** Plataforma SaaS
**Fase:** Fase 4 — Implementación de infraestructura y baseline
**Propósito del documento:** Registro formal de respuestas, decisiones, restricciones y pendientes derivados del formulario de Fase 4.
**Naturaleza:** Documento de registro y control de decisiones. No sustituye al ADR-004.
**Estado:** Decisiones cerradas por ADR-004; verificación de implementación en la auditoría profunda.

## Consolidación vigente F4

ADR-004 prevalece. Los estados parciales del formulario original que se conserva abajo son históricos, superseded por F4-C01–C07, no decisiones pendientes actuales. Common usa @nestjs/config (11 variables de ADR-004 §11), PrismaService singleton, AsyncLocalStorage y consultas tenant-aware explícitas sin middleware Prisma ni Repository obligatorio. ADMIN es global; RoleName solo OWNER/MEMBER; UserTenant.roleId reemplaza User.roleId. JWT HS256 de 8h como snapshot, sin consultas de membership por request.

Se conserva la excepción autorizada de cinco READMEs locales; AGENTS no es obligatorio. El Implementation Plan externo fue ejecutado, no se exige dentro del repo y ahora existe copia en Docs/Auditorias/PlanDeImplementacionFase4.md. roleId opcional/default MEMBER está respaldado por su bloque 5 y consolidado en ADR-004 §45. Auth POST responde 200; CRUD Users opera sobre tenant seleccionado. Swagger sirve /api/docs.

## Formulario original — evidencia histórica

Las decisiones compatibles se conservan; las opciones abiertas, pendientes y restricciones contradictorias de este registro original no gobiernan sobre la consolidación anterior.

---

# 1. Propósito

Este documento consolida las respuestas proporcionadas al formulario de decisiones de Fase 4.

Su objetivo es mantener un registro limpio y verificable de:

* decisiones explícitamente tomadas;
* decisiones heredadas;
* restricciones de implementación;
* recomendaciones aceptadas;
* decisiones parcialmente cerradas;
* puntos pendientes de precisión;
* cuestiones que deberán resolverse antes o durante la implementación.

Este documento existe de forma independiente al flujo principal de auditoría arquitectónica.

El ADR-004 existente continúa siendo el documento arquitectónico de referencia. Este registro sirve como **fuente operacional de las respuestas utilizadas para preparar la implementación de Fase 4**.

---

# 2. Principio rector de Fase 4

La Fase 4 no introduce nuevas capacidades de negocio.

Su objetivo es convertir las decisiones establecidas en Fases 1–3 y los contratos definidos en Fase 2 en una infraestructura NestJS:

* concreta;
* consistente;
* reutilizable;
* segura;
* testeable;
* documentada;
* preparada para implementación por terceros o agentes de IA.

La implementación posterior de módulos funcionales no deberá requerir reinterpretar la arquitectura previamente definida.

---

# 3. F4-01 — Alcance de implementación

## Decisión

Fase 4 implementará el baseline técnico necesario para dejar el backend preparado para el desarrollo de los módulos funcionales.

## Incluido

Se implementará:

* configuración base;
* módulo Common;
* módulo Auth;
* módulo Users;
* Prisma base;
* Health;
* Logger;
* Error Handling;
* Response Handling;
* Validation;
* Security transversal;
* pruebas de infraestructura;
* documentación;
* estructura física y módulos Nest de los módulos funcionales que desarrollará Ángel.

## Módulos que deberán quedar preparados

```text
Common
Auth
Users
Tenant
Campaigns
Prospects
ProspectingJobs
ProspectorClient
Prisma
```

Los módulos funcionales que todavía no serán implementados deberán existir como estructura real de NestJS.

## Explícitamente fuera de F4

No se implementará:

* funcionalidad completa de Tenants;
* Campaigns;
* Prospects;
* Prospecting Jobs;
* cliente real de Prospector Service;
* Flutter;
* integración funcional con Prospector Service;
* Docker;
* Redis;
* colas;
* workers;
* observabilidad avanzada;
* auditoría completa;
* CI/CD;
* deployment.

## Estado

CERRADA.

---

# 4. F4-02 — Estructura del proyecto NestJS

## Decisión

Se utilizará una arquitectura modular por dominio.

La estructura principal estará organizada dentro de `src`.

Los módulos contemplados son:

```text
src/
├── common/
├── auth/
├── users/
├── tenant/
├── campaigns/
├── prospects/
├── prospecting-jobs/
├── prospector-client/
└── prisma/
```

La nomenclatura física definitiva podrá ajustarse a las convenciones ya establecidas en el repositorio.

## Separación interna

Los módulos mantendrán separación interna por responsabilidad.

Se contemplan responsabilidades como:

```text
controllers
services
DTOs
module
```

y cualquier otra separación que resulte necesaria dentro del dominio.

## Archivos de módulo

Cada módulo utilizará su propio archivo:

```text
*.module.ts
```

incluso cuando inicialmente no tenga funcionalidad completa.

## Módulos vacíos de Ángel

Los módulos no serán únicamente carpetas vacías.

Cada módulo deberá contar con:

* carpeta;
* módulo NestJS;
* registro en `AppModule`.

Esto permitirá que Ángel reciba un backend con un esqueleto real sobre el cual trabajar.

## Estado

CERRADA.

---

# 5. F4-03 — main.ts y AppModule

## main.ts

`main.ts` será responsable del bootstrap global de la aplicación.

Se centralizarán en él las configuraciones globales correspondientes a:

* ValidationPipe;
* global filters;
* global interceptors;
* CORS;
* Helmet;
* prefijo global;
* bootstrap;
* shutdown hooks.

## Prefijo global

Se utilizará un prefijo global conforme al contrato OpenAPI existente.

No se modificará arbitrariamente el contrato para adaptarlo a la implementación.

## CORS

CORS será configurable mediante variables de entorno.

No se hardcodeará el origen permitido.

## Helmet

Helmet se utilizará globalmente.

## Estado

CERRADA.

---

# 6. F4-04 — Configuración y variables de entorno

## Decisión

No se permitirá hardcodear credenciales, secretos ni configuraciones sensibles dentro del código.

Las configuraciones sensibles deberán provenir del entorno.

## Variables obligatorias

Se identificaron como variables obligatorias:

```text
NODE_ENV
PORT
DATABASE_URL
JWT_SECRET
JWT_EXPIRES_IN
PROSPECTOR_SERVICE_URL
PROSPECTOR_API_KEY
CORS_ORIGINS
```

Además, deberán existir variables para las credenciales iniciales del usuario administrador global utilizado por el seed.

La nomenclatura exacta de estas variables deberá quedar definida durante la implementación.

## Validación al arrancar

Si falta una variable crítica, la aplicación no deberá arrancar.

Particularmente:

```text
DATABASE_URL
JWT_SECRET
PROSPECTOR_API_KEY
```

son consideradas configuraciones críticas.

## Mecanismo de configuración

Aquí existe una decisión **parcialmente abierta**.

Se contemplaron dos posibilidades:

### Opción A

Utilizar un módulo/archivo de configuración centralizado.

### Restricción

Independientemente de la opción elegida:

**ninguna credencial deberá estar hardcodeada.**

## Ubicación de la regla de configuración

Se consideró inicialmente colocar la configuración en la raíz o dentro de Common.

Esto debe alinearse con la solución final de configuración que se adopte.

## Estado

PARCIALMENTE CERRADA.

---

# 7. F4-05 — Prisma

## Decisión

Se utilizará `PrismaService` basado en `PrismaClient`.

La instancia de Prisma será compartida por los módulos del backend.

## Singleton

Se utilizará una única instancia de Prisma durante el MVP.

No se crearán múltiples instancias independientes por tenant.

La razón es que el modelo utiliza:

```text
Shared Database
+
Shared Schema
+
tenantId
```

por lo que los tenants no requieren conexiones independientes.

## Acceso a Prisma

La intención establecida es que el acceso directo a Prisma quede restringido a los Services.

Los DTOs no deberán acceder a Prisma.

Los Controllers tampoco deberán acceder directamente a Prisma.

## Repositories

Todavía no se ha establecido que exista obligatoriamente una capa Repository.

Por lo tanto, la decisión actual es:

```text
Service
  ↓
PrismaService
  ↓
Prisma
```

La incorporación de Repository Layer queda como una decisión de implementación únicamente si resulta necesaria y no contradice la arquitectura.

## Estado

CERRADA con una precisión pendiente sobre aislamiento multi-tenant.

---

# 8. F4-06 — Tenant isolation y acceso a datos

## Problema

La arquitectura utiliza una base de datos y schema compartidos.

Por lo tanto, el backend debe impedir que una operación de un tenant acceda accidentalmente a información de otro.

Se quiere evitar depender exclusivamente de que cada desarrollador recuerde escribir manualmente el `tenantId` en todas las consultas.

## Opciones consideradas

Se identificaron:

1. filtros explícitos desde cada Service;
2. TenantContext;
3. Prisma middleware;
4. Prisma Extension;
5. Repository Layer;
6. combinación de mecanismos.

## Decisión conceptual

Se utilizará un **TenantContext transversal** como fuente del tenant autorizado.

Los servicios que trabajen con datos multi-tenant deberán operar dentro de dicho contexto.

## Decisión pendiente

No quedó cerrada al 100 % la técnica exacta mediante la cual `TenantContext` se traducirá en restricciones automáticas de Prisma.

Quedan abiertas:

```text
TenantContext
      ↓
Services
      ↓
Prisma con tenantId explícito
```

o alguna forma de encapsulación adicional mediante:

```text
Prisma Extension
```

o:

```text
Repository Layer
```

o:

```text
otro mecanismo transversal
```

## Restricción

No se permitirá confiar en un `tenantId` arbitrario enviado por el cliente.

El contexto debe provenir de la autenticación.

## Prioridad

La solución debe:

1. ser segura;
2. ser simple;
3. reducir errores humanos;
4. evitar sobreingeniería;
5. ser rápida de implementar;
6. permitir que Ángel trabaje independientemente.

## Pendiente F4-P02

Cerrar la implementación concreta de aislamiento Prisma/TenantContext antes de delegar módulos multi-tenant.

## Estado

PARCIALMENTE CERRADA.

---

# 9. F4-07 — TenantContext

## Decisión conceptual

El backend tendrá un contexto transversal de tenant.

El contexto será privado del backend y no será una propiedad que el cliente pueda modificar arbitrariamente.

## Información

El TenantContext contendrá como mínimo:

```text
tenantId
role
```

y el resto de información requerida por el contrato OpenAPI o por la implementación de autenticación.

La identidad del usuario forma parte del contexto autenticado y deberá estar disponible para las operaciones que lo requieran.

## Acceso

No se permitirá obtener el TenantContext fuera del contexto de una request.

No se expondrá directamente al cliente.

## Implementación técnica

Se consideraron:

* Request-scoped provider;
* AsyncLocalStorage;
* contexto asociado al objeto request.

No quedó completamente cerrada la técnica de implementación.

## Pendiente F4-P03

Seleccionar entre:

```text
Request Scope
```

o:

```text
AsyncLocalStorage
```

o una solución equivalente basada en request context.

## Criterio

La decisión deberá priorizar:

* simplicidad;
* bajo acoplamiento;
* compatibilidad con NestJS;
* facilidad de uso desde Services;
* ausencia de sobreingeniería.

## Estado

PARCIALMENTE CERRADA.

---

# 10. F4-08 — ADMIN global

## Decisión

El rol `ADMIN` es un rol global de plataforma.

No representa un usuario perteneciente a un tenant.

Los usuarios normales de los tenants utilizan:

```text
OWNER
MEMBER
```

El `ADMIN` tiene capacidad transversal sobre todos los tenants y módulos del Platform Backend.

## Restricción

No se creará un tenant ficticio o especial para representar al administrador global.

Tampoco se modificará innecesariamente el esquema Prisma existente únicamente para representar este rol.

## Modelo conceptual

```text
Global Platform
└── ADMIN
    └── acceso transversal

Tenant A
├── OWNER
└── MEMBER

Tenant B
├── OWNER
└── MEMBER
```

## TenantContext para ADMIN

El administrador global no deberá recibir automáticamente un `tenantId` como si perteneciera a un tenant normal.

El backend deberá permitir distinguir:

```text
global ADMIN
```

de:

```text
tenant-scoped OWNER/MEMBER
```

## Pendiente F4-P04

Definir la representación exacta de esta distinción dentro del código, sin modificar el modelo Prisma existente.

La solución deberá ser compatible con:

* AuthGuard;
* RolesGuard;
* TenantContext;
* autorización global;
* acceso transversal.

## Estado

DECIDIDA conceptualmente; IMPLEMENTACIÓN PENDIENTE.

---

# 11. F4-09 — Auth Module y JWT Strategy

## Decisión

Se utilizará:

```text
Passport
+
JWT Strategy
```

para la implementación de autenticación.

## Responsabilidades de JWT Strategy

La estrategia deberá participar en el pipeline de autenticación y validar que el usuario continúe activo.

La información del JWT será procesada para construir el contexto autenticado.

## Usuario activo

La existencia y estado activo del usuario deberá validarse como parte del flujo de autenticación.

Si el usuario ya no está activo, la autenticación deberá rechazarse.

## UserTenant

La validación de pertenencia al tenant se realizará mediante la lógica correspondiente al contexto de tenant.

Se consideró introducir un `UserTenantService` si la responsabilidad resulta demasiado grande para los componentes actuales.

## Estado

CERRADA conceptualmente.

La separación exacta entre:

```text
JWT Strategy
TenantContext
UserTenantService
```

queda como decisión de implementación mientras no se altere la arquitectura.

---

# 12. F4-10 — Login multi-tenant

## Decisión conceptual

Un usuario puede pertenecer a múltiples tenants.

Ejemplo:

```text
Usuario
├── Tenant A
└── Tenant B
```

El usuario podrá seleccionar con cuál tenant desea trabajar.

## Usuario con un tenant

Si el usuario tiene exactamente un tenant:

```text
Login
 ↓
JWT
 ↓
Acceso
```

El login podrá devolver directamente el JWT con el contexto correspondiente.

## Usuario con múltiples tenants

Si el usuario tiene múltiples tenants:

```text
Login
 ↓
Identificación del usuario
 ↓
Selección de tenant
 ↓
JWT del tenant seleccionado
```

El tenant activo formará parte del JWT.

## Select Tenant

`POST /auth/select-tenant` utilizará JWT para establecer el contexto del tenant seleccionado.

La selección deberá validarse mediante `UserTenant`.

## Contraseña por tenant

Se planteó la posibilidad de utilizar una contraseña diferente por tenant.

Esta idea **no queda adoptada** en Fase 4.

Se considera una complejidad adicional no diseñada previamente y no necesaria para el MVP actual.

## Pendiente F4-P05

Precisar el flujo exacto de login cuando un usuario tiene múltiples tenants:

* si el login inicial devuelve un token temporal/contextual;
* si se permite seleccionar tenant directamente después de autenticar identidad;
* payload exacto de la respuesta previa a la selección;
* comportamiento exacto de `/auth/select-tenant`.

La arquitectura general sí queda definida:

**un JWT final representa un tenant activo.**

## Estado

PARCIALMENTE CERRADA.

---

# 13. F4-11 — Usuario sin tenant

## Decisión

Un usuario autenticado que no tenga ningún `UserTenant` válido no podrá recibir un JWT operativo con contexto de tenant.

El usuario no podrá acceder al dominio funcional de la plataforma sin un tenant válido.

## Estado del tenant

Si el tenant requerido está suspendido, el acceso será rechazado.

## Estado

CERRADA conceptualmente.

El código HTTP exacto deberá mantenerse alineado con la política de autenticación/autorización de Fase 3 y los contratos OpenAPI.

---

# 14. F4-12 — Política de contraseñas

## Decisión

La política mínima será:

* mínimo 10 caracteres;
* al menos una letra;
* al menos un número;
* al menos un carácter especial.

## Unicode

No se restringirá artificialmente el conjunto de caracteres a ASCII.

Se permitirán caracteres Unicode.

## Estado

CERRADA.

---

# 15. F4-13 — Password hashing

## Decisión

Se utilizará:

```text
bcrypt
cost factor = 12
```

## Encapsulación

El hashing no quedará disperso dentro de los Services.

Se implementará mediante un servicio dedicado.

La responsabilidad de hashing/verificación deberá estar encapsulada para permitir reutilización y evitar duplicación.

## Estado

CERRADA.

---

# 16. F4-14 — Rate limiting

## Decisión

La protección contra intentos repetidos se aplicará específicamente a los mecanismos de autenticación.

No se desea introducir complejidad innecesaria mediante un sistema de rate limiting universal si actualmente no existe un requerimiento para ello.

## Estrategia

Se consideró inicialmente un rate limiter global, pero la decisión se orienta hacia un mecanismo específico para autenticación/login.

Se podrá implementar mediante:

* guard específico;
* interceptor;
* mecanismo equivalente.

La elección concreta dependerá de la solución más sencilla que mantenga el comportamiento requerido.

## Política

```text
Máximo:
5 intentos

Ventana:
60 segundos

Scope:
IP
```

## Exceso de límite

Cuando se exceda:

```text
HTTP 429 Too Many Requests
```

## Bloqueo por cuenta

No se implementará bloqueo temporal por cuenta durante el MVP.

## Almacenamiento

El estado del rate limit estará en memoria del proceso.

No se utilizará Redis para esta funcionalidad en F4.

## Estado

CERRADA funcionalmente.

### Pendiente F4-P06

Determinar la implementación exacta:

```text
Guard
```

vs.

```text
Interceptor
```

sin modificar la política establecida.

---

# 17. F4-15 — Guards y decoradores

## Decoradores confirmados

Se utilizarán:

```text
@Public()
@Roles(...)
@CurrentUser()
```

## Roles

La autorización utilizará metadata asociada a los roles definidos por el dominio.

La representación deberá ser compatible con el `RoleName` de Prisma.

## Roles no especificados

El comportamiento de endpoints que no declaren explícitamente `@Roles()` deberá respetar la arquitectura de autenticación y autorización definida en Fase 3.

No se deberá inferir automáticamente que todo endpoint pertenece a OWNER, ADMIN o MEMBER sin considerar el tipo de protección requerido.

## Estado

CERRADA conceptualmente.

---

# 18. F4-16 — Response wrapper

## Decisión

Las respuestas exitosas utilizarán un wrapper global.

La estructura base definida contempla:

```text
success
data
meta
```

## meta

`meta` no necesariamente aparecerá en todas las respuestas.

Se utilizará cuando exista información adicional relevante, por ejemplo:

* paginación;
* metadata operacional.

## data

El campo `data` contendrá la respuesta principal.

Cuando corresponda a una colección, podrá contener un array.

## 204 No Content

No se implementará una excepción conceptual al wrapper por decisión arquitectónica.

Sin embargo, el comportamiento HTTP real de `204 No Content` deberá respetar las reglas del protocolo HTTP.

## Estado

CERRADA conceptualmente.

### Pendiente F4-P07

Verificar que el comportamiento del interceptor no genere un body incompatible con una respuesta HTTP `204 No Content`.

---

# 19. F4-17 — Error handling

## Decisión

Los errores serán normalizados globalmente.

Los errores nativos de NestJS deberán transformarse al formato de error definido para la API.

## Alcance

Incluye:

* errores de aplicación;
* errores de NestJS;
* errores HTTP;
* errores inesperados.

## Error 500

Los errores internos deberán representarse como errores internos normalizados.

Durante desarrollo se permitirá disponer del stack trace para debugging.

En producción no deberán exponerse:

* stack trace;
* detalles internos;
* información sensible;
* implementación interna.

## Desarrollo

Durante la etapa de construcción se prioriza la capacidad de debugging.

Los errores internos no deberán ser silenciosos.

Tampoco deberán producir ruido innecesario fuera del mecanismo de logging establecido.

## Producción

La exposición de información interna deberá reducirse mediante configuración de entorno.

## Estado

CERRADA.

---

# 20. F4-18 — DTOs y Validation

## Decisión

Los DTOs permanecerán separados de Prisma.

Los DTOs representan contratos de entrada/salida de la API y no serán sustituidos por modelos de persistencia.

## Acceso a Prisma

Los DTOs no tendrán acceso a Prisma.

Los Services serán responsables de interactuar con Prisma.

## Validation

Se utilizará:

```text
class-validator
class-transformer
ValidationPipe
```

## Configuración

Se utilizará:

```text
whitelist: true
forbidNonWhitelisted: true
transform: true
```

## Comportamiento

Los campos no permitidos deberán rechazarse.

Los datos deberán transformarse conforme a las reglas de los DTOs.

## Error de validación

Una validación inválida producirá:

```text
HTTP 400
Validation Error
```

## Estado

CERRADA.

---

# 21. F4-19 — Libertad de Ángel dentro de los módulos

## Decisión

Ángel tendrá libertad de implementación dentro de los límites establecidos por la arquitectura.

Podrá decidir libremente:

* estructura interna de Services;
* queries específicas de Prisma;
* DTOs funcionales;
* reglas de negocio propias del módulo;
* organización interna;
* detalles de implementación.

## Restricciones

Ángel no podrá modificar unilateralmente:

* ADRs;
* decisiones arquitectónicas cerradas;
* contratos OpenAPI;
* modelo Prisma establecido;
* infraestructura transversal;
* reglas de seguridad;
* decisiones de Fases 1–3.

Si necesita realizar un cambio que contradiga una decisión existente, deberá detenerse y reportar la contradicción.

## Principio

La libertad de implementación existe dentro de la arquitectura, no por encima de ella.

## Estado

CERRADA.

---

# 22. F4-20 — Convenciones de código

## Linting y formatting

Se utilizarán:

```text
ESLint
Prettier
```

## Naming

Se mantendrá una convención consistente para Services y DTOs.

Ejemplos:

```text
createUserService
createUserDTO
deleteUserDTO
```

## DTO naming

Se decidió priorizar una convención tradicional basada en DTO.

Sin embargo, debido a que el contrato API ya utiliza una nomenclatura `.request.ts` en determinadas áreas, podrá mantenerse esa convención donde ya esté establecida.

No se considera una decisión arquitectónica.

## Estado

CERRADA como convención general.

---

# 23. F4-21 — Dependencias entre módulos

## Common

Common no dependerá de Auth.

Auth podrá utilizar Common.

```text
Common
   ↑
Auth
```

No se permitirán dependencias circulares.

## Auth / Users

Auth requiere información de Users para autenticar usuarios.

Users no deberá depender de Auth de manera que produzca una dependencia circular.

La separación exacta deberá diseñarse de modo que las responsabilidades permanezcan desacopladas.

## Regla

La solución que evite dependencia circular será la válida.

## Estado

CERRADA como principio arquitectónico.

### Pendiente F4-P08

Precisar la dependencia concreta entre Auth y Users en código, especialmente alrededor de:

* `UserService`;
* `AuthService`;
* `UserTenantService`;
* estrategias de Passport.

---

# 24. F4-22 — Prisma Service y módulos

## Decisión

El acceso a Prisma se realizará mediante `PrismaService`.

La instancia será compartida.

Los Services serán los consumidores directos de Prisma.

No se permitirá acceso directo desde:

* Controllers;
* DTOs;
* Guards;
* interceptors;

salvo que una responsabilidad transversal específicamente definida lo requiera.

## Estado

CERRADA.

---

# 25. F4-23 — Prisma Seed

## Decisión

Se implementará un Prisma Seed.

El seed será idempotente.

Esto significa que:

```text
seed
 ↓
¿dato existe?
 ├── sí → no duplicar
 └── no → crear
```

Ejecutar el seed múltiples veces no deberá producir duplicados.

## Usuario inicial

El seed deberá crear el usuario administrador global inicial.

Este usuario utilizará las credenciales definidas mediante variables de entorno.

## Roles

Los roles forman parte del modelo Prisma existente.

El seed deberá respetar dicho modelo.

## ADMIN

El usuario inicial será un administrador global.

No necesitará pertenecer a un tenant.

## Mensajes

El seed deberá informar claramente si:

* creó un registro;
* detectó que ya existía;
* omitió una operación por idempotencia.

## Estado

CERRADA conceptualmente.

### Pendiente F4-P09

Precisar:

* nombres exactos de variables de entorno del administrador;
* criterio exacto de identificación/upsert del usuario;
* campos mínimos obligatorios para el usuario ADMIN;
* comportamiento exacto cuando las credenciales del seed no están presentes.

---

# 26. F4-24 — Scripts oficiales de desarrollo

## Decisión

El `package.json` deberá proporcionar como mínimo scripts equivalentes a:

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

La nomenclatura exacta deberá seguir la convención válida de npm y la existente en el repositorio.

## Producción

Se contempla posteriormente:

```text
npm run start:prod
```

pero no se considera necesario cerrar ahora su comportamiento definitivo.

La estrategia de producción será definida junto con la configuración de entorno y deployment.

## Estado

CERRADA para desarrollo.

### Pendiente F4-P10

Definir exactamente cómo se resolverá la carga de `.env` y configuración cuando se implemente `start:prod`.

---

# 27. F4-25 — Módulos vacíos para Ángel

## Decisión

Se crearán físicamente y como módulos NestJS:

```text
Tenant
Campaigns
Prospects
ProspectingJobs
ProspectorClient
```

No se implementará funcionalidad de negocio en ellos durante F4.

## README por módulo

No se creará un README independiente para cada módulo.

La documentación estará centralizada.

## OpenAPI

Los endpoints de OpenAPI no se duplicarán innecesariamente en READMEs individuales.

El contrato OpenAPI existente será la fuente de verdad correspondiente.

## Estado

CERRADA.

---

# 28. F4-26 — Module Development Guide

## Decisión

Se creará una guía centralizada para desarrollo de módulos.

Esta guía deberá servir tanto para Ángel como para los agentes de IA que utilice.

La guía deberá explicar:

* estructura esperada;
* restricciones;
* convenciones;
* flujo de implementación;
* uso de OpenAPI;
* uso del modelo Prisma;
* reglas multi-tenant;
* reglas de seguridad;
* pruebas;
* criterios para reportar inconsistencias.

## Objetivo

El repositorio deberá ser **AI-friendly**.

Un agente que entre al repositorio deberá poder entender:

```text
qué está decidido
qué puede modificar
qué no puede modificar
qué documentos debe leer
cómo implementar
cuándo detenerse
cómo reportar contradicciones
```

## Estado

CERRADA.

---

# 29. F4-27 — Autonomía del agente de IA

## Decisión

El agente podrá trabajar de forma altamente autónoma.

Sin embargo, trabajará por bloques con checkpoints.

## Para implementación de Common / Auth / Users

El flujo será conceptualmente:

```text
Leer documentación
 ↓
Implementar bloque
 ↓
Ejecutar tests
 ↓
Corregir errores técnicos
 ↓
Reportar resultado
 ↓
Checkpoint humano
 ↓
Siguiente bloque
```

## Para Ángel

Ángel podrá utilizar agentes de IA para implementar módulos funcionales.

El agente deberá:

1. leer ADRs;
2. leer OpenAPI;
3. leer Prisma;
4. leer `F4 Implementation Plan`;
5. leer `Module Development Guide`;
6. implementar el módulo;
7. ejecutar tests;
8. corregir errores técnicos;
9. reportar resultados;
10. esperar validación cuando corresponda;
11. continuar con el siguiente módulo.

## Prohibiciones del agente

La IA:

* NO puede modificar ADRs;
* NO puede cambiar decisiones arquitectónicas;
* NO puede reinterpretar unilateralmente contratos;
* NO puede modificar el modelo Prisma por conveniencia;
* NO puede ignorar restricciones documentadas.

## Contradicciones

Si encuentra una contradicción real entre:

* código;
* OpenAPI;
* Prisma;
* ADR;
* implementación solicitada;

deberá detenerse.

Deberá explicar:

1. qué intenta implementar;
2. qué documento contradice;
3. cuál es la diferencia;
4. qué alternativas existen;
5. qué decisión necesita del desarrollador.

Después deberá esperar una validación.

## Estado

CERRADA.

---

# 30. F4-28 — Modificación de decisiones por IA

## Decisión

Una IA no tiene autoridad para modificar decisiones arquitectónicas.

Una IA puede:

* implementar;
* analizar;
* detectar inconsistencias;
* reportar riesgos;
* proponer alternativas.

Una IA no puede:

* modificar ADRs;
* cerrar decisiones;
* abrir excepciones por iniciativa propia;
* alterar contratos arquitectónicos.

## Estado

CERRADA.

---

# 31. F4-29 — Sprint personal de implementación

## Secuencia prevista

El trabajo personal de F4 se organizará aproximadamente así:

```text
1. Preparación
2. Bootstrap del proyecto
3. Configuración
4. Prisma
5. Common
6. Auth
7. Users
8. Módulos vacíos
9. Pruebas
10. Documentación
11. Auditoría final
12. Handoff
```

## Checkpoints

Se mantendrán checkpoints después de bloques relevantes.

Especialmente:

```text
Common
 ↓
revisión/tests
 ↓
Auth
 ↓
revisión/tests
 ↓
Users
 ↓
revisión/tests
```

El objetivo es mantener control arquitectónico sin eliminar la autonomía del agente.

## Estado

CERRADA.

---

# 32. F4-30 — Criterio de finalización de Fase 4

F4 se considerará terminada cuando se cumplan como mínimo los siguientes criterios.

## Proyecto

* [ ] El proyecto compila.
* [ ] Lint limpio.
* [ ] Formatting consistente.
* [ ] Prisma funcional.
* [ ] Configuración validada.
* [ ] Variables obligatorias validadas.

## Infraestructura

* [ ] Health funcionando.
* [ ] Logger funcionando.
* [ ] Request ID funcionando.
* [ ] Error handling global funcionando.
* [ ] Response wrapper funcionando.
* [ ] Validation global funcionando.
* [ ] Security transversal funcionando.

## Autenticación

* [ ] JWT funcionando.
* [ ] Login funcionando.
* [ ] Logout funcionando.
* [ ] Select Tenant funcionando.
* [ ] `/auth/me` funcionando.
* [ ] Roles funcionando.
* [ ] TenantContext funcionando.
* [ ] Validación de UserTenant funcionando.
* [ ] Rate limiting funcionando.
* [ ] Política de passwords funcionando.
* [ ] bcrypt funcionando.

## Persistencia

* [ ] Prisma Service funcionando.
* [ ] Seed funcionando.
* [ ] Seed idempotente.
* [ ] Usuario ADMIN inicial creado correctamente.

## Módulos

* [ ] Common terminado.
* [ ] Auth terminado.
* [ ] Users terminado.
* [ ] Módulos funcionales vacíos creados.
* [ ] Módulos registrados en AppModule.

## Testing

* [ ] Tests mínimos pasando.
* [ ] Tests de infraestructura.
* [ ] Tests de autenticación.
* [ ] Tests de autorización.
* [ ] Tests de tenant isolation.
* [ ] Tests de validation.
* [ ] Tests de rate limiting.
* [ ] Tests E2E mínimos.

Los reportes deberán ser suficientemente legibles para una persona.

## Documentación

* [ ] Documentación actualizada.
* [x] No existe un artefacto separado obligatorio de Implementation Plan; el plan conceptual queda integrado en ADR-004 y este registro.
* [ ] Module Development Guide.
* [ ] Handoff.
* [ ] Criterios de aceptación verificados.

## Estado

CERRADA.

---

# 33. F4-31 — Handoff a Ángel

El backend deberá quedar preparado para que Ángel pueda comenzar el desarrollo funcional sin tener que reinterpretar la arquitectura.

Ángel deberá recibir:

```text
Repositorio
+
ADRs
+
OpenAPI
+
Prisma
+
F4 Implementation Plan
+
Module Development Guide
+
convenciones
+
criterios de aceptación
```

El objetivo es que Ángel pueda comenzar directamente desde el baseline sin necesidad de rediseñar:

* autenticación;
* autorización;
* tenant context;
* Prisma;
* errores;
* responses;
* validation;
* logging;
* estructura modular.

## Estado

CERRADA como objetivo.

---

# 34. Registro de pendientes

Estos son los puntos que **no deben considerarse cerrados artificialmente** a partir de las respuestas.

| ID     | Pendiente                                   | Prioridad | Motivo                                                        |
| ------ | ------------------------------------------- | --------: | ------------------------------------------------------------- |
| F4-P01 | Mecanismo exacto de configuración           |     Media | No se seleccionó explícitamente ConfigModule vs `process.env` |
| F4-P02 | Implementación concreta de tenant isolation |      Alta | Falta decidir Prisma explícito vs Extension/Repository        |
| F4-P03 | Implementación concreta de TenantContext    |      Alta | Request Scope vs AsyncLocalStorage vs equivalente             |
| F4-P04 | Representación de ADMIN global              |      Alta | Concepto cerrado, implementación aún pendiente                |
| F4-P05 | Flujo exacto de login multi-tenant          |      Alta | Falta definir respuesta intermedia/token de selección         |
| F4-P06 | Implementación exacta de rate limiting      |     Media | Guard vs interceptor                                          |
| F4-P07 | Compatibilidad wrapper / 204                |     Media | Debe verificarse comportamiento HTTP                          |
| F4-P08 | Dependencia concreta Auth ↔ Users           |     Media | Debe evitarse dependencia circular                            |
| F4-P09 | Detalles exactos del seed ADMIN             |     Media | Faltan variables/campos/criterio de upsert                    |
| F4-P10 | `start:prod` y carga de configuración       |      Baja | Producción fuera del alcance inmediato                        |

---

# 35. Pendientes que NO deberían reabrirse

Las siguientes cuestiones no deben volver a convertirse en decisiones arquitectónicas salvo que aparezca una incompatibilidad real:

* JWT Bearer.
* JWT de 8 horas.
* Sin refresh token.
* Sin OAuth2.
* HS256.
* RBAC.
* OWNER/MEMBER para usuarios tenant.
* ADMIN global.
* Shared DB + Shared Schema + tenantId.
* X-API-Key Platform → Prospector.
* X-API-Key Prospector → Platform.
* bcrypt cost 12.
* password policy.
* rate limit de 5 intentos / 60 segundos / IP.
* stateless logout.
* TenantContext como concepto.
* roles en JWT.
* tenantId en JWT.
* Passport + JWT Strategy.
* guards globales.
* `@Public()`.
* `@Roles()`.
* `@CurrentUser()`.
* ValidationPipe.
* `whitelist: true`.
* `forbidNonWhitelisted: true`.
* `transform: true`.
* response wrapper.
* error normalization.
* Request ID.
* ESLint.
* Prettier.
* PrismaService singleton.
* Prisma como acceso desde Services.
* seed idempotente.
* módulos Nest vacíos.
* Common independiente de Auth.
* IA sin autoridad para modificar arquitectura.

Estas decisiones únicamente deberían reabrirse mediante una nueva decisión formal si aparece una contradicción técnica, requerimiento nuevo o cambio arquitectónico.

---

# 36. Matriz final de estado

| Área                         | Estado                      |
| ---------------------------- | --------------------------- |
| Alcance F4                   | CERRADO                     |
| Estructura NestJS            | CERRADO                     |
| main.ts / AppModule          | CERRADO                     |
| CORS                         | CERRADO                     |
| Helmet                       | CERRADO                     |
| Variables obligatorias       | CERRADO                     |
| Herramienta de configuración | PENDIENTE                   |
| Prisma singleton             | CERRADO                     |
| Acceso a Prisma              | CERRADO                     |
| Tenant isolation             | PARCIAL                     |
| TenantContext                | PARCIAL                     |
| ADMIN global                 | PARCIAL                     |
| Passport/JWT Strategy        | CERRADO                     |
| Login                        | CERRADO conceptualmente     |
| Login multi-tenant           | PARCIAL                     |
| Select Tenant                | CERRADO conceptualmente     |
| Password policy              | CERRADO                     |
| bcrypt 12                    | CERRADO                     |
| Rate limiting                | CERRADO funcionalmente      |
| Implementación rate limit    | PENDIENTE                   |
| Guards                       | CERRADO                     |
| Decoradores                  | CERRADO                     |
| Response wrapper             | CERRADO                     |
| Error handling               | CERRADO                     |
| Validation                   | CERRADO                     |
| ESLint/Prettier              | CERRADO                     |
| Dependencias entre módulos   | CERRADO conceptualmente     |
| Prisma Seed                  | CERRADO conceptualmente     |
| Seed ADMIN                   | PARCIAL                     |
| Scripts de desarrollo        | CERRADO                     |
| start:prod                   | PENDIENTE                   |
| Módulos vacíos               | CERRADO                     |
| README por módulo            | CERRADO — no                |
| Module Development Guide     | CERRADO                     |
| AI-friendly repository       | CERRADO                     |
| Autonomía del agente         | CERRADO                     |
| IA modificando arquitectura  | PROHIBIDO                   |
| Contradicciones              | STOP + reporte + validación |
| Sprint personal              | CERRADO                     |
| Criterios de finalización    | CERRADO                     |
| Handoff                      | CERRADO como objetivo       |

---

# 37. Estado del registro

El formulario de Fase 4 queda **formalmente consolidado**.

La mayoría de las decisiones ya están cerradas.

Los pendientes restantes no representan un rediseño de la arquitectura. Son principalmente decisiones de implementación necesarias para convertir las decisiones conceptuales en código, especialmente:

1. implementación concreta de TenantContext;
2. mecanismo concreto de tenant isolation sobre Prisma;
3. representación de ADMIN global;
4. flujo exacto de selección de tenant en login multi-tenant;
5. detalles menores de configuración, rate limiting y seed.

Estos puntos deberán resolverse antes de que el componente correspondiente sea implementado, pero no deben utilizarse como excusa para volver a abrir toda la Fase 4.

El objetivo de este registro es precisamente permitir que el diseño pase de:

```text
Decisiones arquitectónicas
        ↓
Registro de decisiones
        ↓
Pendientes técnicos concretos
        ↓
Implementación
```

sin volver continuamente al punto inicial de diseño.

# Cierre de decisiones — Fase 4

## Estado

**Fase:** 4 — Implementación de infraestructura y baseline
**Estado:** CERRADA
**Propósito del cierre:** Formalizar las decisiones finales que resolvieron los puntos pendientes identificados durante la auditoría de las respuestas originales del formulario de Fase 4.

Las decisiones siguientes complementan las respuestas originales del formulario y tienen precedencia sobre cualquier interpretación anterior que resulte incompatible con ellas.

---

## F4-C01 — Representación de ADMIN global

**Decisión:** A — Confirmada.

`ADMIN` representa una autoridad global de plataforma y **no pertenece al modelo de roles tenant-scoped**.

Modelo definitivo:

* `User.platformRole` nullable representa el rol global de plataforma.
* `UserTenant.roleId` representa el rol del usuario dentro de un tenant.
* `Role.tenantId` es obligatorio.
* `RoleName` contiene únicamente `OWNER` y `MEMBER`.
* `ADMIN` no pertenece a `Role`.
* No se utilizará un tenant ficticio o "system tenant" para representar administradores globales.
* No se agregará un booleano `isAdmin`.
* No se implementará un RBAC global genérico para el MVP.

Por lo tanto, un usuario puede ser `ADMIN` global sin pertenecer a ningún tenant.

---

## F4-C02 — Roles por tenant

**Decisión:** CONFIRMADA.

La relación entre usuario, tenant y rol queda definida como:

```text
User
 └── platformRole? = ADMIN

UserTenant
 ├── userId
 ├── tenantId
 └── roleId ──> Role

Role
 ├── tenantId
 └── name = OWNER | MEMBER
```

Un mismo usuario puede pertenecer a múltiples tenants y tener un rol diferente en cada uno.

Ejemplo:

```text
User A
 ├── Tenant A → OWNER
 ├── Tenant B → MEMBER
 └── Tenant C → MEMBER
```

El rol tenant-scoped **no se almacenará en `User`**.

Por lo tanto:

* Se elimina `User.roleId`.
* El rol tenant-scoped se obtiene mediante `UserTenant.roleId`.
* `ADMIN` permanece independiente de la pertenencia a tenants.

---

## F4-C03 — Contexto de autorización en JWT

**Decisión:** A — Confirmada.

El JWT distinguirá explícitamente entre autoridad global y contexto tenant-scoped.

Claims relevantes:

```json
{
  "sub": "user-id",
  "email": "user@example.com",
  "platformRole": null,
  "tenantId": "tenant-id",
  "tenantRole": "OWNER",
  "iat": 0,
  "exp": 0
}
```

Para un usuario normal:

```text
platformRole = null
tenantId     = tenant seleccionado
tenantRole   = OWNER | MEMBER
```

Para un `ADMIN` global operando sin tenant:

```text
platformRole = ADMIN
tenantId     = null
tenantRole   = null
```

Si un `ADMIN` opera sobre un tenant seleccionado:

```text
platformRole = ADMIN
tenantId     = tenant seleccionado
tenantRole   = null
```

La selección de un tenant **no convierte al ADMIN en OWNER ni MEMBER**. La autoridad global continúa siendo `ADMIN`.

Los guards y servicios deberán interpretar estos campos de acuerdo con el contexto de autorización correspondiente.

---

## F4-C04 — Flujo de autenticación y selección de tenant

**Decisión:** A — Confirmada.

El flujo de autenticación será:

### Usuario con un solo tenant

El sistema:

1. valida las credenciales;
2. identifica su pertenencia al tenant;
3. selecciona automáticamente el tenant;
4. genera el JWT con el contexto tenant correspondiente.

No se solicitará una selección innecesaria.

### Usuario con múltiples tenants

El sistema:

1. valida las credenciales;
2. identifica los tenants disponibles;
3. requiere selección de tenant;
4. genera el JWT definitivo con el tenant seleccionado.

### Usuario sin tenants

Un usuario normal sin pertenencia a ningún tenant **no obtiene un JWT tenant-scoped**.

### ADMIN global

Un `ADMIN` puede autenticarse sin tenant seleccionado y obtener un contexto global:

```text
platformRole = ADMIN
tenantId     = null
tenantRole   = null
```

También puede operar con un tenant seleccionado sin perder su autoridad global.

---

## F4-C05 — Validación de membresía y rol durante la petición

**Decisión:** A — Confirmada.

El JWT representa un **snapshot del contexto de autorización** en el momento de su emisión.

No se realizará una consulta a `UserTenant` en cada request únicamente para comprobar nuevamente el rol tenant-scoped.

Se mantiene:

* validación de firma y expiración del JWT;
* validación del estado activo del usuario;
* contexto tenant contenido en el token;
* expiración del token de 8 horas;
* actualización del contexto de autorización al emitir un nuevo token.

Por lo tanto, un cambio de rol o membresía podrá reflejarse al obtener un nuevo JWT, manteniendo el modelo de autenticación ya definido para Fase 4.

Esta decisión evita introducir una consulta transversal adicional en cada request sin una necesidad funcional establecida.

---

## F4-C06 — Implementación de TenantContext

**Decisión:** B — Confirmada con mitigación de riesgos.

Se utilizará **AsyncLocalStorage** para mantener el contexto tenant de la petición sin propagar manualmente el `tenantId` por toda la cadena de llamadas.

El contexto será:

* creado a partir del contexto autenticado;
* válido únicamente durante la petición;
* no modificable arbitrariamente por código de negocio;
* inaccesible como mecanismo de entrada controlado por el cliente;
* utilizado exclusivamente como contexto de seguridad y operación transversal.

### Mitigación de riesgos

Debido a que AsyncLocalStorage introduce un mecanismo implícito de propagación de contexto, su implementación deberá mantenerse deliberadamente simple y acompañarse de controles que reduzcan el riesgo de aislamiento incorrecto:

* el `tenantId` nunca proviene directamente del cliente como autoridad de seguridad;
* el contexto se establece únicamente después de validar la autenticación;
* no existirá estado tenant global mutable;
* el contexto deberá limpiarse/aislarse correctamente entre requests;
* las operaciones tenant-scoped deberán requerir contexto válido;
* los tests de aislamiento deberán comprobar que una petición no puede operar accidentalmente sobre otro tenant;
* las operaciones globales de `ADMIN` deberán tratar explícitamente la ausencia de `tenantId`.

AsyncLocalStorage se adopta como mecanismo técnico de propagación del contexto, **no como sustituto de las reglas de autorización ni de las restricciones de acceso a datos**.

---

## F4-C07 — Aislamiento tenant-scoped en acceso a datos

**Decisión:** A — Confirmada con mitigación estricta de error humano.

El aislamiento tenant-scoped se implementará mediante consultas explícitamente restringidas al tenant correspondiente.

El `tenantId` utilizado por dichas operaciones deberá provenir del `TenantContext` autenticado y **no de un valor proporcionado por el cliente como autoridad de seguridad**.

No se implementará Prisma Middleware/Extension obligatorio para inyectar automáticamente el tenant en todas las consultas.

Tampoco se establece un Repository Pattern obligatorio.

### Mitigación del riesgo de omisión

Debido a que el aislamiento explícito puede verse afectado por errores humanos al construir consultas, la implementación deberá incorporar mecanismos para reducir dicho riesgo sin introducir una capa arquitectónica innecesaria:

* `TenantContext` como fuente única del contexto tenant;
* helpers/utilidades reutilizables para obtener o exigir el contexto tenant;
* convenciones claras para consultas tenant-scoped;
* MODULE-DEVELOPMENT.md con ejemplos y reglas obligatorias;
* revisión de código y auditoría de consultas tenant-scoped;
* tests específicos de aislamiento entre tenants;
* prohibición de aceptar `tenantId` del cliente como mecanismo de autorización;
* detección y reporte de cualquier operación tenant-scoped que no aplique correctamente el contexto.

El objetivo es **evitar el cast manual repetitivo del `tenantId` en cada servicio sin introducir mecanismos automáticos de aislamiento que añadan complejidad innecesaria**.

La responsabilidad final del aislamiento permanece en la capa de servicio y en las reglas transversales definidas por Fase 4.

---

# Resultado final de las decisiones pendientes

| Decisión                           | Resultado                         |
| ---------------------------------- | --------------------------------- |
| F4-C01 — ADMIN global              | **A — Confirmada**                |
| F4-C02 — Roles por tenant          | **Confirmada**                    |
| F4-C03 — JWT context               | **A — Confirmada**                |
| F4-C04 — Selección de tenant       | **A — Confirmada**                |
| F4-C05 — Validación de membresía   | **A — Confirmada**                |
| F4-C06 — TenantContext             | **B — Confirmada con mitigación** |
| F4-C07 — Aislamiento tenant-scoped | **A — Confirmada con mitigación** |

---

# Decisión de cierre

Con la resolución de F4-C01 a F4-C07 se consideran cerrados los puntos de arquitectura que permanecían pendientes para iniciar la implementación de la infraestructura de Fase 4.

En consecuencia:

1. El modelo de roles y autorización queda definido.
2. El modelo Prisma puede actualizarse conforme a las decisiones aprobadas.
3. Auth, Users, TenantContext y Guards pueden implementarse sin reinterpretar el modelo de autorización.
4. La estrategia de aislamiento tenant-scoped queda definida.
5. No se requiere introducir Prisma Middleware/Extension ni Repository Pattern como infraestructura obligatoria.
6. No quedan decisiones arquitectónicas abiertas que deban ser resueltas antes de comenzar la implementación de Fase 4.
7. Cualquier contradicción detectada durante la implementación deberá ser reportada conforme al mecanismo de escalamiento definido en ADR-004, sin modificar unilateralmente las decisiones cerradas.

**Estado final:** Fase 4 lista para actualización documental, corrección del modelo Prisma, implementación del baseline y posterior handoff a desarrollo de módulos funcionales.
