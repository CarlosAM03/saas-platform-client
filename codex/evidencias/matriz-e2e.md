# Matriz de escenarios ejecutados

Dos corridas independientes del código 7b5320c2a61e2f4170f23f5637cf630a9902de7d, Backend b51b265f1a545fa915f1dd1c57ef2f5858ec6492, PostgreSQL16 local. Cada scope conserva su significado: HTTP_SQL no es UI_TO_DB. tenantFixture indica la fixture de origen del actor; ADMIN-DISCOVERY navega A→B.

| Caso | Scope | Rol | HTTP observado | SQL | Relectura UI | Run1 | Run2 |
|---|---|---|---|---|---|---|---|
| AUTH-OWNER | UI_HTTP | owner | POST /api/v1/auth/login 200 | NOT RUN | PASS | PASS | PASS |
| USR-CREATE-OWNER | UI_TO_DB | owner | POST /api/v1/users 201 | PASS (1) | PASS | PASS | PASS |
| USR-PATCH-DIFFERENTIAL | UI_TO_DB | owner | PATCH /api/v1/users/{id} 200 | PASS (1) | PASS | PASS | PASS |
| USR-DUPLICATE-409 | UI_TO_DB | owner | POST /api/v1/users 409 | PASS (1) | PASS | PASS | PASS |
| USR-INVALID-400 | UI_TO_DB | owner | POST /api/v1/users 400 | PASS (1) | PASS | PASS | PASS |
| USR-CONCURRENT-CREATE | UI_TO_DB | owner | POST /api/v1/users 201; POST /api/v1/users 409 | PASS (2) | PASS | PASS | PASS |
| USR-SEC01-GLOBAL-403 | UI_TO_DB | owner | PATCH /api/v1/users/{id} 403 | PASS (1) | PASS | PASS | PASS |
| USR-SHARED-NOOP | UI_TO_DB | owner | — | PASS (1) | PASS | PASS | PASS |
| CAM-CREATE | UI_TO_DB | owner | POST /api/v1/campaigns 201 | PASS (1) | PASS | PASS | PASS |
| CAM-CREATE-CSV-TARGET | UI_TO_DB | owner | POST /api/v1/campaigns 201 | PASS (1) | PASS | PASS | PASS |
| PRO-MANUAL | UI_TO_DB | owner | POST /api/v1/prospects 201 | PASS (1) | PASS | PASS | PASS |
| PRO-NULLABLE-PATCH | UI_TO_DB | owner | PATCH /api/v1/prospects/{id} 200 | PASS (1) | PASS | PASS | PASS |
| CSV-CREATE | UI_TO_DB | owner | POST /api/v1/prospects/import/preview 200; POST /api/v1/prospects/import/confirm 200 | PASS (1) | PASS | PASS | PASS |
| CSV-SKIP | UI_TO_DB | owner | POST /api/v1/prospects/import/preview 200; POST /api/v1/prospects/import/confirm 200 | PASS (1) | PASS | PASS | PASS |
| CSV-LINK | UI_TO_DB | owner | POST /api/v1/prospects/import/preview 200; POST /api/v1/prospects/import/confirm 200 | PASS (1) | PASS | PASS | PASS |
| CSV-UPDATE | UI_TO_DB | owner | POST /api/v1/prospects/import/preview 200; POST /api/v1/prospects/import/confirm 200 | PASS (2) | PASS | PASS | PASS |
| CAM-EDIT-STATUS | UI_TO_DB | owner | PATCH /api/v1/campaigns/{id} 200 | PASS (1) | PASS | PASS | PASS |
| JWT-OWNER-SNAPSHOT | UI_TO_DB | owner | POST /api/v1/users 201 | PASS (1) | PASS | PASS | PASS |
| AUTH-MEMBER | UI_HTTP | member | — | NOT RUN | PASS | PASS | PASS |
| CAM-CREATE-MEMBER | UI_TO_DB | member | POST /api/v1/campaigns 201 | PASS (1) | PASS | PASS | PASS |
| USR-MEMBER-403 | UI_ACCESS_CONTROL_AND_HTTP_SQL | member | POST /api/v1/users 403 | PASS (1) | PASS | PASS | PASS |
| TEN-CROSS-READ | UI_TO_DB_READ | other | GET /api/v1/campaigns/{id} 404 | PASS (1) | PASS | PASS | PASS |
| ADMIN-DISCOVERY-MEMBERSHIP | UI_HTTP_SQL | admin | GET /api/v1/tenants 200 | PASS (1) | PASS | PASS | PASS |
| USR-CREATE-ADMIN | UI_TO_DB | admin | POST /api/v1/users 201 | PASS (1) | PASS | PASS | PASS |
| USR-DEACTIVATE-ADMIN | UI_TO_DB | admin | DELETE /api/v1/users/{id} 200 | PASS (1) | PASS | PASS | PASS |
| CAM-ARCHIVE | UI_TO_DB | admin | DELETE /api/v1/campaigns/{id} 200 | PASS (1) | PASS | PASS | PASS |
| JOBS-DISABLED-503 | HTTP_SQL | admin | POST /api/v1/prospecting-jobs 503; POST /api/v1/prospecting-jobs/{id}/cancel 503; POST /api/v1/prospecting-jobs/{id}/persist 503; GET /api/v1/prospecting-jobs/{id}/export 503 | PASS (1) | NOT RUN | PASS | PASS |
| JOBS-READ-UI | UI_TO_DB_READ | admin | GET /api/v1/prospecting-jobs 200; GET /api/v1/prospecting-jobs/{id} 200 | PASS (1) | PASS | PASS | PASS |
| DASH-SQL-TOTALS | UI_TO_DB_READ | admin | GET /api/v1/campaigns 200; GET /api/v1/prospects 200; GET /api/v1/prospecting-jobs 200 | PASS (1) | PASS | PASS | PASS |
| TEN-CREATE-ADMIN | UI_TO_DB | admin | POST /api/v1/tenants 201 | PASS (2) | PASS | PASS | PASS |
| CAM-DELETE-ADMIN | UI_TO_DB | admin | DELETE /api/v1/campaigns/{id} 200 | PASS (1) | PASS | PASS | PASS |
| AUTH-LOGOUT-DEEPLINK | UI_HTTP | admin | POST /api/v1/auth/logout 200 | NOT RUN | PASS | PASS | PASS |

Negativos complementarios: api-negative.json (6 PASS; scopes HTTP_SQL). Mocks solo en unidad/widgets/contratos; estas corridas no usan respuestas de negocio simuladas.
