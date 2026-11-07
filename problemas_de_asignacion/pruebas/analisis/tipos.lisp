(in-package :pruebas-analisis)

;; Los cinco dominios no tienen ningún error de tipos.
(dolist (entrada *esperado*)
  (comprobar-tipos (problema-real (first entrada))))

;; Tipos deducidos de las instancias, y de los nombres en la combinación.
(let* ((p (problema-real "saul"))
       (tipos (nombres (tipos-de-slots p))))
  (flet ((tipo (entidad slot)
           (cdr (assoc (cons entidad slot) tipos :test #'equal))))
    (assert (equal (tipo "PLAN" "PROFESOR") "PROFESOR"))
    (assert (equal (tipo "ASIGNATURA" "DIA-PREPARACION") "DIA"))
    (assert (equal (tipo "UBICACION" "TURNO") "TURNO"))
    (assert (equal (tipo "TURNO" "ORDEN") "NUMERO"))
    (assert (equal (tipo "DIA" "NOMBRE") "TEXTO"))))

;; Parámetros: un dominio deducido de cada aplicación, en orden de aparición.
(let* ((p (problema-real "saul"))
       (parametros (dominios-de-parametros p))
       (del-dia (rest (first (last parametros))))
       (dias (problema-real "tesis")))
  (assert (equal (nombres del-dia) '(("P" "PROFESOR") ("D" "DIA"))))
  (assert (null (rest (first parametros))))
  (assert (equal (nombres (rest (third (dominios-de-parametros dias))))
                 '(("PROF" "PROFESOR")))))

;; Una entidad sin instancias: su slot es desconocido y su comparación no se rechaza.
(let ((p (problema-de "(def-entidad vacia () (dato))
                       (def-consulta m ()
                         :itera-sobre (v vacia)
                         :comprueba (op-igual (dato v) 1)
                         :operacion (suma 1))
                       (def-nppq r (op-mayor (m) 0))")))
  (comprobar-tipos p)
  (assert (eq (cdr (assoc "VACIA" (mapcar (lambda (x) (cons (symbol-name (caar x)) (cdr x)))
                                          (tipos-de-slots p))
                          :test #'equal))
              :desconocido)))

;; Una instancia concreta se puede comparar con su entidad.
(comprobar-tipos
 (problema-de "(def-consulta m ()
                 :itera-sobre (u fila)
                 :comprueba (op-igual (dia u) lunes)
                 :operacion (suma 1))
               (def-nppq r (op-mayor (m) 0))"))

(defun consulta-con (condicion &optional (operacion "(suma 1)"))
  "Devuelve el texto de una consulta M con esa condición y una prohibición R que la usa."
  (format nil "(def-consulta m ()
                 :itera-sobre (u fila) (a ausencia)
                 :comprueba ~a
                 :operacion ~a)
               (def-nppq r (op-mayor (m) 0))"
          condicion operacion))

;; Tabla de rechazos.
(rechaza-tipos (consulta-con "(op-igual (orden u) 1)") '("r") "consulta M" "ORDEN" "FILA")
(rechaza-tipos "(def-sbqp r (op-menor-igual (del-dia d p) 5) :para (p profesor) (d dia))" '("r")
               "consulta DEL-DIA" "PROFESOR" "DIA")
(rechaza-tipos (consulta-con "(op-igual (dia u) 1)") '("r") "consulta M" "DIA" "NUMERO")
(rechaza-tipos (consulta-con "(op-igual (dia u) (profesor a))") '("r")
               "consulta M" "DIA" "PROFESOR")
(rechaza-tipos (consulta-con "(op-mayor (nombre (dia u)) 1)") '("r")
               "consulta M" "OP-MAYOR" "TEXTO")
(rechaza-tipos (consulta-con "(op-igual (op-suma (dia u) 1) 2)") '("r")
               "consulta M" "OP-SUMA" "DIA")
(rechaza-tipos (consulta-con "(op-y (orden (dia u)) (op-igual 1 1))") '("r")
               "consulta M" "OP-Y" "NUMERO")
(rechaza-tipos (consulta-con "(op-no (orden (dia u)))") '("r") "consulta M" "OP-NO" "NUMERO")
(rechaza-tipos (consulta-con "(orden (dia u))") '("r") "consulta M" "lógica")
(rechaza-tipos (consulta-con "(op-igual 1 1)" "(suma (dia u))") '("r") "consulta M" "DIA")
(rechaza-tipos (consulta-con "(op-igual 1 1)" "(contar-distintos (orden u))") '("r")
               "consulta M" "ORDEN")
(rechaza-tipos "(def-nppq r (q))" '("r") "restricción R" "NUMERO")
(rechaza-tipos "(def-tqpq r (op-suma (q) 1))" '("r") "restricción R" "NUMERO")
(rechaza-tipos "(def-minimizar r (op-mayor (del-dia p d) 0) :para (p profesor) (d dia))" '("r")
               "restricción R" "LOGICO")
(rechaza-tipos (consulta-con "(op-igual (dia u) profesor)") '("r")
               "consulta M" "PROFESOR" "no es un valor")
(rechaza-tipos (consulta-con "(op-igual (dia u) 'lunes)") '("r") "consulta M" "LUNES")
(rechaza-tipos "(def-consulta m (x)
                  :itera-sobre (u fila)
                  :comprueba (op-igual (dia u) x)
                  :operacion (suma 1))
                (def-sbqp r (op-mayor (op-suma (m d) (m p)) 0) :para (d dia) (p profesor))"
               '("r") "consulta M" "DIA" "PROFESOR")
(rechaza-tipos "(def-sbqp r (op-menor-igual (del-dia p 'd) 5) :para (p profesor))" '("r")
               "restricción R" "D")
(rechaza-tipos "(def-entidad cargo () (jefe))
                (def-cargo c1 nil)"
               '() "entidad CARGO" "JEFE" "NIL")
(rechaza-tipos "(def-entidad cargo () (jefe))
                (def-cargo c1 ana)
                (def-cargo c2 nil)"
               '() "entidad CARGO" "JEFE" "NIL")
(rechaza-tipos "(def-entidad cargo () (dato))
                (def-cargo c1 1)
                (def-cargo c2 \"uno\")"
               '() "entidad CARGO" "DATO" "NUMERO" "TEXTO")
(rechaza-tipos "(def-entidad cargo () (dato))
                (def-cargo c1 lunes)
                (def-cargo c2 ana)"
               '() "entidad CARGO" "DATO" "DIA" "PROFESOR")
