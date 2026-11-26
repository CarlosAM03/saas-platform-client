# BASELINES Y RAMAS — Segundo Avance v1.0.0

Fecha: 27 de octubre de 2026.

Autoridad: Plan de TrabajoAvance2.md del owner, leído íntegramente (435 líneas; SHA256 df1552887869b3a79d87034b135022c2df265c399ce4c777a654601b5e445f09). Copia congelada: [plan rector](evidencias/PLAN_RECTOR_SNAPSHOT.md). Esta entrega ejecuta exclusivamente Fase 0; G0 pendiente de autorización explícita. Los cambios de implementación descritos son futuros, no aplicados.

Entregables relacionados: [plan de ejecución](PLAN_EJECUCION_CIERRE_AVANCE_2.md), [matriz de cambios](MATRIZ_CAMBIOS_AUTORIZADOS.md), [baselines y ramas](BASELINES_Y_RAMAS.md), [gates](GATES_DE_ACEPTACION.md).

## 1. Raíz y descubrimiento

Raíz documental compartida: `C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal`. Los cuatro repositorios se verificaron con git rev-parse --show-toplevel y origin. No hay AGENTS.md encontrado en ancestros ni archivos AGENTS versionados en los cuatro repositorios. El chat no tiene worktrees adjuntos según list_artifacts; Git sí registra un worktree existente por repositorio.

|Repositorio|Ruta física absoluta|Origin|
|---|---|---|
|Backend|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\Backend_Nestjs\saas-platform-backend|https://github.com/CarlosAM03/saas-platform-backend.git|
|Flutter|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\PlataformaFlutter\saas-platform-client|https://github.com/CarlosAM03/saas-platform-client.git|
|Service|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\ProspectorDocs\PROSPECTOR_SERVICE|https://github.com/CarlosAM03/prospector-service.git|
|Engine|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\ProspectorDocs\PROSPECTOR_ENGINE|https://github.com/CarlosAM03/prospector-engine.git|

## 2. Baselines congelados

|Componente|Referencia elegida|SHA completo|Papel y evidencia|
|---|---|---|---|
|Backend|origin/main|3a3309398458ab333d7b00f16e9c2df6a09ef734|Autoridad funcional/contractual v1.0.0 confirmada por owner; HEAD remoto confirmado por ls-remote y PR#5 merge. No equivale por sí solo a atestación pública del binario Render|
|Backend integración|origin/dev|967044e2dc7d10ea91d7d78a86e1ea6fe2accd1a|Mismo árbol que main; no es motivo para promover PR#6. CI histórico consultado success|
|Flutter|origin/fix/f5-foundation, PR#7|095e899ace31acf17d97bbe945c118c1a5d88682|Candidato de consolidación, CI verde y dependencias verificadas; no es todavía release productiva aceptada|
|Flutter estable Git|origin/main / merge PR#5|a85a99678101b3f5562f66d7dd1c1c454b1d20cb|Ancestro de Foundation; preservación de PR#5 comprobada|
|Flutter dev actual|origin/dev / PR#6|c7dee664cbdda85d38d896ce3103d8fc6319f0af|Ancestro de Foundation,162 líneas de marcadores en15 archivos; CI rojo; no promover tal cual|
|Service|origin/main|566bbbe67a59a0fda307ea7d8c5f6bf46fd93aab|Fuera de v1.0.0, conservar para v1.1.0|
|Engine|origin/main|70f6081688db5c5bc5ea612f5fabd5724aab0b20|Fuera de v1.0.0, dependencia fijada por Service|

Se verificaron referencias con **git ls-remote --heads --tags origin**: sin fetch y sin actualizar refs locales. No hay deriva de baselines respecto de la auditoría. Los main locales Backend/Flutter/Service están atrasados8/24/6 commits; no utilizarlos como base. Todos los repositorios tienen solo origin y ningún commit local no publicado ni stash.

El schema main/dev comparte blob `807371c90e99fe1aa4ff89835ff8e765fd507a64`; únicamente está la migración core `Prisma/migrations/20260909152421_init/migration.sql` más migration_lock.toml. No se conectó a Supabase ni se ejecutó Prisma. El estado de migraciones productivas sigue sin verificación independiente; el owner confirma estabilidad del entorno actual.

## 3. Estado activo y protección del trabajo

