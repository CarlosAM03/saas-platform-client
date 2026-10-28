# E2E local — resultado reproducible

PASS:32/32 escenarios en cada una de dos corridas. Los JSON completos contienen HTTP, requestId, campos enviados, aserciones SQL, recarga y cleanup por caso.

| Evidencia | RunId | Fecha UTC | Casos | Cleanup / seed |
|---|---|---|---|---|
| e2e-local.json | sprintf7022e5895d7fa | 2026-10-28T10:11:58.719Z | 32 PASS | PASS |
| e2e-repeat.json | sprintdc803efd8f9e1a | 2026-10-28T10:24:09.298Z | 32 PASS | PASS |

Aplicación y runner probados: 7b5320c2a61e2f4170f23f5637cf630a9902de7d. Backend de autoridad: b51b265f1a545fa915f1dd1c57ef2f5858ec6492. El checkout de construcción Backend69c7336 tiene árbol completo idéntico a main b51b265; runtime-identities.json confirma imagen activa y PostgreSQL16.

Se probaron creación V1 de usuarios OWNER y ADMIN, default MEMBER, payload diferencial, validación400, duplicado409, SEC-01403, no-op compartido, permisos MEMBER y JWT snapshot después de cambios DB. Dos formularios reales concurrentes produjeron201/409, una identidad y una membresía.

Campaigns: creación OWNER/MEMBER/ADMIN, edición/PAUSADA, archivo y eliminación permanente ADMIN. Prospects: manual, source/relación, null frente a omitted y recarga. CSV: cuatro decisiones, mismos bytes originales (hash), vínculos y actualización real de categoría sobre identidad existente. Dashboard: totales meta.total contra SQL incluyendo Jobs no vacíos. Jobs: lista/detalle reales y cuatro503, sin ejecutar Service. Tenants: discovery ADMIN con membership y provisión técnica V1.

La corrida complementaria HTTP_SQL verificó JWT expirado401, CSV expirado400, bytes alterados400, tamaño413, replay409 y rate limiting429; seis PASS con cleanup PASS. No se presentan como mutaciones de UI.

El verificador SQL está fuera de Flutter. Proyecto exclusivo prospector-frontend-sprint; DB avance2_core en loopback55547, API18541, HTTPS18543. P2C adaptado verifica propiedad del contenedor/base/versión; su modo saas_local heredado queda intacto.

Cleanup elimina únicamente entidades del run y verifica checksum de las ocho tablas seed. Ambos runs y negativos conservaron el seed byte por byte. Stack detenido sin borrar volúmenes tras las verificaciones.

Los intentos anteriores conservan sus FAIL/NOT RUN en sus artefactos y en ejecucion-intentos.md; no acreditan aprobación. La causa del fixture UPDATE se contrastó con el matching por nombre normalizado del Backend.
