(in-package :emision)

(defvar *renombres* '()
  "Variables que se escriben con el nombre de otra: (b . a) escribe a donde dice b.")

(defmethod simbolo ((clase (eql 'op-igual)) (destino python)) "==")
(defmethod simbolo ((clase (eql 'op-distinto)) (destino python)) "!=")
(defmethod simbolo ((clase (eql 'op-mayor)) (destino python)) ">")
(defmethod simbolo ((clase (eql 'op-menor)) (destino python)) "<")
(defmethod simbolo ((clase (eql 'op-mayor-igual)) (destino python)) ">=")
(defmethod simbolo ((clase (eql 'op-menor-igual)) (destino python)) "<=")
(defmethod simbolo ((clase (eql 'op-suma)) (destino python)) "+")
(defmethod simbolo ((clase (eql 'op-resta)) (destino python)) "-")
(defmethod simbolo ((clase (eql 'op-multiplicacion)) (destino python)) "*")
(defmethod simbolo ((clase (eql 'op-division)) (destino python)) "/")
(defmethod simbolo ((clase (eql 'op-y)) (destino python)) "and")
(defmethod simbolo ((clase (eql 'op-o)) (destino python)) "or")

(defmethod generar-codigo ((nodo symbol) (destino python) stream)
  (format stream "~a" (nombre-python (or (cdr (assoc nodo *renombres*)) nodo))))

(defmethod generar-codigo ((nodo string) (destino python) stream)
  (format stream "~s" nodo))

(defmethod generar-codigo ((nodo ref-especifica-ent) (destino python) stream)
  (format stream "~a" (constante-python (gethash nodo (destino-constantes destino)))))

(defmethod generar-codigo ((nodo acceso-a-atributo-de-entidad) (destino python) stream)
  (format stream "~a.~a"
          (codigo (slot-value nodo 'entidad) destino)
          (nombre-python (slot-value nodo 'atributo))))

(defmethod generar-codigo ((nodo op-no) (destino python) stream)
  (format stream "(not ~a)" (codigo (slot-value nodo 'operando) destino)))

(defmethod generar-codigo ((nodo aplicacion-de-consulta) (destino python) stream)
  (format stream "~a(horario~{, ~a~})"
          (nombre-python (slot-value (slot-value nodo 'consulta) 'nombre))
          (mapcar (lambda (argumento) (codigo argumento destino))
                  (slot-value nodo 'argumentos))))

(defun linea (destino stream control &rest argumentos)
  "Escribe una línea con la sangría actual de DESTINO."
  (format stream "~a~?~%"
          (make-string (* 4 (destino-nivel destino)) :initial-element #\Space)
          control argumentos))

(defmacro con-sangria ((destino) &body cuerpo)
  "Ejecuta CUERPO con un nivel más de sangría."
  `(progn
     (incf (destino-nivel ,destino))
     ,@cuerpo
     (decf (destino-nivel ,destino))))

(defun lista-de (dominio destino)
  "Devuelve lo que se recorre para un dominio: las filas, o la lista de sus instancias."
  (if (eq dominio (problema-combinacion (modelo-problema (destino-modelo destino))))
      "horario"
      (constante-python dominio)))

(defun emitir-bucles (iteradores destino stream cuerpo &optional en-pareja)
  "Abre un bucle por cada iterador y llama a CUERPO. La segunda variable de una pareja sigue a la primera."
  (if (null iteradores)
      (funcall cuerpo)
      (destructuring-bind (variable dominio &optional pareja) (first iteradores)
        (let ((nombre (nombre-python variable))
              (lista (lista-de dominio destino)))
          (cond (en-pareja (linea destino stream "for ~a in ~a[i + 1:]:" nombre lista))
                (pareja (linea destino stream "for i, ~a in enumerate(~a):" nombre lista))
                (t (linea destino stream "for ~a in ~a:" nombre lista))))
        (con-sangria (destino)
          (emitir-bucles (rest iteradores) destino stream cuerpo pareja)))))
