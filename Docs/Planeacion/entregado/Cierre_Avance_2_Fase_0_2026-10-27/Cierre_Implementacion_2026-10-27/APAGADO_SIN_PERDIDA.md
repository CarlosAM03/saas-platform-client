# Apagado sin pérdida

Ambos stacks quedan en ejecución para el owner. Estos comandos detienen solo proyectos propios y conservan volúmenes.

~~~powershell
Set-Location 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\backend-core'
docker compose -p prospector-avance2-core --env-file ../.local-avance2/core.env -f ops/avance2/compose.core.yml stop
Set-Location 'C:\Users\Carl0\Desktop\ProyectosPersonales\DesarrolloDeSoftwareConComputoEnLaNube\PlataformaDeProspeccionAutomatizadaYGestionDeCampañasDeMarketing\DocumentacionGlobal\WorktreesAvance2\service-experimental'
docker compose -p prospector-demo-110 --env-file ../.local-avance2/experimental.env -f demo/avance2/compose.demo.yml --profile controlled stop
~~~

Reiniciar core con Start-Core.ps1 -SkipBuild. Para pérdida/reinicio del worker experimental usar Restart-Demo.ps1: verifica propiedad y rota generación local, conserva PostgreSQL y marca trabajos activos anteriores FAILED; requiere una nueva solicitud expresa para ejecutar otro caso. No existe recuperación durable del worker.

Volúmenes: prospector-avance2-core_core-pg/core-tls y prospector-demo-110_demo-pg/demo-tls, etiquetados con propietario exclusivo. No se utilizó down-v, prune ni limpieza global. No se detuvieron proyectos ajenos ni la aplicación local previa18420. El contenedor adicional release-smoke no tiene red ni volúmenes y sirve solo evidencia técnica; puede detenerse por su nombre.
