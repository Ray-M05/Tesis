# Decisiones de la reimplementación

Decisiones ya tomadas. Las de las etapas siguientes que siguen abiertas están en [`plan-reimplementacion.md`](../plan-reimplementacion.md). La implementación de la capa de análisis está en [`plan-etapa-2.md`](plan-etapa-2.md).

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
| Dónde viven las anotaciones de un destino | En un archivo por destino, como `dominios/saul/espanol.lisp`: el dominio queda neutral. Se mueven en la etapa 3. |

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
| En qué orden se implementa la emisión | Fases grandes: destinos, Python y su comparación, matemática y español. Lo que da valores se valida primero. |

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
