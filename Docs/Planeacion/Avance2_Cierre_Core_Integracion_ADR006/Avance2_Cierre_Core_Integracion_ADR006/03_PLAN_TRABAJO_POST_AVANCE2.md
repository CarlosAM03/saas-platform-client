# ROADMAP-AV2-03 — Trabajo posterior a la presentación del Segundo Avance

**Proyecto:** PROSPECTOR SaaS. **Fecha:** 28 de octubre de 2026 (Tijuana).  
**Estado:** backlog propuesto y priorizado; **no es autorización de implementación ni modificación unilateral del ADR-006**.  
**Punto de partida:** presentar Core 1.0.0 o Core + primer onboarding OWNER según gates del `02_PLAN_DECISIONES_QA_INTEGRACION_ADR006.md`.

## 1. Objetivo del siguiente ciclo

Convertir el incremento demostrado en un producto operable, seguro y extensible, sin prometer capacidades de pago o automatización que todavía no forman parte del release. La siguiente etapa se ordena por riesgos reales de autorización, integridad, ciclo de vida de identidades y automatización del despliegue, no por cantidad de pantallas.

## 2. Dos puntos de arranque posibles

| Resultado del Avance 2 | Primer trabajo después de presentar | Qué se conserva |
| --- | --- | --- |
| **A — Se mostró Core 1.0.0** | Resolver cualquier defecto P1, terminar PR Backend ADR-006 y Flutter de onboarding, QA E2E y rollout controlado | El Core sigue funcionando sin nuevo módulo; no mezclar Prospector Service |
| **B — Se mostró Core + ADR-006** | Cierre operacional del onboarding, invitación/vinculación MEMBER y controles de rol, mejoras UX y evidencia de release | Las cinco operaciones ADR-006 se mantienen bajo contrato; nuevas capacidades requieren ADR nuevo |

**Ambas rutas comparten la prioridad de resolver definitivamente Users ACME y la semántica de roles/membresías.** Si se resuelve antes de la presentación, se marca cerrado con evidencia; no se vuelve a programar artificialmente.

## 3. Prioridad 0 — Primer ciclo de mantenimiento tras la presentación

| ID | Trabajo | Justificación | Dependencias / salida |
| --- | --- | --- | --- |
| POST-P0-01 | Cierre de incidente Users ACME | Una lista con `FormatException` no es aceptable como capacidad operativa | Causa HTTP/DTO/DB; regression Flutter+Backend, smoke A/B, no fuga |
| POST-P0-02 | Endurecer asignaciones OWNER/MEMBER | DTO permite OWNER por actor OWNER; falta unicidad efectiva | Tests de permisos POST/PATCH, 1 OWNER por tenant, concurrencia, transferencia futura diseñada |
| POST-P0-03 | Semántica de desactivación | Identidad global y membresía tenant-local no deben confundirse | Política ADMIN global vs OWNER local, pruebas SEC-01 y usuarios compartidos |
| POST-P0-04 | Verificación de migración/cuentas pendientes | Reversión de código no debe reabrir acceso ni bloquear cuentas | Versiones compatibles, política de rollback de Auth/flag y backup |
| POST-P0-05 | Revisión de datos actuales | Detectar inconsistencias de rol/identidad sin alterar producción | SQL read-only autorizado; reporte de anormalías, estrategia de saneamiento separada |
| POST-P0-06 | Consolidar evidencias de release | Correlación operacional de Backend/Frontend y artefactos | SHAs, IDs de despliegue, fecha, estado de feature flag, smoke |

Un P0 abierto puede exigir hotfix independiente y no debe esperar a nuevas funcionalidades.

## 4. Prioridad 1 — Accesos e invitaciones multi-tenant

**Objetivo:** administrar MEMBERS con la misma disciplina de seguridad que el primer OWNER, pero sin fingir que ADR-006 ya define ese alcance.

### 4.1. Nuevo ADR de membresías e invitaciones

Debe fijar, al menos:

- `ADMIN` como operador global; OWNER solo administra su organización y no puede conceder OWNER.
- Un OWNER por tenant comercial, con reglas de titularidad, transferencia y recuperación ante ausencia del titular.
- Alta/invitación MEMBER por OWNER o ADMIN según permisos, **sin contraseñas enviadas por correo**. Destinatario valida enlace y establece su contraseña si es identidad nueva.
- Usuario existente: invitación para **añadir `UserTenant` sin duplicar `User` ni cambiar credenciales globales**; exigir confirmación apropiada del control de la cuenta, no reasignar acceso automáticamente por conocer el email.
- Estado de invitación pendiente/aceptada/revocada/expirada, límites de reenvío, unicidad, idempotencia, auditoría y manejo de concurrencia.
- Usuarios compartidos con distintos roles en A/B y cambio de tenant seguro; snapshot JWT y permisos visibles alineados. Política de revocación si se requiere menor ventana que 8 h.
- Baja de acceso local vs desactivación global; que la baja en un tenant no inutilice innecesariamente el login a otro.
- Accesibilidad de enlaces, reenvíos, emails normalizados, expiración y seguridad de sesión.

