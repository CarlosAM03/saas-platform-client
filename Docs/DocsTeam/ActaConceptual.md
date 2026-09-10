# Acta de Propuesta Conceptual

> Nota de vigencia: este documento es histórico o conceptual. No sustituye ADR-004, el contrato OpenAPI, FormularioDecisionesFase5.md ni ADR-005-FlutterFoundation.md. En caso de contradicción, prevalecen los documentos normativos vigentes.

> **Nota:** Este documento refleja el diseño conceptual inicial. Para las decisiones vigentes de implementación (Fase 4), consulte `ADR-004`.

## Sistema de Prospección Automatizada y Gestión de Campañas de Marketing

**Versión:** 1.0 — Propuesta conceptual
**Fecha:** Agosto 2026
**Asignatura:** Desarrollo de Software con Cómputo en la Nube
**Profesor:** Ramon Loaiza Chavez

---

# 1. Integrantes del equipo

| Nombre completo                 | Número de control |
| ------------------------------- | ----------------: |
| Armenta Marquez Carlos Benjamin |          22211523 |
| Rodríguez Sánchez André Gael    |          22211646 |
| Gonzalez Gamboa Angeles Jizeth  |          22211573 |
| Lopez Calvillo Angel Ivan       |          22211596 |

---

# 2. Identificación del sistema

**Nombre del proyecto:**

**Sistema de Prospección Automatizada y Gestión de Campañas de Marketing**

**Tipo de sistema:**

Plataforma SaaS multiplataforma de prospección y gestión de campañas de marketing digital.

**Modelo arquitectónico:**

Sistema distribuido de arquitectura políglota, orientado a servicios, con soporte para despliegue híbrido o completamente en la nube.

**Modelo de negocio conceptual:**

Software as a Service (SaaS) multi-tenant.

---

# 3. Antecedentes

El proyecto nace de la necesidad de centralizar y automatizar actividades relacionadas con la obtención, organización y utilización de prospectos comerciales.

Actualmente, la generación de prospectos puede requerir búsquedas manuales, extracción de información desde fuentes públicas, procesamiento de datos y posteriormente organización de los resultados para utilizarlos en actividades comerciales o de marketing.

El sistema propuesto busca integrar estas actividades dentro de una plataforma que permita:

* administrar organizaciones;
* administrar usuarios;
* crear campañas;
* solicitar prospectos;
* almacenar prospectos;
* organizar prospectos por campaña;
* consultar y analizar información;
* exportar resultados;
* mantener aislamiento de información entre organizaciones.

La automatización de la obtención de prospectos será proporcionada por un servicio especializado basado en el motor desarrollado previamente en **Prospector CLI**.

---

# 4. Relación con Prospector CLI
## CASO DE USO REAL

- Prospector CLI v0.7.0.

✓ Motor funcional
✓ Obtención automatizada
✓ Información requerida por Marketing
✓ Prospectos utilizados en operación real
✓ Validación del flujo de extracción
✓ Base tecnológica para el nuevo sistema
## 4.1. Sistemas relacionados pero independientes

El proyecto académico **no constituye una nueva versión de Prospector CLI**.

Son dos productos/componentes diferentes.

### Prospector CLI

Prospector CLI es un motor de extracción de información empresarial desde fuentes públicas.

Su responsabilidad actual está delimitada a:

```text
Extracción
    ↓
Normalización
    ↓
Validación
    ↓
Deduplicación
    ↓
Exportación
```

La arquitectura documentada explícitamente excluye responsabilidades como CRM, autenticación, dashboards, campañas, analítica de negocio, workflows comerciales y persistencia de negocio.

Su pipeline actual está diseñado alrededor de etapas independientes de entrada, configuración, búsqueda, scraping, normalización, validación, deduplicación y exportación.

### Plataforma SaaS

La plataforma académica será responsable de:

```text
Usuarios
Organizaciones
Autenticación
Autorización
Campañas
Prospectos
Persistencia
Gobernanza de datos
Análisis
Exportaciones
Integración con servicios externos
```

Por lo tanto:

```text
Prospector CLI
        =
Motor de obtención de datos

Plataforma SaaS
        =
Sistema de gestión y explotación de esos datos
```

---

# 5. Visión general del sistema

La plataforma permitirá que diferentes organizaciones utilicen una misma infraestructura lógica sin compartir información entre ellas.

Cada organización representa un **tenant**.

El usuario accederá mediante una aplicación multiplataforma desarrollada con Flutter.

La aplicación se comunicará exclusivamente con el backend principal mediante una API.

El backend principal será desarrollado con NestJS y Prisma ORM y será responsable de la lógica de negocio, autorización, multitenencia, persistencia y coordinación de servicios externos.

La generación automatizada de prospectos será delegada a un servicio especializado desarrollado con Python y FastAPI.

Este servicio encapsulará el acceso al motor de prospección basado en Prospector CLI.

---

# 6. Arquitectura global

La arquitectura global propuesta es:

```text
                         USUARIO
                            │
                            ▼
                  ┌──────────────────┐
                  │ Flutter Client   │
                  │ Web / Desktop /  │
                  │ Mobile           │
                  └────────┬─────────┘
                           │ HTTPS
                           ▼
                  ┌──────────────────┐
                  │ API / Backend    │
                  │ NestJS            │
                  │                  │
                  │ Auth             │
                  │ Tenancy          │
                  │ Campaigns        │
                  │ Prospects        │
                  │ Analytics        │
                  │ Integration      │
                  └───────┬─────┬────┘
                          │     │
                    Prisma│     │HTTP
                          │     │
                          ▼     ▼
                 ┌────────────┐ ┌────────────────────┐
                 │ PostgreSQL │ │ Prospector Service │
                 │            │ │ Python + FastAPI   │
                 └────────────┘ └─────────┬──────────┘
                                          │
                                          ▼
                                ┌────────────────────┐
                                │ Prospector Core    │
                                │ Python             │
                                └─────────┬──────────┘
                                          │
                                          ▼
                                    Public Sources
                                    Google Maps
```

---

# 7. Principio arquitectónico principal

El sistema no se diseñará como una colección de microservicios por defecto.

Se utilizará una **arquitectura distribuida con componentes claramente delimitados**, donde cada componente tendrá una responsabilidad concreta.

La distribución de componentes responde a la naturaleza de cada problema y no a la necesidad de convertir artificialmente cada módulo en un microservicio.

La arquitectura prioriza:

1. Separación de responsabilidades.
2. Bajo acoplamiento.
3. Cohesión interna.
4. Interoperabilidad.
5. Independencia tecnológica cuando aporte valor.
6. Portabilidad entre infraestructura local y cloud.
7. Evolución incremental.
8. Facilidad de mantenimiento.
9. Seguridad y aislamiento de tenants.
10. Utilización de la tecnología más apropiada para cada responsabilidad.

---

# 8. Arquitectura políglota

La arquitectura será políglota porque diferentes componentes utilizarán tecnologías diferentes cuando sus características proporcionen una ventaja clara.

| Componente              | Tecnología       | Responsabilidad                  |
| ----------------------- | ---------------- | -------------------------------- |
| Cliente                 | Dart + Flutter   | Interfaz multiplataforma         |
| Backend                 | Node.js + NestJS | API y dominio de negocio         |
| ORM                     | Prisma           | Persistencia y acceso relacional |
| Base de datos           | PostgreSQL       | Persistencia transaccional       |
| Servicio de prospección | Python + FastAPI | Exponer el motor de prospección  |
| Motor de prospección    | Python           | Extracción y procesamiento       |
| Automatización web      | Playwright       | Interacción con fuentes web      |
| Contenedores            | Docker           | Empaquetamiento y portabilidad   |
| Infraestructura         | Cloud / híbrida  | Ejecución y operación            |

La elección tecnológica no pretende homogeneizar el sistema, sino asignar cada tecnología al problema para el cual resulta más adecuada.

---

# 9. Arquitectura de software

La arquitectura de software de la plataforma principal seguirá una estructura modular dentro de NestJS.

```text
NestJS Application
│
├── Auth
│
├── Tenants
│
├── Users
│
├── Campaigns
│
├── Prospects
│
├── Prospect Acquisition
│
├── Analytics
│
├── Exports
│
└── External Integrations
```

El backend funcionará inicialmente como un **modular monolith**, no como múltiples microservicios internos.

Esto permite mantener una única unidad de despliegue para el dominio principal, reduciendo complejidad operacional mientras las fronteras de responsabilidad permanecen claramente definidas.

---

# 10. Responsabilidades del backend NestJS

NestJS será el núcleo de la plataforma.

Será responsable de:

* autenticación;
* autorización;
* gestión de usuarios;
* gestión de organizaciones;
* resolución del tenant;
* aplicación de reglas de negocio;
* gestión de campañas;
* gestión de prospectos;
* persistencia;
* consulta y filtrado;
* análisis de información;
* exportaciones;
* integración con Prospector Service;
* validación de solicitudes;
* auditoría de operaciones relevantes;
* exposición de la API pública de la plataforma.

NestJS **no implementará directamente scraping de Google Maps**.

---

# 11. Responsabilidades de Prospector Service

Prospector Service será un servicio externo desarrollado con Python + FastAPI.

Su responsabilidad será actuar como frontera entre la plataforma y el motor de prospección.

```text
Platform Backend
       │
       │ HTTP API
       ▼
Prospector Service
       │
       ▼
Prospector Core
       │
       ▼
Google Maps
```

Prospector Service será responsable de:

* recibir solicitudes de prospección;
* validar parámetros propios del servicio;
* iniciar ejecuciones del motor;
* administrar el ciclo de ejecución del proceso;
* transformar la salida del motor al contrato del servicio;
* devolver resultados y metadatos de ejecución;
* comunicar errores de ejecución;
* ocultar los detalles internos de Playwright y del scraper.

El backend de la plataforma no deberá conocer detalles como:

* selectores;
* Playwright;
* DOM;
* navegación de Google Maps;
* sincronización;
* LazyCharge;
* Detail Panel;
* Website Engine.

La documentación actual de Prospector establece precisamente que los scrapers deben encapsular sus estrategias internas y exponer resultados normalizados al resto del sistema.

---

# 12. Prospector Core

Prospector Core representa la evolución reutilizable del motor desarrollado en Prospector CLI.

La arquitectura actual ya separa:

```text
CLI
    ↓
Configuration
    ↓
Query Builder
    ↓
Scraper
    ↓
Normalization
    ↓
Validation
    ↓
Deduplication
    ↓
Exporter
```

Para la plataforma SaaS, el CLI no será invocado como interfaz de usuario.

La funcionalidad reutilizable será consumida desde Python mediante una interfaz de servicio.

La evolución conceptual será:

```text
                  ┌───────────────┐
                  │ Prospector    │
                  │ Core          │
                  └───────┬───────┘
                          │
                ┌─────────┴─────────┐
                │                   │
                ▼                   ▼
          Prospector CLI     Prospector Service
          Open Source             FastAPI
                                      │
                                      ▼
                               Plataforma SaaS
```

Esto permite conservar dos formas de consumo:

### CLI

Orientado a usuarios técnicos, experimentación, desarrollo y distribución open source.

### API

Orientado a plataformas comerciales y consumo bajo demanda.

---

# 13. Contrato entre NestJS y Prospector Service

El backend no debe consumir funciones internas de Python directamente.

La comunicación se realizará mediante un contrato HTTP.

Conceptualmente:

```text
POST /prospecting/jobs
```

Solicitud:

```json
{
  "query": "maquila tijuana",
  "limit": 100
}
```

Respuesta conceptual:

```json
{
  "jobId": "job_123",
  "status": "queued"
}
```

Posteriormente:

```text
GET /prospecting/jobs/{jobId}
```

Respuesta:

```json
{
  "jobId": "job_123",
  "status": "completed",
  "results": [...]
}
```

El contrato definitivo de la API queda pendiente de especificación técnica.

La arquitectura, sin embargo, establece desde ahora que:

**NestJS conoce el contrato del servicio, pero no conoce su implementación.**

---

# 14. Ejecuciones asíncronas

La generación de prospectos es una operación potencialmente larga debido a la automatización de navegador y acceso a fuentes externas.

Por ello, la plataforma no deberá asumir que una solicitud de generación puede resolverse inmediatamente mediante una petición HTTP tradicional.

El modelo conceptual será:

```text
Usuario
  │
  ▼
Crear solicitud
  │
  ▼
NestJS
  │
  ▼
Prospector Service
  │
  ▼
Job
  │
  ├── queued
  ├── running
  ├── completed
  └── failed
```

La plataforma podrá consultar posteriormente el estado de la ejecución.

La tecnología concreta para la cola y ejecución distribuida será una decisión de la fase de arquitectura técnica y no se fija todavía como requisito del sistema.

---

# 15. Arquitectura de infraestructura

La infraestructura deberá ser portable entre:

```text
Infraestructura local
        │
        ├── Docker
        │
        ├── PostgreSQL
        │
        ├── NestJS
        │
        └── Prospector Service
```

y:

```text
Cloud
 │
 ├── Flutter/Web Client
 │
 ├── API / NestJS
 │
 ├── Prospector Service
 │
 ├── PostgreSQL administrado
 │
 ├── Object Storage
 │
 └── Observability
```

La infraestructura se diseñará con componentes contenedorizados para evitar acoplamiento innecesario con un proveedor específico.

---

# 16. Infraestructura lógica

```text
Internet
   │
   ▼
┌──────────────────────┐
│ Reverse Proxy /      │
│ Load Balancer        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ NestJS API           │
│ Platform Backend     │
└───────┬──────┬───────┘
        │      │
        │      └──────────────────┐
        ▼                         ▼
┌──────────────┐        ┌─────────────────────┐
│ PostgreSQL   │        │ Prospector Service  │
│              │        │ FastAPI             │
└──────────────┘        └──────────┬──────────┘
                                   │
                                   ▼
                          ┌──────────────────┐
                          │ Prospector Core  │
                          └────────┬─────────┘
                                   │
                                   ▼
                              Google Maps
```

---

# 17. Persistencia

PostgreSQL será el sistema principal de persistencia.

La elección se debe a que el dominio contiene relaciones estructuradas entre:

```text
Tenant
  │
  ├── Users
  │
  └── Campaigns
          │
          └── Prospects
```

Además, PostgreSQL permite implementar:

* integridad referencial;
* transacciones;
* índices;
* restricciones;
* relaciones;
* consultas analíticas;
* aislamiento lógico mediante tenant_id;
* mecanismos adicionales de seguridad como Row Level Security.

Prisma ORM será utilizado como capa de acceso y modelado desde NestJS.

---

# 18. Estrategia de Multi-Tenancy

La estrategia inicial será:

**Shared Database + Shared Schema + Tenant ID**

