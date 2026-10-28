# Estado funcional reconciliado — 26 de octubre de 2026

Este documento actualiza la entrega del 22 de octubre conservada en el historial Git.
Autoridad: Foundation y PlatformApi de main a85a996; mejoras tipadas de André en
fe9e32f/e225e6a/9dd9b57; Backend dev 967044e2. No equivale a una validación E2E.

## Implementado y probado con contratos y fixtures

- Autenticación real, restauración, sesión expirada, logout local aun si falla el servidor y selección de organización.
- JWT Bearer, DTOs tipados, permisos ADMIN/OWNER/MEMBER y estado/formularios separados por sesión y tenant.
- Listados, búsqueda, paginación, creación, detalle, edición y archivado de campañas; eliminación permanente ADMIN según Backend.
- Prospectos manuales para ADMIN/OWNER, consultas y edición para los roles admitidos. Los opcionales modificados pueden enviarse como null sin borrar los demás.
- Importación CSV con selector, límite de 5 MiB en tamaño declarado, buffer y stream, campaña paginada, plantilla, preview sin escrituras, clasificaciones, diferencias y decisiones por fila.
- Confirmación CSV explícita, advertencia para actualizaciones compartidas, expiración/409, reutilización de los mismos bytes y actualización de listados/dashboard al confirmar.
- Una respuesta incierta de confirmación bloquea otra preview hasta revisar manualmente el resultado. Nunca se reintenta automáticamente.
- Dashboard con meta.total y registros reales: campañas, prospectos y trabajos recientes, enlaces, carga, vacío, error y refresco.
- Jobs: historial paginado, detalle, errores reales y polling secuencial de cuatro segundos. Se detiene al finalizar, perder listeners, cambiar la sesión o desmontar la página.
- UI compatible de André: Inter local y licencia OFL, tema, login validado con mostrar contraseña, tarjetas y estado visual de campañas, superficies, formularios y navegación responsiva.

Los tests usan fixtures exclusivamente en test/. Las llamadas productivas sólo van a NestJS.
Los resultados temporales y el progreso sólo se muestran si el contrato los proporciona.
Backend actual devuelve resultsAvailable=false, results=null y progress=null.

## Cliente preparado; Backend no habilitado

Crear, cancelar, persistir y exportar Jobs conservan métodos y DTOs para integración,
pero la UI los deshabilita mediante capacidades verificadas, todas falsas en producción.
No hay flag de entorno que las active ni se simula éxito.

NestJS ProspectingJobsService delega esas operaciones en assertAvailable(), que lanza
503 PROSPECTOR_INTEGRATION_PENDING antes de crear trabajos. Cambiar variables de
configuración o desplegar Python no activa ese adaptador.

El formulario preparado conserva Idempotency-Key para el mismo payload cuando se
pierde una respuesta. Una respuesta contractual definitiva descarta la clave para que
un nuevo intento legítimo no quede ligado indefinidamente a un fallo anterior.
Las pruebas que habilitan esa capacidad sólo ejercitan el cliente con repositorios falsos.

## Dependencias y límites externos

Backend main 3a330939 es el baseline, pero el CSV inspeccionado está en dev 967044e2.
La revisión del Backend desplegado debe comprobarse antes de aceptar CSV en producción.
Service main 566bbbe expone POST /api/v1/prospecting/jobs y health live/ready. Su código
local 69c54a1 coincide en src con main. No ofrece HTTP público de cancelación/exportación,
recuperación durable, cuotas completas ni alta disponibilidad validada. Engine main
70f6081 es una biblioteca Python. Flutter no llama a ninguno directamente.

Reinicio durante una búsqueda: mostrar fallo y permitir repetición manual, sin reanudar
scraping. El bloqueo por cuotas gratuitas requiere soporte Backend/Service verificable;
Flutter no inventa contadores, presupuestos ni escalamiento pagado.

## Validación y aceptación

Consultar resultados ejecutables, SHA y riesgos en
[Auditoria_Reconciliacion_Dev_2026-10-26.md](Auditorias/Auditoria_Reconciliacion_Dev_2026-10-26.md).
No se declara E2E, scraping real, disponibilidad productiva de Jobs ni aceptación CORS.
La configuración de publicación está en [Despliegue-Web.md](Despliegue-Web.md).
