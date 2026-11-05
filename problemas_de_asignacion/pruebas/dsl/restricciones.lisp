(in-package :pruebas-dsl)

(defparameter *restricciones-buenas* "
(def-consulta choques ()
  :pares (f1 f2) fila
  :comprueba (op-igual (dia f1) (dia f2))
  :operacion (suma 1))
(def-consulta sesiones-del-dia (p d)
  :itera-sobre (f fila)
  :comprueba (op-and (op-igual (profesor (sesion f)) p) (op-igual (dia f) d))
  :operacion (suma 1))
(def-nppq r-nppq (op-mayor (choques) 0))
(def-tqpq r-tqpq (op-igual (sesiones-del-dia p d) 1) :para (p profesor) (d dia))
(def-ndpq r-ndpq (op-mayor (choques) 0) :peso 5)
(def-sbqp r-sbqp (op-menor-igual (sesiones-del-dia p d) 5) :para (p profesor) (d dia))
(def-sbqp r-orden (op-menor-igual (sesiones-del-dia p d) 5) :peso 3 :para (p profesor) (d dia))
(def-minimizar r-min (sesiones-del-dia dia profesor) :para (dia dia) (profesor profesor))
(def-maximizar r-max (sesiones-del-dia p d) :para (p profesor) (d dia) :peso 2)
(def-tqpq r-sin-usar (op-igual 1 1) :para (x dia))
")

(carga-base *restricciones-buenas*)

(flet ((clase-de (nombre) (type-of (de-dominio nombre)))
       (de (nombre slot) (slot-value (de-dominio nombre) slot)))
  (assert (eq (clase-de "R-NPPQ") 'nppq))
  (assert (eq (clase-de "R-TQPQ") 'tqpq))
  (assert (eq (clase-de "R-NDPQ") 'ndpq))
  (assert (eq (clase-de "R-SBQP") 'sbqp))
  (assert (eq (clase-de "R-MIN") 'minimizar))
  (assert (eq (clase-de "R-MAX") 'maximizar))
  ;; Dureza
  (assert (typep (de-dominio "R-NPPQ") 'restriccion-dura))
  (assert (typep (de-dominio "R-TQPQ") 'restriccion-dura))
  (dolist (nombre '("R-NDPQ" "R-SBQP" "R-MIN" "R-MAX"))
    (assert (not (typep (de-dominio nombre) 'restriccion-dura))))
  ;; Peso
  (assert (= (de "R-NDPQ" 'peso) 5))
  (assert (= (de "R-SBQP" 'peso) 1))
  (assert (= (de "R-ORDEN" 'peso) 3))
  (assert (= (de "R-MIN" 'peso) 1))
  (assert (= (de "R-MAX" 'peso) 2))
  (assert (not (slot-exists-p (de-dominio "R-NPPQ") 'peso)))
  ;; Nombre
  (assert (equal (symbol-name (de "R-NPPQ" 'nombre)) "R-NPPQ"))
  ;; :para guarda variable y dominio, en orden
  (assert (null (de "R-NPPQ" 'para)))
  (let ((para (de "R-TQPQ" 'para)))
    (assert (equal (simbolos (mapcar #'first para)) '("P" "D")))
    (assert (eq (second (first para)) (de-dominio "PROFESOR")))
    (assert (eq (second (second para)) (de-dominio "DIA"))))
  ;; Una variable puede llamarse como su dominio
  (assert (eq (second (first (de "R-MIN" 'para))) (de-dominio "DIA")))
  ;; La comprobación aplica la consulta a las variables
  (let ((aplicacion (slot-value (de "R-TQPQ" 'comprobacion) 'operando-izq)))
    (assert (typep aplicacion 'aplicacion-de-consulta))
    (assert (equal (simbolos (slot-value aplicacion 'argumentos)) '("P" "D"))))
  (assert (typep (de "R-MIN" 'comprobacion) 'aplicacion-de-consulta)))

;; Peso
(rechaza-base "(def-nppq r (op-mayor 1 0) :peso 5)" "R" ":PESO")
(rechaza-base "(def-tqpq r (op-mayor 1 0) :peso 5)" "R" ":PESO")
(rechaza-base "(def-ndpq r (op-mayor 1 0) :peso 0)" "R" "0")
(rechaza-base "(def-ndpq r (op-mayor 1 0) :peso -1)" "R" "-1")
(rechaza-base "(def-ndpq r (op-mayor 1 0) :peso alto)" "R" "ALTO")
(rechaza-base "(def-ndpq r (op-mayor 1 0) :peso 1 2)" "R" ":PESO")

;; Claves y :para
(rechaza-base "(def-nppq r (op-mayor 1 0) :elemento dia)" "R" ":ELEMENTO")
(rechaza-base "(def-nppq r (op-mayor 1 0) :para)" "R" ":PARA")
(rechaza-base "(def-nppq r (op-mayor 1 0) :para (x nada))" "R" "NADA")
(rechaza-base "(def-nppq r (op-mayor 1 0) :para x)" "R" "X")
(rechaza-base "(def-nppq r (op-mayor 1 0) :para (x dia) (x dia))" "R" "X")
(rechaza-base "(def-nppq r (op-mayor 1 0) :para (t dia))" "R" "T")
(rechaza-base "(def-nppq r (op-mayor 1 0) :para (x dia) :para (y dia))" "R" ":PARA")

;; Objetivos
(rechaza-base "(def-minimizar r (op-mayor 1 0))" "R" ":para")
(rechaza-base "(def-maximizar r (op-mayor 1 0))" "R" ":para")

;; Forma y nombre
(rechaza-base "(def-nppq r)" "R" "comprobación")
(rechaza-base "(def-nppq (op-mayor 1 0))" "OP-MAYOR")
(rechaza-base "(def-nppq list (op-mayor 1 0))" "LIST")
(rechaza-base "(def-nppq lunes (op-mayor 1 0))" "LUNES")
(rechaza-base "(def-nppq r (op-mayor 1 0)) (def-ndpq r (op-mayor 1 0))" "R")
