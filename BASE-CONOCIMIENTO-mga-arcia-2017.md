# Base de conocimiento: MGA — "Automatizar la creación de Generadores Multilenguajes" (Arcia Corcho, 2017)

> Documento de contexto para futuros chats. Consolida el análisis completo de la tesis de Yasmany Arcia Corcho sobre **MGA**, una herramienta en Common Lisp para automatizar la creación de Generadores Multilenguajes, y la conecta con el generador de horarios de este repositorio (`C:\Pro\tesis\restrictions_language-main`).
>
> Autocontenido: leyendo solo este documento se entiende qué propone la tesis, cuál es su maquinaria técnica (`defnode`, `gcode`, jerarquía de lenguajes) y qué implica para nuestro proyecto — en particular para el backend ILP descrito en [`BASE-CONOCIMIENTO-tesis.md`](BASE-CONOCIMIENTO-tesis.md).

---

## 0. Ficha del documento

| Campo | Valor |
|---|---|
| Título | *Automatizar la creación de Generadores Multilenguajes* |
| Autor | Yasmany Arcia Corcho |
| Tutor | MSc. Fernando Rodríguez Flores |
| Institución | Universidad de La Habana, Facultad de Matemática y Computación (MATCOM) |
| Tipo | Trabajo de Diploma — Licenciado en Ciencia de la Computación |
| Fecha | Mayo 2017 |
| Extensión | 66 páginas: Introducción + 4 capítulos + Conclusiones + Recomendaciones + Bibliografía (39 referencias) |
| Herramienta propuesta | **MGA** = *Multi-languages Generators Automation* |
| Archivo fuente | `C:\Users\rache\Downloads\38833FF26BA1D.UnigramPreview_g9c9v27vpyspw!App\2017-Yasmani-Arcia-Corcho.pdf` (el nombre del archivo dice "Yasmani"; la portada dice "Yasmany") |

**Estructura del documento:**
- Cap. 1 Preliminares (definiciones, DSLs, AST, Common Lisp: sintaxis, funciones, CLOS, macros)
- Cap. 2 Implementación de un Generador Multilenguaje (ejemplo guía: BASAR)
- Cap. 3 MGA (metodología, `defnode`, `gcode`, jerarquía de lenguajes)
- Cap. 4 Opciones de MGA (parámetros configurables de `defnode`, automatizar sintaxis con `gcode`)

**Dato del tutor (relevante para justificar el aporte):** en su opinión, cada Generador Multilenguaje desarrollado en MATCOM tardaba *un par de meses* en ser medianamente funcional y *más de un semestre* en ser realmente útil; con MGA esos tiempos bajan a *un par de días* y *un par de semanas*.

---

## 1. Tesis central

Un **Generador Multilenguaje (GM)** es una aplicación que define un DSL y permite exportar los programas escritos en él a varios lenguajes de salida. Construir uno tiene 6 pasos; **los pasos 4 y 6 son mecánicos y repetitivos**, y se pueden automatizar con el Sistema de Macros y el Sistema de Objetos de Common Lisp. MGA los automatiza mediante dos macros: **`defnode`** (paso 4) y **`gcode`** (paso 6).

### 1.1 Los 6 pasos de construcción de un GM

1. Determinar el dominio que se quiere representar en el DSL.
2. Identificar los elementos que se desean representar en el DSL.
3. Diseñar el lenguaje del DSL.
4. **Implementar una jerarquía de clases que represente cada elemento del DSL como nodo de un AST.**
5. Construir el analizador lexicográfico y el sintáctico.
6. **Implementar la generación de código de cada nodo del AST, en cada lenguaje de salida.**

### 1.2 Qué pasa con cada paso cuando el DSL es interno en Common Lisp

| Paso | Estado |
|---|---|
| 1, 2 | Dependen del dominio; se asumen ya resueltos (fuera del alcance) |
| 3 | Se reduce a **elegir buenos nombres** para los constructores de las clases del AST (la sintaxis siempre es `(nombre arg1 ... argN)`) |
| 4 | **Automatizado por `defnode`** |
| 5 | **Innecesario**: lo hace el intérprete de Lisp |
| 6 | **Simplificado por `gcode`** + jerarquía de lenguajes |

> Este es el argumento de fondo de toda la tesis: en Lisp, un DSL interno elimina el paso 5 por completo y convierte los pasos 4 y 6 en rellenado de plantillas, y **rellenar plantillas es exactamente lo que hacen las macros**.

