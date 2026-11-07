(in-package :emision)

(defclass destino ()
  ((modelo     :initarg :modelo :reader destino-modelo)
   (constantes :reader destino-constantes)))

(defclass infijo () ())

(defclass python (destino infijo)
  ((nivel :initform 0 :accessor destino-nivel)))

(defclass matematica (destino infijo) ())

(defclass verbalizador (destino)
  ((predicados :initarg :predicados :initform nil :reader destino-predicados)))

(defun constantes-de (modelo)
  "Devuelve una tabla que dice qué símbolo nombra a cada instancia."
  (let ((constantes (make-hash-table :test #'eq)))
    (loop for (nil . instancias) in (problema-instancias (modelo-problema modelo))
          do (dolist (instancia instancias)
               (setf (gethash (symbol-value instancia) constantes) instancia)))
    constantes))

(defmethod initialize-instance :after ((destino destino) &key)
  (setf (slot-value destino 'constantes) (constantes-de (destino-modelo destino))))
