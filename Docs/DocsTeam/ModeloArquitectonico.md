
# Modelo Arquitectónico Técnico

> Nota de vigencia: este documento es conceptual e histórico. No sustituye ADR-004, el contrato OpenAPI, FormularioDecisionesFase5.md ni ADR-005-FlutterFoundation.md. En caso de contradicción, prevalecen los documentos normativos vigentes.

> **Nota:** Este documento refleja el diseño conceptual inicial. Para las decisiones vigentes de implementación (Fase 4), consulte `ADR-004`.

**Sistema de Prospección Automatizada y Gestión de Campañas de Marketing**

**Versión:** 1.0
**Estado:** Propuesta arquitectónica para implementación
**Fecha:** Agosto 2026
**Asignatura:** Desarrollo de Software con Cómputo en la Nube
**Profesor:** Ramon Loaiza Chavez

---

# 1. Propósito del documento

El presente documento define el modelo arquitectónico técnico del **Sistema de Prospección Automatizada y Gestión de Campañas de Marketing**.

Su propósito es transformar la arquitectura conceptual definida en el acta de propuesta del proyecto en una estructura técnica que pueda utilizarse como base para:

* diseño detallado;
* implementación;
* integración;
* pruebas;
* despliegue;
* documentación;
* evolución del sistema.

El modelo establece la distribución de responsabilidades entre componentes, las fronteras de comunicación, los mecanismos generales de persistencia, la estrategia multi-tenant, el flujo de ejecución de operaciones de prospección y los principios que deberán respetarse durante la implementación.

Este documento no pretende definir todavía todos los detalles internos de cada módulo. Las decisiones relacionadas con contratos definitivos, esquema exacto de base de datos, autenticación, autorización, infraestructura específica y mecanismos avanzados de ejecución serán refinadas durante las etapas posteriores de diseño.

---

# 2. Alcance arquitectónico

La arquitectura comprende los siguientes componentes principales:

```text
┌──────────────────────────────────────────────────────────────┐
│                     PLATAFORMA SaaS                          │
│                                                              │
│  Flutter Client                                              │
│       │                                                      │
│       ▼                                                      │
│  NestJS Platform API                                         │
│       │                                                      │
│       ├──────────────► PostgreSQL                            │
│       │                                                      │
│       └──────────────► Prospector Service                    │
│                              │                               │
└──────────────────────────────┼───────────────────────────────┘
                               │
                               ▼
                    Prospector Core
                               │
                               ▼
                       Public Sources
```

La arquitectura deberá permitir que estos componentes sean ejecutados de forma independiente y puedan desplegarse en infraestructura local, cloud o híbrida.

---

# 3. Decisiones arquitectónicas principales

La arquitectura establece inicialmente las siguientes decisiones:

| ID      | Decisión                                                                                      |
| ------- | --------------------------------------------------------------------------------------------- |
| ARCH-01 | Flutter será utilizado como cliente multiplataforma.                                          |
| ARCH-02 | NestJS será el backend principal de la plataforma.                                            |
| ARCH-03 | Prisma será utilizado como ORM.                                                               |
| ARCH-04 | PostgreSQL será el sistema principal de persistencia.                                         |
| ARCH-05 | Prospector Service será desarrollado con Python + FastAPI.                                    |
| ARCH-06 | Prospector Core será independiente del dominio SaaS.                                          |
| ARCH-07 | Prospector podrá ser utilizado mediante CLI y API.                                            |
| ARCH-08 | La plataforma utilizará arquitectura multi-tenant.                                            |
| ARCH-09 | La estrategia inicial de tenancy será Shared Database + Shared Schema + Tenant ID.            |
| ARCH-10 | NestJS será implementado inicialmente como Modular Monolith.                                  |
| ARCH-11 | Las operaciones de prospección serán tratadas como Jobs.                                      |
| ARCH-12 | Los componentes podrán ser empaquetados mediante Docker.                                      |
| ARCH-13 | La arquitectura deberá permitir infraestructura local, cloud o híbrida.                       |
| ARCH-14 | Google Maps será la fuente inicial de prospección.                                            |
| ARCH-15 | La plataforma será responsable del gobierno y persistencia de los prospectos.                 |
| ARCH-16 | `Business` representará un prospecto producido por Prospector.                                |
| ARCH-17 | La plataforma dependerá del contrato de Prospector Service y no de su implementación interna. |

---

# 4. Estilo arquitectónico

La solución utilizará una combinación de diferentes estilos arquitectónicos.

## 4.1. Arquitectura distribuida

Los componentes principales estarán separados por fronteras técnicas explícitas.

```text
Flutter
   │
   ▼
NestJS
   │
   ├── PostgreSQL
   │
   └── Prospector Service
             │
             ▼
       Prospector Core
```

La separación física de los componentes no será obligatoria en todos los entornos.

La arquitectura define principalmente **fronteras de responsabilidad y comunicación**, no una cantidad obligatoria de servidores.

---

## 4.2. Modular Monolith

El backend principal será inicialmente un **Modular Monolith**.

```text
NestJS
│
├── Auth
├── Tenants
├── Users
├── Campaigns
├── Prospects
├── Prospecting
├── Analytics
├── Exports
└── Integrations
```

Los módulos compartirán el mismo proceso de ejecución y despliegue, pero mantendrán responsabilidades y límites lógicos independientes.

Esto permitirá evolucionar posteriormente determinados componentes sin introducir desde el inicio la complejidad operacional de una arquitectura completa de microservicios.

---

## 4.3. Arquitectura políglota

La solución utilizará diferentes tecnologías de acuerdo con la naturaleza de cada problema.

```text
Flutter
   ↓
Presentación

NestJS
   ↓
Dominio y aplicación

Prisma
   ↓
Persistencia

PostgreSQL
   ↓
Datos

FastAPI
   ↓
Servicio de prospección

Python
   ↓
Motor de prospección

Playwright
   ↓
Automatización web
```

