;; =====================================================================
;; idioms.lisp — Reconocimiento de patrones y plantillas de oracion
;; =====================================================================
;; La capa literal (expr.lisp) traduce nodo a nodo y produce parrafos de
;; ocho lineas correctos e ilegibles. Un humano no traduce nodo a nodo:
;; reconoce la FORMA completa y elige una frase hecha.
;;
;; Este archivo tiene dos mitades separadas a proposito:
;;   - el MATCHER  (match-pairwise) clasifica una consulta en un patron
;;   - los EMISORES (pairwise->nl)  rellenan una plantilla
;;
;; REGLA DE SEGURIDAD: esta capa va ENCIMA de la literal, nunca en su
;; lugar. Si no se reconoce el patron, smart-constraint->nl cae a
;; constraint->nl. Un dominio con una restriccion rara sigue produciendo
;; documento, solo que con un parrafo torpe.
;;

;; =====================================================================
;; CAMINOS DE ACCESO
;; =====================================================================

(defun decision-path-p (camino problema)
  "T si el atributo depende de lo que se decide"
  (and (member (car (last camino)) (problema-horario-slots-variables problema))
       t))

(defun same-path->nl (camino)
  "(TIPO PROGRAMA) -> 'el mismo tipo'   (FECHA) -> 'la misma fecha'"
  (let ((cabeza (first camino)))
    (format nil "~a ~a"
            (if (eq :f (nl-gender cabeza)) "la misma" "el mismo")
            (nl-name cabeza))))


;; =====================================================================
;; CLASIFICACION DE ATOMOS
;; =====================================================================

(defun match-shared (izq der v1 v2)
  "(op-igual (f v1) (f v2)) -> los dos elementos comparten f."
  (multiple-value-bind (p1 r1) (access-path izq)
    (multiple-value-bind (p2 r2) (access-path der)
      (when (and p1 p2 (equal p1 p2)
                 (or (and (eq r1 v1) (eq r2 v2))
                     (and (eq r1 v2) (eq r2 v1))))
        (list :shared p1)))))

