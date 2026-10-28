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
