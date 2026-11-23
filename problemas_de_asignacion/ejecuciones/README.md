# Cómo se genera y se ejecuta

Todo pasa por `generar.lisp`, desde la carpeta `problemas_de_asignacion/`. Lo que no se nombra va entero.

```bash
sbcl --script generar.lisp                         # los cinco dominios, los tres destinos y las cuatro estrategias
sbcl --script generar.lisp saul tv                 # solo esos dominios
sbcl --script generar.lisp saul --destinos matematica verbalizador
sbcl --script generar.lisp seder --estrategias genetico --ejecutar --semillas 0 1 2
sbcl --script generar.lisp --archivo ejecuciones/seder.lisp
```

| Opción | Qué hace |
|---|---|
| dominios, antes de la primera opción | Las carpetas de `dominios/` que se generan. |
| `--destinos` | `python`, `matematica`, `verbalizador`. |
| `--estrategias` | `genetico`, `busqueda-local`, `goloso`, `reparacion-tabu`. Sin nombrarlas van todas, pero solo si se genera `python`. Nombrar una trae `python` aunque no se pida, porque su programa importa `modelo.py`. Solo se escriben y se ejecutan las que se nombran: los programas de las demás no se tocan. |
| `--ejecutar` | Además de generar, ejecuta cada estrategia con cada semilla, una tras otra. Sin esta opción solo se genera. |
| `--semillas` | Las semillas de las corridas. Si no se nombra ninguna, se usa la 0. |
| `--archivo` | Lee el pedido de un archivo. Va sola: no se mezcla con las demás opciones. |

Los nombres son los de las clases. Uno que no existe da un error con la lista de los que hay, y no se genera nada. Si un dominio falla, se informa y se sigue con los demás. El proceso termina con código 1 si el pedido está mal escrito o si falló algún dominio o alguna corrida.

## Archivos de ejecución

Un archivo de esta carpeta guarda un pedido para repetirlo igual. Es una lista de Lisp que se lee sin evaluar nada, con un solo dominio:

```lisp
(:dominio "seder"
 :destinos (python)
 :estrategias ((genetico :generaciones 100)
               (busqueda-local :tiempo 30))
 :semillas (0 1 2)
 :ejecutar t)
```

Las claves son las de la línea de comandos, con `:dominio` obligatorio. Cada estrategia es un nombre o una lista con su nombre y sus parámetros, que son los argumentos de su programa sin `--semilla`. Los parámetros solo valen con `:ejecutar t`, porque se pasan al programa al ejecutarlo: el programa generado tiene siempre los valores por defecto. Un parámetro que la estrategia no tiene da un error antes de generar nada.

## Dónde queda cada cosa

```
salida/<dominio>/
├── avisos.txt                 avisos del análisis, también impresos al generar
├── python/
│   ├── modelo.py
│   ├── genetico.py
│   ├── busqueda_local.py
│   ├── goloso.py
│   ├── reparacion_tabu.py
│   └── corridas/              un JSON por corrida
├── matematica/modelo.tex
└── verbalizador/descripcion.md
```

Al regenerar se sobrescribe lo generado y no se borra nada más, así que `corridas/` se conserva.

## Ejecutar un programa a mano

Los programas también se pueden ejecutar directamente desde `salida/<dominio>/python/`, porque importan `modelo.py`. Así la semilla es obligatoria:

```bash
cd salida/seder/python
python genetico.py --semilla 0
```

Cada corrida imprime una línea de resumen y la ruta del JSON que guarda en `corridas/`. `python genetico.py --help` lista los argumentos con sus valores por defecto.

## De dónde salen los valores por defecto

De los slots de las clases Lisp: `genetico`, `busqueda-local`, `goloso`, `reparacion-tabu` y sus operadores, en `src/estrategias/`. Para cambiar un valor en una corrida se pasa el argumento; para cambiarlo en todas, se cambia el slot y se vuelve a generar. La misma semilla con los mismos argumentos da siempre el mismo resultado.

## Argumentos del genético y la búsqueda local

| Argumento | Por defecto | Qué es y para qué sirve |
|---|---|---|
| `--semilla` | obligatoria | Semilla del generador de números al azar. Hace la corrida reproducible. |
| `--inicio` | `voraz` | Cómo se arranca. `voraz`: un horario construido fila a fila donde menos prohibiciones incumple, y en el genético el resto de la población con opciones permitidas. `permitidos`: cada fila con una opción al azar entre las que no incumplen ninguna restricción de una sola fila. `aleatorio`: cada fila con cualquier opción, como el sistema viejo. |
| `--penalizacion` | 1000 | Cuánto cuesta cada unidad de las duras frente a las blandas. El costo es `penalización × duras + Σ peso × blandas`. Tiene que ser mayor que lo que pueden sumar las blandas, para que nunca compense incumplir una dura. |
| `--tiempo` | sin límite | Segundos tras los que se detiene. Se comprueba al final de cada iteración, así que la última puede pasarse un poco, y el voraz, si se usa, termina siempre. |

La corrida también se detiene si llega a 0 duras y 0 blandas, o al máximo de iteraciones. El genético no se detiene por estancamiento: en Saúl seguía mejorando después de 100 generaciones sin mejora.

## Argumentos del genético

