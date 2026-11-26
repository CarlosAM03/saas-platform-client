# Inventario final de Git y artefactos

FechaUTC:2026-10-28T00:33:57.497Z. Fuente detallada:evidencias/local-final-inventory.json y estados PR/GitHub.

| Checkout | Rama/estado | HEAD |
|---|---|---|
|original-backend|feat/prospector-service-mvp-integration; limpio|a80871b6c5ebf39b4fca69eaf5f6352ab342da96|
|original-flutter|feat/flutter-prospector-mvp-parity; cambios locales preexistentes|97ad02a621007e4139e5207511ecca2376754ed8|
|original-service|feat/fastapi-service-foundation; limpio|69c54a15601d238638610d0a5c08af46e3da7f14|
|original-engine|main; limpio|70f6081688db5c5bc5ea612f5fabd5724aab0b20|
|backend-core|fix/avance2-core-security; limpio|69c73365f0547e994f57cad7fb83269023db4b8e|
|flutter-core|release/avance2-frontend-v1; limpio|41a16dd462c2bbe6c892bf2c5669975ca70cb752|
|backend-dev|detached; limpio|09593bb715cd83270821d34126a4344c8ef97cb0|
|flutter-dev|detached; limpio|cd527ef12bc7c1327ed9a8520e1a07f0fc8be39f|
|backend-experimental|demo/avance2-controlled-110; limpio|45df09aebae4ad0a8ec32334894b4d21f81f9272|
|flutter-experimental|demo/avance2-controlled-110; limpio|67d90451fccfa7dccfb88ca0547cca015da51d47|
|service-experimental|demo/avance2-controlled-110; limpio|ad7bec3d7a1212f1bb2e0a808ffea3c42d5aed30|

El original Flutter conserva únicamente el estado documental previo: Plan de Trabajo.md eliminado localmente y documentos Avance1/Avance2 sin tracking. SHA256 del plan rector:df1552887869b3a79d87034b135022c2df265c399ce4c777a654601b5e445f09; Avance1:afdbf821b98f5040d569aec44662f8414f32e4f55eb9fe44a7ebdb8e4a4fdb00. Los otros originales siguen limpios y en sus HEAD iniciales.

| PR | Destino | Estado real |
|---|---|---|
| Backend#7 |dev |Fusionado por Codex bajoG4 después de CI |
| Backend#8 |dev |Corrección de bootstrap fusionada por Codex bajoG4 después de CI |
| Flutter#9 |dev |Foundation core fusionado por Codex bajoG4 después de CI |
| Backend#9 |main |Fusionado manualmente por CarlosAM03; mainb51b265f1a545fa915f1dd1c57ef2f5858ec6492 |
| Flutter#6 histórico |main |Fusionado manualmente por CarlosAM03; main7731649a2c69b45cb9776d02de4a6105d6fd9886 |

Se preserva la separación de P2 (Backend PR#6/Flutter PR#8 no incorporados al core). Foundation se incorporó por ancestry desde su base exacta, sin cherry-pick masivo P2. No hubo force-push, reset-hard ni reescritura de historia. Las tres ramas demo/avance2-controlled-110 son locales y no se publicaron.

Los main del owner tienen el mismo árbol que los candidatos dev validados. Las ramas locales main de los checkouts originales no se cambiaron por Codex. No se creó tag de release por inferencia.

## IDs locales de imágenes

| Tag | Identificador Docker final | Usuario Config |
|---|---|---|
|prospector-avance2-backend:core|sha256:3ed1d27996e32a0b98f0af0b5864fd51bbe8b800c240461e8d50e60c38111972|node|
|prospector-avance2-flutter:core-local|sha256:d6deecc8c29c3128bbb67d18bc7be295c3ed0910aeb4f0510d4c636a806135d0|default de imagen|
|prospector-avance2-flutter:release-candidate|sha256:527c22d5a3c8fc04c6ef70ff846416b8d5c8d68a7a24212bd2c8c074e792189b|default de imagen|
|prospector-avance2-backend:experimental|sha256:f95d9b119308a711f00c8408c4bd961c38b8925c0e0267ade1e33aafc9b30918|node|
|prospector-avance2-flutter:experimental|sha256:2e3f13d12f1e0c1a0dea501ab03aebe598750cc210e17ef8afccfb39e1e52ed5|default de imagen|
|prospector-avance2-service:controlled|sha256:dc243f98f97b833457f181cab8b47d7bdf0d6c0a23fbd256a3e79f81d9d7b79f|10001:10001|
|prospector-avance2-browser:trusted-local|sha256:1131160054b2f04c0788e65ef1b24594776a7c21f65b1dea109501524deb46db|default de imagen|
|postgres:16|sha256:ca0bd484cb98bf4b24eb1010e73fb3fcbd6714d240fbc1a10eea5b7dbecb641d|default de imagen|
|nginx:1.28.0-alpine|sha256:30f1c0d78e0ad60901648be663a710bdadf19e4c10ac6782c235200619158284|default de imagen|

Son identificadores reportados por Docker local; no equivalen a publicación en un registry. Las reconstrucciones pueden variar atestación/ID conservando contenido. El inventario también registra el imageId efectivo de cada contenedor. Fuente core:Backenddev09593bb/Flutterdevcd527ef; fuente B:los3SHA anteriores y Engine70f6081. Bundle productivo exacto:3b5d2f49234e9a5486f235cb3a3b8d551befcb880e37854352ddf4dadb4c1578.

Estado final de PR relacionados: Backend#6 continúa draft/open sin fusionar; Flutter#8 continúa draft/open sin fusionar. Foundation#7 figura closed/merged por incorporación de su ancestry al integrar#9; no se promovió P2. Fuente: pr-foundation-experimental-state.json.
