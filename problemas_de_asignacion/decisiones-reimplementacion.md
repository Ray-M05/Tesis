# Decisiones de la reimplementación

Decisiones ya tomadas. Las de las etapas siguientes que siguen abiertas están en [`plan-reimplementacion.md`](../plan-reimplementacion.md). La implementación de la capa de análisis está en [`plan-etapa-2.md`](plan-etapa-2.md), la de la emisión en [`plan-etapa-3.md`](plan-etapa-3.md) y la de las estrategias en [`plan-etapa-4.md`](plan-etapa-4.md).

## Proyecto

| En qué consistía | Decisión y motivo |
|---|---|
| Nombre de la carpeta principal | `problemas_de_asignacion/`: el sistema resuelve asignación, no solo horarios. |
| Qué hacer con el sistema viejo | Queda en local, sin versionar y sin modificar: es la referencia contra la que se compara. |
| Si la tesis y las bases de conocimiento entran en la carpeta | Las coloca el autor a mano: no forman parte del sistema. |
| Si cada dominio lleva `descripcion.md` y `datos.md` | No se crean y se quedan donde están; el autor los coloca si los necesita. Ningún código los lee. |
| Idioma de los identificadores | Español; `generate-code` pasa a `generar-codigo`. Así el código tiene un solo idioma. |
| Codificación de los archivos | UTF-8 sin BOM, declarado en el `.asd` y en el cargador. Evita repetir los comentarios dañados de `clases-macros.lisp`. |
| Si se ejecutan docentes y Saúl para la referencia | No, solo se copian sus artefactos: evaluarlos todavía es demasiado caro. |
| Si se implementa el dominio departamento | No; queda como análisis en la base de conocimiento. Ninguna etapa lo necesita, y `suma` se prueba con un dominio de prueba. |

## Dureza y pesos

| En qué consistía | Decisión y motivo |
|---|---|
| De dónde sale la dureza | Del cuantificador: `nppq` y `tqpq` son duras, `ndpq` y `sbqp` blandas, `minimizar` y `maximizar` objetivos. Ya lo dice el vocabulario, y se declara una sola vez. |
| Dónde vive el peso de las duras | En la estrategia, como penalización: cambiarla no cambia cuál es la mejor solución, y un solver exacto no la usa. |
| Cómo se escribe el peso de las blandas | `:peso` por clave, con valor 1 por defecto, y en una dura es un error: `(def-ndpq r c :peso 5)` se entiende sin recordar posiciones. |

## Consultas

| En qué consistía | Decisión y motivo |
|---|---|
| Cómo se recorren las parejas no ordenadas | Con `:pares` explícito, sin detección automática: detectar puede equivocarse sin aviso. `:itera-sobre` sigue contando pares ordenados, y la etapa 2 solo avisa. |
| Cuántos `:pares` lleva una consulta | Uno, con `:itera-sobre` por fuera. Ningún dominio necesita más. |
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
| Qué pasa con `jornada` | Se elimina en un paso aparte: sus 130 filas son profesor × día y todas tienen tope 5. |
| Cómo recibe su nombre una restricción | `(def-nppq r cond)`, sin `defvar`: igual que las demás definiciones, y el nodo conoce su nombre. |
| Qué son los cuantificadores | Macros, porque `:para` tiene que ligar las variables antes de evaluar la condición. |
| Qué pasa con `minimizar` sin `:para` | Es un error: hoy genera `return 0` sin avisar. |
| Qué hacer con `frecuencia-exacta` de docentes | Se deja fuera: la sesión es la identidad, así que su conteo lo fijan los datos. |
| Qué hacer con los datos de pares | Por ahora se aceptan como entidades (`plan`, `ausencia`, `indisponibilidad`): son tablas de datos reales y `:para` las recorre. La sintaxis queda pendiente a implementar (ver el final). |

## Entidades y problema

| En qué consistía | Decisión y motivo |
|---|---|
| Cómo se define el problema | Macro `def-problema` con `:combinacion`, `:identidad`, `:variables` y `:restricciones`: evita comillas y `defvar`, y sus claves se validan. |
| Si `def-comb` genera `DEF-<combinación>` | No: las filas las produce la búsqueda y ningún dominio lo usa. |
| Qué se exige a los componentes de la combinación | Que sean exactamente la identidad más las variables. Los cinco dominios ya lo cumplen. |
| Si se aceptan dominios vacíos | No en la identidad ni en las variables: fallarían mucho más tarde. |
| Qué orden conserva el problema | El escrito, en entidades, instancias y restricciones: los horarios de referencia son posiciones, y la prosa sigue ese orden. |
| Dónde viven las anotaciones de un destino | En un archivo por destino, como `dominios/saul/verbalizador.lisp`: el dominio queda neutral. Se mueven en la etapa 3. |

