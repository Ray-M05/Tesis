;; Ejecuta todas las pruebas: sbcl --script pruebas/correr.lisp
;; Una prueba que falla termina el proceso con código 1.
(require :asdf)

(defparameter *pruebas* (make-pathname :name nil :type nil :defaults *load-truename*))

(asdf:load-asd (truename (merge-pathnames "../problemas_de_asignacion.asd" *pruebas*)))
(let ((*compile-verbose* nil) (*compile-print* nil))
  (asdf:load-system "problemas_de_asignacion"))

(dolist (archivo '("dsl/utiles" "dsl/validacion" "dsl/nodos" "dsl/entidades"
                   "dsl/consultas" "dsl/restricciones" "dsl/problema" "dsl/migracion"
                   "analisis/utiles" "analisis/recorrido" "analisis/tipos" "analisis/atomos"
                   "analisis/simetria" "analisis/familias" "analisis/normalizar"
                   "analisis/orden" "analisis/modelo"
                   "emision/utiles" "emision/completitud" "emision/python" "emision/referencia"
                   "emision/matematica" "emision/verbalizador" "emision/sin-dominio"))
  (load (merge-pathnames (concatenate 'string archivo ".lisp") *pruebas*)
        :external-format :utf-8)
  (format t "ok ~a~%" archivo))

(format t "Todas las pruebas pasan.~%")
