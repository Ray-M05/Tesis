# Propuesta: estrategia golosa de una pasada

## Qué tipo de implementación es

Es un algoritmo **constructivo** puro: construye un único horario en una sola pasada. Cada fila se decide una vez y no se vuelve a tocar: no repara, no deshace y no reinicia. No persigue la factibilidad. Si una fila no tiene ninguna celda limpia, toma la que menos daño hace y lo anota. El objetivo es la rapidez.

## Estrategias que incorpora

| Estrategia | Papel en el algoritmo |
|---|---|
| Poda unaria (ya existe) | Cada fila solo mira sus celdas permitidas: `opciones_permitidas()`. Así nunca rompe una restricción de una fila. Si no tiene ninguna permitida, mira todas. |
| Menos opciones primero | Coloca antes las filas con menos celdas permitidas. El orden se calcula una vez y no cambia. |
| Menor daño | El daño de una celda es lo que suben las duras y las blandas al poner ahí la fila. Compara primero las duras y después las blandas con su peso: es lexicográfico, sin `--penalizacion`. |
| Celda menos demandada | Entre las celdas empatadas, elige la que menos necesitan las filas pendientes que podrían tomar sus mismas ocupaciones. Si sigue el empate, al azar. |
| Tablas de ocupación | Una ocupación es el par (clave, celda) donde dos filas pueden chocar, como (10-1, lunes, T2). Las tablas guardan lo ya colocado en cada ocupación, y dan el daño y la demanda sin recorrer el horario. Salen del análisis. Una restricción sin ocupaciones, como un minimax, se evalúa con todas las filas puestas. |

## Flujo del algoritmo

**1. Preparación, una sola vez**

1. Calcula las celdas permitidas de cada fila.
2. Ordena las filas por número de celdas permitidas, desempatando al azar.
3. Calcula la demanda: por cada fila y cada celda permitida suya, suma 1 en cada ocupación que tomaría.

**2. Construcción, una sola pasada.** Para cada fila, en ese orden:

- calcula el daño de cada celda permitida: (duras nuevas, blandas nuevas);
- elige la de menor daño; a igualdad, la menos demandada; si sigue el empate, una al azar;
- la fija, la suma a las tablas y resta su demanda;
- si la celda elegida añadía duras, anota la fila como forzada.

**3. Salida.** Evalúa una vez el horario completo con `evaluar`. Escribe el JSON de la corrida con los campos de las otras estrategias que tienen sentido aquí, más las filas forzadas. No hay parada: termina al colocar la última fila.

## Argumentos

| Argumento | Por defecto | Operador |
|---|---|---|
| `--semilla` | obligatoria | los desempates al azar |

No tiene `--inicio`, ni `--penalizacion`, ni argumentos de parada. La misma semilla da siempre el mismo horario.

En un dominio sin `choque-por-parejas`, como tv, no hay demanda que contar y el empate se rompe al azar. El resto funciona igual.

## Punto extra: el voraz que ya existe

`inicio-voraz` es el arranque por defecto del genético y de la búsqueda local. Funciona así:

- ordena las filas por número de celdas permitidas;
- para cada celda permitida, evalúa todas las `PROHIBICIONES` sobre el horario parcial con la fila nueva;
- se queda con las celdas que menos incumplen y elige una al azar.

En el genético solo el primer individuo es voraz; los otros 99 son celdas permitidas al azar. En la búsqueda local es el horario de partida.

## Resultados

- el goloso y el voraz actual, con `ejecuciones/goloso-<dominio>.lisp` y 25 semillas;
- la búsqueda local, con sus valores por defecto y 3 semillas.

El voraz actual es `busqueda_local.py --pasos 0`. La búsqueda local corrió en los cinco dominios a la vez, así que sus tiempos son aproximados.

Cada celda da la media de duras / blandas y los segundos por corrida:

| Dominio | Goloso | Voraz actual | Búsqueda local |
|---|---|---|---|
| tv | 0 / 0, en 0,07 s | 0 / 0, en 0,05 s | 0 / 0, en 0,06 s |
| tesis | 0 / 1,9, en 0,15 s | 0 / 3,0, en 0,14 s | 0 / 2,0, en 55 s |
| SEDER | 0 / 11,4, en 0,02 s | 0 / 14,0, en 0,04 s | 0 / 11,0, en 5,5 s |
| docentes | 0 / 2,0, en 0,50 s | 0 / 5,0, en 4,1 s | 0 / 5,0, en 166 s |
| Saúl | 12,0 (9–18) / 1,4, en 1,6 s | 15,0 (10–20) / 7,7, en 17,5 s | 1,3 (0–3) / 3,7, en 812 s |

- **Mejoras:**
  - 0 duras en tv, tesis, SEDER y docentes, en las 25 semillas;
  - menos duras en Saúl;
  - menos blandas en todos los dominios salvo tv, donde las dos dan 0;
  - ninguna restricción de una fila incumplida;
  - en Saúl, diez veces más rápido que el voraz actual.
