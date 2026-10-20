;; =====================================================================
;; document.lisp — Emision del documento completo
;; =====================================================================
;; Convierte los fragmentos de expr.lisp en un documento que se lee de
;; principio a fin. Cinco secciones, todas derivadas de problema-horario:
;;
;;   Entidades      <- slots-entidades
;;   Datos          <- instancias  (via instancias-de)
;;   Que se decide  <- entidad-horario, slot-identidad, slots-variables
;;   Que se mide    <- consultas
;;   Restricciones  <- restricciones-duras, restricciones-blandas
;;

;; =====================================================================
;; UTILIDADES
;; =====================================================================

(defun capitalize-first (cadena)
  "Mayuscula inicial sin tocar el resto (string-capitalize destroza
   'un tipo de programa' convirtiendolo en 'Un Tipo De Programa')."
  (if (zerop (length cadena))
      cadena
      (concatenate 'string
                   (string-upcase (subseq cadena 0 1))
                   (subseq cadena 1))))

(defvar *numeros*
  #("cero" "uno" "dos" "tres" "cuatro" "cinco" "seis" "siete" "ocho" "nueve"
    "diez" "once" "doce" "trece" "catorce" "quince" "dieciséis" "diecisiete"
    "dieciocho" "diecinueve" "veinte"))

(defun numero->nl (n)
  "Numero en letra. ponytail: solo 0-20; por encima se usan cifras,
   que es lo que hace tambien la prosa escrita a mano del proyecto.
   Ampliar con composicion decenas+unidades si algun dia hace falta."
  (if (and (integerp n) (<= 0 n 20))
      (aref *numeros* n)
      (format nil "~a" n)))


;; =====================================================================
;; ENTIDADES
;; =====================================================================

