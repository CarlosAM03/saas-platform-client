# Entrega — CSV, Dashboard, Jobs y Prospector

Fecha: 22 de octubre de 2026, Tijuana.

La implementación funciona en el entorno local de revisión:

- Aplicación: http://localhost:4201
- API / Swagger: http://localhost:3001/api/docs
- Prospector readiness: http://localhost:8001/health/ready

Cuenta de desarrollo: `owner.demo-norte@demo.example`  
Contraseña de desarrollo: `DevOnlyPass123!`

## Funciones completadas

| Función | Resultado |
|---|---|
| Importación CSV | Selección de archivo/campaña, plantilla, vista previa, decisiones por fila, advertencia de actualización compartida, confirmación y resumen. |
| Dashboard | Conteos de campañas, prospectos y trabajos desde la API; actividad reciente y enlaces a detalles. |
| Jobs UI | Crear búsquedas, listado paginado, detalle, seguimiento cada cuatro segundos, cancelación, resultados, guardado y descarga CSV/XLSX. |
| Prospector | Conexión NestJS → FastAPI → Engine real, callbacks autenticados, reintentos idempotentes y resultados temporales. |
| CSV de Windows | Se corrigió la lectura de archivos con saltos de línea mixtos sin alterar el contenido de las celdas. |

El dashboard consulta PostgreSQL mediante el backend. La base local está separada
como `saas_preview`: contiene el dataset de desarrollo del proyecto, un prospecto
importado por CSV y un negocio obtenido por una búsqueda real. No representa datos
de producción. En Demo Norte se verificaron 3 campañas, 20 prospectos y 6 trabajos.

## Validación realizada

- Flutter: 206 pruebas de la suite completa aprobadas; las ocho pruebas nuevas se
  repitieron después de los ajustes finales. Análisis sin incidencias y compilación Web correcta.
- Backend: 35 pruebas unitarias, 77 pruebas de API y 13 pruebas PostgreSQL aprobadas.
- Service: 96 pruebas aprobadas; el caso del browser Chromium no se ejecutó.
- Exportador instalado: 103 pruebas aprobadas.
- El runtime real Edge/headless inició correctamente y pasó readiness.
- Una búsqueda pública de cafeterías en Tijuana, límite 1, terminó COMPLETED con un
  resultado. Se exportó en CSV y XLSX y se guardó una sola vez en la campaña.
- Un CSV con finales de línea mixtos se importó y conservó `0012345` como texto.
- PostgreSQL verificó aislamiento de organizaciones, callbacks/replay, vencimiento
  y solicitudes simultáneas de guardado sin duplicar el lote.

## Código guardado

Los cambios están confirmados en ramas locales, sin publicar ni fusionar en main/dev:

| Repositorio | Rama | Commit |
|---|---|---|
| saas-platform-client | codex/complete-pending-features | fe9e32f |
| saas-platform-backend | codex/prospector-integration | 687ecb8 |
| prospector-service | codex/platform-integration | 6009036 |

Ubicación del código:

- Cliente: `C:\Users\BysTameLap\Documents\Codex\2026-10-22\prepar-la-comunicaci-n-para-importar-3\work\client`
- Backend: `C:\Users\BysTameLap\Documents\Codex\2026-10-22\prepar-la-comunicaci-n-para-importar-3\work\backend`
- Service: `C:\Users\BysTameLap\Documents\Codex\2026-10-22\prepar-la-comunicaci-n-para-importar-3\work\prospector-service`

Las copias de cliente y backend son worktrees de los repositorios originales en
C:\dev. Se conservó tu cambio local preexistente de pubspec.lock. Engine no requirió
modificaciones; se usó su commit fijado 70f6081688db5c5bc5ea612f5fabd5724aab0b20.

También se entregan parches completos, verificados contra cada commit:

- [Cliente Flutter](C:/Users/BysTameLap/Documents/Codex/2026-10-22/prepar-la-comunicaci-n-para-importar-3/outputs/cliente-flutter.patch)
- [Backend](C:/Users/BysTameLap/Documents/Codex/2026-10-22/prepar-la-comunicaci-n-para-importar-3/outputs/backend.patch)
- [Prospector Service](C:/Users/BysTameLap/Documents/Codex/2026-10-22/prepar-la-comunicaci-n-para-importar-3/outputs/prospector-service.patch)

El script `work\start-local.ps1`, dentro de la carpeta de esta entrega, arranca los
servicios con el entorno preparado. La base local usa el contenedor
`codex-pending-saas-db`; el script conserva su clave local en work/runtime, fuera
de los repositorios y de los parches. La aplicación ya está arrancada.

## Publicación y límites operativos

No se desplegó en producción. Para publicarlo se deben integrar las ramas,
aplicar la nueva migración, desplegar la revisión compatible del Service y activar
`PROSPECTOR_INTEGRATION_ENABLED=true` con URLs/clave interna y browser del entorno.
Los secretos permanecen en el backend/Service; no van al cliente Flutter.

Los resultados de Platform duran una hora y se eliminan al guardarlos. Service
mantiene un proceso/worker y una cola no durable: reiniciarlo pierde búsquedas
pendientes. Los callbacks tienen reintentos acotados; no hay recuperación automática
de eventos perdidos ni reanudación de búsquedas. Cancelar es cooperativo y espera
la confirmación del motor. Estas limitaciones están documentadas en las guías de
integración de los repositorios.

![Dashboard validado](C:/Users/BysTameLap/Documents/Codex/2026-10-22/prepar-la-comunicaci-n-para-importar-3/outputs/dashboard-validado.png)


