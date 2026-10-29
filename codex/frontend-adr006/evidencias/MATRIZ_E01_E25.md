# Matriz E01–E25

Fecha UTC: 2026-10-29T06:42:10.981Z (2026-10-28 America/Tijuana). Entorno Windows, Flutter3.47.5/Dart3.13.4, Node22, Docker, Chromium/Playwright, PostgreSQL16 real. Rama feat/tenant-register. Código Flutter 2590aa423c2f329d3309507bf08975db435b63c1; Backend candidato PR10 5e214420394101ae7079f8e844cc759b01cce2a3; revisión de tooling/evidencias f981a839781b6415af51805cf4f0724b16a022f4. La publicación documental posterior no altera estos artefactos.

Esperado: flujo autorizado sin regresión, integridad ni secretos expuestos. Observado: evidencia nueva indicada abajo. Los apartados anteriores se conservan como histórico; este apartado actualiza su estado.

PASS se refiere al alcance especificado, no convierte HTTP sintético en E2E ni recepción de correo real.

| Caso | Criterio | Alcance ejecutado | Evidencia | Estado |
|---|---|---|---|---|
| E01 | PostgreSQL16 migrado/seed | SQL + Core setup/checksum | core-clean-run1.json | PASS |
| E02 | ADMIN login | UI_HTTP real | e2e-original-link.json | PASS |
| E03 | OFF sin escrituras y recuperación pendiente | HTTP_SQL real | http-sql.json | PASS |
| E04 | Registro201 atómico | UI_TO_DB real | e2e-original-link.json | PASS |
| E05 | 400/403/409 sin parciales | HTTP_SQL real + CoreUI | http-sql.json | PASS |
| E06 | Onboarding/fechas/relectura | UI_TO_DB_READ real + contrato | e2e-resend-link.json | PASS |
| E07 | Transporte HTTPS falso aislado | UI_TO_DB + networkinternal | e2e-resend-link.json | PASS |
| E08 | Proveedor400/429/500/timeout sin retry | HTTP_SQL + fakeHTTPS real | http-sql.json | PASS |
| E09 | Resend temprano429 | UI_TO_DB real | e2e-resend-link.json | PASS |
| E10 | Resend200 sin body/generación | UI_TO_DB real | e2e-resend-link.json | PASS |
| E11 | Activación enlace original | UI_TO_DB real | e2e-original-link.json | PASS |
| E12 | Nueva generación/revocación original | UI_HTTP + SQL real | e2e-resend-link.json | PASS |
| E13 | Historial/URL/storage | Chromium real HTTP sintético + E2E | browser-qa.json | PASS |
| E14 | Password/TTL/servidor | HTTP_SQL real + Chromium sintético | http-sql.json | PASS |
| E15 | LOGIN_REQUIRED y login normal | UI_TO_DB real | e2e-original-link.json | PASS |
| E16 | Roles/ADMIN/multi/JWT obsoleto | Core UI_TO_DB real | core-clean-run2.json | PASS |
| E17 | Identidad compartida SEC01 | Core UI_TO_DB real | core-clean-run2.json | PASS |
| E18 | Users nullable/QF01 sintético | Unit + Core UI + navegaciónAPI | core-navigation.json | PASS |
| E19 | Campañas/Dashboard | Core UI_TO_DB real | core-clean-run2.json | PASS |
| E20 | Prospectos/4 decisiones CSV | Core UI_TO_DB real | core-clean-run2.json | PASS |
| E21 | Jobs consulta y503 intencional | Core UI_TO_DB real | core-clean-run2.json | PASS |
| E22 | Paginación/búsqueda/orden/sesión/tenants/deeplink | Core UI/API/SQL real | core-navigation.json | PASS |
| E23 | Errores/red/late response | Browser HTTP sintético + Core real403/409/503 | browser-qa.json | PASS |
| E24 | Dos corridas limpias/checksum | Core UI_TO_DB real | core-clean-run1.json; core-clean-run2.json | PASS |
| E25 | Build/CI | Release local + Docker + CI exactocódigo | container-smoke.json; PR11 atestaciónHEAD | PASS |