---

# 5. Vista general de componentes

```text
                              ┌───────────────────────┐
                              │        Usuario        │
                              └───────────┬───────────┘
                                          │
                                          ▼
                              ┌───────────────────────┐
                              │    Flutter Client     │
                              │                       │
                              │ Web / Desktop / Mobile│
                              └───────────┬───────────┘
                                          │
                                      HTTPS/API
                                          │
                                          ▼
┌────────────────────────────────────────────────────────────────────┐
│                        PLATFORM API                                │
│                           NestJS                                   │
│                                                                    │
│ ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐ ┌───────────────┐ │
│ │  Auth  │ │ Tenants│ │ Users  │ │ Campaigns│ │   Prospects   │ │
│ └────────┘ └────────┘ └────────┘ └──────────┘ └───────────────┘ │
│                                                                    │
│ ┌──────────────┐ ┌───────────┐ ┌─────────┐ ┌───────────────────┐│
│ │ Prospecting  │ │ Analytics │ │ Exports │ │ External Integr.  ││
│ └───────┬──────┘ └───────────┘ └─────────┘ └───────────────────┘│
└─────────┼───────────────────────────────────────────────┬─────────┘
          │                                               │
          │ Prisma                                        │ HTTP
          ▼                                               ▼
┌───────────────────────┐                    ┌────────────────────────┐
│      PostgreSQL       │                    │   Prospector Service   │
│                       │                    │        FastAPI         │
│ Tenant                │                    │                        │
│ User                  │                    │ Prospecting API        │
│ Campaign              │                    │ Job execution          │
│ Prospect              │                    │ Result transformation  │
│ CampaignProspect      │                    │                        │
│ ProspectingJob        │                    └───────────┬────────────┘
└───────────────────────┘                                │
                                                         ▼
                                            ┌────────────────────────┐
                                            │    Prospector Core     │
                                            │         Python         │
                                            │                        │
                                            │ Navigation             │
                                            │ Scraping               │
                                            │ Normalization          │
                                            │ Validation             │
                                            │ Deduplication           │
                                            │ Enrichment             │
                                            └───────────┬────────────┘
                                                        │
                                                        ▼
                                               Public Data Sources
                                                  Google Maps
```

---

# 6. Componentes del sistema

## 6.1. Flutter Client

Flutter será responsable de la presentación e interacción con el usuario.

### Responsabilidades

* interfaz gráfica;
* navegación;
* formularios;
* autenticación desde el punto de vista de presentación;
* gestión de estado de interfaz;
* visualización de campañas;
* visualización de prospectos;
* visualización del estado de Jobs;
* dashboards;
* filtros;
* exportaciones iniciadas por el usuario;
* consumo de la API de plataforma.

### No responsabilidades

Flutter no deberá:

* conectarse directamente a PostgreSQL;
* ejecutar SQL;
* ejecutar scraping;
* comunicarse directamente con Prospector Core;
* contener reglas de negocio críticas;
* determinar el tenant confiando únicamente en información proporcionada por el cliente;
* implementar mecanismos de seguridad que deban ser aplicados por el backend.

---

# 7. Platform API

El backend de la plataforma será desarrollado mediante **Node.js + NestJS**.

Su responsabilidad será gobernar el dominio de la aplicación.

```text
Platform API
│
├── Authentication
├── Authorization
├── Tenant Management
├── User Management
├── Campaign Management
├── Prospect Management
├── Prospecting Jobs
├── Analytics
├── Exports
└── External Service Integration
```

---

# 8. Arquitectura interna de NestJS

El backend utilizará una estructura modular.

```text
src/
│
├── auth/
│
├── tenants/
│
├── users/
│
├── campaigns/
│
├── prospects/
│
├── prospecting/
│
├── analytics/
│
├── exports/
│
├── integrations/
│
├── common/
│
└── main
```

La estructura exacta podrá evolucionar durante la implementación.

Cada módulo deberá mantener una responsabilidad claramente delimitada.

---

# 9. Módulo Auth

Responsable de las operaciones relacionadas con autenticación y contexto de identidad.

Responsabilidades:

* inicio de sesión;
* validación de credenciales;
* emisión o validación de credenciales de sesión;
* recuperación de identidad;
* integración con mecanismos de identidad externos si posteriormente fueran utilizados.

El mecanismo concreto de autenticación será definido durante el diseño de seguridad.

---

# 10. Módulo Tenants

Responsable de administrar las organizaciones que utilizan la plataforma.

```text
Tenant
│
├── Users
├── Campaigns
├── Prospects
└── Prospecting Jobs
```

Responsabilidades:

* creación de organizaciones;
* consulta de organización;
* administración de estado;
* resolución del tenant;
* aplicación de reglas relacionadas con la organización.

---

# 11. Módulo Users

Responsable de los usuarios pertenecientes a una organización.

Responsabilidades:

* creación;
* consulta;
* modificación;
* desactivación;
* asignación de roles;
* validación de pertenencia al tenant.

---

# 12. Módulo Campaigns

Responsable del dominio de campañas.

```text
Campaign
│
├── Search Criteria
├── Prospecting Jobs
├── Prospects
└── Metrics
```

Responsabilidades:

* crear campañas;
* modificar campañas;
* consultar campañas;
* cambiar estado;
* asociar Jobs;
* consultar prospectos asociados;
* proporcionar información agregada.

---

# 13. Módulo Prospects

Responsable del gobierno de prospectos dentro de la plataforma.

Un prospecto almacenado será la representación de un `Business` incorporado al dominio de la plataforma.

```text
Business
   │
   │ ingreso a plataforma
   ▼
Prospect
```

Responsabilidades:

