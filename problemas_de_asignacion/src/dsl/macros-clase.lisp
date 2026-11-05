(in-package :dsl-ast)

(defun %expand-slot (slot)
  "Convierte (nombre accesor) o (nombre :initarg accesor) en la forma canónica de defclass."
  (cond ((= (length slot) 2)
         `(,(first slot) :initarg ,(intern (symbol-name (first slot)) :keyword)
                          :accessor ,(second slot)))
        ((= (length slot) 3)
         `(,(first slot) :initarg ,(second slot) :accessor ,(third slot)))
        (t slot)))

(defmacro def-clase (nombre padres slots &rest params-extra)
  "Define la clase y su constructor. :fn-name da el nombre del constructor, :key lo hace
por claves, :variadic encadena N argumentos, y sin nada usa los slots como parámetros."
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
         (slots-sin-acc (mapcar (lambda (slot)
                                  (list (first slot) :initarg (getf (cdr slot) :initarg)))
                                slots-full))
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
                (make-instance ',nombre ,@initargs))))))))

(defmacro def-nodos (&rest specs)
  "Define varias clases que heredan de nodo-ast."
  `(progn
     ,@(mapcar (lambda (spec)
                 `(def-clase ,(first spec) (nodo-ast) ,@(rest spec)))
               specs)))

(defmacro def-jerarquias (&rest grupos)
  "Define varios grupos de la forma (padre (params...) nombre1 nombre2...)."
  `(progn
     ,@(mapcar (lambda (grupo)
                 `(def-subclases ,(first grupo) ,(second grupo) ,@(cddr grupo)))
               grupos)))

(defmacro def-subclases (padre params &rest nombres)
  "Define subclases de un mismo padre. Con :self-named el constructor se llama como la clase."
  (let* ((self-p      (member :self-named params))
         (clean-params (remove :self-named params)))
    `(progn
       ,@(mapcar (lambda (nombre)
                   (if self-p
                       `(def-clase ,nombre (,padre) () :fn-name ,nombre ,@clean-params)
                       `(def-clase ,nombre (,padre) () ,@clean-params)))
                 nombres))))
