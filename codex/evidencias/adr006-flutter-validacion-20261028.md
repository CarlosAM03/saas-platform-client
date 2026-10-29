# Validación Flutter ADR-006 — 28/10/2026

## FASE / GATE

Implementación local del carril ADR-006, separada del sprint Core. G0 PASS;
análisis, tests VM y release Web PASS; G1 completo pendiente por pub get/symlinks;
historial real en navegador BLOCKED; G3/G6 UI→Backend→PostgreSQL NOT RUN.
No habilitado remotamente, desplegado ni listo para merge por inferencia.

## REPOSITORIO / RAMA / SHA VERIFICADOS

`CarlosAM03/saas-platform-client`, rama `feat/tenant-register`, base y HEAD sin
commit `e752f6ca692d2840263cd9e59e0927c56aa129ec`. Árbol inicial limpio y rama
creada desde origin/main tras fetch; base contiene el merge del sprint Core #10.
Ver `adr006-flutter-preflight-20261028.md`. No cambios Backend/infra/contratos.

## ALCANCE REALMENTE EJECUTADO

UI ADMIN de registro exacto de cuatro campos; resumen seguro del 201, consulta y
reenvío sin body; ruta pública y ciclo efímero de canje/contraseña/login. Mismo
PlatformApi/ApiClient/router y TenantPermissions, sin dependencias añadidas.
Contrato normal de login y provisión técnica POST /tenants preservados.

Archivo por archivo y procedimiento manual: `Docs/ADR006-Flutter.md`.
Documentación viva actualizada: README y FEATURE-DEVELOPMENT. Evidencia Core,
inventario y documentos aprobados no reescritos. Outputs nativos generados por
Flutter se revisan y se retiran del diff porque son ajenos a ADR-006.

## CONTRATO UTILIZADO

ADR-006 aprobado y YAML `platform-api.tenant-registration.approved.yaml` completos.
SHA-256 normalizado LF coincide con inventario (checkout Windows CRLF):
ADR `5be9757af462510d7f30d8d41ea9539fc8bde9fba5944cbbdf574c62a4a456b1`;
YAML `5f2e2a70f87c57289d10aaf0fd37737d03e841ff44b71328bf01608ced2721dc`.
No reemplazo del YAML Core. Runtime compatible Backend informado por el owner,
sin certificar disponibilidad remota ni reejecutar sus tests desde Flutter.

## PRUEBAS EJECUTADAS

Flutter 3.47.2 estable / Dart 3.13.2 del host; no se instaló ni actualizó SDK.

| Comando real | Exit / resultado | Estado |
| --- | --- | --- |
| dart run tool/check_merge_markers.dart | 0, sin markers | PASS |
| flutter pub get | 1; resolvió paquetes pero Windows requiere symlink/Developer Mode para plugins | BLOCKED |
| dart run build_runner build | 0; última ejecución 10s, cero outputs nuevos | PASS |
| flutter analyze (repetido con --no-pub) | 0; último análisis 2.1s, sin issues | PASS |
| flutter test test/adr006 --reporter expanded (repetido con --no-pub) | 0; 33 aprobadas, 1 omitida por necesitar navegador, ~3s | PASS (VM) |
| flutter test --reporter compact | 0; 312 aprobadas + 1 omitida, ~14s | PASS (VM) |
| flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=https://api.example.invalid | 0; build/web, última compilación 35.5s | PASS (compilación, no runtime) |
| flutter test --platform chrome test/adr006/web_history_test.dart --reporter expanded, con CHROME_EXECUTABLE=Edge | 1; runner no pudo lanzar Edge tras tres intentos, ningún caso ejecutado | BLOCKED |
| mismo test con Chrome instalado | Timeout del harness a 120s durante carga, ningún PASS obtenido | BLOCKED |
| git diff --check | 0; solo advertencias LF/CRLF | PASS |
| comprobación estática del bundle generado | canvasKitBaseUrl local y canvaskit/canvaskit.wasm presentes | PASS |

El baseline real antes de implementar tenía 279 pruebas aprobadas y analyze limpio.
Advertencia de build_runner: SDK 3.13 frente a analyzer 3.12; no se hicieron upgrades.
El build emitió advertencia no fatal sobre fuente CupertinoIcons no declarada;
el artefacto compiló. No se añadió Cupertino ni se modificaron dependencias.

Fallos propios durante desarrollo: once avisos de braces corregidos; tres fallos
iniciales en tests nuevos (código malformado, selector ambiguo, timer del harness)
corregidos y reejecutados. Se añadió comprobación de sesión original tras awaits
para no invalidar/pintar estados de otro contexto. La aserción estática inicial
del bundle falló por quoting de PowerShell/Node y se repitió correctamente.
Ninguno de estos resultados se presenta como un fallo del Backend.

