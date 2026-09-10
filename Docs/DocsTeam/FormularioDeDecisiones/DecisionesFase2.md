
---

# Formulario de decisiones — ADR Contrato de API

> Nota de vigencia: este documento es histórico o conceptual. No sustituye ADR-004, el contrato OpenAPI, FormularioDecisionesFase5.md ni ADR-005-FlutterFoundation.md. En caso de contradicción, prevalecen los documentos normativos vigentes.

**Instrucción para DeepSeek:**

> Analiza toda la documentación del proyecto disponible como fuente. No inventes decisiones que no estén expresamente definidas en las respuestas siguientes. Usa la documentación únicamente para validar consistencia, detectar contradicciones y señalar decisiones faltantes. Con las respuestas proporcionadas, genera un ADR formal sobre el contrato de API del sistema.

---

## 1. Alcance del contrato

### 1.1 ¿Qué componentes estarán cubiertos por este contrato?

Selecciona:

* [x] Flutter → Platform Backend
* [x] Platform Backend → Flutter
* [x] Platform Backend → Prospector Service
* [x] Prospector Service → Platform Backend
* [ ] Prospector Engine → Prospector Service
* [ ] Otro: _________

### 1.2 ¿El contrato debe definir solamente comunicación HTTP/REST?

* [x] Sí
* [ ] No
* [ ] Parcialmente

Si no es exclusivamente HTTP/REST, especifica:

> ---

### 1.3 ¿El contrato debe cubrir solamente MVP?

* [x] Sí, exclusivamente MVP
* [ ] No, también debe dejar previstas extensiones futuras

---

# 2. Convenciones HTTP

### 2.1 ¿Qué estilo de API quieres utilizar?

* [ ] REST
* [x] REST con algunas acciones específicas
* [ ] Otro: _________

### 2.2 Naming de endpoints

¿Quieres utilizar recursos en plural?

Ejemplo:

```text
/users
/campaigns
/prospects
/prospecting-jobs
```

* [x] Sí
* [ ] No

### 2.3 Formato de nombres

* [x] kebab-case → `/prospecting-jobs`
* [ ] camelCase → `/prospectingJobs`
* [ ] snake_case → `/prospecting_jobs`
* [ ] Otro: _________

### 2.4 Métodos HTTP

¿Se utilizarán los métodos HTTP convencionales?

```text
GET
POST
PATCH
DELETE
```

* [ ] Sí
* [ ] No
* [x] Sí, pero algunas operaciones tendrán endpoints de acción

---

# 3. Versionado

### 3.1 ¿La API tendrá versionado?

* [x] Sí
* [ ] No
* [ ] Se deja para una fase posterior

### 3.2 Si sí, ¿qué estrategia?

* [ ] `/api/v1/...`
* [x] Header
* [ ] Otra: _________

### 3.3 ¿El Prospector Service tendrá el mismo versionado que Platform API?

* [ ] Sí
* [ ] No
* [x] Cada API tendrá su propio versionado

---

# 4. Identificadores

### 4.1 ¿Qué tipo de ID utilizarán las entidades?

* [x] CUID
* [x] UUID
* [ ] Integer autoincremental
* [ ] Otro: _________

### 4.2 ¿El mismo criterio aplica a todas las entidades?

* [x] Sí
* [ ] No

Si no:

> ---

### 4.3 ¿Quién genera los IDs?

Para entidades de Platform:

* [x] Backend
* [ ] Base de datos
* [ ] Otro: _________

Para operaciones relacionadas con Prospector Service:

* [ ] Platform Backend
* [ ] Prospector Service
* [x] Depende de la entidad

---

# 5. Fechas y horas

### 5.1 ¿Qué formato tendrán las fechas en las APIs?

* [x] ISO 8601
* [ ] Unix timestamp
* [ ] Otro: _________

### 5.2 ¿Se manejarán todas las fechas en UTC?

* [x] Sí
* [ ] No
* [ ] Depende del campo

### 5.3 ¿Qué campos deben considerarse timestamps?

Por ejemplo:

```text
createdAt
updatedAt
startedAt
completedAt
```

* [x] Todos los campos temporales utilizan timestamp ISO 8601 UTC
* [ ] Otro criterio: _________

