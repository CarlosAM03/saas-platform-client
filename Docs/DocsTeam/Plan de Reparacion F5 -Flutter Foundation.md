# Plan de Reparación F5 — Flutter Foundation

**Repositorio:** `CarlosAM03/saas-platform-client`  
**Baseline auditado:** `75b4e9498a7535988f0805609da2aa38d2c3d080`  
**Objetivo:** convertir el source foundation actual en un proyecto Flutter realmente ejecutable, probado y listo para desarrollo funcional por André.

---

## 1. Objetivo general

Cerrar los pendientes reales de Fase 5 sin ampliar alcance.

El resultado esperado debe ser:

```text
F5 CLOSED AS FLUTTER FOUNDATION
READY FOR FEATURE DEVELOPMENT
```

pero únicamente después de validar en un entorno Flutter real:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d chrome
```

La reparación debe concentrarse en:

- entorno Flutter/Dart;
- scaffold ejecutable;
- composición global;
- generación de código;
- configuración;
- Auth Foundation;
- routing;
- manejo global de sesión;
- cobertura mínima de tests;
- validación contra backend real.

No se implementarán features posteriores.

---

# 2. Alcance permitido

Se permite modificar únicamente lo necesario para estabilizar el foundation:

```text
lib/main.dart
lib/app/
lib/core/config/
lib/core/network/
lib/core/storage/
lib/core/errors/
lib/routes/
lib/features/auth/
lib/shared/models/
test/
pubspec.yaml
analysis_options.yaml
README/documentación F5
```

También se permite generar los directorios/plataformas Flutter requeridos:

```text
android/
web/
```

y cualquier archivo estándar producido por Flutter necesario para ejecutar el proyecto.

---

# 3. Fuera de alcance

No implementar durante esta reparación:

- Campaigns reales;
- Prospects reales;
- ProspectingJobs reales;
- Admin funcional;
- dashboard funcional;
- FastAPI;
- Prospector Service;
- Prospector Engine;
- scraping;
- polling real de Jobs;
- exportaciones;
- caché real de resultados;
- nuevas reglas de negocio;
- cambios de contratos;
- nuevas decisiones RBAC;
- rediseño UI/UX;
- deployment.

Los placeholders existentes pueden permanecer.

---

# 4. Fase 1 — Diagnóstico del entorno actual

## Objetivo

Determinar exactamente qué dejó instalado/configurado Codex anteriormente.

## Ejecutar

```bash
flutter --version
dart --version
flutter doctor -v
flutter devices
where flutter
where dart
```

En PowerShell puede utilizarse también:

```powershell
Get-Command flutter
Get-Command dart
```

## Verificar

- Flutter SDK instalado;
- Dart disponible a través del SDK;
- PATH correcto;
- Chrome detectado;
- Android toolchain disponible o no;
- VS Code detectado;
- versión real utilizada.

## Regla

No reinstalar Flutter si la instalación existente puede repararse.

No actualizar de versión sin necesidad.

## Criterio de salida

Debe funcionar al menos:

```bash
flutter --version
flutter doctor
flutter devices
```

y Chrome debe estar disponible como target para la validación web.

---

# 5. Fase 2 — Verificar Git antes de tocar el proyecto

## Objetivo

No perder cambios locales que no estén todavía en GitHub.

## Ejecutar

```bash
git status
git branch --show-current
git log --oneline --decorate -10
git diff
```

Comparar con el baseline auditado:

```text
75b4e9498a7535988f0805609da2aa38d2c3d080
```

## Si existen cambios locales

Clasificarlos antes de modificar:

- instalación/scaffold generado;
- trabajo de Andrés;
- trabajo previo de Codex;
- archivos generados;
- cambios manuales.

No descartar nada automáticamente.

## Criterio de salida

Estado inicial documentado y trabajo local preservado.

---

# 6. Fase 3 — Completar el scaffold Flutter

## Hallazgo que resuelve

El repositorio versionado no contiene actualmente plataformas Flutter ejecutables como:

```text
web/
android/
```

aunque el propio Plan F5 exigía inicialización del proyecto.

## Acción

Desde la raíz del repositorio ejecutar:

```bash
flutter create --platforms=android,web .
```

## Restricciones

No permitir que `flutter create` sobrescriba deliberadamente la arquitectura existente en `lib/`.

Después del comando revisar:

```bash
git status
git diff
```

Los cambios esperados deben corresponder principalmente a:

- `android/`;
- `web/`;
- archivos estándar Flutter;
- posibles ajustes mínimos de configuración.

Si Flutter modifica archivos existentes importantes, revisarlos antes de aceptar.

## Criterio de salida

El repositorio debe ser reconocido como proyecto Flutter válido y soportar:

```bash
flutter devices
```

con target web.

---

# 7. Fase 4 — Restaurar dependencias

Ejecutar:

```bash
flutter clean
flutter pub get
```

## No hacer

No ejecutar:

```bash
flutter pub upgrade --major-versions
```

salvo incompatibilidad real demostrada.

## Validar

- Dart SDK compatible con `>=3.3.0 <4.0.0`;
- Dio;
- Riverpod;
- go_router;
- flutter_secure_storage;
- json_serializable;
- build_runner;
- demás dependencias.

## Criterio de salida

```text
flutter pub get → PASS
```

---

# 8. Fase 5 — Corregir composición global Riverpod

## Hallazgo

`SaasPlatformApp` es `ConsumerWidget`, pero `main.dart` no crea un `ProviderScope`.

El foundation no puede considerarse válido sin el scope global de Riverpod.

## Corrección

El root debe quedar conceptualmente como:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: SaasPlatformApp(),
    ),
  );
}
```

