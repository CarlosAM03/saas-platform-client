# Objetivos visuales y flujos de usuario

Backend de referencia: `3b5eec6fa99f846e853794fc8aedff2c4353c269`.

El sprint **extiende** los módulos Flutter existentes: tabs de detalle de campaña, listado de prospectos, ficha de prospecto, importador CSV y dashboard del tenant. No se reconstruyen ni se sustituye el dashboard global.

## 1. Lista de prospectos de una campaña (C1/C2/C4/C6)

Pantalla existente de prospectos dentro de la campaña.

1. La tabla muestra columnas maestras (nombre, categoría, correo, estado del maestro) y columnas de **participación**: etapa comercial, evaluación, responsable.
2. Barra de filtros con: búsqueda libre (`search`), categoría, dirección, fuente, etapa, evaluación, responsable (incluye "Sin asignar" → `UNASSIGNED`), rango de incorporación y rango de actividad.
3. Estado visible cuando hay filtros activos; el `total` viene del `meta`, nunca se calcula en el cliente.
4. Paginación server-side (`page`, `limit` ≤ 100); el orden se pide con `sortBy`/`sortOrder`.
5. Etiquetas obligatorias: "Estado del maestro" (ACTIVO/INACTIVO) no es "Etapa comercial".
6. Errores: 400 por fecha inválida o sin zona, 404 si la campaña no es del tenant.

## 2. Detalle de participación (C1/C2/C3/C4)

Panel o tab de detalle al abrir un prospecto dentro de la campaña.

1. Cabecera con etapa comercial, evaluación (+ motivo cuando `NO_APTO`), responsable actual y su elegibilidad.
2. Cambio de etapa: selector con las seis etapas; envía `PATCH .../stage`; refresca participación y bitácora.
3. Cambio de evaluación: selector + campo obligatorio de motivo cuando se elige `NO_APTO`; el backend rechaza sin motivo (mostrar el 400 del servidor).
4. Responsable: selector alimentado por `GET .../responsibles`; opción "Sin asignar" usa `DELETE`. Si el responsable actual aparece con `eligible: false`, mostrar aviso "pendiente de reasignación" y no borrar la referencia.
5. Cualquier 404 debe mostrarse como "no encontrado o fuera de tu organización", sin detalles del otro tenant.

## 3. Bitácora contextual (C3)

Dentro del detalle de la participación.

1. Lista paginada con autor, tipo, fecha de registro (`recordedAt`) y fecha declarada (`declaredAt`) cuando exista.
2. Distinción visual: **declaración humana** (nota/llamada/correo/reunión/otra/**corrección**) vs **evento automático** (asociación, cambio de etapa, cambio de evaluación, cambio de responsable). No mezclar ambas listas sin etiqueta.
3. Nueva actividad: formulario tipo + contenido (+ fecha declarada opcional). El tipo `CORRECTION` **no** se elige en el formulario: se genera enviando `correctsId` desde una entrada existente ("Corregir").
4. La corrección abre un formulario con el contenido nuevo; el original permanece visible y enlazado.
5. Nunca afirmar que la plataforma envió la llamada/correo: la UI dice "registrada".

## 4. Alta manual con coincidencias (P1)

Botón "Nuevo prospecto" en la campaña.

1. Formulario con datos maestros y campos opcionales de identidad externa (`identitySource: google_maps`, `identityIdentifier`).
2. Al enviar: `POST /prospects/match` primero.
3. Si `strongProspect` no es null → mostrar "Se reutilizará el prospecto existente" y confirmar con `POST /prospects` (el backend reutiliza y asocia).
4. Si hay candidatos débiles → pantalla de decisión explícita: Crear de todas formas (`CREATE`), Vincular al candidato (`LINK_EXISTING` + `candidateId`) u Omitir (`SKIP`) vía `POST /prospects/resolve`.
5. Si el backend responde `409` porque el candidato cambió, mostrar "La información cambió, vuelve a verificar" y repetir `match`; **no** reintentar el resolve con el mismo `candidateId`.
6. En caso 409 por colisión de identidad: mensaje de conflicto, sin ofrecer "fusionar".

## 5. Ficha del prospecto maestro (P2/P3)

Pantalla de ficha existente.

1. Bloque "Campañas asociadas": lista de `GET /prospects/{id}/campaigns` con campaña, `isOrigin` ("Origen"), etapa, evaluación, responsable y última actividad. Paginada.
2. Bloque "Procedencia global": lista de `GET /prospects/{id}/provenance` con tipo (`CREATED/LINKED/REAPPEARED/MASTER_UPDATED`), fecha, actor y campaña cuando aplique. Sólo eventos confirmados.
3. Edición del maestro con `PATCH /prospects/{id}`. Si la edición se hace desde una campaña, enviar `contextCampaignId` para que se registre `MASTER_UPDATED` en esa campaña; avisar que el cambio se verá en **todas** las campañas del maestro.
4. No mostrar `MASTER_UPDATE` como algo que la UI pueda crear: el enum lo admite por contrato, pero la implementación no lo emite.

## 6. Importador CSV (P4)

Flujo existente de importación, adaptado al contrato.

1. Selección de campaña y archivo; validar en cliente tamaño ≤ 5 MB y extensión `.csv` (el backend rechaza Excel).
2. `preview` → tabla por fila con clasificación (`NEW/MATCH/INVALID/CONFLICT`), valores, errores y coincidencias.
3. Para filas con coincidencia: elegir acción; con múltiples candidatos sólo `CREATE` o `SKIP`.
4. `confirm` con `previewReference` y `decisions` (JSON serializado). Mostrar `summary` y el resultado por fila (`CREATED/LINKED/UPDATED/SKIPPED/REJECTED`).
5. Si `previewReference` vence (15 min) o el resultado es 409, volver a hacer preview; no inventar estados intermedios.
6. No ofrecer "deshacer importación": no existe endpoint; la reversión es por rollback del backend ante fallo.

## 7. Dashboard de campaña (C8)

Pantalla o tab de resumen dentro de la campaña (distinto del dashboard global del tenant).

1. Tarjeta de total de participaciones.
2. Distribuciones de etapa y evaluación con suma = total.
3. Responsabilidad: sin asignar, no elegibles (`NO_ELEGIBLE:{userId}`) y asignados.
4. Actividad: total, **manual** y **automática** (`activity.manual` / `activity.events`), con nota "las correcciones cuentan como manuales".
5. Incorporación: nuevas, reutilizadas, desconocidas (legado).
6. Los números se leen de una sola respuesta; no recalcular sumas en cliente ni mezclar respuestas de distintas llamadas.

## 8. Estados y accesibilidad

- Estados por pantalla: cargando, vacío (mensaje explícito, sin ceros falsos), error con reintento.
- Mensajes de error derivados de `error.code` y `error.message`, nunca inventados.
- Textos y botones con etiquetas accesibles; no depender sólo del color para distinguir manual vs automático.
