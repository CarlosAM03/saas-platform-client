# Handoff y futuro arnés de André — obligación de Ángel

**Este directorio NO es todavía el arnés de frontend listo para ejecutar.** Su contenido define cómo producirlo **después del backend**, con el contrato y SHA que realmente se implementen. La responsabilidad del segundo arnés es de Ángel, con aceptación del owner. No modificar Flutter mediante este paquete inicial.

## Contenido mínimo del nuevo arnés frontend

1. `README.md` y `PROMPT_ACTIVACION.txt` autónomos, para instalación en `saas-platform-client/codex/<nombre-sprint-frontend>/` sin tocar otras evidencias.
2. **Contratos de verdad**: OpenAPI/Swagger correspondiente al backend versionado (SHA exacto), matriz de `method/path/request/response/errors/roles/tenant/availability` y ejemplos sintéticos. Diferenciar contract-only, 503 y AVAILABLE.
3. **Objetivos visuales**: C1/C2/C3/C4/C6/C8/P1/P2/P3/P4; aprovechar tabs Detalle/Prospectos, módulos existentes, importador y dashboard global sin sustituirlo.
4. **Flujos de usuario**: paso por paso para etapa/evaluación/responsable/actividad; preview/resolve/confirm manual y CSV; conflictos/actualización maestra compartida; P2/P3 y dashboard campaña.
5. **Reglas Flutter**: solo API NestJS; Riverpod/proveedores, repo por feature, `lib/platform_api` tipada y ApiClient; respetar sessionScope/tenant; estados loading/empty/error; UI accesible.
6. **Carpetas protegidas** según `FEATURE-DEVELOPMENT.md`: sin editar `lib/app`, `lib/core/network`, `lib/routes`, `lib/features/auth` ni modelos base protegidos sin autorización puntual del owner. Ante ruta nueva, escalar con alternativa y pruebas.
7. **Pruebas**: widget/state, filtros/paginación, roles, aislamiento de sesión, errores 409/400, CSV existentes y T32 UI→backend real contra entorno sintético; mocks solo etiquetados para desarrollo visual.
8. **Gates**: baseline de Flutter autorizado por owner; SHA de backend requerido; implementaciones UI con contrato real; QA/E2E; PR Flutter para revisión owner. Nada de merge/deploy automáticos.
9. **Evidencias**: resumen de archivos, pruebas con SHA, capturas sintéticas, no datos reales o secretos, límites observados y problemas abiertos.
10. **Plan de reconciliación** entre el contrato preliminar (si André ya maquetó) y el real final; los mocks no sustituyen un backend implementado.

## Fuente de verdad

El contrato no se deduce únicamente del SPEC ni de este archivo: leer OpenAPI generado/servido, código y tests en el SHA del backend final. Referenciarlo y mantenerlo inmutable. Si hay drift entre backend y SPEC, registrar qué hizo Ángel, quién lo aprobó y el impacto al frontend; no autorizar automáticamente un cambio de negocio por estar implementado.

## Entrega de artefactos

Ángel puede generar el ZIP frontend **cuando cierre G4 y documente G5**. Registrar SHA256, tamaño, estructura, instrucciones de instalación y enlace de entrega en `05_EVIDENCIAS/G5/HANDOFF.md`. El owner decide cuándo André puede usarlo y sobre qué base Flutter trabaja.
