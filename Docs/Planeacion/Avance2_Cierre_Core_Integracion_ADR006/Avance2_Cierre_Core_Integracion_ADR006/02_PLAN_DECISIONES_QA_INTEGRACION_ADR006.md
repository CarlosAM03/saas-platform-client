# PLAN-AV2-02 — Decisiones, trabajo de integración, QA, release y rollback

**Proyecto:** PROSPECTOR SaaS — Segundo Avance.  
**Fecha de emisión:** 28 de octubre de 2026 (Tijuana).  
**Objetivo:** preparar la recepción del Backend de Ángel y su adaptación Flutter, comprobar la paridad 1:1 y decidir si el nuevo alcance puede promoverse a `main` para la demostración.  
**Estado:** plan operativo propuesto para aprobación por el owner; decisiones confirmadas se identifican separadamente.  
**Límites:** sin ejecutar merges, migraciones, despliegues ni escrituras productivas como consecuencia de este documento.

## 1. Principios rectores y estrategia paralela confirmada

1. **Core probado primero.** Flutter `main` parte de `e752f6c` y Backend `main` de `b51b265` al corte. El PR #10 fue fusionado deliberadamente por el owner. La paridad del Core no se volverá a romper para introducir una feature.
2. **Líneas aisladas.** Ángel desarrolla ADR-006 en rama Backend basada en `main`; su adaptación Flutter deberá partir del `main` estabilizado, sin `dev` ni ramas Prospector experimentales. El owner dirige QA, revisa los PR y aprueba promoción.
3. **Backend autoridad de permisos, negocio, JWT, tenant y persistencia.** Flutter consume el contrato aprobado, no inventa capacidades ni corrige errores de Backend ocultándolos en UI.
4. **Ramas `main` publican automáticamente** en Render/Vercel según el owner. Un merge puede activar un deploy; jamás fusionar como mero experimento. `main` Backend con ADR-006 debe conservar comportamiento del Core con feature flag `TENANT_REGISTRATION_ENABLED=false` hasta aprobación controlada.
5. **Criterio de presentación:** se anuncia únicamente el alcance que supere los gates. Si ADR-006 no está listo, el Avance 2 puede presentar Core 1.0.0, declarando los límites restantes honestamente.
6. **No usar el sistema productivo como banco destructivo.** SQL directo remoto solo lectura autorizada; E2E de escritura completos locales/efímeros; smoke productivo restringido, datos sintéticos y acciones explícitamente autorizadas.

## 2. Separación de alcances

| Línea | Incluye | No incluye implícitamente |
| --- | --- | --- |
| **Core 1.0.0 estabilizado** | Auth, tenant switch, usuarios V1 con contraseña administrativa, campañas, prospectos, CSV, dashboard y Jobs lectura | Onboarding email, membresías pagadas, Prospector Engine, acciones Jobs 503 |
| **ADR-006 aprobado (ampliación 1.1.0 documental)** | ADMIN registra tenant + primer OWNER; email de activación 24h; canje 15min; completar contraseña; consulta/reenvío ADMIN; flags, seguridad, migrations | Invitación MEMBER, vinculación de User existente, autoservicio, precios, pagos, límites comerciales, transferencia OWNER |
| **Administración de accesos extendida (decisiones adicionales)** | Política de un OWNER, privilegios y futuras invitaciones MEMBER | No está implementada solo por tener `roleId` en DTO |
| **Evolución comercial posterior** | Cupos por plan y pagos futuros | No forma parte del release de presentación salvo aprobación contractual independiente |

## 3. Decisiones confirmadas que no debemos reinterpretar

- **ADMIN global:** superusuario de plataforma, puede operar sin tenant seleccionado y crear el primer OWNER mediante ADR-006.
- **OWNER:** administrador del negocio/tenant; puede crear y administrar MEMBER **dentro de los permisos del contrato**; no puede crear ni asignar otro OWNER. Solo ADMIN asigna o transfiere OWNER.
- **MEMBER:** usuario operativo tenant-scoped, sin facultad de administrar usuarios ni de crear tenants.
- **Un OWNER por tenant comercial operativo** como política de negocio confirmada por el owner; el Backend actual **aún no garantiza** la unicidad de asignaciones.
- **Un mismo User puede tener membresías en varios tenants** y roles distintos por tenant. `UserTenant` lo modela, pero la invitación y vinculación públicas requieren diseño específico.
- **No enviar contraseñas por correo** en el onboarding nuevo. El destinatario establece su propia contraseña; luego usa el login normal.
- **ADR-006 es registro asistido por ADMIN, no registro público, ni OAuth**. El documento aprobado fija cinco operaciones nuevas y reglas de email/flag/seguridad.
- **No pagos electrónicos en este avance**. La analogía con membresías de pago es visión de producto, no transacciones implementadas.
- **El acceso a Engine/Service y Jobs mutantes continúa fuera del Core**; separar de este release.

