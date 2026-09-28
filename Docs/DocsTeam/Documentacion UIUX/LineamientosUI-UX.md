# Identidad Visual y Lineamientos UI/UX

## Plataforma SaaS — Cliente Flutter

**Versión:** 0.1
**Estado:** Propuesta inicial para diseño UI/UX
**Proyecto:** Plataforma SaaS para gestión de campañas de marketing
**Cliente:** Flutter
**Documento dirigido a:** Diseño UI/UX y desarrollo frontend

---

# 1. Propósito del documento

Este documento establece una primera propuesta de **identidad visual y lineamientos de diseño UI/UX** para la aplicación móvil de la Plataforma SaaS.

Su objetivo principal es proporcionar una base visual sobre la cual puedan comenzar a desarrollarse:

* Bocetos.
* Wireframes.
* Prototipos.
* Diseño de pantallas.
* Componentes reutilizables.
* Flujo de navegación.
* Propuestas visuales para el MVP.

Este documento **no representa todavía un sistema de diseño definitivo**.

Las decisiones visuales podrán modificarse conforme evolucionen los requerimientos funcionales, la arquitectura y las necesidades de las diferentes partes del proyecto.

---

# 2. Contexto del producto

La aplicación forma parte de una plataforma SaaS orientada a la **gestión de campañas de marketing**.

La plataforma está diseñada bajo un modelo de **Multi-Tenancy**, donde diferentes organizaciones pueden utilizar el mismo sistema manteniendo separados sus usuarios, campañas y datos.

Desde la perspectiva del usuario, la aplicación debe transmitir la sensación de estar trabajando dentro de un espacio de trabajo propio.

Conceptualmente:

```text
                    PLATAFORMA SaaS
                          │
             ┌────────────┴────────────┐
             │                         │
         Organización A           Organización B
             │                         │
       ┌─────┴─────┐             ┌─────┴─────┐
       │            │             │           │
    Usuarios     Campañas       Usuarios    Campañas
```

Por esta razón, el diseño debe comunicar:

* Organización.
* Control.
* Claridad.
* Profesionalismo.
* Confianza.
* Productividad.
* Tecnología.

---

# 3. Objetivo de la experiencia

La aplicación debe permitir que un usuario pueda comprender rápidamente:

1. En qué organización está trabajando.
2. Qué campañas tiene disponibles.
3. Cuál es el estado de sus campañas.
4. Qué acciones puede realizar.
5. Qué información requiere atención.
6. Cómo desplazarse entre las principales funcionalidades.

El usuario no debería necesitar conocer la arquitectura interna de la plataforma para utilizarla.

Conceptos como:

* Multi-Tenancy.
* APIs.
* Prospector Service.
* PostgreSQL.
* Backend.
* Microservicios.

son conceptos arquitectónicos y **no deben dominar la interfaz de usuario**.

---

# 4. Dirección visual

## 4.1 Concepto general

La propuesta inicial es utilizar una estética de:

> **SaaS moderno + profesional + tecnológico + limpio**

La aplicación debe parecer una herramienta profesional de productividad y gestión, evitando una apariencia excesivamente corporativa o demasiado informal.

### Palabras clave

```text
MODERNA
    │
    ├── Limpia
    ├── Clara
    ├── Profesional
    ├── Tecnológica
    ├── Confiable
    └── Orientada a productividad
```

---

# 5. Personalidad visual

La interfaz debería comunicar principalmente cinco atributos:

| Atributo    | Aplicación en UI                                                    |
| ----------- | ------------------------------------------------------------------- |
| Profesional | Espaciado consistente, jerarquía clara y componentes ordenados      |
| Moderna     | Uso moderado de tarjetas, iconografía simple y elementos actuales   |
| Tecnológica | Paleta fría y elementos visuales relacionados con datos             |
| Confiable   | Estados claros, feedback inmediato y comportamiento predecible      |
| Productiva  | Acciones importantes visibles y reducción de elementos innecesarios |

Debe evitarse:

