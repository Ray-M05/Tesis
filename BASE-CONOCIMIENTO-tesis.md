# Base de conocimiento: tesis del generador de horarios

> Documento de contexto para futuros chats. Reúne todo lo investigado sobre la tesis: qué es el proyecto, cómo funciona el DSL y su generador, qué problemas describe, hasta dónde llega el lenguaje y dónde se rompe, el diseño del segundo backend de modelo matemático exacto (PARTE IV) y el backend de lenguaje natural, **ya implementado** (PARTE VI). Autocontenido: leyendo solo este documento se entiende el proyecto completo, las decisiones tomadas, la matemática, la arquitectura propuesta y los entregables producidos.
>
> **Novedad importante para la PARTE IV:** el verbalizador implementó, sin proponérselo, el reconocedor de patrones que el backend ILP daba por pendiente. Ver **§30.4**, que recoge ocho hallazgos sobre el modelo matemático surgidos al construirlo.
>
> **Novedad de noviembre de 2026: la reimplementación por capas (PARTE VII).** El proyecto se rehace en una carpeta nueva, `C:\Pro\tesis\problemas_de_asignacion\`, organizada en cinco capas y con las deficiencias del generador corregidas. La PARTE VII explica qué se busca, dónde están el inventario y el plan, qué se ha decidido y en qué estado está cada etapa. **Varias afirmaciones de este documento y de `base_de_conocimiento.md` quedaron corregidas por esa línea de trabajo; ver §37.**
>
> Este documento se llamaba antes `BASE-CONOCIMIENTO-backend-ilp.md` y cubría solo el backend ILP. Se amplió para recoger toda la investigación sobre la tesis, no únicamente esa línea de trabajo. Toda investigación nueva entra aquí.

> **Bases de conocimiento relacionadas.** Para todo lo referido a **Generadores Multilenguajes, la herramienta MGA, los macros `defnode` / `gcode`, la función genérica `generate-code`, la jerarquía de clases de lenguajes de salida y el linaje de trabajos de MATCOM (ADOL\*, LAML, IVNS, GEMURAL)**, consultar [`BASE-CONOCIMIENTO-mga-arcia-2017.md`](BASE-CONOCIMIENTO-mga-arcia-2017.md) — análisis de la tesis de Yasmany Arcia Corcho (UH/MATCOM, 2017), *Automatizar la creación de Generadores Multilenguajes*. Ese documento cubre además la comparación entre MGA y nuestro `clases-macros.lisp`, y qué partes de MGA aplican y cuáles **no** aplican al backend ILP (ver su §9.4).

---

# PARTE I — EL PROYECTO

## 1. Qué es

Es una tesis sobre un DSL (lenguaje específico de dominio) escrito en Common Lisp que describe problemas de horarios de forma declarativa y **genera código** a partir de esa descripción. El repositorio está en `C:\Pro\tesis\restrictions_language-main`.

Estructura relevante del repo:
- `generador-horarios/` — el generador y los tres dominios de ejemplo.
  - `lib/` — la infraestructura del generador (macros del DSL, AST, traductores, generadores de código).
  - `tesis/`, `docentes/`, `tv/` — cada uno con un `dominio.lisp` (la descripción del problema) y un `horario.py` (el código Python generado).
- `doc/` — la tesis en LaTeX (`Salma_Fonseca_Curbelo.tex` y capítulos `cap1`..`cap6`, `conclusiones`, etc.). El capítulo que describe los tres problemas en lenguaje natural es `doc/cap3-dom/cap3-dom.tex`.
- `descripcion-horarios/` — descripciones en markdown de cada dominio.
- `informe-modelo-matematico/` — informes y bases de conocimiento.
- `inputs-usuario.md` — descripciones en lenguaje natural de los cuatro dominios más el input en el DSL (ver §16).
- `limitaciones-del-dsl.md` — qué resuelve el lenguaje y dónde se rompe (ver §17).

> **FUERA DEL REPO — el verbalizador.** El tercer backend (DSL → prosa española) está implementado y funcionando en **`C:\Pro\tesis\verbalizador`**, un sandbox aislado que **no toca este repositorio**. Copió de aquí `lib/clases-macros.lisp`, `lib/gen-utils.lisp` y un extracto verbatim de otros tres archivos. Ver **PARTE VI** y en especial **§30**.
>
> Sus dos documentos, en `C:\Pro\tesis\verbalizador\doc\`:
> - **`informe_verbalizador.md`** — informe autocontenido. Su sección «Lo que esto enseñó sobre el modelo matemático» es material directo para la PARTE IV.
> - **`PLAN-IMPLEMENTACION.md`** — plan operativo por fases, con casos borde y decisiones.

El flujo actual: se escribe un `dominio.lisp` que usa las macros del DSL para declarar entidades, consultas y restricciones; se ejecuta con SBCL; el generador compila esa descripción (un AST) a un `horario.py` autónomo que contiene un **algoritmo genético (GA)** que busca una asignación de bajo costo.

`pdflatex` de MiKTeX está en `C:\Users\rache\AppData\Local\Programs\MiKTeX\miktex\bin\x64`.

> **Nota sobre herramientas:** codegraph solo indexa los seis `.py` (los tres `horario.py` generados y tres `_run_*.py`). **No indexa los `.lisp`**, que es donde vive el DSL. Para leer el lenguaje hay que usar Read/Grep directamente. Codegraph sirve para verificar la forma del problema ya compilada (identidad, slots variables, clases de entidad).

---

# PARTE II — EL DSL Y SU GENERADOR

## 2. Cómo funciona el generador actual (pipeline de generación de código)

### 2.1 Las macros del DSL (`lib/clases-macros.lisp`)

Definen tanto el AST como las macros de dominio:
- `def-entidad nombre (mixins) (slots)` — define una entidad (p. ej. profesor, aula). Genera clase, constructor `def-NOMBRE`, funciones de acceso AST y registra sus slots. Cada `(def-NOMBRE instancia args...)` crea una instancia y la registra en la tabla global `*instancias-de-entidad*` (mapa nombre-entidad → lista de símbolos de instancias).
- `def-comb nombre (componentes)` — entidad combinación (una fila del horario), p. ej. `(def-comb asignacion (tribunal fecha momento local))`.
- `def-consulta nombre params :itera-sobre (v dom)... :comprueba <cond> :operacion <op> :devuelve <r>` — crea un nodo `consulta-simple`. La operación puede ser `suma`, `contar`, `contar-distintos-dias`.
- `def-nppq`, `def-tqpq`, `def-ndpq`, `def-sbqp`, `def-minimizar`, `def-maximizar` — crean nodos `cuantificador-restriccion`.
- `def-problema-horario` — crea la estructura `problema-horario` (ver 2.3).

### 2.2 El AST (nodos, con sus slots exactos)

- `consulta-simple` — slots: `args`, `variable-iteracion`, `dominio-iteracion`, `comprobacion`, `operacion`, `retorno`.
- `cuantificador-restriccion` (padre de `nppq`, `tqpq`, `ndpq`, `sbqp`, `minimizar`, `maximizar`) — slots: `operador`, `comprobacion`, `elemento`.
- Operadores lógicos: `op-and`, `op-or` (variádicos), `op-not`.
- Comparaciones: `op-igual`, `op-distinto`, `op-mayor`, `op-menor`, `op-mayor-igual`, `op-menor-igual`.
- Aritméticos: `op-suma`, `op-resta`, `op-multiplicacion`, `op-division`.
- Acceso a datos: `acceso-a-atributo-de-entidad`, `acceso-a-elemento-de-comb`, `pertenece`, `hay-elementos-duplicados`.

> `hay-elementos-duplicados` está **declarado pero muerto**: ningún dominio lo usa y `expr->py` no lo traduce, así que hoy emitiría `# NODO_DESCONOCIDO`. Es el hueco donde iría un `alldifferent`.

### 2.3 La estructura `problema-horario` (`lib/generador.lisp`)

Campos: `entidad-horario`, `slot-identidad`, `slots-variables`, `consultas`, `restricciones-duras`, `restricciones-blandas`, `peso-dura` (default 1000), `peso-blanda` (default 1), parámetros del GA (`pop-size` 100, `generaciones` 500, `prob-cruce` 0.8, `prob-mutacion` 0.15, `torneo-k` 5), y **dos fotos capturadas** al crear el problema: `instancias` (copia de `*instancias-de-entidad*`) y `slots-entidades` (copia de `*slots-de-entidad*`).

> Detalle clave: gracias a esas dos fotos, el generador es una **función pura** que no depende de estado global mutable. Esto es lo que permite que un backend ILP precompute datos leyendo `problema-horario-instancias`.

### 2.4 Los traductores y generadores (`lib/`)

`generador.lisp` orquesta y carga:
- `gen-utils` — `py-nombre`, `py-indent`, `math-nombre`.
- `gen-ast-python` — `expr->py` (traduce un nodo AST a una cadena Python), registro `*reg-consultas*`.
- `gen-ast-math` — `expr->math` (traduce un nodo AST a notación matemática legible para humanos), `*consultas-por-nombre*`.
- `gen-serializar` — serializa las instancias del dominio a Python (`instancia->py`).
- `gen-consultas` — `recolectar-dominios`, `generar-funcion-consulta` (emite una función Python por consulta: bucles `for` anidados sobre los dominios, un `if` con la comprobación, y un acumulador según la operación).
- `gen-restricciones` — `tipo-restriccion`, `generar-funcion-restriccion`, `generar-cuerpo-nppq-ndpq`, `generar-cuerpo-tqpq-sbqp`, `generar-cuerpo-cuantificado`. Cada restricción se vuelve una función Python que **cuenta cuántas veces se incumple**.
- `gen-visualizacion` — `generar-mostrar-modelo`, `generar-mostrar-resultado`.
- `gen-metaheuristica` — `generar-algoritmo-genetico`.

### 2.5 Estructura del `horario.py` generado

1. Cabecera (imports, UTF-8).
2. Clases de entidad (`@dataclass`).
3. Clase `Horario` (un campo lista por cada dominio usado).
4. Funciones de consulta.
5. Funciones de restricción (cada una devuelve el nº de incumplimientos).
6. `evaluar(horario) = PESO_DURA * sum(duras) + PESO_BLANDA * sum(blandas)`.
7. Visualización del modelo y del resultado, export a JSON.
8. El algoritmo genético.

> **Punto central para el backend ILP:** en el mundo actual, las consultas iteran **sobre una solución ya construida** (`horario.asignacion`) y la puntúan. Es un *evaluador imperativo*. El GA propone soluciones y esta función las evalúa. La idea `expr->py` es **sintáctica**: nodo → cadena.

### 2.6 La forma de solución que impone el generador

`crear_horario_aleatorio` construye **una fila por identidad**, eligiendo para cada slot variable un valor al azar del pool correspondiente. Esa es la representación del GA y define, de raíz, qué puede expresar el sistema: **una función total de identidades a tuplas de valores**. No hay identidades sin asignar, ni identidades con dos valores, ni longitud variable.

---

## 3. Qué puede y qué no puede expresar el DSL

Análisis hecho leyendo `gen-consultas.lisp`, `gen-restricciones.lisp` y `gen-ast-python.lisp`. Sintetizado en [`limitaciones-del-dsl.md`](../limitaciones-del-dsl.md) (§17).

### 3.1 La familia de problemas que cubre

Todo lo que el lenguaje describe tiene una única forma: **una función total de un conjunto de identidades a un producto de pools**, con restricciones que son conteos sobre esa función comparados contra cero o contra una constante.

Eso es la familia de asignación *multiple-choice*, y no está atada al tiempo. Entran: coloreado de grafos, asignación de frecuencias, reparto de tareas a máquinas o personas, formación de equipos con cuotas, distribución de estudiantes a electivas, asignación de asientos con reglas de separación, ubicación de productos por zona, asignación de revisores a artículos, y cualquier horario con franja enumerada de antemano.

**Resultado conceptual:** el lenguaje es más general que su nombre. No es un DSL de horarios, es un **DSL de asignación con restricciones de conteo**. El dominio «departamento de profesores» (§15) lo demuestra porque no tiene franja temporal en absoluto.

### 3.2 Las limitaciones, con su causa exacta en el código

| Limitación | Causa | Qué deja fuera |
|---|---|---|
| **Cuenta pero no suma** | `gen-consultas.lisp:70` emite `count += 1` para la operación `suma`. El `:devuelve` de la consulta **no lo lee ninguna ruta del generador** | mochila, bin packing con tamaños distintos, presupuestos, cargas en horas, pesos, costos acumulados |
| **Los umbrales se pierden en nppq** | `gen-restricciones.lisp:36` toma el operando izquierdo del `op-mayor` y **descarta el derecho**. `(op-mayor consulta 12)` compila a `return consulta(horario)`: el 12 desaparece y penaliza siempre | «a lo sumo K» directo. Hay que rodearlo con tqpq cuantificado, y el umbral debe vivir como atributo de la entidad cuantificada |
| **No hay aritmética sobre lo decidido** | `expr->py` traduce aritmética sobre datos fijos; no existe ningún mecanismo que opere sobre el valor elegido | precedencias, tiempos de inicio calculados, duraciones acumuladas, tiempos de viaje, ventanas, job-shop |
| **No hay restricciones globales** | faltan alldifferent, cardinalidad, circuito, acumulativo; `hay-elementos-duplicados` está muerto | permutaciones, rutas, secuenciación, asignación uno a uno garantizada. En tv nada impide que el mismo programa ocupe dos bloques |
| **Toda identidad recibe valor** | `crear_horario_aleatorio` (§2.6) | elegir k de n, selección de cartera, cobertura de conjuntos, decisiones opcionales |
| **Un solo nivel de agregación** | no hay conteo de conteos ni estadísticos | promedio, desviación, dispersión. Por eso la compacidad del horario de grupo que pide el capítulo 3 no está implementada |
| **`contar-distintos-dias` cableada** | `gen-consultas.lisp:76` busca literalmente un atributo llamado `fecha` o `dia` | contar valores distintos de cualquier otra dimensión |
| **Objetivo plano** | todas las blandas comparten un único `PESO_BLANDA` | ponderar criterios entre sí sin duplicar restricciones |

### 3.3 Qué sí funciona y cómo escribirlo

- **Umbral distinto de cero:** `(def-tqpq (op-menor-igual consulta (tope entidad)) entidad)`. Compila al bucle de `generar-cuerpo-cuantificado`, que recorre el dominio y cuenta incumplimientos. Es el mecanismo de `frecuencia-exacta` en docentes.
- **Minimax:** `def-minimizar` compila a `max(...)` sobre el dominio (`gen-restricciones.lisp:107`). Funciona con cualquier consulta, no solo con `contar-distintos-dias`.
- **Comparación ordinal:** funciona si el atributo es numérico. Un grado académico hay que darlo como nivel numérico, no como referencia a entidad.
- **nppq devuelve el conteo crudo**, no 1: la penalización es proporcional al número de violaciones.

### 3.4 Límite de rendimiento

Las consultas se compilan a bucles anidados, uno por dominio iterado, evaluados enteros por cada individuo en cada generación.

- tesis, `conflictos-de-horario`: profesor × asignación × asignación = 35 × 13 × 13 ≈ 6 000 vueltas por evaluación, × 100 individuos × 500 generaciones.
- docentes, `colisiones-de-profesor`: profesor × clase × clase = 6 × 65 × 65 ≈ 25 000 por evaluación.

El costo crece como el producto de los dominios iterados. Las restricciones de choque comparan dos filas, así que son cuadráticas en el tamaño del horario por naturaleza.

**El punto de ruptura está en el número de filas del horario, no en el tamaño de los pools.** Duplicar locales apenas cuesta; duplicar clases multiplica por cuatro cada evaluación. Una facultad completa (cinco años en vez de uno) pasa de 65 filas a varios cientos: ahí el generador deja de ser usable **mucho antes de que el lenguaje se quede sin expresividad**.

### 3.5 Las dos mejoras de mayor retorno

Honrar `:devuelve` (para sumar atributos) y honrar el operando derecho en nppq (para tener umbrales). Ninguna toca el diseño del lenguaje; las dos son huecos del generador.

---

# PARTE III — LOS DOMINIOS

## 4. Los tres dominios implementados

| Dominio | entidad-horario | slot-identidad | slots-variables | Restricciones duras | Blanda |
|---|---|---|---|---|---|
| **tesis** | asignacion | tribunal | fecha, momento, local | sin-conflictos-de-horario, sin-colisiones-de-local | minimizar-carga-maxima |
| **docentes** | clase | sesion | aula, dia, turno | un-aula-por-profesor, un-grupo-por-aula, una-clase-por-grupo | minimizar-dias-de-viaje |
| **tv** | emision | bloque | programa | sin-mismo-tipo-consecutivo | minimizar-repeticion-de-tipo |

Detalles por dominio:
- **tesis**: un tribunal (conjunto fijo de profesores, dato) debe recibir fecha+momento+local. `conflictos-de-horario` cuenta pares de asignaciones que comparten profesor a la misma fecha y momento con distinto tribunal. `colisiones-de-local` cuenta pares que comparten local+fecha+momento con distinto tribunal. `dias-asistidos(prof)` usa `contar-distintos-dias` y `minimizar` sobre profesor busca minimizar la carga máxima. Tamaño de x ≈ 13·3·7·4 = **1092** binarias. Datos reales: 35 profesores, 13 estudiantes, 13 tribunales, 3 fechas, 7 momentos, 4 locales.
- **docentes**: una sesión (lleva grabados asignatura, grupo, profesor como datos) debe recibir aula+dia+turno. Tres colisiones (profesor, aula, grupo). `frecuencia-exacta` (tqpq) existe pero se **omite** porque la estructura de sesiones ya garantiza la frecuencia. `dias-de-profesor` con `contar-distintos-dias`. Tamaño ≈ 65·6·5·6 ≈ **11 700** binarias. Datos reales: 6 aulas (1, 2, 5, 6, Laboratorio, SEDER), 5 grupos, 6 profesores, 10 asignaturas, 5 días, 6 turnos.
- **tv**: un bloque (lleva grabados dia y orden como datos) debe recibir un programa (el programa lleva tipo, duración, canal como datos). `adyacentes-mismo-tipo` prohíbe que dos bloques consecutivos del mismo día tengan programas del mismo tipo (usa `orden(e1)+1 = orden(e2)`). Tamaño ≈ 56·8 = **448** binarias. Es el caso con **un solo slot variable**, o sea el `x_ij` clásico. Datos reales: 8 programas, 6 tipos, 7 días, 8 bloques por día.

## 5. La descripción en lenguaje natural (capítulo 3 de la tesis)

`doc/cap3-dom/cap3-dom.tex` es el capítulo «Elementos básicos para describir problemas de horarios». **No es el capítulo de resultados.** Estructura:

- §3.1 horario docente, §3.2 defensas de tesis, §3.3 parrilla televisiva — descripción larga de cada problema con ejemplos.
- §3.4 elementos comunes — las cuatro categorías (franjas temporales, recursos, actividades, asignaciones), la clasificación dura/blanda, y los criterios de evaluación (factibilidad y optimalidad).
- §3.5 «Descripción declarativa de un horario en lenguaje natural», líneas 433-465 — la descripción **compacta** de los tres problemas. Es la que sirve de versión textual canónica.

### 5.1 Discrepancias entre la descripción y la implementación

Registradas al comparar el capítulo con los `dominio.lisp`:

- **Aulas.** El capítulo dice «aulas numeradas del 1 al 9» más Laboratorio; el `dominio.lisp` declara solo Aula 1, 2, 5, 6, Laboratorio y SEDER. El SEDER se menciona en §3.5 pero no en §3.1.
- **Capacidades.** Solo existen en el capítulo (Aula 1 = 30, Aula 6 = 70, Laboratorio = 60). La entidad `aula` del DSL **solo tiene nombre**: la capacidad es dato muerto, no llega a la implementación.
- **Asignaturas.** El capítulo lista cinco «entre otras»; el `dominio.lisp` declara diez.
- **Regla ausente.** «A un grupo solo pueden asignársele las asignaturas que le corresponden» está en el capítulo y en `descripcion-horarios/facu.md`, pero en el DSL queda absorbida en cómo se construyen las sesiones, no como restricción.
- **Asignación predefinida.** C111 y C112 comparten Filosofía C en lunes-turno 1 en el Aula 6. El capítulo la trata como excepción de la regla de aulas; el análisis ILP la clasifica como **dato de entrada**. En el DSL **no se puede declarar**: no hay forma de fijar de antemano el aula y el turno de una clase.
- **Franja de tv.** El capítulo dice que cada bloque empieza cuando termina el anterior (inicio fijo 16:00, fin = inicio + duración). El DSL no lo expresa: el bloque lleva día y orden, y la duración vive en el programa sin que nadie la use. Es el ejemplo canónico de la limitación «no hay aritmética sobre lo decidido».
- **Tipo de público.** Está en el capítulo, no en el DSL.
- **Identificadores.** El capítulo no asigna `id` a ninguna entidad; los `id` de los `descripcion-horarios/*.md` no están en la descripción.