---

## 2. Definiciones formales (Cap. 1, §1.1)

La tesis enuncia cinco definiciones que conviene citar literalmente porque fijan el vocabulario:

- **Definición 1 — Generador Multilenguaje:** aplicación que define un DSL y permite que los programas escritos en él puedan ser representados o exportados a varios lenguajes.
- **Definición 2 — Dominio de un GM:** el área de trabajo en que se especializa.
- **Definición 3 — Elemento del dominio:** representa una parte específica del área de trabajo.
- **Definición 4 — Lenguaje de salida:** lenguaje en el cual se desea representar los programas escritos en un GM.
- **Definición 5 — GM extensible:** el que permite agregar nuevos lenguajes de salida.

Ejemplos que da: Markdown y ORG-Mode (dominio: edición de documentos; salidas: HTML, LaTeX, ODT), ADOL\* (dominio: Diferenciación Automática; salida: cualquier lenguaje con sobrecarga de operadores).

### 2.1 Las 5 etapas de construcción de un DSL (literatura)

Decisión → Análisis → Diseño → Implementación → Despliegue. MGA asume cumplidas las tres primeras y trabaja sobre **Implementación**.

### 2.2 DSL interno vs externo

- **Internos**: viven dentro de la sintaxis de un lenguaje anfitrión, normalmente como bibliotecas (Rails en Ruby, ASP.NET Core, CLOS, Entity Framework).
- **Externos**: sintaxis propia, requieren compilador (MATLAB, Graphviz, R).

MGA produce **DSLs internos en Common Lisp**.

---

## 3. Trabajos previos de MATCOM que MGA generaliza

Esto es importante: **MGA no salió de la nada, es la extracción del patrón común de cuatro tesis previas del mismo grupo**.

| Sistema | Autor / referencia | Dominio |
|---|---|---|
| **ADOL\*** | Manuel Alejandro Cabrera Castillo | Bibliotecas de Diferenciación Automática |
| **LAML** | Jorge Luis Hoyos, 2017 — *"Un Lenguaje para representar Modelos Matemáticos en Lisp"* | **Modelos de programación matemática** |
| **IVNS** | Camila Pérez Mosquera, 2017 | Criterios de vecindad en enrutamiento de vehículos (búsqueda de vecindad infinitamente variable) |
| **GEMURAL** | Antonio Rodríguez Alayón | Generación multilenguaje de rutinas de Álgebra Lineal |

Los tres primeros usan la misma función genérica `generate-code`; ADOL\* y GEMURAL aportaron las jerarquías de lenguajes; ADOL\* aportó la versión original de `gcode`.

> **LAML es el antecedente más relevante para nuestro backend ILP**: es un GM en Lisp cuyo dominio son precisamente los *modelos de programación matemática*. Si se busca bibliografía interna para justificar el backend de modelo matemático, LAML (Hoyos, 2017) es la cita natural, y esta tesis la referencia como [17].

---

## 4. BASAR: el ejemplo guía (Cap. 2)

**BASAR** (*Basic Arithmetic Operations*) es un GM mínimo que sirve de hilo conductor. Dominio: expresiones aritméticas con variables, asignación e impresión.

Elementos del dominio: Suma, Multiplicación, Asignación a variable, Referencia a variable, Imprimir.

La expresión `X = 5 + Y * 2` se escribe en el DSL interno como:

```lisp
(assign-to X (+ 5 (* Y 2)))
```

y genera, en tres lenguajes de salida:

```
X = 5 + Y * 2;        ; C#
X <- 5 + Y * 2        ; R
(setf X (+ 5 (* Y 2))) ; Common Lisp
```

Jerarquía de nodos de BASAR: clase abstracta `binary-operator` (slots `left-hand`, `right-hand`), de la que heredan `sum-node` y `mult-node`; más `variable-assignment-node`, `variable-reference-node`, `print-node`.

**Notación `G(X)`** que usa la tesis para especificar la generación de código: la asignación en C# es `G(parte-izq) = G(parte-der)`, la suma es `G(parte-izq) + G(parte-der)`, imprimir es `Console.WriteLine(G(A))`, etc. Es decir: *plantilla de texto con huecos, donde cada hueco es la generación de código de un descendiente*. Esa observación es la que se cristaliza en `gcode`.

---

## 5. `defnode` — automatizar los nodos del AST (Cap. 3 §3.2, Cap. 4 §4.1)

