# CT-06 · Cierre final frontend — resultados reproducibles

Fecha: 26/11/2026 · Rama: `fix/cierre-final-frontend` · Base: `f7a7511024fb9918f48faf5e3486514f5b45ff42`.

| Validación | SHA del frontend | Resultado |
|---|---|---|
| Análisis estático | `465b788911055587e8795ec24b0da6f30aaa048f` | `flutter analyze`: sin hallazgos. |
| Regresión Flutter (VM) | `465b788` | 345 aprobadas, 3 omitidas (2 exclusivas de Batch mode + 1 de navegador). |
| Batch mode (dart-define) | `465b788` | `dashboard_batch_mode_test.dart`: 2 aprobadas. |
| Build Web release con Batch | `465b788` | `flutter build web --release --dart-define=PROSPECTOR_BATCH_ENABLED=true`: PASS. Además se compiló el default (Batch apagado): PASS. |
| Navegador real, 3 roles | `465b788` | 3/3 casos PASS en 1440×960 y 390×844. [Recibo](CHROMIUM.json) |
| Laboratorio | backend `590aaf0dda98fd42befc4f3ed432d028d23d3946` + PostgreSQL 16 | Aislado en loopback, sin servicios remotos. |

## Entorno local

- Flutter 3.47.2 / Dart 3.13.2 (el CI fija 3.47.5 / 3.13.4).
- Chrome 158.0.8127.38 headless.
- `flutter pub get` conservó `pubspec.lock`; solo regeneró `GeneratedPluginRegistrant` de iOS/macOS, revertido por ser artefacto local.
- La prueba `flutter test --platform chrome test/adr006/web_history_test.dart` no completó en este equipo (se quedó sin salida y se detuvo). Queda NOT_RUN local; el CI del PR la ejecuta en Ubuntu.

## Recorrido verificado (laboratorio)

| Caso | Rol | Resultado | Evidencia |
|---|---|---|---|
| Login, selección de organización, dashboard, logout y URL protegida | OWNER | PASS | `desktop-owner-dashboard.png`, `mobile-owner-dashboard.png` |
| Métrica y accesos de prospección como Batch v1 | OWNER | PASS (con error 503 explícito y reintento porque el Service no forma parte del laboratorio) | `desktop-owner-dashboard.png` |
| Historial `/jobs` y detalle directo `/jobs/:id` | OWNER | PASS de navegación, estado de error y reintento; historial real no disponible sin Service | `desktop-owner-batches.png`, `desktop-owner-batch-not-found.png` |
| Formulario de lote, 1–5 consultas y límite 1–150 | OWNER | PASS de render y gating | `desktop-owner-generate.png`, `mobile-owner-generate.png` |
| Campañas, prospectos, pestañas y resumen comercial | OWNER | PASS | `desktop-owner-campaign-prospects.png`, `desktop-owner-campaign-summary.png` |
| Prospectos y ficha de listado | OWNER | PASS | `desktop-owner-prospects.png` |
| Sin CTA, métrica, panel ni accesos Batch; cero solicitudes batch | MEMBER | PASS | `desktop-member-dashboard.png`, `mobile-member-dashboard.png`, `mobile-member-drawer.png` |
| `/jobs`, `/generate` y `/prospects/new` por URL directa | MEMBER | PASS (denegación visible) | `desktop-member-batches-denied.png`, `desktop-member-generate-denied.png`, `desktop-member-create-denied.png` |
| Campañas accesibles | MEMBER | PASS | `desktop-member-campaigns.png` |
| Organizaciones, registro y usuarios | ADMIN | PASS | `desktop-admin-tenants.png`, `desktop-admin-register.png`, `desktop-admin-users.png` |

## Límites y bloqueos

1. **Generación/confirmación/exportación Batch en laboratorio: NOT_RUN.** El Service/Engine no forma parte del laboratorio; el backend responde 503 en los endpoints de lotes. La UI muestra el error explícito y permite reintentar, sin inventar estados. La generación productiva fue validada previamente por el equipo según el contexto del encargo.
2. **ACME 404: no reproducido.** No se dispone de datos ACME en el laboratorio sintético. Los fixtures nullable de usuarios siguen PASS; la causa histórica permanece no determinada sin una copia autorizada.
3. **Aceptación productiva: NOT_RUN.** Pendiente de Carlos (despliegue) y André (recorrido real).
4. La prueba exclusiva de Chrome no se ejecutó localmente; el CI es la verificación de esa primitiva.

## Reproducción

```powershell
# Laboratorio (backend fijado; requiere Docker)
tool/sprint-cp/Start-Lab.ps1 -BackendPath <backend-590aaf0> -BackendSha 590aaf0dda98fd42befc4f3ed432d028d23d3946
flutter build web --release --dart-define=API_BASE_URL=http://127.0.0.1:18741 --dart-define=PROSPECTOR_BATCH_ENABLED=true
npm install --prefix codex/frontend-cp/.local/browser --no-save --no-package-lock playwright-core@1.65.1
$env:CHROMIUM_EXECUTABLE='<chrome.exe>'; $env:CP_BUILD_SHA='HEAD'
node tool/cierre-final/browser-qa.mjs build/web codex/frontend-cp/evidencias/CT06_CIERRE_FINAL_20261126
tool/sprint-cp/Stop-Lab.ps1
```
