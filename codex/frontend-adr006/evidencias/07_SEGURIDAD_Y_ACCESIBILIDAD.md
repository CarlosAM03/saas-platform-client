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
