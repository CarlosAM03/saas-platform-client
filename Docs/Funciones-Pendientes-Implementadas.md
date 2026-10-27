# Estado funcional MVP — 27 de octubre de 2026

Autoridad Backend b6cd40f5c00990411bd6f46a22991c9be60de4bf, contrato1.1.0; base Flutter fix/f5-foundation97645e4.
La integración es local y reproducible con EnginePort controlado, sin Google Maps live.
Ver [reporte de paridad](Auditorias/Paridad_Flutter_Backend_Prospector_MVP.md).

- Auth/JWT, restore/logout/tenant, revisión de sesión y token serializado permanecen.
- PlatformApi tipado, permisos, GoRouter y Riverpod por scope permanecen; no hay repositorio paralelo de mapas.
- Campañas y prospectos manuales conservan CRUD, null/omitido y permisos.
- CSV conserva multipart5MiB, bytes, preview firmada/TTL, diferencias/decisiones, confirmación, advertencia compartida y bloqueo de respuesta incierta. Existe en Backend main y dev.
- Dashboard mantiene totales/registros API; no calcula conversiones ni progreso ficticio.
- Generación: capabilities verificadas; campaña, keyword/ubicación, límite1–100, confirmación y POST con clave idempotente. La clave sobrevive a 503 incierto o respuesta perdida; los datos se bloquean para impedir otra intención accidental.
- Historial/detalle/polling secuencial cada4s: una petición, se detiene al terminar/desmontar/cambiar scope. Se muestran resultados reales temporales (incluye[]), error seguro e incertidumbre.
- resultsExpiresAt muestra plazo; un timer local único retira la vista vencida y refresca una vez el detalle, sin polling periódico terminal. Backend aplica TTL/limpieza autoritativos.
- Fallo confirmado y reserva liberada permiten preparar otra búsqueda manual con clave nueva. Deadline incierto bloquea repetición hasta callback terminal o reinicio Service confirmado por operador.
- Cancelar, guardar resultados scraping a campaña y exportar Jobs siguen deshabilitados; no se invocan endpoints Python inexistentes.

Sólo NestJS recibe peticiones Flutter. Los fixtures viven en test/. El test de stack
usa el Service FastAPI real y PostgreSQL aislado; el EnginePort está controlado para CI.
No prueba Google Maps live, hosting gratuito/costo real, despliegue/CORS público ni builds nativos.
