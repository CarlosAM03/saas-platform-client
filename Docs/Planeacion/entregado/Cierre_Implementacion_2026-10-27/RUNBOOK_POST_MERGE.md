# Verificación posterior al merge — solo lectura

El owner ya fusionó Backend PR#9 y Flutter PR#6 durante la ejecución. Nuevos main:b51b265f1a545fa915f1dd1c57ef2f5858ec6492 y7731649a2c69b45cb9776d02de4a6105d6fd9886. Codex únicamente consulta estado posterior.

~~~powershell
& 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\00-Docs\Analisis\Cierre_Avance_2_Fase_0_2026-10-27\Cierre_Implementacion_2026-10-27\scripts\Verify-PostMerge.ps1' -FrontendUrl 'https://saas-platform-client-web.vercel.app' -ExpectedBundleSha256 '3b5d2f49234e9a5486f235cb3a3b8d551befcb880e37854352ddf4dadb4c1578'
~~~

El script consulta GET de GitHub/main/checks/runs/deployments, compara árboles con candidatos dev; GET de health/Swagger1.0.0/frontend/bundle y OPTIONS CORS. No crea datos, no inicia sesión demo, no cambia configuración, no ejecuta migraciones ni seeds. Si falla un endpoint guarda informe parcial. El resultado actual está en evidencias/post-merge-verification.json.

La opción -AuthenticatedSmoke solicita un JWT productivo autorizado en entrada privada y hace únicamente GET auth/me/campaigns/prospects/jobs. No usar credenciales demo en producción, no pegar tokens en chat ni incluirlos en logs. Este smoke autenticado no se ejecutó por inferencia.

Atestación: un health200 o Swagger1.0.0 no acredita el SHA Render. Conservar Deployment ID, SHA y URL efectiva del proveedor. Vercel se contrasta con despliegues GitHub environmentProduction y el SHA de main; un preview aislado no acredita Production Branch. Las comprobaciones observadas y cualquier limitación están en REGISTRO_CI.md y DICTAMEN_GLOBAL.md.

Preflight aprobado para nuevo Backend: JWT_SECRET robusto≥32 sin valores ejemplo ni espacios, JWT_EXPIRES_IN8h, CORS_ORIGINS HTTPS explícitos y sin claves Service; comprobar metadatos por proveedor sin publicar valores. No se modificaron secretos de Render/Vercel ni Supabase. Si falla despliegue por configuración, la corrección requiere la autorización reservada al owner.

Orden aplicado por owner: Backend primero y después Flutter. Rollback preparado, no ejecutado: restaurar revisión frontend verificada anterior si es necesario y mantener Backend con SEC-01. Retroceder Backend a3a33093 reintroduce el problema de identidad global y exige reevaluación expresa; no hacerlo automáticamente. Ningún rollback debe resetear PostgreSQL. Datos productivos se preparan en actividad futura autorizada.
