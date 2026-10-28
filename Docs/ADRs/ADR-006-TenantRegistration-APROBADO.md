# ADR-006 — Registro asistido de tenants y activación del primer OWNER

**Estado:** APROBADO — DISEÑO CONTRACTUAL; **NO IMPLEMENTADO**  
**Fecha de aprobación:** 2026-10-27 (hora de Tijuana)  
**Rama prevista de implementación:** `feat/tenant-register` (no se autoriza merge ni despliegue por aprobar este ADR)  
**Autoridad de decisiones de arquitectura y producto:** owner técnico del proyecto.  
**Responsable delegado de diseño técnico, implementación, migraciones, pruebas y documentación:** Ángel.  
**Contrato adjunto:** [`platform-api.tenant-registration.approved.yaml`](./platform-api.tenant-registration.approved.yaml).  
**Baseline inmutable para este trabajo:** `saas-platform-backend/main@b51b265f1a545fa915f1dd1c57ef2f5858ec6492` (core 1.0.0).  
**Compatibilidad a preservar:** Flutter `saas-platform-client/main@7731649a2c69b45cb9776d02de4a6105d6fd9886` mientras se estabiliza el Avance 2.

> **Alcance de esta aprobación:** aprueba reglas y contrato objetivo para una versión posterior; NO confirma tablas, rutas, correo, tokens ni interfaz implementados, ni habilita producción. No se han modificado repositorios ni contratos activos. El trabajo de Flutter 1.0.0 y la integración real del Prospector Service están fuera de este cambio.

## 1. Motivación, autoridad y compatibilidad

Un `ADMIN` global debe dar de alta una organización y su primer `OWNER` sin abrir registro público ni exigir un tenant seleccionado. El `OWNER` recibirá por correo un **enlace de activación de un solo uso**, establecerá su propia contraseña y, a continuación, iniciará sesión normalmente. No se envían contraseñas por correo.

Se conservan las decisiones de ADR-004 y ADR-003: Shared Database + Shared Schema + `tenantId`; `TenantContext` y autorización en servicios; ADMIN global, OWNER/MEMBER tenant-scoped; JWT normal HS256 de 8 horas como snapshot, sin refresh ni OAuth; SEC-01 para identidad global; no RLS ni middleware Prisma obligatorio añadidos por ADR-006. El registro no cambia el tenant seleccionado ni el JWT del ADMIN.

**Fuentes de arquitectura:** `Docs/ADRs/ADR-004-CommonBaseline.md`, `Docs/ADRs/ADR-003-AuthSecureTransversal.md`, `MODULE-DEVELOPMENT.md`, `Docs/Avance2/CORE_V1_VALIDATION.md` y `Docs/Contracts/platform-api.v1.yaml` del Backend main. Esta decisión **amplía** el baseline; no reescribe retrospectivamente sus contratos.

## 2. Registro de decisiones cerradas (D01–D22)

