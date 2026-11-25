# Runbook — entorno sintético para T32 (Flutter → API real)

Backend de referencia: `3b5eec6fa99f846e853794fc8aedff2c4353c269` (rama `feat/sprint-campana-prospector`).

Propósito: que André pueda ejecutar T32 (E2E real UI→API) sin mocks ocultos, con datos sintéticos y sin tocar infraestructura remota.

## 1. Requisitos

- Docker Desktop con Compose.
- Copia local del repositorio backend en el SHA indicado (`git rev-parse HEAD` debe ser `3b5eec6...`; si hay commits documentales posteriores, el código de `src/`, `Prisma/` y `Docs/` es el mismo y puede verificarse con `git diff 3b5eec6 -- src Prisma Docs`).
- Puerto local libre (por defecto `3000`; se puede cambiar con `API_HOST_PORT`).

## 2. Levantar el backend (perfil de desarrollo)

```text
docker compose up --build -d db db-init api
```

- `db`: PostgreSQL 16 local con volumen `dev-postgres`.
- `db-init`: aplica `prisma migrate deploy` y ejecuta `Prisma/seed_dev.ts` (sólo `DATABASE_ENV=local`).
- `api`: NestJS en `http://localhost:3000`.

Comprobaciones:

```text
curl http://localhost:3000/api/v1/health/ready
curl http://localhost:3000/api/v1/health/live
```

Swagger: `http://localhost:3000/api/docs` · JSON: `http://localhost:3000/api/docs-json`.

Registro de tenants deshabilitado (`TENANT_REGISTRATION_ENABLED=false`): no se crean organizaciones desde la UI.

## 3. Usuarios sintéticos del seed

La contraseña de todos es la variable `DEV_SEED_PASSWORD` configurada al levantar el entorno (mínimo 12 caracteres; valor local de desarrollo, no real). No se documenta aquí ese valor ni se usan credenciales reales.

| Usuario | Rol | Tenant |
|---|---|---|
| `admin@demo.example` | ADMIN de plataforma | sin tenant (selecciona uno) |
| `owner.demo-norte@demo.example` | OWNER | `demo-norte` |
| `member.demo-norte@demo.example` | MEMBER | `demo-norte` |
| `owner.demo-sur@demo.example` | OWNER | `demo-sur` |
| `member.demo-sur@demo.example` | MEMBER | `demo-sur` |

Datos: por tenant, 3 campañas (`demo-campaign-<slug>-1..3`) con 6 prospectos cada una; la campaña 1 trae participaciones con etapa/evaluación para probar C1/C2/C4/C6/C8.

## 4. Flujo de sesión

```text
POST /api/v1/auth/login        {email, password}     → data.accessToken, data.tenants
POST /api/v1/auth/select-tenant {tenantId}           → nuevo accessToken con tenant
GET  /api/v1/auth/me                                 → contexto actual
```

- El tenant viaja dentro del JWT; no hay cabecera de tenant.
- Cambiar de tenant exige `select-tenant` y reemplazar el token en `ApiClient`.
- Login limitado a 5 intentos por minuto por IP (429).

Ejemplo de lectura después de seleccionar tenant:

```text
GET /api/v1/campaigns?page=1&limit=20
GET /api/v1/campaigns/demo-campaign-demo-norte-1/dashboard
GET /api/v1/campaigns/demo-campaign-demo-norte-1/prospects?stage=CONTACTADO&page=1&limit=20
```

## 5. Datos para T32

- Alta manual: crear un prospecto nuevo con nombre sintético (`Synthetic T32 <uuid>`), verificar `match` y la decisión explícita.
- Importación CSV: preparar un CSV UTF-8 de 2–3 filas con cabeceras `name,category,address,phone,email,website,language,status`; probar un preview y un confirm.
- Bitácora: crear una actividad `CALL`, corregirla con `correctsId` y verificar que el original no cambia.
- Dashboard: comprobar `total = manual + events` y que las correcciones incrementan `manual`.
- Aislamiento: repetir una lectura con un token de `demo-sur` sobre una campaña de `demo-norte` y confirmar `404`.

Nunca usar datos reales, correos reales, tokens en capturas ni CSV con información personal.

## 6. Regresión del backend (opcional)

Base desechable en memoria temporal (`tmpfs`), sin tocar la base de desarrollo:

```text
docker compose --profile test run --build --rm test-postgres sh -c "npm run build && npm run test:unit:ci && npm run test:e2e:ci && npm run prisma:migrate:deploy && npm run test:postgres"
```

Referencia esperada para el SHA: build PASS, 178 unitarias, 84 HTTP y 199 PostgreSQL (461 pruebas). No se ejecutó contra datos remotos.

## 7. Apagar

```text
docker compose down
```

No usar `down -v` salvo que se quiera destruir la base local de desarrollo.

## 8. Límites

- Sin `prisma migrate deploy` contra bases remotas ni producción.
- Sin `git push`, merge ni deploy desde este runbook.
- T32 es responsabilidad del frontend; el backend sólo entrega el entorno y el contrato.
