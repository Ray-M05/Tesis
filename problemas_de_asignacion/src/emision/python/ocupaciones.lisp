(in-package :emision)

(defgeneric emitir-ocupaciones (restriccion consulta destino stream)
  (:documentation "Define la función que da las ocupaciones de una fila, y devuelve su nombre o nil si no las tiene. Dos filas solo cambian juntas el valor de RESTRICCION si comparten alguna."))

(defun nombre-de-ocupaciones (restriccion)
  "Devuelve el nombre en Python de la función de ocupaciones de RESTRICCION."
  (format nil "ocupaciones_~a" (nombre-python (restriccion-nombre restriccion))))

(defun variables-de-fila (consulta destino)
  "Devuelve las variables de CONSULTA que recorren las filas del horario."
  (mapcar #'first (remove (problema-combinacion (modelo-problema (destino-modelo destino)))
                          (consulta-iteradores consulta) :key #'second :test-not #'eq)))

(defun emitir-sin-ocupaciones (restriccion destino stream)
  "Define una función de ocupaciones que no da ninguna y devuelve su nombre."
  (let ((nombre (nombre-de-ocupaciones restriccion)))
    (linea destino stream "def ~a(fila):" nombre)
    (con-sangria (destino)
      (linea destino stream "return []"))
    (terpri stream)
    nombre))

;; Sin ocupaciones, el daño se calcula con todas las filas puestas.
(defmethod emitir-ocupaciones ((restriccion restriccion-m) (consulta consulta-m) (destino python) stream)
  (declare (ignore stream))
  nil)

;; Las mismas por las que se agrupan las filas al contar el choque: la celda y la clave, por
;; cada valor de los demás iteradores con el que la fila cumple las condiciones de una fila.
(defmethod emitir-ocupaciones ((restriccion prohibicion) (consulta choque-por-parejas) (destino python) stream)
  (let* ((iteradores (consulta-iteradores consulta))
         (pareja (remove-if-not #'third iteradores))
         (exteriores (remove-if #'third iteradores))
         (a (first (first pareja)))
         (condiciones (condiciones-de-fila consulta a (first (second pareja)) destino))
         (ocupacion (append (mapcar (lambda (iterador) (nombre-python (first iterador))) exteriores)
                            (rutas-de-ocupacion consulta a)))
         (nombre (nombre-de-ocupaciones restriccion)))
    (flet ((guardar ()
             (linea destino stream "ocupaciones.append((~{~a~^, ~},))" ocupacion)))
      (linea destino stream "def ~a(~a):" nombre (nombre-python a))
      (con-sangria (destino)
        (linea destino stream "ocupaciones = []")
        (emitir-bucles exteriores destino stream
                       (lambda ()
                         (cond (condiciones
                                (linea destino stream "if ~{~a~^ and ~}:" condiciones)
                                (con-sangria (destino)
                                  (guardar)))
                               (t (guardar)))))
        (linea destino stream "return ocupaciones")))
    (terpri stream)
    nombre))

;; Dos filas solo se relacionan si coinciden en lo que la condición iguala entre ellas. Con
;; papeles, o sin nada que igualar, no se pueden separar.
(defmethod emitir-ocupaciones ((restriccion prohibicion) (consulta relacion-ordenada) (destino python) stream)
  (let* ((a (first (variables-de-fila consulta destino)))
         (rutas (rutas-de-ocupacion consulta a)))
    (when (and rutas (null (pareja-papeles consulta)))
      (let ((nombre (nombre-de-ocupaciones restriccion)))
        (linea destino stream "def ~a(~a):" nombre (nombre-python a))
        (con-sangria (destino)
          (linea destino stream "return [(~{~a~^, ~},)]" rutas))
        (terpri stream)
        nombre))))

(defmethod emitir-ocupaciones ((restriccion prohibicion) (consulta filtro-de-fila) (destino python) stream)
  (emitir-sin-ocupaciones restriccion destino stream))

(defmethod emitir-ocupaciones ((restriccion prohibicion) (consulta cruce-contra-tabla) (destino python) stream)
  (emitir-sin-ocupaciones restriccion destino stream))

;; Una fila cuenta en las tuplas de parámetros que la consulta iguala con sus rutas, y solo
;; cambia el exceso de esas. Un parámetro que no se iguala con ninguna ruta las une a todas.
(defmethod emitir-ocupaciones ((restriccion cota) (consulta agrupacion) (destino python) stream)
  (let* ((fila (first (variables-de-fila consulta destino)))
         (parametros (mapcar #'first (consulta-parametros consulta)))
         (valores (mapcar (lambda (parametro)
                            (mapcar (lambda (dimension) (ruta-python fila (second dimension)))
                                    (remove parametro (agrupacion-dimensiones consulta)
                                            :key #'first :test-not #'eq)))
                          parametros)))
    (when (every #'identity valores)
      (let ((nombre (nombre-de-ocupaciones restriccion)))
        (linea destino stream "def ~a(~a):" nombre (nombre-python fila))
        (con-sangria (destino)
          (linea destino stream "return [(~{~a~^, ~},)~:{ for ~a in [~{~a~^, ~}]~}]"
                 (mapcar #'nombre-python parametros)
                 (mapcar (lambda (parametro lista) (list (nombre-python parametro) lista))
                         parametros valores)))
        (terpri stream)
        nombre))))

(defun emitir-tabla-de-ocupaciones (destino stream)
  "Define las ocupaciones de cada restricción con decisiones y una sola consulta, y OCUPACIONES, que las da por nombre."
  (let ((ocupaciones
          (loop for restriccion in (modelo-restricciones (destino-modelo destino))
                for consultas = (restriccion-consultas restriccion)
                for funcion = (and (restriccion-decisiones restriccion)
                                   consultas
                                   (null (rest consultas))
                                   (emitir-ocupaciones restriccion (first consultas) destino stream))
                when funcion
                  collect (format nil "~s: ~a" (nombre-python (restriccion-nombre restriccion)) funcion))))
    (linea destino stream "OCUPACIONES = {~{~a~^, ~}}" ocupaciones)
    (terpri stream)))
