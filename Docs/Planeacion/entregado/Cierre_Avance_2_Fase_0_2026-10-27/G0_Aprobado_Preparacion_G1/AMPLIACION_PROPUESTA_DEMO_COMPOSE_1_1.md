# AMPLIACIÓN PROPUESTA — DEMO COMPOSE DE INTEGRACIÓN1.1.0

**CR-AV2-DEMO-110-01. Objetivo adicional establecido por el owner; diseño/implementación y validación todavía pendientes de aprobación.** No se editó el Plan de TrabajoAvance2.md ni se ejecutó Fase 7/G6. Este documento es el anexo de ampliación solicitado, separado del core A y del [detalle G1](DETALLE_IMPLEMENTACION_G1.md).

## 1. Cambio de entregable, sin modificación silenciosa del plan

Antes, Fase 7 del §3 del plan termina en una propuesta verificable del entorno experimental. La ampliación propuesta transforma esa salida en **un entorno local implementado, reproducible y validado que inicia con un solo comando**, más guía, evidencias y límites. El owner fijó el objetivo B; no aprobó aún su arquitectura definitiva ni sus decisiones de persistencia/idempotencia/TTL/cuotas.

A permanece v1.0.0 productivo sin Service, snapshot y schema baseline. B es una demostración local separada de integración, con variante experimental propia. No se incorporan PR #6 Backend/PR #8 Flutter a A para acelerar B. Urgencia de presentación no abre G6 ni autoriza cambios de esquema, despliegue o scraping.

## 2. Qué ya existe y qué falta

Verificado por lectura: Backend/Flutter tienen Dockerfiles y Compose separados; Service tiene imagen Python/Chromium con Engine fijado y un worker; Engine es biblioteca instalada, no un quinto servidor HTTP. Docker CLI/Engine 29.9.2 y Compose 5.6.1 responden; no se construyó, inició o probó el stack en este turno.

El core Backend de A siempre rechaza creación externa. Foundation mantiene cuatro capacidades false. Levantar sus imágenes junto con Service no demuestra un flujo de búsqueda integrado. PR #6 Backend contiene transporte/admisión/callbacks pero también persistencia P2 y JWT vivo; PR #8 Flutter es su consumidor experimental. Son fuentes a revisar, no candidatos autorizados en bloque.

El harness controlado previo usa FastAPI/worker/callback reales y ControlledEngine, cuyo execute retorna negocios sintéticos y cuyo probe devuelveTrue. Ese probe no acredita un browser o búsqueda real. La nueva demo deberá demostrar por separado instalación/import y probe local real de Engine, y rotular el origen controlado de resultados. No copiar scripts que migran o limpian fixtures sin delimitar entorno.

Referencias iniciales para investigar, a revalidar en G6:

|Componente|Referencia disponible|Uso propuesto, no aprobación|
|---|---|---|
|Backend core|A futuro aceptado, hoy3a3309398458ab333d7b00f16e9c2df6a09ef734|Preferir sus fixes/seguridad y aislar adaptador experimental de B.|
|Backend P2|a80871b6c5ebf39b4fca69eaf5f6352ab342da96, PR #6|Fuente de transporte/callback, no copiar JWT vivo/schema por inferencia.|
|Flutter core|A futuro aceptado, hoy095e899ace31acf17d97bbe945c118c1a5d88682|Conservar gestión SaaS; no activar P2 en artefacto A.|
|Flutter P2|97ad02a621007e4139e5207511ecca2376754ed8, PR #8|Fuente para consumidor experimental B, con contexto/banner/compilación local propios.|
|Service|566bbbe67a59a0fda307ea7d8c5f6bf46fd93aab|FastAPI real, worker/adaptadores y Dockerfile disponibles.|
|Engine|70f6081688db5c5bc5ea612f5fabd5724aab0b20|Biblioteca instalada por Service; versión dev, no certificación Maps.|

## 3. Arquitectura candidata para revisión G6

Cuatro contenedores principales: Web/Nginx, Nest, PostgreSQL y FastAPI con Engine instalado. Puede existir un init job efímero para bootstrap de datos/secrets/esquema aprobado; no convertirlo en una dependencia productiva. Ubicación propuesta del paquete de demo: demo/avance2 dentro de un futuro checkout experimental Service, con contextos Backend/Flutter parametrizados y manifest de los cuatro repositorios. No crear un quinto repositorio o nuevas ramas B en este turno.

Hay dos decisiones técnicas que deben resolverse antes de construir:

