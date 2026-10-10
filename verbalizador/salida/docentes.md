# Descripción del problema

## Entidades

Una asignatura tiene nombre y frecuencia.

Un aula tiene nombre.

Un día tiene nombre.

Un grupo tiene nombre.

Un profesor tiene nombre.

Un turno tiene nombre.

Una sesión tiene asignatura, grupo y profesor.

Una clase está formada por una sesión, un aula, un día y un turno.

## Datos

Hay diez asignaturas: Filosofia C, Algebra I C, Analisis Matematico I C, Programacion C, Logica C, Educacion Fisica I, Algebra I CP, Analisis Matematico I CP, Programacion CP y Logica CP.

Hay seis aulas: Aula 1, Aula 2, Aula 5, Aula 6, Laboratorio de Computacion y SEDER.

Hay cinco días: Lunes, Martes, Miercoles, Jueves y Viernes.

Hay cinco grupos: C111, C112, C113, C121 y C122.

Hay seis profesores: Ana Garcia Fernandez, Luis Lopez Rodriguez, Maria Martinez Perez, Carlos Hernandez Diaz, Rosa Gonzalez Blanco y Miguel Diaz Morales.

Hay seis turnos: T1, T2, T3, T4, T5 y T6.

Hay 70 sesiones.

## Qué se decide

Cada fila del horario es una clase. Se decide, para cada sesión, qué aula, qué día y qué turno le corresponden.

## Qué se mide

**Colisiones de profesor.** Se cuenta el número de pares de clases de aulas distintas del mismo profesor con el mismo día y el mismo turno.

**Colisiones de aula.** Se cuenta el número de pares de clases de grupos distintos con la misma aula, el mismo día y el mismo turno.

**Colisiones de grupo.** Se cuenta el número de pares de clases de aulas distintas del mismo grupo con el mismo día y el mismo turno.

**Días de profesor.** Se cuenta el número de días distintos en los que interviene.

## Restricciones

### Obligatorias

**Restricción un aula por profesor.** No puede haber dos clases de aulas distintas del mismo profesor con el mismo día y el mismo turno.

**Restricción un grupo por aula.** No puede haber dos clases de grupos distintos con la misma aula, el mismo día y el mismo turno.

**Restricción una clase por grupo.** No puede haber dos clases de aulas distintas del mismo grupo con el mismo día y el mismo turno.

### Preferencias

**Restricción minimizar días de viaje.** Se prefiere la solución que minimiza, para el profesor más cargado, el número de días distintos en los que interviene.

