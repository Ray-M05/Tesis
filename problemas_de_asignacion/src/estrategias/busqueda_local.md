# Estrategia: búsqueda local

## Qué tipo de implementación es

Es una metaheurística de **trayectoria**: trabaja sobre un solo horario completo y lo mejora moviendo una fila por paso. Cada paso le da a una fila elegida al azar la mejor de sus celdas permitidas, sin mirar las demás filas. Es un descenso por el mejor vecino (*hill climbing*), que también acepta los movimientos que dejan el costo igual. Siempre devuelve el mejor horario visto.

## Estrategias que incorpora

| Estrategia | Papel en el algoritmo |
|---|---|
| Arranque | El horario de partida, elegido con `--inicio`: `voraz`, por defecto, que es `inicio-voraz`; `permitidos`, una celda permitida al azar por fila; o `aleatorio`, cualquier celda. |
| Poda unaria | Cada fila solo prueba sus celdas permitidas: `opciones_permitidas()`. Una fila sin ninguna permitida prueba todas. |
| Mejor opción de una fila | El paso, `mejor-opcion-de-fila`: elige una fila al azar y prueba todas sus celdas permitidas. |
| Movimientos laterales | Entre las celdas empatadas en el menor costo se elige una al azar, y la actual cuenta como una más. Así puede moverse sin empeorar, o quedarse donde está. |
| Ruido | Con probabilidad `--ruido`, el paso da a la fila una celda permitida al azar, aunque empeore. Por defecto no se usa. |
| Costo ponderado | `penalización × duras + Σ peso × blandas`, con penalización 1000: una dura pesa más que todas las blandas juntas. |
| Caché | Cada horario se evalúa una sola vez. Las restricciones constantes se calculan una sola vez, al empezar. |
| Mejor visto | Se guarda aparte el mejor horario, que solo cambia si el costo baja de verdad. |
| Parada | Se detiene en el óptimo, por estancamiento, en el máximo de pasos o por tiempo. |

## Flujo del algoritmo

**1. Preparación, una sola vez**

1. Lee los argumentos y crea el generador de números al azar con `--semilla`.
2. Pone en marcha la parada, que empieza a contar el tiempo.
3. Calcula las restricciones constantes y las celdas permitidas de cada fila.
4. Construye un horario con el arranque de `--inicio`. Ese horario es a la vez el actual y el mejor visto.

**2. Cada paso, hasta que se cumpla la parada**

1. Comprueba la parada con el mejor visto:
   - `optimo`, si tiene 0 duras y 0 blandas;
   - `estancamiento`, si lleva `--estancamiento` pasos seguidos sin mejorar;
   - `maximo`, si se llegó a `--pasos`;
   - `tiempo`, si pasaron `--tiempo` segundos.
2. Elige una fila al azar entre todas, esté o no en conflicto.
3. Con probabilidad `--ruido`, le da una celda permitida al azar y pasa al punto 6.
4. Si no, arma los vecinos: el horario actual y uno por cada otra celda permitida de la fila, que solo cambia esa fila. Evalúa cada vecino entero.
5. El horario actual pasa a ser uno de los vecinos de menor costo, elegido al azar.
6. Si el actual cuesta menos que el mejor visto, pasa a ser el mejor y la cuenta sin mejora vuelve a 0. Si no, la cuenta sube en 1.

**3. Salida**

Evalúa el mejor visto y escribe el JSON de la corrida en `corridas/`: el motivo de parada, los pasos, los horarios creados y evaluados, los segundos, el costo, las duras, las blandas, las posiciones, el horario en texto y el valor de cada restricción.

## Argumentos

| Argumento | Por defecto | Operador |
|---|---|---|
| `--semilla` | obligatoria | la elección de filas y los empates al azar |
| `--inicio` | `voraz` | el arranque |
| `--penalizacion` | 1000 | el costo |
| `--tiempo` | sin límite | la parada |
| `--estancamiento` | 2000 | la parada |
| `--ruido` | 0 | el paso |
| `--pasos` | 100000 | la parada |

Con `--pasos 0` devuelve el arranque sin dar ningún paso: es la forma de medir el voraz solo.

## Cuánto cuesta un paso

Un paso evalúa el horario entero una vez por cada celda permitida de la fila, salvo la actual. Lo que cuesta depende de cuántas celdas permitidas tiene la fila y de lo que cuesta evaluar el horario:

- **Saúl:** unas 20 a 28 celdas por fila y unos 7 ms por evaluación, así que unos 6 pasos por segundo.
- **Docentes:** no tiene restricciones de una fila, así que cada paso prueba las 180 celdas. Sus evaluaciones son mucho más baratas, y da unos 12 pasos por segundo.

Elegir la fila al azar entre todas hace que, cuando quedan pocos conflictos, casi ningún paso caiga en una fila con problemas. En Saúl, con unas 6 duras repartidas en 297 filas, la mayoría de los pasos solo mueven filas sin conflicto a celdas del mismo costo.

## Cómo se comporta

Medido con sus valores por defecto y el arranque voraz:

| Dominio | Arranque | Resultado | Pasos | Tiempo |
|---|---|---|---|---|
| tv | 0 duras / 0 blandas | óptimo en el arranque | 0 | menos de 0,1 s |
| tesis | 0 / 3 | 0 / 2 | unos 2 000 | unos 55 s |
| SEDER | 0 / 13 a 16 | 0 / 11 | 2 300 a 2 700 | unos 5 s |
| docentes | 0 / 5 | 0 / 5, sin mejorar nada | 2 000 | unos 165 s |
| Saúl | 11 a 17 / 9 a 10 | 0 a 3 / 3 o 4 | 3 900 a 7 200 | 11 a 18 min |

- **En Saúl, la diferencia de arranque desaparece pronto.** Con las semillas 0, 1 y 2, el arranque tiene 17, 11 y 15 duras, y a los 120 s, unos 760 pasos, las tres corridas están en 6. Lo que queda después lo decide el camino, que cambia con la semilla.
- **En docentes no baja las blandas.** El minimax de días de viaje solo baja si se vacía un día entero de un profesor, y varios profesores pueden empatar en el máximo. Moviendo una fila por paso, casi nunca se consigue.
- **El ruido no ayuda.** En Saúl, desde el voraz, da 8,7 duras de media sin ruido y 14,3 con el 10 %.