### 4.2. Flujo deseado, sujeto a contrato

`OWNER en tenant A` → solicita invitar MEMBER → Backend valida rol/cupo (cuando exista) → crea invitación persistente → email de acceso sin contraseña → receptor canjea enlace → **si cuenta nueva**, establece contraseña; **si cuenta existente**, prueba control de identidad y acepta membresía → login normal/selección de tenant → permisos MEMBER de A.

El mismo User podrá continuar como OWNER de B o MEMBER de C sin migrar ni duplicar la identidad global. No se programa este flujo hasta que el nuevo ADR y OpenAPI lo describan.

### 4.3. Pruebas imprescindibles

- OWNER intenta invitar OWNER ⇒ 403; MEMBER intenta invitar ⇒ 403.
- Email existente en otro tenant ⇒ invitación vinculable pero nunca sobrescribe contraseña, nombre o estado global sin consentimiento.
- Reenvío, caducidad, replay, revocación, dos invitaciones concurrentes, tenants A/B, usuarios compartidos y `UserTenant` única.
- Logout/select tenant, JWT snapshot y acceso denegado a recursos no autorizados.
- E2E real UI→NestJS→PostgreSQL y fixtures con cleanup.

## 5. Prioridad 1 — Mejora de experiencia y accesibilidad

Conservar la arquitectura Flutter existente (`FeaturePage`, `EntityEditor`, `AsyncPanel`, `PlatformApi`, Riverpod, `go_router`). No rehacer la aplicación por motivos visuales durante hardening.

| Componente | Mejora concreta | Criterio de aceptación |
| --- | --- | --- |
| Formularios Users/Tenants | Ayuda visible y validación campo a campo; evitar borrar lo ingresado ante error | Texto de campo/causa disponible sin mostrar respuesta interna confidencial |
| Onboarding OWNER/MEMBER | Etiquetas de expiración y reenvío, botón deshabilitado durante ejecución, confirmar contraseña accesible | Flujo teclado, pantalla, lector y estados de error probados |
| Campos de selección de roles | Mostrar solo roles autorizados, impedir estados contradictorios | Backend impone permiso aunque se altere el request |
| Errores generales | Diferenciar 400, 401, 403, 409, 413, 429, 503 y errores de formato | Mensaje recuperable, sin parser payload/secretos |
| Formularios y diálogos | Labels semánticos, orden de tabulación, foco al primer campo inválido, feedback tras guardar | Widget/a11y tests y navegador real |
| Tablas y listas | Estado vacío vs error, reintento, paginación, filtros parciales explícitos | Los conteos no engañan, no se pierde navegación tras recarga |
| Layout | Revisión responsive en escritorio y web móvil sin cambiar identidad gráfica del avance | Smoke de resoluciones representativas |

La falla de Usuarios ACME **no es una mejora visual**, es bug funcional de prioridad 0/1 y se trata antes de refinar sus mensajes.

## 6. Prioridad 1 — Ingeniería de pruebas y operación

1. Incorporar en CI una ejecución aislada de PostgreSQL 16 + NestJS + Flutter Web + navegador real, sin secretos productivos; reutilizar `tool/sprint` y `ops/avance2`, controlando recursos/tiempos.
2. Separar suites rápidas de PR (`flutter analyze`, widget/unit/contract, build) y suites profundas en rama candidata/antes de release. No usar `main` productivo como entorno destructor.
3. Publicar evidencia de code SHA, Docker image, fecha, resultados y diferencias autorizadas; sanitización automática de capturas/requests/SQL.
4. Contratos: comparar OpenAPI objetivo con Swagger implementado y Flutter; no traducir funcionalidades 503 a éxito por generación de OpenAPI.
5. Implementar reporte de diagnóstico de `FormatException` con nombre de campo y tipo esperado en entorno de prueba (sin JSON de usuarios) para reducir tiempo de incidente.
6. Congelar registro operacional de versiones desplegadas en Vercel/Render, feature flags y compatibilidad de migraciones. Plan de reversión probado en staging.
7. Reconciliar documentación `dev`/`main` y eliminar ambigüedades de release sin borrar ADR históricos ni alterar decisiones previas.
8. Revisar retención, límites de recursos/cuotas de hosting gratuito, backup/restauración Supabase y SMTP, observabilidad/errores por requestId.