## 4. Decisiones técnicas que debe resolver el owner antes de promoción

Las filas siguientes **no se consideran aprobadas por existir aquí**. Donde la política comercial ya está fijada, se solicita definir la implementación y el comportamiento HTTP concreto.

| ID | Tema | Pregunta de decisión | Recomendación | Gate |
| --- | --- | --- | --- | --- |
| AV2-D01 | Falla Users ACME | ¿Cuál es la causa HTTP/JSON/DB? | **Investigar, no tomar atajo visual**. Corregir P1 y prueba de regresión | Gate 0 |
| AV2-D02 | Dato `NULL` | ¿Se observó `users.platform_role`, `users.role_id` inexistente o `user_tenants.role_id`? | Confirmar esquema y `UserTenant`; `platform_role=NULL` es normal para MEMBER | Gate 0 |
| AV2-D03 | Asignación OWNER | ¿Cómo deniega NestJS `roleId` OWNER cuando el actor es OWNER? | 403 transaccional tanto en POST como PATCH; ADMIN-only | Gate 1 |
| AV2-D04 | Unicidad OWNER | ¿Cuál es mecanismo atómico y política ante tenant técnico sin OWNER? | Verificar invariant de un OWNER por tenant comercial operativo y carrera; no cambiar silenciosamente `POST /tenants` heredado | Gate 1 |
| AV2-D05 | Baja de usuario | ¿Quién puede desactivar globalmente a un User con varias membresías? | Reservar baja global a ADMIN; crear semántica local si realmente se necesita | Gate 1 |
| AV2-D06 | Selector rol | ¿Se incorpora FE-04 en la adaptación Flutter? | Solo después de validar permisos Backend; OWNER no ve ni envía OWNER | Gate 2 |
| AV2-D07 | Invitation MEMBER | ¿Entra en esta presentación o en incremento separado? | **Diferir** salvo ADR/contrato/seguridad/pruebas adicionales explícitamente aprobados | Gate 2 |
| AV2-D08 | Identidad existente | ¿Qué ocurre si email invitado ya existe en otro tenant? | No duplicar identidad; diseñar vinculación segura aparte. Mantener 409 ADR-006 actual | Gate 2 |
| AV2-D09 | Recuperación correo | ¿Proveedor gratuito y recuperación manual listos? | Requiere cuota verificada, DNS, variables y smoke controlado; sin costo automático | Gate 1/3 |
| AV2-D10 | Feature flag | ¿Quién habilita `TENANT_REGISTRATION_ENABLED` y cuándo? | Owner tras desplegar Backend/Flutter compatibles y comprobar gates | Gate 3/4 |
| AV2-D11 | FE-07 Jobs seed | ¿Se corrige ahora? | Diferir; corregir seed en Backend aislado, no ampliar enum | Postavance |
| AV2-D12 | UX validación | ¿Qué formularios requieren mensajes por campo, foco y accesibilidad? | Cambios pequeños de P2; no alterar API; priorizar alta, activación y recuperación | Gate 2 o postavance |
| AV2-D13 | Política de rollback | ¿Se conserva feature OFF si falla nuevo flujo? | Sí; revertir artefacto de frontend por promoción/rollback de hosting y backend por release aprobado; migrations no se revierten a ciegas | Gate 4 |
| AV2-D14 | Identidad deploy | ¿Cómo anotar revisiones efectivamente servidas? | Registrar SHA/configuración en metadata de Vercel y Render, no inferir por health | Gate 4 |
| AV2-D15 | Plan comercial | ¿Se fija cupo de MEMBER en esta entrega? | No. Documentar regla futura sin construir cuota ni cobros | Postavance |

**Prioridad de decisión:** AV2-D01/02 y D03/04/05 antes de permitir cambios de administración de accesos en producción. No usar un `PATCH` inseguro para introducir FE-04.

