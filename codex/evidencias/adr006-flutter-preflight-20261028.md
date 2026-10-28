# Preflight Flutter ADR-006 — carril separado

Verificado el 28/10/2026 antes de editar código. Autorización expresa del owner
en esta tarea sustituye únicamente la prohibición de implementar ADR-006 dentro
del sprint Core; no modifica sus documentos históricos ni sus correcciones.

- Raíz absoluta: `C:\Users\angel\OneDrive\Documentos\saas-frontendProspector\saas-platform-client`.
- Remoto: `https://github.com/CarlosAM03/saas-platform-client.git`.
- Inicio: main y origin/main `e752f6ca692d2840263cd9e59e0927c56aa129ec`.
- `git fetch origin main`: correcto, sin cambio del baseline.
- Árbol inicial limpio: status sin modificaciones/no rastreados; diffs index y
  working tree vacíos. Sin AGENTS.md en repo ni directorios ascendentes revisados.
- Base contiene merge PR #10 y commits Core FE-01/02/03, dashboard y deep links.
- Creada rama exclusiva `feat/tenant-register` desde origin/main; sin commit/push.
- Lectura completa: documentos 01/02/03, matriz/inventario, README, guía de features,
  CONTRIBUTING, ADR-005, ADR-006, YAML aprobado, red/router/Auth/Tenants/Admin y tests.
- Hashes normalizados LF coinciden con adr006-inventory.json. Los hashes físicos
  difieren solo por checkout CRLF; no se editaron los documentos aprobados.

## Baseline ejecutado

SDK disponible: Flutter 3.47.2 estable / Dart 3.13.2 (documentación menciona 3.47.5).
No se cambió SDK ni dependencias.

| Comando | Exit | Resultado |
| --- | --- | --- |
| dart run tool/check_merge_markers.dart | 0 | PASS |
| flutter pub get | 1 | Resolvió paquetes; Windows sin soporte symlink para plugins/Developer Mode. ENV_BLOCKER, no se alteró el sistema. |
| dart run build_runner build | 0 | PASS; dos outputs ignorados. Warning previo analyzer 3.12 frente a SDK 3.13; sin upgrades. |
| flutter analyze | 0 | PASS, sin issues |
| flutter test | 0 | PASS, 279 pruebas |

Backend/runtime/PostgreSQL/SMTP y remoto: no certificados por este preflight.
No se escribió fuera de Flutter, no se modificaron flags ni infraestructura.
