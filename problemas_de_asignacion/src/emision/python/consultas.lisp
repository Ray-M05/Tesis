(in-package :emision)

(defgeneric emitir-cuerpo (operacion consulta destino stream)
  (:documentation "Escribe los bucles y el acumulador de una consulta según su operación."))

(defmethod emitir-cuerpo ((operacion suma) consulta destino stream)
  (linea destino stream "total = 0")
  (emitir-bucles (consulta-iteradores consulta) destino stream
                 (lambda ()
                   (linea destino stream "if ~a:" (codigo (consulta-condicion consulta) destino))
                   (con-sangria (destino)
                     (linea destino stream "total += ~a"
                            (codigo (slot-value operacion 'expresion) destino)))))
  (linea destino stream "return total"))

(defmethod emitir-cuerpo ((operacion contar-distintos) consulta destino stream)
  (linea destino stream "valores = set()")
  (emitir-bucles (consulta-iteradores consulta) destino stream
                 (lambda ()
                   (linea destino stream "if ~a:" (codigo (consulta-condicion consulta) destino))
                   (con-sangria (destino)
                     (linea destino stream "valores.add(~a)"
                            (codigo (slot-value operacion 'expresion) destino)))))
  (linea destino stream "return len(valores)"))

(defmethod emitir-consulta :around ((consulta consulta-m) (destino python) stream)
  (linea destino stream "def ~a(horario~{, ~a~}):"
         (nombre-python (consulta-nombre consulta))
         (mapcar (lambda (parametro) (nombre-python (first parametro)))
                 (consulta-parametros consulta)))
  (con-sangria (destino)
    (call-next-method))
  (terpri stream))

(defmethod emitir-consulta ((consulta consulta-m) (destino python) stream)
  (emitir-cuerpo (consulta-operacion consulta) consulta destino stream))

(defun agrupable-p (consulta)
  "Dice si contar por celda da lo mismo que recorrer las parejas: suma un número y hay como mucho un distinto."
  (let ((operacion (consulta-operacion consulta)))
    (and (typep operacion 'suma)
         (numberp (slot-value operacion 'expresion))
         (null (rest (pareja-distintos consulta))))))

(defun ruta-python (variable ruta)
  "Escribe una ruta desde VARIABLE. La ruta va del slot exterior al interior."
  (format nil "~a~{.~a~}" (nombre-python variable)
          (mapcar #'nombre-python (reverse ruta))))

(defun condiciones-de-fila (consulta a b destino)
  "Escribe sin repetir, sobre A, los átomos que hablan de una sola fila de la pareja."
  (let ((*renombres* (list (cons b a))))
    (remove-duplicates
     (loop for atomo in (aplanar 'op-y (consulta-condicion consulta))
           for variables = (variables-usadas atomo)
           unless (and (member a variables) (member b variables))
             collect (codigo atomo destino))
     :test #'string= :from-end t)))

(defun emitir-celdas (consulta a dominio condiciones destino stream)
  "Reparte las filas por celda, guardando de cada una lo que tiene que ser distinto."
  (let ((celda (mapcar (lambda (ruta) (ruta-python a ruta))
                       (append (pareja-celda consulta) (pareja-clave consulta))))
        (distinto (first (pareja-distintos consulta))))
    (flet ((guardar ()
             (linea destino stream "grupos.setdefault((~{~a~^, ~},), []).append(~a)"
                    celda
                    (if distinto (ruta-python a distinto) (nombre-python a)))))
      (linea destino stream "for ~a in ~a:" (nombre-python a) (lista-de dominio destino))
      (con-sangria (destino)
        (cond (condiciones
               (linea destino stream "if ~{~a~^ and ~}:" condiciones)
               (con-sangria (destino)
                 (guardar)))
              (t (guardar)))))))

(defun emitir-choque-agrupado (consulta destino stream)
  "Cuenta las parejas de cada celda en tiempo lineal, por cada valor de los demás iteradores."
  (let* ((iteradores (consulta-iteradores consulta))
         (pareja (remove-if-not #'third iteradores))
         (a (first (first pareja)))
         (b (first (second pareja))))
    (linea destino stream "total = 0")
    (emitir-bucles (remove-if #'third iteradores) destino stream
                   (lambda ()
                     (linea destino stream "grupos = {}")
                     (emitir-celdas consulta a (second (first pareja))
                                    (condiciones-de-fila consulta a b destino)
                                    destino stream)
                     (linea destino stream "for valores in grupos.values():")
                     (con-sangria (destino)
                       (linea destino stream "total += ~a * _parejas(valores)"
                              (codigo (slot-value (consulta-operacion consulta) 'expresion)
                                      destino)))))
    (linea destino stream "return total")))

(defmethod emitir-consulta ((consulta choque-por-parejas) (destino python) stream)
  (if (agrupable-p consulta)
      (emitir-choque-agrupado consulta destino stream)
      (call-next-method)))
