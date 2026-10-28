# Acta G2 — validación local

Emitido UTC: 2026-10-28T00:23:34.968Z. Entorno: Windows/PowerShell7 y Docker Desktop Linux29.9.2/Compose5.6.1. Candidatos dev: Backend 09593bb715cd83270821d34126a4344c8ef97cb0; Flutter cd527ef12bc7c1327ed9a8520e1a07f0fc8be39f.

| Prueba | Resultado | Evidencia |
|---|---|---|
| Backend unitarias | PASS:5 suites/41 pruebas | evidencias/backend-unit.json |
| Backend HTTP | PASS:6 suites/78 pruebas | evidencias/backend-http.json |
| PostgreSQL baseline | PASS:3 suites/20 pruebas | evidencias/backend-pg.json |
| Flutter integrado | PASS:markers, generación, analyze y256 pruebas | evidencias/flutter-dev-suite.json |
| Contratos Flutter | PASS:101 casos, subconjunto de suite | CI y ejecución focalizada, no sumar como cobertura distinta |
| Runtime real Backend | PASS:38 checks | evidencias/backend-runtime-dev.json |
| UI real cinco perfiles | PASS | evidencias/flutter-ui-dev.json |
| CSV desde UI | PASS:preview+confirm de una fila sintética | evidencias/core-csv-confirmed.png |
| B API/worker/callbacks | PASS:26 comprobaciones | evidencias/experimental-e2e.json |
| B UI | PASS:creación, normal/vacío/FAILED | evidencias/experimental-ui.json |
| B caída y generación nueva | PASS:no reanudación durable | evidencias/experimental-restart-after.json |
| Comandos completos de arranque | PASS:core y demo | evidencias/start-core-full.log; start-demo-full.log |

Ambos stacks usan bases/volúmenes exclusivos y credenciales locales distintas de producción. Core contiene solo la migración init; B aplica P2 únicamente a avance2_experimental tras comprobar propiedad. Ninguna prueba usa datos DATRA, Supabase ni búsquedas públicas.

Se corrigieron fallos del harness: limpieza FK de fixtures, sockets del sandbox (EACCES resuelto ejecutando con loopback permitido), archivos requeridos por el montaje Linux y bootstrap/EOL Windows. Dos ejecuciones PostgreSQL fallidas dejaron fixtures propios; se retiraron solo sus IDs inspeccionados en una transacción del volumen exclusivo y se confirmó que quedaron dos tenants. No se borraron tests ni se excluyeron suites. La primera repetición de sesión coincidió con el reinicio; sus evidencias se conservan, no se cuentan como PASS.

Limitaciones: pruebas automatizadas de respuestas tardías/diálogos usan fixtures de UI; la navegación y Auth/CSV/roles/tenant sí se ejecutaron contra contenedores reales. Dockerfile.vercel se probó con HTTPS local confiable y, por separado, con origen público sin red. No confundir esos checks con smoke autenticado productivo.

G2 CUMPLIDO para el alcance local autorizado. Producción y datos productivos se informan por separado.

Comprobación complementaria completada sin cambios de fuente: Verify-Core-Serialization.cjs ejecutó el UsersService compilado del runtime y dos transacciones PostgreSQL reales; obtuvo P2034, conservó la escritura concurrente y rechazó atómicamente nombre+rol. Fixture propio limpiado. Evidencia: core-serialization-runtime.json. La prueba adicional UI también terminó PASS: ADMIN A→B,401real, restauración ACTIVO y nuevo login (core-session-tenant-ui.json).
