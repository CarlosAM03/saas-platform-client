# ADR-006 Flutter — implementación local y QA

Carril separado autorizado por el owner. Base Flutter Core estabilizada:
`main@e752f6ca692d2840263cd9e59e0927c56aa129ec` (merge PR #10).
Rama: `feat/tenant-register`. No commit, PR, push, merge ni despliegue.

Autoridad: `Docs/ADRs/ADR-006-TenantRegistration-APROBADO.md` y
`Docs/Contracts/platform-api.tenant-registration.approved.yaml`, leídos completos
y preservados. No se sustituye el YAML Core ni se editan ADR/inventarios históricos.
Las marcas históricas TARGET_ONLY describen su fecha, no el resultado de esta rama.
Backend compatible declarado por el owner; **runtime y SQL no certificados aquí**.

## Flujo y arquitectura

`Widget → Riverpod/estado → TenantRegistrationRepository → PlatformApi → ApiClient`.
No hay HTTP directo en features, segundo Dio, router ni sistema de permisos.

| Pantalla / acción | Operación | Acceso |
| --- | --- | --- |
| Organizaciones, Administración o selector: Registrar organización | POST `/api/v1/tenants/register` | ADMIN, con/sin tenant |
| Resultado del registro | Tenant + onboarding del 201 | ADMIN; incluso FAILED/UNKNOWN |
| Detalle de organización → Consultar onboarding | GET `/api/v1/tenants/{id}/onboarding` | ADMIN |
| Estado → Reenviar enlace, con confirmación | POST `/api/v1/tenants/{id}/resend-welcome` | ADMIN, sin body |
| `#/activate?code=…` | POST `/api/v1/auth/redeem-first-access` | Público, secreto solo en body |
| Nueva contraseña | POST `/api/v1/auth/complete-first-access` | Público, desafío solo en body |

El formulario contiene exactamente tenantName, tenantSlug, ownerName, ownerEmail.
Trim de nombres y correo, correo en minúsculas; slug 3–63 minúsculas/números/guiones
interiores; nombres 1–120 y correo máximo 254. UI valida por campo; Backend decide.
No cambia el contexto del ADMIN. No invita MEMBER ni reutiliza cuentas existentes.
La interfaz/API/repository técnica `POST /tenants` conserva su contrato y pruebas;
`TenantCreatePage` es ahora un alias de presentación hacia el registro asistido.

Resumen independiente: activationStatus, deliveryStatus, activationLinkExpiresAt,
lastAttemptAt, providerAcceptedAt, completedAt. ACCEPTED significa **aceptación del
transporte, no llegada al buzón**. Las fechas son metadatos, no enlaces recuperables.
Sin onboarding devuelve un vacío/error 404 seguro; no crea ni regulariza uno.
Solo PENDING_FIRST_ACCESS ofrece reenvío; explica invalidación de generaciones y
límites 60s/cinco por hora. Sin reintentos automáticos ni body/destinatario alterno.

## Activación y revisión de seguridad

1. `web/flutter_bootstrap.js` captura y limpia la ubicación **antes de cargar el
   motor Flutter**: la prueba real mostró que hacerlo solo en Dart era demasiado
   tarde para impedir una escritura de historial del motor. Una closure entrega
   la ubicación original una sola vez a la abstracción web y elimina su función
   de transferencia. `main` conserva la validación y limpieza antes del binding.
   En web se reemplaza la entrada actual con
   `history.replaceState(null, '', URL_sin_codigo)`, sin push de otra entrada.
2. Después de limpiar se interpreta el código y se transfiere una sola vez al
   controlador. Duplicados/ausentes/no válidos muestran recuperación por ADMIN.
   Si falla la limpieza del historial, el arranque falla cerrado antes del router.
3. El router inicia `/activate` con override del default del motor para ese arranque;
   no restaura la URI original ni pasa el código por extra/query/state del router.
   La ruta pública evita splash/login/select-tenant en todos los estados Auth.
4. Enlace tomado una sola vez, sin reintentar el canje. La respuesta guarda el
   desafío únicamente en campo privado del controlador; el estado Riverpod solo
   expone fase, vencimiento y mensajes seguros, nunca credenciales/contraseña.
5. ApiClient usa **el mismo Dio** con un método explícito, limitado a las dos rutas
   aprobadas. No lee JWT, elimina Authorization heredado y no ejecuta logout ni
   logging del 401 público. Los errores públicos descartan message/details/code
   remotos potencialmente sensibles; el Core conserva su manejo habitual de 401.
6. Contraseña de mínimo diez code points Unicode, letra/número/especial y máximo
   72 bytes UTF-8. Campo oculto, sin sugerencias/autocorrección/autofill. Se vacía
   al enviar, al vencer, al salir y tras éxito. Backend conserva autoridad.
7. Completar recibe LOGIN_REQUIRED; descarta desafío y va a login sin escribir
   sesión. Si había sesión normal, no se destruye por este flujo; la excepción
   visual para mostrar login finaliza al iniciar el siguiente login normal.
8. El Backend decide la expiración; `expiresAt` es metadato visible y no un motivo
   de rechazo basado en el reloj del dispositivo. El401 del servidor descarta el
   desafío. Salir/desmontar elimina referencias e invalida la operación;
   respuestas tardías no rehidratan secretos. ADMIN también
   verifica que la sesión original siga vigente antes de pintar resultados tardíos.

No storage de activación: ni secure storage, preferencias, localStorage, analytics,
logs, capturas o reportes. DTOs sensibles tienen diagnósticos redactados. Los tests
usan únicamente valores sintéticos en memoria y no imprimen cuerpos sensibles.
JS interop solo se compila para web; stub no-web conserva compatibilidad Dart.
La eliminación de referencias en Dart **no garantiza borrado físico inmediato** de
strings inmutables en memoria; se confía en el runtime/GC, no se promete zeroization.

`web/flutter_bootstrap.js` sirve CanvasKit desde `canvaskit/` local, evitando el
CDN por defecto en esta pantalla. Inter y MaterialIcons ya son assets de la app;
no se añadieron scripts de analytics, dependencias ni recursos externos.
Auditar nuevamente scripts/extensiones/telemetría y encabezados del hosting antes
de promoción. La limpieza no puede eliminar copias previas del enlace en el buzón,
sincronización del navegador o software externo; no compartir enlaces ni HAR.

400 muestra validación segura; 401 de activación mensaje genérico de enlace;
403 permisos; 409 conflicto sin datos adicionales; 429 espera; 503 altas/reenvíos
temporalmente deshabilitados; red/500 incertidumbre sin reflejar detalles remotos.
Si se pierde respuesta de canje, **no reutilizar el enlace**: reenvío ADMIN.
Si la finalización queda incierta, probar login normal de forma controlada y
consultar al ADMIN antes de nuevos intentos. No se inventa recuperación local.

## Archivos nuevos y modificados (explicación simple)

| Archivo | Función |
| --- | --- |
| `lib/core/activation/activation_bootstrap.dart` | Limpia ubicación y entrega código una vez. |
| `lib/core/activation/activation_location_web.dart` | Acceso mínimo a location/history vía JS interop. |
| `lib/core/activation/activation_location_stub.dart` | Implementación no-web sin dependencia de navegador. |
| `lib/main.dart` | Ejecuta limpieza antes de binding/router y entrega memoria al scope. |
| `lib/core/network/api_client.dart` | Excepción pública explícita y acotada, sin JWT/logout/log sensible. |
| `lib/platform_api/tenant_registration_models.dart` | DTOs de las cinco operaciones, estados y fechas. |
| `lib/platform_api/tenant_registration_api.dart` | Paths/métodos/parsing, reenvío sin body. |
| `lib/platform_api/platform_api.dart` | Compone/exporta el cliente tipado nuevo. |
| `lib/features/tenant_registration/data/tenant_registration_repository.dart` | Interfaz y adaptador único a PlatformApi. |
| `lib/features/tenant_registration/state/registration_providers.dart` | Estado administrativo ligado a sesión, sin resultados tardíos cruzados. |
| `lib/features/tenant_registration/state/activation_controller.dart` | Ciclo efímero de canje/completado/expiración, sin sesión automática. |
| `lib/features/tenant_registration/state/registration_validation.dart` | Validación UX y mensajes cerrados, sin eco del servidor. |
| `lib/features/tenant_registration/presentation/registration_pages.dart` | Formulario, resumen, consulta y recuperación ADMIN. |
| `lib/features/tenant_registration/presentation/activation_page.dart` | Pantalla pública de contraseña, limpia campos al salir/enviar. |
| `lib/routes/app_router.dart` | Integra rutas al router existente sin almacenar el código. |
| `lib/features/tenants/presentation/tenants_pages.dart` | Alta visible asistida y acceso ADMIN a onboarding. |
| `lib/features/admin/presentation/admin_page.dart` | Acción Registrar organización, solo ADMIN. |
| `lib/features/auth/presentation/auth_pages.dart` | Etiqueta Registrar organización en selector, sin cambio de login. |
| `web/flutter_bootstrap.js` | Renderer local, sin CDN añadido a activación. |
| `test/adr006/api_contract_test.dart` | Cinco endpoints, payloads, sesión/401 y sanitización. |
| `test/adr006/activation_state_test.dart` | Bootstrap, memoria, TTL, Unicode/bytes, errores y respuestas tardías. |
| `test/adr006/registration_widgets_test.dart` | Formularios, ADMIN/OWNER/MEMBER, routing, resultado y recuperación. |
| `test/adr006/fixtures.dart` | Doble de repository y datos sintéticos exclusivos de pruebas. |
| `test/adr006/web_history_test.dart` | Prueba específica del historial de navegador (no E2E Backend). |
| `test/adr006/history_web.dart`, `history_stub.dart` | Adaptadores de historial exclusivos de prueba. |
| `test/features/core_flows_test.dart` | Conserva prueba del detalle heredado; alta visible se prueba en ADR-006. |
| `test/features/tenants_feature_test.dart` | Expectativa de etiqueta actualizada, permisos Core conservados. |
| `README.md`, `FEATURE-DEVELOPMENT.md`, este runbook | Documentación viva del carril nuevo. |
| `codex/evidencias/adr006-flutter-*.md` | Preflight y resultados verificados, sin sobrescribir evidencia Core. |

## Prueba manual local (pendiente, no ejecutada)

Precondición: usuario levanta Backend ADR-006 y PostgreSQL de ensayo local de forma
independiente, confirma versión, datos y CORS para `http://localhost:4200`.
`TENANT_REGISTRATION_ENABLED=true` pertenece **al Backend local**, no a dart-define
ni al frontend. Este trabajo no modifica Backend, flags, Compose ni infraestructura.
Primero usar doble/SMTP laboratorio; correo manual real solo a buzón controlado
por el usuario y con autorización específica. No incluir secretos en comandos.

Desde Flutter:

```powershell
flutter run -d chrome --web-port=4200 --dart-define=API_BASE_URL=http://localhost:3000
```

1. Login ADMIN local sin tenant. Abrir selector → Registrar organización.
2. Usar nombre/slug únicos y datos sintéticos; comprobar cuatro campos y POST
   `/api/v1/tenants/register`. Comprobar 201 + tenant/onboarding, contexto ADMIN
   sin cambio y activación/entrega separadas incluso FAILED/UNKNOWN.
3. Abrir Consultar estado y recuperación o detalle de organización → Consultar
   onboarding. Confirmar GET y los seis estados/fechas visibles. Un tenant previo
   sin onboarding debe mostrar 404 seguro, no crear un onboarding.
4. Esperar ventana de entrega; confirmar reenvío desde UI. Comprobar POST sin
   body, resultado explícito y generación anterior invalidada. No repetir como
   prueba automatizada contra SMTP real. Completar debe ocultar reenvío.
5. Con enlace emitido por el laboratorio, abrir una pestaña limpia. No pegarlo en
   consolas ni guardar capturas/HAR. Comprobar que la barra queda `#/activate`
   inmediatamente y el código no reaparece con back/forward. Canje sin Bearer.
6. Probar contraseña corta y límite UTF-8; establecer válida dentro de 15 minutos.
   Complete sin Bearer, respuesta LOGIN_REQUIRED, login visible sin sesión nueva.
7. Login habitual con nueva clave, selección de tenant y navegación Core.
8. Repetir acceso inválido/vencido/ya usado; mensaje genérico y recuperación ADMIN.
   Probar con sesión previa guardada: 401 de activación no debe borrarla.
9. OWNER/MEMBER: no ver registro ni consulta/reenvío; ruta directa también rechaza.
10. Verificar en Backend/PostgreSQL de ensayo las entidades y transiciones bajo
    procedimiento autorizado, relectura UI y cleanup exclusivo de fixtures. Sin
    esos pasos, no clasificar como UI→API→PostgreSQL E2E.

## Gates y límites

Resultados originales de Ángel:
`codex/evidencias/adr006-flutter-validacion-20261028.md`.
La revisión posterior y su estado vigente están en
[`codex/frontend-adr006/evidencias/10_HANDOFF_GATE1_FRONTEND.md`](../codex/frontend-adr006/evidencias/10_HANDOFF_GATE1_FRONTEND.md).
Allí se separan unitarias, navegador real, E2E parcial, CI y bloqueos; la ejecución
histórica no se reescribe ni se presenta como una aceptación integral.
Mocks/widget/contrato no prueban disponibilidad ni transacciones Backend. No se
ejecutaron SQL, correo real, remoto o despliegues. Revisión y aprobación expresa
del owner siguen pendientes, así como E2E local y compatibilidad nativa en dispositivo.
