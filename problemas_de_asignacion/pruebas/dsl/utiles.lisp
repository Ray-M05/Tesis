(defpackage :pruebas-dsl
  (:use :cl :dsl-ast :orquestacion))

(in-package :pruebas-dsl)

(defun carga (texto &optional (nombre "prueba"))
  "Carga un dominio dado como texto y falla ante cualquier aviso."
  (handler-bind ((warning (lambda (aviso) (error "Aviso al cargar: ~a" aviso))))
    (with-input-from-string (flujo texto)
      (cargar-flujo flujo nombre))))

(defun simbolos (lista)
  "Convierte una lista de símbolos en sus nombres, para comparar entre paquetes."
  (mapcar #'symbol-name lista))