Es decir, una única base de datos y un único esquema lógico contendrán información de múltiples organizaciones.

Las entidades pertenecientes a un tenant contendrán una referencia:

```text
tenant_id
```

Conceptualmente:

```text
Tenant
 │
 ├── User
 ├── Campaign
 ├── Prospect
 └── CampaignProspect
```

Ejemplo:

```text
Tenant A
 ├── Campaign 1
 │    ├── Prospect 1
 │    └── Prospect 2
 │
 └── Campaign 2
      └── Prospect 3


Tenant B
 └── Campaign 3
      ├── Prospect 4
      └── Prospect 5
```

Tenant A nunca deberá poder consultar información perteneciente a Tenant B.

---

# 19. Aislamiento de tenants

El aislamiento se implementará mediante varias capas.

## Capa 1 — Aplicación

NestJS determinará el tenant asociado a la sesión autenticada.

Las consultas deberán incluir el contexto del tenant.

Conceptualmente:

```text
request
   ↓
authenticated user
   ↓
tenant context
   ↓
business logic
   ↓
database query
```

## Capa 2 — Modelo de datos

Las entidades multi-tenant tendrán relación explícita con `tenant`.

## Capa 3 — Base de datos

Como mecanismo adicional de defensa, podrá utilizarse PostgreSQL Row Level Security.

La decisión de implementar RLS desde la primera iteración queda como decisión técnica posterior, pero la arquitectura debe mantener compatibilidad con esta estrategia.

---

# 20. Regla fundamental de seguridad multi-tenant

El tenant nunca deberá ser confiado únicamente a un parámetro proporcionado por el cliente.

No se deberá aceptar:

```text
GET /campaigns?tenantId=otro-tenant
```

como mecanismo de autorización.

El tenant deberá derivarse del contexto autenticado y autorizado.

```text
JWT / Session
      ↓
User
      ↓
Tenant Membership
      ↓
Tenant Context
      ↓
Data Access
```

---

# 21. Modelo conceptual de datos

El primer modelo de datos propuesto es:

```text
Tenant
 │
 ├───────────────┐
 │               │
 ▼               ▼
User          Campaign
                 │
                 │
                 ▼
          CampaignProspect
                 │
                 ▼
             Prospect
```

---

# 22. Entidades principales

## Tenant

Representa una organización que utiliza la plataforma.

Atributos iniciales:

```text
id
name
slug
status
created_at
updated_at
```

---

## User

Representa un usuario de la plataforma.

```text
id
tenant_id
name
email
password_hash / identity_reference
role
status
created_at
updated_at
```

---

## Campaign

Representa una campaña de prospección.

```text
id
tenant_id
name
description
status
created_at
updated_at
```

---

## Prospect

Representa un prospecto persistido dentro de la plataforma.

```text
id
tenant_id
name
category
address
phone
email
website
source
source_identifier
language
metadata
created_at
updated_at
```

La estructura definitiva deberá evolucionar después de analizar el contrato final del motor.

Esto es especialmente importante porque Prospector CLI todavía tiene pendiente definir exactamente qué representa `Business`, qué identidad debe conservar y qué información debe sobrevivir hasta la salida final.

---

## CampaignProspect

Entidad de relación entre campañas y prospectos.

```text
campaign_id
prospect_id
status
added_at
```

Esta separación permite que un mismo prospecto pueda potencialmente participar en diferentes campañas sin duplicar necesariamente toda la información.

---

## ProspectingJob

Representa una solicitud de obtención de prospectos.

```text
id
tenant_id
campaign_id
status
query
requested_limit
requested_by
started_at
completed_at
error
created_at
```

Conceptualmente:

```text
Campaign
    │
    ▼
ProspectingJob
    │
    ▼
Prospector Service
    │
    ▼
Results
    │
    ▼
Prospects
```

---

# 23. Flujo principal de generación de prospectos

```text
Usuario
  │
  ▼
Flutter
  │
  │ Crear solicitud
  ▼
NestJS
  │
  ├── validar usuario
  ├── validar tenant
  ├── validar campaña
  └── crear ProspectingJob
  │
  ▼
Prospector Service
  │
  ▼
Prospector Core
  │
  ▼
Google Maps
  │
  ▼
Business[]
  │
  ▼
Resultado normalizado
  │
  ▼
NestJS
  │
  ├── validar
  ├── normalizar
  ├── deduplicar
  └── persistir
  │
  ▼
PostgreSQL
  │
  ▼
CampaignProspect
  │
  ▼
Flutter
```

---

# 24. Gobierno de datos

Una diferencia fundamental entre Prospector CLI y la plataforma será el gobierno de datos.

Prospector CLI produce información.

La plataforma administra el ciclo de vida de esa información.

Por lo tanto:

```text
Prospector
    ↓
Obtiene datos

Platform
    ↓
Valida
    ↓
Persiste
    ↓
Relaciona
    ↓
Clasifica
    ↓
Analiza
    ↓
Administra
    ↓
Exporta
```

La plataforma será la autoridad sobre los datos persistidos.

