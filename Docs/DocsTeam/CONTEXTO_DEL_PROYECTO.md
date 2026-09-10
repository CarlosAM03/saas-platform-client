# Contexto del Proyecto — Sistema SaaS de Prospección y Gestión de Campañas

> Nota de vigencia: este documento es histórico o conceptual. No sustituye ADR-004, el contrato OpenAPI, FormularioDecisionesFase5.md ni ADR-005-FlutterFoundation.md. En caso de contradicción, prevalecen los documentos normativos vigentes.

Las decisiones vigentes de implementación del baseline del Platform Backend están formalizadas en `Docs/ADRs/ADR-004-CommonBaseline.md`, que constituye la fuente de verdad para la Fase 4.

## 1. Contexto académico

Este proyecto forma parte de la **Ingeniería en Sistemas Computacionales** y se desarrolla principalmente dentro de la materia de **Desarrollo de Software con Aplicación en la Nube**.

El proyecto también se relaciona con los conocimientos y fundamentos de **Sistemas Operativos, Conducta y Algoritmos**, así como con otras áreas de la formación en ingeniería de software.

El trabajo corresponde a un proyecto académico de semestre, con un periodo efectivo estimado de aproximadamente **tres a cuatro meses de desarrollo**, por lo que las decisiones técnicas deben considerar tanto la calidad del diseño como la viabilidad de implementación dentro del tiempo disponible.

El objetivo académico no es únicamente producir una aplicación funcional, sino aplicar principios de:

* arquitectura de software;
* desarrollo de servicios;
* APIs;
* separación de responsabilidades;
* sistemas distribuidos;
* computación en la nube;
* persistencia;
* seguridad;
* multi-tenancy;
* reutilización de componentes;
* integración entre tecnologías heterogéneas.

## 2. Contexto empresarial

El proyecto no surge únicamente como un ejercicio hipotético.

Parte de una necesidad y de una solución tecnológica que ya existe y ha sido utilizada en un contexto empresarial real. El sistema se está evolucionando y reorganizando con el objetivo de convertir capacidades existentes en una plataforma de software más estructurada y reutilizable.

El componente de prospección tiene como antecedente un sistema denominado **Prospector CLI**, cuyo motor de extracción ya cuenta con una implementación funcional.

La arquitectura actual del proyecto académico busca aprovechar ese trabajo existente en lugar de desarrollar nuevamente desde cero toda la lógica de extracción.

Por ello, una de las decisiones fundamentales del proyecto es:

> **Reutilizar la lógica funcional existente y reorganizarla progresivamente en componentes con responsabilidades claramente delimitadas.**

## 3. Objetivo general del sistema

El proyecto busca construir una plataforma SaaS para la gestión de campañas de marketing y prospección de clientes potenciales.

La plataforma permitirá que los usuarios administren información relacionada con sus campañas y soliciten procesos de prospección.

La prospección utiliza un motor especializado capaz de buscar información en Google Maps y enriquecer los resultados mediante la inspección de sitios web.

La arquitectura completa separa tres responsabilidades principales:

```text
SaaS Backend
    ↓
Administración y lógica de negocio

Prospector Service
    ↓
API y orquestación de la capacidad de prospección

Prospector Engine
    ↓
Extracción y enriquecimiento de prospectos
```

## 4. Arquitectura conceptual

La arquitectura general prevista es:

```text
                         ┌──────────────────────┐
                         │       Flutter        │
                         │   Cliente / UI       │
                         └──────────┬───────────┘
                                    │
                                    │ HTTP
                                    ▼
                    ┌──────────────────────────────┐
                    │       SaaS Backend           │
                    │          NestJS              │
                    │                              │
                    │  Lógica de negocio           │
                    │  Tenants                     │
                    │  Usuarios                    │
                    │  Roles                       │
                    │  Permisos                    │
                    │  Campañas                    │
                    │  Persistencia                │
                    │  Seguridad                   │
                    └──────────────┬───────────────┘
                                   │
                                   │ HTTP
                                   ▼
              ┌────────────────────────────────────────┐
              │          Prospector Service             │
              │              FastAPI                    │
              │                                        │
              │  API / DTOs / Validación                │
              │            │                           │
              │            ▼                           │
              │      Orquestación                     │
              │            │                           │
              │            ▼                           │
              │   ┌──────────────────────────────┐     │
              │   │      Prospector Engine       │     │
              │   │                              │     │
              │   │ Search                       │     │
              │   │ Google Maps                  │     │
              │   │ Extraction                   │     │
              │   │ Detail Enrichment            │     │
              │   │ Website Enrichment           │     │
              │   │ Normalization                 │     │
              │   │ Deduplication                │     │
              │   └──────────────────────────────┘     │
              └──────────────────┬─────────────────────┘
                                 │
                         Browser / Network
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
             Google Maps             External Websites
```

