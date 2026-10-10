# Dashboard: cards de campañas

> **Alcance:** solo front end y UI/UX. No se modificó backend, OpenAPI ni infraestructura.
> **Referencia de diseño:** [`LineamientosUI-UX.md`](LineamientosUI-UX.md), sección 16 (Cards) y sección 17 (Badges / Status).

## Resumen

Se reemplazó el placeholder del Dashboard (texto centrado "Dashboard") por una grilla de tarjetas de campañas. Cada card muestra nombre, estado, tres métricas y un enlace "Ver detalles".

Se muestran tres cards de ejemplo, una por estado: **Finalizada**, **Pausada** y **Activa**.

## Archivos

| Archivo | Acción | Descripción |
|---|---|---|
| `lib/features/campaigns/models/campaign.dart` | Nuevo | Modelo `Campaign` y enum `CampaignStatus`, alineados a OpenAPI. |
| `lib/features/campaigns/widgets/campaign_status_badge.dart` | Nuevo | Badge de estado (color + texto + ícono). |
| `lib/features/campaigns/widgets/campaign_card.dart` | Nuevo | Card de campaña. |
| `lib/features/dashboard/data/dashboard_mock_data.dart` | Nuevo | Datos provisionales y provider. |
| `lib/features/dashboard/presentation/dashboard_page.dart` | Nuevo | Página con grilla responsive. |
| `lib/routes/app_router.dart` | Modificado | Se agregó el import de la nueva página y se **eliminó** la clase `DashboardPage` antigua. |

> [!WARNING]
> `lib/routes/app_router.dart` es zona protegida de Carlos (ver `CONTRIBUTING.md`). El cambio es mínimo, pero debe coordinarse con él.

## Decisiones de diseño

- **Card:** fondo blanco, borde sutil `#E2E8F0`, sin sombra, radio de 12 px, padding de 16 px y separaciones en múltiplos de 4.
- **Estado:** se comunica con color, texto e ícono, no solo con color (regla de accesibilidad del documento UI/UX).
- **Grilla responsive:** 1 columna por debajo de 560 px, 2 desde 560 px y 3 desde 900 px.
- **Estados de pantalla:** loading, empty y error reutilizan `AsyncStateView`.

### Estados de campaña

| Valor del contrato | Enum Dart | Texto en UI | Color |
|---|---|---|---|
| `ACTIVA` | `activa` | Activa | Verde `#16A34A` |
| `PAUSADA` | `pausada` | Pausada | Ámbar `#D97706` |
| `COMPLETADA` | `completada` | **Finalizada** | Azul `#2563EB` |
| `ARCHIVADA` | `archivada` | Archivada | Gris `#64748B` |

"Finalizada" es solo el texto de la UI; el valor real sigue siendo `COMPLETADA`. "Borrador" y "Error" (mencionados en el documento UI/UX) no existen en el contrato, por eso no se usan.

## Elementos provisionales

Todo lo que depende de un backend conectado está marcado con:

```dart
// TODO(backend): <qué es provisional> -> <con qué se reemplaza>
```

Los colores hardcodeados que esperan el Design System usan `TODO(design)`.

Para listarlos en PowerShell:

```powershell
Select-String -Path lib\*,test\* -Pattern "TODO\((backend|design)\)" -Recurse
```

### Pendientes al conectar el backend

| Elemento | Ubicación | Qué hacer |
|---|---|---|
| `dashboardCampaignsProvider` | `dashboard_mock_data.dart` | Reemplazar datos y `delay` por un `CampaignsRepository` que llame a `GET /api/v1/campaigns`. |
| `CampaignStatsMock` | `dashboard_mock_data.dart` | Prospectos, Contactados y Conversión **no existen en OpenAPI**. Definir con Ángel de dónde salen o eliminarlos. |
| `CampaignSummaryMock` | `dashboard_mock_data.dart` | Reemplazar por el DTO real. |
| Dependencia de la card | `campaign_card.dart` | Cambiar `CampaignSummaryMock` por `Campaign` real. |
| Filas de estadísticas | `campaign_card.dart` | Conservar, cambiar de fuente o eliminar según la decisión anterior. |
| `onTap` de "Ver detalles" | `dashboard_page.dart` | Hoy navega a `/campaigns`; apuntar a `/campaigns/:id` cuando exista el detalle. |
| Colores hardcodeados | badge y card | Mover a tokens en `core/theme` (`TODO(design)`). |

## Incidencia resuelta

**Síntoma:** tras implementar, el Dashboard seguía mostrando solo el texto "Dashboard".

**Causa:** la clase `DashboardPage` antigua permanecía en `app_router.dart`. En Dart, una declaración local tiene prioridad sobre una importada del mismo nombre, por lo que el router seguía usando el placeholder sin error de compilación.

**Solución:** eliminar la clase antigua de `app_router.dart` y dejar únicamente el import de `features/dashboard/presentation/dashboard_page.dart`.

## Cumplimiento de reglas del repositorio

- [x] El modelo `Campaign` sigue OpenAPI (`id`, `name`, `description`, `status`, `createdAt`, `updatedAt`).
- [x] Los datos que no están en el contrato están aislados en clases `*Mock` y etiquetados.
- [x] La UI no hace HTTP ni usa Dio.
- [x] Se contemplan los estados loading, empty y error.

## Siguientes pasos

1. Avisar a Carlos del cambio en `app_router.dart`.
2. Preguntar a Ángel si el backend expondrá Prospectos, Contactados y Conversión.
3. Introducir `CampaignsRepository` con implementaciones API y mock, como pide `FEATURE-DEVELOPMENT.md`.
4. Agregar el bloque de resumen del documento UI/UX (contadores de campañas y prospectos), también como mock etiquetado.