### 5.2 Input y resultado: qué es cada cosa

Distinción necesaria porque varios ejemplos del capítulo tienen forma de fila de solución:

- **Input puro:** la composición de los trece tribunales (estudiante + cinco profesores con roles). Parece tabla de resultado pero el algoritmo no la decide, la recibe.
- **Input predefinido con forma de resultado:** C111 y C112 en Filosofía C lunes-turno 1 Aula 6. Es la **única** asignación prefijada de los cuatro dominios. Que compartan la clase es input; el turno y el aula tienen forma de decisión pero vienen dados.
- **Resultado, no input:** la secuencia real del lunes de Canal Habana (qué programa va en qué posición). Lo que sí es input es el catálogo: nombre, tipo, público y duración. El ejemplo del capítulo «El Tiempo y la Memoria seguido de Coordenadas, ambos informativos» es un **contraejemplo didáctico** que muestra que la parrilla real incumple la restricción dura; no es ni entrada ni salida del generador.
- El dominio de tesis **no tiene ninguna asignación predefinida**. Si una defensa tuviera hora comprometida, sería el equivalente al caso de C111/C112.

---

## 6. El cuarto dominio: departamento de profesores

> **No se va a implementar** (decisión D1.9, noviembre de 2026). Se conserva aquí como análisis. Sin él, ningún dominio real suma valores distintos de 1 ni carece de franja temporal, así que §3.1 y §16.9 quedan como argumento sin un dominio que los demuestre.

Problema nuevo planteado por el usuario, no implementado. Reparto de la docencia de un semestre entre los profesores de un departamento.

**Datos:** profesores con nombre y grado científico. Asignaturas con nombre, carrera, horas de conferencia, horas de clase práctica y cantidad de grupos de clase práctica. Dos asignaturas con el mismo nombre en carreras distintas son asignaturas distintas (Estadística CC y Estadística Mat).

**Estructura de la decisión.** La unidad que se coloca **no es la asignatura, es la actividad**. Cada asignatura genera una conferencia más una clase práctica por grupo. Estadística (CC), con 2 grupos, genera tres actividades. Sin ese desdoblamiento la cantidad de grupos sería dato muerto y las horas no se sumarían bien. Identidad = actividad, único slot variable = profesor. Es la forma de tv.

### 6.1 Análisis de restricciones

**El hallazgo estructural: este dominio no tiene franja temporal.** No se decide cuándo, solo quién. Eso elimina toda la familia de restricciones de choque, que es la que sostiene los tres dominios existentes: no hay celda, luego no hay packing por celda. Las duras tienen que venir de las otras dos fuentes posibles: **capacidad** y **elegibilidad**.

Duras elegidas:
1. **Toda actividad lleva un profesor.** Estructural. Importa declararla porque, si se pudieran dejar actividades sin cubrir, la forma trivial de no sobrecargar a nadie sería no asignar nada.
2. **Tope de horas por profesor.** Traducción dura de «no haya profesores sobrecargados». Dura porque un tope de horas no es preferencia: si se pasa, el reparto no es aplicable.
3. **Grado científico mínimo para la conferencia.** Añadida en el análisis. El grado venía sin ninguna regla que lo usara, igual que la capacidad del aula en docentes. Le da función y es cierta en una facultad: la conferencia la da alguien con grado, la práctica puede darla un adiestrado.

Blandas elegidas:
4. **Costo de preparación total.** Modelado como número por par profesor-asignatura, no como categoría, porque la categoría hay que volverla número igual.
5. **Equilibrio de carga (minimax).** Separada del tope a propósito: el tope evita el abuso, el equilibrio busca el reparto justo. Sin ella, el modelo cumple el tope cargando a uno al límite y dejando a otro en cero.
6. **Conferencia y prácticas de una asignatura al mismo profesor.** Añadida en el análisis. Quien da la conferencia ya preparó la materia. Blanda porque no siempre se puede.

Descartadas y por qué: disponibilidad horaria (no hay horas en el problema); prohibir dos asignaturas de la misma carrera (regla inventada sin fundamento); mínimo de asignaturas por profesor (redundante con el equilibrio, y como dura puede volver infactible un caso con profesores de sobra); preferencias explícitas del profesor (se solapa con el costo de preparación y obliga a calibrar dos pesos para medir lo mismo).

### 6.2 ¿Lo soporta el DSL?

Sí, corre y produce solución, pero dos de las seis se degradan:

- **Tope de horas.** Se degrada por el `:devuelve` ignorado: no se pueden sumar horas, solo contar actividades. En este caso concreto se salva por casualidad porque todas las actividades son de 32 horas. Con conferencia de 64 y práctica de 16 dejaría de ser expresable. Además hay que escribirla como tqpq cuantificado sobre profesor, no como nppq, porque el umbral se perdería.
- **Costo de preparación.** Se degrada igual: solo se puede contar cuántas asignaciones caen en la categoría mala, perdiendo la gradación entre «la dio hace tiempo» y «no la dio nunca».

Las otras cuatro salen limpias. Grado mínimo funciona si el grado lleva nivel numérico.

**Valor para la tesis:** es el primer dominio sin tiempo, y ejercita patrones (capacidad, elegibilidad) que los tres existentes no usan. Sirve para mostrar que el DSL no es de horarios sino de asignación.

---

# PARTE IV — EL BACKEND DE MODELO MATEMÁTICO (ILP/MILP)

## 7. El objetivo

Diseñar (a nivel de investigación, todavía no implementación) un **segundo backend** del generador que, a partir del **mismo AST**, produzca un **modelo matemático de Programación Lineal Entera (ILP) / Mixta (MILP)**: variables binarias `x_ijk`, inecuaciones derivadas de las consultas y restricciones del DSL, y una función objetivo.

## 8. La idea central: del evaluador al modelo

- El evaluador (GA) itera **sobre los objetos decididos**. El modelo ILP no tiene objetos decididos; tiene **variables sobre el dominio potencial**.
- Traducir = **reindexar la iteración: de "sobre la solución" a "sobre el dominio de decisión"**.
- Por eso el backend ILP **no** puede ser un traductor sintáctico nodo-a-nodo como `expr->py`: `op-and` no se linealiza composicionalmente (producto de booleanos = no lineal). El backend ILP trabaja **a nivel de restricción completa**, reconociendo la *forma* del cuantificador + su consulta y mapeándola a un idioma de OR (programación lineal).

## 9. Variables de decisión

### 9.1 Variable principal (derivación general)

Se deriva directamente de `:slot-identidad` (lo que se coloca, conjunto *I*) y `:slots-variables` (los pools *V₁..Vₙ*):

```
x_{i, v1, ..., vn} = 1  si la identidad i usa los valores (v1,...,vn); 0 si no
```

El número de índices de x = **1 + número de slots variables**.

| Dominio | Variable |
|---|---|
| tesis | x_{t,f,m,l} (tribunal, fecha, momento, local) |
| docentes | x_{s,a,d,u} (sesión, aula, día, turno) |
| tv | x_{b,p} (bloque, programa) ← el x_ij clásico |
| departamento | x_{k,p} (actividad, profesor) ← también x_ij |

### 9.2 Restricción de asignación (implícita en el DSL)

El DSL dice "hay una fila del horario por identidad" → para cada identidad, la suma de x sobre todos los valores de los slots variables = 1:

```
Σ_{v1..vn} x_{i,v1,...,vn} = 1   ∀ i ∈ I
```

Esto convierte, para cada i, el vector de x en **one-hot**: exactamente un 1, el resto 0.

### 9.3 DECISIÓN: codificación conjunta vs separada

- **Conjunta** (la adoptada): una binaria por combinación completa `x_{i,v1,...,vn}`. Cualquier condición que correlacione varios slots a la vez se expresa sumando/comparando esta misma variable.
- **Separada / por canal**: una binaria por slot (`xf_{t,f}`, `xm_{t,m}`, `xl_{t,l}`). Menos variables (suma de tamaños en vez de producto), **pero** correlacionar dos slots a la vez (p. ej. "misma fecha Y mismo momento") exige el producto `xf·xm`, que **no es lineal**. Linealizar ese producto (con variable extra + 3 desigualdades) reconstruye, restricción por restricción, la misma variable conjunta.

**Conclusión:** como TODAS las restricciones de los tres dominios correlacionan varios slots a la vez, la codificación **conjunta evita por completo términos cuadráticos**. El costo (nº de variables = producto de tamaños) es manejable en los tres casos. Los "marginales" (ver §11) recuperan de la conjunta la información que la separada habría dado, sin la no linealidad. Este es un resultado, no un detalle.

## 10. Datos y precómputo (evaluación parcial) — el motor de la linealización

Principio: cada **condición atómica** del `:comprueba` se clasifica antes de construir el modelo en una de dos categorías.

### 10.1 Predicados de DATOS

Dependen **solo de atributos fijos** de las instancias, sin pasar por ningún slot variable. Se evalúan **en tiempo de generación**, recorriendo `*instancias-de-entidad*` con un bucle ordinario, sin esperar a ningún solver. Su resultado se convierte en:
- **índices** de las sumatorias,
- **agrupaciones** de elementos que comparten un atributo,
- **coeficientes/constantes** dentro de las inecuaciones.

Ejemplos: `profesor-en-tribunal p t` → matriz de incidencia `a_{p,t}`; `orden(bloque)`, `dia(bloque)` → conjunto de pares consecutivos `CONS`; `frecuencia(asignatura)` → constante K; `profesor(sesion)`, `grupo(sesion)` → agrupaciones.

### 10.2 Predicados de DECISIÓN

Dependen de algún slot variable (un valor que el modelo aún no determinó). No se pueden colapsar a un número. Se traducen a la estructura del modelo de **tres maneras**:

1. **Como el índice mismo de x**, cuando la condición define qué combinación ocupa la identidad. Ej.: "el tribunal t ocupa fecha f, momento m, local l" → los cuatro índices de `x_{t,f,m,l}`.
2. **Como una variable auxiliar que suma x**, cuando la condición depende de un *atributo de lo decidido* y no del slot en sí. Ej.: "el bloque b quedó ocupado por un programa de tipo ty" → `z_{b,ty} = Σ_{p: tipo(p)=ty} x_{b,p}`.
3. **Como una inecuación entre variables**, cuando la condición comparaba dos ocurrencias. Ej.: "dos tribunales distintos no pueden coincidir en fecha y momento" → `Σ_t x_{t,f,m,l} ≤ 1` por cada (f,m,l).

> Regla práctica del *matcher*: una condición es de solo-datos **si y solo si todos los símbolos de los que depende son fijos en el dominio** (no atraviesan un slot variable). En cuanto un término atraviesa un `slots-variables`, toda la condición pasa a depender de la decisión, aunque el resto sean datos.

> El eje datos/decisión y la "restricción marginal" (§11) NO se contradicen: el precómputo de datos sigue igual; una marginal es siempre del lado decisión (opción 2 de arriba). Escribirla como restricción explícita no la cambia de categoría, solo cambia dónde se declara.

## 11. Variables auxiliares (todas lineales, sin productos)

| Auxiliar | Definición | Para qué |
|---|---|---|
| **Marginal** | y_{i,s} = Σ_{slots no-s} x_{i,...} | proyectar x sobre un subconjunto de slots |
| **Presencia** | w_{celda,g} ≥ x_{i,...} (i de clase g) | "la clase g está presente en la celda" |
| **Atributo** | z_{b,ty} = Σ_{p: tipo(p)=ty} x_{b,p} | atributo que vive en el valor decidido |
| **Día** | att_{p,f} ≥ Σ_{resto} x_{i,f,...} | "el profesor p asiste el día f" |
| **Minimax** | Z ≥ (expresión) | linealizar "minimizar el máximo" |
| **Holgura** | r ≥ (expresión) − K, r ≥ 0 | contar violaciones de una restricción blanda |

### 11.1 Por qué las marginales valen 0 o 1 y actúan como un "for/any"

Tomando `y_{t,f,m} = Σ_l x_{t,f,m,l}`:
- La restricción de asignación hace que, para cada tribunal t, el vector completo de x sea **one-hot** (un solo 1).
- La marginal suma solo una **rebanada** de ese vector (fija f y m, varía l).
- Como en toda la fila de t hay un único 1, esa rebanada contiene ese 1 (→ y=1) o no (→ y=0); **nunca más de 1**. Por tanto `y ∈ {0,1}` es **consecuencia automática** de que x es binaria y de la asignación; no hay que declararla entera.
- Es literalmente un `any()`: "¿existe algún l tal que x_{t,f,m,l}=1?". Equivale a:
  ```
  y = 0
  for l in locales:
      if x[t,f,m,l] == 1: y = 1; break
  ```
- Igual para `y_{s,d,u}=Σ_a x_{s,a,d,u}` (docentes) y `z_{b,ty}=Σ_{p:tipo(p)=ty} x_{b,p}` (tv).

### 11.2 Decisión: las marginales se escriben como RESTRICCIONES del modelo, con nombre "Marginal"

En los modelos completos (§13), la ecuación de la marginal **no** se deja solo en prosa como "se obtiene sumando x"; aparece como una **línea de restricción explícita dentro del bloque del modelo**, etiquetada **"Marginal y"** / **"Marginal z"** (inicialmente se etiquetó "Enlace", luego el usuario pidió renombrarla a "Marginal"). En la prosa se dice que "su valor queda determinado por una restricción marginal del modelo". No se dejó ninguna nota meta del cambio (el usuario lo pidió explícitamente).

Por qué: (1) da estatus de variable de primera clase (un solver real necesita toda variable declarada); (2) uniformiza el catálogo de restricciones (asignación, marginal, R1, R2, ..., objetivo, todas con la misma forma); (3) hace visible la diferencia entre marginales (igualdad exacta `=`) e indicadores de presencia/día (desigualdad `≥`). Matemáticamente el conjunto factible es idéntico; no añade grados de libertad.

## 12. Taxonomía: cómo se convierte cada restricción a sumatorias

Cada patrón de cuantificador del DSL corresponde a un idioma clásico de OR:

| Patrón en el DSL | Ejemplos | Qué significa | Inecuación |
|---|---|---|---|
| `nppq`, conteo pairwise "mismos slots decididos + identidad distinta" | conflictos, colisiones-de-local | a lo sumo una identidad por celda de slots decididos | Σ ≤ 1 por celda (packing) |
| igual, pero lo que distingue es un **atributo de datos** | colisiones-de-aula, colisiones-de-grupo | varias identidades juntas solo si comparten el atributo; no dos atributos distintos en la celda | Σ_g w ≤ 1 (packing con presencia) |
| `tqpq`, conteo = constante | frecuencia-exacta | el nº de identidades en un subconjunto por dato = K | Σ = K (covering/igualdad) |
| `nppq`, conteo ≤ constante | capacidad, tope de horas | el nº de identidades en un subconjunto por dato ≤ K | Σ ≤ K (capacidad) |
| `minimizar` + `contar-distintos-dias` | carga máxima, días de viaje | minimizar el máximo, entre elementos, de valores distintos usados | Z ≥ días_p; min Z (minimax) |
| adyacencia con atributo del **valor decidido** | tv adyacentes/consecutivos | dos combinaciones de posición conocida no comparten atributo decidido | z_{b1,ty}+z_{b2,ty} ≤ 1 |

Observaciones:
- **Packing es mejora de representación, no solo traducción**: el DSL expresa la colisión como conteo O(n²) sobre pares; el ILP la compila a O(celdas) inecuaciones porque "dos ítems distintos en la misma celda" ≡ "a lo sumo uno por celda". **Esto es también la respuesta al límite de rendimiento de §3.4**: el backend exacto elimina justo el factor cuadrático que ahoga al GA.
- **El lugar del atributo que discrimina decide la forma**: si discrimina la *identidad* → packing simple `Σ x ≤ 1`; si discrimina un *atributo de datos* (grupo) → packing con presencia `Σ_g w ≤ 1`; si el atributo vive en el *valor decidido* (tipo en tv) → indicador z + packing sobre CONS.

### 12.1 Función objetivo global

Con las duras convertidas en restricciones reales, el objetivo solo pondera lo blando:

```
min Σ_{j blandas} w_j · violación_j
```

donde violación_j es una cota minimax Z_j (patrón minimizar) o una suma de holguras Σr (patrón adyacencia).

**Efecto colateral importante:** desaparece el peso artificial `PESO_DURA = 1000`. En el GA hacía falta para que una violación dura pesara más que cualquier valor blando; en el modelo exacto las duras son restricciones que el solver DEBE cumplir, no términos del costo. Menos hiperparámetros que calibrar.

> **Nota:** el objetivo del ILP admite coeficientes `w_j` distintos por restricción blanda, cosa que el GA no (§3.2, «objetivo plano»). El backend exacto también resuelve esa limitación.

## 13. Los modelos completos por dominio

### 13.1 Tesis

Variables: `x_{t,f,m,l}` (decisión: tribunal t en fecha f, momento m, local l); `y_{t,f,m}` (marginal); `att_{p,f}` (indicador: profesor p asiste día f); `Z` (continua, cota minimax). Dato: `a_{p,t}` (1 si profesor p ∈ tribunal t).

```
Asignación   Σ_{f,m,l} x_{t,f,m,l} = 1                         ∀t
Marginal y   y_{t,f,m} = Σ_l x_{t,f,m,l}                        ∀t,f,m
R1 conflictos Σ_{t: a_{p,t}=1} y_{t,f,m} ≤ 1                    ∀p,f,m
R2 un local  Σ_t x_{t,f,m,l} ≤ 1                               ∀f,m,l
R3 carga     att_{p,f} ≥ Σ_{m,l} x_{t,f,m,l}                   ∀p,f, t:a_{p,t}=1
             Z ≥ Σ_f att_{p,f}                                 ∀p
Objetivo     min Z
```

### 13.2 Docentes

Variables: `x_{s,a,d,u}`; `y_{s,d,u}` (marginal); `w_{a,d,u,g}` (presencia de grupo g en celda aula-día-turno); `v_{g,d,u,a}` (presencia simétrica, grupo g en aula a); `att_{p,d}`; `Z`. Datos: profesor y grupo de cada sesión.

```
Asignación         Σ_{a,d,u} x_{s,a,d,u} = 1                         ∀s
Marginal y         y_{s,d,u} = Σ_a x_{s,a,d,u}                       ∀s,d,u
R1 un aula/prof    Σ_{s: prof(s)=p} y_{s,d,u} ≤ 1                    ∀p,d,u
R2 un grupo/aula   Σ_g w_{a,d,u,g} ≤ 1;  w_{a,d,u,g} ≥ x_{s,a,d,u} (grupo(s)=g)  ∀a,d,u
R3 una clase/grupo Σ_a v_{g,d,u,a} ≤ 1;  v_{g,d,u,a} ≥ x_{s,a,d,u} (grupo(s)=g)  ∀g,d,u
R4 días de viaje   att_{p,d} ≥ Σ_a x_{s,a,d,u};  Z ≥ Σ_d att_{p,d}
Objetivo           min Z
```

Nota sobre R2/R3: la condición del DSL discrimina por **grupo** (atributo de datos), no por identidad, por eso hace falta el indicador de presencia (permite varias sesiones del mismo grupo en la celda, prohíbe grupos distintos).

> La asignación predefinida de C111/C112 (§5.2), que el DSL no puede declarar, en el ILP **sí es trivial**: se fija `x_{s,aula6,lunes,t1} = 1` para las sesiones implicadas. Es un argumento a favor del backend exacto.

### 13.3 Televisión (tv)

Datos: `CONS` = {(b1,b2): dia(b1)=dia(b2) ∧ orden(b2)=orden(b1)+1} (pares consecutivos, precomputado). Variables: `x_{b,p}`; `z_{b,ty}` (marginal/atributo: bloque b ocupado por programa de tipo ty); `r_{b1,b2,ty}` (holgura ≥ 0).

```
Asignación            Σ_p x_{b,p} = 1                                       ∀b
Marginal z            z_{b,ty} = Σ_{p: tipo(p)=ty} x_{b,p}                  ∀b,ty
R1 sin tipo consec.   z_{b1,ty} + z_{b2,ty} ≤ 1                             ∀(b1,b2)∈CONS, ∀ty
R2 minimizar repet.   r_{b1,b2,ty} ≥ z_{b1,ty} + z_{b2,ty} − 1
Objetivo              min Σ r_{b1,b2,ty}
```

> Recomendación de alcance para prototipar: **empezar por tv** — un solo slot variable (x_ij puro) y aun así contiene el patrón más difícil (adyacencia + atributo del valor decidido). Valida casi toda la maquinaria con el modelo más pequeño.

### 13.4 Departamento (esbozo, no elaborado en detalle)

