(in-package :pruebas-dsl)

(defparameter *vocabulario* 27)

(let ((total 0))
  (do-external-symbols (simbolo :dsl) (incf total))
  (assert (= total *vocabulario*)))

(let* ((a (dsl:op-igual 1 2))
       (b (dsl:op-igual 3 4))
       (c (dsl:op-igual 5 6))
       (nodo (dsl:op-and a b c)))
  (assert (typep nodo 'dsl:op-and))
  (assert (typep (slot-value nodo 'operando-izq) 'dsl:op-and))
  (assert (eq (slot-value nodo 'operando-der) c))
  (assert (eq (slot-value (slot-value nodo 'operando-izq) 'operando-izq) a)))

(assert (= (slot-value (dsl:suma 1) 'expresion) 1))
(assert (typep (dsl:contar-distintos 1) 'operacion-de-consulta))
(assert (typep (dsl:op-not 1) 'operacion-logica-unaria))
(assert (typep (dsl:op-suma 1 2) 'operacion-aritmetica))
(assert (typep (dsl:op-mayor 1 2) 'comprobacion-aritmetica))

;; Sin funciones de acceso generadas para los nodos, ni los cinco nodos borrados.
(dolist (nombre '("OPERANDO-IZQ" "IZQ" "OPERANDO" "ATRIBUTO" "COMPROBACION" "EXPRESION"))
  (let ((simbolo (find-symbol nombre :dsl-ast)))
    (assert (not (and simbolo (fboundp simbolo))))))
(dolist (nombre '("COMB-ENTIDADES" "LISTA" "ACCESO-A-ELEMENTO-DE-COMB"
                  "HAY-ELEMENTOS-DUPLICADOS" "PERTENECE"))
  (let ((simbolo (find-symbol nombre :dsl-ast)))
    (assert (not (and simbolo (find-class simbolo nil))))))

(dolist (clase '(nppq tqpq))
  (assert (subtypep clase 'restriccion-dura)))
(dolist (clase '(ndpq sbqp))
  (assert (subtypep clase 'restriccion-blanda)))
(dolist (clase '(minimizar maximizar))
  (assert (subtypep clase 'objetivo)))
(assert (subtypep 'restriccion-blanda 'restriccion-ponderada))
(assert (subtypep 'objetivo 'restriccion-ponderada))
(assert (not (subtypep 'restriccion-dura 'restriccion-ponderada)))
