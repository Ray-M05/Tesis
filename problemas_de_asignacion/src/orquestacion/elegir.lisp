(in-package :orquestacion)

(defun clases-hoja (clase)
  "Devuelve, ordenadas por nombre, las clases sin subclases que descienden de CLASE."
  (labels ((hojas (clase)
             (let ((subclases (sb-mop:class-direct-subclasses (find-class clase))))
               (if subclases
                   (mapcan (lambda (subclase) (hojas (class-name subclase))) subclases)
                   (list clase)))))
    (sort (remove-duplicates (hojas clase)) #'string< :key #'symbol-name)))

(defun nombre-de-clase (clase)
  "Devuelve el nombre con el que se pide CLASE: el de la clase, en minúsculas."
  (string-downcase (symbol-name clase)))

(defun elegir (nombres clase que)
  "Devuelve las clases hoja de CLASE llamadas NOMBRES, o todas si NOMBRES está vacío."
  (let ((hojas (clases-hoja clase)))
    (if (null nombres)
        hojas
        (mapcar (lambda (nombre)
                  (or (find (string nombre) hojas :key #'symbol-name :test #'string-equal)
                      (rechazar "no existe ~a ~a. Hay: ~{~a~^, ~}"
                                que (string-downcase (string nombre))
                                (mapcar #'nombre-de-clase hojas))))
                nombres))))
