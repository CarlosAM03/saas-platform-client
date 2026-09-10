# Fase 5 - Flutter Foundation: Registro de decisiones y baseline reconciliado

**Proyecto:** Plataforma SaaS — Cliente Flutter  
**Fase:** 5 — Flutter Foundation  
**Versión:** 0.3 (reconciliada con Formulario F5 y ADR-005)  
**Fecha:** 9 de septiembre de 2026  
**Autor:** Carlos Armenta  
**Estado:** Baseline documental reconciliado  
**Documento dirigido a:** André (Flutter Developer), Ángeles (UI/UX + Documentación), Carlos (Arquitecto/DevOps)

---

## 0. Nota de alineación con F4

Este documento fue **actualizado** para alinearse con el estado real del Platform Backend tras:

- **F4 CLOSED AS BASELINE** (rama `dev`).
- La **auditoría profunda de reconciliación** `Docs/Auditorias/Fase4-Auditoria-Profunda-PostCodex.md`.
- El **ADR-004** con la gobernanza consolidada y las decisiones F4-C01 a F4-C07.
- El **registro de decisiones F4** con la consolidación vigente.
- El **OpenAPI actualizado** (`platform-api.v1.yaml`) que ya incluye Health, proyecciones `AuthUser`/`AuthTenant`, `platformRole`, `tenants[]` y endpoints con códigos HTTP correctos.

**Implicación clave para Fase 5:** el contrato del backend ya está cerrado y verificado. André no necesita mocks para Auth, Users y Health; esos endpoints están operativos y estables. Para Tenants, Campaigns, Prospects y ProspectingJobs, el contrato sigue siendo objetivo F5+ y André debe diseñar contra el YAML, no contra implementaciones futuras.

**Advertencia operativa:** las credenciales locales y de desarrollo del backend **deben rotarse** antes de cualquier despliegue compartido o de entregar entornos a terceros. Ninguna credencial del `.env` actual debe considerarse valor definitivo.

---

## 1. Propósito y alcance

Este documento establece el **baseline técnico de Fase 5 (Flutter Foundation)**.

**Modelo de colaboración:**

- **Carlos (Arquitecto/DevOps):** esqueleto, infraestructura transversal, configuración, cliente API, DTOs base, routing, convenciones e integración con el backend.
- **André (Flutter Developer):** desarrollo de features, pantallas y lógica de UI. Consulta a Carlos solo para integraciones o extensiones del backend.
- **Ángeles (UI/UX + Documentación):** identidad visual, wireframes, prototipos y documentación académica.

**Principio rector:** *"El frontend es un cliente API. No implementa lógica de negocio que ya resuelve el backend."*

---

## 2. Jerarquía de fuentes de verdad (actualizada)

Para resolver conflictos:

1. **ADR-004** — Gobernanza consolidada de F4. Autoridad máxima.
2. **Registro de decisiones Fase 4** — Consolidación vigente + evidencia histórica.
3. **Prisma y migraciones alineados con F4**.
4. **OpenAPI/Swagger** (`Docs/Contracts/platform-api.v1.yaml`) — Contrato público vigente.
5. **Auditoría profunda F4** (`Docs/Auditorias/Fase4-Auditoria-Profunda-PostCodex.md`) — Evidencia operativa.
6. **ADR-001, ADR-002, ADR-003** — Compatibles; reconciliados donde F4 prevalece.
7. **Este documento (Baseline Fase 5)** — Convenciones, estructura y decisiones del frontend.
8. **Identidad Visual UI/UX v0.1** — No vinculante hasta v1.0.
9. **Documentación general** (ActaConceptual, ModeloArquitectonico) — Contexto histórico.

**Regla:** si un documento anterior contradice ADR-004 o el OpenAPI actualizado, prevalece F4.

---

## 3. Estado del backend que el cliente va a consumir

### 3.1 Endpoints operativos y estables (F4 cerrado)

