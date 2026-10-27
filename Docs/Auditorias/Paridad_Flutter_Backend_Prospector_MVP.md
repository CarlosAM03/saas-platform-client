# Paridad Flutter ↔ Backend — Prospector MVP

Cierre local 27-10-2026. Rama feat/flutter-prospector-mvp-parity, desde
fix/f5-foundation97645e4a9abcfb52121d74e2b1d6f5a14a73e3ef. No main/dev,
push, merge, despliegue ni scraping público. Engine/Service permanecen intactos.

## 1. Backend y componentes exactos

Backend funcional consumido: b6cd40f5c00990411bd6f46a22991c9be60de4bf,
feat/prospector-service-mvp-integration. Base967044e2; implementación iniciald19b78a,
arnés portableb37fb92 y hardening de mantenimiento b6cd40f.
Engine70f6081688db5c5bc5ea612f5fabd5724aab0b20; Service main566bbbe67a59a0fda307ea7d8c5f6bf46fd93aab,
checkout69c54a1 con src idéntico, sin modificaciones. Python3.13.4, PostgreSQL18
local aislado (CI16), Node22.16 local (CI20), Flutter3.47.5/Dart3.13.4.
No equivale al código efectivamente desplegado en un proveedor.

## 2. Contrato

OpenAPI1.1.0, copia del YAML Backend; hash LF y SHA consumido en
Docs/Contracts/prospector-mvp.version.json. Backend conserva documentos OpenAPI
extraídos de Swagger real y del endpoint servido, con diff: generación por decoradores
incompleta en propiedades/errores y éxitos2xx por defecto de rutas que en ejecución
rechazan503. El contrato servido y las pruebas representan la conducta efectiva.
Capabilities exige prospector-mvp-v1,google_maps,1–100,TTL3600 y futuras operacionesfalse.
Cualquier contrato no reconocido,404,503,fallo de parseo o red deja creación deshabilitada.

## 3. Endpoint → cliente → pantalla

| Endpoint NestJS | Cliente tipado | Pantalla/estado |
|---|---|---|
| POST auth/login,select-tenant,logout; GET auth/me | AuthRepository/ApiClient/AuthApi | AuthController, selector y router por sesión |
| GET prospecting-jobs/capabilities | ProspectingJobsApi.capabilities | Provider verificado por scope, GeneratePage |
| POST prospecting-jobs | ProspectingJobsApi.create / repository | Campaña/query/confirmación/idempotencia → detalle |
| GET prospecting-jobs | list | JobsPage, dashboard con metadata del servidor |
| GET prospecting-jobs/{id} | get / monitor secuencial | JobDetailPage, estados/resultados/error/TTL |
| POST cancel,persist; GET export | Métodos preparados, UI bloqueada | Controles deshabilitados; no éxito contractual |
| GET/POST/PATCH Campaigns y Prospects | Clientes existentes | CRUD conservado |
| POST prospects/import/preview,confirm | ProspectsApi / ProspectImportRepository | CSV separado y protegido |
| Callback interno | No cliente Flutter | Sólo FastAPI → NestJS con X-API-Key |

Todas las rutas de recursos incluyen /api/v1. No hay peticiones Flutter a Python.

## 4. Habilitado

Sólo crear búsquedas cuando Backend verifica disponibilidad/cuota/capacidad/política.
Seleccionar campaña, validar texto y límite1–100, confirmar explícitamente, clave por
intención, abrir Job real, historial, seguimiento y resultados temporales incluidos[].
Confirmación declara TTL1h y ausencia de guardado automático. El Backend revalida todo.
503 incierto o respuesta perdida conserva clave/payload y bloquea edición. jobId permite
consultar esa intención; no se afirma aceptación. Reintento de la misma intención no
reenvía scraping. Rechazo contractual definitivo libera la clave del formulario.
Fallo con retryAllowed=true permite preparar una nueva intención manual, con clave nueva.
Fallo operacional incierto conserva reserva y bloquea repetición hasta confirmación segura.

## 5. Deshabilitado

Cancelar HTTP, persistir scraping a campaña, exportar Jobs, reanudar automáticamente,
progreso porcentual y capacidades futuras. Los botones conservan estado no disponible;
no se equiparan CSV, snapshot PostgreSQL y persistencia de scraping. progress=null se
representa con indicador indeterminado, sin inventar porcentaje.

## 6. Auth y tenant

ApiClient, SecureTokenStorage y AuthController no se sustituyen. Continúan tokenOperation,
sessionRevision, filtrado de respuestas antiguas, JWT y logout local. Provider de capacidades
depende del scope; respuesta vieja no habilita el tenant siguiente. Formularios/scopes y
providers se retiran al cambiar sesión/tenant. La confirmación de búsqueda se elimina al
disponer el formulario y se verifica el scope antes y después de toda operación.
Capacidad no sustituye TenantPermissions ni autorización Backend. Ningún secret interno
forma parte de DTO, bundle, logs o configuración Flutter. Las credenciales de login E2E
son fixtures efímeros locales y el manifiesto se mantiene ignorado.

