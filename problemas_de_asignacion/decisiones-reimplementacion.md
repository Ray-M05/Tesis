# Decisiones de la reimplementación

Decisiones ya tomadas. Las de las etapas siguientes que siguen abiertas están en [`plan-reimplementacion.md`](../plan-reimplementacion.md). La implementación de la capa del DSL está en [`plan-etapa-1.md`](plan-etapa-1.md).

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
