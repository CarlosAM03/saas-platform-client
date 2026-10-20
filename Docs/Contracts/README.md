# Contrato Platform API V1

`platform-api.v1.yaml` es una copia exacta del contrato público de backend/main `3a3309398458ab333d7b00f16e9c2df6a09ef734`. Backend es autoridad; sincronizar su YAML antes de ampliar DTOs/clientes. `API_V1_AUDIT.md` se conserva como histórico.

Flutter sólo consume NestJS mediante Bearer JWT. No accede a PostgreSQL, Prospector Service, Engine ni callbacks internos. El tenant operativo deriva del contexto autenticado.

PlatformApi cubre todos los paths/métodos públicos del YAML, incluidas creación manual y CSV preview/confirm multipart. PersistedProspectSource separa `google_maps|manual|csv` de ProspectingSource, que sólo admite `google_maps`.

Tenants, Users, Campaigns y Prospects no-CSV tienen features API reales. CSV UI, Jobs UI, Prospector y caché/polling quedan diferidos. Jobs create/cancel/persist/export siguen propagando 503 con `PROSPECTOR_INTEGRATION_PENDING`.

La guía de uso y validación está en [Platform_API_Client.md](Platform_API_Client.md). No se inventan endpoints, roles IDs, analytics ni semántica de persistencia en Flutter.
