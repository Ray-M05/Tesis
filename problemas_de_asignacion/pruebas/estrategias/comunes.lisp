(in-package :pruebas-estrategias)

;; Las posiciones son [día, turno], con día 0 lunes, 1 martes y 2 jueves.
(comprobar-estrategias
 (modelo-pequeno) (list (make-instance 'genetico))
 "
import random
import genetico as g
import modelo

assert correr('genetico').returncode != 0

permitidas = g.opciones_permitidas()
assert all(sorted(p) == [(0, 0), (0, 1), (2, 0), (2, 1)] for p in permitidas), permitidas
opciones = [p or g.OPCIONES for p in permitidas]

def duras(posiciones):
    return g.Evaluador(1000).valor(g.Individuo(posiciones))[1]

azar = random.Random(0)
permitidos = g.inicio_permitido(azar, 30, opciones)
assert len(permitidos) == 30
assert all(modelo.r_martes(modelo.crear_horario(p)) == 0 for p in permitidos)
aleatorios = g.inicio_aleatorio(azar, 30, opciones)
assert len(aleatorios) == 30 and all(len(p) == 4 for p in aleatorios)
assert any(modelo.r_martes(modelo.crear_horario(p)) > 0 for p in aleatorios)
for semilla in range(10):
    voraces = g.inicio_voraz(random.Random(semilla), 5, opciones)
    assert len(voraces) == 5 and duras(voraces[0]) == 0
    assert all(modelo.r_martes(modelo.crear_horario(p)) == 0 for p in voraces[1:])

# El costo: penalización por duras más peso por blandas. La constante r_todas se evalúa una vez.
llamadas = []
def contada(horario, funcion=modelo.r_todas):
    llamadas.append(1)
    return funcion(horario)
modelo.RESTRICCIONES = [(n, p, contada if n == 'r_todas' else f) for n, p, f in modelo.RESTRICCIONES]
evaluador = g.Evaluador(10)
juntas = g.Individuo([(1, 0), (1, 0), (0, 0), (2, 1)])
assert evaluador.valor(juntas) == (10 * (1 + 2) + 2 * 3, 3, 6)
assert evaluador.valor(juntas) == (36, 3, 6)
for _ in range(4):
    evaluador.valor(g.Individuo([(0, 1), (0, 0), (2, 0), (2, 1)]))
assert evaluador.evaluaciones == 5
assert len(llamadas) == 1
")

(let ((programa (programa-de (make-instance 'genetico) (modelo-pequeno))))
  (assert (not (search "copy" programa))))

;; El voraz solo, sin el genético, ya da un horario sin duras en el SEDER.
(comprobar-estrategias
 (modelo-del-dominio "seder") (list (make-instance 'genetico))
 "
import random
import genetico as g
opciones = [p or g.OPCIONES for p in g.opciones_permitidas()]
for semilla in range(3):
    voraz = g.inicio_voraz(random.Random(semilla), 1, opciones)[0]
    assert g.Evaluador(1000).valor(g.Individuo(voraz))[1] == 0, semilla
")