## 5. Recepción del trabajo de Ángel — checklist auditable

**R0 — Identidad y diff**

- Solicitar rama, HEAD SHA, base merge y PR del Backend. Confirmar ancestro `b51b265` o explicar divergencias; detectar commits de Service/Jobs fuera de alcance.
- Comprobar árbol de trabajo, conflictos, cambios de Prisma, migraciones, DTO, Guards, Users, Auth, Tenants, SMTP, Swagger, tests y nuevos secretos requeridos.
- Exigir un inventario de rutas y cambios frente a las 33 operaciones Core. ADR-006 agrega **solo 5 operaciones** objetivo: `/tenants/register`, `GET /tenants/{id}/onboarding`, `POST /tenants/{id}/resend-welcome`, `/auth/redeem-first-access`, `/auth/complete-first-access` (todas bajo `/api/v1`). No anunciar 38 operaciones efectivas hasta comprobar el código/Swagger desplegado.

**R1 — Arquitectura y migraciones**

- Revisar migraciones *aditivas*, `mustChangePassword` con default false en usuarios anteriores, índices de correo case-insensitive y manejo de colisiones antes de migrar; no reescribir migración inicial.
- Auditar estructura `TenantOnboarding`, `ActivationLinkToken`, `FirstAccessChallenge`, `DeliveryAttempt`, constraints y estados; nunca persistir token en claro.
- Exigir rollback planificado: qué pasa con cuentas activadas y pendientes si se revierte versión de código; deshabilitar altas no revierte automáticamente una migración ni una contraseña.
- Comprobar reglas comerciales OWNER/MEMBER con tests negativos de POST/PATCH y concurrencia. Si ADR-006 no incluía la corrección y depende de otro cambio, clasificarlo como PR separado/bloqueante según impacto.

**R2 — Seguridad del onboarding**

- ADMIN sin tenant crea tenant + primer OWNER en transacción atómica; `POST /tenants` heredado mantiene semántica técnica.
- Email existente y slug duplicado: 409, sin escritura parcial. Primer OWNER `mustChangePassword=true`; sin contraseña válida antes de activar.
- Enlace opaco single-use 24h, desafío 15min sin exceder vencimiento del enlace; consumo atómico; tras contraseña 200 `LOGIN_REQUIRED`; login normal no cambia forma del `AuthContext`.
- `JwtStrategy`, `/auth/login`, `/auth/me`, `/auth/select-tenant`, `PATCH /users` y rutas protegidas no permiten bypass por cuenta pendiente.
- Reenvío invalida generación y desafíos previos; limitación 1/min y 5/h, timeout 15s, lease 60s; fallo SMTP no revierte la creación y respuesta distingue ACCEPTED/FAILED/UNKNOWN sin prometer entrega inbox.
- Rate limiting/errores públicos y cadenas maliciosas: no filtrar tokens, secretos, mensajes internos ni enumerar usuarios ante actores no autorizados.
- Feature flag OFF rechaza nuevas altas/reenvíos sin escrituras, pero permite completar enlaces válidos ya emitidos y mantiene bloqueo de cuentas pendientes.

**R3 — SMTP y costo**

- Proveedor sin cargo automático y cuotas documentadas; variables del secret manager y DNS SPF/DKIM/DMARC/TLS; pruebas con transporte local ficticio y con correo de ensayo autorizado.
- Validar que falla de envío no genera doble OWNER, doble envío ni tokens reutilizables; 201 indica persistencia, no entrega al buzón.

**R4 — Contrato**

- Código, Swagger implementado y `Docs/Contracts/platform-api.tenant-registration.approved.yaml` coinciden para tipos, códigos, seguridad, errores, nullability y semántica.
- No sobreescribir el YAML Core con un archivo futuro sin implementación. Backend es autoridad antes de adaptar Flutter.

## 6. Adaptación Flutter — PR independiente

