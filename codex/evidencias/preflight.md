# Preflight — 28 octubre 2026

PASS: harness completo leído. Sin AGENTS propios. Backend working tree experimental: autoridad verificada por git ls-remote main y git show origin/main: b51b265f1a545fa915f1dd1c57ef2f5858ec6492. Flutter origin/main: 7731649a2c69b45cb9776d02de4a6105d6fd9886.

PASS: rama sprint/frontend-core-v1-parity creada desde origin/main. Checkout anterior dev 2fdba28; único no rastreado codex/ del owner, preservado. Sin stash/reset/clean ni integración experimental. Git requiere ejecución fuera sandbox; alias C:/w y C:/f documentados.

PASS: Flutter3.47.5, Dart3.13.4, Node22.16.0, Docker29.9.2, Compose5.6.1. Docker Desktop iniciado oculto. Ningún contenedor activo; volúmenes históricos preservados. E2E usará proyecto y volumen nuevos.

Decisión expresa owner: excepción FE-03 para leer claims JWT solo para presentación, validando identidad/tenant. Backend conserva autorización.

Baseline PASS: merge markers, pub get, build_runner (80s), analyze (47.4s sin issues), flutter test (256 aprobadas,25s). Warning preexistente analyzer3.12 frente SDK3.13; no actualizar dependencias. Registrantes generados de plugins inspeccionados separadamente.

NOT RUN: reglas efectivas de promoción, CI futuro PR, deployment Vercel/SHA Render. PR Flutter#8 abierto draft sobre fix/f5-foundation: excluido. main autorizado expresamente frente CONTRIBUTING histórico dev.

Cierre: los SHA remotos main se revalidaron sin cambios. Runtime local Swagger1.0.0/33 operaciones, sin ADR-006 activo. Las dos referencias aprobadas añadidas durante la ejecución se conservan íntegramente y se incluyen en el commit documental por instrucción expresa del owner. Backend working tree conserva su estado inicial.

Formato documental: git diff --cached --check detectó espacios finales preexistentes en los insumos aprobados (hard breaks Markdown y YAML). Se preservan íntegros; se normalizó solo whitespace de transcripciones propias .txt, sin cambiar resultados. El chequeo de todos los demás archivos debe pasar. doc-format-check.json identifica la excepción; no se cambia configuración global ni se omiten controles de código.