* validación;
* normalización de dominio;
* resolución de identidad;
* deduplicación de dominio;
* persistencia;
* consulta;
* búsqueda;
* filtrado;
* asociación con campañas;
* exportación.

---

# 14. Módulo Prospecting

Será responsable de coordinar las operaciones de prospección.

No implementará scraping.

Su responsabilidad será coordinar:

```text
Platform
    ↓
Prospecting Job
    ↓
Prospector Service
    ↓
Results
    ↓
Platform
```

Responsabilidades:

* crear Jobs;
* validar solicitudes;
* comunicarse con Prospector Service;
* consultar estados;
* procesar resultados;
* persistir resultados válidos;
* actualizar estados;
* manejar errores de integración.

---

# 15. Módulo Analytics

Responsable de proporcionar información agregada.

Ejemplos:

* cantidad de prospectos;
* prospectos por campaña;
* resultados por operación;
* cantidad de Jobs completados;
* cantidad de Jobs fallidos;
* métricas básicas de campañas.

El módulo no deberá modificar directamente la información de dominio fuera de las operaciones explícitamente definidas.

---

# 16. Módulo Exports

Responsable de generar exportaciones de información administrada por la plataforma.

Las exportaciones deberán respetar:

* tenant;
* autorización;
* filtros;
* permisos;
* estructura de datos permitida.

Los formatos concretos serán definidos posteriormente.

---

# 17. Módulo Integrations

Centralizará integraciones externas de la plataforma.

La integración con Prospector Service deberá estar aislada de los módulos de dominio mediante una interfaz interna.

Conceptualmente:

```text
Prospecting Module
        │
        ▼
Prospector Client Interface
        │
        ▼
HTTP Adapter
        │
        ▼
Prospector Service
```

El dominio no deberá depender directamente de detalles de HTTP.

---

# 18. Arquitectura por capas del backend

Cada módulo podrá seguir una separación interna por responsabilidades.

```text
┌───────────────────────────────┐
│          Controllers          │
│       HTTP / API Layer        │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│          Application          │
│     Use Cases / Services      │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│            Domain             │
│ Rules / Entities / Policies   │
└───────────────┬───────────────┘
                │
                ▼
┌───────────────────────────────┐
│       Infrastructure          │
│ Prisma / HTTP / External      │
└───────────────────────────────┘
```

La implementación exacta podrá utilizar las convenciones propias de NestJS, siempre que se preserve la separación de responsabilidades.

---

# 19. Persistencia

PostgreSQL será el sistema principal de persistencia.

Prisma será utilizado como ORM desde NestJS.

```text
NestJS
   │
   ▼
Prisma
   │
   ▼
PostgreSQL
```

Flutter y Prospector Service no deberán acceder directamente a la base de datos de la plataforma.

---

# 20. Modelo de datos conceptual

```text
Tenant
│
├── User
│
├── Campaign
│      │
│      ├── ProspectingJob
│      │
│      └── CampaignProspect
│                         │
│                         ▼
│                      Prospect
│
└── ProspectingJob
```

Las relaciones definitivas serán determinadas durante el diseño ER.

---

# 21. Entidades principales

## Tenant

```text
Tenant
├── id
├── name
├── slug
├── status
├── created_at
└── updated_at
```

---

## User

```text
User
├── id
├── tenant_id
├── name
├── email
├── password_hash / identity_reference
├── role
├── status
├── created_at
└── updated_at
```

---

## Campaign

```text
Campaign
├── id
├── tenant_id
├── name
├── description
├── status
├── created_at
└── updated_at
```

---

## Prospect

```text
Prospect
├── id
├── tenant_id
├── name
├── category
├── address
├── phone
├── email
├── website
├── source
├── source_identifier
├── language
├── metadata
├── created_at
└── updated_at
```

---

## CampaignProspect

```text
CampaignProspect
├── campaign_id
├── prospect_id
├── status
└── added_at
```

---

## ProspectingJob

```text
ProspectingJob
├── id
├── tenant_id
├── campaign_id
├── status
├── query
├── requested_limit
├── requested_by
├── started_at
├── completed_at
├── error
└── created_at
```

---

# 22. Estrategia Multi-Tenant

La estrategia inicial será:

```text
Shared Database
       +
Shared Schema
       +
Tenant ID
```

Todos los tenants utilizarán la misma base de datos y esquema lógico.

La separación se realizará mediante las relaciones de las entidades con `tenant_id`.

```text
PostgreSQL
│
├── Tenant A
│    ├── Users
│    ├── Campaigns
│    └── Prospects
│
├── Tenant B
│    ├── Users
│    ├── Campaigns
│    └── Prospects
│
└── Tenant C
     ├── Users
     ├── Campaigns
     └── Prospects
```

---

# 23. Resolución del Tenant

El tenant no deberá ser determinado únicamente mediante un identificador proporcionado por el cliente.

El flujo conceptual será:

```text
Request
   ↓
Authentication
   ↓
Authenticated User
   ↓
Tenant Membership
   ↓
Tenant Context
   ↓
Authorization
   ↓
Business Logic
   ↓
Data Access
```

El contexto del tenant deberá estar disponible para las operaciones que accedan a recursos multi-tenant.

---

# 24. Aislamiento de datos

El aislamiento deberá aplicarse en todas las capas relevantes.

```text
HTTP Request
     ↓
Identity
     ↓
Tenant Context
     ↓
Authorization
     ↓
Application Service
     ↓
Repository / Prisma
     ↓
tenant_id
     ↓
PostgreSQL
```

Una consulta multi-tenant no deberá depender únicamente de que el desarrollador recuerde agregar manualmente un filtro en cada lugar.

Durante el diseño técnico deberán evaluarse mecanismos adicionales para reducir el riesgo de acceso accidental entre tenants.

---

