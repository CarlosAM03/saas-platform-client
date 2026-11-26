# Hallazgos y correcciones

Fecha: 2026-10-28, America/Tijuana. Rama feat/tenant-register. Original9c0e556,
hardening a09c117592f6be115b413f71c1441b08da9d0a4d; fixture CI919ce03.
Entorno y comandos: informe01, final-commands.jsonl y suites tool/frontend-adr006.

| Hallazgo | Reproducción / diagnóstico | Corrección / resultado |
|---|---|---|
| FBR-01 | Chromium observó escritura de historial con código tras limpieza Dart; browser-qa-before.json FAIL | Scrub en flutter_bootstrap.js antes del motor; handoff efímero de una lectura a la abstracción existente. Cuatro grupos reales PASS en browser-qa.json |
| FBR-02 | Registro201, SQL, consulta/relectura y resend429/200 reales; activación preliminar no concluyó | Suite y laboratorio exclusivos creados. E2E completo aún sin PASS; ver05 |
| FBR-03 | Claims siguen siendo presentación. D4 Backend añade autoridad viva en Users | No endpoint/DTO/cliente de permisos nuevo. Unitarias401/403 y sesiones PASS; matriz runtime final pendiente |
| FBR-04 | Fixtures User.platformRole=null, OWNER/MEMBER, ADMIN, membresía múltiple y paginación pasan parser | Sin reparación especulativa. Causa histórica ACME no reproducida; ver08 |
| FBR-05 | Ambos registrants añaden file_picker ya presente en Core/pubspec.lock | Se conservan: necesarios para CSV nativo. No plugin/dependencia desactivado; se retiró solo churn LF/CRLF propio |
| FBR-06 | Runbooks anteriores describen resultados de Ángel y limitaciones de su host | Nuevos diez informes y resultados separados; históricos intactos |
| FBR-07 | Registro carecía de foco explícito al inválido y secuencia de teclado | FocusNode por campo, primer error, next/done, bloqueo busy, live regions de error; widget móvil PASS |
| FBR-08 | clock_authority_test falló antes con expiresAt aparente pasado | Retiradas decisiones por reloj local/timer. Backend decide al completar; metadata visible. Relojes2000/2100 y401 servidor PASS |

## Pruebas antes/después

FBR08: fbr08-before.log (ignorado, local) registra una falla y dos éxitos contra
el controlador original. Tras cambio: suite ADR00636 PASS+1 omitida; después
accesibilidad y QF01 elevan la suite a38 PASS+1 omitida y la global a317 PASS.
Se sustituyó la antigua expectativa de expiración por dispositivo por una prueba
que exige401 autoritativo del servidor; no se acepta una credencial por reloj local.

CI inicial a09c117: foundation FAIL en web_history_test.dart:19, por fixture que
construía ##/activate. removeFragment() conserva una sola almohadilla y la misma
expectativa estricta. CI919ce03: tres jobs PASS, incluido Chrome real.

Riesgos: E2E incompleto y fallo Docker/WSL; causa histórica QF01 sin determinar.
No se amplió dominio, no se alteraron33 operaciones Core ni cinco ADR006.


## Revalidación conjunta del agente único

Fecha UTC: 2026-10-29T06:42:10.981Z (2026-10-28 America/Tijuana). Entorno Windows, Flutter3.47.5/Dart3.13.4, Node22, Docker, Chromium/Playwright, PostgreSQL16 real. Rama feat/tenant-register. Código Flutter 2590aa423c2f329d3309507bf08975db435b63c1; Backend candidato PR10 5e214420394101ae7079f8e844cc759b01cce2a3; revisión de tooling/evidencias f981a839781b6415af51805cf4f0724b16a022f4. La publicación documental posterior no altera estos artefactos.

Esperado: flujo autorizado sin regresión, integridad ni secretos expuestos. Observado: evidencia nueva indicada abajo. Los apartados anteriores se conservan como histórico; este apartado actualiza su estado.

| FBR | Estado actual | Evidencia / corrección |
|---|---|---|
|01|PASS|Limpieza temprana también en hashchange/popstate y fallback de captura de una lectura. Browser7/7.|
|02|PASS|Enlace original8 casos; resend11 casos. UI→NestJS→Prisma→PG16; ambos cleanupPASS.|
|03|PASS|Core32×2 y HTTP/SQL: ADMIN sin/con tenant, OWNER, MEMBER, múltiples membresías, JWT obsoleto403 sin logout.|
|04|PASS sintético|QF01 parser + Core Users real; causa histórica ACME no determinada.|
|05|PASS|Registrants file_picker requeridos por CSV Core; no retiro de plugin ni lockfile.|
|06|PASS|Diez informes actualizados, matrizE01–E25 y manifiesto. Históricos preservados.|
|07|PASS automatizado|Foco primer inválido, teclado, móvil390×844 real, busy, live regions, resend confirmado.|
|08|PASS|Servidor autoridad TTL; reloj±24h, desafío vencido, red y respuesta tardía. Sin retry.|

Se corrigieron defectos del arnés: apertura hash en documento existente, orden FK de cleanup, colisión de email de dos fixtures y expectativa histórica JWT-OWNER-SNAPSHOT superada explícitamente por D4. No se rebajó SEC01 ni ninguna expectativa contractual. Sin cambios de código Backend. Véase la matriz para el alcance concreto de cada resultado.