Prospector Service no será el sistema de registro permanente de prospectos.

---

# 25. Deduplicación

La deduplicación de prospectos será responsabilidad de la plataforma.

El motor de prospección puede proporcionar identificadores o metadata provenientes de la fuente, pero la plataforma deberá decidir cuándo dos resultados representan el mismo prospecto dentro de su dominio.

Esto evita trasladar reglas de negocio de la plataforma al motor.

Una posible estrategia inicial será utilizar una combinación de:

```text
tenant
+
source
+
source_identifier
```

complementada, cuando sea necesario, con atributos normalizados como:

```text
name
address
phone
website
```

La estrategia definitiva será definida durante el diseño técnico.

---

# 26. Gestión de campañas

Una campaña representa el contexto comercial en el que se utilizan determinados prospectos.

La campaña podrá contener:

* nombre;
* descripción;
* estado;
* criterios de prospección;
* prospectos asociados;
* fecha de creación;
* responsable;
* métricas.

Conceptualmente:

```text
Campaign
   │
   ├── Search criteria
   │
   ├── Prospecting jobs
   │
   ├── Prospects
   │
   └── Metrics
```

---

# 27. Requerimientos funcionales

## RF-01 — Registro de organización

El sistema deberá permitir registrar una organización como tenant.

## RF-02 — Autenticación

El sistema deberá permitir a los usuarios autenticarse.

## RF-03 — Gestión de usuarios

Los usuarios autorizados deberán poder administrar miembros de su organización de acuerdo con sus permisos.

## RF-04 — Aislamiento de información

El sistema deberá impedir que un usuario consulte o modifique información perteneciente a otro tenant.

## RF-05 — Gestión de campañas

Los usuarios autorizados deberán poder crear, consultar, modificar y administrar campañas.

## RF-06 — Solicitud de prospectos

El usuario deberá poder solicitar la generación de prospectos indicando al menos criterios de búsqueda y límite solicitado.

## RF-07 — Ejecución de prospección

El sistema deberá comunicarse con Prospector Service para ejecutar una operación de prospección.

## RF-08 — Seguimiento de ejecución

El usuario deberá poder consultar el estado de una solicitud de prospección.

Estados conceptuales:

```text
Queued
Running
Completed
Failed
```

## RF-09 — Persistencia de resultados

Los resultados válidos deberán almacenarse en PostgreSQL.

## RF-10 — Asociación con campañas

Los prospectos obtenidos deberán poder asociarse con una campaña.

## RF-11 — Consulta de prospectos

Los usuarios deberán poder consultar los prospectos pertenecientes a su organización.

## RF-12 — Filtrado

El sistema deberá permitir filtrar prospectos mediante atributos relevantes.

## RF-13 — Búsqueda

El sistema deberá permitir localizar prospectos mediante criterios de búsqueda.

## RF-14 — Exportación

El sistema deberá permitir exportar prospectos a formatos definidos por la plataforma.

## RF-15 — Análisis

El sistema deberá proporcionar información agregada relacionada con campañas y prospectos.

## RF-16 — Administración de campañas

Los usuarios autorizados deberán poder modificar el estado y configuración de las campañas.

## RF-17 — Integración externa

La plataforma deberá poder comunicarse con Prospector Service mediante una interfaz definida.

## RF-18 — Gestión de errores

La plataforma deberá informar al usuario cuando una operación de prospección no pueda completarse.

---

# 28. Requerimientos no funcionales

## RNF-01 — Seguridad

La comunicación entre componentes deberá utilizar protocolos seguros.

## RNF-02 — Aislamiento

Los datos de tenants deberán permanecer aislados lógica y funcionalmente.

## RNF-03 — Portabilidad

Los componentes deberán poder ejecutarse mediante contenedores.

## RNF-04 — Escalabilidad

Los componentes con mayor consumo de recursos deberán poder escalar independientemente cuando la infraestructura lo permita.

## RNF-05 — Mantenibilidad

Cada componente deberá mantener responsabilidades claramente delimitadas.

## RNF-06 — Observabilidad

El sistema deberá registrar eventos relevantes de ejecución, errores y operaciones importantes.

## RNF-07 — Interoperabilidad

Los componentes desarrollados con tecnologías diferentes deberán comunicarse mediante contratos estables.

## RNF-08 — Disponibilidad

El backend principal deberá permanecer disponible independientemente de que una operación individual de prospección esté ejecutándose.

## RNF-09 — Trazabilidad

Las operaciones importantes deberán poder relacionarse con:

```text
tenant
user
campaign
job
prospect
```

## RNF-10 — Evolución

La arquitectura deberá permitir reemplazar o ampliar el motor de prospección sin rediseñar el dominio principal.

---

# 29. Alcance de la versión 1

La primera versión del sistema académico incluirá:

### Plataforma

* Aplicación Flutter.
* API NestJS.
* PostgreSQL.
* Prisma ORM.
* Autenticación.
* Gestión de tenants.
* Gestión de usuarios.
* Gestión de campañas.
* Gestión de prospectos.
* Solicitud de prospección.
* Consulta de estado de jobs.
* Persistencia de resultados.
* Filtrado y búsqueda.
* Exportación.
* Métricas básicas.