## Paquetes, carga y errores

| En qué consistía | Decisión y motivo |
|---|---|
| Quién crea el paquete de un dominio | El cargador; `dominio.lisp` no declara paquete, así que solo describe el problema. |
| Qué paquetes tiene la capa | `dsl`, solo con el vocabulario, y `dsl-ast`, con la implementación y lo que leen las capas siguientes. Los dominios solo ven lo primero. |
| Cuántos problemas tiene un dominio | Exactamente uno, y `cargar-dominio` lo devuelve: las capas siguientes reciben un objeto, no un nombre. |
| De dónde sale la foto de instancias | De registros que el cargador crea nuevos en cada carga: un dominio no puede ver los de otro. |
| Qué nombres puede usar un dominio | Solo los suyos: se rechaza uno de Common Lisp o del lenguaje, como `list` o la entidad `consulta`. |
| Quién genera las funciones de acceso | Solo las entidades, una vez por slot aunque se repita. Los nodos del AST se leen con `slot-value`, y así no hay avisos de redefinición. |
| Cómo se señala un error | Con la condición base `error-dsl`, cuyo mensaje nombra el objeto. Las pruebas comprueban el tipo y el nombre. |
| Cómo se prueba la migración | Se lee el dominio viejo con `read` y se comparan instancias, condiciones y restricciones contra una lista de cambios esperados. Si no, un error en una condición no se vería hasta la etapa 3. |

## Nodos

| En qué consistía | Decisión y motivo |
|---|---|
| Qué hacer con los nodos sin semántica | Se borran `comb-entidades`, `lista`, `acceso-a-elemento-de-comb`, `hay-elementos-duplicados` y `pertenece`: no los usa ni los traduce nadie. Se añaden si un dominio los necesita. |
| Cómo se representa la aplicación de una consulta | Con un nodo nuevo, que comprueba el número de argumentos: la aplicación deja de ser una variable global. |

## Análisis

