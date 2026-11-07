# Deficiencias del DSL y de su generador, por capa

### Objetivo de la reimplementación

Rehacer la generación de código sobre **funciones genéricas** de CLOS y una **jerarquía de clases de destinos**: lenguajes de exportación y estrategias de resolución. Lo esencial es la modularidad. Añadir un lenguaje de exportación o una heurística distinta tiene que ser añadir clases y métodos, sin tocar lo existente. No puede quedar nada cableado para que funcionen los dominios ya tratados, ni parches.

Como consecuencia, el verbalizador pasaría a ser un destino más sobre la misma entrada, en lugar de un proyecto que copia código y dominios.

---

## Las capas

| Capa | Qué hace | Bloque | MGA |
|---|---|---|---|
| **1. Construcción del DSL** | macros `def-*`, clases del AST, entidades e instancias, definición del problema | construcción del DSL | `defnode` |
| **2. Análisis** | lo que cualquier backend necesita saber del problema: forma de cada restricción, dominios, familias, orden | generación | — |
| **3. Emisión** | traducción a cada lenguaje destino | generación | `gcode`, `generate-code`, jerarquía de lenguajes |
| **4. Estrategia de resolución** | la heurística o el solver: representación, operadores, evaluación, parámetros | heurísticas | — |
| **5. Orquestación** | qué se genera, en qué orden, dónde se escribe, cómo se conectan los backends | generación | — |

**La capa 2 hoy no existe.** Su trabajo está repartido entre los emisores y duplicado en el verbalizador. Esa ausencia es la causa de buena parte de lo que sigue.

---

## Capa 1 — Construcción del DSL

### 1.1 La forma de la restricción es implícita · grave

Una restricción como «no puede haber más de K» se codifica con la convención `(op-mayor consulta 0)` dentro de un nodo `nppq`. Qué se mide, contra qué umbral y sobre qué dominio no son campos del nodo: hay que deducirlos del árbol. Cada backend repite esa deducción, y el generador de Python la hace mal (3.5).
→ Normalizar cada restricción en un objeto con campos explícitos: medida, comparador, umbral, dominio cuantificado, dureza y peso.

### 1.2 La dureza se declara dos veces, y las dos pueden contradecirse · grave

Una restricción es dura o blanda según su tipo de nodo (`nppq`/`tqpq` duras, `ndpq`/`sbqp` blandas) **y también** según la lista de `def-problema-horario` en la que se coloque. El costo usa la lista; la etiqueta del modelo usa el tipo de nodo.
→ Una sola fuente de verdad para la dureza.

### 1.3 La definición del problema lleva los parámetros del genético · grave

`def-problema-horario` incluye `pop-size`, `generaciones`, probabilidades de cruce y mutación, torneo y pesos. Es configuración de una estrategia concreta dentro de la descripción del problema. El verbalizador conserva esos parámetros sin usarlos, solo para que los dominios se puedan copiar sin editarlos.
→ El problema no sabe nada de cómo se resuelve. Los parámetros viven en el objeto estrategia.

### 1.4 No hay pares de entidades · grave

Falta en sus dos formas:

- **Datos de pares.** Un dato como «la frecuencia de una asignatura en un grado» no tiene dónde guardarse.
- **Cuantificar por pares.** El cuantificador tiene un único `elemento`, así que no se puede decir «para cada grupo y cada asignatura». Por eso la frecuencia exacta de docentes está mal planteada y se omite.
En los dos casos la salida es inventar una entidad para cada par: `plan`, `jornada` y `ausencia` en Saúl, `indisponibilidad` en el SEDER.

### 1.5 La lista `:consultas` es contabilidad manual · moderado

Hay que listar a mano las consultas, aunque las restricciones ya las referencian. Si se olvida una, el emisor no la registra y escribe `consulta_desconocida(horario)`, que falla al ejecutar. Además, un nombre mal escrito en la lista se descarta sin aviso (`boundp`).
→ Derivar las consultas recorriendo las restricciones.

### 1.6 No hay validación de la entrada · moderado

- `def-consulta` busca sus palabras clave por posición, así que una clave mal escrita se ignora sin aviso.
- Cualquier símbolo vale como `:operacion`.
- La macro que crea instancias empareja argumentos y slots sin comprobar cuántos hay: los que faltan salen como `None`.
→ Validar al construir el AST, que es donde el error tiene nombre y línea.

### 1.7 No hay conjuntos ni pertenencia · moderado

El nodo `pertenece` está declarado pero no tiene semántica. Una relación de tamaño variable solo se expresa si se enuncia como prohibición.

### 1.8 El peso es por categoría, no por restricción · moderado

Todas las blandas comparten un único peso. Además, los objetivos `minimizar` (un máximo de cargas) se suman en la misma bolsa que los conteos de incumplimientos, aunque miden cosas distintas.