| Módulo | Endpoint | Estado | Notas |
|--------|----------|--------|-------|
| Health | `GET /api/v1/health`, `/health/live`, `/health/ready` | ✅ Operativo | `ready` consulta PostgreSQL real |
| Auth | `POST /api/v1/auth/login` | ✅ Operativo | **200** (no 201), JWT HS256 8h, rate limit 5/60s/IP |
| Auth | `POST /api/v1/auth/logout` | ✅ Operativo | **200**, `data: {}` |
| Auth | `POST /api/v1/auth/select-tenant` | ✅ Operativo | Valida membership o ADMIN; 403 si no pertenece |
| Auth | `GET /api/v1/auth/me` | ✅ Operativo | Devuelve el token presentado sin renovarlo |
| Users | `GET/POST/GET:id/PATCH/DELETE /api/v1/users` | ✅ Operativo | Requiere tenant seleccionado; DELETE = soft delete |

### 3.2 Endpoints con contrato definido pero sin implementación F4

- Tenants (GET, POST, GET:id)
- Campaigns (CRUD)
- Prospects (GET, GET:id, PATCH)
- ProspectingJobs (POST, GET, GET:id, cancel, persist, export)

**Estos endpoints forman parte de F5+/F6.** André diseña contra el contrato, no contra implementación futura.

---

## 4. Decisiones arquitectónicas heredadas aplicables al frontend

### 4.1 Decisiones globales (Fases 1-4)

| # | Decisión | Fuente | Impacto en Flutter |
|---|----------|--------|-------------------|
| D-01 | Multi-tenancy: Shared DB + Shared Schema + tenantId | ADR-001 | El frontend maneja contexto de tenant sin asumir autorización |
| D-02 | Auth: JWT Bearer, HS256, 8h, sin refresh token | ADR-003 / ADR-004 §29 | Almacenar token; manejar 401/expiración |
| D-03 | Flutter no se comunica con Prospector Service | ADR-002 | Todas las llamadas pasan por Platform Backend |
| D-04 | Roles: `OWNER`/`MEMBER` tenant-scoped; `ADMIN` global (`platformRole`) | ADR-004 §33, §34 | Distinguir autoridad global vs tenant-scoped |
| D-05 | `User.role` **nullable** (ADMIN sin tenant) | ADR-004 §30, auditoría | DTOs tratan `role` como nullable |
| D-06 | JWT incluye `platformRole`, `tenantId`, `tenantRole` | ADR-004 §29 | Lectura para UI, nunca autorización |
| D-07 | Estructura de respuesta: `{ success, data, meta? }` | ADR-002 / ADR-004 §24 | Deserializar `data` |
| D-08 | Error: `{ success: false, error: { code, message, details, timestamp } }` | ADR-002 / ADR-004 §23 | Parsear estructura |
| D-09 | Paginación: `page` (1-based), `limit` (max 100, default 20) | ADR-002 §9 | Manejar `meta` en listados |
| D-10 | Prefijo global `/api/v1` | ADR-002 | Base URL: `http://<host>/api/v1` |
| D-11 | `Idempotency-Key` en creación de ProspectingJobs | ADR-002 §27 | Generar UUID por request |
| D-12 | Job lifecycle: `QUEUED → RUNNING → COMPLETED/FAILED/CANCELLED` | ADR-002 §10 | Modelar estados y transiciones |
| D-13 | Cancelación: `POST /prospecting-jobs/{id}/cancel` | ADR-002 §26 | Solicitar cancelación |
| D-14 | Persistencia: `POST /prospecting-jobs/{id}/persist` | ADR-002 §18 | Decidir persistir/exportar/descartar |
| D-15 | Exportación: `GET /prospecting-jobs/{id}/export?format=csv\|xlsx` | ADR-002 §20 | Respuestas binarias |
| D-16 | Results/progress vía Job Detail (`resultsAvailable`, `results`, `progress`) | ADR-002 §14 | Campos nullable y estados de carga |
| D-17 | Tenant resolution desde JWT, NO del cliente | ADR-003 / ADR-004 §17 | El cliente no envía `tenantId` arbitrario |

### 4.2 Decisiones específicas del frontend (alcance Carlos)

