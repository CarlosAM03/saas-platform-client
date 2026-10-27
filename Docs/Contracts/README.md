# Contrato Platform API V1

Contrato reconciliado el 26-10-2026 con el código de Backend **dev 967044e2dc7d10ea91d7d78a86e1ea6fe2accd1a**. Main **3a3309398458ab333d7b00f16e9c2df6a09ef734** sigue siendo el baseline, pero no contiene aún la implementación CSV de dev. El YAML conserva DTOs compatibles y distingue respuestas actuales de Jobs (503) de sus respuestas objetivo en x-target-responses. No se presenta como copia exacta del YAML de main. Backend sigue siendo autoridad; API_V1_AUDIT.md se conserva como histórico.

Flutter sólo consume NestJS mediante Bearer JWT. No accede a PostgreSQL, Prospector Service, Engine ni callbacks internos. El tenant operativo deriva del contexto autenticado.

PlatformApi cubre todos los paths/métodos públicos del YAML, incluidas creación manual y CSV preview/confirm multipart. PersistedProspectSource separa `google_maps|manual|csv` de ProspectingSource, que sólo admite `google_maps`.

Tenants, Users, Campaigns, Prospects, CSV UI y dashboard tienen clientes de API reales. Jobs UI consulta registros y hace polling sin solapamiento; Prospector sigue pendiente. Jobs create/cancel/persist/export siguen propagando 503 con `PROSPECTOR_INTEGRATION_PENDING`.

La guía de uso y validación está en [Platform_API_Client.md](Platform_API_Client.md). No se inventan endpoints, roles IDs, analytics ni semántica de persistencia en Flutter.

## Cierre v1.0.0 — 27 octubre2026

La autoridad es el documento servido por Backendmain1.0.0. Jobs admite solo lectura: resultsAvailable=false y results/progress=null. Las operaciones objetivo en x-target-responses no están habilitadas. No existe SnapshotPG ni TTL de resultados en core. La demo visual no usa SDK/red/datos de negocio.
