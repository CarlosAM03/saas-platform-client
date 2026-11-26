# Matriz de aislamiento y RBAC

FechaUTC:2026-10-28T00:23:34.968Z. Backend dev09593bb715cd83270821d34126a4344c8ef97cb0, Flutter devcd527ef12bc7c1327ed9a8520e1a07f0fc8be39f. Fuentes: guards/controladores baseline y pruebas JSON referenciadas en G2.

| Operación | ADMIN con contexto | OWNER | MEMBER | Evidencia |
|---|---|---|---|---|
| Descubrir tenants | Global autorizado | Sus membresías activas | Sus membresías activas | HTTP/runtime/UI |
| Crear tenant | Sí |403 |403 | HTTP/contrato |
| Leer usuarios | Sí |Sí |Sí | Runtime real; MEMBER no es solo lectura global |
| Crear/editar usuarios | Sí |Sí, sujeto SEC-01 |403 | HTTP/PG/runtime |
| Desactivar mediante DELETE user | Sí |403 |403 | HTTP/SDK |
| Crear/editar/archivar campaña | Sí |Sí |Sí | Runtime MEMBER y HTTP |
| Borrado permanente campaña | Sí |403 |403 | HTTP/SDK |
| Leer/editar prospectos | Sí |Sí |Sí | HTTP/runtime/UI |
| Alta manual de prospecto | Sí |Sí |403 | HTTP/SDK/feature tests |
| CSV preview/confirm | Sí |Sí |403 | PG/runtime/UI |
| Jobs GET | Sí |Sí |Sí | Runtime/UI |
| Generación/cancel/persist/export core |503 tras validar |503 tras validar |503 tras validar | Capabilities UIfalse; runtime |

ADMIN sin tenant no puede consumir colecciones que exigen contexto; runtime devuelve403 hasta seleccionar organización. OWNER A no lee prospecto B; OWNER B no lee campaña A:404. Listados y búsqueda usan contexto; no existe header de tenant que suplante al JWT. Una importación de campaña ajena devuelve404.

SEC-01: OWNER ajeno a identidad ADMIN o a identidad compartida recibe403 al editar identidad/password/status, sin cambios parciales de rol; cambio de rol local permitido y no cambia el de B. Self-edit/local/global ADMIN permanecen legítimos. Snapshot conserva autorización previa8h: ver RIESGOS_JWT_SNAPSHOT.md.

UI real: cinco cuentas y campañas A/B sin mezcla, logout y rutas protegidas; prueba adicional ADMIN A→B y401real en core-session-tenant-ui.json. Widget suites prueban invalidación de formularios/diálogos, respuestas tardías, token replacement y cambios de scope con fixtures controlados; no se presentan como retardos inyectados en producción.

B tiene otra base y prueba GETJob ajeno404, campaña ajena404 y autenticación interna/replay sin exponer claves al navegador. La pérdida del worker no altera core: conteos antes/después idénticos2/5/7/38/10.
