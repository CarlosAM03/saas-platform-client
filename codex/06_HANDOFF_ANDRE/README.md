# Arnés de handoff backend → frontend (sprint CP)

**Estado: `LISTO_PARA_REVISION`.** G4 fue aceptado por el owner el `2026-11-23` sobre el candidato `3b5eec6fa99f846e853794fc8aedff2c4353c269`. Este arnés **no** está aprobado para uso: el owner decide cuándo André lo adopta y sobre qué base Flutter.

## Qué es

Paquete contractual para que André extienda el cliente Flutter existente con C1/C2/C3/C4/C6/C8/P1/P2/P3/P4 **desde el contrato realmente implementado**, no desde el SPEC supuesto.

- Backend: `feat/sprint-campana-prospector` @ `3b5eec6fa99f846e853794fc8aedff2c4353c269`.
- Contrato servido: `openapi-served-3b5eec6.json` (162 688 bytes; SHA256 `e73bb1e924a1e956d20567768e63861552d9799c51170257b1098f424384e14c`), mismo documento que expone `GET /api/docs-json`.
- Regresión atribuida al SHA: build PASS, 178 unitarias, 84 HTTP y 199 PostgreSQL (461 pruebas) en árbol limpio.

## Contenido

| Archivo | Uso |
|---|---|
| `README.md` | Este índice y reglas de instalación. |
| `PROMPT_ACTIVACION.txt` | Prompt reproducible para el agente frontend. |
| `01_PLANTILLA_HARNESS_FRONTEND.md` | Plantilla histórica; el contenido real está en los demás archivos. |
| `02_MATRIZ_API_FLUTTER.csv` | 25 operaciones con disponibilidad, roles, request/response, errores, ejemplo, pantalla y prueba. |
| `03_CONTRATO_IMPLEMENTADO.md` | Autenticación/tenant, envoltura, paginación y semántica por feature. |
| `04_OBJETIVOS_Y_FLUJOS.md` | Objetivos visuales y flujos paso a paso. |
| `05_REGLAS_FLUTTER_Y_PRUEBAS.md` | Arquitectura, carpetas protegidas y plan de pruebas (incluye T32). |
| `06_RUNBOOK_QA_SINTETICO.md` | Cómo levantar el backend sintético y ejecutar T32. |
| `openapi-served-3b5eec6.json` | Documento OpenAPI servido, inmutable para este handoff. |

## Instalación (cuando el owner lo autorice)

1. Copiar esta carpeta a `saas-platform-client/codex/<nombre-sprint-frontend>/`.
2. No modificar otras evidencias ni carpetas del arnés existente.
3. Confirmar la base Flutter autorizada (rama y SHA) antes de escribir código.
4. Ejecutar `PROMPT_ACTIVACION.txt` con el agente frontend.

## Orden de lectura recomendado

1. `03_CONTRATO_IMPLEMENTADO.md`
2. `02_MATRIZ_API_FLUTTER.csv`
3. `04_OBJETIVOS_Y_FLUJOS.md`
4. `05_REGLAS_FLUTTER_Y_PRUEBAS.md`
5. `06_RUNBOOK_QA_SINTETICO.md`

## Reglas que no se negocian

- Sólo API NestJS a través de `lib/platform_api`; nada de HTTP suelto en pantallas.
- Respetar `sessionScope`, tenant del JWT y carpetas protegidas (`lib/app`, `lib/core/network`, `lib/routes`, `lib/features/auth`).
- No inventar campos ni rutas: lo que no está en el contrato no existe.
- `CORRECTION` es actividad manual; `MASTER_UPDATE` está documentado pero hoy **no** se emite; `MASTER_UPDATED` es procedencia, no actividad.
- Sin datos reales, secretos ni tokens en evidencias.
- PR Flutter para revisión del owner; sin auto-merge ni deploy.

## Pendientes y riesgos

- **T32 `NOT_RUN`**: E2E real UI→API lo ejecuta el frontend; el backend no puede declararlo.
- Base Flutter y momento de uso: decisión del owner.
- G5 queda en preparación; G6 (revisión del owner) sigue pendiente.
- Cualquier commit posterior del backend que no sea documental invalida la atribución de este arnés y exige regenerarlo.
