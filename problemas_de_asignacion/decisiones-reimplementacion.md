# Decisiones de la reimplementación

## Proyecto

| En qué consistía | Decisión y motivo |
|---|---|
| Idioma de los identificadores | Español; `generate-code` pasa a `generar-codigo`. Así el código tiene un solo idioma. |

## Dureza y pesos

| En qué consistía | Decisión y motivo |
|---|---|
| De dónde sale la dureza | Del cuantificador: `nppq` y `tqpq` son duras, `ndpq` y `sbqp` blandas, `minimizar` y `maximizar` objetivos. Ya lo dice el vocabulario, y se declara una sola vez. |
| Dónde vive el peso de las duras | En la estrategia, como penalización: cambiarla no cambia cuál es la mejor solución, y un solver exacto no la usa. |
| Cómo se escribe el peso de las blandas | `:peso` por clave, con valor 1 por defecto, y en una dura es un error: `(def-ndpq r c :peso 5)` se entiende sin recordar posiciones. |

## Consultas

| En qué consistía | Decisión y motivo |
|---|---|
| Cómo se recorren las parejas no ordenadas | Con `:pares` explícito, sin detección automática: detectar puede equivocarse sin aviso. `:itera-sobre` sigue contando pares ordenados. |
| Sintaxis de `contar-distintos` | `(contar-distintos (dia c))`, con atributo obligatorio: elimina el cableado a `fecha` y `dia`. |
| Qué operaciones hay | `(suma e)` y `(contar-distintos e)`, sin `:devuelve`; contar es `(suma 1)`. Son una clase cada una, así que añadir otra no toca el análisis de argumentos. |
| Cómo se escribe una condición reutilizable | `(def-condicion nombre (params) condición)`: no recorre ni cuenta, y `def-consulta` deja de tener dos significados. |
| Cómo se usa una consulta sin parámetros | Como llamada, `(colisiones-de-aula)`: una sola regla para todas las consultas. |
| Qué argumentos recibe una consulta | Solo variables ligadas por `:para`: así no hay expresiones que deducir después. |
| Qué define `def-consulta` | Una función que devuelve un nodo de aplicación, y el nodo de la consulta guarda su `nombre`. Sin `:consultas`, el nombre tiene que salir de ahí. |
| Si una consulta puede ir dentro de `:comprueba` | No: el lenguaje tiene un solo nivel de agregación. |

## Restricciones

| En qué consistía | Decisión y motivo |
|---|---|
| Si se cuantifica sobre varios dominios | Sí, con variables explícitas: `:para (p profesor) (d dia)`. Un solo dominio es el caso N=1 y sustituye a `elemento`. |
| Cómo recibe su nombre una restricción | `(def-nppq r cond)`, sin `defvar`: igual que las demás definiciones, y el nodo conoce su nombre. |
| Qué son los cuantificadores | Macros, porque `:para` tiene que ligar las variables antes de evaluar la condición. |
| Qué hacer con los datos de pares | Por ahora se aceptan como entidades (`plan`, `ausencia`, `indisponibilidad`): son tablas de datos reales y `:para` las recorre. |

## Entidades y problema

| En qué consistía | Decisión y motivo |
|---|---|
| Cómo se define el problema | Macro `def-problema` con `:combinacion`, `:identidad`, `:variables` y `:restricciones`: evita comillas y `defvar`, y sus claves se validan. |
| Dónde viven las anotaciones de un destino | En un archivo por destino, como `dominios/saul/verbalizador.lisp`: el dominio queda neutral. |

## Paquetes, carga y errores

| En qué consistía | Decisión y motivo |
|---|---|
| Cuántos problemas tiene un dominio | Exactamente uno, y `cargar-dominio` lo devuelve: las capas siguientes reciben un objeto, no un nombre. |
| De dónde sale la foto de instancias | De registros que el cargador crea nuevos en cada carga: un dominio no puede ver los de otro. |
| Qué nombres puede usar un dominio | Solo los suyos: se rechaza uno de Common Lisp o del lenguaje, como `list` o la entidad `consulta`. |
| Quién genera las funciones de acceso | Solo las entidades, una vez por slot aunque se repita. Los nodos del AST se leen con `slot-value`, y así no hay avisos de redefinición. |
| Cómo se señala un error | Con la condición base `error-dsl`, cuyo mensaje nombra el objeto. Las pruebas comprueban el tipo y el nombre. |

## Análisis

