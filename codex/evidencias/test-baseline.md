# Baseline de calidad

Revisión Flutter: 7731649a2c69b45cb9776d02de4a6105d6fd9886. Backend main b51b265f1a545fa915f1dd1c57ef2f5858ec6492 verificado remotamente.

| Comando | Exit | Estado | Resultado |
|---|---|---|---|
| dart run tool/check_merge_markers.dart | 0 | PASS | Sin markers |
| flutter pub get | 0 | PASS | Dependencias bloqueadas conservadas |
| dart run build_runner build | 0 | PASS | 80s; salida generada ignorada |
| flutter analyze | 0 | PASS | Sin issues; 47.4s |
| flutter test --reporter expanded | 0 | PASS | 256 pruebas; 25s |

Warning previo: analyzer admite lenguaje3.12 frente SDK3.13. No se actualizaron dependencias para ocultarlo.

Las regresiones nuevas iniciales de FE-01/02/03: 9 aprobadas, 10 fallidas; después19 aprobadas. FE-09: fallo anterior reproducido contra el router real; la ruta esperada terminaba en Dashboard. Después,37 pruebas de router/Auth/CRUD vecinas aprobadas. La suite final de código produjo278 aprobadas y análisis limpio.

Las salidas locales .log están ignoradas por reglas existentes; se entregan resúmenes y JSON sanitizados. No se versionan registrantes generados por pub get.