| En qué consistía | Decisión y motivo |
|---|---|
| Cómo se representa la familia | Dos jerarquías de clases: la forma de la restricción y la familia de la consulta. Son dos ejes independientes, y así los destinos despachan sobre cada uno sin `case` ni una clase por combinación. |
| Qué pasa con lo que no encaja en ninguna familia | Pasa a una familia `generica` explícita, que Python y el español pueden emitir de forma literal. Un destino que no pueda con ella da error. Así una restricción válida y rara se puede seguir escribiendo. |
| Cuándo se calcula el modelo | Todo al construirlo: los modelos son pequeños y así queda inmutable. |
| A qué entidad apunta un slot | Se deduce de las instancias, y de los nombres en la combinación. Así los dominios no declaran tipos. |
| Qué pasa con un camino o una comparación sin sentido | El análisis los rechaza y nombra la consulta y el slot: `(orden u)` sin ese slot, argumentos cambiados o comparar un día con un número. Si no, el error aparece lejos o la restricción nunca salta. |
| Cómo se detecta si una condición es simétrica | Se intercambian las dos variables después de aplicar las igualdades de la propia condición. Comparar solo el texto da un aviso falso en `repeticiones-en-el-dia`. |
| Cómo se entregan los avisos | Como una lista dentro del modelo: la función sigue siendo pura y las pruebas los leen directamente. Los muestra la orquestación. |
| Qué se guarda de una comparación | Lo escrito, para la prosa, y cuándo se incumple, para el cálculo. La negación es un método y no se repite en cada destino. |
| Si el modelo copia las expresiones | No: reutiliza los nodos del AST, y `generar-codigo` despacha sobre ellos. Solo se envuelven las consultas, para unir `:itera-sobre` y `:pares`. |
| Si los pares simétricos y los ordenados son una familia | Dos, bajo un padre común: `choque-por-parejas` y `relacion-ordenada`. Agrupar por celda solo vale para los simétricos. |
| Qué pasa con un ciclo entre entidades | Es un error que nombra el ciclo. Cortarlo sin avisar daría un orden incorrecto sin que nadie se entere. |
| Si se avisa de una restricción que no depende de ninguna decisión | Sí, y cada restricción guarda qué decisiones toca. Ningún horario cambia su resultado: gasta tiempo y puede esconder un error en los datos. La etapa 4 podrá evaluarla una sola vez. |
| Qué pasa con un slot cuyos valores son de clases distintas | Se rechaza, también con `nil` en unas filas y una referencia en otras. Ningún dominio lo hace, y así Python no tiene que manejar la ausencia de valor. |
| Qué pasa con una variable declarada que no se usa | El análisis avisa y no la rechaza: el modelo sigue construyéndose, aunque el conteo se multiplique. Quien escribe el dominio decide. |
| Cómo se recorren una consulta y sus parejas en el modelo | Una sola lista de `(variable dominio)`, con `:pareja` en las que vienen de `:pares`. Los destinos construyen sus bucles sin distinguir dos casos. |
| De dónde sale el dominio de un parámetro | De las aplicaciones de la consulta: `(dias-asistidos p)` con `p` en `profesor`. Dos aplicaciones con dominios distintos son un error. Así los dominios no declaran tipos. |
| Cuándo una ruta es una decisión | Si su raíz recorre la combinación y el slot más cercano a la raíz es una variable del problema. Mirar solo el nombre del slot confunde `(dia a)` de `ausencia`, que es un dato, con una decisión. |
| Con qué orden se presentan las entidades | Cada una después de las que referencia; primero las que dependen de menos y, a igualdad, por nombre. Es el criterio del verbalizador, porque la prosa tiene que quedar idéntica. |
| Qué valores puede tener un slot | Un número, un texto o una instancia, de un solo tipo en todas las filas. Un slot de una entidad sin instancias queda como desconocido, y sus comparaciones no se rechazan. |
| Qué se comprueba de una restricción | Que un cuantificador lleve una condición y un objetivo un número. `(def-nppq r (q))` no significa nada y Python lo aceptaría sin avisar, así que no va a `generica`. |
| Qué forma tiene cada restricción | `prohibicion` si se incumple con `q > 0` y no tiene `:para`; `cota` si compara una consulta con algo sin consultas; `minimax` si es un objetivo con alguna consulta; `generica` en otro caso. La forma no depende de cómo se escribió. |
| Cuándo `q ≥ 1` equivale a `q > 0` | Solo si la consulta da enteros: `contar-distintos` o `suma` de un literal entero. Con `q = 0.5` no son lo mismo. |
| Cómo se guarda cuándo se incumple una cota | Como un nodo del AST, por ejemplo `(op-mayor medida 5)`. `generar-codigo` lo traducirá sin lógica nueva. |
| Si `contar-distintos` es una familia | No: es una `agrupacion`. La operación ya es una clase propia, y añadir una familia repetiría esa distinción. |
| Qué familia tiene una pareja dudosa | Un choque simétrico sin `:pares` es `relacion-ordenada`, con aviso, porque así se comporta lo escrito. `:pares` con una condición no simétrica, sin celda o fuera de la combinación es `generica`. |
| Qué pasa con los slots compartidos a través de una variable | Dos igualdades con la misma variable y la misma ruta equivalen a una ruta compartida. Va a la celda o a la clave, y `pareja-enlaces` conserva la variable. |
| Qué consultas tiene el modelo | Las que aparecen en sus restricciones, en orden de primera aparición. Sustituyen a la lista `:consultas` y coinciden con ella. |
| Qué dominios tiene el modelo | Los componentes de la combinación y lo que recorren consultas y `:para`, sin la combinación, que no tiene instancias. La identidad siempre está (2.3). |
| Qué guarda el modelo del problema | Una referencia al objeto `problema`, además de lo que deduce. Entidades, slots e instancias no se copian. |
| Cuándo se detiene el análisis | En el primer error, igual que el DSL. Los avisos no lo detienen. |
| Cómo se organiza el análisis | Sin `dominios.lisp`: esa lógica está en `tipos.lisp` y `construir.lisp`. `tipos.lisp` y `simetria.lisp` son archivos propios. |

## Emisión

