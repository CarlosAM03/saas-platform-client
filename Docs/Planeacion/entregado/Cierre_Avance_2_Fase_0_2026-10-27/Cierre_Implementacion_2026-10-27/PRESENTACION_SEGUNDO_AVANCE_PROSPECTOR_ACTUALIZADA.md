# PROSPECTOR SaaS — Presentación del Segundo Avance

**Fecha de corte:** 27 de octubre de 2026, America/Tijuana.  
**Documento rector:** Plan de TrabajoAvance2.md, sus decisiones aprobadas y la autorización ampliada del owner.  
**Resultado:** núcleo v1.0.0 integrado en main y demostración experimental 1.1.0 disponible en Docker Compose local, con alcance y evidencias separados.

## 1. Accesos para la presentación

| Recurso | Enlace | Qué demuestra |
|---|---|---|
| **Frontend productivo en Vercel** | [Abrir PROSPECTOR SaaS](https://saas-platform-client-web.vercel.app) | Interfaz publicada; el owner acreditó una sesión y el dashboard productivo. |
| **Contrato público del Backend** | [Swagger v1.0.0](https://saas-platform-backend-l55n.onrender.com/api/docs) | Operaciones, DTO, respuestas y disponibilidad del contrato actualmente publicado. |
| OpenAPI público | [Documento JSON](https://saas-platform-backend-l55n.onrender.com/api/docs-json) | Fuente contrastada con el cliente Flutter. |
| Backend productivo en Render | [Origen de la API](https://saas-platform-backend-l55n.onrender.com) | Servicio que atiende al frontend productivo. Los endpoints se consultan bajo /api/v1. |
| **Demo experimental local 1.1.0** | [Abrir plataforma integrada local](http://127.0.0.1:18470/vnc.html?autoconnect=1&resize=scale) | Navegador aislado con Flutter, NestJS, PostgreSQL y FastAPI; resultados sintéticos controlados. |
| Core v1.0.0 local | [Abrir plataforma core](http://127.0.0.1:18450/vnc.html?autoconnect=1&resize=scale) | Recorrido reproducible de roles, tenants, CSV, dashboard y consulta de jobs con datos locales. |
| Contrato core local | [Swagger local](http://127.0.0.1:18441/api/docs) | Contrato del runtime core usado en las pruebas. |

Los enlaces 127.0.0.1 funcionan en el equipo donde se ejecuta Compose. Abren un navegador mediante noVNC; dentro de él, la plataforma experimental está en **https://localhost:18463** y el core en **https://localhost:18443**. Ese navegador confía en la CA local de su contenedor. No se modificó el almacén de certificados del equipo. Si aparece una pantalla de conexión, pulsar **Connect**.

## 2. Qué se entrega realmente

El Segundo Avance consolida dos entregables independientes:

**A — PROSPECTOR SaaS v1.0.0.** Flutter conserva las aportaciones válidas de André y Foundation y consume el contrato funcional del Backend. Incluye autenticación, contexto de organización, usuarios y RBAC, campañas, prospectos, importación CSV con previsualización y confirmación, dashboard y lectura de trabajos. El Backend conserva el esquema Prisma baseline y JWT snapshot, con correcciones de seguridad selectivas.

**B — Integración experimental local 1.1.0.** Docker Compose levanta Flutter, NestJS, PostgreSQL y FastAPI con Prospector Engine instalado. Se demuestra el recorrido de creación de un trabajo, procesamiento controlado, callbacks autenticados y consulta del resultado persistido. La extracción se sustituye explícitamente por fixtures sintéticos. La interfaz muestra permanentemente **“DEMO INTEGRADA — RESULTADOS CONTROLADOS”**.

La ampliación **CR-AV2-DEMO-110-01** convirtió la planificación original de la Fase 7 en construcción y validación local autorizadas. Su implementación y criterios de aceptación están documentados en el [informe experimental](INFORME_COMPOSE_EXPERIMENTAL.md). La arquitectura productiva 1.1.0 continúa pendiente de aprobación.

## 3. Núcleo v1.0.0 consolidado

| Área | Comportamiento implementado y validado |
|---|---|
| Auth y sesión | Login, selección de tenant y sustitución del contexto JWT; logout y rutas protegidas. Un 401 real elimina la sesión; 403 conserva la sesión. |
| Multi-tenant | Consultas y operaciones acotadas a la organización del JWT. Se probaron accesos cruzados por ID, listados y cambio visual de organización. |
| Usuarios y RBAC | Guardas del Backend y controles de interfaz acordes con ADMIN, OWNER y MEMBER. Protección transaccional SEC-01 sobre cambios de identidad y permisos. |
| Campañas y prospectos | Gestión permitida por contrato, paginación, validaciones y tratamiento de errores reales. |
| CSV | Archivo multipart, preview, decisiones por fila y confirmación; coincidencias y referencias vencidas se gestionan sin inventar éxito. Se comprobó que un teléfono con ceros iniciales conserva su valor. |
| Dashboard | Totales y actividad de la organización obtenidos mediante consultas reales. |
| Jobs | Listado y detalle reales. Creación, cancelación, persistencia y exportación permanecen deshabilitadas con 503 en el core. |
| Generación visual | El panel **“DEMO — SIN EJECUCIÓN REAL”** permite presentar el flujo visual sin invocar Service ni crear datos de negocio. |
| Contrato | 33 operaciones y sus esquemas, entradas, parámetros y respuestas de éxito evaluados frente al OpenAPI público, sin diferencias semánticas en la comparación ejecutada. |

MEMBER puede consultar usuarios, gestionar campañas y editar prospectos según las guardas existentes. La administración de usuarios y la importación CSV tienen restricciones adicionales. La [matriz de aislamiento y RBAC](MATRIZ_AISLAMIENTO_RBAC.md) detalla los casos; la interfaz no redefine los permisos del Backend.

Se preservaron el esquema Prisma baseline, su migración inicial, JwtStrategy y el comportamiento productivo de Jobs. El core no depende de Prospector Service. Las capacidades experimentales del PR #6 de Backend y PR #8 de Flutter no se incorporaron a main.

## 4. Integración, CI y publicación verificadas

El owner realizó las fusiones finales hacia main. Se verificaron los commits, la igualdad de sus árboles con dev validado y los checks del commit integrado.

| Repositorio | Commit main | CI del commit |
|---|---|---|
| Backend NestJS | [b51b265f1a545fa915f1dd1c57ef2f5858ec6492](https://github.com/CarlosAM03/saas-platform-backend/commit/b51b265f1a545fa915f1dd1c57ef2f5858ec6492) | [quality, PostgreSQL y Docker aprobados](https://github.com/CarlosAM03/saas-platform-backend/actions/runs/40606722665) |
| Flutter | [7731649a2c69b45cb9776d02de4a6105d6fd9886](https://github.com/CarlosAM03/saas-platform-client/commit/7731649a2c69b45cb9776d02de4a6105d6fd9886) | [Foundation y contenedores aprobados](https://github.com/CarlosAM03/saas-platform-client/actions/runs/40607324970) |

Vercel reportó un despliegue **Production / success** para ese main. El bundle público del alias coincide byte a byte con el candidato validado y contiene el origen HTTPS esperado de Render. Render respondió correctamente a health y Swagger 1.0.0; CORS permitió el origen productivo de Vercel.

La captura aportada por el owner acredita sesión y dashboard productivo de **ACME CORPORATION**, con **1 campaña, 1 prospecto y 0 trabajos** al momento de la captura. Ese conteo es productivo e histórico: no corresponde al dataset local de demostración.

Permanece pendiente la atestación del **Deployment ID y SHA Live de Render**. Los enlaces de los commits de GitHub y la salud de la API no prueban por sí solos ese SHA. También queda pendiente la aceptación productiva completa de roles y CSV; no se ejecutaron seeds, migraciones ni importaciones en producción por Codex.

## 5. Pruebas que respaldan el avance

| Capa | Resultado verificado | Alcance |
|---|---|---|
| Backend unitario | **41 pruebas** aprobadas, 5 suites | Servicios y reglas del core. |
| Backend HTTP | **78 pruebas** aprobadas, 6 suites | Rutas, validación, permisos y errores. |
| Backend con PostgreSQL | **20 pruebas** aprobadas, 3 suites | Persistencia, aislamiento y atomicidad. |
| Concurrencia real | **P2034 / SERIALIZABLE aprobado** | Conflicto real contra UsersService compilado: rollback del cambio rechazado y conservación de la transacción concurrente. |
| Backend runtime Docker | **38 comprobaciones** aprobadas | Dockerfile real, API y PostgreSQL locales. |
| Flutter | **256 pruebas** aprobadas; análisis y build correctos | Incluye los **101 casos contractuales**; no se suman como otra suite independiente. |
| Navegación core real | **5 perfiles** aprobados | ADMIN, OWNER y MEMBER de dos organizaciones; CSV, cambio de tenant y 401 real. |
| Integración experimental | **26 comprobaciones API/E2E**, más recorrido UI y reinicio | Casos normal, vacío y fallo; callbacks, idempotencia, claves y aislamiento. |
| Dependencias Backend | Producción: **0 vulnerabilidades** en el audit ejecutado | Audit completo: 8 bajas de desarrollo; 0 moderadas, altas o críticas. |

Las pruebas locales utilizan bases y credenciales propias. Los builds y arranques completos de ambos entornos se ejecutaron con los Dockerfiles reales. Los resultados locales, la CI y las comprobaciones públicas son evidencias complementarias; no equivalen a ejecutar todos los flujos autenticados en producción.

La [validación Backend](VALIDACION_BACKEND_RUNTIME.md), la [validación Flutter](VALIDACION_FLUTTER_VERCEL.md), la [paridad OpenAPI](MATRIZ_PARIDAD_OPENAPI.md) y el [registro de CI](REGISTRO_CI.md) conservan el detalle.

## 6. Demostración integrada 1.1.0: componentes y límites

~~~text
Flutter experimental
        |
        v
NestJS experimental <---- callbacks HTTP autenticados ---- FastAPI + worker
        |                                                    |
        v                                                    v
PostgreSQL exclusivo                              Adaptador de resultados controlados
                                                   Engine instalado; probe Chromium aparte
~~~

| Capacidad | Naturaleza demostrada |
|---|---|
| Interfaz, login y contexto tenant | Flutter y Backend reales con datos sintéticos locales. |
| Trabajo y ciclo de estados | Solicitudes HTTP reales, worker real y estados persistidos en PostgreSQL. |
| Callbacks | HTTP autenticado real; replay comprobado sin duplicar efectos. |
| Resultado normal | Un resultado sintético identificado como CONTROLLED DEMO. |
| Resultado vacío y error | Cero resultados y estado FAILED, con comportamiento visible en Flutter. |
| Idempotencia y aislamiento | Mismo key/payload conserva el job; conflicto devuelve 409; acceso ajeno devuelve 404. |
| Prospector Engine | Instalación real fijada al commit 70f6081688db5c5bc5ea612f5fabd5724aab0b20 y prueba separada de Chromium con contenido local. |
| Extracción de prospectos | Adaptador controlado: no se llamó Engine.search ni se hizo scraping de Google Maps. |
| Caída del Service | Reinicio con nueva generación marca trabajos activos previos como FAILED/SERVICE_RESTARTED; no hay reanudación durable. |

El enum de protocolo source=google_maps no acredita el origen de los datos sintéticos. La demostración no se presenta como scraping real ni como integración productiva aceptada.

B dispone de base **avance2_experimental**, secretos, volúmenes y ramas locales propios. La migración P2 se aplicó exclusivamente a esa base nueva. El core conserva **avance2_core** y su esquema baseline. PostgreSQL y Service experimentales no publican puertos en el anfitrión.

## 7. Arranque y preparación de la demostración

Requisitos verificados en este equipo: **Docker Desktop con contenedores Linux y PowerShell 7**. Ejecutar desde la raíz **DocumentacionGlobal**. El siguiente comando construye imágenes, prepara configuración privada local, inicializa su base exclusiva, ejecuta el seed demo y comprueba salud:

~~~powershell
pwsh -File .WorktreesAvance2service-experimentaldemoavance2Start-Demo.ps1
~~~

Después abrir **[la plataforma experimental local](http://127.0.0.1:18470/vnc.html?autoconnect=1&resize=scale)**. Para un nuevo arranque usando las imágenes existentes, añadir -SkipBuild al comando anterior.

Si se desea presentar también el core local:

~~~powershell
pwsh -File .WorktreesAvance2ackend-coreopsavance2Start-Core.ps1
~~~

Las cuentas reservadas son ADMIN y OWNER/MEMBER de **Demo Norte** y **Demo Sur**. Las contraseñas se consultan mediante el enlace privado de la [guía de acceso](ACCESO_RAPIDO_AVANCE2.md); no forman parte de este informe. No son cuentas productivas.

**Antes del recorrido experimental**, crear trabajos nuevos desde Flutter o preparar los tres casos:

~~~powershell
pwsh -File .WorktreesAvance2service-experimentaldemoavance2Prepare-Presentation.ps1
~~~

Los snapshots experimentales duran **una hora**. Ejecutar la preparación cerca de la presentación; no confiar en resultados antiguos. En la UI elegir la campaña **Demo controlada 1.1.0 norte** o **sur**, keyword **normal**, **empty** o **fail**, ubicación de prueba y límite **1**. El script respeta cuotas y rate limit; no ejecutarlo en bucle.

Para CSV, usar la [muestra sintética de dos filas](evidencias/DEMO_IMPORTACION_SINTETICA.csv). En el selector de archivos del navegador contenedor está en **/evidence/DEMO_IMPORTACION_SINTETICA.csv**. Revisar preview y confirmar; al repetir, vincular u omitir coincidencias y regenerar una referencia vencida. El recorrido actual no requiere cargar XLSX ni los aproximadamente 600 prospectos de DATRA.

Las instrucciones de [apagado sin pérdida](APAGADO_SIN_PERDIDA.md) conservan los volúmenes. Los scripts y enlaces adicionales están en [ACCESO_RAPIDO_AVANCE2.md](ACCESO_RAPIDO_AVANCE2.md).

## 8. Guion sugerido de exposición: 10 minutos

| Tiempo | Acción | Mensaje verificable |
|---|---|---|
| 0–1 min | Abrir Vercel y Swagger público. | Frontend publicado y contrato 1.0.0 existente; señalar la reserva de atestación Render. |
| 1–3 min | Core local: ADMIN cambia Demo Norte → Demo Sur; mostrar OWNER y MEMBER. | Separación de datos y permisos por organización; MEMBER no es un lector universal. |
| 3–5 min | CSV sintético: preview, decisión y confirmación; refrescar dashboard. | Importación y métricas reales del dataset local. |
| 5–6 min | Abrir Jobs y el panel visual core. | Historial consultable; generación productiva deshabilitada. |
| 6–9 min | Abrir B con su rótulo permanente; crear normal y mostrar empty/fail frescos. | Integración real de servicios con resultados controlados; no extracción externa. |
| 9–10 min | Mostrar CI y cerrar con alcance pendiente. | Core consolidado y demo reproducible; aceptación productiva restante y arquitectura 1.1.0 delimitadas. |

Como respaldo están las [capturas y resultados indexados](evidencias/EVIDENCE_INDEX.json). El [guion operativo ampliado](GUION_PRESENTACION.md) incluye reinicio y recuperación del recorrido. Las capturas acreditan ejecuciones previas; no sustituyen resultados actuales ni se presentan como scraping.

## 9. Conclusiones y dictamen de cierre

1. **El núcleo v1.0.0 está consolidado en main**, con fusiones finales realizadas por el owner, CI aprobada y paridad contractual evaluada. Se preservan CSV, dashboard, gestión SaaS y consulta real de jobs.
2. **La demostración local integrada está construida y validada.** Un comando por entorno prepara el sistema; B demuestra UI, API, worker, callbacks y persistencia con resultados sintéticos explícitos. El core y la integración experimental permanecen separados.
3. **La publicación productiva tiene evidencia verificable y aceptación parcial.** Vercel Production y su bundle están comprobados; Render publica contrato/health correctos; el owner acreditó sesión/dashboard. Falta atestar el SHA Live de Render y completar la aceptación productiva de permisos y CSV.
4. **Se conserva JWT snapshot de hasta 8 horas por decisión aprobada.** Cambiar rol o membresía no implica revocación inmediata de un token emitido. La desactivación global de usuario sí produjo un 401 real en la prueba. SEC-01 no sustituye una futura estrategia de revocación. Node 20 continúa como deuda diferida por el owner.
5. **La demo no acredita extracción real ni preparación productiva de 1.1.0.** Persistencia durable del worker, recuperación, política de snapshots/cuotas y arquitectura de producción requieren definición y aceptación posteriores. Los datos productivos y la prospección externa requieren autorización específica.

**Dictamen: GO para presentar el core consolidado y la demostración local controlada. Estado técnico: VALIDADO CON LIMITACIONES.** La certificación productiva integral y la aceptación de arquitectura 1.1.0 quedan pendientes de las comprobaciones y decisiones indicadas.

## 10. Documentación de cierre y trazabilidad

Este informe actualiza la presentación del avance sin sobrescribir el plan rector, la auditoría, los ADR ni los checkouts originales. Las decisiones aprobadas prevalecen sobre propuestas experimentales.

- [Índice de documentación de cierre](README.md).
- [Dictamen global por artefacto y área](DICTAMEN_GLOBAL.md).
- [Estado de los gates G0–G6](GATES_CIERRE_EJECUTADOS.md).
- [Inventario de ramas, commits, PR e imágenes](INVENTARIO_RAMAS_COMMITS_PR.md).
- [Riesgos de JWT snapshot](RIESGOS_JWT_SNAPSHOT.md).
- [Verificación posterior al merge](RUNBOOK_POST_MERGE.md).
- [Índice de evidencias con hashes y limitaciones](evidencias/EVIDENCE_INDEX.json).

**Pendientes concretos:** atestación Live Render, aceptación productiva completa, autorización previa para datos reales y aprobación de la arquitectura productiva 1.1.0. La documentación de esta entrega cierra la ejecución técnica autorizada y conserva estos pendientes de forma explícita.
