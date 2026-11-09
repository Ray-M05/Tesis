(in-package :emision)

(defun bloque (stream lineas)
  "Escribe LINEAS en un entorno align*."
  (format stream "\\begin{align*}~%~{~a~^ \\\\~%~}~%\\end{align*}~%~%" lineas))

(defun iterador-latex (iterador pareja)
  "Escribe un iterador. Los dos de una pareja van juntos, porque el par no tiene orden."
  (destructuring-bind (variable dominio &optional en-pareja) iterador
    (if en-pareja
        (format nil "\\{~a, ~a\\} \\subseteq ~a"
                (identificador-latex (first (first pareja)))
                (identificador-latex (first (second pareja)))
                (conjunto-latex dominio))
        (format nil "~a \\in ~a" (identificador-latex variable) (conjunto-latex dominio)))))

(defun indices-latex (iteradores)
  "Escribe los índices de un sumatorio, con una sola entrada por pareja."
  (let ((pareja (remove-if-not #'third iteradores)))
    (format nil "~{~a~^,\\ ~}"
            (mapcar (lambda (iterador) (iterador-latex iterador pareja))
                    (remove (second pareja) iteradores)))))

(defun cuantificador-latex (variables)
  "Escribe el cuantificador universal de :para. Sin variables no escribe nada."
  (format nil "~{\\forall\\, ~a~^,\\ ~}~:[~;:\\quad ~]"
          (mapcar (lambda (variable) (iterador-latex variable nil)) variables)
          variables))

(defun sumatorio-latex (variables)
  "Escribe el sumatorio de :para. Sin variables no escribe nada."
  (if variables
      (format nil "\\sum_{~a} " (indices-latex variables))
      ""))

(defun lineas-de-condicion (apertura condicion cierre destino)
  "Escribe una conjunción con una línea por átomo, alineadas."
  (let ((atomos (mapcar (lambda (atomo) (codigo atomo destino)) (aplanar 'op-y condicion))))
    (append (list (format nil "~a & ~a~@[~a~]" apertura (first atomos)
                          (and (null (rest atomos)) cierre)))
            (loop for (atomo . resto) on (rest atomos)
                  collect (format nil "\\land\\ & ~a~@[~a~]" atomo (and (null resto) cierre))))))

(defun firma-de-consulta (consulta)
  "Escribe el lado izquierdo de la definición de una consulta."
  (format nil "~a(h~{, ~a~})"
          (identificador-latex (consulta-nombre consulta))
          (mapcar (lambda (parametro) (identificador-latex (first parametro)))
                  (consulta-parametros consulta))))

(defgeneric definicion (operacion consulta destino)
  (:documentation "Devuelve las líneas de la definición de una consulta según su operación."))

(defmethod definicion ((operacion suma) consulta destino)
  (let ((expresion (slot-value operacion 'expresion)))
    (lineas-de-condicion
     (format nil "~a = \\sum_{~a} ~:[~a \\cdot ~;~*~][\\,"
             (firma-de-consulta consulta)
             (indices-latex (consulta-iteradores consulta))
             (eql expresion 1)
             (codigo expresion destino))
     (consulta-condicion consulta)
     "\\,]"
     destino)))

(defmethod definicion ((operacion contar-distintos) consulta destino)
  (lineas-de-condicion
   (format nil "~a = |\\{\\, ~a :\\ ~a,\\ "
           (firma-de-consulta consulta)
           (codigo (slot-value operacion 'expresion) destino)
           (indices-latex (consulta-iteradores consulta)))
   (consulta-condicion consulta)
   "\\,\\}|"
   destino))

(defmethod emitir-consulta ((consulta consulta-m) (destino matematica) stream)
  (bloque stream (definicion (consulta-operacion consulta) consulta destino)))

(defgeneric requisito (restriccion destino)
  (:documentation "Escribe lo que la restricción exige, o nil si es un objetivo."))

(defmethod requisito ((restriccion prohibicion) destino)
  (format nil "~a = 0" (codigo (restriccion-medida restriccion) destino)))

(defmethod requisito ((restriccion cota) destino)
  (let ((incumplimiento (cota-incumplimiento restriccion)))
    (format nil "~a~a ~a ~a"
            (cuantificador-latex (restriccion-variables restriccion))
            (codigo (restriccion-medida restriccion) destino)
            (simbolo (negado (type-of incumplimiento)) destino)
            (codigo (slot-value incumplimiento 'operando-der) destino))))

(defmethod requisito ((restriccion minimax) destino)
  (declare (ignore destino))
  nil)

(defgeneric requisito-generico (nodo restriccion destino)
  (:documentation "Escribe lo que exige una restricción sin forma reconocida."))

(defmethod requisito-generico ((nodo cuantificador-restriccion) restriccion destino)
  (format nil "~a~a"
          (cuantificador-latex (restriccion-variables restriccion))
          (condicion-exigida nodo destino)))

(defmethod requisito-generico ((nodo objetivo) restriccion destino)
  (declare (ignore restriccion destino))
  nil)

(defmethod requisito ((restriccion restriccion-generica) destino)
  (requisito-generico (restriccion-nodo restriccion) restriccion destino))

(defgeneric valor (restriccion destino)
  (:documentation "Escribe cuánto vale una restricción, que es su término en el objetivo."))

(defmethod valor ((restriccion prohibicion) destino)
  (codigo (restriccion-medida restriccion) destino))

(defmethod valor ((restriccion cota) destino)
  (let* ((incumplimiento (cota-incumplimiento restriccion))
         (margen (margen-de-incumplimiento (type-of incumplimiento))))
    (format nil "~a[~a] \\cdot (|~a - ~a|~[~; + 1~])"
            (sumatorio-latex (restriccion-variables restriccion))
            (codigo incumplimiento destino)
            (codigo (restriccion-medida restriccion) destino)
            (codigo (slot-value incumplimiento 'operando-der) destino)
            margen)))

(defun valor-agregado (restriccion expresion destino)
  "Escribe el valor de un objetivo sobre su :para."
  (format nil "~a_{~a} ~a"
          (agregado (restriccion-nodo restriccion) destino)
          (indices-latex (restriccion-variables restriccion))
          (codigo expresion destino)))

(defmethod valor ((restriccion minimax) destino)
  (valor-agregado restriccion (restriccion-medida restriccion) destino))

(defgeneric valor-generico (nodo restriccion destino)
  (:documentation "Escribe cuánto vale una restricción sin forma reconocida."))

(defmethod valor-generico ((nodo cuantificador-restriccion) restriccion destino)
  (format nil "~a[~a]"
          (sumatorio-latex (restriccion-variables restriccion))
          (condicion-incumplida nodo destino)))

(defmethod valor-generico ((nodo objetivo) restriccion destino)
  (valor-agregado restriccion (slot-value nodo 'comprobacion) destino))

(defmethod valor ((restriccion restriccion-generica) destino)
  (valor-generico (restriccion-nodo restriccion) restriccion destino))

(defun indice-de (restriccion destino)
  "Devuelve el número de una restricción en el modelo."
  (1+ (position restriccion (modelo-restricciones (destino-modelo destino)))))

(defmethod emitir-restriccion ((restriccion restriccion-m) (destino matematica) stream)
  (let ((indice (indice-de restriccion destino))
        (exigido (requisito restriccion destino)))
    (format stream "\\paragraph{R~d. ~a}~%~%" indice
            (nombre-latex (restriccion-nombre restriccion)))
    (when exigido
      (bloque stream (list exigido)))
    (when (restriccion-peso restriccion)
      (bloque stream (list (format nil "v_{~d}(h) = ~a" indice (valor restriccion destino)))))
    (when (restriccion-consultas restriccion)
      (format stream "Donde:~%~%")
      (dolist (consulta (restriccion-consultas restriccion))
        (emitir-consulta consulta destino stream)))))

(defun emitir-conjuntos (destino stream)
  "Escribe el tamaño de cada conjunto que el modelo recorre."
  (let ((problema (modelo-problema (destino-modelo destino))))
    (format stream "\\subsubsection*{Conjuntos}~%~%")
    (bloque stream
            (mapcar (lambda (entidad)
                      (format nil "|~a| &= ~d" (conjunto-latex entidad)
                              (length (cdr (assoc entidad (problema-instancias problema))))))
                    (modelo-dominios (destino-modelo destino))))))

(defun emitir-decisiones (destino stream)
  "Escribe qué se decide en cada fila del horario."
  (let ((problema (modelo-problema (destino-modelo destino))))
    (format stream "\\subsubsection*{Decisiones}~%~%")
    (format stream "Un horario $h$ tiene una fila $x \\in ~a$ por cada elemento de $~a$, y en cada fila se decide:~%~%"
            (conjunto-latex (problema-combinacion problema))
            (conjunto-latex (problema-identidad problema)))
    (bloque stream
            (mapcar (lambda (variable)
                      (format nil "~a(x) &\\in ~a" (identificador-latex variable)
                              (conjunto-latex variable)))
                    (problema-variables problema)))))

(defun emitir-objetivo (blandas destino stream)
  "Escribe la función objetivo: la suma de las blandas con su peso."
  (format stream "\\subsubsection*{Objetivo}~%~%")
  (if blandas
      (bloque stream
              (list (format nil "\\min_{h}\\ ~{~a~^ + ~}"
                            (mapcar (lambda (restriccion)
                                      (format nil "~a \\cdot v_{~d}(h)"
                                              (codigo (restriccion-peso restriccion) destino)
                                              (indice-de restriccion destino)))
                                    blandas))))
      (format stream "Basta cumplir las restricciones.~%~%")))

(defun emitir-seccion (titulo restricciones destino stream)
  "Escribe una sección de restricciones, si tiene alguna."
  (when restricciones
    (format stream "\\subsubsection*{~a}~%~%" titulo)
    (dolist (restriccion restricciones)
      (emitir-restriccion restriccion destino stream))))

(defmethod archivo-de ((destino matematica)) "modelo.tex")

(defmethod emitir ((destino matematica) stream)
  (let* ((restricciones (modelo-restricciones (destino-modelo destino)))
         (blandas (remove-if-not #'restriccion-peso restricciones)))
    (emitir-conjuntos destino stream)
    (emitir-decisiones destino stream)
    (emitir-objetivo blandas destino stream)
    (emitir-seccion "Sujeto a" (remove-if #'restriccion-peso restricciones) destino stream)
    (emitir-seccion "Restricciones blandas y objetivos" blandas destino stream)))
