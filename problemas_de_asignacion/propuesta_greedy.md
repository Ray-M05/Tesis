# Propuesta: estrategia voraz con reparación y reinicios

## Qué tipo de implementación es

Es una metaheurística de **trayectoria**: trabaja sobre una sola solución a la vez. Construye un horario de forma voraz y lo repara por **mínimos conflictos con tabú**. Cuando se estanca, empieza otra vez: es un esquema de **multiarranque**. El objetivo es: primero las duras, después las blandas.

## Estrategias que incorpora

| Estrategia | Papel en el algoritmo |
|---|---|
| Poda unaria (ya existe) | Cada fila solo puede tomar sus celdas permitidas: `opciones_permitidas()`. |
| Holgura por clave | Antes de buscar, compara por clave las sesiones con las celdas alcanzables. Si alguna no cabe, demuestra que no hay solución. Si caben, ordena la construcción: primero las claves más justas. |
| Voraz dinámico | Construye colocando cada vez la fila con menos celdas todavía libres, y recalcula después de cada colocación. |
| Mínimos conflictos | Repara moviendo solo filas que están en una restricción incumplida, cada una a su mejor celda. Es la brújula. |
| Permuta de clave | Movimiento secundario: intercambia las celdas de dos filas que comparten la clave más justa, por ejemplo el grupo. |
| Tabú corto | Durante *t* pasos, una fila no puede volver a la celda que acaba de dejar, salvo que eso mejore lo mejor del arranque (aspiración). |
| Lexicográfico | Compara (duras, blandas) en ese orden. En la fase 2 solo se aceptan movimientos que mantienen 0 duras. Quita `--penalizacion`. |
| Reinicios | Tras *E* pasos sin mejora, construye desde cero y guarda el mejor horario visto. |


## Flujo del algoritmo

**1. Preparación, una sola vez**

1. Calcula las celdas permitidas de cada fila.
2. Emite el certificado de holgura. Para cada clave compara sus sesiones con las celdas que alcanzan. Si alguna no cabe, termina con `infactible` y nombra la clave. Si todas caben, la holgura de una fila es la menor de las de sus claves.

**2. Cada arranque, hasta que se cumpla la parada**

1. **Construcción.** Mientras queden filas sin poner:
   - elige la fila con menos celdas libres; a igualdad, la de menor holgura, y si sigue el empate, una al azar;
   - la pone en la celda de menor (duras, blandas), desempatando al azar;
   - actualiza las celdas libres de las filas que comparten alguna clave con ella.
2. **Fase 1, duras.** Mientras haya duras:
   - elige al azar una fila en conflicto;
   - con probabilidad *p*, la permuta con otra fila de su clave más justa, siempre que ninguna de las dos salga de su dominio, el movimiento no sea tabú y no empeore;
   - si no, la lleva a su mejor celda permitida que no sea tabú (o que, aun siéndolo, mejore lo mejor del arranque);
   - marca como tabú, durante *t* pasos, la pareja (fila, celda que deja).

   Si pasan *E* pasos sin mejora, termina el arranque.
3. **Fase 2, blandas.** Si llegó a 0 duras, pule durante un tiempo corto: el mismo paso, eligiendo entre las filas con alguna blanda incumplida y aceptando solo movimientos que mantienen 0 duras.
4. **Guardar.** Si (duras, blandas) es menor que el mejor visto, guarda el horario.

**3. Parada**

Se detiene en el óptimo (0, 0), por tiempo o al llegar al máximo de arranques. Escribe el JSON de la corrida con los mismos campos que las otras estrategias, más el número de arranques y el resultado del certificado.

## Argumentos

Cada argumento pertenece al operador que lo usa, como en las otras estrategias.

| Argumento | Por defecto | Operador |
|---|---|---|
| `--tabu` | 10 pasos | tabú |
| `--permuta` | 0,25 | permuta de clave |
| `--estancamiento` | 5 × filas | reinicio |
| `--pulido` | 1 s por arranque | fase 2 |
| `--tiempo`, `--arranques` | sin límite | parada |

En un dominio sin `choque-por-parejas`, como tv, la holgura y la permuta no tienen clave sobre la que actuar. El resto funciona igual.