# Validación del sprint CP frontend

Fecha local: 2026-11-24, America/Tijuana. Timestamps de los recibos JSON en UTC ISO 8601.

Código frontend verificado: `e78b82a32d3afe185b69c2643455034e52ba57f6`. Backend real: `779fc7885faefdfe9e3cb0f3fee86810d96d2711`. El commit posterior sólo incorpora estos recibos y capturas; no cambia código, pruebas, dependencias ni configuración de ejecución.

## Resultados ejecutados

| Comando / comprobación | Fixture y esperado | Observado | Estado |
|---|---|---|---|
| `flutter test --no-pub --reporter expanded` | Fixtures sintéticos; regresión baseline y 17 pruebas CP nuevas | 334 aprobadas; una prueba de historial reservada para Chrome omitida | PASS |
| `flutter test --no-pub tool/sprint-cp/t32_real_api_test.dart --dart-define=CP_REAL_API=true --reporter expanded` | UI Flutter → HTTP NestJS → PostgreSQL16 en proyecto `andre-sprint-cp`, sin mocks de API | 12 casos aprobados; recibo `T32.json`, solicitudes sólo con método/ruta/status | PASS |
| `node tool/sprint-cp/verify-contract.mjs` | Swagger servido igual al arnés inmutable y matriz de 25 operaciones | 39 rutas, 77 esquemas, 25 pares; SHA256 normalizado `1520369724d778a620541c1f56e312dd6a41a221afdbb3e857030b6c6a7ec14f` | PASS |
| Comparación de blobs Git del handoff | Copia completa sin alteraciones | 10 blobs idénticos; recibo `INTEGRIDAD.json` | PASS |
| `flutter build web --release --no-pub --no-wasm-dry-run --dart-define=API_BASE_URL=https://api.example.invalid` | Compilación del cliente completo; origen de ejemplo sin servicio real | `Built build/web`, 56.6 s | PASS |
| `flutter analyze --no-pub` | Sin diagnósticos | `No issues found`, 4.3 s | PASS |
| `flutter test --no-pub --platform chrome test/adr006/web_history_test.dart --reporter expanded` | Ejecutar el caso de historial en navegador real | El runner local quedó en carga sin iniciar el caso; intento detenido. No se declara PASS | NOT_RUN |

T32 verifica alta con match y confirmación humana; etapa CONTACTADO; 400 real al evaluar NO_APTO sin motivo y éxito al completarlo; PUT/DELETE de responsable; CALL y CORRECTION conservando original; edición compartida contextual con MASTER_UPDATED; preview CSV sin escrituras y confirmación de dos filas; resumen de una sola instantánea; campañas/procedencia con UI; filtro C6 contra servidor; MEMBER sin controles de alta/importación y dos 403 reales; cambio de tenant con desaparición inmediata de datos previos y 404 real de la campaña ajena.

La suite CP también verifica consulta C6 con todas las dimensiones, paginación, parser estricto, CORRECTION manual, prohibición de crear MASTER_UPDATE, 400/401/403/404/409 sobre PUT, limpieza sólo ante 401 de la sesión actual, 409 de resolución con reverificación explícita y descarte del candidato anterior, respuesta tardía tras cambiar tenant, estado de error/reintento y visibilidad OWNER/MEMBER. Se conservan las pruebas baseline de expiración/409 CSV, respuesta incierta, límites de archivo y formularios.

## Alcance y límites

- Flutter local 3.41.6 / Dart 3.11.4. La CI existente usa Flutter 3.47.5; `pubspec.lock` se conserva idéntico al baseline. La resolución local usa los paquetes compatibles con el SDK instalado; no se publican cambios de dependencias.
- `flutter pub get` genera los archivos de paquetes pero reporta falta de soporte de symlinks para plugins nativos en Windows. No se cambió Developer Mode ni otra configuración del sistema. Las pruebas Flutter y la compilación Web se ejecutan con `--no-pub` después de generar los modelos con build_runner.
- T32 es un recorrido de widgets reales con solicitudes TCP reales, no una ejecución Chromium de la aplicación CP. El selector de archivos recibe un CSV sintético explícito y el token se guarda en memoria de pruebas. No se simulan respuestas ni persistencia del backend.
- Las capturas `participacion.png`, `importacion.png`, `resumen.png` proceden de ese recorrido real, alojado en MaterialApp de prueba con Inter. Se inspeccionaron para comprobar textos y disposición; los glifos de iconos no se cargan en este host de pruebas. No certifican el tema completo de producción, contraste exhaustivo ni lectura humana con tecnologías asistivas.
- No se ejecutó aquí la regresión backend de 468 pruebas; no se atribuye como ejecución propia. No hubo datos reales, correo real, prospección pública, merge ni deploy.
- Se preservan tres espacios finales de Markdown del arnés histórico porque representan saltos de línea y la copia debe permanecer íntegra. El chequeo de whitespace del código propio pasa; esos tres avisos pertenecen al documento copiado sin editar.

## Hallazgos y decisiones

El owner autorizó usar `779fc78` y su suplemento para resolver roles de PATCH del maestro, respuesta EmptySuccess al archivar campañas y exclusión de sortBy=email de campañas. Después autorizó que los conflictos CSV con múltiples candidatos se rechacen y requieran corregir el archivo, como implementa el backend, pese al texto CREATE/SKIP del arnés. La excepción de ApiClient se limita al método PUT autorizado y sus pruebas. Las fuentes y alcance constan en `../README.md`.

La primera regresión expuso cuatro pruebas históricas que aún asumían alta directa, edición sin confirmación o el cliente de listado anterior: se actualizaron sus fixtures/aserciones manteniendo sus verificaciones. Una prueba nueva encontró desbordamiento de filtros al expandirlos en ventana pequeña; se corrigió con un área desplazable y la prueba pasó. Los intentos iniciales de T32 requirieron corregir publicación loopback del laboratorio y coordinación del reloj/red del runner; el recibo final contiene sólo el recorrido ejecutado satisfactoriamente.

## Revisión y publicación

El PR nuevo se apila sobre `feat/tenant-register` para que el diff contenga únicamente el sprint CP. Eso no modifica esa rama ni su PR #11, que continúa abierto sobre main. La integración, orden de merges y promoción quedan al owner. No se cierra G6 ni se aprueba producción por esta validación local.
