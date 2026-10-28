# Handoff Gate 1 Frontend — estado de trabajo

Fecha: 2026-10-28, America/Tijuana. CarlosAM03/saas-platform-client,
feat/tenant-register, PR11→main. Core e752f6c; entrega original Ángel9c0e556;
hardening a09c117; fixture de historial919ce03. Backend candidato5e214420.

G1_FRONTEND = BLOCKED
E2E_LOCAL = BLOCKED
PARIDAD_BACKEND_FINAL = BLOCKED
CI_FINAL = PASS en919ce03; verificar nuevamente tras el commit documental.

## Trabajo realizado

Se conserva el módulo original. Corregidos el guardado temprano del secreto por
el motor Web y la autoridad incorrecta del reloj local. Mejorado foco, teclado,
errores accesibles y bloqueo de envíos. Añadidas regresiones específicas, runner
real Chromium/Edge, laboratorio aislado por SHA y documentación nueva sin alterar
históricos. No se modificó Backend ni contrato, no merge ni despliegue.

Validación: baseline312 PASS+1 skip, final317 PASS+1 skip, ADR00638 PASS+1 skip,
análisis/generación/pub/build PASS, cuatro grupos de historial/resiliencia reales
PASS y tres jobs GitHub PASS en919ce03. Ver01–09 para scopes y límites exactos.

## Trabajo que impide cerrar

- Concluir la activación E2E y el recorrido Core UI→API→SQL en el laboratorio.
- Repetir contra Backend5e214420, incluida autorización viva D4, flagOFF y roles.
- Recuperar Docker/WSL y acreditar cleanup si una ejecución fue interrumpida.
- QF01 histórico: no reproducido con datos sintéticos; no declarar resuelto.
- Publicar tooling/evidencias y verificar tres checks en el HEAD definitivo.

El owner autorizó recuperar Docker/WSL después de terminar el agente Backend.
No se realizaron limpieza global, cambios de seguridad Windows ni operaciones
Supabase. No se infiere integridad de registros históricos reales desde fixtures.

Reproducción preparada: tool/frontend-adr006/Start-Lab.ps1, run-browser.mjs,
e2e.mjs y run-core.mjs. Configuración privada .local excluida por Git/Docker.
El transporte definitivo se sustituye solo dentro de la red de laboratorio, con
TLS/CA confinados y destinatarios sintéticos.

Aceptación/promoción siguen reservadas al owner. El PR permanece abierto sin
fusionar ni desplegar y no debe promocionarse mientras los bloqueos sigan abiertos.