### 5.1 El problema

Definir un nodo del AST en CLOS son **dos plantillas a rellenar**:

1. `defclass` + nombre + superclases + slots, donde cada slot repite `:accessor <nombre>` `:initarg :<nombre>` (¡el mismo nombre tres veces!).
2. Una **función constructora** (`defun`) cuyos parámetros corresponden a los slots y cuyo cuerpo es un `make-instance` que vuelve a repetir esos nombres.

La tesis muestra las 5 clases + 5 constructores de BASAR escritos a mano: decenas de líneas donde el único contenido real son los nombres.

> **Terminología que fija la tesis:** *función constructora* = función/método/macro ordinario que recibe los valores y devuelve una instancia vía `make-instance`. En un DSL interno, **las funciones constructoras SON las palabras clave del lenguaje**, y evaluar un programa del DSL produce directamente el AST.

### 5.2 La solución

```lisp
(defnode sum-node () (left-hand right-hand))
```

expande a:

```lisp
(defclass sum-node ()
  ((left-hand  :accessor left-hand  :initarg :left-hand)
   (right-hand :accessor right-hand :initarg :right-hand)))

(defun sum-node (left-hand right-hand)
  (make-instance 'sum-node
    :left-hand left-hand
    :right-hand right-hand))
```

**Lambda list de `defnode`:** `(nombre (superclases) (slots) &rest opciones-nombradas)`.

**`defabsnode`** es la variante para declarar una clase **abstracta** (p. ej. `binary-operator`).

> **Errata de la tesis (p. 30):** el bloque de ejemplo escribe `(defnode sum-node () (binary-operator) ())` con cuatro argumentos, inconsistente con la lambda list de §4.1 y con la línea siguiente `(defnode variable-assignment-node (binary-operator) ())`. La forma correcta es `(defnode sum-node (binary-operator) ())`. Anotado por si se reutiliza el diseño.

### 5.3 Valores por defecto que rellena `defnode`

Si el elemento de la lista de slots es un **símbolo**, se rellenan automáticamente:

```lisp
:accessor      <nombre-del-slot>
:initarg       :<nombre-del-slot>
:allocation    instance
:initform      nil
:documentation "empty"
```

Si es una **lista**, el usuario declara las opciones que quiera y esas sustituyen a las generadas:

```lisp
(defnode collection-definition-node ()
  (collection-name
   collection-type
   (collection-capacity :initarg :capacity :initform 100)))
```

### 5.4 Opciones nombradas de `defnode`

| Opción | Qué controla | Ejemplo |
|---|---|---|
| `:func-name` | nombre de la función constructora (por defecto, el de la clase) | `(:func-name collection-insert)` |
| `:lambda-list` | lambda list del constructor (por defecto: los `initarg` de los slots, en orden de declaración) | `:lambda-list (name &rest value)` → permite `(collection-insert-range coll 4 5 6 7)` |
| `:ctr-body` | cuerpo del constructor; acepta cualquier código Lisp válido | `(:ctr-body (make-instance 'collection-insert-node :name name :value value))` |

**Principio de diseño explícito de la tesis:** *"El código generado por `defnode` es completamente modificable"*. Los defaults cubren el 90 % mecánico; las opciones nombradas permiten escapar del molde sin abandonar la macro. Esto es el Cap. 4 entero.

### 5.5 Caso motivador de escala

`class-definition-node` de ADOL\* (una biblioteca de Diferenciación Automática necesita definir clases con campos valor/derivada y sobrecargar operadores) tiene 7 slots: `class-name`, `class-parent`, `slots-definitions`, `constructor`, `operator-overloads`, `functions-definitions`, `methods-definitions`. A mano son ~30 líneas de `defclass`; con `defnode`, 8 líneas.

---

## 6. `gcode` — automatizar la generación de código (Cap. 3 §3.3, Cap. 4 §4.2)

### 6.1 La base: la función genérica `generate-code`

Toda la generación multilenguaje descansa en **una sola función genérica de tres parámetros**:

```lisp
(defgeneric generate-code (node language stream))
```

Sus métodos se especializan simultáneamente en **(nodo del AST × lenguaje de salida)** y escriben en un flujo `stream`:

```lisp
(defmethod generate-code ((node sum-node) (lang csharp) stream)
  (format stream "~a + ~a"
          (generate-code (left-hand node) lang nil)
          (generate-code (right-hand node) lang nil)))
```

