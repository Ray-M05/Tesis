(in-package :dsl-ast)

(defun valor-de-peso (claves que)
  "Devuelve el :peso declarado, un número positivo, o 1 si no se declaró."
  (if (getf claves :peso)
      (let ((peso (valor-unico claves :peso que)))
        (unless (and (realp peso) (plusp peso))
          (rechazar "~a: el peso ~s no es un número positivo" que peso))
        peso)
      1))

(defun expandir-restriccion (clase forma permitidas)
  "Valida (nombre comprobación opciones...) y devuelve la forma que define la restricción."
  (let* ((nombre (first forma))
         (que (format nil "restricción ~s" nombre)))
    (unless (>= (length forma) 2)
      (rechazar "~a: falta su comprobación" que))
    (exigir-nombre-nuevo nombre que)
    (let* ((claves (repartir-claves (cddr forma) permitidas que))
           (iteradores (getf claves :para)))
      (exigir-iteradores iteradores que)
      (let ((variables (mapcar #'first iteradores)))
        (exigir-variables variables que)
        `(defvar ,nombre
           (let ((para (list ,@(mapcar (lambda (iterador)
                                         `(list ',(first iterador) ,(second iterador)))
                                       iteradores))))
             (make-instance ',clase
                            :nombre ',nombre
                            :para para
                            :comprobacion ,(ligar-variables variables (second forma))
                            ,@(when (member :peso permitidas)
                                `(:peso ,(valor-de-peso claves que))))))))))

(defmethod initialize-instance :after ((restriccion objetivo) &key)
  (unless (slot-value restriccion 'para)
    (rechazar "restricción ~a: un objetivo necesita :para" (slot-value restriccion 'nombre))))

(defmacro def-nppq (&rest forma)
  "Dura: no puede pasar que se cumpla la comprobación."
  (expandir-restriccion 'nppq forma '(:para)))

(defmacro def-tqpq (&rest forma)
  "Dura: tiene que pasar que se cumpla la comprobación."
  (expandir-restriccion 'tqpq forma '(:para)))

(defmacro def-ndpq (&rest forma)
  "Blanda: no debe pasar que se cumpla la comprobación."
  (expandir-restriccion 'ndpq forma '(:para :peso)))

(defmacro def-sbqp (&rest forma)
  "Blanda: sería bueno que se cumpla la comprobación."
  (expandir-restriccion 'sbqp forma '(:para :peso)))

(defmacro def-minimizar (&rest forma)
  "Objetivo: minimizar el mayor valor de la consulta sobre el dominio de :para."
  (expandir-restriccion 'minimizar forma '(:para :peso)))

(defmacro def-maximizar (&rest forma)
  "Objetivo: maximizar el menor valor de la consulta sobre el dominio de :para."
  (expandir-restriccion 'maximizar forma '(:para :peso)))