| # | Decisión | Valor | Estado |
|---|----------|-------|--------|
| F5-01 | Plataforma cliente | Flutter (multiplataforma) | DEFINIDA |
| F5-02 | HTTP Client | Dio encapsulado dentro de `ApiClient` | DEFINIDA |
| F5-03 | State Management | Riverpod (`flutter_riverpod`) | DEFINIDA |
| F5-04 | Routing | `go_router` con guards | DEFINIDA |
| F5-05 | Secure Storage | `flutter_secure_storage` | DEFINIDA |
| F5-06 | Serialización JSON | `json_annotation` + `json_serializable` | DEFINIDA |
| F5-07 | Env vars | `envied` + `.env` | DEFINIDA |
| F5-08 | Logging | `logger` | DEFINIDA |
| F5-09 | Estructura | Por features (`lib/features/<feature>/`) | DEFINIDA |
| F5-10 | Prefijo API | `/api/v1` en URL base | DEFINIDA |
| F5-11 | Versionado | Sigue al backend (no versionado en cliente) | DEFINIDA |
| F5-12 | Theme base | Inter, `#2563EB` (Identidad Visual v0.1) | PROPUESTA |
| F5-13 | Navegación | Bottom nav móvil + drawer/sidebar web/tablet | PROPUESTA |
| F5-14 | Manejo de errores | `ApiException` con `code`, `message`, `details` | DEFINIDA |
| F5-15 | Testing | `flutter_test` + `mockito` | DEFINIDA |
| F5-16 | Linting | `flutter_lints` | DEFINIDA |
| F5-17 | Null safety | Habilitado (default Flutter) | DEFINIDA |

### 4.3 Decisiones funcionales del MVP

| # | Decisión | Fuente | Estado |
|---|----------|--------|--------|
| FN-01 | Autenticación email + password | OpenAPI | DEFINIDA |
| FN-02 | 1 tenant → selección automática | ADR-004 §37 | DEFINIDA |
| FN-03 | Múltiples tenants → el usuario elige | ADR-004 §37, §38 | DEFINIDA |
| FN-04 | ADMIN sin tenant, acceso a cualquiera | ADR-004 §33, §37 | DEFINIDA |
| FN-05 | Dashboard: campañas actuales + crear nueva | WhatsApp | DEFINIDA |
| FN-06 | Flujo: crear campaña → generar prospectos → jobs asíncronos | WhatsApp | DEFINIDA |
| FN-07 | Cancelar job en progreso | WhatsApp | DEFINIDA |
| FN-08 | Caché temporal de prospectos en cliente | WhatsApp | DEFINIDA |
| FN-09 | Persistir / exportar / descartar resultados | ADR-002 §17, §18, §20 | DEFINIDA |
| FN-10 | Deduplicación al persistir (auto) | ADR-001 | DEFINIDA |
| FN-11 | Gestión de campañas (prospectos + ciclo de vida) | WhatsApp | DEFINIDA |
| FN-12 | Sin métricas avanzadas / Analytics en MVP | WhatsApp | FUERA DE ALCANCE |
| FN-13 | Navegación: perfil, campañas, prospectos, generar, logout | WhatsApp | DEFINIDA |
| FN-14 | Pantallas de administración (ADMIN) | WhatsApp | DEFINIDA (v1) |
| FN-15 | Evolución de API para reducir admin manual | WhatsApp | POSTERGADA |

### 4.4 Decisiones de UI/UX (Identidad Visual v0.1)

| # | Decisión | Valor | Estado |
|---|----------|-------|--------|
| UX-01 | Estética | SaaS moderno, limpio, profesional | PROPUESTA |
| UX-02 | Color primario | `#2563EB` | PROPUESTA |
| UX-03 | Semánticos | Success `#16A34A`, Warning `#D97706`, Error `#DC2626` | PROPUESTA |
| UX-04 | Tipografía | Inter | PROPUESTA |
| UX-05 | Espaciado | Escala de 4px | PROPUESTA |
| UX-06 | Bordes | 6 / 10 / 14 px | PROPUESTA |
| UX-07 | Sombras | Uso moderado | PROPUESTA |
| UX-08 | Iconos | Simples, lineales | PROPUESTA |
| UX-09 | Navegación | Bottom nav + sidebar opcional | PROPUESTA |
| UX-10 | Estados | Loading, Empty, Error, Success, Offline | PROPUESTA |
| UX-11 | Responsive | Mobile-first → tablet → desktop | PROPUESTA |

---

## 5. DTOs y proyecciones que el cliente debe consumir

