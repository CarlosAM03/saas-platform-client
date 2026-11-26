# Reglas Flutter, carpetas protegidas y pruebas

Backend de referencia: `3b5eec6fa99f846e853794fc8aedff2c4353c269`.

## 1. Arquitectura obligatoria

```text
UI (widgets/pantallas)
  → Riverpod (providers/notifiers de estado)
    → repositorio por feature
      → lib/platform_api (cliente tipado del contrato)
        → ApiClient (HTTP y sesión existentes)
```

- Prohibido llamar `http`/`dio` directamente desde widgets o providers de UI.
- Toda ruta nueva debe representarse en `lib/platform_api` con modelos tipados y parseo explícito; nada de `Map<String, dynamic>` suelto en pantallas.
- Respetar `sessionScope` y el tenant de la sesión: el tenant viaja en el JWT del backend, no en cabecera propia. Tras `select-tenant` hay que sustituir el token y refrescar providers dependientes del tenant.
- Un `403` no borra la sesión; un `401` sí debe llevar al flujo de autenticación existente.
- Estados explícitos: `loading`, `empty`, `data`, `error` (con reintento). Sin valores por defecto silenciosos.

## 2. Carpetas protegidas

Sin autorización puntual del owner **no** se editan:

- `lib/app`
- `lib/core/network`
- `lib/routes`
- `lib/features/auth`
- modelos base compartidos y `ApiClient`

Si una ruta o pantalla nueva requiere tocar una carpeta protegida, se escala con alternativa concreta y pruebas propuestas. No hacerlo por conveniencia.

## 3. Contrato

- Sólo se consume lo marcado `AVAILABLE` en `02_MATRIZ_API_FLUTTER.csv`.
- Envoltura `{success, data, meta?}`; errores `{success:false, error:{code,message,details,timestamp}}`.
- No inventar campos: si falta algo, se registra como brecha y se consulta; no se rellena en cliente.
- `CORRECTION` es manual y se genera con `correctsId`; `MASTER_UPDATE` está en el contrato pero no se emite: no construir UI que lo cree.
- `activity.manual` incluye correcciones; `activity.events` son eventos automáticos.

## 4. Pruebas requeridas

1. **Unitarias de estado/provider** por feature: carga, vacío, error y paginación.
2. **Parseo de modelos** contra JSON de ejemplo sintético del contrato (incluye `participation`, `responsible.eligible`, `activity.manual`, `MASTER_UPDATED`).
3. **Filtros**: cada filtro de C6 enviado como query y combinado con AND; `UNASSIGNED`; fechas con zona; 400 mostrado correctamente.
4. **Roles**: `MEMBER` no ve alta ni importación; `OWNER`/`ADMIN` sí. Los 403 se muestran sin romper la pantalla.
5. **Aislamiento de sesión**: cambio de tenant refresca datos; 404 de otro tenant se muestra como "no encontrado"; no se conservan datos del tenant anterior en caché.
6. **Conflictos**: `409` de `match/resolve` (candidato cambió) y de importación (preview vencido/stale) con el flujo de reintento.
7. **Bitácora**: corrección no edita el original; eventos automáticos y declaraciones humanas se distinguen.
8. **CSV**: preview sin escrituras, confirm con resultado por fila, límite de 5 MB/1000 filas, archivo no CSV rechazado.
9. **Dashboard**: no recalcular sumas en cliente; verificar `total = manual + events` tal como llega.
10. **T32 (E2E real UI→API)**: contra backend sintético de `06_RUNBOOK_QA_SINTETICO.md`, sin mocks ocultos. Es la prueba que el backend **no** puede ejecutar y hoy está `NOT_RUN`.

## 5. Evidencia y gates

- Cada prueba reportada lleva: fecha ISO, SHA del backend, SHA del frontend, comando, fixture sintético, esperado, observado, estado. Nada de `PASS` sin ejecución.
- Mocks sólo para desarrollo visual, etiquetados como tales; no sustituyen T32.
- Prohibido en este handoff: datos reales, secretos, tokens en capturas o logs, y auto-merge del PR Flutter.
- Gates del frontend: baseline Flutter autorizado por el owner; SHA de backend fijado; contrato real; QA/E2E; PR para revisión del owner. El owner decide cuándo se usa este arnés.