**Persistencia:** reutilizar la implementación P2 actual exige su schema en una DB local propia. Su migración no está autorizada todavía, tampoco por ser local o de demo. Alternativas para revisión: aceptar de forma explícita ese schema exclusivamente efímero/dedicado a B, o diseñar un adaptador no durable sobre el schema core. La segunda alternativa también cambia diseño/código y no está aprobada por defecto. No declarar integrada la demo hasta que exista una variante decidida, implementada y probada. Ninguna de las opciones alcanza Supabase o cambia A.

**Red:** los guards existentes permiten HTTP solo para loopback en desarrollo/test explícito. Backend rechazaría http://service:8000 y Service rechazaría callback http://backend:3000. Un Compose convencional con esos nombres en HTTP fallaría. No relajar validaciones productivas para hacerlo arrancar.

Candidata de menor cambio de código para evaluar: contenedores Service y Web comparten el namespace de red de Backend mediante network_mode:service:backend, manteniendo cuatro procesos/containers independientes. Backend usa Service en127.0.0.1:8000; callback vuelve a127.0.0.1:3000; Web/Nginx comparte loopback y hace proxy de /api a Nest. La red DB sigue aislada y solo se publica la Web en127.0.0.1:<puerto_demo>, desde el contenedor dueño del namespace. No es network_mode:host. Ese acoplamiento y su comportamiento al recrear Backend son riesgos a aceptar/probar, no arquitectura definitiva aprobada.

