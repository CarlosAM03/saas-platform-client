# Regresión Core V1

Fecha: 2026-10-28, America/Tijuana. feat/tenant-register@919ce03.
Windows/Flutter3.47.5, Dart3.13.4. Esperado: conservar279 tests Core y contratos,
incluidos SEC01, permisos, sesión, CSV y Jobs503. Comando: flutter test --reporter
expanded; registros baseline-commands.jsonl y final-commands.jsonl.

Observado: baseline312 PASS+1 omitida; final317 PASS+1 omitida, análisis sin issues.
El incremento es de cinco tests (reloj3, accesibilidad1, QF01).
No se redujeron expectativas Core ni se alteraron sus contratos.

| Capacidad | Automatización ejecutada | Navegador/API/SQL final |
|---|---|---|
| Login/logout, restore, deep links, pérdida de sesión | PASS | Recorrido Core completo pendiente |
| Cambio tenant, ADMIN/OWNER/MEMBER, respuestas tardías | PASS | Pendiente en candidato final |
| Users/SEC01, PATCH diferencial, paginación/filtros | PASS | QF01 histórico no reproducido |
| Campaigns/Prospects, nullable/omitted y permisos | PASS | Pendiente UI→SQL final |
| CSV CREATE/SKIP/LINK_EXISTING/UPDATE_EXISTING | PASS | Pendiente UI→SQL final |
| Dashboard y fallo parcial Jobs | PASS | Pendiente lectura real final |
| Jobs consultas y operaciones503 | PASS | Pendiente HTTP/SQL final |

tool/frontend-adr006/run-core.mjs reutiliza íntegramente la suite Core establecida,
en proyecto/puertos propios. Adapta solo el alta visible /tenants/new al formulario
ADR006 actual, mantiene UI→HTTP→SQL→relectura y añade onboarding/OWNER; cleanup
incluye únicamente entidades de ese run. No cambia ni debilita la suite original.

Estado de suite Core real del laboratorio actual: BLOCKED por Docker/WSL.
Los32 escenarios de dos corridas anteriores pertenecen al sprint histórico y no
se atribuyen a esta revisión. Core1.0.0 no se declara integralmente revalidado
solo por317 unitarias/widget/contrato.


## Revalidación conjunta del agente único

Fecha UTC: 2026-10-29T06:42:10.981Z (2026-10-28 America/Tijuana). Entorno Windows, Flutter3.47.5/Dart3.13.4, Node22, Docker, Chromium/Playwright, PostgreSQL16 real. Rama feat/tenant-register. Código Flutter 2590aa423c2f329d3309507bf08975db435b63c1; Backend candidato PR10 5e214420394101ae7079f8e844cc759b01cce2a3; revisión de tooling/evidencias f981a839781b6415af51805cf4f0724b16a022f4. La publicación documental posterior no altera estos artefactos.

Esperado: flujo autorizado sin regresión, integridad ni secretos expuestos. Observado: evidencia nueva indicada abajo. Los apartados anteriores se conservan como histórico; este apartado actualiza su estado.

REGRESION_CORE=PASS. Dos corridas limpias Core 32/32 PASS con runId distintos: sprintdc70c9ca74cb74 y sprint019b5402c9f1ad. core-clean-run1.json y core-clean-run2.json: sourceMatches=true,cleanupPASS. Se comprueba igualdad byte-equivalente del checksum de8 tablas antes/después.

Auth3roles, logout/deeplink, restauración por reload, tenantA/B, UsersCRUD/SEC01/shared/noop/concurrencia, campañas CRUD/archivo/borrado, prospectos nullable, CSV CREATE/SKIP/LINK_EXISTING/UPDATE_EXISTING, DashboardSQL, Jobs lectura/503. D4 sustituye autoridad snapshot solo para escrituras sensibles Users; ahora exige403 vivo, cero parciales y sesión preservada.

core-navigation.json añade UI/API/SQL real con25 miembros sintéticos: página2/anterior, búsqueda única, orden y reload con sesión preservada, cleanupPASS. El intento anterior con expectativa D4 antigua/colisión del fixture se conserva en core-e2e-sprint169b03e79fe17a.json si presente; se recuperaron solo sus fixtures. No se presenta como una de las dos corridas limpias.
