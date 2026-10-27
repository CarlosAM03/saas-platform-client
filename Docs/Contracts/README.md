# Contrato MVP implementado

platform-api.v1.yaml 1.1.0 es copia del Backend b6cd40f5c00990411bd6f46a22991c9be60de4bf;
implementación funcional d19b78afef8148a41f69397f6fdbc5ef70c5f912.
La versión y hash LF están en prospector-mvp.version.json, copiado del Backend.
El YAML se sirve por /api/docs-json y se contrastó con DTO/controladores/pruebas HTTP.
No existe generación automática completa desde decoradores. La prueba de cliente
comprueba todos los endpoints públicos y sus esquemas, incluidos errores de operaciones
deshabilitadas. Cancel/persist/export no tienen éxito ficticio ni x-target-responses vigente.

CSV ya existe en Backend main 3a330939 y dev 967044e2 (mismo árbol); la referencia anterior
que lo restringía a dev era incorrecta. Las auditorías históricas se conservan y esta
corrección prevalece para la lectura actual. Código presente no certifica despliegue.

Flutter usa sólo NestJS con JWT. GET prospecting-jobs/capabilities debe coincidir con
prospector-mvp-v1, google_maps,1–100,TTL3600 y operaciones futuras false; cualquier
incompatibilidad/404/error deja creación off. POST revalida cuota/capacidad/permisos.
resultsExpiresAt/dispatchState/failureCode/retryAllowed son aditivos; al leer Backend
anterior, sus ausencias conservan null/false. Nunca se habilita create por URL configurada.
No hay secretos Service ni destinos callback en Flutter.

Ver [reporte de paridad](../Auditorias/Paridad_Flutter_Backend_Prospector_MVP.md).