Agregar el import correspondiente:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

## Regla

Solo debe existir un `ProviderScope` raíz salvo necesidad explícita de scopes anidados.

## Criterio de salida

La aplicación puede resolver:

```text
appRouterProvider
authControllerProvider
apiClientProvider
```

sin `ProviderScope` runtime exceptions.

---

# 9. Fase 6 — Generar código de json_serializable

## Hallazgo

Existe:

```dart
part 'api_models.g.dart';
```

pero los `*.g.dart` están ignorados por Git y nunca se generaron en el baseline auditado.

## Ejecutar

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Revisar

Que se genere correctamente:

```text
lib/shared/models/api_models.g.dart
```

y cualquier otro archivo generado necesario.

## Importante

Los modelos actuales tienen una combinación de:

- clases con `@JsonSerializable`;
- algunos `fromJson` manuales;
- clases sin `factory fromJson`.

Si `build_runner` reporta inconsistencias, corregir únicamente lo necesario para que la estrategia sea coherente.

No rediseñar todos los DTOs si no hace falta.

## Criterio de salida

```text
build_runner → PASS
```

---

# 10. Fase 7 — Ejecutar análisis estático

Ejecutar:

```bash
flutter analyze
```

Clasificar resultados:

## P0 — errores

Todo error que impida compilación debe corregirse.

## P1 — warnings estructurales del foundation

Corregir si afectan:

- Auth;
- routing;
- Riverpod;
- null safety;
- generación;
- API client.

## P2 — lint/estilo

Solo corregir si es rápido y seguro.

No convertir la reparación en una refactorización estética.

## Criterio de salida

Preferido:

```text
No issues found
```

Mínimo:

```text
0 errores
```

y warnings restantes documentados.

---

# 11. Fase 8 — Resolver estrategia de configuración

## Hallazgo

La documentación declara `envied`, pero `AppConfig` utiliza:

```dart
String.fromEnvironment('API_BASE_URL')
```

mientras `.env.example` no es leído automáticamente.

## Objetivo

Dejar una sola estrategia reproducible para ejecutar localmente.

## Criterio conservador

No cambiar arquitectura innecesariamente.

Si `String.fromEnvironment` funciona correctamente, puede mantenerse durante F5 y documentarse explícitamente.

La ejecución sería:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

En ese caso:

- documentar que `.env.example` es referencia;
- dejar de afirmar que `.env` se carga automáticamente;
- no exigir Envied todavía.

Alternativamente, si la documentación normativa obliga inequívocamente a Envied y su integración resulta trivial, puede completarse.

## Regla

No mantener simultáneamente dos estrategias ambiguas.

## Criterio de salida

Debe existir un comando reproducible para cambiar la URL del backend sin editar código.

---

# 12. Fase 9 — Primer arranque web

Ejecutar:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

o la URL correspondiente.

## Objetivo inicial

Todavía no probar backend.

Primero confirmar:

- compilación;
- apertura de Chrome;
- render inicial;
- ausencia de red screen provocada por infraestructura.

## Si falla

Capturar:

- excepción completa;
- stack trace;
- archivo;
- línea;
- condición causante.

Corregir causa raíz.

## Criterio de salida

La aplicación abre correctamente.

---

# 13. Fase 10 — Revisar lifecycle de AuthState

## Área crítica

`AuthController.build()` ejecuta:

```dart
Future<void>.microtask(restoreSession);
```

Debe probarse realmente.

## Casos

### Sin token

Resultado:

```text
unauthenticated
→ /login
```

### Token válido

Resultado:

```text
/auth/me
→ authenticated
```

### Token inválido/expirado

Resultado:

```text
401
→ token eliminado
→ sessionExpired/login
```

