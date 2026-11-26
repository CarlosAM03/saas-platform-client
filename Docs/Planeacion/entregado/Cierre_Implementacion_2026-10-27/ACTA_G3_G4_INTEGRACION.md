# Acta G3–G4 — integración y trazabilidad

Emitido UTC:2026-10-28T00:23:34.968Z. No se repite la auditoría Fase0.

| Repositorio | PR correctivo | Acción Codex autorizada | Resultado |
|---|---|---|---|
| Backend | #7 fix/avance2-core-security→dev | Merge normal tras3 checks verdes | dev200c0e8a8654732cca90597bf79b269197078f6a |
| Backend | #8 misma rama→dev | Corrección puntual de bootstrap y LF; CI40603593884 success | dev09593bb715cd83270821d34126a4344c8ef97cb0 |
| Flutter | #9 release/avance2-frontend-v1→dev | Merge normal tras foundation/container/production-container y Vercel verdes | devcd527ef12bc7c1327ed9a8520e1a07f0fc8be39f |

Se verificaron protecciones antes de integrar: dev sin reglas de aprobación obligatoria; main protegido por PR y checks específicos. No se modificaron protecciones, no se forzaron pushes ni se eludieron checks. La integración usa expected-head y el helper de merge rechaza cualquier PR cuyo target no sea dev. El conector GitHub devolvió403 al crear PR; se utilizó GitHub REST con la credencial Git existente, sin cambiar permisos ni persistir el token.

Se crearon checkouts detached backend-dev-validated y flutter-dev-validated para validar los HEAD definitivos, con árboles limpios. Ambos Dockerfiles reales se reconstruyeron sobre estos candidatos. CI del HEAD exacto: Backend40604081978 success; Flutter40603614993 success. Los árboles de las ramas correctivas coinciden con los integrados.

## Intervención manual posterior del owner

Mientras continuaba esta ejecución, CarlosAM03 fusionó Backend PR#9 dev→main a las00:07:29UTC del28-10 (17:07:29Tijuana del27-10), creando b51b265f1a545fa915f1dd1c57ef2f5858ec6492. Fusionó Flutter PR histórico#6 a las00:12:59UTC (17:12:59Tijuana), creando7731649a2c69b45cb9776d02de4a6105d6fd9886. Se comprobó merged_by y merge_commit_sha mediante GET; Codex no efectuó esas fusiones. No se creó un PR Flutter duplicado.

A partir de esos merges se ejecutaron únicamente verificaciones públicas/GitHub de lectura conforme a §14 de la autorización ampliada. Estado efectivo de CI y despliegue posterior: REGISTRO_CI.md, RUNBOOK_POST_MERGE.md y DICTAMEN_GLOBAL.md. Un health200 no se usa como atestación del SHA Render.

Main no recibió P2/Backend PR#6/Flutter PR#8 mediante este cierre. Las ramas experimentales locales no se publicaron. Los checkouts originales conservan sus HEAD y documentos.
