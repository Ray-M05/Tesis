# Descripción del problema

## Entidades

Un aula tiene nombre.

Un día tiene nombre.

Un grado tiene nombre.

Un profesor tiene nombre, y dice si vive lejos del centro y si es contratado.

Un turno tiene nombre y orden.

Una asignatura tiene nombre y día de preparación, y dice si es educación física.

Un grupo tiene nombre y grado.

Un plan tiene grupo, asignatura, profesor, aula y frecuencia, y dice si admite turno doble y si admite turnos de tarde.

Una sesión tiene plan y número.

Una ausencia tiene profesor y día.

Una jornada tiene profesor, día y tope.

Una ubicación está formada por una sesión, un día y un turno.

## Datos

Hay doce aulas.

Hay cinco días: Lunes, Martes, Miércoles, Jueves y Viernes.

Hay tres grados: 10mo grado, 11no grado y 12mo grado.

Hay 26 profesores.

Hay siete turnos: T1, T2, T3, T4, T5, T6 y T7.

Hay trece asignaturas.

Hay nueve grupos: 10-1, 10-2, 10-3, 11-1, 11-2, 11-3, 12-1, 12-2 y 12-3.

Hay 102 planes.

Hay 297 sesiones.

Hay seis ausencias: (profesor profesor_P, día Martes), (profesor profesor_P, día Jueves), (profesor profesor_U, día Lunes), (profesor profesor_U, día Viernes), (profesor profesor_V, día Lunes) y (profesor profesor_V, día Jueves).

Hay 130 jornadas.

## Qué se decide

Cada fila del horario es una ubicación. Se decide, para cada sesión, qué día y qué turno le corresponden.

## Qué se mide

**Colisiones de grupo.** Se cuenta el número de pares de ubicaciones distintas del mismo grupo con el mismo día y el mismo turno.

**Colisiones de profesor.** Se cuenta el número de pares de ubicaciones distintas del mismo profesor con el mismo día y el mismo turno.

**Repeticiones en el día.** Se cuenta el número de pares de ubicaciones distintas del mismo plan con el mismo día, cuando el plan no admite turno doble.

**Dobles no consecutivos.** Se cuenta el número de pares de ubicaciones del mismo plan con el mismo día en turnos no consecutivos, cuando el plan admite turno doble.

**Sesiones en día de preparación.** Se cuenta el número de ubicaciones en que su día es igual al día de preparación de su asignatura.

**Educación física fuera de horario.** Se cuenta el número de ubicaciones en que su asignatura es educación física y el orden de su turno es mayor que 3.

**Sesiones de tarde no autorizadas.** Se cuenta el número de ubicaciones en que su plan no admite turnos de tarde y el orden de su turno es mayor que 5.

**Sesiones en día sin asistencia.** Se cuenta el número de ubicaciones que coinciden con una ausencia en el profesor y el día.

**Primeros turnos de lejanos.** Se cuenta el número de ubicaciones en que su profesor vive lejos del centro y el orden de su turno es igual a 1.

## Restricciones

### Obligatorias

**Restricción una sesión por grupo.** No puede haber dos ubicaciones distintas del mismo grupo con el mismo día y el mismo turno.

**Restricción una sesión por profesor.** No puede haber dos ubicaciones distintas del mismo profesor con el mismo día y el mismo turno.

**Restricción sin repetir asignatura en el día.** No puede haber dos ubicaciones distintas del mismo plan con el mismo día, cuando el plan no admite turno doble.

**Restricción turno doble consecutivo.** No puede haber dos ubicaciones del mismo plan con el mismo día en turnos no consecutivos, cuando el plan admite turno doble.

**Restricción sin clases el día de preparación.** Ninguna ubicación puede cumplir lo siguiente: su día es igual al día de preparación de su asignatura.

**Restricción educación física temprano.** Ninguna ubicación puede cumplir lo siguiente: su asignatura es educación física y el orden de su turno es mayor que 3.

**Restricción tarde solo para las autorizadas.** Ninguna ubicación puede cumplir lo siguiente: su plan no admite turnos de tarde y el orden de su turno es mayor que 5.

**Restricción contratado solo sus días.** Ninguna ubicación puede coincidir con una ausencia en el profesor y el día.

**Restricción frecuencia exacta.** El número de ubicaciones de cada plan debe ser igual a su frecuencia.

### Preferencias

**Restricción evitar primer turno a los lejanos.** Ninguna ubicación puede cumplir lo siguiente: su profesor vive lejos del centro y el orden de su turno es igual a 1.

**Restricción tope diario de profesor.** El número de ubicaciones de cada jornada no puede superar su tope.

