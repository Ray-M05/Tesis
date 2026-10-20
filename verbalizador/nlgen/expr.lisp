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
;; CAMINOS DE ACCESO
;; =====================================================================
;; Vive aqui y no en idioms.lisp porque la capa literal tambien lo
;; necesita, para decidir si puede acortar una cadena.

(defun access-path (nodo)
  "Descompone una cadena de accesores en (valores CAMINO RAIZ).
   (tipo (programa e1))  ->  (TIPO PROGRAMA) , E1
   El ultimo tramo del camino es el slot de la entidad combinacion."
  (let ((camino '()) (n nodo))
    (loop while (typep n 'acceso-a-atributo-de-entidad)
          do (push (slot-value n 'atributo) camino)
             (setf n (slot-value n 'entidad)))
    (if (and camino (symbolp n))
        (values (nreverse camino) n)
        (values nil nil))))


;; =====================================================================
;; CONTEXTO DE RENDERIZADO
;; =====================================================================
;; Dos cosas que la capa literal no puede saber mirando solo el nodo.

(defvar *var-entities* '()
  "Alist variable de iteracion -> entidad que recorre. Lo liga quien
   renderiza una consulta. Sin el no se puede saber desde que entidad
   arranca una cadena de acceso, y por tanto no se puede acortar.")

(defvar *elide-var* nil
  "Variable que NO debe aparecer en el texto. Cuando una consulta recorre
   una sola fila, nombrarla ('el día de u') no aporta nada y estorba; se
   escribe el posesivo ('su día'). Ligarla a NIL deja el texto como antes.")

(defvar *elide-style* :posesivo
  "Como se escribe lo elidido. :posesivo da 'su día', que es lo correcto
   cuando se habla de una fila. :definido da 'el día', que es lo correcto
   cuando la condicion vale para las dos filas de un par y el posesivo
   no sabria a cual de las dos apunta.")

(defun var-entity (v)
  (cdr (assoc v *var-entities*)))

(defun shortenable-p (nodo)
  "T si la cadena se puede acortar sin volverse ambigua."
  (multiple-value-bind (camino raiz) (access-path nodo)
    (and camino raiz (cdr camino)
         (let ((e (var-entity raiz)))
           (and e (attr-unique-from-p e (first camino))))
         raiz)))


;; =====================================================================
;; EXPRESIONES
;; =====================================================================

(defun bin->nl (nodo verbo)
  "Operador binario infijo: '<izq> <verbo> <der>'."
  (format nil "~a ~a ~a"
          (expr->nl (slot-value nodo 'operando-izq))
          verbo
          (expr->nl (slot-value nodo 'operando-der))))

(defun boolean->nl (nodo)
  "(op-igual (admite-doble (plan (sesion u))) 0) -> 'su plan no admite
   turno doble'. La codificacion 0/1 es un truco de modelado y la prosa
   no tiene por que exponerlo. Solo dispara con los slots declarados
   como predicado: con cualquier otro se cae a la comparacion literal,
   que es fea pero nunca miente."
  (let ((izq (slot-value nodo 'operando-izq))
        (der (slot-value nodo 'operando-der)))
    (when (and (typep izq 'acceso-a-atributo-de-entidad)
               (integerp der) (<= 0 der 1))
      (let ((frase (predicate-phrase (slot-value izq 'atributo)
                                     :negated (eql der 0))))
        (when frase
          (format nil "~a ~a" (expr->nl (slot-value izq 'entidad)) frase))))))

(defun entity-valued-p (attr)
  "T si el slot apunta a otra entidad, o sea si su nombre ES una entidad."
  (and (gethash attr *slots-de-entidad*) t))

(defun attr->nl (nodo)
  "Un acceso a atributo, acortado y elidido cuando se puede.

   El acortado distingue dos casos, y la distincion importa:

     plan(sesion(u))                -> 'su plan'
     dia-preparacion(asignatura(…)) -> 'el día de preparación de su asignatura'

   Un atributo que apunta a otra entidad nombra algo que la fila tiene,
   y se puede colapsar hasta la raiz. Uno escalar PERTENECE a una entidad
   concreta, y hay que seguir nombrandola: 'su día de preparación' diria
   que el dia de preparacion es de la ubicacion, que es falso. El dueno
   se colapsa por su cuenta en la llamada recursiva."
  (let* ((attr (slot-value nodo 'atributo))
         (dueno (slot-value nodo 'entidad))
         (base (if (entity-valued-p attr)
                   (or (shortenable-p nodo) dueno)
                   dueno)))
    (if (and *elide-var* (eq base *elide-var*))
        (if (eq *elide-style* :definido)
            (nl-noun attr :definite t)
            (format nil "su ~a" (nl-name attr)))
        (format nil "~a de ~a" (nl-noun attr :definite t) (expr->nl base)))))

(defun expr->nl (nodo)
  "Traduce un nodo AST a un fragmento en espanol."
  (typecase nodo
    (null    "nada")
    (symbol  (nl-var nodo))
    (number  (format nil "~a" nodo))
    (string  (format nil "«~a»" nodo))

    ;; (tipo (programa e1)) -> "el tipo de el programa de e1"
    ;; contract() lo convierte despues en "el tipo del programa de e1".
    (acceso-a-atributo-de-entidad (attr->nl nodo))

    ;; "es igual a" y "es diferente de" son invariables en genero. Es la
    ;; misma razon por la que se eligio "es igual a" y no "es el mismo
    ;; que": el sujeto es una expresion arbitraria cuyo genero habria que
    ;; calcular. "distinto" si varia, y por eso no sirve.
    (op-igual       (or (boolean->nl nodo) (bin->nl nodo "es igual a")))
    (op-distinto    (bin->nl nodo "es diferente de"))
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

(defun var-entity-alist (vars doms)
  "Alist variable -> entidad, para poder acortar cadenas de acceso."
  (loop for v in vars for d in doms collect (cons v (nombre-entidad d))))

(defun query->nl (nodo)
  "consulta-simple -> que mide. Espejo de consulta->math-str."
  (let* ((args  (slot-value nodo 'args))
         (vars  (slot-value nodo 'variable-iteracion))
         (doms  (slot-value nodo 'dominio-iteracion))
         (check (slot-value nodo 'comprobacion))
         (op    (slot-value nodo 'operacion))
         (*var-entities* (append (var-entity-alist vars doms) *var-entities*)))
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
