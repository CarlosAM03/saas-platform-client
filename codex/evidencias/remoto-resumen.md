# Smoke remoto autorizado

Origen confirmado por el owner: https://saas-platform-client-web.vercel.app. API embebida comprobada: https://saas-platform-backend-l55n.onrender.com.

PASS: health/live, health/ready, Swagger1.0.0, bundle público, origen API, CORS permitido para el frontend correcto y CORS rechazado para origen ajeno.

PASS: 7 escenarios UI autenticados (login, selección, Dashboard, Campaigns, Prospects, Users, Jobs y logout se agrupan en7 resultados). Logout HTTP200 y recarga a login comprobados. 17 respuestas HTTP registradas sin cuerpos, identidad de cuenta ni IDs de entidades. Evidencia: remote-ui.json. Credenciales solo por stdin y excluidas de documentación.

Los dos FAIL del smoke público pertenecen al alias histórico sin -web:404 y CORS no permitido. Son DOC_DRIFT; el URL entregado por el owner pasa ambos controles. NOT RUN en la fila pública de Auth significa que se ejecutó en el runner autenticado separado, no ausencia de ejecución.

BLOCKED: atribución de SHA efectivo servido por Vercel y Render. GitHub reporta deployment productivo de7731649, pero no demuestra por sí solo el alias servido ni la revisión Render. No hay correlación autorizada completa de hosting; no se deduce versión desde health o Swagger.

NOT RUN: SQL remoto y pruebas de escritura de negocio remotas. No se crearon fixtures productivos ni se cambiaron hosting, CORS, flags o despliegues manuales. Las lecturas no se presentan como prueba SQL de persistencia remota.

G4 permanece BLOCKED por identidad de artefactos, aunque el smoke de lectura autorizado pasó.
