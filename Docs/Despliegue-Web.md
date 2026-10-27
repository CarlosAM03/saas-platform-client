# Configuración Web y Vercel

## Origen de API y compilación

API_BASE_URL representa el origen de NestJS. PlatformApi añade /api/v1 y los recursos.
No incluir ese prefijo, rutas, query, fragmentos ni credenciales en la variable.
String.fromEnvironment lee --dart-define durante la compilación; Nginx no puede cambiar
la URL del bundle mediante una variable runtime. AppConfig valida la forma del origen.

- Local: http://localhost:3000; el navegador debe poder alcanzar ese puerto.
- CI: https://api.example.invalid, sólo marcador de compilación, nunca Backend para E2E.
- Publicado: HTTPS y dominio real verificado por el propietario.
- Dockerfile.vercel conserva el default público preexistente https://saas-platform-backend-l55n.onrender.com. Su health /api/v1/health/live respondió HTTP 200 durante esta auditoría; eso no certifica el SHA desplegado, CORS ni CSV.

```powershell
docker build -f Dockerfile.vercel --build-arg API_BASE_URL=https://api.tudominio.com -t saas-platform-client:prod .
```

El build productivo rechaza HTTP, origen vacío y valores con /api/v1 mediante
`tool/validate_api_origin.dart`. El default público no es una credencial y no debe
usarse para asumir que el Backend desplegado corresponde al commit MVP b6cd40f.

## Ajustes externos de Vercel pendientes del propietario

1. Confirmar qué flujo usa el proyecto: Dockerfile.vercel o compilación estática. El flujo observado históricamente no propagaba Project Environment automáticamente a Docker ARG; comprobar el log del build concreto.
2. Configurar API_BASE_URL por separado en Preview y Production. En Docker, pasar --build-arg; en compilación estática, usar flutter build web con --dart-define=API_BASE_URL. Reconstruir al cambiarlo.
3. Identificar el dominio exacto del Preview/Production y añadirlo en CORS_ORIGINS del Backend autorizado. El código inspeccionado usa una lista de orígenes separados por comas, sin activación automática por PR.
4. Configurar fallback de rutas al index.html y HTTPS en el hosting. Las plantillas Nginx versionadas conservan ese fallback y sus cabeceras.
5. Verificar con una cuenta de prueba autorizada login, selección de organización, campañas, prospectos, CSV y logout, comprobando el SHA del Backend desplegado y GET /prospecting-jobs/capabilities para creación. Un health HTTP 200 no sustituye estas pruebas.

No se cambió configuración Vercel, CORS, dominios ni secretos; tampoco se publicó un deployment.
No se proporcionó un dominio Preview concreto para comprobar su CORS en esta ejecución.

## Assets y contexto Docker

Ambos Dockerfiles copian assets/. La allow-list sólo admite Inter.ttf y OFL.txt dentro
de esa carpeta, además de las fuentes/lib/web y configuración necesarias. .env*, .git,
.vercel, claves, caches, tests, documentación y logs siguen fuera del contexto.
La etapa final está definida con Nginx y el bundle Web, sin Flutter/Dart ni fuentes de la app; la imagen no pudo validarse aquí por la indisponibilidad del motor Docker.

## Entorno Windows

Este workspace usa una junction .dart_tool preexistente para caches y una ruta larga.
Durante esta ejecución se usó un alias temporal Q: del workspace para evitar el límite
de rutas de Dart. No se reemplazó ni eliminó la junction. Flutter pub get inicialmente
falló por symlinks de plugins; tras resolver dependencias desde la ruta corta, se pudo
repetir satisfactoriamente. No se cambió Developer Mode ni la configuración global.
El alias C:\w existente sólo acorta el proyecto; ejecutar el SDK por su ruta larga
provocó errores de listado y de includes GLSL en impellerc. El build final pasó usando
también el SDK mediante Q:\.flutter-sdk. No se desactivaron shaders ni checks para resolverlo.

Docker Desktop estaba apagado. Se solicitó su inicio para intentar ambos builds; los
resultados efectivos, incluidos los reintentos, se registran en la auditoría.
