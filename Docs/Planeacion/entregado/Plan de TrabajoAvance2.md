# PROSPECTOR SaaS — Plan de cierre del segundo avance

26 decisiones recibidas

Planificación previa a Codex

Con tus decisiones ya tenemos una dirección arquitectónica suficientemente definida para preparar el cierre del segundo avance.

El objetivo es consolidar la versión v1.0.0 sobre el Backend que ya está funcionando en Render y PostgreSQL administrado en Supabase, actualizar Flutter en Vercel para alcanzar paridad contractual y dejar aislada la integración v1.1.0.

No vamos a ejecutar todos los PR pendientes ni intentar terminar Prospector Service anticipadamente.

## 1. Reconciliación de las decisiones

De las 26 decisiones, identifico dos que necesitan una delimitación técnica adicional y tres condiciones importantes de implementación. No requieren rehacer el cuestionario.

### Decisiones que deben interpretarse conjuntamente

A4 + C5 — Flujos simulados en Flutter.

Autorizaste conservar interacciones simuladas en funcionalidades cuyo contrato todavía no está implementado. Esto es compatible con mantener Backend como autoridad siempre que diferenciemos estrictamente la simulación de una operación real.

Propongo la siguiente regla de implementación:

- Los módulos de producción pueden mostrar demostraciones locales de UI, pero deben identificarse inequívocamente como `DEMO — SIN EJECUCIÓN REAL`.
- Una simulación no podrá realizar solicitudes de creación de jobs, generar resultados ficticios que parezcan persistidos ni modificar información de negocio.
- Los datos ficticios deberán diferenciarse de los datos reales y no mezclarse con conteos, historial o dashboard.
- La demo se implementará mediante componentes de presentación o adaptadores locales explícitos, nunca sustituyendo silenciosamente el repositorio HTTP real.

Así podremos conservar el trabajo visual y mostrar cómo funcionará la generación de prospectos sin afirmar que existe una integración productiva.

E1 + E3 — `dev` como integración y preview experimental v1.1.0.

Aquí debemos evitar que `dev` se convierta en una rama permanentemente inestable.

La secuencia que propongo es utilizar `dev` primero como punto de aceptación del cierre v1.0.0. Una vez promovido el candidato a `main`, `dev` podrá avanzar con integración experimental de 1.1.0. Las características aún no aprobadas se mantendrán aisladas en ramas P2 hasta cumplir sus criterios de entrada.

Esto evita mezclar el cierre productivo con decisiones futuras sobre Prisma, callbacks, cuotas y persistencia.

### Tres condiciones que considero obligatorias

1. SEC-01 debe seleccionarse sin arrastrar la revalidación JWT viva. Mantienes la política snapshot en v1.0.0, por lo que copiar íntegro el commit de seguridad sería incorrecto.
2. La migración P2 no debe alcanzar la base administrada de Supabase. Preservaremos ese trabajo en la rama experimental, pero el Backend del cierre conservará el esquema baseline.
3. La actualización de Node queda expresamente diferida. La decisión de posponerla es válida como secuencia operativa, pero debe quedar registrada como deuda técnica prioritaria, no como riesgo resuelto.

El informe respalda esta separación: identifica que Backend `main` y `dev` tienen el mismo árbol funcional, que el PR #6 mezcla seguridad con nuevas políticas y persistencia, y que Flutter Foundation es el candidato core con menor riesgo.&#x20;

AUDITORIA_RECONCILIACION_PROSPECTOR_V1.md



## 2. Alcance definitivo del cierre v1.0.0

## Arquitectura aprobada para este avance

Flutter Web — Vercel

Interfaz consolidada, PR #5 + Foundation + trabajo válido de André

API REST existente

NestJS — Render

`main` + correcciones de seguridad estrictamente seleccionadas

PostgreSQL — Supabase

Esquema actual sin migraciones P2

Prospector Service / Engine

Fuera del cierre

La integración externa permanece reservada para las pruebas locales y el trabajo de v1.1.0.

### Matriz funcional de aceptación

| Módulo                                | Comportamiento exigido                    | Estado objetivo |
| ------------------------------------- | ----------------------------------------- | --------------- |
| Autenticación                         | Login, sesión, logout y selección tenant  | Real            |
| Organizaciones                        | Listado y operaciones autorizadas         | Real            |
| Usuarios                              | Operaciones RBAC y protección multitenant | Real            |
| Campañas                              | CRUD contractual y asociaciones           | Real            |
| Prospectos                            | Gestión manual y por campaña              | Real            |
| CSV                                   | Preview, decisiones y confirmación        | Real            |
| Dashboard                             | Métricas del tenant obtenidas del Backend | Real            |
| Jobs                                  | Listado y detalle de registros existentes | Real            |
| Generación externa                    | Demostración visual identificada          | Simulada        |
| Cancelación / exportación de scraping | Sin ejecución real                        | Deshabilitada   |
| Callbacks / Service / Engine          | No requeridos por v1.0.0                  | Experimental    |

