# ACTA G0 — RAMAS Y WORKTREES PREPARADOS

Estado: **G0 APROBADO POR EL OWNER Y EJECUTADO. G1 PENDIENTE; DETENIDO ANTES DE MODIFICAR CÓDIGO.**

## 1. Autoridad y alcance ejecutado

Se ejecutó la autorización explícita del mensaje del owner “G0 APROBADO”: dos ramas, dos bases y dos destinos exactos. El Plan de TrabajoAvance2.md permanece rector, SHA256 **df1552887869b3a79d87034b135022c2df265c399ce4c777a654601b5e445f09**. El SHA Git del Backend se registra aparte en la tabla; no confundir identificación del plan con un commit.

Los cuatro entregables de Fase 0 revisados por el owner permanecen intactos. Sus estados históricos G0pendiente no se reescribieron: esta acta registra la autorización y transición posterior. No se repitió la auditoría Fase 0; solo sus precondiciones concretas y la integridad de los objetivos autorizados.

La herramienta de worktree administrada no ofrece repositorio/destino exactos y este chat no tiene repositorio adjunto. Se usó el fallback Git por directorio ya descrito y aprobado, sin --force, checkout del original o limpieza.

## 2. Resultado de creación

|Repo|Worktree absoluto|Rama local|HEAD|Estado|
|---|---|---|---|---|
|Backend|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\backend-core|fix/avance2-core-security|3a3309398458ab333d7b00f16e9c2df6a09ef734|Limpio; sin staged/unstaged/untracked; sin commits nuevos|
|Flutter|C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\flutter-core|release/avance2-frontend-v1|095e899ace31acf17d97bbe945c118c1a5d88682|Limpio; sin staged/unstaged/untracked; sin commits nuevos|

Comandos efectivamente ejecutados:

~~~powershell
git --no-optional-locks -C 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\Backend_Nestjs\saas-platform-backend' worktree add -b 'fix/avance2-core-security' 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\backend-core' '3a3309398458ab333d7b00f16e9c2df6a09ef734'
git --no-optional-locks -C 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\PlataformaFlutter\saas-platform-client' worktree add -b 'release/avance2-frontend-v1' 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\flutter-core' '095e899ace31acf17d97bbe945c118c1a5d88682'
~~~

Ambos devolvieron exit0. Cada repo ahora registra su checkout original y el candidato nuevo. No se configuró upstream ni se publicaron ramas. Las puntas apuntan exactamente a los commits ya existentes; no hay commits de implementación. Base y árbol checkout coinciden por identidad del commit.

## 3. Revalidación y preservación

Antes: bases remotas verificadas con ls-remote sin fetch, objetos locales commit existentes, nombres/destinos ausentes, hooks activos no encontrados y core.longpaths=true. Documentos locales y cuatro informes F0 conservaban sus hashes. Todo pasó antes de la primera mutación.

Después: únicamente aparecen las dos refs nuevas aprobadas y los registros worktree correspondientes. Ninguna ref previa, HEAD o rama activa de los originales cambió. Service/Engine conservan HEAD/status/refs/worktrees. Integridad completa: [evidencia07](evidencias/07_INTEGRIDAD_FINAL.json).

|Original preservado|Rama activa / HEAD|Estado documental|
|---|---|---|
|Backend|feat/prospector-service-mvp-integration / a80871b6c5ebf39b4fca69eaf5f6352ab342da96|Limpio; sin cambios nuevos.|
|Flutter|feat/flutter-prospector-mvp-parity /97ad02a621007e4139e5207511ecca2376754ed8|Mantiene exactamente la eliminación local de Plan de Trabajo.md y los dos documentos sin seguimiento; no se restauró ni stageó.|
|Service|feat/fastapi-service-foundation /69c54a15601d238638610d0a5c08af46e3da7f14|Limpio y preservado.|
|Engine|main /70f6081688db5c5bc5ea612f5fabd5724aab0b20|Limpio y preservado.|

