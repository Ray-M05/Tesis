(in-package :pruebas-dsl)

(defparameter *consulta-buena* "
(def-condicion da-clase (p f) (op-igual (profesor (sesion f)) p))
(def-consulta sesiones-del-dia (p d)
  :itera-sobre (f fila)
  :comprueba (op-y (da-clase p f) (op-igual (dia f) d))
  :operacion (suma 1))
(def-consulta choques ()
  :itera-sobre (p profesor)
  :pares (f1 f2) fila
  :comprueba (op-y (da-clase p f1) (da-clase p f2) (op-igual (dia f1) (dia f2)))
  :operacion (suma (orden (dia f1))))
(def-consulta dias-distintos (p)
  :itera-sobre (f fila)
  :comprueba (da-clase p f)
  :operacion (contar-distintos (dia f)))
(def-consulta sin-usar (x)
  :itera-sobre (dia dia)
  :comprueba (op-igual 1 1)
  :operacion (suma 1))
")

(carga-base *consulta-buena*)

(flet ((funcion (nombre) (symbol-function (find-symbol nombre "DOMINIO-PRUEBA")))
       (nodo-de (nombre)
         (slot-value (funcall (symbol-function (find-symbol nombre "DOMINIO-PRUEBA")))
                     'consulta)))
  ;; Una consulta sin parámetros se usa como llamada y guarda nombre y recorrido
  (let ((consulta (nodo-de "CHOQUES")))
    (assert (typep consulta 'consulta-simple))
    (assert (equal (symbol-name (slot-value consulta 'nombre)) "CHOQUES"))
    (assert (null (slot-value consulta 'parametros)))
    (assert (equal (simbolos (slot-value consulta 'variable-iteracion)) '("P")))
    (assert (eq (first (slot-value consulta 'dominio-iteracion)) (de-dominio "PROFESOR")))
    (assert (equal (simbolos (slot-value consulta 'variables-pares)) '("F1" "F2")))
    (assert (eq (slot-value consulta 'dominio-pares) (de-dominio "FILA")))
    (assert (typep (slot-value consulta 'operacion) 'dsl:suma))
    (assert (typep (slot-value (slot-value consulta 'operacion) 'expresion)
                   'acceso-a-atributo-de-entidad)))
  ;; Con parámetros
  (let* ((p (find-symbol "P" "DOMINIO-PRUEBA"))
         (d (find-symbol "D" "DOMINIO-PRUEBA"))
         (aplicacion (funcall (funcion "SESIONES-DEL-DIA") p d))
         (consulta (slot-value aplicacion 'consulta)))
    (assert (typep aplicacion 'aplicacion-de-consulta))
    (assert (equal (slot-value aplicacion 'argumentos) (list p d)))
    (assert (equal (simbolos (slot-value consulta 'parametros)) '("P" "D")))
    (assert (null (slot-value consulta 'variables-pares)))
    (assert (null (slot-value consulta 'dominio-pares)))
    (assert (typep (slot-value consulta 'comprobacion) 'dsl:op-y))
    (assert (= (slot-value (slot-value consulta 'operacion) 'expresion) 1)))
  ;; contar-distintos guarda su atributo
  (let* ((p (find-symbol "P" "DOMINIO-PRUEBA"))
         (consulta (slot-value (funcall (funcion "DIAS-DISTINTOS") p) 'consulta))
         (operacion (slot-value consulta 'operacion)))
    (assert (typep operacion 'dsl:contar-distintos))
    (assert (equal (symbol-name (slot-value (slot-value operacion 'expresion) 'atributo)) "DIA")))
  ;; Un dominio se evalúa fuera de las variables, aunque se llamen igual
  (let* ((x (find-symbol "X" "DOMINIO-PRUEBA"))
         (consulta (slot-value (funcall (funcion "SIN-USAR") x) 'consulta)))
    (assert (eq (first (slot-value consulta 'dominio-iteracion)) (de-dominio "DIA"))))
  ;; Una condición es una función que devuelve un nodo
  (assert (typep (funcall (funcion "DA-CLASE") 'p 'f) 'dsl:op-igual)))

(defparameter *q* "(def-consulta q (p) :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma 1))")

;; Claves
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :comprueva (op-igual 1 1) :operacion (suma 1))"
              "Q" ":COMPRUEVA")
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma 1) :devuelve 1)"
              "Q" ":DEVUELVE")
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :itera-sobre (g fila) :comprueba (op-igual 1 1) :operacion (suma 1))"
              "Q" ":ITERA-SOBRE")
(rechaza-base "(def-consulta q () :pares (a b) fila :pares (c d) fila :comprueba (op-igual 1 1) :operacion (suma 1))"
              "Q" ":PARES")
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :operacion (suma 1))" "Q" ":COMPRUEBA")
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :comprueba (op-igual 1 1))" "Q" ":OPERACION")
(rechaza-base "(def-consulta q () :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" ":itera-sobre")
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :comprueba (op-igual 1 1) (op-igual 2 2) :operacion (suma 1))"
              "Q" ":COMPRUEBA")

;; Recorridos
(rechaza-base "(def-consulta q () :itera-sobre (f nada) :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" "NADA")
(rechaza-base "(def-consulta q () :itera-sobre f :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" "F")
(rechaza-base "(def-consulta q () :pares (a b) nada :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" "NADA")
(rechaza-base "(def-consulta q () :pares (a) fila :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" ":pares")
(rechaza-base "(def-consulta q () :pares (a b) :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" ":pares")
(rechaza-base "(def-consulta q () :pares (a a) fila :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" "A")

;; Variables
(rechaza-base "(def-consulta q (x) :itera-sobre (x fila) :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" "X")
(rechaza-base "(def-consulta q () :itera-sobre (x fila) :pares (x y) fila :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" "X")
(rechaza-base "(def-consulta q () :itera-sobre (t fila) :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" "T")
(rechaza-base "(def-consulta q (list) :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma 1))" "Q" "LIST")

;; Operaciones
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (promedio 1))" "Q" "PROMEDIO")
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion suma)" "Q" "SUMA")
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma))" "Q" "SUMA")
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (contar-distintos))" "Q" "CONTAR-DISTINTOS")
(rechaza-base "(def-consulta q () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma 1 2))" "Q" "SUMA")

;; Nombres
(rechaza-base "(def-consulta orden () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma 1))" "ORDEN")
(rechaza-base "(def-consulta list () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma 1))" "LIST")

;; Una consulta dentro de otra
(rechaza-base (concatenate 'string
                           "(def-consulta r () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma 1))
                            (def-consulta s () :itera-sobre (f fila) :comprueba (op-mayor (r) 0) :operacion (suma 1))")
              "R" "dentro")
(rechaza-base (concatenate 'string
                           "(def-consulta r () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma 1))
                            (def-consulta s () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma (r)))")
              "R" "dentro")

;; Aplicación
(rechaza-base (concatenate 'string *q* "(def-nppq r (op-mayor (q) 0))") "Q" "0" "1")
(rechaza-base (concatenate 'string *q* "(def-nppq r (op-mayor (q lunes) 0))") "Q" "variables ligadas")
(rechaza-base (concatenate 'string *q* "(def-nppq r (op-mayor (q 3) 0))") "Q" "variables ligadas")

;; Condiciones
(rechaza-base "(def-condicion list (a) (op-igual a 1))" "LIST")
(rechaza-base "(def-condicion orden (a) (op-igual a 1))" "ORDEN")
(rechaza-base "(def-condicion c (a a) (op-igual a 1))" "C" "A")
(rechaza-base "(def-condicion c (a))" "C")
(rechaza-base "(def-condicion c (a) (op-igual a 1) (op-igual a 2))" "C")
