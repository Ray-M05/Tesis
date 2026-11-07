(defpackage :pruebas-analisis
  (:use :cl :dsl :dsl-ast :orquestacion :analisis)
  (:import-from :analisis
                #:iteradores-de #:tipos-de-slots #:dominios-de-parametros #:exigir-tipos
                #:tipo-de #:decision-de #:decisiones-de #:papel-de #:simetrica-p
                #:clasificar-consulta #:normalizar-restriccion
                #:referencias #:orden-topologico))

(in-package :pruebas-analisis)

(defparameter *base* "
(def-mixin tiene-nombre () (nombre))
(def-entidad dia (tiene-nombre) (orden))
(def-entidad turno () (orden))
(def-entidad profesor (tiene-nombre))
(def-entidad ausencia () (profesor dia))
(def-entidad sesion () (profesor))
(def-comb fila (sesion dia turno))
(def-dia lunes \"Lunes\" 1)
(def-dia martes \"Martes\" 2)
(def-turno t1 1)
(def-profesor ana \"Ana\")
(def-ausencia a1 ana lunes)
(def-sesion s1 ana)
(def-sesion s2 ana)
(def-consulta q ()
  :itera-sobre (u fila)
  :comprueba (op-igual (orden (dia u)) 1)
  :operacion (suma 1))
(def-consulta q2 ()
  :itera-sobre (u fila)
  :comprueba (op-igual (orden (dia u)) 2)
  :operacion (suma 1))
(def-consulta q-suma ()
  :itera-sobre (u fila)
  :comprueba (op-igual (orden (dia u)) 2)
  :operacion (suma (orden (dia u))))
(def-consulta del-dia (p d)
  :itera-sobre (u fila)
  :comprueba (op-y (op-igual (profesor (sesion u)) p) (op-igual (dia u) d))
  :operacion (suma 1))
")

(defun problema-de (texto &optional (restricciones '("r")))
  "Carga el dominio base con TEXTO, y un problema con las RESTRICCIONES nombradas."
  (pruebas-dsl::carga
   (format nil "~a~a~%(def-problema el-problema :combinacion fila :identidad sesion ~
                :variables (dia turno) :restricciones (~{~a~^ ~}))"
           *base* texto restricciones)))

(defun consultas-de (problema)
  "Clasifica las consultas derivadas del problema, en orden de aparición."
  (loop for (nodo . parametros) in (dominios-de-parametros problema)
        collect (clasificar-consulta nodo parametros problema)))

(defun restricciones-de (problema)
  "Normaliza las restricciones del problema."
  (let ((consultas (consultas-de problema)))
    (mapcar (lambda (nodo) (normalizar-restriccion nodo consultas problema))
            (problema-restricciones problema))))

(defun comprobar-tipos (problema)
  "Hace todas las comprobaciones de tipos de un problema."
  (exigir-tipos problema (tipos-de-slots problema) (dominios-de-parametros problema)))

(defun rechaza-tipos (texto restricciones &rest fragmentos)
  "Exige que los tipos de TEXTO se rechacen con un mensaje que contenga los FRAGMENTOS."
  (handler-case (progn (comprobar-tipos (problema-de texto restricciones))
                       (error "No se rechazó: ~a" texto))
    (error-dsl (condicion)
      (let ((mensaje (princ-to-string condicion)))
        (dolist (fragmento fragmentos)
          (assert (search fragmento mensaje) ()
                  "El mensaje «~a» no contiene «~a»" mensaje fragmento))))))

(defun nombres (arbol)
  "Convierte los símbolos de un árbol en sus nombres, para comparar entre paquetes."
  (cond ((null arbol) nil)
        ((symbolp arbol) (symbol-name arbol))
        ((consp arbol) (cons (nombres (car arbol)) (nombres (cdr arbol))))
        (t arbol)))

(defun clase-de (objeto)
  "Devuelve el nombre de la clase de OBJETO."
  (class-name (class-of objeto)))

(defparameter *problemas* (make-hash-table :test #'equal))

(defun problema-real (dominio)
  "Carga una sola vez uno de los cinco dominios."
  (or (gethash dominio *problemas*)
      (setf (gethash dominio *problemas*)
            (cargar-dominio (merge-pathnames (format nil "dominios/~a/dominio.lisp" dominio)
                                             pruebas-dsl::*raiz*)))))

(defparameter *esperado*
  '(("tv"
     ("SIN-MISMO-TIPO-CONSECUTIVO" prohibicion "ADYACENTES-MISMO-TIPO" relacion-ordenada ("PROGRAMA"))
     ("MINIMIZAR-REPETICION-DE-TIPO" minimax "CONSECUTIVOS-POR-CANAL" relacion-ordenada ("PROGRAMA")))
    ("tesis"
     ("SIN-CONFLICTOS-DE-HORARIO" prohibicion "CONFLICTOS-DE-HORARIO" choque-por-parejas
      ("FECHA" "MOMENTO"))
     ("UN-LOCAL-POR-DEFENSA" prohibicion "COLISIONES-DE-LOCAL" choque-por-parejas
      ("LOCAL" "FECHA" "MOMENTO"))
     ("MINIMIZAR-CARGA-MAXIMA" minimax "DIAS-ASISTIDOS" agrupacion ("FECHA")))
    ("docentes"
     ("UN-AULA-POR-PROFESOR" prohibicion "COLISIONES-DE-PROFESOR" choque-por-parejas
      ("DIA" "TURNO" "AULA"))
     ("UN-GRUPO-POR-AULA" prohibicion "COLISIONES-DE-AULA" choque-por-parejas
      ("AULA" "DIA" "TURNO"))
     ("UNA-CLASE-POR-GRUPO" prohibicion "COLISIONES-DE-GRUPO" choque-por-parejas
      ("DIA" "TURNO" "AULA"))
     ("MINIMIZAR-DIAS-DE-VIAJE" minimax "DIAS-DE-PROFESOR" agrupacion ("DIA")))
    ("seder"
     ("SOLO-TURNOS-DISPONIBLES" prohibicion "CLASES-EN-TURNO-NO-DISPONIBLE" cruce-contra-tabla
      ("TURNO"))
     ("LA-BRIGADA-CABE" prohibicion "BRIGADAS-QUE-NO-CABEN" filtro-de-fila ("INSTALACION"))
     ("UNA-BRIGADA-POR-INSTALACION" prohibicion "COLISIONES-DE-INSTALACION" choque-por-parejas
      ("INSTALACION" "TURNO"))
     ("UN-PROFESOR-POR-TURNO" prohibicion "COLISIONES-DE-PROFESOR" choque-por-parejas ("TURNO"))
     ("EQUILIBRAR-INSTALACIONES" minimax "BRIGADAS-DE-LA-INSTALACION" agrupacion ("INSTALACION"))
     ("EQUILIBRAR-TURNOS" minimax "BRIGADAS-DEL-TURNO" agrupacion ("TURNO")))
    ("saul"
     ("UNA-SESION-POR-GRUPO" prohibicion "COLISIONES-DE-GRUPO" choque-por-parejas ("DIA" "TURNO"))
     ("UNA-SESION-POR-PROFESOR" prohibicion "COLISIONES-DE-PROFESOR" choque-por-parejas
      ("DIA" "TURNO"))
     ("SIN-REPETIR-ASIGNATURA-EN-EL-DIA" prohibicion "REPETICIONES-EN-EL-DIA" choque-por-parejas
      ("DIA"))
     ("TURNO-DOBLE-CONSECUTIVO" prohibicion "DOBLES-NO-CONSECUTIVOS" relacion-ordenada
      ("DIA" "TURNO"))
     ("SIN-CLASES-EL-DIA-DE-PREPARACION" prohibicion "SESIONES-EN-DIA-DE-PREPARACION" filtro-de-fila
      ("DIA"))
     ("EDUCACION-FISICA-TEMPRANO" prohibicion "EDUCACION-FISICA-FUERA-DE-HORARIO" filtro-de-fila
      ("TURNO"))
     ("TARDE-SOLO-PARA-LAS-AUTORIZADAS" prohibicion "SESIONES-DE-TARDE-NO-AUTORIZADAS" filtro-de-fila
      ("TURNO"))
     ("CONTRATADO-SOLO-SUS-DIAS" prohibicion "SESIONES-EN-DIA-SIN-ASISTENCIA" cruce-contra-tabla
      ("DIA"))
     ("FRECUENCIA-EXACTA" cota "SESIONES-DEL-PLAN" agrupacion ())
     ("EVITAR-PRIMER-TURNO-A-LOS-LEJANOS" prohibicion "PRIMEROS-TURNOS-DE-LEJANOS" filtro-de-fila
      ("TURNO"))
     ("TOPE-DIARIO-DE-PROFESOR" cota "SESIONES-DEL-DIA" agrupacion ("DIA"))))
  "Lo que se espera de cada restricción: nombre sin prefijo, forma, consulta, familia y decisiones.")
