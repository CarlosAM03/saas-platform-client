# Validación Backend runtime v1.0.0

FechaUTC:2026-10-28T00:23:34.968Z. Fuente dev:09593bb715cd83270821d34126a4344c8ef97cb0; main posterior del owner:b51b265f1a545fa915f1dd1c57ef2f5858ec6492. Base3a3309398458ab333d7b00f16e9c2df6a09ef734.

Se utilizó Dockerfile original target runtime, Node20.20.2, Prisma5.22.0 y PostgreSQL16 dedicado. Build completo, npm ci productivo, generación Prisma y compilación NestJS aprobados; arranque real como usuario node, NODE_ENV=production, JWT local robusto, CORS HTTPS explícito y sin variables Service. La imagen/ID local final se registra en evidencias/local-final-inventory.json. No se publicó una imagen en un registry.

Los38 checks de verify-runtime.mjs validan live/ready, Swagger1.0.0, orígenes CORS permitido/ajeno, Auth/cinco cuentas, contexto ADMIN, aislamiento de listados e IDs, MEMBER conforme a guards, campaña creada/editada por MEMBER, CSV multipart real con teléfono0012345 preservado, rechazo de campaña ajena/MEMBER, consulta de Jobs y rechazo503 de creación/cancelación tras requests válidos. No hay endpoint dashboard: sus totales provienen de las listas reales. Swagger/API están en http://127.0.0.1:18441/api/docs y /api/v1.

SEC-01 se comprueba además con PostgreSQL real: identidad compartida, ADMIN ajeno, atomicidad identidad+rol, self/local/global ADMIN permitidos y rol limitado a la membresía A. La suite conserva snapshot y verifica que un usuario global inactivo obtiene401. Esquema y migración init siguen baseline, sin Event/Snapshot/dispatch/TTL P2.

El arranque completo y el reinicio controlado conservan volúmenes. El seed reservado es idempotente y restaura sus passwords; el dataset final core tiene2 tenants,5 usuarios,7 campañas,38 prospectos y10 jobs históricos (6/36 baseline más campaña/fila de smoke y fila CSV UI). El panel visual no añadió Jobs ni prospectos. Se escanearon logs y bundle sin coincidencias con secretos locales.

Audit productivo:0 vulnerabilidades; árbol completo:8low en herramientas dev, cero moderate/high/critical. No se aplicó npm audit fix general. Advertencias de deprecación no se presentan como exploits demostrados.

Limitaciones: snapshot permite vigencia de autorizaciones hasta8h; Node20 queda diferido por decisión expresa del plan. CI/tests locales no acreditan por sí solos el despliegue Render ni su configuración secreta; la revisión pública posterior se separa en RUNBOOK_POST_MERGE.md.

Serialización real verificada posteriormente sobre esta misma clase compilada: P2034 por actualización concurrente después de la lectura SERIALIZABLE; escritura concurrente preservada y rol anterior intacto. No se añadió reintento externo ni se modificó código. Ver core-serialization-runtime.json.
