;; =====================================================================
;; problema.lisp — Estructura del problema y acceso a instancias
;; =====================================================================
;; EXTRACTO VERBATIM del proyecto original
;;
;;   generador-horarios/lib/generador.lisp:44-129
;;     defstruct problema-horario, def-problema-horario, mostrar-problema
;;
;;   generador-horarios/lib/gen-serializar.lisp:5-11, 35-38
;;     entidad-de-clase, instancias-de
;;
;;   generador-horarios/lib/gen-restricciones.lisp:12-20
;;     tipo-restriccion
;;
;; Se conservan los parametros del algoritmo genetico aunque aqui no se
;; usen: asi cualquier dominio.lisp del proyecto original se copia sin
;; editar una linea.
;;
;; Depende de: lib/clases-macros.lisp  (*instancias-de-entidad*,
;;                                      *slots-de-entidad*, ref-especifica-ent)
;; =====================================================================


;; =====================================================================
;; DEFINICIÓN DEL PROBLEMA
;; =====================================================================

(defstruct problema-horario
  entidad-horario
  slot-identidad
  slots-variables
  consultas
  restricciones-duras
  restricciones-blandas
  (peso-dura     1000)
  (peso-blanda      1)
  ;; Parámetros del algoritmo genético
  (pop-size       100)
  (generaciones   500)
  (prob-cruce     0.8)
  (prob-mutacion 0.15)
  (torneo-k         5)
  instancias       ;; foto de *instancias-de-entidad* al momento de crear el problema
  slots-entidades) ;; foto de *slots-de-entidad* al momento de crear el problema

(defun def-problema-horario (&key entidad-horario
                                   slot-identidad
                                   slots-variables
                                   consultas
                                   restricciones-duras
                                   restricciones-blandas
                                   (peso-dura     1000)
                                   (peso-blanda      1)
                                   ;; Parámetros del algoritmo genético
                                   (pop-size       100)
                                   (generaciones   500)
                                   (prob-cruce     0.8)
                                   (prob-mutacion 0.15)
                                   (torneo-k         5))
  "Crea un objeto con toda la descripción del problema: estructura, restricciones
   e instancias de dominio. Captura una foto del estado actual para que el generador
   sea una función pura que no depende de variables globales."
  (let ((snap-inst  (make-hash-table))
        (snap-slots (make-hash-table)))
    (maphash (lambda (k v) (setf (gethash k snap-inst)  (copy-list v)))
             *instancias-de-entidad*)
    (maphash (lambda (k v) (setf (gethash k snap-slots) (copy-list v)))
             *slots-de-entidad*)
    (make-problema-horario
      :entidad-horario       entidad-horario
      :slot-identidad        slot-identidad
      :slots-variables       slots-variables
      :consultas             consultas
      :restricciones-duras   restricciones-duras
      :restricciones-blandas restricciones-blandas
      :peso-dura             peso-dura
      :peso-blanda           peso-blanda
      :pop-size              pop-size
      :generaciones          generaciones
      :prob-cruce            prob-cruce
      :prob-mutacion         prob-mutacion
      :torneo-k              torneo-k
      :instancias            snap-inst
      :slots-entidades       snap-slots)))

(defun mostrar-problema (problema)
  "Imprime el contenido completo del problema: estructura, restricciones e instancias
   capturadas. Útil para verificar que el objeto tiene todo antes de generar código."
  (format t "~%============================================================~%")
  (format t "PROBLEMA DE HORARIO~%")
  (format t "============================================================~%")
  (format t "  Entidad combinación : ~a~%" (problema-horario-entidad-horario  problema))
  (format t "  Slot identidad      : ~a~%" (problema-horario-slot-identidad   problema))
  (format t "  Slots variables     : ~a~%" (problema-horario-slots-variables  problema))
  (format t "  Consultas           : ~a~%" (problema-horario-consultas        problema))
  (format t "  Restricciones duras : ~a~%" (problema-horario-restricciones-duras   problema))
  (format t "  Restricciones bland.: ~a~%" (problema-horario-restricciones-blandas problema))
  (format t "  Pesos               : dura=~a  blanda=~a~%"
          (problema-horario-peso-dura  problema)
          (problema-horario-peso-blanda problema))
  (format t "  AG: pop=~a  gen=~a  cruce=~a  mut=~a  torneo=~a~%"
          (problema-horario-pop-size      problema)
          (problema-horario-generaciones  problema)
          (problema-horario-prob-cruce    problema)
          (problema-horario-prob-mutacion problema)
          (problema-horario-torneo-k      problema))
  (format t "~%  Instancias capturadas:~%")
  (let ((tabla (problema-horario-instancias problema)))
    (maphash (lambda (tipo simbolos)
               (format t "    ~a: ~a instancia~:p~%"
                       tipo (length simbolos)))
             tabla))
  (format t "============================================================~%~%"))


;; =====================================================================
;; ACCESO A LAS INSTANCIAS DEL DOMINIO
;; =====================================================================

(defun entidad-de-clase (clase-sym)
  "REF-ESPECIFICA-A-PROFESOR → PROFESOR (símbolo)."
  (let* ((str     (symbol-name clase-sym))
         (prefijo "REF-ESPECIFICA-A-"))
    (when (and (>= (length str) (length prefijo))
               (string= (subseq str 0 (length prefijo)) prefijo))
      (intern (subseq str (length prefijo))))))

(defun instancias-de (entidad-nombre)
  "Devuelve la lista de valores (no símbolos) de las instancias de una entidad."
  (mapcar #'symbol-value
          (gethash entidad-nombre *instancias-de-entidad*)))


;; =====================================================================
;; CLASIFICACIÓN DE RESTRICCIONES
;; =====================================================================

(defun tipo-restriccion (nodo)
  (typecase nodo
    (nppq      :nppq)
    (tqpq      :tqpq)
    (ndpq      :ndpq)
    (sbqp      :sbqp)
    (minimizar :minimizar)
    (maximizar :maximizar)
    (t         :desconocido)))
