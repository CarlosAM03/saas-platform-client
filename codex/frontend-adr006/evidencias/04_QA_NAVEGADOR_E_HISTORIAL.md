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


## Revalidación conjunta del agente único

Fecha UTC: 2026-10-29T06:42:10.981Z (2026-10-28 America/Tijuana). Entorno Windows, Flutter3.47.5/Dart3.13.4, Node22, Docker, Chromium/Playwright, PostgreSQL16 real. Rama feat/tenant-register. Código Flutter 2590aa423c2f329d3309507bf08975db435b63c1; Backend candidato PR10 5e214420394101ae7079f8e844cc759b01cce2a3; revisión de tooling/evidencias f981a839781b6415af51805cf4f0724b16a022f4. La publicación documental posterior no altera estos artefactos.

Esperado: flujo autorizado sin regresión, integridad ni secretos expuestos. Observado: evidencia nueva indicada abajo. Los apartados anteriores se conservan como histórico; este apartado actualiza su estado.

Estado: PASS. browser-qa.json:7/7 REAL_BROWSER con HTTP sintético declarado. Procedimiento: node tool/frontend-adr006/run-browser.mjs; para la ampliación móvil se ejecutó el mismo módulo fresco bajo service/HOME=/tmp/prospector-browser-home, con TLS verificado. Back/forward/reload, pestañas nuevas, duplicados, storage, replaceState fallido sin canje, errores/red, respuesta tardía, reloj±24h y móvil teclado/foco PASS.

Las activaciones E2E reales están separadas en e2e-original-link.json y e2e-resend-link.json. native-browser.json conserva FAIL histórico de foco Edge/CDP; se revisó y documentó como diagnóstico, no aceptación. El runner mantenido Playwright/Chromium ejecuta efectivamente el historial. browser-qa-context-error.json registra un intento bajo root sin CA privada, reemplazado por ejecución correcta bajo service; no se desactivó TLS.