| ID | Decisión aprobada y efecto obligatorio |
|---|---|
| D01 | Solo ADMIN global autenticado registra tenant y primer OWNER, aun con `tenantId=null`. Prohibidos self-register y creación desde OWNER/MEMBER. |
| D02 | `POST /api/v1/tenants/register` es la vía de **alta de negocio completa**. `POST /api/v1/tenants` conserva exactamente su semántica actual como provisión administrativa/compatibilidad, sin correo ni OWNER implícito. |
| D03 | Tenant/slug existente (aunque carezca de OWNER): `409`, sin mutación ni correo. Regularización de organizaciones preexistentes es procedimiento administrativo separado, no parte de este contrato. |
| D04 | Correo global existente: `409`, sin vincular cuentas, restablecer credenciales ni revelar membresías. Invitación de usuarios ya existentes queda fuera. |
| D05 | Tenant nuevo `ACTIVO`; onboarding `PENDING_FIRST_ACCESS` hasta completar. Estados de entrega/activación independientes. |
| **D06** | **Enlace de activación**, no contraseña temporal enviada por email. Un secreto opaco de alta entropía se coloca en fragmento de enlace HTTPS compatible con el routing Flutter; el navegador lo canjea por un desafío breve. |
| D07 | Ni el enlace ni el desafío son JWT; no conceden acceso a módulos, tenant ni API de sesión. Mientras el primer acceso esté pendiente se rechaza cualquier JWT normal de esa identidad. |
| **D08** | Interpretación coherente con D06: **enlace válido 24 h** desde su generación; **desafío de canje válido 15 min** como máximo. Nueva contraseña mínimo 10 caracteres Unicode, letra+número+especial, máximo 72 **bytes UTF-8** para bcrypt; hash bcrypt costo 12. No existe contraseña temporal enviada al usuario. |
| D09 | Tras establecer contraseña se devuelve `LOGIN_REQUIRED`; se exige login habitual con contraseña nueva, sin sesión automática. |
| D10 | Bloqueo backend del bypass por login, `JwtStrategy`, `/auth/me`, `/auth/select-tenant`, `PATCH /users` u otra ruta alternativa. Frontend no es control de seguridad. |
| D11 | Email global normalizado y garantía de unicidad case-insensitive en PostgreSQL, con auditoría previa de colisiones, sin fusión automática. Consistencia en login, registro y mutación de emails existentes. |
| D12 | `201` si la transacción crea las entidades aunque el email falle o quede incierto; `deliveryStatus` explícito; jamás afirmar entrega real a partir de aceptación SMTP. |
| D13 | Consulta y recuperación/reenvío de onboarding solo ADMIN autenticado. |
| D14 | Reenvío genera **nuevo enlace** y nueva generación, invalida enlace y desafíos anteriores. No restablece contraseñas ni reenvía el token anterior. Prohibido tras completar. |
| D15 | Máximo 1 intento de entrega/minuto y 5/hora por onboarding (historial persistente, incluido intento inicial); timeout transporte 15 s; lease 60 s. Desafíos y canjes con límites antiabuso. |
| D16 | Recuperación **manual** ante fallo/reinicio: sin worker, outbox durable ni envío automático en esta versión. `UNKNOWN` representa incertidumbre; no prometer exactly-once. |
| **D17** | Proveedor de correo con **plan gratuito efectivo y sin facturación automática**. Ángel seleccionará integración/proveedor tras verificar cuota, requisitos de dominio y términos; owner autoriza cualquier costo/servicio pago antes de usarse. Desarrollo con buzón o transporte simulado. |
| D18 | Mantener rutas `/api/v1`. La ampliación objetivo se identifica documentalmente como `1.1.0` (aprobada, NO desplegada), sin alterar el contrato del release core 1.0.0. |
| **D19** | **Resolución de conflicto con D06:** se conserva el principio de respuestas discriminadas por `action`, pero **NO se cambia `/auth/login` a `oneOf`**: con enlace no existe contraseña de primer acceso que permita producir esa variante de login. El `oneOf` propuesto queda sustituido por `POST /auth/redeem-first-access`, que responde `CHANGE_PASSWORD_REQUIRED`, y `POST /auth/complete-first-access`, que responde `LOGIN_REQUIRED`. `POST /auth/login` mantiene `AuthContext` en 200 para sesiones normales. |
| D20 | `TENANT_REGISTRATION_ENABLED=false` por defecto. Bloquea **solo nuevas altas y reenvíos** cuando está desactivado; GET onboarding y canje/completado de tokens ya emitidos deben seguir disponibles. Bloqueo de cuentas pendientes siempre obligatorio. |
| D21 | Migraciones Prisma/SQL **aditivas**, no reescribir migración inicial; usuarios existentes conservan su login; rollback no puede reabrir cuentas pendientes ni volver inseguro el modelo. |
| D22 | Sin merge/despliegue hasta unitarias + HTTP + PostgreSQL real + seguridad/concurrencia/correo + contrato válido + regresión del core 1.0.0, y revisión explícita del owner. |

