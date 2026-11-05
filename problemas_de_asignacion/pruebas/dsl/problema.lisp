(in-package :pruebas-dsl)

(defparameter *dominio-completo* "
(def-entidad dia () (orden))
(def-entidad turno () (orden))
(def-entidad sesion () (numero))
(def-comb fila (sesion dia turno))
(def-dia lunes 1)
(def-dia martes 2)
(def-dia miercoles 3)
(def-turno primero 1)
(def-sesion s1 1)
(def-consulta q () :itera-sobre (f fila) :comprueba (op-igual 1 1) :operacion (suma 1))
(def-ndpq zeta (op-mayor (q) 0))
(def-nppq alfa (op-mayor (q) 0))
(def-sbqp medio (op-mayor (q) 0))
(def-problema mi-problema
  :combinacion fila
  :identidad sesion
  :variables (turno dia)
  :restricciones (zeta alfa medio))
")

(let ((problema (carga *dominio-completo*)))
  (assert (typep problema 'problema))
  (assert (eq problema (de-dominio "MI-PROBLEMA")))
  (assert (equal (symbol-name (problema-nombre problema)) "MI-PROBLEMA"))
  (assert (equal (symbol-name (problema-combinacion problema)) "FILA"))
  (assert (equal (symbol-name (problema-identidad problema)) "SESION"))
  (assert (equal (simbolos (problema-variables problema)) '("TURNO" "DIA")))
  ;; Orden escrito de restricciones, entidades e instancias
  (assert (equal (mapcar (lambda (r) (symbol-name (slot-value r 'nombre)))
                         (problema-restricciones problema))
                 '("ZETA" "ALFA" "MEDIO")))
  (assert (equal (simbolos (problema-entidades problema)) '("DIA" "TURNO" "SESION" "FILA")))
  (assert (equal (simbolos (mapcar #'car (problema-instancias problema)))
                 '("DIA" "TURNO" "SESION" "FILA")))
  (assert (equal (simbolos (cdr (first (problema-instancias problema))))
                 '("LUNES" "MARTES" "MIERCOLES")))
  (assert (null (cdr (fourth (problema-instancias problema)))))
  (assert (equal (simbolos (cdr (fourth (problema-slots problema))))
                 '("SESION" "DIA" "TURNO"))))

;; La foto no comparte estructura con los registros
(let* ((dsl-ast::*entidades* '(a))
       (tabla (make-hash-table))
       (lista (list 1 2)))
  (setf (gethash 'a tabla) lista)
  (let ((foto (dsl-ast::foto-de tabla)))
    (assert (equal (cdr (first foto)) '(1 2)))
    (assert (not (eq (cdr (first foto)) lista)))))

(defparameter *datos* "
(def-entidad dia () (orden))
(def-entidad turno () (orden))
(def-entidad vacia () (orden))
(def-comb fila (dia turno))
(def-comb fila-vacia (dia vacia))
(def-dia lunes 1)
(def-turno primero 1)
(def-nppq r (op-mayor 1 0))
")

(flet ((rechaza-datos (texto &rest fragmentos)
         (apply #'rechaza (concatenate 'string *datos* texto) fragmentos)))
  ;; Claves
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (turno))"
                 "P" ":RESTRICCIONES")
  (rechaza-datos "(def-problema p :identidad dia :variables (turno) :restricciones ())"
                 "P" ":COMBINACION")
  (rechaza-datos "(def-problema p :combinacion fila :variables (turno) :restricciones ())"
                 "P" ":IDENTIDAD")
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :restricciones ())"
                 "P" ":VARIABLES")
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (turno)
                    :restricciones () :consultas ())"
                 "P" ":CONSULTAS")
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (turno)
                    :restricciones () :peso-dura 1000)"
                 "P" ":PESO-DURA")
  (rechaza-datos "(def-problema list :combinacion fila :identidad dia :variables (turno)
                    :restricciones ())"
                 "LIST")
  ;; Combinación
  (rechaza-datos "(def-problema p :combinacion dia :identidad dia :variables (turno)
                    :restricciones ())"
                 "P" "DIA")
  (rechaza-datos "(def-problema p :combinacion nada :identidad dia :variables (turno)
                    :restricciones ())"
                 "P" "NADA")
  ;; Componentes
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables ()
                    :restricciones ())"
                 "P" "FILA")
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (turno vacia)
                    :restricciones ())"
                 "P" "FILA")
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (vacia)
                    :restricciones ())"
                 "P" "FILA")
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (turno turno)
                    :restricciones ())"
                 "P" "FILA")
  ;; Dominios vacíos
  (rechaza-datos "(def-problema p :combinacion fila-vacia :identidad vacia :variables (dia)
                    :restricciones ())"
                 "P" "VACIA")
  (rechaza-datos "(def-problema p :combinacion fila-vacia :identidad dia :variables (vacia)
                    :restricciones ())"
                 "P" "VACIA")
  ;; Restricciones
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (turno)
                    :restricciones (nada))"
                 "P" "NADA")
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (turno)
                    :restricciones (lunes))"
                 "P" "LUNES")
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (turno)
                    :restricciones (r r))"
                 "P" "R")
  ;; Dos problemas
  (rechaza-datos "(def-problema p :combinacion fila :identidad dia :variables (turno)
                    :restricciones ())
                  (def-problema q :combinacion fila :identidad dia :variables (turno)
                    :restricciones ())"
                 "Q" "P"))
