# Futuras mejoras

Reúne lo que queda por hacer después de [`reparacion_tabu.md`](reparacion_tabu.md):

- Los puntos del ranking de estrategias que la propuesta no toma y que siguen valiendo la pena.
- Todo lo de las etapas extra de [`plan-reimplementacion.md`](plan-reimplementacion.md): la etapa 6 extra y el trabajo extra.

Lo que la propuesta ya cubre queda marcado como **cubierto**. Las cifras son de prototipos fuera del proyecto, salvo que se diga otra cosa.

---

## 1. Evaluación

| Mejora | Qué hace | Por qué vale la pena | Origen |
|---|---|---|---|
| **Evaluación incremental por familia** | Al mover una fila, recalcula solo los términos donde aparece esa fila, en vez de evaluar el horario entero. Tiene tres niveles, todos derivados del modelo: **A**, fijar la fila en vez de recorrerla, con los iteradores y la condición; **B**, además el índice por `pareja-clave` y los `pareja-enlaces`; **C**, además contadores por `pareja-celda`. | Es lo que hace escalar a cualquier estrategia. Al doblar las filas, la evaluación completa cuesta unas 3 veces más y los pasos se duplican: la propuesta voraz tardaría unos 6 minutos en Saúl ×2, frente a 1,4 s con contadores. En Saúl: 152 movimientos por segundo con la evaluación completa; unos 420 con A, 23 000 con B y 88 000 con C. Saúl llega a 0 duras en 62 s con A, 1,6 s con B y 0,35 s con C. Ninguna de las 27 consultas de los cinco dominios es `consulta-generica`, así que cinco métodos, uno por familia, más A como respaldo, lo cubren todo. Lo difícil está acotado: `minimax` necesita la tabla por tupla de `:para`, y `contar-distintos` una cuenta por valor. | Ranking 1; etapa 6 extra, mejora C (D4.10) |
| **Agrupar las relaciones ordenadas** | Compara solo las filas que comparten celda y clave, como ya se hace con los choques. Toca `src/emision/python/consultas.lisp`. | `turno_doble_consecutivo` es el 44 % del tiempo de Saúl, y con el doble de filas pasa a ser el 68 %: es lo que más crece. Medido en la etapa 4: pasa de 2,96 ms a 0,03 ms con el mismo valor. La incremental lo hace innecesario, pero se escribe en un día. | Ranking 11; etapa 6 extra, mejora B (D4.10) |

Criterio que viene del plan y sigue vigente: **los valores de las restricciones no cambian con B ni con C**, y las pruebas de referencia de la etapa 3 lo comprueban. Para la incremental hay que añadir una prueba fija: el total llevado de forma incremental tiene que ser igual a lo que devuelve `evaluar`.

---

## 2. Búsqueda

### Para la estrategia voraz

| Mejora | Qué hace | Por qué vale la pena | Origen |
|---|---|---|---|
| **Ruptura y recomposición** | Cuando la reparación se estanca, descoloca las filas en conflicto y las que comparten clave con ellas, y las reconstruye con el voraz, en vez de reiniciar desde cero. | Conserva la parte buena del horario. En Saúl reiniciar es barato, pero el costo de reconstruir crece con el tamaño: es el reinicio que escala. | Ranking 7 |
| **Propagación al construir** | Al colocar una fila, quita esa celda del dominio de las filas que comparten su clave. Si algún dominio queda vacío, deshace. | Evita callejones sin salida en las claves sin holgura. Por sí sola no basta: un retroceso con detección de callejón no resolvió un grupo de 10mo en 20 s. Sirve como guardia del voraz. | Ranking 8 |
| **Valor menos restrictivo** | Entre las celdas empatadas en costo, elige la que menos opciones quita a las filas que comparten su clave. Hoy el empate se rompe al azar. | Es la pareja natural del orden de filas del voraz dinámico, y cuesta una cuenta sobre los datos que ya se llevan. | Ranking 10 |
| **Pesos dinámicos** | Cuando no hay mejora, sube el peso de las restricciones que siguen incumplidas. | Es el remedio clásico del muro de «las últimas dos violaciones». Es la alternativa al tabú si una instancia más grande se atasca. | Ranking 13 |
| **Cadenas de Kempe** | Intercambia en bloque dos celdas para una componente conexa del grafo de choques. Conserva la factibilidad por construcción. | Es el movimiento más fuerte en rejillas sin huecos. Es caro: hay que emitir el grafo de choques. | Ranking 14 |

### Para el genético y la búsqueda local existentes

