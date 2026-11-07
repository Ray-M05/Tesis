(in-package :emision)

(defgeneric generar-codigo (nodo destino stream)
  (:documentation "Traduce una expresión al lenguaje de DESTINO. Con STREAM nil devuelve una cadena."))

(defgeneric simbolo (clase destino)
  (:documentation "Devuelve cómo se escribe en DESTINO el operador de la clase CLASE."))

(defgeneric emitir-consulta (consulta destino stream)
  (:documentation "Define una consulta en el lenguaje de DESTINO."))

(defgeneric emitir-restriccion (restriccion destino stream)
  (:documentation "Define una restricción en el lenguaje de DESTINO."))

(defgeneric emitir (destino stream)
  (:documentation "Escribe en STREAM el archivo completo de DESTINO."))

(defgeneric margen-de-incumplimiento (comparador)
  (:documentation "Devuelve lo que se suma a |q - umbral| según la condición de incumplimiento."))

(defmethod margen-de-incumplimiento ((comparador (eql 'op-mayor))) 0)
(defmethod margen-de-incumplimiento ((comparador (eql 'op-menor))) 0)
(defmethod margen-de-incumplimiento ((comparador (eql 'op-distinto))) 0)
(defmethod margen-de-incumplimiento ((comparador (eql 'op-mayor-igual))) 1)
(defmethod margen-de-incumplimiento ((comparador (eql 'op-menor-igual))) 1)
(defmethod margen-de-incumplimiento ((comparador (eql 'op-igual))) 1)

(defgeneric negada (texto destino)
  (:documentation "Escribe la negación de una condición ya traducida."))

(defgeneric agregado (nodo destino)
  (:documentation "Devuelve cómo se resume un objetivo: el máximo, o menos el mínimo."))

(defun comprobacion-escrita (nodo destino)
  "Escribe la comprobación de un cuantificador."
  (generar-codigo (slot-value nodo 'comprobacion) destino nil))

(defgeneric condicion-incumplida (nodo destino)
  (:documentation "Escribe la condición con la que se incumple un cuantificador."))

(defmethod condicion-incumplida ((nodo nppq) destino) (comprobacion-escrita nodo destino))
(defmethod condicion-incumplida ((nodo ndpq) destino) (comprobacion-escrita nodo destino))
(defmethod condicion-incumplida ((nodo tqpq) destino)
  (negada (comprobacion-escrita nodo destino) destino))
(defmethod condicion-incumplida ((nodo sbqp) destino)
  (negada (comprobacion-escrita nodo destino) destino))

(defgeneric condicion-exigida (nodo destino)
  (:documentation "Escribe la condición que un cuantificador exige."))

(defmethod condicion-exigida ((nodo nppq) destino)
  (negada (comprobacion-escrita nodo destino) destino))
(defmethod condicion-exigida ((nodo ndpq) destino)
  (negada (comprobacion-escrita nodo destino) destino))
(defmethod condicion-exigida ((nodo tqpq) destino) (comprobacion-escrita nodo destino))
(defmethod condicion-exigida ((nodo sbqp) destino) (comprobacion-escrita nodo destino))

(defun codigo (nodo destino)
  "Devuelve como cadena la traducción de NODO."
  (generar-codigo nodo destino nil))

(defmethod generar-codigo ((nodo integer) (destino infijo) stream)
  (format stream "~d" nodo))

(defmethod generar-codigo ((nodo real) (destino infijo) stream)
  (format stream "~f" (coerce nodo 'double-float)))

(defmethod generar-codigo ((nodo operacion-binaria) (destino infijo) stream)
  (format stream "(~a ~a ~a)"
          (codigo (slot-value nodo 'operando-izq) destino)
          (simbolo (type-of nodo) destino)
          (codigo (slot-value nodo 'operando-der) destino)))

(defmethod generar-codigo ((nodo operacion-logica-binaria) (destino infijo) stream)
  (let ((separador (format nil " ~a " (simbolo (type-of nodo) destino))))
    (format stream "(~{~a~})"
            (loop for (termino . resto) on (aplanar (type-of nodo) nodo)
                  collect (codigo termino destino)
                  when resto collect separador))))
