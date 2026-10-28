# CI y builds

Fecha: 2026-10-28, America/Tijuana. Rama feat/tenant-register.
Comandos/exit/duración/SHA: baseline-commands.jsonl, final-commands.jsonl,
container-commands.jsonl. Flutter3.47.5/Dart3.13.4, Docker29.9.2.

Esperado: generación/análisis/tests/build y tres jobs en HEAD; pruebas locales
que CI no ejecuta deben quedar separadas.

| Fuente | SHA / resultado | Estado |
|---|---|---|
| Baseline local |9c0e556:312 PASS+1 skip, analyze/build/pub/generation exit0 | PASS |
| Hardening local |919ce03:317 PASS+1 skip, ADR00638 PASS+1 skip, analyze/build exit0 | PASS |
| Bootstrap Node |4 pruebas PASS | PASS |
| CI37 |a09c117: container/production-container PASS; foundation FAIL por fixture ## | FAIL histórico |
| CI38 |919ce033f76a0f04aebe9dc2bed4c159d6fb86ca: foundation/container/production-container success | PASS |
| Imagen Web QA acelerada |a09c117, Dockerfile.e2e y SDK verificado | PASS build |
| Compose config local |exit0 | PASS |
| Dockerfile.dev y Dockerfile.vercel locales |Engine500/502/_ping; sin finalización válida | BLOCKED |

CI38: https://github.com/CarlosAM03/saas-platform-client/actions/runs/40780400050
CI37: https://github.com/CarlosAM03/saas-platform-client/actions/runs/40779371150
GitHub confirmó Chrome real, los cuatro tests Node,317 tests, analyze y build en38.
La suite pesada UI→PostgreSQL no está en ese pipeline.

Se añadieron dos pasos sin nueva dependencia: Node builtin y el test Flutter Chrome
ya existente. No credenciales, costos externos ni cambios de los tres jobs.
El contrato Core, lockfile y SDK fijado se conservaron.

Docker/WSL se deterioró durante builds locales; se registraron500/502 y disco
ocupado. El reinicio fue autorizado por el owner cuando Backend estaba inactivo,
y luego se autorizó reinicio WSL. No se borraron discos/volúmenes/cachés globales.
Hay aproximadamente2GB libres en C:; no se atribuye causalidad sin prueba adicional.

CI_FINAL al cierre documental aún requiere verificar el commit que contenga las
evidencias y tooling. No atribuir los checks919ce03 a un HEAD nuevo sin consultarlo.
