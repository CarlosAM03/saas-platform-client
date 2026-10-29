# EVID-AV2-04 — Registro de validación visual de Vercel por el owner

**Proyecto:** PROSPECTOR SaaS, Core 1.0.0.  
**Fecha de capturas:** 28 de octubre de 2026 (hora local del equipo mostrada en Windows, aproximadamente 04:35–04:43).  
**Origen mostrado:** `https://saas-platform-client-web.vercel.app`, rutas Flutter Web con `/#/`.  
**Tipo de evidencia:** capturas de navegador autenticado aportadas por el owner; no es ejecución automática ni verificación directa de PostgreSQL.  
**Tratamiento de privacidad:** se registran observaciones agregadas y rutas. **Las imágenes originales, que incluyen posibles datos de contacto y negocios reales, no se redistribuyen en este ZIP**. Solo se nombran los archivos fuente para poder relacionar el reporte con el material original compartido.

## 1. Resumen

Se inspeccionaron **10 capturas** del frontend productivo después del merge del PR #10, alternando ACME CORPORATION y Empresa B mediante la sesión de ADMIN global.

**Hallazgo funcional confirmado visualmente:** en ACME la pantalla Usuarios presenta el mensaje «La respuesta del servidor no coincide con el formato esperado»; en Empresa B la misma pantalla carga correctamente una fila. No hay indicación visual equivalente en otras pantallas. La creación y persistencia de usuarios en Supabase, y las operaciones de escritura/importación, **fueron reportadas por el owner**; ninguna imagen muestra por sí misma la transacción SQL ni el cuerpo HTTP de esas operaciones.

**Resultados visibles importantes:** ACME muestra dos campañas y 185 prospectos en el dashboard; Empresa B muestra una campaña y 207 prospectos. Los dos contextos exhiben cero Jobs en el momento de captura, sin afirmar que todos los Jobs pasados estén ausentes de la base.

## 2. Inventario de las diez capturas y alcance probatorio

| ID | Archivo de imagen compartido | Ruta/contexto | Observación explícita | Resultado visual |
| --- | --- | --- | --- | --- |
| EV-01 | `image(20261028-113542).png` | `/#/users` — ACME | Pantalla Usuarios, botón Crear usuario; panel de error «La respuesta del servidor no coincide con el formato esperado» y Reintentar. No se muestran filas. | **FAIL / incidencia AV2-FE-01** |
| EV-02 | `image(20261028-113602).png` | `/#/campaigns` — ACME | Se renderizan 2 campañas, estado Activa; contador de página: 2 registros, navegación y filtros. | **PASS visual** |
| EV-03 | `image(20261028-113705).png` | `/#/dashboard` — ACME | Resumen: 2 campañas, **185 prospectos**, 0 trabajos; campañas recientes visibles. | **PASS visual** |
| EV-04 | `image(20261028-113741).png` | `/#/prospects` — ACME | Lista de prospectos cargada, estado por fila, botón Importar CSV y Crear prospecto; pie de página **185 registros**. | **PASS visual** |
| EV-05 | `image(20261028-113758).png` | `/#/jobs` — ACME | Se muestra estado vacío, «Aún no hay trabajos de prospección», página 1, 0 trabajos. | **PASS visual del estado vacío** |
| EV-06 | `image(20261028-113824).png` | `/#/generate` — ACME | Mensaje de integración pendiente, DEMO sin ejecución real y vínculo Ver trabajos. | **PASS visual / funcionalidad intencionalmente deshabilitada** |
| EV-07 | `image(20261028-113851).png` | `/#/tenants` — ACME | Se muestran ACME CORPORATION y Empresa B como organizaciones activas; ACME marcada Actual, opciones Crear organización y Cambiar organización. | **PASS visual** |
| EV-08 | `image(20261028-113916).png` | `/#/profile` — ACME | Perfil autenticado con rol de plataforma ADMIN, organización actual y rol actual ADMIN; enlaces de navegación y logout. | **PASS visual** |
| EV-09 | `image(20261028-113947).png` | `/#/dashboard` — Empresa B | Resumen: **1 campaña, 207 prospectos, 0 trabajos**; campaña y prospectos recientes visibles. | **PASS visual** |
| EV-10 | `image(20261028-114411).png` | `/#/users` — Empresa B | Lista carga una identidad, estado ACTIVO, página 1 y 1 registro, sin mensaje de formato. | **PASS visual** |

**Regla de interpretación:** PASS visual significa que los elementos que aparecen en esa captura se renderizaron correctamente; **no** acredita todos los formularios, autorización de API, integridad de DB, ausencia global de regresiones ni la revisión exacta desplegada. La opción «Crear usuario» o «Importar CSV» visible no prueba el resultado al pulsarla.

## 3. Comparación de ACME y Empresa B

| Indicador visible | ACME CORPORATION | Empresa B | Interpretación |
| --- | ---: | ---: | --- |
| Campañas del dashboard | 2 | 1 | Datos diferenciados por tenant en las capturas |
| Prospectos del dashboard | 185 | 207 | Datos diferenciados por tenant; ACME además coincide con pie de la lista de prospectos |
| Jobs actuales en resumen | 0 | 0 | Estado mostrado al momento, no diagnóstico sobre Service |
| Lista de usuarios | Error de formato | 1 registro | Falla específica asociada a contexto/datos/ruta de ACME; causa no determinada |
| Identidad actual | ADMIN global (en perfil de ACME) | Cambió a Empresa B en capturas posteriores | Evidencia compatible con capacidad de selección de organizaciones |

