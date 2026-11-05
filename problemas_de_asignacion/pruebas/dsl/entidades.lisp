(in-package :pruebas-dsl)

;; Carga y foto
(let ((problema (carga-base "")))
  (assert (typep problema 'problema))
  (assert (equal (simbolos (problema-entidades problema))
                 '("DIA" "PROFESOR" "SESION" "FILA")))
  (assert (typep (de-dominio "DIA") 'ref-gen-entidad))
  (assert (equal (slot-value (de-dominio "LUNES") (find-symbol "NOMBRE" "DOMINIO-PRUEBA"))
                 "Lunes"))
  (assert (= (slot-value (de-dominio "LUNES") (find-symbol "ORDEN" "DOMINIO-PRUEBA")) 1)))

;; Una instancia puede referirse a otra
(carga-base "")
(assert (eq (slot-value (de-dominio "S1") (find-symbol "PROFESOR" "DOMINIO-PRUEBA"))
            (de-dominio "ANA")))

;; Un accesor construye un nodo, y es uno solo aunque el slot se repita
(carga-base "(def-entidad otra () (orden nombre))")
(let ((nodo (funcall (find-symbol "ORDEN" "DOMINIO-PRUEBA") 'x)))
  (assert (typep nodo 'acceso-a-atributo-de-entidad))
  (assert (eq (slot-value nodo 'entidad) 'x))
  (assert (equal (symbol-name (slot-value nodo 'atributo)) "ORDEN")))

;; El constructor de una entidad vive en el paquete del dominio
(carga "(def-entidad clase () (a))
        (def-clase c1 1)
        (def-entidad otra () (b))
        (def-comb fila (clase otra))
        (def-otra o1 2)
        (def-problema p :combinacion fila :identidad clase :variables (otra) :restricciones ())")
(assert (eq (symbol-package (find-symbol "DEF-CLASE" "DOMINIO-PRUEBA"))
            (find-package "DOMINIO-PRUEBA")))
(assert (fboundp 'dsl-ast::def-clase))
(assert (macro-function 'dsl-ast::def-clase))
(assert (not (eq (find-symbol "DEF-CLASE" "DOMINIO-PRUEBA") 'dsl-ast::def-clase)))

;; Una combinación no tiene constructor
(carga-base "")
(assert (null (find-symbol "DEF-FILA" "DOMINIO-PRUEBA")))

;; Dos dominios con la misma entidad no se mezclan
(flet ((dominio (slot instancia)
         (format nil "(def-entidad profesor () (~a))
                      (def-entidad dia () (n))
                      (def-comb fila (profesor dia))
                      (def-profesor ~a 1)
                      (def-dia d1 1)
                      (def-problema p :combinacion fila :identidad profesor
                        :variables (dia) :restricciones ())"
                 slot instancia)))
  (let ((uno (carga (dominio "grado" "ana") "uno"))
        (dos (carga (dominio "edad" "luis") "dos")))
    (assert (equal (simbolos (cdr (first (problema-slots uno)))) '("GRADO")))
    (assert (equal (simbolos (cdr (first (problema-slots dos)))) '("EDAD")))
    (assert (equal (simbolos (cdr (first (problema-instancias uno)))) '("ANA")))
    (assert (equal (simbolos (cdr (first (problema-instancias dos)))) '("LUIS")))
    (assert (not (eq (find-package "DOMINIO-UNO") (find-package "DOMINIO-DOS"))))))

;; Cargar dos veces el mismo dominio no choca
(carga-base "")
(carga-base "")

;; cargar-dominio lee un archivo en UTF-8 y usa el nombre de la carpeta
(cargar-dominio (merge-pathnames "archivo/dominio.lisp" *load-truename*))
(assert (equal (slot-value (de-dominio "MIERCOLES" "DOMINIO-ARCHIVO")
                           (find-symbol "NOMBRE" "DOMINIO-ARCHIVO"))
               "Miércoles"))

;; Rechazos
(rechaza "(def-entidad consulta () (a))" "DEF-CONSULTA")
(rechaza "(def-entidad problema () (a))" "DEF-PROBLEMA")
(rechaza "(def-entidad list () (a))" "LIST")
(rechaza "(def-entidad cosa () (position))" "POSITION")
(rechaza "(def-entidad cosa () (a a))" "COSA" "A")
(rechaza "(def-entidad cosa (mixin-falso) (a))" "COSA" "MIXIN-FALSO")
(rechaza "(defclass* list () (a))" "LIST")
(rechaza "(defclass* mixin (otro) (a))" "MIXIN" "OTRO")
(rechaza "(def-comb list (a b))" "LIST")
(rechaza-base "(def-entidad dia () (a))" "DIA")
(rechaza-base "(def-consulta q () :itera-sobre (u fila)
                 :comprueba (op-igual 1 1) :operacion (suma 1))
               (def-entidad cosa () (q))"
              "COSA" "Q")

;; Instancias
(rechaza-base "(def-dia viernes)" "VIERNES" "DIA" "0" "2")
(rechaza-base "(def-dia viernes \"V\" 5 9)" "VIERNES" "3" "2")
(rechaza-base "(def-dia lunes \"L\" 9)" "LUNES")
(rechaza-base "(def-profesor lunes \"L\")" "LUNES")
(rechaza-base "(def-dia dia \"L\" 9)" "DIA")
(rechaza-base "(def-dia list \"L\" 9)" "LIST")

;; Cargador
(rechaza *base* "prueba" "def-problema")
