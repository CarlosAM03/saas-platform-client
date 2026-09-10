# Reconciliación documental — Fase 5 Flutter Foundation

## 1. Veredicto

**DOCUMENTATION RECONCILED / READY FOR IMPLEMENTATION PLAN**

La documentación Flutter quedó alineada con ADR-004, OpenAPI y las decisiones cerradas de Fase 5. No se modificaron backend, OpenAPI ni código Flutter.

## 2. Archivos modificados

| Archivo | Acción | Motivo |
|---|---|---|
| `PlataformaFlutter/saas-platform-client/README.md` | Reemplazado | Eliminó decisiones obsoletas y documentó el baseline vigente. |
| `PlataformaFlutter/saas-platform-client/CONTRIBUTING.md` | Completado | Añadió ownership, Git flow, seguridad y reglas de contrato. |
| `PlataformaFlutter/saas-platform-client/FEATURE-DEVELOPMENT.md` | Actualizado | Eliminó DTO de persistencia no soportado y corrigió referencias a ADR-005. |
| `PlataformaFlutter/saas-platform-client/Docs/Flutter-Foundation.md` | Actualizado | Cambió `http` por Dio, cerró polling y eliminó decisiones antiguas. |
| `PlataformaFlutter/saas-platform-client/Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md` | Actualizado | Eliminó HTTP 402 y corrigió referencias documentales. |
| `PlataformaFlutter/Docs/DocsTeam/DistribucionResponsabilidadesEquipo.md` | Actualizado | Corrigió ownership de Carlos, André, Ángeles y Ángel. |
| `PlataformaFlutter/Docs/DocsTeam/ModeloArquitectonico.md` | Actualizado | Añadió nota de vigencia histórica/conceptual. |
| `PlataformaFlutter/Docs/DocsTeam/CONTEXTO_DEL_PROYECTO.md` | Actualizado | Añadió nota de vigencia. |
| `PlataformaFlutter/Docs/DocsTeam/ActaConceptual.md` | Actualizado | Añadió nota de vigencia. |
| `PlataformaFlutter/Docs/DocsTeam/RoadMapTentativo.md` | Actualizado | Añadió nota de vigencia. |
| `PlataformaFlutter/Docs/DocsTeam/DecisionesFase2.md` | Actualizado | Añadió nota de vigencia. |
| `PlataformaFlutter/Docs/DocsTeam/FormularioDecisionesFase4.md` | Actualizado | Añadió nota de vigencia subordinada a ADR-004. |

## 3. Archivos renombrados

| Antes | Después | Motivo |
|---|---|---|
| `PlataformaFlutter/Docs/ADRs/ADR-005-FlutterFundation.md` | `PlataformaFlutter/saas-platform-client/Docs/ADRs/ADR-005-FlutterFoundation.md` | Normalizar nombre y ubicar el ADR vigente dentro del repositorio cliente. |
| `PlataformaFlutter/saas-platform-client/Flutter-Foundation.md` | `PlataformaFlutter/saas-platform-client/Docs/Flutter-Foundation.md` | Alinear documentación normativa con `saas-platform-client/Docs`. |
| `PlataformaFlutter/saas-platform-client/LineamientosUI-UX.md` | `PlataformaFlutter/saas-platform-client/Docs/LineamientosUI-UX.md` | Alinear documentación del cliente. |
| `PlataformaFlutter/Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md` | `PlataformaFlutter/saas-platform-client/Docs/DocsTeam/FormularioDeDecisiones/FormularioDecisionesFase5.md` | Convertirlo en la fuente normativa del repositorio Flutter. |

`PropuestaDeDecisionesFase5.md` no fue creado. La propuesta previa quedó absorbida por `FormularioDecisionesFase5.md`.

## 4. Decisiones consolidadas

Quedaron normalizadas las siguientes decisiones:

- Dio encapsulado dentro de `ApiClient`.
- Dio limitado a `lib/core/network`.
- Features, providers y widgets no hacen HTTP directo.
- Repositories consumen `ApiClient`.
- Polling cerrado para MVP, inicialmente de 3 a 5 segundos.
- No WebSocket ni SSE.
- No workers ni background tasks en Flutter.
- No self-register público.
- No OAuth.
- No refresh token.
- Auth Foundation como único cierre funcional obligatorio.
- Campaigns, Prospects y ProspectingJobs como placeholders o mocks en Fase 5.
- Repositorio real: `PlataformaFlutter/saas-platform-client`.
- Android como primer target y Web compatible para demo.
- Ownership separado entre Carlos, André, Ángeles y Ángel.
- OpenAPI como autoridad contractual.
- ADR-004 como autoridad para autenticación, roles y tenant context.

## 5. Inconsistencias resueltas

| ID | Problema | Estado | Archivo corregido |
|---|---|---|---|
| R-01 | Conflicto `http`/`http_interceptor` frente a Dio | RESUELTO | `Docs/Flutter-Foundation.md` |
| R-02 | README con decisiones marcadas como no definidas | RESUELTO | `README.md` |
| R-03 | `CONTRIBUTING.md` vacío | RESUELTO | `CONTRIBUTING.md` |
| R-04 | Nombre inconsistente de ADR-005 | RESUELTO | `Docs/ADRs/ADR-005-FlutterFoundation.md` |
| R-05 | Referencias a `PropuestaDeDecisionesFase5.md` inexistente | RESUELTO | ADR-005 y Formulario F5 |
| R-06 | `PersistJobResultsRequest` no soportado por OpenAPI | RESUELTO | `FEATURE-DEVELOPMENT.md` |
| R-07 | HTTP 402 no definido en OpenAPI | RESUELTO | Formulario F5 y CONTRIBUTING |
| R-08 | Polling marcado como decisión pendiente | RESUELTO | `Flutter-Foundation.md` |
| R-09 | Ownership de Ángel sobre Flutter | RESUELTO | Distribución de responsabilidades |
| R-10 | Documentos históricos usados como autoridad vigente | RESUELTO | Documentos conceptuales e históricos |
| R-11 | Rutas documentales inconsistentes | RESUELTO | Documentación normativa movida a `saas-platform-client/Docs` |

## 6. Inconsistencias restantes

```text
No quedan inconsistencias bloqueantes conocidas.
```

Los documentos históricos conservan contenido conceptual antiguo, pero ahora incluyen una nota explícita de vigencia y no sustituyen ADR-004, OpenAPI, Formulario F5 ni ADR-005.

## 7. Validación contra OpenAPI

- No se modificó `platform-api.v1.yaml`.
- Se eliminó la referencia operativa a un DTO de persistencia no soportado.
- Se eliminó HTTP 402 de la documentación vigente.
- Se mantuvieron los endpoints Auth:
  - Login.
  - `/auth/me`.
  - Select tenant.
  - Logout.
- Se mantuvo la diferencia entre contrato definido y endpoint operativo.
- Se mantuvieron respuestas estándar, errores, paginación, `EmptySuccess`, exportación binaria, JWT sin refresh, `Idempotency-Key` y estados de job.

## 8. Validación contra ADR-004

- Se mantiene ADMIN global.
- Se mantienen OWNER y MEMBER como roles tenant-scoped.
- Se mantiene `currentTenantId` nullable.
- Se mantiene ADMIN sin tenant seleccionado.
- Se mantiene JWT sin refresh token.
- Se mantiene el backend como autoridad de autorización.
- Se mantiene el backend como autoridad de tenant isolation.
- Flutter no envía `tenantId` arbitrario como mecanismo de seguridad.

## 9. Recomendación siguiente

**Siguiente paso recomendado: crear Plan de Implementación Fase 5 Flutter Foundation.**