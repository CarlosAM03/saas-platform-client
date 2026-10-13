Sí. Para tu caso diseñaría el despliegue como **un bloque específico de predeploy + un bloque de deployment**, manteniendo `Dockerfile.dev` para desarrollo local y creando un **`Dockerfile.vercel` productivo** separado.

Vercel ya puede construir y ejecutar un `Dockerfile.vercel` como contenedor OCI sobre Vercel Functions/Fluid Compute; el requisito clave es que el servidor HTTP escuche en `$PORT` —por defecto 80— y no en un puerto fijo como el `4200` que hoy usa tu Nginx local. [Vercel](https://vercel.com/blog/dockerfile-on-vercel?utm_source=chatgpt.com)

## Objetivo final

La arquitectura productiva quedaría:

```text
Usuario
   ↓ HTTPS
Vercel
Flutter Web dentro de contenedor Nginx
   ↓ HTTPS REST/JWT
Render
NestJS Backend
   ↓
Supabase PostgreSQL producción
```

Y conservaríamos:

```text
Dockerfile.dev + compose.yaml
→ desarrollo local

Dockerfile.vercel
→ producción Vercel
```

No usaríamos `compose.yaml` en Vercel, porque Vercel no despliega Docker Compose directamente; despliega contenedores individuales. [Vercel](https://vercel.com/i/can-you-run-docker-compose-on-vercel?utm_source=chatgpt.com)

---

# Plan de implementación

## Bloque 0 — prerrequisitos

Antes de tocar código necesitamos tener identificados:

```text
BACKEND_PRODUCTION_URL=https://<backend-render>.onrender.com
```

y después, cuando Vercel nos entregue dominio:

```text
FRONTEND_PRODUCTION_URL=https://<proyecto>.vercel.app
```

No necesitamos en frontend:

```text
DATABASE_URL
JWT_SECRET
SUPABASE_PASSWORD
ADMIN_PASSWORD
DEV_SEED_PASSWORD
```

De hecho, **ninguno de esos valores debe entrar al build Flutter**.

En una aplicación Web cualquier valor compilado dentro del bundle puede ser inspeccionado por el navegador. La única configuración que debe llegar al frontend es:

```text
API_BASE_URL
```

que es pública por naturaleza.

---

# Bloque 1 — hardening predeploy

Antes de crear el deployment, haría un commit dedicado:

```text
chore: harden Flutter web production container
```

### 1. Crear `Dockerfile.vercel`

No modificaría `Dockerfile.dev`.

El nuevo Dockerfile tendría dos stages:

```text
Flutter builder
↓
Nginx production runtime
```

El builder debe conservar lo bueno que ya tenemos:

```text
Flutter 3.47.5 fijo
checksum SHA-256 del SDK
pubspec.lock
flutter pub get
build_runner
flutter build web --release
API_BASE_URL mediante --dart-define
```

Conceptualmente:

```dockerfile
FROM debian:bookworm-slim AS flutter-build

ARG FLUTTER_VERSION=3.47.5
ARG FLUTTER_SHA256=2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb
ARG API_BASE_URL

RUN test -n "$API_BASE_URL"

# instalar únicamente herramientas de build
# descargar Flutter
# verificar checksum
# flutter pub get
# build_runner
# flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginx:1.28.0-alpine

COPY ...
```

El `RUN test -n "$API_BASE_URL"` es importante.

Así evitamos producir accidentalmente un build productivo que termine apuntando a:

```text
http://localhost:3000
```

---

## 2. Quitar el fallback localhost en producción

Hoy `AppConfig` tiene:

```dart
defaultValue: 'http://localhost:3000'
```

Eso está bien para desarrollo.

Pero el **production build** debe fallar si no recibe `API_BASE_URL`.

No necesariamente tenemos que modificar `AppConfig`; podemos imponer la validación desde `Dockerfile.vercel`.

Eso mantiene:

```text
dev → localhost funciona
prod → API_BASE_URL obligatorio
```

---

# Bloque 2 — Nginx productivo para Vercel

Tu Nginx actual tiene:

```nginx
listen 4200;
```

Eso **no debe usarse tal cual en Vercel**.

Vercel exige que el servidor escuche en `$PORT`; el puerto por defecto es 80 y puede configurarse en Project Settings. [Vercel](https://vercel.com/i/can-you-run-docker-compose-on-vercel?utm_source=chatgpt.com)

Crearía:

```text
docker/nginx.vercel.conf.template
```

con algo parecido a:

```nginx
server {
    listen ${PORT};
    listen [::]:${PORT};

    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    server_tokens off;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

El fallback a `index.html` es correcto para mantener la SPA preparada incluso si después migramos a clean URLs.

El entrypoint debe sustituir `${PORT}` al arrancar.

La imagen oficial de Nginx puede procesar templates vía `envsubst`, por lo que podemos aprovechar `/etc/nginx/templates`.

Por ejemplo:

```text
/etc/nginx/templates/default.conf.template
```

y:

```text
NGINX_ENVSUBST_TEMPLATE_SUFFIX=.template
```

---

# Bloque 3 — security headers

Al Nginx productivo le agregaría:

```nginx
server_tokens off;

add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header X-Frame-Options "DENY" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
```

Y HSTS:

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

pero sólo en producción HTTPS, que Vercel sí proporciona.

No pondría una CSP estricta todavía.

Flutter Web puede requerir ajustes específicos para scripts, WASM/CanvasKit o recursos del engine. Una CSP incorrecta puede romper la aplicación aunque el build sea válido.

Primero deployment estable; CSP después mediante auditoría de DevTools.

---

# Bloque 4 — caché correcta

Ahora el Nginx dev envía:

```text
Cache-Control: no-store
```

a todo.

Eso es útil para desarrollo pero malo para producción.

Para producción propondría:

```nginx
location = /index.html {
    add_header Cache-Control "no-cache";
}

location = /flutter_bootstrap.js {
    add_header Cache-Control "no-cache";
}

location /assets/ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

y fallback normal para la SPA.

La idea es:

```text
HTML/bootstrap
→ revalidar

assets versionados/hash
→ cache largo
```

---

# Bloque 5 — minimizar superficie de la imagen

`.dockerignore` ya está bastante bien.

Para producción revisaría que el contexto permita únicamente:

```text
pubspec.yaml
pubspec.lock
analysis_options.yaml
lib/**
web/**
```

y lo estrictamente necesario para compilar.

No deben entrar:

```text
.env
.env.local
Docs/
test/
tool/
.git/
build/
.dart_tool/
credenciales
archivos personales
```

Al runtime final sólo deben llegar:

```text
build/web
nginx config
```

Nada del source Flutter.

---

# Bloque 6 — comprobar que no haya secretos

Antes del build:

```powershell
git grep -n -E "DATABASE_URL|JWT_SECRET|SUPABASE|ADMIN_PASSWORD|DEV_SEED_PASSWORD"
```

La aparición de **nombres** en documentación puede ser válida.

Lo que no debe aparecer son valores productivos.

También:

```powershell
git status
```

y confirmar que:

```text
.env
.vercel
credenciales
```

no están trackeados.

Después de construir la imagen:

```powershell
docker history saas-platform-client:prod --no-trunc
```

y revisar que no aparezcan secretos en las capas.

En este caso:

```text
API_BASE_URL=https://...
```

sí puede aparecer porque no es secreto.

---

# Bloque 7 — build productivo local

Antes de Vercel debemos demostrar que la imagen productiva funciona localmente.

Build:

```powershell
docker build `
  -f Dockerfile.vercel `
  --build-arg API_BASE_URL=https://TU-BACKEND-RENDER.onrender.com `
  -t saas-platform-client:prod .
```

Luego ejecutar simulando el contrato de Vercel:

```powershell
docker run --rm `
  -e PORT=8080 `
  -p 8080:8080 `
  saas-platform-client:prod
```

Validar:

```powershell
Invoke-WebRequest http://localhost:8080 -UseBasicParsing
```

Debe regresar:

```text
200
```

Después abrir:

```text
http://localhost:8080
```

---

# Bloque 8 — smoke test contra backend productivo

Antes de Vercel:

```text
Flutter container local
        ↓
Render production backend
```

Probar:

```text
login
auth/me
logout
tenant select
dashboard
refresh browser
```

En DevTools:

```text
Network
```

confirmar que todas las llamadas van a:

```text
https://<backend>.onrender.com
```

y nunca a:

```text
localhost
Supabase
PostgreSQL
```

---

# Bloque 9 — CORS del backend

Aquí debemos tener cuidado con el orden.

Primero podemos hacer Preview en Vercel.

Después de conocer la URL productiva final:

```text
https://<frontend>.vercel.app
```

en Render configurar:

```text
CORS_ORIGINS=https://<frontend>.vercel.app
```

Si quieres conservar desarrollo local:

```text
CORS_ORIGINS=https://<frontend>.vercel.app,http://localhost:4200
```

Luego:

```text
Redeploy Render
```

y comprobar un preflight/request real.

No introduciría `*`.

Tienes JWT Bearer y una aplicación autenticada; mantener allowlist explícita es mejor.

---

# Bloque 10 — preparación de Vercel

Instalar CLI:

```powershell
npm install -g vercel
```

Comprobar:

```powershell
vercel --version
```

Autenticarse:

```powershell
vercel login
```

Desde la raíz:

```powershell
vercel link
```

Seleccionar:

```text
CarlosAM03
saas-platform-client
```

o crear un proyecto nuevo.

Vercel registra la asociación local en `.vercel/`; esa metadata no debe versionarse. [Vercel](https://vercel.com/academy/build-and-launch-with-ai/use-vercel-cli?utm_source=chatgpt.com)

Añadir:

```text
.vercel/
```

a `.gitignore` si todavía no está.

---

# Bloque 11 — configurar variables Vercel

La única variable requerida por el frontend debería ser:

```text
API_BASE_URL
```

Production:

```powershell
vercel env add API_BASE_URL production
```

Valor:

```text
https://<backend-render>.onrender.com
```

Vercel permite variables distintas para Production, Preview y Development. [Vercel](https://vercel.com/academy/vercel-foundations/vercel-settings?utm_source=chatgpt.com)

No agregar:

```text
DATABASE_URL
JWT_SECRET
POSTGRES_PASSWORD
SUPABASE_PASSWORD
ADMIN_PASSWORD
```

al proyecto frontend.

Ni siquiera como "Sensitive".

El frontend no necesita conocerlas.

---

# Problema importante: build arg vs runtime env

Aquí debemos diseñar con cuidado.

`API_BASE_URL` es utilizada por:

```dart
String.fromEnvironment()
```

por lo que debe existir **durante `flutter build web`**, no sólo cuando arranca Nginx.

Los argumentos de Docker y las variables runtime son mecanismos distintos; Vercel también advierte que los build args no pasan mágicamente a runtime. [Vercel](https://vercel.com/i/docker-works-locally-fails-in-production?utm_source=chatgpt.com)

Nuestro requisito es:

```text
Vercel environment
      ↓
Docker build ARG API_BASE_URL
      ↓
flutter build --dart-define
```

Por eso esta parte debe validarse durante el primer Preview.

Si la integración directa de Vercel no expone `API_BASE_URL` automáticamente como Docker `ARG`, tenemos dos opciones seguras:

```text
A. Dockerfile.vercel consume env disponible durante build.

B. vercel.json/build configuration pasa explícitamente el valor
   al proceso de compilación.
```

No asumiría que funciona hasta verificarlo en logs.

---

# Bloque 12 — primer Preview deployment

No ir directo a producción.

Primero:

```powershell
vercel deploy
```

Vercel debería detectar:

```text
Dockerfile.vercel
```

construir la imagen, subirla al Vercel Container Registry y crear una Preview URL. Ese es el flujo documentado actualmente. [Vercel](https://vercel.com/blog/dockerfile-on-vercel?utm_source=chatgpt.com)

Guardar:

```text
Preview URL
Deployment ID
Image/build logs
```

---

# Bloque 13 — auditar logs del build

En Vercel comprobar:

```text
Flutter 3.47.5
checksum OK
flutter pub get OK
build_runner OK
flutter build web --release OK
Nginx runtime built
container started
PORT correcto
```

No deben imprimirse:

```text
JWT
DB URL
passwords
Supabase credentials
tokens
```

La URL pública del backend puede aparecer.

---

# Bloque 14 — smoke test Preview

Probar:

```text
/
login
refresh
logout
invalid credentials
session restore
backend error screen
responsive mobile
responsive desktop
```

DevTools:

```text
Console:
0 errores críticos

Network:
HTTPS únicamente
sin mixed content
sin localhost
sin CORS errors
```

---

# Bloque 15 — producción

Cuando Preview esté aprobado:

```powershell
vercel deploy --prod
```

Vercel documenta `vercel deploy --prod` para enviar directamente el deployment productivo. [Vercel](https://vercel.com/academy/python-on-vercel/deploy-to-prod?utm_source=chatgpt.com)

El resultado será algo tipo:

```text
Production:
https://saas-platform-client.vercel.app
```

---

# Bloque 16 — CORS definitivo

Con esa URL exacta:

Render:

```text
CORS_ORIGINS=https://saas-platform-client.vercel.app,http://localhost:4200
```

Redeploy backend.

Después:

```text
Vercel Flutter
↓
Render NestJS
↓
Supabase
```

hacer login real.

---

# Bloque 17 — pruebas productivas

Checklist de aceptación:

```text
[ ] HTTPS válido
[ ] / carga
[ ] assets cargan
[ ] favicon/manifest cargan
[ ] login OWNER funciona
[ ] login ADMIN funciona
[ ] select tenant funciona
[ ] refresh conserva sesión
[ ] logout limpia sesión
[ ] 401 lleva a session-expired
[ ] 403 conserva sesión
[ ] backend unavailable funciona
[ ] no CORS errors
[ ] no mixed content
[ ] ninguna request a localhost
[ ] ninguna request directa a Supabase
[ ] API apunta exclusivamente a Render
[ ] responsive mobile
[ ] responsive desktop
```

---

# Bloque 18 — security inspection

Después del deployment:

Browser DevTools → Application.

Verificar que el JWT no esté en:

```text
Local Storage
Session Storage
cookies no previstas
```

La aplicación usa `flutter_secure_storage`, por lo que revisaremos el mecanismo Web real que resulte de ese paquete.

También inspeccionar:

```text
Sources
```

y buscar:

```text
DATABASE_URL
JWT_SECRET
postgresql://
supabase password
```

No deberían existir.

`API_BASE_URL` sí existirá y es correcto.

---

# Bloque 19 — rollback

Una ventaja de Vercel container deployments es que cada commit genera un deployment inmutable y Vercel mantiene previews/deployments. [Vercel](https://vercel.com/blog/dockerfile-on-vercel?utm_source=chatgpt.com)

Nuestro rollback debe ser:

```text
Vercel Dashboard
→ Deployments
→ deployment anterior aprobado
→ Promote/Redeploy
```

No modificar producción manualmente dentro del contenedor.

---

# Bloque 20 — CI

Después de demostrar que funciona, ampliaría GitHub Actions.

Actualmente tienes:

```text
foundation
container
```

Agregaría:

```text
production-container
```

que ejecute:

```powershell
docker build `
  -f Dockerfile.vercel `
  --build-arg API_BASE_URL=https://api.example.invalid `
  -t saas-platform-client:prod .
```

y opcionalmente:

```text
docker run
curl /
```

Esto evitaría que un PR rompa específicamente la imagen que Vercel usa.

Entonces `main` debería requerir:

```text
foundation
container
production-container
```

antes de merge.

---

# Estructura final esperada del repo

```text
saas-platform-client/
│
├── Dockerfile.dev
├── Dockerfile.vercel
├── compose.yaml
│
├── docker/
│   ├── nginx.conf
│   └── nginx.vercel.conf.template
│
├── lib/
├── web/
│
├── .dockerignore
├── .gitignore
└── .github/
    └── workflows/
        └── ci.yml
```

---

# Qué conservar y qué separar

No reutilizaría directamente el Nginx dev.

Quedaría:

```text
DEV
Dockerfile.dev
docker/nginx.conf
PORT 4200
API localhost

PRODUCTION
Dockerfile.vercel
docker/nginx.vercel.conf.template
PORT dinámico Vercel
API Render
security headers
production caching
```

La lógica Flutter sigue siendo exactamente la misma.

---

# Qué jamás debe estar en el contenedor frontend

Ésta sería una regla explícita del predeploy:

```text
PROHIBIDO
────────────────────────────
DATABASE_URL
POSTGRES_USER productivo
POSTGRES_PASSWORD productivo
JWT_SECRET
Supabase service key
Supabase DB password
ADMIN_PASSWORD productivo
PROSPECTOR_API_KEY
Render secrets
GitHub tokens
Vercel tokens
.env productivo
```

El frontend sólo necesita:

```text
API_BASE_URL
```

El resto pertenece al backend.

---

# Secuencia Git que usaría

No haría cambios directamente sobre `main`.

```powershell
git switch dev
git pull origin dev

git switch -c chore/vercel-production-container
```

Implementación.

Luego:

```powershell
flutter analyze
flutter test
flutter build web --release --dart-define=API_BASE_URL=https://api.example.invalid
```

Build container:

```powershell
docker build `
  -f Dockerfile.vercel `
  --build-arg API_BASE_URL=https://api.example.invalid `
  -t saas-platform-client:prod .
```

Runtime:

```powershell
docker run --rm `
  -e PORT=8080 `
  -p 8080:8080 `
  saas-platform-client:prod
```

Después commit:

```powershell
git add .
git commit -m "chore: harden Vercel production container"
git push -u origin chore/vercel-production-container
```

PR:

```text
chore/vercel-production-container
→ dev
```

CI verde.

Luego:

```text
dev
→ main
```

y sólo entonces conectar deployment productivo a `main`.

---

## Orden que recomiendo

No haría todo de un golpe. Lo dividiría así:

| Etapa | Resultado |
|---|---|
| 1 | Auditoría y hardening del container |
| 2 | `Dockerfile.vercel` productivo |
| 3 | CI del production container |
| 4 | Build/run local contra Render |
| 5 | Crear proyecto Vercel |
| 6 | Configurar `API_BASE_URL` |
| 7 | Preview deployment |
| 8 | Smoke test |
| 9 | Configurar CORS Render |
| 10 | Production deployment |
| 11 | Smoke test productivo |
| 12 | Protección/required checks |
| 13 | Documentar deployment y rollback |

## Criterio de cierre

Yo sólo declararía el frontend productivo cuando tengamos:

```text
PRODUCTION CONTAINER HARDENED
VERCEL CONTAINER DEPLOYED
RENDER CORS CONFIGURED
HTTPS E2E VERIFIED
NO FRONTEND SECRETS
CI GREEN
ROLLBACK VERIFIED
```

Hay una precisión importante: Vercel construye y almacena automáticamente `Dockerfile.vercel` en su Container Registry en cada deployment, por lo que **no necesitamos montar Docker Hub, GHCR ni administrar un registry externo**. [Vercel](https://vercel.com/blog/dockerfile-on-vercel?utm_source=chatgpt.com)

Para este proyecto, ése sería el plan que seguiría. El siguiente paso lógico es convertirlo en un **prompt de ejecución para Codex**, pero en este caso lo dividiría en dos fases: primero hardening/commit del repo, y después deployment interactivo en Vercel para no mezclar cambios de código con configuración externa.