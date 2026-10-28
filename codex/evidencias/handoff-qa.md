# Handoff QA — candidato Flutter Core V1

FASE / GATE: P0–P5 ejecutadas dentro de autorización. Propuesta revisable, sin aceptación automática.

REPOSITORIO / RAMA / SHA: CarlosAM03/saas-platform-client, sprint/frontend-core-v1-parity. Base7731649; código probado 7b5320c2a61e2f4170f23f5637cf630a9902de7d. Backend main b51b265f1a545fa915f1dd1c57ef2f5858ec6492 en solo lectura. PR: https://github.com/CarlosAM03/saas-platform-client/pull/10, base main, Draft, sin merge.

ALCANCE REAL: FE-01/02/03 y regresiones adicionales de restauración y dashboard corregidos; Auth/Tenants/Users/Campaigns/Prospects/CSV/Dashboard/Jobs auditados contra33 operaciones Core. P2C, dos corridas32/32, seis negativos HTTP_SQL, build/contenedores/CI y smoke remoto de lectura ejecutados.

ARCHIVOS / CAMBIOS: formularios Users con PATCH diferencial; SelectTenant ADMIN; TenantPermissions desde claims de presentación por excepción del owner; router conserva URI durante restauración y la descarta al terminar sesión; dashboard parcial y Jobs tipados; ErrorMapper seguro. Fixtures/pruebas/tooling y documentación correspondientes. Contrato Core y Backend permanecen intactos; ADR-006 se adjunta como referencia futura por instrucción del owner.

| Gate | Estado | Evidencia / condición |
|---|---|---|
| G0 | PASS | baseline,remotos main,33 operaciones,Swagger local1.0.0 e identidad de imágenes |
| G1 | PASS | 279 pruebas,analyze,generación,Web,Docker y tres checks CI de código |
| G2 | BLOCKED | P1 cerrados y casos contractuales válidos PASS; owner debe decidir diferimiento de FE-04 y FE-07 P2 |
| G3 | PASS | 32/32 en dos runs,6 negativos,SQL/recarga/cleanup y seed intacto |
| G4 | BLOCKED | smoke autorizado PASS; SHA servidos Vercel/Render sin correlación completa |
| G5 | PASS | rama/PR y cierre documental completo,puestos a revisión; no implica merge |
| G6 | NOT RUN | ADR-006 inventariado,fuera de este carril |

PRUEBAS: [resultados](test-resultados.md), [baseline](test-baseline.md), [CI](ci-results.json), [matriz Core](matriz-modulos-core.md), [contratos](matriz-contrato-1a1.md), [escenarios](matriz-e2e.md). Los JSON conservan scope y no equiparan HTTP_SQL con UI_TO_DB.

E2E LOCAL: [run1](e2e-local.json), [run2](e2e-repeat.json), [negativos](api-negative.json), [resumen SQL](e2e-local-resumen.md), [identidades](runtime-identities.json). Roles ADMIN/OWNER/MEMBER, tenants exclusivos A/B e identidad compartida. Alta V1 con User+UserTenant+Role, carrera de dos formularios201/409, SEC-01, cuatro decisiones CSV y comprobación posterior a recarga. Cleanup exclusivo por run y checksum completo de seed PASS.

REMOTO: [resumen](remoto-resumen.md), [UI](remote-ui.json), [público](remote-smoke.json). URL exacto del owner, CORS y API origin comprobados. Credenciales, cuenta, IDs y negocio excluidos. Sin SQL ni escrituras de negocio productivas.

HALLAZGOS / RIESGOS: [registro](hallazgos.md). FE-04: roleId soportado por API no expuesto como selector UI; no hay catálogo de roles nuevo autorizado. FE-07: seed de Jobs query.source=demo fuera de enum público; se conserva señal y se prueba fixture válida. Recomendación: diferir ambos P2 expresamente y corregir seed en línea Backend separada; alternativa: ampliar alcance con aprobación, sin mezclar ADR-006. JWT snapshot8h conserva riesgo ALTO aprobado; presentación no es revocación ni verificación de firma.

DECISIONES DEL OWNER: revisar/diferir P2; correlacionar revisiones servidas con metadatos de hosting; revisar PR y autorizar aceptación/merge. No se declara sprint aceptado ni producción validada mientras G2/G4 sigan BLOCKED.

REPRODUCCIÓN: [tool/sprint/README](../../tool/sprint/README.md). Iniciar el stack exclusivo, ejecutar P2C y E2E en secuencia, luego negativos; conservar backend/main verificado. El stack quedó detenido sin borrar volúmenes. No usar down -v sobre datos compartidos.

ROLLBACK PROPUESTO: antes de integración no hay cambio productivo que revertir. Si posteriormente el owner integra y detecta una regresión, preparar un PR de revert de los commits de aplicación y volver al último artefacto aprobado mediante su proceso de release. No requiere revert de migraciones de este sprint; no se hicieron. No se ejecutó rollback, merge ni despliegue.

SIGUIENTE TAREA SEGURA: revisión humana del PR y de sus gates, después la integración ADR-006 por el carril de Ángel. El commit final documental incluye el harness completo, estos resultados y las dos referencias aprobadas aportadas durante la ejecución.