## 7. Regresión y gates

Engine247 PASS +1 E2E público deseleccionado; Service94 PASS +ruff PASS.
Backend61 unit,77 HTTP/regresión,29 PostgreSQL PASS (19 MVP realHTTP +10 CRUD/CSV),
lint/formato/build/tipos PASS. Flutter264 pruebas PASS, conservando las252 anteriores,
añadiendo capacidades/DTO/aislamiento/UI y un recorrido de stack real. Se actualizaron
aserciones de confirmación y contrato deshabilitado sin retirar casos aprobados.
10 pruebas específicas MVP repetidas PASS, incluyendo cuota429,503 incierto, estado
vacío/expirado, repetición manual y reemplazo de tenant durante confirmación.
Pub get offline, build_runner y analyze PASS. Build_runner avisa analyzer3.12 vsSDK3.13;
no fallo ni modificación de dependencias. No se ignoraron errores para pasar checks.

## 8. Plataformas

Web release compilado; tests de widgets incluyen layouts móvil/escritorio de la
reconciliación y nuevos estados de Jobs. Android/iOS no compilados en esta ejecución.
Los registrants regenerados incidentalmente se restauraron a la base autorizada.
Se conservó la junction .dart_tool preexistente; SDK y proyecto por alias cortoQ:.
No se cambió Developer Mode, fuentes Inter ni las reglas de despliegue existentes.
Una repetición desde la ruta física larga con ñ falló en framing JSON del LSP; se repitió
desde Q: (ruta ASCII corta), sin desactivar checks ni modificar código por ese problema.

## 9. Builds y CI

flutter analyze sin observaciones. flutter test con MVP_MANIFEST habilita el recorrido
real y completa264 PASS (sin sustituirlo por mocks). Web release PASS, origen marcador
https://api.example.invalid; no se usó como Backend E2E. Warning de fuente CupertinoIcons
no encontrada en assets, sin error de compilación; el código añadido usa Material.
Compose config estático PASS. Daemon Docker ausente: contenedor desarrollo, producción,
Service Docker y smoke SPA/Nginx no ejecutados/aprobados. No se sustituyen por validación
estática. No se afirma funcionamiento publicado/CORS.
CI foundation y contenedores permanecen independientes. Se agrega workflow_dispatch
prospector-integration.yml con PostgreSQL, Service pin566 y Backend ref explícito,
para repetir el E2E después del push autorizado. No se ejecutó GitHub Actions aquí;
los commits de Backend aún no publicados deben estar accesibles antes de dispararlo.
Sin MVP_MANIFEST, la suite normal identifica el test externo como omitido por infraestructura;
el cierre local lo ejecutó explícitamente. El workflow explícito falla si falta el stack.

## 10. CSV

CSV está implementado en Backend main3a330939 y dev967044e2, árboles idénticos; fue
incorrecto documentarlo sólo en dev. Se corrigieron documentos vigentes; auditorías
históricas no se sobrescribieron. Preview y confirmación multipart reales se ejercitaron
desde Flutter; se creó una fila y se verificaron totales junto a un prospecto manual.
Siguen vigentes permisos, referencia firmada/TTL, decisiones, warning de actualización
compartida y bloqueo de confirmación incierta. No se creó un segundo importador.

## 11. Jobs y E2E

Recorrido ejecutado: Auth/PlatformApi/Riverpod Flutter → NestJS → HTTP FastAPI real →
EnginePort controlado → callbacks HTTP → PostgreSQL → GET → DTO/monitor Flutter.
COMPLETED, FAILED y COMPLETED[] comprobados, con CUIDs trazables en
Evidencia_Prospector_Stack_MVP.json. No se almacenaron resultados como prospectos;
CSV y creación manual se probaron separadamente. Se verificaron replay idempotente,
conflicto por payload, lista, aislamiento404 al cambiar tenant y logout durante búsqueda.
UI se valida mediante widgets con fixtures; el recorrido HTTP usa código cliente real,
no un navegador interactivo completo. No valida Google Maps live ni scraping externo.
Backend valida además carreras callbacks antes de202, fallos de entrega,409/401 reales,
cuota/capacidad, constraints/rollback/TTL, reinicio y late terminal. Fuera de scope no
hay Service GET/cancel/export ni recuperación durable automática.
Polling: una solicitud por Job,4s, cierre por terminal/dispose/scope. Un timer local de
vencimiento oculta resultados y refresca una vez; no añade polling periódico terminal.

