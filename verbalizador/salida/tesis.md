# Descripción del problema

## Entidades

Un estudiante tiene nombre.

Una fecha tiene día y mes.

Un grado tiene id.

Un local tiene nombre.

Un momento tiene hora.

Un profesor tiene nombre y grado.

Un tribunal tiene estudiante, tutor, oponente, presidente, vocal y secretario.

Una asignación está formada por un tribunal, una fecha, un momento y un local.

## Datos

Hay trece estudiantes.

Hay tres fechas: (día 5, mes 6), (día 8, mes 6) y (día 10, mes 6).

Hay seis grados: Lic, MSc, Dr, Dra, DrC y DraC.

Hay cuatro locales: Postgrado, Salon decanato, Francofonia y Francofomia.

Hay siete momentos: 930, 1000, 1030, 1130, 1200, 1230 y 1330.

Hay 35 profesores.

Hay trece tribunales.

## Qué se decide

Cada fila del horario es una asignación. Se decide, para cada tribunal, qué fecha, qué momento y qué local le corresponden.

## Qué se mide

**Conflictos de horario.** Se cuenta el número de pares de asignaciones distintas que compartan un profesor con la misma fecha y el mismo momento.

**Colisiones de local.** Se cuenta el número de pares de asignaciones distintas con el mismo local, la misma fecha y el mismo momento.

**Días asistidos.** Se cuenta el número de días distintos en los que interviene.

## Restricciones

### Obligatorias

**Restricción sin conflictos de horario.** No puede haber dos asignaciones distintas que compartan un profesor con la misma fecha y el mismo momento.

**Restricción un local por defensa.** No puede haber dos asignaciones distintas con el mismo local, la misma fecha y el mismo momento.

### Preferencias

**Restricción minimizar carga máxima.** Se prefiere la solución que minimiza, para el profesor más cargado, el número de días distintos en los que interviene.

