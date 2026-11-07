(in-package :analisis)

(defstruct (vista (:constructor crear-vista)) rutas a b renombrar)

(defun ordenar-formas (formas)
  "Ordena formas canónicas de manera que no dependa del paquete actual."
  (let ((*package* (find-package :keyword)))
    (sort (copy-list formas) #'string< :key #'prin1-to-string)))

(defun forma-conmutativa (nodo vista)
  "Devuelve la forma de un nodo binario cuyos operandos se pueden intercambiar."
  (cons (type-of nodo)
        (ordenar-formas (list (canonica (slot-value nodo 'operando-izq) vista)
                              (canonica (slot-value nodo 'operando-der) vista)))))

(defun forma-logica (nodo vista)
  "Devuelve la forma de un op-y u op-o, plana, ordenada y sin términos repetidos."
  (cons (type-of nodo)
        (ordenar-formas
         (remove-duplicates (mapcar (lambda (termino) (canonica termino vista))
                                    (aplanar (type-of nodo) nodo))
                            :test #'equal))))

(defgeneric canonica (nodo vista)
  (:documentation "Convierte una condición en una lista comparable con equal."))

(defmethod canonica ((nodo number) vista)
  (declare (ignore vista))
  nodo)

(defmethod canonica ((nodo string) vista)
  (declare (ignore vista))
  nodo)

(defmethod canonica ((nodo symbol) vista)
  (funcall (vista-renombrar vista) nodo))

(defmethod canonica ((nodo ref-especifica-ent) vista)
  (declare (ignore vista))
  (list :instancia (sxhash nodo)))

(defmethod canonica ((nodo acceso-a-atributo-de-entidad) vista)
  (multiple-value-bind (ruta raiz) (camino nodo)
    (if (and (member ruta (vista-rutas vista) :test #'equal)
             (member raiz (list (vista-a vista) (vista-b vista))))
        (list :acceso ruta (vista-a vista))
        (list :acceso (slot-value nodo 'atributo) (canonica (slot-value nodo 'entidad) vista)))))

(defmethod canonica ((nodo operacion-binaria) vista)
  (list (type-of nodo)
        (canonica (slot-value nodo 'operando-izq) vista)
        (canonica (slot-value nodo 'operando-der) vista)))

(defmethod canonica ((nodo op-igual) vista) (forma-conmutativa nodo vista))
(defmethod canonica ((nodo op-distinto) vista) (forma-conmutativa nodo vista))
(defmethod canonica ((nodo op-suma) vista) (forma-conmutativa nodo vista))
(defmethod canonica ((nodo op-multiplicacion) vista) (forma-conmutativa nodo vista))
(defmethod canonica ((nodo op-y) vista) (forma-logica nodo vista))
(defmethod canonica ((nodo op-o) vista) (forma-logica nodo vista))

(defmethod canonica ((nodo operacion-unaria) vista)
  (list (type-of nodo) (canonica (slot-value nodo 'operando) vista)))

(defun rutas-igualadas (condicion a b)
  "Devuelve las rutas que la conjunción iguala entre A y B."
  (loop for atomo in (aplanar 'op-y condicion)
        for ruta = (and (typep atomo 'op-igual)
                        (ruta-compartida (slot-value atomo 'operando-izq)
                                         (slot-value atomo 'operando-der) a b))
        when ruta collect ruta))

(defun simetrica-p (condicion a b)
  "Dice si intercambiar A y B no cambia CONDICION, una vez aplicadas sus propias igualdades."
  (let ((rutas (rutas-igualadas condicion a b)))
    (flet ((forma (renombrar)
             (canonica condicion (crear-vista :rutas rutas :a a :b b :renombrar renombrar))))
      (equal (forma #'identity)
             (forma (lambda (variable)
                      (cond ((eq variable a) b)
                            ((eq variable b) a)
                            (t variable))))))))
