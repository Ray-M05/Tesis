(in-package :dsl-ast)

(define-condition error-dsl (error)
  ((mensaje :initarg :mensaje :reader mensaje-de-error))
  (:report (lambda (condicion flujo)
             (write-string (mensaje-de-error condicion) flujo))))

(defun rechazar (formato &rest argumentos)
  "Señala un error-dsl con el mensaje dado."
  (error 'error-dsl :mensaje (apply #'format nil formato argumentos)))

(defun exigir-nombre-propio (simbolo que)
  "Rechaza lo que no sea un símbolo del dominio: nombres de Common Lisp o del lenguaje."
  (unless (and (symbolp simbolo) (eq (symbol-package simbolo) *package*))
    (rechazar "~a: ~s no es un nombre propio del dominio" que simbolo)))

(defun exigir-nombre-nuevo (simbolo que)
  "Exige un nombre propio que todavía no nombre ninguna variable."
  (exigir-nombre-propio simbolo que)
  (when (boundp simbolo)
    (rechazar "~a: el nombre ~a ya está en uso" que simbolo)))

(defun exigir-variables (variables que)
  "Exige que las variables sean nombres propios y que no se repitan."
  (dolist (variable variables)
    (exigir-nombre-propio variable que)
    (when (> (count variable variables) 1)
      (rechazar "~a: la variable ~a está repetida" que variable))))

(defun repartir-claves (cuerpo permitidas que)
  "Convierte (:clave v v :clave v) en una lista de propiedades de clave y lista de valores."
  (let ((claves '()))
    (loop while cuerpo
          do (let ((clave (pop cuerpo)))
               (unless (member clave permitidas)
                 (rechazar "~a: clave ~s no permitida; se admite ~{~s~^, ~}"
                           que clave permitidas))
               (when (getf claves clave)
                 (rechazar "~a: clave ~s repetida" que clave))
               (let ((valores (loop while (and cuerpo (not (keywordp (first cuerpo))))
                                    collect (pop cuerpo))))
                 (unless valores
                   (rechazar "~a: clave ~s sin valor" que clave))
                 (setf (getf claves clave) valores))))
    claves))

(defun valor-unico (claves clave que)
  "Devuelve el único valor de una clave obligatoria."
  (let ((valores (getf claves clave)))
    (unless valores
      (rechazar "~a: falta la clave ~s" que clave))
    (unless (= (length valores) 1)
      (rechazar "~a: la clave ~s admite un solo valor" que clave))
    (first valores)))
