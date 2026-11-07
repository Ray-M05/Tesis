(in-package :pruebas-analisis)

(dolist (clase '(prohibicion cota minimax restriccion-generica))
  (assert (subtypep clase 'restriccion-m)))
(dolist (clase '(pareja filtro-de-fila cruce-contra-tabla agrupacion consulta-generica))
  (assert (subtypep clase 'consulta-m)))
(dolist (clase '(choque-por-parejas relacion-ordenada))
  (assert (subtypep clase 'pareja)))

;; Las dos jerarquías no se mezclan, y el modelo no se puede escribir desde fuera.
(assert (not (subtypep 'consulta-m 'restriccion-m)))
(assert (not (subtypep 'choque-por-parejas 'relacion-ordenada)))
(dolist (lector '(modelo-consultas modelo-restricciones modelo-avisos cota-umbral pareja-celda))
  (assert (fboundp lector))
  (assert (not (fboundp `(setf ,lector)))))

;; Ninguna función del análisis tiene un método sobre t.
(do-symbols (simbolo :analisis)
  (when (and (eq (symbol-package simbolo) (find-package :analisis))
             (fboundp simbolo)
             (typep (symbol-function simbolo) 'generic-function))
    (dolist (metodo (sb-mop:generic-function-methods (symbol-function simbolo)))
      (assert (not (eq (first (sb-mop:method-specializers metodo)) (find-class t)))
              () "~a tiene un método sobre t" simbolo))))

(defun modelo-real (dominio)
  "Construye el modelo de uno de los cinco dominios."
  (construir-modelo (problema-real dominio)))

(defun consultas-viejas (dominio)
  "Lee la lista :consultas del dominio de referencia."
  (let ((formas (pruebas-dsl::formas-de
                 (merge-pathnames (format nil "pruebas/referencia/~a/dominio.lisp" dominio)
                                  pruebas-dsl::*raiz*))))
    (dolist (forma formas)
      (when (and (consp forma)
                 (equal (symbol-name (first forma)) "DEFVAR")
                 (consp (third forma))
                 (equal (symbol-name (first (third forma))) "DEF-PROBLEMA-HORARIO"))
        (return (nombres (second (getf (rest (third forma)) :consultas))))))))

;; Los cinco dominios contra lo esperado.
(loop for (dominio . filas) in *esperado*
      do (let ((m (modelo-real dominio)))
           (assert (eq (modelo-problema m) (problema-real dominio)))
           (assert (= (length (modelo-restricciones m)) (length filas)))
           (assert (equal (nombres (modelo-orden m))
                          (nombres (orden-topologico (modelo-referencias m)))))
           (loop for r in (modelo-restricciones m)
                 for (nombre forma consulta familia decisiones) in filas
                 do (assert (equal (symbol-name (restriccion-nombre r))
                                   (concatenate 'string "RESTRICCION-" nombre)))
                    (assert (eq (clase-de r) forma))
                    (assert (equal (nombres (restriccion-decisiones r)) decisiones))
                    (let ((c (first (restriccion-consultas r))))
                      (assert (equal (symbol-name (consulta-nombre c)) consulta))
                      (assert (eq (clase-de c) familia))
                      ;; La restricción enlaza la misma consulta que guarda el modelo.
                      (assert (member c (modelo-consultas m)))))))

;; Las consultas derivadas son las listas viejas, en el mismo orden (1.5).
(loop for (dominio) in *esperado*
      do (let ((viejas (substitute "SESIONES-DEL-DIA" "SESIONES-DE-LA-JORNADA"
                                   (consultas-viejas dominio) :test #'equal)))
           (assert viejas)
           (assert (equal (nombres (mapcar #'consulta-nombre (modelo-consultas (modelo-real dominio))))
                          viejas)
                   () "~a" dominio)))

;; Dominios: los componentes y lo que se recorre, sin la combinación.
(assert (equal (nombres (modelo-dominios (modelo-real "tv"))) '("BLOQUE" "PROGRAMA" "CANAL")))
(assert (equal (nombres (modelo-dominios (modelo-real "saul")))
               '("SESION" "DIA" "TURNO" "PROFESOR" "AUSENCIA" "PLAN")))
(assert (equal (nombres (modelo-dominios (modelo-real "seder")))
               '("BRIGADA" "TURNO" "INSTALACION" "INDISPONIBILIDAD" "PROFESOR")))

;; La identidad es un dominio más y conserva su variable (2.3). Su valor se prueba en la etapa 3.
(let* ((m (construir-modelo
           (problema-de "(def-consulta filas-de (b)
                           :itera-sobre (u fila)
                           :comprueba (op-igual (sesion u) b)
                           :operacion (suma 1))
                         (def-tqpq r (op-igual (filas-de b) 2) :para (b sesion))")))
       (r (first (modelo-restricciones m))))
  (assert (member "SESION" (nombres (modelo-dominios m)) :test #'equal))
  (assert (equal (nombres (restriccion-variables r)) '(("B" "SESION"))))
  (assert (equal (nombres (consulta-parametros (first (modelo-consultas m)))) '(("B" "SESION")))))

(defun motivos (texto &optional (restricciones '("r")))
  "Devuelve los motivos de los avisos del modelo de TEXTO."
  (mapcar #'aviso-motivo (modelo-avisos (construir-modelo (problema-de texto restricciones)))))

(defun con-prohibicion (consulta)
  "Añade a una consulta M sin parámetros una prohibición R que la usa."
  (format nil "~a (def-nppq r (op-mayor (m) 0))" consulta))

;; Los cinco dominios solo dan un aviso, el de la frecuencia de Saúl.
(loop for (dominio) in *esperado*
      do (let ((avisos (modelo-avisos (modelo-real dominio))))
           (if (equal dominio "saul")
               (progn
                 (assert (= (length avisos) 1))
                 (assert (eq (aviso-motivo (first avisos)) :restriccion-constante))
                 (assert (equal (symbol-name (aviso-objeto (first avisos)))
                                "RESTRICCION-FRECUENCIA-EXACTA"))
                 (assert (search "RESTRICCION-FRECUENCIA-EXACTA" (aviso-mensaje (first avisos)))))
               (assert (null avisos) () "~a: ~a" dominio (mapcar #'aviso-mensaje avisos)))))

;; Tabla de avisos.
(assert (equal (motivos (con-prohibicion
                         "(def-consulta m ()
                            :itera-sobre (a fila) (b fila)
                            :comprueba (op-y (op-igual (dia a) (dia b))
                                               (op-distinto (sesion a) (sesion b)))
                            :operacion (suma 1))"))
               '(:simetrica-sin-pares)))
(assert (equal (motivos (con-prohibicion
                         "(def-consulta m ()
                            :pares (a b) fila
                            :comprueba (op-igual (op-suma (orden (dia a)) 1) (orden (dia b)))
                            :operacion (suma 1))"))
               '(:pares-con-orden)))
(assert (equal (motivos (con-prohibicion
                         "(def-consulta m ()
                            :pares (a b) profesor
                            :comprueba (op-igual (nombre a) \"Ana\")
                            :operacion (suma 1))"))
               '(:pares-con-orden :variable-sin-usar :restriccion-constante)))
(assert (equal (motivos "(def-nppq r (op-mayor 3 2))") '(:restriccion-constante)))
(assert (equal (motivos (con-prohibicion
                         "(def-consulta m ()
                            :itera-sobre (x profesor) (u fila)
                            :comprueba (op-igual (orden (dia u)) 1)
                            :operacion (suma 1))"))
               '(:variable-sin-usar)))
(assert (equal (motivos "(def-consulta m (x)
                           :itera-sobre (u fila)
                           :comprueba (op-igual (orden (dia u)) 1)
                           :operacion (suma 1))
                         (def-nppq r (op-mayor (m d) 0) :para (d dia))")
               '(:variable-sin-usar)))
(assert (equal (motivos "(def-sbqp r (op-menor-igual (q) 5) :para (x profesor))")
               '(:variable-sin-usar)))

;; Una variable de :para que se llama como un iterador de la consulta no cuenta como usada.
(assert (equal (motivos "(def-sbqp r (op-menor-igual (q) 5) :para (u profesor))")
               '(:variable-sin-usar)))

;; Un aviso no detiene la construcción, y su mensaje nombra el objeto y la variable.
(let* ((m (construir-modelo
           (problema-de "(def-sbqp r (op-menor-igual (q) 5) :para (x profesor))")))
       (aviso (first (modelo-avisos m))))
  (assert (eq (clase-de (first (modelo-restricciones m))) 'cota))
  (assert (equal (symbol-name (aviso-objeto aviso)) "R"))
  (assert (search "R:" (aviso-mensaje aviso)))
  (assert (search "X" (aviso-mensaje aviso))))

;; Sin avisos cuando todo se usa y la condición ordena el par.
(assert (null (motivos "(def-nppq r (op-mayor (q) 0))")))
(assert (null (motivos (con-prohibicion
                        "(def-consulta m ()
                           :itera-sobre (a fila) (b fila)
                           :comprueba (op-mayor (orden (dia a)) (orden (dia b)))
                           :operacion (suma 1))"))))

(defun rechaza-modelo (texto &rest fragmentos)
  "Exige que construir el modelo de TEXTO se rechace con esos FRAGMENTOS en el mensaje."
  (handler-case (progn (construir-modelo (problema-de texto))
                       (error "No se rechazó: ~a" texto))
    (error-dsl (condicion)
      (let ((mensaje (princ-to-string condicion)))
        (dolist (fragmento fragmentos)
          (assert (search fragmento mensaje) () "~a" mensaje))))))

;; construir-modelo hace todas las comprobaciones.
(rechaza-modelo "(def-nppq r (q))" "restricción R")
(rechaza-modelo "(def-sbqp r (op-menor-igual (del-dia d p) 5) :para (p profesor) (d dia))"
                "consulta DEL-DIA")
(rechaza-modelo "(def-entidad cargo () (jefe)) (def-cargo c1 nil) (def-nppq r (op-mayor (q) 0))"
                "entidad CARGO" "JEFE")
(rechaza-modelo "(def-entidad puesto () (superior))
                 (def-entidad area () (jefe))
                 (def-puesto p1 0)
                 (def-area a2 p1)
                 (setf (slot-value p1 'superior) a2)
                 (def-nppq r (op-mayor (q) 0))"
                "ciclo" "PUESTO" "AREA")

(defun resumen (m)
  "Resume un modelo en una lista de nombres que se puede comparar con equal."
  (nombres (list (mapcar (lambda (r) (list (restriccion-nombre r) (clase-de r)
                                           (restriccion-decisiones r)))
                         (modelo-restricciones m))
                 (mapcar (lambda (c) (list (consulta-nombre c) (clase-de c)
                                           (consulta-iteradores c) (consulta-parametros c)))
                         (modelo-consultas m))
                 (modelo-tipos m) (modelo-referencias m) (modelo-orden m) (modelo-dominios m)
                 (mapcar #'aviso-mensaje (modelo-avisos m)))))

;; Pureza: dos construcciones dan lo mismo, y no se altera el problema.
(loop for (dominio) in *esperado*
      do (let* ((p (problema-real dominio))
                (restricciones (copy-list (problema-restricciones p))))
           (assert (equal (resumen (construir-modelo p)) (resumen (construir-modelo p))))
           (assert (equal restricciones (problema-restricciones p)))))

;; Un problema se sigue construyendo después de volver a cargar su dominio, sin mezclarse.
(let* ((viejo (problema-de "(def-nppq r (op-mayor (q) 0))"))
       (antes (resumen (construir-modelo viejo))))
  (problema-de "(def-nppq r (op-mayor (q2) 0))")
  (assert (equal (resumen (construir-modelo viejo)) antes)))

(defun fuentes-del-analisis ()
  "Devuelve el texto en mayúsculas de cada archivo de src/analisis/."
  (mapcar (lambda (ruta)
            (with-open-file (flujo ruta :external-format :utf-8)
              (let* ((texto (make-string (file-length flujo)))
                     (fin (read-sequence texto flujo)))
                (string-upcase (subseq texto 0 fin)))))
          (directory (merge-pathnames "src/analisis/*.lisp" pruebas-dsl::*raiz*))))

(defun separar-palabras (texto)
  "Divide un texto en las palabras que pueden nombrar un símbolo."
  (let ((palabras '()) (actual '()))
    (loop for caracter across texto
          do (if (or (alphanumericp caracter) (char= caracter #\-))
                 (push caracter actual)
                 (when actual
                   (push (coerce (reverse actual) 'string) palabras)
                   (setf actual '()))))
    palabras))

;; Sin registros globales, sin typecase y sin nombres de un dominio concreto.
(let ((palabras (remove-duplicates (mapcan #'separar-palabras (fuentes-del-analisis))
                                   :test #'equal)))
  (assert (> (length palabras) 100))
  (dolist (prohibida '("TYPECASE" "ETYPECASE" "CASE" "ECASE"))
    (assert (not (member prohibida palabras :test #'equal)) () "~a" prohibida))
  (dolist (texto (fuentes-del-analisis))
    (dolist (registro '("*ENTIDADES*" "*SLOTS-DE-ENTIDAD*" "*INSTANCIAS-DE-ENTIDAD*"
                        "*COMBINACIONES*" "*PROBLEMA-CARGADO*"))
      (assert (not (search registro texto)) () "~a" registro)))
  ;; CLASE es a la vez una entidad de docentes y un nombre genérico de variable.
  (loop for (dominio) in *esperado*
        do (let ((m (modelo-real dominio)))
             (dolist (nombre (append (mapcar #'consulta-nombre (modelo-consultas m))
                                     (mapcar #'restriccion-nombre (modelo-restricciones m))
                                     (problema-entidades (modelo-problema m))))
               (assert (or (not (member (symbol-name nombre) palabras :test #'equal))
                           (equal (symbol-name nombre) "CLASE"))
                       () "~a de ~a aparece en src/analisis/" nombre dominio)))))
