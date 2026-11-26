# Matriz de cumplimiento funcional por rol

Contrato vigente: Backend `590aaf0` · Frontend probado: `465b788` (+ evidencia `48e80e8`).

| Superficie | ADMIN | OWNER | MEMBER | Control en UI | Verificación |
|---|---|---|---|---|---|
| Dashboard del tenant | Sí, con organización activa | Sí | Sí | `currentTenantPermissionsProvider` | Laboratorio PASS (3 roles) |
| Métrica/panel de lotes | Solo con organización activa | Sí | No | `canCreateProspects` + flag batch | Laboratorio PASS; batch-mode test PASS |
| Buscar prospectos / generar lote | Sí, con organización activa | Sí | No | `canCreateProspects` | Laboratorio: OWNER PASS, MEMBER denegado sin solicitudes |
| Historial y detalle de lotes propios | Sí | Sí | No | `canCreateProspects`; API por tenant/usuario | Navegación/error PASS; historial real requiere Service |
| Revisar, confirmar y exportar lote | Sí | Sí | No | Detalle Batch v1 | Tests de contrato/fixtures PASS; E2E con Service NOT_RUN |
| Campañas: listar, crear, editar, archivar | Sí | Sí | Sí | `canManageCampaigns` | Laboratorio PASS lectura; escrituras NOT_RUN |
| Eliminar campaña permanentemente | Sí | No | No | `canDeleteCampaigns` | Estático; no ejecutado |
| Prospectos: listar, detalle, editar | Sí | Sí | Sí | `canEditProspects` | Laboratorio PASS lectura |
| Alta manual / importación CSV | Sí | Sí | No | `canCreateProspects` | Alta directa denegada a MEMBER PASS; escrituras NOT_RUN |
| Usuarios: listar/detalle | Sí | Sí | Sí | Backend + ruta tenant | ADMIN PASS listado |
| Usuarios: crear/editar | Sí | Sí (solo MEMBER de su tenant) | No | `canManageUsers` | Estático; no ejecutado |
| Desactivar usuario | Sí | No | No | `canDeactivateUsers` | Estático; no ejecutado |
| Organizaciones: listar/consultar | Sí | Accesibles | Accesibles | Backend | ADMIN PASS |
| Registrar organización + primer OWNER | Sí | No | No | `canCreateTenants` | Render PASS; alta real/correo NOT_RUN |
| Onboarding: consultar/reenviar | Sí | No | No | `canCreateTenants` | Estático; NOT_RUN |
| Activación pública `#/activate` | Público con token válido | — | — | Enlace de un solo uso | NOT_RUN (requiere correo real) |

Reglas permanentes: el Backend autoriza cada operación aunque la UI oculte una acción; un 403/404 se muestra sin filtrar datos de otro tenant. `MEMBER` no recibe solicitudes batch ni CTAs incompatibles. La aceptación productiva se registra aparte.