1. Ángel parte de Flutter `main=e752f6c` (o su sucesor autorizado), no de `dev` experimental. Crear rama segura; trabajar sobre `PlatformApi`, repositorios, Riverpod y GoRouter existentes.
2. Añadir ruta pública `/activate` solo cuando los endpoints y guardas Backend estén presentes y validados. Fragmento hash del router: capturar código temprano, **limpiarlo de URL/historial inmediatamente**, mantenerlo solo en memoria; no logs/storage persistente/analytics.
3. Pantalla ADMIN para registro tenant+primer OWNER conforme cuerpo `{tenantName,tenantSlug,ownerName,ownerEmail}`. Presentar estado `PENDING_FIRST_ACCESS` y delivery sin confundir envío aceptado con correo entregado.
4. ADMIN consulta onboarding y solicita reenvío bajo los rate limits. Error/feedback útil sin revelar detalles internos.
5. Pantalla pública canjea activation token, solicita contraseña conforme política, completa primer acceso y dirige al login normal sin crear sesión ficticia.
6. Mantener `POST /users` Core V1 operativo y **diferenciado** del registro del primer OWNER. Cualquier invitación MEMBER requiere contrato nuevo; no suponer que viene incluida.
7. Si se incorpora selector de rol de usuario, demostrar que API Backend deniega crear o promover OWNER desde OWNER y bloquea más de un OWNER por tenant; no basarse únicamente en UI.
8. Incorporar estados Loading/Empty/Error/Success, mensajes de campo, labels/foco/accesibilidad, bloqueo de doble submit, cancelación, expiración, enlaces inválidos/reusados y navegación profunda.
9. Añadir tests unitarios/widget/contrato y E2E local completo sin sacrificar los 279 tests anteriores; número exacto final depende de la suite ejecutada.

## 7. Matriz de aceptación E2E local — Core + ADR-006

| Caso | Actor | Camino y expectativa | PostgreSQL/seguridad |
| --- | --- | --- | --- |
| CORE-REG-01 | ADMIN | Login, discover A/B, cambiar tenant | Identidad/tenant correctos; cero mezcla de datos |
| CORE-USER-01 | ADMIN/OWNER | Crear USER V1 en tenant permitido | `User`, `UserTenant.roleId` válido, relectura, MEMBER por defecto |
| CORE-USER-02 | OWNER/MEMBER | Intentar asignar OWNER desde API y UI | 403, sin cambios ni segundo OWNER |
| CORE-USER-03 | ADMIN/OWNER | Listado en ACME y Empresa B | Parser, meta, membresías y ausencia de fuga cruzada |
| CORE-CSV-01 | ADMIN/OWNER | Importar CSV con decisiones admitidas | Asociación y totales correctos, sin duplicación; seed intacto |
| CORE-ISOLATION | OWNER/MEMBER A/B | IDs cruzados, cambio de tenant, requests tardías | 403/404 y no escrituras ajenas |
| REG-01 | ADMIN sin tenant | Registro de empresa+OWNER | Tenant, Role OWNER/MEMBER, User+Membership, onboarding y token/attempt atómicos |
| REG-02 | OWNER nuevo | Recibe enlace de prueba, canjea, fija contraseña, inicia sesión | Hash, consumo single-use, `mustChangePassword=false`, onboarding COMPLETED |
| REG-03 | Public/OWNER | Token inválido, caducado, replay, doble canje | 401/409 contractual, ningún JWT emitido antes de completar |
| REG-04 | ADMIN | Resend de onboarding pendiente | Nueva generación; token/desafío anterior inutilizable; límites 429 |
| REG-05 | ADMIN | Simular fallo SMTP | Registro 201 persistido, estado FAILED/UNKNOWN; reenvío controlado |
| REG-06 | OWNER/MEMBER | Intentos prohibidos de `/tenants/register` y `resend` | 403/401 sin escrituras |
| REG-07 | ADMIN | Flag OFF y rutas nuevas | Alta/reenvío 503 sin escritura; completar pendientes sigue posible |
| REG-08 | ADMIN | Slug/email duplicado y concurrencia | 409, cero registros huérfanos, unicidad case-insensitive |
| REG-09 | Core existente | Repetición de Auth/Users/Campaigns/Prospects/CSV/Dashboard/Jobs | Sin regresiones; Jobs operaciones futuras siguen 503 |
| REG-10 | Seguridad | JWT emitido antes/revocado/pending, PATCH bypass, cambio de rol | Backend rechaza bypass; snapshots normales según política Core |

**Tipos de cobertura:** marcar `UI_TO_DB`, `UI_HTTP`, `HTTP_SQL` por escenario. `PASS` exige ejecución y resultado verificable de su alcance, no una extrapolación de otros casos. Repetir suite completa al menos una vez tras corregir fallos; almacenar SHAs, HTTP sanitizado, verificaciones SQL y cleanup. Usar buzón SMTP ficticio local para tokens.