(defun match-adjacent (izq der v1 v2)
  "(op-igual (op-suma (f v1) k) (f v2)) -> son consecutivos en f."
  (when (typep izq 'op-suma)
    (multiple-value-bind (p1 r1) (access-path (slot-value izq 'operando-izq))
      (multiple-value-bind (p2 r2) (access-path der)
        (when (and p1 p2 (equal p1 p2)
                   (numberp (slot-value izq 'operando-der))
                   (or (and (eq r1 v1) (eq r2 v2))
                       (and (eq r1 v2) (eq r2 v1))))
          (list :adjacent p1))))))

(defun match-link (izq der v1 v2)
  "(op-igual (f vX) S) con S una tercera variable -> enlace."
  (multiple-value-bind (p r) (access-path izq)
    (if (and p (member r (list v1 v2))
             (symbolp der) der (not (member der (list v1 v2))))
        (list :link der p)
        (multiple-value-bind (p2 r2) (access-path der)
          (when (and p2 (member r2 (list v1 v2))
                     (symbolp izq) izq (not (member izq (list v1 v2))))
            (list :link izq p2))))))

(defun match-roles (nodo v1 v2)
  "Una disyuncion de igualdades contra la misma tercera variable por
   caminos distintos. Es lo que queda del inlining de una consulta
   auxiliar como profesor-en-tribunal: el nombre desaparece del AST y
   solo sobrevive el op-or de cinco op-igual."
  (let ((raiz nil) (sym nil))
    (dolist (d (flatten-op nodo 'op-or) (and sym (list :roles sym)))
      (unless (typep d 'op-igual) (return nil))
      (multiple-value-bind (p r) (access-path (slot-value d 'operando-izq))
        (let ((s (slot-value d 'operando-der)))
          (unless (and p (member r (list v1 v2)) (symbolp s) s
                       (not (member s (list v1 v2))))
            (return nil))
          (if raiz
              (unless (and (eq raiz r) (eq sym s)) (return nil))
              (setf raiz r sym s)))))))

(defun match-filter (a v1 v2)
  "(op-igual (f v) k) con k constante -> condicion propia de una fila, no
   una comparacion entre las dos. Es el papel que a Saul le faltaba: las
   tres restricciones de turno doble lo llevan y por el se caia el patron
   entero. Se guarda el nodo, no el camino, porque la frase se emite
   renderizandolo con la variable elidida."
  (let ((izq (slot-value a 'operando-izq))
        (der (slot-value a 'operando-der)))
    (multiple-value-bind (p r) (access-path izq)
      (when (and p (member r (list v1 v2)) (numberp der))
        (list :filter (cons r a))))))

(defun match-order (a v1 v2)
  "(op-mayor (f vA) (f vB)) por el mismo camino -> ordena el par para no
   contar dos veces la misma pareja. NO es una condicion del problema y
   no debe aparecer en la prosa: un humano tampoco la dice."
  (multiple-value-bind (p1 r1) (access-path (slot-value a 'operando-izq))
    (multiple-value-bind (p2 r2) (access-path (slot-value a 'operando-der))
      (when (and p1 p2 (equal p1 p2)
                 (or (and (eq r1 v1) (eq r2 v2))
                     (and (eq r1 v2) (eq r2 v1))))
        (list :order p1)))))

(defun match-non-adjacent (a v1 v2)
  "(op-distinto (f vA) (op-suma (f vB) k)) -> los dos NO son consecutivos."
  (let ((izq (slot-value a 'operando-izq))
        (der (slot-value a 'operando-der)))
    (dolist (par (list (cons izq der) (cons der izq)))
      (let ((lado (car par)) (suma (cdr par)))
        (when (typep suma 'op-suma)
          (multiple-value-bind (p1 r1) (access-path lado)
            (multiple-value-bind (p2 r2) (access-path (slot-value suma 'operando-izq))
              (when (and p1 p2 (equal p1 p2)
                         (numberp (slot-value suma 'operando-der))
                         (or (and (eq r1 v1) (eq r2 v2))
                             (and (eq r1 v2) (eq r2 v1))))
                (return (list :nonadj p1))))))))))

(defun classify-atom (a v1 v2)
  "Un atomo del :comprueba -> su papel en el patron, o NIL."
  (typecase a
    (op-igual
     (let ((izq (slot-value a 'operando-izq))
           (der (slot-value a 'operando-der)))
       (or (match-shared   izq der v1 v2)
           (match-adjacent izq der v1 v2)
           (match-filter   a v1 v2)
           (match-link     izq der v1 v2))))
    (op-distinto
     (or (match-non-adjacent a v1 v2)
         (multiple-value-bind (p1 r1) (access-path (slot-value a 'operando-izq))
           (multiple-value-bind (p2 r2) (access-path (slot-value a 'operando-der))
             (when (and p1 p2 (equal p1 p2)
                        (or (and (eq r1 v1) (eq r2 v2))
                            (and (eq r1 v2) (eq r2 v1))))
               (list :distinct p1))))))
    (op-mayor (or (match-order a v1 v2) (match-filter a v1 v2)))
    (op-menor (match-filter a v1 v2))
    (op-or    (match-roles a v1 v2))
    (t nil)))


;; =====================================================================
;; EL MATCHER: CHOQUE POR PARES
;; =====================================================================

(defun var-domain (v vars doms)
  (loop for x in vars for d in doms
        when (eq x v) return (nombre-entidad d)))

(defun match-pairwise (nodo problema)
  "Reconoce el patron de choque por pares. Devuelve un plist o NIL.

   Forma: dos variables que iteran sobre la entidad combinacion, mas un
   conjunto de atomos que comparan la misma cosa en las dos. Cubre la
   familia de conflictos, colisiones y adyacencia."
  (let* ((vars (slot-value nodo 'variable-iteracion))
         (doms (slot-value nodo 'dominio-iteracion))
         (comb (problema-horario-entidad-horario problema))
         (pares (loop for v in vars for d in doms
                      when (eq (nombre-entidad d) comb) collect v)))
    (unless (= 2 (length pares)) (return-from match-pairwise nil))

    (let ((v1 (first pares)) (v2 (second pares))
          (shared '()) (distinct '()) (adjacent '()) (links '()) (roles '())
          (filters '()) (nonadj '()))

      ;; 1. Clasificar cada atomo. Uno solo sin reconocer aborta el
      ;;    patron entero: mejor caer a la capa literal que emitir una
      ;;    oracion que se deja algo fuera en silencio.
      (dolist (a (flatten-op (slot-value nodo 'comprobacion) 'op-and))
        (let ((c (classify-atom a v1 v2)))
          (case (and c (first c))
            (:shared   (push (second c) shared))
            (:distinct (push (second c) distinct))
            (:adjacent (push (second c) adjacent))
            (:nonadj   (push (second c) nonadj))
            (:filter   (push (second c) filters))
            (:order    nil)   ; antisimetria: no se dice
            (:link     (push (cons (second c) (third c)) links))
            (:roles    (push (second c) roles))
            (t (return-from match-pairwise nil)))))

      ;; 2. Dos enlaces a la misma variable por el mismo camino equivalen
      ;;    a que los dos elementos del par comparten ese atributo:
      ;;      canal(prog(e1)) = c  y  canal(prog(e2)) = c
      ;;    implica  canal(prog(e1)) = canal(prog(e2)).
      ;;    Un enlace sin pareja no se sabe interpretar: se aborta.
      (dolist (l (remove-duplicates links :test #'equal))
        (if (= 2 (count l links :test #'equal))
            (push (cdr l) shared)
            (return-from match-pairwise nil)))

      ;; 3. Igual con los roles: uno por cada elemento del par.
      (dolist (r (remove-duplicates roles))
        (unless (= 2 (count r roles)) (return-from match-pairwise nil)))

      ;; 4. Sin nada compartido no hay choque que describir.
      (unless (or shared adjacent nonadj) (return-from match-pairwise nil))

      (list :entity   comb
            :vars     vars
            :doms     doms
            :distinct (remove-duplicates distinct :test #'equal)
            :adjacent (remove-duplicates adjacent :test #'equal)
            :nonadj   (remove-duplicates nonadj :test #'equal)
            :filters  (nreverse filters)
            :shared   (remove-duplicates (nreverse shared) :test #'equal)
            :roles    (loop for r in (remove-duplicates roles)
                            for d = (var-domain r vars doms)
                            when d collect d)))))


;; =====================================================================
;; EMISOR
;; =====================================================================

(defun distinct->nl (camino problema fem)
  "Como se describe la dimension que separa a los dos elementos.

   Si es la identidad, basta con 'distintas'. Si no, hay que nombrarla:
   dos clases EN AULAS DISTINTAS no es lo mismo que dos clases distintas,
   y el DSL de docentes usa las dos formas en restricciones vecinas."
  (let ((id (problema-horario-slot-identidad problema)))
    (if (equal camino (list id))
        (if fem "distintas" "distintos")
        (let ((cabeza (first camino)))
          (format nil "de ~a ~a"
                  (nl-name cabeza :plural t)
                  (if (eq :f (nl-gender cabeza)) "distintas" "distintos"))))))

(defun nonadj->nl (camino)
  "(ORDEN TURNO) -> 'en turnos no consecutivos'. La dimension que importa
   es la entidad, no el atributo numerico por el que se mide."
  (let ((dim (if (cdr camino) (second camino) (first camino))))
    (format nil "en ~a no consecutiv~a"
            (nl-name dim :plural t)
            (if (eq :f (nl-gender dim)) "as" "os"))))

(defun filters->nl (filtros m)
  "Las condiciones propias de la fila, como clausula final. Se renderizan
   con la variable elidida: 'su plan no admite turno doble' y no 'el
   admite doble del plan de la sesión de u1 es igual a 0'."
  (when filtros
    (let ((*var-entities* (append (var-entity-alist (getf m :vars) (getf m :doms))
                                  *var-entities*))
          ;; Articulo definido y no posesivo: la condicion vale para las
          ;; dos filas del par, y 'su plan' no diria de cual de las dos.
          (*elide-style* :definido))
      (join-nl (mapcar (lambda (f)
                         (let ((*elide-var* (car f)))
                           (expr->nl (cdr f))))
                       filtros)))))

(defun pairwise-parts (m problema)
  "Devuelve (valores SUJETO CALIFICADORES PROHIBIDO) ya en espanol."
  (let* ((ent   (getf m :entity))
         (fem   (eq :f (nl-gender ent)))
         (datos (remove-if     (lambda (p) (decision-path-p p problema)) (getf m :shared)))
         (decis (remove-if-not (lambda (p) (decision-path-p p problema)) (getf m :shared)))
         (quals '()))
    (dolist (d (getf m :distinct)) (push (distinct->nl d problema fem) quals))
    (when (getf m :adjacent) (push (if fem "consecutivas" "consecutivos") quals))
    (dolist (p datos) (push (format nil "de ~a" (same-path->nl p)) quals))
    (dolist (d (getf m :roles))
      (push (format nil "que compartan ~a" (nl-noun d)) quals))
    (values (nl-name ent :plural t)
            (nreverse quals)
            decis)))

(defun pairwise-tail (m problema)
  "Lo que va detras del 'con ...': la no adyacencia y los filtros. Van al
   final porque modifican a la pareja entera, no al sujeto."
  (declare (ignore problema))
  (format nil "~{ ~a~}~@[, cuando ~a~]"
          (mapcar #'nonadj->nl (getf m :nonadj))
          (filters->nl (getf m :filters) m)))

(defun pairwise->nl (m problema)
  "Oracion prohibitiva: 'No puede haber dos X ... con ...'"
  (multiple-value-bind (sujeto quals decis) (pairwise-parts m problema)
    (when decis
      (format nil "No puede haber dos ~a~{ ~a~} con ~a~a."
              sujeto quals (join-nl (mapcar #'same-path->nl decis))
              (pairwise-tail m problema)))))

(defun pairwise->noun (m problema)
  "Sintagma nominal, para encajarlo como objeto de un minimizar."
  (multiple-value-bind (sujeto quals decis) (pairwise-parts m problema)
    (when decis
      (format nil "pares de ~a~{ ~a~} con ~a~a"
              sujeto quals (join-nl (mapcar #'same-path->nl decis))
              (pairwise-tail m problema)))))


;; =====================================================================
;; FAMILIA: FILTRO DE UNA SOLA FILA
;; =====================================================================
;; Una sola variable, que recorre la entidad combinacion, y condiciones
;; que hablan solo de esa fila. No hay par, no hay choque: hay filas
;; prohibidas. Es la familia mas numerosa de Saul y el reconocedor
;; anterior ni la miraba, porque empezaba exigiendo dos variables.

(defun match-single-row (nodo problema)
  (let* ((vars (slot-value nodo 'variable-iteracion))
         (doms (slot-value nodo 'dominio-iteracion))
         (comb (problema-horario-entidad-horario problema)))
    (when (and (= 1 (length vars))
               (eq (nombre-entidad (first doms)) comb))
      (list :entity comb :var (first vars) :vars vars :doms doms
            :check (slot-value nodo 'comprobacion)
            :args  (slot-value nodo 'args)))))

(defun single-row-conditions (m)
  "Las condiciones, con la variable elidida."
  (let ((*var-entities* (append (var-entity-alist (getf m :vars) (getf m :doms))
                                *var-entities*))
        (*elide-var* (getf m :var)))
    (expr->nl (getf m :check))))

(defun single-row->nl (m)
  "Oracion prohibitiva en singular. Se usa indicativo tras los dos puntos
   por la misma razon que constraint->nl: conjugar en subjuntivo esta
   fuera del alcance de la capa literal."
  (let ((ent (getf m :entity)))
    (format nil "~a ~a puede cumplir lo siguiente: ~a."
            (if (eq :f (nl-gender ent)) "Ninguna" "Ningún")
            (nl-name ent)
            (single-row-conditions m))))

(defun single-row->noun (m)
  (format nil "~a en que ~a"
          (nl-name (getf m :entity) :plural t)
          (single-row-conditions m)))


;; Una sola variable sobre la entidad combinacion y una sola igualdad, que
;; compara una dimension de la fila contra el parametro de la consulta.

(defun grouping-dim (expr var)
  "Si EXPR es una cadena de accesos que arranca en VAR, devuelve la
   dimension exterior: la que agrupa. NIL si no lo es."
  (multiple-value-bind (camino raiz) (access-path expr)
    (and camino (eq raiz var) (first camino))))

(defun match-grouping (nodo problema)
  (let ((m (match-single-row nodo problema)))
    (when (and m
               (= 1 (length (getf m :args)))
               (typep (getf m :check) 'op-igual))
      (let* ((check (getf m :check))
             (arg   (first (getf m :args)))
             (var   (getf m :var))
             (izq   (slot-value check 'operando-izq))
             (der   (slot-value check 'operando-der))
             ;; El parametro puede venir en cualquiera de los dos lados.
             (dim   (cond ((eq der arg) (grouping-dim izq var))
                          ((eq izq arg) (grouping-dim der var)))))
        (when dim
          (list :entity (getf m :entity) :dim dim :arg arg))))))

(defun grouping-tail (m)
  "'en una misma instalacion', 'en un mismo turno'.
   El articulo sale del genero crudo y NO de nl-article, a proposito: la
   marca :art-m solo vale cuando el articulo toca al sustantivo, y aqui
   se interpone 'mismo'. Es la regla de 'un aula' frente a 'una misma
   aula', la misma que el lexico documenta."
  (let* ((dim (getf m :dim))
         (f   (eq :f (nl-gender dim))))
    (format nil "en ~a mism~a ~a"
            (if f "una" "un") (if f "a" "o") (nl-name dim))))

(defun grouping->nl (m problema)
  "Oracion de preferencia: minimax de reparto sobre una dimension."
  (format nil "Se prefiere el reparto que reduce el número máximo de ~a ~a."
          (nl-name (problema-horario-slot-identidad problema) :plural t)
          (grouping-tail m)))

(defun grouping->noun (m problema)
  "Sintagma nominal, para la seccion de lo que se mide."
  (format nil "~a que caen ~a"
          (nl-name (problema-horario-slot-identidad problema) :plural t)
          (grouping-tail m)))


;; =====================================================================
;; FAMILIA: CRUCE CONTRA UNA TABLA DE PROHIBICIONES
;; =====================================================================
;; Una variable sobre la entidad combinacion y otra sobre una entidad de
;; datos, con igualdades que emparejan atributos homonimos. El lenguaje
;; no tiene pertenencia, asi que una relacion de tamano variable solo se
;; expresa enunciandola como prohibicion; esta es su forma.

(defun match-join (nodo problema)
  (let* ((vars (slot-value nodo 'variable-iteracion))
         (doms (slot-value nodo 'dominio-iteracion))
         (comb (problema-horario-entidad-horario problema))
         (fila (loop for v in vars for d in doms
                     when (eq (nombre-entidad d) comb) collect v))
         (otra (loop for v in vars for d in doms
                     unless (eq (nombre-entidad d) comb) collect (cons v (nombre-entidad d)))))
    (when (and (= 1 (length fila)) (= 1 (length otra)))
      (let ((v (first fila)) (w (car (first otra))) (dims '()))
        (dolist (a (flatten-op (slot-value nodo 'comprobacion) 'op-and))
          (unless (typep a 'op-igual) (return-from match-join nil))
          (multiple-value-bind (p1 r1) (access-path (slot-value a 'operando-izq))
            (multiple-value-bind (p2 r2) (access-path (slot-value a 'operando-der))
              ;; Las dos partes tienen que ser accesos, una por cada
              ;; variable, y coincidir en el atributo que emparejan.
              (unless (and p1 p2 (eq (first p1) (first p2))
                           (or (and (eq r1 v) (eq r2 w))
                               (and (eq r1 w) (eq r2 v))))
                (return-from match-join nil))
              (pushnew (first p1) dims))))
        (when dims
          (list :entity comb :other (cdr (first otra)) :dims (nreverse dims)))))))

(defun join->nl (m)
  (let ((ent (getf m :entity)))
    (format nil "~a ~a puede coincidir con ~a en ~a."
            (if (eq :f (nl-gender ent)) "Ninguna" "Ningún")
            (nl-name ent)
            (nl-noun (getf m :other))
            (join-nl (mapcar (lambda (d) (nl-noun d :definite t)) (getf m :dims))))))

(defun join->noun (m)
  (format nil "~a que coinciden con ~a en ~a"
          (nl-name (getf m :entity) :plural t)
          (nl-noun (getf m :other))
          (join-nl (mapcar (lambda (d) (nl-noun d :definite t)) (getf m :dims)))))


;; =====================================================================
;; FAMILIA: CUANTIFICADA CON UMBRAL
;; =====================================================================
;; tqpq sobre una entidad, comparando el conteo de filas que le
;; corresponden contra un atributo suyo. Es la forma que toma cualquier
;; cupo en este lenguaje, porque el umbral del lado derecho se descarta
;; en nppq y tiene que vivir como atributo de la entidad cuantificada.

(defun match-quantified (nodo problema)
  (let ((check (slot-value nodo 'comprobacion))
        (elem  (slot-value nodo 'elemento)))
    (when (and check elem (typep check 'operacion-binaria))
      (let ((izq (slot-value check 'operando-izq))
            (der (slot-value check 'operando-der)))
        (when (and (typep izq 'consulta-simple)
                   (typep der 'acceso-a-atributo-de-entidad)
                   (typep (slot-value der 'entidad) 'ref-gen-entidad))
          (list :elem  (nombre-entidad elem)
                :attr  (slot-value der 'atributo)
                :comb  (problema-horario-entidad-horario problema)
                :rel   (typecase check
                         (op-igual       "debe ser igual a")
                         (op-menor-igual "no puede superar")
                         (op-mayor-igual "no puede quedar por debajo de")
                         (op-menor       "tiene que ser menor que")
                         (op-mayor       "tiene que ser mayor que")
                         (t nil))))))))

(defun quantified->nl (m)
  (when (getf m :rel)
    (format nil "El número de ~a de cada ~a ~a su ~a."
            (nl-name (getf m :comb) :plural t)
            (nl-name (getf m :elem))
            (getf m :rel)
            (nl-name (getf m :attr)))))


;; =====================================================================
;; DESPACHO
;; =====================================================================

(defun query-of (check)
  "De (op-mayor <consulta> 0) saca la consulta. NIL en otro caso.

   Esa forma es un idioma, no una comparacion: dentro de un nppq
   significa 'que no ocurra ninguna vez'. Traducirla literalmente como
   'el número de casos es mayor que cero' es leer la mecanica en vez del
   significado, y es lo que producia la oracion de sesenta palabras con
   dos verbos chocando al final."
  (when (typep check 'op-mayor)
    (let ((izq (slot-value check 'operando-izq))
          (der (slot-value check 'operando-der)))
      (when (and (typep izq 'consulta-simple) (eql der 0))
        izq))))

(defun query-family (q problema)
  "Clasifica la FORMA de una consulta antes de intentar reconocerla.

   Es el paso que faltaba. El reconocedor anterior era uno solo y
   empezaba exigiendo dos variables sobre la entidad combinacion, asi
   que las familias que no la cumplen ni llegaban a mirarse. Aqui se
   mira primero cuantas variables hay y sobre que, y se despacha."
  (let* ((vars (slot-value q 'variable-iteracion))
         (doms (slot-value q 'dominio-iteracion))
         (comb (problema-horario-entidad-horario problema))
         (n-comb (count comb doms :key #'nombre-entidad))
         (n-otras (- (length vars) n-comb)))
    (cond ((>= n-comb 2)                      :pairwise)
          ((and (= n-comb 1) (zerop n-otras)) :single-row)
          ((and (= n-comb 1) (= n-otras 1))   :join)
          (t                                  :none))))

(defun query-idiom->nl (q problema &key noun)
  "Reconoce una consulta y devuelve oracion o sintagma nominal. NIL si no
   encaja. Cada familia tiene su reconocedor y su emisor; la regla de
   seguridad se conserva intacta: si el reconocedor de la familia falla,
   se devuelve NIL y quien llama cae a la capa literal.

   Las familias describen CUANTAS filas cumplen algo, asi que solo valen
   si la operacion cuenta filas. Con contar-distintos-dias la consulta
   mide otra cosa -dias distintos, no filas- y describirla como un conteo
   de filas seria falso."
  (unless (member (slot-value q 'operacion) '(suma contar))
    (return-from query-idiom->nl nil))
  (case (query-family q problema)
    (:pairwise   (let ((m (match-pairwise q problema)))
                   (and m (if noun (pairwise->noun m problema)
                                   (pairwise->nl   m problema)))))
    ;; La agrupacion se intenta ANTES de single-row y solo para el
    ;; sintagma nominal. El orden importa: match-single-row acepta
    ;; cualquier condicion de una fila, asi que si va primero se queda
    ;; con el caso y nunca se llega al reconocedor mas especifico.
    ;; Para la oracion suelta no aplica: una agrupacion envuelta en un
    ;; nppq diria "ninguna fila puede caer en un grupo", que no es lo
    ;; que la restriccion significa. Ahi se cae a single-row, que si lo
    ;; dice bien.
    (:single-row (or (and noun
                          (let ((g (match-grouping q problema)))
                            (and g (grouping->noun g problema))))
                     (let ((m (match-single-row q problema)))
                       (and m (if noun (single-row->noun m) (single-row->nl m))))))
    (:join       (let ((m (match-join q problema)))
                   (and m (if noun (join->noun m) (join->nl m)))))
    (t nil)))

(defun idiom->nl (nodo problema)
  "Intenta reconocer un idioma. NIL si no encaja ninguno."
  (let ((tipo  (tipo-restriccion nodo))
        (check (slot-value nodo 'comprobacion))
        (elem  (slot-value nodo 'elemento)))
    (case tipo
      ((:nppq :ndpq)
       (let ((q (query-of check)))
         (when q (query-idiom->nl q problema))))
      ((:tqpq :sbqp)
       (let ((m (match-quantified nodo problema)))
         (when m (quantified->nl m))))
      (:minimizar
       (when (and (typep check 'consulta-simple) elem)
         (let* ((e   (nombre-entidad elem))
                (f   (eq :f (nl-gender e)))
                (sup (format nil "para ~a ~a" (nl-article e :definite t) (nl-name e))))
           (case (slot-value check 'operacion)
             ;; Minimax sobre valores distintos. No hace falta mirar la condicion: la forma
             ;; ya dice todo lo que la oracion necesita.
             (contar-distintos-dias
              (format nil "Se prefiere la solución que minimiza, ~a más cargad~a, el número de días distintos en los que interviene."
                      sup (if f "a" "o")))
             ;; Minimax de reparto sobre una dimension, o sobre un conteo
             ;; de choques. Se prueba la agrupacion primero porque es la
             ;; forma mas especifica; si no encaja, se intenta el choque y
             ;; si tampoco, se devuelve NIL y la capa literal se encarga.
             (t (or (let ((g (match-grouping check problema)))
                      ;; La dimension agrupada tiene que ser la que se
                      ;; cuantifica. Si no coinciden, la oracion hablaria
                      ;; de un maximo sobre un conjunto que no es el que
                      ;; el minimizar recorre.
                      (and g (eq (getf g :dim) e)
                           (grouping->nl g problema)))
                    (let ((m (match-pairwise check problema)))
                      (when m
                        (format nil "Se prefiere la solución que minimiza, ~a más afectad~a, el número de ~a."
                                sup (if f "a" "o")
                                (pairwise->noun m problema))))))))))
      (t nil))))

(defun smart-constraint->nl (nodo problema)
  "Idioma si se reconoce; traduccion literal si no. Nunca falla."
  (contract (or (idiom->nl nodo problema)
                (constraint->nl nodo))))

(defun smart-query->nl (nodo problema)
  "Lo mismo para una consulta suelta. Las consultas SON el patron que
   envuelven las restricciones, asi que se reconocen con el mismo
   clasificador y solo cambia el envoltorio: sintagma nominal en vez de
   oracion."
  (contract
   (or (let ((n (query-idiom->nl nodo problema :noun t)))
         (and n (format nil "el número de ~a" n)))
       ;; Conteo de valores distintos sobre un parametro. La forma basta:
       ;; la condicion solo dice que el parametro aparece en la fila, y
       ;; eso es lo que significa "interviene".
       (and (eq 'contar-distintos-dias (slot-value nodo 'operacion))
            (slot-value nodo 'args)
            "el número de días distintos en los que interviene")
       (query->nl nodo))))
