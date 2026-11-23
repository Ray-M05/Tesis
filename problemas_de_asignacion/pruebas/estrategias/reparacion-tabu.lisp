(in-package :pruebas-estrategias)

;; Se mueven filas al azar. Lo que sale y lo que entra en cada restricción es lo que cambia su valor
;; con todas las filas, propio es la suma de lo que sale, y una fila que no es vecina de la que se
;; mueve, ni antes ni después, no cambia lo que bajaría al quitarla.
(dolist (modelo (cons (modelo-pequeno)
                      (mapcar #'modelo-del-dominio '("tv" "tesis" "docentes" "seder" "saul"))))
  (comprobar-estrategias
   modelo (list (make-instance 'reparacion-tabu))
   "
import random
import reparacion_tabu as r
import modelo

azar = random.Random(0)
dano = r.Dano_Reversible()
filas = [modelo.crear_fila(i, azar.choice(r.OPCIONES)) for i in range(r.FILAS)]
for fila in filas:
    dano.poner(fila)
valores = {viva[0]: viva[2](filas) for viva in dano.vivas}

def propios():
    resultado = []
    for fila in filas:
        dano.quitar(fila)
        resultado.append([dano.cambio(viva, fila) for viva in dano.vivas if viva[3]])
        dano.poner(fila)
    return resultado

for n in range(100):
    i = azar.randrange(r.FILAS)
    vieja, nueva = filas[i], modelo.crear_fila(i, azar.choice(r.OPCIONES))
    antes = propios() if n < 10 else None
    vecinas = dano.vecinas(vieja)
    propio = dano.propio(vieja)
    dano.quitar(vieja)
    sin = filas[:i] + filas[i + 1:]
    salen = {}
    for viva in dano.vivas:
        salen[viva[0]] = dano.cambio(viva, vieja)
        assert salen[viva[0]] == valores[viva[0]] - viva[2](sin), (viva[0], n)
        valores[viva[0]] -= salen[viva[0]]
    assert propio == (sum(salen[nombre] for nombre, peso, _, _ in dano.vivas if peso is None),
                      sum(peso * salen[nombre] for nombre, peso, _, _ in dano.vivas if peso is not None)), n
    for viva in dano.vivas:
        entra = dano.cambio(viva, nueva)
        assert entra == viva[2](sin + [nueva]) - viva[2](sin), (viva[0], n)
        valores[viva[0]] += entra
    dano.poner(nueva)
    filas[i] = nueva
    assert all(valores[viva[0]] == viva[2](filas) for viva in dano.vivas), n
    if antes is not None:
        vecinas |= dano.vecinas(nueva)
        afectadas = {i} | {j for j, fila in enumerate(filas) if fila in vecinas}
        despues = propios()
        assert {j for j in range(r.FILAS) if antes[j] != despues[j]} <= afectadas, n
"))

;; El certificado: en Saúl caben todas las claves, y los grupos de 10mo y el profesor W no tienen
;; holgura. Docentes y tv no tienen claves.
(comprobar-estrategias
 (modelo-del-dominio "saul") (list (make-instance 'reparacion-tabu))
 "
import reparacion_tabu as r
import modelo
holguras = r.certificar([p or r.OPCIONES for p in r.opciones_permitidas()])
assert len(modelo.CLAVES) == 3
assert all(holgura >= 0 for _, holgura in holguras.values())
justas = {(nombre, tuple(map(str, clave))) for (nombre, clave), (_, holgura) in holguras.items() if holgura == 0}
for grupo in ('10-1', '10-2', '10-3'):
    assert ('restriccion_una_sesion_por_grupo', (grupo,)) in justas, grupo
assert ('restriccion_una_sesion_por_profesor', ('profesor_W', 'profesor_W')) in justas
")

(loop for (dominio claves) in '(("tv" 0) ("tesis" 2) ("docentes" 0) ("seder" 2))
      do (comprobar-estrategias
          (modelo-del-dominio dominio) (list (make-instance 'reparacion-tabu))
          (format nil "
import reparacion_tabu as r
import modelo
assert len(modelo.CLAVES) == ~d, modelo.CLAVES
holguras = r.certificar([p or r.OPCIONES for p in r.opciones_permitidas()])
assert all(holgura >= 0 for _, holgura in holguras.values())
assert bool(holguras) == bool(modelo.CLAVES)
" claves)))

;; Cinco sesiones para cuatro celdas: no cabe, y la corrida termina tras construir.
(comprobar-estrategias
 (modelo-de (format nil "~a(def-sesion s5 luis 3)~%" *pequeno*)
            '("r-choque" "r-martes" "r-todas" "r-temprano"))
 (list (make-instance 'reparacion-tabu))
 "
corrida = correr('reparacion_tabu', '--semilla', 0)
assert corrida['motivo_de_parada'] == 'infactible', corrida['motivo_de_parada']
assert corrida['arranques'] == 1 and corrida['iteraciones'] == 0
assert [(c['restriccion'], c['clave'], c['filas'], c['holgura']) for c in corrida['certificado']] == [('r_choque', [], 5, -1)], corrida['certificado']
")

;; Cuatro celdas para cuatro sesiones: dos quedan en el primer turno, así que (0, 0) no se alcanza
;; y hace todos los arranques.
(comprobar-estrategias
 (modelo-pequeno) (list (make-instance 'reparacion-tabu))
 "
assert correr('reparacion_tabu').returncode != 0
for extra in (['--penalizacion', 10], ['--inicio', 'voraz'], ['--tiempo', 5]):
    assert correr('reparacion_tabu', '--semilla', 0, *extra).returncode != 0, extra

def sin_segundos(corrida):
    corrida = sin_tiempo(corrida)
    corrida['mejoras'] = [{clave: valor for clave, valor in mejora.items() if clave != 'segundos'}
                          for mejora in corrida['mejoras']]
    return corrida

a = correr('reparacion_tabu', '--semilla', 3)
b = correr('reparacion_tabu', '--semilla', 3)
assert sin_segundos(a) == sin_segundos(b)
assert a['argumentos'] == {'semilla': 3, 'tabu': 10, 'permuta': 0.25, 'arranques': 10,
                           'estancamiento': None, 'pulido': None}, a['argumentos']
for campo in ('costo', 'inicio', 'individuos', 'filas_forzadas'):
    assert campo not in a, campo
assert a['motivo_de_parada'] == 'maximo' and a['arranques'] == 10
assert a['evaluaciones'] == a['arranques'] + 1
assert a['duras'] == 0 and a['blandas'] == 4, a
assert (a['mejoras'][-1]['duras'], a['mejoras'][-1]['blandas']) == (a['duras'], a['blandas'])
assert a['certificado'] == [{'restriccion': 'r_choque', 'clave': [], 'filas': 4, 'holgura': 0}], a['certificado']
")

;; El (duras, blandas) que se lleva paso a paso es el de evaluar al terminar cada fase, y el mejor
;; horario guardado vale lo que dice.
(dolist (modelo (cons (modelo-pequeno)
                      (mapcar #'modelo-del-dominio '("tv" "tesis" "docentes" "seder" "saul"))))
  (comprobar-estrategias
   modelo (list (make-instance 'reparacion-tabu))
   "
import argparse
import random
import time
import reparacion_tabu as r
import modelo

def valor(filas):
    valores = modelo.evaluar(filas)
    return (sum(valores[nombre] for nombre, peso, _ in modelo.RESTRICCIONES if peso is None),
            sum(peso * valores[nombre] for nombre, peso, _ in modelo.RESTRICCIONES if peso is not None))

fases = []
original = r.reparar
def comprobada(azar, estado, *resto):
    original(azar, estado, *resto)
    assert estado.valor == valor(estado.filas), (estado.valor, valor(estado.filas))
    fases.append(estado.valor)
r.reparar = comprobada
opciones = [p or r.OPCIONES for p in r.opciones_permitidas()]
args = argparse.Namespace(semilla=0, tabu=10, permuta=0.25, arranques=1, estancamiento=50, pulido=20)
mejor, _, _ = r.buscar(args, random.Random(0), opciones, time.perf_counter())
assert fases
assert mejor.valor == valor(modelo.crear_horario(mejor.posiciones))
"))

;; Sin pasos, el horario es el del goloso con la misma semilla; con pasos, nunca es peor. En Saúl
;; solo con la semilla 0, por tiempo.
(loop for (dominio semillas) in '(("tv" 3) ("tesis" 3) ("docentes" 3) ("seder" 3) ("saul" 1))
      do (comprobar-estrategias
          (modelo-del-dominio dominio) (list (make-instance 'reparacion-tabu) (make-instance 'goloso))
          (format nil "
import modelo
for semilla in range(~d):
    goloso = correr('goloso', '--semilla', semilla)
    corta = correr('reparacion_tabu', '--semilla', semilla, '--arranques', 1, '--estancamiento', 0, '--pulido', 0)
    assert corta['posiciones'] == goloso['posiciones'] and corta['iteraciones'] == 0, semilla
    larga = correr('reparacion_tabu', '--semilla', semilla, '--arranques', 1, '--estancamiento', 50, '--pulido', 20)
    assert (larga['duras'], larga['blandas']) <= (goloso['duras'], goloso['blandas']), semilla
    assert all(larga['valores'][nombre] == 0 for nombre in modelo.DE_UNA_FILA), larga['valores']
" semillas)))

;; En tv el goloso ya da (0, 0): para en el primer arranque sin dar ningún paso.
(comprobar-estrategias
 (modelo-del-dominio "tv") (list (make-instance 'reparacion-tabu))
 "
corrida = correr('reparacion_tabu', '--semilla', 0)
assert corrida['motivo_de_parada'] == 'optimo' and corrida['arranques'] == 1 and corrida['iteraciones'] == 0
")

;; La reparación tabú no trae nada de las estrategias de búsqueda.
(let ((programa (programa-de (make-instance 'reparacion-tabu) (modelo-pequeno))))
  (dolist (texto '("penalizacion" "Evaluador" "Individuo" "INICIOS" "Parada_" "inicio"))
    (assert (not (search texto programa)) () "la reparación tabú menciona ~a" texto)))