Criterio de salida: ninguna función marcada como real debe depender de un mock o un endpoint inexistente; ninguna función simulada debe ser presentada como ejecutada por Backend.

## 3. Plan detallado de implementación

La propuesta consta de ocho fases con criterios de entrada, actividades, evidencia y puntos de control.

Fase 0 — Congelación y trazabilidad

Confirmar SHA de referencias remotas, ramas activas, PR abiertos, CI y estado de despliegues. Respaldar referencias de trabajo sin reescribir historia. Comparar el contrato público anunciado con `origin/main` y registrar las diferencias.

Salida: inventario de baselines y plan exacto de ramas. Bloqueo si hay archivos o commits sin proteger que puedan perderse.

Fase 1 — Hardening selectivo de Backend

Partir de `origin/main` (`3a330939` en la auditoría). Separar SEC-01, correcciones de configuración y pruebas útiles del PR #6. Conservar JWT snapshot y esquema Prisma baseline. No introducir Event/Snapshot ni capacidades externas.

Salida: candidato Backend core sin nuevas migraciones, con pruebas de identidades compartidas y aislamiento tenant.

Fase 2 — Consolidación Flutter

Partir de Foundation (`095e899` según la auditoría), comparando contra PR #5, PR #6 de André y `main`. Preservar identidad visual, responsive, navegación y componentes útiles. Verificar que todos los repositorios y DTO utilicen el contrato Backend v1.0.0.

Salida: Flutter compilable y visualmente consolidado sin dependencia de FastAPI.

Fase 3 — Cierre funcional CSV, Dashboard y Jobs

Validar CSV preview/confirm con decisiones por fila y manejo de errores; dashboard mediante datos reales aislados; listado y detalle de jobs. Implementar las demos visuales de prospección sin escritura ni solicitudes externas.

Salida: matriz de operaciones Flutter–Backend con cobertura, estado y pruebas por cada flujo habilitado.

Fase 4 — Validación E2E del núcleo

Ejecutar Backend y Flutter contra PostgreSQL desechable usando únicamente las migraciones core autorizadas. Comprobar usuarios compartidos en dos tenants, operaciones negativas, cambios de sesión, CSV y dashboard. Verificar que la UI no invoque rutas P2.

Salida: CI verde, pruebas E2E reproducibles y evidencia de ausencia de llamadas de prospección externa.

Fase 5 — Integración y aceptación en dev

Integrar selectivamente los cambios validados, resolver el historial de PR #6/#7 sin descartar trabajo útil y ejecutar nuevamente las verificaciones sobre los commits candidatos. No promover PR #8 como parte del core.

Salida: ramas dev de Backend y Flutter coherentes con el cierre v1.0.0 y aprobadas técnicamente.

Fase 6 — Promoción a main y despliegue

Tras aceptación, promover el candidato mediante PR y comprobaciones. Atestar SHA, configuración de API, migraciones y CORS. Actualizar Frontend Vercel; actualizar Backend Render únicamente si las correcciones autorizadas lo requieren, con reversión preparada.

Salida: producción con paridad funcional comprobada y registro de release. Despliegue sujeto a autorización separada.

Fase 7 — Preparación posterior de v1.1.0

Preservar ramas P2, revisar contratos Service/Engine, diseñar Compose de cuatro servicios y definir pruebas de integración locales. No decidir todavía la persistencia de resultados, idempotencia o alcance definitivo 1.1.0.

Salida: propuesta verificable de entorno experimental, sin activación en Render ni despliegue de Service productivo.

## 4. Controles de Codex

El prompt de ejecución debe trabajar por etapas y detenerse en puntos de aprobación. No recomiendo entregar a Codex una instrucción que autorice de una sola vez modificaciones, PR, merges y despliegues: parte del trabajo depende del resultado de pruebas y de SHA que pueden cambiar.

| Puerta | Condición de aprobación                     | Acción permitida después                      |
| ------ | ------------------------------------------- | --------------------------------------------- |
| G0     | Baselines y worktrees verificados           | Crear ramas temporales                        |
| G1     | Plan de cambios Backend y Frontend revisado | Implementar cambios locales                   |
| G2     | Código implementado y diff inspeccionado    | Ejecutar pruebas aisladas                     |
| G3     | E2E, seguridad y contrato aceptados         | Proponer PR hacia `dev`                       |
| G4     | `dev` validado y revisión aprobada          | Proponer promoción a `main`                   |
| G5     | Release aprobado y rollback preparado       | Despliegue autorizado                         |
| G6     | v1.0.0 consolidado                          | Iniciar diseño y ejecución experimental 1.1.0 |