Los DTOs del frontend deben seguir **exactamente** el contrato OpenAPI. Puntos críticos:

### 5.1 `AuthContext` (respuesta de login / select-tenant / me)

```dart
class AuthContext {
  final String accessToken;
  final AuthUser user;
  final List<AuthTenant> tenants;
  final String? currentTenantId;  // nullable (ADMIN sin tenant)
}
```

### 5.2 `AuthUser` (proyección reducida, distinta de `User` completo)

```dart
class AuthUser {
  final String id;
  final String name;
  final String email;
  final String? platformRole;  // "ADMIN" | null
  final String status;          // ACTIVO | INACTIVO
  final String createdAt;
  final String updatedAt;
}
```

**Importante:** `AuthUser` NO incluye `role` ni `tenants[]`. Esa proyección es específica de `/auth/*`. Para `/users`, el DTO `User` sí incluye `role` (nullable) y `tenants[]`.

### 5.3 `AuthTenant` (proyección reducida)

```dart
class AuthTenant {
  final String id;
  final String name;
  final String slug;
  final String status;  // ACTIVO | SUSPENDIDO
}
```

### 5.4 `User` (para `/users`)

```dart
class User {
  final String id;
  final String name;
  final String email;
  final String? platformRole;   // ADMIN | null
  final Role? role;             // nullable
  final List<UserTenantMembership>? tenants;
  final String status;
  final String createdAt;
  final String updatedAt;
}

class Role {
  final String id;
  final String name;   // OWNER | MEMBER
  final String? description;
  final String tenantId;
}
```

### 5.5 Reglas de deserialización

- **Nunca** asumir que `role` viene no nulo. Un `ADMIN` global sin tenant tendrá `role: null`.
- **Nunca** asumir que `currentTenantId` viene no nulo. Un `ADMIN` sin selección tendrá `null`.
- **Nunca** exponer `passwordHash` (no viene en el DTO).
- Manejar `tenants[]` como lista posiblemente vacía para ADMIN global.

---

## 6. Comportamiento HTTP que el cliente debe respetar

| Situación | Código | Comportamiento del cliente |
|-----------|--------|---------------------------|
| Login exitoso | **200** | Guardar `accessToken` en secure storage |
| Login inválido | 401 | Mostrar error genérico |
| Rate limit excedido | 429 | Mostrar mensaje de reintento |
| Logout | **200** | Eliminar token y limpiar estado |
| Select tenant válido | 200 | Actualizar token con nuevo contexto |
| Select tenant ajeno | **403** | Mostrar "no autorizado" |
| `me` sin token | 401 | Redirigir a login |
| `me` válido | 200 | Actualizar estado (sin renovar token) |
| Users list sin tenant seleccionado (ADMIN) | **403** | Redirigir a `select-tenant` |
| Users DELETE | 200 | Marcar usuario como inactivo en UI |
| Health ready sin DB | 503 | No afecta al cliente directamente |

**Nota:** el backend **no renueva el token en `me`**. Si el token está cerca de expirar (8h), el cliente debe anticipar el re-login.

---

## 7. Pendientes por responsable (actualizado)

### 7.1 Carlos (Fase 5)

| ID | Pendiente | Prioridad | Estado |
|----|-----------|-----------|--------|
| P-01 | Crear repo `saas-platform-client` en GitHub | Alta | Pendiente |
| P-02 | `pubspec.yaml` con versiones fijas | Alta | Pendiente |
| P-03 | Estructura de carpetas definitiva | Alta | Pendiente |
| P-04 | `ApiClient` + interceptores (auth, logging) | Alta | Pendiente |
| P-05 | `AuthService` (login, logout, select-tenant, me) | Alta | Pendiente |
| P-06 | Modelos DTOs (`AuthUser`, `AuthTenant`, `AuthContext`, `User`, `Role`) | Alta | Pendiente |
| P-07 | `envied` + `.env.example` | Alta | Pendiente |
| P-08 | `AuthGuard` en `go_router` | Alta | Pendiente |
| P-09 | `AuthState` con Riverpod | Alta | Pendiente |
| P-10 | Pantallas base: Login, Select Tenant, Home (esqueleto) | Media | Pendiente |
| P-11 | `SecureStorageService` para JWT | Alta | Pendiente |
| P-12 | Tema base (colores, tipografía, componentes) | Media | Pendiente |
| P-13 | `README.md` con convenciones y cómo extender | Alta | Pendiente |
| P-14 | `FEATURE-DEVELOPMENT.md` para André | Alta | Pendiente |
| P-15 | `.gitignore`, `analysis_options.yaml` | Media | Pendiente |
| P-16 | Scripts de build | Baja | Pendiente |

