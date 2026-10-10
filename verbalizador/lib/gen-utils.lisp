;; === gen-utils.lisp — Utilidades básicas ===
;; Funciones de utilidad general usadas por el resto del generador:
;;   py-nombre, py-indent, flatten-op, math-nombre

(defun py-nombre (sym)
  "Símbolo Lisp → identificador Python válido  (- → _)."
  (string-downcase (substitute #\_ #\- (symbol-name sym))))

(defun py-indent (n)
  "Devuelve n*4 espacios."
  (make-string (* n 4) :initial-element #\Space))

(defun flatten-op (nodo clase)
  "Aplana un árbol binario asociativo en lista de operandos."
  (if (typep nodo clase)
      (append (flatten-op (slot-value nodo 'operando-izq) clase)
              (flatten-op (slot-value nodo 'operando-der) clase))
      (list nodo)))

(defun math-nombre (sym)
  "Símbolo → identificador matemático."
  (string-downcase (substitute #\_ #\- (symbol-name sym))))
