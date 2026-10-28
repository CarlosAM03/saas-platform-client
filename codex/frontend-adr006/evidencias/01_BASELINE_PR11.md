# Baseline PR #11

Fecha: 2026-10-28, America/Tijuana. Ejecutor: Codex Frontend. Entorno: Windows 11,
Flutter 3.47.5 / Dart 3.13.4, Java 8u503, Node 22.16.0, Docker Desktop 4.97.0,
Engine 29.9.2, Edge 156. Rutas cortas existentes C:\w y C:\f; no cambios globales
de PATH, Developer Mode, políticas o SDK.

Repositorio CarlosAM03/saas-platform-client. Inicio local:
sprint/frontend-core-v1-parity@469677d88339157379d28f1dd883f6af0626d981.
Únicos archivos ajenos: Docs/Planeacion/Avance2_Cierre_Core_Integracion_ADR006/
sin rastrear; preservados y excluidos de los commits. Índice y código inicialmente
limpios. Se inspeccionaron cuatro worktrees existentes sin modificarlos.

Fetch y GitHub confirmaron main e752f6ca692d2840263cd9e59e0927c56aa129ec y
PR11 feat/tenant-register@9c0e556b64f6ca51db3baaf284096adcde480e9b.
Switch seguro a la rama remota, sin stash/reset/rebase/force-push.

## Ejecución del baseline intacto

Comandos, UTC de inicio, duración y exit code: [baseline-commands.jsonl](baseline-commands.jsonl).

| Procedimiento | Esperado | Observado | Estado |
|---|---|---|---|
| dart run tool/check_merge_markers.dart | Sin conflictos | Exit 0 | PASS |
| flutter pub get | Lockfile conservado | Exit 0, sin bloqueo symlink | PASS |
| dart run build_runner build | Generación | Exit 0, cero outputs nuevos | PASS |
| flutter analyze | Sin incidencias | Exit 0 | PASS |
| flutter test --reporter expanded | Reproducir 312 | 312 PASS + 1 omitida de navegador, exit 0 | PASS |
| flutter test test/adr006 --reporter expanded | Reproducir 33 | 33 PASS + 1 omitida, exit 0 | PASS |
| flutter build web --release --dart-define=API_BASE_URL=http://localhost:3311 | Compilar | Exit 0 | PASS |
| flutter test --platform chrome ...web_history_test.dart con Edge | Historial real | Runner detenido en loading; cancelado sin caso aprobado | BLOCKED |

La URL3311 solo fue un argumento de compilación del baseline. No acredita API.
Advertencia histórica analyzer3.12/SDK3.13 y fuente Cupertino no declarada:
no fatales, sin upgrades. Pubspec.lock no cambió.

La evidencia de Ángel permanece en codex/evidencias/adr006-flutter-*.md.
Su SDK3.47.2 y bloqueo symlink no se atribuyen a esta máquina. Los279 tests Core
son históricos; aquí se ejecutó otra vez la suite completa del PR.

Backend inicialmente publicado: ca1e7c9d55d4cad73430801140593b58cb7c413b.
El checkout principal Backend estaba en otra rama/SHA y se mantuvo en lectura.
Se exportaron commits con git archive a .local ignorado, sin fetch ni escrituras
en Backend. Candidato posterior publicado: 5e214420394101ae7079f8e844cc759b01cce2a3.