### 7.2 André (features)

| ID | Pendiente | Prioridad |
|----|-----------|-----------|
| A-01 | Pantallas de campañas (lista, detalle, crear/editar) | Alta |
| A-02 | Pantallas de prospectos (lista, detalle, filtros) | Alta |
| A-03 | Pantalla de generación de prospectos (form + progreso job) | Alta |
| A-04 | Perfil + contexto de tenant | Media |
| A-05 | Servicios API: Campaigns, Prospects, Jobs | Alta |
| A-06 | DTOs: Campaign, Prospect, ProspectingJob | Alta |
| A-07 | Caché temporal de prospectos | Alta |
| A-08 | Deduplicación en cliente (opcional) | Media |
| A-09 | Implementar polling para job | Alta |
| A-10 | Persistencia / exportación / descarte | Alta |
| A-11 | Pantallas de administración de tenants (ADMIN) | Media |
| A-12 | Pantallas de administración de usuarios | Media |
| A-13 | Estados de carga / error / vacío | Alta |
| A-14 | Tests de widgets e integración | Media |
| A-15 | i18n (opcional) | Baja |

### 7.3 Ángeles (UI/UX + docs)

| ID | Pendiente | Prioridad |
|----|-----------|-----------|
| G-01 | Wireframes de baja fidelidad | Alta |
| G-02 | Bocetos de alta fidelidad | Alta |
| G-03 | Design System v1.0 | Media |
| G-04 | Logo y nombre comercial | Media |
| G-05 | Prototipo interactivo (Figma) | Media |
| G-06 | Documentación académica | Media |
| G-07 | Manual de usuario final | Baja |
| G-08 | Accesibilidad | Baja |
| G-09 | Tema oscuro | Baja |

### 7.4 Pendientes generales (post-MVP / integración)

| ID | Pendiente | Prioridad |
|----|-----------|-----------|
| GLOBAL-01 | Polling para jobs | DEFINIDA para MVP |
| GLOBAL-02 | TTL de caché en Flutter | Media |
| GLOBAL-03 | Integración real con Prospector Service (Carlos) | Alta |
| GLOBAL-04 | Cliente HTTP transversal | CERRADA: Dio aprobado y encapsulado en `ApiClient` |
| GLOBAL-05 | Refresh token (backend no lo soporta) | Baja |
| GLOBAL-06 | Política de reintentos en cliente | Baja |
| GLOBAL-07 | Offline / persistencia local | Media |
| GLOBAL-08 | CI/CD para Flutter | Baja |
| GLOBAL-09 | Publicación en stores | Baja |
| GLOBAL-10 | Analytics/telemetría en cliente | Baja |

---

## 8. Alcance explícito de Fase 5 (Carlos)

### 8.1 Lo que Carlos hará

- Repo `saas-platform-client`.
- `pubspec.yaml` con versiones fijas.
- Estructura modular por features.
- Implementación de:
  - `core/config/` (`envied`).
  - `core/network/` (`ApiClient` + interceptores).
  - `core/storage/` (`SecureStorageService`).
  - `core/errors/` (`ApiException`).
  - `core/theme/` (colores, tipografía, tema base).
  - `shared/models/` (`AuthUser`, `AuthTenant`, `AuthContext`, `User`, `Role`, `Tenant`).
  - `features/auth/` (servicio + estado + guards + pantallas esqueleto).
  - `routes/` (`go_router` + guards).
  - `app/` (`MyApp` + configuración global).
  - `main.dart` con `ProviderScope`.
- Lints (`flutter_lints`).
- Documentación: `README.md`, `FEATURE-DEVELOPMENT.md`, `CONTRIBUTING.md`.

### 8.2 Lo que Carlos NO hará

- Features completas (campañas, prospectos, jobs).
- Diseño de pantallas (más allá del esqueleto).
- Identidad visual final.
- Integración con Prospector Service (Fase 8).