> **Esta es la pieza arquitectónica más importante de la tesis.** El despacho múltiple de CLOS sobre `(nodo, lenguaje)` es lo que convierte "agregar un lenguaje de salida" en "agregar un conjunto de métodos", sin tocar nada existente. Es la razón declarada por la que se eligió Common Lisp.

### 6.2 `gcode` versión ADOL\* (la original)

El patrón mecánico es: *cadena de texto con variables, donde las variables se sustituyen por el `generate-code` de los descendientes*. ADOL\* lo encapsuló así:

```lisp
(gcode sum-node csharp "~a+~a" left-hand right-hand)
```

Argumentos: nodo, lenguaje, cadena de `format`, y luego los slots a incluir.

**Limitación:** deja de servir cuando la generación no cumple exactamente ese patrón. El caso que rompe el molde es la **indentación de Python**: el nodo `while` debe *aumentar* la indentación para su cuerpo y luego restaurarla. Con el `gcode` de ADOL\* la única salida era escribir el `defmethod` a mano.

### 6.3 `gcode` versión MGA (la contribución)

MGA generaliza `gcode` a **dos listas paralelas**: la primera con cadenas de texto *o código Lisp*; la segunda con listas de slots.

```lisp
(gcode while python
  ("while (~a):~%" indent "~a~%" deindent)
  ((condition) (body)))
```

Regla de expansión: **por cada cadena de la primera lista se emite un `format`** con el `generate-code` de los slots de la lista correspondiente; **si el elemento no es una cadena, se considera código Lisp y se inserta tal cual en la macroexpansión**. La expansión resultante:

```lisp
(defmethod generate-code ((node while) (lang python) stream)
  (format stream "while (~a):~%" (generate-code (condition node) python nil))
  indent
  (format stream "~a" (generate-code (body node) python nil))
  deindent
  (format stream "~%" nil))
```

> **La idea clave: `gcode` deja de ser una plantilla cerrada y pasa a ser una plantilla con puntos de inyección de código arbitrario.** Es el mismo movimiento que `defnode` hace con `:ctr-body`: defaults mecánicos + escotilla de escape. Ese es, en una frase, el patrón de diseño de MGA completo.

### 6.4 `recognize-pattern` — automatizar propiedades sintácticas

`(recognize-pattern symbol code)` le indica a `gcode` que, **en cada macroexpansión**, sustituya `symbol` por `code` (código Lisp válido). Así, registrando `indent` → función que aumenta la indentación actual y `deindent` → función que la disminuye, los símbolos `indent`/`deindent` del ejemplo anterior pasan a ser vocabulario del generador.

### 6.5 `mark-node-as-indentable` — el caso de estudio de automatización

Para automatizar la indentación se identifican **tres tipos de nodos** frente a un lenguaje indentable:

1. Los que **aumentan** la indentación de sus descendientes (`if`, `while` en C#, Java, Python).
2. Los que **requieren** indentación (`if`, `while`, asignación a variable).
3. Los que **no la requieren** (operaciones aritméticas en C#).

> **Observación fina de la tesis:** *"La indentación de un nodo del AST no depende de él, sino del lenguaje"* — el mismo nodo es indentable en Python y no en C#. Por eso la propiedad no puede vivir en la clase del nodo; tiene que vivir en el cruce (nodo × lenguaje), que es justo lo que el despacho múltiple de CLOS modela.

Implementación: un método auxiliar `:before` sobre `generate-code`, especializado en el nodo y en `indentable-language`, que escribe los espacios antes de generar el nodo:

```lisp
(defnode indentable-language () (indentation indent-increment))

(defmethod generate-code :before ((node node-type)
                                  (language indentable-language)
                                  stream)
  ...)
```

encapsulado en un macro de un solo uso:

```lisp
(mark-node-as-indentable while language)
```

Los **métodos auxiliares de CLOS** (`:before`, `:after`, `:around`) son, según la tesis, la herramienta general para automatizar características sintácticas transversales.

---

## 7. Jerarquía de lenguajes (Cap. 3 §3.3.2)

Los lenguajes de salida **también son clases**, y la herencia múltiple de CLOS permite factorizar sus propiedades sintácticas comunes. Clases identificadas en ADOL\* y GEMURAL:

| Clase de lenguaje | Propiedad que representa |
|---|---|
| `Infix-Language` | notación infija para expresiones aritméticas |
| `Camel-Case-Language` | variables y funciones en Camel-Case |
| `Indent-Language` | usa indentación (Python, C#) |
| `Symbol-Separated-Language` | instrucciones separadas por un símbolo (`;` en C#) |
| `Basic-Operation-Language` | operadores `+ * / < >` con los símbolos habituales |

Composición: `C-like` hereda de las cuatro/cinco anteriores; luego `C#` y `Java` heredan de `C-like` y solo hay que definir lo que ellos añaden.

**Consecuencia:** agregar un lenguaje de salida nuevo cuesta proporcionalmente a lo que ese lenguaje tiene de *distinto*, no a su tamaño total. Esa es la definición operativa de "GM extensible" (Definición 5).

---

## 8. Conclusiones y recomendaciones de la tesis

### 8.1 Conclusiones

1. Se identificaron las etapas principales de construcción de un GM.
2. Se presentó una **metodología** para desarrollarlos en Common Lisp.
3. Se automatizó la escritura de código repetido y mecánico con dos macros: **`defnode`** (clases + funciones constructoras) y **`gcode`** (generación de código, inspirado en una funcionalidad previa de ADOL\*).
4. Con MGA, **definir el DSL se reduce a elegir bien los nombres y los campos** de los elementos del dominio; y **la generación de código se reduce a encontrar patrones repetidos, encapsularlos, y escribir solo lo diferente**.

### 8.2 Recomendaciones (trabajo futuro que la tesis deja abierto)

- Automatizar nuevas características comunes en la sintaxis de los lenguajes.
- Admitir **macros** como posibles funciones constructoras (hoy solo `defun`).
- Agregar nuevas funciones o métodos en la macroexpansión de `defnode`.

---

## 9. Relación con NUESTRO proyecto (generador de horarios)

Esta sección es la que hace útil el documento. Contrasta MGA con lo que ya existe en `C:\Pro\tesis\restrictions_language-main`.

### 9.1 Nuestro generador YA ES un Generador Multilenguaje

Según la Definición 1, un GM define un DSL y exporta a varios lenguajes de salida. Nuestro generador cumple: define el DSL de horarios (`def-entidad`, `def-comb`, `def-consulta`, `def-nppq`, …) y **ya tiene dos lenguajes de salida** sobre el mismo AST:

| Lenguaje de salida | Traductor | Archivo |
|---|---|---|
| Python (evaluador + GA) | `expr->py` | [gen-ast-python.lisp:36](../generador-horarios/lib/gen-ast-python.lisp) |
| Notación matemática legible | `expr->math` | [gen-ast-math.lisp:16](../generador-horarios/lib/gen-ast-math.lisp) |

Ambos son un `typecase` gigante sobre las clases de nodo, con **la misma lista de casos** (`op-igual`, `op-distinto`, `op-mayor`, `op-suma`, `op-and`, `op-or`, `op-not`, `acceso-a-atributo-de-entidad`, `consulta-simple`, …) y cuerpos que difieren solo en la cadena de formato:

```lisp
;; gen-ast-python.lisp          ;; gen-ast-math.lisp
(op-igual    (bin->py nodo "==")) (op-igual    (bin->math nodo " = "))
(op-distinto (bin->py nodo "!=")) (op-distinto (bin->math nodo " ≠ "))
(op-mayor    (bin->py nodo ">"))  (op-mayor    (bin->math nodo " > "))
```

> **Ese paralelismo literal entre los dos archivos es exactamente el código repetitivo que MGA existe para eliminar.** En vocabulario de la tesis: tenemos dos lenguajes de salida implementados como dos `typecase` monolíticos en vez de como métodos de una función genérica `generate-code` despachada por `(nodo, lenguaje)`.

### 9.2 `def-clase` ≈ `defnode` (redescubrimiento independiente)

`generador-horarios/lib/clases-macros.lisp` contiene una familia de macros que resuelve **el mismo problema que `defnode`**, con el mismo enfoque:

| Nuestro macro | Línea | Equivalente MGA |
|---|---|---|
| `def-clase nombre padres slots &rest params-extra` | [51](../generador-horarios/lib/clases-macros.lisp) | `defnode` |
| `def-nodos` (varias clases hijas de `nodo-ast` en una forma) | [105](../generador-horarios/lib/clases-macros.lisp) | — (MGA no lo tiene) |
| `def-jerarquias` / `def-subclases` | [114](../generador-horarios/lib/clases-macros.lisp) / [124](../generador-horarios/lib/clases-macros.lisp) | — (MGA no lo tiene) |
| `defclass*` | [209](../generador-horarios/lib/clases-macros.lisp) | — |
| `%expand-slot` (formato compacto de slot → canónico) | [29](../generador-horarios/lib/clases-macros.lisp) | rellenado de defaults de slots de `defnode` |

Coincidencias conceptuales exactas:

- `def-clase` genera `defclass` + constructor + funciones de acceso, igual que `defnode` genera `defclass` + función constructora.
- El constructor por defecto se llama `DEF-<NOMBRE>`; `defnode` usa `<NOMBRE>`. Ambos permiten **override**: nuestro `:fn-name` ≡ el `:func-name` de MGA.
- Nuestro `:key` / `:variadic` / lista de params explícita ≡ el `:lambda-list` de MGA (misma necesidad, resuelta con tres casos preconfigurados en vez de con un lambda list libre).
- `%expand-slot` acepta `(nombre accessor)` o `(nombre :initarg-kw acc)` o forma canónica — el mismo "símbolo → defaults / lista → explícito" de `defnode`.

Diferencias donde **nosotros vamos por delante**:

- `def-nodos`, `def-jerarquias` y `def-subclases` declaran **grupos** de nodos en una sola forma. MGA no tiene equivalente; su recomendación de trabajo futuro "agregar nuevas funciones o métodos en la macroexpansión de `defnode`" apunta hacia ahí.
- `def-clase` genera además **funciones de acceso AST** (`(defun <acc> (entidad) (def-acceso-a-atributo-de-entidad ...))`), que es un nivel de indirección que MGA no contempla.

Diferencias donde **MGA va por delante**:

- `:ctr-body` (cuerpo del constructor arbitrario). Nuestro `def-clase` siempre emite un `make-instance` fijo (o un `reduce` en el caso `:variadic`).
- Toda la mitad de `gcode`: nosotros **no tenemos** el equivalente del paso 6 automatizado.

### 9.3 Lo que falta: la mitad `gcode`

**Este es el hallazgo principal de la comparación.** Nuestro proyecto automatizó el paso 4 (con `def-clase`/`def-nodos`) pero **no el paso 6**: la generación de código está escrita a mano, dos veces, en `gen-ast-python.lisp` y `gen-ast-math.lisp`, más los generadores estructurales (`gen-consultas.lisp`, `gen-restricciones.lisp`, `gen-visualizacion.lisp`, `gen-metaheuristica.lisp`, `gen-serializar.lisp`).

Adoptar el esquema MGA significaría:

1. Convertir `expr->py` / `expr->math` en métodos de `(defgeneric generate-code (nodo lenguaje stream))`, con clases `python` y `math` como lenguajes de salida.
2. Reescribir los casos triviales con `gcode`: `(gcode op-igual python "~a == ~a" operando-izq operando-der)`, `(gcode op-igual math "~a = ~a" operando-izq operando-der)`.
3. Introducir la jerarquía de lenguajes: nuestro Python generado es `Infix-Language` + `Indent-Language` + `Basic-Operation-Language`; la notación matemática es infija pero no indentada. La indentación de Python ya la manejamos con `py-indent` en `gen-utils.lisp` — el caso de estudio del Cap. 4 de la tesis es **literalmente nuestro caso**.

### 9.4 Implicaciones para el backend ILP

Ver [`BASE-CONOCIMIENTO-tesis.md`](BASE-CONOCIMIENTO-tesis.md) para el diseño completo del backend de modelo matemático. Cruzándolo con MGA:

**A favor (lo que MGA aporta):**

- El backend ILP es, en vocabulario de la tesis, **un tercer lenguaje de salida** (PuLP / CP-SAT / MiniZinc). La Definición 5 —"GM extensible"— es exactamente la propiedad que nuestra tesis quiere demostrar con él, y MGA da el marco conceptual y el vocabulario para enunciarlo.
- La **jerarquía de lenguajes** encaja bien con los tres formatos destino: PuLP, CP-SAT y MiniZinc comparten "modelo declarativo con variables, restricciones lineales y objetivo" y difieren en sintaxis. Una clase `Solver-Model-Language` con hijos `pulp`, `cp-sat`, `minizinc` es la aplicación directa del §7 de este documento.
- El despacho `(nodo, lenguaje)` permite añadir el backend ILP **sin tocar los métodos de Python ni de math** — el mismo argumento de "el DSL es agnóstico al backend" de la conclusión 1 del informe ILP, pero sostenido por un mecanismo del lenguaje en vez de por disciplina.
- `recognize-pattern` es el mecanismo natural para inyectar el vocabulario del emisor ILP (declarar variable auxiliar, abrir sumatoria, cerrar restricción) en las plantillas.

**En contra / límite importante (no confundir):**

- `gcode` automatiza traducción **sintáctica, composicional, nodo a nodo**. El backend ILP **no es composicional**: como establece el §3 del informe ILP, `op-and` no se linealiza multiplicando booleanos, y el backend tiene que reconocer la *forma completa* de la restricción (cuantificador + consulta) para mapearla a un idioma de OR (packing, covering, minimax).
- Por tanto MGA aplica al backend ILP **solo en su capa de emisión** (imprimir la inecuación ya construida en la sintaxis de PuLP/MiniZinc, es decir el módulo `gen-ilp-emit.lisp` del §10.3 del informe ILP). **No aplica** a la capa de *matcher/emitter* (`gen-ilp-patrones.lisp`), que es reconocimiento de patrones sobre subárboles, no traducción de nodos.
- Dicho de otro modo: MGA asume que "generar código de un nodo" = "cadena con huecos rellenados por los hijos". Esa hipótesis vale para Python y para la notación matemática; **se rompe para el modelo ILP**, y caracterizar por qué se rompe es un resultado publicable de nuestra tesis (conecta con la "frontera de expresividad linealizable", §10.6 del informe ILP).

### 9.5 Cómo citar esta tesis en nuestro documento

Usos naturales en el capítulo de preliminares / estado del arte:

- Definiciones 1–5 (GM, dominio, elemento del dominio, lenguaje de salida, extensibilidad) — vocabulario listo para reutilizar.
- Los 6 pasos de construcción de un GM y el argumento de por qué el paso 5 desaparece en un DSL interno en Lisp.
- Las 5 etapas de construcción de un DSL (Decisión/Análisis/Diseño/Implementación/Despliegue) con sus referencias [15][32][24].
- El linaje MATCOM (ADOL\*, LAML, IVNS, GEMURAL) para situar nuestro trabajo en una línea de investigación del grupo — **LAML en particular**, por ser el GM de modelos matemáticos.
- El argumento CLOS: despacho múltiple + herencia múltiple + métodos auxiliares como sustrato de la generación multilenguaje.

Bibliografía de la tesis reutilizable directamente (numeración original): [15] Voelter et al., *DSL Engineering*; [24] Mernik, *Formal and Practical Aspects of DSLs*; [32] van Rossum et al., *Language Implementation Patterns*; [5] Aho & Ullman, *The Theory of Parsing, Translation and Compiling*; [12] Graham, *On Lisp*; [13] Graham, *ANSI Common Lisp*; [33] Keene, *OOP in Common Lisp*; [34] Seibel, *Practical Common Lisp*; [18] Hoyte, *Let Over Lambda*; [6] Barski, *Land of Lisp*; [17] Hoyos, *LAML*.

---

## 10. Resumen ejecutivo en cinco frases

1. MGA automatiza los pasos 4 y 6 de la construcción de Generadores Multilenguajes en Common Lisp, mediante `defnode` (clases + constructores del AST) y `gcode` (generación de código).
2. Su arquitectura descansa en una única función genérica `generate-code (nodo lenguaje stream)` despachada por CLOS sobre el par (nodo, lenguaje), más una jerarquía de clases de lenguajes con herencia múltiple.
3. Su patrón de diseño recurrente es **defaults mecánicos + escotilla de escape**: `:func-name`/`:lambda-list`/`:ctr-body` en `defnode`, inserción de código Lisp arbitrario y `recognize-pattern` en `gcode`.
4. Nuestro generador de horarios ya reimplementó de forma independiente la mitad `defnode` (`def-clase`, `def-nodos`, `def-jerarquias`), pero **no** la mitad `gcode`: `expr->py` y `expr->math` son dos `typecase` paralelos escritos a mano.
5. El backend ILP es, en este vocabulario, un tercer lenguaje de salida; MGA le sirve como marco y como capa de emisión, pero **no** como mecanismo de traducción, porque la linealización no es composicional nodo a nodo.
