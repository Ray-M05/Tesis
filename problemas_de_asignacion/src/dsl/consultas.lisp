(in-package :dsl-ast)

(defvar *dentro-de-comprueba* nil)

(defun ligar-variables (variables forma)
  "Envuelve FORMA ligando cada variable a su propio símbolo, sin avisar si no se usa."
  `(let ,(mapcar (lambda (variable) `(,variable ',variable)) variables)
     ,@variables
     ,forma))

(defun exigir-pares (pares que)
  "Exige que :pares tenga la forma (u1 u2) dominio."
  (unless (and (= (length pares) 2)
               (listp (first pares))
               (= (length (first pares)) 2))
    (rechazar "~a: :pares ~s no tiene la forma (u1 u2) dominio" que pares))
  (exigir-dominio (second pares) que))

(defun exigir-operacion (forma que)
  "Exige una subclase de operacion-de-consulta aplicada a una expresión."
  (let ((clase (and (consp forma) (symbolp (first forma)) (find-class (first forma) nil))))
    (unless (and clase (subtypep clase 'operacion-de-consulta))
      (rechazar "~a: operación desconocida ~s" que forma))
    (unless (= (length forma) 2)
      (rechazar "~a: ~a necesita una expresión" que (first forma)))))

(defun exigir-funcion-nueva (nombre que)
  "Exige un nombre propio que todavía no nombre ninguna función."
  (exigir-nombre-propio nombre que)
  (when (fboundp nombre)
    (rechazar "~a: el nombre ~a ya es una función" que nombre)))

(defun aplicar-consulta (consulta argumentos)
  "Comprueba el uso de una consulta y devuelve su nodo de aplicación."
  (let ((nombre (slot-value consulta 'nombre))
        (esperados (length (slot-value consulta 'args))))
    (when *dentro-de-comprueba*
      (rechazar "consulta ~a: no se puede usar dentro de otra consulta" nombre))
    (unless (= (length argumentos) esperados)
      (rechazar "consulta ~a: recibe ~a argumentos y se esperaban ~a"
                nombre (length argumentos) esperados))
    (unless (every (lambda (argumento) (and argumento (symbolp argumento))) argumentos)
      (rechazar "consulta ~a: sus argumentos tienen que ser variables ligadas" nombre))
    (def-aplicacion-de-consulta consulta argumentos)))

(defun expandir-consulta (nombre parametros cuerpo)
  "Valida una consulta y devuelve la forma que crea su nodo y la función que la aplica."
  (let* ((que (format nil "consulta ~a" nombre))
         (claves (repartir-claves cuerpo '(:itera-sobre :pares :comprueba :operacion) que))
         (iteradores (getf claves :itera-sobre))
         (pares (getf claves :pares))
         (comprobacion (valor-unico claves :comprueba que))
         (operacion (valor-unico claves :operacion que)))
    (exigir-funcion-nueva nombre que)
    (unless (or iteradores pares)
      (rechazar "~a: necesita :itera-sobre o :pares" que))
    (exigir-iteradores iteradores que)
    (when pares
      (exigir-pares pares que))
    (exigir-operacion operacion que)
    (let ((variables-iteracion (mapcar #'first iteradores))
          (variables-pares (first pares)))
      (exigir-variables (append parametros variables-iteracion variables-pares) que)
      `(let* ((dominios (list ,@(mapcar #'second iteradores)))
              (dominio-pares ,(second pares))
              (nodo ,(ligar-variables
                      (append parametros variables-iteracion variables-pares)
                      `(let ((*dentro-de-comprueba* t))
                         (def-consulta-simple
                           :nombre ',nombre
                           :args ',parametros
                           :variable-iteracion ',variables-iteracion
                           :dominio-iteracion dominios
                           :variables-pares ',variables-pares
                           :dominio-pares dominio-pares
                           :comprobacion ,comprobacion
                           :operacion ,operacion)))))
         (defun ,nombre (&rest argumentos)
           (aplicar-consulta nodo argumentos))))))

(defmacro def-consulta (nombre parametros &rest cuerpo)
  "Define una consulta: recorre filas, comprueba una condición y agrega el resultado."
  (expandir-consulta nombre parametros cuerpo))

(defmacro def-condicion (nombre parametros &rest cuerpo)
  "Define una condición reutilizable, que no recorre ni cuenta."
  (let ((que (format nil "condición ~a" nombre)))
    (exigir-funcion-nueva nombre que)
    (exigir-variables parametros que)
    (unless (= (length cuerpo) 1)
      (rechazar "~a: tiene que tener una sola condición" que))
    `(defun ,nombre ,parametros ,(first cuerpo))))
