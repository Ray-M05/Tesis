# Verbalizador: del DSL al lenguaje natural

## Objetivo

Añadir un **traductor sobre el mismo AST, que emita prosa española**.
De una descripción en el DSL, producir el documento que describe el problema en lenguaje natural.

---

## Ejemplo

**Entrada** (fragmento de un dominio de programación televisiva):

```lisp
(def-entidad bloque   ()             (dia orden))
(def-entidad programa (tiene-nombre) (tipo duracion canal))
(def-comb    emision  (bloque programa))

(def-consulta adyacentes-mismo-tipo ()
  :itera-sobre (c canal) (e1 emision) (e2 emision)
  :comprueba
  (op-and (op-igual (canal (programa e1)) c)
          (op-igual (canal (programa e2)) c)
          (op-igual (dia   (bloque e1))   (dia   (bloque e2)))
          (op-igual (tipo  (programa e1)) (tipo  (programa e2)))
          (op-igual (op-suma (orden (bloque e1)) 1)
                    (orden   (bloque e2))))
  :operacion suma :devuelve 1)

(defvar restriccion-sin-mismo-tipo-consecutivo
  (def-nppq (op-mayor adyacentes-mismo-tipo 0)))
```

**Salida:**

> ## Entidades
>
> Un canal tiene nombre.
> Un día tiene nombre.
> Un tipo de programa tiene código.
> Un bloque tiene día y orden.
> Un programa tiene nombre, tipo, duración y canal.
> Una emisión está formada por un bloque y un programa.
>
> ## Datos
>
> Hay un canal: Canal Habana.
> Hay siete días: Lunes, Martes, Miercoles, Jueves, Viernes, Sabado y Domingo.
> Hay ocho programas: El Tiempo y la Memoria, Coordenadas, Revista Hola Habana…
>
> ## Qué se decide
>
> Cada fila del horario es una emisión. Se decide, para cada bloque, qué programa le corresponde.
>
> ## Restricciones
>
> **Obligatorias.** No puede haber dos emisiones consecutivas del mismo día con el mismo tipo y el mismo canal.
>
> **Preferencias.** Se prefiere la solución que minimiza, para el canal más afectado, el número de pares de emisiones consecutivas del mismo día con el mismo tipo y el mismo canal.

---

## Cómo funciona

Cuatro capas, cada una encima de la anterior.

| Capa | Qué hace |
|---|---|
| **Léxico** | Símbolo → palabra española, con género, número y artículo. `emision` → «una emisión» / «las emisiones» |
| **Literal** | Nodo del AST → fragmento de frase. `op-and` → «y», `op-igual` → «es igual a». Un `typecase` sobre los veinte tipos de nodo |
| **Documento** | Recorre el problema y emite cinco secciones: entidades, datos, qué se decide, qué se mide, restricciones |
| **Idiomas** | Reconoce la *forma* completa de una restricción y elige una frase hecha, en vez de traducir nodo a nodo |

La capa de idiomas es la que hace la diferencia. La traducción literal de la restricción del ejemplo ocupa **406 caracteres**:

> No puede pasar lo siguiente: el número de casos, para cada canal c, cada emisión e1 y cada emisión e2, en que el canal del programa de e1 es igual a c, el canal del programa de e2 es igual a c, el día del bloque de e1 es igual al día del bloque de e2, el tipo del programa de e1 es igual al tipo del programa de e2 y la suma del orden del bloque de e1 y 1 es igual al orden del bloque de e2 es mayor que 0.

Correcta e ilegible. El reconocedor de patrones la reduce a **91**.

### Cómo reconoce

El matcher detecta que el `:comprueba` tiene la forma de un **choque por pares**: dos variables que recorren la misma entidad, y un conjunto de condiciones que comparan lo mismo en ambas. Clasifica cada condición en cuatro papeles:

- **compartido** — `(op-igual (f e1) (f e2))` → los dos coinciden en `f`
- **distinto** — `(op-distinto (f e1) (f e2))` → son elementos diferentes
- **adyacente** — `(op-igual (op-suma (f e1) 1) (f e2))` → son consecutivos
- **enlace** — ambos apuntan a un tercer elemento → «que comparten un profesor»

Después separa lo compartido en dos grupos según si el atributo **depende de lo que se decide** o es un dato fijo. Los datos describen al par («dos emisiones *del mismo día*»); lo decidido es lo prohibido («*con el mismo tipo*»).

---

## Lo que esto enseñó sobre el modelo matemático

Ese eje datos/decisión no se inventó aquí: es el mismo que la tesis ya había identificado como motor para generar el modelo matemático exacto del problema. **La misma clasificación produce una inecuación o una oración** según qué emisor tenga detrás.

Pero el hallazgo interesante no es esa coincidencia, que estaba prevista. Es lo que apareció **al implementarla**, que no lo estaba.

### El reconocedor del modelo matemático ya está escrito

El diseño del backend matemático describía un reconocedor de patrones como su pieza central: clasificar el cuantificador, aplanar la condición en átomos, separar los de datos de los de decisión, y elegir según eso la familia de inecuaciones. Esa pieza se daba por pendiente.

Construir el verbalizador **la implementó**. El matcher hace exactamente esos pasos, y está validado contra las nueve restricciones de los tres dominios reales. El backend matemático ya no tiene que construirlo: tiene que enchufarle otro emisor detrás. La mitad difícil del trabajo pendiente resultó estar hecha.

