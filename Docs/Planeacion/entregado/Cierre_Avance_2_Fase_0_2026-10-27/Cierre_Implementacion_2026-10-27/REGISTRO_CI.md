# Registro de CI y publicación

FechaUTC:2026-10-28T00:33:57.497Z. Se consultaron jobs reales, sin reutilizar un verde de una rama anterior como certificación del integrado.

| Etapa | SHA | Run | Jobs |
|---|---|---|---|
|backend-source-pr|78d076d3d367a7789f41f5f29c581f5cf28b88fc|[40602592022](https://github.com/CarlosAM03/saas-platform-backend/actions/runs/40602592022)|quality:success, postgres-integration:success, docker-build:success|
|backend-tooling-pr|69c73365f0547e994f57cad7fb83269023db4b8e|[40603593884](https://github.com/CarlosAM03/saas-platform-backend/actions/runs/40603593884)|docker-build:success, postgres-integration:success, quality:success|
|backend-dev|09593bb715cd83270821d34126a4344c8ef97cb0|[40604081978](https://github.com/CarlosAM03/saas-platform-backend/actions/runs/40604081978)|postgres-integration:success, quality:success, docker-build:success|
|backend-main-owner|b51b265f1a545fa915f1dd1c57ef2f5858ec6492|[40606722665](https://github.com/CarlosAM03/saas-platform-backend/actions/runs/40606722665)|quality:success, docker-build:success, postgres-integration:success|
|flutter-source-pr|41a16dd462c2bbe6c892bf2c5669975ca70cb752|[40602606524](https://github.com/CarlosAM03/saas-platform-client/actions/runs/40602606524)|foundation:success, container:success, production-container:success|
|flutter-dev|cd527ef12bc7c1327ed9a8520e1a07f0fc8be39f|[40603614993](https://github.com/CarlosAM03/saas-platform-client/actions/runs/40603614993)|foundation:success, container:success, production-container:success|
|flutter-main-owner|7731649a2c69b45cb9776d02de4a6105d6fd9886|[40607324970](https://github.com/CarlosAM03/saas-platform-client/actions/runs/40607324970)|container:success, production-container:success, foundation:success|

Fuente normalizada:evidencias/ci-cierre.json. Los main del owner pasan los mismos tres checks requeridos. Las protecciones no se modificaron ni se omitieron revisiones obligatorias; dev no exigía aprobación adicional.

Vercel source41a16dd y devcd527ef tuvieron checksuccess. Tras merge del owner, main7731649 tiene checkVercelsuccess con referencia de proveedor7HmfhjKpxRoDvK1Tu3XdD5oGA4wF y deploymentGitHub7373752531, environmentProduction, success. URL efectiva observada:https://saas-platform-client-7ilcy9dnx-carlos-armentas-projects.vercel.app; aliashttps://saas-platform-client-web.vercel.app. Se observa así la cadena main→Production, sin cambiar Production Branch ni configuración. El bundle público del alias coincide byte a byte con el candidato validado y no tiene loopback.

Render responde200 en live/ready/Swagger1.0.0 y CORS204 permite el alias Vercel. No publica en GitHub un Deployment ID/SHA de proveedor verificable con las fuentes conectadas. El owner confirmó los enlaces a commits main y el origen Render; esos enlaces acreditan GitHub, no el binario Live de Render. Esta atestación permanece pendiente.

El owner aportó captura de sesión/dashboard productivo de ACME CORPORATION (1 campaña/1 prospecto/0 jobs), registrada como smoke manual básico. No acredita por sí sola matriz completa de permisos/CSV productiva ni revisión Live Render. El smoke autenticado automático de producción no se ejecutó sin un token autorizado.

post-merge-verification.json contiene las comprobaciones de lectura; public-bundle-raw.json confirma hash binario y public-openapi-parity.json confirma33 operaciones públicas. El primer hash PowerShell se calculó sobre texto decodificado y fue falso diferente; se corrigió a bytes HTTP y se conservó el intento inicial. No se modificó la aplicación para hacer pasar esta comprobación.
