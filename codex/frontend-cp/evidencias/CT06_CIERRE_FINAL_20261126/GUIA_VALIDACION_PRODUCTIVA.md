# Guía de validación productiva — André

Esta guía se ejecuta **después** de que Carlos despliegue el PR #18. No sustituye la aceptación: hasta que André complete el recorrido, el dictamen productivo es NOT_RUN.

## Antes de empezar

1. Confirmar con Carlos el SHA desplegado y la URL de Vercel (producción informada: `https://saas-platform-client-web.vercel.app/#/login`).
2. Confirmar que el backend `590aaf0` y el Prospector Service están disponibles ese día.
3. Usar únicamente cuentas de prueba acordadas; no pegar contraseñas ni tokens en capturas o reportes.
4. Registrar por caso: hora, rol, URL, resultado, código/correlation ID si falla y captura saneada.

## ADMIN

1. Entrar sin organización activa y abrir `/#/tenants`: deben listarse las organizaciones reales.
2. Abrir `/#/tenants/new`: comprobar el formulario de registro y el aviso de que «ACCEPTED» es aceptación del transporte, no entrega al buzón.
3. Abrir el onboarding de una organización de prueba: verificar estados de activación/entrega y que el reenvío advierte la invalidación de enlaces.
4. Seleccionar una organización y abrir `/#/users`: listado y detalle sin 404 indebido. Si aparece un error, capturar solo estado HTTP, `requestId`, ruta y rol.
5. Dashboard: métricas de campañas/prospectos/lotes reales; no debe haber cifras inventadas.

## OWNER

1. Iniciar sesión normal y seleccionar la organización.
2. Dashboard: la tarjeta «Lotes» y «Lotes recientes» deben usar totales reales. «Buscar prospectos» debe estar visible.
3. `/#/generate`: seleccionar campaña, enviar un lote pequeño autorizado. Verificar estados separados de admisión, ejecución, disponibilidad y calidad.
4. `/#/jobs`: historial propio paginado; abrir un lote, actualizar/consultar estado y regresar. Probar recarga directa de `/#/jobs/<id>`.
5. Revisar resultados: elegir acción por fila (crear/vincular/actualizar solo si procede/omitir), confirmar y verificar incorporación y conteos. Repetir la consulta de estado no debe duplicar registros.
6. Exportar CSV y XLSX; abrir ambos archivos.
7. Campañas: crear/editar una campaña de prueba, abrir pestañas Detalle, Prospectos y Resumen comercial; registrar una actividad y una corrección en una participación.
8. Alta manual de prospecto: probar coincidencia fuerte, candidatos débiles y 409 de información cambiada.
9. Importación CSV: archivo ≤5 MB, previsualizar, decidir por fila y confirmar; revisar el resumen.
10. Cerrar sesión y abrir una URL protegida: debe volver a login.

## MEMBER

1. Iniciar sesión y seleccionar la organización.
2. Dashboard: **no** debe mostrar «Buscar prospectos», tarjeta «Lotes», panel «Lotes recientes» ni «Ver lotes».
3. Navegación de escritorio/móvil: no debe existir acceso «Lotes» ni «Buscar prospectos» en el menú.
4. Abrir por URL `/#/jobs`, `/#/generate` y `/#/prospects/new`: debe mostrarse «No tienes permisos para realizar esta acción.» y no debe salir ninguna petición a `prospecting-batches` (verificar en DevTools → Network).
5. Campañas y prospectos permitidos: consultar y editar lo autorizado; probar un 403/404 real de otro tenant y confirmar que no se muestran datos ajenos.

## UI/UX y responsive

- Revisar 1440×960 y 390×844: sin overflow, menús coherentes, foco visible, botones con nombres accesibles y estados de carga/vacío/error/reintento.
- Repetir con escala de texto del navegador aumentada.
- No se introdujo un rediseño nuevo; cualquier diferencia visual debe contrastarse con las capturas CT-06 y la propuesta CT-05.

## Si algo falla

No cambiar código ni configuración productiva desde esta validación. Reportar a Carlos con: hora, SHA, rol, tenant, ruta, pasos, esperado/observado, estado HTTP, `requestId` y captura saneada. Si el fallo es de Vercel/Render/Service, esperar la intervención de Carlos y revalidar.

## Cierre

- PASS por caso solo con el flujo observado completo.
- BLOCKED no se convierte en PASS.
- Guardar el registro final en `EVIDENCIAS.md` (sección Handoff) con fecha, SHA de Vercel y responsable.