## 12. Riesgos

Service es memoria volátil con un worker y registry acotado sin eviction; callbacks tienen
reintentos limitados. Deadline no acredita cese del scraping. Backend conserva reserva
incierta y permite liberarla sólo por terminal legítimo o generación Service cambiada
tras verificar que murió/reinició el proceso previo. Backend reiniciado no cambia esa
generación. Snapshot TTL y deadlines se mantienen aun al retirar política de admisión.
Cuotas de Jobs no verifican facturación. Configurar topes conservadores del plan real,
presupuesto aprobado y feature flag antes de habilitar. Por defecto off. No hay costos,
autoescalado, Redis, exactly-once ni durabilidad Python prometida. Publicación requiere
revisión posterior y validación de entorno/CORS; Docker y builds nativos siguen pendientes.

## 13. Reproducción y commits

Backend: preparar una DB PostgreSQL desechable, generar Prisma y aplicar migraciones.
PROSPECTOR_TEST_PYTHON apunta a Python con Service566 y Engine70 instalados.
INTEGRATION_TEST_DATABASE_URL apunta a esa DB. Ejecutar node -r ts-node/register
test/scripts/mvp-stack.ts desde Backend; esperar MVP_STACK_READY y .tmp/mvp-stack.json.
Desde Flutter: flutter test --dart-define=MVP_MANIFEST=<ruta absoluta al manifiesto>.
Para sólo E2E añadir test/integration/prospector_stack_test.dart. El manifiesto tiene
login de fixture; no publicarlo. La evidencia entregada no contiene JWT, password ni API keys.
Para cerrar crear el archivo stopFile del manifiesto o enviar stop por stdin abierto;
el arnés limpia sólo sus fixtures, cierra Service/Nest y desconecta Prisma.
Commits de implementación y documentación se separan por repositorio, sin push/merge.
SHA funcional Flutter **9a766c2a5d06dd90561ef5594ebcbdb807874beb**; base97645e4.
El commit documental posterior contiene este reporte y no altera el código validado.
Pruebas y procesos de integración finalizados; fixtures retirados y cluster temporal apagado.

## 14. Dictamen

Gates1–4 aprobados para la integración HTTP local con EnginePort controlado. Gate4
se repitió contra el Backend final indicado. No se declara Google Maps live, UI Web
interactiva completa, builds Docker ni disponibilidad de producción.
INTEGRACIÓN FUNCIONAL CON LIMITACIONES.

## Matriz global

| Capacidad | Engine | Service | Backend | Flutter | Evidencia |
|---|---|---|---|---|---|
| Buscar Google Maps | IMPLEMENTADO | IMPLEMENTADO | IMPLEMENTADO condicionado | IMPLEMENTADO condicionado | VALIDADO con EnginePort controlado; live PENDIENTE |
| Registrar Job | NO APLICA | IMPLEMENTADO memoria | VALIDADO durable | VALIDADO | HTTP+PostgreSQL |
| Consultar estado | NO APLICA | DESHABILITADO HTTP | VALIDADO | VALIDADO | GET+monitor |
| Recibir resultados | IMPLEMENTADO | VALIDADO callback | VALIDADO snapshot1h | VALIDADO | COMPLETED/[] |
| Importar CSV | NO APLICA | NO APLICA | VALIDADO | VALIDADO | Multipart real y regresión |
| Guardar scraping en campaña | NO APLICA | NO APLICA | DESHABILITADO | DESHABILITADO | No creación automática de prospectos |
| Exportar Jobs HTTP | NO APLICA | DESHABILITADO | DESHABILITADO | DESHABILITADO | 503 |
| Cancelar HTTP | IMPLEMENTADO cooperativo interno | DESHABILITADO HTTP | DESHABILITADO | DESHABILITADO | No endpoint supuesto |
| Reinicio/fallo | NO APLICA | PENDIENTE durabilidad | VALIDADO deadline/reserva | VALIDADO fallo/repetición | Sin reanudación automática |
| Cuotas | NO APLICA | IMPLEMENTADO capacidad | VALIDADO | VALIDADO capabilities | Facturación PENDIENTE verificación del operador |


## Cierre MVP — 27 de octubre de 2026

