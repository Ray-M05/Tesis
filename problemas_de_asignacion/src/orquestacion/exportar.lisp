(in-package :orquestacion)

(defun escribir (archivo carpeta escritura)
  "Escribe en CARPETA el archivo ARCHIVO con lo que ESCRITURA escribe en un flujo."
  (let ((ruta (merge-pathnames archivo carpeta)))
    (ensure-directories-exist ruta)
    (with-open-file (flujo ruta :direction :output :if-exists :supersede
                                :external-format :utf-8)
      (funcall escritura flujo))))

(defun exportar (modelo carpeta &optional anotaciones)
  "Escribe en CARPETA, un directorio, el modelo, su LaTeX, su prosa y un programa por estrategia."
  (flet ((destino (clase &rest argumentos)
           (apply #'make-instance clase :modelo modelo argumentos)))
    (escribir "modelo.py" carpeta (lambda (flujo) (emitir (destino 'python) flujo)))
    (escribir "modelo.tex" carpeta (lambda (flujo) (emitir (destino 'matematica) flujo)))
    (escribir "descripcion.md" carpeta
              (lambda (flujo)
                (emitir (destino 'verbalizador :predicados (getf anotaciones :predicados)) flujo)))
    (dolist (estrategia (list (make-instance 'genetico) (make-instance 'busqueda-local)))
      (escribir (format nil "~a.py" (estrategia-nombre estrategia)) carpeta
                (lambda (flujo) (emitir-estrategia estrategia (destino 'python) flujo))))))
