> Actualización 26-10-2026: conservar esta API tipada como única capa contractual. CSV UI y dashboard están implementados; Jobs sólo consulta/monitorea registros existentes. Mutaciones y exportación siguen sin integración Backend. Las respuestas exitosas futuras viven en x-target-responses del YAML y sus fixtures no prueban E2E. Ver [auditoría](../Auditorias/Auditoria_Reconciliacion_Dev_2026-10-26.md).

# Platform API Client

Backend de autoridad: `main@3a3309398458ab333d7b00f16e9c2df6a09ef734`. La copia `platform-api.v1.yaml` es idéntica al backend. Las pruebas contractuales recorren todos sus paths/métodos públicos; al actualizar backend hay que sincronizar esta copia y volver a ejecutar los tests.

## Arquitectura

Widget → provider/estado → interfaz de repository → API repository → PlatformApi → ApiClient → NestJS.

Dio permanece en `lib/core/network`. Los repositories reciben `PlatformApi` mediante providers. Cada lista/detalle depende de la sesión y tenant actual; un contexto nuevo, logout o 401 invalida el estado. Los formularios también se reinician al cambiar contexto.

Health, Auth, Tenants, Users, Campaigns, Prospects y ProspectingJobs están representados. Jobs create/cancel/persist/export conservan el contrato y propagan `503`, `error.code` y `error.details.reason=PROSPECTOR_INTEGRATION_PENDING`; no hay éxito simulado. Persist no envía body; create requiere Idempotency-Key; export devuelve bytes y metadata HTTP sin exponer Dio.

## Prospectos y CSV

`Prospect.source` usa `PersistedProspectSource` (`google_maps`, `manual`, `csv`). `ProspectingQuery`, `PipelineProgress` y `BusinessResult` usan `ProspectingSource` (`google_maps`). Los tipos impiden construir una query de motor con manual/csv y los parsers rechazan sources no contractuales.

`CreateProspectRequest` acepta campaignId, name y los opcionales contractuales; nunca tenantId/source/sourceIdentifier. Los PATCH nullable usan `FieldUpdate.omitted()` para conservar y `FieldUpdate.set(null)` para limpiar. La UI de edición sólo envía campos modificados; metadata conserva soporte completo en PlatformApi y se muestra como lectura simple en detalle.

```dart
final upload = ApiUploadFile(filename: 'prospects.csv', bytes: originalBytes);
final preview = await api.prospects.previewImport(campaignId: id, upload: upload);
final result = await api.prospects.confirmImport(
  campaignId: id, upload: upload, previewReference: preview.previewReference,
  decisions: const [ProspectImportDecision(record: 1, action: ProspectImportAction.CREATE)],
);
```

`ApiUploadFile` conserva una copia inmutable de bytes. Cada request crea multipart nuevo dentro de ApiClient; preview y confirm reutilizan exactamente los bytes. Los modelos tipan summary, rows, errors, matches, campaignIds, sharedWithOtherCampaigns y differences, así como resultados/rechazos. Las decisiones admiten CREATE/LINK_EXISTING/UPDATE_EXISTING/SKIP. Backend valida clasificación, expiración, concurrencia y deduplicación.

HTTP 413 tiene `ApiErrorKind.payloadTooLarge` y mensaje específico de 5 MB. Se preservan 400/401/403/404/409/429/503 y sus detalles. Un 400 por preview inválido/expirado y 409 por snapshot obsoleto deben provocar nuevo preview en la futura UI.

CSV PlatformApi está implementado. CSV UI/file picker/wizard se difieren deliberadamente. No se agregó dependencia de selección de archivo.

## Validación

`flutter test` cubre contratos, requests/responses, wrappers, pagination, multipart, enum split, omission/null, permisos y features.

P2C usa exclusivamente el backend Docker local y su seed oficial. Desde backend: `docker compose up --build -d`. Desde el cliente:

```powershell
flutter test tool/platform_api_p2c_test.dart --dart-define=P2C_BASE_URL=http://localhost:3000 --dart-define=P2C_PASSWORD=DevOnlyPass123!
```

Rechaza hosts no locales y HTTPS; no se ejecuta contra Render, shared-dev o producción. Verifica health/Auth, tenants list/detail/create/switch, Users create/read/update/deactivate, Campaign CRUD/archive, manual source, CSV preview/confirm y consulta persistida source=csv, así como Jobs list/detail. El archivo CSV se crea en memoria y se reutiliza sin transformación.

El seed heredado guarda `query.source="demo"` en algunos Jobs; P2C conserva la comprobación de `FormatException` y usa una fixture contractual temporal para leer un detalle válido. No modifica el seed ni archivos backend. El `finally` borra sólo IDs creados por esa ejecución mediante el mecanismo SQL local existente; no deja campañas demo nuevas ni borra datos ajenos.

El backend se localiza por defecto en `../../Backend_Nestjs/saas-platform-backend` desde el path real del cliente; `P2C_BACKEND_DIR` permite indicar el checkout local.