| Argumento | Por defecto | Qué es y para qué sirve |
|---|---|---|
| `--poblacion` | 100 | Individuos por generación. Más individuos exploran más, y cada generación cuesta proporcionalmente más. |
| `--generaciones` | 500 | Máximo de generaciones. |
| `--cruce` | 0,8 | Probabilidad de cruzar cada pareja de padres. El cruce corta los dos horarios por la misma fila e intercambia el final. |
| `--mutacion` | 0,15 | Probabilidad de mutar cada hijo. |
| `--torneo` | 5 | Cuántos individuos al azar compiten para ser padre: gana el de menor costo. Más grande, más presión hacia los mejores. |
| `--radio` | 2 | Cuántas filas cambia, como mucho, una mutación que mueve: entre 1 y este número, cada una en un campo al azar. Mover dos a la vez permite salir de un horario donde cualquier cambio de una sola fila empeora. |
| `--intercambio` | 0,3 | Probabilidad de que una mutación intercambie las posiciones de dos filas en vez de moverlas. |

El mejor individuo pasa siempre a la generación siguiente.

## Argumentos de la búsqueda local

| Argumento | Por defecto | Qué es y para qué sirve |
|---|---|---|
| `--pasos` | 100000 | Máximo de pasos. En cada paso se elige una fila al azar y se le da la opción permitida de menor costo. |
| `--estancamiento` | 2000 | Cuántos pasos seguidos sin mejorar al mejor detienen la corrida. Solo existe en la búsqueda local, porque sin él sus 100 000 pasos tardarían horas en Saúl. |
| `--ruido` | 0 | Probabilidad de que un paso dé a la fila una opción permitida al azar en vez de la mejor. Sirve para salir de un mínimo local, pero en Saúl empeoró el resultado. |

La búsqueda local recuerda el mejor horario visto y es el que devuelve.

## El goloso

Construye un solo horario en una pasada. Solo tiene `--semilla`, que decide los desempates al azar. No tiene penalización: compara primero las duras y después las blandas.

Su JSON no tiene `costo`, `motivo_de_parada` ni `individuos`. `iteraciones` es el número de filas, `evaluaciones` vale 1, y `filas_forzadas` da las filas que no tuvieron ninguna celda sin duras.

## La reparación tabú

Cada arranque construye un horario con la pasada del goloso y lo repara: primero las duras y, si llega a 0, las blandas. En cada paso elige al azar una fila en conflicto, una que al quitarla baja alguna restricción incumplida, y la lleva a su mejor celda permitida que no sea la actual ni tabú, o la intercambia con otra fila de su clave más justa. Compara primero las duras y después las blandas, sin penalización. Para en (0, 0) o al llegar a `--arranques`. No tiene límite de tiempo, así que la misma semilla da siempre el mismo horario.

| Argumento | Por defecto | Qué es y para qué sirve |
|---|---|---|
| `--semilla` | obligatoria | Semilla del generador de números al azar. Decide los desempates y qué fila en conflicto se mueve. |
| `--tabu` | 10 | Pasos durante los que una fila no puede volver a la celda que acaba de dejar, salvo que eso mejore lo mejor del arranque. |
| `--permuta` | 0,25 | Probabilidad de que un paso intente intercambiar la fila con otra de su clave más justa antes de moverla. Solo vale en los choques donde dos filas con la misma clave y la misma celda chocan siempre: no hay claves en tv ni en docentes. |
| `--arranques` | 10 | Máximo de arranques. Hace al menos uno. En tesis, docentes y el SEDER el objetivo nunca llega a 0, así que hace todos. |
| `--estancamiento` | 5 × filas | Pasos seguidos sin mejorar lo mejor del arranque que terminan la fase de las duras y el arranque. |
| `--pulido` | filas | Pasos seguidos sin mejora que terminan la fase de las blandas. |

Antes de buscar compara, por cada clave, las filas que la tienen con las celdas que alcanzan. Si alguna no cabe, construye un horario y termina con `infactible`.

Su JSON no tiene `costo`, `individuos` ni `filas_forzadas`. `motivo_de_parada` es `optimo`, `maximo` o `infactible`. `iteraciones` son los pasos, `arranques` los que hizo, y `evaluaciones` los horarios enteros evaluados: uno por arranque y el del resultado. `certificado` da las claves con holgura 0 o negativa, y `mejoras`, el arranque, el paso, los segundos y las duras y blandas cada vez que mejora el mejor horario visto.

## Lo que guarda una corrida

`corridas/<estrategia>-semilla-<semilla>-<fecha>.json`:

| Campo | Qué es |
|---|---|
| `estrategia`, `argumentos` | Qué se ejecutó y con qué valores, también los que se dejaron por defecto |
| `motivo_de_parada` | `optimo`, `estancamiento`, `maximo` o `tiempo` |
| `iteraciones` | Generaciones o pasos |
| `individuos`, `evaluaciones` | Horarios creados y horarios evaluados. Cada horario se evalúa una vez como mucho |
| `segundos` | Lo que tardó, contando el arranque |
| `sin_opciones_permitidas` | Las filas que no tenían ninguna opción permitida y arrancaron con cualquiera |
| `costo`, `duras`, `blandas` | El valor del mejor horario. Las blandas ya multiplicadas por su peso |
| `posiciones` | El mejor horario como índices, para reconstruirlo con `modelo.crear_horario` |
| `horario`, `valores` | El mejor horario en texto, y el valor sin ponderar de cada restricción |

## Ejemplos a mano

Desde `salida/<dominio>/python/`:

```bash
# Arrancar como el sistema viejo, para comparar
python genetico.py --semilla 0 --inicio aleatorio

# Una corrida larga, con 10 minutos como mucho
python genetico.py --semilla 0 --generaciones 2000 --tiempo 600

# Población grande
python genetico.py --semilla 0 --poblacion 500

# Búsqueda local con 2 minutos como mucho
python busqueda_local.py --semilla 0 --tiempo 120
```
