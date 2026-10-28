# QA de navegador e historial

Fecha: 2026-10-28, America/Tijuana. feat/tenant-register; aplicación a09c117,
test919ce03. Entorno: Flutter Web release real, Chromium/Playwright del navegador
Docker exclusivo y Edge156 nativo/CDP. HTTP simulado en las pruebas de historial/
resiliencia; no se presentan como E2E PostgreSQL.

Comando: node tool/frontend-adr006/run-browser.mjs.
Esperado: reemplazar la entrada antes del motor/router, no push del secreto,
back/forward/refresh sin canje repetido, estado/storage/consola limpios.

| Grupo real | Observado | Estado |
|---|---|---|
| Replace antes del router + back/forward + reload | Una redención, ninguna escritura posterior con secreto | PASS |
| Nueva pestaña, enlaces inválidos/duplicados y storage de sesión | URL limpia; errores seguros; código ausente de persistencia | PASS |
| replaceState lanza excepción | No inicia canje ni formulario | PASS |
|400/401/403/404/409/429/500/503 y pérdida de red | Un intento, sin eco de secretos ni reintento automático | PASS |

Salida: [browser-qa.json](browser-qa.json). Reproducción inicial fallida:
[browser-qa-before.json](browser-qa-before.json). El scrub solo en Dart no bastaba:
el motor ya podía capturar el URI inicial. El bootstrap JS limpia antes de
flutter_js/loader; el valor original viaja por closure consumible y se elimina
la función de handoff al leerla. Dart conserva validación/one-shot existentes.

CI ejecuta node --test tool/frontend-adr006/bootstrap.test.mjs (4 PASS) y
flutter test --platform chrome test/adr006/web_history_test.dart (PASS en919ce03).
Esta última prueba valida el primitivo de historial; no sustituye la aplicación
compilada ni el E2E. Edge con el runner Flutter quedó en loading; el mecanismo
alternativo real reproducible es Chromium Docker y el runner nativo/CDP.

Ampliaciones de respuesta tardía y reloj±24h: incorporadas al harness; no contar
como PASS hasta terminar su ejecución. El runner nativo confirmó handoff íntegro
y ausencia de Bearer, pero su interacción de formulario sigue en diagnóstico.
Consultar native-browser.json; alcance MOCK_HTTP_NOT_E2E.