# 25. Prospector Service

Prospector Service será una aplicación independiente desarrollada con:

```text
Python
   +
FastAPI
```

Su propósito será proporcionar una frontera de servicio entre la plataforma y el motor de prospección.

```text
NestJS
   │
   │ HTTP
   ▼
Prospector Service
   │
   ▼
Prospector Core
```

---

# 26. Responsabilidades de Prospector Service

Prospector Service será responsable de:

* recibir solicitudes;
* validar parámetros propios de prospección;
* iniciar ejecuciones;
* administrar el estado de Jobs de prospección;
* ejecutar Prospector Core;
* transformar resultados;
* exponer estados;
* comunicar errores;
* proporcionar resultados mediante un contrato definido.

No será responsable de:

* usuarios;
* tenants;
* campañas;
* permisos comerciales;
* CRM;
* dashboards;
* persistencia comercial de prospectos.

---

# 27. Prospector Core

Prospector Core será el núcleo reutilizable de Prospector.

Su origen será el motor desarrollado previamente dentro de Prospector CLI.

La arquitectura objetivo será:

```text
                Prospector Core
                 /           \
                /             \
               ▼               ▼
       Prospector CLI    Prospector Service
                               │
                               ▼
                         Plataforma SaaS
```

---

# 28. Responsabilidades de Prospector Core

El Core será responsable de:

```text
Configuration
      ↓
Query
      ↓
Navigation
      ↓
Scraping
      ↓
Normalization
      ↓
Validation
      ↓
Deduplication
      ↓
Enrichment
      ↓
Business[]
```

El Core no deberá conocer:

* tenants;
* usuarios;
* campañas;
* permisos;
* dashboards;
* relaciones comerciales;
* persistencia de la plataforma.

---

# 29. Relación entre Business y Prospect

La frontera entre ambos conceptos será:

```text
Prospector
     │
     ▼
Business
     │
     │ transformación / validación
     ▼
Platform
     │
     ▼
Prospect
```

Por lo tanto:

```text
Business
=
resultado producido por Prospector
```

mientras que:

```text
Prospect
=
Business incorporado al dominio de la plataforma
```

Esta distinción deberá mantenerse durante la implementación.

---

# 30. Contrato entre NestJS y Prospector Service

La comunicación entre ambos componentes será mediante HTTP.

```text
NestJS
   │
   │ Prospecting Request
   ▼
Prospector Service
   │
   │ Prospecting Result
   ▼
NestJS
```

NestJS dependerá del **contrato del servicio**, no de la implementación de Prospector.

Por lo tanto, NestJS no deberá conocer:

* Playwright;
* selectores;
* DOM;
* navegación interna;
* mecanismos de scraping;
* estructura interna de módulos Python;
* sincronización interna;
* implementación de fuentes.

---

# 31. Interfaz lógica de Prospector

Conceptualmente, Prospector Service deberá proporcionar capacidades similares a:

```text
Create Prospecting Job
        ↓
Get Job Status
        ↓
Get Job Results
```

La definición exacta de:

* endpoints;
* métodos HTTP;
* payloads;
* códigos de respuesta;
* autenticación;
* errores;
* versionamiento;
* paginación;

será establecida en el contrato API definitivo.

---

# 32. Arquitectura de Jobs

Las operaciones de prospección no deberán tratarse como solicitudes HTTP convencionales de larga duración.

El modelo será:

```text
Request
   ↓
Create Job
   ↓
Queued
   ↓
Running
   ↓
Completed
   │
   └── Failed
```

---

# 33. Ciclo de vida de ProspectingJob

Estados iniciales:

```text
QUEUED
RUNNING
COMPLETED
FAILED
```

Flujo esperado:

```text
                 ┌───────────┐
                 │  QUEUED   │
                 └─────┬─────┘
                       │
                       ▼
                 ┌───────────┐
                 │  RUNNING  │
                 └─────┬─────┘
                       │
              ┌────────┴────────┐
              ▼                 ▼
        ┌───────────┐      ┌───────────┐
        │ COMPLETED │      │   FAILED  │
        └───────────┘      └───────────┘
```

Las transiciones definitivas y reglas de reintento se definirán durante el diseño técnico.

---

# 34. Flujo completo de prospección

```text
Usuario
   │
   ▼
Flutter
   │
   │ POST solicitud
   ▼
NestJS
   │
   ├── Authentication
   ├── Tenant validation
   ├── Campaign validation
   └── Create ProspectingJob
   │
   ▼
Prospector Service
   │
   ▼
Prospector Core
   │
   ├── Navigation
   ├── Scraping
   ├── Normalization
   ├── Validation
   └── Deduplication
   │
   ▼
Business[]
   │
   ▼
Prospector Service
   │
   ▼
NestJS
   │
   ├── Validate
   ├── Normalize
   ├── Resolve identity
   ├── Domain deduplication
   └── Persist
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

# 35. Responsabilidad de la deduplicación

Existirán dos niveles conceptualmente diferentes.

## Nivel 1 — Prospector

```text
Scraping
   ↓
Normalization
   ↓
Deduplication
   ↓
Business[]
```

Su objetivo será evitar duplicados dentro de los resultados producidos por el motor.

## Nivel 2 — Plataforma

```text
Business
   ↓
Identity Resolution
   ↓
Existing Prospect?
   ↓
Create / Update / Associate
```

Su objetivo será determinar si el prospecto ya existe dentro del dominio de una organización.

Por lo tanto:

```text
Motor Deduplication
≠
Domain Deduplication
```

---

# 36. Gobierno de datos

Prospector:

```text
Obtener
Procesar
Normalizar
Validar
Entregar
```

Plataforma:

```text
Recibir
Validar
Persistir
Relacionar
Organizar
Consultar
Analizar
Exportar
```

Principio:

> **Prospector produce información; la plataforma gobierna los datos que utiliza el negocio.**

---

# 37. Seguridad

La seguridad será aplicada principalmente en la frontera de la plataforma.

```text
Client
  ↓