PR Draft [#8](https://github.com/CarlosAM03/saas-platform-client/pull/8), base temporal `fix/f5-foundation`, destino final dev tras [#7](https://github.com/CarlosAM03/saas-platform-client/pull/7). Se incorporó el hardening Foundation `095e899ace31acf17d97bbe945c118c1a5d88682` mediante merge exclusivo entre ramas de trabajo. Dev y main no se modificaron.

P0 de diálogos reproducido con tres pruebas antes de corregir: confirmación/búsqueda del tenant anterior visible tras cambiar contexto o salir. Todos los diálogos de dominio y la confirmación de generación usan `showSessionDialog`; se ocultan al observar nuevo contexto y se cierran sin confirmar. Providers, formularios, CSV, respuestas tardías y monitor de Jobs mantienen los guards de contexto existentes. Véase `Cierre_MVP_Seguridad_2026-10-27.md`.

Los mensajes distinguen generación deshabilitada, política sin configurar, Service inaccesible, verificación fallida, capacidad ocupada y cuota agotada. El Backend decide `create`; Flutter conserva cancel/persist/export deshabilitados.

Regresión completa local: **267 pruebas aprobadas, 2 integraciones explícitas omitidas por defecto**, sin reemplazarlas por mocks. Foundation obtuvo 255 aprobadas. Se ejecutó adicionalmente `test/integration/core_stack_test.dart` con manifest privado: **1/1 aprobada**, contra el `dist/src/main.js` real de Backend `42b96fefd73cc11b42ecde4df6d5f42393328bfc`, NODE_ENV=production, PostgreSQL real desechable y sin Service ni credenciales externas. Login/tenant/Users/Campaigns/Prospects/CSV600/dashboard/Jobs, 600 altas + 1 manual = 601, replay409, cruce404, generación503, cero Jobs ficticios y cero llamadas fetch salientes del Backend. Evidencia agregada `build/test-evidence/core-stack.json`; manifest y tokens no se publican.

CI ahora se dispara para PR apilados. `core-integration.yml` comprueba el núcleo sin instalar Service; `prospector-integration.yml` comprueba separadamente HTTP con FastAPI real y EnginePort controlado. Ambos fijan el Backend remoto por SHA y sólo publican evidencia agregada. No ejecutan extracción pública ni importan datos DATRA.

La existencia de un Preview exitoso en GitHub/Vercel no certifica la aplicación productiva, CORS ni sesión autenticada. La revisión productiva y dictamen se detallan en los documentos globales del 27 de octubre. Ningún merge a dev/main ni despliegue se ejecuta aquí.


Comprobación local adicional del cierre: build_runner aprobado, analyze sin incidencias tras retirar un import sin uso del nuevo test, build Web release aprobado (advertencia preexistente de fuente Cupertino ausente, sin fallo de compilación). La integración HTTP con FastAPI/EnginePort controlado se volvió a ejecutar explícitamente: **1/1 aprobada**, separada del flujo de núcleo sin Service. Los dos tests no se contabilizan como ejecutados en la regresión que los omite por defecto.

CI remoto Foundation `095e899`: [40480231249](https://github.com/CarlosAM03/saas-platform-client/actions/runs/40480231249), aprobado, incluidos build compose, imagen de producción y smoke SPA `/dashboard`. La revisión de paridad tiene sus propios checks; no se hereda su aprobación por inferencia.


Los primeros runs remotos de las dos integraciones explícitas fallaron antes de ejecutar sus pruebas porque el checkout limpio no contenía los modelos generados de `json_serializable`. Se agregó el paso requerido `dart run build_runner build` a ambos workflows, conservando todos sus checks. No fue un fallo de aislamiento ni se sustituyó la integración por mocks; la aprobación se debe verificar en el nuevo SHA remoto.


### Ensayo Web real y cierre remoto

En `0465db2` los tres workflows remotos quedaron aprobados: [Foundation/calidad/containers 40481914447](https://github.com/CarlosAM03/saas-platform-client/actions/runs/40481914447), [núcleo sin Service 40481914550](https://github.com/CarlosAM03/saas-platform-client/actions/runs/40481914550) e [integración HTTP controlada 40481914785](https://github.com/CarlosAM03/saas-platform-client/actions/runs/40481914785).

Se realizó además el flujo en navegador sobre Web release local: login efímero, tenant A, selección de campaña/CSV sintético, preview600 NEW, confirm600 CREATE, dashboard600; cambio a B mostró cero campañas/prospectos/Jobs; generación mostró el mensaje explícito de indisponibilidad; historial y logout funcionaron. Es un fixture separado de la integración automatizada de601 (600+manual). Las capturas sin contactos reales se versionan en el reporte global del Backend.

`tool/core-demo-server.cjs` permite reproducir el ensayo: sólo loopback18420, build Web con API_BASE_URL de ese mismo origen y proxy al Backend aislado identificado por el manifest privado. No expone credenciales ni sustituye hosting/CORS productivos. El entorno local puede conservarse para ensayo y cerrarse con el stopFile específico del harness. Los informes globales canónicos de preauditoría, readiness y segundo avance están en `saas-platform-backend/Docs/Auditorias`; DocumentacionGlobal sólo los indexa.
