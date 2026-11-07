(in-package :emision)

(defvar *entidades-de-variables* '()
  "Iteradores en curso. Sin ellos no se sabe desde qué entidad arranca una cadena de acceso.")

(defvar *variable-elidida* nil
  "Variable que no se nombra: cuando se habla de una sola fila, se escribe «su día».")

(defvar *estilo-de-elision* :posesivo
  "Cómo se escribe lo elidido: «su día», o «el día» cuando vale para las dos filas de un par.")

(defun modelo-actual ()
  "Devuelve el modelo que se está escribiendo."
  (destino-modelo *verbalizador*))

(defun problema-actual ()
  "Devuelve el problema que se está escribiendo."
  (modelo-problema (modelo-actual)))

(defun prosa (nodo)
  "Traduce un nodo a español."
  (generar-codigo nodo *verbalizador* nil))

(defun entidad-p (simbolo)
  "Dice si un slot apunta a otra entidad, es decir, si su nombre es una entidad."
  (member simbolo (problema-entidades (problema-actual))))

(defun alcanzables (raiz)
  "Devuelve las entidades a las que se llega desde RAIZ, incluida ella."
  (let ((vistas '()) (pila (list raiz)))
    (loop while pila
          for entidad = (pop pila)
          unless (member entidad vistas)
            do (push entidad vistas)
               (dolist (referida (cdr (assoc entidad (modelo-referencias (modelo-actual)))))
                 (push referida pila)))
    vistas))

(defun atributo-unico-p (raiz atributo)
  "Dice si ATRIBUTO es slot de exactamente una entidad alcanzable desde RAIZ."
  (= 1 (count-if (lambda (entidad) (member atributo (slots-de-entidad entidad (modelo-actual))))
                 (alcanzables raiz))))

(defun acortable-p (nodo)
  "Devuelve la raíz si la cadena se puede acortar sin volverse ambigua."
  (multiple-value-bind (ruta raiz) (camino nodo)
    (and ruta (symbolp raiz) (rest ruta)
         (let ((entidad (second (assoc raiz *entidades-de-variables*))))
           (and entidad (atributo-unico-p entidad (first ruta))))
         raiz)))

(defun acceso->prosa (nodo)
  "Escribe un acceso. Un slot que apunta a otra entidad se colapsa hasta la raíz: «su plan».
Uno escalar sigue nombrando a su dueño: «el día de preparación de su asignatura»."
  (let* ((atributo (slot-value nodo 'atributo))
         (dueno (slot-value nodo 'entidad))
         (base (if (entidad-p atributo)
                   (or (acortable-p nodo) dueno)
                   dueno)))
    (if (and *variable-elidida* (eq base *variable-elidida*))
        (if (eq *estilo-de-elision* :definido)
            (sintagma atributo :definido t)
            (format nil "su ~a" (nombre-prosa atributo)))
        (format nil "~a de ~a" (sintagma atributo :definido t) (prosa base)))))

(defun booleano->prosa (nodo)
  "Escribe (op-igual (admite-doble x) 0) como «x no admite turno doble». Sin predicado devuelve nil."
  (let ((izq (slot-value nodo 'operando-izq))
        (der (slot-value nodo 'operando-der)))
    (when (and (typep izq 'acceso-a-atributo-de-entidad) (integerp der) (<= 0 der 1))
      (let ((frase (frase-de-predicado (slot-value izq 'atributo) :negada (eql der 0))))
        (when frase
          (format nil "~a ~a" (prosa (slot-value izq 'entidad)) frase))))))

(defun binaria->prosa (nodo control)
  "Escribe los dos operandos de NODO en la plantilla CONTROL."
  (format nil control (prosa (slot-value nodo 'operando-izq)) (prosa (slot-value nodo 'operando-der))))

(defgeneric plantilla-binaria (nodo)
  (:documentation "Devuelve la plantilla en español de un operador binario."))

(defmethod plantilla-binaria ((nodo op-igual)) "~a es igual a ~a")
(defmethod plantilla-binaria ((nodo op-distinto)) "~a es diferente de ~a")
(defmethod plantilla-binaria ((nodo op-mayor)) "~a es mayor que ~a")
(defmethod plantilla-binaria ((nodo op-menor)) "~a es menor que ~a")
(defmethod plantilla-binaria ((nodo op-mayor-igual)) "~a es mayor o igual que ~a")
(defmethod plantilla-binaria ((nodo op-menor-igual)) "~a es menor o igual que ~a")
(defmethod plantilla-binaria ((nodo op-suma)) "la suma de ~a y ~a")
(defmethod plantilla-binaria ((nodo op-resta)) "la diferencia entre ~a y ~a")
(defmethod plantilla-binaria ((nodo op-multiplicacion)) "el producto de ~a por ~a")
(defmethod plantilla-binaria ((nodo op-division)) "el cociente de ~a entre ~a")

(defmethod generar-codigo ((nodo operacion-binaria) (destino verbalizador) stream)
  (format stream "~a" (binaria->prosa nodo (plantilla-binaria nodo))))

(defmethod generar-codigo ((nodo op-igual) (destino verbalizador) stream)
  (format stream "~a" (or (booleano->prosa nodo) (binaria->prosa nodo (plantilla-binaria nodo)))))

(defmethod generar-codigo ((nodo op-y) (destino verbalizador) stream)
  (format stream "~a" (enumerar (mapcar #'prosa (aplanar 'op-y nodo)) "y")))

(defmethod generar-codigo ((nodo op-o) (destino verbalizador) stream)
  (format stream "~a" (enumerar (mapcar #'prosa (aplanar 'op-o nodo)) "o")))

(defmethod generar-codigo ((nodo op-no) (destino verbalizador) stream)
  (format stream "no se cumple que ~a" (prosa (slot-value nodo 'operando))))

(defmethod generar-codigo ((nodo symbol) (destino verbalizador) stream)
  (format stream "~a" (variable-prosa nodo)))

(defmethod generar-codigo ((nodo number) (destino verbalizador) stream)
  (format stream "~a" nodo))

(defmethod generar-codigo ((nodo string) (destino verbalizador) stream)
  (format stream "«~a»" nodo))

(defmethod generar-codigo ((nodo ref-especifica-ent) (destino verbalizador) stream)
  (format stream "~a" (etiqueta nodo)))

(defmethod generar-codigo ((nodo acceso-a-atributo-de-entidad) (destino verbalizador) stream)
  (format stream "~a" (acceso->prosa nodo)))

(defun consulta-de (nodo)
  "Devuelve la consulta del modelo que corresponde a un nodo del AST."
  (find nodo (modelo-consultas (modelo-actual)) :key #'consulta-nodo))

(defmethod generar-codigo ((nodo aplicacion-de-consulta) (destino verbalizador) stream)
  (format stream "~a" (consulta->prosa (consulta-de (slot-value nodo 'consulta)))))

(defun iteracion->prosa (iteradores)
  "Escribe los iteradores: cada canal c y cada emisión e1."
  (enumerar (mapcar (lambda (iterador)
                      (format nil "cada ~a ~a"
                              (nombre-prosa (second iterador))
                              (variable-prosa (first iterador))))
                    iteradores)))

(defun parametros->prosa (parametros)
  "Presenta los parámetros de una consulta, que en la condición son variables libres."
  (if parametros
      (format nil "dado ~a, "
              (enumerar (mapcar (lambda (parametro) (variable-prosa (first parametro))) parametros) "y"))
      ""))

(defun distintos->prosa (operacion)
  "Nombra lo que cuenta contar-distintos a partir de su slot: fechas distintas."
  (let ((slot (first (camino (slot-value operacion 'expresion)))))
    (format nil "~a ~a" (nombre-prosa slot :plural t)
            (if (femenino-p slot) "distintas" "distintos"))))

(defgeneric medida-literal (operacion consulta)
  (:documentation "Escribe nodo a nodo lo que mide una consulta."))

(defmethod medida-literal ((operacion suma) consulta)
  (format nil "el número de casos, ~apara ~a, en que ~a"
          (parametros->prosa (consulta-parametros consulta))
          (iteracion->prosa (consulta-iteradores consulta))
          (prosa (consulta-condicion consulta))))

(defmethod medida-literal ((operacion contar-distintos) consulta)
  (format nil "el número de ~a, ~apara ~a, en que ~a"
          (distintos->prosa operacion)
          (parametros->prosa (consulta-parametros consulta))
          (iteracion->prosa (consulta-iteradores consulta))
          (prosa (consulta-condicion consulta))))

(defun consulta->prosa (consulta)
  "Escribe literalmente lo que mide CONSULTA."
  (let ((*entidades-de-variables* (append (consulta-iteradores consulta) *entidades-de-variables*)))
    (medida-literal (consulta-operacion consulta) consulta)))

(defgeneric restriccion-literal (nodo restriccion)
  (:documentation "Escribe una restricción nodo a nodo. Se usa «lo siguiente:» porque tras los dos puntos vale el indicativo."))

(defun comprobacion->prosa (nodo)
  "Traduce la comprobación de un cuantificador."
  (prosa (slot-value nodo 'comprobacion)))

(defmethod restriccion-literal ((nodo nppq) restriccion)
  (declare (ignore restriccion))
  (format nil "No puede pasar lo siguiente: ~a." (comprobacion->prosa nodo)))

(defmethod restriccion-literal ((nodo tqpq) restriccion)
  (declare (ignore restriccion))
  (format nil "Tiene que pasar lo siguiente: ~a." (comprobacion->prosa nodo)))

(defmethod restriccion-literal ((nodo ndpq) restriccion)
  (declare (ignore restriccion))
  (format nil "No debe pasar lo siguiente: ~a." (comprobacion->prosa nodo)))

(defmethod restriccion-literal ((nodo sbqp) restriccion)
  (declare (ignore restriccion))
  (format nil "Sería bueno lo siguiente: ~a." (comprobacion->prosa nodo)))

(defun dominios-de-para (restriccion)
  "Escribe los dominios de un objetivo: los profesores."
  (enumerar (mapcar (lambda (variable) (sintagma (second variable) :definido t :plural t))
                    (restriccion-variables restriccion))))

(defmethod restriccion-literal ((nodo minimizar) restriccion)
  (format nil "Se prefiere la solución que minimiza el máximo, entre ~a, de ~a."
          (dominios-de-para restriccion) (comprobacion->prosa nodo)))

(defmethod restriccion-literal ((nodo maximizar) restriccion)
  (format nil "Se prefiere la solución que maximiza el mínimo, entre ~a, de ~a."
          (dominios-de-para restriccion) (comprobacion->prosa nodo)))
