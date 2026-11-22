(in-package :pruebas-estrategias)

;; Cuatro celdas para cuatro sesiones: sin choques, dos quedan en el primer turno.
(comprobar-estrategias
 (modelo-pequeno) (list (make-instance 'goloso))
 "
assert correr('goloso').returncode != 0
assert correr('goloso', '--semilla', 0, '--penalizacion', 10).returncode != 0
a = correr('goloso', '--semilla', 3)
b = correr('goloso', '--semilla', 3)
assert sin_tiempo(a) == sin_tiempo(b)
assert a['duras'] == 0 and a['blandas'] == 4 and a['filas_forzadas'] == [], a
assert a['argumentos'] == {'semilla': 3}, a['argumentos']
assert a['iteraciones'] == 4 and a['evaluaciones'] == 1
assert 'costo' not in a and 'motivo_de_parada' not in a
")

;; El daño de cada restricción es lo que sube al poner la fila, calculado con todas las filas
;; puestas. Se comprueba paso a paso en las primeras filas, y en total con todas.
(dolist (modelo (cons (modelo-pequeno)
                      (mapcar #'modelo-del-dominio '("tv" "tesis" "docentes" "seder" "saul"))))
  (comprobar-estrategias
   modelo (list (make-instance 'goloso))
   "
import random
import goloso as g
import modelo

azar = random.Random(0)
dano = g.Dano_Por_Tablas()
filas = [modelo.crear_fila(i, azar.choice(g.OPCIONES)) for i in range(g.FILAS)]
azar.shuffle(filas)
totales = {viva[0]: viva[2]([]) for viva in dano.vivas}
puestas = []
for n, fila in enumerate(filas):
    for viva in dano.vivas:
        cambio = dano.cambio(viva, fila)
        if n < 60:
            assert cambio == viva[2](puestas + [fila]) - viva[2](puestas), (viva[0], n)
        totales[viva[0]] += cambio
    dano.poner(fila)
    puestas.append(fila)
for nombre, _, funcion, _ in dano.vivas:
    assert totales[nombre] == funcion(puestas), nombre
"))

(dolist (dominio '("tv" "tesis" "docentes" "seder"))
  (comprobar-estrategias
   (modelo-del-dominio dominio) (list (make-instance 'goloso))
   "
corrida = correr('goloso', '--semilla', 0)
assert corrida['duras'] == 0, corrida['valores']
"))

;; En Saúl todas las filas tienen celdas permitidas, así que ninguna restricción de una fila se
;; incumple, y todas las restricciones vivas tienen ocupaciones.
(comprobar-estrategias
 (modelo-del-dominio "saul") (list (make-instance 'goloso))
 "
import modelo
corrida = correr('goloso', '--semilla', 0)
assert corrida['sin_opciones_permitidas'] == []
assert all(corrida['valores'][nombre] == 0 for nombre in modelo.DE_UNA_FILA), corrida['valores']
assert len(corrida['filas_forzadas']) <= corrida['duras']
assert set(modelo.OCUPACIONES) == {nombre for nombre, _, _ in modelo.RESTRICCIONES
                                   if nombre not in modelo.CONSTANTES}
")

;; Añadir el goloso no cambia las estrategias de búsqueda, y el goloso no trae nada de ellas.
(let ((genetico (programa-de (make-instance 'genetico) (modelo-pequeno)))
      (goloso (programa-de (make-instance 'goloso) (modelo-pequeno))))
  (assert (not (search "Dano_Por_Tablas" genetico)))
  (dolist (texto '("penalizacion" "Evaluador" "Individuo" "INICIOS" "parada"))
    (assert (not (search texto goloso)) () "el goloso menciona ~a" texto)))