| Mejora | Qué hace | Por qué vale la pena | Origen |
|---|---|---|---|
| **Elegir la fila por conflicto en la búsqueda local** | Cambia `azar.randrange(FILAS)` por una fila elegida entre las que están en conflicto. Necesita la misma función de filas en conflicto que la propuesta voraz. | Medido con la `busqueda_local.py` generada, sin tocar nada más: 0 duras en las tres semillas, en 125, 271 y 324 s. La original se queda en 4 duras a los 600 s. | Ranking 2, aplicado a la estrategia que ya existe |
| **Mutación dirigida en el genético** | `mover-filas` elige una fila en conflicto y le da una celda permitida: una al azar, o la mejor (memética). | A los 600 s, el genético pasa de 14 y 10 duras a 7 y 6 con la mutación dirigida, y a 4 y 2 con la memética. No llega a 0, porque el cruce deshace lo arreglado. También cubre la poda al mutar, que D4.6 dejó solo para el arranque. | Análisis de la estrategia voraz; D4.6 |
| **Intercambiar dos sesiones del mismo grupo** | Operador que intercambia día y turno entre dos sesiones de un mismo grupo. | **Cubierto** por la propuesta voraz, como permuta de clave. Medido: ayuda alrededor de un 20 %, pero no es lo que desbloquea Saúl. Para el genético sigue pendiente. | Etapa 6 extra |
| **Encadenar las estrategias** | Una estrategia da el horario de partida y otra lo pule. | Para la factibilidad ya no hace falta, porque el voraz llega a 0 solo. Lo que queda de valor es poder arrancar desde un JSON de `corridas/`, para pulir las blandas con otra estrategia. | Etapa 6 extra |
| **Medir el efecto de D3.7** | Comparar el exceso de las cotas con contar 1 por elemento incumplido. | Sigue sin medirse desde la etapa 3. | Etapa 6 extra |
| **Comprobar la capacidad de Saúl** | Comparar, por grupo y por profesor, las sesiones con las celdas que dejan las restricciones de una fila. | **Cubierto** por la propuesta voraz, como certificado de holgura. Saúl cabe: tres grupos y un profesor tienen holgura 0, ninguno negativa. | Etapa 6 extra |

---

## 3. Backend exacto

| Mejora | Qué hace | Por qué vale la pena | Origen |
|---|---|---|---|
| **Destino ILP** | La rama reservada `modelo-solver` de la jerarquía de destinos: PuLP, CP-SAT o MiniZinc. | Es lo único que puede **demostrar** que una instancia no tiene solución, o que una solución es óptima. El certificado de holgura solo demuestra la infactibilidad cuando las cuentas no caben. | Trabajo extra (D3.5, D4.1) |
| **Ruptura de simetría** | Impone un orden entre las celdas de identidades intercambiables, como las sesiones de un mismo plan. | No ayuda a la búsqueda local: medido, no rescató al retroceso. Pero la simetría es la patología clásica de branch-and-bound, así que es una mejora del backend exacto. | Ranking 15 |

Si se adopta MGA, conviene crear la clase `infijo` **antes** de escribir el ILP. Es la única forma de que PuLP, CP-SAT y MiniZinc compartan su traductor.

---

## 4. MGA

| Pieza | Situación | Qué haría |
|---|---|---|
| `gcode` | Sin implementar. El prototipo está en el apéndice A del plan. | Escribe los métodos de `generar-codigo` a partir de una cadena de formato. Hace visibles los nodos sin traducción. |
| `recognize-pattern` | Sin implementar. | Añade `indent` y `deindent` a `gcode`, con un método `:before`. Sustituiría a `con-sangria` (D3.6). |
| `defnode` | No se adopta. | Rompería el DSL: el nombre de un slot es vocabulario del usuario, no un accesor. |

Incorporarlo no cambia la salida, y las pruebas de la etapa 3 sirven para comprobarlo.

---

## 5. Lenguaje

| Mejora | Qué falta | Por qué vale la pena |
|---|---|---|
| **Datos de pares** | Una sintaxis para un dato que pertenece a dos entidades, sin inventar una entidad con una fila por par. Hoy se usan `plan` y `ausencia` en Saúl, e `indisponibilidad` en el SEDER. | Gana en expresividad. En la búsqueda no cambia nada y casi no cambia el tiempo. (Deficiencia 1.4) |

---

## 6. Emisión

| Mejora | Qué falta |
|---|---|
| **Cuatro puntos del verbalizador** | Revisar si ocurren al terminar la implementación y corregirlos si afectan directamente: la frase fija «en los que interviene», `:para` sin presentar en la capa literal, la `ú` que falta en `pluralizar` y `maximizar` sin frase propia. |
| **Fórmulas largas de LaTeX** | Se salen del margen, porque solo se parten por conjunción. |

---

## 7. Documentación

| Mejora | Qué falta |
|---|---|
| **Nombres viejos** | `mga-y-problemas-pendientes.md` y `limitaciones-del-dsl.md` todavía dicen `op-and` y `defclass*`. |
| **Criterio de la etapa 6** | Dice «Saúl por debajo de 6 duras, o una prueba de que no tiene solución». Saúl tiene solución, e incluso óptimo con 0 duras y 0 blandas, así que el criterio hay que reescribirlo. |
