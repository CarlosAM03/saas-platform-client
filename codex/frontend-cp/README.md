# Sprint frontend de campañas y prospectos

## Base y alcance

- Frontend: `feat/sprint-campana-prospector`, base autorizada `0fe5d368e11b1da745ccf42ead3892470dcae0be`, idéntica a `feat/tenant-register` al inicio.
- Backend de solo lectura: `CarlosAM03/saas-platform-backend`, rama `feat/sprint-campana-prospector`, fijado por el owner en `779fc7885faefdfe9e3cb0f3fee86810d96d2711` durante esta sesión.
- Arnés íntegro, sin editar: `codex/06_HANDOFF_ANDRE/`, copiado desde `codex/sprint-campanas-prospectos/06_HANDOFF_ANDRE/` de ese backend.
- Suplemento aprobado: backend `codex/cierre-pr11-backend/evidencias/CONTRATO_Y_HANDOFF.md`. El documento servido de referencia sigue siendo `openapi-served-3b5eec6.json`.
- Sin cambios, commits ni push al backend, a `feat/tenant-register` ni a su PR #11. Sin merge ni despliegue.

## Implementación

C1/C2/C3/C4/C6/C8 amplían los tabs existentes de campaña: filtros AND y paginación del servidor; estado maestro separado de etapa; evaluación con motivo y errores del servidor; responsables elegibles y aviso de reasignación; bitácora inmutable y correcciones manuales; resumen comercial de una única respuesta.

P1 incorpora match previo y decisión humana de reutilización, creación, vinculación u omisión. Un 409 obliga a verificar otra vez y descartar el candidato anterior. La identidad Google Maps conserva sus mayúsculas/minúsculas. P2/P3 agregan campañas asociadas y procedencia paginadas al maestro. La edición contextual avisa del efecto compartido y envía `contextCampaignId`. P4 muestra el resultado de cada fila y permite crear de todas formas ante una coincidencia única; mantiene la regeneración de preview ante 400/409 y la revisión humana ante respuesta incierta.

Arquitectura: widgets → providers Riverpod → repositorios → clientes tipados en `lib/platform_api` → ApiClient. Los providers observan `sessionScope`; los diálogos usan el mecanismo existente de descarte al cambiar sesión. No se cambian modelos base, Auth, rutas ni app. La única excepción autorizada a carpetas protegidas es `ApiClient.put(path, data)`, con los mismos interceptores de sesión/401 y errores que los demás métodos; pruebas para 400/401/403/404/409.

## Discrepancias resueltas por el owner

1. Usar backend `779fc78` y el suplemento: PATCH del maestro admite MEMBER; archivar campaña devuelve EmptySuccess; campañas no admite ordenar por email. Se conservan los comportamientos baseline correctos y se documenta la diferencia del arnés.
2. Múltiples candidatos CSV: el código `src/prospects/imports/prospect-imports.service.ts` excluye CONFLICT de las filas accionables y devuelve REJECTED. El owner aprobó conservar rechazo, corrección de archivo y nuevo preview, en lugar de ofrecer CREATE/SKIP para estas filas. No se introdujo alternativa en backend.

## Reproducción

```powershell
flutter pub get
dart run build_runner build
flutter analyze --no-pub
flutter test --no-pub
flutter build web --release --no-pub --no-wasm-dry-run --dart-define=API_BASE_URL=https://api.example.invalid
./tool/sprint-cp/Start-Lab.ps1 -BackendPath '<checkout backend de solo lectura>'
flutter test --no-pub tool/sprint-cp/t32_real_api_test.dart --dart-define=CP_REAL_API=true --reporter expanded
./tool/sprint-cp/Stop-Lab.ps1
```

El laboratorio exporta el SHA backend a una carpeta ignorada y construye una imagen local; no modifica el checkout backend. PostgreSQL16 usa tmpfs, sin acceso remoto ni puertos publicados. Sólo la API publica `127.0.0.1:18741`; onboarding está apagado. Los secretos sintéticos aleatorios permanecen en `.local/lab.env`, ignorado y nunca adjunto. Al apagar el proyecto se descartan sus datos sintéticos.

T32 utiliza widgets Flutter reales, repositorios reales, HTTP NestJS y PostgreSQL reales. El selector de archivos del sistema operativo recibe un CSV sintético explícito; el almacenamiento de token es sólo memoria de pruebas. No hay respuestas HTTP simuladas. El runner está separado de la suite estándar y exige `CP_REAL_API=true`. No equivale a una ejecución Chromium de los flujos CP ni certifica lectura por tecnologías asistivas.

Resultados y atribución por SHA: `evidencias/RESULTADOS.md` y `evidencias/T32.json`. No declarar PASS por pruebas pendientes ni sustituir UI→API real por mocks.

Los resultados originales se conservan. Para una corrida nueva, con el laboratorio activo, ejecutar también `node tool/sprint-cp/verify-contract.mjs`. T32 y el verificador escriben en `codex/frontend-cp/.local/recibos/`. Revisar los recibos antes de copiarlos a una carpeta de evidencias nueva. El [cierre CT-02](evidencias/CT02_CIERRE_20261125/RESULTADOS.md) y el [handoff CT-03](evidencias/CT03_RECONCILIACION.md) corresponden al ciclo posterior.
