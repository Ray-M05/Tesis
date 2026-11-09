(in-package :pruebas-emision)

;; Lo que modelo.py cuenta a las estrategias: la identidad, los dominios y los grupos de restricciones.
(comprobar-en-python
 (modelo-de "
(def-consulta en-martes ()
  :itera-sobre (u fila)
  :comprueba (op-igual (dia u) martes)
  :operacion (suma 1))
(def-consulta choque ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                   (op-igual (turno a) (turno b))
                   (op-distinto (sesion a) (sesion b)))
  :operacion (suma 1))
(def-consulta con-duracion ()
  :itera-sobre (u fila)
  :comprueba (op-mayor (duracion (sesion u)) 0)
  :operacion (suma 1))
(def-consulta crear-fila ()
  :itera-sobre (u fila)
  :comprueba (op-igual (dia u) lunes)
  :operacion (suma 1))
(def-nppq r-choque (op-mayor (choque) 0))
(def-nppq prohibiciones (op-mayor (crear-fila) 0))
(def-nppq r-martes (op-mayor (en-martes) 0))
(def-nppq r-constante (op-mayor (con-duracion) 0))
(def-tqpq r-cota (op-menor-igual (de-dia d) 2) :para (d dia))
(def-ndpq r-blanda (op-mayor (en-martes) 0) :peso 2)
" '("r-choque" "prohibiciones" "r-martes" "r-constante" "r-cota" "r-blanda"))
 "
assert IDENTIDADES is SESION
assert DOMINIOS_DE_DECISION == [DIA, TURNO]
fila = crear_fila(2, (1, 0))
assert fila.sesion is S3 and fila.dia is MARTES and fila.turno is T1
assert [f.dia for f in crear_horario([[0, 0], [1, 0], [2, 1], [0, 1]])] == [LUNES, MARTES, JUEVES, LUNES]
assert PROHIBICIONES == ['r_choque', 'prohibiciones_', 'r_martes', 'r_constante']
assert DE_UNA_FILA == ['prohibiciones_', 'r_martes', 'r_constante']
assert crear_fila_(crear_horario([[0, 0], [1, 0], [2, 1], [0, 1]])) == 2
assert CONSTANTES == ['r_constante']
")

;; Las opciones que dejan las restricciones de una fila son las del prototipo.
(dolist (caso '(("seder" 615) ("saul" 645)))
  (destructuring-bind (dominio por-mil) caso
    (comprobar-en-python
     (modelo-del-dominio dominio)
     (format nil "
import itertools
FUNCIONES = {nombre: funcion for nombre, _, funcion in RESTRICCIONES}
OPCIONES = list(itertools.product(*(range(len(d)) for d in DOMINIOS_DE_DECISION)))
de_una_fila = [FUNCIONES[n] for n in DE_UNA_FILA]
permitidas = sum(1 for i in range(len(IDENTIDADES)) for o in OPCIONES
                 if all(f([crear_fila(i, o)]) == 0 for f in de_una_fila))
assert round(1000 * permitidas / (len(OPCIONES) * len(IDENTIDADES))) == ~d, permitidas
" por-mil))))

(comprobar-en-python
 (modelo-del-dominio "saul")
 "
assert 'restriccion_frecuencia_exacta' in CONSTANTES
assert 'restriccion_frecuencia_exacta' not in PROHIBICIONES
assert 'restriccion_tope_diario_de_profesor' not in PROHIBICIONES
")
