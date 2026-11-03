# Diferencias esperadas respecto a la referencia

La reimplementación corrige errores, así que algunas salidas **tienen** que cambiar. Este documento dice cuáles y cómo. Cualquier otra diferencia con la referencia es un error de la migración.

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

**Cuánto cambia el valor depende de D3.1:**

- **si se cuentan parejas,** el valor nuevo es exactamente la mitad del viejo;
- **si se cuenta el exceso por celda,** una celda con k filas en conflicto pasa de k(k−1) a k−1. Con k = 2 coincide con la mitad; con k ≥ 3 es menor.

En los horarios factibles las diez valen 0 antes y después.

Las consultas de dos variables que ordenan el par **no cambian**: `adyacentes-mismo-tipo` y `consecutivos-por-canal` de tv, y `dobles-no-consecutivos` de Saúl.

### Umbrales y sumas (3.5, 3.6)

**Sin diferencias en los dominios actuales.** Ningún `nppq` ni `ndpq` compara contra un umbral distinto de 0, y toda consulta `suma` usa `:devuelve 1`, que suma lo mismo que contar.

Los únicos `:devuelve` distintos de 1 son `n-dias`, en `dias-asistidos` de tesis y `dias-de-profesor` de docentes. Los dos están en consultas `contar-distintos-dias`, donde el valor no se usa, y desaparecen al migrar a `contar-distintos` con atributo explícito (D1.4).

### Comparación por identidad (3.1)

Sin diferencias de valor. Las entidades que hoy son iguales campo a campo ya se distinguen con campos añadidos a propósito (el número de la sesión de Saúl, el nombre del año del SEDER). Si al migrar se quitan esos campos, los valores tienen que seguir siendo los mismos; esa es la prueba de que la comparación por identidad funciona.

---

## Modelo matemático (`modelo.txt`)

Cambia de formato por completo: deja de ser texto impreso por el Python (3.3). Con independencia del formato, el contenido tiene que corregir esto:

| Dominio | Hoy | Debe quedar |
|---|---|---|
| Saúl | R9: `(sesiones_del_plan(h, pl) = frecuencia(?))` | cuantificador explícito y entidad nombrada: «∀ pl ∈ PLAN: sesiones_del_plan(h, pl) = frecuencia(pl)» |
| Saúl | R11: `(sesiones_de_la_jornada(h, jornada) ≤ tope(?))` | lo mismo, sobre JORNADA |
| Saúl | R10: `(primeros_turnos_de_lejanos(h) > 0)`, la condición prohibida | la restricción: `primeros_turnos_de_lejanos(h) = 0`, igual que un `nppq` |
| Saúl | R9 y R11 sin «donde» | cada restricción con la definición de sus consultas (2.5) |
| docentes | `frecuencia(?)` en la restricción de frecuencia, si se incluye (D1.7) | la entidad nombrada |
| docentes | `dias_de_profesor(h, prof) = \|{ fecha(c) : … }\|` | el atributo real, `dia(c)` (3.7) |
| SEDER | la letra `I` nombra a la vez instalación e indisponibilidad, y `T` y `I` aparecen dos veces | un símbolo distinto por conjunto (3.4) |
| todos | encabezado «tdpq / sbqp / minimizar» | `ndpq`; la errata desaparece con el emisor nuevo |

Los modelos de docentes y Saúl no se capturaron ejecutando (D0.6). Sus filas de esta tabla salen de leer las cadenas `print` de su `horario.py`.

---

## Prosa en español (`descripcion.md`)

**Debe quedar idéntica**, carácter por carácter:

| Dominio | Caracteres |
|---|---|
| tesis | 1720 |
| docentes | 2192 |
| tv | 1433 |
| Saúl | 4313 |
| SEDER | 2527 |

La única excepción aceptable es una que cambie el significado por una decisión tomada. Por ejemplo, si una consulta de choque pasa a `:pares` y el verbalizador ya no necesita callar la cláusula del orden del par. Cada excepción se anota aquí con su motivo antes de aceptarla.

---

## Salida del Python generado

No se compara texto con texto: cambia la estructura (D3.2) y desaparecen los cableados (3.7), como «Defensa {i}». Lo que se compara es el valor de cada restricción sobre los horarios de referencia, tal como se describe arriba.

**Requisito para que la comparación sea posible:** el sistema nuevo tiene que conservar el **orden de las instancias** de cada entidad tal como aparecen en el dominio. Los horarios de referencia están guardados como posiciones dentro de esas listas.
