; =====================================================================
;; BASE
;; =====================================================================

(defclass nodo-ast () ()
  (:documentation "Clase base absoluta para todos los nodos del Ã¡rbol."))


;; =====================================================================
;; ENTIDADES
;; =====================================================================

(defclass entidad () ())

(defclass ref-gen-entidad ()
  ((nombre-entidad :initarg :nombre-entidad :reader nombre-entidad)))

(defclass ref-especifica-ent () ())


;; =====================================================================
;; MACROS
;; =====================================================================

;; Expande formatos compactos de slot a la forma canÃ³nica de defclass:
;;   (nombre accessor)          â†' (nombre :initarg :nombre   :accessor accessor)
;;   (nombre :initarg-kw acc)   â†' (nombre :initarg :initarg-kw :accessor acc)
;;   forma canÃ³nica             â†' se deja pasar tal cual
(defun %expand-slot (slot)
  (cond ((= (length slot) 2)
         `(,(first slot) :initarg ,(intern (symbol-name (first slot)) :keyword)
                          :accessor ,(second slot)))
        ((= (length slot) 3)
         `(,(first slot) :initarg ,(second slot) :accessor ,(third slot)))
        (t slot)))


;; Genera (defclass NOMBRE PADRES SLOTS), el constructor (defun CONSTRUCTOR PARAMS ...)
;; y una funciÃ³n de acceso AST por cada slot: (defun INITARG (entidad) ...).
;;
;; Slots pueden escribirse en formato compacto:
;;   (nombre accessor)         â†' initarg derivado del nombre del slot
;;   (nombre :initarg-kw acc)  â†' initarg explÃ­cito (cuando difiere del nombre)
;;
;; Params-extra opcionales:
;;   :fn-name sym    â†' nombre explÃ­cito del constructor (por defecto: DEF-NOMBRE)
;;   :key            â†' constructor con &key (params derivados de los slots)
;;   :variadic p1 p2 â†' constructor variÃ¡dico que encadena N args por reducciÃ³n
;;   p1 p2           â†' constructor posicional con params explÃ­citos
;;   (vacÃ­o y sin slots) â†' solo defclass, sin constructor ni accesores
(defmacro def-clase (nombre padres slots &rest params-extra)
  (let* ((fn-name-pos  (position :fn-name params-extra))
         (fn-override  (when fn-name-pos (nth (1+ fn-name-pos) params-extra)))
         (params-extra (if fn-name-pos
                           (append (subseq params-extra 0 fn-name-pos)
                                   (subseq params-extra (+ fn-name-pos 2)))
                           params-extra))
         (nombre-str  (symbol-name nombre))
         (fn-sym      (or fn-override (intern (concatenate 'string "DEF-" nombre-str))))
         (keyword-p   (equal params-extra '(:key)))
         (variadic-p  (eq (first params-extra) :variadic))
         (real-extra  (if variadic-p (rest params-extra) params-extra))
         (slots-full  (mapcar #'%expand-slot slots))
         (derivados   (mapcar (lambda (slot)
                                (intern (symbol-name (getf (cdr slot) :initarg))))
                              slots-full))
         (params      (cond (keyword-p  derivados)
                            (variadic-p real-extra)
                            (real-extra real-extra)
                            (t          derivados)))
         (initargs    (loop for p in params
                            unless (member p lambda-list-keywords)
                            append (list (intern (symbol-name p) :keyword) p)))
         (lambda-ll   (if keyword-p (cons '&key params) params))
         ;; Las funciones de acceso AST usan el nombre del initarg.
         ;; Se omite :accessor en defclass para evitar redefinir la genÃ©rica CLOS.
         (slots-sin-acc (mapcar (lambda (slot)
                                  (list (first slot) :initarg (getf (cdr slot) :initarg)))
                                slots-full))
         (acc-fns     (mapcar (lambda (slot)
                                (let ((acc (intern (symbol-name (getf (cdr slot) :initarg)))))
                                  `(defun ,acc (entidad)
                                     (def-acceso-a-atributo-de-entidad ',acc entidad))))
                              slots-full))
         ;; Para :variadic: los params se mapean a (a b) en el lambda del reduce
         (var-initargs (when variadic-p
                         (loop for p in params
                               for lp in '(a b)
                               append (list (intern (symbol-name p) :keyword) lp)))))
    `(progn
       (defclass ,nombre ,padres ,slots-sin-acc)
       ,@(cond
           (variadic-p
            `((defun ,fn-sym (&rest args)
                (reduce (lambda (a b) (make-instance ',nombre ,@var-initargs)) args))))
           (params
            `((defun ,fn-sym ,lambda-ll
                (make-instance ',nombre ,@initargs)))))
       ,@acc-fns)))


;; Define en una sola forma mÃºltiples clases que heredan de nodo-ast.
;; Cada spec tiene la forma (NOMBRE SLOTS &rest PARAMS-EXTRA), que expande a
;; (def-clase NOMBRE (nodo-ast) SLOTS PARAMS-EXTRA...).
(defmacro def-nodos (&rest specs)
  `(progn
     ,@(mapcar (lambda (spec)
                 `(def-clase ,(first spec) (nodo-ast) ,@(rest spec)))
               specs)))


;; Define en una sola forma mÃºltiples grupos de subclases.
;; Cada spec tiene la forma (PADRE (PARAMS...) nombre1 nombre2 ...).
(defmacro def-jerarquias (&rest grupos)
  `(progn
     ,@(mapcar (lambda (grupo)
                 `(def-subclases ,(first grupo) ,(second grupo) ,@(cddr grupo)))
               grupos)))


;; Define en una sola forma un grupo de subclases que comparten el mismo padre.
;; Si params contiene :self-named, cada subclase usa su propio nombre como
;; constructor (sin prefijo DEF-). Sin :self-named, el constructor es DEF-NOMBRE.
(defmacro def-subclases (padre params &rest nombres)
  (let* ((self-p      (member :self-named params))
         (clean-params (remove :self-named params)))
    `(progn
       ,@(mapcar (lambda (nombre)
                   (if self-p
                       `(def-clase ,nombre (,padre) () :fn-name ,nombre ,@clean-params)
                       `(def-clase ,nombre (,padre) () ,@clean-params)))
                 nombres))))


;; =====================================================================
;; NODOS DEL AST
;; =====================================================================

(def-nodos
  ;; Estructuras de datos
  (comb-entidades     ((entidades comb-entidades-lista)))
  (lista              ((elementos lista-elementos)))
  ;; Acceso a datos
  (acceso-a-atributo-de-entidad ((atributo acceso-atributo)
                                  (entidad  acceso-entidad)))
  (acceso-a-elemento-de-comb    ((entidad        acceso-comb-entidad)
                                  (comb-entidades acceso-comb-origen)))
  ;; Consulta
  (consulta-simple
    ((args               consulta-args)
     (variable-iteracion consulta-var-iter)
     (dominio-iteracion  consulta-dominio)
     (comprobacion       consulta-comprobacion)
     (operacion          consulta-operacion)
     (retorno            consulta-retorno))
    :key)
  ;; Cuantificadores (padre de nppq, tqpq, ndpq, sbqp)
  (cuantificador-restriccion ((operador     cuanti-operador)
                               (comprobacion cuanti-comprobacion)
                               (elemento     cuanti-elemento)))
  ;; Comprobaciones de conjuntos
  (hay-elementos-duplicados ((lista     check-duplicados-lista)))
  (pertenece                ((elemento  pertenece-elemento)
                             (coleccion pertenece-coleccion)))
  ;; Operaciones â€” initarg difiere del nombre del slot, se especifica explÃ­cito
  (operacion-binaria ((operando-izq :izq op-izq)
                      (operando-der :der op-der)))
  (operacion-unaria  ((operando op-operando))))

(def-jerarquias
  ;; CategorÃ­as semÃ¡nticas
  (operacion-binaria (izq der)
    operacion-aritmetica comprobacion-aritmetica operacion-logica-binaria)
  (operacion-unaria (operando)
    operacion-logica-unaria)
  ;; Cuantificadores
  (cuantificador-restriccion (comprobacion &optional elemento)
    nppq tqpq ndpq sbqp maximizar minimizar)
  ;; LÃ³gicas â€” variÃ¡dicos; :self-named â†' constructor = nombre de la clase
  (operacion-logica-binaria (:variadic izq der :self-named) op-and op-or)
  (operacion-logica-unaria  (operando :self-named) op-not)
  ;; Relacionales
  (comprobacion-aritmetica (izq der :self-named)
    op-igual op-distinto op-mayor op-menor op-mayor-igual op-menor-igual)
  ;; AritmÃ©ticas
  (operacion-aritmetica (izq der :self-named)
    op-suma op-resta op-multiplicacion op-division))



;; =====================================================================
;; DSL â€” MACROS DE DOMINIO
;; =====================================================================

;; Registro de slots por entidad, necesario para que def-entidad herede
;; los slots de los mixins al construir el constructor de instancias.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *slots-de-entidad*    (make-hash-table))
  ;; Mapa: nombre-entidad â†' lista de sÃ­mbolos defvar de sus instancias concretas
  ;; (en el orden en que fueron definidas con def-X)
  (defvar *instancias-de-entidad* (make-hash-table)))


;; Define una clase mixin con slots simples.
;; def-clase genera automÃ¡ticamente el constructor y las funciones de acceso AST.
;;
;; (defclass* tiene-nombre () (nombre))
;; â†' (nombre ent) construye un nodo de acceso AST
(defmacro defclass* (nombre padres slots)
  `(progn
     (eval-when (:compile-toplevel :load-toplevel :execute)
       (setf (gethash ',nombre *slots-de-entidad*) ',slots))
     (def-clase ,nombre ,padres
       ,(mapcar (lambda (s) `(,s ,s)) slots))))


;; Define una entidad de dominio con padres opcionales (mixins) y slots propios.
;; Genera vÃ­a def-clase: clase especÃ­fica con herencia, clase genÃ©rica, defvar,
;; funciones de acceso AST y macro constructor DEF-NOMBRE.
;;
;; (def-entidad profesor (tiene-nombre) (grado))
;; (def-profesor piad "Alejandro Piad" grado-dr)   â† orden: slots mixin, slots propios
(defmacro def-entidad (nombre padres &optional (slots '()))
  (let* ((str         (symbol-name nombre))
         (ref-gen-sym (intern (concatenate 'string "REF-GEN-A-" str)))
         (ref-esp-sym (intern (concatenate 'string "REF-ESPECIFICA-A-" str)))
         (mk-sym      (intern (concatenate 'string "DEF-" str)))
         (mixin-slots (loop for p in padres
                            append (gethash p *slots-de-entidad* '())))
         (all-slots   (append mixin-slots slots))
         (slot-defs   (mapcar (lambda (s) `(,s ,s)) slots)))
    `(progn
       (eval-when (:compile-toplevel :load-toplevel :execute)
         (setf (gethash ',nombre *slots-de-entidad*) ',all-slots))
       (def-clase ,ref-esp-sym (,@padres ref-especifica-ent) ,slot-defs)
       (defclass  ,ref-gen-sym (ref-gen-entidad) ())
       (defvar    ,nombre (make-instance ',ref-gen-sym :nombre-entidad ',nombre))
       ;; Cada (def-X inst args...) crea la instancia Y la registra en *instancias-de-entidad*
       (defmacro  ,mk-sym (inst-nombre &rest arg-values)
         (let* ((all-sl ',all-slots)
                (initargs (loop for s in all-sl
                                for v in arg-values
                                append (list (intern (symbol-name s) :keyword) v))))
           `(progn
              (defvar ,inst-nombre
                (make-instance ',',ref-esp-sym ,@initargs))
              (eval-when (:compile-toplevel :load-toplevel :execute)
                (setf (gethash ',',nombre *instancias-de-entidad*)
                      (append (gethash ',',nombre *instancias-de-entidad*)
                              (list ',inst-nombre))))))))))


;; Entidad que agrupa otras entidades como componentes (sin padres mixin).
;;
;; (def-comb asignacion (tribunal fecha momento local))
(defmacro def-comb (nombre componentes)
  `(def-entidad ,nombre () ,componentes))


;; Define una consulta reutilizable (defun) o una consulta completa (defvar + consulta-simple).
;;
;; Sin :itera-sobre â†' funciÃ³n que recibe variables AST y devuelve un nodo condiciÃ³n.
;; Con :itera-sobre â†' defvar con nodo consulta-simple listo para evaluar.
;;
;; :itera-sobre acepta mÃºltiples specs: (var dominio) (var dominio) ...
;; Se usa &rest + parsing manual porque &key solo acepta un valor por clave.
(defmacro def-consulta (nombre params &rest body)
  (let* ((itera-pos   (position :itera-sobre body))
         (comp-pos    (position :comprueba   body))
         (op-pos      (position :operacion   body))
         (dev-pos     (position :devuelve    body))
         (itera-sobre (when itera-pos
                        (loop for item in (nthcdr (1+ itera-pos) body)
                              while (not (keywordp item))
                              collect item)))
         (comprueba   (when comp-pos (nth (1+ comp-pos) body)))
         (operacion   (when op-pos   (nth (1+ op-pos)   body)))
         (devuelve    (when dev-pos  (nth (1+ dev-pos)  body))))
    (if itera-sobre
        (let* ((iter-vars (mapcar #'first  itera-sobre))
               (iter-doms (mapcar #'second itera-sobre))
               ;; Ligar TAMBIÃ‰N los params (args) como sÃ­mbolos, igual que
               ;; las variables de iteraciÃ³n, para que la comprobaciÃ³n pueda
               ;; referirse a ellos y obtener nodos AST simbÃ³licos.
               (bindings  (mapcar (lambda (v) `(,v ',v))
                                  (append iter-vars params))))
          `(defvar ,nombre
             (let ,bindings
               (def-consulta-simple
                 :args               ',params
                 :variable-iteracion ',iter-vars
                 :dominio-iteracion  (list ,@iter-doms)
                 :comprobacion       ,comprueba
                 :operacion          ',operacion
                 :retorno            ',devuelve))))
        `(defun ,nombre ,params
           ,comprueba))))
