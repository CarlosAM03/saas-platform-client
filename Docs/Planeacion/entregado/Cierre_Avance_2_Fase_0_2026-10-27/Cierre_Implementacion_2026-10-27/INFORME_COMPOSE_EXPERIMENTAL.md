# CR-AV2-DEMO-110-01 — informe experimental

FechaUTC:2026-10-28T00:33:57.497Z. La autorización ampliada del owner convirtió la propuesta original de Fase7 en permiso G6 de diseño, construcción y validación local. El plan rector/históricos no se sobrescribieron. Alcance aprobado: demostración local controlada; arquitectura productiva1.1.0 permanece pendiente.

| Componente | Fuente final local | Naturaleza |
|---|---|---|
| Backend experimental |45df09aebae4ad0a8ec32334894b4d21f81f9272, basea80871b6 |NestJS/Prisma reales, P2 solo en DB propia; JWT baseline snapshot y SEC-01 seleccionados |
| Flutter experimental |67d90451fccfa7dccfb88ca0547cca015da51d47, base97ad02a |Flutter/Nginx reales, banner global permanente y textos controlados |
| Service experimental |ad7bec3d7a1212f1bb2e0a808ffea3c42d5aed30, base566bbbe |src/ funcional intacto; paquete demo/avance2 añadido |
| Engine instalado |70f6081688db5c5bc5ea612f5fabd5724aab0b20 |Instalación real0.1.0.dev0 y BrowserRuntime Chromium comprobado separadamente |
| ControlledEngine |demo/avance2/controlled_service.py |Fixtures sintéticos, no llama Engine.search |

FastAPI, worker, callbacks HTTP autenticados y PostgreSQL son reales. El transporte de observación delega HTTP real y registra solo cuerpos de eventos sintéticos, sin headers/keys. Campo source=google_maps es enum del protocolo, no procedencia real. Los nombres CONTROLLED DEMO y el rótulo DEMO INTEGRADA — RESULTADOS CONTROLADOS aparecen antes del login y en todas las rutas Flutter (capturas verificadas). No se ejecutó scraping externo.

Proyecto prospector-demo-110, DBavance2_experimental, volúmenes demo-pg/demo-tls etiquetados con propietario exclusivo. PostgreSQL/Service no publican puertos. NestJS, Service y web comparten namespace limitado para loopback permitido por guards actuales; no se desactivan TLS/hostname/validaciones productivas. Gateway expone solo127.0.0.1:18463 y navegador18470 con confianzaCA dentro del contenedor. Core usa otros secretos, DB, volúmenes y puertos.

Migraciones comprobadas: init20260909152421 y20261027063000_prospector_mvp_integration únicamente en B. Core conserva solo init. El seed prepara dos tenantsCUID sintéticos y cinco cuentas; conserva seis campañas y36 prospectos baseline, y demo-fixtures.cjs agrega dos campañas CUID reservadas. Total8 campañas, idempotentes. Las campañas legacy del seed no cumplen CUID experimental; para Jobs elegir Demo controlada1.1.0 norte/sur. El seed restaura contraseñas de las cuentas reservadas y no se usa en Supabase.

## Aceptación ejecutada

| Criterio | Resultado | Evidencia |
|---|---|---|
| Build/arranque de un comando |PASS |start-demo-full.log, bootstrap4/7 claves y ownership checks |
| Crear desde Flutter |PASS |experimental-ui.json; experimental-created-from-flutter.png |
| Worker/callback/estadoPG |PASS |9callbacks200 de los3 casos API y eventos/snapshots PG reales |
| Normal / vacío / FAILED |PASS |experimental-e2e.json:26 checks y UI correspondiente |
| Idempotencia |PASS |mismo key/payload mismo job; payloaddistinto409; replay callback200 sin duplicar |
| Claves internas |PASS |ausentes/claveequivocada401; keys distintas y no en bundle |
| Tenant A/B y campaña |PASS |job ajeno404, campaña ajena404 y UIA aislada |
| Caída abruptaService |PASS |slow→RUNNING, KILL de su contenedor propio, generación nueva→FAILED/SERVICE_RESTARTED |
| Sin recuperación ficticia |PASS |mismo key devuelve mismo FAILED, no reanuda worker |
| Reinicio/fixtures |PASS |2 tenants/5 usuarios/8 campañas/36 prospectos conservados |
| Core sin efectosB |PASS |conteos2/5/7/38/10 iguales antes/después y Git separado |
| Enginebrowser real sin búsqueda |PASS |probeChromium en página de contenido local, sin Maps |

Snapshots vencen1h. Para la presentación de19:00 crear un Job nuevo desde la UI o ejecutar Prepare-Presentation.ps1 cerca de la demostración: prepara normal/empty/fail frescos, conserva cuotas y utiliza keys por minuto para repetir sin duplicación inmediata. No ejecutar en bucle ni presentar una captura como resultado aún vigente. El comando se ejecutó y aprobó.

Comandos y apagado están en ACCESO_RAPIDO_AVANCE2.md y demo/avance2/README.md. G6 CUMPLIDO exclusivamente para demostración controlada. Persistencia temporal/cuotas/reanudación/arquitectura productiva requieren aceptación futura. Opt-in de scraping real exige aprobación específica de consulta, cantidad, red, condiciones y presupuesto, otro almacenamiento separado y entrypoint EngineAdapter real; este paquete no ofrece perfil real automático.