| En qué consistía | Decisión y motivo |
|---|---|
| Cómo se representa la familia | Dos jerarquías de clases: la forma de la restricción y la familia de la consulta. Son dos ejes independientes, y así los destinos despachan sobre cada uno sin `case` ni una clase por combinación. |
| Qué pasa con lo que no encaja en ninguna familia | Pasa a una familia `generica` explícita, que Python y el español pueden emitir de forma literal. Un destino que no pueda con ella da error. Así una restricción válida y rara se puede seguir escribiendo. |
| A qué entidad apunta un slot | Se deduce de las instancias, y de los nombres en la combinación. Así los dominios no declaran tipos. |
| Qué pasa con un camino o una comparación sin sentido | El análisis los rechaza y nombra la consulta y el slot: `(orden u)` sin ese slot, argumentos cambiados o comparar un día con un número. Si no, el error aparece lejos o la restricción nunca salta. |
| Cómo se detecta si una condición es simétrica | Se intercambian las dos variables después de aplicar las igualdades de la propia condición. Comparar solo el texto da un aviso falso en `repeticiones-en-el-dia`. |
| Cómo se entregan los avisos | Como una lista dentro del modelo: la función sigue siendo pura y las pruebas los leen directamente. Los muestra la orquestación. |
| Qué se guarda de una comparación | Lo escrito, para la prosa, y cuándo se incumple, para el cálculo. La negación es un método y no se repite en cada destino. |
| Si el modelo copia las expresiones | No: reutiliza los nodos del AST, y `generar-codigo` despacha sobre ellos. Solo se envuelven las consultas, para unir `:itera-sobre` y `:pares`. |
| Si los pares simétricos y los ordenados son una familia | Dos, bajo un padre común: `choque-por-parejas` y `relacion-ordenada`. Agrupar por celda solo vale para los simétricos. |
| Qué pasa con un ciclo entre entidades | Es un error que nombra el ciclo. Cortarlo sin avisar daría un orden incorrecto sin que nadie se entere. |
| Si se avisa de una restricción que no depende de ninguna decisión | Sí, y cada restricción guarda qué decisiones toca. Ningún horario cambia su resultado: gasta tiempo y puede esconder un error en los datos. |
| Con qué orden se presentan las entidades | Cada una después de las que referencia; primero las que dependen de menos y, a igualdad, por nombre. Es el criterio del verbalizador, porque la prosa tiene que quedar idéntica. |
| Qué valores puede tener un slot | Un número, un texto o una instancia, de un solo tipo en todas las filas. Un slot de una entidad sin instancias queda como desconocido, y sus comparaciones no se rechazan. |
| Qué se comprueba de una restricción | Que un cuantificador lleve una condición y un objetivo un número. `(def-nppq r (q))` no significa nada y Python lo aceptaría sin avisar, así que no va a `generica`. |
| Qué forma tiene cada restricción | `prohibicion` si se incumple con `q > 0` y no tiene `:para`; `cota` si compara una consulta con algo sin consultas; `minimax` si es un objetivo con alguna consulta; `generica` en otro caso. La forma no depende de cómo se escribió. |
| Qué familia tiene una pareja dudosa | Un choque simétrico sin `:pares` es `relacion-ordenada`, con aviso, porque así se comporta lo escrito. `:pares` con una condición no simétrica, sin celda o fuera de la combinación es `generica`. |
| Qué pasa con los slots compartidos a través de una variable | Dos igualdades con la misma variable y la misma ruta equivalen a una ruta compartida. Va a la celda o a la clave, y `pareja-enlaces` conserva la variable. |
| Cuándo se detiene el análisis | En el primer error, igual que el DSL. Los avisos no lo detienen. |

## Emisión

| En qué consistía | Decisión y motivo |
|---|---|
| Cuánto vale un choque con k filas en la misma celda | Las parejas que chocan, una vez cada una: k(k−1)/2 si todas chocan. Es lo que dicen `(suma 1)` y la prosa, y se comprueba exactamente: es la mitad del valor viejo. |
| Cuánto vale incumplir una cota | Lo que falta para cumplirla: `q ≤ 5` con `q = 7` vale 2. Sigue la regla de `q > 0`, que vale `q`, y da pendiente a la búsqueda. Solo afecta a dos restricciones de Saúl. |
| Qué contiene el modelo matemático | Conjuntos, decisiones, objetivo y restricciones, como la salida que sustituye. |
| Qué es la función objetivo | Las duras van como «sujeto a» y el objetivo solo suma las blandas con su peso. La penalización es de la estrategia, no del problema. |
| Qué aspecto tiene una restricción blanda | Su requisito y su término de costo, para que el modelo diga cuánto vale incumplirla. |