Las copias documentales congeladas de F0 siguen idénticas a los archivos del usuario; la eliminación local permanece deliberadamente intacta. Los nuevos checkouts contienen los archivos propios de sus commits base, sin transportar las modificaciones documentales del original. El plan rector se consulta desde el original/copia congelada, no se sustituye por otro plan de un checkout nuevo.

## 4. Trabajo de preparación G1 entregado

[DETALLE_IMPLEMENTACION_G1.md](DETALLE_IMPLEMENTACION_G1.md) concreta B01–B08/F01–F09 de la matriz revisada: SEC-01 por método, config/413 y dependencias candidatas, invariantes snapshot/schema/Jobs, documentación y UI core, panel demo sin red y tests/harness propuestos. Contiene comandos con efectos y gates pendientes. No se escribió ese código ni los tests.

[AMPLIACION_PROPUESTA_DEMO_COMPOSE_1_1.md](AMPLIACION_PROPUESTA_DEMO_COMPOSE_1_1.md) registra CR-AV2-DEMO-110-01. El owner fija como objetivo B un entorno implementado y validado con arranque único, ampliando la salida de propuesta de Fase 7. Diseño final y ejecución no están aprobados. Define12 criterios de aceptación y separa transporte real, fixtures controlados, Engine instalado/probe local y extracción real pendiente.

Dos dependencias críticas de B: el core A no ejecuta búsquedas y la reutilización P2 exige decidir almacenamiento local; HTTP entre nombres DNS Docker no satisface las allowlists loopback actuales. La propuesta ofrece red compartida loopback o TLS interno para revisión, sin relajar guards productivos ni aplicar migración. No se creó ningún archivo Compose, rama B o contenedor.

## 5. Prerrequisitos observados y límites

Docker 29.9.2, Compose 5.6.1 y daemon Linux responden a consultas de versión; el primer acceso sandbox al pipe fue insuficiente y la consulta de solo lectura autorizada lo confirmó disponible. Esto no es rechazo de aprobación ni prueba de imagen/stack. No se arrancó Docker ni se cambiaron sus ajustes.

SDK Flutter local existente: .flutter-sdk, cache 3.47.5 stable/Dart 3.13.4. Se leyeron presencia y versión cacheada; no se ejecutó Flutter ni inicializó/actualizó SDK. No está en PATH; los futuros comandos deben resolver ese ejecutable o imagen fijada. Host Node 22.16.0 difiere del target20.x; la actualización Node del producto sigue diferida por decisión del owner.

Pruebas funcionales, builds, instalaciones, migraciones y scraping ejecutados en este tramo: **0**. No se alteraron Supabase/Render/Vercel, Service ni datos. Las inspecciones de archivos y Docker son de solo lectura; las únicas mutaciones Git son la preparación explícitamente autorizada de ramas/worktrees.

## 6. Dictamen y próxima autorización

**GO: preparación G0 terminada y verificable. GO técnico para revisar el detalle de G1; G1 NO APROBADO.**

Solicitar autorización G1 únicamente para la implementación local A descrita, con decisión expresa sobre B06/regeneración lock. G2 cubre después instalaciones/pruebas/DB desechable concretas; G3–G5 publicación/integración/promoción/despliegue requieren permisos explícitos. G6 y una aceptación técnica adicional abren B; G1 de A no lo habilita.

Se detiene aquí, antes de modificar código. No merges, commits, pushes, cambios de infraestructura, migraciones P2 ni búsquedas externas. El objetivo adicional de presentación no altera las puertas de autorización.

Evidencias: [revalidación](evidencias/01_REVALIDACION_G0.json), [creación/estado](evidencias/02_CREACION_Y_ESTADO.json), [prerrequisitos](evidencias/03_PRERREQUISITOS_LECTURA.json), [referencias G1](evidencias/04_REFERENCIAS_G1.json), [propuesta/SDK](evidencias/05_PROPUESTA_Y_ENTORNO.json), [matriz estructurada](evidencias/06_MATRIZ_PROPUESTA_G1.json), [integridad final](evidencias/07_INTEGRIDAD_FINAL.json). QA y manifiesto se adjuntan como evidencias08/09.