**D06 × D08 × D19:** la frase anterior de “contraseña temporal válida 24 h + login temporal con `oneOf`” es **sustituida**, no conservada en paralelo. La misma intención de seguridad se materializa mediante enlace de 24 h, canje y desafío de 15 min. No crear una contraseña temporal ficticia solo para preservar el `oneOf` anterior.

## 3. Registro global y operación administrativa

**Operación:** `POST /api/v1/tenants/register`. Requiere JWT Bearer normal y rol `ADMIN`; no requiere tenant activo. Cuerpo cerrado: `tenantName`, `tenantSlug`, `ownerName`, `ownerEmail`. Nombres: trim, no vacíos, máximo 120 caracteres; slug: minúsculas, 3–63 caracteres alfanuméricos y guiones interiores; email: válido, máximo 254, trim + normalización uniforme a minúsculas. Ni contraseñas, ni `tenantId`, ni destinatarios alternativos, ni URL de activación en el body.

En una transacción atómica: crear tenant `ACTIVO`, roles OWNER/MEMBER, usuario OWNER `ACTIVO` sin `platformRole`, membresía `UserTenant(OWNER)`, onboarding pendiente, generación y hash de token de activación + registro del intento de envío. El usuario nuevo tiene `mustChangePassword=true`; no es necesario almacenar ni enviar una contraseña temporal. Como el esquema actual exige `passwordHash`, Ángel debe elegir un **verificador criptográfico inaccesible e inutilizable** mientras el usuario esté pendiente; siempre validar `mustChangePassword` **antes** de emitir JWT o dar acceso. No emitir nunca una contraseña utilizable en respuesta, correo o logs.

Una alta concurrente con el mismo slug o correo falla con `409` y no deja registros parciales. No se reenvía por reintento del POST; se consulta el onboarding y se usa el endpoint ADMIN de reenvío. La existencia de un correo se revela exclusivamente a ADMIN autorizado.

`POST /api/v1/tenants` **permanece intacto** (crea Tenant + Role). Es la vía técnica heredada, no el alta asistida de negocio. Las organizaciones anteriores sin OWNER no se regularizan implícitamente ni se re-registran.

## 4. Persistencia aprobada como invariantes (implementación física delegada)

- **User:** marca persistente `mustChangePassword` con default `false` para registros existentes. No exponerla como campo editable a través de `Users` DTO. No añadir `temporaryPasswordExpiresAt` porque D06 elimina contraseñas temporales por correo.
- **TenantOnboarding:** asociación exclusiva por tenant (`tenantId` único), primer OWNER, ADMIN creador, fechas, activación `PENDING_FIRST_ACCESS|COMPLETED`, generación, deliveryStatus, intento y lease. La activación y el delivery no comparten una sola columna de estado.
- **ActivationLinkToken:** solo **hash** de token aleatorio criptográficamente seguro de **al menos 32 bytes**; onboarding, owner, generación, expiración (24 h), marca de canje/consumo. No almacenar token recuperable.
- **FirstAccessChallenge:** secreto opaco diferente, hash persistido, user/onboarding/generación, expedición, expiración (15 min) y consumo. No es JWT.
- **DeliveryAttempt:** persistencia del número/fecha/resultado de intentos, `attemptId` y lease para límites tras reinicio, concurrencia y auditoría. No persistir cuerpos de correo ni tokens en claro.

Ángel define nombres Prisma/SQL y constraints finales, con pruebas de transacciones concurrentes. Proteger las transiciones de generación, canje, reenvío y completado bajo control transaccional equivalente a serialización: un reenvío tardío no puede reactivar onboarding completado ni invalidar una contraseña nueva. El TTL se verifica en el servidor con reloj autoritativo.

**Correo global:** auditar primero datos actuales; definir constraint/index único case-insensitive validado contra concurrentes. Considerar comportamiento de `findUnique`, login, `POST /users`, `PATCH /users` y seeds en la migración. No fusionar ni renombrar cuentas automáticamente.

