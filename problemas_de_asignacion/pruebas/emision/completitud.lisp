(in-package :pruebas-emision)

(defun hojas (clase)
  "Devuelve las clases sin subclases que descienden de CLASE, o ella misma."
  (sb-mop:finalize-inheritance clase)
  (let ((hijas (sb-mop:class-direct-subclasses clase)))
    (if hijas
        (mapcan #'hojas (copy-list hijas))
        (list clase))))

(defun hojas-de (&rest nombres)
  "Devuelve las clases sin subclases de varias raíces."
  (mapcan (lambda (nombre) (hojas (find-class nombre))) nombres))

(defun comprobar-metodos (funcion argumentos que)
  "Exige que FUNCION tenga un método aplicable a ARGUMENTOS."
  (assert (compute-applicable-methods funcion argumentos) ()
          "~a no tiene método de ~a" que funcion))

(defun comprobar-sin-defecto (funcion posiciones)
  "Exige que FUNCION no tenga ningún método sobre t en POSICIONES."
  (dolist (metodo (sb-mop:generic-function-methods funcion))
    (dolist (posicion posiciones)
      (assert (not (eq (nth posicion (sb-mop:method-specializers metodo)) (find-class t))) ()
              "~a tiene un método por defecto: ~a" funcion metodo))))

(defun comprobar-destino (clase)
  "Exige un método por cada expresión, operador, familia y forma para el destino CLASE."
  (let ((destino (allocate-instance (find-class clase))))
    (dolist (clase-de-nodo (cons (find-class 'ref-especifica-ent)
                                 (hojas-de 'acceso-a-atributo-de-entidad 'aplicacion-de-consulta
                                           'operacion-binaria 'operacion-unaria)))
      (comprobar-metodos #'generar-codigo
                         (list (allocate-instance clase-de-nodo) destino nil)
                         clase-de-nodo))
    (dolist (valor (list 'variable 1 1.5 "texto"))
      (comprobar-metodos #'generar-codigo (list valor destino nil) valor))
    (when (typep destino 'emision::infijo)
      (dolist (operador (hojas-de 'comprobacion-aritmetica 'operacion-aritmetica
                                  'operacion-logica-binaria))
        (comprobar-metodos #'simbolo (list (class-name operador) destino) operador)))
    (dolist (familia (hojas-de 'consulta-m))
      (comprobar-metodos #'emitir-consulta
                         (list (allocate-instance familia) destino nil)
                         familia))
    (dolist (forma (hojas-de 'restriccion-m))
      (comprobar-metodos #'emitir-restriccion
                         (list (allocate-instance forma) destino nil)
                         forma))
    (comprobar-metodos #'emitir (list destino nil) clase)))

(comprobar-destino 'python)
(comprobar-destino 'matematica)
(comprobar-destino 'verbalizador)

(dolist (familia (hojas-de 'consulta-m))
  (let ((consulta (allocate-instance familia)))
    (comprobar-metodos #'emision::oracion (list consulta) familia)
    (comprobar-metodos #'emision::sustantivo (list consulta) familia)))
(dolist (nodo (hojas-de 'cuantificador-restriccion))
  (comprobar-metodos #'emision::restriccion-literal
                     (list (allocate-instance nodo) nil) nodo))

(dolist (forma (hojas-de 'restriccion-m))
  (let ((destino (allocate-instance (find-class 'matematica)))
        (restriccion (allocate-instance forma)))
    (comprobar-metodos #'emision::requisito (list restriccion destino) forma)
    (comprobar-metodos #'emision::valor (list restriccion destino) forma)))

(assert (> (length (hojas-de 'operacion-binaria)) 10))
(assert (= (length (hojas-de 'consulta-m)) 6))
(assert (= (length (hojas-de 'restriccion-m)) 4))

(comprobar-sin-defecto #'generar-codigo '(0 1))
(comprobar-sin-defecto #'simbolo '(0 1))
(comprobar-sin-defecto #'emitir-consulta '(0 1))
(comprobar-sin-defecto #'emitir-restriccion '(0 1))
(comprobar-sin-defecto #'emitir '(0))

;; Un nodo sin traducir es un error, no un texto.
(assert (null (compute-applicable-methods
               #'generar-codigo
               (list (list 1 2) (allocate-instance (find-class 'python)) nil))))
