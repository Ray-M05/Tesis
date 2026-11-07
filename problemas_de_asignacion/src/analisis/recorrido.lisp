(in-package :analisis)

(defgeneric hijos (nodo)
  (:documentation "Devuelve lo que un nodo del AST o un valor contiene directamente."))

(defmethod hijos ((nodo number)) nil)
(defmethod hijos ((nodo string)) nil)
(defmethod hijos ((nodo symbol)) nil)
(defmethod hijos ((nodo ref-especifica-ent)) nil)
(defmethod hijos ((nodo ref-gen-entidad)) nil)

(defmethod hijos ((nodo acceso-a-atributo-de-entidad))
  (list (slot-value nodo 'entidad)))

(defmethod hijos ((nodo operacion-binaria))
  (list (slot-value nodo 'operando-izq) (slot-value nodo 'operando-der)))

(defmethod hijos ((nodo operacion-unaria))
  (list (slot-value nodo 'operando)))

(defmethod hijos ((nodo operacion-de-consulta))
  (list (slot-value nodo 'expresion)))

(defmethod hijos ((nodo aplicacion-de-consulta))
  (cons (slot-value nodo 'consulta) (slot-value nodo 'argumentos)))

(defmethod hijos ((nodo consulta-simple))
  (list (slot-value nodo 'comprobacion) (slot-value nodo 'operacion)))

(defmethod hijos ((nodo cuantificador-restriccion))
  (list (slot-value nodo 'comprobacion)))

(defun recorrer (funcion nodo)
  "Llama a FUNCION con NODO y con todo lo que contiene."
  (funcall funcion nodo)
  (dolist (hijo (hijos nodo))
    (recorrer funcion hijo)))

(defun nodos-de (clase nodo)
  "Devuelve los nodos de CLASE que hay dentro de NODO, en orden de aparición."
  (let ((encontrados '()))
    (recorrer (lambda (actual)
                (when (typep actual clase)
                  (push actual encontrados)))
              nodo)
    (nreverse encontrados)))

(defun aplanar (clase nodo)
  "Devuelve los términos de una cadena de nodos binarios de CLASE; si no lo es, el propio nodo."
  (if (typep nodo clase)
      (append (aplanar clase (slot-value nodo 'operando-izq))
              (aplanar clase (slot-value nodo 'operando-der)))
      (list nodo)))
