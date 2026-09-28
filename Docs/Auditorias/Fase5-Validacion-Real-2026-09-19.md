# Fase 5 — Validación real de baseline Flutter

Fecha: 2026-09-19

## Alcance

Se intentó cerrar la validación real de `PlataformaFlutter/saas-platform-client` sin implementar funcionalidades de campañas, prospectos ni jobs. El checkout estaba limpio al iniciar y continuó limpio respecto de archivos versionados.

## Evidencia de entorno

- No había `flutter` ni `dart` disponibles en el PATH inicial.
- Se instaló Flutter estable en una ruta aislada fuera del checkout.
- El Dart SDK embebido quedó operativo en versión `3.13.4`, compatible con `sdk: ">=3.3.0 <4.0.0"`.
- Flutter no completó su bootstrap en este Windows aislado: el CLI falló al listar `bin/cache/downloads/.../*` con `PathNotFound` y dejó locks del bootstrap. También se probaron alias de ruta corta sin resolver el problema.

## Comandos solicitados

| Comando | Resultado | Evidencia / límite |
|---|---|---|
| `flutter doctor -v` | Bloqueado por entorno | Bootstrap/caché de Flutter falló antes de producir un diagnóstico completo. |
| `flutter pub get` | No ejecutado | Requiere el CLI Flutter funcional para resolver dependencias `flutter` y `flutter_test`. |
| `dart run build_runner build --delete-conflicting-outputs` | No ejecutado | El Dart embebido funciona, pero `dart pub` no puede resolver el SDK Flutter del proyecto. |
| `flutter analyze` | No ejecutado | Bloqueado por el mismo bootstrap. |
| `flutter test` | No ejecutado | Bloqueado por el mismo bootstrap. |

No se declaran comandos exitosos sin salida verificable. En particular, no se corrigieron supuestos diagnósticos del código basándose en ejecución simulada.

## Artefactos generados

`lib/shared/models/api_models.g.dart` era un archivo ignorado por Git con el contenido explícito `Generated placeholder`; no era salida legítima de `build_runner`. Se retiró para no conservar generación manual disfrazada. La salida real debe producirse ejecutando `build_runner` en un entorno Flutter funcional.

## Límites restantes

1. Ejecutar `flutter doctor`, `flutter pub get`, `build_runner`, `flutter analyze` y `flutter test` en un host donde Flutter complete la caché del engine y del CLI.
2. Regenerar `api_models.g.dart` únicamente con `build_runner` y revisar el diff generado.
3. No declarar Fase 5 cerrada ni lista para features hasta contar con esa evidencia.

Se mantuvo fuera de alcance cualquier implementación de campañas, prospectos o jobs.