| En qué consistía | Decisión y motivo |
|---|---|
| Cuánto vale un choque con k filas en la misma celda | Las parejas que chocan, una vez cada una: k(k−1)/2 si todas chocan. Es lo que dicen `(suma 1)` y la prosa, y se comprueba exactamente: es la mitad del valor viejo. |
| Cuánto vale incumplir una cota | Lo que falta para cumplirla: `q ≤ 5` con `q = 7` vale 2. Sigue la regla de `q > 0`, que vale `q`, y da pendiente a la búsqueda. Solo afecta a dos restricciones de Saúl. |
| Cómo se imprime una instancia | Por su único slot de texto; si no lo hay, o hay varios, por todos sus slots. La regla mira tipos y cantidad, no nombres, y elige lo mismo que la vieja en las 36 entidades con instancias. |
| Formato de la salida matemática | Solo LaTeX: entra directo en la tesis y hay un solo destino que mantener. |
| Si hay un destino ILP en esta etapa | No: se reserva la rama del destino y se hace en una etapa propia, después de la 5. |
| Si se capturan valores de docentes y Saúl | Sí, 10 horarios sin ejecutar el genético: evaluar una vez cuesta 0,01 s y 1 s. Lo caro era buscar. Los factibles siguen sin capturarse, porque esos sí exigen buscar. |
| Si las sesiones de Saúl conservan `numero` | No: solo existía para que dos sesiones del mismo plan no fueran iguales por valor. Con identidad sobra, y es la prueba real de que funciona. |
| Qué dice la prosa de `contar-distintos` | Lo que sale del slot contado: «fechas distintas» en tesis y «días distintos» en docentes. Cambian dos líneas de la prosa de tesis. |
| Cómo se escribe el tope en la prosa | «El número de ubicaciones de cada profesor y cada día no puede superar 5.»: sale de `:para` con cualquier número de variables. |
| En qué idioma van los identificadores | En español, también lo que se migre del verbalizador. Solo queda en inglés lo que pertenece a Common Lisp, a Python o a LaTeX. |
| En qué orden se implementa la emisión | Fases grandes: destinos, Python y su comparación, matemática, español y, al final, traducir lo que queda en inglés. Lo que da valores se valida primero, y un cambio de nombres no se mezcla con lógica nueva. |
| Qué se traduce de lo ya implementado | Todo, salvo las copias congeladas de `pruebas/referencia/`: `op-and`, `op-or` y `op-not` son `op-y`, `op-o` y `op-no`; `defclass*` es `def-mixin`; `args` es `parametros`; y la abreviatura `nl` es `prosa`. Quedan `slot` y `mixin`, que son términos de CLOS. |
| Forma del Python generado | Un `modelo.py` con datos, consultas, restricciones y `evaluar`, y un archivo por estrategia que lo importa. Varias estrategias usan el mismo modelo sin regenerarlo. Esta etapa solo genera `modelo.py`. |
| Qué se hace con MGA | Nada por ahora: `gcode` y la sangría de MGA quedan para una etapa extra del plan. Los métodos se escriben con `defmethod`, y añadirlos después no cambia la salida. |
| Cómo se llama el destino de la prosa | `verbalizador`, su nombre original, en la carpeta, en la clase y en las anotaciones de cada dominio. |
| Cómo se lleva la sangría | Un slot de nivel y la macro `con-sangria`. Es más simple, y la salida es la misma. Se puede pasar al mecanismo de MGA más adelante. |
| Dónde vive lo que la prosa sabe del español | La morfología y las palabras del idioma, en `src/`, con claves de texto. Lo propio de un dominio, en `dominios/<d>/verbalizador.lisp`. Hoy solo Saúl lo necesita, para sus predicados. |
| Cómo se migra el verbalizador | Se traslada a su sitio sin cambiar su lógica ni arreglar nada. Si aparece un error real, se informa al autor, que decide. Cuatro puntos ya vistos se analizan al terminar la implementación, y se corrigen si afectan directamente. |
| Si la prosa tiene que ser idéntica a la referencia | No. Compararla es un informe: las diferencias se muestran para decidir, y la prueba no falla por ellas. |
| Qué contiene el modelo matemático | Conjuntos, decisiones, objetivo y restricciones, como la salida que sustituye. |
| Cómo se escriben las decisiones en la matemática | Como funciones, `fecha(a) ∈ FECHA`. Las binarias son del ILP y obligarían a reescribir cada restricción. |
| Qué es la función objetivo | Las duras van como «sujeto a» y el objetivo solo suma las blandas con su peso. La penalización es de la estrategia, no del problema. |
| Qué aspecto tiene una restricción blanda | Su requisito y su término de costo, para que el modelo diga cuánto vale incumplirla. |
| Cómo se nombran los conjuntos | Por el nombre de la entidad, `PROFESOR`: es único sin reglas, y las letras chocaban en el SEDER. |
| Cómo se escribe una consulta en la matemática | Nodo por nodo, con Σ y corchetes de Iverson, una línea por conjunción: dice lo que está escrito en el dominio. |
| Qué archivo matemático se entrega | Un fragmento para `\input` en la tesis. Las pruebas lo envuelven para compilarlo. |

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
| Si el ILP entra en esta etapa | No: tiene su propia etapa, y allí se decide si es destino, estrategia o las dos cosas. |
| Qué estrategias se implementan | El genético y la búsqueda local. La segunda demuestra que añadir una no toca la otra. Una exhaustiva no sirve con estos tamaños. |
| Cómo se elige el arranque de la población | Las tres vías, voraz, valores permitidos y al azar, se generan siempre, y se elige al ejecutar con `--inicio`, voraz por defecto. Voraz es un individuo voraz y el resto con valores permitidos: una población entera de voraces costaría unos 50 minutos en Saúl. |
| Cómo se combinan duras y blandas | Suma ponderada: `penalización × duras + Σ peso × blandas`, con penalización 1000. Las blandas de un horario al azar no pasan de 18, así que una prioridad lexicográfica daría el mismo orden. |
| Cómo es la mutación | Mueve entre 1 y k filas, con k = 2 por defecto, más un intercambio entre dos filas. En el SEDER pasa de 15 a 18 semillas de 20. |
| Si los valores prohibidos se quitan también al mutar | No, solo al arrancar. Se midió: en el SEDER no cambia nada, y en Saúl queda en 111,5 frente a 118,7 duras con 6 semillas y rangos solapados. Con arranque voraz, 14,2 frente a 13,8. |
| Cuándo se detiene una corrida | El genético, con 0 duras y sin blandas, en el máximo de generaciones o por tiempo. No se detiene por estancamiento: se quitó porque en Saúl seguía mejorando después de 100 generaciones sin mejora, de 17 a 14 duras. La búsqueda local sí se detiene tras 2 000 pasos sin mejora, porque sin eso sus 100 000 pasos tardarían horas. Seguir tras ser factible mejora algo las blandas por poco costo. |
| Cómo se reparte la parada | Dos clases: `parada-por-limite`, la del genético, y `parada-por-estancamiento`, la de la búsqueda local, que añade `--estancamiento`. Cada estrategia elige la suya en un slot, así que cambiar la de una no toca la otra. |
| Cómo se generan los operadores | Cada operador es una clase Lisp con un método por destino que escribe su Python. Añadir uno no toca los demás, como pide 4.1. |
| Qué se invierte en velocidad de evaluación | Solo no recalcular las restricciones que no dependen de ninguna decisión. Agrupar las relaciones y la evaluación incremental quedan como trabajo extra. |
| Dónde se fijan la semilla y los parámetros | Valores por defecto en la clase Lisp, y argumentos al ejecutar el Python, para no regenerar en cada corrida. Sin semilla da error. `ejecuciones/` lleva un archivo Markdown que explica cada parámetro y argumento. |
| De quién es cada argumento | De la pieza que lo usa: el tamaño del torneo es del torneo, el radio de `mover-filas`, la probabilidad de intercambiar del intercambio, y el estancamiento y el tiempo de la parada. La estrategia solo tiene los de su bucle. Cambiar un operador cambia sus argumentos sin tocar los demás. |
| Qué cuenta como evaluación | Solo evaluar un horario completo. Las comprobaciones del voraz sobre un horario a medias no cuentan, porque no producen un individuo. |
| Qué listas de restricciones da `modelo.py` | Listas de nombres, no de funciones, para que el JSON y las pruebas hablen de cada restricción por su nombre. |
| Cómo es un paso de la búsqueda local | Un operador, `mejor-opcion-de-fila`: elige una fila al azar y le da, entre sus opciones permitidas, la de menor costo, desempatando al azar. El horario actual entra entre los candidatos, así que quedarse es posible y no se vuelve a evaluar. Con `--ruido` le da una opción permitida al azar. Devuelve el mejor horario visto, no el último. |
| Dónde vive la búsqueda local | Entera en su archivo, con su operador. Añadirla no tocó `estrategia.lisp`, `operadores.lisp` ni el genético, y el `genetico.py` de los cinco dominios salió idéntico byte a byte. |
| Qué programas escribe `exportar` | `genetico.py` y `busqueda_local.py`, con los valores por defecto de sus clases, junto a los tres archivos del modelo. Los argumentos se cambian al ejecutar, sin regenerar. |
| Cómo se mide el rendimiento | Con `pruebas/estrategias/rendimiento.py`, aparte de las pruebas porque tarda minutos. Las corridas de los criterios van en paralelo, y entonces su tiempo no vale; las de tiempo van de una en una. Lo que no se puede medir se proyecta desde el costo de una generación y de una evaluación. |
| Qué se exige para dar la etapa por cumplida | SEDER: al menos 18 de 20 semillas en 0 duras. Saúl: no se exige 0, porque no se sabe si es posible; no superar 17 duras y como mucho 1 evaluación por individuo. Al terminar se calcula en minutos cuánto costaría una corrida más grande. |

