# Beta frontend reconciliada — 26-10-2026

La beta conserva la UI compatible de André sobre Foundation y PlatformApi del propietario.
Usa Inter local con licencia OFL, login con validación y mostrar contraseña, tarjetas,
superficies, estados visibles, organización activa en el encabezado, filtro de estado en la página actual, cuadrícula responsiva y navegación lateral desde 700 px e inferior en móvil.
Se retiró PlatformRepository dinámico y se adaptaron las pantallas a DTOs, permisos y
repositorios tipados. No hay mocks ni credenciales incrustadas en código productivo.

## Recorrido disponible

1. Login con una cuenta existente de prueba autorizada.
2. Seleccionar organización; ADMIN puede descubrirlas y abrir creación sin tenant previo.
3. Consultar dashboard: conteos de meta.total y registros recientes con enlaces reales.
4. Crear campaña con validación y confirmación explícita. Consultar detalle y prospectos asociados; editar estado/atributos o archivar con confirmación. Borrado permanente sólo ADMIN según Backend.
5. Consultar y editar prospectos. ADMIN/OWNER pueden crearlos manualmente eligiendo una campaña e importar CSV; MEMBER puede consultar/editar según Backend. No hay endpoint para borrar prospectos.
6. CSV: seleccionar campaña/archivo, revisar preview, coincidencias y conflictos, elegir decisiones y confirmar. Revisar advertencia de cambios compartidos. Si la respuesta es incierta, verificar la campaña antes de otra importación.
7. Consultar Trabajos y detalle. La generación automática muestra su indisponibilidad; cancelar/guardar/exportar no se presentan como disponibles.
8. Consultar Usuarios, Perfil y Organizaciones; cambiar organización o cerrar sesión. Formularios y providers se reinician al reemplazar la sesión.

El Backend es la autoridad final de autorización. La UI obtiene la membresía real y
comprueba que el rol corresponde al tenant; no deduce permisos de un tenantId arbitrario.
No hay registro público, OAuth, recuperación de contraseña ni notificaciones inventadas.

## Ejecución y compilación

Desde la raíz del cliente, usando Flutter 3.47.5 / Dart 3.13.4:

```powershell
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter run -d chrome --web-port=4200 --dart-define=API_BASE_URL=https://api.tudominio.com
flutter build web --release --no-wasm-dry-run --dart-define=API_BASE_URL=https://api.tudominio.com
```

API_BASE_URL debe ser el origen sin /api/v1, query, fragmentos ni credenciales. Fuera de
localhost se exige HTTPS. La variable se incorpora al compilar; cambiarla requiere rebuild.
El script scripts/Run-Beta.ps1 conserva el inicio local con un origen indicado por el usuario.
Ver [Despliegue-Web.md](Despliegue-Web.md) para Preview/Vercel y CORS.

Las capturas opcionales se producen con:

```powershell
flutter test --no-pub test/beta_flows_test.dart --dart-define=BETA_SCREENSHOTS=true
```

Son fixtures de QA en build/beta-qa, nunca datos reales ni entregables versionados.
Los resultados actuales constan en la [auditoría](Auditorias/Auditoria_Reconciliacion_Dev_2026-10-26.md).
Las validaciones históricas de esta beta permanecen en Git; no certifican la revisión actual.
No se han verificado Android/iOS ni el recorrido E2E con cuentas reales en esta entrega.
