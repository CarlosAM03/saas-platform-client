# CSV, dashboard y Jobs — 22 de octubre de 2026

## Importación CSV

Prospectos → Importar CSV, disponible para OWNER/ADMIN y protegida por ruta directa.
Seleccionar una campaña desde la API paginada, elegir CSV UTF-8 y generar vista previa.
El selector admite hasta 5 MiB; el backend valida las 1,000 filas y las columnas.
La plantilla se puede descargar desde la pantalla.

Las filas nuevas proponen Crear. Las coincidencias proponen Omitir hasta que se elija
Vincular o Actualizar. Cada fila muestra valores, errores, candidatos y diferencias.
Conflictos múltiples e inválidos no permiten una decisión. Actualizar un prospecto
compartido exige advertencia explícita en la confirmación. Una celda vacía presente
puede limpiar el campo; una columna ausente lo conserva, según la decisión backend.

Preview y confirmación reutilizan el mismo ApiUploadFile inmutable. Cambiar campaña
o archivo elimina la revisión anterior. Una vista vencida/obsoleta exige otra preview.
Después de confirmar se muestran creados/vinculados/actualizados/omitidos/rechazados.
No se reintenta una confirmación automáticamente si su respuesta se pierde.

## Dashboard

Conteos totales de campañas, prospectos y trabajos vienen de `meta.total` del backend,
no del número de filas visibles ni de mocks. Muestra las cinco campañas y trabajos
más recientes, con navegación al detalle. No se inventan conversiones ni contactos.
Se puede actualizar manualmente y los datos se eliminan al cambiar sesión/tenant.

## Prospección y Jobs

Buscar prospectos permite elegir campaña, tipo de negocio, ubicación y límite 1–100.
La UI envía una clave idempotente por input y la conserva en reintentos. Todos los
requests van al SaaS Backend; no se llama directamente al Service ni al Engine.

Trabajos lista registros paginados de la organización y abre su detalle. El monitor
consulta cada cuatro segundos sin solapar peticiones; termina en COMPLETED, FAILED,
CANCELLED, error, falta de listeners, cambio de sesión/tenant o destrucción de página.
Muestra progreso real cuando existe, sin inventar porcentajes si es null.

Los resultados disponibles pueden guardarse en campaña o exportarse CSV/XLSX mediante
descarga de bytes del backend. Descartar vista pide confirmación y abandona el detalle,
liberando el estado local; no elimina datos persistidos ni el snapshot remoto.
Sin resultados disponibles se explica su ausencia. Errores 503 no se presentan como
búsquedas aceptadas.

## Rutas nuevas

- `/prospects/import`
- `/generate` (reemplaza el placeholder)
- `/jobs`
- `/jobs/:id`

El menú ofrece Trabajos y Buscar prospectos. Las rutas usan el alcance de sesión y
organización de Foundation y mantienen autorización definitiva en el backend.

## Dependencias y pruebas

file_picker 10.3.10 es compatible con flutter_secure_storage 9.2.4 / win32 5.
Se conserva la versión de secure storage. Web y pruebas se compilan con Flutter
3.47.5. El SDK local de Windows puede exigir Developer Mode para compilar plugins
nativos; eso no impide la compilación Web.

`flutter analyze`, `flutter test`, `flutter build web --no-wasm-dry-run`.
Las pruebas nuevas verifican preview sin escritura, archivo idéntico al confirmar,
expiración/409, permiso MEMBER, reintento idempotente, límite de búsqueda, detención
del monitor y conteos del dashboard. Las pruebas existentes conservan CRUD/Auth.

La integración de backend requiere la migración y configuración documentadas en
`backend/Docs/Prospector-Integration.md`; desplegar sólo este cliente no activa Python.