HTTPS
  ↓
Authentication
  ↓
Authorization
  ↓
Tenant Context
  ↓
Business Rules
  ↓
Persistence
```

La plataforma será responsable de proteger:

* autenticación;
* autorización;
* aislamiento de tenants;
* acceso a campañas;
* acceso a prospectos;
* operaciones de prospección;
* información exportada.

Los mecanismos concretos de autenticación y autorización deberán definirse posteriormente.

---

# 38. Seguridad de comunicación entre servicios

La comunicación:

```text
NestJS
   ↓
Prospector Service
```

deberá protegerse contra acceso no autorizado.

La estrategia concreta podrá incluir mecanismos como:

* autenticación entre servicios;
* credenciales almacenadas como secretos;
* redes privadas;
* HTTPS cuando la topología lo requiera;
* restricciones de origen;
* validación de solicitudes.

La selección definitiva dependerá del entorno de despliegue.

---

# 39. Manejo de errores

Los errores deberán clasificarse de acuerdo con su origen.

```text
Client Error
     ↓
Platform Error
     ↓
Integration Error
     ↓
Prospector Error
     ↓
Source Error
```

Ejemplo:

```text
Flutter
   ↓
NestJS
   ↓
Prospector Service
   ↓
Prospector Core
   ↓
Google Maps
```

Cada frontera deberá traducir los errores internos a un contrato apropiado para el componente consumidor.

NestJS no deberá exponer directamente excepciones internas de Python, Playwright o del scraper.

---

# 40. Observabilidad

La plataforma deberá registrar información suficiente para reconstruir operaciones relevantes.

Como mínimo, deberán poder relacionarse:

```text
Request
   ↓
User
   ↓
Tenant
   ↓
Campaign
   ↓
ProspectingJob
   ↓
Prospector Execution
   ↓
Prospects
```

La implementación podrá utilizar identificadores de correlación para seguir una operación entre servicios.

---

# 41. Trazabilidad

Una operación de prospección deberá poder rastrearse desde su origen hasta sus resultados.

```text
User
 │
 ▼
Tenant
 │
 ▼
Campaign
 │
 ▼
ProspectingJob
 │
 ▼
Prospector Service
 │
 ▼
Prospector Core
 │
 ▼
Business[]
 │
 ▼
Prospect
 │
 ▼
CampaignProspect
```

Esto permitirá investigar errores y conocer el origen de la información almacenada.

---

# 42. Arquitectura de despliegue lógica

La arquitectura lógica de despliegue será:

```text
                    INTERNET
                       │
                       ▼
              ┌────────────────┐
              │ Flutter Client │
              └───────┬────────┘
                      │ HTTPS
                      ▼
              ┌────────────────┐
              │ Platform API   │
              │    NestJS      │
              └───────┬────────┘
                      │
          ┌───────────┴────────────┐
          │                        │
          ▼                        ▼
 ┌─────────────────┐     ┌─────────────────────┐
 │   PostgreSQL    │     │ Prospector Service  │
 │                 │     │      FastAPI        │
 └─────────────────┘     └──────────┬──────────┘
                                    │
                                    ▼
                           ┌─────────────────┐
                           │ Prospector Core │
                           │     Python      │
                           └────────┬────────┘
                                    │
                                    ▼
                              Public Sources
```

---

# 43. Despliegue local

El entorno local deberá poder ejecutar todos los componentes.

```text
Local Environment
│
├── Flutter
├── NestJS
├── PostgreSQL
└── Prospector Service
       │
       └── Prospector Core
```

Docker podrá utilizarse para facilitar la reproducción del entorno.

---

# 44. Despliegue cloud

La arquitectura podrá desplegarse en infraestructura cloud.

```text
Cloud
│
├── Client
│
├── Platform API
│
├── PostgreSQL
│
└── Prospector Service
       │
       └── Prospector Core
```

La distribución física concreta dependerá del proveedor y de las restricciones de la implementación.

---

# 45. Despliegue híbrido

La arquitectura permitirá separar físicamente la plataforma del motor.

```text
                    CLOUD
                      │
          ┌───────────┴────────────┐
          │                        │
          ▼                        ▼
   Platform API              PostgreSQL
      NestJS
          │
          │ Secure Communication
          │
          ▼
              LOCAL / DEDICATED
                      │
                      ▼
             Prospector Service
                      │
                      ▼
               Prospector Core
```

Este modelo resulta especialmente útil cuando el motor requiere características de infraestructura diferentes a las del backend principal.

---

# 46. Docker

Los componentes principales deberán poder empaquetarse mediante Docker.

Conceptualmente:

```text
Docker
│
├── platform-api
│      └── NestJS
│
├── prospector-service
│      └── FastAPI
│
└── postgres
       └── PostgreSQL
```

La forma definitiva de ejecutar PostgreSQL deberá considerar las necesidades de persistencia y del entorno objetivo.

---

# 47. Configuración

La configuración dependiente del entorno no deberá estar codificada directamente en el código fuente.

Ejemplos:

```text
DATABASE_URL
PROSPECTOR_SERVICE_URL
AUTH_CONFIGURATION
SERVICE_CREDENTIALS
APP_ENVIRONMENT
PORT
LOG_LEVEL
```

Los nombres definitivos serán establecidos durante la implementación.

Los secretos deberán mantenerse fuera del repositorio.

---

# 48. Comunicación entre componentes

Las fronteras principales serán:

```text
Flutter
   │
   │ HTTPS
   ▼
NestJS
   │
   ├── Prisma
   │
   │
   └── HTTP
          ▼
    Prospector Service
          │
          ▼
    Prospector Core
