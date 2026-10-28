# ESPACIO DE TRABAJO Y EVIDENCIAS DE CODEX

**Proyecto:** PROSPECTOR SaaS — Segundo Avance / estabilización Flutter Core V1.0.0  
**Directorio:** `codex/evidencias/`  
**Estado inicial:** reservado para la ejecución; **todavía no contiene evidencias de trabajo**.  
**Responsable de ejecución:** Codex, exclusivamente dentro del encargo autorizado.  
**Autoridad de revisión y aceptación:** owner técnico del proyecto.

## 1. Propósito de esta carpeta

Esta carpeta es el **espacio exclusivo de Codex para organizar los documentos, evidencias, resultados de pruebas y archivos auxiliares seguros** que genere durante el sprint de paridad 1:1 entre Flutter y Platform Backend 1.0.0.

No contiene código de producción ni sustituye los directorios `lib/`, `test/`, `tool/` o `Docs/` del repositorio Flutter. Es un espacio de **trazabilidad y apoyo**: el código, los tests y las correcciones deben permanecer en las ubicaciones que establece la arquitectura del proyecto.

**Este `README.md` es el único archivo que debe existir inicialmente en `evidencias/`.** Los demás archivos o subdirectorios se crearán **únicamente cuando Codex efectúe las actividades correspondientes**; no se deben prellenar resultados, pruebas ni reportes.

## 2. Normas que gobiernan su uso

El orden de lectura del harness es:

1. `../01_PLAN_RECTOR_SPRINT_FRONTEND_1A1.md` — alcance, decisiones y gates aprobados.
2. `../02_NORMATIVA_CODEX.md` — restricciones, autoridad, seguridad y evidencias.
3. `../03_GUIA_EJECUCION_AUTONOMA.md` — procedimiento operativo y formatos de entrega.
4. **Este archivo** — destino y política de los artefactos generados.

Este README **no amplía facultades de Codex** ni autoriza cambios al Backend, merges, despliegues, escrituras remotas o ejecución fuera del sprint. Si surge una contradicción, prevalecen los documentos superiores y la decisión expresa del owner.

## 3. Material permitido durante la ejecución

Codex podrá guardar aquí, **después de haberlos generado realmente**:

- Inventarios de repositorios, ramas, commits, configuración no sensible y versiones verificadas.
- Matrices de paridad entre pantalla Flutter, cliente `PlatformApi`, contrato Backend y operación implementada.
- Hallazgos reproducibles, análisis de causa, decisiones pendientes y justificación de cambios.
- Informes de pruebas unitarias, de widgets, contratos, P2C y E2E locales, con comandos y salidas sanitizadas.
- Evidencias de escenarios `UI → API Client → NestJS → Prisma → PostgreSQL`: acciones de interfaz, códigos HTTP, comprobaciones SQL locales, relectura y limpieza de datos sintéticos.
- Capturas, trazas o registros **previamente sanitizados** que permitan comprobar un resultado concreto.
- Informes de smoke remoto ejecutado con autorización, límites, identificación del despliegue y resultados verificables.
- Documentos de apoyo, comparativas, notas de integración ADR-006 **sin implementarla en este carril**, y handoff de QA/PR.

Los nombres sugeridos y formatos de entrega se encuentran en la **sección E12.2 de la Guía 03**. No es obligatorio crear todos los archivos desde el inicio; cada uno nace cuando exista evidencia que reportar.

## 4. Reglas de trazabilidad y calidad

Cada resultado debe indicar, cuando corresponda: **fecha/hora, repositorio, rama, SHA, entorno, identificador del caso, acción, expectativa, resultado observado, comando y código de salida, referencia de evidencia y estado**.

Los únicos estados válidos son:

- `PASS`: prueba efectivamente ejecutada y satisfactoria.
- `FAIL`: prueba ejecutada con resultado fallido.
- `BLOCKED`: no pudo ejecutarse por una limitación identificada y documentada.
- `NOT RUN`: no se ejecutó.

No convertir `BLOCKED` o `NOT RUN` en `PASS`; no presentar un mock, un smoke parcial o una respuesta HTTP aislada como E2E integral. Los resultados deben poder rastrearse al **SHA exacto** y al entorno en que se obtuvieron. Cada evidencia debe referenciarse mediante su **ruta relativa dentro de esta carpeta**, sin inventar archivos ni enlaces.

## 5. Seguridad y manejo de materiales sensibles

**No guardar ni versionar aquí** contraseñas, JWT, cookies, cabeceras `Authorization`, `.env`, `DATABASE_URL`, secretos SMTP, enlaces o tokens de activación, datos reales de clientes, volcados de bases de datos, HAR autenticados sin sanear ni capturas que expongan información privada.

Los insumos sensibles indispensables para ejecutar pruebas deberán permanecer **fuera del repositorio**, en ubicaciones locales protegidas y autorizadas. Antes de incorporar una evidencia, sanitizarla **sin alterar el resultado técnico**. Si una salida no puede sanearse con seguridad, registrar un resumen verificable y la razón por la que no se adjunta el artefacto bruto.

No copiar aquí caches, dependencias, builds, volúmenes Docker, temporales de herramientas ni archivos masivos ajenos al entregable. Evitar publicar rutas absolutas privadas y correos reales.

## 6. Organización, limpieza y entrega

Codex puede crear subcarpetas temáticas o por ejecución (`runId`) **solo cuando ayuden a la trazabilidad**, manteniendo identificadores estables y evitando duplicados. Los archivos auxiliares no destinados al PR deben permanecer fuera del repositorio o quedar excluidos de versionado de forma segura, sin alterar de manera unilateral las reglas globales de Git.

**No borrar ni sobrescribir** evidencia previa, trabajos ajenos o datos no identificados. Si existe una versión anterior, conservar su trazabilidad o documentar el reemplazo autorizado. Las verificaciones SQL y la limpieza de fixtures se realizan en el **entorno de pruebas designado**, nunca desde esta carpeta como autorización para operar una base de datos.

Al cerrar cada fase, Codex debe actualizar el estado de los artefactos **realmente existentes** y enlazarlos desde su reporte. Al terminar el sprint, entregará un **handoff de QA** con los resultados, bloqueos, deuda, referencias a commits/PR si existen y requisitos que aún requieren autorización humana.

## 7. Declaración inicial

En el momento de preparar este harness **no se han realizado mediante esta carpeta pruebas E2E, correcciones, merges ni despliegues**. La presencia de `evidencias/README.md` solo establece dónde Codex documentará su trabajo. La aceptación de los gates y del release corresponde exclusivamente al owner técnico.

## Ejecución del 28 octubre 2026

[Handoff QA](handoff-qa.md):279 pruebas; dos corridas32/32; seis negativos HTTP_SQL; P2C y smoke remoto autorizados. G2/G4 requieren decisión/verificación humana. Las credenciales están excluidas. Ver matriz-e2e.md, test-resultados.md y hallazgos.md. Los históricos de intentos conservan sus estados.
