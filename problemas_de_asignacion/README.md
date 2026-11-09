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
| 4. Estrategias | `src/estrategias/` | cómo se busca la solución: genético y búsqueda local | **completada** |
| 5. Orquestación | `src/orquestacion/` | qué se genera, en qué orden y dónde, y su ejecución | **completada** |

Las carpetas se crean en la etapa que las llena.

## Etapa 5: la orquestación

`generar.lisp` es la única entrada. Genera lo que se nombra y, si se pide, lo ejecuta; lo que no se nombra va entero. Se ejecuta desde `problemas_de_asignacion/`:

```bash
sbcl --script generar.lisp                                             # todo
sbcl --script generar.lisp saul --destinos matematica
sbcl --script generar.lisp seder --estrategias genetico --ejecutar --semillas 0 1 2
sbcl --script generar.lisp --archivo ejecuciones/seder.lisp            # un pedido guardado
```

Cada destino queda en su carpeta, y los avisos del análisis se imprimen y se guardan:

```
salida/<dominio>/
├── avisos.txt
├── python/          modelo.py, genetico.py, busqueda_local.py y corridas/
├── matematica/      modelo.tex
└── verbalizador/    descripcion.md
```

Las opciones, el formato de un archivo de `ejecuciones/` y los argumentos de cada estrategia están en [`ejecuciones/README.md`](ejecuciones/README.md). La implementación está en [`plan-etapa-5.md`](plan-etapa-5.md).

## Etapa 4: las estrategias

`generar.lisp` escribe también, en `salida/<dominio>/python/`, un programa por estrategia que importa `modelo.py`:

| Archivo | Qué es | Sale de |
|---|---|---|
| `genetico.py` | Algoritmo genético | `src/estrategias/genetico/` |
| `busqueda_local.py` | Búsqueda local | `src/estrategias/busqueda-local/` |

Se ejecutan con `--ejecutar` (etapa 5) o a mano desde su carpeta, con una semilla obligatoria:

```bash
cd salida/seder/python
python genetico.py --semilla 0
```

Cada corrida guarda un JSON en `corridas/`. La misma semilla con los mismos argumentos da el mismo resultado. Qué es cada argumento y su valor por defecto está en [`ejecuciones/README.md`](ejecuciones/README.md).

Los criterios de la etapa y el costo en minutos de corridas más grandes se miden aparte, porque tarda unos 40 minutos:

```bash
python pruebas/estrategias/rendimiento.py
```

La implementación está en [`plan-etapa-4.md`](plan-etapa-4.md).

## Etapa 3: la emisión

Genera los tres archivos de cada dominio, incluida la prosa del verbalizador. Se ejecuta desde `problemas_de_asignacion/`:

```bash
sbcl --script generar.lisp
```

Los dominios son `tv`, `tesis`, `docentes`, `seder` y `saul`. La salida queda en `salida/<dominio>/<destino>/`, y cada ejecución sobrescribe lo generado:

| Archivo | Qué es | Sale de |
|---|---|---|
| `modelo.py` | Datos, consultas, restricciones y `evaluar`, sin búsqueda | `src/emision/python/` |
| `modelo.tex` | El modelo matemático, para `\input` en un documento con `amsmath` | `src/emision/matematica/` |
| `descripcion.md` | La descripción en español, del verbalizador | `src/emision/verbalizador/` |
| `genetico.py` y `busqueda_local.py` | Las estrategias, descritas en la etapa 4 | `src/estrategias/` |

Para revisar la prosa, abre `salida/<dominio>/verbalizador/descripcion.md`.

Desde Lisp, lo mismo para un dominio:

```lisp
(let ((ruta "dominios/saul/dominio.lisp"))
  (orquestacion:exportar (analisis:construir-modelo (orquestacion:cargar-dominio ruta))
                         "salida/saul/"
                         :anotaciones (orquestacion:cargar-anotaciones ruta)))
```

Las pruebas ejecutan el Python generado, así que hace falta `python` en el `PATH`.

La implementación está en [`plan-etapa-3.md`](plan-etapa-3.md).

## Etapa 2: el análisis

`construir-modelo` convierte un problema en el modelo que leerán los destinos: la forma de cada restricción, la familia de cada consulta, sus decisiones, el orden de las entidades y los avisos.

```lisp
(analisis:construir-modelo (orquestacion:cargar-dominio "dominios/tv/dominio.lisp"))
```

Lo que no tiene sentido, como comparar un día con un número, se rechaza con `error-dsl`. Lo dudoso queda en `modelo-avisos`, que `generar.lisp` imprime y guarda en `salida/<dominio>/avisos.txt`.

La implementación está en [`plan-etapa-2.md`](plan-etapa-2.md).

## Etapa 1: el DSL

Los dominios están en `dominios/<dominio>/dominio.lisp` y solo describen el problema. Las pruebas comparan los cinco dominios con su referencia. Qué comprueba cada archivo está en [`pruebas/README.md`](pruebas/README.md):

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

`pruebas/referencia/<dominio>/` guarda lo que produjo el sistema viejo, para comprobar que la versión nueva calcula lo mismo:

| Archivo | Qué es |
|---|---|
| `dominio.lisp` | la fuente que produjo la referencia, congelada |
| `valores.json` | diez horarios con semilla fija, como índices, y el valor de cada restricción |

`pruebas/factibles/<dominio>.json` guarda un horario sin incumplimientos duros de tesis, tv y SEDER.

Lo que la reimplementación cambia a propósito está en [`pruebas/referencia/diferencias-esperadas.md`](pruebas/referencia/diferencias-esperadas.md). Cualquier otra diferencia es un error.

Las herramientas que capturaron estos datos, y los `horario.py`, `modelo.txt` y `descripcion.md` del sistema viejo, se quitaron al cerrar la etapa 5. El sistema viejo sigue en `restrictions_language-main/` si hubiera que rehacerlos.

## Decisiones tomadas

| ID | Decisión |
|---|---|
| D0.1 | La carpeta se llama `problemas_de_asignacion/`. |
| D0.2 | `restrictions_language-main/` queda en local, sin versionar, y no se modifica. |
| D0.3 | Los documentos de la tesis se colocan a mano; el plan no los mueve. |
| D0.4 | Variables, funciones y carpetas en español. |
| D0.5 | Archivos en UTF-8 sin BOM. |
| D0.6 | Docentes y Saúl no se ejecutan para la referencia. Revisada en D3.8: evaluar era barato, y se capturan sus valores. |
