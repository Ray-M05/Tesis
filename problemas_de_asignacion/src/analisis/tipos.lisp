(in-package :analisis)

(defstruct ambito que variables tipos duenos)

(defun iteradores-de (consulta)
  "Une :itera-sobre y :pares en una lista de (variable dominio), con :pareja en los de :pares."
  (append (mapcar (lambda (variable dominio) (list variable (nombre-entidad dominio)))
                  (slot-value consulta 'variable-iteracion)
                  (slot-value consulta 'dominio-iteracion))
          (mapcar (lambda (variable)
                    (list variable (nombre-entidad (slot-value consulta 'dominio-pares)) :pareja))
                  (slot-value consulta 'variables-pares))))

(defun variables-de-para (restriccion)
  "Devuelve las variables de :para como una lista de (variable dominio)."
  (mapcar (lambda (iterador) (list (first iterador) (nombre-entidad (second iterador))))
          (slot-value restriccion 'para)))

(defun duenos-de-instancias (problema)
  "Devuelve una tabla que dice de qué entidad es cada instancia."
  (let ((duenos (make-hash-table :test #'eq)))
    (loop for (entidad . instancias) in (problema-instancias problema)
          do (dolist (instancia instancias)
               (setf (gethash (symbol-value instancia) duenos) entidad)))
    duenos))

(defun tipo-de-valor (valor duenos entidad slot)
  "Devuelve el tipo de un valor de slot, que tiene que ser un número, un texto o una instancia."
  (cond ((numberp valor) :numero)
        ((stringp valor) :texto)
        ((gethash valor duenos))
        (t (rechazar "entidad ~a: el slot ~a tiene el valor ~s, que no es un número, un texto ni una instancia"
                     entidad slot valor))))

(defun tipo-en-instancias (entidad slot instancias duenos)
  "Devuelve el único tipo que SLOT tiene en INSTANCIAS, o :desconocido si no hay ninguna."
  (let ((tipos (remove-duplicates
                (mapcar (lambda (instancia)
                          (tipo-de-valor (slot-value (symbol-value instancia) slot)
                                         duenos entidad slot))
                        instancias))))
    (when (rest tipos)
      (rechazar "entidad ~a: el slot ~a tiene valores de tipos distintos: ~{~a~^ y ~}"
                entidad slot tipos))
    (or (first tipos) :desconocido)))

(defun tipos-de-slots (problema)
  "Devuelve la lista ((entidad . slot) . tipo). Un slot de la combinación es del tipo que nombra."
  (let ((duenos (duenos-de-instancias problema)))
    (loop for (entidad . slots) in (problema-slots problema)
          for instancias = (cdr (assoc entidad (problema-instancias problema)))
          append (loop for slot in slots
                       collect (cons (cons entidad slot)
                                     (if (eq entidad (problema-combinacion problema))
                                         slot
                                         (tipo-en-instancias entidad slot instancias duenos)))))))

(defun parametros-de-aplicacion (aplicacion restriccion)
  "Devuelve los parámetros de la consulta aplicada con el dominio que les da :para."
  (let ((variables (variables-de-para restriccion)))
    (mapcar (lambda (parametro argumento)
              (let ((variable (assoc argumento variables)))
                (unless variable
                  (rechazar "restricción ~a: el argumento ~a no está en :para"
                            (slot-value restriccion 'nombre) argumento))
                (list parametro (second variable))))
            (slot-value (slot-value aplicacion 'consulta) 'args)
            (slot-value aplicacion 'argumentos))))

(defun dominios-de-parametros (problema)
  "Devuelve ((consulta . parámetros)...) en orden de aparición, con un solo dominio por parámetro."
  (let ((resultado '()))
    (dolist (restriccion (problema-restricciones problema) (nreverse resultado))
      (dolist (aplicacion (nodos-de 'aplicacion-de-consulta restriccion))
        (let* ((consulta (slot-value aplicacion 'consulta))
               (parametros (parametros-de-aplicacion aplicacion restriccion))
               (anterior (assoc consulta resultado)))
          (cond ((null anterior)
                 (push (cons consulta parametros) resultado))
                ((not (equal (cdr anterior) parametros))
                 (rechazar "consulta ~a: se aplica con los dominios ~s y ~s"
                           (slot-value consulta 'nombre) (cdr anterior) parametros))))))))

(defun compatibles-p (tipo otro)
  "Dice si dos tipos pueden compararse. Del tipo :desconocido no se puede afirmar nada."
  (or (eq tipo otro) (eq tipo :desconocido) (eq otro :desconocido)))

(defun tipos-de-operandos (nodo ambito)
  "Devuelve el tipo de cada operando de un nodo binario."
  (values (tipo-de (slot-value nodo 'operando-izq) ambito)
          (tipo-de (slot-value nodo 'operando-der) ambito)))

(defun tipo-de-comparacion-por-igualdad (nodo ambito)
  "Exige dos operandos del mismo tipo."
  (multiple-value-bind (izq der) (tipos-de-operandos nodo ambito)
    (unless (compatibles-p izq der)
      (rechazar "~a: ~a compara ~a con ~a" (ambito-que ambito) (type-of nodo) izq der))
    :logico))

(defgeneric tipo-de (nodo ambito)
  (:documentation "Devuelve el tipo de una expresión y rechaza la que no tiene sentido."))

(defmethod tipo-de ((nodo number) ambito)
  (declare (ignore ambito))
  :numero)

(defmethod tipo-de ((nodo string) ambito)
  (declare (ignore ambito))
  :texto)

(defmethod tipo-de ((nodo symbol) ambito)
  (let ((variable (assoc nodo (ambito-variables ambito))))
    (unless variable
      (rechazar "~a: ~s no es una variable con dominio" (ambito-que ambito) nodo))
    (second variable)))

(defmethod tipo-de ((nodo ref-especifica-ent) ambito)
  (gethash nodo (ambito-duenos ambito)))

(defmethod tipo-de ((nodo ref-gen-entidad) ambito)
  (rechazar "~a: la entidad ~a no es un valor" (ambito-que ambito) (nombre-entidad nodo)))

(defmethod tipo-de ((nodo acceso-a-atributo-de-entidad) ambito)
  (let ((dueno (tipo-de (slot-value nodo 'entidad) ambito))
        (slot (slot-value nodo 'atributo)))
    (if (eq dueno :desconocido)
        :desconocido
        (let ((tipo (assoc (cons dueno slot) (ambito-tipos ambito) :test #'equal)))
          (unless tipo
            (rechazar "~a: ~a no es un slot de ~a" (ambito-que ambito) slot dueno))
          (cdr tipo)))))

(defmethod tipo-de ((nodo aplicacion-de-consulta) ambito)
  (declare (ignore ambito))
  :numero)

(defmethod tipo-de ((nodo operacion-aritmetica) ambito)
  (multiple-value-bind (izq der) (tipos-de-operandos nodo ambito)
    (unless (and (compatibles-p izq :numero) (compatibles-p der :numero))
      (rechazar "~a: ~a opera sobre ~a y ~a" (ambito-que ambito) (type-of nodo) izq der))
    :numero))

(defmethod tipo-de ((nodo comprobacion-aritmetica) ambito)
  (multiple-value-bind (izq der) (tipos-de-operandos nodo ambito)
    (unless (and (compatibles-p izq :numero) (compatibles-p der :numero))
      (rechazar "~a: ~a ordena ~a y ~a" (ambito-que ambito) (type-of nodo) izq der))
    :logico))

(defmethod tipo-de ((nodo op-igual) ambito)
  (tipo-de-comparacion-por-igualdad nodo ambito))

(defmethod tipo-de ((nodo op-distinto) ambito)
  (tipo-de-comparacion-por-igualdad nodo ambito))

(defmethod tipo-de ((nodo operacion-logica-binaria) ambito)
  (multiple-value-bind (izq der) (tipos-de-operandos nodo ambito)
    (unless (and (compatibles-p izq :logico) (compatibles-p der :logico))
      (rechazar "~a: ~a une ~a y ~a" (ambito-que ambito) (type-of nodo) izq der))
    :logico))

(defmethod tipo-de ((nodo operacion-logica-unaria) ambito)
  (let ((tipo (tipo-de (slot-value nodo 'operando) ambito)))
    (unless (compatibles-p tipo :logico)
      (rechazar "~a: ~a niega ~a" (ambito-que ambito) (type-of nodo) tipo))
    :logico))

(defgeneric exigir-tipo-de-operacion (operacion ambito)
  (:documentation "Comprueba la expresión de una operación de consulta."))

(defmethod exigir-tipo-de-operacion ((operacion suma) ambito)
  (let ((tipo (tipo-de (slot-value operacion 'expresion) ambito)))
    (unless (compatibles-p tipo :numero)
      (rechazar "~a: suma una expresión de tipo ~a" (ambito-que ambito) tipo))))

(defmethod exigir-tipo-de-operacion ((operacion contar-distintos) ambito)
  (tipo-de (slot-value operacion 'expresion) ambito))

(defgeneric tipo-exigido (restriccion)
  (:documentation "Devuelve el tipo que tiene que tener la comprobación de una restricción."))

(defmethod tipo-exigido ((restriccion cuantificador-restriccion)) :logico)
(defmethod tipo-exigido ((restriccion objetivo)) :numero)

(defun exigir-tipos-de-consulta (consulta parametros tipos duenos)
  "Exige una condición lógica y una operación con sentido."
  (let* ((ambito (make-ambito :que (format nil "consulta ~a" (slot-value consulta 'nombre))
                              :variables (append (iteradores-de consulta) parametros)
                              :tipos tipos
                              :duenos duenos))
         (condicion (tipo-de (slot-value consulta 'comprobacion) ambito)))
    (unless (compatibles-p condicion :logico)
      (rechazar "~a: su condición es de tipo ~a y tiene que ser lógica"
                (ambito-que ambito) condicion))
    (exigir-tipo-de-operacion (slot-value consulta 'operacion) ambito)))

(defun exigir-tipos-de-restriccion (restriccion tipos duenos)
  "Exige que la comprobación sea del tipo que pide su cuantificador."
  (let* ((que (format nil "restricción ~a" (slot-value restriccion 'nombre)))
         (ambito (make-ambito :que que
                              :variables (variables-de-para restriccion)
                              :tipos tipos
                              :duenos duenos))
         (tipo (tipo-de (slot-value restriccion 'comprobacion) ambito))
         (exigido (tipo-exigido restriccion)))
    (unless (compatibles-p tipo exigido)
      (rechazar "~a: su comprobación es de tipo ~a y tiene que ser de tipo ~a"
                que tipo exigido))))

(defun exigir-tipos (problema tipos parametros)
  "Comprueba las consultas derivadas y las restricciones del problema."
  (let ((duenos (duenos-de-instancias problema)))
    (loop for (consulta . de-la-consulta) in parametros
          do (exigir-tipos-de-consulta consulta de-la-consulta tipos duenos))
    (dolist (restriccion (problema-restricciones problema))
      (exigir-tipos-de-restriccion restriccion tipos duenos))))