|Repo|Rama activa|HEAD|Estado al iniciar|
|---|---|---|---|
|Backend|feat/prospector-service-mvp-integration|a80871b6c5ebf39b4fca69eaf5f6352ab342da96|Limpio|
|Flutter|feat/flutter-prospector-mvp-parity|97ad02a621007e4139e5207511ecca2376754ed8|Cambios documentales locales; ver preservación|
|Service|feat/fastapi-service-foundation|69c54a15601d238638610d0a5c08af46e3da7f14|Limpio|
|Engine|main|70f6081688db5c5bc5ea612f5fabd5724aab0b20|Limpio|

Flutter mantiene exactamente estos cambios del usuario, sin restauración ni staging:

```text
 D "Plan de Trabajo.md"
?? "Docs/Planeacion/entregado/Plan de TrabajoAvance1.md"
?? "Plan de TrabajoAvance2.md"
```

Se crearon únicamente copias nuevas de los dos archivos sin seguimiento y del blob publicado del plan eliminado. El contenido de Avance1 coincide con el plan eliminado al normalizar CRLF/LF y salto final, aunque sus bytes/hashes son distintos; no se decide ni se materializa un rename. La intención de versionado documental deberá resolverse antes de una futura integración, sin mezclarlo con código del candidato.

|Evidencia de preservación|SHA256|
|---|---|
|[evidencias/PLAN_RECTOR_SNAPSHOT.md](evidencias/PLAN_RECTOR_SNAPSHOT.md)|df1552887869b3a79d87034b135022c2df265c399ce4c777a654601b5e445f09|
|[evidencias/PLAN_AVANCE_1_SNAPSHOT.md](evidencias/PLAN_AVANCE_1_SNAPSHOT.md)|afdbf821b98f5040d569aec44662f8414f32e4f55eb9fe44a7ebdb8e4a4fdb00|
|[Plan anterior publicado](evidencias/PLAN_ANTERIOR_TRACKED_HEAD_SNAPSHOT.md)|5f1ddfed25739662755687832da2e122f851033eb91b653781e2f1a4d30bd683|

Los archivos no publicados están protegidos mediante copias verificadas; el contenido eliminado sigue además alcanzable por Git publicado. No se afirma respaldo offline íntegro de repositorios: se congelaron referencias y documentos relevantes. Nunca cambiar el checkout activo experimental ni limpiar estos cambios para preparar el core. No hay trabajo desprotegido identificado que obligue a bloquear G0 una vez verificadas esas copias y la integridad final.

## 4. Todas las referencias y upstreams

Se incluyen locales, remotas y tags. Formato original sin emails; evidencia01 contiene también worktrees, autor/committer, fechas y último commit.

### Backend

```text
ref|SHA|upstream|tracking|autor Git|fecha
refs/heads/dev|967044e2dc7d10ea91d7d78a86e1ea6fe2accd1a|refs/remotes/origin/dev||CarlosAM03|2026-10-20T09:16:20-07:00
refs/heads/feat/prospector-service-mvp-integration|a80871b6c5ebf39b4fca69eaf5f6352ab342da96|refs/remotes/origin/feat/prospector-service-mvp-integration||CarlosAM03|2026-10-27T02:55:12-07:00
refs/heads/main|ab53272f531d15e6c4dcc9df8c1d6dca8601e87a|refs/remotes/origin/main|[behind 8]|Carlos Armenta|2026-10-09T06:20:28-07:00
refs/heads/release/avance-1|af62f313d15a5a5be6b0aeed4ce7652e2dfb77b3|refs/remotes/origin/release/avance-1||CarlosAM03|2026-09-28T10:21:38-07:00
refs/remotes/origin/HEAD|3a3309398458ab333d7b00f16e9c2df6a09ef734|||Carlos Armenta|2026-10-20T09:32:49-07:00
refs/remotes/origin/dev|967044e2dc7d10ea91d7d78a86e1ea6fe2accd1a|||CarlosAM03|2026-10-20T09:16:20-07:00
refs/remotes/origin/feat/prospector-service-mvp-integration|a80871b6c5ebf39b4fca69eaf5f6352ab342da96|||CarlosAM03|2026-10-27T02:55:12-07:00
refs/remotes/origin/main|3a3309398458ab333d7b00f16e9c2df6a09ef734|||Carlos Armenta|2026-10-20T09:32:49-07:00
refs/remotes/origin/release/avance-1|af62f313d15a5a5be6b0aeed4ce7652e2dfb77b3|||CarlosAM03|2026-09-28T10:21:38-07:00
refs/tags/Avance-1|af62f313d15a5a5be6b0aeed4ce7652e2dfb77b3|||CarlosAM03|2026-09-28T10:21:38-07:00
```