Alternativa: namespaces separados con TLS y CA local confiable para nombres internos; requiere bootstrap/certificados y confianza explícita en clientes, sin verify=false. No basta poner SSL_CERT_FILE si el cliente ignora trust_env. Owner debe ratificar red y complejidad antes de implementación. La semántica service: y la incompatibilidad con declarar networks en el mismo servicio están documentadas por [Docker Compose](https://docs.docker.com/reference/compose-file/services/); el diseño concreto anterior es una inferencia/propuesta técnica, no un resultado ensayado.

Para modo controlado se propone red runtime sin egreso externo, cuatro servicios sanos y sin búsquedas automáticas. Imágenes/dependencias/browser se obtendrían durante build, con versiones/hash fijados. Un modo real opt-in necesitaría red y aprobación específica posterior. No cambiar URLs o validaciones de A para resolver la demo.

## 4. Modos y clasificación de capacidades

|Modo/capa|Real|Controlado/simulado|Pendiente o no disponible|
|---|---|---|---|
|A v1.0.0|Auth/tenants/CRUD/CSV/dashboard/jobs lectura|Solo demo visual sin ejecución|Prospección externa apagada.|
|B perfil controlled|Flutter→Nest→PG→FastAPI/worker/callback HTTP reales; Engine instalado y browser local probado por separado|Búsqueda devuelve fixture sintético explícito mediante EnginePort de prueba aislado|Extracción Maps no verificada; storage/red/local policy esperan decisión.|
|B perfil real opt-in|Service usa EngineAdapter público para consulta real si se autoriza|No se atribuyen fixtures al motor real|No ejecutar hasta permiso de consulta/límite/red/coste; sin prueba real no se declara PASS.|
|Cancel/export/persist externos|No se promete ninguna operación nueva|La UI puede explicarlas como no disponibles|Endpoints inexistentes/no aceptados no se implementan por tener Compose.|
|Reinicio|Fallo visible y repetición manual bajo procedimiento aceptado|Fallas/timeouts inyectados solo en perfil controlado|Sin outbox/recuperación automática/durabilidad o exactly-once.|

B debe mostrar “DEMO INTEGRADA — RESULTADOS CONTROLADOS” cuando corresponda. No confundir ese flujo HTTP real controlado con la demo visual de A, que no hace solicitudes ni mutaciones. El origen de cada conjunto de resultados debe figurar en UI/evidencia. Si el perfil real no se valida, la presentación lo dirá explícitamente.

## 5. Arranque y comandos propuestos, todavía inexistentes/no ejecutados

Interfaz objetivo desde el directorio de demo preparado y versiones fijadas:

~~~powershell
docker compose -p prospector-demo-110 -f compose.demo.yml --profile controlled up --build --wait
~~~

Ese único comando debe encargarse de builds y dependencias internas. Un init job puede generar/compartir credenciales estrictamente locales y datos sintéticos de forma idempotente; si se requiere un .env previo, la generación debe automatizarse en un launcher de un solo comando claramente documentado, no quedar como pasos manuales ocultos. La elección del bootstrap aún debe aprobarse. No existe compose.demo.yml creado por esta entrega, ni se promete que el comando funcione hoy.

--build construye imágenes y --wait espera servicios running/healthy; se requieren healthchecks funcionales y dependencias declaradas, no solo que el contenedor esté vivo. [Comando oficial up](https://docs.docker.com/reference/cli/docker/compose/up/) y [orden/readiness](https://docs.docker.com/compose/how-tos/startup-order/). Los perfiles permiten selección explícita de modos; sus restricciones deben validarse con config antes de usarlo. [Perfiles Compose](https://docs.docker.com/compose/how-tos/profiles/).

Evitar ciclos de arranque: DBhealthy → init completado → Backendhealthy → Service con probe/browser/workerready → Web. Backend no debe depender para arrancar de Service si Service comparte su namespace; readiness de creación se comprueba antes de aceptar una búsqueda. Después del up, el usuario decide iniciar la prueba controlada, no un scraping automático.

Comandos futuros de validación, solo tras autorización del tramo B:

|Comando/actividad|Qué verifica|Límite|
|---|---|---|
|docker compose ... --profile controlled config --quiet|Sintaxis, contextos y perfiles|No valida salud, auth o integración.|
|docker compose ... --profile controlled build|Dockerfiles/versiones/deps/browser|Consume red/compute; sin acceso producción.|
|docker compose ... --profile controlled up --build --wait|Arranque único e init/health|Escribe solo DB/volumen demo aprobado; no demuestra por sí solo el flujo funcional.|
|docker compose ... ps; logs --no-color|Estado y logs|Sanitizar consultas/datos/claves; correlación sin secretos.|
|Runner E2E nuevo de demo|Caso UI→job→callback→PG→resultado controlado, A/B, fallos y restart|Debe ser código dedicado y explícito, no adaptar silenciosamente test a producto.|
|Smoke Engine/browser offline|Import/API pública/probe local real|No se etiqueta como extracción Maps.|
|docker stats --no-stream del proyecto|Medición CPU/RAM para presentación|No inventar sizing mínimo antes de medir.|
|down sin-v del proyecto exacto|Parada y conservación de datos|No reset o prune global; limpieza de volumen solo con permiso y ownership verificado.|
|Perfil real/consulta live|Extracción real con Engine|Permiso adicional; NO EJECUTADO por construir controlled.|

No se modifica Supabase/Render/Vercel. PostgreSQL no se publica por defecto; nombre de proyecto/volumen y secrets exclusivos de B. No montar .env productivos ni Docker socket, no reutilizar credenciales públicas de tests para infraestructura compartida. Solo puerto Web en loopback; puerto libre se verificará antes de ejecución, no se afirma reserva de uno hoy.

## 6. Archivos y pruebas que requeriría construir B

Propuesta de paquete experimental, a ratificar en G6: compose.demo.yml, manifest de SHA/contextos y versiones/digests, Dockerfile/entrypoint de demo cuando el existente no basta, config Nginx proxy, bootstrap local/seed, test-only controlled_engine adapter, runner E2E y README/runbook. Mantener separado el adaptador controlado del paquete/entrypoint productivo Service; no modificar silenciosamente su EngineAdapter real.

No copiar el harness mvp-stack existente como launcher de producto: hace fixtures y limpieza por stdin/stop, usa claves en entorno de test y un puerto efímero; revisar cada efecto y sustituirlo por ownership/ciclo de demo explícito. Tampoco reutilizar la DB demo anterior con migración P2 como prueba de compatibilidad del core.

Para Backend/Flutter B, seleccionar integración sobre el core A aceptado o construir variantes experimentales desde los heads fijados con diff completo y sin arrastre de JWT vivo. La opción y los SHA finales están pendientes; usar artifacts de A y B con nombres distintos. Antes de construir, comprobar que ninguna modificación B aparece en las ramas A ni en sus pipelines productivos.

## 7. Criterios de aceptación de la ampliación

|ID|Criterio|Condición observable|Evidencia requerida|
|---|---|---|---|
|B-AC01|Arranque con un único comando|Desde repos/manifest y prerrequisitos documentados, levantar Flutter/Nest/PG/FastAPI+Engine sin procesos o pip/npm manuales en host. Build/bootstrap/env de demo automatizados o claramente incluidos en el launcher.|Log de comando, versiones/digests, tiempo y códigos de salida; no repetir preparación manual escondida.|
|B-AC02|Cuatro componentes reales y Engine instalado|Frontend Web, Nest, PG y FastAPI reales. Import/version Engine fijado y probe local de browser real, aun cuando las búsquedas del perfil controlado usen adaptador.|Manifest SHA/imágenes y smoke Engine/browser; indicar por separado el motor que produjo cada conjunto de resultados.|
|B-AC03|Flujo integrado controlado|UI→Nest→FastAPI→worker→callback→PG→UI con fixture sintético explícito y correlación job/event/tenant.|HTTP/trazas y consultas de la DB demo; no tests solo con mocks de repositorios ni afirmación de scraping.|
|B-AC04|Separación de A y producción|Artefactos/config/proyecto/volumen/secrets propios; no Render/Vercel/Supabase en URLs o credenciales demo.|Diff de A sin P2, inventario de volúmenes/proyecto, prueba negativa de destinos productivos y captura sin secretos.|
|B-AC05|Modo controlado claramente rotulado|Banner persistente DEMO INTEGRADA — RESULTADOS CONTROLADOS; dataset sintético distinto de negocios reales. A demo visual sigue sin red y no se confunde con B.|Capturas/guion/trazas; cada capa clasificada como real/controlada/no aceptada.|
|B-AC06|Arranque no significa ejecutar búsquedas|Default sin scraping, sin jobs automáticos; no proveedor externo requerido por el modo controlado.|Arranque y navegación sin egreso Maps/Service externo; contador de jobs sigue0 hasta acción de prueba explícita.|
|B-AC07|Aislamiento tenant y límites|Dos tenants sintéticos y pruebas de acceso cruzado; payload/capacidad/timeout acotados según política experimental aceptada para esta demo.|Casos positivos/401/403/404/409/503 y sin datos del otro tenant. No elevarlos a contrato productivo1.1.|
|B-AC08|Fallas/reinicio transparentes|Fallo visible si Service se cae; no éxito ni recuperación durable inventados. Repetición manual con runbook de generación/cuarentena aceptado, sin duplicar búsquedas inciertas.|Prueba controlada de caída/reinicio/timeout; estado, límites y procedimiento registrados.|
|B-AC09|Reproducibilidad y ciclo de datos|Mismo manifest en checkout limpio; seeds sintéticos identificados/idempotentes; reup sin duplicación; parada sin borrar datos por defecto.|Dos arranques, healthchecks, recursos medidos; reset solo del proyecto/volumen propio y con permiso separado.|
|B-AC10|Extracción real opcional y distinta|Ruta real Engine→Maps solo tras aprobación específica de consulta/límites/red/coste. Perfil controlado nunca cuenta como scraping real.|Si no se autoriza: estado NO EJECUTADO/NO VERIFICADO, sin bloquear honestidad de demo controlada. Si se autoriza: evidencia real separada.|
|B-AC11|Ningún secreto interno en Web/logs|Claves API Service/callback solo server-side, distintas entre sí y de JWT; locales y no compartidas con producción.|Bundle/manifest público/logs sanitizados y pruebas de auth interna.|
|B-AC12|Aceptación y alcance explícitos|Owner acepta variante local/controlada y riesgos; storage/red/retry local definidos antes de ejecutar. No release definitiva1.1 por disponer de Compose.|Acta de aprobación G6 y alcance de ejecución; limitaciones pendientes listadas.|

El mínimo honesto para presentación puede ser la integración controlada con Engine instalado/probe real y sus límites visibles. Una captura de FakeEngine o un202 no satisface la extracción real; tampoco cuatro contenedores sanos satisfacen B-AC03. El owner debe aceptar el nivel de demostración que se presentará.

## 8. Decisiones y autorizaciones pendientes

1. Ratificar la ampliación Fase 7 como construcción+validación de B y su nivel mínimo controlled, manteniendo A separado. No editar el plan original sin una decisión documental expresa posterior.
2. Elegir variante Backend/Frontend experimental y tratamiento de almacenamiento local. La migración P2 sigue NO AUTORIZADA hasta una aprobación específica incluso para DBdemo.
3. Elegir red loopback compartida o TLS interno y aprobar bootstrap de credenciales/DB, perfiles, recursos y límites. No se relajan guards productivos.
4. Autorizar en G6 un tramo concreto para escribir Compose/adaptadores/harness, seguido de inspección y permiso concreto de build/up/tests. G1 de A no cubre este trabajo.
5. Si se desea extracción real: aprobar por separado query/límite/entorno/salida de red y restricción económica. Ningún job live al iniciar Compose por defecto.

La secuencia G1–G5 de A no cambia. G6 exige v1.0.0 consolidado según plan; no se adelanta por el objetivo de presentación. Si el owner quisiera otro orden, deberá modificar expresamente esa condición, no inferirse de esta ampliación. El alcance definitivo1.1 seguirá pendiente aun cuando B sea aceptado como demo local.

**Estado: propuesta registrada; Fase 7/G6 NO INICIADOS. Ningún Compose, contenedor, migración, rama B o scraping ejecutado.**
