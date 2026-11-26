# RELEASE_MANIFEST_ADR006

Fecha UTC: 2026-10-29T06:42:10.981Z (2026-10-28 America/Tijuana). Entorno Windows, Flutter3.47.5/Dart3.13.4, Node22, Docker, Chromium/Playwright, PostgreSQL16 real. Rama feat/tenant-register. Código Flutter 2590aa423c2f329d3309507bf08975db435b63c1; Backend candidato PR10 5e214420394101ae7079f8e844cc759b01cce2a3; revisión de tooling/evidencias f981a839781b6415af51805cf4f0724b16a022f4. La publicación documental posterior no altera estos artefactos.

Esperado: flujo autorizado sin regresión, integridad ni secretos expuestos. Observado: evidencia nueva indicada abajo. Los apartados anteriores se conservan como histórico; este apartado actualiza su estado.

Código Flutter probado: 2590aa423c2f329d3309507bf08975db435b63c1; Backend congelado: 5e214420394101ae7079f8e844cc759b01cce2a3. Tooling/evidencia previo a publicación documental: f981a839781b6415af51805cf4f0724b16a022f4. El commit que contiene este archivo se obtiene con git log -1 -- este archivo; un manifiesto no puede contener su propio hash. CI exacto de publicación se atesta en PR11 después del push. No hay cambios de aplicación posteriores a 2590aa423c2f329d3309507bf08975db435b63c1.

- G1_FRONTEND = PASS
- E2E_LOCAL_CONJUNTO = PASS
- PARIDAD_33_MAS_5 = PASS
- REGRESION_CORE = PASS
- SEGURIDAD = PASS
- CI_FRONTEND = PASS
- CI_BACKEND = PASS
- READY_FOR_OWNER_REVIEW = PASS
- BREVO_REAL_READY = OWNER_ACTION_REQUIRED
- CORREO_REAL_ENTREGA = NOT RUN
- READY_FOR_OWNER_EMAIL_PILOT = PASS
- PILOTO_OWNER_INSTITUCIONAL = OWNER_ACTION_REQUIRED

READY_FOR_OWNER_EMAIL_PILOT significa preparación local deshabilitada, no remitente/Brevo/entrega comprobados. Solo el owner puede comprobar cuenta/dominio/cuota y activar una única acción manual, siguiendo Docs/ADR006_PILOTO_EMAIL_REAL.md. Sin destinatario institucional ni clave solicitados al agente.

Matriz: MATRIZ_E01_E25.md. Inventario: INVENTARIO_33_MAS_5.md. Artefactos/hashes: release-manifest.json. Ningún merge, despliegue, Supabase ni envío real.
