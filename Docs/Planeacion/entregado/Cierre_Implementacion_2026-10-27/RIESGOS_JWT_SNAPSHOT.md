# JWT snapshot y riesgos residuales

FechaUTC:2026-10-28T00:23:34.968Z. Autoridad: Plan de TrabajoAvance2.md, ADR-004 y ratificación expresa del owner en autorización ampliada.

Se conserva JwtStrategy baseline y duración8h. El rol/membresía/contexto incluido en un token emitido puede seguir autorizando hasta su expiración aunque cambie la relación en PostgreSQL. Logout cliente limpia su almacenamiento; no implementa blacklist ni refresh/revocación global. SEC-01 limita quién modifica identidad global y NO resuelve revocación dinámica.

Riesgo residual ALTO: un permiso ya emitido puede continuar vigente durante8h. También debe considerarse la diferencia entre cambiar contexto/estado en DB y lo que contiene el token vigente. No se reclasifica el riesgo como corregido ni se copia JwtStrategy vivo del P2 para ocultarlo. El usuario global inactivo sí se comprueba en cada request: prueba PostgreSQL y prueba UI401real. Cualquier mitigación global afecta la identidad completa y requiere autoridad ADMIN; este informe no ejecuta acciones productivas.

Se diferencia aislamiento estático A/B (filtros tenant e IDs404 probados), vigencia de autorización (snapshot) y revocación inmediata (no implementada). Las pruebas que antes esperaban401 por revocación viva no sustituyen la decisión arquitectónica actual. No se identificó un nuevo P0 en el candidato que contradiga esta política ratificada; no equivale a declarar producción sin riesgos.

Node20 sigue la decisión expresa de diferir la actualización inmediatamente después del cierre. RUN-01 del informe histórico permanece deuda de runtime fuera de soporte, no se borra ni se considera resuelto con overrides. Auditprod0 y ocho low de desarrollo reflejan únicamente la auditoría ejecutada, no una certificación general.

WEB-01 sigue separado: atestar SHA/configuración/deployment efectivo y smoke autenticado productivo requiere evidencia de proveedor/owner. La ejecución local usa secretos propios y no inspecciona ni modifica valores productivos. Si una revisión independiente determina P0 no aceptado, bloquear la operación afectada conforme a la autorización ampliada.