### Flutter

```text
ref|SHA|upstream|tracking|autor Git|fecha
refs/heads/chore/vercel-production-container|372a16de849f09d85c464dc2a0696562d618c8f0|refs/remotes/origin/chore/vercel-production-container||CarlosAM03|2026-10-13T06:44:23-07:00
refs/heads/dev|c7dee664cbdda85d38d896ce3103d8fc6319f0af|refs/remotes/origin/dev||Andre GRS|2026-10-26T19:27:07-07:00
refs/heads/feat/flutter-prospector-mvp-parity|97ad02a621007e4139e5207511ecca2376754ed8|refs/remotes/origin/feat/flutter-prospector-mvp-parity||CarlosAM03|2026-10-27T02:48:36-07:00
refs/heads/feature/flutter-backend-parity-core|95e7092d461f883a0c18da11f32e4eae6c43dcc4|refs/remotes/origin/feature/flutter-backend-parity-core||CarlosAM03|2026-10-20T11:54:58-07:00
refs/heads/fix/f5-foundation|095e899ace31acf17d97bbe945c118c1a5d88682|refs/remotes/origin/fix/f5-foundation||CarlosAM03|2026-10-27T02:21:57-07:00
refs/heads/fix/vercel-api-base-url-build|1a9e8841682f2e5a8ed8582b5d0ffe0fc3237905|refs/remotes/origin/fix/vercel-api-base-url-build|[gone]|CarlosAM03|2026-10-13T08:35:52-07:00
refs/heads/main|dd9e95b2a4e71afc98662ed4250312a615b7915a|refs/remotes/origin/main|[behind 24]|CarlosAM03|2026-09-27T21:49:43-07:00
refs/remotes/origin/HEAD|a85a99678101b3f5562f66d7dd1c1c454b1d20cb|||Carlos Armenta|2026-10-20T21:26:34-07:00
refs/remotes/origin/chore/vercel-production-container|372a16de849f09d85c464dc2a0696562d618c8f0|||CarlosAM03|2026-10-13T06:44:23-07:00
refs/remotes/origin/codex/complete-pending-features|fe9e32ff6decbf74de14b40f4355557904b40533|||Andre GRS|2026-10-22T12:34:31-07:00
refs/remotes/origin/dev|c7dee664cbdda85d38d896ce3103d8fc6319f0af|||Andre GRS|2026-10-26T19:27:07-07:00
refs/remotes/origin/feat/flutter-prospector-mvp-parity|97ad02a621007e4139e5207511ecca2376754ed8|||CarlosAM03|2026-10-27T02:48:36-07:00
refs/remotes/origin/feature/flutter-backend-parity-core|95e7092d461f883a0c18da11f32e4eae6c43dcc4|||CarlosAM03|2026-10-20T11:54:58-07:00
refs/remotes/origin/fix/f5-foundation|095e899ace31acf17d97bbe945c118c1a5d88682|||CarlosAM03|2026-10-27T02:21:57-07:00
refs/remotes/origin/main|a85a99678101b3f5562f66d7dd1c1c454b1d20cb|||Carlos Armenta|2026-10-20T21:26:34-07:00
```

### Service

```text
ref|SHA|upstream|tracking|autor Git|fecha
refs/heads/feat/fastapi-service-foundation|69c54a15601d238638610d0a5c08af46e3da7f14|refs/remotes/origin/feat/fastapi-service-foundation||CarlosAM03|2026-10-21T08:08:33-07:00
refs/heads/main|0494f2b385e38c6a83202290a13fab33e345c7c4|refs/remotes/origin/main|[behind 6]|CarlosAM03|2026-10-21T05:58:44-07:00
refs/remotes/origin/HEAD|566bbbe67a59a0fda307ea7d8c5f6bf46fd93aab|||Carlos Armenta|2026-10-21T07:37:30-07:00
refs/remotes/origin/feat/fastapi-service-foundation|69c54a15601d238638610d0a5c08af46e3da7f14|||CarlosAM03|2026-10-21T08:08:33-07:00
refs/remotes/origin/main|566bbbe67a59a0fda307ea7d8c5f6bf46fd93aab|||Carlos Armenta|2026-10-21T07:37:30-07:00
```

### Engine

