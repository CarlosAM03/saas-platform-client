# Matriz de paridad OpenAPI

FechaUTC:2026-10-28T00:36:51.471Z. Fuente principal: Swagger público real https://saas-platform-backend-l55n.onrender.com/api/docs-json, versión1.0.0 consultada después del merge del owner. Cliente devcd527ef12bc7c1327ed9a8520e1a07f0fc8be39f. Comparación:33 operaciones, requestBody/parameters/respuestas de éxito y todos los esquemas sin diferencias semánticas evaluadas; descripciones/vendor extensions se conservan como documentación. Evidencias public-openapi-parity.json y openapi-parity.json (local).

El YAML objetivo de Backend contiene reservas futuras; deploymentDocument lo transforma a disponibilidad real. Se mantuvieron responses503 y x-target-responses contract-only de Foundation, sin reintroducir éxito ficticio. Las únicas correcciones demostradas fueron restricciones heredadas de consulta P2, campaignId, afirmaciones snapshotPG/TTL y sortBy Jobs. Backend no se cambió para satisfacer pantallas.

| Operación | Disponibilidad | Entrada | Autoridad | Éxitos documentados disponibles | Errores declarados |
|---|---|---|---|---|---|
|GET /api/v1/health|Real|path/query o vacío|Público|200||
|GET /api/v1/health/live|Real|path/query o vacío|Público|200||
|GET /api/v1/health/ready|Real|path/query o vacío|Público|200|503|
|POST /api/v1/auth/login|Real|LoginRequest|Público|200|400/401/429|
|POST /api/v1/auth/logout|Real|path/query o vacío|JWT; select valida membresía/ADMIN|200|401|
|POST /api/v1/auth/select-tenant|Real|SelectTenantRequest|JWT; select valida membresía/ADMIN|200|400/401/403/404|
|GET /api/v1/auth/me|Real|path/query o vacío|JWT; select valida membresía/ADMIN|200|401|
|GET /api/v1/tenants|Real|path/query o vacío|JWT; descubrimiento autorizado|200|401|
|POST /api/v1/tenants|Real|CreateTenantRequest|ADMIN|201|400/401/403/409|
|GET /api/v1/tenants/{id}|Real|path/query o vacío|JWT; descubrimiento autorizado|200|401/404|
|GET /api/v1/users|Real|path/query o vacío|ADMIN/OWNER/MEMBER|200|400/401/403|
|POST /api/v1/users|Real|CreateUserRequest|ADMIN/OWNER +SEC-01|201|400/401/403/409|
|GET /api/v1/users/{id}|Real|path/query o vacío|ADMIN/OWNER/MEMBER|200|401/404|
|PATCH /api/v1/users/{id}|Real|UpdateUserRequest|ADMIN/OWNER +SEC-01|200|400/401/403/404/409|
|DELETE /api/v1/users/{id}|Real|path/query o vacío|ADMIN|200|401/403/404|
|GET /api/v1/campaigns|Real|path/query o vacío|ADMIN/OWNER/MEMBER|200|401|
|POST /api/v1/campaigns|Real|CreateCampaignRequest|ADMIN/OWNER/MEMBER|201|400/401/409|
|GET /api/v1/campaigns/{id}|Real|path/query o vacío|ADMIN/OWNER/MEMBER|200|401/404|
|PATCH /api/v1/campaigns/{id}|Real|UpdateCampaignRequest|ADMIN/OWNER/MEMBER|200|400/401/403/404|
|DELETE /api/v1/campaigns/{id}|Real|path/query o vacío|ADMIN/OWNER/MEMBER; permanent soloADMIN|200|401/403/404/409|
|GET /api/v1/campaigns/{id}/prospects|Real|path/query o vacío|ADMIN/OWNER/MEMBER|200|401/404|
|GET /api/v1/prospects|Real|path/query o vacío|ADMIN/OWNER/MEMBER|200|401|
|POST /api/v1/prospects|Real|CreateProspectRequest|ADMIN/OWNER|201|400/401/403/404|
|POST /api/v1/prospects/import/preview|Real|CSV multipart (file/campaignId/ref/decisions según etapa)|ADMIN/OWNER|200|400/401/403/404/413|
|POST /api/v1/prospects/import/confirm|Real|CSV multipart (file/campaignId/ref/decisions según etapa)|ADMIN/OWNER|200|400/401/403/404/409/413|
|GET /api/v1/prospects/{id}|Real|path/query o vacío|ADMIN/OWNER/MEMBER|200|401/404|
|PATCH /api/v1/prospects/{id}|Real|UpdateProspectRequest|ADMIN/OWNER/MEMBER|200|400/401/404/409|
|GET /api/v1/prospecting-jobs|Real|path/query o vacío|ADMIN/OWNER/MEMBER|200|401/403|
|POST /api/v1/prospecting-jobs|Deshabilitada503|CreateProspectingJobRequest|ADMIN/OWNER/MEMBER||400/401/403/503|
|GET /api/v1/prospecting-jobs/{id}|Real|path/query o vacío|ADMIN/OWNER/MEMBER|200|401/403/404|
|POST /api/v1/prospecting-jobs/{id}/cancel|Deshabilitada503|path/query o vacío|ADMIN/OWNER/MEMBER||401/403/503|
|POST /api/v1/prospecting-jobs/{id}/persist|Deshabilitada503|path/query o vacío|ADMIN/OWNER/MEMBER||401/403/503|
|GET /api/v1/prospecting-jobs/{id}/export|Deshabilitada503|path/query o vacío|ADMIN/OWNER/MEMBER||400/401/403/503|

Convenciones verificadas: prefijo/api/v1, Authorization:Bearer en protegidas; JSONContent-Type o multipart según operación. No header tenantoverride: el contexto procede del JWT. Idempotency-Key sigue obligatorio en creación de Job aunque sea503 y no se almacene; el SDK preparado permanece inactivo. AuthContext reemplaza token/contexto al seleccionar tenant.

Listas paginadas usan success/data/meta y page/limit/total/totalPages, máximo100; GETtenants devuelve array simple. Jobs sortBy acepta createdAt/updatedAt/startedAt/completedAt/status/id. Los schemas preservan enums/nullables; PATCH distingue omisión y null (prospectos/usuarios según DTO), sin inventar endpoints roles/dashboard ni permisos. Errores normalizan successfalse/error(code,message,details,timestamp);401actual cierra sesión,403 conserva sesión,404oculta ID ajeno,409rechaza estado/referencia stale,413payload,429rate limit y503indisponibilidad donde procede.

Los101 casos contractuales del SDK verifican método/ruta/query/headers/DTO/envelopes/errores/nullables, dentro de la suite256 aprobada. Son pruebas con fixtures; HTTP/PG/runtime y navegación real complementan esa evidencia. No se afirma haber ejecutado todas las operaciones CRUD contra producción. La captura del owner acredita login/dashboard productivo básico, y la paridad pública no acredita por sí sola el SHA binario de Render.
