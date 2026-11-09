(in-package :orquestacion)

;; Un pedido es una lista de propiedades: (:dominios :destinos :estrategias :semillas :ejecutar).
;; Cada estrategia es (nombre :parametro valor ...). Lo que falta significa todo, o no ejecutar.

(defparameter *opciones* '(:destinos :estrategias :semillas :ejecutar)
  "Las opciones de la línea de comandos, sin los dos guiones.")

(defun nombre-de-opcion (clave)
  "Devuelve la opción de la línea de comandos que corresponde a CLAVE."
  (format nil "--~(~a~)" clave))

(defun opcion-p (argumento)
  "Dice si ARGUMENTO empieza por dos guiones."
  (and (> (length argumento) 2) (string= "--" argumento :end2 2)))

(defun semillas-de (valores que)
  "Convierte VALORES en enteros o rechaza el pedido."
  (mapcar (lambda (valor)
            (or (if (stringp valor) (ignore-errors (parse-integer valor)) (and (integerp valor) valor))
                (rechazar "~a: la semilla ~a no es un entero" que valor)))
          valores))

(defun pedido-de-argumentos (argumentos)
  "Convierte los argumentos de la línea de comandos en un pedido. --archivo va solo."
  (when (member "--archivo" argumentos :test #'string=)
    (unless (and (= (length argumentos) 2) (string= (first argumentos) "--archivo"))
      (rechazar "--archivo va solo, seguido de una ruta, sin otras opciones"))
    (return-from pedido-de-argumentos (pedido-de-archivo (second argumentos))))
  (let ((grupos (list (list :dominios))))
    (dolist (argumento argumentos)
      (if (opcion-p argumento)
          (let ((clave (find argumento *opciones* :key #'nombre-de-opcion :test #'string=)))
            (unless clave
              (rechazar "opción desconocida: ~a. Las que hay: --archivo~{, ~a~}"
                        argumento (mapcar #'nombre-de-opcion *opciones*)))
            (when (assoc clave grupos)
              (rechazar "~a está repetida" argumento))
            (push (list clave) grupos))
          (push argumento (rest (first grupos)))))
    (loop for (clave . al-reves) in (reverse grupos)
          for valores = (reverse al-reves)
          append (cond ((eq clave :dominios)
                        (and valores (list :dominios (mapcar #'string-downcase valores))))
                       ((eq clave :ejecutar)
                        (when valores
                          (rechazar "--ejecutar no lleva valores: ~{~a~^ ~}" valores))
                        (list :ejecutar t))
                       ((null valores)
                        (rechazar "~a necesita al menos un valor" (nombre-de-opcion clave)))
                       ((eq clave :semillas)
                        (list :semillas (semillas-de valores "--semillas")))
                       ((eq clave :estrategias)
                        (list :estrategias (mapcar #'list valores)))
                       (t (list clave valores))))))

(defparameter *claves-del-archivo* '(:dominio :destinos :estrategias :semillas :ejecutar))

(defun nombre-p (valor)
  "Dice si VALOR puede nombrar un dominio, un destino o una estrategia."
  (or (stringp valor) (and (symbolp valor) valor (not (keywordp valor)))))

(defun lista-de-propiedades-p (valor)
  "Dice si VALOR es una lista con un número par de elementos."
  (and (listp valor) (null (cdr (last valor))) (evenp (length valor))))

(defun texto-de-nombre (nombre)
  "Devuelve NOMBRE, un símbolo o una cadena, como cadena en minúsculas."
  (string-downcase (string nombre)))

(defun leer-archivo (ruta)
  "Lee la única forma de RUTA sin evaluar nada. Los símbolos van a un paquete aparte."
  (with-open-file (flujo ruta :external-format :utf-8 :if-does-not-exist nil)
    (unless flujo
      (rechazar "no existe el archivo ~a" ruta))
    (let ((*read-eval* nil)
          (*package* (or (find-package "PEDIDO") (make-package "PEDIDO" :use nil))))
      (handler-case
          (let ((forma (read flujo)))
            (unless (eq (read flujo nil flujo) flujo)
              (rechazar "~a: tiene que ser una sola lista" ruta))
            forma)
        (error-dsl (condicion) (error condicion))
        (error (condicion) (rechazar "~a: no se puede leer: ~a" ruta condicion))))))

(defun pedido-de-archivo (ruta)
  "Lee un archivo de ejecuciones/: una lista de propiedades con un solo dominio."
  (let ((forma (leer-archivo ruta)))
    (unless (lista-de-propiedades-p forma)
      (rechazar "~a: tiene que ser una lista de propiedades" ruta))
    (loop for clave in forma by #'cddr
          unless (member clave *claves-del-archivo*)
            do (rechazar "~a: clave desconocida ~s. Las que hay: ~{~s~^ ~}" ruta clave *claves-del-archivo*))
    (destructuring-bind (&key dominio destinos estrategias semillas ejecutar) forma
      (unless (nombre-p dominio)
        (rechazar "~a: :dominio tiene que ser un nombre" ruta))
      (unless (and (listp destinos) (every #'nombre-p destinos))
        (rechazar "~a: :destinos tiene que ser una lista de nombres" ruta))
      (unless (listp estrategias)
        (rechazar "~a: :estrategias tiene que ser una lista" ruta))
      (unless (listp semillas)
        (rechazar "~a: :semillas tiene que ser una lista de enteros" ruta))
      (list :dominios (list (texto-de-nombre dominio))
            :destinos (mapcar #'texto-de-nombre destinos)
            :estrategias (mapcar (lambda (estrategia)
                                   (let ((estrategia (if (listp estrategia) estrategia (list estrategia))))
                                     (unless (and (nombre-p (first estrategia))
                                                  (lista-de-propiedades-p (rest estrategia))
                                                  (every #'keywordp (loop for clave in (rest estrategia) by #'cddr
                                                                          collect clave)))
                                       (rechazar "~a: ~s tiene que ser un nombre o (nombre :parametro valor ...)"
                                                 ruta estrategia))
                                     (cons (texto-de-nombre (first estrategia)) (rest estrategia))))
                                 estrategias)
            :semillas (semillas-de semillas ruta)
            :ejecutar (and ejecutar t)))))