### 8.3 Entregable de Fase 5

Repo Flutter con:

1. Estructura base funcional.
2. Cliente HTTP listo.
3. Auth funcional (login/logout/select-tenant/me).
4. Navegación protegida con guards.
5. DTOs base (con `role` y `currentTenantId` nullable).
6. Tema base.
7. Documentación para André y Ángeles.
8. Sin features completas.

---

## 9. Handoff a André

### 9.1 Lo que André recibe

- Repo `saas-platform-client` funcional.
- `README.md`, `FEATURE-DEVELOPMENT.md`, `CONTRIBUTING.md`.
- `ApiClient` con interceptores.
- DTOs base.
- `AuthService` funcional.
- `go_router` + `AuthGuard`.
- Tema base.
- Pantallas esqueleto (Login, Select Tenant, Home).

### 9.2 Lo que André debe hacer

1. Leer ADR-002 y ADR-004.
2. Leer `platform-api.v1.yaml` (contrato vigente).
3. Leer `FEATURE-DEVELOPMENT.md`.
4. Implementar features:
   - **Campañas:** lista, detalle, crear, editar, archivar.
   - **Prospectos:** lista, detalle, filtros, gestión.
   - **Jobs:** crear, monitorear, cancelar, persistir/exportar/descartar.
   - **Perfil y Tenant:** ver contexto, cambiar tenant.
   - **Administración (ADMIN):** tenants, usuarios.
5. Seguir UI/UX definida por Ángeles.
6. Consultar a Carlos para extensiones de API o integración con Prospector Service.

### 9.3 Reglas para André

- ❌ No modificar `ApiClient`, `AuthGuard`, `AuthService` sin coordinar.
- ❌ No implementar lógica de negocio del backend.
- ❌ No modificar el OpenAPI.
- ✅ Features en `lib/features/<feature>/`.
- ✅ Riverpod para estado.
- ✅ Estados: Loading, Empty, Error, Success.
- ✅ Reportar contradicciones a Carlos.

---

## 10. Handoff a Ángeles

### 10.1 Lo que Ángeles recibe

- Identidad Visual v0.1.
- Lista de pantallas a diseñar.
- Contexto del producto.
- OpenAPI para conocer los datos disponibles.

### 10.2 Lo que Ángeles debe hacer

1. Leer Identidad Visual v0.1.
2. Wireframes de baja fidelidad:
   - Splash, Login, Select Tenant.
   - Dashboard.
   - Campañas (lista, detalle, crear/editar).
   - Prospectos (lista, detalle).
   - Generación de prospectos (form + progreso).
   - Perfil y tenant.
3. Diseños de alta fidelidad.
4. Design System v1.0.
5. Prototipo en Figma.
6. Documentación académica.

### 10.3 Reglas para Ángeles

- ✅ Claridad sobre decoración.
- ✅ Considerar estados.
- ✅ Diseñar pensando en Flutter.
- ✅ Consultar con Carlos y André.
- ⚠️ Evitar componentes no nativos.
- ⚠️ No asumir acceso a datos sensibles.

---

## 11. Cronograma tentativo de Fase 5

| Semana | Carlos | André | Ángeles |
|--------|--------|-------|---------|
| S1 | Repo + skeleton + ApiClient + AuthService | Onboarding, lectura | Wireframes Login + Dashboard |
| S2 | DTOs + Guards + tema + README | Pantallas esqueleto | Wireframes Campañas + Prospectos |
| S3 | FEATURE-DEVELOPMENT + pruebas básicas | Feature Campaigns | Alta fidelidad Login + Dashboard |
| S4 | Handoff + soporte | Feature Prospects + Jobs | Alta fidelidad Campañas + Prospectos |
| S5+ | Fase 8 (Prospector) | Iteración sobre features | Design System + Prototipo |

---

## 12. Riesgos conocidos (actualizado)

