# problemas_de_asignacion

Reimplementación por capas del DSL de problemas de asignación con restricciones y de su generador de código. Sustituye a `restrictions_language-main/` y a `verbalizador/`, que siguen en local como referencia de solo lectura y no se modifican.

- **Qué se corrige:** [`deficiencias-por-capa.md`](../deficiencias-por-capa.md)
- **Cómo y en qué orden:** [`plan-reimplementacion.md`](../plan-reimplementacion.md)

## Capas

| Capa | Carpeta | Qué hace | Estado |
|---|---|---|---|
| 1. DSL | `src/dsl/` | el lenguaje que escribe el usuario | **completada** |
| 2. Análisis | `src/analisis/` | el modelo intermedio que leen todos los backends | **completada** |
| 3. Emisión | `src/emision/` | un destino por lenguaje: Python, LaTeX y prosa en español | **completada** |
| 4. Estrategias | `src/estrategias/` | cómo se busca la solución | pendiente |
| 5. Orquestación | `src/orquestacion/` | qué se genera, en qué orden y dónde | pendiente |

Las carpetas se crean en la etapa que las llena.

## Etapa 3: la emisión

Genera los tres archivos de cada dominio, incluida la prosa del verbalizador. Se ejecuta desde `problemas_de_asignacion/`:

```bash
sbcl --script generar.lisp
```

Para generar solo algunos dominios, se nombran:

```bash
sbcl --script generar.lisp saul tesis
```

Los dominios son `tv`, `tesis`, `docentes`, `seder` y `saul`. La salida queda en `salida/<dominio>/`, que git ignora, y cada ejecución sobrescribe la anterior:

| Archivo | Qué es | Sale de |
|---|---|---|
| `modelo.py` | Datos, consultas, restricciones y `evaluar`, sin búsqueda | `src/emision/python/` |
| `modelo.tex` | El modelo matemático, para `\input` en un documento con `amsmath` | `src/emision/matematica/` |
| `descripcion.md` | La descripción en español, del verbalizador | `src/emision/verbalizador/` |

Para revisar la prosa, abre `salida/<dominio>/descripcion.md`. La referencia con la que se compara es `pruebas/referencia/<dominio>/descripcion.md`, y las diferencias previstas están en [`diferencias-esperadas.md`](pruebas/referencia/diferencias-esperadas.md).

Desde Lisp, lo mismo para un dominio:

```lisp
(let ((ruta "dominios/saul/dominio.lisp"))
  (orquestacion:exportar (analisis:construir-modelo (orquestacion:cargar-dominio ruta))
                         "salida/saul/"
                         (orquestacion:cargar-anotaciones ruta)))
```

Las pruebas ejecutan el Python generado, así que hace falta `python` en el `PATH`. El LaTeX se compila si hay `pdflatex`, en el `PATH` o en la variable `PDFLATEX`; si no, se avisa y no falla.

La implementación está en [`plan-etapa-3.md`](plan-etapa-3.md).

## Etapa 2: el análisis

`construir-modelo` convierte un problema en el modelo que leerán los destinos: la forma de cada restricción, la familia de cada consulta, sus decisiones, el orden de las entidades y los avisos.

```lisp
(analisis:construir-modelo (orquestacion:cargar-dominio "dominios/tv/dominio.lisp"))
```

Lo que no tiene sentido, como comparar un día con un número, se rechaza con `error-dsl`. Lo dudoso queda en `modelo-avisos`. Todavía nadie llama al análisis al cargar un dominio ni muestra los avisos: eso llega en la etapa 5.

La implementación está en [`plan-etapa-2.md`](plan-etapa-2.md).

## Etapa 1: el DSL

Los dominios están en `dominios/<dominio>/dominio.lisp` y solo describen el problema. Las pruebas comprueban cada entrada mal formada y comparan los cinco dominios con su referencia:

```bash
sbcl --script pruebas/correr.lisp
```

Para cargar un dominio desde Lisp:

```lisp
(require :asdf)
(asdf:load-asd (truename "problemas_de_asignacion.asd"))
(asdf:load-system "problemas_de_asignacion")
(orquestacion:cargar-dominio "dominios/tv/dominio.lisp")
```

`cargar-dominio` crea el paquete `DOMINIO-TV` y devuelve el objeto `problema`. La salida se genera con `exportar`, descrito en la etapa 3.

Las decisiones están en [`decisiones-reimplementacion.md`](decisiones-reimplementacion.md), y la lógica de cada archivo en [`estructura.md`](estructura.md).

## Etapa 0: la referencia

`pruebas/referencia/<dominio>/` guarda lo que produce el sistema viejo, para comprobar que la versión nueva dice lo mismo:

| Archivo | Qué es | Dominios |
|---|---|---|
| `dominio.lisp` | la fuente que produjo la referencia | los cinco |
| `horario.py` | el Python generado | los cinco |
| `descripcion.md` | la prosa del verbalizador | los cinco |
| `modelo.txt` | lo que imprime `mostrar_modelo()` | tesis, tv, SEDER |
| `valores.json` | diez horarios con semilla fija, como índices, y el valor de cada restricción | tesis, tv, SEDER |

`pruebas/factibles/<dominio>.json` guarda un horario sin incumplimientos duros por dominio: tesis, tv y SEDER.

Docentes y Saúl se capturan sin ejecutar el genético (D3.8), y no tienen horario factible.

Lo que la reimplementación cambia a propósito está en [`pruebas/referencia/diferencias-esperadas.md`](pruebas/referencia/diferencias-esperadas.md). Cualquier otra diferencia es un error.

### Regenerar la referencia

```bash
cd pruebas/referencia && python capturar.py tesis tv seder
cd pruebas/factibles && python buscar.py tesis tv seder
```

`capturar.py` tarda unos segundos. `buscar.py` tarda minuto y medio, sobre todo por tesis.

## Decisiones tomadas

| ID | Decisión |
|---|---|
| D0.1 | La carpeta se llama `problemas_de_asignacion/`. |
| D0.2 | `restrictions_language-main/` queda en local, sin versionar, y no se modifica. |
| D0.3 | Los documentos de la tesis se colocan a mano; el plan no los mueve. |
| D0.4 | Variables, funciones y carpetas en español. |
| D0.5 | Archivos en UTF-8 sin BOM. |
| D0.6 | Docentes y Saúl no se ejecutan para la referencia. Revisada en D3.8: evaluar era barato, y se capturan sus valores. |