## Orquestación

| En qué consistía | Decisión y motivo |
|---|---|
| Un proceso por dominio o la misma imagen | La misma imagen. Cada dominio se carga en su propio paquete `DOMINIO-<NOMBRE>`, que solo ve Common Lisp y el vocabulario `dsl`, y con registros nuevos. Así el `def-clase` que genera la entidad `clase` de docentes no es el de la infraestructura, y un dominio no ve las instancias de otro. |
| Qué se hace con `verbalizador/` | Nada: se encarga el usuario. |
| Cómo se pide una ejecución | De las dos formas. La línea de comandos para lo rápido; un archivo de `ejecuciones/` para una corrida que se quiere repetir o citar. |
| Dónde queda la salida | Una carpeta por destino dentro de la del dominio. Los programas de las estrategias van con `modelo.py`, porque lo importan. |
| Cómo se elige un destino o una estrategia | Por el nombre de su clase. Una clase nueva queda disponible sin tocar la orquestación. |
| Qué se hace con los avisos del análisis | Se imprimen al generar y se guardan en la salida del dominio. |
| Si la orquestación ejecuta la búsqueda | Solo si se pide. Por defecto, solo genera. |
| Banco de comparación | No se hace. `rendimiento.py` queda como está. |
| Qué es un archivo de `ejecuciones/` | Una lista de Lisp que se lee sin evaluar, con un solo dominio. No se mezcla con la línea de comandos. |
| Qué se genera si no se nombra nada | Todo: todos los dominios, destinos y estrategias. |
| Varias semillas | Se ejecutan una tras otra. |
| Al regenerar | Se sobrescribe lo generado y la carpeta no se borra, así que las corridas guardadas se conservan. |
| Si un dominio falla | Se informa y se sigue con el resto. |
| Los cuatro puntos del verbalizador | Se revisan al terminar la etapa, no dentro de ella. |

