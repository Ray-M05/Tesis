(in-package :pruebas-estrategias)

(comprobar-estrategias
 (modelo-pequeno) (list (make-instance 'busqueda-local))
 "
for inicio in ('voraz', 'permitidos', 'aleatorio'):
    a = correr('busqueda_local', '--semilla', 3, '--inicio', inicio, '--pasos', 300)
    b = correr('busqueda_local', '--semilla', 3, '--inicio', inicio, '--pasos', 300)
    assert sin_tiempo(a) == sin_tiempo(b), inicio
    assert a['duras'] == 0 and a['blandas'] == 4, a
    assert a['evaluaciones'] <= a['individuos'], a
assert (correr('busqueda_local', '--semilla', 4, '--inicio', 'aleatorio', '--pasos', 1)['posiciones']
        != correr('busqueda_local', '--semilla', 5, '--inicio', 'aleatorio', '--pasos', 1)['posiciones'])

corrida = correr('busqueda_local', '--semilla', 0)
assert corrida['motivo_de_parada'] == 'estancamiento' and corrida['iteraciones'] < 100000, corrida
corrida = correr('busqueda_local', '--semilla', 0, '--estancamiento', 10 ** 6, '--pasos', 50)
assert corrida['motivo_de_parada'] == 'maximo' and corrida['iteraciones'] == 50, corrida
corrida = correr('busqueda_local', '--semilla', 0, '--tiempo', 0)
assert corrida['motivo_de_parada'] == 'tiempo' and corrida['iteraciones'] == 0, corrida
assert corrida['argumentos'] == {'semilla': 0, 'inicio': 'voraz', 'penalizacion': 1000, 'estancamiento': 2000,
                                 'tiempo': 0, 'ruido': 0, 'pasos': 100000}, corrida['argumentos']

# Con todo ruido el actual vaga, pero se devuelve el mejor visto: el voraz ya no tenía duras.
for semilla in range(5):
    corrida = correr('busqueda_local', '--semilla', semilla, '--ruido', 1, '--pasos', 200)
    assert corrida['duras'] == 0, corrida
")

;; El paso: cambia una fila como mucho, a una opción permitida, y sin ruido nunca empeora.
(comprobar-estrategias
 (modelo-pequeno) (list (make-instance 'busqueda-local))
 "
import random
from argparse import Namespace
import busqueda_local as b

azar = random.Random(2)
evaluador = b.Evaluador(1000)
opciones = [p or b.OPCIONES for p in b.opciones_permitidas()]
for ruido, puede_empeorar in ((0, False), (1, True)):
    args = Namespace(ruido=ruido)
    empeoro = False
    for _ in range(300):
        actual = b.Individuo(b.inicio_aleatorio(azar, 1, opciones)[0])
        siguiente = b.mejor_opcion_de_fila(azar, actual, evaluador, opciones, args)
        distintas = [i for i in range(4) if siguiente.posiciones[i] != actual.posiciones[i]]
        assert len(distintas) <= 1
        assert all(siguiente.posiciones[i] in opciones[i] for i in distintas)
        empeoro |= evaluador.costo(siguiente) > evaluador.costo(actual)
    assert empeoro == puede_empeorar, ruido
assert evaluador.evaluaciones <= b.Individuo.creados
")

(dolist (dominio '("tv" "tesis" "seder"))
  (comprobar-estrategias
   (modelo-del-dominio dominio) (list (make-instance 'busqueda-local))
   "
corrida = correr('busqueda_local', '--semilla', 0, '--estancamiento', 200)
assert corrida['duras'] == 0, corrida['valores']
"))

;; Añadir la búsqueda local no cambia el genético: su programa no menciona nada de ella.
(let ((programa (programa-de (make-instance 'genetico) (modelo-pequeno))))
  (assert (not (search "ruido" programa)))
  (assert (not (search "estancamiento" programa)))
  (assert (not (search "mejor_opcion_de_fila" programa))))
