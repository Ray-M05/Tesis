(in-package :orquestacion)

(defun cargar-flujo (flujo nombre)
  "Carga desde FLUJO el dominio NOMBRE en un paquete propio y devuelve su problema."
  (let ((paquete (format nil "DOMINIO-~:@(~a~)" nombre)))
    (when (find-package paquete)
      (delete-package paquete))
    (let ((*package* (make-package paquete :use '(:cl :dsl))))
      (con-registros-nuevos
        (load flujo)
        (or *problema-cargado*
            (rechazar "dominio ~a: falta def-problema" nombre))))))

(defun cargar-dominio (ruta)
  "Carga el dominio de RUTA; su nombre es el de la carpeta que lo contiene."
  (with-open-file (flujo ruta :external-format :utf-8)
    (cargar-flujo flujo (first (last (pathname-directory ruta))))))

(defun cargar-anotaciones (ruta)
  "Lee las anotaciones del verbalizador junto al dominio de RUTA. Son datos, y son opcionales."
  (let ((archivo (merge-pathnames "verbalizador.lisp" ruta)))
    (when (probe-file archivo)
      (with-open-file (flujo archivo :external-format :utf-8)
        (let* ((*read-eval* nil)
               (anotaciones (read flujo))
               (predicados (getf anotaciones :predicados)))
          (unless (every (lambda (predicado)
                           (and (= (length predicado) 2) (every #'stringp predicado)))
                         predicados)
            (rechazar "~a: :predicados tiene que ser una lista de (slot frase)" archivo))
          anotaciones)))))
