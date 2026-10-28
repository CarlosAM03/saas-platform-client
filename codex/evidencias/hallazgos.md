# Hallazgos — Sprint Core V1, 28 octubre 2026

| ID | Prioridad | Estado | Causa, corrección y evidencia |
|---|---|---|---|
| FE-01 | P1 | PASS | UserFormPage enviaba name/email/status sin cambios. PATCH diferencial y no-op local normalizado. Seis regresiones específicas fallaron antes y pasan después; UI/HTTP/SQL comprueba nombre, SEC-01 y ausencia de PATCH espurio. |
| FE-02 | P1 | PASS | ADMIN descubría globalmente solo sin memberships. Ahora discovery es independiente de ellas. Regresiones ADMIN/OWNER/MEMBER y retry; navegador demuestra ADMIN miembro de A descubriendo B sin membership. |
| FE-03 | P1 | PASS | La UI leía rol vigente en DB mientras NestJS autoriza por JWT snapshot. Excepción expresamente autorizada durante este chat: lectura de claims solo de presentación, con sub/tenantId/exp/algoritmo/roles conocidos. Sin verificación de firma ni autoridad nueva en cliente. JWT OWNER conserva presentación tras democión DB; JWT MEMBER sigue restringido tras promoción DB. |
| FE-04 | P2 | NOT RUN | roleId existe en API; no se añadió selector de rol a UI. El harness exige decisión del owner para esa ampliación visible. Recomendación: tratarlo aparte con diseño aprobado, sin mezclarlo con ADR-006. |
| FE-05 | P2 | PASS | Future.wait derribaba todo el dashboard por Jobs. Ahora esa sección muestra error/retry y conserva cifras reales de campañas/prospectos. No fabrica cero. Regresión de repository + widget; errores críticos conservan fallo general. |
| FE-06 | P2 | PASS | Auditoría: la UI ya advierte que el filtro de estado aplica a la página actual. Backend no ofrece parámetro de filtro global. Se conserva la semántica explícita. |
| FE-07 | P2 | BLOCKED | Seed histórico de Jobs usa query.source=demo; enum público exige google_maps. P2C conserva rechazo del detalle heredado y crea una fixture contractual temporal para validar consultas reales. Corregir seed/Backend está fuera de autoridad del sprint. |
| FE-08 | P2 | PASS | FormatException/TypeError tenían mensaje genérico. Se distingue incompatibilidad de formato sin incluir el mensaje del parser, payload o secretos. Tests de redacción y diagnóstico observables. |
| FE-10 | P1 | PASS | La ampliación E2E reveló una regresión introducida al hacer Jobs nullable: el fallback [] convertía el elemento a dynamic y Enum.name fallaba con listas no vacías. Se conservó el tipo al iterar dentro de una condición no-null. Test poblado falla antes con NoSuchMethodError y pasa después; la suite completa sube a279. |
| FE-09 | P1 | PASS | E2E reprodujo que recargar detalle restauraba sesión y perdía la ruta, terminando en Dashboard. El router conserva URI interna durante restauración y la descarta en logout/expiración/fallo. Regresión fallida antes, aprobada después; SQL + recarga de usuarios/prospectos/campañas ejercitan la corrección. |

## Riesgo residual aprobado

JWT sigue siendo snapshot servidor de hasta ocho horas. La lectura de claims no revoca ni verifica tokens; NestJS continúa autorizando y validando identidad activa. Esta deuda ALTA permanece. Los datos descriptivos de identidad se conservan según AuthContext; no se modifica contrato.

## Correcciones del verificador, separadas del producto

- P2C: una contraseña aleatoria hex del seed no satisface la política de alta V1. La fixture nueva agrega caracteres de las clases requeridas; el seed y las validaciones no cambian.
- Flutter Web representa texto estático mediante semántica. Se esperan estados accesibles y se introducen teclas reales; vaciar un campo requiere Backspace. La carrera de usuarios usa dos formularios reales.
- La CA confiable de Chromium no era automáticamente confiable para el driver HTTP Node. NODE_EXTRA_CA_CERTS se limita al contenedor de ensayo; TLS sigue validado.
- CSV V1 clasifica por nombre normalizado. Cambiar el nombre de la fila producía NEW, no MATCH. UPDATE_EXISTING mantiene ese identificador y verifica una modificación real de categoría en la misma fila por SQL y recarga. No se cambia la clasificación ni el Backend para pasar el test.
- Cada run conserva registros previos mediante checksum completo del seed y cleanup de sus entidades sintéticas. Los intentos fallidos se conservan; no acreditan aceptación.

## Límites remotos y ADR-006

El URL productivo suministrado por el owner pasa bundle/API origin y CORS. El alias histórico documentado responde404; es DOC_DRIFT. Smoke autenticado de solo lectura aprobado; datos de cuenta/negocio y credenciales excluidos.

El SHA efectivo servido por Vercel/Render no queda probado por un health, Swagger o registro GitHub de deployment: G4 no puede certificar identidad de ambos artefactos. No se cambió hosting/CORS ni se hicieron escrituras de negocio remotas.

Los dos insumos aprobados ADR-006 aparecieron posteriormente como archivos no rastreados del checkout. Se leyeron e inventariaron cinco operaciones futuras con sus hashes, sin modificarlos ni incorporarlos al contrato Core.
