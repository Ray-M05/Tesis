(in-package :pruebas-emision)

;; Genera cada dominio real y compara sus valores con los del sistema viejo.
(dolist (dominio '("tv" "tesis" "docentes" "seder" "saul"))
  (let ((ruta (merge-pathnames (format nil "../../dominios/~a/dominio.lisp" dominio) *aqui*)))
    (con-carpeta (carpeta)
      (exportar (construir-modelo (cargar-dominio ruta)) carpeta)
      (ejecutar-python carpeta
                       (namestring (merge-pathnames "comparar.py" *aqui*))
                       dominio))))