## 8. Gates operativos para el owner

| Gate | Criterio de salida | Si falla |
| --- | --- | --- |
| **G0 — Baseline** | Identidad de commits, Core reproducible; Users ACME reparado y rol/membresía esclarecidos | No afirmar Core completamente cerrado; corregir o acotar demo |
| **G1 — Backend ADR-006** | Diff revisado; migración aditiva ensayada con copia sintética; tests unitarios/HTTP/PostgreSQL, permisos, correo, concurrencia y 5 endpoints contrato | No merge Backend |
| **G2 — Flutter ADR-006** | PR independiente, análisis y CI verde, contratos tipados, UI accesible y Core sin regresiones | No merge Flutter |
| **G3 — E2E integrado local** | Core + nuevos flujos, A/B multi-tenant, 2 ejecuciones reproducibles, cleanup, seguridad, SQL, sin FAIL P1/P0 | No habilitar funciones; usar presentación Core |
| **G4 — Promoción controlada** | Aprobación owner, plan de activación/rollback, recursos y variables validados; Backend flag OFF antes de cliente | No merge/despliegue |
| **G5 — Smoke productivo** | Auth/tenant/Users A/B, dashboard, campañas, prospectos/CSV controlado, nuevas pantallas y correo de prueba autorizado; checks postdeploy | Desactivar flag y/o rollback según matriz |
| **G6 — Decisión de demo** | Alcance aprobado expresamente según capacidades operativas demostradas | Presentar solo Core validado |

Criterio duro: ningún P0/P1 reproducible abierto en funciones que se vayan a mostrar; ningún test `BLOCKED` o `NOT RUN` equivale a `PASS`. Un éxito de CI o de screenshot aislado no autoriza release sin las demás condiciones.

## 9. Orden de promoción con despliegue automático desde main

**Precondición:** respaldos/plan de recuperación, migración ensayada, compatibilidad hacia atrás revisada, autorización owner y proveedor SMTP validado.

1. Registrar versiones previas en Render y Vercel, estado de variables y salud, conteos sintéticos de control y respaldo de PostgreSQL mediante procedimiento administrado. No guardar secretos en evidencia.
2. **Backend PR**: fusionar solo tras G1. Render desplegará `main` automáticamente. Feature flag `TENANT_REGISTRATION_ENABLED=false`. Verificar Core 1.0.0 y sus 33 operaciones sin regresión. Si migración es aditiva, el Backend anterior debe seguir funcionando sobre esquema ampliado antes de continuar.
3. **Flutter PR**: fusionar solo tras G2/G3, con Backend compatible. Vercel publicará el cliente. Revisar bundle/origen API, rutas hash SPA, CORS, acceso público, login y Core.
4. Habilitar flag por operación autorizada del owner (posible redeploy de Render) tras confirmar que el cliente ya puede completar activaciones. Probar cuentas sintéticas controladas y alcance mínimo del correo.
5. Ejecutar smoke G5, registrar deploy IDs/SHA si hosting los ofrece y decidir presentación G6.

**Importante:** `GET onboarding` y canje/completado de enlaces emitidos pueden seguir disponibles con flag OFF según ADR-006. Apagar flag **no** cancela onboarding pendiente. Validar la semántica real antes de usarlo como contención.

## 10. Rollback y contención de incidentes

| Incidente | Contención inmediata | Reversión / recuperación | Restricción |
| --- | --- | --- | --- |
| Error en UI nuevo, Core sano | Flag OFF para nuevas altas/reenvíos si corresponde | Restaurar deployment Vercel anterior o revertir PR frontend aprobado | Revisar que cuentas pendientes puedan completar onboarding |
| Error Backend nuevo con Core afectado | Detener altas, revisar health/logs sanitizados; evaluar desactivar flag | Rollback de release Render a artefacto compatible o PR revert controlado | **No** revertir migración aditiva a ciegas |
| Migración incompatible, corrupción o pérdida de datos | Suspender operaciones que escriban; conservar evidencias y snapshots | Procedimiento específico de restauración probado por DBA/owner | Restaurar BD puede perder datos nuevos; requiere decisión explícita |
| Falla correo o proveedor/cuota | Bloquear reenvíos adicionales, revisar deliveryStatus | Recuperación ADMIN manual bajo reglas; no recrear tenants | 201 no significa correo entregado; tokens nunca se recuperan en claro |
| Fuga de credencial/token | Deshabilitar ingreso afectado y rotar secretos bajo plan | Revocar/invalidar credenciales, investigar accesos, informar según impacto | No registrar tokens en capturas/logs |
| Solo Users ACME falla en Core | No mostrar Users ACME como validado; investigar diagnóstico | Hotfix pequeño en PR y smoke posterior | No ocultar filas ni tocar datos reales sin auditoría |