Variables: `x_{k,p}` (actividad k impartida por profesor p); `u_{a,p}` (presencia: el profesor p imparte alguna actividad de la asignatura a); `Z` (minimax). Datos: `h_k` (horas de la actividad k), `T_p` (tope del profesor p), `c_{p,a}` (costo de preparación), `g_p` y `m_a` (nivel de grado y mínimo exigido).

```
Asignación     Σ_p x_{k,p} = 1                                    ∀k
Elegibilidad   x_{k,p} = 0                     ∀k conferencia, ∀p: g_p < m_{asig(k)}
Tope           Σ_k h_k · x_{k,p} ≤ T_p                            ∀p
Carga          Z ≥ Σ_k h_k · x_{k,p}                              ∀p
Coherencia     u_{a,p} ≥ x_{k,p} (asig(k)=a);  Σ_p u_{a,p} ≥ 1 + r_a
Objetivo       min Σ_{k,p} c_{p,asig(k)} · x_{k,p} + w1·Z + w2·Σ_a r_a
```

**Este dominio es el mejor argumento a favor del backend ILP.** Las dos restricciones que el DSL degrada —tope de horas y costo de preparación— son en el ILP sumas ponderadas triviales (`Σ h_k x` y `Σ c x`). El coeficiente numérico que `:devuelve` tira a la basura es exactamente lo que el modelo matemático sabe usar.

## 14. ¿Cómo se resuelve el modelo? ¿Se necesitan heurísticas?

- **No se necesita metaheurística** (GA) para resolverlo. Un modelo MILP se resuelve con **solvers exactos** que usan *branch-and-bound* / *branch-and-cut* con relajación lineal (LP): CBC (libre), Gurobi, CPLEX. La alternativa de programación por restricciones es **OR-Tools CP-SAT**, muy fuerte en scheduling.
- Estos solvers dan **garantía de optimalidad** (o un *gap* certificado) y pueden **demostrar infactibilidad** — cosas que el GA no puede.
- El GA no desaparece del proyecto: queda como **backend complementario**. Escala a instancias grandes pero sin garantías; el exacto da garantías pero puede no escalar. Se posicionan como complementarios.
- **Validación cruzada**: el óptimo del ILP acota inferiormente el mejor costo del GA; toda solución del GA debe ser factible en el ILP. Esto permite medir el *gap* de optimalidad del GA y verificar que ambos backends codifican el mismo problema.

## 15. Arquitectura propuesta del backend

### 15.1 Lo que NO cambia (punto fuerte de la tesis)

- **El DSL** (`clases-macros.lisp`, `def-consulta`, `def-nppq`, `def-problema-horario`) — cero cambios.
- **El AST** — se consume el mismo `consulta-simple` y `cuantificador-restriccion`.
- **`problema-horario`** ya guarda la foto `instancias` y `slots-entidades`, así que el backend precompute como función pura.

### 15.2 Nuevo punto de entrada

`generar-ilp archivo problema &key (formato :pulp)` en `generador.lisp`, paralelo a `generar-python` (o un parámetro `:backend`). Reutiliza el mismo `problema-horario`.

### 15.3 Módulos nuevos (espejo de los existentes)

| Nuevo módulo | Responsabilidad | Espeja a |
|---|---|---|
| `gen-ilp-datos.lisp` | precómputo: recorre `*instancias-de-entidad*`, evalúa predicados de datos, construye incidencias/agrupaciones/CONS | `gen-serializar.lisp` |
| `gen-ilp-vars.lisp` | declara x desde slot-identidad + slots-variables y emite Σx=1 | `generador.lisp` |
| `gen-ilp-patrones.lisp` | catálogo {matcher, emitter}: clasifica cada restricción y emite inecuaciones | `gen-restricciones.lisp` |
| `gen-ilp-emit.lisp` | impresor del formato destino (PuLP / CP-SAT / MiniZinc) | `gen-ast-python.lisp` |

Y un registro `*reg-aux-vars*` (marginales, presencia, día, minimax, holguras), análogo a `*reg-consultas*`.

> **Encaje con MGA** (detalle en [`BASE-CONOCIMIENTO-mga-arcia-2017.md`](BASE-CONOCIMIENTO-mga-arcia-2017.md) §9.4): en el vocabulario de Generadores Multilenguajes, este backend es un **tercer lenguaje de salida** (junto a Python y a la notación matemática de `expr->math`). El esquema de MGA —función genérica `generate-code (nodo lenguaje stream)` con despacho CLOS sobre el par (nodo, lenguaje), más una jerarquía de clases de lenguajes— aplica a `gen-ilp-emit.lisp` (la capa de impresión: PuLP / CP-SAT / MiniZinc como hijos de un `Solver-Model-Language` común). **No aplica** a `gen-ilp-patrones.lisp`: el macro `gcode` presupone traducción composicional nodo a nodo, y la linealización no lo es (§8). Esa ruptura es en sí un resultado de la tesis y conecta con la frontera de expresividad de §15.6.

### 15.4 El núcleo: algoritmo del matcher/emitter

> **Este algoritmo ya está implementado.** Los pasos 1-4 son `match-pairwise` en `verbalizador/nlgen/idioms.lisp`, validados contra las nueve restricciones de los tres dominios. Falta solo el paso 6 en su variante ILP. Ver §30.4. El paso 4 resultó más barato de lo que dice §10.2: se resuelve con una sola comparación, no con un recorrido de dependencias.

Por cada restricción (equivalente a `generar-funcion-restriccion`, pero emitiendo modelo):
1. Clasificar el cuantificador con `tipo-restriccion` (ya existe): nppq/tqpq → dura; ndpq/sbqp → blanda; minimizar/maximizar → objetivo.
2. Tomar la consulta (dentro del `op-mayor … 0` o directa) y leer `operacion`: suma/contar → conteo; contar-distintos-dias → minimax con indicador de día.
3. Aplanar `op-and` en una lista de átomos (op-igual, op-distinto, op-suma...).
4. Clasificar cada átomo (datos vs decisión, regla de §10): datos-datos → filtro/agrupación precomputada; decisión-decisión sobre el mismo slot → define la **celda** (clave de packing); op-distinto → define la **dimensión que discrimina**.
5. Elegir el idioma (§12): identidad → Σx≤1; atributo de datos → Σ_g w≤1; atributo del valor decidido → z + packing sobre CONS; tqpq → Σ=K; minimizar+distintos → indicadores + Z.
6. Emitir en el formato destino, registrando las auxiliares nuevas.

### 15.5 Formato destino (a decidir en la tesis)

| Destino | A favor | En contra |
|---|---|---|
| **PuLP / CBC** (Python) | mantiene "un .py de salida"; solver libre | solo MILP; distinct/adyacencia a mano (justo lo que hacemos) |
| **OR-Tools CP-SAT** | booleanos ≈ CP con reificación; AllDifferent; muy rápido | menos parecido a "ecuación matemática" clásica |
| **MiniZinc** | el artefacto más cercano a "modelo matemático" puro; expositivo | toolchain fuera de Python |

Como el objetivo declarado es "modelo matemático con inecuaciones", el centro natural es **MILP (PuLP)**; CP-SAT es la variante pragmática de alto rendimiento y MiniZinc la más expositiva.

### 15.6 Frontera de expresividad del backend ILP

- `op-or` / disyunciones: no aparecen hoy; requerirían big-M o reificación.
- Consultas anidadas / agregados de agregados: no presentes; romperían la linealidad polinómica.
- Correlaciones que exijan la codificación conjunta: el tamaño de x crece como |I|·∏|Vk| (aceptable: tesis 1092, tv 448, docentes ≈ 11 700).
- **Resultado positivo demostrable**: *todo el corpus actual se linealiza a un MILP sin términos cuadráticos*, con auxiliares lineales (marginales, indicadores). Caracterizar qué extensiones lo romperían delimita la frontera de expresividad linealizable.

> **Comparación con la frontera del DSL (§3.2).** Son fronteras distintas y en general el ILP es más ancho: el modelo matemático **sí** suma magnitudes, **sí** admite umbrales arbitrarios y **sí** pondera criterios. Lo que el ILP no gana por sí solo es la aritmética sobre lo decidido y las restricciones globales, que siguen necesitando reformulación. O sea: de las ocho limitaciones del DSL, el backend ILP resuelve tres (sumar, umbrales, pesos) por el solo hecho de existir, dos las mejora (rendimiento, agregación), y tres siguen abiertas (aritmética sobre lo decidido, globales, decisión opcional).

## 16. Conclusiones de investigación

1. **El DSL es agnóstico al backend.** La misma descripción alimenta (a) metaheurística y (b) modelo exacto, sin tocar el lenguaje: solo se añaden módulos `gen-ilp-*`. Es la validación más fuerte del diseño "AST como única fuente de verdad".
2. **Correspondencia sistemática DSL ↔ familias clásicas de OR** (packing, covering, capacidad, minimax): convierte el "lenguaje de restricciones" en un esquema de compilación hacia programación entera.
3. **La evaluación parcial datos/decisión es el motor de la linealización.**
4. **Teorema de linealizabilidad** + frontera de expresividad (§15.6).
5. **Exacto vs metaheurístico** son complementarios (garantías vs escalabilidad).
6. **Validación cruzada** entre backends (mide el gap del GA).
7. **Elimina el ajuste de pesos** (`PESO_DURA` es artefacto de la metaheurística).
8. **El modelo como artefacto portable**: cierra el ciclo con `expr->math` (que ya imprime el modelo para humanos) haciéndolo ejecutable por cualquier solver estándar.
9. **El DSL no es de horarios, es de asignación** (§3.1). El dominio del departamento lo prueba: sin franja temporal, la maquinaria sigue funcionando.
10. **Las limitaciones del generador no son limitaciones del lenguaje.** Las dos más graves (`:devuelve` ignorado, umbral descartado en nppq) son huecos de implementación que el backend ILP resuelve de oficio.

---

# PARTE V — ENTREGABLES, OPERATIVA E HISTORIAL

## 17. Entregables producidos

### 17.1 En `informe-modelo-matematico/`

| Archivo | Qué es |
|---|---|
| `informe-modelo-matematico.md` | Informe completo en Markdown (fórmulas LaTeX). Cubre variables, datos/precómputo, taxonomía completa, modelos, arquitectura, conclusiones. Con cajas "nota". |
| `informe-modelo-matematico.tex` / `.pdf` | Versión LaTeX/PDF del informe completo (~6–10 pág), con cajas, verbatim, tablas, índice, portada. |
| `modelo-matematico.tex` / `.pdf` | **Resumen** solo-LaTeX+PDF (el usuario NO quiere .md de este). Sin negritas/cursivas/cajas/índice/portada; vista textual simple; empieza directo en sección 1. Contiene: 1 Notación y conjuntos; 2 Variables de decisión (2.1 principal, 2.2 asignación — SIN 2.3); 3 Datos y precómputo (resumida); 4 Variables auxiliares (tabla); 5 Conversión a sumatorias (tabla + 5.1 objetivo global); 6 Modelos completos con las marginales como restricción "Marginal". Compila 0 errores, 6 páginas. |
| `elementos-dominio-descripcion.tex` / `.pdf` | **Inventario de elementos de los tres dominios reales**, extraído únicamente de la descripción en lenguaje natural (sin implementación). 4 páginas, 0 errores. Ver §19 para las decisiones que lo gobiernan. |
| `BASE-CONOCIMIENTO-tesis.md` | Este documento. |

### 17.3 En `C:\Pro\tesis\verbalizador\doc\` (sandbox del verbalizador)

| Archivo | Qué es |
|---|---|
| `informe_verbalizador.md` | Informe autocontenido del verbalizador para quien no conoce el proyecto: objetivo, ejemplo de entrada y salida, las cuatro capas, decisiones, hallazgos y estado. Su sección **«Lo que esto enseñó sobre el modelo matemático»** desarrolla los ocho puntos de §30.4 y es material directo para la PARTE IV. |
| `PLAN-IMPLEMENTACION.md` | Plan operativo por fases: qué archivo se crea en cada una, qué contiene, por qué, qué problema resuelve y cómo se verifica. Incluye qué se copió del proyecto original y qué se excluyó, con la razón de cada exclusión. |
| `BASE-CONOCIMIENTO-mga-arcia-2017.md` | Base de conocimiento de la tesis de Yasmany Arcia Corcho (UH/MATCOM, mayo 2017), *Automatizar la creación de Generadores Multilenguajes*, sobre la herramienta **MGA**. Cubre: los 6 pasos de construcción de un Generador Multilenguaje y por qué en un DSL interno de Lisp desaparece el análisis léxico/sintáctico; las 5 definiciones formales; el ejemplo guía BASAR; los macros `defnode`/`defabsnode` y `gcode`, `recognize-pattern`, `mark-node-as-indentable`; la función genérica `generate-code` y la jerarquía de lenguajes; el linaje MATCOM (ADOL\*, **LAML**, IVNS, GEMURAL); y la comparación con nuestro `clases-macros.lisp`. **Consultar ese documento para cualquier pregunta sobre generación multilenguaje.** |

### 17.2 En la raíz del repo

| Archivo | Qué es |
|---|---|
| `inputs-usuario.md` | Descripción en lenguaje natural de los cuatro dominios (tesis, docentes, tv, departamento) más, para los tres implementados, el input completo en el DSL. Ver §18. |
| `limitaciones-del-dsl.md` | Qué familia de problemas resuelve el lenguaje y dónde se rompe, más el límite de rendimiento. Es la versión pulida de §3. Ver §18. |
| `flujo-descripcion-a-dsl.md` | **El procedimiento de tres pasos** para incorporar un problema real al proyecto (normalizar la descripción → traducir al DSL → verbalizar y comparar), más el estado del caso en curso. Ver §31. |
| `descripcion-saul.md` | Descripción normalizada del preuniversitario Saúl, con duras y blandas. Producto del paso 1. Ver §31.2. |
| `datos-saul.md` | Los datos concretos que faltan para el paso 2 de Saúl: disposiciones, topes y formato de salida deseado. Ver §31.3. |
| `base_de_conocimiento.md` | **Base de conocimiento de la línea Saúl.** Continúa §31 a partir del paso 2: el procedimiento operativo completo, qué tener en cuenta para cada backend, cómo ejecutar los dos, las tres limitaciones nuevas del modelo de datos y las medidas reales de rendimiento con su proyección. |
| `modelacion_saul.md` / `modelacion_saul.lisp` | Los datos reales e inventados del dominio, y su traducción al DSL. El `.lisp` se replica en `verbalizador/dominios/saul.lisp` y en `generador-horarios/saul/dominio.lisp`. |
| `plan-cambios-saul.md` | Los diez cambios aplicados a la modelación DSL, con su causa y su verificación. Incluye los tres defectos del lenguaje descubiertos al traducir y al ejecutar. |
| `plan-mejora-verbalizador.md` | Por qué la salida del verbalizador sobre Saúl es ilegible, y el plan por fases con seis bifurcaciones de diseño sin decidir. |

## 18. Los dos documentos de la raíz: decisiones que los gobiernan

### 18.1 `inputs-usuario.md`

**Qué contiene.** Una sección por dominio. Cada una tiene la descripción en lenguaje natural y, para los tres implementados, una subsección «Input en el lenguaje» con el programa del DSL.

**DECISIONES:**
- **Estilo de la prosa:** frases cortas y directas, sin conectores ni azúcar sintáctico, sin guiones largos, sin «etc.». El usuario lo pidió explícitamente y hay que mantenerlo en cualquier edición futura.
- **Sin tablas.** Las listas (asignaturas con frecuencia, aulas con capacidad) van en párrafo corrido. El usuario rechazó las tablas.
- **Solo input, nunca resultado.** Se excluyen los ejemplos con forma de fila de solución: la asignación de ejemplo de tesis, el horario inviable de docentes, la secuencia real del lunes de tv y su contraejemplo de violación. La única excepción es la asignación predefinida de C111/C112, que es input aunque tenga forma de resultado (§5.2).
- **Los inputs en el DSL son copia de los `dominio.lisp`, no construcción propia.** Se recortaron los datos repetitivos (6 profesores de 35 en tesis, 4 sesiones de 65 en docentes, 8 bloques de 56 en tv) y cada recorte está anotado en el propio archivo. También se quitaron `:peso-dura` y `:peso-blanda`.
- **Advertencia registrada:** por venir de la implementación, ese input refleja «cómo está descrito hoy», no «cómo debería describirse el problema del capítulo 3». Eso incumple el criterio de fuente única de §19.2. Si se quiere cumplirlo, hay que reescribir los inputs desde la descripción sin mirar la implementación.
- Las limitaciones del lenguaje frente a cada descripción se anotan al final de cada bloque de código (capacidad del aula, asignación predefinida, franja construida de tv).

### 18.2 `limitaciones-del-dsl.md`

**DECISIONES:**
- **Sin referencias a archivos ni líneas del código.** El usuario pidió quitarlas todas. La causa se explica en prosa («la operación suma incrementa un contador en uno»), no señalando el archivo. En ESTE documento sí se conservan las referencias, porque es base de conocimiento interna.
- **La lista de problemas que resuelve va en párrafo**, no en viñetas.
- **Sin sección de resumen.** El documento termina en el apartado de rendimiento.
- Estructura: qué resuelve, ocho limitaciones de expresividad con subtítulo propio, limitaciones por rendimiento.

## 19. Inventario de elementos del dominio (`elementos-dominio-descripcion.tex`)

### 19.1 Qué es y para qué

Inventario de los elementos que intervienen en los tres problemas reales. Su destino es servir de insumo al diseño de los **nodos del AST** de un lenguaje nuevo para el backend de modelo matemático, construido **sin pasar por el backend actual**. Es material de entrada, no un diseño de nodos.

### 19.2 DECISIÓN: fuente única y qué se excluyó

- **Única fuente admitida:** `doc/cap3-dom/cap3-dom.tex`.
- **Excluido deliberadamente:** los `descripcion-horarios/*.md`, toda la implementación (`generador-horarios/**`, los tres `dominio.lisp`, el DSL, el AST actual) y los informes ILP previos.
- **Razón:** el usuario quiere construir el backend nuevo sin heredar decisiones de la implementación existente. Si el inventario se apoya en el DSL actual, el lenguaje nuevo nace condicionado por él.

### 19.3 DECISIÓN: solo elementos, nada de reglas

El documento contiene únicamente elementos del dominio. **No lleva sección de restricciones**. La tercera columna de cada tabla (`Qué papel desempeña`) describe el papel estructural —recurso, actividad, componente de la franja, dato de entrada— sin apoyarse en ninguna restricción.

### 19.4 DECISIÓN: estructura y estilo

1. **Descripción** — un solo párrafo, con las cuatro categorías en negrita: franja temporal, recurso, actividad y asignación.
2. **Una sección por dominio** — tabla de tres columnas (`Elemento` / `Qué contiene` / `Qué papel desempeña`) más un párrafo que fija la franja temporal, la unidad de asignación, qué se decide y qué es fijo.
3. **Unificación de los tres dominios** — tabla de cuatro columnas con las filas: Actividad, Recursos, Franja temporal, Cómo se forma la franja, Unidad de asignación, Qué se decide, Qué es fijo, Atributo con conjunto de valores, Atributo calculado, Lista de referencias.

**Excepción de estilo:** este documento **sí usa negrita** en el párrafo de Descripción. El resto de preferencias se mantiene.

### 19.5 Ediciones finales aplicadas

- **Descripción:** se dejó solo el párrafo de las cuatro categorías. Se eliminaron el introductorio y el de las cinco naturalezas de los atributos.
- **Defensas de tesis:** eliminado el último párrafo (los cinco papeles como referencias a la misma entidad profesor).
- **Defensas de tesis, fila Tribunal:** eliminado «la descripción lo nombra indistintamente como tribunal, defensa o tesis».
- **Horario docente:** eliminado el último párrafo (la capacidad del aula está pero no el tamaño del grupo).

### 19.6 Pendiente

Al eliminar el párrafo de las cinco naturalezas de los atributos, las tres últimas filas de la tabla de unificación —Atributo con conjunto de valores, Atributo calculado, Lista de referencias— quedaron sin la frase que las introducía. Falta decidir si se recortan o se reintroduce una frase corta que las ancle.

## 20. Preferencias de estilo del usuario

**Para documentos LaTeX** (resumen y similares): solo LaTeX + PDF, no markdown; sin negrita, cursiva ni otras fuentes; sin cajas encapsuladas por gusto; sin títulos con muchos niveles; sin índice ni portada; vista textual lo más sencilla posible; sin comentarios en el `.tex`; y **sin dejar evidencia meta de los cambios dentro del propio documento**.

**Para documentos markdown de entrega** (`inputs-usuario.md`, `limitaciones-del-dsl.md`): prosa directa sin conectores ni azúcar sintáctico; sin guiones largos; sin «etc.»; párrafos en vez de tablas y viñetas cuando el contenido lo permita; sin referencias a archivos y líneas del código; sin secciones de resumen que repitan lo dicho.

