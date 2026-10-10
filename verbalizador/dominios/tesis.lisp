;; =====================================================================
;; DOMINIO: HORARIO DE DEFENSAS DE TESIS
;; =====================================================================
;; Este archivo solo DECLARA. No carga infraestructura, no genera codigo
;; y no imprime nada. El orden de carga y los efectos viven en run.lisp,
;; que recorre dominios/*.lisp automaticamente.
;;
;; Convencion: el archivo dominios/tesis.lisp declara problema-tesis.
;; =====================================================================

;; =====================================================================
;; MIXINS
;; =====================================================================

(defclass* tiene-nombre ()
  (nombre))


;; =====================================================================
;; ENTIDADES DEL DOMINIO
;; =====================================================================

;; Grado académico (enumeración)
(def-entidad grado () (id))

;; Personas
(def-entidad profesor   (tiene-nombre) (grado))
(def-entidad estudiante (tiene-nombre))

;; Tribunal: agrupa las personas que evalúan una defensa
(def-entidad tribunal ()
  (estudiante tutor oponente presidente vocal secretario))

;; Recursos de tiempo y espacio
(def-entidad fecha   () (dia mes))
(def-entidad momento () (hora))
(def-entidad local   (tiene-nombre))


;; =====================================================================
;; ENTIDAD COMBINACIÓN: ASIGNACIÓN
;; Una asignación = un tribunal + cuándo y dónde defiende
;; =====================================================================

(def-comb asignacion
  (tribunal fecha momento local))


;; =====================================================================
;; CONSULTAS Y RESTRICCIONES
;; =====================================================================

;; Auxiliar: ¿está el profesor prof en el tribunal de la asignación asig?
(def-consulta profesor-en-tribunal (prof asig)
  :comprueba
  (op-or (op-igual (tutor      (tribunal asig)) prof)
             (op-igual (oponente   (tribunal asig)) prof)
             (op-igual (presidente (tribunal asig)) prof)
             (op-igual (vocal      (tribunal asig)) prof)
             (op-igual (secretario (tribunal asig)) prof)))


;; Consulta: cuántas veces un profesor está en dos defensas simultáneas
(def-consulta conflictos-de-horario ()
  :itera-sobre (p profesor) (a1 asignacion) (a2 asignacion)
  :comprueba
  (op-and (profesor-en-tribunal p a1)
              (profesor-en-tribunal p a2)
              (op-igual    (fecha    a1) (fecha    a2))
              (op-igual    (momento  a1) (momento  a2))
              (op-distinto (tribunal a1) (tribunal a2)))
  :operacion suma
  :devuelve 1)

;; Restricción DURA (nppq): ningún profesor puede estar en dos defensas a la vez
(defvar restriccion-sin-conflictos-de-horario
  (def-nppq (op-mayor conflictos-de-horario 0)))


;; Consulta: cuántas defensas comparten local, fecha y momento
(def-consulta colisiones-de-local ()
  :itera-sobre (a1 asignacion) (a2 asignacion)
  :comprueba
  (op-and (op-igual    (local   a1) (local   a2))
          (op-igual    (fecha   a1) (fecha   a2))
          (op-igual    (momento a1) (momento a2))
          (op-distinto (tribunal a1) (tribunal a2)))
  :operacion suma
  :devuelve 1)

;; Restricción DURA (nppq): no puede haber dos defensas en el mismo local al mismo tiempo
(defvar restriccion-un-local-por-defensa
  (def-nppq (op-mayor colisiones-de-local 0)))


;; Consulta: cuántos días distintos asiste un profesor
(def-consulta dias-asistidos (prof)
  :itera-sobre (asig asignacion)
  :comprueba (profesor-en-tribunal prof asig)
  :operacion contar-distintos-dias
  :devuelve n-dias)

;; Restricción BLANDA (minimizar): minimizar la carga del profesor que más días asiste
(defvar restriccion-minimizar-carga-maxima
  (def-minimizar dias-asistidos profesor))


;; =====================================================================
;; DATOS CONCRETOS
;; Agrega aquí todas las instancias de tu problema real.
;; El generador las usa para construir el horario en la metaheurística.
;; =====================================================================

;; -- Grados --
(def-grado lic  "Lic")
(def-grado msc  "MSc")
(def-grado dr  "Dr")
(def-grado dra  "Dra")
(def-grado drc  "DrC")
(def-grado drac "DraC")

;; -- Profesores --
(def-profesor prof-fernandez-montoto    "Carmen T. Fernandez Montoto"         msc)
(def-profesor prof-fernandez-oliva      "Alberto Fernandez Oliva"             dr)
(def-profesor prof-labourdette          "Alejandro Labourdette-Lantigua Soto" lic)
(def-profesor prof-gonzalez-duran       "Dennis Daniel Gonzalez Duran"        lic)
(def-profesor prof-garcia-armenteros    "Aracelys Garcia Armenteros"          msc)
(def-profesor prof-monzon               "Alejandra Monzon Pena"               lic)
(def-profesor prof-rodriguez-flores     "Fernando Raul Rodriguez Flores"      msc)
(def-profesor prof-noris                "Amanada Noris Hernandez"             lic)
(def-profesor prof-manzano              "Kevin Manzano Rodriguez"             lic)
(def-profesor prof-abad                 "Daniel Abad Fundora"                 lic)
(def-profesor prof-garcia-gomez         "Rodrigo Garcia Gomez"                lic)
(def-profesor prof-gonzalez-martinez    "Lazaro Daniel Gonzalez Martinez"     lic)
(def-profesor prof-guaty                "David Guaty Dominguez"               lic)
(def-profesor prof-gonzalez-gonzales    "Celia T. Gonzalez Gonzales"          msc)
(def-profesor prof-morales              "Wilfredo Morales Lezca"              msc)
(def-profesor prof-marrero              "Ayme Marrero Severo"                 dra)
(def-profesor prof-campbell             "Joanna Campbell Amos"                msc)
(def-profesor prof-valdes               "Daniel Alejandro Valdes Perez"       lic)
(def-profesor prof-beltran              "Alejandro Beltran Varela"            lic)
(def-profesor prof-marti                "Roberto Marti Cedeno"                lic)
(def-profesor prof-baguer               "Marta Lourdes Baguer Diaz-Romanach"  drac)
(def-profesor prof-castro               "Lydia Amalia Castro Odio"            drac)
(def-profesor prof-sanchez              "Alejandro Sanchez Castellanos"       drc)
(def-profesor prof-gonzalez-munoz       "Ana Paula Gonzalez Munoz"            lic)
(def-profesor prof-piad                 "Alejandro Piad Morfis"               drc)
(def-profesor prof-perez-acosta         "Madeylis Maria Perez Acosta"         msc)
(def-profesor prof-perez-martinez       "Juan Miguel Perez Martinez"          lic)
(def-profesor prof-fundora              "Gabriel Fundora"                     dr)
(def-profesor prof-ariel-gonzalez       "Ariel Gonzalez Gomez"                lic)
(def-profesor prof-ortiz                "Rocio Ortiz Gancedo"                 lic)
(def-profesor prof-sabater              "Merling Sabater Ramirez"             lic)
(def-profesor prof-muniz                "Carlos David Muniz Chall"            lic)
(def-profesor prof-toledo               "Daniel Toledo Martinez"              lic)
(def-profesor prof-rodriguez-sanchez    "Javier Rodriguez Sanchez"            lic)
(def-profesor prof-hernandez-rodriguez  "Gabriel Hernandez Rodriguez"         lic)

;; -- Estudiantes --
(def-estudiante est-alonso              "Angel Daniel Alonso Guevara")
(def-estudiante est-hernandez-c         "Adrian Hernandez Castellanos")
(def-estudiante est-martir              "Laura Martir Beltran")
(def-estudiante est-perez-calvo         "Noel Perez Calvo")
(def-estudiante est-hernandez-aparicio  "Claudia Hernandez Perez y Joel Aparicio Tamayo")
(def-estudiante est-hernandez-cubilla   "Dario Hernandez Cubilla")
(def-estudiante est-matos               "Richard Alejandro Matos Arderi")
(def-estudiante est-forsythe            "Melani Forsythe Matos")
(def-estudiante est-campver             "Mauro Eduardo Campver Barrios")
(def-estudiante est-leyva               "Jose Miguel Leyva De La Cruz")
(def-estudiante est-arteche             "Jossue Arteche Munoz")
(def-estudiante est-valiente            "Amalia Beatriz Valiente Hinojosa")
(def-estudiante est-amat                "Luis Ernesto Amat Cardenas")

;; -- Tribunales (uno por defensa) --
;;   orden de argumentos: estudiante tutor oponente presidente vocal secretario
;;   Cuando hay co-tutores se indica el primero en el slot tutor.
(def-tribunal trib-alonso
  est-alonso
  prof-fernandez-montoto prof-garcia-armenteros prof-fernandez-oliva
  prof-gonzalez-duran    prof-labourdette)

(def-tribunal trib-hernandez-c
  est-hernandez-c
  prof-monzon            prof-garcia-gomez      prof-noris
  prof-abad              prof-manzano)

(def-tribunal trib-martir
  est-martir
  prof-monzon            prof-garcia-gomez      prof-noris
  prof-abad              prof-manzano)

(def-tribunal trib-perez-calvo
  est-perez-calvo
  prof-rodriguez-flores  prof-guaty             prof-garcia-gomez
  prof-monzon            prof-gonzalez-martinez)

(def-tribunal trib-hernandez-aparicio
  est-hernandez-aparicio
  prof-gonzalez-gonzales prof-beltran           prof-marrero
  prof-valdes            prof-campbell)

(def-tribunal trib-hernandez-cubilla
  est-hernandez-cubilla
  prof-garcia-armenteros prof-labourdette       prof-marrero
  prof-beltran           prof-marti)

(def-tribunal trib-matos
  est-matos
  prof-gonzalez-gonzales prof-garcia-armenteros prof-morales
  prof-beltran           prof-marti)

(def-tribunal trib-forsythe
  est-forsythe
  prof-baguer            prof-rodriguez-sanchez prof-sanchez
  prof-gonzalez-duran    prof-gonzalez-munoz)

(def-tribunal trib-campver
  est-campver
  prof-baguer            prof-rodriguez-flores  prof-piad
  prof-gonzalez-duran    prof-gonzalez-munoz)

(def-tribunal trib-leyva
  est-leyva
  prof-beltran           prof-garcia-armenteros prof-noris
  prof-fundora           prof-perez-martinez)

(def-tribunal trib-arteche
  est-arteche
  prof-rodriguez-flores  prof-ariel-gonzalez    prof-piad
  prof-abad              prof-garcia-gomez)

(def-tribunal trib-valiente
  est-valiente
  prof-rodriguez-flores  prof-monzon            prof-rodriguez-sanchez
  prof-sabater           prof-ortiz)

(def-tribunal trib-amat
  est-amat
  prof-marti             prof-toledo            prof-piad
  prof-labourdette       prof-muniz)

;; -- Fechas disponibles (dia mes) --
(def-fecha fecha-05-jun  5 6)
(def-fecha fecha-08-jun  8 6)
(def-fecha fecha-10-jun 10 6)

;; -- Momentos disponibles (hora como entero hhmm) --
(def-momento momento-0930   930)
(def-momento momento-1000  1000)
(def-momento momento-1030  1030)
(def-momento momento-1130  1130)
(def-momento momento-1200  1200)
(def-momento momento-1230  1230)
(def-momento momento-1330  1330)

;; -- Locales disponibles --
(def-local local-postgrado   "Postgrado")
(def-local local-decanato    "Salon decanato")
(def-local local-francofonia "Francofonia")
(def-local local-francofomia "Francofomia")


;; =====================================================================
;; DEFINICIÓN DEL PROBLEMA
;; =====================================================================

(defvar problema-tesis
  (def-problema-horario
    ;; Entidad combinación: lo que constituye una "fila" del horario
    :entidad-horario   'asignacion
    ;; Slot fijo (identidad): hay una asignación POR tribunal
    :slot-identidad    'tribunal
    ;; Slots variables: el GA elige estos de entre los pools de arriba
    :slots-variables   '(fecha momento local)
    ;; Consultas con nodo AST (defvar con :itera-sobre)
    :consultas         '(conflictos-de-horario colisiones-de-local dias-asistidos)
    ;; Restricciones simples / duras
    :restricciones-duras   '(restriccion-sin-conflictos-de-horario
                             restriccion-un-local-por-defensa)
    ;; Restricciones débiles / blandas
    :restricciones-blandas '(restriccion-minimizar-carga-maxima)
    ;; Pesos del modelo matemático
    :peso-dura   1000
    :peso-blanda    1))
