(in-package :pruebas-estrategias)

;; El dominio pequeño no puede llegar a blandas 0, así que solo para por el máximo de
;; generaciones o por tiempo. El genético no para por estancamiento.
(comprobar-estrategias
 (modelo-pequeno) (list (make-instance 'genetico))
 "
for inicio in ('voraz', 'permitidos', 'aleatorio'):
    a = correr('genetico', '--semilla', 3, '--inicio', inicio, '--generaciones', 40, '--poblacion', 20)
    b = correr('genetico', '--semilla', 3, '--inicio', inicio, '--generaciones', 40, '--poblacion', 20)
    assert sin_tiempo(a) == sin_tiempo(b), inicio
    assert a['duras'] == 0 and a['blandas'] == 4, a
    assert a['evaluaciones'] <= a['individuos'], a
assert (sin_tiempo(correr('genetico', '--semilla', 4, '--generaciones', 20))
        != sin_tiempo(correr('genetico', '--semilla', 5, '--generaciones', 20)))

corrida = correr('genetico', '--semilla', 0)
assert corrida['motivo_de_parada'] == 'maximo' and corrida['iteraciones'] == 500, corrida
corrida = correr('genetico', '--semilla', 0, '--generaciones', 20)
assert corrida['motivo_de_parada'] == 'maximo' and corrida['iteraciones'] == 20, corrida
assert correr('genetico', '--semilla', 0, '--estancamiento', 10).returncode != 0
corrida = correr('genetico', '--semilla', 0, '--tiempo', 0)
assert corrida['motivo_de_parada'] == 'tiempo' and corrida['iteraciones'] == 0, corrida
assert corrida['argumentos'] == {'semilla': 0, 'inicio': 'voraz', 'penalizacion': 1000,
                                 'tiempo': 0, 'torneo': 5, 'radio': 2, 'intercambio': 0.3, 'poblacion': 100,
                                 'generaciones': 500, 'cruce': 0.8, 'mutacion': 0.15}, corrida['argumentos']
for semilla in range(8):
    corrida = correr('genetico', '--semilla', semilla, '--inicio', 'permitidos', '--poblacion', 1, '--generaciones', 0)
    assert corrida['motivo_de_parada'] == 'maximo' and corrida['valores']['r_martes'] == 0, corrida
assert corrida['sin_opciones_permitidas'] == []
assert [fila['dia'] for fila in corrida['horario']] == [['Lunes', 'Martes', 'Jueves'][p[0]] for p in corrida['posiciones']]
")

;; Los dominios reales pequeños llegan a 0 duras. Con 100 generaciones basta, y las 500 por
;; defecto tardarían medio minuto en tesis.
(dolist (dominio '("tv" "tesis" "seder"))
  (comprobar-estrategias
   (modelo-del-dominio dominio) (list (make-instance 'genetico))
   "
corrida = correr('genetico', '--semilla', 0, '--generaciones', 100)
assert corrida['duras'] == 0, corrida['valores']
assert corrida['evaluaciones'] <= corrida['individuos']
"))

;; Los valores por defecto salen de los slots.
(let ((programa (programa-de (make-instance 'genetico :poblacion 7 :inicio "aleatorio"
                                            :mutaciones (list (make-instance 'estrategias::mover-filas
                                                                             :radio 3)))
                             (modelo-pequeno))))
  (assert (search "'--poblacion', type=int, default=7," programa))
  (assert (search "'--inicio', type=str, default=\"aleatorio\"," programa))
  (assert (search "'--radio', type=int, default=3," programa))
  (assert (not (search "intercambio" programa))))

;; Cada operador hace lo que dice, y el bucle los usa con sus probabilidades.
(comprobar-estrategias
 (modelo-pequeno) (list (make-instance 'genetico))
 "
import random
from argparse import Namespace
import genetico as g

azar = random.Random(1)
args = Namespace(radio=2, intercambio=0.3, torneo=5, poblacion=20, generaciones=30, cruce=0.8,
                 mutacion=0.15, inicio='aleatorio', tiempo=None)
a = [(0, 0), (0, 1), (2, 0), (2, 1)]
b = [(1, 1), (1, 0), (1, 1), (1, 0)]

cortes = set()
for _ in range(100):
    x, y = g.cruce_un_punto(azar, a, b, args)
    corte = next(i for i in range(4) if x[i] != a[i])
    assert x == a[:corte] + b[corte:] and y == b[:corte] + a[corte:]
    cortes.add(corte)
assert cortes == {1, 2, 3}

dos = 0
for _ in range(4000):
    m = g.mover_filas(azar, a, args)
    distintas = [i for i in range(4) if m[i] != a[i]]
    assert len(distintas) <= 2 and len(m) == 4
    assert all(sum(u != v for u, v in zip(m[i], a[i])) == 1 for i in distintas)
    dos += len(distintas) == 2
assert 0.1 < dos / 4000 < 0.25, dos

for _ in range(50):
    m = g.intercambio(azar, a, args)
    assert sum(m[i] != a[i] for i in range(4)) == 2 and sorted(m) == sorted(a)

intercambios = sum(sorted(m) == sorted(a) and m != a for m in (g.mutar(azar, a, args) for _ in range(4000)))
assert 0.25 < intercambios / 4000 < 0.35, intercambios

evaluador = g.Evaluador(1000)
poblacion = [g.Individuo(p) for p in g.inicio_aleatorio(azar, 10, None)]
assert g.torneo(azar, poblacion, evaluador, Namespace(torneo=10)) is min(poblacion, key=evaluador.costo)

cuentas = {'torneo': 0, 'cruce': 0, 'mutar': 0}
def contar(nombre, funcion):
    def contada(*argumentos):
        cuentas[nombre] += 1
        return funcion(*argumentos)
    return contada
g.torneo = contar('torneo', g.torneo)
g.cruce_un_punto = contar('cruce', g.cruce_un_punto)
g.mutar = contar('mutar', g.mutar)
mejor, generaciones, motivo = g.buscar(args, azar, evaluador, g.Parada_Por_Limite(args.generaciones, args),
                                       [g.OPCIONES] * 4)
assert (generaciones, motivo) == (30, 'maximo')
assert 0.75 < cuentas['cruce'] / (cuentas['torneo'] / 2) < 0.85, cuentas
assert 0.12 < cuentas['mutar'] / cuentas['torneo'] < 0.18, cuentas
")