## 5. Entrega del enlace de activación

Tras **commit** se genera el email de bienvenida texto + HTML escapado con organización, correo, duración y enlace. El enlace se construye exclusivamente desde configuración confiable `PLATFORM_ACTIVATION_URL`, nunca desde `Host` o el body del ADMIN. Producción exige HTTPS.

**Formato compatible con el router web actual basado en hash:** URL pública con ruta bajo fragmento, p. ej. `https://<frontend>/#/activate?code=<token>`; el fragmento **no se envía al servidor HTTP de alojamiento ni al encabezado Referer**, aunque puede permanecer en historial o estar visible a scripts de la misma página. Flutter debe implementar una ruta pública `/activate`, capturar el secreto **de forma temprana**, limpiarlo inmediatamente de la URL/historial, mantenerlo solo en memoria y enviarlo en el **body** a `POST /api/v1/auth/redeem-first-access`. No almacenar el secreto en analytics, logs, storage persistente, capturas, monitoreo de errores, solicitudes de terceros ni rutas de GoRouter. Sin scripts/recursos de terceros en esa pantalla; `Cache-Control: no-store` para respuestas sensibles.

Un enlace puede canjearse **una sola vez** dentro de sus 24 h. El canje consume el token de enlace y emite un desafío distinto, también de un solo uso, válido 15 min. Si la respuesta del canje se pierde o el desafío expira antes de completar, la recuperación de esta versión requiere reenvío manual ADMIN (no regenerar enlaces reutilizando el anterior). Esta limitación de UX se acepta para preservar garantías de un solo uso y cero costos.

**No aceptar enlaces anteriores** tras reenvío: la generación sustituye la previa, invalida enlaces pendientes y desafíos del onboarding. No hay “confirmación de entrega” garantizada por la respuesta del proveedor.

## 6. Flujo de primer acceso y autenticación

1. ADMIN crea organización mediante `/tenants/register`. La API devuelve `201` con tenant + metadatos de onboarding, nunca token, enlace ni contraseña. La creación queda persistida incluso si falla el email.
2. OWNER recibe el enlace HTTPS de 24 h. Cliente Flutter público carga la ruta de activación sin requerir JWT ni tenant y retira el secreto de la URL tras leerlo.
3. Flutter llama **`POST /api/v1/auth/redeem-first-access`** con `{activationToken}` en JSON, sin Bearer. El servidor comprueba hash, generación, pendiente, usuario y tenant activos, expiración, límite, uso único; en transacción consume enlace y crea desafío. Responde `200` con sobre `{success:true,data:{action:'CHANGE_PASSWORD_REQUIRED',firstAccessToken,expiresAt}}`. Credencial opaca limitada a completar primer acceso.
4. Flutter pide contraseña nueva y envía **`POST /api/v1/auth/complete-first-access`** con `{firstAccessToken,newPassword}`. Validaciones de política, token, generación, usuario/tenant activos, estado pendiente y consumo único. En transacción, fija hash bcrypt costo 12, limpia `mustChangePassword`, marca onboarding `COMPLETED` y anula demás desafíos/enlaces; dos confirmaciones simultáneas no pueden terminar ambas en éxito.
5. Responde `200` con `{success:true,data:{action:'LOGIN_REQUIRED'}}`. Cliente inicia sesión usando **`POST /api/v1/auth/login`** con email y nueva contraseña; obtiene el `AuthContext` **sin cambios** y continúa selección de tenant conforme ADR-004.

Mientras `mustChangePassword=true`, login normal rechaza genéricamente con `401`, sin emitir JWT, y la estrategia JWT rechaza tokens previos o emitidos por error. `/auth/me`, `/auth/select-tenant` y rutas protegidas no permiten bypass. `PATCH /users` u operaciones administrativas no pueden establecer contraseña de cuenta pendiente ni cambiar estados/challenges para evadir activación. Esto **no** implica revalidar roles o memberships en cada request: el JWT de los demás usuarios conserva el snapshot aprobado.

