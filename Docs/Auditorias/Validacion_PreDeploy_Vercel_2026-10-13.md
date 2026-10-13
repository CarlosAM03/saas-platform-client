# Validación predeploy Vercel — 2026-10-13

## Baseline y alcance

- Baseline: `ae4e4aa878cc4fe4593ec0ddf3e7c83980e3c08b`, `dev`, actualizado con `origin/dev`.
- Rama: `chore/vercel-production-container`, creada desde `origin/dev`.
- Único archivo previo sin tracking: `Docs/Planeacion/PlanDeployVercel.md`,
  especificación aportada por el usuario; se incluye sin alterar su contenido.
- Entorno: Windows, PowerShell, Docker Desktop Linux/amd64.
- Flutter `3.47.5`, Dart `3.13.4`. Gates del host desde el path corto
  existente `C:\w`; los Dockerfiles no dependen de ese path ni del SDK host.
- Backend, Render, Vercel, Supabase, OpenAPI y lógica Foundation sin cambios.

## Archivos

- `Dockerfile.vercel`: builder Linux con SDK/checksum fijados, generación y
  build release; runtime Nginx `1.28.0-alpine` con sólo artefactos Web.
- `docker/nginx.vercel.conf.template`: PORT runtime, SPA, headers y caché.
- `.dockerignore`: whitelist común para ambos builds y exclusiones de secretos.
- `.gitignore`: exclusión de `.vercel/`.
- `web/index.html`, `web/manifest.json`: identidad Prospector SaaS.
- `.github/workflows/ci.yml`: nuevo job `production-container`; conserva
  `foundation` y `container`, smoke con timeout y limpieza `always()`.
- `test/app_config_environment_test.dart`: lectura compile-time de API URL.
- `README.md`: sección breve de producción y enlace al plan operativo.
- Este informe y el plan del usuario.

## Gates ejecutadas

| Comando / comprobación | Evidencia / resultado |
| --- | --- |
| `flutter pub get` | PASS, exit 0 |
| `dart run build_runner build` | PASS, exit 0 |
| `flutter analyze` | PASS, No issues found |
| `flutter test` | PASS, 96 tests |
| `flutter test --no-pub test/app_config_environment_test.dart --dart-define=API_BASE_URL=https://api.example.invalid` | PASS, 1 test |
| `flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=https://api.example.invalid` | PASS, Built build/web |
| `docker compose config --quiet` | PASS |
| `docker compose build` | PASS |
| `docker compose up -d`; GET localhost:4200 | PASS, HTTP 200; luego compose down |
| `docker build -f Dockerfile.vercel --build-arg API_BASE_URL=https://api.example.invalid -t saas-platform-client:prod .` | PASS, exit 0 |
| `docker build -f Dockerfile.vercel -t saas-platform-client:missing-url .` | PASS negativo, exit 1: ERROR: API_BASE_URL is required and must use HTTPS |
| `docker run -d --name saas-predeploy-smoke -e PORT=8080 -p 8080:8080 saas-platform-client:prod` | PASS |
| GET localhost:8080/ y /dashboard | PASS, HTTP 200, HTML idéntico |
| `docker exec saas-predeploy-smoke nginx -t` | PASS, syntax ok |
| Runtime sin flutter/dart, /opt/flutter, /app ni Docs | PASS |
| YAML CI y JSON manifest parseados con dependencias existentes | PASS; tres jobs presentes |
| GitHub Actions remoto | NOT VERIFIED; se verificaron configuración y comandos locales |

Imagen final: `sha256:eec484481d26110b501e1ee41c4bc5b1d4044dd3aac0936cc84ea89ca7d38a2d`.
El catálogo oficial Flutter confirmó versión, Dart y SHA-256:
`2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb`.
La instrucción de descarga/verificación/extracción reutilizó su capa Docker
previamente validada; no se omitió la comprobación de checksum del Dockerfile.

Primera tentativa dev: FAIL porque Docker Desktop estaba detenido
(`dockerDesktopLinuxEngine: The system cannot find the file specified`).
Se ejecutó `docker desktop start` y el build posterior pasó.
Warnings preexistentes: analyzer language 3.12 frente a Dart 3.13,
constraints json_annotation/SDK y fuente CupertinoIcons; sin upgrades.

## Seguridad, caché y configuración

- Headers observados: nosniff, strict-origin-when-cross-origin, DENY,
  camera/microphone/geolocation bloqueados, HSTS max-age=31536000.
- HSTS supone terminación HTTPS productiva en Vercel. CSP diferida para
  evaluar scripts, CanvasKit y engine. No se agregó una CSP restrictiva.
- HTML, bootstrap y nombres estables revalidan. Sólo nombres con hash de
  al menos 16 caracteres hexadecimales admiten caché larga immutable.
- `String.fromEnvironment` se usa como const: API URL se fija durante
  compilación. El bundle contiene el endpoint dummy; el runtime no tiene
  una variable API_BASE_URL. Cambiar PORT sólo modifica el listener.
- Escaneo de archivos de esta tarea: no valores secretos introducidos.
  Nombres de variables en el plan son referencias documentales.
  El README del baseline ya contiene credenciales demo locales explícitamente
  públicas y sin uso productivo; se preservaron. README, Docs, test y tool
  quedan fuera del contexto Docker. No se copiaron esas credenciales a la imagen.
- Escaneo de Web/template en la imagen y `docker history
  saas-platform-client:prod --no-trunc`: PASS, sin coincidencias de URLs DB,
  asignaciones sensibles, claves Supabase/Prospector, passwords demo o tokens.
  Se inspeccionó también el environment final: variables base Nginx, PORT y
  filtro envsubst; no secretos ni tooling Flutter.
- Contenedor de smoke y servicio dev detenidos tras las comprobaciones.

## Vercel: configuración necesaria y pendientes externos

No se agregó `vercel.json`: la documentación oficial describe autodetección
de Dockerfile.vercel en raíz y routing al contenedor para un único servicio:
[Running Docker on Vercel](https://vercel.com/kb/guide/docker).
El builder oficial pasa el environment de build del proyecto como build args:
[implementación Vercel](https://github.com/vercel/vercel/blob/main/packages/container/src/index.ts).
Configurar únicamente API_BASE_URL para Preview/Production. Flujo:
`Vercel project build env → ARG API_BASE_URL → flutter --dart-define → bundle`.
No confiar sólo en una variable runtime ni asumir que `--build-env` de CLI
equivale a la configuración del proyecto; validar propagación en Preview.
El guard obligatorio impide una caída silenciosa a localhost.

Todos los siguientes puntos están **NOT VERIFIED / externos**, sin ejecutar:

1. Crear/conectar proyecto Vercel.
2. Configurar API_BASE_URL con el backend Render HTTPS.
3. Realizar Preview y confirmar propagación del argumento durante build.
4. Obtener dominio Vercel.
5. Agregar dominio a CORS_ORIGINS en Render.
6. Redeploy Render.
7. Smoke test Preview, incluyendo requests al backend y CORS.
8. Deploy Production.
9. Smoke test productivo.

## Veredicto

Preparación local de contenedor: PASS. READY FOR PR.
Deployment, HTTPS/CORS E2E y CI remoto siguen pendientes; este documento
no declara un deployment Vercel realizado ni un frontend productivo aprobado.