* Exceso de colores.
* Gradientes demasiado llamativos.
* Sombras excesivas.
* Interfaces saturadas.
* Demasiadas animaciones.
* Elementos decorativos que no aporten información.
* Uso excesivo de tarjetas.

---

# 6. Paleta de colores propuesta

Esta paleta es una **propuesta inicial** para comenzar los bocetos.

No debe considerarse todavía la paleta oficial de marca.

## 6.1 Color primario

**Azul tecnológico**

```text
Primary
#2563EB
```

Uso sugerido:

* Botones principales.
* Elementos seleccionados.
* Links.
* Indicadores activos.
* Acciones principales.
* Elementos de navegación.

El azul busca transmitir confianza, tecnología y profesionalismo.

---

## 6.2 Colores secundarios

### Azul oscuro

```text
#1E3A8A
```

Uso:

* Encabezados importantes.
* Elementos de contraste.
* Estados activos destacados.

### Azul claro

```text
#DBEAFE
```

Uso:

* Fondos de información.
* Estados seleccionados.
* Chips.
* Elementos secundarios.

---

# 7. Colores semánticos

Además del color principal, la interfaz deberá manejar colores asociados al estado de los elementos.

| Estado  | Color     | Uso                         |
| ------- | --------- | --------------------------- |
| Success | `#16A34A` | Completado, activo, exitoso |
| Warning | `#D97706` | Advertencias o atención     |
| Error   | `#DC2626` | Errores o acciones críticas |
| Info    | `#2563EB` | Información                 |
| Neutral | `#64748B` | Información secundaria      |

Los colores semánticos deben utilizarse principalmente para **comunicar estados**, no como decoración.

---

# 8. Escala de grises

La interfaz debe utilizar una escala neutral para la mayoría de los elementos.

```text
Background
#F8FAFC

Surface
#FFFFFF

Border
#E2E8F0

Text Primary
#0F172A

Text Secondary
#475569

Text Disabled
#94A3B8
```

La intención es mantener una interfaz predominantemente clara y utilizar el color primario únicamente para destacar acciones y elementos importantes.

---

# 9. Tipografía

Como propuesta inicial se recomienda utilizar:

## Inter

Inter es adecuada para una aplicación SaaS debido a su buena legibilidad en interfaces digitales.

Jerarquía propuesta:

```text
Display / Título principal
32 px

Heading
24 px

Section title
20 px

Body
16 px

Secondary
14 px

Caption
12 px
```

### Pesos

```text
Regular     400
Medium      500
SemiBold    600
Bold        700
```

No es necesario utilizar todos los tamaños en todas las pantallas.

La prioridad debe ser mantener una jerarquía visual consistente.

---

# 10. Espaciado

Se recomienda utilizar una escala basada en múltiplos de 4.

```text
4 px
8 px
12 px
16 px
20 px
24 px
32 px
40 px
48 px
```

Como regla inicial:

* 8–12 px para separación interna pequeña.
* 16 px como separación estándar.
* 24 px entre bloques importantes.
* 32 px o más para separar secciones.

Esto permitirá que los diseños puedan traducirse posteriormente de forma consistente a Flutter.

---

# 11. Bordes y formas

La interfaz deberá utilizar bordes ligeramente redondeados.

Propuesta:

```text
Small      6 px
Medium     10 px
Large      14 px
```

Los componentes principales pueden utilizar aproximadamente:

```text
Border Radius: 10–12 px
```

Debe evitarse el uso de radios excesivamente grandes que hagan que la aplicación parezca una interfaz infantil o excesivamente casual.

---

# 12. Sombras

Las sombras deberán utilizarse con moderación.

La jerarquía visual debe depender principalmente de:

1. Espaciado.
2. Color.
3. Contraste.
4. Bordes.
5. Sombras.

No se recomienda que todas las tarjetas tengan una sombra visible.

Una alternativa preferida es utilizar:

```text
Background
    ↓
Surface blanca
    ↓
Border sutil
```

y utilizar sombra únicamente cuando sea necesario establecer elevación.

---

# 13. Iconografía

Se recomienda utilizar una biblioteca de iconos consistente.