### Backend no disponible

Resultado:

```text
backendUnavailable
```

## Objetivo

Confirmar que no existen:

- loops de rebuild;
- llamadas repetidas a `/auth/me`;
- race conditions básicas;
- estado `loading` permanente.

---

# 14. Fase 11 — Corregir manejo global de 401

## Hallazgo

`ApiClient` limpia el token ante 401:

```text
401 → clearToken()
```

pero no actualiza automáticamente `AuthState`.

Eso dejaría una futura feature viendo al usuario como authenticated después de perder la sesión.

## Objetivo

Establecer una única vía transversal:

```text
HTTP 401
→ limpiar token
→ invalidar sesión
→ AuthState no autenticado/sessionExpired
→ routing correspondiente
```

## Restricción

No acoplar `ApiClient` directamente a widgets.

Debe mantenerse la separación:

```text
network
→ mecanismo de sesión
→ AuthController
→ router
```

La solución debe ser simple y testeable.

## Criterio de salida

Un 401 ocurrido fuera de `/auth/me` también invalida correctamente la sesión global.

---

# 15. Fase 12 — Validar comportamiento 403

## Objetivo

Confirmar:

```text
403
→ NO elimina token
→ NO destruye sesión
→ ApiException.forbidden
```

Después las features podrán decidir cómo mostrarlo.

## Criterio de salida

AuthState sigue autenticado tras un 403.

---

# 16. Fase 13 — Levantar backend baseline

Utilizar un backend NestJS conocido y funcional.

No depender del hardening final de Ángel todavía.

Verificar previamente:

```text
health
PostgreSQL
seed
Auth
```

## Confirmar

Flutter usa exactamente el contrato ya compartido.

Ya se verificó documentalmente que el OpenAPI copiado en ambos repos coincide.

---

# 17. Fase 14 — Validación real del login

Probar:

### Credenciales válidas

```text
Login
→ POST /api/v1/auth/login
→ wrapper success/data
→ AuthContext
→ token en secure storage
→ navegación
```

### Credenciales inválidas

```text
401
→ mensaje controlado
→ permanecer en Login
```

### Backend apagado

```text
network error
→ backendUnavailable
```

## Revisar

Que no se imprima JWT.

---

# 18. Fase 15 — Validar selección de tenant

## Caso usuario con múltiples tenants

Debe poder:

```text
Login
→ SelectTenant
→ POST /auth/select-tenant
→ reemplazar JWT
→ reemplazar AuthContext
→ Dashboard
```

## Hallazgo a verificar

La implementación actual no contiene una redirección explícita:

```text
/select-tenant → /dashboard
```

después de la selección.

Debe probarse en runtime.

Si no ocurre correctamente, corregir routing para que una selección exitosa termine en Dashboard.

## Criterio de salida

No quedarse atrapado en `/select-tenant`.

---

# 19. Fase 16 — Validar ADMIN sin tenant

El baseline permite:

```text
platformRole = ADMIN
currentTenantId = null
```

## Probar

Login ADMIN sin tenant.

Debe poder existir la sesión.

No debe acceder automáticamente a rutas tenant-aware.

Si intenta:

```text
/campaigns
/prospects
/generate
```

debe enviarse a Select Tenant.

## Criterio de salida

ADMIN sin tenant es un estado válido y estable.

---

# 20. Fase 17 — Validar restauración de sesión

Cerrar/reiniciar la aplicación manteniendo token.

Esperado:

```text
Splash
→ readToken
→ GET /auth/me
→ AuthContext
→ ruta adecuada
```

Probar también token inválido.

## Criterio de salida

La app no exige login innecesariamente con sesión válida.

---

# 21. Fase 18 — Validar logout

Esperado:

```text
POST /auth/logout
→ clearToken()
→ AuthState unauthenticated
→ /login
```

Incluso si el request remoto falla, el estado local debe limpiarse conforme al comportamiento actual previsto.

## Criterio de salida

No queda acceso a rutas autenticadas.

---

# 22. Fase 19 — Revisar Secure Storage en Web

## Motivo

El target inmediato de validación es Chrome.

`flutter_secure_storage` tiene particularidades por plataforma.

## Acción

Validar realmente:

- escritura;
- lectura;
- eliminación;
- persistencia durante refresh/reinicio razonable.

No cambiar a localStorage como workaround.

El ADR F5 prohíbe almacenar JWT en localStorage.

## Criterio de salida

JWT usable en target web manteniendo la abstracción existente.

---

# 23. Fase 20 — Completar tests mínimos de F5

Actualmente existen solo dos tests.

Agregar pruebas suficientes para cerrar lo ya exigido documentalmente.

## Obligatorias