```text
ref|SHA|upstream|tracking|autor Git|fecha
refs/heads/feat/extract-cli-v1-engine|70f6081688db5c5bc5ea612f5fabd5724aab0b20|||CarlosAM03|2026-10-21T05:48:28-07:00
refs/heads/main|70f6081688db5c5bc5ea612f5fabd5724aab0b20|refs/remotes/origin/main||CarlosAM03|2026-10-21T05:48:28-07:00
refs/remotes/origin/HEAD|70f6081688db5c5bc5ea612f5fabd5724aab0b20|||CarlosAM03|2026-10-21T05:48:28-07:00
refs/remotes/origin/main|70f6081688db5c5bc5ea612f5fabd5724aab0b20|||CarlosAM03|2026-10-21T05:48:28-07:00
```

## 5. PR, historia y dependencias

|PR|Base ← origen / SHA head|Estado consultado|Dependencia y tratamiento|
|---|---|---|---|
|[Backend6](https://github.com/CarlosAM03/saas-platform-backend/pull/6)|dev ← feat/prospector-service-mvp-integration / a80871b6c5ebf39b4fca69eaf5f6352ab342da96|OPEN Draft|Conservar P2; extraer solo conceptos de seguridad aprobados, nunca PR completo|
|[Backend5](https://github.com/CarlosAM03/saas-platform-backend/pull/5)|main ← dev / 967044e2dc7d10ea91d7d78a86e1ea6fe2accd1a|MERGED|Trabajo integrado verificado por ancestry y baseline|
|[Flutter5](https://github.com/CarlosAM03/saas-platform-client/pull/5)|main ← dev / 3fa87b9fa4d25b30c0c13af652e2ae88a71983dd|MERGED|Trabajo integrado verificado por ancestry y baseline|
|[Flutter6](https://github.com/CarlosAM03/saas-platform-client/pull/6)|main ← dev / c7dee664cbdda85d38d896ce3103d8fc6319f0af|OPEN|Aportaciones André preservadas en Foundation; descripción cancel/save/export sobrepromete al Backend actual|
|[Flutter7](https://github.com/CarlosAM03/saas-platform-client/pull/7)|dev ← fix/f5-foundation / 095e899ace31acf17d97bbe945c118c1a5d88682|OPEN Draft|Base dev#6; Foundation es descendiente de main y dev; seleccionar este SHA|
|[Flutter8](https://github.com/CarlosAM03/saas-platform-client/pull/8)|fix/f5-foundation ← feat/flutter-prospector-mvp-parity / 97ad02a621007e4139e5207511ecca2376754ed8|OPEN Draft|Apilado en #7; excluir del core y no retargetear ahora|
|[Service1](https://github.com/CarlosAM03/prospector-service/pull/1)|main ← feat/fastapi-service-foundation / d0be7b7589b74cf4510ee11217723fee7ed8ff73|MERGED|Head original fusionado; rama activa conserva después diferencias solo en dos documentos|

GitHub REST enumera únicamente Backend#6 y Flutter#6/#7/#8 abiertos; Service/Engine sin PR abiertos. Las reviews formales de esos cuatro PR abiertos están vacías. Mergeable=true o merge_commit_sha de un PR abierto no equivale a aprobación/merge. No se modificó conversación, revisión, estado o base de ningún PR.

Relaciones comprobadas: mainFlutter→Foundation0/9 detrás/delante; devFlutter→Foundation0/5; Foundation→parity0/8. PR#5 está integrado en main, por lo que no se debe reaplicar. Los seis commits exclusivos de Backend#6 están en evidencia07; el commit `42b96fefd73cc11b42ecde4df6d5f42393328bfc` mezcla SEC-01 con JWT vivo y **no se copiará completo**. Autor/committer CarlosAM03 no constituye aprobación de todos sus cambios.

Service69c54a1 y main566bbbe difieren solo en DependenciasServicePlatform.md y un handoff; código/tests/paquete siguen equivalentes. Service fija Engine70f6081 y exportador0494f2 por SHA; versiones0.1.0.dev0, sin tag estable. Conservar ramas y worktrees; no crear dev artificial para esos repositorios.

## 6. CI y despliegues consultados, no ejecutados

|Referencia / run|Estado verificado|Límite|
|---|---|---|
|Foundation 095e899 /40480231249|3 jobs success: foundation, container, production-container|CI existente, no rerun ni aceptación productiva|
|Flutter dev c7dee66 /40438948365|3 jobs failure|Consistente con marcadores versionados|
|Backend dev 967044e /39456351630|quality/PG/docker success|Árbol igual main; no nuevo test del candidato selectivo|
|Backend feature a808 /40484475130|success|Schema/P2; no candidato core aprobado|
|Service main 566 /39618476631|9 jobs success|No bloquea ni habilita corev1|
|Engine main 70 /39608150150|8 jobs success|No valida Maps de producción|

El conector de runs por SHA filtra PR: un array vacío para merges/main no prueba ausencia de checks push; se consultaron jobs conocidos y se mantuvo el vínculo histórico de SHA desde la auditoría. Los cinco últimos deployments Flutter de GitHub son Preview, incluidos97ad02a y095e899; no prueban el SHA servido por el alias de producción. El registro Production a85 de la auditoría no se presenta como atestación nueva del alias web. Render/Vercel/Supabase no se modificaron.

## 7. Plan concreto de ramas, todavía no ejecutado

Se propone **una rama temporal core por repo Backend/Flutter**, en nuevos worktrees para preservar el checkout experimental y los documentos del usuario. Reutilizar los worktrees activos mezclaría P2 o cambios documentales. No se creará rama/worktree en Service o Engine.

|Repo|Rama local propuesta|Base exacta|Destino propuesto, inexistente al preflight|
|---|---|---|---|
|Backend|fix/avance2-core-security|3a3309398458ab333d7b00f16e9c2df6a09ef734|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\backend-core|
|Flutter|release/avance2-frontend-v1|095e899ace31acf17d97bbe945c118c1a5d88682|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\flutter-core|

Operaciones revisables **NO EJECUTADAS**:

```powershell
git -C 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\Backend_Nestjs\saas-platform-backend' worktree add -b 'fix/avance2-core-security' 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\backend-core' '3a3309398458ab333d7b00f16e9c2df6a09ef734'
git -C 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\PlataformaFlutter\saas-platform-client' worktree add -b 'release/avance2-frontend-v1' 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\flutter-core' '095e899ace31acf17d97bbe945c118c1a5d88682'
```

Preferir herramienta de worktree administrada si puede direccionar el repositorio correcto; este chat está en una raíz documental sin repositorio adjunto y la interfaz consultada no ofrece parámetro repo. El equivalente Git por -C permite revisar exactamente ambos destinos. Cualquier adaptación de rutas debe seguir dentro de la raíz indicada y mantener los mismos SHA/ramas; no usar --force ni reciclar directorios existentes. Los nombres de ramas no existen local/remoto y los destinos no existen. No hay hooks activos reportados y core.longpaths=true; volver a comprobar al ejecutar.

Después de autorizar G0: revalidar SHA remotos, copias y destinos; crear exclusivamente estas ramas/worktrees; comprobar limpieza y HEAD y **detenerse en G1 antes de editar o probar**. Si una referencia cambia, un destino aparece o falta protección de trabajo, detenerse y revisar el plan. No push, no upstream nuevo, no cambio de main/dev ni checkout del worktree original.

## 8. Estado G0 y decisiones pendientes

**GO técnico para preparar ramas/worktrees con el alcance anterior; autorización formal G0 PENDIENTE.** El worktree Flutter original está sucio por documentos preservados y no se hará pasar por limpio. No bloquea preparar un checkout separado después de autorización.

Pendiente del owner: aprobar explícitamente los dos nombres, bases y preparación aislada; revisar en G1 el plan selectivo antes de implementar. La incorporación futura de documentos del usuario se resolverá sin sobrescribirlos. No quedan pendientes las decisiones JWT snapshot/exclusión P2: ya están resueltas por el plan. El cuestionario original de26respuestas no está adjunto; registrar su ausencia, no reconstruir aprobaciones.

Evidencias: [Git inicial](evidencias/01_GIT_INICIAL.json), [PR](evidencias/02_PRS_GITHUB.json), [diferencial](evidencias/07_GIT_DIFERENCIAL.json), [metadatos remotos](evidencias/09_METADATA_REMOTA_Y_DEPLOYMENTS.json), [preflight](evidencias/13_PREFLIGHT_Y_DEPENDENCIAS.json), [operaciones propuestas](evidencias/14_OPERACIONES_PROPUESTAS_G0.json). La integridad final y hashes se entregan en evidencias15/16/17.

**DETENIDO EN G0. No se han creado ramas ni worktrees; se espera autorización explícita del owner.**
