;; =====================================================================
;; expr.lisp — Traduccion AST -> espanol 
;; =====================================================================
;; Espejo exacto de gen-ast-math.lisp del proyecto original:
;;
;;   bin->math            -> bin->nl
;;   expr->math           -> expr->nl
;;   consulta->math-str   -> query->nl
;;   restriccion->math-str-> constraint->nl
;;
;; Esta es la capa LITERAL: traduce nodo a nodo, sin reconocer patrones.

;; =====================================================================
;; EXPRESIONES
;; =====================================================================

(defun bin->nl (nodo verbo)
  "Operador binario infijo: '<izq> <verbo> <der>'."
  (format nil "~a ~a ~a"
          (expr->nl (slot-value nodo 'operando-izq))
          verbo
          (expr->nl (slot-value nodo 'operando-der))))

(defun expr->nl (nodo)
  "Traduce un nodo AST a un fragmento en espanol."
  (typecase nodo
    (null    "nada")
    (symbol  (nl-var nodo))
    (number  (format nil "~a" nodo))
    (string  (format nil "«~a»" nodo))

    ;; (tipo (programa e1)) -> "el tipo de el programa de e1"
    ;; contract() lo convierte despues en "el tipo del programa de e1".
    (acceso-a-atributo-de-entidad
     (format nil "~a de ~a"
             (nl-noun (slot-value nodo 'atributo) :definite t)
             (expr->nl (slot-value nodo 'entidad))))

    (op-igual       (bin->nl nodo "es igual a"))
    (op-distinto    (bin->nl nodo "es distinto de"))
    (op-mayor       (bin->nl nodo "es mayor que"))
    (op-menor       (bin->nl nodo "es menor que"))
    (op-mayor-igual (bin->nl nodo "es mayor o igual que"))
    (op-menor-igual (bin->nl nodo "es menor o igual que"))

    (op-suma           (format nil "la suma de ~a y ~a"
                               (expr->nl (slot-value nodo 'operando-izq))
                               (expr->nl (slot-value nodo 'operando-der))))
    (op-resta          (format nil "la diferencia entre ~a y ~a"
                               (expr->nl (slot-value nodo 'operando-izq))
                               (expr->nl (slot-value nodo 'operando-der))))
    (op-multiplicacion (format nil "el producto de ~a por ~a"
                               (expr->nl (slot-value nodo 'operando-izq))
                               (expr->nl (slot-value nodo 'operando-der))))
    (op-division       (format nil "el cociente de ~a entre ~a"
                               (expr->nl (slot-value nodo 'operando-izq))
                               (expr->nl (slot-value nodo 'operando-der))))

    ;; Logicas. Se aplanan igual que en expr->py / expr->math, para no
    ;; arrastrar el anidamiento binario a la prosa.
    (op-and (join-nl (mapcar #'expr->nl (flatten-op nodo 'op-and)) "y"))
    (op-or  (join-nl (mapcar #'expr->nl (flatten-op nodo 'op-or))  "o"))
    (op-not (format nil "no se cumple que ~a"
                    (expr->nl (slot-value nodo 'operando))))

    ;; Una consulta referenciada se EXPANDE en linea. El DSL solo tiene
    ;; un nivel de agregacion, asi que no hay riesgo de recursion honda,
    ;; y expandirla es lo que hace que la oracion se baste sola.
    (consulta-simple (query->nl nodo))

    ;; Referencia generica a una entidad, p.ej. (frecuencia asignatura).
    (ref-gen-entidad (nl-noun (slot-value nodo 'nombre-entidad) :definite t))

    ;; Nunca fallar en silencio. Mismo principio que el
    ;; "# NODO_DESCONOCIDO" de expr->py.
    (t (format nil "[NODO_DESCONOCIDO: ~a]" (class-name (class-of nodo))))))


;; =====================================================================
;; CONSULTAS
;; =====================================================================

(defun iteration->nl (vars doms)
  "((c canal) (e1 emision)) -> 'cada canal c y cada emisión e1'."
  (join-nl (mapcar (lambda (v d)
                     (format nil "cada ~a ~a"
                             (nl-name (nombre-entidad d))
                             (nl-var v)))
                   vars doms)))

(defun params->nl (args)
  "Los :args de la consulta, que en la condicion aparecen como variables
   libres. Sin declararlos, la prosa menciona una 'c' que sale de la nada."
  (if args
      (format nil "dado ~a, " (join-nl (mapcar #'nl-var args) "y"))
      ""))

(defun query->nl (nodo)
  "consulta-simple -> que mide. Espejo de consulta->math-str."
  (let ((args  (slot-value nodo 'args))
        (vars  (slot-value nodo 'variable-iteracion))
        (doms  (slot-value nodo 'dominio-iteracion))
        (check (slot-value nodo 'comprobacion))
        (op    (slot-value nodo 'operacion)))
    (if (null vars)
        ;; Una consulta sin :itera-sobre compila a defun y se inlinea en
        ;; el AST del llamador, asi que en teoria no llega aqui.
        (format nil "se cumple que ~a" (expr->nl check))
        (case op
          ((suma contar)
           (format nil "el número de casos, ~apara ~a, en que ~a"
                   (params->nl args) (iteration->nl vars doms) (expr->nl check)))
          (contar-distintos-dias
           (format nil "el número de días distintos, ~apara ~a, en que ~a"
                   (params->nl args) (iteration->nl vars doms) (expr->nl check)))
          (t
           (format nil "el resultado de «~a», ~apara ~a, en que ~a"
                   (nl-name op) (params->nl args)
                   (iteration->nl vars doms) (expr->nl check)))))))


;; =====================================================================
;; RESTRICCIONES
;; =====================================================================
;; Los nombres de los cuantificadores del DSL YA SON plantillas de
;; lenguaje natural: nppq = No Puede Pasar Que, tqpq = Tiene Que Pasar
;; Que, ndpq = No Debe Pasar Que. Se aprovechan tal cual.
;;
;; Se usa "lo siguiente:" en vez de "que ..." a proposito. En espanol,
;; "no puede pasar que" exige subjuntivo ("...sea mayor que 0"), y
;; conjugar en subjuntivo esta fuera del alcance de la capa literal.
;; Con dos puntos, el indicativo que produce expr->nl es gramatical.

(defun constraint->nl (nodo)
  "cuantificador-restriccion -> una oracion. Espejo de restriccion->math-str."
  (let ((tipo  (tipo-restriccion nodo))
        (check (slot-value nodo 'comprobacion))
        (elem  (slot-value nodo 'elemento)))
    (contract
     (case tipo
       (:nppq (format nil "No puede pasar lo siguiente: ~a." (expr->nl check)))
       (:tqpq (format nil "Tiene que pasar lo siguiente: ~a." (expr->nl check)))
       (:ndpq (format nil "No debe pasar lo siguiente: ~a."   (expr->nl check)))
       (:sbqp (format nil "Sería bueno lo siguiente: ~a."     (expr->nl check)))
       (:minimizar
        (if (and check elem)
            (format nil "Se prefiere la solución que minimiza el máximo, entre ~a, de ~a."
                    (nl-noun (nombre-entidad elem) :definite t :plural t)
                    (expr->nl check))
            "Se prefiere la solución que minimiza. [sin consulta o elemento]"))
       (:maximizar
        (if (and check elem)
            (format nil "Se prefiere la solución que maximiza el mínimo, entre ~a, de ~a."
                    (nl-noun (nombre-entidad elem) :definite t :plural t)
                    (expr->nl check))
            "Se prefiere la solución que maximiza. [sin consulta o elemento]"))
       (t (format nil "[RESTRICCION_DESCONOCIDA: ~a]" (class-name (class-of nodo))))))))