### 1.9 Los nombres de las entidades chocan con los de la infraestructura · moderado

Una entidad llamada `clase` genera `DEF-CLASE` y tapa la macro central del DSL. Le pasa lo mismo a otros seis nombres.

---

## Capa 2 — Análisis

### 2.1 No existe un modelo intermedio · crítico para la reimplementación

Cada backend lee el AST crudo y rehace su propia clasificación
→ Una capa que construye un modelo normalizado una vez, con pasadas escritas como funciones genéricas, y que todos los backends consumen.

### 2.2 Los choques se cuentan dos veces · crítico

Las consultas de choque recorren todas las parejas ordenadas, así que cada conflicto se cuenta dos veces y pesa el doble que una violación simple. Eso deforma la búsqueda y es la causa del atasco del genético (4.2). Afecta a tesis, docentes y SEDER. Hoy depende de que el usuario escriba la antisimetría a mano en cada dominio.
→ El análisis reconoce la familia «choque por parejas» y el emisor recorre parejas no ordenadas. Nada de parches dominio por dominio.

### 2.3 Cuantificar sobre la identidad da 0 en silencio · crítico latente

La clase `Horario` declara el campo de la identidad, pero nadie lo llena, así que el bucle recorre una lista vacía y devuelve 0. Una restricción imposible («cada brigada tiene dos ubicaciones») sale con 0 incumplimientos. Ningún dominio actual la usa.
→ El dominio de la identidad es un dominio más del modelo intermedio.

### 2.4 La variable del bucle se deduce solo con `op-igual` · moderado

`extraer-loop-var` solo trata `op-igual`. Para traducir la entidad cuantificada dentro del bucle se usa una variable dinámica, `*gen-tqpq-loop-var*`, que cambia lo que emite el traductor según el contexto. En Saúl se sortea con una convención de nombres.
→ El cuantificador liga explícitamente su variable en el modelo intermedio.

### 2.5 La búsqueda de consultas es incompleta · moderado

`consultas-en-restriccion` solo mira dentro de `op-mayor`, `op-and`, `op-or` y `op-not`. Las restricciones con `op-igual` o `op-menor-igual` no muestran su consulta en el modelo matemático: R9 y R11 de Saúl salen sin «donde».

---

## Capa 3 — Emisión

### 3.1 La comparación por valor la decide el emisor · crítico

En el Python generado no hay identidad compartida, y la igualdad por valor es lo único que hace funcionar las comparaciones. Por eso dos entidades con los mismos datos son la misma, cosa que ya produjo resultados falsos en Saúl y en el SEDER. También encarece el genético: cada `deepcopy` duplica árboles enteros de datos.

Los dominios lo esquivan añadiendo campos sin significado, como el número de orden de la sesión o el nombre del año. Es un parche en los datos.
→ Emitir cada instancia una sola vez, con nombre, referenciarla por ese nombre y comparar por identidad.

### 3.2 Los fallbacks son silenciosos · crítico

Cuando un emisor no sabe qué hacer, no avisa:

| Sitio | Qué emite |
|---|---|
| traductor de Python | `# NODO_DESCONOCIDO`, un comentario donde iba una expresión |
| traductor matemático | `?` |
| serializador | `# desconocido` |
| operación desconocida | `count += 1  # adaptar si es necesario` |

→ Sin métodos por defecto: lo que falta es un error en tiempo de generación.

### 3.3 La emisión no está organizada por destino · grave

Todo esto lo resuelve la arquitectura de funciones genéricas con jerarquía de destinos:

- **Traductores paralelos.** `expr->py`, `expr->math` y `expr->nl` son tres `typecase` de unos 20 casos con la misma lista de nodos, sincronizados a mano. Ya divergieron (3.4).
- **Sin jerarquía.** El lenguaje destino vive en el nombre de la función, y nada se comparte entre lenguajes parecidos. Es lo que más costaría con los tres formatos del ILP.
- **La notación matemática no es un destino.** Solo existe como cadenas `print('...')` dentro del Python generado. No se puede obtener sin generar Python, las comillas no se escapan, y depende del registro de nombres de Python (`nombre-consulta-py`).
- **Indentación a mano.** Hay aritmética de profundidad repartida por los emisores.

→ `generate-code` despachado por (nodo, destino), con los destinos como clases.

### 3.4 El modelo matemático imprime fórmulas incorrectas · grave

- Las referencias a entidad salen como `?`: Saúl imprime `frecuencia(?)` y `tope(?)` en su modelo real.
- El cuantificador desaparece: una `tqpq` sale como `sesiones_del_plan(h, pl) = frecuencia(?)`, sin «para todo `pl` ∈ PLAN», así que la variable queda libre.
- Cada conjunto se nombra con la inicial de su entidad, y dos dominios que empiezan por la misma letra comparten símbolo.