Errores de tokens vencidos, consumidos, desconocidos o de generación anterior: `401` genérico, evitando distinguir situaciones. Contraseña débil: `400`; limitación temporal: `429`. Rate limit inicial de login (5/60s/IP) se conserva; canje y completado también tienen límite por IP y por credencial/identificador, de forma persistente o equivalente bajo concurrencia. No usar Bearer JWT para estos dos endpoints; el token del body es su autorización restringida.

## 7. Estado del email, límites gratuitos y recuperación

**Delivery**: `PENDING`, `SENDING`, `ACCEPTED`, `FAILED`, `UNKNOWN`. `ACCEPTED` significa aceptado por el transporte, **no** entrega al buzón. **Activación**: `PENDING_FIRST_ACCESS` o `COMPLETED`, independiente del delivery.

Se intenta enviar tras el commit; máximo 15 s por operación SMTP. Reserva atómica del intento con `attemptId` y lease de 60 s; si el proceso termina en mitad del envío, al vencer el lease el estado queda/puede consultarse como `UNKNOWN`, sin reenvío automático. Los callbacks/respuestas tardíos solo actualizan el intento y generación vigentes. Conflictos de intento concurrente o onboarding ya completado: `409`.

**`POST /tenants/{id}/resend-welcome`:** ADMIN, sin body ni destinatario alterno; solo onboarding pendiente. Genera nuevo enlace y generación, anula la anterior, crea un intento, y envía. Nunca reenvía el enlace antiguo. Límite persistente: al menos 1 minuto entre intentos de envío y máximo 5 intentos de entrega por onboarding en 60 minutos (incluido primer envío); al exceder, `429`. La respuesta `200` indica intento procesado, aunque transporte FAILED/UNKNOWN. Si el intento anterior sigue activo, `409`.

**Proveedor sin gasto:** Ángel investiga e implementa proveedor con nivel gratuito realmente utilizable y verificado a fecha de implementación: límite suficiente para demo, soporte TLS y envío seguro, reputación y requisitos de DNS/remitente, posibilidad de conocer cuota y deshabilitar envío antes de facturar, sin cargos automáticos. No se autoriza contratar plan ni introducir tarjeta, ni consumos de pago sin aprobación explícita. Si cuota gratuita o SMTP no están disponibles, registrar envío `FAILED/UNKNOWN` y detener nuevos intentos conforme reglas, **sin eliminar tenants creados ni intentar proveedor de pago por fallback**. Pruebas usan stub/SMTP de laboratorio y no consumen cuotas de producción.

Configurar por variables/secret manager (p. ej. `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM`, `SMTP_TLS_MODE`, `PLATFORM_ACTIVATION_URL`); validar al activar flag. DNS SPF/DKIM/DMARC según proveedor antes de envío real. No escribir secretos en repositorio ni publicar tokens, enlaces o cuerpos de email en logs.

## 8. Feature flag, despliegue seguro y rollback

`TENANT_REGISTRATION_ENABLED=false` por defecto. Mientras no se habilite:

- `POST /tenants/register` y `POST /tenants/{id}/resend-welcome` devuelven `503` **sin escrituras**.
- `GET /tenants/{id}/onboarding`, `POST /auth/redeem-first-access` y `POST /auth/complete-first-access` siguen disponibles para gestionar cuentas/enlaces previamente emitidos.
- Validar la marca `mustChangePassword` y rechazar sesión/JWT normales sigue siendo obligatorio, aunque la función esté apagada.
- Los usuarios normales continúan utilizando el login y las APIs 1.0.0.

**Orden de despliegue obligatorio:** migración y auditoría de datos → Backend compatible con cambios pero flag apagado → frontend compatible con ruta de activación y contratos → smoke E2E con correo controlado → revisión/GO del owner → activar flag. Prohibido desplegar un Backend anterior que ignore `mustChangePassword` mientras existan cuentas pendientes, salvo plan probado que garantice el bloqueo. Retirar feature flag **no** implica borrar tablas/cuentas ni interrumpir la recuperación de pendientes.

