(in-package :emision)

(defun bucles-de-generador (restriccion)
  "Escribe los for de :para dentro de una expresión generadora."
  (format nil "~{for ~a in ~a~^ ~}"
          (loop for (variable dominio) in (restriccion-variables restriccion)
                collect (nombre-python variable)
                collect (constante-python dominio))))

(defmethod negada (texto (destino python))
  (format nil "not ~a" texto))

(defmethod agregado ((nodo minimizar) (destino python)) "max")
(defmethod agregado ((nodo maximizar) (destino python)) "-min")

(defun emitir-agregado (restriccion expresion destino stream)
  "Escribe el valor de un objetivo sobre su :para."
  (linea destino stream "return ~a((~a ~a), default=0)"
         (agregado (restriccion-nodo restriccion) destino)
         (codigo expresion destino)
         (bucles-de-generador restriccion)))

(defgeneric emitir-generica (nodo restriccion destino stream)
  (:documentation "Escribe el cuerpo de una restricción sin forma reconocida."))

(defmethod emitir-generica ((nodo cuantificador-restriccion) restriccion destino stream)
  (linea destino stream "total = 0")
  (emitir-bucles (restriccion-variables restriccion) destino stream
                 (lambda ()
                   (linea destino stream "if ~a:" (condicion-incumplida nodo destino))
                   (con-sangria (destino)
                     (linea destino stream "total += 1"))))
  (linea destino stream "return total"))

(defmethod emitir-generica ((nodo objetivo) restriccion destino stream)
  (emitir-agregado restriccion (slot-value nodo 'comprobacion) destino stream))

(defmethod emitir-restriccion :around ((restriccion restriccion-m) (destino python) stream)
  (linea destino stream "def ~a(horario):" (nombre-python (restriccion-nombre restriccion)))
  (con-sangria (destino)
    (call-next-method))
  (terpri stream))

(defmethod emitir-restriccion ((restriccion prohibicion) (destino python) stream)
  (linea destino stream "return ~a" (codigo (restriccion-medida restriccion) destino)))

(defmethod emitir-restriccion ((restriccion cota) (destino python) stream)
  (let* ((incumplimiento (cota-incumplimiento restriccion))
         (comparador (type-of incumplimiento))
         (limite (codigo (slot-value incumplimiento 'operando-der) destino)))
    (linea destino stream "total = 0")
    (emitir-bucles (restriccion-variables restriccion) destino stream
                   (lambda ()
                     (linea destino stream "q = ~a" (codigo (restriccion-medida restriccion) destino))
                     (linea destino stream "if q ~a ~a:" (simbolo comparador destino) limite)
                     (con-sangria (destino)
                       (linea destino stream "total += abs(q - ~a)~[~; + 1~]"
                              limite (margen-de-incumplimiento comparador)))))
    (linea destino stream "return total")))

(defmethod emitir-restriccion ((restriccion minimax) (destino python) stream)
  (emitir-agregado restriccion (restriccion-medida restriccion) destino stream))

(defmethod emitir-restriccion ((restriccion restriccion-generica) (destino python) stream)
  (emitir-generica (restriccion-nodo restriccion) restriccion destino stream))

(defgeneric prohibicion-dura-p (restriccion)
  (:documentation "Dice si la restricción es una prohibición dura: tiene sentido en un horario a medias."))

(defmethod prohibicion-dura-p ((restriccion restriccion-m)) nil)
(defmethod prohibicion-dura-p ((restriccion prohibicion)) (null (restriccion-peso restriccion)))

(defgeneric de-una-fila-p (consulta)
  (:documentation "Dice si la consulta se puede comprobar mirando una sola fila."))

(defmethod de-una-fila-p ((consulta consulta-m)) nil)
(defmethod de-una-fila-p ((consulta filtro-de-fila)) t)
(defmethod de-una-fila-p ((consulta cruce-contra-tabla)) t)

(defun emitir-grupos-de-restricciones (destino stream)
  "Define las listas de nombres que usan las estrategias: prohibiciones, las de una fila y las constantes."
  (let* ((restricciones (modelo-restricciones (destino-modelo destino)))
         (prohibiciones (remove-if-not #'prohibicion-dura-p restricciones)))
    (flet ((nombres (lista)
             (mapcar (lambda (restriccion) (nombre-python (restriccion-nombre restriccion))) lista)))
      (linea destino stream "PROHIBICIONES = [~{~s~^, ~}]" (nombres prohibiciones))
      (linea destino stream "DE_UNA_FILA = [~{~s~^, ~}]"
             (nombres (remove-if-not (lambda (restriccion)
                                       (every #'de-una-fila-p (restriccion-consultas restriccion)))
                                     prohibiciones)))
      (linea destino stream "CONSTANTES = [~{~s~^, ~}]"
             (nombres (remove-if #'restriccion-decisiones restricciones)))
      (terpri stream))))

(defun emitir-evaluar (destino stream)
  "Define la tabla de restricciones, con peso None en las duras, y evaluar."
  (linea destino stream "RESTRICCIONES = [")
  (con-sangria (destino)
    (dolist (restriccion (modelo-restricciones (destino-modelo destino)))
      (let ((nombre (nombre-python (restriccion-nombre restriccion)))
            (peso (restriccion-peso restriccion)))
        (linea destino stream "(~s, ~a, ~a),"
               nombre (if peso (codigo peso destino) "None") nombre))))
  (linea destino stream "]")
  (terpri stream)
  (emitir-grupos-de-restricciones destino stream)
  (linea destino stream "def evaluar(horario):")
  (con-sangria (destino)
    (linea destino stream "return {nombre: funcion(horario) for nombre, _, funcion in RESTRICCIONES}"))
  (terpri stream))
