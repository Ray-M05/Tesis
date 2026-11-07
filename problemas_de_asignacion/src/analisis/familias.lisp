(in-package :analisis)

(defun datos-de-papel (papel papeles)
  "Devuelve el resto de cada entrada de PAPELES cuyo papel es PAPEL."
  (mapcar #'rest (remove papel papeles :key #'first :test-not #'eq)))

(defun rutas-de-papel (papel papeles)
  "Devuelve las rutas sin repetir de las entradas de PAPELES cuyo papel es PAPEL."
  (remove-duplicates (mapcar #'first (datos-de-papel papel papeles))
                     :test #'equal :from-end t))

(defun uno-por-fila-p (entradas a b)
  "Exige que cada entrada (clave raíz) aparezca exactamente una vez por cada fila."
  (flet ((veces (clave raiz)
           (count (list clave raiz) entradas :test #'equal)))
    (every (lambda (entrada)
             (and (= 1 (veces (first entrada) a))
                  (= 1 (veces (first entrada) b))))
           entradas)))

(defun datos-de-pareja (papeles problema)
  "Reparte los papeles de una pareja en los campos comunes de las dos familias."
  (let* ((enlaces (datos-de-papel :enlace papeles))
         (rutas-enlazadas (remove-duplicates (mapcar #'second enlaces)
                                             :test #'equal :from-end t))
         (compartidas (append (rutas-de-papel :celda papeles)
                              (rutas-de-papel :clave papeles)
                              rutas-enlazadas)))
    (list :celda (remove-if-not (lambda (ruta) (slot-de-decision ruta problema)) compartidas)
          :clave (remove-if (lambda (ruta) (slot-de-decision ruta problema)) compartidas)
          :enlaces (remove-duplicates (mapcar (lambda (enlace) (list (first enlace) (second enlace)))
                                              enlaces)
                                      :test #'equal :from-end t)
          :distintos (rutas-de-papel :distinto papeles)
          :filtros (datos-de-papel :filtro papeles)
          :papeles (remove-duplicates (mapcar #'first (datos-de-papel :papeles papeles))
                                      :from-end t))))

(defun papeles-coherentes (nodo a b problema)
  "Devuelve el papel de cada átomo si todos tienen uno y sus enlaces y papeles van por parejas."
  (let ((papeles (mapcar (lambda (atomo) (papel-de atomo a b problema))
                         (aplanar 'op-and (slot-value nodo 'comprobacion)))))
    (when (and (every #'identity papeles)
               (uno-por-fila-p (mapcar (lambda (enlace)
                                         (list (list (first enlace) (second enlace)) (third enlace)))
                                       (datos-de-papel :enlace papeles))
                               a b)
               (uno-por-fila-p (datos-de-papel :papeles papeles) a b))
      papeles)))

(defun clase-de-pareja (nodo filas problema)
  "Devuelve la clase y los campos de una consulta sobre dos filas, o nil si no encaja."
  (let* ((a (first (first filas)))
         (b (first (second filas)))
         (papeles (papeles-coherentes nodo a b problema))
         (datos (and papeles (datos-de-pareja papeles problema)))
         (adyacentes (rutas-de-papel :adyacente papeles))
         (no-adyacentes (rutas-de-papel :no-adyacente papeles)))
    (cond ((null papeles) nil)
          ((third (first filas))
           (when (and (getf datos :celda)
                      (null adyacentes)
                      (null no-adyacentes)
                      (simetrica-p (slot-value nodo 'comprobacion) a b))
             (cons 'choque-por-parejas datos)))
          ((or (getf datos :celda) (getf datos :clave) adyacentes no-adyacentes)
           (list* 'relacion-ordenada :adyacentes adyacentes :no-adyacentes no-adyacentes datos)))))

(defun dimensiones-de-atomo (atomo fila)
  "Devuelve las (parámetro ruta) de un átomo que iguala la fila con parámetros, o :no."
  (let ((enlaces (mapcar (lambda (termino)
                           (and (typep termino 'op-igual)
                                (enlace-de termino (list fila))))
                         (aplanar 'op-or atomo))))
    (if (every #'identity enlaces)
        (mapcar (lambda (enlace) (list (first enlace) (second enlace))) enlaces)
        :no)))

(defun clase-de-agrupacion (nodo fila)
  "Devuelve la clase y los campos de una consulta que agrupa filas por parámetros, o nil."
  (let ((dimensiones (mapcar (lambda (atomo) (dimensiones-de-atomo atomo fila))
                             (aplanar 'op-and (slot-value nodo 'comprobacion)))))
    (unless (member :no dimensiones)
      (list 'agrupacion :dimensiones (apply #'append dimensiones)))))

(defun dimension-de-cruce (atomo fila otra)
  "Devuelve el slot exterior si ATOMO iguala un slot de la fila con el del mismo nombre de la tabla."
  (and (typep atomo 'op-igual)
       (multiple-value-bind (ruta-izq raiz-izq) (camino (slot-value atomo 'operando-izq))
         (multiple-value-bind (ruta-der raiz-der) (camino (slot-value atomo 'operando-der))
           (and ruta-izq ruta-der
                (eq (first ruta-izq) (first ruta-der))
                (or (and (eq raiz-izq fila) (eq raiz-der otra))
                    (and (eq raiz-izq otra) (eq raiz-der fila)))
                (first ruta-izq))))))

(defun clase-de-cruce (nodo fila otra)
  "Devuelve la clase y los campos de un cruce entre una fila y una tabla, o nil."
  (let ((dimensiones (mapcar (lambda (atomo) (dimension-de-cruce atomo fila (first otra)))
                             (aplanar 'op-and (slot-value nodo 'comprobacion)))))
    (when (every #'identity dimensiones)
      (list 'cruce-contra-tabla
            :tabla (second otra)
            :dimensiones (remove-duplicates dimensiones :from-end t)))))

(defun clase-de-consulta (nodo parametros problema)
  "Devuelve la clase de la familia de una consulta, seguida de sus campos propios."
  (let* ((iteradores (iteradores-de nodo))
         (combinacion (problema-combinacion problema))
         (filas (remove combinacion iteradores :key #'second :test-not #'eq))
         (otros (remove combinacion iteradores :key #'second)))
    (or (cond ((= (length filas) 2)
               (clase-de-pareja nodo filas problema))
              ((and (= (length filas) 1) (null otros) parametros)
               (clase-de-agrupacion nodo (first (first filas))))
              ((and (= (length filas) 1) (null otros))
               (list 'filtro-de-fila))
              ((and (= (length filas) 1) (= (length otros) 1) (null parametros))
               (clase-de-cruce nodo (first (first filas)) (first otros))))
        (list 'consulta-generica))))

(defun clasificar-consulta (nodo parametros problema)
  "Crea la consulta del modelo, con su familia, sus iteradores y sus decisiones."
  (destructuring-bind (clase &rest campos) (clase-de-consulta nodo parametros problema)
    (let ((iteradores (iteradores-de nodo)))
      (apply #'make-instance clase
             :nombre (slot-value nodo 'nombre)
             :nodo nodo
             :parametros parametros
             :iteradores iteradores
             :condicion (slot-value nodo 'comprobacion)
             :operacion (slot-value nodo 'operacion)
             :decisiones (decisiones-de nodo (append iteradores parametros) problema)
             campos))))