## 9. Contrato objetivo versus contrato implementado

- **Baseline core 1.0.0:** `Docs/Contracts/platform-api.v1.yaml` en `main` y el Swagger servido por `src/common/openapi/deployment-document.ts` → `/api/docs`, `/api/docs-json`. **No se modifica en esta entrega**.
- **Extensión aprobada futura:** `platform-api.tenant-registration.approved.yaml` (este ADR). Conserva las **33 operaciones originales**, añade **5 operaciones de onboarding/activación** y mantiene **sin cambio el wire shape del login normal**. Especificación objetivo `1.1.0`, NO desplegada.
- **Al implementar:** Ángel compara su rama con el contrato vigente, integra los nuevos elementos con revisión, mantiene Jobs de escritura como `503` y hace que el **Swagger implementado refleje las rutas reales** y su disponibilidad, sin afirmar que funciona lo no desplegado. La copia contractual Flutter se actualiza **solo tras aprobar el contrato nuevo** y adaptar el consumidor; no mezclar este trabajo con la estabilización del frontend core.
- Si la implementación opta por otras rutas, esquemas de respuesta o semánticas que alteren este documento, requerirá **aprobación nueva del owner**, no una decisión unilateral de ingeniería.

## 10. Criterios de aceptación / gates de merge

1. **Core sin regresión:** tests unitarios/HTTP/PostgreSQL y rutas preexistentes, incluido SEC-01, aislamiento y roles, autenticación habitual, CSV y Jobs read-only/503.
2. **Seguridad del onboarding:** solo ADMIN sin tenant; OWNER/MEMBER 403; caso de 401; no correo/secreto en body, respuestas ni logs; sin auto-registro.
3. **Persistencia/migración:** rollback transaccional, colisiones case-insensitive, pruebas concurrentes slug/email, usuarios previos activos, generación vigente, índices y claves externas.
4. **Activación:** expiración enlace 24 h y desafío 15 min; ambos de un solo uso; redención y finalización concurrentes; token inválido 401 genérico; nueva clave fuerte y máximo bytes; no JWT antes; anti bypass en JWT/Users.
5. **Entrega:** SMTP aceptación/rechazo/timeout, lease expirado, generación vieja, fallo previo a envío, `UNKNOWN`, reenvío, cuota gratuita agotada sin facturación, límite 1 min/5 h persistente.
6. **Contrato:** YAML parseable, referencias válidas, operaciones nuevas con DTO, status, seguridad; 33 originales conservadas, comparación Swagger implementado versus rutas reales, pruebas del contrato sin falsos éxitos.
7. **Frontend futuro:** ruta pública de activación, token en fragmento limpiado antes de llamadas externas, canje/complete, mensajes de vencimiento y derivación a ADMIN; sesión normal y cambio de tenant sin regresión.
8. **Operación:** runbook de variables, secretos, proveedor/cupo, supervisión, feature flag, activación, rollback seguro, evidencias de CI y reporte de revisión.

**Gate de autoridad:** Ángel puede desarrollar en su rama, crear PR y documentar. Merge a `main`, modificación de baseline y activación productiva requieren aprobación expresa del owner después de revisar evidencia. No se autoriza trabajo en el Prospector Service bajo este ADR.

## 11. Estado de la entrega documental

Dos documentos aprobados para iniciar implementación. Los nombres físicos de tablas, librería SMTP, proveedor gratuito seleccionado, código y despliegue quedan a cargo del responsable técnico delegado, sujeto a los requisitos anteriores. Ningún endpoint nuevo existe aún en el Backend `main`; Swagger productivo sigue reflejando solo el código disponible. Las decisiones D06, D08 y D19 quedan reconciliadas explícitamente en este documento.
