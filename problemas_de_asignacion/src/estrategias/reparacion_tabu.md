# Estrategia de reparación tabú

## Qué tipo de implementación es

Es una metaheurística de **trayectoria**: trabaja sobre una sola solución a la vez. Construye un horario con la pasada del goloso y lo repara por **mínimos conflictos con tabú**. Cuando se estanca, empieza otra vez: es un esquema de **multiarranque**. El objetivo es: primero las duras, después las blandas.

Se llama `reparacion-tabu`. Lo que la separa del goloso es que repara: el goloso nunca vuelve a tocar una fila puesta.

## Estrategias que incorpora

| Estrategia | Papel en el algoritmo |
|---|---|
| Poda unaria (ya existe) | Cada fila solo puede tomar sus celdas permitidas: `opciones_permitidas()`. |
| Holgura por clave | Antes de buscar, compara por clave las sesiones con las celdas alcanzables. Si alguna no cabe, demuestra que no hay solución. Si caben, da la clave más justa de cada fila, que es la que usa la permuta. Solo cuenta los choques duros en los que dos filas con la misma clave y la misma celda chocan siempre. |
| Construcción golosa (ya existe) | Cada arranque se construye con la pasada del goloso: menos opciones primero, menor daño, celda menos demandada y, si sigue el empate, al azar. |
| Tablas de ocupación (ya existen) | Dan el daño de poner, quitar o mover una fila mirando solo las filas con las que comparte alguna ocupación, sin evaluar el horario entero. |
| Mínimos conflictos | Repara moviendo solo filas en conflicto: las que, al quitarlas, bajan alguna restricción incumplida. Cada una va a su mejor celda, sin contar la que ocupa. Es la brújula. |
| Permuta de clave | Movimiento secundario: intercambia las celdas de dos filas que comparten la clave más justa, por ejemplo el grupo. |
| Tabú corto | Durante *t* pasos, una fila no puede volver a la celda que acaba de dejar, salvo que eso mejore lo mejor del arranque (aspiración). |
| Lexicográfico | Compara (duras, blandas) en ese orden. En la fase 2 solo se aceptan movimientos que mantienen 0 duras. No hay `--penalizacion`. |
| Reinicios | Tras *E* pasos sin mejora, construye desde cero y guarda el mejor horario visto. |

## Flujo del algoritmo

**1. Preparación, una sola vez**

1. Calcula las celdas permitidas de cada fila.
2. Emite el certificado de holgura. Para cada clave cuenta las filas que la tienen en todas sus celdas permitidas y las celdas que alcanzan con ella.
   - Si alguna no cabe, construye un horario con la pasada golosa y termina con `infactible`, nombrando la clave.
   - Si todas caben, la holgura de una clave es la diferencia, y la clave más justa de una fila es la de menor holgura entre las suyas.

   Contar por clave solo demuestra que no cabe. Que todas quepan no demuestra que haya solución.

**2. Cada arranque, hasta que se cumpla la parada**

1. **Construcción.** La pasada del goloso, con su orden, su criterio y su desempate. Evalúa una vez el horario construido, y desde ahí lleva (duras, blandas) sumando lo que cambia cada movimiento.
2. **Fase 1, duras.** Mientras haya duras:
   - elige al azar una fila en conflicto con alguna dura;
   - con probabilidad *p*, y si la fila tiene clave, la permuta con la primera fila de su clave más justa, en orden al azar, con la que ninguna de las dos sale de su dominio, el movimiento no es tabú y no empeora;
   - si no, la lleva a su mejor celda permitida, sin contar la actual, que no sea tabú (o que, aun siéndolo, mejore lo mejor del arranque), desempatando al azar;
   - marca como tabú, durante *t* pasos, la pareja (fila, celda que deja).

   Si pasan *E* pasos sin mejorar lo mejor del arranque, termina el arranque.
3. **Fase 2, blandas.** Si llegó a 0 duras, pule con el mismo paso, eligiendo entre las filas que al quitarlas bajan alguna blanda y aceptando solo celdas que no añaden duras. Termina tras *P* pasos sin mejora.
4. **Guardar.** Si (duras, blandas) es menor que el mejor visto, guarda el horario.

El primer arranque construye el mismo horario que el goloso con la misma semilla, y se guarda el mejor visto: la reparación tabú nunca queda peor que el goloso.

