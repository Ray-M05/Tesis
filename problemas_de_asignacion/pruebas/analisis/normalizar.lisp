(in-package :pruebas-analisis)

(defun normal (texto)
  "Normaliza la restricción R de TEXTO."
  (first (last (restricciones-de (problema-de texto)))))

(defun incumple (restriccion)
  "Devuelve (comparador umbral) del incumplimiento de una cota."
  (let ((nodo (cota-incumplimiento restriccion)))
    (list (type-of nodo) (slot-value nodo 'operando-der))))

;; Formas equivalentes dan una prohibición, sobre la misma medida.
(dolist (escrito '("(def-nppq r (op-mayor (q) 0))"
                   "(def-nppq r (op-mayor-igual (q) 1))"
                   "(def-nppq r (op-menor 0 (q)))"
                   "(def-nppq r (op-menor-igual 1 (q)))"
                   "(def-tqpq r (op-menor-igual (q) 0))"
                   "(def-tqpq r (op-menor (q) 1))"
                   "(def-ndpq r (op-mayor (q) 0))"
                   "(def-sbqp r (op-menor-igual (q) 0))"))
  (let ((r (normal escrito)))
    (assert (eq (clase-de r) 'prohibicion) () "~a" escrito)
    (assert (typep (restriccion-medida r) 'aplicacion-de-consulta))
    (assert (equal (nombres (slot-value (slot-value (restriccion-medida r) 'consulta) 'nombre)) "Q"))))

;; Cotas: se conserva lo escrito, y aparte cuándo se incumple.
(loop for (escrito comparador umbral incumple-con limite)
        in '(("(def-nppq r (op-mayor (q) 12))" op-mayor 12 op-mayor 12)
             ("(def-nppq r (op-menor 12 (q)))" op-mayor 12 op-mayor 12)
             ("(def-tqpq r (op-igual (q) 0))" op-igual 0 op-distinto 0)
             ("(def-tqpq r (op-mayor (q) 0))" op-mayor 0 op-menor-igual 0)
             ("(def-nppq r (op-mayor-igual (q-suma) 1))" op-mayor-igual 1 op-mayor-igual 1)
             ("(def-sbqp r (op-menor-igual (del-dia p d) 5) :para (p profesor) (d dia))"
              op-menor-igual 5 op-mayor 5)
             ("(def-ndpq r (op-mayor (del-dia p d) 0) :para (p profesor) (d dia))"
              op-mayor 0 op-mayor 0)
             ("(def-nppq r (op-mayor-igual (del-dia p d) 1) :para (p profesor) (d dia))"
              op-mayor-igual 1 op-mayor 0))
      do (let ((r (normal escrito)))
           (assert (eq (clase-de r) 'cota) () "~a" escrito)
           (assert (eq (cota-comparador r) comparador) () "~a" escrito)
           (assert (eql (cota-umbral r) umbral) () "~a" escrito)
           (assert (equal (incumple r) (list incumple-con limite)) () "~a ~a" escrito (incumple r))
           (assert (eq (slot-value (cota-incumplimiento r) 'operando-izq)
                       (restriccion-medida r)))))

;; Un umbral puede ser un atributo de la variable cuantificada.
(let* ((r (normal "(def-consulta del-profesor (x)
                     :itera-sobre (u fila)
                     :comprueba (op-igual (dia u) x)
                     :operacion (suma 1))
                   (def-tqpq r (op-igual (del-profesor d) (orden d)) :para (d dia))")))
  (assert (eq (clase-de r) 'cota))
  (assert (typep (cota-umbral r) 'acceso-a-atributo-de-entidad))
  (assert (typep (cota-incumplimiento r) 'op-distinto)))

;; Lo que no tiene una sola medida es genérico.
(dolist (escrito '("(def-nppq r (op-mayor (op-suma (q) (q2)) 10))"
                   "(def-tqpq r (op-igual (q) (q2)))"
                   "(def-nppq r (op-mayor (q) (op-suma (q2) 1)))"
                   "(def-nppq r (op-or (op-mayor (q) 0) (op-mayor (q2) 0)))"
                   "(def-nppq r (op-mayor 3 2))"
                   "(def-minimizar r 5 :para (d dia))"))
  (assert (eq (clase-de (normal escrito)) 'restriccion-generica) () "~a" escrito))

;; Objetivos.
(let ((r (normal "(def-minimizar r (del-dia p d) :peso 3 :para (p profesor) (d dia))")))
  (assert (eq (clase-de r) 'minimax))
  (assert (eql (restriccion-peso r) 3))
  (assert (typep (restriccion-nodo r) 'minimizar)))
(assert (eq (clase-de (normal "(def-maximizar r (op-suma (del-dia p d) 1) :para (p profesor) (d dia))"))
            'minimax))

;; Campos comunes.
(let ((dura (normal "(def-nppq r (op-mayor (q) 0))"))
      (blanda (normal "(def-sbqp r (op-menor-igual (del-dia p d) 5) :peso 2 :para (p profesor) (d dia))")))
  (assert (null (restriccion-peso dura)))
  (assert (eql (restriccion-peso blanda) 2))
  (assert (null (restriccion-variables dura)))
  (assert (equal (nombres (restriccion-variables blanda)) '(("P" "PROFESOR") ("D" "DIA"))))
  (assert (equal (nombres (restriccion-decisiones dura)) '("DIA")))
  (assert (equal (nombres (restriccion-decisiones blanda)) '("DIA")))
  (assert (equal (nombres (restriccion-nombre blanda)) "R")))

;; Las consultas se enlazan sin repetirse, y las decisiones se unen.
(let* ((r (normal "(def-consulta del-turno ()
                     :itera-sobre (u fila)
                     :comprueba (op-mayor (orden (turno u)) 1)
                     :operacion (suma 1))
                   (def-nppq r (op-or (op-mayor (q) 0)
                                      (op-or (op-mayor (del-turno) 0) (op-mayor (q) 1))))")))
  (assert (equal (nombres (mapcar #'consulta-nombre (restriccion-consultas r)))
                 '("Q" "DEL-TURNO")))
  (assert (equal (nombres (restriccion-decisiones r)) '("DIA" "TURNO"))))

;; Una restricción sobre datos no toca ninguna decisión.
(let ((r (normal "(def-consulta filas-de (b)
                    :itera-sobre (u fila)
                    :comprueba (op-igual (sesion u) b)
                    :operacion (suma 1))
                  (def-tqpq r (op-igual (filas-de b) 2) :para (b sesion))")))
  (assert (eq (clase-de r) 'cota))
  (assert (null (restriccion-decisiones r)))
  (assert (equal (nombres (restriccion-variables r)) '(("B" "SESION")))))

;; Las variables de :para no se confunden con las de la consulta aplicada, aunque se llamen igual.
(let ((r (normal "(def-consulta m (w)
                    :itera-sobre (x ausencia)
                    :comprueba (op-and (op-igual (dia x) lunes)
                                       (op-igual (profesor x) (profesor (sesion w))))
                    :operacion (suma 1))
                  (def-sbqp r (op-menor-igual (m x) 1) :para (x fila))")))
  (assert (null (restriccion-decisiones r))))

;; Forma y decisiones de cada restricción de los cinco dominios.
(let ((formas (make-hash-table)))
  (loop for (dominio . filas) in *esperado*
        do (let ((restricciones (restricciones-de (problema-real dominio))))
             (assert (= (length restricciones) (length filas)))
             (loop for r in restricciones
                   for (nombre forma consulta nil decisiones) in filas
                   do (incf (gethash forma formas 0))
                      (assert (equal (symbol-name (restriccion-nombre r))
                                     (concatenate 'string "RESTRICCION-" nombre)))
                      (assert (eq (clase-de r) forma) () "~a es ~a" nombre (clase-de r))
                      (assert (equal (nombres (mapcar #'consulta-nombre (restriccion-consultas r)))
                                     (list consulta)))
                      (assert (equal (nombres (restriccion-decisiones r)) decisiones)
                              () "~a toca ~a" nombre (restriccion-decisiones r)))))
  (assert (= (gethash 'prohibicion formas) 19))
  (assert (= (gethash 'minimax formas) 5))
  (assert (= (gethash 'cota formas) 2)))

;; Las dos cotas reales de Saúl.
(let* ((restricciones (restricciones-de (problema-real "saul")))
       (frecuencia (find 'cota restricciones :key #'clase-de))
       (tope (find 'cota restricciones :key #'clase-de :from-end t)))
  (assert (eq (cota-comparador frecuencia) 'op-igual))
  (assert (typep (cota-incumplimiento frecuencia) 'op-distinto))
  (assert (typep (cota-umbral frecuencia) 'acceso-a-atributo-de-entidad))
  (assert (eq (cota-comparador tope) 'op-menor-igual))
  (assert (eql (cota-umbral tope) 5))
  (assert (typep (cota-incumplimiento tope) 'op-mayor))
  (assert (typep (restriccion-nodo tope) 'sbqp))
  (assert (eql (restriccion-peso tope) 1)))
