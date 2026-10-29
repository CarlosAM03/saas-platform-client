# Inventario Core 33 + ADR-006 5

Auditoría 2026-10-29T06:11:19.669Z. Backend 5e214420394101ae7079f8e844cc759b01cce2a3. Contrato aprobado SHA256 25c2293627214eacf14cd62a511c26d6b70912abe2746b83e7b950020aff5419.

Comparación real de método/ruta, request, autorización y schema/status de respuesta. Sin cambios al contrato aprobado. Las cuatro operaciones Jobs que declaran 503 conservan su indisponibilidad intencional. La especialización heredada de sortBy está identificada en el JSON y ya existía en b51b265.

| Operación | Ámbito | Request | Autorización | Respuesta | 503 intencional |
|---|---|---|---|---|---|
| GET /api/v1/health | CORE | PASS | PASS | PASS | No |
| GET /api/v1/health/live | CORE | PASS | PASS | PASS | No |
| GET /api/v1/health/ready | CORE | PASS | PASS | PASS | No |
| POST /api/v1/auth/login | CORE | PASS | PASS | PASS | No |
| POST /api/v1/auth/logout | CORE | PASS | PASS | PASS | No |
| POST /api/v1/auth/select-tenant | CORE | PASS | PASS | PASS | No |
| GET /api/v1/auth/me | CORE | PASS | PASS | PASS | No |
| GET /api/v1/tenants | CORE | PASS | PASS | PASS | No |
| POST /api/v1/tenants | CORE | PASS | PASS | PASS | No |
| GET /api/v1/tenants/{id} | CORE | PASS | PASS | PASS | No |
| GET /api/v1/users | CORE | PASS | PASS | PASS | No |
| POST /api/v1/users | CORE | PASS | PASS | PASS | No |
| GET /api/v1/users/{id} | CORE | PASS | PASS | PASS | No |
| PATCH /api/v1/users/{id} | CORE | PASS | PASS | PASS | No |
| DELETE /api/v1/users/{id} | CORE | PASS | PASS | PASS | No |
| GET /api/v1/campaigns | CORE | PASS | PASS | PASS | No |
| POST /api/v1/campaigns | CORE | PASS | PASS | PASS | No |
| GET /api/v1/campaigns/{id} | CORE | PASS | PASS | PASS | No |
| PATCH /api/v1/campaigns/{id} | CORE | PASS | PASS | PASS | No |
| DELETE /api/v1/campaigns/{id} | CORE | PASS | PASS | PASS | No |
| GET /api/v1/campaigns/{id}/prospects | CORE | PASS | PASS | PASS | No |
| GET /api/v1/prospects | CORE | PASS | PASS | PASS | No |
| POST /api/v1/prospects | CORE | PASS | PASS | PASS | No |
| POST /api/v1/prospects/import/preview | CORE | PASS | PASS | PASS | No |
| POST /api/v1/prospects/import/confirm | CORE | PASS | PASS | PASS | No |
| GET /api/v1/prospects/{id} | CORE | PASS | PASS | PASS | No |
| PATCH /api/v1/prospects/{id} | CORE | PASS | PASS | PASS | No |
| GET /api/v1/prospecting-jobs | CORE | PASS | PASS | PASS | No |
| POST /api/v1/prospecting-jobs | CORE | PASS | PASS | FAIL | Sí |
| GET /api/v1/prospecting-jobs/{id} | CORE | PASS | PASS | PASS | No |
| POST /api/v1/prospecting-jobs/{id}/cancel | CORE | PASS | PASS | FAIL | Sí |
| POST /api/v1/prospecting-jobs/{id}/persist | CORE | PASS | PASS | FAIL | Sí |
| GET /api/v1/prospecting-jobs/{id}/export | CORE | PASS | PASS | FAIL | Sí |
| POST /api/v1/tenants/register | ADR006 | PASS | PASS | PASS | No |
| GET /api/v1/tenants/{id}/onboarding | ADR006 | PASS | PASS | PASS | No |
| POST /api/v1/tenants/{id}/resend-welcome | ADR006 | PASS | PASS | PASS | No |
| POST /api/v1/auth/redeem-first-access | ADR006 | PASS | PASS | PASS | No |
| POST /api/v1/auth/complete-first-access | ADR006 | PASS | PASS | PASS | No |