### Prospección

* Integración con Prospector Service.
* Python.
* FastAPI.
* Integración con Prospector Core.
* Google Maps como fuente inicial.

### Infraestructura

* Docker.
* Entorno local.
* Entorno cloud.
* Configuración mediante variables de entorno.
* Persistencia PostgreSQL.
* Comunicación HTTP segura.

---

# 30. Fuera del alcance de la versión 1

La primera versión no tendrá como objetivo:

* convertir Prospector en microservicios;
* implementar múltiples fuentes de scraping;
* desarrollar un CRM completo;
* automatización avanzada de correo electrónico;
* WhatsApp;
* campañas multicanal;
* inteligencia artificial;
* scoring avanzado mediante ML;
* facturación SaaS completa;
* marketplace;
* sistema complejo de suscripciones;
* infraestructura multi-cloud avanzada;
* Kubernetes como requisito;
* arquitectura de microservicios completa.

Estas capacidades podrán considerarse posteriormente.

---

# 31. Frontera entre componentes

Una regla fundamental será:

```text
Flutter
   │
   │ UI / UX
   ▼
NestJS
   │
   │ Domain / Governance
   ▼
PostgreSQL


NestJS
   │
   │ Prospecting API
   ▼
Prospector Service
   │
   │ Extraction
   ▼
Prospector Core
   │
   │ Source interaction
   ▼
Google Maps
```

Cada componente debe permanecer dentro de su frontera.

---

# 32. Lo que Flutter NO hará

Flutter no deberá:

* acceder directamente a PostgreSQL;
* ejecutar consultas SQL;
* comunicarse directamente con Google Maps para scraping;
* conocer detalles de Prospector;
* implementar reglas de negocio críticas;
* administrar el aislamiento de tenants.

Flutter será un cliente del backend.

---

# 33. Lo que NestJS NO hará

NestJS no deberá:

* controlar Playwright;
* manipular DOM;
* implementar scraping;
* conocer selectores de Google Maps;
* ejecutar directamente el motor Python;
* convertirse en un wrapper de cada función interna de Prospector.

NestJS será consumidor del contrato de Prospector Service.

---

# 34. Lo que Prospector Service NO hará

Prospector Service no será responsable de:

* usuarios;
* tenants;
* campañas;
* CRM;
* permisos de negocio;
* dashboards;
* persistencia comercial;
* relaciones entre prospectos y campañas.

Su responsabilidad será proporcionar una capacidad técnica:

```text
"Obtener prospectos a partir de criterios de búsqueda."
```

---

# 35. Lo que PostgreSQL NO hará

La base de datos será responsable de persistencia e integridad de datos.

No será responsable de:

* scraping;
* comunicación con Google Maps;
* lógica de interfaz;
* ejecución de campañas;
* orquestación de procesos externos.

---

# 36. Flujo completo de usuario

```text
1. Usuario inicia sesión
          │
          ▼
2. Selecciona organización
          │
          ▼
3. Accede al dashboard
          │
          ▼
4. Crea campaña
          │
          ▼
5. Define criterios de prospección
          │
          ▼
6. Solicita prospectos
          │
          ▼
7. NestJS crea Job
          │
          ▼
8. Prospector Service ejecuta motor
          │
          ▼
9. Se obtienen resultados
          │
          ▼
10. NestJS valida y persiste
          │
          ▼
11. Prospectos asociados a campaña
          │
          ▼
12. Usuario consulta resultados
          │
          ▼
13. Usuario filtra / analiza / exporta
```

---

# 37. Arquitectura híbrida

Una propiedad importante de la arquitectura será la posibilidad de separar físicamente los componentes.

Por ejemplo:

```text
Cloud
│
├── Flutter
├── NestJS
└── PostgreSQL

Infraestructura local / dedicada
│
└── Prospector Service
        │
        └── Prospector Core
```

O alternativamente:

```text
Cloud
│
├── Flutter
├── NestJS
├── PostgreSQL
└── Prospector Service
       │
       └── Prospector Core
```

El backend no debe depender de que Prospector se encuentre físicamente en el mismo servidor.

La comunicación deberá realizarse mediante un contrato de servicio.

---

# 38. Ventaja de la arquitectura híbrida

La separación permite que el motor de prospección tenga requerimientos de infraestructura diferentes al resto de la plataforma.

Por ejemplo, el motor puede requerir:

* navegador automatizado;
* mayor consumo de CPU/RAM;
* ejecución prolongada;
* características específicas del sistema operativo;
* aislamiento de procesos.

Mientras que la plataforma requiere principalmente:

* API;
* base de datos;
* procesamiento transaccional;
* autenticación;
* consultas;
* gestión de usuarios.

Por ello, no resulta necesario ejecutar todos los componentes en la misma infraestructura.

---

# 39. Arquitectura preparada para evolución

La arquitectura permitirá evolucionar:

```text
Google Maps
    │
    ▼
Prospector Core
```

hacia:

```text
                 ┌── Google Maps
                 │
Prospector Core ─┼── Future Source
                 │
                 └── Future Source
```

sin que NestJS necesite conocer las implementaciones internas de cada fuente.

La propia arquitectura de Prospector ya establece que cada scraper debe permanecer aislado y producir una representación normalizada común.

---

# 40. Estrategia de evolución

La evolución del sistema se dividirá conceptualmente en capas:

```text
Nivel 1
Producto
    ↓
Requerimientos
    ↓
Dominio

Nivel 2
Arquitectura de software
    ↓
Contratos
    ↓
Modelos

Nivel 3
Infraestructura
    ↓
Contenedores
    ↓
Cloud

Nivel 4
Operación
    ↓
Observabilidad
    ↓
Escalamiento
    ↓
Seguridad
```

No se introducirán tecnologías únicamente por su popularidad.

Cada componente deberá justificarse por la responsabilidad que resuelve.

---

# 41. Organización propuesta del trabajo

La distribución conceptual del trabajo del equipo podrá dividirse en:

## Backend / Arquitectura / Integración

Responsabilidades principales:

* arquitectura;
* NestJS;
* integración con Prospector Service;
* FastAPI;
* evolución de Prospector Core;
* PostgreSQL;
* Prisma;
* infraestructura;
* integración;
* contratos entre servicios;
* DevOps;
* supervisión técnica.

## Frontend

Responsabilidades principales:

* Flutter;
* navegación;
* interfaces;
* formularios;
* dashboard;
* gestión visual de campañas;
* visualización de prospectos;
* consumo de API.

## Base de datos / Backend

Responsabilidades principales:

* modelos Prisma;
* relaciones;
* migraciones;
* consultas;
* índices;
* validación del modelo de datos;
* soporte al backend.

Las decisiones de dominio y arquitectura deberán mantenerse centralizadas en el proceso de diseño del equipo antes de convertirse en implementación.

---

# 42. Principio de ownership técnico

El proyecto mantendrá una separación entre:

```text
Implementar
```

y

```text
Definir arquitectura
```

Una persona puede implementar una parte del sistema sin ser necesariamente responsable de decidir la arquitectura completa de esa parte.

Las decisiones arquitectónicas deberán documentarse antes de implementarse cuando afecten:

* contratos;
* persistencia;
* seguridad;
* multitenancy;
* comunicación entre servicios;
* infraestructura;
* dominio.

---

# 43. Riesgos iniciales

## R-01 — Acoplamiento entre plataforma y Prospector

Debe evitarse que NestJS dependa de estructuras internas del motor Python.

**Mitigación:** API contractual mediante FastAPI.

## R-02 — Operaciones de scraping prolongadas

Una ejecución puede tardar considerablemente más que una petición HTTP convencional.

**Mitigación:** modelo de Jobs y ejecución asíncrona.

## R-03 — Aislamiento multi-tenant

Un error de filtrado podría exponer información de otra organización.

**Mitigación:** tenant context + restricciones de modelo + mecanismos adicionales de PostgreSQL.

## R-04 — Cambios en Google Maps

Prospector depende actualmente de una interfaz web dinámica.

La documentación del scraper ya reconoce esta dependencia y utiliza mecanismos específicos de navegación, sincronización e identidad.

**Mitigación:** mantener la lógica de fuente completamente aislada dentro de Prospector.

## R-05 — Complejidad prematura

Existe riesgo de introducir microservicios, Kubernetes, colas y otros componentes antes de que sean necesarios.

**Mitigación:** modular monolith para el dominio + servicios externos únicamente donde exista una responsabilidad técnica clara.

---

# 44. Decisiones arquitectónicas preliminares

| ID     | Decisión                                                                   |
| ------ | -------------------------------------------------------------------------- |
| ADR-01 | Flutter será el cliente multiplataforma                                    |
| ADR-02 | NestJS será el backend principal                                           |
| ADR-03 | NestJS utilizará Prisma ORM                                                |
| ADR-04 | PostgreSQL será la base de datos principal                                 |
| ADR-05 | Prospector será consumido mediante FastAPI                                 |
| ADR-06 | Prospector Core permanecerá independiente del dominio SaaS                 |
| ADR-07 | La plataforma utilizará arquitectura multi-tenant                          |
| ADR-08 | La estrategia inicial será shared database/shared schema                   |
| ADR-09 | El tenant será parte explícita del modelo de datos                         |
| ADR-10 | El backend será inicialmente un modular monolith                           |
| ADR-11 | Las ejecuciones de prospección serán tratadas como jobs                    |
| ADR-12 | La infraestructura será containerizada                                     |
| ADR-13 | La arquitectura será portable entre cloud y entorno híbrido                |
| ADR-14 | Google Maps será la fuente inicial de prospección                          |
| ADR-15 | La plataforma será responsable de la persistencia y gobierno de prospectos |

Estas decisiones son **conceptuales**. Las decisiones técnicas detalladas se formalizarán posteriormente mediante Architecture Decision Records.

