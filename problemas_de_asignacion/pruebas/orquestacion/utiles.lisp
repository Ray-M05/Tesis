(defpackage :pruebas-orquestacion
  (:use :cl :dsl-ast :orquestacion)
  (:import-from :pruebas-emision #:con-carpeta))

(in-package :pruebas-orquestacion)

(defparameter *aqui* (make-pathname :name nil :type nil :defaults *load-truename*))

(defun rechaza (funcion &rest fragmentos)
  "Exige que FUNCION señale error-dsl con un mensaje que contenga los FRAGMENTOS."
  (handler-case (progn (funcall funcion)
                       (error "No se rechazó"))
    (error-dsl (condicion)
      (let ((mensaje (princ-to-string condicion)))
        (dolist (fragmento fragmentos)
          (assert (search fragmento mensaje) ()
                  "El mensaje «~a» no contiene «~a»" mensaje fragmento))))))

(defun escribir-texto (ruta texto)
  "Escribe TEXTO en RUTA, creando sus carpetas."
  (ensure-directories-exist ruta)
  (with-open-file (flujo ruta :direction :output :if-exists :supersede :external-format :utf-8)
    (write-string texto flujo)))

(defun leer-texto (ruta)
  "Devuelve el contenido de RUTA."
  (uiop:read-file-string ruta :external-format :utf-8))

(defun archivo-con (carpeta texto)
  "Escribe TEXTO como un archivo de ejecución en CARPETA y devuelve su pedido."
  (let ((ruta (merge-pathnames "pedido.lisp" carpeta)))
    (escribir-texto ruta texto)
    (pedido-de-archivo ruta)))

(defun archivos-de (carpeta)
  "Devuelve, ordenadas, las rutas relativas a CARPETA de los archivos que tiene, fuera de corridas/."
  (sort (loop for ruta in (directory (merge-pathnames "**/*.*" carpeta))
              for relativa = (enough-namestring ruta carpeta)
              unless (or (null (pathname-name ruta)) (search "corridas" relativa))
                collect (substitute #\/ #\\ relativa))
        #'string<))

(defun conducir-en (salida pedido &optional dominios)
  "Conduce PEDIDO con SALIDA y, si se da, DOMINIOS. Lo que imprime Lisp no se muestra."
  (let ((*standard-output* (make-broadcast-stream)))
    (if dominios
        (conducir pedido :salida salida :dominios dominios)
        (conducir pedido :salida salida))))
