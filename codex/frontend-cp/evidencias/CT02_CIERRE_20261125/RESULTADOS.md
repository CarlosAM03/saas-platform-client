# CT-02 · Validación funcional del 25 de noviembre de 2026

| Validación | SHA de frontend | Resultado |
| --- | --- | --- |
| Regresión Flutter y análisis estático | `2ae32ab391d159b13b513b44b8240204d97b2f57` | 335 pruebas aprobadas, una prueba exclusiva de Chromium omitida en VM. Sin hallazgos de análisis. |
| Flutter Web release | `2ae32ab391d159b13b513b44b8240204d97b2f57` | Compilación local aprobada con Flutter 3.47.5, Dart 3.13.4 y API de loopback. Flutter avisó sobre la familia no incluida CupertinoIcons. |
| T32 Flutter → NestJS → PostgreSQL 16.15 | `e2b27cbe69e8b2d0d6fa753de641ed3a0ed51211` | 13 casos aprobados, incluidos los tres filtros del resumen. [Recibo](T32.json) |
| Contrato OpenAPI servido | `e2b27cbe69e8b2d0d6fa753de641ed3a0ed51211` | 25 operaciones, 39 rutas, 77 esquemas. Hash normalizado idéntico al handoff. [Recibo](CONTRATO.json) |
| CI del checkpoint CP | `2ae32ab391d159b13b513b44b8240204d97b2f57` | foundation, container y production-container aprobados. CI ejecutó también la prueba de historial Chrome. [Run 45695225854](https://github.com/CarlosAM03/saas-platform-client/actions/runs/45695225854) |

El código de la aplicación, assets, configuración Web y lockfile son idénticos entre el SHA local de regresión y el de T32. El segundo commit ajusta la superficie Material del arnés de captura para evitar que Flutter marque como invisibles los efectos Ink de ListTile dentro de una caja opaca. La prueba conservó su aserción de ausencia de excepciones.

T32 usó el backend contractual `779fc7885faefdfe9e3cb0f3fee86810d96d2711` con su PostgreSQL 16.15 en un laboratorio desechable. Probó altas, edición contextual, actividades y correcciones, asignación PUT/DELETE, importación CSV, respuestas 400/403/404 y lectura con tenant ajeno. El resumen abrió prospectos en página uno por etapa, responsable sin asignar y evaluación pendiente, y contrastó los conteos visibles con la respuesta real. MEMBER no podía crear ni importar. La regresión complementó esta corrida con descarte de respuesta tardía al sustituir tenant, manejo de errores y reintento de lectura.

El checkpoint fuerza una nueva selección al volver a abrir el mismo filtro del resumen tras modificarlo en la lista. Añadió una aserción de regresión y cambió el destino de los recibos locales para preservar T32 y OpenAPI históricos. La configuración de Vercel restringe el auto-preview únicamente en las dos ramas de este encargo.

## Candidato móvil

La revisión en Chromium detectó que el rótulo «Resumen comercial» desaparecía parcialmente en 390 px. Las pestañas ahora se pueden desplazar horizontalmente cuando el ancho disponible o la escala de fuente requieren más espacio. En escritorio conservan la distribución anterior. La regresión específica verifica la apertura de la pestaña con desplazamiento y los tres filtros desde el resumen.

| Validación | SHA probado | Resultado |
| --- | --- | --- |
| Flutter analyze y Web release | `9fa71984af9cf8ef135149f7803662a7dd904c88` | Sin hallazgos de análisis. Web release compilada para API sintética de loopback. |
| Flutter test | `49665c82f8c22cf145a08f36daab8a504737811e` | 335 aprobadas, una exclusiva de Chromium omitida en VM. |
| T32 y contrato | `49665c82f8c22cf145a08f36daab8a504737811e` | 13 casos y 25 operaciones aprobados. [T32](T32-MOVIL.json) · [Contrato](CONTRATO-MOVIL.json) |
| Chromium 156.0.8078.4 | `9fa71984af9cf8ef135149f7803662a7dd904c88` | Recorrido aprobado en 1440 × 960 y 390 × 844. [Recibo](CHROMIUM.json) · [Captura móvil del resumen](capturas/mobile-resumen.png) |

El código, assets, configuración Web y lockfile coinciden entre los dos SHA del candidato móvil. Chromium ejercitó login, selección de organización, carga del dashboard, los tres GET de filtros sobre página uno, cierre de sesión y redirección desde una URL protegida. T32 complementa el navegador con escrituras, CSV, roles y aislamiento. La revisión de accesibilidad cubrió nombres semánticos, foco de entrada y rótulos en pantallas estrechas. La validación con lector de pantalla y dispositivo físico queda para la aceptación posterior.

### Repetir Chromium

Con el laboratorio de este repositorio activo, compilar Web con el origen sintético `http://127.0.0.1:18741` y ejecutar desde la raíz.

```powershell
npm install --prefix codex/frontend-cp/.local/browser --no-save --no-package-lock playwright-core@1.65.1
$env:CHROMIUM_EXECUTABLE = '<ruta a chrome.exe o chromium>'
$env:CP_BUILD_SHA = '<SHA con el que se compiló flutter build web>'
node tool/sprint-cp/browser-qa.mjs build/web codex/frontend-cp/.local/chromium
```

El runner levanta un servidor local en el puerto 18742, bloquea solicitudes del navegador a otros orígenes y crea un fixture sintético nuevo. Las capturas del login se obtienen con el formulario vacío. Al terminar, apagar el laboratorio para descartar la base de datos desechable.
