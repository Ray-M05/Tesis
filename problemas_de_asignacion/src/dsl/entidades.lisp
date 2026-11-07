(in-package :dsl-ast)

(defvar *slots-de-mixin* (make-hash-table))
(defvar *slots-de-entidad* (make-hash-table))
(defvar *instancias-de-entidad* (make-hash-table))
(defvar *accesores* (make-hash-table))
(defvar *entidades* '())
(defvar *combinaciones* '())
(defvar *problema-cargado* nil)

(defmacro con-registros-nuevos (&body cuerpo)
  "Ejecuta CUERPO con registros vacíos, para que un dominio no vea los de otro."
  `(let ((*slots-de-mixin* (make-hash-table))
         (*slots-de-entidad* (make-hash-table))
         (*instancias-de-entidad* (make-hash-table))
         (*accesores* (make-hash-table))
         (*entidades* '())
         (*combinaciones* '())
         (*problema-cargado* nil))
     ,@cuerpo))

(defun exigir-dominio (dominio que)
  "Rechaza un dominio que no sea una entidad registrada."
  (unless (member dominio *entidades*)
    (rechazar "~a: el dominio ~s no existe" que dominio)))

(defun exigir-iteradores (iteradores que)
  "Exige que cada iterador tenga la forma (variable dominio) y que el dominio exista."
  (dolist (iterador iteradores)
    (unless (and (consp iterador) (= (length iterador) 2))
      (rechazar "~a: ~s no tiene la forma (variable dominio)" que iterador))
    (exigir-dominio (second iterador) que)))

(defun slots-de-padres (padres que)
  "Devuelve los slots de los mixins PADRES, en orden."
  (loop for padre in padres
        append (multiple-value-bind (slots existe) (gethash padre *slots-de-mixin*)
                 (unless existe
                   (rechazar "~a: el mixin ~s no existe" que padre))
                 slots)))

(defun definiciones-de-slots (slots)
  "Convierte los slots en definiciones de defclass con su initarg."
  (mapcar (lambda (slot) `(,slot :initarg ,(intern (symbol-name slot) :keyword))) slots))

(defun formas-de-accesores (slots que)
  "Devuelve las funciones de acceso de los slots que aún no tienen una."
  (loop for slot in slots
        do (exigir-nombre-propio slot que)
        unless (gethash slot *accesores*)
          do (when (fboundp slot)
               (rechazar "~a: el slot ~a ya es una función" que slot))
          and append `((setf (gethash ',slot *accesores*) t)
                       (defun ,slot (entidad)
                         (def-acceso-a-atributo-de-entidad ',slot entidad)))))

(defun formas-de-entidad (nombre padres propios que)
  "Devuelve las formas comunes a def-entidad y def-comb."
  (exigir-nombre-nuevo nombre que)
  (let* ((texto (symbol-name nombre))
         (clase-especifica (intern (concatenate 'string "REF-ESPECIFICA-A-" texto)))
         (clase-generica (intern (concatenate 'string "REF-GEN-A-" texto)))
         (slots (append (slots-de-padres padres que) propios)))
    (exigir-variables slots que)
    `((defclass ,clase-especifica (,@padres ref-especifica-ent) ,(definiciones-de-slots propios))
      (defclass ,clase-generica (ref-gen-entidad) ())
      (defvar ,nombre (make-instance ',clase-generica :nombre-entidad ',nombre))
      (setf (gethash ',nombre *slots-de-entidad*) ',slots)
      (setf *entidades* (append *entidades* (list ',nombre)))
      ,@(formas-de-accesores propios que))))

(defun expandir-instancia (entidad clase instancia valores)
  "Comprueba una instancia y devuelve la forma que la crea y la registra."
  (let ((slots (gethash entidad *slots-de-entidad*))
        (que (format nil "instancia ~a de ~a" instancia entidad)))
    (exigir-nombre-nuevo instancia que)
    (unless (= (length valores) (length slots))
      (rechazar "~a: recibe ~a argumentos y se esperaban ~a"
                que (length valores) (length slots)))
    `(progn
       (defvar ,instancia
         (make-instance ',clase
                        ,@(loop for slot in slots
                                for valor in valores
                                append (list (intern (symbol-name slot) :keyword) valor))))
       (setf (gethash ',entidad *instancias-de-entidad*)
             (append (gethash ',entidad *instancias-de-entidad*) (list ',instancia)))
       ',instancia)))

(defmacro def-mixin (nombre padres slots)
  "Define un mixin: una clase cuyos slots heredan las entidades."
  (let ((que (format nil "mixin ~a" nombre)))
    (exigir-nombre-propio nombre que)
    `(progn
       (defclass ,nombre ,padres ,(definiciones-de-slots slots))
       (setf (gethash ',nombre *slots-de-mixin*)
             ',(append (slots-de-padres padres que) slots))
       ,@(formas-de-accesores slots que)
       ',nombre)))

(defmacro def-entidad (nombre padres &optional slots)
  "Define una entidad con sus accesores y la macro DEF-<ENTIDAD> que crea instancias."
  (let ((que (format nil "entidad ~a" nombre))
        (constructor (and (symbolp nombre)
                          (intern (concatenate 'string "DEF-" (symbol-name nombre))))))
    (exigir-nombre-propio nombre que)
    (unless (eq (symbol-package constructor) *package*)
      (rechazar "~a: ~a es parte del lenguaje" que constructor))
    `(progn
       ,@(formas-de-entidad nombre padres slots que)
       (defmacro ,constructor (instancia &rest valores)
         (expandir-instancia ',nombre
                             ',(intern (concatenate 'string "REF-ESPECIFICA-A-" (symbol-name nombre)))
                             instancia
                             valores))
       ',nombre)))

(defmacro def-comb (nombre componentes)
  "Define la entidad combinación. Sus filas las produce la búsqueda, así que no tiene instancias."
  `(progn
     ,@(formas-de-entidad nombre '() componentes (format nil "combinación ~a" nombre))
     (setf *combinaciones* (append *combinaciones* (list ',nombre)))
     ',nombre))
