# Platform API Client

Backend de autoridad: `ab53272f531d15e6c4dcc9df8c1d6dca8601e87a`.

Las features reciben `ref.watch(platformApiProvider)` y usan un repository/adaptador de feature encima de `PlatformApi`. Endpoints, queries y parsing están en `lib/platform_api`; Dio sigue encapsulado en transporte. Los modelos visuales no son DTOs HTTP.

Ejemplo: `api.campaigns.list(query: const PaginationQuery(page: 1, limit: 20, sortBy: SortField.createdAt, sortOrder: SortOrder.desc))`.

Los PATCH anulables usan `FieldUpdate.omitted()` (conservar) o `FieldUpdate.set(null)` (limpiar); un valor se envía con `FieldUpdate.set(valor)`. Requests de actualización vacíos se rechazan. Enum desconocido, tipo incorrecto o wrapper inválido produce error detectable. El backend actual puede devolver `User.role = null`, aunque el OpenAPI no marca esa propiedad nullable; el DTO acepta explícitamente ese resultado real sin modificar OpenAPI.

Health, Auth, Tenants, Users, Campaigns, Prospects y Jobs list/detail están representados. Jobs create/cancel/persist/export son sólo contrato: el backend actual responde 503 y conserva `error.code` y `error.details.reason=PROSPECTOR_INTEGRATION_PENDING`. Persist no envía body; create requiere Idempotency-Key; export devuelve bytes y metadata HTTP sin exponer Dio. No existe cliente para callbacks internos de Prospector.

## Pruebas

`flutter test` incluye Foundation, clientes API y pruebas directas contra el YAML versionado (todos los paths/métodos públicos, queries, cuerpos, wrappers y DTOs). `yaml` es dependencia de desarrollo exclusiva de estas pruebas; no se actualizaron dependencias de runtime.

P2C es manual y usa únicamente backend Docker local con su seed demo. Desde el checkout del backend, ejecutar `docker compose up --build -d`. Desde el cliente:

```powershell
flutter test tool/platform_api_p2c_test.dart --dart-define=P2C_BASE_URL=http://localhost:3000 --dart-define=P2C_PASSWORD=DevOnlyPass123!
```

El password del comando corresponde exclusivamente al seed local de Compose. P2C rechaza hosts no locales. Usa almacenamiento de test en memoria y HTTP real; no usa mocks de backend. Crea una campaña con nombre único, lee, actualiza y archiva; verifica lectura persistida y consulta prospects/users/jobs. Deja únicamente la campaña de prueba archivada para evidencia de PostgreSQL. No se ejecuta como parte de CI estándar ni contra producción.

El seed actual de Jobs guarda `query.source="demo"`, fuera del enum contractual `google_maps`; P2C comprueba que ese drift produce `FormatException`. Para verificar también un detalle válido, inserta un Job temporal contractual en PostgreSQL local mediante `docker compose exec db psql` y lo elimina en `finally`. No altera los Jobs existentes ni archivos del backend. El checkout backend se encuentra por defecto en `../../Backend_Nestjs/saas-platform-backend` desde el path real del cliente; puede sobrescribirse con `--dart-define=P2C_BACKEND_DIR=<ruta>`. Corregir el seed queda pendiente para el owner del backend.
