# E2E Flutter → Backend → PostgreSQL

Fecha: 2026-10-28, America/Tijuana. Rama feat/tenant-register, cliente a09c117/
919ce03. Snapshot preliminar Backend ca1e7c9d55d4cad73430801140593b58cb7c413b.
Candidato final publicado5e214420394101ae7079f8e844cc759b01cce2a3 exportado y
construido por separado; compatibilidad E2E final aún BLOCKED.

Comandos: tool/frontend-adr006/Start-Lab.ps1 -BackendPath <checkout-read-only>;
node tool/frontend-adr006/e2e.mjs. Proyecto prospector-frontend-g1; PostgreSQL16
avance2_core, volumen etiquetado frontend-g1-exclusive. API18641, HTTPS18643,
DB55647, noVNC18650, todos en loopback. Configuración/credenciales aleatorias en
.local ignorado. No datos/clientes/SMTP productivos.

Esperado: registro ADMIN201, entidades atómicas, consulta/reenvío, enlace obtenido
solo del transporte sintético, limpieza, canje sinJWT, contraseña, LOGIN_REQUIRED,
loginOWNER, relectura, aislamiento y cleanup.

## Observación preliminar real

- Login ADMIN sin tenant200 por Flutter.
- Registro desde cuatro campos: POST201 y estados separados.
- SQL: Tenant, dos Role, User sin platformRole y pendiente, UserTenant OWNER,
  TenantOnboarding, ActivationLink hasheado y DeliveryAttempt ACCEPTED.
- GET onboarding200 y recarga Flutter con PENDING_FIRST_ACCESS.
- Reenvío inmediato429: generación intacta.
- Reenvío tras ventana real de61s:200, sin body, generación2.
- Apertura limpia /activate, pero formulario no alcanzó contraseña en esta corrida.
  No se acredita canje/completado/loginOWNER ni el E2E integral.
- Cleanup de fixtures de los intentos previos: PASS, checksum del seed conservado.

Evidencias: e2e-adr006.json y archivos e2e-adr006-g1fe*.json por run.
Los fallos de instrumentación Windows y de interacción se conservan/clasifican;
no son automáticamente defectos Backend. La última interrupción por Docker no
permite asumir limpieza de cualquier intento que no haya emitido reporte final.

## Candidato final y bloqueo de entorno

El nuevo Backend usa Brevo HTTPS443. El laboratorio preparado asigna api.brevo.com
solo al sink privado por DNS de su red Docker, con certificado propio firmado
por CA local confiada solo en contenedores. No cambia DNS/CA de Windows, no usa
credencial real ni hace tráfico a Brevo. Un201 del doble no acredita recepción.

Docker devolvió500/502 y después WSL/device busy al recrear el navegador. El owner
autorizó reiniciar Docker y luego WSL/Docker; recuperación en curso. No se borraron
volúmenes ni cachés ajenas. Se requiere repetir el recorrido completo contra el
SHA final identificado y verificar de nuevo HEAD remoto.

E2E_LOCAL = BLOCKED (preliminares parciales con FAIL; ninguna corrida integral PASS).
PARIDAD_BACKEND_FINAL = BLOCKED. Estos estados no equivalen a aprobación.