## 5. Responsabilidad de cada componente

### 5.1 Flutter

Flutter representa la interfaz utilizada por el usuario.

Su responsabilidad principal es:

* presentar información;
* permitir interacción con campañas;
* solicitar operaciones;
* mostrar resultados;
* consumir el SaaS Backend.

Flutter no ejecuta directamente el motor de prospección.

La aplicación cliente tampoco debe comunicarse directamente con Google Maps ni con Prospector Engine.

El flujo esperado es:

```text
Flutter
   ↓
SaaS Backend
   ↓
Prospector Service
   ↓
Prospector Engine
```

## 6. SaaS Backend

El SaaS Backend está construido con **NestJS + TypeScript**.

Representa la capa de aplicación y dominio de la plataforma.

Su responsabilidad principal es administrar las reglas propias del producto SaaS.

Entre sus responsabilidades se encuentran:

* tenants;
* usuarios;
* roles;
* permisos;
* autenticación;
* autorización;
* campañas;
* relación entre campañas y prospectos;
* persistencia;
* reglas de negocio;
* administración del contexto del tenant;
* integración con servicios externos.

El Backend no debe contener la lógica específica de extracción de Google Maps.

No es responsabilidad del Backend conocer detalles como:

```text
Google Maps selectors
Playwright
DOM extraction
Scrolling
place_id parsing
WebsiteCrawler
BeautifulSoup
EmailExtractor
```

Estos elementos pertenecen al Prospector Engine.

## 7. Prospector Service

Prospector Service está planteado como un servicio desarrollado con **Python + FastAPI**.

Su responsabilidad es proporcionar una frontera de servicio para ejecutar las capacidades de prospección.

El Service se encarga de:

* recibir requests HTTP;
* definir DTOs;
* validar datos de entrada;
* validar tipos;
* controlar parámetros de ejecución;
* orquestar el motor;
* transformar la entrada externa en estructuras utilizadas por el Engine;
* ejecutar el proceso de prospección;
* transformar los resultados en respuestas apropiadas para el consumidor.

La arquitectura interna conceptual es:

```text
HTTP Request
      ↓
FastAPI
      ↓
DTO
      ↓
Validation
      ↓
Application Service
      ↓
Prospector Engine
      ↓
Result
      ↓
Response DTO
      ↓
HTTP Response
```

Prospector Service no representa el dominio completo de la plataforma SaaS.

La lógica de tenants, usuarios, campañas, permisos y demás reglas de negocio pertenece al SaaS Backend.

## 8. Integración del Prospector Engine

El Prospector Engine tiene un repositorio propio para permitir su desarrollo, documentación y reutilización.

Sin embargo, **no se plantea inicialmente como un microservicio independiente**.

La arquitectura prevista para el proyecto consiste en integrar el Engine dentro de Prospector Service como un módulo interno.

Conceptualmente:

```text
prospector-service/
│
├── API
├── DTOs
├── Services
├── Validation
│
└── prospector_engine/
      ├── Search
      ├── Google Maps
      ├── Extraction
      ├── Detail Enrichment
      ├── Website Enrichment
      ├── Normalization
      └── Deduplication
```

Por lo tanto, el desacoplamiento del Engine es principalmente **lógico y de responsabilidades**, no necesariamente una separación física mediante comunicación de red.

La ejecución prevista es:

```text
Prospector Service
        │
        ▼
Prospector Engine
        │
        ▼
Google Maps / Websites
```

No:

```text
Prospector Service
        │
        │ HTTP
        ▼
Prospector Engine
```

salvo que una futura evolución arquitectónica determine que una separación distribuida sea necesaria.

## 9. Prospector Engine

Prospector Engine es la capacidad especializada de extracción y enriquecimiento.

Su origen es **Prospector CLI v0.7.0**.

La auditoría realizada sobre el CLI identificó que `main.py` no constituye el motor de extracción.

El motor real se encuentra distribuido principalmente entre:

```text
scraper.py
search.py
result_list.py
detail_panel.py
website_enrichment.py
navigation
selectors
website
models
```

El flujo funcional identificado es:

```text
SearchQuery
      ↓
Google Maps Navigation
      ↓
Result Loading / Scrolling
      ↓
Initial Business Extraction
      ↓
Detail Panel Enrichment
      ↓
Website Enrichment
      ↓
Normalization
      ↓
Deduplication
      ↓
Business[]
```

