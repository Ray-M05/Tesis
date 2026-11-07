;; Genera la salida de los dominios en salida/<dominio>/: sbcl --script generar.lisp [dominio...]
;; Sin argumentos genera todos.
(require :asdf)

(defparameter *raiz* (make-pathname :name nil :type nil :defaults *load-truename*))

(asdf:load-asd (merge-pathnames "problemas_de_asignacion.asd" *raiz*))
(let ((*compile-verbose* nil) (*compile-print* nil))
  (asdf:load-system "problemas_de_asignacion"))

(defun dominios-indicados ()
  "Devuelve los dominios pedidos al ejecutar el guion o, si no hay ninguno, todos."
  (or (cddr (member "--script" sb-ext:*posix-argv* :test #'string=))
      (mapcar (lambda (carpeta) (first (last (pathname-directory carpeta))))
              (directory (merge-pathnames "dominios/*/" *raiz*)))))

(dolist (dominio (dominios-indicados))
  (let ((ruta (merge-pathnames (format nil "dominios/~a/dominio.lisp" dominio) *raiz*))
        (carpeta (merge-pathnames (format nil "salida/~a/" dominio) *raiz*)))
    (orquestacion:exportar (analisis:construir-modelo (orquestacion:cargar-dominio ruta))
                           carpeta
                           (orquestacion:cargar-anotaciones ruta))
    (format t "~a: ~a~%" dominio (namestring carpeta))))
