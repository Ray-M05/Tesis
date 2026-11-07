(in-package :pruebas-analisis)

(defun familias-de (dominio)
  "Devuelve (nombre . consulta del modelo) de cada consulta derivada de un dominio."
  (mapcar (lambda (consulta) (cons (symbol-name (consulta-nombre consulta)) consulta))
          (consultas-de (problema-real dominio))))

;; Familia y decisiones de cada consulta de los cinco dominios.
(let ((total 0))
  (loop for (dominio . filas) in *esperado*
        do (let ((familias (familias-de dominio)))
             (assert (= (length familias) (length filas)))
             (loop for (nil nil consulta familia decisiones) in filas
                   do (let ((modelo (cdr (assoc consulta familias :test #'equal))))
                        (incf total)
                        (assert (eq (clase-de modelo) familia) ()
                                "~a es ~a y se esperaba ~a" consulta (clase-de modelo) familia)
                        (assert (equal (nombres (consulta-decisiones modelo)) decisiones) ()
                                "~a toca ~a" consulta (consulta-decisiones modelo))))))
  (assert (= total 26)))

(defun de-dominio (dominio consulta)
  "Devuelve la consulta del modelo llamada CONSULTA en DOMINIO."
  (cdr (assoc consulta (familias-de dominio) :test #'equal)))

;; Celda, clave y lo que distingue a las filas de los diez choques.
(loop for (dominio consulta celda clave distintos)
        in '(("tesis" "CONFLICTOS-DE-HORARIO" (("FECHA") ("MOMENTO")) () (("TRIBUNAL")))
             ("tesis" "COLISIONES-DE-LOCAL" (("LOCAL") ("FECHA") ("MOMENTO")) () (("TRIBUNAL")))
             ("docentes" "COLISIONES-DE-PROFESOR" (("DIA") ("TURNO")) (("PROFESOR" "SESION"))
              (("AULA")))
             ("docentes" "COLISIONES-DE-AULA" (("AULA") ("DIA") ("TURNO")) ()
              (("GRUPO" "SESION")))
             ("docentes" "COLISIONES-DE-GRUPO" (("DIA") ("TURNO")) (("GRUPO" "SESION")) (("AULA")))
             ("seder" "COLISIONES-DE-INSTALACION" (("INSTALACION") ("TURNO"))
              (("PARIDAD" "ANNO" "BRIGADA")) (("BRIGADA")))
             ("seder" "COLISIONES-DE-PROFESOR" (("TURNO"))
              (("PARIDAD" "ANNO" "BRIGADA") ("PROFESOR" "BRIGADA")) (("BRIGADA")))
             ("saul" "COLISIONES-DE-GRUPO" (("DIA") ("TURNO")) (("GRUPO" "PLAN" "SESION"))
              (("SESION")))
             ("saul" "COLISIONES-DE-PROFESOR" (("DIA") ("TURNO")) (("PROFESOR" "PLAN" "SESION"))
              (("SESION")))
             ("saul" "REPETICIONES-EN-EL-DIA" (("DIA")) (("PLAN" "SESION")) (("SESION"))))
      do (let ((choque (de-dominio dominio consulta)))
           (assert (equal (nombres (pareja-celda choque)) celda) () "~a" consulta)
           (assert (equal (nombres (pareja-clave choque)) clave) () "~a ~a" consulta
                   (pareja-clave choque))
           (assert (equal (nombres (pareja-distintos choque)) distintos) () "~a" consulta)))

;; Enlaces y papeles: la variable externa se conserva.
(let ((tesis (de-dominio "tesis" "CONFLICTOS-DE-HORARIO"))
      (docentes (de-dominio "docentes" "COLISIONES-DE-PROFESOR")))
  (assert (equal (nombres (pareja-papeles tesis)) '("P")))
  (assert (null (pareja-enlaces tesis)))
  (assert (equal (nombres (pareja-enlaces docentes)) '(("P" ("PROFESOR" "SESION")))))
  (assert (null (pareja-papeles docentes))))

;; Saúl: el filtro de una sola fila.
(let ((filtros (pareja-filtros (de-dominio "saul" "REPETICIONES-EN-EL-DIA"))))
  (assert (= (length filtros) 1))
  (assert (equal (nombres (first (first filtros))) "U1")))

;; Relaciones ordenadas.
(let ((tv (de-dominio "tv" "ADYACENTES-MISMO-TIPO"))
      (saul (de-dominio "saul" "DOBLES-NO-CONSECUTIVOS")))
  (assert (equal (nombres (relacion-adyacentes tv)) '(("ORDEN" "BLOQUE"))))
  (assert (null (relacion-no-adyacentes tv)))
  (assert (equal (nombres (pareja-celda tv)) '(("TIPO" "PROGRAMA") ("CANAL" "PROGRAMA"))))
  (assert (equal (nombres (pareja-clave tv)) '(("DIA" "BLOQUE"))))
  (assert (equal (nombres (pareja-enlaces tv)) '(("C" ("CANAL" "PROGRAMA")))))
  (assert (equal (nombres (relacion-no-adyacentes saul)) '(("ORDEN" "TURNO"))))
  (assert (null (relacion-adyacentes saul))))

;; Cruces y agrupaciones.
(let ((seder (de-dominio "seder" "CLASES-EN-TURNO-NO-DISPONIBLE"))
      (saul (de-dominio "saul" "SESIONES-EN-DIA-SIN-ASISTENCIA"))
      (asistidos (de-dominio "tesis" "DIAS-ASISTIDOS"))
      (del-dia (de-dominio "saul" "SESIONES-DEL-DIA")))
  (assert (equal (nombres (cruce-tabla seder)) "INDISPONIBILIDAD"))
  (assert (equal (nombres (cruce-dimensiones seder)) '("ANNO" "TURNO")))
  (assert (equal (nombres (cruce-tabla saul)) "AUSENCIA"))
  (assert (equal (nombres (cruce-dimensiones saul)) '("PROFESOR" "DIA")))
  (assert (typep (consulta-operacion asistidos) 'contar-distintos))
  (assert (= (length (agrupacion-dimensiones asistidos)) 5))
  (assert (equal (nombres (agrupacion-dimensiones del-dia))
                 '(("P" ("PROFESOR" "PLAN" "SESION")) ("D" ("DIA")))))
  (assert (equal (nombres (consulta-parametros del-dia)) '(("P" "PROFESOR") ("D" "DIA")))))

;; Iteradores unificados: :pares se marca y :itera-sobre no.
(let ((saul (de-dominio "saul" "COLISIONES-DE-PROFESOR")))
  (assert (equal (nombres (consulta-iteradores saul))
                 '(("P" "PROFESOR") ("U1" "UBICACION" "PAREJA") ("U2" "UBICACION" "PAREJA")))))

(defun familia-de-texto (encabezado condicion &optional (uso "(m)") (para ""))
  "Devuelve la familia de una consulta M definida con ese encabezado y esa condición."
  (let ((p (problema-de (format nil "(def-consulta m ~a :comprueba ~a :operacion (suma 1))
                                     (def-ndpq r (op-mayor ~a 0) ~a)"
                                encabezado condicion uso para))))
    (clase-de (first (consultas-de p)))))

;; Consultas que encajan por su estructura.
(assert (eq (familia-de-texto "() :pares (a b) fila" "(op-igual (dia a) (dia b))")
            'choque-por-parejas))
(assert (eq (familia-de-texto "() :itera-sobre (a fila) (b fila)"
                              "(op-and (op-igual (dia a) (dia b)) (op-distinto (sesion a) (sesion b)))")
            'relacion-ordenada))
(assert (eq (familia-de-texto "() :itera-sobre (a fila) (b fila)"
                              "(op-igual (op-suma (orden (dia a)) 1) (orden (dia b)))")
            'relacion-ordenada))
(assert (eq (familia-de-texto "() :itera-sobre (u fila)" "(op-mayor (orden (dia u)) 1)")
            'filtro-de-fila))
(assert (eq (familia-de-texto "() :itera-sobre (u fila) (a ausencia)"
                              "(op-igual (dia u) (dia a))")
            'cruce-contra-tabla))
(assert (eq (familia-de-texto "(d) :itera-sobre (u fila)" "(op-igual (dia u) d)"
                              "(m x)" ":para (x dia)")
            'agrupacion))

;; Consultas que quedan en consulta-generica.
(dolist (caso '(("() :pares (a b) fila" "(op-distinto (sesion a) (sesion b))")
                ("() :pares (a b) fila" "(op-igual (op-suma (orden (dia a)) 1) (orden (dia b)))")
                ("() :pares (a b) fila"
                 "(op-and (op-igual (dia a) (dia b)) (op-mayor (orden (turno a)) 1))")
                ("() :pares (a b) fila"
                 "(op-and (op-igual (dia a) (dia b))
                          (op-distinto (orden (turno a)) (op-suma (orden (turno b)) 1))
                          (op-distinto (orden (turno b)) (op-suma (orden (turno a)) 1)))")
                ("() :pares (a b) fila"
                 "(op-and (op-igual (dia a) (dia b))
                          (op-igual (orden (turno a)) (op-suma (orden (turno b)) 1))
                          (op-igual (orden (turno b)) (op-suma (orden (turno a)) 1)))")
                ("() :pares (a b) profesor" "(op-distinto a b)")
                ("() :itera-sobre (p profesor) (a fila) (b fila)"
                 "(op-and (op-igual (profesor (sesion a)) p) (op-igual (dia a) (dia b)))")
                ("() :itera-sobre (p profesor) (a fila) (b fila)"
                 "(op-and (op-or (op-igual (profesor (sesion a)) p)
                                 (op-igual (profesor (sesion a)) p))
                          (op-igual (dia a) (dia b)))")
                ("() :pares (a b) fila"
                 "(op-and (op-igual (dia a) (dia b)) (op-not (op-igual (turno a) (turno b))))")
                ("() :itera-sobre (p profesor) :pares (a b) fila"
                 "(op-and (op-igual (profesor (sesion a)) p) (op-igual (dia a) (dia b)))")
                ("() :itera-sobre (p profesor) :pares (a b) fila"
                 "(op-and (op-or (op-igual (profesor (sesion a)) p)
                                 (op-igual (profesor (sesion a)) p))
                          (op-igual (dia a) (dia b)))")
                ("() :itera-sobre (a fila) (b fila) (c fila)" "(op-igual (dia a) (dia b))")
                ("() :itera-sobre (a fila) (b fila)" "(op-igual (orden (dia a)) 1)")
                ("() :itera-sobre (u fila) (a ausencia)" "(op-igual (dia a) lunes)")
                ("() :itera-sobre (u fila) (a ausencia)" "(op-igual (turno u) (dia a))")
                ("() :itera-sobre (u fila) (a ausencia)" "(op-distinto (dia u) (dia a))")
                ("() :itera-sobre (p profesor)" "(op-igual p p)")))
  (assert (eq (apply #'familia-de-texto caso) 'consulta-generica) () "~a" caso))

(assert (eq (familia-de-texto "(d) :itera-sobre (u fila)"
                              "(op-and (op-igual (dia u) d) (op-mayor (orden (turno u)) 3))"
                              "(m x)" ":para (x dia)")
            'consulta-generica))
(assert (eq (familia-de-texto "(d) :itera-sobre (u fila) (a ausencia)"
                              "(op-and (op-igual (dia a) d) (op-igual (dia u) (dia a)))"
                              "(m x)" ":para (x dia)")
            'consulta-generica))

;; Cada consulta se clasifica con todos sus datos comunes.
(let* ((c (first (consultas-de (problema-de "(def-nppq r (op-mayor (q) 0))"))))
       (nodo (consulta-nodo c)))
  (assert (eq (consulta-condicion c) (slot-value nodo 'comprobacion)))
  (assert (eq (consulta-operacion c) (slot-value nodo 'operacion)))
  (assert (equal (nombres (consulta-nombre c)) "Q"))
  (assert (null (consulta-parametros c))))