El objetivo de Prospector Engine 1.0.0 es estabilizar esta capacidad como componente reutilizable.

## 10. Evolución del Engine

La evolución prevista parte del comportamiento existente de Prospector CLI.

La intención es evitar una reescritura completa.

La evolución conceptual es:

```text
Prospector CLI v0.7.0
        │
        │ Auditoría
        ▼
Prospector Engine
        │
        ├── Estabilización
        │
        ├── Normalización
        │
        ├── Deduplicación
        │
        └── Cierre funcional
                │
                ▼
          Engine v1.0.0
```

La prioridad es:

1. conservar el comportamiento funcional existente;
2. eliminar dependencias del CLI;
3. estabilizar errores y logs;
4. mejorar el comportamiento determinista;
5. incorporar normalización;
6. incorporar deduplicación;
7. evitar sobreingeniería.

## 11. Alcance funcional de Prospector Engine 1.0.0

La versión 1.0.0 debe considerarse una versión funcional y reutilizable del motor, no una plataforma de prospección distribuida.

Su alcance incluye:

### Entrada

Una consulta estructurada de prospección:

```text
SearchQuery
```

con información como:

```text
source
keyword
location
limit
```

Actualmente la fuente soportada es:

```text
Google Maps
```

### Extracción

El Engine debe ser capaz de:

* navegar a Google Maps;
* ejecutar búsquedas;
* cargar resultados;
* recorrer el feed;
* extraer negocios;
* obtener información inicial;
* acceder al panel de detalle;
* obtener información adicional;
* detectar websites;
* inspeccionar websites;
* extraer metadata;
* extraer emails;
* generar resultados estructurados.

### Normalización

La versión 1 debe incluir una normalización básica de los datos obtenidos para reducir variaciones innecesarias entre resultados equivalentes.

La normalización debe mantenerse simple y determinista.

No se busca crear un sistema complejo de resolución de entidades.

### Deduplicación

La versión 1 debe contemplar deduplicación de resultados obtenidos durante una ejecución de prospección.

Esto es especialmente importante cuando una campaña contiene varias búsquedas.

Ejemplo:

```text
Búsqueda 1
Dentistas Tijuana
        ↓
Business A
Business B
Business C

Búsqueda 2
Clínicas dentales Tijuana
        ↓
Business B
Business C
Business D

Búsqueda 3
Odontólogos Tijuana
        ↓
Business A
Business D
Business E
```

El Engine debe poder producir:

```text
Business A
Business B
Business C
Business D
Business E
```

en lugar de conservar múltiples apariciones del mismo negocio.

La deduplicación del Engine se refiere a resultados obtenidos dentro del proceso de extracción.

No debe confundirse con la lógica del SaaS para determinar si un prospecto ya existe en la base de datos de un tenant.

## 12. Límites de responsabilidad del Engine

Prospector Engine no es responsable de:

* tenants;
* usuarios;
* roles;
* permisos;
* autenticación;
* autorización;
* campañas;
* reglas comerciales;
* planes de suscripción;
* persistencia del SaaS;
* base de datos de la plataforma;
* interfaz HTTP pública;
* Flutter;
* lógica de negocio del SaaS.

El Engine solamente produce información de prospección.

## 13. Diferencia entre deduplicación del Engine y deduplicación de plataforma

Esta diferencia es importante para mantener la arquitectura coherente.

El Engine puede recibir:

```text
Resultados de varias búsquedas
        ↓
Normalización
        ↓
Deduplicación
        ↓
Prospectos únicos de la ejecución
```

Pero el SaaS Backend puede posteriormente realizar otra operación:

```text
Prospectos obtenidos
        ↓
Tenant
        ↓
Campaña
        ↓
Base de datos existente
        ↓
Reglas de negocio
        ↓
¿Ya existe este prospecto?
```

La primera operación pertenece al Engine.

La segunda pertenece al dominio de la plataforma.

## 14. Flujo completo de una campaña

Un escenario completo puede representarse de la siguiente manera:

```text
Usuario
   ↓
Flutter
   ↓
SaaS Backend
   ↓
Tenant / User / Campaign
   ↓
Validación de reglas de negocio
   ↓
Prospector Service
   ↓
DTO
   ↓
Validation
   ↓
Application Service
   ↓
Prospector Engine
   ↓
────────────────────────────
Search 1
Search 2
Search 3
Search N
────────────────────────────
   ↓
Extraction
   ↓
Detail Enrichment
   ↓
Website Enrichment
   ↓
Normalization
   ↓
Deduplication
   ↓
Business[]
   ↓
Prospector Service
   ↓
Response
   ↓
SaaS Backend
   ↓
Persistencia / reglas de negocio
   ↓
Flutter
   ↓
Usuario
```