En particular, la ejecución del plan de cierre no debe autorizar automáticamente el despliegue ni una modificación de Supabase.

## 5. Instrucción maestra para Codex

Este es el prompt de activación del plan, orientado a comenzar la ejecución controlada de las primeras fases, sin conceder permisos implícitos para merges ni producción.

# CODEX — EJECUCIÓN CONTROLADA DEL CIERRE DEL SEGUNDO AVANCE

## PROSPECTOR SaaS v1.0.0

**Fecha de decisiones:** 27 de octubre de 2026\
**Autoridad:** Owner técnico\
**Estado:** Plan aprobado para preparación y ejecución local controlada, con puertas de autorización.

### 1. Misión

Ejecutar el cierre técnico del segundo avance de PROSPECTOR SaaS consolidando la versión v1.0.0 del Backend y Flutter, sin ampliar el contrato de negocio aprobado ni activar Prospector Service.

Debes trabajar con los cuatro repositorios existentes, tomando como autoridad:

1. Decisiones del owner contenidas en este encargo.
2. ADR y requisitos aprobados no contradichos expresamente.
3. Backend `main` estable y contrato publicado en Render.
4. Código ejecutable y pruebas reales.
5. Flutter Foundation, PR #5, aportaciones válidas de André y correcciones posteriores.
6. Implementaciones experimentales, solo como propuestas separadas.

Documentación principal: `AUDITORIA_RECONCILIACION_PROSPECTOR_V1.md` y sus anexos. Si un anexo no está disponible, registra la ausencia y utiliza evidencia equivalente de Git, código y CI. No inventes su contenido.

### 2. Baseline productivo

Backend:

`https://saas-platform-backend-l55n.onrender.com/api/docs#/`

Frontend:

`https://saas-platform-client-web.vercel.app/#/login`

Preview:

`https://saas-platform-client-web-git-fi-5adecc-carlos-armentas-projects.vercel.app/#/login`

El owner confirma que el Backend productivo en Render y PostgreSQL Supabase son estables para el alcance actual.

Referencia Git Backend de la auditoría:

`3a3309398458ab333d7b00f16e9c2df6a09ef734`

Referencia Flutter Foundation:

`095e899ace31acf17d97bbe945c118c1a5d88682`

Verificar que estas referencias no hayan cambiado antes de trabajar.

No asumir que un alias desplegado demuestra su SHA exacto si no existe atestación de build.

### 3. Alcance aprobado v1.0.0

Funcionalidades reales:

- Auth y sesiones.
- Tenants.
- Usuarios.
- RBAC.
- Campañas.
- Prospectos.
- Importación CSV con preview/confirm.
- Dashboard con métricas reales.
- Lectura de jobs existentes.
- PostgreSQL y aislamiento multitenant.

Operaciones externas de prospección:

- No habilitar generación.
- No ejecutar cancelación externa.
- No persistir resultados de scraping.
- No exportar resultados externos.
- No generar callbacks productivos.
- No invocar FastAPI desde Flutter.
- No insertar secretos Service en Flutter.

Está autorizada una demostración local y visual de los flujos de prospección siempre que aparezca identificada claramente como simulación, sin llamadas reales, mutaciones ni contaminación de datos productivos.

### 4. Backend

Partir del core estable.

Seleccionar el fix SEC-01 de identidad global, correcciones de configuración y pruebas independientes justificadas.

No incorporar íntegramente el PR #6.

Mantener:

- JWT snapshot según ADR-004.
- Roles actuales.
- Contratos actuales.
- Esquema Prisma baseline.
- Jobs sin integración externa.
- CSV existente.

No incorporar:

- ProspectingJobEvent.
- ProspectingJobSnapshot.
- Migración P2.
- Revalidación viva de JWT.
- Nuevos callbacks.
- TTL, cuotas o idempotencia experimental.
- Nuevos endpoints para satisfacer pantallas.

El runtime Node 20 queda registrado como deuda técnica para actualización inmediatamente posterior al cierre, no como autorización de migración de runtime en esta ejecución.

### 5. Flutter

Partir de Foundation PR #7, verificando sus dependencias.

Conservar las funcionalidades y cambios visuales útiles de PR #5 y André.

Consolidar:

- Login y navegación.
- Tenants y sesiones.
- Usuarios y permisos.
- Campañas.
- Prospectos.
- CSV.
- Dashboard.
- Jobs de lectura.
- Responsive y estados de error.
- Limpieza de estado ante logout/cambio tenant.
- Cancelación lógica de respuestas tardías.

Toda operación real habilitada debe tener contrato Backend existente.

No inventar respuestas HTTP.

No mantener mocks ocultos en funcionalidades productivas.

Las demostraciones UI deben vivir en componentes claramente identificados, aislados del SDK de producción.

### 6. Fases de ejecución

**Fase 0 — Inventario y preparación**

