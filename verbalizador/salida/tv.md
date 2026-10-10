# Descripción del problema

## Entidades

Un canal tiene nombre.

Un día tiene nombre.

Un tipo de programa tiene código.

Un bloque tiene día y orden.

Un programa tiene nombre, tipo, duración y canal.

Una emisión está formada por un bloque y un programa.

## Datos

Hay un canal: Canal Habana.

Hay siete días: Lunes, Martes, Miercoles, Jueves, Viernes, Sabado y Domingo.

Hay seis tipos de programa: informativo, musical, infantil, revista, cine y deportes.

Hay 56 bloques.

Hay ocho programas: El Tiempo y la Memoria, Coordenadas, Revista Hola Habana, Decadas Milagrosas, Habana Noticiario, Power Rangers, Cine+ y Deporte Total.

## Qué se decide

Cada fila del horario es una emisión. Se decide, para cada bloque, qué programa le corresponde.

## Qué se mide

**Adyacentes mismo tipo.** Se cuenta el número de pares de emisiones consecutivas del mismo día con el mismo tipo y el mismo canal.

**Consecutivos por canal.** Se cuenta el número de pares de emisiones consecutivas del mismo día con el mismo tipo y el mismo canal.

## Restricciones

### Obligatorias

**Restricción sin mismo tipo consecutivo.** No puede haber dos emisiones consecutivas del mismo día con el mismo tipo y el mismo canal.

### Preferencias

**Restricción minimizar repetición de tipo.** Se prefiere la solución que minimiza, para el canal más afectado, el número de pares de emisiones consecutivas del mismo día con el mismo tipo y el mismo canal.