Los iconos deberán ser:

* Simples.
* Lineales.
* Reconocibles.
* Consistentes en grosor.
* No excesivamente decorativos.

Conceptualmente:

```text
Dashboard       → Inicio / resumen
Campaigns       → Campañas
Prospecting     → Prospección
Notifications   → Notificaciones
Settings        → Configuración
Profile         → Usuario
```

No se recomienda combinar diferentes estilos de iconografía dentro de una misma pantalla.

---

# 14. Componentes visuales iniciales

El diseño debería contemplar desde el principio un conjunto reducido de componentes reutilizables.

## 14.1 Buttons

### Primary

Para la acción principal de una pantalla.

Ejemplos:

```text
+ Crear campaña
Iniciar sesión
Guardar cambios
Continuar
```

### Secondary

Para acciones alternativas.

```text
Cancelar
Ver detalles
Editar
```

### Destructive

Para acciones potencialmente peligrosas.

```text
Eliminar campaña
Cerrar sesión
```

---

# 15. Inputs

Los campos de entrada deberán utilizar:

* Label.
* Placeholder cuando sea necesario.
* Estado normal.
* Estado focused.
* Estado error.
* Estado disabled.
* Mensaje de validación cuando corresponda.

Ejemplo conceptual:

```text
Nombre de campaña

┌──────────────────────────────┐
│ Campaña verano 2026          │
└──────────────────────────────┘

Ingrese un nombre descriptivo
```

---

# 16. Cards

Las tarjetas serán importantes para representar información resumida.

Ejemplo:

```text
┌────────────────────────────────────┐
│ Campaña Verano 2026         ● Activa
│                                    │
│ Prospectos                 1,240   │
│ Contactados                  380   │
│ Conversión                  12.4%  │
│                                    │
│                     Ver detalles → │
└────────────────────────────────────┘
```

Las cards deberán utilizarse para agrupar información relacionada, no simplemente para colocar cada elemento de la interfaz dentro de una caja.

---

# 17. Badges / Status

Los estados de campañas deberán ser fácilmente identificables.

Ejemplo:

```text
● Activa
● Pausada
● Completada
● Borrador
● Error
```

Los badges deberán combinar:

* Color.
* Texto.
* Opcionalmente un icono.

No se deberá depender únicamente del color para comunicar el estado.

---

# 18. Navegación propuesta

Para la aplicación móvil se propone inicialmente una navegación inferior.

Conceptualmente:

```text
┌─────────────────────────────────┐
│                                 │
│          CONTENIDO              │
│                                 │
│                                 │
│                                 │
├─────────────────────────────────┤
│  Inicio   Campañas   Prospector │
│    ◉         ◇          ◇       │
│                                 │
└─────────────────────────────────┘
```

La navegación exacta todavía deberá validarse conforme se definan las funcionalidades reales.

Una alternativa para funcionalidades secundarias sería:

```text
Perfil
Configuración
Organización
Notificaciones
Ayuda
```

dentro de un menú de usuario.

---

# 19. Contexto del Tenant

El usuario debe poder identificar claramente la organización con la que está trabajando.

Por ejemplo:

```text
┌─────────────────────────────────┐
│ ACME Marketing            ▾     │
│                                 │
│ Campañas                        │
│                                 │
└─────────────────────────────────┘
```

El nombre o identificador del tenant puede aparecer en:

* Header.
* Perfil.
* Selector de organización.
* Menú lateral o menú de usuario.

### Importante

La interfaz deberá comunicar el contexto del tenant, pero **la seguridad del tenant no depende de la interfaz**.

La aplicación Flutter no debe asumir que mostrar un tenant implica que el usuario tenga autorización sobre él.

La autorización real corresponde al backend.

---

# 20. Pantallas iniciales a diseñar

Para comenzar los bocetos se recomienda trabajar primero con las siguientes pantallas.

## 20.1 Splash / Loading

Objetivo:

Mostrar brevemente la identidad de la aplicación mientras se inicializa la sesión.

Elementos:

```text
Logo

Plataforma SaaS

        Loading...
```

No debe convertirse en una pantalla innecesariamente compleja.

---

# 21. Login

Esta debería ser una de las primeras pantallas diseñadas.

Propuesta conceptual:

```text
┌─────────────────────────────────┐
│                                 │
│             LOGO                │
│                                 │
│       Bienvenido de nuevo       │
│                                 │
│       Inicia sesión             │
│       para continuar            │
│                                 │
│ Correo                          │
│ ┌─────────────────────────────┐ │
│ │ usuario@empresa.com         │ │
│ └─────────────────────────────┘ │
│                                 │
│ Contraseña                      │
│ ┌─────────────────────────────┐ │
│ │ ••••••••••••            ◉   │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │       Iniciar sesión        │ │
│ └─────────────────────────────┘ │
│                                 │
│       ¿Olvidaste tu contraseña? │
│                                 │
└─────────────────────────────────┘
```

Debe contemplarse posteriormente:

* Loading.
* Error de credenciales.
* Sesión expirada.
* Campos inválidos.
* Backend no disponible.

---

# 22. Dashboard / Inicio

El Dashboard será el punto principal después de iniciar sesión.

Su objetivo será responder rápidamente:

> ¿Qué está pasando con mis campañas?

Propuesta:

```text
Hola, Carlos

ACME Marketing

Resumen

┌──────────────┐ ┌──────────────┐
│ Campañas     │ │ Prospectos   │
│     12       │ │    1,240     │
└──────────────┘ └──────────────┘

Campañas recientes

┌──────────────────────────────┐
│ Campaña Verano       Activa  │
│ 1,240 prospectos             │
│ ███████████░░░ 78%           │
└──────────────────────────────┘

┌──────────────────────────────┐
│ Campaña B2B          Pausada │
│ 530 prospectos               │
└──────────────────────────────┘
```

El Dashboard debe priorizar información útil y no convertirse en un tablero lleno de métricas sin propósito.

---

# 23. Lista de campañas

Debe permitir visualizar rápidamente las campañas disponibles.

Elementos:

* Nombre.
* Estado.
* Fecha.
* Progreso.
* Información resumida.
* Acción para consultar detalles.

Ejemplo:

```text
Campañas                         +

Buscar campañas...

[ Todas ] [ Activas ] [ Pausadas ]

┌───────────────────────────────┐
│ Campaña Verano 2026   Activa  │
│ 1,240 prospectos              │
│ Actualizada hoy               │
└───────────────────────────────┘

┌───────────────────────────────┐
│ Campaña B2B           Pausada │
│ 530 prospectos                │
│ Actualizada ayer              │
└───────────────────────────────┘
```

---

# 24. Detalle de campaña

Esta pantalla deberá proporcionar una visión más completa de una campaña.

Posible estructura:

```text
← Campañas

Campaña Verano 2026

● Activa

Resumen
────────────────────

Prospectos       1,240
Contactados        380
Respuestas          94

Progreso
████████████░░ 78%

Actividad reciente
────────────────────

09:42   Prospección ejecutada
08:31   120 prospectos encontrados
Ayer    Campaña activada

                    [Editar]
```

Las acciones disponibles dependerán de las reglas de negocio que se definan posteriormente.

---

# 25. Crear campaña

La creación de campañas deberá diseñarse como un flujo sencillo y progresivo.

Posible estructura:

```text
Nueva campaña

1. Información
2. Público objetivo
3. Configuración
4. Confirmación

────────────────────

Nombre de campaña

[____________________]

Descripción

[____________________]

                    Continuar →
```

No se recomienda colocar todos los campos posibles en una única pantalla si el formulario termina siendo demasiado extenso.

---

# 26. Perfil y organización

Debe existir una sección donde el usuario pueda consultar información relacionada con:

```text
Usuario
├── Nombre
├── Correo
├── Perfil
└── Sesión

Organización
├── Nombre
├── Información
└── Contexto actual
```

Las funciones administrativas podrán agregarse posteriormente.

---

# 27. Estados de interfaz

