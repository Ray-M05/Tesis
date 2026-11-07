(in-package :dsl-ast)

(defun %expandir-slot (slot)
  "Convierte (nombre accesor) o (nombre :initarg accesor) en la forma canónica de defclass."
  (cond ((= (length slot) 2)
         `(,(first slot) :initarg ,(intern (symbol-name (first slot)) :keyword)
                          :accessor ,(second slot)))
        ((= (length slot) 3)
         `(,(first slot) :initarg ,(second slot) :accessor ,(third slot)))
        (t slot)))

(defmacro def-clase (nombre padres slots &rest parametros-extra)
  "Define la clase y su constructor. :funcion da el nombre del constructor, :claves lo hace
por claves, :encadenado encadena N argumentos, y sin nada usa los slots como parámetros."
  (let* ((posicion-de-funcion (position :funcion parametros-extra))
         (funcion-indicada (when posicion-de-funcion
                             (nth (1+ posicion-de-funcion) parametros-extra)))
         (parametros-extra (if posicion-de-funcion
                               (append (subseq parametros-extra 0 posicion-de-funcion)
                                       (subseq parametros-extra (+ posicion-de-funcion 2)))
                               parametros-extra))
         (texto-del-nombre (symbol-name nombre))
         (simbolo-de-funcion (or funcion-indicada
                                 (intern (concatenate 'string "DEF-" texto-del-nombre))))
         (por-claves-p (equal parametros-extra '(:claves)))
         (encadenado-p (eq (first parametros-extra) :encadenado))
         (extra-real (if encadenado-p (rest parametros-extra) parametros-extra))
         (slots-completos (mapcar #'%expandir-slot slots))
         (derivados (mapcar (lambda (slot)
                              (intern (symbol-name (getf (cdr slot) :initarg))))
                            slots-completos))
         (parametros (cond (por-claves-p derivados)
                           (encadenado-p extra-real)
                           (extra-real extra-real)
                           (t derivados)))
         (initargs (loop for p in parametros
                         unless (member p lambda-list-keywords)
                           append (list (intern (symbol-name p) :keyword) p)))
         (lista-lambda (if por-claves-p (cons '&key parametros) parametros))
         (slots-sin-accesor (mapcar (lambda (slot)
                                      (list (first slot) :initarg (getf (cdr slot) :initarg)))
                                    slots-completos))
         (initargs-encadenados (when encadenado-p
                                 (loop for p in parametros
                                       for lp in '(a b)
                                       append (list (intern (symbol-name p) :keyword) lp)))))
    `(progn
       (defclass ,nombre ,padres ,slots-sin-accesor)
       ,@(cond
           (encadenado-p
            `((defun ,simbolo-de-funcion (&rest argumentos)
                (reduce (lambda (a b) (make-instance ',nombre ,@initargs-encadenados)) argumentos))))
           (parametros
            `((defun ,simbolo-de-funcion ,lista-lambda
                (make-instance ',nombre ,@initargs))))))))

(defmacro def-nodos (&rest definiciones)
  "Define varias clases que heredan de nodo-ast."
  `(progn
     ,@(mapcar (lambda (definicion)
                 `(def-clase ,(first definicion) (nodo-ast) ,@(rest definicion)))
               definiciones)))

(defmacro def-jerarquias (&rest grupos)
  "Define varios grupos de la forma (padre (parametros...) nombre1 nombre2...)."
  `(progn
     ,@(mapcar (lambda (grupo)
                 `(def-subclases ,(first grupo) ,(second grupo) ,@(cddr grupo)))
               grupos)))

(defmacro def-subclases (padre parametros &rest nombres)
  "Define subclases de un mismo padre. Con :autonombrado el constructor se llama como la clase."
  (let* ((autonombrado-p      (member :autonombrado parametros))
         (parametros-limpios (remove :autonombrado parametros)))
    `(progn
       ,@(mapcar (lambda (nombre)
                   (if autonombrado-p
                       `(def-clase ,nombre (,padre) () :funcion ,nombre ,@parametros-limpios)
                       `(def-clase ,nombre (,padre) () ,@parametros-limpios)))
                 nombres))))
