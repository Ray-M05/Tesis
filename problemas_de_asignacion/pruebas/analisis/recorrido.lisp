(in-package :pruebas-analisis)

(defun clases-del-ast (clase)
  "Devuelve CLASE y todas sus subclases."
  (sb-mop:finalize-inheritance clase)
  (cons clase (mapcan #'clases-del-ast (copy-list (sb-mop:class-direct-subclasses clase)))))

;; Toda clase del AST tiene un método, y un valor desconocido no se ignora.
(let ((clases (rest (clases-del-ast (find-class 'nodo-ast)))))
  (assert (> (length clases) 20))
  (dolist (clase clases)
    (assert (compute-applicable-methods #'hijos (list (allocate-instance clase))) ()
            "~a no tiene método de hijos" clase)))
(assert (null (find-method #'hijos '() (list (find-class t)) nil)))
(assert (null (compute-applicable-methods #'hijos (list (list 1 2)))))

(let* ((p (problema-de "(def-tqpq r (op-igual (del-dia x y) 3) :para (x profesor) (y dia))"))
       (r (first (problema-restricciones p)))
       (aplicaciones (nodos-de 'aplicacion-de-consulta r)))
  ;; La consulta se encuentra dentro de op-igual, no solo dentro de op-mayor (2.5).
  (assert (= (length aplicaciones) 1))
  (assert (equal (nombres (slot-value (first aplicaciones) 'argumentos)) '("X" "Y")))
  ;; El recorrido entra en la consulta aplicada.
  (assert (nodos-de 'acceso-a-atributo-de-entidad r)))

(let ((p (problema-de "(def-sbqp r (op-menor-igual (op-suma (q) (q2)) 3))")))
  (assert (equal (nombres (mapcar (lambda (a) (slot-value (slot-value a 'consulta) 'nombre))
                                  (nodos-de 'aplicacion-de-consulta
                                            (first (problema-restricciones p)))))
                 '("Q" "Q2"))))

(let* ((a (op-igual 1 2)) (b (op-igual 3 4)) (c (op-igual 5 6))
       (d (op-mayor 7 8)))
  (assert (equal (aplanar 'op-y (op-y a b c)) (list a b c)))
  (assert (equal (aplanar 'op-y (op-y a (op-y b c))) (list a b c)))
  (assert (equal (aplanar 'op-o (op-o a b d)) (list a b d)))
  (assert (equal (aplanar 'op-y a) (list a))))