- Verificar Git, SHA, worktrees y PR.
- Crear matriz final de cambios.
- No alterar ramas existentes.
- Obtener aprobación G0 antes de crear ramas de implementación.

**Fase 1 — Backend core**

- Preparar rama temporal desde baseline verificado.
- Aplicar correcciones selectivas.
- No modificar esquema.
- Generar diff y pruebas del fix.
- Detenerse para revisión G1/G2.

**Fase 2 — Frontend consolidado**

- Preparar rama temporal desde Foundation.
- Reconciliar aportaciones.
- Corregir incompatibilidades.
- Conservar diseño.
- Aislar simulaciones.
- Generar matriz contractual y diff.

**Fase 3 — Validación**

- Ejecutar lint, tipos, análisis estático y tests.
- Ejecutar pruebas aisladas PostgreSQL.
- Validar Auth, RBAC, tenants, CRUD, CSV, dashboard y jobs.
- Comprobar que la UI no invoca operaciones externas.
- Registrar cobertura y limitaciones.

**Fase 4 — Integración dev**

- Preparar propuestas de PR.
- No fusionar sin aprobación G3.
- Validar commits integrados.
- No incorporar P2.

**Fase 5 — Release main**

- Preparar informe de release y rollback.
- No promover ni desplegar sin autorización G4/G5.

**Fase 6 — Separación v1.1.0**

- Conservar PR #6 Backend y PR #8 Flutter como trabajo experimental.
- Documentar dependencias y decisiones pendientes.
- Proponer Compose de Flutter + NestJS + PostgreSQL + FastAPI con Engine instalado.
- No ejecutar pruebas reales de Maps sin autorización.
- No desplegar Service.
- No aprobar automáticamente nuevas migraciones.

### 7. Evidencia obligatoria

Por fase entregar:

- Rama y SHA exactos.
- Archivos modificados.
- Justificación de cada cambio.
- Decisión aprobada que lo respalda.
- Diff resumido.
- Contratos afectados.
- Tests ejecutados.
- Tests omitidos.
- Riesgos y regresiones.
- Resultado GO / NO-GO.
- Acciones que requieren autorización.

No presentar CI anterior como ejecución nueva.

No utilizar una base PostgreSQL ya migrada con P2 como única evidencia de compatibilidad del esquema baseline.

No realizar pruebas de escritura sobre Supabase de producción.

### 8. Restricciones permanentes

Prohibido sin aprobación explícita posterior:

- Merge a `dev` o `main`.
- Push a ramas protegidas.
- Force-push.
- Eliminación de ramas.
- Limpieza destructiva Git.
- Migraciones productivas.
- Modificación de bases compartidas.
- Cambios de secretos.
- Despliegues Render/Vercel.
- Activación Service.
- Scraping externo real.
- Introducción de decisiones de arquitectura no autorizadas.

### 9. Primera ejecución

Comienza por Fase 0.

Verifica los baselines, los PR y la disponibilidad de evidencias. Produce:

`PLAN_EJECUCION_CIERRE_AVANCE_2.md`

`MATRIZ_CAMBIOS_AUTORIZADOS.md`

`BASELINES_Y_RAMAS.md`

`GATES_DE_ACEPTACION.md`

Almacena los informes fuera de los repositorios o en un directorio documental expresamente destinado a ello.

No crees ramas ni modifiques código hasta presentar el resultado de Fase 0 y solicitar aprobación G0.

La aprobación de G0 autoriza únicamente el siguiente tramo definido del plan, no las etapas posteriores.

### 10. Criterio final

El resultado objetivo es un Frontend productivo consolidado y contractualmente compatible con el Backend estable, con seguridad tenant preservada, CSV y dashboard reales, y trabajos de integración externa aislados para v1.1.0.

La versión 1.1.0 no tiene alcance funcional final aprobado hasta que Service, Engine y el entorno Docker Compose hayan sido validados.

**Ejecuta solamente la etapa autorizada y detente en la primera puerta de control.**

## 6. Mi dictamen del plan

GO para iniciar Fase 0 de Codex

Las decisiones de negocio y arquitectura necesarias para preparar los candidatos core están definidas. Codex puede verificar referencias y generar el plan operacional concreto.

Autorización posterior para modificar e integrar

Todavía quedan sujetas a gates la creación de ramas, la implementación, los PR, las promociones y los despliegues. El resultado de la Fase 0 servirá para validar los comandos y diffs exactos.

Con esto quedan separadas tres responsabilidades: Codex implementa y verifica, nosotros revisamos los resultados técnicos frente al contrato y las decisiones registradas, y tú conservas la autoridad para aceptar cambios de arquitectura, reglas de negocio y promoción a producción.

La prioridad del segundo avance sigue siendo una sola: dejar el Frontend consolidado en paridad con el Backend productivo sin arrastrar las decisiones experimentales de v1.1.0.