---

# 6. Content-Type y formato

### 6.1 ¿La API utilizará JSON?

* [x] Sí
* [ ] No

### 6.2 ¿Se utilizará?

```http
Content-Type: application/json
Accept: application/json
```

* [x] Sí
* [ ] No

### 6.3 ¿Se permitirán otros formatos?

* [ ] No
* [x] CSV
* [x] XLSX
* [ ] Otro: _________

Si existen, ¿en qué endpoints?

> endpoints relacionados a exportacion desde el servicio de prospeccion cosultado por el backend.

---

# 7. Respuesta exitosa

Aquí necesitamos tomar una decisión importante.

### 7.1 ¿Quieres una estructura común para respuestas exitosas?

SI

```json
{
  "success": true,
  "data": {}
}
```

### 7.2 ¿Las colecciones deben utilizar la misma estructura?

Ejemplo:

```json
{
  "success": true,
  "data": [],
  "meta": {
    "total": 100
  }
}
```

* [x] Sí
* [ ] No

### 7.3 ¿Qué información debe poder contener `meta`?

* [x] Paginación
* [x] Conteos
* [ ] Información adicional
* [ ] Nada por ahora
* [ ] Otro: _________

---

# 8. Modelo de errores

### 8.1 ¿Quieres un formato de error común para todas las APIs?

* [x] Sí
* [ ] No

### 8.2 ¿Qué estructura prefieres?

```json
{
  "success": false,
  "error": {
    "code": "CAMPAIGN_NOT_FOUND",
    "message": "Campaign not found",
    "details": {}
  }
}
```

### 8.3 ¿Debe existir un código de error estable?

* [x] Sí
* [ ] No

### 8.4 ¿Debe existir `details` para errores de validación?

Ejemplo:

```json
{
  "code": "VALIDATION_ERROR",
  "details": {
    "field": "email",
    "reason": "Invalid email"
  }
}
```

* [x] Sí
* [ ] No

### 8.5 ¿Qué categorías de errores quieres distinguir?

* [x] Validación
* [x] Autenticación
* [x] Autorización
* [x] Recurso no encontrado
* [x] Conflicto
* [x] Error de negocio
* [x] Error interno
* [x] Error del Prospector Service
* [x] Timeout
* [ ] Otro: _________

---

# 9. HTTP Status Codes

### 9.1 ¿Quieres utilizar códigos HTTP estándar?

* [x] Sí
* [ ] No

### 9.2 ¿Quieres establecer explícitamente un catálogo mínimo?

Por ejemplo:

```text
200 OK
201 Created
204 No Content
400 Bad Request
401 Unauthorized
403 Forbidden
404 Not Found
409 Conflict
422 Unprocessable Entity
500 Internal Server Error
502 Bad Gateway
503 Service Unavailable
```

* [x] Sí
* [ ] No

### 9.3 ¿Quieres que DeepSeek proponga el catálogo basándose en REST y la documentación?

* [x] Sí
* [ ] No

---

# 10. Paginación

### 10.1 ¿Qué recursos necesitan paginación?

* [x] Campaign
* [x] Prospect
* [ ] ProspectingJob
* [x] User
* [ ] Otro: _________
* [ ] Todos los recursos que devuelvan colecciones

### 10.2 ¿Qué estrategia?

* [x] `page` + `limit`
* [ ] Cursor
* [ ] Otra: _________

### 10.3 ¿Cuál será el límite máximo?

> 100

### 10.4 ¿Quieres una estructura como?

```json
{
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "totalPages": 8
  }
}
```

* [x] Sí
* [ ] No
* [ ] Modificar: _________

---

# 11. Filtros, búsqueda y ordenamiento

### 11.1 ¿Los listados podrán filtrarse mediante query parameters?

Ejemplo:

```text
/campaigns?status=ACTIVE
/prospecting-jobs?status=RUNNING
/prospects?source=GOOGLE_MAPS
```

* [x] Sí
* [ ] No

### 11.2 ¿Qué recursos necesitan filtros en MVP?

> campaigns, prospects, users

### 11.3 ¿Se necesita búsqueda textual?

