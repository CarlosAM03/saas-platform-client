# ACCESO RÁPIDO — Avance2

Los dos stacks locales están arrancados y healthy. Backend PR#9 y Flutter PR#6 ya fueron fusionados a main por el owner; CI verde en ambos. Producción se informa separadamente al final.

| Entorno | Abrir / consultar | Estado |
|---|---|---|
| Flutter core |[Abrir navegador de prueba](http://127.0.0.1:18450/vnc.html?autoconnect=1&resize=scale) |PASS; cinco perfiles |
| API core |[Health](http://127.0.0.1:18441/api/v1/health/ready) |PASS; runtimeproductivo real |
| Swagger core |[Swagger1.0.0](http://127.0.0.1:18441/api/docs) |PASS |
| Flutter experimental |[Abrir demo integrada](http://127.0.0.1:18470/vnc.html?autoconnect=1&resize=scale) |PASS; resultados controlados |
| Service experimental |Interno,127.0.0.1:8000 en namespace del BackendB |PASS; no puerto público |

El navegador de pruebas confía en la CA local dentro de su contenedor. La aplicación consume https://localhost:18443 (core) o https://localhost:18463 (B) dentro de ese navegador; no se alteró la confianza TLS del anfitrión. En noVNC pulsar Connect si aparece.

## Cuentas

[Credenciales demo privadas](C:/Users/Carl0/Desktop/ProyectosPersonales/DesarrolloDeSoftwareConComputoEnLaNube/PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing/DocumentacionGlobal/WorktreesAvance2/.local-avance2/ACCOUNTS_PRIVATE.md). No están en Git ni en los informes públicos. Las cuentas son admin@demo.example; owner.demo-norte@demo.example; member.demo-norte@demo.example; owner.demo-sur@demo.example; member.demo-sur@demo.example. A=Demo Norte, B=Demo Sur. ADMIN selecciona contexto; MEMBER puede consultar usuarios y gestionar campañas/editar prospectos, pero no administrar usuarios ni CSV. Estas credenciales son exclusivamente locales.

## Reiniciar rápido

~~~powershell
& 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\backend-core\ops\avance2\Start-Core.ps1' -SkipBuild
& 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\service-experimental\demo\avance2\Start-Demo.ps1' -SkipBuild
~~~

Para reproducir builds+configuración+DB+seed+health desde un comando por entorno, usar los mismos scripts sin -SkipBuild. Docker Desktop Linux y PowerShell7 ya están verificados. No requiere instalar Flutter/Python en el host, mapearQ: ni editar secretos productivos. Se comprueba propiedad de volúmenes y se crean secretos privados si falta configuración. Seedidempotente: restaura passwords de cuentas demo reservadas y conserva datasets. El comando completo de ambos entornos pasó.

Para reinicio/pérdida del workerB, usar Restart-Demo.ps1 en la misma carpeta: rota generación y conserva PostgreSQL; jobs previos activos→FAILED, sin reanudación automática.

## CSV manual

Muestra de dos filas: [DEMO_IMPORTACION_SINTETICA.csv](evidencias/DEMO_IMPORTACION_SINTETICA.csv). En el selector del navegador contenedor usar la ruta /evidence/DEMO_IMPORTACION_SINTETICA.csv. Elegir campaña propia, generar preview y confirmar. Para repetir sin duplicar, revisar coincidencias y elegir LINK_EXISTING/Vincular u Omitir; regenerar si409. No subir XLSX ni archivos DATRA en este recorrido. La prueba ejecutada ya conservó0012345 y añadió solo filas sintéticas.

## Preparar demostración1.1.0

~~~powershell
& 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\service-experimental\demo\avance2\Prepare-Presentation.ps1'
~~~

Hace tres solicitudes sintéticas normal/empty/fail reales a FastAPI/worker/callback y muestra sus rutas. Snapshots duran1h: ejecutarlo cerca de19:00 o crear un Job nuevo desde Flutter. Elegir campaña Demo controlada1.1.0 norte/sur, keywordnormal/empty/fail, ubicación de prueba, límite1. Respeta keys, rate limit y cuotas; repetir la preparación inmediata conserva keys del minuto. No ejecutar en bucle. No hay scraping público.

## Salud y parada

~~~powershell
Invoke-RestMethod http://127.0.0.1:18441/api/v1/health/ready
docker exec prospector-demo-110-service-1 python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8000/health/ready').read().decode())"
~~~

Parada sin pérdida: [APAGADO_SIN_PERDIDA.md](APAGADO_SIN_PERDIDA.md). No se eliminan volúmenes, no se hace prune y no se toca el entorno previo18420. Core:2 tenants/5 usuarios/7 campañas/38 prospectos/10 jobs en la captura de cierre. B:2/5/8/36/19 jobs; snapshots pueden disminuir por TTL. Operaciones manuales posteriores pueden cambiar estos conteos.

## Producción después del owner

[Frontend público](https://saas-platform-client-web.vercel.app) · [API Render](https://saas-platform-backend-l55n.onrender.com) · [Swagger público](https://saas-platform-backend-l55n.onrender.com/api/docs). MainBackendb51b265… y Flutter7731649… tienen CI verde. VercelProduction success y bundle idéntico al candidato. Health/Swagger/CORS públicos aprobados; captura del owner verifica login/dashboard ACME. Atestación Deployment ID/SHA Live Render y pruebas productivas de roles/CSV completas continúan pendientes. No se ejecutaron seeds, migraciones ni carga de datos productivos por Codex.

Ver [dictamen](DICTAMEN_GLOBAL.md), [CI](REGISTRO_CI.md), [guion](GUION_PRESENTACION.md) y [verificación post-merge](RUNBOOK_POST_MERGE.md).
