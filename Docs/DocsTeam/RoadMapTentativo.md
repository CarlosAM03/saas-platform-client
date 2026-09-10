# Roadmap Tentativo de Desarrollo — MVP

> Nota de vigencia: este documento es histórico o conceptual. No sustituye ADR-004, el contrato OpenAPI, FormularioDecisionesFase5.md ni ADR-005-FlutterFoundation.md. En caso de contradicción, prevalecen los documentos normativos vigentes.

**Periodo:** Agosto–Diciembre 2026
**Objetivo:** Construir y demostrar un MVP funcional de la plataforma SaaS de prospección automatizada y gestión de campañas.

> Roadmap tentativo. Puede ajustarse conforme avance el diseño, la implementación y las decisiones del equipo.

## Fases del proyecto

### 1. Diseño y definición

**Agosto 2026**

* Consolidar propuesta y alcance del MVP.
* Validar arquitectura general.
* Definir responsabilidades de cada componente.
* Finalizar estrategia Multi-Tenancy.
* Finalizar modelado conceptual y pasar al diseño de datos.

**Resultado:** arquitectura y alcance suficientemente definidos para comenzar la construcción.

---

### 2. Modelado y contratos — Actual

**Agosto–Septiembre**

* Modelo de datos final.
* Entidades y relaciones.
* Contratos entre Flutter, SaaS Backend y Prospector Service.
* Estructura inicial de repositorios.
* Configuración base de ambientes.

**Resultado:** componentes preparados para desarrollo paralelo.

---

### 3. Construcción de componentes v0.0.0 → v1.0.0

**Septiembre–Octubre**

Desarrollar progresivamente cada componente desde una base inicial hasta una primera versión funcional:

```text
Flutter              v0.0.0 → v1.0.0
SaaS Backend         v0.0.0 → v1.0.0
Prospector Service   v0.0.0 → v1.0.0
Prospector Engine    v0.7.0 → v1.0.0
```

El Engine parte de **v0.7.0** porque proviene de una herramienta previamente desarrollada; los demás componentes comienzan desde una base nueva.

**Resultado:** primera versión funcional e integrable de cada componente.

---

### 4. Integración vertical

**Octubre**

Construir y validar el flujo mínimo completo:

```text
Flutter
   ↓
SaaS Backend
   ↓
Prospector Service
   ↓
Prospector Engine
   ↓
Fuentes externas
   ↓
Resultados
   ↓
SaaS Backend
   ↓
Flutter
```

**Resultado:** arquitectura funcionando de extremo a extremo.

---

### 5. Integración del dominio SaaS

**Octubre–Noviembre**

* Autenticación y usuarios.
* Tenants.
* Campañas.
* Prospecciones.
* Persistencia de resultados.
* Aislamiento lógico entre tenants.
* Integración completa con PostgreSQL.

**Resultado:** plataforma SaaS funcional sobre la arquitectura definida.

---

### 6. Endurecimiento y preparación del MVP

**Noviembre**

* Corrección de errores.
* Validaciones.
* Manejo de estados y errores.
* Limpieza de código.
* Configuración de ambientes.
* Empaquetado y despliegue.
* Pruebas de integración.
* Revisión de Multi-Tenancy.

**Resultado:** versión candidata a MVP.

---

### 7. MVP y presentación

**Noviembre–Diciembre**

El MVP debe demostrar como mínimo:

```text
Usuario
   ↓
Tenant
   ↓
Campaña
   ↓
Prospección
   ↓
Prospector Service
   ↓
Prospector Engine
   ↓
Prospectos
   ↓
Persistencia
   ↓
Visualización
```

Prioridad:

**funcionalidad → integración → estabilidad → presentación.**

Las funcionalidades secundarias y mejoras de UX quedan después del flujo principal.

---

## Secuencia general

```text
DISEÑO
  ↓
MODELO DE DATOS + CONTRATOS
  ↓
COMPONENTES v0.0.0 → v1.0.0
  ↓
INTEGRACIÓN VERTICAL
  ↓
FUNCIONALIDADES SaaS
  ↓
PRUEBAS + HARDENING
  ↓
DESPLIEGUE
  ↓
MVP
  ↓
PRESENTACIÓN
```

## Meta del semestre

> **Pasar de una arquitectura diseñada y documentada a un MVP funcional, integrado y desplegable que demuestre la aplicación práctica de una arquitectura SaaS multi-tenant y de los conceptos de desarrollo de software con aplicación en la nube.**
