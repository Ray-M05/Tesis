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

(defun classify-atom (a v1 v2)
  "Un atomo del :comprueba -> su papel en el patron, o NIL."
  (typecase a
    (op-igual
     (let ((izq (slot-value a 'operando-izq))
           (der (slot-value a 'operando-der)))
       (or (match-shared   izq der v1 v2)
           (match-adjacent izq der v1 v2)
           (match-link     izq der v1 v2))))
    (op-distinto
     (multiple-value-bind (p1 r1) (access-path (slot-value a 'operando-izq))
       (multiple-value-bind (p2 r2) (access-path (slot-value a 'operando-der))
         (when (and p1 p2 (equal p1 p2)
                    (or (and (eq r1 v1) (eq r2 v2))
                        (and (eq r1 v2) (eq r2 v1))))
           (list :distinct p1)))))
    (op-or (match-roles a v1 v2))
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
          (shared '()) (distinct '()) (adjacent '()) (links '()) (roles '()))

      ;; 1. Clasificar cada atomo. Uno solo sin reconocer aborta el
      ;;    patron entero: mejor caer a la capa literal que emitir una
      ;;    oracion que se deja algo fuera en silencio.
      (dolist (a (flatten-op (slot-value nodo 'comprobacion) 'op-and))
        (let ((c (classify-atom a v1 v2)))
          (case (and c (first c))
            (:shared   (push (second c) shared))
            (:distinct (push (second c) distinct))
            (:adjacent (push (second c) adjacent))
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
      (unless (or shared adjacent) (return-from match-pairwise nil))

      (list :entity   comb
            :distinct (remove-duplicates distinct :test #'equal)
            :adjacent (remove-duplicates adjacent :test #'equal)
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

(defun pairwise->nl (m problema)
  "Oracion prohibitiva: 'No puede haber dos X ... con ...'"
  (multiple-value-bind (sujeto quals decis) (pairwise-parts m problema)
    (when decis
      (format nil "No puede haber dos ~a~{ ~a~} con ~a."
              sujeto quals (join-nl (mapcar #'same-path->nl decis))))))

(defun pairwise->noun (m problema)
  "Sintagma nominal, para encajarlo como objeto de un minimizar."
  (multiple-value-bind (sujeto quals decis) (pairwise-parts m problema)
    (when decis
      (format nil "pares de ~a~{ ~a~} con ~a"
              sujeto quals (join-nl (mapcar #'same-path->nl decis))))))


;; =====================================================================
;; DESPACHO
;; =====================================================================

(defun query-of (check)
  "De (op-mayor <consulta> 0) saca la consulta. NIL en otro caso."
  (when (typep check 'op-mayor)
    (let ((izq (slot-value check 'operando-izq))
          (der (slot-value check 'operando-der)))
      (when (and (typep izq 'consulta-simple) (eql der 0))
        izq))))

(defun idiom->nl (nodo problema)
  "Intenta reconocer un idioma. NIL si no encaja ninguno."
  (let ((tipo  (tipo-restriccion nodo))
        (check (slot-value nodo 'comprobacion))
        (elem  (slot-value nodo 'elemento)))
    (case tipo
      ((:nppq :ndpq)
       (let ((q (query-of check)))
         (when q
           (let ((m (match-pairwise q problema)))
             (when m (pairwise->nl m problema))))))
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
             ;; Minimax sobre un conteo de choques.
             (t (let ((m (match-pairwise check problema)))
                  (when m
                    (format nil "Se prefiere la solución que minimiza, ~a más afectad~a, el número de ~a."
                            sup (if f "a" "o")
                            (pairwise->noun m problema)))))))))
      (t nil))))

(defun smart-constraint->nl (nodo problema)
  "Idioma si se reconoce; traduccion literal si no. Nunca falla."
  (contract (or (idiom->nl nodo problema)
                (constraint->nl nodo))))

(defun smart-query->nl (nodo problema)
  "Lo mismo para una consulta suelta. Las consultas SON el patron que
   envuelven las restricciones, asi que se reconocen con el mismo matcher
   y solo cambia el envoltorio: sintagma nominal en vez de oracion."
  (contract
   (or (let ((m (match-pairwise nodo problema)))
         (and m (let ((n (pairwise->noun m problema)))
                  (and n (format nil "el número de ~a" n)))))
       ;; Conteo de valores distintos sobre un parametro. La forma basta:
       ;; la condicion solo dice que el parametro aparece en la fila, y
       ;; eso es lo que significa "interviene".
       (and (eq 'contar-distintos-dias (slot-value nodo 'operacion))
            (slot-value nodo 'args)
            "el número de días distintos en los que interviene")
       (query->nl nodo))))
