;; Ejecuta todas las pruebas: sbcl --script pruebas/correr.lisp
;; Una prueba que falla termina el proceso con código 1.
(require :asdf)

(defparameter *pruebas* (make-pathname :name nil :type nil :defaults *load-truename*))

(asdf:load-asd (truename (merge-pathnames "../problemas_de_asignacion.asd" *pruebas*)))
(let ((*compile-verbose* nil) (*compile-print* nil))
  (asdf:load-system "problemas_de_asignacion"))

(dolist (archivo '("dsl/utiles" "dsl/validacion" "dsl/nodos" "dsl/entidades"
                   "dsl/consultas" "dsl/restricciones" "dsl/problema" "dsl/migracion"))
  (load (merge-pathnames (concatenate 'string archivo ".lisp") *pruebas*)
        :external-format :utf-8)
  (format t "ok ~a~%" archivo))

(format t "Todas las pruebas pasan.~%")
