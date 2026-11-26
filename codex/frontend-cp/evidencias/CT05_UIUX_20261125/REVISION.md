# CT-05 · Revisión independiente de UI/UX

La propuesta de André, `28e0ec7bc42fa8a37a840e09b5d38a8f4b9dd527`, y el cierre funcional, `9768b52894750da0eedd341cb448453125cb7151`, son ancestros del candidato probado `21f383a5f0d7e44e4f6b5adddb3e43af2afe2030`. Los dos merges de entrada se resolvieron sin conflictos. El diff de aplicación contra CP conserva los 15 archivos visuales de la propuesta.

## Auditoría

| Superficie | Hallazgo |
| --- | --- |
| AppTheme y CatalogPalette | La paleta y el tema centralizan colores, tipografía, controles, tablas y navegación. Las pruebas existentes de formularios se ejecutaron con el candidato. |
| Login y selección de organización | Cambian el contenedor, los colores y la jerarquía visual del login. Los controladores, validadores, envío, autofill y alternancia de la contraseña se conservan. El selector de organizaciones hereda el tema. Su selección, descubrimiento ADMIN, manejo de errores y navegación son idénticos al carril funcional. |
| AppShell y rutas | Rail extendido de escritorio, navegación inferior en móvil y nuevo estilo del menú de cuenta. El diff de `app_router.dart` se limita a un import y `AppShell`. La tabla de rutas, `redirectForAuth`, restauración de destino, entrada de activación y condiciones de tenant conservan sus implementaciones. |
| Dashboard | Conserva el provider, la recarga y el manejo de errores de trabajos. Cambia la composición del encabezado, métricas y listados recientes. El acceso «Crear campaña» usa `canManageCampaigns` del provider existente. |
| Campañas, prospectos y trabajos | Las vistas de listado usan componentes de catálogo. Conservan rutas de detalle, paginación, filtros y proveedores. La corrección móvil de CP y los accesos desde el resumen comercial están presentes. |
| Componentes reutilizables | CatalogList usa filas con objetivo mínimo de 48 px, encabezados semánticos y apila celdas en espacio reducido o con texto ampliado. Los cambios a FeaturePage y componentes beta son de presentación. |

La comparación de Git acredita igualdad de `lib/features/auth/state`, `lib/core/network`, `lib/core/activation`, `lib/app`, `lib/platform_api`, `web` y manifest/lockfile entre el head CP y el candidato. Las rutas se revisaron por hunks. `sessionScope`, los interceptores, contratos y el almacenamiento de sesión están en los archivos idénticos. La suite completa incluye restauración y cambio de sesión, permisos por rol, acceso directo, activación ADR-006, descarte de respuesta tardía y pruebas móviles de formulario.

## Verificación y capturas

- Flutter 3.47.5 y Dart 3.13.4. Regresión de 335 aprobadas y una exclusiva de navegador omitida en VM. Análisis sin hallazgos y compilación Web release aprobada.
- Chromium 156.0.8078.4 con la aplicación Web real y el backend NestJS `779fc7885faefdfe9e3cb0f3fee86810d96d2711` sobre PostgreSQL 16.15. El recorrido confirmó login, selección de organización, dashboard, tres filtros del resumen en página uno, logout y redirección desde una ruta protegida. [Recibo](CHROMIUM.json)
- Las capturas usan datos sintéticos y estados estables en ambos tamaños. Algunos conteos y nombres de fixture varían entre corridas.

| Pantalla | CP, escritorio | UI/UX, escritorio | CP, móvil | UI/UX, móvil |
| --- | --- | --- | --- | --- |
| Login | [1440 × 960](../CT02_CIERRE_20261125/capturas/desktop-login.png) | [1440 × 960](capturas/desktop-login.png) | [390 × 844](../CT02_CIERRE_20261125/capturas/mobile-login.png) | [390 × 844](capturas/mobile-login.png) |
| Dashboard | [1440 × 960](../CT02_CIERRE_20261125/capturas/desktop-dashboard.png) | [1440 × 960](capturas/desktop-dashboard.png) | [390 × 844](../CT02_CIERRE_20261125/capturas/mobile-dashboard.png) | [390 × 844](capturas/mobile-dashboard.png) |
| Resumen comercial | [1440 × 960](../CT02_CIERRE_20261125/capturas/desktop-resumen.png) | [1440 × 960](capturas/desktop-resumen.png) | [390 × 844](../CT02_CIERRE_20261125/capturas/mobile-resumen.png) | [390 × 844](capturas/mobile-resumen.png) |

La aceptación visual, la experiencia con lector de pantalla y la comprobación en dispositivos físicos quedan para el propietario. El cierre funcional acredita roles, aislamiento y escrituras reales mediante su T32. El recorrido visual no ejecuta generación de prospectos. Consultar el [handoff de reconciliación](../CT03_RECONCILIACION.md) para la integración posterior de los PR funcionales.