- **En Saúl, casi todas las duras que quedan son choques de grupo:** 9,3 de 12. 10mo no tiene holgura. Los choques de profesor bajan de 3,6 a 1,4. Cada fila forzada añade una dura.
- **En docentes, el goloso deja las blandas en 2,** y la búsqueda local no baja de 5. También apila hasta 5 sesiones del mismo grupo en la misma aula, día y turno, frente a 3 del voraz actual; el modelo lo permite.
- **La búsqueda local, si se la deja correr hasta el estancamiento, llega a 0 duras en Saúl** con una de las tres semillas, y a 1 y 3 con las otras dos, en 11 a 18 minutos. Lo mejor medido antes eran 6 duras, en 120 s.

## Valoración: el goloso como arranque del genético

Es una estimación: no se ha probado.

**Qué se compara.** Hoy el genético arranca con un individuo voraz y 99 al azar entre las celdas permitidas, y el mejor pasa siempre a la generación siguiente. Ese individuo voraz es el mismo horario que da el voraz actual con la misma semilla.

- **Saúl: la mejora no es despreciable.**
  - **Lo medido antes:** en corridas de 500 generaciones, de unos 5 minutos, el genético bajó el voraz de 17, 11 y 15 duras a 14, 10 y 14. Mejoró de 1 a 3 duras, y las blandas pasaron de 9 o 10 a entre 5 y 7. Con 20 generaciones, como en la fase 5, no lo mueve.
  - **Por qué pesa el arranque:** lo que mejora sale casi entero del mejor individuo. El resto de la población arranca con unas 150 duras, y el cruce deshace lo arreglado.
  - **Qué cabe esperar:** el goloso da 3 duras menos que el voraz de media. Arrancando de él, el genético terminaría con unas 2 o 3 duras menos, unas 10 frente a unas 13, y con 1 o 2 blandas en vez de entre 5 y 7. Es más de lo que el genético mejora por su cuenta en 500 generaciones. El arranque costaría además unos 16 s menos, el 5 % de una corrida.
  - **Las dudas:** la mejora es de media, no por semilla. Con las semillas 1 y 2, el goloso da 12 y 17 duras frente a 11 y 15 del voraz. Además, desde un horario mejor, una mutación al azar encuentra menos mejoras, y el genético podría bajar menos de 1 a 3.
- **Docentes: mejoran las blandas.** El genético se queda en 5 blandas, como su voraz, y desde el goloso no bajaría de 2. Solo hay una semilla medida del genético.
- **tv, tesis y SEDER: despreciable.** El genético ya llega solo a 0 duras y a blandas parecidas a las del goloso: 2 en tesis y 11 o 12 en el SEDER.

## Valoración: el goloso como arranque de la búsqueda local

Es una estimación: no se ha probado.

**Qué se compara.** La búsqueda local arranca del voraz y mejora una fila por paso, hasta 2 000 pasos seguidos sin mejora. Ese voraz es el mismo horario que da el voraz actual con la misma semilla.

- **Saúl: despreciable en el resultado; ahorra algo de tiempo.**
  - **Lo medido antes:** con las semillas 0, 1 y 2, el voraz arranca con 17, 11 y 15 duras. A los 120 s, unos 760 pasos, las tres estaban en 6 duras. Hasta el estancamiento terminaron en 0, 1 y 3 duras, con 3, 4 y 4 blandas, en 11 a 18 minutos.
  - **Por qué no pesa el arranque:** la búsqueda local borra la diferencia en los primeros cientos de pasos, porque de 11, 15 o 17 duras llega a 6 en todos los casos. Al contrario que el genético, mejora el horario entero y no depende de un solo individuo. Lo que decide el final es el camino que sigue después, y ese cambia con la semilla.
  - **Qué cabe esperar:** el mismo reparto final, de 0 a 3 duras, quizá con 1 o 2 blandas menos. Ahorraría unos 16 s de arranque y los pasos que hoy cuesta bajar de 15 a 12 duras: quizá medio minuto, entre el 3 y el 5 % de una corrida.
  - **Las dudas:** de una semilla a otra el final cambia de 0 a 3 duras, mucho más que cualquier efecto del arranque. Con 3 semillas no se podría distinguir.
- **Docentes: mejoran las blandas.** La búsqueda local se queda en las 5 blandas de su voraz. Mover una sola fila casi nunca baja el máximo de días de un profesor: hay que vaciarle un día entero, y varios pueden empatar en el máximo. Desde el goloso se quedaría en 2, y tardaría lo mismo, porque para tras 2 000 pasos sin mejora.
- **tv, tesis y SEDER: despreciable.** La búsqueda local ya llega a 0 duras, a 2 blandas en tesis y a 11 en el SEDER, lo mismo o algo mejor que el goloso.

**En resumen:** el arranque pesa mucho en el genético y poco en la búsqueda local. En las dos mejora las blandas de docentes.