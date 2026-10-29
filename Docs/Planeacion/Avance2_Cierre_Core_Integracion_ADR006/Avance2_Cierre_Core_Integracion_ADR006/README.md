# Paquete de auditoría y preparación del Segundo Avance — PROSPECTOR SaaS

**Corte de referencia:** 28 de octubre de 2026.  
**Formato:** todos los documentos del paquete son Markdown (`.md`).  
**Alcance:** diagnóstico del Core Flutter `main`, decisiones de recepción e integración de ADR-006, ruta de QA/rollback y trabajo posterior a la presentación.

## Orden de lectura

1. **`01_AUDITORIA_ESTADO_ACTUAL_CORE_V1.md`** — estado real, hallazgos, explicación de Users ACME, roles y riesgo residual.
2. **`04_REGISTRO_EVIDENCIAS_CAPTURAS_PRODUCCION.md`** — diez capturas, resultados visibles y límites de inferencia.
3. **`02_PLAN_DECISIONES_QA_INTEGRACION_ADR006.md`** — decisiones pendientes, auditoría del PR de Ángel, E2E, gates, orden de merge y rollback.
4. **`03_PLAN_TRABAJO_POST_AVANCE2.md`** — backlog priorizado según se presente Core solo o Core más ADR-006.

## Versiones de referencia

- Frontend `main`: `e752f6ca692d2840263cd9e59e0927c56aa129ec`.
- Backend `main`: `b51b265f1a545fa915f1dd1c57ef2f5858ec6492`.
- PR estabilización Flutter: https://github.com/CarlosAM03/saas-platform-client/pull/10.
- ADR-006 aprobado y OpenAPI futuro: `Docs/ADRs/ADR-006-TenantRegistration-APROBADO.md` y `Docs/Contracts/platform-api.tenant-registration.approved.yaml` del repositorio Flutter al corte.

Estos documentos **no autorizan cambios de producción**, no constituyen evidencia de que ADR-006 haya sido implementado y distinguen comprobaciones de código, pruebas registradas, observaciones visuales y propuestas todavía pendientes de aprobación.

## Protección de evidencias

No se incluyen capturas PNG originales, credenciales, JWT, email de administradores, prospectos reales ni volcados de PostgreSQL. Las imágenes compartidas contienen información de contacto de negocios y se mantienen únicamente como referencia privada de la conversación; su análisis agregado está en el Documento 04.