## Cómo queda cada recorrido

Con X e Y dos filas distintas.

| Caso | Declaración | Se visita | Resultado |
|---|---|---|---|
| Choque simétrico, declarado | `:pares (c1 c2) clase` | (X,Y) | Cuenta 1. Correcto |
| Choque simétrico, sin declarar | `:itera-sobre (c1 clase) (c2 clase)` | (X,Y) y (Y,X) | Cuenta 2 por un solo hecho. La etapa 2 avisa |
| Choque con otra variable | `:itera-sobre (p profesor)` y `:pares (c1 c2) clase` | (X,Y) por cada profesor | Cuenta 1 por profesor. Correcto |
| Par ordenado | `:itera-sobre (e1 emision) (e2 emision)` | (X,Y) y (Y,X) | Cada orden se evalúa por separado. Correcto |
| Par ordenado, declarado con `:pares` | `:pares (e1 e2) emision` | Solo un orden | Se puede perder el caso. La etapa 2 avisa |

## Pendiente a implementar

| Punto | Qué falta y por qué |
|---|---|
| Datos de pares (deficiencia 1.4) | Una sintaxis para guardar un dato que pertenece a dos entidades, sin inventar una entidad con una fila por par. Su valor es de expresividad: en el genético no cambia la búsqueda y casi no cambia el tiempo. |
