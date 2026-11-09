;; Genera y, si se pide, ejecuta. Lo que no se nombra va entero; el detalle está en ejecuciones/README.md.
;;   sbcl --script generar.lisp [dominio ...] [--destinos ...] [--estrategias ...] [--semillas ...] [--ejecutar]
;;   sbcl --script generar.lisp --archivo ejecuciones/<nombre>.lisp
;; Termina con código 1 si el pedido está mal escrito o si algún dominio falló.
(require :asdf)

(asdf:load-asd (merge-pathnames "problemas_de_asignacion.asd"
                                (make-pathname :name nil :type nil :defaults *load-truename*)))
(let ((*compile-verbose* nil) (*compile-print* nil))
  (asdf:load-system "problemas_de_asignacion"))

(sb-ext:exit
 :code (if (handler-case
               (orquestacion:conducir
                (orquestacion:pedido-de-argumentos (rest sb-ext:*posix-argv*)))
             (error (condicion)
               (format t "~a~%" condicion)
               nil))
           0
           1))
