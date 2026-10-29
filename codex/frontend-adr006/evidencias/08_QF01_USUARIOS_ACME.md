# QF-01 — Usuarios ACME

Fecha: 2026-10-28, America/Tijuana. feat/tenant-register@919ce03.
Procedimiento: lectura User/UserMembership/Role/UsersApi/unwrapPaginated,
serializador Backend ca1e7c9 y reporte09 del candidato5e214420; ejecución de
test/adr006/users_nullable_regression_test.dart y suite completa Flutter.

Esperado: platformRole=null admisible con OWNER/MEMBER tenant-scoped; ADMIN global
independiente; relaciones, fechas, nullable y meta paginada contractuales parsean.
Observado: PASS. El test incluye OWNER, MEMBER, ADMIN con role=null, membresía
múltiple, description=null, página2, límite4 y search. No se encontró un defecto
demostrable en User.fromJson ni se añadió tolerancia arbitraria a enums inválidos.

User.platformRole representa autoridad global ADMIN/null. UserTenant.roleId y
Role.name representan OWNER/MEMBER del tenant. Un null global no significa FK
nula ni falta de rol. Backend filtra memberships visibles al tenant operativo.

La investigación Backend publicada en
codex/backend-adr006/evidencias/09_QF01_USUARIOS_ACME.md del SHA5e214420 también
reporta PASS sintético con PostgreSQL16, sin reproducir la causa histórica.
Se conserva como evidencia de otro agente y no como ejecución SQL de este carril.

Estado: diagnóstico sintético PASS; causa histórica NO DETERMINADA/BLOCKED.
No se modificó producción, ACME, esquema, roles ni contrato. Sin un payload mínimo
anonimizado o copia autorizada que conserve la forma defectuosa no se puede
atribuir la falla al parser o al servidor, ni declarar resuelto el incidente real.

Siguiente comprobación: capturar solo status/requestId, claves/tipos y posición
anónima de fila problemática; validar meta/fechas/enums y Role/UserTenant en copia
autorizada. Si la respuesta es contractual, regresión Flutter; si no, reporte
Backend. Datos históricos reales y reparación requieren el carril autorizado.


## Revalidación conjunta del agente único

Fecha UTC: 2026-10-29T06:42:10.981Z (2026-10-28 America/Tijuana). Entorno Windows, Flutter3.47.5/Dart3.13.4, Node22, Docker, Chromium/Playwright, PostgreSQL16 real. Rama feat/tenant-register. Código Flutter 2590aa423c2f329d3309507bf08975db435b63c1; Backend candidato PR10 5e214420394101ae7079f8e844cc759b01cce2a3; revisión de tooling/evidencias f981a839781b6415af51805cf4f0724b16a022f4. La publicación documental posterior no altera estos artefactos.

Esperado: flujo autorizado sin regresión, integridad ni secretos expuestos. Observado: evidencia nueva indicada abajo. Los apartados anteriores se conservan como histórico; este apartado actualiza su estado.

Estado: PASS sintético; causa del incidente histórico NO DETERMINADA. Fixture nullable de parser pasa en317tests y Core32×2 verifica Users reales con platformRole=null, OWNER/MEMBER y membresía compartida; navegación adicional valida paginación/búsqueda API real. Backend256 PASS reproducido por este agente. No se modificaron producción ni parser ante un supuesto no demostrado. User.platformRole ADMIN/null es distinto de UserTenant.roleId/Role.name. No declarar resuelto el ACME histórico sin payload anonimizado o reproducción autorizada.