```

No deberán existir conexiones directas entre:

```text
Flutter → PostgreSQL
Flutter → Prospector Core
Flutter → Prospector Service
NestJS → Prospector Core
Prospector Core → PostgreSQL de plataforma
```

salvo que una decisión arquitectónica posterior explícita modifique esta regla.

---

# 49. Principio de inversión de dependencia

La plataforma deberá depender de una abstracción de Prospector Service.

Conceptualmente:

```text
                    ┌────────────────────┐
                    │ Prospector Client  │
                    │    Interface      │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │ HTTP Implementation│
                    └─────────┬──────────┘
                              │
                              ▼
                    Prospector Service
```

Esto permitirá reemplazar la implementación de comunicación sin modificar el dominio principal.

---

# 50. Independencia tecnológica

NestJS no deberá depender de Python.

Prospector Service no deberá depender de TypeScript.

Prospector Core no deberá depender de NestJS.

La integración deberá ocurrir mediante contratos.

```text
TypeScript
    │
    │ HTTP Contract
    ▼
Python
```

---

# 51. Evolución de fuentes de información

Google Maps será la fuente inicial.

La arquitectura deberá permitir incorporar fuentes adicionales.

```text
                 ┌── Google Maps
                 │
Prospector Core ─┼── Future Source
                 │
                 └── Future Source
```

Las implementaciones específicas de cada fuente deberán permanecer aisladas dentro de Prospector.

La plataforma no deberá conocer los detalles de ninguna fuente.

---

# 52. Escalabilidad

La arquitectura permitirá escalar componentes de forma independiente cuando sea necesario.

Por ejemplo:

```text
                 ┌── Platform API instance 1
Client ──────────┼── Platform API instance 2
                 └── Platform API instance N
```

y:

```text
Prospector Service
        │
        ├── Worker 1
        ├── Worker 2
        └── Worker N
```

La estrategia concreta de escalamiento dependerá de las necesidades reales del MVP.

No se establece Kubernetes como requisito.

---

# 53. Disponibilidad

La ejecución de una prospección no deberá bloquear la disponibilidad general de la plataforma.

La separación mediante Jobs permitirá:

```text
User
 ↓
Create Job
 ↓
Response
 ↓
Platform remains available
 ↓
Job executes independently
```

Por lo tanto, una operación prolongada no deberá mantener abierta indefinidamente la conexión HTTP inicial del usuario.

---

# 54. Concurrencia

La arquitectura deberá contemplar la posibilidad de múltiples operaciones simultáneas.

```text
Tenant A
 ├── Job 1
 └── Job 2

Tenant B
 └── Job 3

Tenant C
 ├── Job 4
 ├── Job 5
 └── Job 6
```

La política concreta de:

* concurrencia;
* límites;
* prioridades;
* cuotas;
* reintentos;

será definida posteriormente.

---

# 55. Integridad de datos

PostgreSQL será responsable de proporcionar:

* integridad referencial;
* restricciones;
* relaciones;
* índices;
* unicidad;
* consistencia transaccional.

Las reglas de negocio permanecerán principalmente en NestJS.

```text
NestJS
   ↓
Business Rules

PostgreSQL
   ↓
Data Integrity
```

---

# 56. Transacciones

Las operaciones que modifiquen múltiples entidades relacionadas deberán utilizar transacciones cuando la consistencia del dominio lo requiera.

Por ejemplo:

```text
Business[]
   ↓
Create / Update Prospect
   ↓
Create CampaignProspect
   ↓
Update ProspectingJob
```

Estas operaciones deberán diseñarse para evitar estados parciales.

---

# 57. API de la plataforma

La API de NestJS será la frontera pública de la plataforma.

Conceptualmente se organizará alrededor de recursos:

```text
/auth
/tenants
/users
/campaigns
/prospects
/prospecting-jobs
/analytics
/exports
```

Los endpoints concretos serán definidos posteriormente mediante OpenAPI.

---

# 58. API de Prospector Service

La API de Prospector Service será una API interna orientada a la plataforma.

Conceptualmente:

```text
/prospecting/jobs
/prospecting/jobs/{id}
/prospecting/jobs/{id}/results
```

Estos nombres representan únicamente una estructura conceptual.

El contrato definitivo deberá definirse independientemente de la estructura interna de Prospector Core.

---

# 59. Versionamiento de contratos

Los contratos de API deberán poder evolucionar sin romper inmediatamente a los consumidores.

La estrategia de versionamiento será definida durante el diseño de API.

La compatibilidad deberá considerarse especialmente en:

```text
Flutter ↔ NestJS
NestJS ↔ Prospector Service
```

---

# 60. Testing

La estrategia de pruebas deberá cubrir diferentes niveles.

```text
                 Testing
                    │
       ┌────────────┼────────────┐
       ▼            ▼            ▼
     Unit       Integration    E2E
       │            │            │
       ▼            ▼            ▼
 Domain        API / DB      Complete Flow
```

También deberán considerarse pruebas específicas para:

* multi-tenancy;
* autorización;
* Jobs;
* integración con Prospector;
* persistencia;
* deduplicación;
* errores;
* contratos.

---

# 61. Testing de aislamiento multi-tenant

Deberán existir pruebas explícitas para garantizar que:

```text
Tenant A
   ✕
Tenant B
```

no pueda acceder accidentalmente a información del otro.

Ejemplo conceptual:

```text
Authenticated User A
        ↓
Tenant A
        ↓
Request Prospect B
        ↓
Access Denied
```

Este comportamiento deberá considerarse requisito de seguridad y no únicamente una prueba funcional.

---

# 62. Testing de integración

La integración deberá comprobar:

```text
NestJS
   ↓
Prospector Service
   ↓
Prospector Core
   ↓
Business[]
   ↓
