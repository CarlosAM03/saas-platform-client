# Trazabilidad de iteración

Los intentos previos no se convirtieron en PASS. Las primeras interrupciones del automatizador se recuperaron por su runId exclusivo y SQL acotado; se registró la causa en hallazgos.

- Baseline unitario:256 PASS. Nuevas regresiones:10 FAIL antes de corregir;19 PASS después.
- Primer P2C:FAIL400 de política de contraseña de alta; fixture corregida; repetición PASS.
- Primeros intentos de navegador: espera por DOM text en lugar de semántica; almacenamiento de sesión anterior; readiness y display X tras reinicio. Fallos del verificador, corregidos sin desactivar TLS ni guards.
- e2e-local-attempt5.json:18 PASS,6 FAIL; cleanup PASS. Casos fallidos identificaron vaciado de campo, selectores CSV y confianza del driver HTTP.
- e2e-local-attempt6.json:25 PASS,2 FAIL y casos nuevos NOT RUN; cleanup PASS. UPDATE usaba una fila NEW en lugar de MATCH; export omitía format obligatorio. Correcciones basadas en código/DTO de Backend main.
- Los JSON posteriores conservan su revisión y alcance. El reporte e2e-local.json solo acredita sus casos efectivamente ejecutados; los anteriores permanecen como evidencia de iteración.

No hay HAR, capturas autenticadas, cuerpos de respuesta de producción ni credenciales en estos artefactos.

- Smoke remoto: los primeros intentos del automatizador no completaron la entrada/selección por cambios de foco y etiquetas semánticas. No demostraron fallo de credenciales ni ausencia de organizaciones. Se corrigió el verificador; la ejecución final registró siete resultados PASS y17 respuestas, con logoutHTTP200 y recarga. Las salidas brutas se excluyeron por privacidad; no se registraron credenciales ni datos de negocio.
- Cierre local: e2e-local.json y e2e-repeat.json acreditan32/32 PASS en cada corrida, cleanup PASS y fuente7b5320c. El caso Dashboard poblado detectado en el intento7 se corrigió y quedó cubierto por regresión y SQL.