| Riesgo | Mitigación |
|--------|------------|
| Endpoints `/campaigns`, `/prospects`, `/prospecting-jobs` aún no implementados | André diseña contra OpenAPI; usa mocks hasta que Ángel implemente |
| `role` nullable en `AuthUser` (no existe) y `User` (existe pero puede ser null) | DTOs manejan `Role?` nullable |
| `currentTenantId` nullable | DTOs manejan `String?` |
| Multi-tenant: nunca enviar `tenantId` arbitrario | El flujo solo usa `select-tenant` |
| Jobs asíncronos | Polling cerrado para MVP; WebSocket/SSE fuera de alcance |
| Caché de resultados en Flutter | TTL y estructura por definir (André) |
| Design System v0.1 | Ángeles define v1.0 |
| **Credenciales backend requieren rotación** | Antes de cualquier despliegue compartido |
| Warning `LegacyRouteConverter` | Residual; no bloqueante |

---

## 13. Preguntas abiertas

| # | Pregunta | Estado |
|---|----------|--------|
| Q1 | Polling para jobs | **DEFINIDA**: 3 a 5 segundos; detener en estados terminales |
| Q2 | TTL de caché en Flutter | **POSTERGADA** (André) |
| Q3 | Manejo offline | **POSTERGADA** (André) |
| Q4 | Cliente HTTP | **DEFINIDA**: Dio encapsulado en `ApiClient` |
| Q5 | Refresh token | **NO** (backend no lo soporta) |
| Q6 | Analytics en cliente | **NO** para MVP |
| Q7 | Tema oscuro | **POSTERGADA** |
| Q8 | i18n | **NO** para MVP |
| Q9 | Push notifications | **POSTERGADA** |
| Q10 | Deep linking | **POSTERGADA** |

---

## 14. Documentos relacionados (actualizado)

| Documento | Ubicación | Propósito |
|-----------|-----------|-----------|
| ADR-004 | `Docs/ADRs/` | Gobernanza consolidada F4 |
| Registro F4 | `Docs/DocsTeam/FormularioDeDecisiones/` | Decisiones + evidencia histórica |
| Auditoría profunda F4 | `Docs/Auditorias/Fase4-Auditoria-Profunda-PostCodex.md` | Evidencia operativa |
| platform-api.v1.yaml | `Docs/Contracts/` | Contrato público vigente |
| ADR-001, ADR-002, ADR-003 | `Docs/ADRs/` | Dominio, contratos, seguridad |
| MODULE-DEVELOPMENT.md | `saas-platform-backend/` | Convenciones backend |
| IdentidadVisualUIUX.md | `Docs/` (por crear) | Identidad visual v0.1 |
| FEATURE-DEVELOPMENT.md | `saas-platform-client/` | Guía features Flutter |
| README.md (Flutter) | `saas-platform-client/` | Instalación y estructura |

---

## 15. Estado del documento

| Versión | Estado | Descripción |
|---------|--------|-------------|
| 0.1 | Histórico | Versión inicial previa a F4 cerrado |
| 0.2 | **Actual** | Alineada con F4 CLOSED AS BASELINE |
| 0.3 | Pendiente | Tras primer sprint de Carlos |
| 1.0 | Pendiente | Baseline estable con features iniciales |

**Estado actual:** Documento de definición y planificación alineado con F4 cerrado. Sirve como baseline para Carlos, André y Ángeles.

---

**Firma:**  
Carlos Armenta  
Arquitecto de Software / DevOps  
9 de septiembre de 2026

---

## 16. Nota final de alineación

Este documento refleja el estado **real y verificado** del Platform Backend tras el cierre formal de Fase 4. Cualquier discrepancia futura entre este documento y ADR-004 se resuelve a favor del ADR.

**Cambios principales respecto a v0.1:**

1. Jerarquía de fuentes actualizada (ADR-004 prevalece).
2. Endpoints operativos vs contractuales diferenciados (Auth/Users/Health vs Tenants/Campaigns/Prospects/Jobs).
3. DTOs corregidos: `AuthUser`, `AuthTenant`, `AuthContext` (no son `User`/`Tenant` completos).
4. `role` y `currentTenantId` marcados como nullable.
5. Códigos HTTP corregidos (login 200, logout 200, select-tenant 403 posible, users 403 sin tenant).
6. Advertencia explícita sobre rotación de credenciales.
7. Riesgos actualizados (algunos resueltos en F4, otros persistentes).
8. Estado documental alineado a "F4 CLOSED AS BASELINE".