## 15. Flujo de datos

El flujo de información puede resumirse en cuatro transformaciones principales:

```text
Request externo
      ↓
DTO
      ↓
SearchQuery
      ↓
Extraction Pipeline
      ↓
Business[]
      ↓
Response DTO
      ↓
SaaS Backend
```

Dentro del Engine:

```text
Google Maps DOM
      ↓
Selectors / Locators
      ↓
Raw extracted data
      ↓
Business
      ↓
Detail enrichment
      ↓
Website enrichment
      ↓
Normalization
      ↓
Deduplication
      ↓
Business[]
```

## 16. Dominio y extracción

Una distinción central del proyecto es la separación entre **lógica de negocio** y **lógica de extracción**.

### Lógica de negocio

Pertenece principalmente al SaaS Backend:

```text
Tenant
User
Role
Permission
Campaign
Prospect
Persistence
Business Rules
```

### Lógica de extracción

Pertenece al Prospector Engine:

```text
Search
Google Maps
DOM
Scrolling
Business extraction
Detail panel
Website crawling
Website parsing
Email extraction
Normalization
Deduplication
```

### Orquestación del servicio

Pertenece al Prospector Service:

```text
HTTP
DTO
Validation
Request handling
Engine invocation
Response transformation
```

Esta separación constituye una de las decisiones arquitectónicas centrales del proyecto.

## 17. Relación entre repositorios

Los componentes principales pueden desarrollarse como repositorios independientes:

```text
prospector-engine
        │
        │ reutilización
        ▼
prospector-service
        │
        │ consumo
        ▼
saas-backend
        │
        │ consumo
        ▼
Flutter
```

El repositorio del Engine existe para permitir:

* evolución independiente de la lógica de extracción;
* pruebas;
* documentación;
* reutilización;
* mantenimiento;
* separación del código originalmente perteneciente al CLI.

La integración posterior dentro del Service no significa que el Engine se convierta automáticamente en un servicio distribuido.

## 18. Desarrollo paralelo

Debido al tiempo limitado del proyecto, el desarrollo se realizará de manera progresiva y parcialmente paralela.

Mientras se estabiliza Prospector Engine y posteriormente Prospector Service, el desarrollo del SaaS Backend puede comenzar con su estructura inicial.

La estrategia prevista es:

```text
                    Prospector Engine
                           │
                           │ desarrollo
                           ▼
                    Prospector Service
                           │
                           │ integración
                           ▼
                      SaaS Backend
```

En paralelo:

```text
SaaS Backend
    │
    ├── estructura inicial
    ├── autenticación
    ├── seguridad
    ├── módulos
    ├── contratos
    └── mocks
```

Esto permite que el resto del equipo pueda comenzar a trabajar con contratos y comportamientos simulados antes de que toda la lógica de prospección esté terminada.

## 19. Uso de mocks durante el desarrollo

El SaaS Backend puede comenzar utilizando respuestas simuladas mientras Prospector Service se encuentra en desarrollo.

Por ejemplo:

```text
Flutter
   ↓
SaaS Backend
   ↓
Mock Prospector Response
```

Posteriormente:

```text
Flutter
   ↓
SaaS Backend
   ↓
Prospector Service
   ↓
Prospector Engine
```

Esto permite desacoplar parcialmente los tiempos de desarrollo de los diferentes componentes sin modificar la arquitectura conceptual.

## 20. Multi-tenancy

La plataforma SaaS requiere soporte multi-tenant.

La estrategia considerada es:

```text
Shared Database
Shared Schema
Tenant ID
```

El tenant pertenece al dominio de la plataforma y, por lo tanto, su administración corresponde al SaaS Backend.

El Prospector Engine no debe administrar tenants.

El Prospector Service puede recibir información contextual necesaria para ejecutar una solicitud, pero no debe convertirse en el propietario del dominio de tenants de la plataforma.

## 21. Principios arquitectónicos

El proyecto seguirá inicialmente estos principios:

1. **Reutilizar antes que reescribir.**

2. **Separar lógica de negocio de lógica de extracción.**

3. **Mantener el Engine independiente del SaaS.**

4. **Mantener el Engine independiente de Flutter y NestJS.**

5. **Utilizar Prospector Service como frontera HTTP de la capacidad de prospección.**

6. **Mantener el Engine integrado dentro del Service en lugar de introducir distribución innecesaria.**

7. **Validar requests mediante DTOs y tipado estructurado.**

8. **Evitar introducir lógica de tenants o campañas dentro del Engine.**

