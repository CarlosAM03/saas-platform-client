# CT-03 · Reconciliación para autorización del propietario

Referencias actualizadas desde GitHub el 25 de noviembre de 2026.

| Referencia | SHA observado | Situación |
| --- | --- | --- |
| `origin/main` | `e752f6ca692d2840263cd9e59e0927c56aa129ec` | Base del PR #11 |
| `origin/dev` | `2fdba28bf394d8a103b4f61deba98cd37061b2cd` | Base común `cd527ef12bc7c1327ed9a8520e1a07f0fc8be39f` |
| `origin/feat/tenant-register` | `0fe5d368e11b1da745ccf42ead3892470dcae0be` | Head del PR #11 y base inicial del #12 |
| `origin/feat/sprint-campana-prospector` | `2ae32ab391d159b13b513b44b8240204d97b2f57` | Head CP usado como entrada en la simulación |
| `origin/UI/UX` | `28e0ec7bc42fa8a37a840e09b5d38a8f4b9dd527` | Entrada visual original, con `f1b6cbf` de CP como ancestro |
| Backend `dev` | `f231c8d820fe89849f74b10bde279a9fd53108ad` | Referencia de integración consultada en GitHub |
| Backend contractual CP | `779fc7885faefdfe9e3cb0f3fee86810d96d2711` | Fuente del laboratorio T32 y del suplemento aprobado |

El checkout principal se identificó por su directorio Git común y su remoto origin. Los tres worktrees de Flutter pertenecen a Core, al ensayo desprendido de dev y a la demo experimental. El checkout empezó limpio en `feat/tenant-register`. La rama local `main` estaba 44 commits detrás de origin y `dev` coincidía con origin. La simulación utiliza las referencias remotas.

## Simulación

Se utilizó `git merge-tree --write-tree` y se crearon objetos temporales con `git commit-tree` para conservar la ascendencia en las etapas siguientes. Los SHA de árbol son reproducibles con las mismas entradas. Los objetos de commit de simulación pueden tener otro SHA por fecha y autor. Las tres operaciones terminaron sin conflictos.

| Paso | Árbol resultante | Commit temporal local |
| --- | --- | --- |
| #11 como merge commit a main | `a946c8df14850f370f3211c248d3df99d5db6a74` | `6e11146dffa45293253d54168a9c0dcae46af052` |
| #12 retarget a main y merge commit | `b00b87f9a6ad2464ae07e748f922c8596c3ef70d` | `0be441afa56654cbb41f661e07b37695ea0e6749` |
| Merge documental de dev hacia main | `135824d0eb588361289cb4a0a0bb251b3e32a2b8` | `f38a25d7e27b73a3e538d523805c55ff1ee87619` |

El árbol del paso #12 coincide con el árbol CP probado en la simulación. Los dos commits exclusivos de dev, `0b40f1f048ea71ab8f3fddf1f7306e82c977ca6e` y `2fdba28bf394d8a103b4f61deba98cd37061b2cd`, producen 147 cambios netos bajo `Docs/` desde la base común. El diff bruto sin renombres coincide entrada por entrada con el aplicado en el paso final, incluidos modo, ruta y SHA de blob. Las evidencias CP, el código, las pruebas, los arneses y las dependencias coinciden con CP después del merge documental. Los cuatro heads de entrada y el primer commit documental son ancestros del resultado. El avance rápido de dev hacia ese resultado es posible.

## Ejecución posterior

1. Esperar autorización del propietario. Hacer fetch, confirmar los heads, volver a simular si hay cambios y verificar los tres jobs de los PR por head exacto. Revisar la política del repositorio y la automatización de despliegue antes de cambiar una rama de integración.
2. Fusionar #11 en `main` con **Create a merge commit**. Verificar que el head revisado de registro sea ancestro de `origin/main`.
3. Retarget del #12 de `feat/tenant-register` a `main`. Revisar el diff CP y la nueva ejecución CI contra main. Fusionar con **Create a merge commit**, usando el head CP aprobado.
4. Conservar la historia documental mediante un PR de `dev` a `main` con merge commit. Si una protección exige actualizar la rama fuente, preparar un carril temporal a partir del SHA documental autorizado y simular nuevamente con la misma ascendencia. Verificar el árbol y que ambos commits documentales sean ancestros de main.
5. Después de validar main, avanzar `dev` por fast-forward al SHA final de main conforme a las protecciones vigentes. Confirmar igualdad de SHA y árbol. Actualizar las ramas locales desde origin conforme al procedimiento normal del repositorio.
6. Mantener el PR visual independiente durante esta secuencia. Su integración requiere la aceptación visual y autorización posterior del propietario. Dejar el PR histórico #8 fuera de esta secuencia.
