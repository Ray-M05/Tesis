(defpackage :pruebas-emision
  (:use :cl :dsl-ast :orquestacion :analisis :emision))

(in-package :pruebas-emision)

(defparameter *aqui* (make-pathname :name nil :type nil :defaults *load-truename*))

(defparameter *base* "
(def-mixin tiene-nombre () (nombre))
(def-entidad semana () (numero))
(def-entidad dia (tiene-nombre) (semana))
(def-entidad turno () (orden global))
(def-entidad profesor (tiene-nombre) (apellido))
(def-entidad sesion () (profesor duracion))
(def-entidad vacia ())
(def-entidad aula (tiene-nombre) (edificio capacidad))
(def-comb fila (sesion dia turno))
(def-semana sem1 1)
(def-semana sem2 2)
(def-dia lunes \"Lunes\" sem1)
(def-dia martes \"Martes\" sem1)
(def-dia jueves \"Jueves\" sem2)
(def-turno t1 1 0)
(def-turno t2 2 0)
(def-profesor ana \"Peña \\\"Ana\\\"\" \"Paz\")
(def-profesor luis \"Luis\" \"Rey\")
(def-aula aula-1 \"A1\" \"Norte\" 30)
(def-sesion s1 ana 2)
(def-sesion s2 ana 2)
(def-sesion s3 luis 3)
(def-sesion s4 luis 3)
(def-consulta de-dia (d)
  :itera-sobre (u fila)
  :comprueba (op-igual (dia u) d)
  :operacion (suma 1))
(def-consulta de-profesor (p)
  :itera-sobre (u fila)
  :comprueba (op-igual (profesor (sesion u)) p)
  :operacion (suma 1))
")

(defmacro con-carpeta ((carpeta) &body cuerpo)
  "Ejecuta CUERPO con una carpeta temporal vacía, que se borra al terminar."
  `(let ((,carpeta (merge-pathnames (format nil "problemas-de-asignacion-~36r/" (random (expt 36 8)))
                                    (uiop:temporary-directory))))
     (unwind-protect (progn ,@cuerpo)
       (uiop:delete-directory-tree ,carpeta :validate t :if-does-not-exist :ignore))))

(defun modelo-de (texto restricciones)
  "Construye el modelo del dominio base con TEXTO y un problema con las RESTRICCIONES."
  (construir-modelo
   (pruebas-dsl::carga
    (format nil "~a~a~%(def-problema el-problema :combinacion fila :identidad sesion ~
                 :variables (dia turno) :restricciones (~{~a~^ ~}))"
            *base* texto restricciones))))

(defun ejecutar-python (carpeta &rest argumentos)
  "Ejecuta Python en CARPETA y exige que termine bien. Devuelve lo que imprimió."
  (let* ((salida (make-string-output-stream))
         (proceso (sb-ext:run-program "python" (list* "-X" "utf8" argumentos)
                                      :search t
                                      :directory carpeta
                                      :output salida
                                      :error salida
                                      :external-format :utf-8))
         (texto (get-output-stream-string salida)))
    (assert (zerop (sb-ext:process-exit-code proceso)) () "Python falló:~%~a" texto)
    texto))

(defun codigo-generado (modelo)
  "Devuelve como texto el modelo.py de MODELO."
  (with-output-to-string (flujo)
    (emitir (make-instance 'python :modelo modelo) flujo)))

(defun comprobar-en-python (modelo guion)
  "Ejecuta GUION, un programa con asserts, después de importar el modelo.py de MODELO."
  (con-carpeta (carpeta)
    (exportar modelo carpeta)
    (let ((prueba (merge-pathnames "prueba.py" carpeta)))
      (with-open-file (flujo prueba :direction :output :external-format :utf-8)
        (format flujo "from modelo import *~%~a~%" guion))
      (ejecutar-python carpeta "prueba.py"))))
