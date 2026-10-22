# Descripción del problema

## Entidades

Una carrera tiene nombre.

Una instalación tiene nombre y capacidad.

Un profesor tiene nombre.

Un turno tiene nombre y orden.

Un año tiene nombre, carrera y paridad.

Una brigada tiene nombre, año, profesor y cantidad.

Una indisponibilidad tiene año y turno.

Una ubicación está formada por una brigada, un turno y una instalación.

## Datos

Hay seis carreras: Matemática, Computación, Física, Química, Biología y Geografía.

Hay ocho instalaciones: Terreno de fútbol, Terreno de béisbol, Pista de atletismo, Gimnasio, Cancha de baloncesto, Cancha de voleibol, Piscina y Sala de pesas.

Hay doce profesores.

Hay tres turnos: 10:00, 11:00 y 15:00.

Hay doce años.

Hay 24 brigadas.

Hay once indisponibilidades.

## Qué se decide

Cada fila del horario es una ubicación. Se decide, para cada brigada, qué turno y qué instalación le corresponden.

## Qué se mide

**Clases en turno no disponible.** Se cuenta el número de ubicaciones que coinciden con una indisponibilidad en el año y el turno.

**Brigadas que no caben.** Se cuenta el número de ubicaciones en que la cantidad de su brigada es mayor que la capacidad de su instalación.

**Colisiones de instalación.** Se cuenta el número de pares de ubicaciones distintas de la misma paridad con la misma instalación y el mismo turno.

**Colisiones de profesor.** Se cuenta el número de pares de ubicaciones distintas de la misma paridad del mismo profesor con el mismo turno.

**Brigadas de la instalación.** Se cuenta el número de brigadas que caen en una misma instalación.

**Brigadas del turno.** Se cuenta el número de brigadas que caen en un mismo turno.

## Restricciones

### Obligatorias

**Restricción solo turnos disponibles.** Ninguna ubicación puede coincidir con una indisponibilidad en el año y el turno.

**Restricción la brigada cabe.** Ninguna ubicación puede cumplir lo siguiente: la cantidad de su brigada es mayor que la capacidad de su instalación.

**Restricción una brigada por instalación.** No puede haber dos ubicaciones distintas de la misma paridad con la misma instalación y el mismo turno.

**Restricción un profesor por turno.** No puede haber dos ubicaciones distintas de la misma paridad del mismo profesor con el mismo turno.

### Preferencias

**Restricción equilibrar instalaciones.** Se prefiere el reparto que reduce el número máximo de brigadas en una misma instalación.

**Restricción equilibrar turnos.** Se prefiere el reparto que reduce el número máximo de brigadas en un mismo turno.

