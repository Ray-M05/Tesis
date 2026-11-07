(in-package :emision)

(defvar *duenos*)

(defun capitalizar (cadena)
  "Pone en mayúscula la inicial sin tocar el resto."
  (if (zerop (length cadena))
      cadena
      (concatenate 'string (string-upcase (subseq cadena 0 1)) (subseq cadena 1))))

(defparameter *numeros*
  #("cero" "uno" "dos" "tres" "cuatro" "cinco" "seis" "siete" "ocho" "nueve"
    "diez" "once" "doce" "trece" "catorce" "quince" "dieciséis" "diecisiete"
    "dieciocho" "diecinueve" "veinte"))

(defun numero->prosa (numero)
  "Escribe un número en letra hasta 20; por encima, en cifras."
  (if (and (integerp numero) (<= 0 numero 20))
      (aref *numeros* numero)
      (format nil "~a" numero)))

(defgeneric etiqueta (valor)
  (:documentation "Escribe cómo se nombra un valor en prosa."))

(defmethod etiqueta ((valor string)) valor)
(defmethod etiqueta ((valor number)) (format nil "~a" valor))

(defmethod etiqueta ((valor ref-especifica-ent))
  (let* ((entidad (gethash valor *duenos*))
         (slots (slots-de-etiqueta entidad (modelo-actual))))
    (if (rest slots)
        (format nil "(~{~a~^, ~})"
                (mapcar (lambda (slot)
                          (format nil "~a ~a" (nombre-prosa slot) (etiqueta (slot-value valor slot))))
                        slots))
        (etiqueta (slot-value valor (first slots))))))

(defun entidad->prosa (entidad)
  "Presenta una entidad. Los slots booleanos no se tienen, se dicen: dice si admite turno doble."
  (let* ((slots (slots-de-entidad entidad (modelo-actual)))
         (predicados (remove-if-not #'frase-de-predicado slots))
         (otros (remove-if #'frase-de-predicado slots))
         (sujeto (capitalizar (sintagma entidad)))
         (dice (enumerar (mapcar (lambda (slot) (format nil "si ~a" (frase-de-predicado slot)))
                                 predicados))))
    (cond ((and otros predicados)
           (format nil "~a tiene ~a, y dice ~a."
                   sujeto (enumerar (mapcar #'nombre-prosa otros)) dice))
          (predicados (format nil "~a dice ~a." sujeto dice))
          (otros (format nil "~a tiene ~a." sujeto (enumerar (mapcar #'nombre-prosa otros))))
          (t (format nil "~a no tiene atributos." sujeto)))))

(defun combinacion->prosa (entidad)
  "Presenta la combinación: una emisión está formada por un bloque y un programa."
  (format nil "~a está ~a por ~a."
          (capitalizar (sintagma entidad))
          (if (femenino-p entidad) "formada" "formado")
          (enumerar (mapcar #'sintagma (slots-de-entidad entidad (modelo-actual))))))

(defun datos->prosa (entidad &key (limite 10))
  "Presenta los datos: se enumeran si son pocos y se cuentan si son muchos."
  (let* ((instancias (mapcar #'symbol-value
                             (cdr (assoc entidad (problema-instancias (problema-actual))))))
         (cuantas (length instancias)))
    (cond ((zerop cuantas) nil)
          ((= cuantas 1)
           (format nil "Hay ~a: ~a." (sintagma entidad) (etiqueta (first instancias))))
          ((<= cuantas limite)
           (format nil "Hay ~a ~a: ~a."
                   (numero->prosa cuantas) (nombre-prosa entidad :plural t)
                   (enumerar (mapcar #'etiqueta instancias))))
          (t
           (format nil "Hay ~a ~a." (numero->prosa cuantas) (nombre-prosa entidad :plural t))))))

(defun mecanicas ()
  "Devuelve las consultas que solo miden una cota con :para: no son indicadores del problema."
  (loop for restriccion in (modelo-restricciones (modelo-actual))
        when (and (typep restriccion 'cota)
                  (typep (restriccion-nodo restriccion) '(or tqpq sbqp))
                  (restriccion-variables restriccion))
          collect (consulta-de-medida restriccion)))

(defun decision->prosa ()
  "Escribe qué se decide."
  (let ((variables (problema-variables (problema-actual))))
    (format nil "Cada fila del horario es ~a. Se decide, para cada ~a, ~a ~a."
            (sintagma (combinacion-actual))
            (nombre-prosa (identidad-actual))
            (enumerar (mapcar (lambda (variable) (format nil "qué ~a" (nombre-prosa variable))) variables))
            (if (rest variables) "le corresponden" "le corresponde"))))

(defmethod emitir-consulta ((consulta consulta-m) (destino verbalizador) stream)
  (let ((*entidades-de-variables* (append (consulta-iteradores consulta) *entidades-de-variables*)))
    (format stream "**~a.** Se cuenta ~a.~%~%"
            (capitalizar (nombre-prosa (consulta-nombre consulta)))
            (contraer (medida-prosa (consulta-operacion consulta) consulta)))))

(defmethod emitir-restriccion ((restriccion restriccion-m) (destino verbalizador) stream)
  (format stream "**~a.** ~a~%~%"
          (capitalizar (nombre-prosa (restriccion-nombre restriccion)))
          (restriccion->prosa restriccion)))

(defmethod emitir ((destino verbalizador) stream)
  (let* ((*verbalizador* destino)
         (modelo (destino-modelo destino))
         (*duenos* (duenos-de-instancias (modelo-problema modelo)))
         (restricciones (modelo-restricciones modelo)))
    (format stream "# Descripción del problema~%~%## Entidades~%~%")
    (dolist (entidad (modelo-orden modelo))
      (format stream "~a~%~%" (if (eq entidad (combinacion-actual))
                                  (combinacion->prosa entidad)
                                  (entidad->prosa entidad))))
    (format stream "## Datos~%~%")
    (dolist (entidad (modelo-orden modelo))
      (let ((linea (datos->prosa entidad)))
        (when linea
          (format stream "~a~%~%" linea))))
    (format stream "## Qué se decide~%~%~a~%~%" (decision->prosa))
    (format stream "## Qué se mide~%~%")
    (let ((mecanicas (mecanicas)))
      (dolist (consulta (modelo-consultas modelo))
        (unless (member consulta mecanicas)
          (emitir-consulta consulta destino stream))))
    (format stream "## Restricciones~%~%### Obligatorias~%~%")
    (dolist (restriccion (remove-if #'restriccion-peso restricciones))
      (emitir-restriccion restriccion destino stream))
    (format stream "### Preferencias~%~%")
    (dolist (restriccion (remove-if-not #'restriccion-peso restricciones))
      (emitir-restriccion restriccion destino stream))))
