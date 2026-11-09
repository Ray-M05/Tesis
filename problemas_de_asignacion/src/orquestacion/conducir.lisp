(in-package :orquestacion)

(defun valor-de-argumento (valor)
  "Escribe VALOR como lo espera la línea de comandos de un programa."
  (if (symbolp valor) (string-downcase (symbol-name valor)) (princ-to-string valor)))

(defun revisar-parametros (clase parametros ejecutar)
  "Exige que PARAMETROS sean argumentos de la estrategia CLASE y que se vaya a ejecutar."
  (when (and parametros (not ejecutar))
    (rechazar "~a: los parámetros solo se usan al ejecutar, y no se pide ejecutar" (nombre-de-clase clase)))
  (let ((validos (remove "semilla" (mapcar #'first (argumentos-de (make-instance clase)))
                         :test #'string=)))
    (loop for clave in parametros by #'cddr
          unless (member (string-downcase (symbol-name clave)) validos :test #'string=)
            do (rechazar "~a no tiene el parámetro ~(~s~). Los que tiene: ~{~a~^, ~}"
                         (nombre-de-clase clase) clave validos))))

(defun resolver (pedido)
  "Devuelve las clases de destino de PEDIDO y sus estrategias como (clase . parámetros), ya revisadas."
  (let* ((destinos (elegir (getf pedido :destinos) 'destino "el destino"))
         (estrategias (cond ((getf pedido :estrategias)
                             (mapcar (lambda (estrategia)
                                       (cons (first (elegir (list (first estrategia)) 'estrategia "la estrategia"))
                                             (rest estrategia)))
                                     (getf pedido :estrategias)))
                            ((member 'python destinos)
                             (mapcar #'list (elegir nil 'estrategia "la estrategia"))))))
    (dolist (estrategia estrategias)
      (revisar-parametros (first estrategia) (rest estrategia) (getf pedido :ejecutar)))
    (values destinos estrategias)))

(defun escribir-avisos (modelo nombre carpeta)
  "Imprime los avisos del análisis y los escribe en avisos.txt, aunque no haya ninguno."
  (let ((mensajes (mapcar #'aviso-mensaje (modelo-avisos modelo))))
    (dolist (mensaje mensajes)
      (format t "~a: aviso: ~a~%" nombre mensaje))
    (escribir "avisos.txt" carpeta
              (lambda (flujo) (format flujo "~{~a~%~}" mensajes)))))

(defun ejecutar (clase parametros semilla carpeta)
  "Ejecuta el programa de la estrategia CLASE en CARPETA. Devuelve t si terminó bien."
  (let* ((archivo (format nil "~a.py" (estrategia-nombre (make-instance clase))))
         (argumentos (list* "-X" "utf8" archivo "--semilla" (princ-to-string semilla)
                            (loop for (clave valor) on parametros by #'cddr
                                  collect (format nil "--~(~a~)" (symbol-name clave))
                                  collect (valor-de-argumento valor))))
         (proceso (progn (format t "python ~{~a~^ ~}~%" (rest (rest argumentos)))
                         (finish-output)
                         (sb-ext:run-program "python" argumentos :search t :directory (namestring carpeta)
                                                                 :output t :error t))))
    (or (zerop (sb-ext:process-exit-code proceso))
        (progn (format t "~a con la semilla ~a terminó mal~%" archivo semilla) nil))))

(defun generar-dominio (nombre pedido destinos estrategias dominios salida)
  "Genera el dominio NOMBRE y, si PEDIDO lo dice, ejecuta sus estrategias. Devuelve t si todo terminó bien."
  (let ((ruta (merge-pathnames (format nil "~a/dominio.lisp" nombre) dominios))
        (carpeta (merge-pathnames (format nil "~a/" nombre) salida)))
    (unless (probe-file ruta)
      (rechazar "no existe ~a" (namestring ruta)))
    (let ((modelo (construir-modelo (cargar-dominio ruta))))
      (escribir-avisos modelo nombre carpeta)
      (exportar modelo carpeta :destinos destinos
                               :estrategias (mapcar (lambda (estrategia) (make-instance (first estrategia)))
                                                    estrategias)
                               :anotaciones (cargar-anotaciones ruta))
      (format t "~a: ~a~%" nombre (namestring carpeta)))
    (or (not (getf pedido :ejecutar))
        (let ((bien t))
          (dolist (estrategia estrategias bien)
            (dolist (semilla (or (getf pedido :semillas) '(0)))
              (unless (ejecutar (first estrategia) (rest estrategia) semilla (carpeta-de 'python carpeta))
                (setf bien nil))))))))

(defun dominios-de (pedido dominios)
  "Devuelve los dominios de PEDIDO o, si no nombra ninguno, todas las carpetas de DOMINIOS."
  (or (getf pedido :dominios)
      (sort (mapcar (lambda (carpeta) (first (last (pathname-directory carpeta))))
                    (directory (merge-pathnames "*/" dominios)))
            #'string<)))

(defun conducir (pedido &key (dominios (asdf:system-relative-pathname "problemas_de_asignacion" "dominios/"))
                             (salida (asdf:system-relative-pathname "problemas_de_asignacion" "salida/")))
  "Genera y, si se pide, ejecuta cada dominio de PEDIDO. Devuelve t si ninguno falló."
  (multiple-value-bind (destinos estrategias) (resolver pedido)
    (let ((bien t))
      (dolist (nombre (dominios-de pedido dominios) bien)
        (handler-case (unless (generar-dominio nombre pedido destinos estrategias dominios salida)
                        (setf bien nil))
          (error (condicion)
            (format t "~a: ~a~%" nombre condicion)
            (setf bien nil)))))))
