(in-package :emision)

(defun combinacion-actual ()
  "Devuelve la entidad combinación."
  (problema-combinacion (problema-actual)))

(defun identidad-actual ()
  "Devuelve el slot identidad."
  (problema-identidad (problema-actual)))

(defun ruta-igual->prosa (ruta)
  "Escribe lo que dos filas comparten: el mismo tipo, la misma fecha."
  (let ((cabeza (first ruta)))
    (format nil "~a ~a" (if (femenino-p cabeza) "la misma" "el mismo") (nombre-prosa cabeza))))

(defun distinto->prosa (ruta femenino)
  "Escribe lo que separa a dos filas. Si es la identidad basta «distintas»: dos clases en aulas distintas no es lo mismo que dos clases distintas."
  (if (equal ruta (list (identidad-actual)))
      (if femenino "distintas" "distintos")
      (let ((cabeza (first ruta)))
        (format nil "de ~a ~a" (nombre-prosa cabeza :plural t)
                (if (femenino-p cabeza) "distintas" "distintos")))))

(defun no-adyacente->prosa (ruta)
  "Escribe «en turnos no consecutivos»: importa la entidad, no el atributo con que se mide."
  (let ((dimension (if (rest ruta) (second ruta) (first ruta))))
    (format nil "en ~a no consecutiv~a" (nombre-prosa dimension :plural t)
            (if (femenino-p dimension) "as" "os"))))

(defun filtros->prosa (consulta)
  "Escribe las condiciones de una fila, con artículo: valen para las dos filas del par."
  (when (pareja-filtros consulta)
    (let ((*entidades-de-variables* (append (consulta-iteradores consulta) *entidades-de-variables*))
          (*estilo-de-elision* :definido))
      (enumerar (mapcar (lambda (filtro)
                          (let ((*variable-elidida* (first filtro)))
                            (prosa (second filtro))))
                        (pareja-filtros consulta))))))

(defgeneric adyacentes-de (consulta)
  (:documentation "Devuelve las rutas consecutivas de una pareja."))

(defmethod adyacentes-de ((consulta pareja)) nil)
(defmethod adyacentes-de ((consulta relacion-ordenada)) (relacion-adyacentes consulta))

(defgeneric no-adyacentes-de (consulta)
  (:documentation "Devuelve las rutas no consecutivas de una pareja."))

(defmethod no-adyacentes-de ((consulta pareja)) nil)
(defmethod no-adyacentes-de ((consulta relacion-ordenada)) (relacion-no-adyacentes consulta))

