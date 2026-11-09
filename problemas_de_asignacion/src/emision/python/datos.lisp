(in-package :emision)

(defun emitir-etiqueta (entidad destino stream)
  "Define __str__ de una clase. Sin slots no hay nada que mostrar."
  (let ((nombres (mapcar #'nombre-python (slots-de-etiqueta entidad (destino-modelo destino)))))
    (cond ((null nombres))
          ((null (rest nombres))
           (linea destino stream "def __str__(self): return str(self.~a)" (first nombres)))
          (t
           (linea destino stream "def __str__(self): return f'(~{~a~^, ~})'"
                  (mapcar (lambda (nombre) (format nil "~a={self.~a}" nombre nombre)) nombres))))))

(defun emitir-clase (entidad destino stream)
  "Define la clase de una entidad. Sin eq, dos instancias solo son iguales si son la misma."
  (let ((slots (slots-de-entidad entidad (destino-modelo destino))))
    (linea destino stream "@dataclass(eq=False)")
    (linea destino stream "class ~a:" (clase-python entidad))
    (con-sangria (destino)
      (unless slots
        (linea destino stream "pass"))
      (dolist (slot slots)
        (linea destino stream "~a: object" (nombre-python slot)))
      (emitir-etiqueta entidad destino stream))
    (terpri stream)))

(defun emitir-instancias (entidad instancias destino stream)
  "Define una constante por instancia y la lista de la entidad, en el orden declarado."
  (let ((slots (slots-de-entidad entidad (destino-modelo destino))))
    (dolist (instancia instancias)
      (linea destino stream "~a = ~a(~{~a~^, ~})"
             (constante-python instancia)
             (clase-python entidad)
             (mapcar (lambda (slot) (codigo (slot-value (symbol-value instancia) slot) destino))
                     slots)))
    (linea destino stream "~a = [~{~a~^, ~}]"
           (constante-python entidad)
           (mapcar #'constante-python instancias))
    (terpri stream)))

(defun emitir-crear-horario (destino stream)
  "Define la identidad, los dominios de las decisiones, crear_fila y crear_horario, una fila por identidad."
  (let* ((problema (modelo-problema (destino-modelo destino)))
         (identidad (problema-identidad problema))
         (variables (problema-variables problema)))
    (linea destino stream "IDENTIDADES = ~a" (constante-python identidad))
    (linea destino stream "DOMINIOS_DE_DECISION = [~{~a~^, ~}]" (mapcar #'constante-python variables))
    (terpri stream)
    (linea destino stream "def crear_fila(i, posicion):")
    (con-sangria (destino)
      (linea destino stream "return ~a(~a=IDENTIDADES[i]~{, ~a~})"
             (clase-python (problema-combinacion problema))
             (nombre-python identidad)
             (loop for variable in variables
                   for indice from 0
                   collect (format nil "~a=~a[posicion[~d]]"
                                   (nombre-python variable)
                                   (constante-python variable)
                                   indice))))
    (terpri stream)
    (linea destino stream "def crear_horario(posiciones):")
    (con-sangria (destino)
      (linea destino stream "return [crear_fila(i, posicion) for i, posicion in enumerate(posiciones)]"))
    (terpri stream)))

(defun emitir-datos (destino stream)
  "Define las clases y las instancias, de modo que nada se use antes de definirse."
  (let* ((modelo (destino-modelo destino))
         (problema (modelo-problema modelo)))
    (dolist (entidad (modelo-orden modelo))
      (emitir-clase entidad destino stream)
      (unless (eq entidad (problema-combinacion problema))
        (emitir-instancias entidad
                           (cdr (assoc entidad (problema-instancias problema)))
                           destino stream)))
    (emitir-crear-horario destino stream)))
