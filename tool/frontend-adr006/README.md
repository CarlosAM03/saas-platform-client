# QA ADR-006 reproducible

Ejecutar desde la raíz Frontend, con Flutter3.47.5, Node22 y Docker disponible.
Start-Lab exporta un commit Backend verificado; no cambia su checkout. Los puertos
18641/18643/18650/55647 son exclusivos y loopback. PostgreSQL16 y correo HTTPS
sintético están en una red interna; la confianza TLS queda en el contenedor.

```powershell
./tool/frontend-adr006/Start-Lab.ps1 -BackendPath '<checkout Backend de solo lectura>' -BackendSha 5e214420394101ae7079f8e844cc759b01cce2a3
node tool/frontend-adr006/run-browser.mjs
node tool/frontend-adr006/e2e.mjs --quick
node tool/frontend-adr006/e2e.mjs
node tool/frontend-adr006/run-core.mjs
node tool/frontend-adr006/run-core.mjs
node tool/frontend-adr006/run-core.mjs --navigation
node tool/frontend-adr006/http-sql.mjs
```

Ejecutar los runners que usan el navegador autenticado SECUENCIALMENTE. Todos
comprueban su estado; Core y registro comparan checksum antes/después y limpian
solo su prefijo aleatorio. `--quick` activa el enlace original; sin él se esperan
61s de cooldown contractual, se comprueba429 y luego200 sin body, revocación del
original y activación con la nueva generación. No acortar ni editar timestamps.

HTTP/SQL crea una base y dos runtimes propios con flag ON/OFF; los retira al
final. Usa NestJS TCP real, Prisma/PostgreSQL y el fake HTTPS443 confinado,
controlado solo mediante8025 interno. Nunca apunta a Supabase ni Brevo real.

`contract-38.cjs` se ejecuta en la imagen development del snapshot Backend con
Docs frontend montado como /consumer, script /audit.cjs y evidencias /output.
Compara el contrato aprobado con Swagger /api/docs-json del API aislado y registra
la especialización heredada de Jobs separadamente; no altera contratos.

El historial, error/late response, almacenamiento, reloj y móvil se ejecutan con
Chromium real y respuestas HTTP sintéticas en contextos separados. El registro,
activación y Core usan HTTP/SQL reales. No intercambiar esos alcances.
`native-browser.mjs` es un diagnóstico histórico Edge/CDP: su falla de foco queda
en native-browser.json y no es el runner de aceptación. El runner mantenido es
run-browser.mjs, con Playwright/Chromium y CA privada, sin ignorar errores TLS.

No publicar .local, logs crudos, correos, claves, contraseñas, JWT o enlaces.
El piloto real está deshabilitado: ver Docs/ADR006_PILOTO_EMAIL_REAL.md. El agente
no lo activa. CI automatiza tests Flutter, bootstrap Node, historial Chrome,
release y ambas imágenes; la suite conjunta PostgreSQL sigue siendo QA local.