**3. Parada**

Se detiene en el óptimo (0, 0) o al llegar al máximo de arranques. No tiene límite de tiempo, así que la misma semilla da siempre el mismo horario.

Escribe el JSON de la corrida con los campos de las otras estrategias que tienen sentido aquí, sin `costo`, `inicio`, `individuos` ni `filas_forzadas`, y añade:

- `arranques`;
- `certificado`, con las claves de holgura 0 o negativa;
- `mejoras`, con el arranque, el paso, los segundos y (duras, blandas) cada vez que mejora lo mejor visto.

`motivo_de_parada` es `optimo`, `maximo` o `infactible`. `iteraciones` son los pasos, y `evaluaciones` cuenta los horarios enteros evaluados: uno por arranque y el del resultado.

## Argumentos

Cada argumento pertenece a la pieza que lo usa. Los que miden los bucles son de la estrategia, como `--pasos` en la búsqueda local.

| Argumento | Por defecto | De quién es |
|---|---|---|
| `--semilla` | obligatoria | los desempates al azar |
| `--arranques` | 10 | la estrategia: el bucle de arranques |
| `--estancamiento` | 5 × filas | la estrategia: pasos sin mejora que terminan la fase 1 |
| `--pulido` | filas | la estrategia: pasos sin mejora que terminan la fase 2 |
| `--tabu` | 10 pasos | tabú |
| `--permuta` | 0,25 | permuta de clave |

No tiene `--inicio`, `--penalizacion` ni `--tiempo`. Las otras estrategias no cambian: el genético y la búsqueda local siguen arrancando del voraz por defecto.

## Resultados

Cada celda da la media de duras / blandas, con el rango entre paréntesis si varía, y los segundos por corrida. Entre corchetes, las semillas:

| Dominio | Reparación tabú [10] | Genético | Búsqueda local [3] |
|---|---|---|---|
| tv | 0 / 0, en 0,16 s | 0 / 0, en 0,09 s [1] | 0 / 0, en 0,06 s |
| tesis | 0 / 1,0, en 2,9 s | 0 / 2, en 11 s [1] | 0 / 2,0, en 55 s |
| SEDER | 0 / 11,0, en 0,4 s | 0 / 11,7 (11–12), en 6,2 s [20] | 0 / 11,0, en 5,5 s |
| docentes | 0 / 2,0, en 11 s | 0 / 5, en 18 s [1] | 0 / 5,0, en 166 s |
| Saúl | 0 / 0,7 (0–2), en 84 s | 12,7 (10–14) / 6,3 (5–7), en 289 s [3] | 1,3 (0–3) / 3,7 (3–4), en 812 s |

### Saúl, semilla por semilla

| Semilla | Construcción | 0 duras: paso y segundos | (0, 0): segundos | Final | Arranques | Pasos | Segundos |
|---|---|---|---|---|---|---|---|
| 0 | 12 / 1 | 2 119, 22,9 s | no llega | 0 / 1 | 10 | 15 019 | 128 |
| 1 | 12 / 0 | 527, 5,9 s | no llega | 0 / 2 | 10 | 17 432 | 143 |
| 2 | 17 / 0 | 712, 6,7 s | 28,2 s | 0 / 0 | 2 | 3 541 | 28 |
| 3 | 13 / 1 | 1 559, 12,1 s | no llega | 0 / 2 | 10 | 16 930 | 134 |
| 4 | 12 / 0 | 2 111, 17,1 s | 28,5 s | 0 / 0 | 2 | 3 495 | 29 |
| 5 | 9 / 2 | 724, 6,6 s | 13,0 s | 0 / 0 | 2 | 1 431 | 13 |
| 6 | 11 / 2 | 1 317, 11,2 s | 75,1 s | 0 / 0 | 7 | 9 397 | 75 |
| 7 | 10 / 2 | 263, 3,7 s | 53,6 s | 0 / 0 | 4 | 6 916 | 54 |
| 8 | 9 / 0 | 1 456, 12,0 s | no llega | 0 / 1 | 10 | 17 044 | 134 |
| 9 | 12 / 1 | 1 351, 10,9 s | no llega | 0 / 1 | 10 | 17 410 | 106 |

La construcción es la del primer arranque, que es el horario del goloso con la misma semilla.