### AuthState

- sin token;
- restore success;
- restore 401;
- backend unavailable;
- login success;
- login failure;
- select tenant;
- logout.

### ApiClient/session

- Bearer cuando existe token;
- 401 invalida sesión;
- 403 conserva sesión.

### Router

- unknown/loading → splash;
- unauthenticated → login;
- authenticated sin tenant → select tenant;
- authenticated con tenant → dashboard;
- ADMIN sin tenant y ruta tenant-aware → select tenant;
- sessionExpired;
- backendUnavailable.

### Storage

Usar fake/mock.

No utilizar secure storage real en unit tests.

## Criterio de salida

```bash
flutter test
```

completamente verde.

---

# 24. Fase 21 — No tocar las features placeholder

Mantener:

```text
Campaigns
Prospects
ProspectingJobs
Admin
Dashboard
```

como están salvo cambios mínimos requeridos para compilación/navegación.

No conectar API real todavía.

Eso corresponde a Andrés.

---

# 25. Fase 22 — Regresión completa

Ejecutar desde estado limpio:

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

## Smoke test manual

1. abre aplicación;
2. login inválido;
3. login válido;
4. selección tenant si aplica;
5. dashboard;
6. profile;
7. logout;
8. restauración de sesión;
9. backend apagado;
10. 401;
11. 403 si existe caso reproducible.

---

# 26. Fase 23 — Documentación mínima

Actualizar únicamente documentación afectada por hallazgos reales.

Debe quedar claro:

- versión Flutter/Dart probada;
- cómo ejecutar Web;
- cómo definir `API_BASE_URL`;
- si se usa `dart-define` o Envied;
- build_runner obligatorio;
- targets iniciales;
- estado de Auth Foundation;
- placeholders aún no implementados;
- tests disponibles.

No declarar Campaigns/Prospects/Jobs como funcionales.

---

# 27. Fase 24 — Commit de baseline reparado

El commit debe contener únicamente la estabilización F5.

Nombre sugerido:

```text
fix: close executable Flutter Foundation baseline
```

o:

```text
fix(flutter): stabilize F5 foundation execution
```

Registrar SHA final.

---

# 28. Criterios de aceptación final

F5 podrá declararse cerrada solo si se cumplen todos:

### Entorno

- Flutter disponible.
- Dart disponible.
- Chrome reconocido.

### Proyecto

- scaffold Android/Web generado.
- dependencias resueltas.
- ProviderScope configurado.
- build_runner funcional.
- proyecto compila.

### Calidad

- `flutter analyze` sin errores.
- `flutter test` verde.

### Runtime

- `flutter run -d chrome` funciona.
- sin pantallazo rojo.

### Auth real

- login.
- auth/me.
- select-tenant.
- logout.
- JWT storage.
- restore session.
- 401 global.
- 403 conserva sesión.
- backend unavailable.

### Routing

- login.
- splash.
- select tenant.
- dashboard.
- ADMIN sin tenant.
- session expired.

### Arquitectura

- Dio solo en core/network.
- ningún HTTP directo desde UI.
- ningún cambio de contrato.
- ningún acceso a FastAPI.
- ninguna feature posterior implementada.

### Git

- commit estable;
- working tree limpio;
- baseline listo para handoff.

---

# 29. Resultado del trabajo

Al terminar debe existir una línea reproducible:

```text
F5 Flutter Foundation
        ↓
ejecutable
        ↓
Auth validado contra NestJS
        ↓
routing estable
        ↓
tests verdes
        ↓
commit limpio
        ↓
READY FOR ANDRÉ FEATURE DEVELOPMENT
```

Ese commit se convierte en la única base desde la cual Andrés deberá implementar las features siguientes.

---

# 30. Pendientes que deliberadamente NO resuelve esta reparación

Después de cerrar F5 quedarán para el plan de Andrés:

- Campaigns real;
- Prospects real;
- integración de repositories API;
- providers y estados por feature;
- formularios;
- CRUD visual;
- manejo de paginación;
- alineación RBAC visual;
- Admin según alcance;
- mejora de Profile;
- UI/UX;
- tests de features.

ProspectingJobs deberá permanecer limitado hasta que el backend hardening de Ángel y posteriormente Prospector Service definan el siguiente corte funcional.

También queda pendiente reconciliar la diferencia documental actual sobre permisos de `MEMBER` entre Flutter F5 y el backend antes de implementar controles visuales definitivos de esas features.

---

## Veredicto esperado

Al terminar esta reparación:

```text
F5 BASELINE PASSED
EXECUTABLE AND TESTED
READY FOR FEATURE DEVELOPMENT
```

Solo entonces debe generarse el plan de implementación de André.