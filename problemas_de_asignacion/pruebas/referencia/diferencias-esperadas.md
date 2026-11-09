# Diferencias esperadas respecto a la referencia

La reimplementación corrige errores, así que algunas salidas **tienen** que cambiar. Este documento dice cuáles y cómo. Cualquier otra diferencia en los valores es un error de la migración.

Los números entre paréntesis remiten a `deficiencias-por-capa.md`.

---

## Valores de las restricciones (`valores.json`, `factibles/*.json`)

### Choques simétricos que dejan de contar doble (2.2)

Diez consultas recorren las parejas ordenadas con una condición simétrica, así que cada conflicto se cuenta dos veces. En la versión nueva pasan a `:pares` y cada conflicto cuenta una sola vez.

| Dominio | Consulta | Restricción |
|---|---|---|
| tesis | `conflictos-de-horario` | `restriccion-sin-conflictos-de-horario` |
| tesis | `colisiones-de-local` | `restriccion-un-local-por-defensa` |
| docentes | `colisiones-de-aula` | `restriccion-un-grupo-por-aula` |
| docentes | `colisiones-de-grupo` | `restriccion-una-clase-por-grupo` |
| docentes | `colisiones-de-profesor` | `restriccion-un-aula-por-profesor` |
| Saúl | `colisiones-de-grupo` | `restriccion-una-sesion-por-grupo` |
| Saúl | `colisiones-de-profesor` | `restriccion-una-sesion-por-profesor` |
| Saúl | `repeticiones-en-el-dia` | `restriccion-sin-repetir-asignatura-en-el-dia` |
| SEDER | `colisiones-de-profesor` | `restriccion-un-profesor-por-turno` |
| SEDER | `colisiones-de-instalacion` | `restriccion-una-brigada-por-instalacion` |

Se cuentan parejas (D3.1): **el valor nuevo es exactamente la mitad del viejo.**

En los horarios factibles las diez valen 0 antes y después.

Las consultas de dos variables que ordenan el par **no cambian**: `adyacentes-mismo-tipo` y `consecutivos-por-canal` de tv, y `dobles-no-consecutivos` de Saúl.

### Umbrales y sumas (3.5, 3.6)

**Sin diferencias en los dominios actuales.** Ningún `nppq` ni `ndpq` compara contra un umbral distinto de 0, y toda consulta `suma` usa `:devuelve 1`, que suma lo mismo que contar.

Los únicos `:devuelve` distintos de 1 son `n-dias`, en `dias-asistidos` de tesis y `dias-de-profesor` de docentes. Los dos están en consultas `contar-distintos-dias`, donde el valor no se usa, y desaparecen al migrar a `contar-distintos` con atributo explícito (D1.4).

### Cotas (D3.7)

Dos restricciones de Saúl pasan de 1 por elemento a lo que falta para cumplirlas:

| Restricción | Viejo | Nuevo |
|---|---|---|
| `restriccion-tope-diario-de-profesor` | 1 por cada profesor y día que supera el tope | Lo que supera el tope |
| `restriccion-frecuencia-exacta` | 1 por cada plan que no la cumple | Cuánto se aleja de la frecuencia. Vale 0 siempre, porque no se puede incumplir |

Valen 0 en los mismos casos, y el nuevo nunca es menor. Con la semilla 0, el tope pasa de 5 a 9.

### Comparación por identidad (3.1)

Sin diferencias de valor. Docentes tiene 20 sesiones iguales campo a campo, pero ninguna consulta las compara directamente. Saúl pierde `numero` (D3.9), que solo existía para distinguir sus sesiones: los valores tienen que seguir siendo los mismos, y esa es la prueba de que la comparación por identidad funciona.

---

## Salida del Python generado

No se compara texto con texto: cambia la estructura (D3.2) y desaparecen los cableados (3.7), como «Defensa {i}». Lo que se compara es el valor de cada restricción sobre los horarios de referencia, tal como se describe arriba.

**Requisito para que la comparación sea posible:** el sistema nuevo tiene que conservar el **orden de las instancias** de cada entidad tal como aparecen en el dominio. Los horarios de referencia están guardados como posiciones dentro de esas listas.
