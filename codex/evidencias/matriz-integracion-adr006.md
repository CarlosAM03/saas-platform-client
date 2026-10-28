# Frontera ADR-006 — inventario documental, sin implementación

Estado de inventario: PASS. Durante P0 los insumos no estaban presentes; posteriormente aparecieron como archivos no rastreados aportados al checkout. Se leyeron sin modificarlos. Por autorización expresa posterior del owner se adjuntan al commit documental final como referencias futuras, sin sustituir el contrato Core. Sus hashes están en adr006-inventory.json. La versión aprobada1.1.0 conserva33 operaciones Core y añade cinco TARGET_ONLY; ninguna se cuenta como disponible en Backend main b51b265.

| Operación futura | Seguridad | DTO/resultado aprobado | Estado de ejecución |
|---|---|---|---|
| POST /api/v1/tenants/register | ADMIN, sin tenant obligatorio | tenantName,tenantSlug,ownerName,ownerEmail;201 Tenant+onboarding, aun con fallo de correo;409 colisiones;503 con flag apagado | NOT RUN |
| GET /api/v1/tenants/{id}/onboarding | ADMIN | Estado de onboarding/entrega sin secretos; disponible para pendientes aunque flag esté apagado | NOT RUN |
| POST /api/v1/tenants/{id}/resend-welcome | ADMIN, sin body | Nueva generación, invalida enlaces/desafíos previos;200 resultado de intento,409/429/503 según contrato | NOT RUN |
| POST /api/v1/auth/redeem-first-access | Público, token del body, sin Bearer | activationToken;200 CHANGE_PASSWORD_REQUIRED,firstAccessToken,expiresAt;401/429 | NOT RUN |
| POST /api/v1/auth/complete-first-access | Público, desafío del body | firstAccessToken,newPassword;200 LOGIN_REQUIRED;400/401/429 | NOT RUN |

Se preserva AuthContext normal de POST /auth/login; no se convierte a oneOf. El enlace opaco de24h se canjea una vez por desafío de15min. Contraseña futura: mínimo10 caracteres, letra/número/especial, máximo72 bytes UTF-8; bcrypt12. No se aplica retroactivamente esta ampliación al Core.

Puntos de extensión posteriores: AuthApi, providers Auth, router público /activate y pantallas dedicadas; extracción temprana y limpieza del fragmento, secretos solo en memoria. No activar rutas ni llamadas en esta rama. La creación de User V1 y la provisión técnica POST /tenants se conservan y se prueban de forma independiente.

Orden: PR Backend de Ángel probado → migración/auditoría y release compatible con flag apagado → adaptación Flutter desde Core revisado → E2E extendida/correo controlado → GO del owner para habilitar. Flag apagado bloquea nuevas altas y reenvíos, sin interrumpir canje/completado/consulta de pendientes existentes.

Casos futuros: transacción Tenant/OWNER, unicidad case-insensitive, carreras slug/email, enlace/desafío de un uso y expiración, reenvío/generación, LOGIN_REQUIRED/login, bypass rechazado en JWT/Users, correo aceptación/fallo/timeout/lease UNKNOWN, límites1min/5h, SEC-01, PostgreSQL y regresión Core. Sin pagos, quotas comerciales, autorregistro ni Prospector Service.

La futura activación debe retirar code del fragmento antes de entregar la URI a GoRouter: la restauración Core conserva la URI interna y no debe convertirse en almacenamiento de secretos de activación. Este requisito queda como punto de integración futuro, no como ruta activa del Core.
