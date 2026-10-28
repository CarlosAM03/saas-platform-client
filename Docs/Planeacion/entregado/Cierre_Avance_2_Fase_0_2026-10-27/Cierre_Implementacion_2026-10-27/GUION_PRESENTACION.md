# Guion de presentación — 27 de octubre, aproximadamente19:00Tijuana

Usar ACCESO_RAPIDO_AVANCE2.md y las credenciales demo privadas. Para resultados experimentales cercanos a la presentación ejecutar Prepare-Presentation.ps1 o crear solicitudes nuevas desde Flutter; los snapshots B duran1h y los anteriores pueden vencer antes de19:00.

1. Core: login ADMIN, mostrar selector de dos organizaciones y gestión autorizada. Seleccionar Demo Norte; pasar a Demo Sur y constatar que campañas/prospectos de Norte desaparecen.
2. OWNER A: mostrar dashboard con datos reales locales, campañas, usuarios y prospectos de Norte. Editar una campaña permitida o recorrer creación/confirmación.
3. MEMBER A: consultar usuarios y gestionar campañas/editar prospectos conforme a guards. Mostrar que no administra usuarios ni CSV y que backend devuelve403 ante operación prohibida. No afirmar que MEMBER es solo lector en toda la plataforma.
4. OWNER B/MEMBER B: repetir consulta breve con Demo Sur y ausencia de datos de A.
5. CSV: plantilla/archivo sintético, preview, decisiones por fila y confirmación; para repetir elegir LINK_EXISTING o SKIP cuando haya coincidencia y regenerar ante409. Teléfono0012345 se conserva como texto. No cargar DATRA ni XLSX en esta demostración.
6. Dashboard: totales reales y refresco después de importación; Jobs: historial/detalle reales. Abrir generación core: DEMO — SIN EJECUCIÓN REAL, avanzar pasos visuales y explicar que no se añade un Job ni datos.
7. Abrir interfaz B separada, etiqueta permanente DEMO INTEGRADA — RESULTADOS CONTROLADOS. Elegir campaña Demo controlada1.1.0 norte, keywordnormal, ubicación de prueba, límite1 y confirmar. Mostrar resultado CONTROLLED DEMO. Keywordempty muestra cero; fail muestra FAILED. Worker/callbacks/PostgreSQL son reales; adaptador no consulta Google Maps. Engine instalado/Chromium comprobado no significa extracción real.
8. Explicar reinicio: memoria Service no durable, generación nueva falla trabajos antiguos; no se reanudan ni repiten solos. Mostrar evidencia experimental-restart-after.json si no conviene reiniciar en vivo.
9. Producción: presentar URL Vercel/Swagger Render solo con estado efectivo posterior del owner; distinguir contrato publicado, commit desplegado y smoke autenticado pendiente cuando corresponda. B no autoriza producción1.1.0.

Respaldo sin red: capturas core-owner-dashboard.png, core-csv-confirmed.png, core-generation-disabled.png, core-*-a/b.png y experimental-created-from-flutter.png/normal.png/empty.png/fail.png; informes JSON de resultados reales. Capturas son evidencia histórica sintética, no datos actuales ni scraping.
