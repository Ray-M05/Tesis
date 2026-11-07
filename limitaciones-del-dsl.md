# Limitaciones del DSL

## Qué resuelve

Todo lo que el lenguaje describe tiene una única forma: una función total de un conjunto de identidades a un producto de pools. Cada identidad recibe exactamente una tupla de valores. Las restricciones son conteos sobre esa función, comparados contra cero o contra una constante.

Esa forma cubre la familia de problemas de asignación multiple-choice. Entran sin forzar nada el coloreado de grafos, que asigna un color a cada vértice exigiendo que los adyacentes difieran, la asignación de frecuencias a antenas, el reparto de tareas a máquinas o a personas, la formación de equipos con cuotas, la distribución de estudiantes a cursos electivos, la asignación de asientos con reglas de separación, la ubicación de productos en almacén por zona, la asignación de revisores a artículos y cualquier problema de horario cuya franja esté enumerada de antemano.

El rasgo común es doble: la decisión es elegir uno de un conjunto, y la calidad se mide contando.

El lenguaje no está atado al tiempo. Un problema de reparto de docencia entre profesores, sin ninguna franja temporal, encaja igual de bien: la identidad es la actividad y el único slot variable es el profesor.

## Limitaciones de expresividad

### Cuenta pero no suma

La operación `suma` incrementa un contador en uno. El `:devuelve` de la consulta se ignora. Ningún atributo numérico entra en una restricción como magnitud.

No se puede resolver: mochila, bin packing con tamaños distintos, presupuestos, cargas en horas, pesos, costos acumulados. Solo funciona si todos los ítems pesan igual.

### Los umbrales se pierden en nppq

Una restricción nppq sobre una comparación mayor toma el operando izquierdo y descarta el derecho. En `(op-mayor consulta 12)` el 12 desaparece y la restricción penaliza siempre, incluso con conteo 1. Solo funciona la comparación contra cero.

Un umbral distinto de cero hay que escribirlo como tqpq cuantificado, y eso exige que el umbral viva como atributo de la entidad sobre la que se cuantifica. Un umbral global suelto no tiene dónde declararse.

### No hay aritmética sobre lo decidido

Se puede hacer aritmética sobre datos fijos, como `orden(b1) + 1 = orden(b2)`. No se puede calcular con lo que el modelo decide.

No se puede resolver: precedencias, tiempos de inicio calculados, duraciones acumuladas, tiempos de viaje, ventanas temporales, job-shop, cualquier planificación con secuencia real.

El dominio de televisión lo evidencia. La descripción dice que cada bloque empieza cuando termina el anterior. El DSL no lo expresa, por eso el bloque se declara con día y orden en vez de hora de inicio.

### No hay restricciones globales

Faltan alldifferent, cardinalidad, circuito y acumulativo. El nodo `hay-elementos-duplicados` está declarado en el AST, pero ningún dominio lo usa y no tiene traducción, así que hoy no es utilizable.

No se puede resolver: permutaciones, rutas, secuenciación, asignación uno a uno garantizada. En televisión nada impide que el mismo programa ocupe dos bloques.

### Toda identidad recibe valor

No existe la decisión opcional ni la selección parcial.

No se puede resolver: elegir k de n, selección de cartera, cobertura de conjuntos, ni ningún problema donde no asignar sea una opción válida.

### Un solo nivel de agregación

No hay conteo de conteos, ni promedio, ni desviación, ni dispersión.

Por eso la compacidad del horario de cada grupo, que el capítulo 3 pide como restricción blanda del dominio docente, no está implementada.

### `contar-distintos-dias` está cableada

La operación busca literalmente un atributo llamado `fecha` o `dia`. Contar valores distintos de cualquier otra dimensión no funciona, aunque sea la misma operación.

### El objetivo es plano

Todas las restricciones blandas comparten un único `PESO_BLANDA`. No se puede declarar que un criterio vale el triple que otro sin duplicar restricciones.

## Limitaciones por rendimiento

Cada consulta se compila a bucles anidados, uno por dominio iterado, y se evalúa entera para cada individuo en cada generación.

La consulta de conflictos en el dominio de tesis itera profesor por asignación por asignación: 35 × 13 × 13, unas seis mil vueltas por evaluación, por cien individuos, por quinientas generaciones.

La consulta de colisiones de profesor en el dominio docente itera profesor por clase por clase: 6 × 65 × 65, unas veinticinco mil vueltas por evaluación.

El costo crece como el producto de los dominios iterados. Las restricciones de choque comparan dos filas del horario, así que son cuadráticas en el tamaño del horario por naturaleza. Añadir un dominio iterado multiplica.

El punto de ruptura está en el número de filas del horario, no en el tamaño de los pools. Duplicar los locales apenas cuesta. Duplicar las clases multiplica por cuatro cada evaluación. El horario de una facultad completa, con los cinco años en vez de uno solo, pasa de sesenta y cinco filas a varios cientos: ahí el generador deja de ser usable mucho antes de que el lenguaje se quede sin expresividad.
