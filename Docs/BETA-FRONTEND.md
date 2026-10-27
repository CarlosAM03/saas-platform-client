# Beta frontend 0.2

Implementación basada en [LineamientosUI-UX.md](DocsTeam/Documentacion%20UIUX/LineamientosUI-UX.md), el contrato `platform-api.v1.yaml` y los controladores y servicios actuales de `saas-platform-backend`. La beta utiliza datos reales del backend; los ejemplos se limitan a las pruebas automatizadas.

## Ejecutar con el backend desplegado

Desde la raíz del cliente, sustituir el dominio por el servidor real:

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --web-port=4200 --dart-define=API_BASE_URL=https://api.tudominio.com
```

`API_BASE_URL` es el origen del servidor: no debe terminar en `/api/v1` ni `/api/docs`. Los repositories añaden los paths del contrato. `.env.example` es documental; Flutter no lo carga. No introducir contraseñas ni tokens en archivos de configuración.

En Windows también se puede ejecutar:

```powershell
.\scripts\Run-Beta.ps1 -BackendUrl https://api.tudominio.com
```

El script usa Chrome si está instalado, o Edge como navegador compatible. Para otro destino Flutter, usar el comando directo con `-d <dispositivo>`.

El backend debe permitir `http://localhost:4200` en `CORS_ORIGINS` para esta prueba web. Configurar HTTPS para frontend y API al publicar. Usar un usuario ya creado en el servidor: se retiraron la cuenta provisional y el registro público simulado.

## Primer recorrido

1. Iniciar sesión con una cuenta existente.
2. Seleccionar organización. ADMIN puede crear una organización desde esta pantalla; no necesita tener una membresía para descubrirla.
3. Consultar Inicio y sus contadores reales.
4. Crear campaña: información → confirmación → detalle.
5. Editar nombre, descripción y estado; archivar con confirmación. ADMIN puede eliminar permanentemente si el servidor permite la operación.
6. Consultar prospectos generales o asociados a una campaña. Editar los contactos; vaciar un campo opcional envía `null`.
7. Consultar Equipo. ADMIN y OWNER pueden crear integrantes como MEMBER y editar sus datos/estado/contraseña. ADMIN puede desactivar cuentas ajenas.
8. Consultar Perfil, cambiar organización y cerrar sesión.

La visibilidad de acciones mejora la experiencia; el servidor sigue siendo la autoridad de permisos. El rol de organización se consulta mediante `GET /users/{id}`; no se deduce un permiso a partir de una organización visible. Las consultas se invalidan al cambiar de usuario u organización.

## Correspondencia con UI/UX

| Secciones del documento | Implementación |
| --- | --- |
| 6–12: colores, texto, espaciado, formas | Azul `#2563EB`, fondo `#F8FAFC`, superficies blancas, borde `#E2E8F0`, Inter incluida localmente con licencia OFL, jerarquía 32/24/20/16/14/12, radios 6/10/12 y espaciado en múltiplos de 4. |
| 13–19: componentes y navegación | Iconos Material consistentes, botones, formularios, tarjetas, estados con color y texto, organización en encabezado y selector. Navegación inferior en móvil y lateral desde 900 px. |
| 20–21: carga y acceso | Splash, formulario de login validado, visibilidad de contraseña, errores, sesión expirada y recuperación de conexión. |
| 22–24: inicio y campañas | Contadores de campañas/prospectos, campañas recientes, búsqueda, paginación, chips de estado, detalle y prospectos asociados. |
| 25–26: creación, cuenta y organización | Creación en dos pasos con campos admitidos; edición, perfil, selector y creación de organización por ADMIN. |
| 27–31: estados y feedback | Carga, vacío, error con reintento, guardado, confirmaciones, formularios bloqueados mientras se envían y rutas protegidas. |

## Disponibilidad y límites del backend actual

| Punto | Beta |
| --- | --- |
| Campañas | Crear/listar/buscar/consultar/editar/archivar; eliminación permanente solo ADMIN. |
| Prospectos | Listar/buscar/consultar/editar contactos existentes; no existe alta manual ni borrado en el contrato actual. |
| Usuarios | Listar/buscar/crear/editar/desactivar según permisos. No hay endpoint para descubrir o gestionar roles; no se presenta un selector de roles con valores inventados. |
| Organizaciones | Listar/consultar/seleccionar y crear como ADMIN. Sin edición o borrado porque no existen endpoints. |
| Trabajos | Historial paginado y detalle real. Generación, cancelación, persistencia y exportación no operativas: pantalla explica su disponibilidad futura. No se simula aceptación ni progreso. |
| Métricas del boceto | Totales reales y número de prospectos asociados. Contactados, conversión, porcentaje de progreso y actividad reciente no están expuestos; no se inventan valores. |
| Filtro de campaña por estado | Se aplica a la página actual y la UI lo indica. El backend admite búsqueda y paginación, pero no un parámetro de filtro por estado. |
| Registro / recuperación / notificaciones | No hay registro público ni endpoints de recuperación o notificaciones. Login dirige al administrador para obtener acceso o recuperar contraseña. |

## Compilar y distribuir

```powershell
flutter build web --release --dart-define=API_BASE_URL=https://api.tudominio.com
```

Publicar el contenido de `build/web` en hosting estático HTTPS y permitir el origen público del frontend en CORS. La URL se fija al compilar: cambiarla requiere otra compilación. La compilación local verificada sin `--dart-define` usa `http://localhost:3000`, por lo que no es una conexión verificada al servidor público.

Flutter Secure Storage conserva la sesión con la implementación existente. En web requiere HTTPS o localhost. La beta usa la compilación JavaScript normal; el plugin de almacenamiento actual no es compatible con Wasm. No se comprobó una compilación Android/iOS en esta entrega.

El manifiesto Android incluye permiso de Internet también para release. En dispositivos físicos usar el dominio HTTPS del servidor: `localhost` apunta al propio dispositivo.

## Verificación

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter test --no-pub --dart-define=BETA_SCREENSHOTS=true
flutter build web --release --no-pub
```

Las capturas opcionales se escriben en `build/beta-qa`. Las pruebas cubren sesión, Bearer, permisos de red, navegación, wrappers y paginación, creación confirmada de campaña, edición de prospectos, archivado, organización, errores con reintento y layouts móvil/escritorio. Usan fixtures exclusivamente en `test/`; no verifican credenciales reales, CORS ni la disponibilidad de una instancia desplegada.

Verificación local realizada: `flutter analyze` sin incidencias, 30 pruebas aprobadas, compilación web release exitosa y revisión de capturas en 390×844 y 1280×900. Las imágenes de QA tienen datos de prueba y no son datos de una organización real.

Pendiente para la aceptación contra el servidor real: URL pública y sesión con un usuario existente, revisar CORS y ejecutar el recorrido de inicio, organización, campaña, prospectos, equipo y logout.