NestJS
   ↓
PostgreSQL
```

El objetivo será comprobar que los contratos funcionan independientemente de los detalles internos de cada componente.

---

# 63. CI/CD

La arquitectura deberá permitir automatizar posteriormente:

```text
Git
 ↓
Validation
 ↓
Tests
 ↓
Build
 ↓
Container
 ↓
Deploy
```

El pipeline concreto será definido durante la etapa de infraestructura.

---

# 64. Gestión de secretos

Los secretos no deberán almacenarse en el repositorio.

Ejemplos:

```text
Database Credentials
Service Credentials
Authentication Secrets
API Keys
External Source Credentials
```

La solución concreta podrá variar entre entorno local y cloud.

---

# 65. Principios de diseño

La implementación deberá respetar los siguientes principios:

1. Separación de responsabilidades.
2. Alta cohesión.
3. Bajo acoplamiento.
4. Contratos explícitos.
5. Independencia tecnológica.
6. Aislamiento multi-tenant.
7. Gobierno centralizado de datos.
8. Seguridad por diseño.
9. Observabilidad.
10. Portabilidad.
11. Evolución incremental.
12. Simplicidad operacional.
13. No introducir infraestructura sin necesidad real.

---

# 66. Restricciones arquitectónicas

La implementación deberá respetar las siguientes restricciones:

```text
Flutter
  ✕ PostgreSQL directo

Flutter
  ✕ Prospector Core directo

NestJS
  ✕ Scraping

NestJS
  ✕ Playwright

NestJS
  ✕ DOM de Google Maps

Prospector Core
  ✕ Tenant management

Prospector Core
  ✕ Campaign management

Prospector Core
  ✕ Business persistence

Prospector Service
  ✕ CRM

Prospector Service
  ✕ Platform database
```

---

# 67. Frontera definitiva de responsabilidades

```text
┌─────────────────────────────────────────────┐
│                  FLUTTER                    │
│                                             │
│ Presentación                                │
│ Interacción                                 │
│ Navegación                                  │
│ Visualización                               │
└──────────────────────┬──────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────┐
│                  NESTJS                     │
│                                             │
│ API                                         │
│ Auth                                        │
│ Authorization                               │
│ Tenants                                     │
│ Users                                       │
│ Campaigns                                   │
│ Prospects                                   │
│ Jobs                                        │
│ Analytics                                   │
│ Exports                                     │
│ Business Rules                              │
│ Data Governance                             │
└──────────────┬──────────────────┬───────────┘
               │                  │
               ▼                  ▼
       ┌───────────────┐   ┌───────────────────┐
       │  PostgreSQL   │   │ Prospector Service│
       │               │   │     FastAPI       │
       │ Persistence   │   │                   │
       │ Integrity     │   │ Prospecting API   │
       └───────────────┘   └─────────┬─────────┘
                                     │
                                     ▼
                           ┌───────────────────┐
                           │  Prospector Core  │
                           │      Python       │
                           │                   │
                           │ Navigation        │
                           │ Scraping          │
                           │ Normalization     │
                           │ Validation        │
                           │ Deduplication     │
                           │ Enrichment        │
                           └─────────┬─────────┘
                                     │
                                     ▼
                              Public Sources
```

---

# 68. Flujo arquitectónico completo

La operación completa del sistema podrá representarse como:

```text
                         USER
                           │
                           ▼
                    Flutter Client
                           │
                         HTTPS
                           │
                           ▼
                    Platform API
                        NestJS
                           │
               ┌───────────┴────────────┐
               │                        │
               ▼                        ▼
        Authentication             Tenant Context
               │                        │
               └───────────┬────────────┘
                           │
                           ▼
                    Campaign Validation
                           │
                           ▼
                  Create ProspectingJob
                           │
                           ▼
                  PostgreSQL Persistence
                           │
                           ▼
                 Prospector Service
                       FastAPI
                           │
                           ▼
                  Prospector Core
                       Python
                           │
                           ▼
                    Public Sources
                           │
                           ▼
                       Business[]
                           │
                           ▼
                  Prospector Service
                           │
                           ▼
                       NestJS
                           │
             ┌─────────────┼─────────────┐
             │             │             │
             ▼             ▼             ▼
          Validate     Normalize     Deduplicate
             │             │             │
             └─────────────┼─────────────┘
                           │
                           ▼
                     PostgreSQL
                           │
                 ┌─────────┴─────────┐
                 ▼                   ▼
             Prospect         CampaignProspect
                 │                   │
                 └─────────┬─────────┘
                           ▼
                       Flutter
                           │
                           ▼
                         User
```

---

# 69. Modelo arquitectónico de referencia

La arquitectura completa puede resumirse en cinco niveles:

```text
┌────────────────────────────────────────────┐
│              PRESENTACIÓN                  │
│                                            │
│              Dart + Flutter                │
└──────────────────────┬─────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────┐
│              PLATAFORMA                   │
│                                            │
│             Node.js + NestJS              │
│                                            │
│ Auth / Tenants / Users / Campaigns         │
│ Prospects / Jobs / Analytics / Exports     │
└───────────────┬──────────────────┬─────────┘
                │                  │
                ▼                  ▼
┌────────────────────────┐ ┌────────────────────────┐
│      PERSISTENCIA      │ │       INTEGRACIÓN      │
│                        │ │                        │
│      PostgreSQL        │ │   Prospector Service   │
│                        │ │        FastAPI         │
└────────────────────────┘ └───────────┬────────────┘
                                       │
                                       ▼
                            ┌────────────────────────┐
                            │      PROSPECTOR        │
                            │                        │
                            │    Prospector Core     │
                            │         Python         │
                            └───────────┬────────────┘
                                        │
                                        ▼
                                 Public Sources
