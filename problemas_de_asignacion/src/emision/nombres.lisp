(in-package :emision)

(defparameter *reservadas-python*
  '("and" "as" "assert" "async" "await" "break" "class" "continue" "def" "del" "elif" "else"
    "except" "false" "finally" "for" "from" "global" "if" "import" "in" "is" "lambda" "none"
    "nonlocal" "not" "or" "pass" "raise" "return" "true" "try" "while" "with" "yield"
    "abs" "counter" "dataclass" "enumerate" "len" "max" "min" "object" "print" "self" "set"
    "str" "sum" "zip"
    "a_json" "constantes" "crear_fila" "crear_horario" "de_una_fila" "dominios_de_decision"
    "evaluar" "grupos" "horario" "i" "identidades" "mostrar_resultado" "prohibiciones"
    "q" "restricciones" "total" "valores")
  "Palabras de Python y nombres del código generado, que un dominio no puede ocupar.")

(defun identificador-valido-p (texto)
  "Dice si TEXTO se puede escribir como identificador de Python."
  (and (plusp (length texto))
       (not (digit-char-p (char texto 0)))
       (every (lambda (caracter) (or (alphanumericp caracter) (char= caracter #\_))) texto)))

(defun nombre-python (simbolo)
  "Convierte un símbolo en un identificador, y escapa los reservados con un guion bajo final."
  (let ((texto (substitute #\_ #\- (string-downcase (symbol-name simbolo)))))
    (unless (identificador-valido-p texto)
      (rechazar "python: ~s no se puede escribir como identificador" simbolo))
    (if (member texto *reservadas-python* :test #'string=)
        (concatenate 'string texto "_")
        texto)))

(defun clase-python (simbolo)
  "Devuelve el nombre de la clase de una entidad: Tipo_Programa."
  (string-capitalize (nombre-python simbolo)))

(defun constante-python (simbolo)
  "Devuelve el nombre de una instancia o de la lista de una entidad: TIPO_PROGRAMA."
  (string-upcase (nombre-python simbolo)))

(defun exigir-distintos (que nombres)
  "Rechaza dos símbolos de NOMBRES que en Python se escribirían igual."
  (let ((repetido (find-if (lambda (nombre) (> (count nombre nombres :test #'string=) 1))
                           nombres)))
    (when repetido
      (rechazar "python: hay dos ~a que se escribirían ~a" que repetido))))

(defun exigir-nombres-distintos (modelo)
  "Exige que las funciones y las constantes del modelo no choquen al escribirse en Python."
  (let ((problema (modelo-problema modelo)))
    (exigir-distintos "funciones"
                      (mapcar #'nombre-python
                              (append (mapcar #'consulta-nombre (modelo-consultas modelo))
                                      (mapcar #'restriccion-nombre (modelo-restricciones modelo)))))
    (exigir-distintos "constantes"
                      (mapcar #'constante-python
                              (append (problema-entidades problema)
                                      (mapcan (lambda (par) (copy-list (cdr par)))
                                              (problema-instancias problema)))))))

(defun slots-de-entidad (entidad modelo)
  "Devuelve los slots de ENTIDAD."
  (cdr (assoc entidad (problema-slots (modelo-problema modelo)))))

(defun slots-de-etiqueta (entidad modelo)
  "Devuelve con qué slots se nombra una instancia: su único slot de texto o, si no, todos."
  (let* ((slots (slots-de-entidad entidad modelo))
         (textos (remove-if-not (lambda (slot)
                                  (eq :texto (cdr (assoc (cons entidad slot) (modelo-tipos modelo)
                                                         :test #'equal))))
                                slots)))
    (if (= (length textos) 1) textos slots)))
