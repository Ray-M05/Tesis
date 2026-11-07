(in-package :analisis)

(defun camino (nodo)
  "Devuelve la ruta de un acceso, del slot exterior al interior, y su raíz."
  (let ((ruta '()))
    (loop while (typep nodo 'acceso-a-atributo-de-entidad)
          do (push (slot-value nodo 'atributo) ruta)
             (setf nodo (slot-value nodo 'entidad)))
    (values (nreverse ruta) nodo)))

(defun slot-de-decision (ruta problema)
  "Devuelve el slot más cercano a la raíz si es una de las variables del problema."
  (find (first (last ruta)) (problema-variables problema)))

(defun decision-de (acceso variables problema)
  "Devuelve el slot de decisión de ACCESO si parte de una fila de la combinación; si no, nil."
  (multiple-value-bind (ruta raiz) (camino acceso)
    (and (eq (second (assoc raiz variables)) (problema-combinacion problema))
         (slot-de-decision ruta problema))))

(defun accesos-de (nodo)
  "Devuelve los accesos completos de NODO, sin entrar en una consulta aplicada."
  (cond ((typep nodo 'acceso-a-atributo-de-entidad) (list nodo))
        ((typep nodo 'aplicacion-de-consulta) nil)
        (t (mapcan #'accesos-de (hijos nodo)))))

(defun decisiones-de (nodo variables problema)
  "Devuelve las decisiones que toca NODO, en orden de aparición."
  (remove-duplicates (remove nil (mapcar (lambda (acceso) (decision-de acceso variables problema))
                                         (accesos-de nodo)))
                     :from-end t))

(defun ruta-compartida (izq der a b)
  "Devuelve la ruta si IZQ y DER recorren la misma, uno desde A y el otro desde B."
  (multiple-value-bind (ruta-izq raiz-izq) (camino izq)
    (multiple-value-bind (ruta-der raiz-der) (camino der)
      (and ruta-izq
           (equal ruta-izq ruta-der)
           (or (and (eq raiz-izq a) (eq raiz-der b))
               (and (eq raiz-izq b) (eq raiz-der a)))
           ruta-izq))))

(defun ruta-adyacente (izq der a b)
  "Devuelve la ruta si un lado es (op-suma f k) y el otro es la misma f desde la otra fila."
  (flet ((de-suma (suma otro)
           (and (typep suma 'op-suma)
                (numberp (slot-value suma 'operando-der))
                (ruta-compartida (slot-value suma 'operando-izq) otro a b))))
    (or (de-suma izq der) (de-suma der izq))))

(defun filtro-de (atomo a b)
  "Devuelve (:filtro raíz átomo) si ATOMO compara un acceso de una fila con un número."
  (flet ((ver (acceso numero)
           (multiple-value-bind (ruta raiz) (camino acceso)
             (and ruta (member raiz (list a b)) (numberp numero)
                  (list :filtro raiz atomo)))))
    (or (ver (slot-value atomo 'operando-izq) (slot-value atomo 'operando-der))
        (ver (slot-value atomo 'operando-der) (slot-value atomo 'operando-izq)))))

(defun enlace-de (atomo filas)
  "Devuelve (variable ruta raíz) si ATOMO iguala un acceso de FILAS con otra variable."
  (flet ((ver (acceso variable)
           (multiple-value-bind (ruta raiz) (camino acceso)
             (and ruta (member raiz filas)
                  variable (symbolp variable) (not (member variable filas))
                  (list variable ruta raiz)))))
    (or (ver (slot-value atomo 'operando-izq) (slot-value atomo 'operando-der))
        (ver (slot-value atomo 'operando-der) (slot-value atomo 'operando-izq)))))

(defgeneric papel-de (atomo a b problema)
  (:documentation "Devuelve el papel de un átomo en una pareja de filas A y B, o nil si no tiene."))

(defmethod papel-de ((atomo nodo-ast) a b problema)
  (declare (ignore a b problema))
  nil)

(defmethod papel-de ((atomo comprobacion-aritmetica) a b problema)
  (declare (ignore problema))
  (let ((orden (ruta-compartida (slot-value atomo 'operando-izq)
                                (slot-value atomo 'operando-der) a b)))
    (if orden
        (list :orden orden)
        (filtro-de atomo a b))))

(defmethod papel-de ((atomo op-igual) a b problema)
  (let* ((izq (slot-value atomo 'operando-izq))
         (der (slot-value atomo 'operando-der))
         (compartida (ruta-compartida izq der a b))
         (adyacente (ruta-adyacente izq der a b))
         (enlace (enlace-de atomo (list a b))))
    (cond (compartida
           (list (if (slot-de-decision compartida problema) :celda :clave) compartida))
          (adyacente (list :adyacente adyacente))
          ((filtro-de atomo a b))
          (enlace (cons :enlace enlace)))))

(defmethod papel-de ((atomo op-distinto) a b problema)
  (declare (ignore problema))
  (let* ((izq (slot-value atomo 'operando-izq))
         (der (slot-value atomo 'operando-der))
         (distinta (ruta-compartida izq der a b))
         (no-adyacente (ruta-adyacente izq der a b)))
    (cond (distinta (list :distinto distinta))
          (no-adyacente (list :no-adyacente no-adyacente))
          ((filtro-de atomo a b)))))

(defmethod papel-de ((atomo op-or) a b problema)
  (declare (ignore problema))
  (let ((enlaces (mapcar (lambda (termino)
                           (and (typep termino 'op-igual)
                                (enlace-de termino (list a b))))
                         (aplanar 'op-or atomo))))
    (when (and (every #'identity enlaces)
               (every (lambda (enlace)
                        (and (eq (first enlace) (first (first enlaces)))
                             (eq (third enlace) (third (first enlaces)))))
                      enlaces))
      (list :papeles (first (first enlaces)) (third (first enlaces))))))