Ejemplo:

```text
/prospects?search=restaurant
```

* [ ] Sí
* [x] No
usar sensitive a 2 caracteres de coincidencia como norma general para listados de colecciones completas.
### 11.4 ¿Se necesita ordenamiento?

Ejemplo:

```text
/campaigns?sort=createdAt&order=desc
```

* [x] Sí
* [ ] No

### 11.5 ¿Quieres limitar estas capacidades al MVP?

* [ ] Sí
* [ ] No
* [x] Parcialmente

---

# 12. Platform API

### 12.1 ¿Qué recursos estarán expuestos?

Confirma:

* [x] Auth
* [x] Tenants
* [x] Users
* [x] Roles
* [x] Permissions
* [x] Campaigns
* [x] Prospects
* [x] CampaignProspects
* [x] ProspectingJobs
* [ ] Analytics
* [x] Exports

Otros:

> ---

### 12.2 ¿Qué operaciones tendrá cada recurso?

Puedes indicar:

```text
Campaign
- POST
- GET lista
- GET individual
- PATCH
- DELETE
```

Respuesta:

> dar una propuesta especificamente acorde a la documetacion.

### 12.3 ¿Qué operaciones especiales existen?

Por ejemplo:

```text
POST /prospecting-jobs/{id}/cancel
POST /prospecting-jobs/{id}/persist
POST /prospecting-jobs/{id}/export
```

Respuesta:

> dar una propuesta especificamente acorde a la documetacion.

---

# 13. ProspectingJob

Esta sección es **especialmente importante**.

### 13.1 ¿El usuario crea un Job y recibe inmediatamente el resultado?

* [ ] Sí
* [x] No

### 13.2 ¿El Job representa una operación asíncrona desde la perspectiva del usuario?

* [x] Sí
* [ ] No

### 13.3 ¿Los estados definitivos son?

```text
QUEUED
RUNNING
STARTSOURCEPIPELINE 
COMPLETED
FAILED
CANCELLED
```
STARTSOURCEPIPELINE (actualmente solo esta disponible googlemaps pero el punto es que, internamente mientras va el proceso de Carga debe mostrar mensajes del estado del proceso del pipeline interno de la fuente que el usuario utilizó, por ejemplo RESULTLISTEXTRACTING, DETAILPANELEXTRACTING, WEBSITEEXTRACTING, para el caso soportado actualmente pero esto corresponde mas a un logeo del proceso que esta ejecutando el sercicio de prospeccion, el job debe permitir compartir informacion del detalle del pipeline especifico o el proceso especifico, el servicio de prospeccion es el que genera esta informacion de logeo del proceso en carga actual para el backend de la plataforma no requiera ser modificado cada que se enriquece el logeo de los procesos para la vista de carga de los jobs)
### 13.4 ¿Quién es responsable del estado del Job?

* [ ] Platform Backend
* [X] Prospector Service
* [ ] Ambos
* [ ] Otro

### 13.5 ¿Quién crea el Job?

* [ ] Platform Backend
* [x] Prospector Service

### 13.6 ¿Qué sucede cuando se crea?

Describe brevemente:

> Platform Backend hace un request al sercicio con el input necesario para realizar una busqueda y este crea el job asyncrono permitiendo atender a multiples clientes de la plataforma saas que requieran el servicio de prospeccion externo este servicio es tema aparte ya que requiere principios ACID Y SOLID de manera imperativa y determinista alineado a los requerimientos de la materia.

### 13.7 ¿Dónde están temporalmente los resultados?

* [ ] Platform Backend
* [ ] Prospector Service
* [ ] Cache compartido
* [x] Otro
consideramos evaluar una estrategia de tecnologia moderna existente tanto para cache como para jobs, lo cual queda pendiente tras evaluar pero no bloquea el inicio de la construccion inicial del sistema
### 13.8 ¿El endpoint de consulta del Job devuelve los resultados?

* [x] Sí, por etapa de extraccion
* [ ] No
* [ ] Solo cuando está `COMPLETED`

### 13.9 ¿El usuario puede cancelar?

* [x] Sí
* [ ] No

### 13.10 Si cancela, ¿qué comportamiento contractual debe ocurrir?

