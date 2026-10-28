# Resultados de calidad y alcance

Código de aplicación probado: 7b5320c2a61e2f4170f23f5637cf630a9902de7d. Backend main b51b265f1a545fa915f1dd1c57ef2f5858ec6492. Fecha de cierre:28 octubre2026 (America/Tijuana); los JSON llevan UTC.

| Comando / control | Exit | Estado | Resultado |
|---|---|---|---|
| dart run tool/check_merge_markers.dart | 0 | PASS | baseline y CI |
| flutter pub get | 0 | PASS | lock y dependencias de producción conservados |
| dart run build_runner build | 0 | PASS | generación local/imagen y CI |
| flutter analyze | 0 | PASS | sin issues |
| flutter test --reporter expanded | 0 | PASS | 279 pruebas |
| flutter build web --release --no-wasm-dry-run | 0 | PASS | Windows; imagen E2E final; release en CI |
| Run-P2C.ps1 (contraseña redactada) | 0 | PASS | 1 integración real, repetida sobre el código final |
| node tool/sprint/e2e.mjs (run1) | 0 | PASS | 32/32; SQL y cleanup |
| node tool/sprint/e2e.mjs (run2) | 0 | PASS | 32/32; repetición limpia |
| node tool/sprint/api-negative.mjs | 0 | PASS | 6/6 HTTP_SQL; cleanup |
| remote-ui.mjs (stdin protegido) | 0 | PASS | 7 resultados / 17 respuestas |
| Smoke público | 0 | FAIL | alias histórico404/CORS; URL correcto PASS |
| CI foundation,container,production-container | 0 | PASS | https://github.com/CarlosAM03/saas-platform-client/actions/runs/40667717590 |

Los controles Docker productivos usan Dockerfile.vercel y Dockerfile.dev originales en CI, incluidos smoke Nginx/SPA y runtime sin SDK. La imagen E2E local final acelera con toolchain existente verificado3.47.5/3.13.4 y WORKDIR vacío; no incorpora fuentes de otra rama.

Regresiones antes/después: FE-01/02/03 tuvieron10 fallos iniciales y19 PASS después; FE-09 conserva deep link/query; FE-05/08 fallan contra main original (p2-before.txt); FE-10 falló con NoSuchMethodError al renderizar un Job y pasa tipado. No se redujeron expectativas ni controles de seguridad.

Warning previo de build_runner: analyzer3.12 frente lenguaje SDK3.13. No se introdujeron paquetes nuevos ni se alteró el lock. Las actualizaciones de registrantes por pub get se restauran como salida generada de esta ejecución.

Este reporte identifica el SHA de código; el commit documental posterior incorpora evidencias sin modificar las fuentes de aplicación. Los checks del HEAD documental se revisan también en el PR antes de entrega.
