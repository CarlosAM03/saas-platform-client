# Paridad por módulo y autoridad de permisos

Complementa matriz-contrato-1a1.md (33 operaciones) y las matrices de ejecución. Las autorizaciones provienen de Controllers/Services/Guards de Backend main b51b265, no de etiquetas UI.

| Módulo | Pantalla → repository → PlatformApi | Regla implementada / límite | Cobertura |
|---|---|---|---|
| Auth | Login/SelectTenant → AuthRepository → AuthApi/ApiClient | JWT normal8h; login público; me/select/logout autenticados;401 limpia sesión vigente,403 conserva sesión | Foundation,regresiones,P2C,AUTH*,smoke remoto |
| Tenants | TenantsPage/TenantCreatePage → ApiTenantsRepository → TenantsApi | ADMIN discovery global aun con membership; crear ADMIN sin onboarding implícito; otros listan accesibles | TEN*,ADMIN-DISCOVERY,unit/contrato/P2C |
| Users | Users/UserForm → ApiUsersRepository → UsersApi | Leer ADMIN/OWNER/MEMBER; crear/editar ADMIN/OWNER; MEMBER por defecto al omitir roleId; DELETE desactiva solo ADMIN; SEC-01 global | USR*,DTO/contrato,SQL User+UserTenant+Role,recarga |
| Campaigns | Campaigns/Detail/Form → ApiCampaignsRepository → CampaignsApi | ADMIN/OWNER/MEMBER gestionan; DELETE archiva; permanent=true solo ADMIN; filtro de estado local a página | CAM*,CRUD,estado,SQL,recarga;unit/paginación |
| Prospects | Prospects/Detail/Form → ApiProspectsRepository → ProspectsApi | Alta manual ADMIN/OWNER; edición también MEMBER; null limpia y omitted conserva; aislamiento de campaña/tenant | PRO*,SQL/source/relación,404 cruzado,unit/contrato |
| CSV | ProspectImportPage → ProspectImportRepository → ProspectsApi multipart | ADMIN/OWNER; bytes originales; nombre normalizado determina MATCH;CREATE/LINK_EXISTING/UPDATE_EXISTING/SKIP;validación/snapshot/15min/5MB | CSV* UI+SQL,negativos HTTP_SQL,contratos/unit |
| Dashboard | DashboardPage → ApiDashboardRepository → campaigns/prospects/jobs.list | meta.total real; Jobs fallido muestra sección parcial sin inventar cero; fallo crítico mantiene error general | DASH-SQL-TOTALS y widgets FE-05/FE-10 |
| Jobs | Jobs/Detail → ApiProspectingJobsRepository → ProspectingJobsApi | GET list/detail reales;create/cancel/persist/export503 después de validar;export exige format;query.source google_maps | JOBS*,P2C,contrato y smoke remoto |

Prospects no tiene DELETE público en V1; no se inventa una operación para completar literalmente un CRUD inexistente. La paridad cubre las capacidades implementadas de alta/consulta/edición.

## Diferencias deliberadas de contrato

El YAML objetivo Backend no equivale a disponibilidad. deployment-document.ts limita cuatro operaciones Jobs a503 y precisa consultas. Flutter conserva éxitos futuros en x-target-responses. La comparación JSON registra una diferencia de parámetros de GET Jobs (sortBy permitido por implementación) y de ProspectingJobDetail (resultados/progreso efectivos nulos). Son diferencias revisadas contra código/Swagger, no endpoints agregados ni una sincronización ciega.

Los mocks de unidad/contrato comprueban serialización/errores/UI aislada. P2C y los JSON UI_TO_DB/HTTP_SQL acreditan su alcance real por separado.