**Rollback no es simétrico.** Código Flutter, Backend, flags, migraciones y datos son capas distintas. Antes del merge demostrar qué versiones del Backend pueden leer el esquema nuevo y cómo proteger cuentas pendientes ante una vuelta al código anterior. No usar `prisma migrate reset`, `drop`, `down -v` ni limpieza de Supabase productiva.

## 11. Decisión del alcance de presentación — dos rutas

### Ruta A — Core 1.0.0 (fallback legítimo)

**Elegir si:** ADR-006 incompleto, migraciones/correo no validados, flags o roles inseguros, P1 en nuevo flujo, o tiempo de QA insuficiente. Demostrar login, ADMIN y tenant switch A/B, campañas, prospectos CSV, dashboard, permisos actuales y Jobs de lectura/no integración. **Antes:** resolver Users ACME o excluir ese listado de afirmaciones de cobertura total y declarar el hallazgo si preguntan.

**Mensaje técnico correcto:** plataforma multitenant operativa con Backend NestJS, cliente Flutter, PostgreSQL administrado, JWT/roles y operaciones Core probadas; prospección automática/onboarding empresarial extendido quedan fuera de lo habilitado.

### Ruta B — Core + ampliación ADR-006

**Elegir solo si:** G0–G5 PASS; contrato 5 endpoints efectivamente implementado, correo y activación del primer OWNER completados E2E, rol y unicidad seguros, Core sin regresiones. Mostrar creación asistida ADMIN de tenant y primer OWNER, enlace, nueva contraseña y login normal; dashboard y aislamiento entre empresas. **No** mostrar invitación MEMBER ni cobros como implementados si no hay contrato/QA independiente.

**Mensaje técnico correcto:** Core 1.0.0 conservado y ampliado por onboarding asistido de primer OWNER, con protección multi-tenant. El modelo prepara futuras membresías, pero todavía no procesa pagos ni aplica cuotas comerciales.

## 12. Handoff y evidencia mínima que debe entregar Ángel

- SHA base y HEAD de ambos PR, diff por módulo y checklist de migraciones/flags/secretos sin valores.
- Contrato implementado y diferencias justificadas respecto a ADR-006/OpenAPI aprobado.
- Matriz HTTP de actor × endpoint × estado, incluyendo ADMIN sin tenant, OWNER y MEMBER.
- Resultado unitario + integración PostgreSQL real + concurrency + SMTP simulado, con `PASS/FAIL/BLOCKED/NOT RUN` y comandos.
- Prueba UI real Flutter→NestJS→PostgreSQL para REG-01..09, con capturas sanitizadas y limpieza.
- Procedimiento de reenvío/recuperación y límites del proveedor gratuito.
- Plan rollback compatible con las migraciones y cuentas pendientes.
- Lista de decisiones que requieren owner, riesgos residuales, prohibición de merge sin aprobación.

## 13. Preguntas concretas para resolución por el owner

1. ¿Aprobamos corregir el control de asignación OWNER y unicidad en el mismo PR de Ángel si su diff ya lo toca, o exigimos PR Backend separado de hardening previo al merge?
2. ¿Confirmamos diferir **invitación de MEMBER** y **vinculación de correo existente a otro tenant** hasta después de la presentación, manteniendo ADR-006 íntegro?
3. ¿Un OWNER puede modificar `status` global de un User local o solo quitarle acceso a su tenant? Recomendado: solo local; desactivación global ADMIN.
4. ¿FE-04 selector de rol para ADMIN se incorpora ahora o postavance, una vez que Backend imponga restricciones?
5. ¿Cuál es el procedimiento aprobado de habilitación/deshabilitación del flag en Render y de rollback de ambos servicios?
6. ¿Qué flujo de prueba remota de activación con correo sintético y datos sintéticos autoriza el owner en producción?

**Sin respuesta no se asumirán aprobadas funcionalidades extra**. Continuar con ADR-006 tal como está definido y bloquear solo los puntos inseguros.