> se hace shutdown graceful del servicio pero se persiste en caché los resultados de la ultima etapa o estado en que haya quedado la extraccion.

---

# 14. Idempotencia

### 14.1 ¿Qué debe ocurrir si el cliente manda dos veces la misma solicitud para crear un Job?

* [ ] Crear dos Jobs
* [ ] Detectar duplicado
* [x] Utilizar una `Idempotency-Key`
* [ ] Otro: _________

### 14.2 ¿Quieres que la API soporte `Idempotency-Key`?

* [x] Sí
* [ ] No
* [ ] Se deja para una fase posterior

---

# 15. Contrato Platform → Prospector Service

### 15.1 ¿Qué operación realizará Platform Backend?

Ejemplo:

```http
POST /prospecting/jobs
```

¿Quieres conservar este concepto?

* [x] Sí
* [ ] No
* [ ] Otro endpoint: _________

### 15.2 ¿Qué información debe recibir Prospector Service?

Actualmente:

```json
{
  "query": {
    "keyword": "...",
    "location": "...",
    "source": "...",
    "limit": 50
  }
}
```

¿Es suficiente?

* [x] Sí
* [ ] No

### 15.3 ¿Debe recibir `tenantId`?

* [x] Sí
* [ ] No

### 15.4 ¿Debe recibir `campaignId`?

* [ ] Sí
* [x] No

### 15.5 ¿Debe recibir `jobId`?

* [x] Sí
* [ ] No

### 15.6 ¿Debe recibir `requestedBy`?

* [x] Sí
* [ ] No

---

# 16. Respuesta del Prospector Service

### 16.1 ¿El Prospector Service ejecutará la extracción de forma síncrona?

* [ ] Sí
* [x] No
* [ ] No está decidido

### 16.2 ¿Qué debe devolver?

Actualmente se plantea:

```json
{
  "status": "COMPLETED",
  "businesses": [],
  "executionTime": 0.000ms,
  "error": null
}
```

¿Es correcto?

* [x] Sí
* [ ] No

Cambios:

> debe actualzar cada estado del job de manera asyncrona al backend saas, para que el usuario pueda observar con relativo detalle el proceso etapa por etapa, como va cargando y las actualizaciones del pipeline interno de la fuente seleccionada sin bloqueqar el resto de funciones y modulos de la plataforma.

### 16.3 ¿Debe el Service devolver el estado del Job?

* [x] Sí
* [ ] No, Platform es propietario del estado

### 16.4 ¿Debe el Service persistir resultados?

* [ ] Sí
* [x] No

---

# 17. Errores entre servicios

### 17.1 ¿El Prospector Service debe devolver errores propios mediante el mismo modelo de error?

* [x] Sí
* [ ] No
por homogeneidad en contratos del sistema 
### 17.2 ¿Platform Backend debe traducir los errores del Service?

* [x] Sí
* [ ] No

### 17.3 ¿El cliente Flutter debe conocer errores internos del Engine?

* [ ] Sí
* [x] No

> Esta pregunta es importante para evitar que errores internos de scraping terminen expuestos como parte del contrato público.

---

# 18. Cancelación

### 18.1 ¿Quién solicita la cancelación?

* [ ] Flutter → Platform Backend
* [ ] Platform Backend → Prospector Service
* [x] Flutter → Platform Backend → Prospector Service

### 18.2 ¿El Service debe recibir explícitamente una orden de cancelación?

* [x] Sí
* [ ] No
* [ ] Todavía no definido

### 18.3 ¿Qué debe suceder si el Job ya está `COMPLETED`?

* [ ] Error
* [x] No-op
* [ ] Otro: _________

### 18.4 ¿Qué debe suceder si ya está `FAILED` o `CANCELLED`?

> se bloquea opcion Cancelacion. se permite reintentar.

---

# 19. Persistencia de resultados

### 19.1 Cuando el usuario decide conservar resultados, ¿qué ocurre?

Confirma:

```text
Resultados temporales
        ↓
Detección de duplicados
        ↓
Crear/identificar Prospect
        ↓
Crear CampaignProspect
```

* [x] Sí
* [ ] No
* [ ] Modificar: _________