### El test datos/decisión se colapsó a una consulta

El diseño lo formulaba así: una condición es de solo-datos si y solo si todos los símbolos de los que depende son fijos en el dominio. Eso sugiere recorrer un grafo de dependencias.

Al implementarlo resultó innecesario. Las cadenas de acceso del DSL siempre terminan en una variable que recorre la entidad combinación, así que **el último tramo del camino es un slot de esa entidad**. Basta mirar si ese slot está entre los que se deciden. Una comparación, sin recorrido.

Es una simplificación real de un diseño ya escrito, encontrada por implementarlo.

### La misma decisión, y el mismo error, en los dos backends

El diseño del modelo matemático dice que el lugar del atributo que discrimina decide la forma de la inecuación: si separa a las identidades, basta `Σx ≤ 1`; si separa por un atributo de datos, hace falta una variable de presencia y `Σ_g w ≤ 1`.

El verbalizador tropezó con esa misma distinción sin buscarla. Un dominio tiene tres restricciones de choque con forma idéntica; la primera versión las escribió las tres como «no puede haber dos clases distintas», y quedaron indistinguibles entre sí. El arreglo fue nombrar la dimensión que separa al par: «de aulas distintas», «de grupos distintos».

**Nombrar esa dimensión y elegir entre las dos formas de inecuación son la misma decisión.** Escribir mal la frase y modelar mal la restricción son el mismo error. El verbalizador lo hace visible leyendo una línea de prosa; en el modelo se vería mucho más tarde, o no se vería.

### Una errata de datos es inocua para el algoritmo genético y peligrosa para el solver exacto

El verbalizador mostró que un dominio declara cuatro locales de los que dos son el mismo nombre mal escrito. Para el algoritmo genético eso casi no importa: un valor de más en el conjunto de opciones.

De ahí una conclusión de ingeniería: **el control de calidad de los datos de entrada importa más para el backend exacto que para el metaheurístico**, y verbalizar antes de modelar es la forma barata de hacerlo. El algoritmo genético tolera datos sucios devolviendo una solución peor; el solver exacto o los arrastra como simetría o demuestra infactibilidad sobre basura.

---

## Decisiones

**Reglas con tabla de excepciones, no diccionario.** El género se deduce de la terminación, el plural de la última letra. La tabla solo carga lo que la regla falla (`programa` y `día` terminan en `-a` y son masculinos). Un diccionario completo sería trabajo proporcional al tamaño del dominio y habría que rehacerlo con cada dominio nuevo.

**La capa de idiomas va encima de la literal, nunca en su lugar.** Si no se reconoce el patrón, se cae a la traducción literal. Un dominio con una restricción rara sigue produciendo documento, solo que con un párrafo torpe. Y un solo átomo sin clasificar aborta el patrón entero: mejor un párrafo feo que una oración que se deja algo fuera en silencio.

**Nunca fallar en silencio.** Un tipo de nodo sin traducir emite `[NODO_DESCONOCIDO: <clase>]` en el texto, y una comprobación automática busca esa marca y rompe la ejecución.

**Se escribe un archivo, no código que lo imprima.** El generador de Python emite un programa que hay que ejecutar para ver el modelo. Aquí el texto se escribe directamente. Consecuencia práctica: el sandbox **no necesita Python**, solo un intérprete Lisp.

**El orden de las entidades se calcula, no se hereda.** Las entidades se ordenan topológicamente para que ninguna se mencione antes de presentarse, leyendo las dependencias de las instancias reales y no de los nombres de los slots (el slot `tipo` apunta a la entidad `tipo-programa`; en otro dominio, cinco slots con nombres distintos apuntan todos a `profesor`). El desempate es determinista a propósito: el documento se va a comparar por diff, y un orden inestable lo haría inútil.

**La prosa será fiel pero pelada.** La descripción original escrita a mano empieza situando el problema («la convocatoria del curso 2025-2026 de la Facultad de Matemática y Computación»). Nada de eso está en el DSL. El objetivo no es reproducir el texto original, sino producir una paráfrasis verificable: **el hueco entre las dos prosas es la medida de lo que el DSL no captura**.

---

## Qué encontró

El verbalizador expuso cosas que en el código generado nadie miraría:

- **Un error latente en el propio DSL.** Un dominio declara una entidad llamada `clase`, y el constructor que el lenguaje genera para ella tapa una macro interna de la infraestructura del mismo nombre. Cualquier dominio cargado después falla. Nunca se había visto porque cada dominio se ejecuta en su propio proceso. El generador ahora hace lo mismo, por eso.
- **Un dato duplicado por errata.** Un dominio declara cuatro locales; dos son el mismo nombre mal escrito. Solo hay tres.
- **Un recuento equivocado en la documentación del proyecto.** Un dominio tiene 70 unidades de programación, no 65 como estaba registrado. El tamaño estimado del problema estaba calculado sobre la cifra mala.
- **Datos declarados que ninguna regla usa.** Un atributo existe en el modelo y ninguna restricción lo menciona, porque la regla que lo usaba quedó fuera.

Ninguno de los cuatro es un fallo del verbalizador. Son exactamente el tipo de hallazgo para el que se construyó: poner la descripción en prosa al lado de la original hace visible lo que el código oculta.

Añadir un ejemplo nuevo es dejar su archivo en la carpeta de dominios. El generador la recorre sola.