## 7. Prioridad 2 — Membresías por cupos sin cobrar todavía

La idea comercial del owner: una membresía inicial podría permitir, por ejemplo, **cinco accesos MEMBER**, administrados por su OWNER. Ese número **es ilustrativo y no constituye una cuota aprobada**.

Antes de implementarlo definir en un ADR específico:

- Qué es un *plan*, un *entitlement*, un cupo permitido y el estado de suscripción sin facturación.
- Qué ocupa un cupo: invitación pendiente, miembro aceptado activo, invitación caducada, usuario suspendido o invitación revocada.
- Si el OWNER cuenta como asiento o es adicional a los MEMBER.
- Cómo imponer límites **transaccionalmente** ante invitaciones simultáneas; cómo liberar cupo al revocar; qué pasa al reducir el plan.
- Qué diferencias hay entre tenant administrativo sin OWNER y tenant comercial con titular y plan.
- Qué haría ADMIN para asignar plan manualmente al no existir pasarela de pagos.
- Cómo registrar cambios, historial, auditoría, compatibilidad con cuentas existentes y política de facturación futura.

La implementación futura de pagos requiere además proveedor, conciliación, webhooks verificados/idempotentes, facturación/comprobante fiscal según jurisdicción, reembolsos, impuestos, cancelación, seguridad PCI indirecta y protección de datos. **No integrar pago ni emitir comprobantes de pago ahora.**

## 8. Prioridad 2 — Prospector Service / Engine / Jobs

Línea separada y deliberadamente no mezclada con onboarding:

- Cerrar persistencia y ciclo de vida de jobs, cancelación/timeout/reintentos, cuota por tenant, exportación HTTP segura, auditoría, aislamiento y manejo del reinicio del Service según decisiones MVP.
- Diseñar límites de consumo de hosting gratuito antes de ejecutar motores potencialmente costosos; al agotar cuota gratuita, bloquear nuevas búsquedas.
- Auditoría Backend ↔ Service ↔ Flutter y generación/exportación de resultados, sin permitir que el cliente hable directo con FastAPI.
- Solo habilitar mutaciones Jobs cuando Backend esté implementado y Swagger de runtime entregue éxito real; mantener estado 503 mientras corresponda.
- PRs experimentales actuales de Prospector no entran implícitamente a esta línea de release.

## 9. Tabla de prioridad sugerida para el siguiente sprint

| Orden | Ticket | Responsable natural | Bloquea qué |
| --- | --- | --- | --- |
| 1 | Cierre Users ACME y diagnóstico del rol | Owner QA + implementador del componente | Cierre Core sin reservas |
| 2 | Guards de OWNER y baja global/local | Ángel Backend, owner revisa | FE-04 / invitaciones MEMBER |
| 3 | QA, release y documentación ADR-006 si sigue pendiente | Ángel Backend/Flutter + owner QA | Registro asistido en producción |
| 4 | ADR de invitación MEMBER y multitenant existente | Owner técnico, equipo revisa | Administración de accesos ampliada |
| 5 | Validaciones UI/accesibilidad | Flutter / UIUX | Calidad operativa |
| 6 | E2E en CI + release metadata + rollback drill | Owner/DevOps | Robustez de entregas |
| 7 | Planes/cupos sin pago | Owner producto/arquitectura | Evolución comercial |
| 8 | Service/Engine/Jobs | Equipo según disponibilidad | Prospección automatizada |

**Regla:** no abrir todas las líneas simultáneamente si comprometen la estabilidad o los recursos del equipo.

## 10. Definición de terminado postavance

Un incremento solo está terminado cuando:

- Su contrato/ADR está aprobado, sin sobrescribir decisiones antiguas.
- Hay pruebas negativas de permisos, multi-tenant, concurrencia y reversión aplicable.
- Flutter y Backend `main` están alineados y pasan smoke sobre revisiones identificadas.
- Se documentan migraciones, flags, cuota externa y límites conocidos.
- No se declara funcional un módulo aún 503 o basado en mocks.
- El owner firma aceptación y conserva capacidad de contención/rollback.

**Resultado esperado:** un producto cada vez más completo sin convertir el avance universitario en pretexto para asumir riesgos innecesarios en un entorno ya accesible públicamente.