### 3.5 El umbral de las prohibiciones se descarta · grave

`(op-mayor consulta 12)` compila a «devuelve el conteo»: el 12 desaparece. Es consecuencia de 1.1. En Saúl obligó a crear la entidad `jornada`, con 130 instancias, para guardar un número.

### 3.6 La suma no suma · grave

La operación `suma` emite `count += 1` y el valor de `:devuelve` no lo lee nadie. No se pueden sumar horas, costos ni personas. Afecta al dominio departamento y a la capacidad del SEDER.

### 3.7 Cableados para casos concretos · moderado

- `mostrar_resultado` imprime «Defensa {i}» en los cinco dominios, porque se escribió para tesis.
- `__str__` y la exportación a JSON tratan de forma especial los slots llamados `nombre` e `id`.
- `contar-distintos-dias` busca en Python atributos llamados `fecha` o `dia`, y en la notación matemática escribe siempre `fecha(...)`: docentes imprime `fecha(c)` aunque su atributo es `dia`.
- La tabla de predicados del verbalizador (`admite-doble`, `admite-tarde`, `es-contratado`) es de Saúl y vive en el léxico compartido.

→ Lo que depende del dominio lo declara el dominio o se deriva del modelo, nunca el emisor.

### 3.8 No hay política de identificadores por destino · menor

`py-nombre` y `math-nombre` son el mismo código. No se escapan las palabras reservadas de Python, y la `ñ` se resuelve con una excepción en el léxico.

---

## Capa 4 — Estrategia de resolución

### 4.1 Hay una sola estrategia y está fija · grave

`generar-python` llama siempre a `generar-algoritmo-genetico`. Representación, cruce, mutación, selección y evaluación se emiten en línea dentro de esa función. Probar una búsqueda local significa editar el emisor del genético.
→ La estrategia es una clase con sus parámetros, y sus operadores son funciones genéricas despachadas por estrategia y lenguaje.

### 4.2 La mutación tiene radio uno · crítico

En el SEDER, una instancia pequeña que se sabe resoluble, el genético se atasca a una o dos restricciones duras de la solución. Ninguno de los 216 vecinos posibles mejora el costo. Salir del atasco exige mover dos filas a la vez.

**Corrección medida:** el atasco no ocurre siempre. El genético viejo llegó a 0 duras en 2 de 3 semillas con 100 generaciones, y con los choques contados una vez la mutación de radio uno llega en 15 de 20. Mover dos filas e intercambiar sube a 18 de 20: ayuda, pero no es tan crítico como aquí se dice, y contar doble era buena parte del problema (2.2).

### 4.3 El costo no se memoriza · grave

`evaluar` se llama unas seis veces por individuo y generación. En Saúl, una corrida completa tarda unos tres días; memorizar el costo lo divide por seis.

### 4.4 La evaluación es cuadrática y no incremental · grave

Las colisiones comparan todas las parejas de filas.
→ Si el análisis reconoce la familia «choque», el emisor puede agrupar por celda y contar en tiempo lineal, sin cambiar el lenguaje.

### 4.5 No hay semilla aleatoria · grave

Dos corridas iguales dan resultados distintos: en el SEDER, 2012 y después 1012. Sin semilla no hay prueba de regresión ni comparación entre backends.

### 4.6 La población inicial es aleatoria · moderado

No hay reparación. En Saúl el algoritmo arranca con 599 restricciones duras incumplidas.

### 4.7 El criterio de parada está cableado a costo cero · menor

Con un `minimizar` el costo casi nunca llega a cero, y con un `maximizar` puede ser negativo.

---

## Capa 5 — Orquestación

### 5.1 No existe una capa de orquestación · grave

Todos estos problemas desaparecen al construir la capa:

- **`generar-python` es un monolito.** Escribe nueve secciones, en orden fijo, a un único archivo. Calcula nombres propios de Python, como `SESIONS` (un plural ingenuo) o `LISTA_DIA`, y los pasa a los demás generadores como diez argumentos posicionales.
- **El verbalizador duplica la entrada.** Copia `clases-macros.lisp` (idéntico), un extracto del generador, y una copia de cada dominio obtenida borrando cinco líneas.
- **Los dominios mezclan descripción y ejecución.** Cada `dominio.lisp` carga la infraestructura, llama a `generar-python` y termina con `sb-ext:exit`. Es la razón de que el verbalizador necesite copias.
- **Registros globales que se llenan como efecto lateral.** `*reg-consultas*` y `*consultas-por-nombre*` se llenan dentro de `generar-python`, así que el emisor matemático depende de que el de Python haya pasado antes.
- **Rutas que dependen del directorio actual.** Todo se carga con `(truename ".")`.

→ Una canalización de fases genéricas, especializables por destino y estrategia, que recibe un dominio que solo describe el problema. El verbalizador pasa a ser un destino más.

---