9. **Mantener la extracción determinista en la medida que las fuentes externas lo permitan.**

10. **Preferir simplicidad y funcionalidad sobre complejidad arquitectónica innecesaria.**

11. **Evitar sobreingeniería debido al alcance temporal del proyecto.**

12. **Documentar las decisiones que posteriormente puedan cambiar.**

## 22. Restricción temporal

El proyecto se desarrolla durante el semestre agosto-diciembre, pero el periodo efectivo de implementación es limitado.

Por esta razón, las decisiones arquitectónicas deben evaluarse bajo el principio:

> **La arquitectura debe ser suficientemente sólida para cumplir el objetivo, pero suficientemente simple para poder terminarse.**

No se busca implementar prematuramente:

* microservicios adicionales;
* sistemas de mensajería complejos;
* infraestructura distribuida innecesaria;
* mecanismos avanzados de procesamiento;
* patrones que no aporten valor inmediato;
* abstracciones excesivas.

La prioridad es obtener:

```text
Funcionalidad
    >
Correctitud
    >
Determinismo
    >
Mantenibilidad
    >
Complejidad innecesaria
```

## 23. Estado conceptual del proyecto

El proyecto se encuentra en una etapa de transición desde componentes existentes hacia una arquitectura de servicios.

El punto de partida es:

```text
Prospector CLI v0.7.0
```

La auditoría permitió identificar la lógica de extracción existente y separar conceptualmente:

```text
CLI
    ↓
Motor de extracción
```

El siguiente paso es:

```text
Prospector Engine v1.0.0
```

Posteriormente:

```text
Prospector Service
        +
Prospector Engine integrado
```

Y finalmente:

```text
SaaS Backend
        ↓
Prospector Service
        ↓
Prospector Engine
```

## 24. Estado de las decisiones

No todas las decisiones de arquitectura se consideran definitivas.

Las siguientes áreas pueden evolucionar durante la implementación:

* modelo definitivo de Business;
* campos de identidad de Google Maps;
* estrategia de deduplicación;
* contrato definitivo de Prospector Service;
* modelo de errores;
* manejo de resultados parciales;
* concurrencia;
* retries;
* límites de ejecución;
* persistencia;
* estrategia definitiva de integración del repositorio del Engine;
* posibilidad de distribuir el Engine en una futura versión.

La documentación representa el **estado actual del diseño y del alcance**, no necesariamente el diseño final de producción.

## 25. Relación conceptual final

El sistema puede resumirse en tres niveles:

```text
┌───────────────────────────────────────┐
│             SaaS Backend              │
│                                       │
│     "¿Qué significa esto para        │
│        nuestra plataforma?"          │
│                                       │
│ Tenant / User / Campaign / Business   │
└───────────────────┬───────────────────┘
                    │
                    │ HTTP
                    ▼
┌───────────────────────────────────────┐
│          Prospector Service            │
│                                       │
│     "¿Cómo ejecuto esta capacidad     │
│             de prospección?"          │
│                                       │
│ API / DTO / Validation / Orchestration│
└───────────────────┬───────────────────┘
                    │
                    │ in-process
                    ▼
┌───────────────────────────────────────┐
│           Prospector Engine            │
│                                       │
│     "¿Cómo encuentro y enriquezco     │
│          estos prospectos?"           │
│                                       │
│ Maps / Extraction / Website /         │
│ Normalization / Deduplication         │
└───────────────────┬───────────────────┘
                    │
                    ▼
              External Sources
```

La idea fundamental es:

> **El SaaS Backend administra el negocio. Prospector Service administra la ejecución de la capacidad de prospección. Prospector Engine ejecuta la extracción y enriquecimiento.**

## 26. Propósito de este contexto para la documentación académica

Este documento debe utilizarse como contexto general del proyecto junto con los README específicos de cada componente.

Los README individuales describen las responsabilidades y decisiones propias de cada componente.

Este documento proporciona la relación entre ellos y permite interpretar el proyecto como un sistema completo.

La arquitectura no debe interpretarse como tres aplicaciones aisladas, sino como una composición de responsabilidades:

```text
Flutter
   ↓
Interfaz de usuario

SaaS Backend
   ↓
Dominio y reglas de negocio

Prospector Service
   ↓
API y orquestación

Prospector Engine
   ↓
Capacidad técnica de extracción

Google Maps / Websites
   ↓
Fuentes externas
```

El resultado esperado es una plataforma académica con fundamento en una solución empresarial existente, donde la reutilización de software, la separación de responsabilidades y la integración de servicios permitan evolucionar una capacidad de prospección existente hacia una arquitectura SaaS.
