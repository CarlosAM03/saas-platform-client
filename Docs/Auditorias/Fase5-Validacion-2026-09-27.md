# Fase 5 — validación técnica del Flutter Foundation

Fecha: 2026-09-27. Checkout: `fix/f5-foundation`; baseline original `75b4e9498a7535988f0805609da2aa38d2c3d080`. Esta auditoría actualiza, sin borrar, la evidencia histórica del 19 de septiembre.

## Entorno y alcance

- SDK existente en `DocumentacionGlobal/.flutter-sdk`: Flutter 3.47.5 stable, Dart 3.13.4. Se usa el enlace `C:\f` al mismo SDK; no se reinstaló.
- Checkout en `PlataformaFlutter/saas-platform-client`; `C:\w` es enlace al mismo checkout. Windows tiene rutas largas deshabilitadas; `.dart_tool` es un junction a una caché generada de ruta corta. Tras `flutter clean` se recreó apuntando a un directorio vacío.
- `flutter doctor -v`: Web y Edge disponibles (Edge configurado mediante `CHROME_EXECUTABLE` como destino `chrome`), Visual Studio disponible; Android SDK ausente. Los avisos de PATH se deben a los alias de ruta corta. Chrome nativo no está instalado.
- Sin cambios de features, backend, permisos de negocio ni UI/UX. Dashboard, Admin, Campaigns, Prospects y ProspectingJobs siguen como placeholders.

## Regresión limpia

| Comando | Resultado | Evidencia / límite |
|---|---|---|
| `flutter clean` | PASS | Retiró build y `.dart_tool`; se recreó el junction a caché corta vacía. |
| `flutter pub get` | PASS | Dependencias resueltas sin upgrades mayores. |
| `dart run build_runner build --delete-conflicting-outputs` | PASS | Generó legítimamente `lib/shared/models/api_models.g.dart` (ignorado por Git). La versión actual avisa que ignora esa opción; también advierte sobre constraints antiguos de `json_annotation`/SDK, sin impedir la generación. |
| `flutter analyze` | PASS | `No issues found!` |
| `flutter test` | PASS | 16/16 tests; AuthState, red 401/403, routing, DTOs y excepciones. Storage unitario usa fake. |
| `flutter devices` | PASS Web | Windows, Chrome alias y Edge detectados. Android no disponible. |
| `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000` | PASS arranque | Edge abrió, conectó el debug service y registró `Starting application from main method`. No se certifica inspección visual de todas las pantallas. |
| `flutter build web --dart-define=API_BASE_URL=http://localhost:3000` | PASS | Compilación JS Web completada en la validación anterior de este mismo checkout; dry-run Wasm emitió aviso por `flutter_secure_storage_web`, sin afectar JS. |

## Auth y backend real

El backend NestJS local respondió en `http://localhost:3000`; no se modificó. Con las credenciales administrativas ya configuradas localmente, sin imprimirlas en el registro, se comprobó `POST /api/v1/auth/login` (200, JWT y contexto), `GET /api/v1/auth/me` (200, mismo usuario) y `POST /api/v1/auth/logout` (éxito). Login inválido y `/auth/me` sin token devolvieron 401. Una petición autenticada sin tenant a `/campaigns` devolvió 403. Esa cuenta tenía cero tenants accesibles, por lo que `POST /auth/select-tenant` no se pudo ensayar con datos reales; el flujo de selección y redirección tiene pruebas unitarias.

Los tests de Foundation demuestran: arranque sin token a login, restauración válida, 401 que limpia JWT e invalida AuthState global, backend no disponible, login exitoso/fallido, selección de tenant, logout local aun con fallo de red, Bearer y 403 que conserva la sesión. No sustituyen una prueba visual completa en navegador. El smoke visual de perfil y navegación base, así como la persistencia de `flutter_secure_storage` tras recarga real, siguen sin evidencia. Se intentó `flutter test --platform chrome` para write/read/delete de secure storage, pero el runner no logró completar la conexión con Edge; se interrumpió y no se incorporó una prueba no verificada.

## Estado y pendientes

- Configuración activa: `String.fromEnvironment('API_BASE_URL')` mediante `--dart-define`; `.env.example` es referencia, no carga automática. No se introdujo un segundo mecanismo Envied.
- Android requiere instalar/configurar Android SDK; no bloquea Web.
- Verificar manualmente en Edge la navegación completa, secure storage real (write/read/delete y restauración tras recarga) y select-tenant con una cuenta que tenga tenant. El backend local no aportó esa cuenta.
- Permisos MEMBER: **PENDIENTE DE RECONCILIACIÓN ANTES DE FEATURES FUNCIONALES**.

**Veredicto: F5 BASELINE PARTIALLY PASSED / BLOCKERS DOCUMENTED.** El foundation compila, arranca y pasa análisis y tests, pero las comprobaciones de navegador indicadas arriba no están demostradas y no se declara cierre total.