```

---

# 70. Arquitectura y evolución

La arquitectura está diseñada para evolucionar de forma incremental.

La evolución esperada será:

```text
Prospector CLI v0.7.0
          │
          ▼
   Prospector Core
          │
      ┌───┴────┐
      ▼        ▼
     CLI    Service
               │
               ▼
        Plataforma SaaS
```

Mientras que la plataforma evolucionará:

```text
MVP Modular Monolith
          │
          ▼
Mayor volumen / complejidad
          │
          ▼
Identificación de cuellos de botella
          │
          ▼
Separación selectiva de componentes
```

La extracción de nuevos servicios será una consecuencia de necesidades reales y no un requisito inicial.

---

# 71. Decisiones todavía abiertas

Las siguientes decisiones no se consideran cerradas por este modelo:

* mecanismo definitivo de autenticación;
* mecanismo definitivo de autorización;
* estrategia exacta de tenant resolution;
* uso de Row-Level Security en PostgreSQL;
* contrato definitivo de Prospector Service;
* contrato definitivo de Platform API;
* estrategia exacta de Jobs;
* mecanismo de cola;
* estrategia de workers;
* política de reintentos;
* límites de concurrencia;
* estrategia definitiva de deduplicación;
* identidad definitiva de prospectos;
* formato de exportaciones;
* proveedor cloud;
* topología definitiva de infraestructura;
* almacenamiento de secretos;
* CI/CD;
* sistema definitivo de observabilidad;
* estrategia de backups;
* política de versionamiento de APIs.

Estas decisiones deberán derivarse del diseño detallado y validarse antes de considerarse parte definitiva de la arquitectura.

---

# 72. Secuencia de diseño e implementación

La implementación deberá seguir aproximadamente la siguiente secuencia:

```text
Requerimientos
      ↓
Casos de uso
      ↓
Modelo de dominio
      ↓
Modelo ER
      ↓
Prisma Schema
      ↓
Diseño de API
      ↓
Contrato Prospector Service
      ↓
Diseño de Jobs
      ↓
Autenticación
      ↓
Autorización
      ↓
Tenant Resolution
      ↓
Implementación NestJS
      ↓
Implementación Prospector Core
      ↓
Implementación Prospector Service
      ↓
Implementación Flutter
      ↓
Integración
      ↓
Testing
      ↓
Docker
      ↓
Infraestructura
      ↓
CI/CD
      ↓
Observabilidad
      ↓
Despliegue
```

---

# 73. Criterio rector de la arquitectura

La arquitectura deberá seguir el siguiente principio:

> **Cada componente debe resolver un problema concreto y exponer únicamente las capacidades que otros componentes necesitan consumir.**

En consecuencia:

```text
Flutter
    → presenta e interactúa

NestJS
    → gobierna el dominio

PostgreSQL
    → persiste y garantiza integridad

Prospector Service
    → expone la capacidad de prospección

Prospector Core
    → obtiene y procesa prospectos

Public Sources
    → proporcionan información
```

---

# 74. Conclusión arquitectónica

El sistema se implementará como una plataforma SaaS multi-tenant basada inicialmente en un **Modular Monolith para el backend principal**, complementado por un **servicio independiente de prospección**.

La plataforma estará compuesta por:

```text
Flutter
   +
NestJS
   +
Prisma
   +
PostgreSQL
```

mientras que la capacidad de prospección estará compuesta por:

```text
Prospector Service
        +
FastAPI
        +
Prospector Core
        +
Python
        +
Playwright
```

La frontera entre ambos dominios será un contrato HTTP explícito.

La plataforma será propietaria del dominio de negocio:

```text
Tenant
User
Campaign
Prospect
CampaignProspect
ProspectingJob
```

mientras que Prospector será responsable exclusivamente de:

```text
Navigation
Scraping
Normalization
Validation
Deduplication
Enrichment
```

El resultado del motor será representado mediante:

```text
Business[]
```

y posteriormente incorporado al dominio de la plataforma como:

```text
Prospect
```

La estrategia inicial de tenancy será:

```text
Shared Database
+
Shared Schema
+
Tenant ID
```

y las operaciones de prospección serán modeladas como Jobs para evitar que procesos prolongados bloqueen la disponibilidad de la plataforma.

La arquitectura no establece microservicios como requisito. La separación de Prospector se justifica por su naturaleza técnica y operacional, mientras que el dominio principal permanecerá inicialmente dentro de un Modular Monolith.

El sistema deberá poder ejecutarse en infraestructura local, cloud o híbrida, utilizando Docker como mecanismo de portabilidad y manteniendo las dependencias entre componentes mediante contratos explícitos.

El objetivo arquitectónico principal será mantener:

```text
Separación de responsabilidades
        +
Bajo acoplamiento
        +
Gobierno de datos
        +
Aislamiento multi-tenant
        +
Integración mediante contratos
        +
Portabilidad
        +
Observabilidad
        +
Evolución incremental
```

por encima de la incorporación prematura de complejidad operacional.

---

# 75. Estado del modelo

Este documento representa el **modelo arquitectónico técnico de referencia v1.0**.

Define la arquitectura base sobre la cual deberán construirse los siguientes artefactos:

```text
Modelo Arquitectónico
        ↓
Casos de Uso
        ↓
Modelo de Dominio
        ↓
ERD
        ↓
Prisma Schema
        ↓
Platform API
        ↓
Prospector Service API
        ↓
OpenAPI
        ↓
Diseño de Jobs
        ↓
Seguridad
        ↓
Docker
        ↓
Infraestructura
        ↓
CI/CD
        ↓
Testing
        ↓
Observabilidad
        ↓
Implementación
```

Las decisiones que no han sido cerradas en este documento deberán considerarse **Architecture Decisions Pending** y no deberán asumirse como definitivas hasta completar su diseño y validación.