**Nota sobre números históricos:** en la conversación anterior se mencionaron 91 y 207 registros por tenant, mientras estas capturas muestran 185 y 207. No se corrige ni fuerza ninguno de los números: pueden corresponder a momentos, campañas, importaciones o criterios distintos. Para el cierre, comparar recuentos actuales por tenant/campaña con `meta.total` y SQL autorizado, con fecha y filtros documentados.

## 4. Fallo visible de la lista de usuarios — detalles y precauciones

La captura EV-01 muestra un error de **formato esperado por el cliente**. El código Flutter centraliza ese mensaje para `FormatException` y `TypeError`. No se ve en la imagen si el HTTP fue 200 o error, cuál fue el `requestId`, qué fila falló ni cómo respondieron las relaciones de PostgreSQL.

El hecho de que EV-10 cargue Empresa B indica que no hay un bloqueo uniforme de la pantalla en todos los contextos. **No prueba** que exista contaminación entre tenants ni demuestra que alguna fila específica sea culpable. La causa debe determinarse por contrato/serializador y por la respuesta real sanitizada.

### Preguntas de diagnóstico que las imágenes no responden

1. ¿`GET /api/v1/users` de ACME devuelve 200 y sobre válido? ¿Qué reporta `meta`?
2. ¿Qué tipo/campo difiere del modelo `User.fromJson` o `UserMembership.fromJson`, si existe?
3. ¿El ADMIN sin membresía local se está interpretando como usuario de tenant? ¿Se espera verlo listado?
4. ¿La identidad creada de la que se observó `NULL` tiene `users.platform_role=NULL` (normal) o el problema está en una asociación `UserTenant`?
5. ¿Existen usuarios compartidos cuya respuesta `role`/`tenants` difiera entre los dos contextos?
6. ¿Un refresh de página, cierre de sesión y nueva selección cambia el resultado? Documentar el efecto sin manipular datos productivos.

**No utilizar** nombres, correos, IDs de usuarios, JWT, hashes ni registros de prospectos mostrados en las capturas para compartir evidencia de depuración. El identificador de caso, campo, tipo esperado, requestId sanitizado y SHA son suficientes.

## 5. Validaciones declaradas por el owner, no visibles directamente

El owner informó haber realizado con éxito lo siguiente en producción: altas y persistencia de datos de formularios, importaciones CSV por tenant, navegación con ADMIN y creación de usuarios persistidos en Supabase. También informó haber importado un conjunto de 207 filas exitosamente. **Estas observaciones son testimonio de ejecución manual** y se conservan como tales; deben vincularse a pruebas HTTP/SQL autorizadas antes de declararlas certificación técnica completa.

Se informó además que un campo de rol aparecía `NULL` en Supabase. Esto **no prueba que el usuario carezca de rol en un tenant**: `User.platformRole` admite `NULL` para usuarios OWNER/MEMBER y `UserTenant.roleId` es FK no nula en el esquema Core. Ver instrucciones de verificación en `01_AUDITORIA_ESTADO_ACTUAL_CORE_V1.md`.

## 6. Evidencia que falta para el QA de cierre

| Control | Lo que ya hay | Lo que falta |
| --- | --- | --- |
| Despliegue Vercel/Render | Captura en dominio Vercel y confirmación del owner de deploy automático desde `main` | Identidad de revisión servida registrable por hosting y smoke posterior al siguiente merge |
| Auth/ADMIN | Perfil autenticado y navegación por tenant | Matriz de usuarios OWNER/MEMBER y permiso negativo por API/SQL en nuevo release |
| Campañas/Prospectos | Datos, paginación y agregados visuales | Releer HTTP y SQL por tenant en entorno autorizado; verificar integridad posterior al nuevo módulo |
| Users ACME | Fallo reproducido visualmente | Root cause, regresión y smoke correcto |
| Users Empresa B | Lista con una fila | Comprobar rol MEMBER en `UserTenant`, login de usuario y aislamiento |
| CSV | Lista con prospectos y declaración de importación | Evidencia posterior de confirmación y checksum/filas de prueba sin exponer datos de negocio |
| Jobs | Estado vacío y pantalla demo | Confirmación de 503 esperado y no prometer ejecución del Service |
| Onboarding ADR-006 | Ninguna pantalla nueva en material actual | Todos los pasos ADMIN→correo→OWNER→login en ensayo autorizado y PostgreSQL local |

## 7. Conclusión visual y decisión para presentación

Las diez capturas **respaldan una demostración sólida del Core actual**, particularmente dashboards distintos, dos organizaciones, campañas, prospectos y presentación honesta de Jobs pendiente. El único error visible es el listado de usuarios ACME, que debe tratarse como hallazgo P1 antes de presentar el módulo Users como completamente validado.

Si el PR de Ángel no supera las pruebas, las capturas son referencia útil para el **plan alternativo Core**, sin ampliar afirmaciones a pagos, correo de invitaciones MEMBER ni motor de prospección. Para presentar ADR-006 será imprescindible un set nuevo de evidencias propio del incremento.

---

**Trazabilidad:** archivos EV-01..EV-10 corresponden exactamente a las diez imágenes adjuntas en la conversación del 28 de octubre de 2026. Este documento **no edita, sanitiza ni redistribuye las imágenes originales** y no contiene credenciales de las sesiones.
