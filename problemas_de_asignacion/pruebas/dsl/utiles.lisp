(defpackage :pruebas-dsl
  (:use :cl :dsl-ast :orquestacion))

(in-package :pruebas-dsl)

(defparameter *base* "
(def-mixin tiene-nombre () (nombre))
(def-entidad dia (tiene-nombre) (orden))
(def-entidad profesor (tiene-nombre))
(def-entidad sesion () (profesor))
(def-comb fila (sesion dia))
(def-dia lunes \"Lunes\" 1)
(def-dia martes \"Martes\" 2)
(def-profesor ana \"Ana\")
(def-sesion s1 ana)
")

(defparameter *cierre* "
(def-problema el-problema
  :combinacion fila :identidad sesion :variables (dia) :restricciones ())
")

(defun carga (texto &optional (nombre "prueba"))
  "Carga un dominio dado como texto y falla ante cualquier aviso."
  (handler-bind ((warning (lambda (aviso) (error "Aviso al cargar: ~a" aviso))))
    (with-input-from-string (flujo texto)
      (cargar-flujo flujo nombre))))

(defun carga-base (texto)
  "Carga el dominio base con TEXTO añadido antes de def-problema."
  (carga (concatenate 'string *base* texto *cierre*)))

(defun rechaza (texto &rest fragmentos)
  "Comprueba que TEXTO señala error-dsl y que el mensaje contiene los FRAGMENTOS."
  (handler-case (progn (carga texto)
                       (error "No se rechazó: ~a" texto))
    (error-dsl (condicion)
      (let ((mensaje (princ-to-string condicion)))
        (dolist (fragmento fragmentos)
          (assert (search fragmento mensaje) ()
                  "El mensaje «~a» no contiene «~a»" mensaje fragmento))))))

(defun rechaza-base (texto &rest fragmentos)
  "Como rechaza, sobre el dominio base."
  (apply #'rechaza (concatenate 'string *base* texto) fragmentos))

(defun de-dominio (nombre &optional (paquete "DOMINIO-PRUEBA"))
  "Devuelve el valor de la variable NOMBRE en el paquete del dominio."
  (symbol-value (find-symbol nombre paquete)))

(defun simbolos (lista)
  "Convierte una lista de símbolos en sus nombres, para comparar entre paquetes."
  (mapcar #'symbol-name lista))
