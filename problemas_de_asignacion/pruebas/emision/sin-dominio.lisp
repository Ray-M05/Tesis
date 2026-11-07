(in-package :pruebas-emision)

;; Palabras que un dominio y el código comparten por casualidad, porque nombran otra cosa.
(defparameter *coincidencias*
  '("BLOQUE" "CLASE" "CODIGO" "EMISION" "GRUPO" "NOMBRE" "ORDEN" "TIPO"))

(defun nombres-de-dominio (dominio)
  "Devuelve los nombres de entidades, slots, instancias, consultas y restricciones de un dominio."
  (let* ((modelo (modelo-del-dominio dominio))
         (problema (modelo-problema modelo)))
    (mapcar #'symbol-name
            (append (problema-entidades problema)
                    (mapcan (lambda (par) (copy-list (cdr par))) (problema-slots problema))
                    (mapcan (lambda (par) (copy-list (cdr par))) (problema-instancias problema))
                    (mapcar #'consulta-nombre (modelo-consultas modelo))
                    (mapcar #'restriccion-nombre (modelo-restricciones modelo))))))

(defun sin-textos (linea)
  "Quita de una línea los textos entre comillas y lo que sigue a un punto y coma."
  (let ((dentro nil) (anterior nil))
    (with-output-to-string (salida)
      (loop for caracter across linea
            do (cond ((and (char= caracter #\") (not (eql anterior #\\)))
                      (setf dentro (not dentro)))
                     (dentro)
                     ((char= caracter #\;) (loop-finish))
                     (t (write-char caracter salida)))
               (setf anterior caracter)))))

(defun simbolos-del-codigo (archivo)
  "Devuelve en mayúsculas las palabras del código de ARCHIVO, sin textos ni comentarios."
  (let ((texto (uiop:read-file-lines archivo :external-format :utf-8))
        (separadores '(#\Space #\Tab #\Return #\( #\) #\' #\` #\, #\# #\:)))
    (mapcan (lambda (linea)
              (mapcar #'string-upcase
                      (remove "" (uiop:split-string (sin-textos linea) :separator separadores)
                              :test #'string=)))
            texto)))

;; Los textos quedan fuera: «día» o «programa» son palabras del idioma, no del dominio.
(let ((propios (remove-duplicates
                (mapcan #'nombres-de-dominio '("tv" "tesis" "docentes" "seder" "saul"))
                :test #'string=))
      (archivos (directory (merge-pathnames "../../src/**/*.lisp" *aqui*))))
  (assert (> (length archivos) 25))
  (dolist (archivo archivos)
    (dolist (palabra (intersection (simbolos-del-codigo archivo) propios :test #'string=))
      (assert (member palabra *coincidencias* :test #'string=) ()
              "~a contiene ~a, que es de un dominio" archivo palabra))))