### Cuánto vale cada restricción

| Forma | Valor |
|---|---|
| Prohibición | El conteo. |
| Cota | Lo que falta para cumplirla, sumado sobre `:para`. |
| Minimax | El máximo. |
| Maximizar | Menos el mínimo. |
| Genérica | 1 por cada combinación que incumple. |

En una cota, si se incumple, vale `|q − umbral|`, más 1 si la condición de incumplimiento incluye la igualdad. `q ≤ 5` se incumple con `q > 5`, así que `q = 7` vale 2; `q < 5` se incumple con `q ≥ 5`, así que vale 3.

`evaluar` calcula todas, duras y blandas, y devuelve estos valores sin ponderar. El costo lo suma la estrategia: `penalización × Σ duras + Σ peso × blandas`. La penalización es de la estrategia, y el peso de cada blanda viene del dominio.

## Estrategias

| En qué consistía | Decisión y motivo |
|---|---|
| Cómo se elige el arranque de la población | Las tres vías, voraz, valores permitidos y al azar, se generan siempre, y se elige al ejecutar con `--inicio`, voraz por defecto. Voraz es un individuo voraz y el resto con valores permitidos: una población entera de voraces costaría unos 50 minutos en Saúl. |
| Cómo se combinan duras y blandas | Suma ponderada: `penalización × duras + Σ peso × blandas`, con penalización 1000. Las blandas de un horario al azar no pasan de 18, así que una prioridad lexicográfica daría el mismo orden. |
| Cómo es la mutación | Mueve entre 1 y k filas, con k = 2 por defecto, más un intercambio entre dos filas. |
| Cuándo se detiene una corrida | El genético, con 0 duras y sin blandas, en el máximo de generaciones o por tiempo. La búsqueda local sí se detiene tras 2 000 pasos sin mejora, porque sin eso sus 100 000 pasos tardarían horas. |
| Cómo se reparte la parada | Dos clases: `parada-por-limite`, la del genético, y `parada-por-estancamiento`, la de la búsqueda local, que añade `--estancamiento`. Cada estrategia elige la suya en un slot, así que cambiar la de una no toca la otra. |
| Qué se invierte en velocidad de evaluación | Solo no recalcular las restricciones que no dependen de ninguna decisión. Agrupar las relaciones y la evaluación incremental quedan como trabajo extra. |
| De quién es cada argumento | De la pieza que lo usa: el tamaño del torneo es del torneo, el radio de `mover-filas`, la probabilidad de intercambiar del intercambio, y el estancamiento y el tiempo de la parada. La estrategia solo tiene los de su bucle. Cambiar un operador cambia sus argumentos sin tocar los demás. |
| Cómo es un paso de la búsqueda local | Un operador, `mejor-opcion-de-fila`: elige una fila al azar y le da, entre sus opciones permitidas, la de menor costo, desempatando al azar. El horario actual entra entre los candidatos, así que quedarse es posible y no se vuelve a evaluar. Con `--ruido` le da una opción permitida al azar. Devuelve el mejor horario visto, no el último. |

## Orquestación

| En qué consistía | Decisión y motivo |
|---|---|
| Cómo se pide una ejecución | De las dos formas. La línea de comandos para lo rápido; un archivo de `ejecuciones/` para una corrida que se quiere repetir o citar. |
| Dónde queda la salida | Una carpeta por destino dentro de la del dominio. Los programas de las estrategias van con `modelo.py`, porque lo importan. |
| Cómo se elige un destino o una estrategia | Por el nombre de su clase. Una clase nueva queda disponible sin tocar la orquestación. |
| Qué se hace con los avisos del análisis | Se imprimen al generar y se guardan en la salida del dominio. |
| Si la orquestación ejecuta la búsqueda | Solo si se pide. Por defecto, solo genera. |
| Qué es un archivo de `ejecuciones/` | Una lista de Lisp que se lee sin evaluar, con un solo dominio. No se mezcla con la línea de comandos. |
| Qué se genera si no se nombra nada | Todo: todos los dominios, destinos y estrategias. |
| Si un dominio falla | Se informa y se sigue con el resto. |