### 19.2 ¿Esta operación forma parte del contrato de Fase 2?

* [x] Sí
* [ ] No

### 19.3 ¿Debe ser idempotente?

* [ ] Sí
* [ ] No
* [x] Aún no definido

---

# 20. Exportación

### 20.1 ¿La API soportará exportación?

* [x] Sí
* [ ] No

### 20.2 ¿Formatos?

* [ ] CSV
* [ ] XLSX
* [x] Ambos
son los formatos actualmente soportados por el engine de prospeccion por lo que se delega a prospector service y el backend saas solo orquesta y persiste en db
### 20.3 ¿La exportación será?

* [ ] Síncrona
* [x] Asíncrona
* [ ] Depende del tamaño

### 20.4 ¿Debe formar parte de este ADR?

* [ ] Sí
* [x] No, dejar para contrato posterior

---

# 21. Qué NO debe decidir este ADR

Marca lo que debe quedar explícitamente fuera del contrato:

* [x] Redis
* [x] RabbitMQ
* [x] Celery
* [x] Workers
* [x] Docker
* [x] Kubernetes
* [x] Implementación interna del Engine
* [x] Base de datos interna del Service
* [x] RLS
* [ ] JWT/API Key/mTLS
* [x] CI/CD
* [x] Cloud provider
* [x] Observabilidad interna
* [ ] Otro: _________

---

# 22. Decisiones que quieres dejar abiertas

Indica cualquier tema que **no quieras cerrar todavía**:

> ---

---

# 23. Criterio de DeepSeek para generar el ADR

Finalmente, dale esta instrucción:

> Si alguna respuesta entra en contradicción con la documentación del proyecto, NO corrijas automáticamente la decisión. Señala la contradicción y explica cuál es el conflicto.
>
> Si una decisión no fue respondida, pero la documentación establece claramente una solución, puedes marcarla como "definida por documentación".
>
> Si ni las respuestas ni la documentación permiten determinarla, marcarla como "PENDIENTE DE DECISIÓN" en lugar de inventarla.
>
> El ADR debe distinguir claramente entre:
>
> 1. Decisiones tomadas en esta fase.
> 2. Decisiones heredadas de documentación previa.
> 3. Decisiones pendientes.
> 4. Decisiones explícitamente fuera del alcance.
>
> Genera el ADR con:
>
> * Contexto
> * Problema
> * Decisión
> * Convenciones
> * Platform API
> * Prospector Service API
> * Job Contract
> * Error Contract
> * Integration Contract
> * Ejemplos JSON
> * Consecuencias
> * Decisiones pendientes
> * Fuera de alcance
> * Referencias a la documentación utilizada

### Mi recomendación

**No necesitas responder las 70 preguntas una por una.** El formulario está deliberadamente exhaustivo para que no se nos escape una decisión importante. Muchas pueden contestarse con `Sí/No`, y otras DeepSeek puede resolverlas directamente desde la documentación.

Las que **sí quiero que definamos nosotros con especial cuidado** antes de generar el ADR son:

1. **¿API pública y Service API tendrán el mismo formato de respuesta?**
2. **Modelo exacto de errores.**
3. **Versionado.**
4. **IDs.**
5. **Paginación mínima del MVP.**
6. **Filtros/búsqueda/ordenamiento mínimos.**
7. **DTO exacto de `ProspectingJob`.**
8. **DTO exacto de `query`.**
9. **Qué devuelve `GET /prospecting-jobs/{id}`.**
10. **La relación síncrona/asíncrona entre Platform → Service.**
11. **Cómo se representa la cancelación en el contrato.**
12. **Idempotencia de creación de Jobs.**
13. **Qué información cruza realmente entre Platform y Prospector Service.**

Especialmente **la #10**: es la decisión que no dejaría que DeepSeek infiera. El hecho de que el usuario vea un `ProspectingJob` con estados `QUEUED/RUNNING/...` no necesariamente significa que el Prospector Service tenga que ser asíncrono. Podemos perfectamente tener **Job asíncrono a nivel de Platform y ejecución síncrona dentro de Prospector Service**, pero eso debe quedar como una decisión explícita del proyecto.
