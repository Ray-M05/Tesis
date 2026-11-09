(in-package :orquestacion)

(defun escribir (archivo carpeta escritura)
  "Escribe en CARPETA el archivo ARCHIVO con lo que ESCRITURA escribe en un flujo."
  (let ((ruta (merge-pathnames archivo carpeta)))
    (ensure-directories-exist ruta)
    (with-open-file (flujo ruta :direction :output :if-exists :supersede
                                :external-format :utf-8)
      (funcall escritura flujo))))

(defun carpeta-de (clase carpeta)
  "Devuelve la subcarpeta de CARPETA en la que escribe el destino CLASE."
  (merge-pathnames (format nil "~a/" (nombre-de-clase clase)) carpeta))

(defun exportar (modelo carpeta &key (destinos (elegir nil 'destino "el destino"))
                                     (estrategias (mapcar #'make-instance
                                                          (elegir nil 'estrategia "la estrategia")))
                                     anotaciones)
  "Escribe una subcarpeta por destino y, en la de python, que siempre va si hay ESTRATEGIAS, un programa por estrategia."
  (flet ((crear (clase)
           (make-instance clase :modelo modelo :predicados (getf anotaciones :predicados)
                                :allow-other-keys t)))
    (dolist (clase (if estrategias (adjoin 'python destinos) destinos))
      (let ((destino (crear clase)))
        (escribir (archivo-de destino) (carpeta-de clase carpeta)
                  (lambda (flujo) (emitir destino flujo)))))
    (dolist (estrategia estrategias)
      (escribir (format nil "~a.py" (estrategia-nombre estrategia)) (carpeta-de 'python carpeta)
                (lambda (flujo) (emitir-estrategia estrategia (crear 'python) flujo))))))
