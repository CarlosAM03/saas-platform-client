# Acta G1 — implementación autorizada

Fecha: 27-10-2026. Autoridad: Plan de TrabajoAvance2.md y autorización ampliada del owner (archivo 48238023-1628-4404-905a-bffff8499f05). Esta autorización sustituyó la parada anterior en G1 y permitió G1–G4 y G6 locales, conservando el merge main/producción reservado. No modifica entregables históricos G0.

A1 se implementó desde 3a3309398458ab333d7b00f16e9c2df6a09ef734 en fix/avance2-core-security. B01: protección transaccional SEC-01; B02/B03: configuración productiva y tests aislados; B04: trim CORS; B05: 413; B06: overrides acotados y lock; B07: prueba HTTP y PostgreSQL de identidad/roles/atomicidad/snapshot. B08: Prisma, migración init, JwtStrategy, Jobs, cliente Prospector y deploymentDocument permanecen baseline.

A2 parte exactamente de Foundation 095e899ace31acf17d97bbe945c118c1a5d88682. F01/F02: copia OpenAPI alineada al contrato público servido, no al YAML objetivo futuro; se preservan extensiones contract-only. F03–F07: se conserva Foundation con sesión/scope/dialogs, UI válida de André, SaaS, CSV, dashboard y GET Jobs. F08: panel visual aislado DEMO — SIN EJECUCIÓN REAL sin SDK, red o datos de negocio. F09: contenedores/tema/assets preservados.

Commits core: Backend78d076d3d367a7789f41f5f29c581f5cf28b88fc y corrección de reproducibilidad69c73365f0547e994f57cad7fb83269023db4b8e; Flutter41a16dd462c2bbe6c892bf2c5669975ca70cb752. Tooling adicional responde a la exigencia ampliada de arranque local de un comando y TLS confiable aislado. La corrección de bootstrap fue demostrada generando cuatro claves core y siete experimentales sin imprimir valores; se añadió validación y reglas LF.

G1 CUMPLIDO. Evidencia de ejecución y CI en actas G2/G3–G4. Pendientes de producto: revocación dinámica y Node20, diferidos expresamente; arquitectura productiva1.1.0 continúa sin aprobar. Ningún merge main ni modificación de proveedores se deriva de esta acta.