## 21. Operativa LaTeX / MiKTeX

- Compilar con `pdflatex` de MiKTeX en `C:\Users\rache\AppData\Local\Programs\MiKTeX\miktex\bin\x64`, dos pasadas, `-interaction=nonstopmode -halt-on-error`.
- El aviso "you have not checked for MiKTeX updates" es solo warning; no es error.
- **Paquetes disponibles**: babel spanish, amsmath, amssymb, booktabs, array, enumitem, xcolor, hyperref, geometry, lmodern, inputenc/fontenc.
- **Paquetes NO disponibles / evitar**: `tcolorbox` (arrastra muchas dependencias) y `fancyvrb`. Para cajas usar `\fbox`/`\fcolorbox` con `lrbox` + `minipage`; para código usar `verbatim` estándar.
- La auto-instalación de MiKTeX no se activó de forma fiable; mejor no depender de ella.
- Limpiar auxiliares tras compilar: `.aux .log .out .toc`.

## 21.1 Operativa SBCL / PowerShell

- SBCL está instalado desde el `.msi` oficial en `C:\Program Files\Steel Bank Common Lisp\sbcl.exe`. **No** está en el PATH de todas las shells; conviene invocarlo con la ruta completa.
- **`choco install sbcl` falla** con `Unable to resolve dependency 'python312'`. No tiene relación con SBCL: es un estado inconsistente previo del `lib` folder de Chocolatey (`python` y `python3` registrados, `python312` ausente) que bloquea cualquier operación de paquetes. Se arreglaría con `choco uninstall python python3 -y -n --skip-autouninstaller`, que borra solo el registro y deja intacto el Python real de `AppData\Local\Programs\Python\Python312`.
- **SBCL publica dos MSI por versión**, `arm64` y `x86-64`. La máquina es AMD64; el de `arm64` da «no es compatible con este tipo de procesador».
- **No generar archivos `.lisp` con `Set-Content -Encoding utf8`**: escribe BOM y SBCL falla al leerlos.
- Un script SBCL recibe sus argumentos en `(second sb-ext:*posix-argv*)` y conoce su propio binario en `sb-ext:*runtime-pathname*`.

## 22. Historial de decisiones (cronológico)

### Hilo 1 — backend ILP

1. Se analizaron los tres dominios y el pipeline completo. Codegraph solo indexa el Python generado, por eso los `.lisp` se leen con Read.
2. Se decidió la codificación **conjunta** de x (evita productos).
3. Se definió el principio de **evaluación parcial** (datos vs decisión) como motor.
4. Se construyó la **taxonomía** consulta→idioma de OR.
5. Se elaboraron los **modelos completos** de los tres dominios.
6. Se propuso la **arquitectura** del backend (módulos, matcher/emitter, formatos).
7. Se generaron los informes LaTeX + PDF.
8. El usuario pidió un **resumen** solo-LaTeX. Se produjo `modelo-matematico.tex/.pdf`; luego se refinó (se quitó la subsección 2.3, se resumió la sección 3).
9. **Marginales como restricciones**: la ecuación de la marginal pasó al bloque del modelo como restricción explícita, primero etiquetada "Enlace", luego renombrada a **"Marginal"**. Sin notas meta del cambio.
10. Se respondieron preguntas conceptuales: relación datos/decisión con la marginal, por qué la marginal es 0/1 y actúa como for/any, cómo se resuelve el modelo.
11. Se produjo `elementos-dominio-descripcion.tex` con la regla de fuente única (§19.2).

### Hilo 2 — descripciones, cuarto dominio y límites del DSL

12. Se localizaron las descripciones de los tres problemas en `cap3-dom.tex` (no en el capítulo de resultados, como se creía) y se produjo, para cada una, la versión textual y una traducción a lenguaje natural.
13. El usuario pidió prosa más directa, sin conectores ni azúcar sintáctico, sin guiones ni «etc.». Se rehicieron las tres.
14. Se verificó la completitud contra el capítulo y **se encontraron omisiones en las tres** (horas exactas de tesis, tres asignaturas y una restricción dura completa en docentes, secuencia y tupla de asignación en tv). Se corrigieron.
15. Se creó `inputs-usuario.md` con solo las versiones en lenguaje natural.
16. Se separó **input de resultado** (§5.2) y se depuró el archivo en consecuencia.
17. Se completaron asignaturas y capacidades leyendo los `dominio.lisp`; se detectó que el capítulo y la implementación **no coinciden** en las aulas.
18. Tablas → párrafos, a petición del usuario.
19. Se añadió a cada dominio el **input en el DSL**, copiado de los `dominio.lisp` (§18.1). Se usó codegraph para verificar identidad y slots variables de cada problema.
20. Se planteó el **cuarto dominio, departamento de profesores** (§6). Se analizaron qué restricciones duras y blandas añadir y cuáles descartar, y se añadió su descripción en lenguaje natural a `inputs-usuario.md`.
21. Se analizó **si el DSL soporta ese problema** (§6.2) y, a partir de ahí, **hasta dónde llega el lenguaje en general** (§3), leyendo `gen-consultas.lisp`, `gen-restricciones.lisp` y `gen-ast-python.lisp`. Hallazgos nuevos: `:devuelve` ignorado, umbral descartado en nppq, `hay-elementos-duplicados` muerto, `contar-distintos-dias` cableada.
22. Se creó `limitaciones-del-dsl.md` y se ajustó al estilo pedido (§18.2).
23. Se renombró esta base de conocimiento de `BASE-CONOCIMIENTO-backend-ilp.md` a `BASE-CONOCIMIENTO-tesis.md` y se reestructuró en cinco partes para que recoja toda la investigación, no solo el backend ILP.

### Hilo 3 — verbalizador (backend de lenguaje natural)

24. El usuario planteó un generador que tome el `dominio.lisp` y devuelva la descripción del problema **en prosa española**. Se analizó a fondo y se concluyó que no es "el generador al revés" sino un **cuarto lenguaje de salida** del mismo AST (PARTE VI).
25. Se identificó el contraste con el backend ILP: la verbalización **sí** es composicional nodo a nodo, luego el esquema `gcode` de MGA le aplica limpio; la linealización no lo es. Tener los dos casos convierte la observación de §15.3 en un contraste, no en un ejemplo suelto.
26. Se localizó el molde de implementación: `gen-ast-math.lisp` es el espejo exacto de lo que hay que construir.
27. Hallazgos nuevos del análisis del código, no registrados antes: **los slots de `def-entidad` no llevan tipo**; las `def-consulta` sin `:itera-sobre` compilan a `defun` y **se inlinean** en el AST del llamador; el `maphash` sobre `*slots-de-entidad*` da orden arbitrario, irrelevante para Python y fatal para la prosa. Ver §28.
28. Se fijó el plan por fases (§29) y el criterio de empezar por **tv**, el mismo que para el ILP y por la misma razón.

### Hilo 4 — implementación del verbalizador

29. Se montó el **sandbox** `C:\Pro\tesis\verbalizador` copiando del proyecto principal solo `clases-macros.lisp`, `gen-utils.lisp` y un extracto verbatim de tres archivos más (§30.1). Regla de separación: `lib/` prestado en español, `nlgen/` nuevo en inglés.
30. Se instaló SBCL desde el `.msi` oficial. Chocolatey falla por un estado inconsistente previo (`python312` ausente con `python`/`python3` registrados), sin relación con SBCL.
31. **Fase 0** (infraestructura), **1** (traducción literal), **2** (documento), **3** (orden topológico), **4** (idiomas) y **5** (los tres dominios): todas completas. 9 de 9 restricciones reconocidas.
32. Se retiró `infer-slot-types` del alcance a petición del usuario. Se comprobó que no afecta a la Fase 4 y se dejó registrado en §29.
33. Se descubrió la **colisión `def-clase`** (§28.4-bis) al cargar los tres dominios juntos. Obligó a rediseñar el runner como conductor + trabajador con un proceso SBCL por dominio (§30.5).
34. Se reestructuró en `dominios/` y `salida/` para que añadir un ejemplo no requiera tocar el runner, y se sustituyeron los `assert` por avisos no fatales (`revisar`).
35. Se produjeron `informe_verbalizador.md` y `PLAN-IMPLEMENTACION.md` en `verbalizador/doc/`.
36. Se recogieron en §30.4 los **ocho hallazgos sobre el backend ILP** que surgieron al implementar, y en §28.4-bis los cuatro sobre los datos del proyecto.

### Hilo 5 — el flujo de tres pasos y el quinto dominio (Saúl)

37. El usuario fijó un **procedimiento de tres pasos** para incorporar problemas reales: normalizar la descripción al estilo de las ya tratadas, traducirla al DSL sin omitir nada, y verbalizar para comprobar que las dos descripciones apuntan a lo mismo. Documentado en [`flujo-descripcion-a-dsl.md`](../flujo-descripcion-a-dsl.md) y en §31.
38. Primer caso: el **preuniversitario Saúl**, quinto dominio del proyecto. Paso 1 cerrado, paso 2 bloqueado a la espera de datos.
39. Hallazgos del paso 1 de Saúl, todos en §31.4: el DSL **no tiene pertenencia** (novena limitación, del modelo de datos); es el **primer dominio con adyacencia sobre un slot variable**; y los tres años no se pueden partir sin romper `colisiones-de-profesor`, lo que convierte el límite de §3.4 en un límite duro (§31.2).
40. **Sexto dominio: el SEDER de educación física** ([`base_de_conocimiento.md`](restrictions_language-main/base_de_conocimiento.md), PARTE V). Paso 1 cerrado, paso 2 bloqueado. Aporta el primer caso de **capacidad acumulada**, que choca de frente con «cuenta pero no suma» (§3.2). Se acotó el alcance asumiendo que las brigadas no comparten instalación, con la deficiencia anotada.
41. El usuario abrió el SEDER **sin cerrar los pasos 2 y 3 de Saúl**. Los dos casos quedan en el mismo estado y ninguno está medido todavía.

### Hilo 6 — inventario de deficiencias y reimplementación por capas

42. Se analizaron juntas las bases de conocimiento, `limitaciones-del-dsl.md` y el código del generador, y se compararon con la tesis de Arcia (MGA). El documento de límites cubría 8 de 33 problemas. Se produjo `informe-deficiencias.pdf`, que contiene un error corregido después (§37, punto 1).
43. Se concluyó que MGA resuelve la capa de emisión y no la expresividad del lenguaje, y que **no hay que importar `defnode`**: `def-clase` ya cubre más. Se escribió `mga-y-problemas-pendientes.md`.
44. El usuario fijó el objetivo: **rehacer toda la generación de código sobre funciones genéricas y una jerarquía de destinos, sin nada cableado**, de modo que añadir un lenguaje o una heurística no toque lo existente.
45. Se reorganizó el inventario por capas en `deficiencias-por-capa.md`. El usuario descartó los problemas de calidad de datos y los que no afectan a ningún dominio trabajado, y pidió fusionar los que dicen lo mismo. Quedaron 30 puntos.
46. Se corrigió Saúl: dos restricciones blandas estaban escritas con cuantificadores de dura (§37, punto 4).
47. Se escribió `plan-reimplementacion.md` y se tomaron las decisiones de la etapa 0 (§35).
48. **Etapa 0 completada** el 2026-11-02 (§36).

## 23. Próximos pasos posibles (no hechos aún)

> **Desde noviembre de 2026, los pasos sobre el generador están absorbidos por la reimplementación por capas** (PARTE VII): honrar `:devuelve` y el umbral del nppq, la colisión de nombres, el emisor ILP y el dominio del departamento tienen su etapa en [`plan-reimplementacion.md`](plan-reimplementacion.md). Lo que sigue se conserva como historial; el plan es la fuente vigente.

- Prototipar la generación ILP real de un dominio (recomendado: tv) hacia PuLP o MiniZinc, produciendo un `.py`/`.mzn` ejecutable y comparable contra el GA.
- Implementar los módulos `gen-ilp-*.lisp`.
- Capítulo empírico: resolver los casos con ambos backends y comparar optimalidad, tiempo, escalabilidad, gap del GA.
- **Arreglar los dos huecos del generador** (§3.5): honrar `:devuelve` y honrar el operando derecho en nppq. Son baratos y ensanchan mucho el alcance del backend GA.
- **Implementar el dominio del departamento** como cuarto `dominio.lisp`. Es el caso que prueba que el DSL no es de horarios, y el que mejor justifica el backend exacto.
- Decidir el pendiente de §19.6.
- Decidir si los inputs de `inputs-usuario.md` se rehacen desde la descripción, sin mirar la implementación, para cumplir el criterio de §19.2.
- ~~Implementar el verbalizador (PARTE VI)~~ — **HECHO**. Ver §30. Queda solo §30.6: la comparación sistemática contra `cap3-dom.tex`.
- **Corregir los números de §3.4, §4 y §13** con las cifras reales: docentes tiene 70 sesiones (no 65) y tesis 3 locales reales (no 4). Ver §30.4, punto 7.
- **Arreglar la colisión de nombres del DSL** (§28.4-bis): los constructores generados por `def-entidad` comparten espacio de nombres con las macros de `clases-macros.lisp`. Prefijar las macros de infraestructura, o moverlas a un paquete propio, **antes** de añadir el tercer backend.
- **Enchufar el emisor ILP al matcher ya escrito** (§30.4, punto 1). El reconocedor de patrones de §15.4 existe, funciona y está validado contra los tres dominios; falta el emisor de inecuaciones.

---

# PARTE VI — EL BACKEND DE LENGUAJE NATURAL (VERBALIZADOR)