(defun real-entity-p (nombre)
  "T si NOMBRE es una entidad de dominio y no un mixin.
   def-entidad crea un defvar ligado a un ref-gen-entidad; defclass* no.
   Sin este filtro, el mixin tiene-nombre produciria la frase absurda
   'Un tiene nombre tiene nombre.'"
  (and (boundp nombre)
       (typep (symbol-value nombre) 'ref-gen-entidad)))

(defun entity-names (problema)
  (let ((comb  (problema-horario-entidad-horario problema))
        (otras '()))
    (maphash (lambda (nombre slots)
               (declare (ignore slots))
               (when (and (real-entity-p nombre) (not (eq nombre comb)))
                 (push nombre otras)))
             (problema-horario-slots-entidades problema))
    (append (nreverse otras) (list comb))))

(defun entity->nl (nombre)
  "'Un programa tiene nombre, tipo, duración y canal.'

   Los slots booleanos se separan: un plan no 'tiene admite doble', dice
   SI admite turno doble. Es la misma tabla de predicados que usa
   expr.lisp para no escribir 'es igual a 0'."
  (let* ((slots (gethash nombre *slots-de-entidad*))
         (preds (remove-if-not (lambda (s) (predicate-phrase s)) slots))
         (otros (remove-if     (lambda (s) (predicate-phrase s)) slots))
         (sujeto (capitalize-first (nl-noun nombre)))
         (dice  (join-nl (mapcar (lambda (s) (format nil "si ~a" (predicate-phrase s)))
                                 preds))))
    (cond ((and otros preds)
           (format nil "~a tiene ~a, y dice ~a."
                   sujeto (join-nl (mapcar #'nl-name otros)) dice))
          (preds (format nil "~a dice ~a." sujeto dice))
          (otros (format nil "~a tiene ~a."
                         sujeto (join-nl (mapcar #'nl-name otros))))
          (t     (format nil "~a no tiene atributos." sujeto)))))

(defun combination->nl (nombre)
  "'Una emisión está formada por un bloque y un programa.'"
  (let ((slots (gethash nombre *slots-de-entidad*))
        (fem   (eq :f (nl-gender nombre))))
    (format nil "~a está ~a por ~a."
            (capitalize-first (nl-noun nombre))
            (if fem "formada" "formado")
            (join-nl (mapcar (lambda (s) (nl-noun s)) slots)))))


;; =====================================================================
;; DATOS CONCRETOS
;; =====================================================================

(defun slot-label (inst s)
  (if (slot-boundp inst s)
      (instance-label (slot-value inst s))
      "?"))

(defun instance-label (inst)
  "Como se nombra una instancia en prosa. Misma logica de eleccion que
   generar-str-entidad del proyecto original: el slot 'nombre' si existe,
   el unico slot si solo hay uno, y si no la tupla de todos."
  (typecase inst
    (string inst)
    (number (format nil "~a" inst))
    (ref-especifica-ent
     (let* ((ent   (entidad-de-clase (class-name (class-of inst))))
            (slots (and ent (gethash ent *slots-de-entidad*))))
       (cond
         ((member 'nombre slots)         (slot-label inst 'nombre))
         ((and slots (null (cdr slots))) (slot-label inst (first slots)))
         (slots (format nil "(~{~a~^, ~})"
                        (loop for s in slots
                              when (slot-boundp inst s)
                                collect (format nil "~a ~a"
                                                (nl-name s)
                                                (slot-label inst s)))))
         (t "?"))))
    (symbol (nl-var inst))
    (t (format nil "~a" inst))))

(defun data->nl (nombre &key (limite 10))
  "Regla: enumerar si son pocas, contar si son muchas.
   Es lo que impide que los 56 bloques de tv ensucien el documento."
  (let* ((insts (instancias-de nombre))
         (n     (length insts)))
    (cond
      ((zerop n) nil)
      ((= n 1)
       (format nil "Hay ~a: ~a." (nl-noun nombre) (instance-label (first insts))))
      ((<= n limite)
       (format nil "Hay ~a ~a: ~a."
               (numero->nl n)
               (nl-name nombre :plural t)
               (join-nl (mapcar #'instance-label insts))))
      (t
       (format nil "Hay ~a ~a." (numero->nl n) (nl-name nombre :plural t))))))


;; =====================================================================
;; QUE SE MIDE: MEDIDAS Y MECANICA
;; =====================================================================

(defun mechanical-queries (problema)
  "Consultas que no son medidas del problema sino mecanica del lenguaje.

   Una restriccion con umbral no se puede escribir directa, porque el
   operando derecho se descarta en nppq. Hay que rodearla con un tqpq
   cuantificado sobre una entidad que lleve el umbral como atributo, y
   eso obliga a declarar una consulta auxiliar que solo existe para
   contar las filas de esa entidad. Listarla bajo 'Qué se mide' como si
   fuera un indicador del problema confunde: no mide nada que al lector
   le interese, y su enunciado literal menciona el parametro suelto."
  (let ((mec '()))
    (dolist (r (append (problema-horario-restricciones-duras   problema)
                       (problema-horario-restricciones-blandas problema)) mec)
      (when (boundp r)
        (let ((nodo (symbol-value r)))
          (when (and (member (tipo-restriccion nodo) '(:tqpq :sbqp))
                     (slot-value nodo 'elemento))
            (let ((check (slot-value nodo 'comprobacion)))
              (when (typep check 'operacion-binaria)
                (let ((izq (slot-value check 'operando-izq)))
                  (when (typep izq 'consulta-simple)
                    (let ((sym (query-name izq)))
                      (when sym (pushnew sym mec)))))))))))))


;; =====================================================================
;; QUE SE DECIDE
;; =====================================================================

(defun decision->nl (problema)
  (let ((comb (problema-horario-entidad-horario problema))
        (id   (problema-horario-slot-identidad  problema))
        (vars (problema-horario-slots-variables problema)))
    (format nil "Cada fila del horario es ~a. Se decide, para cada ~a, ~a ~a."
            (nl-noun comb)
            (nl-name id)
            (join-nl (mapcar (lambda (v) (format nil "qué ~a" (nl-name v))) vars))
            (if (cdr vars) "le corresponden" "le corresponde"))))


;; =====================================================================
;; EL DOCUMENTO
;; =====================================================================

(defun description-text (problema)
  "Devuelve el documento completo como cadena."
  (let ((*instancias-de-entidad* (problema-horario-instancias      problema))
        (*slots-de-entidad*      (problema-horario-slots-entidades problema)))
    (register-queries problema)
    (with-output-to-string (out)
      (let* ((comb (problema-horario-entidad-horario problema))
             (ents (entity-order (entity-names problema))))

        (format out "# Descripción del problema~%~%")

        (format out "## Entidades~%~%")
        (dolist (e ents)
          (format out "~a~%~%" (if (eq e comb) (combination->nl e) (entity->nl e))))

        (format out "## Datos~%~%")
        (dolist (e ents)
          (let ((linea (data->nl e)))
            (when linea (format out "~a~%~%" linea))))

        (format out "## Qué se decide~%~%~a~%~%" (decision->nl problema))

        (format out "## Qué se mide~%~%")
        (let ((mec (mechanical-queries problema)))
          (dolist (q (problema-horario-consultas problema))
            (when (and (boundp q) (not (member q mec)))
              ;; smart-query->nl devuelve un sintagma nominal ("el numero
              ;; de..."); aqui hace falta una oracion, de ahi el verbo.
              (format out "**~a.** Se cuenta ~a.~%~%"
                      (capitalize-first (nl-name q))
                      (smart-query->nl (symbol-value q) problema)))))

        (format out "## Restricciones~%~%")
        (format out "### Obligatorias~%~%")
        (dolist (r (problema-horario-restricciones-duras problema))
          (when (boundp r)
            (format out "**~a.** ~a~%~%"
                    (capitalize-first (nl-name r))
                    (smart-constraint->nl (symbol-value r) problema))))
        (format out "### Preferencias~%~%")
        (dolist (r (problema-horario-restricciones-blandas problema))
          (when (boundp r)
            (format out "**~a.** ~a~%~%"
                    (capitalize-first (nl-name r))
                    (smart-constraint->nl (symbol-value r) problema))))))))

(defun generate-description (archivo problema)
  "Escribe el documento y lo devuelve como cadena."
  (let ((texto (description-text problema)))
    (with-open-file (out archivo :direction :output
                                 :if-exists :supersede
                                 :if-does-not-exist :create
                                 :external-format :utf-8)
      (write-string texto out))
    texto))


;; =====================================================================
;; VERIFICACION DE COBERTURA
;; =====================================================================

(defun revisar (problema texto)
  "Devuelve la lista de problemas encontrados en el documento. Vacia si
   todo esta bien. No lanza errores: el documento siempre se escribe, y
   quien llama decide si avisar."
  (let ((avisos '()))
    (let ((*instancias-de-entidad* (problema-horario-instancias      problema))
          (*slots-de-entidad*      (problema-horario-slots-entidades problema)))

      ;; Nada sin traducir, ninguna contraccion sin aplicar.
      (when (search "NODO_DESCONOCIDO" texto)
        (push "hay nodos del AST sin traducir" avisos))
      (when (search "RESTRICCION_DESCONOCIDA" texto)
        (push "hay cuantificadores sin traducir" avisos))
      (when (search " de el " texto) (push "contraccion 'de el' sin aplicar" avisos))
      (when (search " a el "  texto) (push "contraccion 'a el' sin aplicar"  avisos))

      ;; Cobertura: todo lo declarado aparece en el documento.
      ;; char-equal porque las etiquetas llevan mayuscula inicial.
      ;; Las consultas mecanicas no se cuentan: no salen en 'Qué se mide'
      ;; a proposito, y lo que de verdad hay que comprobar es que su
      ;; restriccion este verbalizada, cosa que esta lista ya hace.
      (let ((mec (mechanical-queries problema)))
        (dolist (n (append (entity-names problema)
                           (set-difference (problema-horario-consultas problema) mec)
                           (problema-horario-restricciones-duras   problema)
                           (problema-horario-restricciones-blandas problema)))
          (unless (search (nl-name n) texto :test #'char-equal)
            (push (format nil "sin verbalizar: ~a" n) avisos))))

      ;; Orden: nadie se menciona antes de presentarse.
      (let ((orden (entity-order (entity-names problema))))
        (dolist (e orden)
          (dolist (r (entity-refs e))
            (let ((pr (position r orden)) (pe (position e orden)))
              (when (and pr (> pr pe))
                (push (format nil "~a se menciona antes que ~a, a la que referencia"
                              e r)
                      avisos)))))))
    (nreverse avisos)))

(defun idiomas-reconocidos (problema)
  "(reconocidos . total) de las restricciones del problema."
  (let ((rs (append (problema-horario-restricciones-duras   problema)
                    (problema-horario-restricciones-blandas problema))))
    (cons (count-if (lambda (r) (and (boundp r) (idiom->nl (symbol-value r) problema)))
                    rs)
          (length rs))))
