# Validación Flutter / Dockerfile.vercel

FechaUTC:2026-10-28T00:23:34.968Z. Fuente dev:cd527ef12bc7c1327ed9a8520e1a07f0fc8be39f; Foundation095e899ace31acf17d97bbe945c118c1a5d88682. Main posterior del owner7731649a2c69b45cb9776d02de4a6105d6fd9886.

Se utilizó el Dockerfile.vercel real, Flutter3.47.5 con checksum fijado, build_runner, releaseJavaScript y Nginx1.28.0. Markers/analyze y256 pruebas del integrado pasaron. Se preservaron UI/UX de André, tema/assets/Inter/layouts y Foundation tipada; no se introdujo PR#8 ni capacidades Prospector1.1.0.

Se probaron dos variantes del mismo código: imagen funcional con API_BASE_URL=https://localhost:18443, y release-candidate con el HTTPS público predeterminado del Dockerfile. La primera recorrió navegador→gatewayTLS→NestJS→PostgreSQL reales con ADMIN/OWNER A/MEMBER A/OWNER B/MEMBER B, cambio de organización, logout, rutas protegidas, CSV y dashboard. La segunda arrancó con red Docker deshabilitada y pasó índice/SPA/ausencia de SDK, sin contactar producción.

El bundle productivo SHA2563b5d2f49234e9a5486f235cb3a3b8d551befcb880e37854352ddf4dadb4c1578 no contiene secretos locales ni URLs loopback y contiene el origen Render esperado. Los IDs locales de ambas imágenes están en local-final-inventory.json; las imágenes con localhost nunca se promueven a hosting.

El panel DEMO — SIN EJECUCIÓN REAL importa solo presentación Material y mantiene su etiqueta en todos sus estados, sin SDK/red/mutaciones. Jobs son GET reales con nullables del baseline; crear/cancelar/guardar/exportar siguen cuatro flagsfalse.

TLS se valida con CA local en un navegador contenedor y NSS propio, ignore_https_errors=false. No se cambió la confianza del host ni se desactivó validación. Acceso de pruebas: http://127.0.0.1:18450/vnc.html?autoconnect=1&resize=scale. API/Swagger directos en18441; origen HTTPS18443 dentro del navegador aislado.

La compilación emitió advertencias heredadas del analyzer generado y fuente Cupertino no incluida; analyze/test/build aprobaron y las pantallas revisadas usan Material/Inter sin defecto visual observado. No se hizo actualización general para silenciarlas. El intento Windows pub get resolvió paquetes pero requirió Developer Mode para symlinks; se usó el SDK Linux del Dockerfile sin cambiar el host.

CI exacto dev40603614993 y checkVercel del mismo SHA en verde. Preview verde no equivale a prueba autenticada productiva. Los merges manuales del owner y las comprobaciones públicas posteriores se documentan separadamente.