Cada pantalla importante debe contemplar al menos los siguientes estados:

### Loading

```text
Cargando información...
```

### Empty

Cuando todavía no existen datos.

```text
No tienes campañas todavía.

Crea tu primera campaña para comenzar.

[Crear campaña]
```

### Error

```text
No pudimos cargar las campañas.

Intenta nuevamente.

[Reintentar]
```

### Success

Feedback posterior a una acción.

```text
✓ Campaña creada correctamente.
```

### Offline / Connectivity

Cuando la aplicación no pueda comunicarse con el backend.

```text
Sin conexión

Comprueba tu conexión a Internet
e intenta nuevamente.
```

Estos estados deben considerarse desde los bocetos iniciales y no agregarse únicamente al final del desarrollo.

---

# 28. UX y accesibilidad

La aplicación deberá procurar:

* Contraste suficiente entre texto y fondo.
* Tamaños de texto legibles.
* Áreas táctiles adecuadas.
* Mensajes de error comprensibles.
* No depender únicamente del color para comunicar estados.
* Navegación predecible.
* Acciones destructivas claramente diferenciadas.
* Feedback después de acciones importantes.

Los componentes deberán diseñarse considerando inicialmente dispositivos móviles, pero procurando que puedan evolucionar posteriormente hacia diferentes tamaños de pantalla.

---

# 29. Responsive / Multiplataforma

Aunque Flutter permitirá desarrollar para múltiples plataformas, el primer diseño deberá priorizar la experiencia móvil.

El diseño deberá evitar depender de:

* Anchos fijos.
* Posiciones absolutas.
* Tamaños rígidos.
* Elementos que solo funcionen en una resolución específica.

La interfaz deberá poder adaptarse progresivamente a:

```text
Mobile
   ↓
Tablet
   ↓
Desktop / Web
```

sin requerir necesariamente un rediseño completo.

---

# 30. Principios de diseño

Todos los bocetos deberían seguir estos principios:

### 1. Claridad antes que decoración

La interfaz debe explicar qué puede hacer el usuario.

### 2. Una acción principal por contexto

Cada pantalla debe tener una acción claramente priorizada.

### 3. Información progresiva

Mostrar primero lo importante y permitir consultar detalles posteriormente.

### 4. Consistencia

Un mismo componente debe comportarse igual en toda la aplicación.

### 5. Feedback

Toda acción relevante debe proporcionar una respuesta visual.

### 6. Seguridad percibida

El usuario debe entender cuándo está realizando acciones importantes o irreversibles.

### 7. Escalabilidad

El diseño debe permitir agregar funcionalidades sin romper la estructura visual existente.

---

# 31. Flujo inicial de navegación

Como punto de partida:

```text
                    Splash
                       │
                       ▼
                    Login
                       │
                       ▼
                  Dashboard
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
      Campañas      Prospector    Perfil
          │
          ▼
    Lista campañas
          │
          ▼
   Detalle campaña
          │
          ▼
    Editar / Crear
```

Este flujo es únicamente una propuesta inicial.

La navegación definitiva deberá ajustarse conforme se definan las funcionalidades y reglas de negocio.

---

# 32. Componentes que deberían convertirse posteriormente en Design System

A medida que avance el proyecto, se recomienda formalizar:

```text
Design System
│
├── Colors
├── Typography
├── Spacing
├── Icons
├── Buttons
├── Inputs
├── Cards
├── Badges
├── Dialogs
├── Bottom Sheets
├── Navigation
├── App Bars
├── Lists
├── Loading states
├── Empty states
├── Error states
└── Feedback / Notifications
```

El objetivo es que los componentes diseñados en Figma puedan posteriormente tener equivalentes reutilizables en Flutter.

---

# 33. Relación entre diseño y Flutter

El diseño debe realizarse teniendo presente que será implementado en Flutter.

Por lo tanto, se recomienda evitar diseños que dependan excesivamente de:

* Elementos imposibles de reutilizar.
* Animaciones extremadamente complejas.
* Componentes visuales diferentes para cada pantalla.
* Layouts rígidos.
* Elementos puramente decorativos que incrementen innecesariamente la complejidad.

