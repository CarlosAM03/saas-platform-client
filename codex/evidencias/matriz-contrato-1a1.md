# Matriz contractual Core V1

Backend b51b265f1a545fa915f1dd1c57ef2f5858ec6492. AVAILABLE describe código inspeccionado y no certifica runtime. Deployment-document.ts limita cuatro operaciones Jobs a503 y conserva consultas.

| Operación | Implementación | Request equivalente | HTTP objetivo | HTTP Flutter | Runtime |
|---|---|---|---|---|---|
| GET /api/v1/health | AVAILABLE | PASS | 200 | 200 | PASS |
| GET /api/v1/health/live | AVAILABLE | PASS | 200 | 200 | PASS |
| GET /api/v1/health/ready | AVAILABLE | PASS | 200,503 | 200,503 | PASS |
| POST /api/v1/auth/login | AVAILABLE | PASS | 200,400,401,429 | 200,400,401,429 | PASS |
| POST /api/v1/auth/logout | AVAILABLE | PASS | 200,401 | 200,401 | PASS |
| POST /api/v1/auth/select-tenant | AVAILABLE | PASS | 200,400,401,403,404 | 200,400,401,403,404 | PASS |
| GET /api/v1/auth/me | AVAILABLE | PASS | 200,401 | 200,401 | PASS |
| GET /api/v1/tenants | AVAILABLE | PASS | 200,401 | 200,401 | PASS |
| POST /api/v1/tenants | AVAILABLE | PASS | 201,400,401,403,409 | 201,400,401,403,409 | PASS |
| GET /api/v1/tenants/{id} | AVAILABLE | PASS | 200,401,404 | 200,401,404 | PASS |
| GET /api/v1/users | AVAILABLE | PASS | 200,400,401,403 | 200,400,401,403 | PASS |
| POST /api/v1/users | AVAILABLE | PASS | 201,400,401,403,409 | 201,400,401,403,409 | PASS |
| GET /api/v1/users/{id} | AVAILABLE | PASS | 200,401,404 | 200,401,404 | PASS |
| PATCH /api/v1/users/{id} | AVAILABLE | PASS | 200,400,401,403,404,409 | 200,400,401,403,404,409 | PASS |
| DELETE /api/v1/users/{id} | AVAILABLE | PASS | 200,401,403,404 | 200,401,403,404 | PASS |
| GET /api/v1/campaigns | AVAILABLE | PASS | 200,401 | 200,401 | PASS |
| POST /api/v1/campaigns | AVAILABLE | PASS | 201,400,401,409 | 201,400,401,409 | PASS |
| GET /api/v1/campaigns/{id} | AVAILABLE | PASS | 200,401,404 | 200,401,404 | PASS |
| PATCH /api/v1/campaigns/{id} | AVAILABLE | PASS | 200,400,401,403,404 | 200,400,401,403,404 | PASS |
| DELETE /api/v1/campaigns/{id} | AVAILABLE | PASS | 200,401,403,404,409 | 200,401,403,404,409 | PASS |
| GET /api/v1/campaigns/{id}/prospects | AVAILABLE | PASS | 200,401,404 | 200,401,404 | PASS |
| GET /api/v1/prospects | AVAILABLE | PASS | 200,401 | 200,401 | PASS |
| POST /api/v1/prospects | AVAILABLE | PASS | 201,400,401,403,404 | 201,400,401,403,404 | PASS |
| POST /api/v1/prospects/import/preview | AVAILABLE | PASS | 200,400,401,403,404,413 | 200,400,401,403,404,413 | PASS |
| POST /api/v1/prospects/import/confirm | AVAILABLE | PASS | 200,400,401,403,404,409,413 | 200,400,401,403,404,409,413 | PASS |
| GET /api/v1/prospects/{id} | AVAILABLE | PASS | 200,401,404 | 200,401,404 | PASS |
| PATCH /api/v1/prospects/{id} | AVAILABLE | PASS | 200,400,401,404,409 | 200,400,401,404,409 | PASS |
| GET /api/v1/prospecting-jobs | AVAILABLE | FAIL | 200,401 | 200,401,403 | PASS |
| POST /api/v1/prospecting-jobs | DISABLED_503 | PASS | 201,400,401,409,503 | 400,401,403,503 | PASS |
| GET /api/v1/prospecting-jobs/{id} | AVAILABLE | PASS | 200,401,404 | 200,401,403,404 | PASS |
| POST /api/v1/prospecting-jobs/{id}/cancel | DISABLED_503 | PASS | 200,401,404,409 | 401,403,503 | PASS |
| POST /api/v1/prospecting-jobs/{id}/persist | DISABLED_503 | PASS | 200,401,404,409 | 401,403,503 | PASS |
| GET /api/v1/prospecting-jobs/{id}/export | DISABLED_503 | PASS | 200,400,401,404,409 | 400,401,403,503 | PASS |

Runtime: véase runtime-parity.json. P2C real ejercita27 operaciones; Health público completa las dos restantes de Health y UI/HTTP_SQL demuestra las cuatro503 de Jobs. PASS aplica a requests válidos y a respuestas de disponibilidad; FE-07 permanece como drift de seed documentado. La comparación de identidad JSON de request (PASS/FAIL) es distinta de paridad semántica con Swagger implementado.