(defun partes-de-pareja (consulta)
  "Devuelve el sujeto, los calificadores y las rutas de decisión de una pareja."
  (let* ((entidad (combinacion-actual))
         (femenino (femenino-p entidad))
         (calificadores '()))
    (dolist (ruta (pareja-distintos consulta))
      (push (distinto->prosa ruta femenino) calificadores))
    (when (adyacentes-de consulta)
      (push (if femenino "consecutivas" "consecutivos") calificadores))
    (dolist (ruta (pareja-clave consulta))
      (push (format nil "de ~a" (ruta-igual->prosa ruta)) calificadores))
    (dolist (variable (pareja-papeles consulta))
      (push (format nil "que compartan ~a"
                    (sintagma (second (assoc variable (consulta-iteradores consulta)))))
            calificadores))
    (values (nombre-prosa entidad :plural t)
            (nreverse calificadores)
            (pareja-celda consulta))))

(defun cola-de-pareja (consulta)
  "Escribe lo que modifica a la pareja entera: la no adyacencia y los filtros."
  (format nil "~{ ~a~}~@[, cuando ~a~]"
          (mapcar #'no-adyacente->prosa (no-adyacentes-de consulta))
          (filtros->prosa consulta)))

(defun condiciones-de-fila-prosa (consulta)
  "Escribe la condición de una consulta sobre una sola fila, con la variable elidida."
  (let ((*entidades-de-variables* (append (consulta-iteradores consulta) *entidades-de-variables*))
        (*variable-elidida* (first (first (consulta-iteradores consulta)))))
    (prosa (consulta-condicion consulta))))

(defun ninguna (entidad)
  "Escribe «Ninguna ubicación» o «Ningún bloque»."
  (format nil "~a ~a" (if (femenino-p entidad) "Ninguna" "Ningún") (nombre-prosa entidad)))

(defgeneric oracion (consulta)
  (:documentation "Escribe la oración prohibitiva de una familia, o nil si no tiene."))

(defgeneric sustantivo (consulta)
  (:documentation "Escribe el sintagma nominal de una familia, o nil si no tiene."))

(defmethod oracion ((consulta pareja))
  (multiple-value-bind (sujeto calificadores decisiones) (partes-de-pareja consulta)
    (when decisiones
      (format nil "No puede haber dos ~a~{ ~a~} con ~a~a."
              sujeto calificadores
              (enumerar (mapcar #'ruta-igual->prosa decisiones))
              (cola-de-pareja consulta)))))

(defmethod sustantivo ((consulta pareja))
  (multiple-value-bind (sujeto calificadores decisiones) (partes-de-pareja consulta)
    (when decisiones
      (format nil "pares de ~a~{ ~a~} con ~a~a"
              sujeto calificadores
              (enumerar (mapcar #'ruta-igual->prosa decisiones))
              (cola-de-pareja consulta)))))

(defun oracion-de-fila (consulta)
  "Escribe la oración de una consulta sobre una sola fila."
  (format nil "~a puede cumplir lo siguiente: ~a."
          (ninguna (combinacion-actual)) (condiciones-de-fila-prosa consulta)))

(defun sustantivo-de-fila (consulta)
  "Escribe el sintagma de una consulta sobre una sola fila."
  (format nil "~a en que ~a"
          (nombre-prosa (combinacion-actual) :plural t) (condiciones-de-fila-prosa consulta)))

(defmethod oracion ((consulta filtro-de-fila)) (oracion-de-fila consulta))
(defmethod sustantivo ((consulta filtro-de-fila)) (sustantivo-de-fila consulta))

(defun cola-de-agrupacion (dimension)
  "Escribe «en una misma instalación». El artículo sale del género: un aula, pero una misma aula."
  (let ((femenino (femenino-p dimension)))
    (format nil "en ~a mism~a ~a"
            (if femenino "una" "un") (if femenino "a" "o") (nombre-prosa dimension))))

(defun dimension-unica (consulta)
  "Devuelve la dimensión si la consulta agrupa por un solo parámetro y una sola igualdad."
  (let ((dimensiones (agrupacion-dimensiones consulta)))
    (when (and (null (rest dimensiones)) (null (rest (consulta-parametros consulta))))
      (first (second (first dimensiones))))))

(defmethod oracion ((consulta agrupacion)) (oracion-de-fila consulta))

(defmethod sustantivo ((consulta agrupacion))
  (let ((dimension (dimension-unica consulta)))
    (if dimension
        (format nil "~a que caen ~a"
                (nombre-prosa (identidad-actual) :plural t) (cola-de-agrupacion dimension))
        (sustantivo-de-fila consulta))))

(defun dimensiones-de-cruce (consulta)
  "Escribe en qué coincide una fila con la tabla."
  (enumerar (mapcar (lambda (dimension) (sintagma dimension :definido t))
                    (cruce-dimensiones consulta))))

(defmethod oracion ((consulta cruce-contra-tabla))
  (format nil "~a puede coincidir con ~a en ~a."
          (ninguna (combinacion-actual))
          (sintagma (cruce-tabla consulta))
          (dimensiones-de-cruce consulta)))

(defmethod sustantivo ((consulta cruce-contra-tabla))
  (format nil "~a que coinciden con ~a en ~a"
          (nombre-prosa (combinacion-actual) :plural t)
          (sintagma (cruce-tabla consulta))
          (dimensiones-de-cruce consulta)))

(defmethod oracion ((consulta consulta-generica)) nil)
(defmethod sustantivo ((consulta consulta-generica)) nil)

(defun interviene->prosa (operacion)
  "Escribe lo que cuenta una consulta de valores distintos sobre un parámetro."
  (let ((slot (first (camino (slot-value operacion 'expresion)))))
    (format nil "el número de ~a en ~a que interviene"
            (distintos->prosa operacion) (if (femenino-p slot) "las" "los"))))

(defgeneric medida-prosa (operacion consulta)
  (:documentation "Escribe lo que mide una consulta: su frase si la tiene y, si no, la capa literal."))

(defmethod medida-prosa ((operacion suma) consulta)
  (let ((frase (sustantivo consulta)))
    (if frase
        (format nil "el número de ~a" frase)
        (consulta->prosa consulta))))

(defmethod medida-prosa ((operacion contar-distintos) consulta)
  (if (consulta-parametros consulta)
      (interviene->prosa operacion)
      (consulta->prosa consulta)))

(defgeneric oracion-de-operacion (operacion consulta)
  (:documentation "Escribe la oración de una consulta. Las familias solo valen si se cuentan filas."))

(defmethod oracion-de-operacion ((operacion suma) consulta) (oracion consulta))
(defmethod oracion-de-operacion ((operacion contar-distintos) consulta)
  (declare (ignore consulta))
  nil)

(defun consulta-de-medida (restriccion)
  "Devuelve la consulta del modelo que una restricción mide."
  (consulta-de (slot-value (restriccion-medida restriccion) 'consulta)))

(defun frase-de-prohibicion (restriccion nodo)
  "Escribe una prohibición. Solo (op-mayor consulta 0) significa que no ocurra ninguna vez."
  (let ((comprobacion (slot-value nodo 'comprobacion)))
    (when (and (typep (slot-value comprobacion 'operando-izq) 'aplicacion-de-consulta)
               (eql (slot-value comprobacion 'operando-der) 0))
      (let ((consulta (consulta-de-medida restriccion)))
        (oracion-de-operacion (consulta-operacion consulta) consulta)))))

(defgeneric relacion-de (comparador)
  (:documentation "Escribe qué exige un comparador en una cota, o nil si no tiene frase."))

(defmethod relacion-de ((comparador (eql 'op-igual))) "debe ser igual a")
(defmethod relacion-de ((comparador (eql 'op-menor-igual))) "no puede superar")
(defmethod relacion-de ((comparador (eql 'op-mayor-igual))) "no puede quedar por debajo de")
(defmethod relacion-de ((comparador (eql 'op-menor))) "tiene que ser menor que")
(defmethod relacion-de ((comparador (eql 'op-mayor))) "tiene que ser mayor que")
(defmethod relacion-de ((comparador (eql 'op-distinto))) nil)

(defgeneric umbral-prosa (umbral)
  (:documentation "Escribe el umbral de una cota, o nil si no tiene frase."))

(defmethod umbral-prosa ((umbral number)) (format nil "~a" umbral))
(defmethod umbral-prosa ((umbral nodo-ast)) nil)
(defmethod umbral-prosa ((umbral acceso-a-atributo-de-entidad))
  (format nil "su ~a" (nombre-prosa (slot-value umbral 'atributo))))

(defun frase-de-cota (restriccion)
  "Escribe una cota con :para: el número de ubicaciones de cada profesor y cada día no puede superar 5."
  (let ((relacion (relacion-de (cota-comparador restriccion)))
        (umbral (umbral-prosa (cota-umbral restriccion))))
    (when (and relacion umbral (restriccion-variables restriccion))
      (format nil "El número de ~a de ~a ~a ~a."
              (nombre-prosa (combinacion-actual) :plural t)
              (enumerar (mapcar (lambda (variable) (format nil "cada ~a" (nombre-prosa (second variable))))
                                (restriccion-variables restriccion)))
              relacion
              umbral))))

(defgeneric minimax-de-operacion (operacion consulta entidad)
  (:documentation "Escribe un minimizar según lo que mide su consulta."))

(defmethod minimax-de-operacion ((operacion contar-distintos) consulta entidad)
  (declare (ignore consulta))
  (format nil "Se prefiere la solución que minimiza, para ~a más cargad~a, ~a."
          (sintagma entidad :definido t)
          (if (femenino-p entidad) "a" "o")
          (interviene->prosa operacion)))

(defgeneric minimax-de-familia (consulta entidad)
  (:documentation "Escribe un minimizar de filas según la familia de su consulta, o nil."))

(defmethod minimax-de-familia ((consulta consulta-m) entidad)
  (declare (ignore entidad))
  nil)

(defmethod minimax-de-familia ((consulta agrupacion) entidad)
  (when (eq (dimension-unica consulta) entidad)
    (format nil "Se prefiere el reparto que reduce el número máximo de ~a ~a."
            (nombre-prosa (identidad-actual) :plural t)
            (cola-de-agrupacion entidad))))

(defmethod minimax-de-familia ((consulta pareja) entidad)
  (let ((frase (sustantivo consulta)))
    (when frase
      (format nil "Se prefiere la solución que minimiza, para ~a más afectad~a, el número de ~a."
              (sintagma entidad :definido t)
              (if (femenino-p entidad) "a" "o")
              frase))))

(defmethod minimax-de-operacion ((operacion suma) consulta entidad)
  (minimax-de-familia consulta entidad))

(defun frase-de-minimizar (restriccion)
  "Escribe un minimizar de una consulta sobre una sola entidad."
  (let ((medida (restriccion-medida restriccion))
        (variables (restriccion-variables restriccion)))
    (when (and (typep medida 'aplicacion-de-consulta) (null (rest variables)))
      (let ((consulta (consulta-de-medida restriccion)))
        (minimax-de-operacion (consulta-operacion consulta) consulta (second (first variables)))))))

(defgeneric idioma (restriccion nodo)
  (:documentation "Escribe la frase hecha de una restricción, o nil para caer a la capa literal."))

(defmethod idioma ((restriccion restriccion-generica) nodo)
  (declare (ignore nodo))
  nil)

(defmethod idioma ((restriccion prohibicion) (nodo cuantificador-restriccion)) nil)
(defmethod idioma ((restriccion prohibicion) (nodo nppq)) (frase-de-prohibicion restriccion nodo))
(defmethod idioma ((restriccion prohibicion) (nodo ndpq)) (frase-de-prohibicion restriccion nodo))

(defmethod idioma ((restriccion cota) (nodo cuantificador-restriccion)) nil)
(defmethod idioma ((restriccion cota) (nodo tqpq)) (frase-de-cota restriccion))
(defmethod idioma ((restriccion cota) (nodo sbqp)) (frase-de-cota restriccion))

(defmethod idioma ((restriccion minimax) (nodo minimizar)) (frase-de-minimizar restriccion))
(defmethod idioma ((restriccion minimax) (nodo maximizar)) nil)

(defun restriccion->prosa (restriccion)
  "Escribe una restricción: su frase hecha o, si no la tiene, nodo a nodo. Nunca falla."
  (let ((nodo (restriccion-nodo restriccion)))
    (contraer (or (idioma restriccion nodo)
                  (restriccion-literal nodo restriccion)))))
