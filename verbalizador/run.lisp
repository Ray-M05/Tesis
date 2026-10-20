;; =====================================================================
;; run.lisp — Verbaliza todos los dominios de dominios/
;; =====================================================================
;; Uso:
;;
;;   sbcl --script run.lisp            <- todos los dominios
;;   sbcl --script run.lisp tesis      <- solo uno
;;
;; Recorre dominios/*.lisp y escribe un .md por dominio en salida/.
;; Para anadir un ejemplo nuevo basta poner su .lisp en dominios/

;; Cada dominio se revisa en silencio despues de generarlo; solo se
;; imprimen avisos si hay algo mal (nodos sin traducir, algo sin
;; verbalizar, orden de entidades incorrecto).

(defparameter *raiz*
  (make-pathname :name nil :type nil
                 :defaults (or *load-truename* (truename "."))))

;; Sin argumento -> conductor. Con argumento -> trabajador de un dominio.
(defparameter *dominio* (second sb-ext:*posix-argv*))

(defun cargar (rel)
  (load (merge-pathnames rel *raiz*)))


;; ── Infraestructura prestada del proyecto original ──────────────────
(cargar "lib/clases-macros.lisp")   ; AST + macros del DSL
(cargar "lib/gen-utils.lisp")       ; flatten-op
(cargar "lib/problema.lisp")        ; problema-horario, instancias-de

;; ── Modulos del verbalizador ────────────────────────────────────────
(cargar "nlgen/lexicon.lisp")       ; morfologia espanola + registro
(cargar "nlgen/order.lisp")         ; grafo de entidades y orden logico
(cargar "nlgen/expr.lisp")          ; capa literal: nodo -> frase
(cargar "nlgen/idioms.lisp")        ; reconocimiento de patrones
(cargar "nlgen/document.lisp")      ; el documento completo


;; =====================================================================
;; TRABAJADOR: un dominio
;; =====================================================================

(defun problema-de (nombre)
  (let ((sym (find-symbol (string-upcase (format nil "problema-~a" nombre)))))
    (and sym (boundp sym) (symbol-value sym))))

(defun trabajar (nombre)
  (load (merge-pathnames (format nil "dominios/~a.lisp" nombre) *raiz*))
  (let ((p (problema-de nombre)))
    (cond
      ((null p)
       (format t "  ~12a  SIN PROBLEMA: se esperaba la variable problema-~a~%"
               nombre nombre)
       1)
      (t
       (let* ((salida (merge-pathnames (format nil "salida/~a.md" nombre) *raiz*))
              (texto  (generate-description salida p))
              (avisos (revisar p texto))
              (idi    (idiomas-reconocidos p)))
         (format t "  ~12a  ~2a entidades  ~2a consultas  ~2a restricciones  ~a/~a idiomas  ~5a car.~%"
                 nombre
                 (length (entity-names p))
                 (length (problema-horario-consultas p))
                 (cdr idi) (car idi) (cdr idi)
                 (length texto))
         ;; El documento se escribe siempre. Los avisos solo aparecen si
         ;; hay algo que revisar.
         (dolist (a avisos) (format t "                AVISO: ~a~%" a))
         (if avisos 1 0))))))


;; =====================================================================
;; CONDUCTOR: lanza un proceso por dominio
;; =====================================================================

(defun conducir ()
  (ensure-directories-exist (merge-pathnames "salida/" *raiz*))
  (let ((archivos (sort (directory (merge-pathnames "dominios/*.lisp" *raiz*))
                        #'string< :key #'pathname-name))
        (script   (namestring (merge-pathnames "run.lisp" *raiz*)))
        (fallos   0))
    (format t "~%Verbalizando ~a dominio~:p de dominios/~%~%" (length archivos))
    (dolist (a archivos)
      (let ((proc (sb-ext:run-program sb-ext:*runtime-pathname*
                                      (list "--script" script (pathname-name a))
                                      :output *standard-output*
                                      :error  *standard-output*
                                      :search nil)))
        (unless (zerop (sb-ext:process-exit-code proc))
          (incf fallos)
          (format t "  ~12a  FALLO (ver el error arriba)~%" (pathname-name a)))))
    (format t "~%~a~%~%"
            (if (zerop fallos)
                "Documentos en salida/"
                (format nil "~a dominio~:p con error. Documentos en salida/" fallos)))
    fallos))


;; =====================================================================

(if *dominio*
    (sb-ext:exit :code (trabajar *dominio*))
    (sb-ext:exit :code (if (zerop (conducir)) 0 1)))
