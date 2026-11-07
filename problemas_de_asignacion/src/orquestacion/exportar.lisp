(in-package :orquestacion)

(defun escribir (destino archivo carpeta)
  "Escribe en CARPETA el archivo completo de DESTINO."
  (let ((ruta (merge-pathnames archivo carpeta)))
    (ensure-directories-exist ruta)
    (with-open-file (flujo ruta :direction :output :if-exists :supersede
                                :external-format :utf-8)
      (emitir destino flujo))))

(defun exportar (modelo carpeta &optional anotaciones)
  "Escribe en CARPETA, un directorio, los archivos que se generan de MODELO."
  (escribir (make-instance 'python :modelo modelo) "modelo.py" carpeta)
  (escribir (make-instance 'matematica :modelo modelo) "modelo.tex" carpeta)
  (escribir (make-instance 'verbalizador :modelo modelo :predicados (getf anotaciones :predicados))
            "descripcion.md" carpeta))
