;; =====================================================================
;; DOMINIO: HORARIO DOCENTE UNIVERSITARIO
;; Facultad de Matemática y Computación — 1.er año Ciencia de la Computación
;; =====================================================================
;; Este archivo solo DECLARA. No carga infraestructura, no genera codigo
;; y no imprime nada. El orden de carga y los efectos viven en run.lisp,
;; que recorre dominios/*.lisp automaticamente.
;;
;; Convencion: el archivo dominios/docentes.lisp declara problema-docentes.
;; =====================================================================

;; =====================================================================
;; MIXINS
;; =====================================================================

(defclass* tiene-nombre ()
  (nombre))


;; =====================================================================
;; ENTIDADES ENUMERADAS
;; =====================================================================

;; Días lectivos (nombre del día para visualización)
(def-entidad dia (tiene-nombre))

;; Turnos (nombre del turno para visualización)
(def-entidad turno (tiene-nombre))


;; =====================================================================
;; ENTIDADES DEL DOMINIO
;; =====================================================================

;; Asignatura: tiene nombre y frecuencia semanal de impartición
(def-entidad asignatura (tiene-nombre) (frecuencia))

;; Profesor que imparte clases
(def-entidad profesor (tiene-nombre))

;; Aula donde se celebra la clase
(def-entidad aula (tiene-nombre))

;; Grupo de estudiantes que recibe la clase
(def-entidad grupo (tiene-nombre))

;; Sesión: unidad de programación — qué asignatura, a qué grupo, con qué profesor.
;; Por cada vez que la asignatura debe impartirse a la semana se crea una sesión distinta.
;; Ejemplo: Filosofía C con frecuencia 2 genera 2 sesiones por grupo.
(def-entidad sesion () (asignatura grupo profesor))


;; =====================================================================
;; ENTIDAD COMBINACIÓN: CLASE
;; Una clase = sesión + cuándo (día, turno) + dónde (aula)
;; =====================================================================

(def-comb clase (sesion aula dia turno))


;; =====================================================================
;; CONSULTAS Y RESTRICCIONES
;; =====================================================================

;; ── Restricciones duras ────────────────────────────────────────────

;; Colisiones de profesor: mismo profesor en distinta aula al mismo tiempo.
;; Se itera explicitamente sobre (p profesor) para que 'profesor' quede
;; registrado como dominio en el Horario (necesario para def-minimizar).
(def-consulta colisiones-de-profesor ()
  :itera-sobre (p profesor) (c1 clase) (c2 clase)
  :comprueba
  (op-and (op-igual    (profesor (sesion c1)) p)
          (op-igual    (profesor (sesion c2)) p)
          (op-igual    (dia   c1) (dia   c2))
          (op-igual    (turno c1) (turno c2))
          (op-distinto (aula  c1) (aula  c2)))
  :operacion suma
  :devuelve 1)

(defvar restriccion-un-aula-por-profesor
  (def-nppq (op-mayor colisiones-de-profesor 0)))


;; Colisiones de aula: misma aula con grupos distintos al mismo tiempo
(def-consulta colisiones-de-aula ()
  :itera-sobre (c1 clase) (c2 clase)
  :comprueba
  (op-and (op-igual    (aula  c1) (aula  c2))
          (op-igual    (dia   c1) (dia   c2))
          (op-igual    (turno c1) (turno c2))
          (op-distinto (grupo (sesion c1)) (grupo (sesion c2))))
  :operacion suma
  :devuelve 1)

(defvar restriccion-un-grupo-por-aula
  (def-nppq (op-mayor colisiones-de-aula 0)))


;; Colisiones de grupo: un grupo en dos aulas distintas al mismo tiempo
(def-consulta colisiones-de-grupo ()
  :itera-sobre (c1 clase) (c2 clase)
  :comprueba
  (op-and (op-igual    (grupo (sesion c1)) (grupo (sesion c2)))
          (op-igual    (dia   c1) (dia   c2))
          (op-igual    (turno c1) (turno c2))
          (op-distinto (aula  c1) (aula  c2)))
  :operacion suma
  :devuelve 1)

(defvar restriccion-una-clase-por-grupo
  (def-nppq (op-mayor colisiones-de-grupo 0)))


;; Frecuencia exacta: cuántas sesiones se programan para una asignatura concreta
(def-consulta clases-de-asignatura (asig)
  :itera-sobre (c clase)
  :comprueba   (op-igual (asignatura (sesion c)) asig)
  :operacion   suma
  :devuelve    1)

;; Tiene que pasar que el número de sesiones iguale la frecuencia de cada asignatura
(defvar restriccion-frecuencia-exacta
  (def-tqpq (op-igual clases-de-asignatura (frecuencia asignatura)) asignatura))


;; ── Restricción blanda ─────────────────────────────────────────────

;; Días distintos en que un profesor tiene que impartir clase
(def-consulta dias-de-profesor (prof)
  :itera-sobre (c clase)
  :comprueba   (op-igual (profesor (sesion c)) prof)
  :operacion   contar-distintos-dias
  :devuelve    n-dias)

;; Minimizar el número máximo de días de desplazamiento entre todos los profesores
(defvar restriccion-minimizar-dias-de-viaje
  (def-minimizar dias-de-profesor profesor))


;; =====================================================================
;; DATOS CONCRETOS
;; Primer año de Ciencia de la Computación (C1), 1.er período lectivo
;; =====================================================================

;; ── Días lectivos ──────────────────────────────────────────────────
(def-dia lunes     "Lunes")
(def-dia martes    "Martes")
(def-dia miercoles "Miercoles")
(def-dia jueves    "Jueves")
(def-dia viernes   "Viernes")

;; ── Turnos (6 turnos diarios) ──────────────────────────────────────
(def-turno turno-1 "T1")
(def-turno turno-2 "T2")
(def-turno turno-3 "T3")
(def-turno turno-4 "T4")
(def-turno turno-5 "T5")
(def-turno turno-6 "T6")

;; ── Aulas disponibles ──────────────────────────────────────────────
(def-aula aula-1   "Aula 1")
(def-aula aula-2   "Aula 2")
(def-aula aula-5   "Aula 5")
(def-aula aula-6   "Aula 6")
(def-aula lab-comp "Laboratorio de Computacion")
(def-aula seder    "SEDER")

;; ── Grupos del año C1 ──────────────────────────────────────────────
(def-grupo grupo-c111 "C111")
(def-grupo grupo-c112 "C112")
(def-grupo grupo-c113 "C113")
(def-grupo grupo-c121 "C121")
(def-grupo grupo-c122 "C122")

;; ── Profesores ─────────────────────────────────────────────────────
(def-profesor prof-garcia-f   "Ana Garcia Fernandez")
(def-profesor prof-lopez-r    "Luis Lopez Rodriguez")
(def-profesor prof-martinez-p "Maria Martinez Perez")
(def-profesor prof-hernandez  "Carlos Hernandez Diaz")
(def-profesor prof-gonzalez   "Rosa Gonzalez Blanco")
(def-profesor prof-diaz-m     "Miguel Diaz Morales")

;; ── Asignaturas (nombre, frecuencia semanal) ───────────────────────
(def-asignatura asig-filosofia  "Filosofia C"               2)
(def-asignatura asig-algebra    "Algebra I C"               2)
(def-asignatura asig-am         "Analisis Matematico I C"   2)
(def-asignatura asig-prog       "Programacion C"            1)
(def-asignatura asig-logica     "Logica C"                  1)
(def-asignatura asig-ed-fisica  "Educacion Fisica I"        1)
(def-asignatura asig-algebra-cp "Algebra I CP"              1)
(def-asignatura asig-am-cp      "Analisis Matematico I CP"  1)
(def-asignatura asig-prog-cp    "Programacion CP"           2)
(def-asignatura asig-logica-cp  "Logica CP"                 1)


;; ── Sesiones ───────────────────────────────────────────────────────
;; Por cada sesión que debe impartirse en la semana se crea un defvar de sesión.
;; El sufijo -a / -b distingue las dos ocurrencias semanales (frecuencia 2).

;; Filosofía C — frecuencia 2 por grupo
(def-sesion ses-filo-c111-a asig-filosofia grupo-c111 prof-garcia-f)
(def-sesion ses-filo-c111-b asig-filosofia grupo-c111 prof-garcia-f)
(def-sesion ses-filo-c112-a asig-filosofia grupo-c112 prof-garcia-f)
(def-sesion ses-filo-c112-b asig-filosofia grupo-c112 prof-garcia-f)
(def-sesion ses-filo-c113-a asig-filosofia grupo-c113 prof-garcia-f)
(def-sesion ses-filo-c113-b asig-filosofia grupo-c113 prof-garcia-f)
(def-sesion ses-filo-c121-a asig-filosofia grupo-c121 prof-garcia-f)
(def-sesion ses-filo-c121-b asig-filosofia grupo-c121 prof-garcia-f)
(def-sesion ses-filo-c122-a asig-filosofia grupo-c122 prof-garcia-f)
(def-sesion ses-filo-c122-b asig-filosofia grupo-c122 prof-garcia-f)

;; Álgebra I C — frecuencia 2 por grupo
(def-sesion ses-alg-c111-a asig-algebra grupo-c111 prof-lopez-r)
(def-sesion ses-alg-c111-b asig-algebra grupo-c111 prof-lopez-r)
(def-sesion ses-alg-c112-a asig-algebra grupo-c112 prof-lopez-r)
(def-sesion ses-alg-c112-b asig-algebra grupo-c112 prof-lopez-r)
(def-sesion ses-alg-c113-a asig-algebra grupo-c113 prof-lopez-r)
(def-sesion ses-alg-c113-b asig-algebra grupo-c113 prof-lopez-r)
(def-sesion ses-alg-c121-a asig-algebra grupo-c121 prof-lopez-r)
(def-sesion ses-alg-c121-b asig-algebra grupo-c121 prof-lopez-r)
(def-sesion ses-alg-c122-a asig-algebra grupo-c122 prof-lopez-r)
(def-sesion ses-alg-c122-b asig-algebra grupo-c122 prof-lopez-r)

;; Análisis Matemático I C — frecuencia 2 por grupo
(def-sesion ses-am-c111-a asig-am grupo-c111 prof-martinez-p)
(def-sesion ses-am-c111-b asig-am grupo-c111 prof-martinez-p)
(def-sesion ses-am-c112-a asig-am grupo-c112 prof-martinez-p)
(def-sesion ses-am-c112-b asig-am grupo-c112 prof-martinez-p)
(def-sesion ses-am-c113-a asig-am grupo-c113 prof-martinez-p)
(def-sesion ses-am-c113-b asig-am grupo-c113 prof-martinez-p)
(def-sesion ses-am-c121-a asig-am grupo-c121 prof-martinez-p)
(def-sesion ses-am-c121-b asig-am grupo-c121 prof-martinez-p)
(def-sesion ses-am-c122-a asig-am grupo-c122 prof-martinez-p)
(def-sesion ses-am-c122-b asig-am grupo-c122 prof-martinez-p)

;; Programación C — frecuencia 1 por grupo
(def-sesion ses-prog-c111 asig-prog grupo-c111 prof-hernandez)
(def-sesion ses-prog-c112 asig-prog grupo-c112 prof-hernandez)
(def-sesion ses-prog-c113 asig-prog grupo-c113 prof-hernandez)
(def-sesion ses-prog-c121 asig-prog grupo-c121 prof-hernandez)
(def-sesion ses-prog-c122 asig-prog grupo-c122 prof-hernandez)

;; Lógica C — frecuencia 1 por grupo
(def-sesion ses-log-c111 asig-logica grupo-c111 prof-diaz-m)
(def-sesion ses-log-c112 asig-logica grupo-c112 prof-diaz-m)
(def-sesion ses-log-c113 asig-logica grupo-c113 prof-diaz-m)
(def-sesion ses-log-c121 asig-logica grupo-c121 prof-diaz-m)
(def-sesion ses-log-c122 asig-logica grupo-c122 prof-diaz-m)

;; Educación Física I — frecuencia 1 por grupo
(def-sesion ses-ef-c111 asig-ed-fisica grupo-c111 prof-gonzalez)
(def-sesion ses-ef-c112 asig-ed-fisica grupo-c112 prof-gonzalez)
(def-sesion ses-ef-c113 asig-ed-fisica grupo-c113 prof-gonzalez)
(def-sesion ses-ef-c121 asig-ed-fisica grupo-c121 prof-gonzalez)
(def-sesion ses-ef-c122 asig-ed-fisica grupo-c122 prof-gonzalez)

;; Álgebra I CP — frecuencia 1 por grupo
(def-sesion ses-alg-cp-c111 asig-algebra-cp grupo-c111 prof-lopez-r)
(def-sesion ses-alg-cp-c112 asig-algebra-cp grupo-c112 prof-lopez-r)
(def-sesion ses-alg-cp-c113 asig-algebra-cp grupo-c113 prof-lopez-r)
(def-sesion ses-alg-cp-c121 asig-algebra-cp grupo-c121 prof-lopez-r)
(def-sesion ses-alg-cp-c122 asig-algebra-cp grupo-c122 prof-lopez-r)

;; Análisis Matemático I CP — frecuencia 1 por grupo
(def-sesion ses-am-cp-c111 asig-am-cp grupo-c111 prof-martinez-p)
(def-sesion ses-am-cp-c112 asig-am-cp grupo-c112 prof-martinez-p)
(def-sesion ses-am-cp-c113 asig-am-cp grupo-c113 prof-martinez-p)
(def-sesion ses-am-cp-c121 asig-am-cp grupo-c121 prof-martinez-p)
(def-sesion ses-am-cp-c122 asig-am-cp grupo-c122 prof-martinez-p)

;; Programación CP — frecuencia 2 por grupo
(def-sesion ses-prog-cp-c111-a asig-prog-cp grupo-c111 prof-hernandez)
(def-sesion ses-prog-cp-c111-b asig-prog-cp grupo-c111 prof-hernandez)
(def-sesion ses-prog-cp-c112-a asig-prog-cp grupo-c112 prof-hernandez)
(def-sesion ses-prog-cp-c112-b asig-prog-cp grupo-c112 prof-hernandez)
(def-sesion ses-prog-cp-c113-a asig-prog-cp grupo-c113 prof-hernandez)
(def-sesion ses-prog-cp-c113-b asig-prog-cp grupo-c113 prof-hernandez)
(def-sesion ses-prog-cp-c121-a asig-prog-cp grupo-c121 prof-hernandez)
(def-sesion ses-prog-cp-c121-b asig-prog-cp grupo-c121 prof-hernandez)
(def-sesion ses-prog-cp-c122-a asig-prog-cp grupo-c122 prof-hernandez)
(def-sesion ses-prog-cp-c122-b asig-prog-cp grupo-c122 prof-hernandez)

;; Lógica CP — frecuencia 1 por grupo
(def-sesion ses-log-cp-c111 asig-logica-cp grupo-c111 prof-diaz-m)
(def-sesion ses-log-cp-c112 asig-logica-cp grupo-c112 prof-diaz-m)
(def-sesion ses-log-cp-c113 asig-logica-cp grupo-c113 prof-diaz-m)
(def-sesion ses-log-cp-c121 asig-logica-cp grupo-c121 prof-diaz-m)
(def-sesion ses-log-cp-c122 asig-logica-cp grupo-c122 prof-diaz-m)


;; =====================================================================
;; DEFINICIÓN DEL PROBLEMA
;; =====================================================================

(defvar problema-docentes
  (def-problema-horario
    ;; Entidad combinación: lo que constituye una fila del horario
    :entidad-horario   'clase
    ;; Slot identidad: hay una clase POR sesión
    :slot-identidad    'sesion
    ;; Slots variables: el GA elige estos de entre los pools de arriba
    :slots-variables   '(aula dia turno)
    ;; Consultas registradas en el AST
    :consultas         '(colisiones-de-profesor colisiones-de-aula colisiones-de-grupo
                         dias-de-profesor)
    ;; Restricciones duras
    ;; (restriccion-frecuencia-exacta se omite: la estructura de sesiones garantiza
    ;;  que cada asignatura se imparte exactamente su frecuencia de veces por grupo)
    :restricciones-duras   '(restriccion-un-aula-por-profesor
                              restriccion-un-grupo-por-aula
                              restriccion-una-clase-por-grupo)
    ;; Restricciones blandas
    :restricciones-blandas '(restriccion-minimizar-dias-de-viaje)
    :peso-dura   1000
    :peso-blanda    1))
