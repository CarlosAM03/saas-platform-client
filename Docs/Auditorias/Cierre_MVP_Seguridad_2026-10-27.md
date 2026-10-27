# Cierre de seguridad del núcleo Flutter — 27 de octubre de 2026

Rama: `fix/f5-foundation`. Base auditada: `97645e4a9abcfb52121d74e2b1d6f5a14a73e3ef`. PR Draft [#7 → dev](https://github.com/CarlosAM03/saas-platform-client/pull/7). La paridad Prospector [#8](https://github.com/CarlosAM03/saas-platform-client/pull/8) depende de este PR; no fusionar en paralelo.

## Hallazgo P0 corregido
Los diálogos del navegador raíz conservaban texto de una confirmación o búsqueda de campañas cuando cambiaba la organización o terminaba la sesión. Tres pruebas de widgets reprodujeron el problema antes de la corrección (0/3 aprobadas).

`showSessionDialog` captura el contexto autenticado que abre el diálogo. Cuando cambia usuario, tenant, JWT/contexto o estado de autenticación, oculta el contenido en el primer frame que observa el cambio y retira la ruta concreta sin animación ni confirmación. Aplica a confirmaciones compartidas, selectores de campañas, CSV y acciones de Jobs. Las protecciones de requests y formularios existentes siguen vigentes.

Evidencia: `test/features/session_dialog_test.dart`, con cambio de tenant, logout y búsqueda privada. Resultado posterior 3/3. Regresión completa Foundation: **255 pruebas aprobadas**; build_runner y Flutter analyze aprobados. Los fixtures de CRUD ahora declaran sesión autenticada explícita, sin relajar verificaciones de permisos ni resultados. CI se ejecuta para todos los PR, incluida una base temporal de Foundation.

## Límites
No se ha fusionado a dev/main ni autorizado un despliegue. Las pruebas locales no certifican el SHA servido por Vercel, CORS de Render, backups ni credenciales de producción. El dictamen productivo se concentra en el reporte global de release. El componente Prospector continúa siendo opcional y su activación requiere validación independiente.