La intención es que exista una correspondencia razonable:

```text
Figma / Diseño
      │
      ▼
Design System
      │
      ▼
Flutter Widgets
      │
      ▼
Features
```

Por ejemplo:

```text
Figma Button
      ↓
AppButton

Figma Input
      ↓
AppTextField

Figma Card
      ↓
CampaignCard

Figma Status Badge
      ↓
StatusBadge
```

---

# 34. Entregables esperados del diseño

Para la primera iteración se recomienda que el diseño produzca:

## Prioridad 1

* Splash.
* Login.
* Dashboard.
* Lista de campañas.
* Detalle de campaña.

## Prioridad 2

* Crear campaña.
* Editar campaña.
* Perfil.
* Organización / Tenant.

## Prioridad 3

* Estados de error.
* Estados vacíos.
* Loading.
* Confirmaciones.
* Modales.
* Notificaciones.

---

# 35. Qué NO debe definirse todavía

Para evitar convertir decisiones temporales en restricciones del proyecto, todavía no deben considerarse definitivos:

* Logotipo final.
* Nombre comercial definitivo.
* Paleta corporativa oficial.
* Roles definitivos.
* Permisos definitivos.
* Flujo definitivo de cambio de tenant.
* Funcionalidades completas de campañas.
* Diseño final del Prospector.
* Sistema definitivo de notificaciones.
* Arquitectura definitiva de navegación.
* Tema oscuro.
* Sistema completo de accesibilidad.

Estas decisiones podrán incorporarse posteriormente mediante nuevas versiones del documento.

---

# 36. Criterio para los primeros bocetos

Los primeros bocetos no necesitan ser diseños finales.

El objetivo inicial es validar:

```text
¿La navegación tiene sentido?
          ↓
¿La información importante está visible?
          ↓
¿El usuario entiende dónde está?
          ↓
¿Las acciones principales son claras?
          ↓
¿El flujo puede implementarse razonablemente en Flutter?
```

Por esta razón, la primera iteración puede comenzar con **wireframes de baja fidelidad** antes de invertir tiempo en detalles visuales.

Posteriormente:

```text
Wireframe
    ↓
Validación del flujo
    ↓
Diseño visual
    ↓
Design System
    ↓
Prototipo
    ↓
Implementación Flutter
```

---

# 37. Propuesta inicial de identidad

Como punto de partida, la identidad visual de la plataforma puede resumirse como:

```text
                PLATAFORMA SaaS

        ┌───────────────────────────┐
        │                           │
        │       MODERNA             │
        │                           │
        │   PROFESIONAL             │
        │                           │
        │       TECNOLÓGICA         │
        │                           │
        │   CLARA Y PRODUCTIVA      │
        │                           │
        └───────────────────────────┘

Primary:
#2563EB

Typography:
Inter

Style:
Clean / Modern / SaaS

UI:
Cards + Lists + Status + Clear Actions
```

---

# 38. Nota para diseño

Este documento debe utilizarse como **punto de partida para explorar propuestas**, no como una restricción absoluta.

La persona encargada del diseño puede proponer modificaciones cuando encuentre una solución visual o de experiencia que mejore el producto.

Cualquier cambio que afecte elementos estructurales importantes deberá posteriormente validarse con el equipo de desarrollo y producto.

La prioridad es construir una interfaz que sea:

> **clara para el usuario, consistente visualmente y viable de implementar en Flutter.**

---

# 39. Control de versiones

| Versión | Estado    | Descripción                                                |
| ------- | --------- | ---------------------------------------------------------- |
| 0.1     | Inicial   | Primera propuesta de identidad visual y lineamientos UI/UX |
| 0.2     | Pendiente | Ajustes derivados de los primeros wireframes               |
| 0.3     | Pendiente | Incorporación del Design System                            |
| 1.0     | Pendiente | Identidad visual y UI/UX aprobados para implementación     |

**Estado actual:** Documento de exploración y definición inicial.
