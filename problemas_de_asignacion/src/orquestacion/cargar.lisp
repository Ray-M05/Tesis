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
