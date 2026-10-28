# Matriz de contrato ADR-006

Fecha: 2026-10-28, America/Tijuana. Rama feat/tenant-register; cliente a09c117,
corrección de test919ce03. Fuentes inmutables: ADR-006 aprobado y
Docs/Contracts/platform-api.tenant-registration.approved.yaml. Código Backend
contrastado mediante snapshots ca1e7c9 y5e214420. Runtime final aún no acreditado.

Procedimiento: lectura de DTO/controllers/services/guards, PlatformApi, ApiClient
y test/adr006/api_contract_test.dart; flutter test completo y ADR006. Esperado:
igualdad de ruta/método/body/nullability/acciones/roles sin cambiar login normal.

| Operación | Request / autorización | Respuesta / errores | Observado |
|---|---|---|---|
| POST /api/v1/tenants/register | Bearer ADMIN con/sin tenant; exactamente tenantName,tenantSlug,ownerName,ownerEmail |201 tenant+onboarding;400/401/403/409/429/500/503 | CONTRACT PASS; runtime preliminar201/SQL PASS |
| GET /api/v1/tenants/{id}/onboarding | ADMIN; sin body ni tenant obligatorio |200 onboarding;401/403/404/500 | CONTRACT PASS; runtime preliminar200/relectura PASS |
| POST /api/v1/tenants/{id}/resend-welcome | ADMIN; ausencia de body |200 onboarding;400/401/403/404/409/429/500/503 | CONTRACT PASS; runtime preliminar429 y200 sin body PASS |
| POST /api/v1/auth/redeem-first-access | Público, JSON activationToken; sin lectura/adjunto JWT |200 CHANGE_PASSWORD_REQUIRED,firstAccessToken,expiresAt;400/401/429/500 | CONTRACT PASS; canje real completo pendiente |
| POST /api/v1/auth/complete-first-access | Público, JSON firstAccessToken,newPassword; sin JWT |200 LOGIN_REQUIRED;400/401/429/500 | CONTRACT PASS; runtime final pendiente |

Register: trim de nombres y correo, minúsculas de correo; nombres1–120 Unicode,
slug3–63 con guiones interiores, email máximo254. Backend sigue validando.
Onboarding requiere tenantId,ownerUserId,ownerEmail,activationStatus,deliveryStatus,
createdAt,lastAttemptAt,providerAcceptedAt,activationLinkExpiresAt,completedAt.
Las últimas cuatro fechas admiten null; createdAt no. Enums cerrados y acciones
discriminadas comprobados por tests. No se expone secreto en el onboarding.

Flag OFF: Backend503 sin writes para registro/reenvío; GET, canje y finalización
de pendientes siguen disponibles. Frontend no inventa un flag equivalente.
Contrato estático PASS; repetición runtime OFF contra candidato final pendiente.

El mismo Dio interno centraliza requests. Solo dos paths públicos aprobados
omiten JWT/logout global y descartan mensajes/details/codes externos sensibles.
Login mantiene AuthContext; POST /tenants técnico conserva su API aunque el alta
visible /tenants/new usa el formulario asistido aprobado por este PR.

Evidencia: tests de contrato ejecutados en baseline/final, CI38 y reporte05.
Límite: fixtures no prueban disponibilidad NestJS ni transacciones.