> **ESTADO: IMPLEMENTADO Y FUNCIONANDO.** Lo que sigue (§24–§29) es el diseño; §30 documenta la implementación real, dónde vive y qué se aprendió al construirla. Las cinco fases del plan están completas y los tres dominios se verbalizan con el 100% de sus restricciones reconocidas.
>
> **Documentos del sandbox** (en `C:\Pro\tesis\verbalizador\doc\`):
> - `informe_verbalizador.md` — informe autocontenido: objetivo, ejemplo de entrada y salida, arquitectura, decisiones, hallazgos. Incluye la sección **«Lo que esto enseñó sobre el modelo matemático»**, que es material directo para PARTE IV.
> - `PLAN-IMPLEMENTACION.md` — plan operativo por fases, con qué archivo hace qué y por qué, casos borde y decisiones de implementación.

## 24. Qué es y cómo se posiciona

### 24.1 El objetivo

Un generador que toma el mismo `dominio.lisp` (entidades, consultas, restricciones, instancias) y emite la **descripción del problema en prosa española**, en vez de Python.

De esto:

```lisp
(def-entidad profesor (tiene-nombre) (grado))
(def-entidad tribunal () (estudiante tutor oponente presidente vocal secretario))
```

sale esto:

> Un profesor tiene nombre y grado. Un tribunal está formado por un estudiante, un tutor, un oponente, un presidente, un vocal y un secretario.

Y de la pareja `colisiones-de-local` + `restriccion-un-local-por-defensa`:

> Dos defensas distintas no pueden usar el mismo local en la misma fecha y el mismo momento.

### 24.2 No es "el generador al revés"

Aclaración necesaria porque el nombre engaña. Esto **no** es tomar un texto en español y producir el DSL: eso sería análisis de lenguaje natural, otro problema y mucho más duro. Esto es **generación de código en la dirección de siempre**, con el español como lenguaje de destino. Para el generador no hay diferencia: recorre un árbol y escribe cadenas en un archivo.

El término académico es **verbalización**. Linaje: Attempto Controlled English, los verbalizadores de ontologías OWL, SBVR Structured English. Todos hacen lo mismo: especificación formal → prosa controlada. Sirve de bibliografía para el capítulo.

### 24.3 Es el cuarto lenguaje de salida del mismo AST

```
                        ┌──► expr->py    ──► Python + GA          (existe)
   dominio.lisp ──► AST ├──► expr->math  ──► notación matemática  (existe)
                        ├──► expr->nl    ──► prosa española       (PARTE VI)
                        └──► backend ILP ──► modelo MILP          (PARTE IV, proyectado)
```

### 24.4 DECISIÓN / RESULTADO: la verbalización sí es composicional, la linealización no

§8 estableció que el backend ILP **no** puede ser un traductor sintáctico nodo a nodo (`op-and` de booleanos da un producto, que no es lineal), y §15.3 concluyó que por eso el macro `gcode` de MGA no le aplica.

La verbalización **sí** es composicional: `op-and` → «y», `op-igual` → «es el mismo que», `acceso-a-atributo-de-entidad` → «el X de Y». Se compone limpio, nodo por nodo, igual que `expr->py` y `expr->math`.

Por tanto, en el vocabulario de Generadores Multilenguajes ([`BASE-CONOCIMIENTO-mga-arcia-2017.md`](BASE-CONOCIMIENTO-mga-arcia-2017.md)), el verbalizador es el caso donde el esquema `defnode`/`gcode` / `generate-code (nodo lenguaje stream)` **aplica sin fricción**, y el ILP es el caso donde **se rompe**.

> Tener los dos casos convierte la observación de §15.3 en un **contraste demostrado**, no en un ejemplo suelto: se delimita dónde termina la traducción composicional y dónde empieza el reconocimiento de formas. Es material de capítulo.

## 25. Justificación (por qué vale la pena para la tesis)

Cuatro razones, de menor a mayor peso.

1. **Documentación que no envejece.** Hoy, si cambia un `dominio.lisp`, las descripciones de `descripcion-horarios/` se quedan viejas y nadie se entera. Una descripción generada no puede desincronizarse, por construcción.

2. **Cierra el ciclo con quien no programa.** El experto que conoce las reglas reales de la facultad no lee Lisp. Hoy el flujo se corta: el experto dicta, alguien codifica el DSL, y el experto **no tiene forma de verificar** que se codificó lo que dijo. Con el verbalizador el ciclo se cierra: DSL → prosa → el experto corrige. Sin esto, nadie fuera del autor puede validar un `dominio.lisp`, y eso es una debilidad real del sistema actual.

3. **Mide la fidelidad del DSL de forma reproducible.** Las discrepancias de §5.1 (aulas, capacidades, asignaturas, regla ausente, franja de tv, tipo de público) se encontraron con una lectura comparada manual. Con el verbalizador se obtienen poniendo la prosa generada al lado de `doc/cap3-dom/cap3-dom.tex`. Convierte una observación puntual en un **instrumento de medición** que cualquiera puede repetir y que sigue funcionando cuando el dominio cambie.

   El inventario resultante es de dos clases y hay que separarlas: lo que el DSL **no puede expresar** (capacidades, duración, tipo de público → refuerza `limitaciones-del-dsl.md` con evidencia mecánica) y lo que simplemente **no se codificó** (las aulas 3, 4, 7, 8, 9 → errores de transcripción).

4. **Demuestra la tesis con la tesis.** Tres salidas reales del mismo AST —un programa, unas fórmulas y un texto— demuestran el marco de Generadores Multilenguajes en vez de citarlo.

## 26. Qué ya existe y se reutiliza

`gen-ast-math.lisp` es el molde exacto. La correspondencia es casi uno a uno:

| Pieza existente | Su gemelo en el verbalizador |
|---|---|
| `expr->math` (`typecase` sobre ~20 tipos de nodo) | `expr->nl` — mismo `typecase`, otras cadenas |
| `bin->math` | `bin->nl` |
| `consulta->math-str` | `consulta->nl-str` |
| `restriccion->math-str` (ya hace `case` sobre `tipo-restriccion`) | `restriccion->nl-str` |
| `consultas-en-restriccion` | se reusa tal cual |
| `math-nombre` (`gen-utils.lisp`) | `nl-nombre` + género/número/artículo — aquí está el trabajo real |
| el recorrido de `generar-mostrar-modelo` | el recorrido del documento |
| `instancia->py` (`gen-serializar.lisp`) | lectura de los datos concretos |
| `recolectar-dominios` (`gen-consultas.lisp:5`) | se reusa tal cual |

Las dos fotos de `problema-horario` (`instancias`, `slots-entidades`, §2.3) hacen que el verbalizador sea, igual que el backend ILP, una **función pura** sin estado global mutable.

### 26.1 DECISIÓN: artefacto de tiempo de generación, no código que imprime

`generar-mostrar-modelo` emite **código Python que imprime** el modelo. El verbalizador **no** hace eso: escribe un archivo de texto en el momento de generar, como el `.tex`. No pasa por Python.

Punto de entrada hermano de `generar-python` en `generador.lisp`:

```lisp
(generar-descripcion "tv/descripcion.md" problema-tv)
```

## 27. Las capas

> En el diseño eran tres. La implementación las separó en **cuatro módulos**, porque la capa literal (nodo → fragmento de frase) merece archivo propio: es la que el resto usa como red cuando no reconoce un patrón.
>
> | Capa | Módulo | Qué hace |
> |---|---|---|
> | Léxico | `nlgen/lexicon.lisp` | símbolo → palabra española, con género, número, artículo y ortografía |
> | Literal | `nlgen/expr.lisp` | nodo del AST → fragmento de frase (§27.1 tabla) |
> | Documento | `nlgen/document.lisp` | las cinco secciones (§27.2) |
> | Idiomas | `nlgen/idioms.lisp` | reconoce la forma completa y elige una frase hecha (§27.3, §27.4) |
>
> Más `nlgen/order.lisp` para el orden topológico de las entidades (§29 Fase 3).

### 27.1 Capa léxica — el español (la que de verdad cuesta)

`math-nombre` solo hace `string-downcase` y `-`→`_`. La prosa necesita **género, número y artículo**: *un* profesor pero *una* fecha, *los* tribunales pero *las* fechas.

**DECISIÓN: regla general + tabla de excepciones**, no diccionario completo.

- Género: termina en `-a`, `-ción`, `-dad`, `-ez` → femenino; el resto masculino.
- Plural: vocal → `+s`; consonante → `+es`; `-z` → `-ces`.
- La tabla solo carga los casos que la regla falla (`local`, `momento`, `grado`, `tipo-programa`).

Funciones (nombres reales): `nl-name`, `nl-gender`, `nl-plural`, `nl-article`, `nl-noun`, `nl-var`.

**Tres niveles, no uno.** Al implementarlo hicieron falta:
1. `*lexicon*` — excepciones indexadas por el **símbolo entero** (`programa` masculino pese a terminar en `-a`, `dia` → «día», `orden` → «órdenes», `tipo-programa` → «tipo de programa»).
2. `*spelling*` — ortografía por **palabra suelta**, aplicada a cada segmento de un símbolo compuesto. `*lexicon*` no llega ahí: `restriccion-sin-mismo-tipo-consecutivo` habría necesitado entrada propia.
3. La regla `-cion`/`-sion` → `-ción`/`-sión` dentro de `spell`, que cubre restricción, repetición, emisión, asignación, duración, sesión y colisión **sin una sola entrada**. No dispara en falso con los plurales, porque «colisiones» ya es correcto.

**Regla del artículo para femeninos de *a* tónica.** «el aula», «un aula», pero «las aulas» y «la misma aula». Se marca con `:art-m` en el léxico y solo invierte el artículo en singular. Sin ella, docentes decía «una aula».

Correspondencia de nodos (capa literal, `nlgen/expr.lisp`):

| Nodo | `expr->math` | `expr->nl` |
|---|---|---|
| `op-and` | `∧` | «y» (aplanado, enumeración «A, B y C») |
| `op-or` | `∨` | «o» (aplanado) |
| `op-not` | `¬` | «no se cumple que …» |
| `op-igual` | `=` | «es igual a» |
| `op-distinto` | `≠` | «es distinto de» |
| `op-mayor` / `op-menor` | `>` / `<` | «es mayor que» / «es menor que» |
| `op-suma` | `+` | «la suma de X y Y» (forma nominal, para poder ser sujeto) |
| `acceso-a-atributo-de-entidad` | `tipo(p)` | «el tipo de p» |
| `consulta-simple` | llamada `f(h)` | se **expande en línea** |
| desconocido | `?` | `[NODO_DESCONOCIDO: <clase>]` |

> **«es igual a» y no «es el mismo que».** La segunda exige concordancia de género con el sujeto («el mismo» / «la misma»), y el sujeto es una expresión arbitraria cuyo género habría que calcular. «Es igual a» es invariable y siempre gramatical.
>
> **Contracciones.** Componer «de» + «el» produce «de el programa»; «igual a» + «el día» produce «a el día». Una pasada final (`contract`) los convierte en «del» y «al». Es idempotente.
>
> **Las consultas se expanden en línea**, al revés que `expr->math`, que imprime una llamada y deja la definición en un bloque «donde:». El DSL solo tiene un nivel de agregación, así que no hay recursión honda, y expandir hace que cada oración se baste sola.

### 27.2 Capa estructural — el documento

Cinco secciones, todas derivadas de `problema-horario`. **Orden final** (el plan inicial ponía la decisión al final; se movió al centro porque el lector necesita saber qué se decide antes de poder juzgar las restricciones):

1. **Entidades** — de `slots-entidades`. `def-entidad` → «Un programa tiene nombre, tipo, duración y canal.»; la entidad combinación (`entidad-horario`) → «Una emisión está formada por un bloque y un programa.» Son distinguibles porque la comb es exactamente `entidad-horario`. Los slots de mixin ya vienen fusionados en `all-slots` por `def-entidad`. Concordancia: «está formad**a**» / «formad**o**» según el género de la comb.
2. **Datos** — de `instancias`. Los símbolos están en la tabla y los valores en los `defvar`; `instancias-de` + slots recupera los literales. Enumerar si son diez o menos, contar si son más («Hay 56 bloques»). Caso aparte `n = 1`: «Hay un canal: Canal Habana», porque «Hay uno canal» es incorrecto.
3. **Qué se decide** — de `entidad-horario`, `slot-identidad` y `slots-variables`: «Cada fila del horario es una emisión. Se decide, para cada bloque, qué programa le corresponde.» Con varios slots variables: «…qué fecha, qué momento y qué local le corresponden.»
4. **Qué se mide** — las consultas.
5. **Restricciones** — Obligatorias / Preferencias.

**Dos filtros imprescindibles descubiertos al implementar:**
- `real-entity-p` — `slots-entidades` incluye los **mixins**. Sin filtrarlos, el documento abría con «Un tiene nombre tiene nombre.» El test es limpio: `def-entidad` crea un `defvar` ligado a un `ref-gen-entidad`; `defclass*` no.
- `instance-label` — cómo se nombra una instancia en prosa. Misma lógica de elección que `generar-str-entidad`: el slot `nombre` si existe, el único slot si solo hay uno, la tupla si hay varios. Mantenerla igual hace que los dos backends nombren las cosas del mismo modo.

**`numero->nl`** deletrea del 0 al 20 y usa cifras por encima. `format ~R` solo deletrea en inglés.

### 27.3 Capa de idiomas — reconocer la forma, no traducir el nodo

La traducción literal de `conflictos-de-horario` es correcta e ilegible:

> La suma, para cada profesor p, cada asignación a1 y cada asignación a2, de los casos en que p es el tutor de a1 o p es el oponente de a1 o … y la fecha de a1 es la misma que la fecha de a2 y el momento de a1 es el mismo que el momento de a2 y el tribunal de a1 es distinto del tribunal de a2, no puede ser mayor que cero.

Lo que un humano escribe es:

> Dos defensas distintas que comparten un profesor no pueden coincidir en la misma fecha y el mismo momento.

La diferencia es que el humano **reconoce la forma completa** y elige una frase hecha.

**RESULTADO: ese reconocedor es el mismo de §12/§15.4.** La taxonomía construida para el backend ILP clasifica; luego hay dos emisores distintos:

| Forma reconocida (§12) | El ILP emite | La prosa emite |
|---|---|---|
| choque pairwise, misma celda, identidad distinta | `Σ x ≤ 1` por celda | «Dos X distintas no pueden compartir ⟨celda⟩.» |
| choque discriminando por atributo de datos | `Σ_g w ≤ 1` | «En ⟨celda⟩ no pueden coincidir dos ⟨atributo⟩ distintos.» |
| `tqpq`, conteo = K | `Σ x = K` | «Cada X debe tener exactamente K ⟨…⟩.» |
| `nppq`, conteo ≤ K | `Σ x ≤ K` | «Ningún X puede superar ⟨K⟩ ⟨…⟩.» |
| `minimizar` + `contar-distintos-dias` | `Z ≥ …; min Z` | «Se prefiere el reparto que reduce el número máximo de ⟨…⟩ de cualquier X.» |
| adyacencia con atributo del valor decidido | `z + z ≤ 1` sobre CONS | «Dos X consecutivos no pueden ser del mismo ⟨atributo⟩.» |

> Que la misma clasificación produzca **una inecuación y una oración** significa que esos patrones no son un artefacto del ILP: son **estructura del lenguaje**. Es el segundo resultado de esta parte, junto al de §24.4.

**Regla de seguridad.** La capa de idiomas va *encima* de la literal, nunca en lugar de ella: se intenta reconocer el patrón y, si no encaja ninguno, se cae a la traducción literal. Nunca falla en silencio. Mismo principio que el `# NODO_DESCONOCIDO` de `expr->py`.

### 27.4 El matcher, a nivel de átomo (el algoritmo, tal como quedó)

> **Esta es la pieza que §15.4 daba por pendiente para el backend ILP.** Está implementada en `verbalizador/nlgen/idioms.lisp` como `match-pairwise` y validada contra las nueve restricciones de los tres dominios. §27.3 da la clasificación de *salida* (qué idioma emitir); esto es la clasificación de *entrada*, que es lo que faltaba escribir.

**Paso previo: `access-path`.** Descompone una cadena de accesores en camino + raíz:

```
(tipo (programa e1))   ->   camino (TIPO PROGRAMA),  raíz E1
```

El **último tramo del camino es siempre un slot de la entidad combinación**, porque las cadenas del DSL arrancan en una variable que itera sobre ella. De ahí sale la simplificación de §30.4 punto 2.

**Reconocimiento del patrón.** Se exige que exactamente **dos** variables de iteración recorran la entidad combinación (`v1`, `v2`). Después se aplana el `op-and` y cada átomo se clasifica en uno de cinco papeles:

| Papel | Forma en el AST | Qué significa | Su parte en el modelo |
|---|---|---|---|
| **compartido** | `(op-igual (f v1) (f v2))` | los dos coinciden en `f` | la **celda** (si es decisión) o el **filtro** precomputado (si es dato) |
| **distinto** | `(op-distinto (f v1) (f v2))` | son elementos diferentes según `f` | `Σx ≤ 1` si `f` es la identidad; presencia + `Σ_g w ≤ 1` si es otro atributo |
| **adyacente** | `(op-igual (op-suma (f v1) k) (f v2))` | son consecutivos en `f` | el conjunto `CONS` precomputado (§13.3) |
| **enlace** | `(op-igual (f vX) S)`, con `S` una tercera variable | ambos apuntan al mismo tercero | ver abajo |
| **roles** | `op-or` de igualdades contra el mismo `S` por caminos distintos | lo que queda del inlining de una consulta auxiliar (§28.2) | la matriz de incidencia `a_{p,t}` (§10.1) |

**Normalización de los enlaces.** Dos enlaces a la misma variable por el mismo camino equivalen a un compartido:

```
canal(prog(e1)) = c   y   canal(prog(e2)) = c
        implica   canal(prog(e1)) = canal(prog(e2))
```

**Partición datos/decisión de los compartidos.** `(member (car (last camino)) slots-variables)`. Una comparación, no un recorrido. Decide la **estructura de la oración**: los de datos describen al par («dos emisiones *del mismo día*»), los de decisión son lo prohibido («*con el mismo tipo*»). En el ILP decide qué es celda y qué es filtro precomputado.

**DECISIONES de seguridad, las dos restrictivas a propósito:**
- **Un solo átomo sin clasificar aborta el patrón entero.** Mejor un párrafo literal feo que una oración que se deja algo fuera en silencio. En el ILP el equivalente sería emitir una inecuación que ignora una condición: un modelo incorrecto que parece correcto.
- **Un enlace sin pareja aborta también.** Si `(f v1) = S` aparece sin su gemelo para `v2`, no se sabe interpretar.

**Nombrar la dimensión que discrimina (`distinct->nl`)** es lo que hizo funcionar docentes. Si el camino es exactamente `(slot-identidad)` basta «distintas»; si no, hay que nombrarlo: «de aulas distintas», «de grupos distintos». **Es la misma decisión que elegir entre `Σx ≤ 1` y `Σ_g w ≤ 1`** (§30.4 punto 3).

## 28. Hallazgos del código y trampas conocidas

### 28.1 Los slots de `def-entidad` no llevan tipo

`(def-entidad tribunal () (estudiante tutor oponente presidente vocal secretario))` — nada dice que `tutor` sea un profesor. El DSL solo registra que existe un slot llamado `tutor`. Igual con `(def-entidad fecha () (dia mes))`: aquí `dia` es un número, en tv y docentes es una entidad.

Consecuencia: la prosa literal solo puede decir «un tribunal tiene un estudiante, un tutor, un oponente…», mientras la descripción humana dice «un tribunal de cinco profesores con roles fijos». Esa información **no está en el AST**.

**Arreglo barato: inferir el tipo desde las instancias.** Un bucle sobre `problema-horario-instancias`: si todos los valores de `tutor` son instancias de `profesor`, el slot es una referencia a profesor; si todos son números, es una magnitud. No toca el lenguaje, solo lee la foto que `problema-horario` ya guarda.

**Arreglo caro:** tipar los slots en el DSL (`(tutor profesor)`). Cambia el lenguaje; anotar el coste antes de decidir.

> **ESTADO: fuera del alcance de la implementación** (decisión del usuario, §29 Fase 3). Del arreglo barato se conservó **solo la arista del grafo** —si un slot apunta a otra entidad y a cuál—, que es lo que el orden topológico necesita. Se descartó la clasificación de los slots que no son referencias y toda la prosa tipada que dependía de ella. Consecuencia visible: tesis dice «Un tribunal tiene estudiante, tutor, oponente, presidente, vocal y secretario» y no «está formado por un estudiante y cinco profesores».
>
> Si algún día se quiere, `entity-refs` (§28.3) ya tiene medio hecho el trabajo: la arista que dice «`bloque.dia` apunta a `dia`» es exactamente lo que hace falta para escribir «un bloque pertenece a un día».

> Esta es una limitación del **modelo de datos** del DSL, paralela pero distinta a las ocho de §3.2, que son todas de expresividad de restricciones. Conviene registrarla como novena, o como categoría aparte. **Retirarla del alcance de la implementación no la borra del análisis.**

### 28.2 Las consultas auxiliares se inlinean y desaparecen del AST

`def-consulta` **sin** `:itera-sobre` compila a un `defun` ordinario (`clases-macros.lisp:296`), no a un nodo. Cuando `conflictos-de-horario` escribe `(profesor-en-tribunal p a1)` dentro de `:comprueba`, eso **se evalúa** y deja en el árbol un `op-or` de cinco `op-igual`. El nombre `profesor-en-tribunal` no existe en el AST y no está en `*consultas-por-nombre*`, que solo registra nodos `consulta-simple`.

Consecuencias:
- Para describir la auxiliar por separado hay que llamarla con símbolos: `(profesor-en-tribunal 'prof 'asig)` devuelve el nodo. Funciona, pero hay que conocer sus nombres: no existe registro de auxiliares.
- Dentro de la restricción, o se acepta verbalizar la disyunción cruda («es tutor, oponente, presidente, vocal o secretario de a1», que de hecho se lee bien) o se reconoce el árbol inlineado contra un registro de auxiliares para recuperar el nombre. Lo primero basta; lo segundo es un lujo.

### 28.3 El orden de `maphash` es arbitrario

`generar-python` recorre las entidades con `maphash` sobre `*slots-de-entidad*` (`generador.lisp:191`). A Python le da igual el orden de las clases; a la prosa no: hay que introducir `profesor` antes que `tribunal`, y `tipo-programa` antes que `programa`.

Hace falta **orden topológico** por dependencia de slots. Es poco trabajo, pero si se deja para el final hay que reescribir la sección de entidades.

> **RESUELTO** en `verbalizador/nlgen/order.lisp`. `entity-refs` construye el grafo mirando **las instancias reales**, no los nombres de los slots: en tv el slot `tipo` apunta a `tipo-programa`, y en tesis `tutor`, `oponente`, `presidente`, `vocal` y `secretario` apuntan todos a `profesor` sin que el nombre lo diga. Un heurístico por nombre fallaría en cinco de seis.
>
> Tres detalles que costaron:
> - **La entidad combinación no tiene instancias** (nadie crea emisiones, las produce el solver). Pero `def-comb` declara sus componentes **como slots**, y esos sí son nombres de entidad por construcción. El grafo se lee de ahí y la comb acaba última sola, sin tratarla como caso especial.
> - **El orden base tiene que ser determinista.** Un orden topológico no es único, y si el desempate lo decide `maphash` el documento baila entre ejecuciones. Se ordena por (número de referencias ascendente, luego alfabético). Importa porque el documento se va a comparar por diff (§30.7).
> - **Guarda contra ciclos:** la marca `:en-curso` los detecta y corta; el DSL no los produce hoy, pero el ordenador degrada al orden base en vez de colgarse.
>
> Resultado en tv: `canal`, `dia`, `tipo-programa` (las hojas, alfabético), luego `bloque`, `programa`, `emision`.

### 28.4 La prosa generada será fiel pero pelada

`inputs-usuario.md` empieza con «Se planifica la convocatoria de defensas de tesis del curso 2025-2026 de la Facultad de Matemática y Computación de la Universidad de La Habana». Nada de eso está en el `dominio.lisp`. Tampoco las capacidades de las aulas (§5.1, dato muerto), ni el tipo de público de tv.

**DECISIÓN: el objetivo no es reproducir `inputs-usuario.md`**, sino producir una paráfrasis fiel y verificable de lo que el DSL realmente dice. El hueco entre las dos prosas **es** la medida de lo que el DSL no captura (§25, razón 3). Si el generador produjera el texto idéntico, no se habría aprendido nada.

### 28.4-bis Hallazgos de la Fase 5 (al verbalizar los tres dominios)

Encontrados al ejecutar el verbalizador sobre tesis, docentes y tv. Los cuatro son sobre el proyecto, no sobre el verbalizador.

- **Colisión de macros en el DSL.** `docentes/dominio.lisp` declara `(def-comb clase (sesion aula dia turno))`. `def-comb` expande a `def-entidad`, que genera la macro constructora `DEF-CLASE`. Pero **`def-clase` es la macro central de `clases-macros.lisp`**, la que define todas las clases del AST. Cargar docentes y después cualquier otro dominio falla con `illegal function call` al expandir `defclass*`. No se había visto nunca porque cada `dominio.lisp` se ejecuta en su propio proceso SBCL. Es un fallo latente del lenguaje: **el espacio de nombres de los constructores generados y el de las macros de infraestructura son el mismo**. Cualquier entidad llamada `clase`, `entidad`, `comb`, `consulta`, `nodos`, `subclases` o `jerarquias` lo reproduce.
- **`Francofonia` y `Francofomia`** son dos instancias distintas de `local` en tesis. Una es errata de la otra. El dominio declara **cuatro** locales; en realidad hay tres. §4 y §13.1 dan «4 locales» y el tamaño de x (1092) está calculado sobre esa cifra.
- **docentes tiene 70 sesiones, no 65.** §4 y §3.4 registran 65 y calculan sobre ella el tamaño (11 700 binarias) y el costo de `colisiones-de-profesor` (6 × 65 × 65). Recuento real: filosofía 10, álgebra 10, AM 10, prog 5, lógica 5, ed. física 5, álgebra CP 5, AM CP 5, prog CP 10, lógica CP 5 = **70**.
- **`frecuencia` es dato muerto en docentes.** La entidad `asignatura` la declara, y ninguna restricción la usa porque `restriccion-frecuencia-exacta` se omite a propósito del `def-problema-horario`. Es el mismo patrón que la capacidad del aula (§5.1): un atributo que existe en el modelo y no llega a ninguna regla.

> El verbalizador expuso los cuatro sin buscarlos. Es el mecanismo de §25 (razón 3) funcionando a escala pequeña, antes de la comparación sistemática contra `cap3-dom.tex`.

### 28.5 Números en letra

`format nil "~R"` deletrea números solo en inglés. Para «trece defensas» hace falta una tabla pequeña, o usar cifras. `inputs-usuario.md` mezcla las dos formas. Es menor; decidir al llegar.

### 28.6 El estilo del usuario juega a favor

Las preferencias de §20 —frases cortas, sin conectores, sin guiones largos, sin «etc.»— son exactamente lo que un verbalizador por plantillas hace bien. Lo que en una persona es disciplina, en el generador sale gratis y sale igual siempre. El generador **estabiliza** ese estilo mejor que la escritura a mano.

## 29. Plan por fases

Cada fase entrega algo que corre. Si se para después de cualquiera, lo hecho sirve.

| Fase | Qué se construye | Qué entrega |
|---|---|---|
| 1 | `lib/gen-ast-nl.lisp` — traductor nodo→frase + capa léxica | Frases correctas aunque torpes |
| 2 | `generar-descripcion` + las cinco secciones | `tv/descripcion.md` completo |
| 3 | Inferencia de tipos de slot + orden topológico | Prosa que se lee de arriba abajo |
| 4 | Reconocedor de patrones (el mismo del ILP) | Frases como las escribiría un humano |
| 5 | Los tres dominios + diff contra `cap3-dom.tex` | Inventario reproducible de discrepancias |

**Fase 1.** Copiar la estructura de `gen-ast-math.lisp` y cambiar las cadenas (§27.1). Añadir `nl-nombre` / `nl-genero` / `nl-plural` / `nl-art`. Sin idiomas todavía. ~120 líneas. *Verificación:* pasarle el nodo de `adyacentes-mismo-tipo` y obtener algo legible, aunque largo.

**Fase 2.** Punto de entrada `generar-descripcion` en `generador.lisp`, reusando el recorrido de `generar-mostrar-modelo`. *Verificación:* un `assert` de cobertura — cada entidad, consulta y restricción del `problema-horario` aparece al menos una vez en el texto emitido. Es la comprobación más pequeña que falla si el recorrido se rompe.

**DECISIÓN: empezar por tv.** Es el dominio más pequeño (un solo slot variable, 8 programas, 56 bloques) y aun así contiene el patrón más difícil (adyacencia con atributo del valor decidido). Mismo criterio y misma razón que la recomendación de §13.3 para prototipar el ILP.

**Fase 3.** §28.1 y §28.3. Es el añadido de mayor retorno por unidad de esfuerzo en todo el verbalizador.

**Fase 4.** La capa de idiomas de §27.3, como *override* sobre la literal.

**Fase 5.** Correr sobre tesis y docentes y comparar contra `doc/cap3-dom/cap3-dom.tex`, separando las dos clases de discrepancia de §25.

### 29.1 Relación con el backend ILP

Las dos líneas comparten el matcher de §15.4 (pasos 1–5 del algoritmo). Conviene implementarlo **una vez**, en un módulo propio, con dos emisores enchufados detrás. Si se hace primero el verbalizador, el matcher queda escrito y probado —sobre un destino mucho más fácil de inspeccionar a ojo— antes de atacar la emisión de inecuaciones.

> Argumento de orden: prototipar el verbalizador **antes** que el ILP reduce el riesgo del ILP, porque valida el reconocimiento de patrones sin necesitar solver ni verificar optimalidad. Un error del matcher se ve leyendo una frase.
>
> **Confirmado en la práctica** (§30.4): el matcher se escribió, se probó contra las nueve restricciones de los tres dominios, y el único error que cometió fue exactamente el que en el ILP equivale a confundir `Σx ≤ 1` con `Σ_g w ≤ 1`.

---

## 30. La implementación real

### 30.1 Dónde vive

Sandbox aislado en `C:\Pro\tesis\verbalizador`, construido copiando del proyecto principal solo lo imprescindible. **No toca `restrictions_language-main`.**

```
verbalizador/
├── doc/          informe_verbalizador.md, PLAN-IMPLEMENTACION.md
├── lib/          prestado del proyecto original, español, sin modificar
│   ├── clases-macros.lisp   copia byte a byte
│   ├── gen-utils.lisp       copia byte a byte
│   └── problema.lisp        extracto verbatim de generador.lisp:44-129,
│                            gen-serializar.lisp:5-11,35-38,
│                            gen-restricciones.lisp:12-20
├── nlgen/        código nuevo, inglés
│   ├── lexicon.lisp    morfología española (género, número, artículo,
│   │                   ortografía) + registro de consultas
│   ├── expr.lisp       capa literal: expr->nl, query->nl, constraint->nl
│   ├── order.lisp      entity-refs, entity-order (orden topológico)
│   ├── idioms.lisp     el matcher + los emisores
│   └── document.lisp   generate-description, revisar
├── dominios/     un archivo por ejemplo: tv, tesis, docentes
├── salida/       los .md generados
└── run.lisp      recorre dominios/ y lanza un proceso por dominio
```

**Regla de separación:** `lib/` es prestado y se puede re-sincronizar desde el proyecto original; `nlgen/` es nuevo. Por eso los nombres están en idiomas distintos.

**Requisito único: SBCL.** No necesita Python, porque el verbalizador escribe texto en tiempo de generación en vez de emitir un programa que lo imprima. Instalado desde el `.msi` oficial (el paquete de Chocolatey falla por un estado inconsistente previo del gestor, sin relación con SBCL).

Ejecución:

```
sbcl --script run.lisp          todos los dominios
sbcl --script run.lisp tesis    solo uno
```

Para añadir un dominio basta dejar su `.lisp` en `dominios/`; el runner recorre la carpeta. Única convención: `dominios/tesis.lisp` declara `problema-tesis`.

### 30.2 Resultado

Las cinco fases de §29 están completas. Los tres dominios se verbalizan con **todas** sus restricciones reconocidas por un idioma: 9 de 9. El reconocedor no quedó sobreajustado a tv.

| Dominio | Entidades | Consultas | Restricciones | Idiomas | Caracteres |
|---|---|---|---|---|---|
| docentes | 8 | 4 | 4 | 4/4 | 2192 |
| tesis | 8 | 3 | 3 | 3/3 | 1720 |
| tv | 6 | 2 | 2 | 2/2 | 1433 |

Muestra de salida (tesis y docentes):

> No puede haber dos asignaciones distintas que compartan un profesor con la misma fecha y el mismo momento.
>
> No puede haber dos asignaciones distintas con el mismo local, la misma fecha y el mismo momento.
>
> Se prefiere la solución que minimiza, para el profesor más cargado, el número de días distintos en los que interviene.
>
> No puede haber dos clases de aulas distintas del mismo profesor con el mismo día y el mismo turno.
>
> No puede haber dos clases de grupos distintos con la misma aula, el mismo día y el mismo turno.

Para comparar, la misma primera restricción en la capa literal ocupa 406 caracteres y la idiomática 91.

### 30.3 Desviaciones del plan, con su causa

| Qué cambió | Por qué |
|---|---|
| `query->nl` pasó de la Fase 2 a la Fase 1 | El molde (`consulta->math-str`) la tiene, y `constraint->nl` la necesita: un `nppq` envuelve una consulta y sin expandirla la oración no dice nada |
| Se añadió `params->nl` | La primera versión ignoraba el slot `args` y producía prosa con una variable libre («…es igual a c», sin que `c` se declarase nunca) |
| Se añadió la capa `*spelling*` con la regla `-cion`/`-sion` → `-ción`/`-sión` | `*lexicon*` indexa el símbolo entero y no llega a los compuestos: `restriccion-sin-mismo-tipo-consecutivo` habría necesitado entrada propia. La regla cubre restricción, repetición, emisión, asignación, duración, sesión y colisión sin ninguna |
| La sección «Qué se decide» se movió al centro del documento | El lector necesita saber qué se decide antes de poder juzgar las restricciones |
| Se retiró `infer-slot-types` del alcance | Decisión del usuario: interesa el orden, no la prosa tipada. Se conservó solo el grafo de referencias, que es lo que el orden necesita. La Fase 4 no se vio afectada (§29.1) |
| `verify-coverage` (que lanzaba error) pasó a ser `revisar`, que devuelve una lista de avisos | El documento debe escribirse siempre; quien llama decide si avisar |
| **Un proceso SBCL por dominio** | Ver §30.5. No es una preferencia: cargarlos juntos no funciona |

### 30.4 Lo que la implementación enseñó sobre el backend ILP

Desarrollado en la sección «Lo que esto enseñó sobre el modelo matemático» de `informe_verbalizador.md`. Resumen:

1. **El matcher de §15.4 ya está escrito y probado.** `match-pairwise` hace los pasos 1-4 del algoritmo (clasificar el cuantificador, tomar la consulta y su operación, aplanar el `op-and` en átomos, clasificar cada átomo en datos/decisión) y está validado contra las nueve restricciones de los tres dominios reales. El backend ILP no tiene que construirlo: tiene que enchufarle otro emisor. **La mitad difícil del trabajo pendiente resultó estar hecha.**

2. **El test datos/decisión se colapsa a una consulta, no a un recorrido.** §10.2 lo formula como «todos los símbolos de los que depende son fijos», lo que sugiere recorrer un grafo. Al implementarlo: las cadenas de acceso del DSL siempre terminan en una variable que itera sobre la entidad combinación, así que **el último tramo del camino es un slot de esa entidad**; basta `(member (car (last camino)) slots-variables)`. Una comparación. Es una simplificación real de un diseño ya escrito.

3. **Nombrar la dimensión que discrimina y elegir entre `Σx ≤ 1` y `Σ_g w ≤ 1` son la misma decisión.** §12 dice que «el lugar del atributo que discrimina decide la forma». El verbalizador tropezó con eso sin buscarlo: las tres restricciones de choque de docentes tienen forma idéntica, y la primera versión las escribió las tres como «dos clases distintas», indistinguibles. El arreglo (`distinct->nl`) fue nombrar la dimensión: «de aulas distintas», «de grupos distintos». **Escribir mal la frase y modelar mal la restricción son el mismo error**, y en prosa se ve leyendo una línea.

4. **Los cuatro papeles del matcher mapean uno a uno a las partes del modelo:**

   | Papel del átomo | Su parte en el modelo |
   |---|---|
   | `shared`, lado decisión | la **celda**: el conjunto de índices del packing |
   | `shared`, lado datos | el **filtro/agrupación** precomputada (§10.1) |
   | `distinct` sobre la identidad | `Σ x ≤ 1` |
   | `distinct` sobre un atributo de datos | variable de presencia + `Σ_g w ≤ 1` |
   | `adjacent` | el conjunto `CONS` precomputado (§13.3) |
   | `roles` (el `op-or` inlineado) | la matriz de incidencia `a_{p,t}` (§10.1) |

5. **Una errata de datos es inocua para el GA y peligrosa para el solver exacto.** Los dos locales `Francofonia`/`Francofomia` (§28.4-bis) son, para el GA, un valor de más en el pool. Para el MILP, dos elementos idénticos hacen que toda solución tenga un gemelo obtenido al intercambiarlos: **simetría**, patología clásica de branch-and-bound. Conclusión de ingeniería: el control de calidad de la entrada importa **más** para el backend exacto que para el metaheurístico, y verbalizar antes de modelar es la forma barata de hacerlo.

6. **La restricción que el GA descarta es trivial en el ILP.** `restriccion-frecuencia-exacta` se omite del `def-problema-horario` de docentes, y por eso `frecuencia` es dato muerto. En el ILP es `Σ_{a,d,u} x_{s,a,d,u} = K` — el idioma de covering de §12, de los más simples del catálogo. Caso concreto de §16.10.

7. **Los tamaños de modelo de §13 están mal.** Con 70 sesiones (no 65), docentes es 70·6·5·6 = **12 600** binarias, no 11 700. Con 3 locales reales (no 4), tesis es 13·3·7·3 = **819**, no 1092. Y el costo cuadrático de §3.4 para `colisiones-de-profesor` es 6·70·70 ≈ 29 400, no 25 000 — lo que **agranda** la ventaja del packing: 180 inecuaciones (6·5·6 celdas) frente a 4 900 pares por evaluación.

8. **El aislamiento por proceso condiciona el capítulo empírico.** La validación cruzada de §14 y §16.6 exige ejecutar varios dominios y comparar. Con la colisión de §30.5, ese banco de pruebas tiene que aislar por proceso desde el principio.

### 30.5 DECISIÓN: un proceso SBCL por dominio

Los dominios **no se pueden cargar juntos en la misma imagen**. Dos motivos, el segundo sin arreglo desde fuera del DSL:

1. Las macros acumulan en `*instancias-de-entidad*` y `*slots-de-entidad*`, y `def-problema-horario` las fotografía al final del archivo. El segundo dominio se llevaría en su foto las entidades del primero. Esto se arregla vaciando las tablas.
2. **Los constructores generados tapan macros de la infraestructura.** `docentes` declara `(def-comb clase ...)` → `def-entidad` genera la macro `DEF-CLASE` → y `def-clase` **es la macro central de `clases-macros.lisp`**. Ver §28.4-bis.

En el proyecto original nunca se vio porque cada `dominio.lisp` se ejecuta en su propio proceso. Aislar es además lo correcto: cada documento sale de una imagen limpia, que es lo que exige compararlos por diff.

### 30.6 Detalles de implementación no obvios

Cosas que costaron encontrarse y que hay que saber antes de tocar el código.

**El runner.** Dos modos en un archivo. Sin argumento es **conductor**: recorre `dominios/*.lisp` ordenados por nombre y lanza `sb-ext:run-program` sobre `sb-ext:*runtime-pathname*` (la ruta del SBCL en ejecución) con `--script run.lisp <nombre>`. Con argumento es **trabajador**. El argumento llega en `(second sb-ext:*posix-argv*)`.

**`*load-truename*` y no `(truename ".")`.** Los `dominio.lisp` originales resuelven contra el directorio actual y fallan si se invocan desde otra carpeta. `run.lisp` usa `(or *load-truename* (truename "."))`.

**`revisar` sustituye a los `assert`.** Devuelve una lista de avisos en vez de romper: el documento se escribe siempre y el trabajador decide si hablar. Salida limpia = todo pasó. Comprueba seis cosas:
1. sin `NODO_DESCONOCIDO` en el texto,
2. sin `RESTRICCION_DESCONOCIDA`,
3. contracción «de el» aplicada,
4. contracción «a el» aplicada,
5. **cobertura** — cada entidad, consulta y restricción declarada aparece en el texto (búsqueda con `char-equal`, porque las etiquetas llevan mayúscula inicial),
6. **invariante topológico** — toda entidad referenciada aparece antes que la que la referencia, comprobado sobre todos los pares.

**Dos trampas de codificación en Windows:**
- Al escribir el `.md` hace falta `:external-format :utf-8` explícito en `with-open-file`. El default de SBCL en Windows puede no serlo, y los acentos salen rotos **en el archivo** aunque se vean bien en consola.
- **`Set-Content -Encoding utf8` de PowerShell escribe un BOM**, y SBCL falla al leer el archivo con `The variable ... is unbound`. Para generar `.lisp` desde PowerShell hay que evitarlo.

**`lib/clases-macros.lisp` tiene mojibake en los comentarios** (`Ã¡`, `â†'`). Es inofensivo, solo afecta comentarios. Hay que copiarlo **byte a byte**; no abrirlo y volver a guardarlo con otra codificación.

**`instance-label` y `entity-refs` leen las globales**, no la foto del problema. Toda función que las use debe ir dentro del `let` que rebindea `*instancias-de-entidad*` y `*slots-de-entidad*`. `description-text` y `revisar` lo hacen.

### 30.7 Lo que queda

La **comparación sistemática** contra `doc/cap3-dom/cap3-dom.tex`. Los cuatro hallazgos de §28.4-bis salieron de una lectura rápida de la salida; el inventario completo —separando «lo que el DSL no puede expresar» de «lo que no se codificó»— está sin hacer. Es trabajo de lectura comparada, no de código.

---

## 31. El flujo de tres pasos y el quinto dominio (preuniversitario Saúl)

> **ESTADO: pasos 1 y 2 cerrados, paso 3 en curso.** El dominio está traducido, corre en los dos backends y está verificado. La prosa generada ya es legible: el reconocedor de patrones pasó de cubrir una familia a cubrir cinco, y Saúl reconoce 11 idiomas de 11. Falta la comparación sistemática de esa prosa contra la descripción, que es lo que cierra el paso 3.
>
> Esta sección cubre hasta el cierre del paso 1. **Todo lo posterior está en [`base_de_conocimiento.md`](../base_de_conocimiento.md)**: la reestructuración del modelo, los tres defectos del lenguaje que aparecieron, el procedimiento operativo, cómo ejecutar los dos backends y las medidas de rendimiento. El documento del acuerdo es [`flujo-descripcion-a-dsl.md`](../flujo-descripcion-a-dsl.md).
>
> **No se abre otro problema de horario hasta cerrar los tres pasos de éste.** El flujo solo sirve si se recorre entero: el paso 3 es lo que mide si el paso 2 perdió algo, y saltar a otro dominio con el paso 2 sin escribir deja la medición sin hacer.

### 31.1 El procedimiento

Acordado por el usuario el 2026-09-21. Tres pasos, cada uno cerrado antes de empezar el siguiente.

| Paso | Qué se hace | Con qué | Qué entrega |
|---|---|---|---|
| 1 | Normalizar la descripción cruda al estilo y la forma de las ya tratadas | `inputs-usuario.md`, `descripcion-horarios/*.md`, `cap3-dom.tex` §3.5, estilo de §20 | Descripción legible, paralela a los cuatro dominios existentes |
| 2 | Traducirla al DSL, **sin omitir datos ni restricciones** | El lenguaje de §2.1; es la entrada del verbalizador (§30.1) | Un `dominio.lisp` nuevo |
| 3 | Verbalizar y comparar las dos prosas | El verbalizador (PARTE VI) y su función `revisar` (§30.6) | Confirmación de equivalencia, resumen de datos y formato de salida deseado |

**El paso 3 es el mecanismo de §25 razón 3 aplicado a un dominio nuevo**, no a los tres existentes: en vez de medir la fidelidad de un `dominio.lisp` ya escrito contra el capítulo 3, mide la fidelidad de uno recién escrito contra la descripción que lo originó. Misma herramienta, uso preventivo en vez de forense.

**El paso 1 produce tres cosas que la descripción cruda no trae**, y las tres son material de tesis: las restricciones duras que nadie enuncia por obvias (un grupo no puede recibir dos clases a la vez), el inventario de lo inexpresable con su causa, y las incoherencias de la descripción de partida.

### 31.2 El caso: preuniversitario Saúl

Quinto dominio del proyecto, después de tesis, docentes, tv y departamento (§6). Horario semanal de un preuniversitario: 5 días, 8 turnos diarios (5 de mañana, 3 de tarde), 13 asignaturas con frecuencia semanal, y los grupos de los **tres años** resueltos a la vez. La descripción normalizada está en [`descripcion-saul.md`](../descripcion-saul.md).

**Forma del problema.** Identidad = la **sesión de clase** (una por cada frecuencia de cada asignatura en cada grupo). Slots variables = **día y turno**. El grupo, la asignatura y el profesor vienen grabados en la sesión como datos. **Es exactamente la forma de `docentes`** sin la dimensión aula.

| | entidad-horario | slot-identidad | slots-variables | Duras | Blandas |
|---|---|---|---|---|---|
| **saul** | ubicacion | sesion | dia, turno | 9 | 2 |

La oferta (frecuencia, si admite doble, si admite tarde) es por **par de año y asignatura**, no por asignatura. El día de preparación sí es por asignatura y vale para los tres años.

**Dos decisiones de alcance tomadas en el paso 1:**

- **Los tres años a la vez, asumiendo el riesgo de tamaño.** Se evaluó recortar a un año por ejecución: con tres años de cuatro grupos y unas treinta frecuencias salen ~360 filas de horario, y las restricciones de choque son cuadráticas en el número de filas (§3.4), del orden de millones de vueltas por evaluación; un año solo deja ~120 filas, el orden de `docentes`. **El usuario decidió mantener los tres años**, y la razón es del dominio: un profesor imparte a grupos de años distintos, así que separar los años rompería `colisiones-de-profesor`. Los años no son subproblemas independientes; el profesor es lo que los acopla.
  > **Es el caso límite de §3.4 llegando por una vía nueva.** Allí el argumento era «una facultad completa pasa de 65 filas a varios cientos y ahí el generador deja de ser usable **mucho antes de que el lenguaje se quede sin expresividad**». Aquí el problema no se puede partir sin perder una restricción dura, lo que convierte el límite de rendimiento en un límite **duro** del backend GA y no en una molestia. Es el mejor argumento empírico que tiene el proyecto para el backend exacto.
- **El profesor viene dado, no se decide.** Ver §31.4.

### 31.3 Los datos que faltan

En [`datos-saul.md`](../datos-saul.md). Lo no obvio de esa lista: **de cada disposición se pide el tamaño, no solo el contenido**. Cuántos grupos tiene el profesor con más grupos, si los días de los contratados son contiguos, cuántos patrones distintos hay. De esas cifras depende si la relación se puede escribir en el lenguaje o hay que resolverla antes de generar (§31.4).

El documento recoge también el **formato de salida deseado**, que es lo que el paso 3 tiene que extraer y que nunca viene en la descripción original.

### 31.4 Hallazgos del paso 1

**1. El DSL no tiene pertenencia. Es una novena limitación, del modelo de datos.** Una disposición («este profesor puede darle a estos grupos») es una relación de tamaño variable. La única forma de expresar una relación en el lenguaje es la disyunción de igualdades contra un número **fijo** de slots: el patrón `profesor-en-tribunal` de tesis, que funciona porque un tribunal tiene exactamente cinco roles (§28.2). Sin aridad fija no hay forma.

> Consecuencias prácticas: un **conjunto cerrado sobre una sola entidad** sí sale, como atributo booleano o numérico de esa entidad (qué asignaturas admiten turno doble, cuáles admiten tarde, quién vive lejos). Una **relación entre dos entidades** de tamaño variable no sale. El día de preparación sale porque es **un** día por asignatura, o sea una función, no una relación.
>
> Por eso el profesor viene dado: si lo decidiera el generador, las disposiciones serían restricciones y el problema se saldría del lenguaje. Con el profesor grabado en la sesión, las disposiciones se consumen al construir los datos y desaparecen del modelo.
>
> Esta limitación es **paralela a §28.1** (los slots no llevan tipo): las dos son del modelo de datos, no de la expresividad de las restricciones como las ocho de §3.2. Conviene registrarlas juntas como categoría aparte.

**2. Primer dominio con adyacencia sobre un slot variable.** El turno doble compara `orden(turno(s1)) + 1 = orden(turno(s2))`, y `turno` es un **slot variable**. En tv la adyacencia es `orden(e1) + 1 = orden(e2)` sobre el bloque, que es la **identidad** y por tanto dato fijo.

> **Esto toca directamente el backend ILP.** El papel `adyacente` del matcher (§27.4) mapea al conjunto `CONS` **precomputado** (§13.3, §30.4 punto 4), y precomputar solo es posible si la dimensión es dato. Con la adyacencia sobre lo decidido, `CONS` no se puede construir de antemano: hace falta una variable auxiliar que ligue dos casillas contiguas, o sea un caso nuevo del catálogo de §12. Ninguno de los cuatro dominios anteriores lo producía.
>
> Para el evaluador del GA es transparente, porque evalúa un individuo concreto y la aritmética se calcula. **La divergencia aparece solo en el backend exacto**, que es otra instancia del contraste de §24.4.

**3. Dos reglas que se sostienen mutuamente.** Las asignaturas de frecuencia cinco son exactamente las que admiten turno doble. Con día de preparación, quedan cuatro días para cinco sesiones, y solo el doble lo hace factible (2+1+1+1). Es una coherencia del dominio real que la descripción cruda no enunciaba y que el paso 1 sacó a flote.

**4. El umbral blando vuelve a aparecer.** El tope de sesiones diarias de un profesor choca con §3.2: el operando derecho del `op-mayor` se descarta en nppq. La vía prevista es la de §3.3, una entidad `jornada` con una instancia por cada par profesor-día y el tope como atributo suyo, cuantificando sobre ella. **Falta confirmar que la cuantificación admite esa forma**; si no, el respaldo es contar pares de sesiones del mismo profesor el mismo día y minimizar, que reparte pero no fija número.

**5. El horario compacto sigue sin poder expresarse.** Un preuniversitario no admite huecos en el horario del grupo. Requiere contar por grupo y por día y comparar entre días: conteo de conteos, prohibido por «un solo nivel de agregación» (§3.2). **Es exactamente la misma regla del capítulo 3 que quedó sin implementar en `docentes`.** Que reaparezca en un dominio independiente la confirma como limitación estructural y no como omisión puntual.

**6. Los horarios de reloj no entran, y no importa.** Las 8:00, los 45 minutos, los recesos y el almuerzo no son modelables (no hay aritmética sobre lo decidido) y tampoco restringen nada: solo nombran los turnos. La única regla que dependía del reloj, «educación física no después de las 10:30», se traduce limpio a «turnos uno, dos y tres». **Mismo caso que la franja de tv de §5.1**, pero con final distinto: allí el reloj sí llevaba una regla y se perdió; aquí no.

### 31.5 Lo que queda

Recibir los datos de [`datos-saul.md`](../datos-saul.md) y ejecutar los pasos 2 y 3. Después de eso, decidir si el dominio entra en `verbalizador/dominios/` como quinto ejemplo y si `limitaciones-del-dsl.md` se amplía con la novena limitación de §31.4 punto 1.


---

# PARTE VII — LA REIMPLEMENTACIÓN POR CAPAS

> **ESTADO: etapa 0 completada el 2026-11-02; etapas 1 a 5 pendientes.** El progreso detallado, archivo por archivo, se registra en [`plan-reimplementacion.md`](plan-reimplementacion.md), en la sección «Progreso» de cada etapa. Esta parte da el contexto y lo que no cabe en el plan: por qué se hace, qué se decidió y qué corrige del análisis anterior.

## 32. Qué es y por qué

El proyecto se rehace en una carpeta nueva, **`C:\Pro\tesis\problemas_de_asignacion\`**, que pasa a ser la carpeta principal de la tesis y se versiona en el repositorio de la raíz. Allí se migra lo que existe en `restrictions_language-main/` y en `verbalizador/`, con las deficiencias del generador corregidas.

**El objetivo**, tal como lo fijó el usuario: rehacer toda la generación de código sobre **funciones genéricas** de CLOS y una **jerarquía de clases de destinos**, es decir, de lenguajes de exportación y de estrategias de resolución. Lo esencial es la modularidad. Añadir un lenguaje o una heurística tiene que ser añadir clases y métodos, sin tocar lo existente, y no puede quedar nada cableado para que funcionen los dominios ya tratados, ni parches.

**La consecuencia que más se busca:** el verbalizador deja de ser un proyecto aparte que copia código y dominios, y pasa a ser un destino más sobre la misma entrada.

**Por qué ahora.** El análisis encontró que los errores más graves no están en el lenguaje sino en el generador, y que muchos son de una clase peligrosa: **no fallan, mienten** (devuelven un número creíble). La causa estructural es la falta de una capa de análisis compartida y de un despacho por destino. Arreglarlos uno a uno sobre el código actual sería parchear; por eso se rehace.

### Documentos de esta línea de trabajo

| Documento | Para qué es |
|---|---|
| [`deficiencias-por-capa.md`](deficiencias-por-capa.md) | **El inventario de lo que se quiere arreglar**: 30 deficiencias, numeradas por capa (1.1 a 5.1), con su gravedad y lo que exige a la reimplementación. Es la fuente de verdad del alcance. |
| [`plan-reimplementacion.md`](plan-reimplementacion.md) | **El plan de trabajo**: estructura de carpetas, una etapa por capa, de dónde se toma cada pieza (archivo y línea), tareas, decisiones con opciones y recomendación, criterios de completado y el progreso de cada etapa. |
| [`mga-y-problemas-pendientes.md`](mga-y-problemas-pendientes.md) | Qué aporta MGA y qué no, explicado para quien no conoce el proyecto. |
| `informe-deficiencias.pdf` / `.tex` | El primer análisis, de 16 páginas. **Tiene un error**: recomienda devolver `:accessor` a `def-clase` (§37, punto 1). |
| [`problemas_de_asignacion/README.md`](problemas_de_asignacion/README.md) | Portada de la carpeta nueva: mapa de capas, cómo correr las pruebas, cómo cargar un dominio y cómo regenerar la referencia. |
| [`problemas_de_asignacion/estructura.md`](problemas_de_asignacion/estructura.md) | **Dónde está cada lógica** y qué hace cada archivo de la carpeta nueva. |
| [`problemas_de_asignacion/decisiones-reimplementacion.md`](problemas_de_asignacion/decisiones-reimplementacion.md) | Cada decisión tomada, con su motivo, agrupadas por tema, y lo pendiente a implementar. |
| [`problemas_de_asignacion/plan-etapa-2.md`](problemas_de_asignacion/plan-etapa-2.md) | Cómo se construyó el análisis: fases, lo esperado de cada restricción y las tablas de rechazos, avisos y consultas genéricas. |
| [`problemas_de_asignacion/plan-etapa-3.md`](problemas_de_asignacion/plan-etapa-3.md) | Cómo se construyó la emisión: fases, valor de cada restricción y destino de cada función del verbalizador. |

## 33. Las cinco capas

| Capa | Carpeta | Qué hace | MGA |
|---|---|---|---|
| 1. Construcción del DSL | `src/dsl/` | macros `def-*`, clases del AST, entidades, instancias, definición del problema | no se adopta `defnode` |
| 2. Análisis | `src/analisis/` | el modelo intermedio que leen todos los backends: forma de cada restricción, familias, dominios, orden | — |
| 3. Emisión | `src/emision/` | un destino por lenguaje: Python, LaTeX y prosa en español; más adelante ILP | sin implementar: etapa extra |
| 4. Estrategias | `src/estrategias/` | cómo se busca la solución: representación, operadores, evaluación, parada | — |
| 5. Orquestación | `src/orquestacion/` | qué se genera, en qué orden y dónde | — |

**La capa 2 no existía en el sistema viejo.** Su trabajo estaba repartido entre los emisores y duplicado en el verbalizador, y esa ausencia causaba buena parte de las deficiencias.

**La capa 1 ya está construida.** Lo que la distingue del sistema viejo:

- **Paquetes:** `dsl` solo tiene las 27 palabras que ve un dominio, y `dsl-ast` tiene la implementación. Cada dominio se carga en su paquete con registros nuevos, así que no ve los de otro.
- **Dureza y peso:** la dureza sale de la jerarquía de clases del cuantificador. Solo las blandas y los objetivos llevan `:peso`.
- **Consultas:** `def-consulta` crea su nodo y una función. Llamarla devuelve un nodo `aplicacion-de-consulta`, incluso sin parámetros: `(colisiones-de-aula)`.
- **Restricciones:** los cuantificadores son macros con nombre, `(def-nppq r cond)`, y `:para` liga sus variables sobre uno o varios dominios.
- **Accesores:** solo los generan las entidades. `def-clase` ya no genera funciones de acceso, y los nodos se leen con `slot-value`.
- **Errores:** toda entrada mal formada señala `error-dsl`, con un mensaje que nombra el objeto.

**La capa 2 ya está construida.** `construir-modelo` convierte un `problema` en un modelo inmutable, sin estado global:

- **Dos ejes:** cada restricción tiene una forma (`prohibicion`, `cota`, `minimax`, `restriccion-generica`) y cada consulta una familia (`choque-por-parejas`, `relacion-ordenada`, `filtro-de-fila`, `cruce-contra-tabla`, `agrupacion`, `consulta-generica`).
- **Una comparación guarda dos cosas:** lo escrito, para la prosa, y cuándo se incumple, para el cálculo.
- **Decisión o dato:** una ruta es decisión si su raíz recorre la combinación y el slot más cercano a la raíz es una variable del problema.
- **Tipos deducidos:** el tipo de un slot sale de las instancias, y el dominio de un parámetro, de cómo se aplica la consulta. Las comparaciones sin sentido se rechazan.
- **Avisos:** una lista en el modelo, con cuatro motivos: `:simetrica-sin-pares`, `:pares-con-orden`, `:restriccion-constante` y `:variable-sin-usar`.

**La capa 3 ya está construida.** De un mismo modelo salen `modelo.py`, `modelo.tex` y `descripcion.md`:

- **Sin métodos por defecto:** cada destino es una clase, y `generar-codigo` no tiene ningún método sobre `t`. Un nodo sin traducir es un error, no un `?`.
- **Python:** compara por identidad (`eq=False`). Un choque se cuenta por celda en tiempo lineal cuando eso es exacto, y si no, con bucles. `evaluar` devuelve valores sin ponderar.
- **LaTeX:** las duras van como «sujeto a», y el objetivo solo suma las blandas con su peso. La penalización de las duras es de la estrategia.
- **Verbalizador:** se trasladó sin cambiar su lógica, a `src/emision/verbalizador/`. Sus reconocedores ya estaban en el análisis.

**Cuánto vale cada restricción:** una prohibición, su conteo; una cota, lo que falta para cumplirla, sumado sobre `:para`; un minimax, su máximo; un maximizar, menos su mínimo; una genérica, 1 por cada combinación que incumple. Un choque cuenta cada pareja una vez.

### Relación con MGA

- **De la mitad `defnode` no se importa nada.** `def-clase` ya tiene `:funcion`, `:claves` y `:encadenado`, y además `def-nodos`, `def-jerarquias` y `def-subclases`, que MGA no tiene. Sustituirla rompería el DSL: el nombre de cada slot es un constructor de nodos (`(tope jornada)` construye un nodo de acceso), y `defnode` le daría ese nombre a un accesor.
- **`gcode` no se ha implementado.** Se decidió dejarlo, junto con la sangría de MGA, para una etapa extra al final del plan: los métodos se escriben con `defmethod`, y nada del sistema depende de MGA. El prototipo, probado sobre el AST real, sigue en el apéndice A del plan, y lee los huecos con `slot-value` en lugar de con accesores.
- **Nombres en español** (D0.4): `generar-codigo` se parece a `generate-code` de MGA, pero es una función genérica normal.
- **El límite de MGA, medido:** `gcode` solo cubre la traducción composicional. En el verbalizador eso son 258 líneas (`expr.lisp`) frente a 604 de reconocimiento de familias (`idioms.lisp`): el 70 % del trabajo real queda fuera. En la arquitectura nueva, ese reconocimiento pasa a la capa 2 y lo comparten todos los destinos.

## 34. Principios

Valen para todas las etapas y son la forma práctica de «nada cableado»:

1. Cada capa depende solo de las anteriores.
2. Lo que varía por destino, por estrategia o por familia de restricción se resuelve con despacho de CLOS, nunca con `case`, `typecase` ni `if` sobre un nombre.
3. Ningún método por defecto sobre `t`: lo que no está implementado es un error al generar, no un `?` en la salida.
4. Ningún símbolo, texto o convención de un dominio concreto dentro de `src/`.
5. La entrada mal formada se rechaza al construir el AST, con su nombre.
6. Todo es reproducible: misma entrada y misma semilla, misma salida.
7. Sin dependencias nuevas. ASDF viene con SBCL. Las pruebas son funciones con `assert`.

## 35. Decisiones tomadas

### De dirección, tomadas al construir el inventario

- **Fuera del alcance:** los problemas de calidad de datos, como la errata `Francofonia`/`Francofomia`.
- **Fuera del inventario**, por no afectar a ningún dominio trabajado o por no producir errores: la expresividad que ningún dominio usa (restricciones globales, decisiones derivadas, agregación anidada, decisión opcional), los slots sin tipo, las consultas auxiliares que se inlinean, el estado global acumulativo y la identidad de entidades por convención de nombre.
- **Fusionados**, por decir lo mismo: los datos de pares y el cuantificador de un solo dominio (1.4); los cableados de la emisión (3.7); lo que resuelve la jerarquía de destinos (3.3); los errores de la fórmula matemática (3.4); y toda la orquestación en un solo punto (5.1).
- **Las deficiencias solo llevan gravedad**, sin etiquetas de «nuevo», «parche» o «ejecutado».

### De la etapa 0

| ID | Decisión |
|---|---|
| D0.1 | La carpeta se llama `problemas_de_asignacion/`. |
| D0.2 | `restrictions_language-main/` queda en local, sin versionar, y **no se modifica**. Todo lo que se necesita de él se lee o se copia. |
| D0.3 | Los documentos de la tesis (`doc/`, bases de conocimiento) los coloca el usuario a mano en la carpeta nueva; el plan no los mueve. |
| D0.4 | Variables, funciones y carpetas en español. Lo que viene del verbalizador en inglés se traduce al migrarlo. |
| D0.5 | Archivos en UTF-8 sin BOM. Los comentarios dañados de `clases-macros.lisp` (`Ã¡` en lugar de `á`) se reescriben al migrarlo. |
| D0.6 | **Docentes y Saúl no se ejecutan** para la referencia: de ellos solo se copian los artefactos. |

### De la etapa 1 (las demás siguen abiertas en el plan)

| ID | Decisión |
|---|---|
| D1.1 | La dureza sale del cuantificador. |
| D1.2 | Las duras no llevan número en el dominio: su penalización es de la estrategia. El peso de las blandas sí define el problema y se queda en el DSL. |
| D1.3 | Las parejas no ordenadas se declaran con `:pares`, compatible con `:itera-sobre`. |
| D1.4 | Se escribe `:operacion (contar-distintos (dia c))`, con el atributo obligatorio. |
| D1.5 | Se cuantifica sobre varios dominios desde ahora, con variables explícitas: `:para (p profesor) (d dia)`. `jornada` se elimina en un paso aparte, y su eliminación cambia tres líneas de la prosa de Saúl. |
| D1.7 | `frecuencia-exacta` de docentes se deja fuera, porque su conteo lo fijan los datos (§37, punto 11). |
| D1.6 | Se borran los cinco nodos sin semántica: `comb-entidades`, `lista`, `acceso-a-elemento-de-comb`, `hay-elementos-duplicados` y `pertenece`. |
| D1.8 | El problema se define con la macro `def-problema` y las claves `:combinacion`, `:identidad`, `:variables` y `:restricciones`. |
| D1.9 | El dominio departamento no se implementa. |
| D1.10 | Las anotaciones de un destino van en un archivo por destino, como `verbalizador.lisp`. |
| D1.11 | Las condiciones reutilizables se escriben con `def-condicion`. `def-consulta` siempre exige iteración. |
| D1.12 | `:peso` se escribe por clave, con valor 1 por defecto. |
| D1.13 | `(suma e)` y `(contar-distintos e)`, sin `:devuelve`. Contar se escribe `(suma 1)`. |
| D1.14 | El cargador crea el paquete de cada dominio. |
| D1.15 | Una consulta sin parámetros se usa como llamada: `(op-mayor (colisiones-de-aula) 0)`. |
| D1.16 | Una restricción recibe su nombre en su macro: `(def-nppq r …)`, sin `defvar`. |
| D1.17 | Los datos de pares se aceptan por ahora como entidades (`plan`, `ausencia`, `indisponibilidad`). 1.4 queda resuelto solo en su parte de cuantificación, y la sintaxis de datos de pares queda pendiente a implementar. |
| D1.18 | `descripcion.md` y `datos.md` no se crean por dominio; se quedan donde están y los coloca el usuario si los necesita. |

### De la etapa 2

| ID | Decisión |
|---|---|
| D2.1 | La familia se representa con dos jerarquías de clases: la forma de la restricción y la familia de la consulta. |
| D2.2 | Lo que no encaja va a una familia `generica` explícita; un destino que no pueda emitirla da error. |
| D2.3 | Todo se calcula al construir el modelo, que queda inmutable. |
| D2.4 | El tipo de un slot se deduce de las instancias. |
| D2.5 | El análisis rechaza los caminos y las comparaciones sin sentido. |
| D2.6 | La simetría se detecta intercambiando las dos filas después de aplicar las igualdades de la propia condición. |
| D2.7 | Los avisos son una lista dentro del modelo. |
| D2.8 | De una comparación se guardan lo escrito y cuándo se incumple. |
| D2.9 | El modelo reutiliza los nodos del AST y solo envuelve las consultas. |
| D2.10 | Los pares simétricos y los ordenados son dos subclases de un padre común. |
| D2.11 | Se avisa de una restricción que no depende de ninguna decisión, y cada restricción guarda las decisiones que toca. |
| D2.12 | Un ciclo entre entidades es un error. |
| D2.13 | Un slot con `nil` o con valores de dos tipos se rechaza. |
| D2.14 | Una variable declarada sin usar da un aviso, no un error. |

Las decisiones de diseño de las etapas 1 y 2 están con su motivo en `problemas_de_asignacion/decisiones-reimplementacion.md`.

### De la etapa 3

| ID | Decisión |
|---|---|
| D3.1 | Un choque cuenta cada pareja una vez: k(k−1)/2 si todas chocan. El valor nuevo es la mitad exacta del viejo. |
| D3.2 | Un `modelo.py` y un archivo por estrategia que lo importa. |
| D3.3 | Una instancia se nombra por su único slot de texto; si no lo hay, o hay varios, por todos sus slots. |
| D3.4 | La salida matemática es solo LaTeX. |
| D3.5 | El ILP va en una etapa propia, después de la 5. |
| D3.6 | La sangría es un slot de nivel y la macro `con-sangria`. |
| D3.7 | Incumplir una cota vale lo que falta para cumplirla: `\|q − umbral\|`, más 1 si la condición de incumplimiento incluye la igualdad. |
| D3.8 | Se capturan los valores de docentes y Saúl sin ejecutar el genético. Revisa D0.6. |
| D3.9 | Saúl pierde `numero`. |
| D3.10 | `contar-distintos` se nombra en prosa por su slot: «fechas distintas». |
| D3.11 | El tope se escribe «de cada profesor y cada día». |
| D3.12 | Lo que la prosa sabe del idioma está en `src/`, y lo propio de un dominio en `dominios/<d>/verbalizador.lisp`. |
| D3.13 a D3.19 | El modelo matemático es completo, con funciones y no binarias, duras como «sujeto a», blandas con requisito y costo, conjuntos por su nombre, consultas nodo por nodo y un fragmento para `\input`. |
| D3.20 | Lo que quedaba en inglés se tradujo en una fase final: `op-y`, `op-o`, `op-no`, `def-mixin`, `parametros`, `prosa`. |

Además: el verbalizador se traslada sin cambiar su lógica, y un error real se informa al autor; la prosa no tiene que ser idéntica a la referencia; la carpeta, la clase y las anotaciones se llaman `verbalizador`; y MGA queda para una etapa extra.

### De la etapa 4

| ID | Decisión |
|---|---|
| D4.1 | El ILP no entra en esta etapa. |
| D4.2 | Se implementan el genético y la búsqueda local. |
| D4.3 | Las tres vías de arranque se generan y se elige con `--inicio`, voraz por defecto. |
| D4.4 | Duras y blandas se combinan con suma ponderada y penalización 1000. |
| D4.5 | La mutación mueve de 1 a k filas, con k = 2 por defecto, e intercambia. |
| D4.6 | Los valores prohibidos se quitan solo al arrancar. Quitarlos también al mutar no dio una mejora clara. |
| D4.7 | Una corrida se detiene sin duras ni blandas, en el máximo de generaciones o por tiempo. **Revisada el 2026-11-08:** el genético ya no se detiene tras 100 generaciones sin mejora, porque en Saúl seguía mejorando. La búsqueda local conserva el estancamiento. |
| D4.8 | Cada operador es una clase Lisp con un método que escribe su Python. |
| D4.9 | Valores por defecto en la clase y argumentos al ejecutar. `ejecuciones/` lleva un Markdown que explica cada parámetro. |
| D4.10 | Solo se dejan de recalcular las restricciones constantes. Agrupar relaciones y la evaluación incremental quedan como trabajo extra. |
| D4.11 | SEDER: 18 de 20 semillas en 0 duras. Saúl: no más de 17 duras y como mucho 1 evaluación por individuo. Al terminar se calcula el costo en minutos de una corrida más grande. |

Al implementar se decidió además:
- **Cada argumento es de la pieza que lo usa:** el tamaño del torneo, del torneo; el radio, de `mover-filas`; el ruido, del paso de la búsqueda local; el estancamiento y el tiempo, de la parada.
- **`modelo.py` da listas de nombres:** `PROHIBICIONES`, `DE_UNA_FILA` y `CONSTANTES`, calculadas de la forma, la familia y las decisiones, nunca por el nombre de una restricción.
- **Solo cuenta como evaluación un horario completo.** Las comprobaciones del voraz no.
- **La búsqueda local prueba solo las opciones permitidas de la fila,** incluye la actual entre los candidatos y devuelve el mejor visto.

### De la etapa 5 (falta D5.5)

| ID | Decisión |
|---|---|
| D5.1 | Todos los dominios en la misma imagen: el aislamiento ya lo dan el paquete propio y los registros nuevos de cada carga. |
| D5.2 | `verbalizador/` se deja como está; se encarga el usuario. |
| D5.4 | Una ejecución se pide por línea de comandos o con un archivo de `ejecuciones/`. |
| D5.6 | La salida va en una carpeta por destino, y las estrategias con `modelo.py`. |
| D5.7 | Destinos y estrategias se eligen por el nombre de su clase. |
| D5.8 | Los avisos del análisis se imprimen y se guardan. |
| D5.9 | La orquestación ejecuta la búsqueda solo si se pide. |
| D5.3 | No hay banco de comparación; `rendimiento.py` queda como está. |
| D5.10–D5.12 | Un archivo de `ejecuciones/` es una lista de Lisp leída sin evaluar, con un dominio, y no se mezcla con la línea de comandos. |
| D5.13 | Si no se nombra nada, se genera todo. |
| D5.14 | Las semillas se ejecutan una tras otra. |
| D5.15 | Al regenerar se sobrescribe lo generado sin borrar la carpeta. |
| D5.16 | Si un dominio falla, se informa y se sigue. |
| D5.17 | Los cuatro puntos del verbalizador se revisan al terminar la etapa 5. |

### Trabajo extra

Al final del plan, después de la etapa 5, en `plan-reimplementacion.md`:
- **Etapa 6 extra, mejorar la búsqueda y la evaluación del genético:**
  - comprobar la capacidad de Saúl;
  - agrupar las relaciones ordenadas y la evaluación incremental (D4.10 B y C);
  - un operador que intercambie dos sesiones del mismo grupo;
  - encadenar el genético con la búsqueda local;
  - medir el efecto de D3.7.
- **Trabajo extra:** MGA, el ILP y los pendientes anotados.

## 36. Estado por etapa

| Etapa | Capa | Estado |
|---|---|---|
| 0 | preparación y referencia | **completada** el 2026-11-02 |
| 1 | DSL | **completada** el 2026-11-05 |
| 2 | análisis | **completada** el 2026-11-06 |
| 3 | emisión | **completada** el 2026-11-06 |
| 4 | estrategias | **completada** el 2026-11-07; el 2026-11-08 se quitó el estancamiento del genético |
| 5 | orquestación | pendiente |

**Qué dejó la etapa 0**, en `problemas_de_asignacion/pruebas/`:

- **La referencia del sistema viejo** en `referencia/<dominio>/`:
  - de los cinco dominios: `dominio.lisp`, `horario.py` y la prosa del verbalizador, copiados;
  - de tesis, tv y SEDER: además el modelo matemático (`modelo.txt`) y diez horarios con semilla fija, con el valor de cada restricción en cada uno (`valores.json`).

  La captura es determinista, y cada horario se reconstruye exacto desde sus índices.
- **Un horario factible** de tesis, tv y SEDER en `factibles/`, encontrado con una búsqueda local genérica y comprobado con las funciones viejas.
- **`diferencias-esperadas.md`**: lo que la reimplementación cambia a propósito. Cualquier otra diferencia es un error de la migración.

**Requisito que deja a las etapas siguientes:** el sistema nuevo tiene que conservar el **orden de las instancias** de cada entidad, porque los horarios de referencia están guardados como posiciones dentro de esas listas.

**Qué dejó la etapa 1**, en `problemas_de_asignacion/`:

- **El lenguaje** en `src/dsl/` y el cargador mínimo en `src/orquestacion/cargar.lisp`.
- **Los cinco dominios** en `dominios/<dominio>/dominio.lisp`, sin envoltura, con `:pares`, `:para` y las operaciones nuevas. Saúl ya no tiene `jornada`.
- **Las pruebas** en `pruebas/`: `sbcl --script pruebas/correr.lisp` comprueba los rechazos y compara cada dominio con su referencia.
- **Sin commits:** todo queda en el árbol de trabajo; el usuario decide cuándo versionar.

La migración conserva la forma de cada dominio, pero **sus valores todavía no se han comparado**, porque el sistema aún no genera salida. Eso se hace en la etapa 3. Sobre los comentarios: se quitaron de los dominios los que citaban al generador viejo; `pruebas/dsl/migracion.lisp` sí lo nombra, porque su trabajo es comparar con él.

**Pendiente a implementar:** la sintaxis de datos de pares (1.4). Por ahora `plan`, `ausencia` e `indisponibilidad` siguen siendo entidades (D1.17, §37, punto 13).

**Qué dejó la etapa 2**, en `problemas_de_asignacion/`:

- **El modelo intermedio** en `src/analisis/`, con `construir-modelo` como entrada.
- **Las pruebas** en `pruebas/analisis/`, con la forma, la consulta, la familia y las decisiones esperadas de las 26 restricciones.
- **Lo que se comprobó contra la referencia:** las consultas derivadas son las listas `:consultas` viejas, y el orden de las entidades es el de la prosa.
- **Sin commits**, y sin cambios en los dominios ni en `src/dsl/`.

El modelo **todavía no se ha evaluado**: la comparación de valores y de prosa es de la etapa 3. Nadie llama aún al análisis al cargar un dominio ni muestra los avisos: eso es de la etapa 5.

**Qué dejó la etapa 3**, en `problemas_de_asignacion/`:

- **Los tres destinos** en `src/emision/`, `exportar` en `src/orquestacion/` y `generar.lisp`, que escribe la salida en `salida/<dominio>/` con `sbcl --script generar.lisp`.
- **Las pruebas** en `pruebas/emision/`, que ejecutan el Python generado y compilan el LaTeX si hay `pdflatex`.
- **Lo que se comprobó contra la referencia:** 260 valores sobre 50 horarios, y la prosa, que solo difiere en las 6 líneas previstas.
- **Referencia nueva:** `valores.json` y `modelo.txt` de docentes y Saúl.
- **Sin commits**, y sin cambios en las copias de la referencia.

**Medido después:** contar parejas ayuda al genético. Sigue sin medir el efecto del exceso de las cotas.

**Qué dejó la etapa 4**, en `problemas_de_asignacion/`:

- **Las estrategias** en `src/estrategias/`: el genético y la búsqueda local, cada una un objeto con sus operadores, que escribe un programa de Python. `generar.lisp` deja en `salida/<dominio>/` `genetico.py` y `busqueda_local.py`, que se ejecutan con `python genetico.py --semilla 0` y guardan cada corrida en `corridas/`.
- **`modelo.py` cuenta lo que las estrategias necesitan:** la identidad, los dominios de decisión, `crear_fila` y tres listas de restricciones. Las estrategias no saben nada del dominio.
- **`ejecuciones/README.md`:** qué es cada argumento, su valor por defecto y ejemplos.
- **Las pruebas** en `pruebas/estrategias/`, y `rendimiento.py` aparte, que tarda unos 15 minutos.
- **Resultados, sin estancamiento:** SEDER en 0 duras en 20 de 20 semillas, con cualquier arranque; Saúl en 14, 10 y 14 con el genético, en 4,6 min, y en 6 con la búsqueda local en 120 s; 0,87 evaluaciones por individuo. La prueba de mutación detectó los 72 cambios.
- **Cuánto cuesta más:** Saúl tarda 4,6 min con 500 generaciones y población 100 y 17,9 con 2 000, medidos; 85 min con 10 000 y 433 con 10 000 y población 500, proyectados. Con 5 veces más filas, 500 generaciones costarían unos 55 min. Las tablas están en `plan-etapa-4.md`.
- **Revisado el 2026-11-08:** el estancamiento de 100 generaciones cortaba mejoras reales en Saúl, de 17 a 14 duras, y se quitó del genético. Las mejoras de la búsqueda que quedaron fuera forman la etapa 6 extra.
- **Sin commits.**

## 37. Lo que esta línea de trabajo corrigió del análisis anterior

Afirmaciones de este documento, de `base_de_conocimiento.md` o del primer informe que resultaron falsas o incompletas. **Prevalece lo que dice esta sección.**

1. **El `typecase` no era la única salida, y no hay que devolver `:accessor` a `def-clase`.** CLOS despacha por la clase del nodo, no por sus accesores, así que los métodos funcionan leyendo con `slot-value`. Añadir `:accessor` no serviría: el `defun` que genera `def-clase` lo pisa sin avisar. `informe-deficiencias.pdf` dice lo contrario y está equivocado en ese punto.
2. **La comparación por valor no es una limitación del lenguaje, es una decisión del emisor** (corrige `base_de_conocimiento.md` §7). El serializador escribe cada referencia como un objeto nuevo (`Sesion(plan=Plan(grupo=Grupo(...)))`), y las clases se emiten como `@dataclass(unsafe_hash=True)`. En el Python generado no hay identidad compartida, y la igualdad por valor es lo único que hace funcionar las comparaciones. Los campos añadidos para distinguir instancias son parches.
3. **Cuantificar sobre la identidad no genera Python roto: devuelve 0 en silencio** (corrige `base_de_conocimiento.md` §19). La clase `Horario` declara el campo, pero nadie lo llena. Comprobado: una restricción imposible da 0 incumplimientos.
4. **Saúl tenía dos restricciones blandas escritas como duras.** `restriccion-evitar-primer-turno-a-los-lejanos` y `restriccion-tope-diario-de-profesor` estaban en la lista de blandas, pero escritas con `def-nppq` y `def-tqpq`. Se cambiaron a `def-ndpq` y `def-sbqp` en las tres copias del dominio. El costo no cambia y la prosa queda idéntica. Al corregirlo apareció otro error: el emisor matemático no niega los `ndpq`, así que R10 se imprime como la condición prohibida.
5. **Respetar el umbral del nppq no basta para que desaparezca `jornada`** (corrige `base_de_conocimiento.md` §13). El tope es por profesor **y** día, así que hace falta además cuantificar sobre dos dominios (D1.5).
6. **Saúl también cuenta doble los choques**, en tres consultas. Son diez consultas en total: dos de tesis, tres de docentes, tres de Saúl y dos del SEDER.
7. **El traductor matemático no conoce las referencias a entidad.** `(tope jornada)` sale como `tope(?)`, y le pasa lo mismo a `frecuencia`. Reproducido con SBCL y visible en el modelo real de Saúl.
8. **El DSL acepta entradas mal formadas sin quejarse.** Comprobado: con `:comprueva` en vez de `:comprueba`, la consulta pierde su condición y cuenta todas las filas; con un argumento de menos, el slot sale `None`; y una consulta que no se lista en `:consultas` produce `consulta_desconocida(horario)`, que falla al ejecutar.
9. **Los dominios actuales no usan umbrales distintos de 0 ni sumas distintas de 1.** Corregir el umbral y la suma no cambia ningún valor de la referencia.
10. **Una búsqueda local simple resuelve el SEDER en 12 segundos**, y el genético viejo no lo resuelve nunca. Confirma que el atasco es de la vecindad del operador de mutación, no del problema.
11. **`frecuencia-exacta` no restringe ninguna decisión** (corrige §4 y la recomendación inicial de D1.5). Tal como está escrita en docentes da 10 incumplimientos en cualquier horario: cada asignatura se imparte a cinco grupos, así que su conteo es cinco veces su frecuencia. Cuantificada por asignatura y grupo daría siempre 0, porque cada sesión es una identidad con una sola fila. La R9 de Saúl (`sesiones-del-plan`) tiene el mismo carácter.
12. **Docentes tiene 70 sesiones, no 65** (corrige §3.4, §4 y §15.6). Sus variables binarias conjuntas son 70·6·5·6 = 12 600, no unas 11 700.
13. **La sintaxis de datos de pares no cambia la búsqueda del genético.** Los datos no son genes, así que los candidatos y sus costos son los mismos. Medido en el genético viejo, cambiando el bucle sobre la entidad por una búsqueda directa, con la misma semilla: SEDER (población 20, 15 generaciones) y Saúl (población 6, 2 generaciones) dan el mismo costo y el mismo horario. El tiempo apenas cambia: esa restricción es el 5,8 % de una evaluación en el SEDER y el 0,1 % en Saúl. Lo caro son los choques: `restriccion_una_sesion_por_profesor` es el 78 % en Saúl y `restriccion_un_profesor_por_turno` el 80 % en el SEDER. El valor del 1.4 es de expresividad.
14. **Sacar los valores prohibidos del dominio de cada identidad sí puede ayudar a buscar, y no necesita sintaxis nueva.** En el SEDER, leyéndolos de `indisponibilidad`, con población 30 y 60 generaciones, las duras incumplidas por semilla pasan de 3, 3, 2, 1, 3 a 0, 0, 1, 1, 0, en el mismo tiempo. Son 5 semillas en un solo dominio: es un indicio, no un resultado.
15. **`decision-path-p` del verbalizador no mira la raíz.** Solo mira el nombre del slot, así que `(dia a)` sobre `ausencia` contaría como decisión. No cambia la prosa actual, porque solo se usa con parejas de filas del horario. La capa 2 exige que la raíz recorra la combinación.
16. **La simetría no se puede comparar como texto** (corrige el plan inicial de la etapa 2). `repeticiones-en-el-dia` filtra `admite-doble` solo en `u1`, y aun así es simétrica, porque otra igualdad dice que las dos filas tienen el mismo plan. Comparando el texto, el aviso saltaría por error en Saúl.
17. **Una sola lista de familias mezclaba dos ejes** (corrige el plan inicial de la etapa 2). `minimax` es una forma de restricción, y `agrupacion` es una familia de consulta: el objetivo de tv es un minimax sobre un par ordenado. Medido: 19 prohibiciones, 5 minimax y 2 cotas; 10 choques, 6 agrupaciones, 5 filtros, 3 relaciones ordenadas y 2 cruces.
18. **`restriccion-frecuencia-exacta` de Saúl tampoco restringe ninguna decisión**, igual que la de docentes (punto 11). Los 102 planes siempre cumplen y gasta 102 × 297 = 30 294 comparaciones por evaluación. Se conserva por fidelidad con la descripción, y el análisis avisa.
19. **Un ciclo entre entidades casi no se puede crear.** Cada instancia necesita que la otra ya exista, así que la primera tendría que tener `nil` en ese slot, y eso ya se rechaza. Solo se llega rellenando el slot con `setf` después de crear la instancia.
20. **En docentes, dos clases del mismo grupo en la misma aula, día y turno no incumplen nada.** Cada una de las tres condiciones exige algo distinto. Es la forma descrita en §12, «packing con presencia», y por eso el exceso k−1 de D3.1 no es exacto en esas consultas. Sale de leer las condiciones; no se ha ejecutado.
21. **Contar parejas es mejor que contar el exceso** (corrige la recomendación inicial de D3.1). `(suma 1)` y la prosa dicen pares, y en los cinco dominios los 10 choques son duros, así que para un ILP basta que sean cero. El valor nuevo es la mitad exacta del viejo en todo horario, lo que da una comprobación fuerte.
22. **Evaluar docentes y Saúl no era caro** (corrige D0.6). Una evaluación cuesta 0,01 s y 1 s con el sistema viejo; lo caro era buscar. Por eso sus valores sí se capturaron.
23. **No todas las instancias iguales tienen un campo que las distinga** (corrige `diferencias-esperadas.md`). Docentes tiene 20 sesiones iguales campo a campo, aunque ninguna consulta las compara directamente.
24. **`defclass*` no viene de MGA**, sino del DSL viejo. Por eso también se tradujo: es `def-mixin`.
25. **El genético viejo sí resuelve a veces el SEDER** (corrige el punto 10). Llegó a 0 duras en 2 de 3 semillas con 100 generaciones. El atasco ocurre en algunas corridas, y contar doble era buena parte del problema: con parejas, 15 de 20 semillas en una mediana de 29 generaciones, frente a 12 de 20 en 259. Mover dos filas sube a 18 de 20.
26. **El arranque pesa más que la mutación.** En Saúl, tras 90 s, 207–223 duras al azar y 148–159 con valores permitidos, frente a 11–17 de un arranque voraz en unos 30 s. Ningún método ha llegado a 0, y no se sabe si Saúl tiene solución. Lo mejor medido son 6 duras.
27. **Quitar valores prohibidos al mutar era especulación.** Medido, no da una mejora clara: 111,5 frente a 118,7 duras con rangos solapados, y 14,2 frente a 13,8 con arranque voraz.
28. **`copy.deepcopy` es incompatible con la comparación por identidad.** Copia también las instancias, y dos «lunes» dejan de ser iguales. Un individuo se guarda como posiciones.
29. **En Saúl, la búsqueda local es mucho mejor que el genético.** Con 120 s llega a 6 duras en las tres semillas, frente a 11–17 del genético. Es lo mismo que lo mejor medido con el prototipo. Que tres semillas den exactamente 6 sugiere un mínimo difícil de cruzar con pasos de una fila, pero no prueba que no haya solución.
30. **El estancamiento de 100 generaciones cortaba mejoras reales en Saúl** (contradecía el criterio «sin cortar el progreso» del plan). Sin él, 500 generaciones bajan de 17 a 14 duras. En tesis y docentes no se perdía nada, y en el SEDER, una blanda en una semilla. Por eso se quitó del genético: 100 generaciones sin mejora no eran un estancamiento real.
31. **El SEDER lo resuelve el voraz solo.** Para ver lo que aporta el genético hay que arrancar al azar, como el viejo: entonces llega a 0 en 19 de 20 semillas, frente a 2 de 3.
32. **El voraz de Saúl tarda 14 s,** no los 30 del prototipo.
33. **El costo de evaluar crece más que las filas:** 7,2 ms con 297, 20,2 con el doble y 96,3 con cinco veces más. Lo causa `turno_doble_consecutivo`, que compara todas las parejas. Es lo que ataca la opción B de D4.10.
34. **Las opciones permitidas son lo que hace barata la búsqueda local.** Docentes no tiene ninguna restricción de una fila, así que cada paso prueba todas las opciones de aula, día y turno, y la corrida tarda 137 s, frente a 6 s en el SEDER.
35. **Una prueba de mutación encuentra pruebas que faltan.** De 67 cambios, solo sobrevivieron dos en la primera pasada, y los dos señalaban algo sin probar: que el programa arranque con las opciones permitidas y que los valores por defecto sean los del plan.
36. **En Saúl, con el mismo tiempo, más población rinde más que más generaciones.** En 9,1 min, población 200 con 500 generaciones da 11 duras, y población 50 con 2 000 da 14. Población 100 con 2 000 y población 500 con 500 dan las dos 11. Es una semilla.
