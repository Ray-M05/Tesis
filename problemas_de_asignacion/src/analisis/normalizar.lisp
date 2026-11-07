(in-package :analisis)

(defgeneric negado (comparador)
  (:documentation "Devuelve el comparador contrario."))

(defmethod negado ((comparador (eql 'op-mayor))) 'op-menor-igual)
(defmethod negado ((comparador (eql 'op-menor-igual))) 'op-mayor)
(defmethod negado ((comparador (eql 'op-menor))) 'op-mayor-igual)
(defmethod negado ((comparador (eql 'op-mayor-igual))) 'op-menor)
(defmethod negado ((comparador (eql 'op-igual))) 'op-distinto)
(defmethod negado ((comparador (eql 'op-distinto))) 'op-igual)

(defgeneric volteado (comparador)
  (:documentation "Devuelve el comparador que dice lo mismo con los operandos intercambiados."))

(defmethod volteado ((comparador (eql 'op-mayor))) 'op-menor)
(defmethod volteado ((comparador (eql 'op-menor))) 'op-mayor)
(defmethod volteado ((comparador (eql 'op-mayor-igual))) 'op-menor-igual)
(defmethod volteado ((comparador (eql 'op-menor-igual))) 'op-mayor-igual)
(defmethod volteado ((comparador (eql 'op-igual))) 'op-igual)
(defmethod volteado ((comparador (eql 'op-distinto))) 'op-distinto)

(defgeneric incumplimiento-de (restriccion comparador)
  (:documentation "Devuelve el comparador con el que la restricción se incumple."))

(defmethod incumplimiento-de ((restriccion nppq) comparador) comparador)
(defmethod incumplimiento-de ((restriccion ndpq) comparador) comparador)
(defmethod incumplimiento-de ((restriccion tqpq) comparador) (negado comparador))
(defmethod incumplimiento-de ((restriccion sbqp) comparador) (negado comparador))

(defgeneric da-entero-p (operacion)
  (:documentation "Dice si una operación de consulta siempre da un entero."))

(defmethod da-entero-p ((operacion contar-distintos)) t)
(defmethod da-entero-p ((operacion suma)) (integerp (slot-value operacion 'expresion)))

(defgeneric peso-de (restriccion)
  (:documentation "Devuelve el peso de una restricción, o nil si es dura."))

(defmethod peso-de ((restriccion cuantificador-restriccion)) nil)
(defmethod peso-de ((restriccion restriccion-ponderada)) (slot-value restriccion 'peso))

(defun con-consulta-p (nodo)
  "Dice si NODO contiene alguna consulta aplicada."
  (nodos-de 'aplicacion-de-consulta nodo))

(defun orientar (comprobacion)
  "Devuelve (medida comparador umbral), con la consulta a la izquierda, si es una comparación simple."
  (when (typep comprobacion 'comprobacion-aritmetica)
    (let ((izq (slot-value comprobacion 'operando-izq))
          (der (slot-value comprobacion 'operando-der))
          (comparador (type-of comprobacion)))
      (cond ((and (typep izq 'aplicacion-de-consulta) (not (con-consulta-p der)))
             (list izq comparador der))
            ((and (typep der 'aplicacion-de-consulta) (not (con-consulta-p izq)))
             (list der (volteado comparador) izq))))))

(defun simplificar-incumplimiento (comparador umbral medida)
  "Convierte q >= 1 en q > 0 cuando la consulta solo puede dar enteros."
  (if (and (eq comparador 'op-mayor-igual)
           (eql umbral 1)
           (da-entero-p (slot-value (slot-value medida 'consulta) 'operacion)))
      (values 'op-mayor 0)
      (values comparador umbral)))

(defun forma-de-comparacion (nodo medida comparador umbral)
  "Devuelve la clase y los campos de una comparación con una sola consulta."
  (multiple-value-bind (incumple limite)
      (simplificar-incumplimiento (incumplimiento-de nodo comparador) umbral medida)
    (if (and (eq incumple 'op-mayor) (eql limite 0) (null (slot-value nodo 'para)))
        (list 'prohibicion :medida medida)
        (list 'cota
              :medida medida
              :comparador comparador
              :umbral umbral
              :incumplimiento (funcall incumple medida limite)))))

(defgeneric forma-de (nodo)
  (:documentation "Devuelve la clase de la forma de una restricción, seguida de sus campos."))

(defmethod forma-de ((nodo cuantificador-restriccion))
  (let ((orientada (orientar (slot-value nodo 'comprobacion))))
    (if orientada
        (apply #'forma-de-comparacion nodo orientada)
        (list 'restriccion-generica))))

(defmethod forma-de ((nodo objetivo))
  (let ((comprobacion (slot-value nodo 'comprobacion)))
    (if (con-consulta-p comprobacion)
        (list 'minimax :medida comprobacion)
        (list 'restriccion-generica))))

(defun normalizar-restriccion (nodo consultas problema)
  "Crea la restricción del modelo, enlazada con las consultas ya clasificadas de CONSULTAS."
  (destructuring-bind (clase &rest campos) (forma-de nodo)
    (let* ((variables (variables-de-para nodo))
           (propias (mapcar (lambda (aplicacion)
                              (find (slot-value aplicacion 'consulta) consultas
                                    :key #'consulta-nodo))
                            (nodos-de 'aplicacion-de-consulta nodo)))
           (de-las-consultas (mapcan (lambda (consulta)
                                       (copy-list (consulta-decisiones consulta)))
                                     propias)))
      (apply #'make-instance clase
             :nombre (slot-value nodo 'nombre)
             :nodo nodo
             :peso (peso-de nodo)
             :variables variables
             :decisiones (remove-duplicates
                          (append de-las-consultas
                                  (decisiones-de (slot-value nodo 'comprobacion) variables problema))
                          :from-end t)
             :consultas (remove-duplicates propias :from-end t)
             campos))))