## Matriz de requisitos y pruebas

| ID / requisito | Prueba real de frontend | Resultado / alcance |
| --- | --- | --- |
| FEADR-01 cinco operaciones y payload exacto | api_contract_test: rutas, métodos, DTOs, contrato aprobado | PASS / CONTRACT |
| FEADR-02 consulta y estados nullable | api_contract_test + registration_widgets_test | PASS / UNIT/WIDGET |
| FEADR-03 reenvío sin body/confirmado, no tras COMPLETED | api_contract_test + registration_widgets_test | PASS / CONTRACT/WIDGET |
| FEADR-04 públicas sin JWT aunque exista, ni siquiera lectura de storage | api_contract_test: CountingStorage + header heredado | PASS / UNIT |
| FEADR-05 401 público conserva sesión restaurada real del AuthController | api_contract_test + Core network/auth | PASS / UNIT |
| FEADR-06 /activate pública en unknown/loading/autenticado/sin tenant | registration_widgets_test + redirectForAuth todos los estados | PASS / WIDGET |
| FEADR-07 limpieza antes de router, one-shot, fallo cerrado | activation_state_test + startup routing widget, incluido defaultRouteName del motor con código sintético | PASS / UNIT/WIDGET; navegador BLOCKED |
| FEADR-08 Unicode, 10 code points y 72 bytes UTF-8 | activation_state_test | PASS / UNIT |
| FEADR-09 LOGIN_REQUIRED, descarte, login sin sesión nueva y siguiente login normal | activation_state_test + registration_widgets_test | PASS / UNIT/WIDGET |
| FEADR-10 errores/logs sin eco de secretos, DTOs redactados | api_contract_test + activation_state_test | PASS / UNIT |
| FEADR-11 ADMIN con/sin tenant; OWNER/MEMBER rechazados | registration_widgets_test | PASS / WIDGET; Backend no reevaluado |
| FEADR-12 no repoblar estado tardío de otra sesión | registration_widgets_test | PASS / UNIT |
| CORE-REG Auth/restauración/select-tenant/SEC-01/routing/CSV/Jobs | flutter test completo | PASS / 312 pruebas totales, no E2E |
| WEB-HISTORY replaceState real e historial | web_history_test.dart vía Chrome/Edge | BLOCKED / runner navegador |
| E2E-ADR006 UI→Backend→PostgreSQL + relectura + cleanup | No ejecutado | NOT RUN |

Los tokens/passwords de los tests son exclusivamente sintéticos y se construyen
en memoria. Ningún buzón, servidor SMTP, token real o DB se utiliza en los tests.
No se guardan HAR, capturas ni dumps HTTP sensibles en estas evidencias.

## E2E LOCAL

NOT RUN: no se levantó ni modificó Backend/PostgreSQL/SMTP desde esta tarea; no
hubo fixtures reales, aserciones SQL, relectura UI contra API real ni cleanup DB.
No se llama E2E al test de widget ni al test de historial. Prueba manual y correo
controlado quedan a cargo del usuario/QA, con entorno local compatible y buzón
propio o laboratorio. Remoto, flags y despliegues: NOT RUN, fuera del alcance.

## HALLAZGOS, BLOQUEOS Y DEUDA

- Resolver soporte symlink de Windows con el usuario, sin cambios automáticos al SO.
- Repetir historial web en runner funcional, verificar también back/forward y
  ausencia de código en restauraciones del navegador real.
- SDK del host ligeramente distinto del documentado; analyzer emite warning;
  no se ampliaron dependencias fuera de autorización.
- Ejecutar UI→API→PostgreSQL real local, casos de fallo SMTP/flag/expiración y
  matriz ADMIN/OWNER/MEMBER antes de aprobación. Backend probado por separado no
  certifica automáticamente esta integración.
- En Dart se eliminan referencias a strings, no se promete borrado físico de RAM.
  Revisar telemetry/scripts/extensiones y hosting antes de release. El bundle
  usa CanvasKit local, pero no hay auditoría runtime de red productiva aquí.
- Sin prueba de dispositivo Android/iOS/escritorio, solo stub condicional analizado
  y ejecución VM; no se declara validación nativa completa.
- Un 201 y ACCEPTED no prueban entrega de correo. Respuesta de canje perdida:
  recuperación solo mediante nuevo enlace ADMIN, sin reutilización local.

## DECISIONES PENDIENTES / SIGUIENTE TAREA SEGURA

Owner/QA revisa diff y evidencia; corregir entorno de pruebas de navegador y
ejecutar la guía local con Backend ADR-006, PostgreSQL desechable y transporte de
laboratorio, sin habilitar remoto ni enviar a terceros. Solo el owner decide
aceptación, merge, compatibilidad de despliegue y GO de flags.
