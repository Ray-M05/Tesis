(in-package :emision)

(defmethod simbolo ((clase (eql 'op-igual)) (destino matematica)) "=")
(defmethod simbolo ((clase (eql 'op-distinto)) (destino matematica)) "\\ne")
(defmethod simbolo ((clase (eql 'op-mayor)) (destino matematica)) ">")
(defmethod simbolo ((clase (eql 'op-menor)) (destino matematica)) "<")
(defmethod simbolo ((clase (eql 'op-mayor-igual)) (destino matematica)) "\\ge")
(defmethod simbolo ((clase (eql 'op-menor-igual)) (destino matematica)) "\\le")
(defmethod simbolo ((clase (eql 'op-suma)) (destino matematica)) "+")
(defmethod simbolo ((clase (eql 'op-resta)) (destino matematica)) "-")
(defmethod simbolo ((clase (eql 'op-multiplicacion)) (destino matematica)) "\\cdot")
(defmethod simbolo ((clase (eql 'op-division)) (destino matematica)) "/")
(defmethod simbolo ((clase (eql 'op-y)) (destino matematica)) "\\land")
(defmethod simbolo ((clase (eql 'op-o)) (destino matematica)) "\\lor")

(defun texto-latex (texto)
  "Escapa los caracteres que LaTeX interpreta."
  (with-output-to-string (salida)
    (loop for caracter across texto
          do (cond ((find caracter "_%$&#{}")
                    (format salida "\\~a" caracter))
                   ((char= caracter #\\) (write-string "\\textbackslash{}" salida))
                   ((char= caracter #\~) (write-string "\\textasciitilde{}" salida))
                   ((char= caracter #\^) (write-string "\\textasciicircum{}" salida))
                   (t (write-char caracter salida))))))

(defun nombre-latex (simbolo)
  "Escribe un símbolo como texto de LaTeX: tipo\\_programa."
  (texto-latex (substitute #\_ #\- (string-downcase (symbol-name simbolo)))))

(defun identificador-latex (simbolo)
  "Escribe el nombre de una variable, un slot o una consulta."
  (format nil "\\textit{~a}" (nombre-latex simbolo)))

(defun conjunto-latex (entidad)
  "Escribe el conjunto de una entidad por su nombre, que es único sin más reglas."
  (format nil "\\text{~a}" (string-upcase (nombre-latex entidad))))

(defmethod generar-codigo ((nodo symbol) (destino matematica) stream)
  (format stream "~a" (identificador-latex nodo)))

(defmethod generar-codigo ((nodo string) (destino matematica) stream)
  (format stream "\\text{``~a''}" (texto-latex nodo)))

(defmethod generar-codigo ((nodo ref-especifica-ent) (destino matematica) stream)
  (format stream "\\text{~a}" (nombre-latex (gethash nodo (destino-constantes destino)))))

(defmethod generar-codigo ((nodo acceso-a-atributo-de-entidad) (destino matematica) stream)
  (format stream "~a(~a)"
          (identificador-latex (slot-value nodo 'atributo))
          (codigo (slot-value nodo 'entidad) destino)))

(defmethod generar-codigo ((nodo comprobacion-aritmetica) (destino matematica) stream)
  (format stream "~a ~a ~a"
          (codigo (slot-value nodo 'operando-izq) destino)
          (simbolo (type-of nodo) destino)
          (codigo (slot-value nodo 'operando-der) destino)))

(defmethod generar-codigo ((nodo op-no) (destino matematica) stream)
  (format stream "~a" (negada (codigo (slot-value nodo 'operando) destino) destino)))

(defmethod generar-codigo ((nodo aplicacion-de-consulta) (destino matematica) stream)
  (format stream "~a(h~{, ~a~})"
          (identificador-latex (slot-value (slot-value nodo 'consulta) 'nombre))
          (mapcar (lambda (argumento) (codigo argumento destino))
                  (slot-value nodo 'argumentos))))

(defmethod negada (texto (destino matematica))
  (format nil "\\neg(~a)" texto))

(defmethod agregado ((nodo minimizar) (destino matematica)) "\\max")
(defmethod agregado ((nodo maximizar) (destino matematica)) "-\\min")
