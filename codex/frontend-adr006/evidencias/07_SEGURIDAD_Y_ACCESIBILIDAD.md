# Seguridad y accesibilidad

Fecha: 2026-10-28, America/Tijuana. feat/tenant-register; código a09c117,
fixture919ce03. Entorno y procedimientos: Flutter tests, bootstrap Node,
Chromium real, Edge/CDP, revisión estática ApiClient/router/estado/formularios.

Esperado: credenciales públicas solo en body/memoria, ninguna sesión nueva por
activación, Backend autoritativo, errores seguros, foco/teclado y móvil funcional.

| Control | Observado | Estado |
|---|---|---|
| Historial antes del motor/router | Falló antes; cuatro grupos Chromium pasan tras scrub JS temprano | PASS |
| JWT en canje/completado | ApiClient no lee storage ni adjunta Authorization;401 público no hace logout | PASS UNIT/CONTRACT |
|403 administrativo | Conserva sesión; error contextual, sin eco de proveedor | PASS UNIT |
| Token/challenge/password | Fuera de estado Riverpod/URI/storage/logs; DTO toString redactado | PASS revisión/tests |
| Respuesta tardía tras leave/dispose | Operación invalidada; no rehidrata desafío | PASS UNIT |
| Reloj dispositivo | No decide TTL;401 servidor destruye desafío; sin retry de canje | PASS UNIT |
| Registro móvil390×844 | Primer inválido enfocado, next/done, busy bloquea envío duplicado, sin overflow | PASS WIDGET |
| Errores accesibles | Live regions, labels persistentes; estados busy y confirmación de resend | PASS revisión/widget |
| Lector de pantalla humano/contraste exhaustivo/dispositivo nativo | No ejecutado | NOT RUN |

No se agregó cliente HTTP, router, endpoint de roles, dependencia productiva,
analytics ni persistencia de activación. CanvasKit local ya existente en el PR.
Eliminar referencias Dart/JS no garantiza borrado físico inmediato de strings/GC.
No se promete eliminar copias previas de enlaces en correo o software externo.

Tooling: credenciales efímeras solo .local ignorado; sink de correo solo acepta
destinatarios sintéticos; sin relay externo. Evidencias HTTP guardan método,
path,status,requestId,nombres de campos y booleanos de Bearer/body, sin sus valores.
El runner nativo usa perfil propio y sandbox normal de Edge; sin confiar CA global.

Pendiente: repetir seguridad real contra Backend final y completar el E2E.
Un resultado estático o widget no acredita autorización NestJS.


## Revalidación conjunta del agente único

Fecha UTC: 2026-10-29T06:42:10.981Z (2026-10-28 America/Tijuana). Entorno Windows, Flutter3.47.5/Dart3.13.4, Node22, Docker, Chromium/Playwright, PostgreSQL16 real. Rama feat/tenant-register. Código Flutter 2590aa423c2f329d3309507bf08975db435b63c1; Backend candidato PR10 5e214420394101ae7079f8e844cc759b01cce2a3; revisión de tooling/evidencias f981a839781b6415af51805cf4f0724b16a022f4. La publicación documental posterior no altera estos artefactos.

Esperado: flujo autorizado sin regresión, integridad ni secretos expuestos. Observado: evidencia nueva indicada abajo. Los apartados anteriores se conservan como histórico; este apartado actualiza su estado.

SEGURIDAD=PASS en alcance automatizado local. Browser7/7, Core32×2, HTTP/SQL9/9 y suites Backend256 PASS reproducidas en imagen del SHA final. AUTH403 conserva sesión, SEC01 evita editar identidad compartida, sin parciales, aislamiento tenant y sin retry de credenciales. Móvil390×844 con foco al inválido, teclado y envío único PASS real; widget de registro móvil y semántica PASS. Lectura humana de screen reader y contraste exhaustivo: NOT RUN, sin declarar certificación WCAG.

Red de laboratorio internal:true; CA solo contenedor. Se mantuvieron sandbox/seguridad Windows sin cambios. Secretos efímeros solo .local ignorado; no JWT/token/password/URL completa en evidencias. El script OwnerEmailPilot se parseó y probó disabled + guardas de confirmaciones/manifiesto; owner-pilot-guards.json. Nunca se activó Brevo real. Sender/domain/key/cuota/deliverability siguen OWNER_ACTION_REQUIRED. El modo real no registra logs persistentes de API y solo el owner introduce destinatario institucional en UI.