---

# 45. Arquitectura conceptual final

La arquitectura propuesta puede resumirse en cinco dominios:

```text
┌─────────────────────────────────────────────────────────────┐
│                         PRESENTACIÓN                        │
│                                                             │
│                    Flutter Application                      │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                         PLATAFORMA                          │
│                                                             │
│                         NestJS                              │
│                                                             │
│ Auth │ Tenants │ Users │ Campaigns │ Prospects │ Analytics │
│                                                             │
│                 Integration / API Layer                     │
└───────────────┬─────────────────────────────┬───────────────┘
                │                             │
                ▼                             ▼
┌─────────────────────────┐       ┌───────────────────────────┐
│       PostgreSQL        │       │   Prospector Service      │
│                         │       │        FastAPI            │
│ Tenant                  │       │                           │
│ User                    │       │  Prospecting API          │
│ Campaign                │       │  Job Management            │
│ Prospect                │       │  Result Transformation    │
│ ProspectingJob          │       │                           │
└─────────────────────────┘       └─────────────┬─────────────┘
                                                │
                                                ▼
                                    ┌──────────────────────────┐
                                    │    Prospector Core       │
                                    │         Python           │
                                    │                          │
                                    │ Navigation               │
                                    │ Scraping                 │
                                    │ Normalization             │
                                    │ Validation               │
                                    │ Website Enrichment       │
                                    └────────────┬─────────────┘
                                                 │
                                                 ▼
                                          Public Sources
                                          Google Maps
```

---

# 46. Principio rector del sistema

El principio fundamental de la arquitectura será:

> **Cada componente debe resolver un problema concreto y exponer únicamente la capacidad que los demás componentes necesitan consumir.**

Por lo tanto:

```text
Flutter
     → presenta

NestJS
     → gobierna

PostgreSQL
     → persiste

Prospector Service
     → sirve la capacidad de prospección

Prospector Core
     → obtiene y procesa prospectos

Google Maps
     → proporciona la fuente pública
```

La plataforma no necesita conocer cómo Prospector obtiene la información y Prospector no necesita conocer para qué campaña comercial será utilizada.

---

# 47. Definición conceptual de la versión 1

La versión 1 del sistema será considerada un **MVP SaaS multi-tenant de prospección y gestión de campañas**, compuesto por:

```text
Cliente multiplataforma
        +
Backend de plataforma
        +
Persistencia relacional
        +
Servicio externo de prospección
        +
Motor de extracción
```

El objetivo de la primera versión no será demostrar una arquitectura de microservicios compleja.

El objetivo será demostrar que:

1. múltiples organizaciones pueden utilizar la plataforma;
2. sus datos permanecen aislados;
3. los usuarios pueden administrar campañas;
4. las campañas pueden solicitar prospectos;
5. el backend puede consumir un servicio externo;
6. el motor existente puede convertirse en una capacidad reutilizable mediante API;
7. los resultados pueden persistirse;
8. los prospectos pueden consultarse y administrarse;
9. la infraestructura puede ejecutarse localmente o en cloud;
10. cada componente mantiene una responsabilidad claramente delimitada.

---

# 48. Estado del documento

Este documento representa la **arquitectura conceptual inicial**.

Todavía quedan por especificar:

```text
Requerimientos detallados
        ↓
Casos de uso
        ↓
Modelo de dominio
        ↓
Modelo ER definitivo
        ↓
Contrato OpenAPI
        ↓
Contrato Prospector Service
        ↓
Autenticación
        ↓
Autorización
        ↓
Tenant Resolution
        ↓
Estrategia definitiva de RLS
        ↓
Job / Queue Architecture
        ↓
Docker Architecture
        ↓
Cloud Architecture
        ↓
CI/CD
        ↓
Observabilidad
        ↓
Seguridad
        ↓
Plan de implementación
```

Por lo tanto, ninguna tecnología adicional deberá incorporarse únicamente por anticipación.

Cada decisión deberá derivarse de los requerimientos y responsabilidades que se establezcan posteriormente.

---

# 49. Conclusión

El sistema propuesto será una plataforma SaaS multi-tenant que utiliza una arquitectura distribuida y políglota para separar claramente la experiencia de usuario, el dominio de negocio, la persistencia y la generación automatizada de prospectos.

La plataforma será propietaria del dominio de negocio y del ciclo de vida de los datos, mientras que Prospector será tratado como una capacidad especializada de obtención de información.

Esta separación permite que Prospector continúe evolucionando como proyecto independiente y potencialmente open source, mientras que su capacidad de generación de prospectos puede ser consumida comercialmente mediante un servicio API.

La arquitectura propuesta evita acoplar el dominio comercial con la tecnología utilizada para realizar scraping y permite que cada componente evolucione independientemente dentro de una frontera claramente definida.

La primera versión priorizará la correcta separación de responsabilidades, multitenencia, integración entre servicios, persistencia y despliegue cloud/híbrido antes que la incorporación de infraestructura distribuida innecesariamente compleja.
