(defpackage :pruebas-estrategias
  (:use :cl :analisis :emision :estrategias :orquestacion)
  (:import-from :pruebas-emision
                #:con-carpeta #:modelo-de #:modelo-del-dominio #:ejecutar-python
                #:hojas-de #:comprobar-sin-defecto))

(in-package :pruebas-estrategias)

(defparameter *correr* "
import json, subprocess, sys

def correr(programa, *argumentos):
    salida = subprocess.run([sys.executable, '-X', 'utf8', programa + '.py', *map(str, argumentos)],
                            capture_output=True, text=True, encoding='utf-8')
    if salida.returncode != 0:
        return salida
    with open(salida.stdout.strip().splitlines()[-1], encoding='utf-8') as archivo:
        return json.load(archivo)

def sin_tiempo(corrida):
    return {clave: valor for clave, valor in corrida.items() if clave != 'segundos'}
"
  "Lo que tiene a mano cada guion: correr un programa y leer su JSON.")

(defun programa-de (estrategia modelo)
  "Devuelve como texto el programa de ESTRATEGIA."
  (with-output-to-string (flujo)
    (emitir-estrategia estrategia (make-instance 'python :modelo modelo) flujo)))

(defun comprobar-estrategias (modelo estrategias guion)
  "Ejecuta GUION en una carpeta con lo que escribe exportar y el programa de cada una de ESTRATEGIAS."
  (con-carpeta (carpeta)
    (exportar modelo carpeta)
    (dolist (estrategia estrategias)
      (with-open-file (flujo (merge-pathnames (format nil "~a.py" (estrategias::estrategia-nombre estrategia))
                                              carpeta)
                             :direction :output :if-exists :supersede :external-format :utf-8)
        (write-string (programa-de estrategia modelo) flujo)))
    (with-open-file (flujo (merge-pathnames "prueba.py" carpeta)
                           :direction :output :external-format :utf-8)
      (format flujo "~a~%~a~%" *correr* guion))
    (ejecutar-python carpeta "prueba.py")))

(defparameter *pequeno* "
(def-consulta en-martes ()
  :itera-sobre (u fila)
  :comprueba (op-igual (dia u) martes)
  :operacion (suma 1))
(def-consulta choque ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                   (op-igual (turno a) (turno b))
                   (op-distinto (sesion a) (sesion b)))
  :operacion (suma 1))
(def-consulta con-duracion ()
  :itera-sobre (u fila)
  :comprueba (op-mayor (duracion (sesion u)) 0)
  :operacion (suma 1))
(def-consulta en-primer-turno ()
  :itera-sobre (u fila)
  :comprueba (op-igual (orden (turno u)) 1)
  :operacion (suma 1))
(def-nppq r-choque (op-mayor (choque) 0))
(def-nppq r-martes (op-mayor (en-martes) 0))
(def-tqpq r-todas (op-igual (con-duracion) 4))
(def-ndpq r-temprano (op-mayor (en-primer-turno) 0) :peso 2)
"
  "Cuatro sesiones en tres días y dos turnos: sin martes ni choques, y mejor fuera del primer turno.")

(defun modelo-pequeno ()
  "Construye el modelo del dominio de prueba con las restricciones de *PEQUENO*."
  (modelo-de *pequeno* '("r-choque" "r-martes" "r-todas" "r-temprano")))
