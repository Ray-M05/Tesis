;; =====================================================================
;; DOMINIO: HORARIO DEL PREUNIVERSITARIO SAUL
;; Decimo, undecimo y duodecimo grado, semana completa
;; =====================================================================
;; Traduccion al DSL de modelacion_saul.md.
;; =====================================================================

;; =====================================================================
;; MIXINS
;; =====================================================================

(def-mixin tiene-nombre ()
  (nombre))


;; =====================================================================
;; ENTIDADES ENUMERADAS
;; =====================================================================

;; Dia lectivo
(def-entidad dia (tiene-nombre))

;; Turno: orden 1..7. Los turnos 1 a 5 son de manana, los 6 y 7 de tarde.
;; El orden es lo unico del reloj que entra en el modelo.
(def-entidad turno (tiene-nombre) (orden))

;; Grado academico. Ninguna restriccion lo usa: esta para que el grupo
;; diga a que grado pertenece.
(def-entidad grado (tiene-nombre))


;; =====================================================================
;; ENTIDADES DEL DOMINIO
;; =====================================================================

;; Grupo de estudiantes. Pertenece a un grado.
(def-entidad grupo (tiene-nombre) (grado))

;; Asignatura. Una instancia por asignatura real. Lleva solo lo que es
;; suyo y no cambia de un grado a otro.
(def-entidad asignatura (tiene-nombre) (dia-preparacion educacion-fisica))

;; Aula donde se imparte. Dato informativo: ninguna restriccion lo lee,
;; porque cada grupo tiene aula propia y los laboratorios no se comparten.
;; Si algun dia dos grupos compartieran local, haria falta una colision de
;; aula identica a la de profesor.
(def-entidad aula (tiene-nombre))

;; Profesor. vive-lejos vale 1 para los que conviene no poner a primer turno.
;; es-contratado vale 1 para los que solo asisten ciertos dias. No lo lee
;; ninguna restriccion: los dias se controlan con la tabla de ausencias.
;; Esta para que la descripcion generada pueda nombrarlos.
(def-entidad profesor (tiene-nombre) (vive-lejos es-contratado))

;; Plan: lo que un grupo recibe de una asignatura. Una instancia por par de
;; grupo y asignatura. Lleva el profesor que la imparte y los tres datos que
;; cambian de un grado a otro:
;;   frecuencia     veces por semana que el grupo la recibe
;;   admite-doble   1 si puede tener dos turnos seguidos el mismo dia
;;   admite-tarde   1 si puede ubicarse en los turnos 6, 7 u 8
;; El plan no se coloca en ninguna casilla: es dato. Existe porque el lenguaje
;; no tiene atributos de pares.
(def-entidad plan () (grupo asignatura profesor aula frecuencia admite-doble admite-tarde))

;; Sesion: cada una de las veces que un plan se imparte. Un plan de frecuencia
;; cinco engendra cinco sesiones. Es la identidad del horario.
(def-entidad sesion () (plan))

;; Ausencia: dia en que un profesor contratado NO asiste al centro.
;; Se declaran las ausencias y no las asistencias porque el lenguaje cuenta
;; coincidencias: "existe una ausencia que casa con esta sesion" es contable,
;; "no existe ninguna asistencia que case" no lo es.
(def-entidad ausencia () (profesor dia))


;; =====================================================================
;; ENTIDAD COMBINACION: UBICACION
;; Una ubicacion = una sesion + cuando se imparte (dia, turno)
;; =====================================================================

(def-comb ubicacion (sesion dia turno))


;; =====================================================================
;; CONSULTAS Y RESTRICCIONES
;; =====================================================================

;; -- Restricciones duras --------------------------------------------

;; 1. Un grupo no puede recibir dos sesiones en el mismo dia y turno.
(def-consulta colisiones-de-grupo ()
  :pares (u1 u2) ubicacion
  :comprueba
  (op-y (op-igual    (grupo (plan (sesion u1))) (grupo (plan (sesion u2))))
          (op-igual    (dia   u1) (dia   u2))
          (op-igual    (turno u1) (turno u2))
          (op-distinto (sesion u1) (sesion u2)))
  :operacion (suma 1))

(def-nppq restriccion-una-sesion-por-grupo
  (op-mayor (colisiones-de-grupo) 0))


;; 2. Un profesor no puede impartir dos sesiones en el mismo dia y turno.
(def-consulta colisiones-de-profesor ()
  :itera-sobre (p profesor)
  :pares (u1 u2) ubicacion
  :comprueba
  (op-y (op-igual    (profesor (plan (sesion u1))) p)
          (op-igual    (profesor (plan (sesion u2))) p)
          (op-igual    (dia   u1) (dia   u2))
          (op-igual    (turno u1) (turno u2))
          (op-distinto (sesion u1) (sesion u2)))
  :operacion (suma 1))

(def-nppq restriccion-una-sesion-por-profesor
  (op-mayor (colisiones-de-profesor) 0))


;; 3. Una asignatura que no admite turno doble no puede tener dos sesiones
;;    del mismo grupo el mismo dia.
;;    Comparar plan contra plan equivale a comparar grupo y asignatura a la
;;    vez, porque un plan ES ese par.
(def-consulta repeticiones-en-el-dia ()
  :pares (u1 u2) ubicacion
  :comprueba
  (op-y (op-igual    (plan (sesion u1)) (plan (sesion u2)))
          (op-igual    (dia u1) (dia u2))
          (op-igual    (admite-doble (plan (sesion u1))) 0)
          (op-distinto (sesion u1) (sesion u2)))
  :operacion (suma 1))

(def-nppq restriccion-sin-repetir-asignatura-en-el-dia
  (op-mayor (repeticiones-en-el-dia) 0))


;; 4. Una asignatura que admite turno doble no puede tener dos sesiones del
;;    mismo grupo el mismo dia en turnos que no sean consecutivos.
;;    op-mayor ordena el par, asi que cada pareja se cuenta una sola vez y
;;    las dos sesiones son distintas por construccion. Tres sesiones el mismo
;;    dia quedan prohibidas de paso: la primera y la tercera nunca son
;;    consecutivas.
(def-consulta dobles-no-consecutivos ()
  :itera-sobre (u1 ubicacion) (u2 ubicacion)
  :comprueba
  (op-y (op-igual    (plan (sesion u1)) (plan (sesion u2)))
          (op-igual    (dia u1) (dia u2))
          (op-igual    (admite-doble (plan (sesion u1))) 1)
          (op-mayor    (orden (turno u2)) (orden (turno u1)))
          (op-distinto (orden (turno u2)) (op-suma (orden (turno u1)) 1)))
  :operacion (suma 1))

(def-nppq restriccion-turno-doble-consecutivo
  (op-mayor (dobles-no-consecutivos) 0))


;; 5. Ninguna sesion cae en el dia de preparacion de su asignatura.
(def-consulta sesiones-en-dia-de-preparacion ()
  :itera-sobre (u ubicacion)
  :comprueba
  (op-igual (dia u) (dia-preparacion (asignatura (plan (sesion u)))))
  :operacion (suma 1))

(def-nppq restriccion-sin-clases-el-dia-de-preparacion
  (op-mayor (sesiones-en-dia-de-preparacion) 0))


;; 6. Ninguna sesion de educacion fisica cae despues del tercer turno.
(def-consulta educacion-fisica-fuera-de-horario ()
  :itera-sobre (u ubicacion)
  :comprueba
  (op-y (op-igual (educacion-fisica (asignatura (plan (sesion u)))) 1)
          (op-mayor (orden (turno u)) 3))
  :operacion (suma 1))

(def-nppq restriccion-educacion-fisica-temprano
  (op-mayor (educacion-fisica-fuera-de-horario) 0))


;; 7. Ninguna sesion de una asignatura que su grado no autoriza en la tarde
;;    cae en los turnos 6 o 7.
(def-consulta sesiones-de-tarde-no-autorizadas ()
  :itera-sobre (u ubicacion)
  :comprueba
  (op-y (op-igual (admite-tarde (plan (sesion u))) 0)
          (op-mayor (orden (turno u)) 5))
  :operacion (suma 1))

(def-nppq restriccion-tarde-solo-para-las-autorizadas
  (op-mayor (sesiones-de-tarde-no-autorizadas) 0))


;; 8. Ningun profesor contratado imparte en un dia en que no asiste.
(def-consulta sesiones-en-dia-sin-asistencia ()
  :itera-sobre (u ubicacion) (a ausencia)
  :comprueba
  (op-y (op-igual (profesor (plan (sesion u))) (profesor a))
          (op-igual (dia u) (dia a)))
  :operacion (suma 1))

(def-nppq restriccion-contratado-solo-sus-dias
  (op-mayor (sesiones-en-dia-sin-asistencia) 0))


;; 9. Cada grupo recibe cada asignatura tantas veces como indica su frecuencia.
;;    Se cuantifica sobre el plan, que es el par de grupo y asignatura. Sobre
;;    la asignatura sola seria falsa siempre: contaria las sesiones de los tres
;;    grupos del grado contra una frecuencia que es por grupo.
;;    AVISO: es correcta pero no se puede incumplir. Las sesiones se crean una
;;    por unidad de frecuencia y toda identidad recibe valor, asi que el conteo
;;    da siempre la frecuencia. Se declara por fidelidad con la descripcion.
(def-consulta sesiones-del-plan (pl)
  :itera-sobre (u ubicacion)
  :comprueba
  (op-igual (plan (sesion u)) pl)
  :operacion (suma 1))

(def-tqpq restriccion-frecuencia-exacta
  (op-igual (sesiones-del-plan pl) (frecuencia pl))
  :para (pl plan))


;; -- Restricciones blandas ------------------------------------------

;; Primeros turnos asignados a profesores que viven lejos.
;; Una restriccion ndpq devuelve el conteo crudo, asi que la penalizacion es
;; proporcional al numero de veces que ocurre.
(def-consulta primeros-turnos-de-lejanos ()
  :itera-sobre (u ubicacion)
  :comprueba
  (op-y (op-igual (vive-lejos (profesor (plan (sesion u)))) 1)
          (op-igual (orden (turno u)) 1))
  :operacion (suma 1))

(def-ndpq restriccion-evitar-primer-turno-a-los-lejanos
  (op-mayor (primeros-turnos-de-lejanos) 0))


;; Sesiones que un profesor imparte en un dia concreto.
(def-consulta sesiones-del-dia (p d)
  :itera-sobre (u ubicacion)
  :comprueba
  (op-y (op-igual (profesor (plan (sesion u))) p)
          (op-igual (dia u) d))
  :operacion (suma 1))

;; Seria bueno que ningun profesor imparta mas de 5 sesiones en un dia.
(def-sbqp restriccion-tope-diario-de-profesor
  (op-menor-igual (sesiones-del-dia p d) 5)
  :para (p profesor) (d dia))


;; =====================================================================
;; DATOS CONCRETOS
;; =====================================================================

;; ---- Dias lectivos -----------------------------------------------
(def-dia lunes      "Lunes")
(def-dia martes     "Martes")
(def-dia miercoles  "Miércoles")
(def-dia jueves     "Jueves")
(def-dia viernes    "Viernes")

;; ---- Turnos. 1 a 5 de manana, el resto de tarde ------------------
(def-turno turno-1 "T1" 1)
(def-turno turno-2 "T2" 2)
(def-turno turno-3 "T3" 3)
(def-turno turno-4 "T4" 4)
(def-turno turno-5 "T5" 5)
(def-turno turno-6 "T6" 6)
(def-turno turno-7 "T7" 7)

;; ---- Grados ------------------------------------------------------
(def-grado grado-10 "10mo grado")
(def-grado grado-11 "11no grado")
(def-grado grado-12 "12mo grado")

;; ---- Grupos ------------------------------------------------------
(def-grupo grupo-10-1 "10-1" grado-10)
(def-grupo grupo-10-2 "10-2" grado-10)
(def-grupo grupo-10-3 "10-3" grado-10)
(def-grupo grupo-11-1 "11-1" grado-11)
(def-grupo grupo-11-2 "11-2" grado-11)
(def-grupo grupo-11-3 "11-3" grado-11)
(def-grupo grupo-12-1 "12-1" grado-12)
(def-grupo grupo-12-2 "12-2" grado-12)
(def-grupo grupo-12-3 "12-3" grado-12)

;; ---- Asignaturas: nombre, dia de preparacion, si es educacion fisica -
(def-asignatura asig-mat "Matemática"                     viernes    0)
(def-asignatura asig-fis "Física"                         lunes      0)
(def-asignatura asig-inf "Informática"                    martes     0)
(def-asignatura asig-lit "Literatura y Lengua"            miercoles  0)
(def-asignatura asig-his "Historia"                       jueves     0)
(def-asignatura asig-cpo "Cultura Política"               viernes    0)
(def-asignatura asig-ing "Idioma Extranjero (Inglés)"     lunes      0)
(def-asignatura asig-dci "Defensa Civil"                  martes     0)
(def-asignatura asig-bio "Biología"                       miercoles  0)
(def-asignatura asig-qui "Química"                        jueves     0)
(def-asignatura asig-geo "Geografía"                      viernes    0)
(def-asignatura asig-car "Cultura Artística"              lunes      0)
(def-asignatura asig-efi "Educación Física"               martes     1)

;; ---- Aulas: la de cada grupo, mas los locales compartidos --------
(def-aula aula-10-1 "Aula 10-1")
(def-aula aula-10-2 "Aula 10-2")
(def-aula aula-10-3 "Aula 10-3")
(def-aula aula-11-1 "Aula 11-1")
(def-aula aula-11-2 "Aula 11-2")
(def-aula aula-11-3 "Aula 11-3")
(def-aula aula-12-1 "Aula 12-1")
(def-aula aula-12-2 "Aula 12-2")
(def-aula aula-12-3 "Aula 12-3")
(def-aula lab-1    "Laboratorio 1")
(def-aula lab-2    "Laboratorio 2")
(def-aula terreno  "Terreno deportivo")

;; ---- Profesores: nombre, vive lejos, es contratado ---------------
(def-profesor prof-a "profesor_A" 0 0)  ;; 10 sesiones
(def-profesor prof-b "profesor_B" 0 0)  ;; 15 sesiones
(def-profesor prof-c "profesor_C" 1 0)  ;; 15 sesiones
(def-profesor prof-d "profesor_D" 0 0)  ;; 18 sesiones
(def-profesor prof-e "profesor_E" 0 0)  ;; 9 sesiones
(def-profesor prof-f "profesor_F" 0 0)  ;; 18 sesiones
(def-profesor prof-g "profesor_G" 0 0)  ;; 12 sesiones
(def-profesor prof-h "profesor_H" 1 0)  ;; 12 sesiones
(def-profesor prof-i "profesor_I" 0 0)  ;; 15 sesiones
(def-profesor prof-j "profesor_J" 0 0)  ;; 18 sesiones
(def-profesor prof-k "profesor_K" 0 0)  ;; 15 sesiones
(def-profesor prof-l "profesor_L" 0 0)  ;; 15 sesiones
(def-profesor prof-m "profesor_M" 0 0)  ;; 6 sesiones
(def-profesor prof-n "profesor_N" 0 0)  ;; 15 sesiones
(def-profesor prof-o "profesor_O" 0 0)  ;; 6 sesiones
(def-profesor prof-p "profesor_P" 0 1)  ;; 6 sesiones
(def-profesor prof-q "profesor_Q" 0 0)  ;; 12 sesiones
(def-profesor prof-r "profesor_R" 1 0)  ;; 9 sesiones
(def-profesor prof-s "profesor_S" 0 0)  ;; 18 sesiones
(def-profesor prof-t "profesor_T" 1 0)  ;; 9 sesiones
(def-profesor prof-u "profesor_U" 0 1)  ;; 12 sesiones
(def-profesor prof-v "profesor_V" 0 1)  ;; 6 sesiones
(def-profesor prof-w "profesor_W" 0 0)  ;; 12 sesiones
(def-profesor prof-x "profesor_X" 0 0)  ;; 6 sesiones
(def-profesor prof-y "profesor_Y" 0 0)  ;; 5 sesiones
(def-profesor prof-z "profesor_Z" 0 0)  ;; 3 sesiones

;; ---- Ausencias de los profesores contratados ---------------------
(def-ausencia aus-p-martes prof-p martes)
(def-ausencia aus-p-jueves prof-p jueves)
(def-ausencia aus-u-lunes prof-u lunes)
(def-ausencia aus-u-viernes prof-u viernes)
(def-ausencia aus-v-lunes prof-v lunes)
(def-ausencia aus-v-jueves prof-v jueves)

;; ---- Planes: un par de grupo y asignatura ------------------------
;; grupo asignatura profesor aula frecuencia admite-doble admite-tarde
;; 10mo grado
(def-plan plan-mat-10-1 grupo-10-1 asig-mat  prof-a aula-10-1  5 1 0)
(def-plan plan-mat-10-2 grupo-10-2 asig-mat  prof-a aula-10-2  5 1 0)
(def-plan plan-mat-10-3 grupo-10-3 asig-mat  prof-y aula-10-3  5 1 0)
(def-plan plan-fis-10-1 grupo-10-1 asig-fis  prof-d aula-10-1  3 0 0)
(def-plan plan-fis-10-2 grupo-10-2 asig-fis  prof-d aula-10-2  3 0 0)
(def-plan plan-fis-10-3 grupo-10-3 asig-fis  prof-d aula-10-3  3 0 0)
(def-plan plan-inf-10-1 grupo-10-1 asig-inf  prof-f lab-1      2 0 1)
(def-plan plan-inf-10-2 grupo-10-2 asig-inf  prof-f lab-1      2 0 1)
(def-plan plan-inf-10-3 grupo-10-3 asig-inf  prof-f lab-1      2 0 1)
(def-plan plan-lit-10-1 grupo-10-1 asig-lit  prof-g aula-10-1  4 0 0)
(def-plan plan-lit-10-2 grupo-10-2 asig-lit  prof-g aula-10-2  4 0 0)
(def-plan plan-lit-10-3 grupo-10-3 asig-lit  prof-g aula-10-3  4 0 0)
(def-plan plan-his-10-1 grupo-10-1 asig-his  prof-j aula-10-1  3 0 1)
(def-plan plan-his-10-2 grupo-10-2 asig-his  prof-j aula-10-2  3 0 1)
(def-plan plan-his-10-3 grupo-10-3 asig-his  prof-j aula-10-3  3 0 1)
(def-plan plan-cpo-10-1 grupo-10-1 asig-cpo  prof-l aula-10-1  2 0 1)
(def-plan plan-cpo-10-2 grupo-10-2 asig-cpo  prof-l aula-10-2  2 0 1)
(def-plan plan-cpo-10-3 grupo-10-3 asig-cpo  prof-l aula-10-3  2 0 1)
(def-plan plan-ing-10-1 grupo-10-1 asig-ing  prof-n aula-10-1  3 0 1)
(def-plan plan-ing-10-2 grupo-10-2 asig-ing  prof-n aula-10-2  3 0 1)
(def-plan plan-ing-10-3 grupo-10-3 asig-ing  prof-n aula-10-3  3 0 1)
(def-plan plan-dci-10-1 grupo-10-1 asig-dci  prof-p aula-10-1  2 0 1)
(def-plan plan-dci-10-2 grupo-10-2 asig-dci  prof-p aula-10-2  2 0 1)
(def-plan plan-dci-10-3 grupo-10-3 asig-dci  prof-p aula-10-3  2 0 1)
(def-plan plan-bio-10-1 grupo-10-1 asig-bio  prof-q aula-10-1  2 0 1)
(def-plan plan-bio-10-2 grupo-10-2 asig-bio  prof-q aula-10-2  2 0 1)
(def-plan plan-bio-10-3 grupo-10-3 asig-bio  prof-q aula-10-3  2 0 1)
(def-plan plan-qui-10-1 grupo-10-1 asig-qui  prof-s aula-10-1  3 0 0)
(def-plan plan-qui-10-2 grupo-10-2 asig-qui  prof-s aula-10-2  3 0 0)
(def-plan plan-qui-10-3 grupo-10-3 asig-qui  prof-s aula-10-3  3 0 0)
(def-plan plan-geo-10-1 grupo-10-1 asig-geo  prof-u aula-10-1  2 0 1)
(def-plan plan-geo-10-2 grupo-10-2 asig-geo  prof-u aula-10-2  2 0 1)
(def-plan plan-geo-10-3 grupo-10-3 asig-geo  prof-u aula-10-3  2 0 1)
(def-plan plan-car-10-1 grupo-10-1 asig-car  prof-v aula-10-1  2 0 1)
(def-plan plan-car-10-2 grupo-10-2 asig-car  prof-v aula-10-2  2 0 1)
(def-plan plan-car-10-3 grupo-10-3 asig-car  prof-v aula-10-3  2 0 1)
(def-plan plan-efi-10-1 grupo-10-1 asig-efi  prof-w terreno    2 0 0)
(def-plan plan-efi-10-2 grupo-10-2 asig-efi  prof-w terreno    2 0 0)
(def-plan plan-efi-10-3 grupo-10-3 asig-efi  prof-w terreno    2 0 0)

;; 11no grado
(def-plan plan-mat-11-1 grupo-11-1 asig-mat  prof-b aula-11-1  5 1 0)
(def-plan plan-mat-11-2 grupo-11-2 asig-mat  prof-b aula-11-2  5 1 0)
(def-plan plan-mat-11-3 grupo-11-3 asig-mat  prof-b aula-11-3  5 1 0)
(def-plan plan-fis-11-1 grupo-11-1 asig-fis  prof-d aula-11-1  3 0 0)
(def-plan plan-fis-11-2 grupo-11-2 asig-fis  prof-d aula-11-2  3 0 0)
(def-plan plan-fis-11-3 grupo-11-3 asig-fis  prof-d aula-11-3  3 0 0)
(def-plan plan-inf-11-1 grupo-11-1 asig-inf  prof-f lab-1      2 0 1)
(def-plan plan-inf-11-2 grupo-11-2 asig-inf  prof-f lab-1      2 0 1)
(def-plan plan-inf-11-3 grupo-11-3 asig-inf  prof-f lab-1      2 0 1)
(def-plan plan-lit-11-1 grupo-11-1 asig-lit  prof-h aula-11-1  4 0 0)
(def-plan plan-lit-11-2 grupo-11-2 asig-lit  prof-h aula-11-2  4 0 0)
(def-plan plan-lit-11-3 grupo-11-3 asig-lit  prof-h aula-11-3  4 0 0)
(def-plan plan-his-11-1 grupo-11-1 asig-his  prof-j aula-11-1  3 0 1)
(def-plan plan-his-11-2 grupo-11-2 asig-his  prof-j aula-11-2  3 0 1)
(def-plan plan-his-11-3 grupo-11-3 asig-his  prof-j aula-11-3  3 0 1)
(def-plan plan-cpo-11-1 grupo-11-1 asig-cpo  prof-l aula-11-1  3 0 1)
(def-plan plan-cpo-11-2 grupo-11-2 asig-cpo  prof-l aula-11-2  3 0 1)
(def-plan plan-cpo-11-3 grupo-11-3 asig-cpo  prof-l aula-11-3  3 0 1)
(def-plan plan-ing-11-1 grupo-11-1 asig-ing  prof-n aula-11-1  2 0 1)
(def-plan plan-ing-11-2 grupo-11-2 asig-ing  prof-n aula-11-2  2 0 1)
(def-plan plan-ing-11-3 grupo-11-3 asig-ing  prof-n aula-11-3  2 0 1)
(def-plan plan-bio-11-1 grupo-11-1 asig-bio  prof-q aula-11-1  3 0 1)
(def-plan plan-bio-11-2 grupo-11-2 asig-bio  prof-q aula-11-2  3 0 1)
(def-plan plan-bio-11-3 grupo-11-3 asig-bio  prof-z aula-11-3  3 0 1)
(def-plan plan-qui-11-1 grupo-11-1 asig-qui  prof-s aula-11-1  3 0 0)
(def-plan plan-qui-11-2 grupo-11-2 asig-qui  prof-s aula-11-2  3 0 0)
(def-plan plan-qui-11-3 grupo-11-3 asig-qui  prof-s aula-11-3  3 0 0)
(def-plan plan-geo-11-1 grupo-11-1 asig-geo  prof-u aula-11-1  2 0 1)
(def-plan plan-geo-11-2 grupo-11-2 asig-geo  prof-u aula-11-2  2 0 1)
(def-plan plan-geo-11-3 grupo-11-3 asig-geo  prof-u aula-11-3  2 0 1)
(def-plan plan-efi-11-1 grupo-11-1 asig-efi  prof-w terreno    2 0 0)
(def-plan plan-efi-11-2 grupo-11-2 asig-efi  prof-w terreno    2 0 0)
(def-plan plan-efi-11-3 grupo-11-3 asig-efi  prof-w terreno    2 0 0)

;; 12mo grado
(def-plan plan-mat-12-1 grupo-12-1 asig-mat  prof-c aula-12-1  5 1 0)
(def-plan plan-mat-12-2 grupo-12-2 asig-mat  prof-c aula-12-2  5 1 0)
(def-plan plan-mat-12-3 grupo-12-3 asig-mat  prof-c aula-12-3  5 1 0)
(def-plan plan-fis-12-1 grupo-12-1 asig-fis  prof-e aula-12-1  3 0 0)
(def-plan plan-fis-12-2 grupo-12-2 asig-fis  prof-e aula-12-2  3 0 0)
(def-plan plan-fis-12-3 grupo-12-3 asig-fis  prof-e aula-12-3  3 0 0)
(def-plan plan-inf-12-1 grupo-12-1 asig-inf  prof-f lab-2      2 0 1)
(def-plan plan-inf-12-2 grupo-12-2 asig-inf  prof-f lab-2      2 0 1)
(def-plan plan-inf-12-3 grupo-12-3 asig-inf  prof-f lab-2      2 0 1)
(def-plan plan-lit-12-1 grupo-12-1 asig-lit  prof-i aula-12-1  5 1 0)
(def-plan plan-lit-12-2 grupo-12-2 asig-lit  prof-i aula-12-2  5 1 0)
(def-plan plan-lit-12-3 grupo-12-3 asig-lit  prof-i aula-12-3  5 1 0)
(def-plan plan-his-12-1 grupo-12-1 asig-his  prof-k aula-12-1  5 1 0)
(def-plan plan-his-12-2 grupo-12-2 asig-his  prof-k aula-12-2  5 1 0)
(def-plan plan-his-12-3 grupo-12-3 asig-his  prof-k aula-12-3  5 1 0)
(def-plan plan-cpo-12-1 grupo-12-1 asig-cpo  prof-m aula-12-1  2 0 1)
(def-plan plan-cpo-12-2 grupo-12-2 asig-cpo  prof-m aula-12-2  2 0 1)
(def-plan plan-cpo-12-3 grupo-12-3 asig-cpo  prof-m aula-12-3  2 0 1)
(def-plan plan-ing-12-1 grupo-12-1 asig-ing  prof-o aula-12-1  2 0 1)
(def-plan plan-ing-12-2 grupo-12-2 asig-ing  prof-o aula-12-2  2 0 1)
(def-plan plan-ing-12-3 grupo-12-3 asig-ing  prof-o aula-12-3  2 0 1)
(def-plan plan-bio-12-1 grupo-12-1 asig-bio  prof-r aula-12-1  3 0 1)
(def-plan plan-bio-12-2 grupo-12-2 asig-bio  prof-r aula-12-2  3 0 1)
(def-plan plan-bio-12-3 grupo-12-3 asig-bio  prof-r aula-12-3  3 0 1)
(def-plan plan-qui-12-1 grupo-12-1 asig-qui  prof-t aula-12-1  3 0 1)
(def-plan plan-qui-12-2 grupo-12-2 asig-qui  prof-t aula-12-2  3 0 1)
(def-plan plan-qui-12-3 grupo-12-3 asig-qui  prof-t aula-12-3  3 0 1)
(def-plan plan-efi-12-1 grupo-12-1 asig-efi  prof-x terreno    2 0 0)
(def-plan plan-efi-12-2 grupo-12-2 asig-efi  prof-x terreno    2 0 0)
(def-plan plan-efi-12-3 grupo-12-3 asig-efi  prof-x terreno    2 0 0)

;; ---- Sesiones: una por cada unidad de frecuencia de cada plan ----
;; 10mo grado
(def-sesion ses-mat-10-1-1 plan-mat-10-1)
(def-sesion ses-mat-10-1-2 plan-mat-10-1)
(def-sesion ses-mat-10-1-3 plan-mat-10-1)
(def-sesion ses-mat-10-1-4 plan-mat-10-1)
(def-sesion ses-mat-10-1-5 plan-mat-10-1)
(def-sesion ses-mat-10-2-1 plan-mat-10-2)
(def-sesion ses-mat-10-2-2 plan-mat-10-2)
(def-sesion ses-mat-10-2-3 plan-mat-10-2)
(def-sesion ses-mat-10-2-4 plan-mat-10-2)
(def-sesion ses-mat-10-2-5 plan-mat-10-2)
(def-sesion ses-mat-10-3-1 plan-mat-10-3)
(def-sesion ses-mat-10-3-2 plan-mat-10-3)
(def-sesion ses-mat-10-3-3 plan-mat-10-3)
(def-sesion ses-mat-10-3-4 plan-mat-10-3)
(def-sesion ses-mat-10-3-5 plan-mat-10-3)
(def-sesion ses-fis-10-1-1 plan-fis-10-1)
(def-sesion ses-fis-10-1-2 plan-fis-10-1)
(def-sesion ses-fis-10-1-3 plan-fis-10-1)
(def-sesion ses-fis-10-2-1 plan-fis-10-2)
(def-sesion ses-fis-10-2-2 plan-fis-10-2)
(def-sesion ses-fis-10-2-3 plan-fis-10-2)
(def-sesion ses-fis-10-3-1 plan-fis-10-3)
(def-sesion ses-fis-10-3-2 plan-fis-10-3)
(def-sesion ses-fis-10-3-3 plan-fis-10-3)
(def-sesion ses-inf-10-1-1 plan-inf-10-1)
(def-sesion ses-inf-10-1-2 plan-inf-10-1)
(def-sesion ses-inf-10-2-1 plan-inf-10-2)
(def-sesion ses-inf-10-2-2 plan-inf-10-2)
(def-sesion ses-inf-10-3-1 plan-inf-10-3)
(def-sesion ses-inf-10-3-2 plan-inf-10-3)
(def-sesion ses-lit-10-1-1 plan-lit-10-1)
(def-sesion ses-lit-10-1-2 plan-lit-10-1)
(def-sesion ses-lit-10-1-3 plan-lit-10-1)
(def-sesion ses-lit-10-1-4 plan-lit-10-1)
(def-sesion ses-lit-10-2-1 plan-lit-10-2)
(def-sesion ses-lit-10-2-2 plan-lit-10-2)
(def-sesion ses-lit-10-2-3 plan-lit-10-2)
(def-sesion ses-lit-10-2-4 plan-lit-10-2)
(def-sesion ses-lit-10-3-1 plan-lit-10-3)
(def-sesion ses-lit-10-3-2 plan-lit-10-3)
(def-sesion ses-lit-10-3-3 plan-lit-10-3)
(def-sesion ses-lit-10-3-4 plan-lit-10-3)
(def-sesion ses-his-10-1-1 plan-his-10-1)
(def-sesion ses-his-10-1-2 plan-his-10-1)
(def-sesion ses-his-10-1-3 plan-his-10-1)
(def-sesion ses-his-10-2-1 plan-his-10-2)
(def-sesion ses-his-10-2-2 plan-his-10-2)
(def-sesion ses-his-10-2-3 plan-his-10-2)
(def-sesion ses-his-10-3-1 plan-his-10-3)
(def-sesion ses-his-10-3-2 plan-his-10-3)
(def-sesion ses-his-10-3-3 plan-his-10-3)
(def-sesion ses-cpo-10-1-1 plan-cpo-10-1)
(def-sesion ses-cpo-10-1-2 plan-cpo-10-1)
(def-sesion ses-cpo-10-2-1 plan-cpo-10-2)
(def-sesion ses-cpo-10-2-2 plan-cpo-10-2)
(def-sesion ses-cpo-10-3-1 plan-cpo-10-3)
(def-sesion ses-cpo-10-3-2 plan-cpo-10-3)
(def-sesion ses-ing-10-1-1 plan-ing-10-1)
(def-sesion ses-ing-10-1-2 plan-ing-10-1)
(def-sesion ses-ing-10-1-3 plan-ing-10-1)
(def-sesion ses-ing-10-2-1 plan-ing-10-2)
(def-sesion ses-ing-10-2-2 plan-ing-10-2)
(def-sesion ses-ing-10-2-3 plan-ing-10-2)
(def-sesion ses-ing-10-3-1 plan-ing-10-3)
(def-sesion ses-ing-10-3-2 plan-ing-10-3)
(def-sesion ses-ing-10-3-3 plan-ing-10-3)
(def-sesion ses-dci-10-1-1 plan-dci-10-1)
(def-sesion ses-dci-10-1-2 plan-dci-10-1)
(def-sesion ses-dci-10-2-1 plan-dci-10-2)
(def-sesion ses-dci-10-2-2 plan-dci-10-2)
(def-sesion ses-dci-10-3-1 plan-dci-10-3)
(def-sesion ses-dci-10-3-2 plan-dci-10-3)
(def-sesion ses-bio-10-1-1 plan-bio-10-1)
(def-sesion ses-bio-10-1-2 plan-bio-10-1)
(def-sesion ses-bio-10-2-1 plan-bio-10-2)
(def-sesion ses-bio-10-2-2 plan-bio-10-2)
(def-sesion ses-bio-10-3-1 plan-bio-10-3)
(def-sesion ses-bio-10-3-2 plan-bio-10-3)
(def-sesion ses-qui-10-1-1 plan-qui-10-1)
(def-sesion ses-qui-10-1-2 plan-qui-10-1)
(def-sesion ses-qui-10-1-3 plan-qui-10-1)
(def-sesion ses-qui-10-2-1 plan-qui-10-2)
(def-sesion ses-qui-10-2-2 plan-qui-10-2)
(def-sesion ses-qui-10-2-3 plan-qui-10-2)
(def-sesion ses-qui-10-3-1 plan-qui-10-3)
(def-sesion ses-qui-10-3-2 plan-qui-10-3)
(def-sesion ses-qui-10-3-3 plan-qui-10-3)
(def-sesion ses-geo-10-1-1 plan-geo-10-1)
(def-sesion ses-geo-10-1-2 plan-geo-10-1)
(def-sesion ses-geo-10-2-1 plan-geo-10-2)
(def-sesion ses-geo-10-2-2 plan-geo-10-2)
(def-sesion ses-geo-10-3-1 plan-geo-10-3)
(def-sesion ses-geo-10-3-2 plan-geo-10-3)
(def-sesion ses-car-10-1-1 plan-car-10-1)
(def-sesion ses-car-10-1-2 plan-car-10-1)
(def-sesion ses-car-10-2-1 plan-car-10-2)
(def-sesion ses-car-10-2-2 plan-car-10-2)
(def-sesion ses-car-10-3-1 plan-car-10-3)
(def-sesion ses-car-10-3-2 plan-car-10-3)
(def-sesion ses-efi-10-1-1 plan-efi-10-1)
(def-sesion ses-efi-10-1-2 plan-efi-10-1)
(def-sesion ses-efi-10-2-1 plan-efi-10-2)
(def-sesion ses-efi-10-2-2 plan-efi-10-2)
(def-sesion ses-efi-10-3-1 plan-efi-10-3)
(def-sesion ses-efi-10-3-2 plan-efi-10-3)

;; 11no grado
(def-sesion ses-mat-11-1-1 plan-mat-11-1)
(def-sesion ses-mat-11-1-2 plan-mat-11-1)
(def-sesion ses-mat-11-1-3 plan-mat-11-1)
(def-sesion ses-mat-11-1-4 plan-mat-11-1)
(def-sesion ses-mat-11-1-5 plan-mat-11-1)
(def-sesion ses-mat-11-2-1 plan-mat-11-2)
(def-sesion ses-mat-11-2-2 plan-mat-11-2)
(def-sesion ses-mat-11-2-3 plan-mat-11-2)
(def-sesion ses-mat-11-2-4 plan-mat-11-2)
(def-sesion ses-mat-11-2-5 plan-mat-11-2)
(def-sesion ses-mat-11-3-1 plan-mat-11-3)
(def-sesion ses-mat-11-3-2 plan-mat-11-3)
(def-sesion ses-mat-11-3-3 plan-mat-11-3)
(def-sesion ses-mat-11-3-4 plan-mat-11-3)
(def-sesion ses-mat-11-3-5 plan-mat-11-3)
(def-sesion ses-fis-11-1-1 plan-fis-11-1)
(def-sesion ses-fis-11-1-2 plan-fis-11-1)
(def-sesion ses-fis-11-1-3 plan-fis-11-1)
(def-sesion ses-fis-11-2-1 plan-fis-11-2)
(def-sesion ses-fis-11-2-2 plan-fis-11-2)
(def-sesion ses-fis-11-2-3 plan-fis-11-2)
(def-sesion ses-fis-11-3-1 plan-fis-11-3)
(def-sesion ses-fis-11-3-2 plan-fis-11-3)
(def-sesion ses-fis-11-3-3 plan-fis-11-3)
(def-sesion ses-inf-11-1-1 plan-inf-11-1)
(def-sesion ses-inf-11-1-2 plan-inf-11-1)
(def-sesion ses-inf-11-2-1 plan-inf-11-2)
(def-sesion ses-inf-11-2-2 plan-inf-11-2)
(def-sesion ses-inf-11-3-1 plan-inf-11-3)
(def-sesion ses-inf-11-3-2 plan-inf-11-3)
(def-sesion ses-lit-11-1-1 plan-lit-11-1)
(def-sesion ses-lit-11-1-2 plan-lit-11-1)
(def-sesion ses-lit-11-1-3 plan-lit-11-1)
(def-sesion ses-lit-11-1-4 plan-lit-11-1)
(def-sesion ses-lit-11-2-1 plan-lit-11-2)
(def-sesion ses-lit-11-2-2 plan-lit-11-2)
(def-sesion ses-lit-11-2-3 plan-lit-11-2)
(def-sesion ses-lit-11-2-4 plan-lit-11-2)
(def-sesion ses-lit-11-3-1 plan-lit-11-3)
(def-sesion ses-lit-11-3-2 plan-lit-11-3)
(def-sesion ses-lit-11-3-3 plan-lit-11-3)
(def-sesion ses-lit-11-3-4 plan-lit-11-3)
(def-sesion ses-his-11-1-1 plan-his-11-1)
(def-sesion ses-his-11-1-2 plan-his-11-1)
(def-sesion ses-his-11-1-3 plan-his-11-1)
(def-sesion ses-his-11-2-1 plan-his-11-2)
(def-sesion ses-his-11-2-2 plan-his-11-2)
(def-sesion ses-his-11-2-3 plan-his-11-2)
(def-sesion ses-his-11-3-1 plan-his-11-3)
(def-sesion ses-his-11-3-2 plan-his-11-3)
(def-sesion ses-his-11-3-3 plan-his-11-3)
(def-sesion ses-cpo-11-1-1 plan-cpo-11-1)
(def-sesion ses-cpo-11-1-2 plan-cpo-11-1)
(def-sesion ses-cpo-11-1-3 plan-cpo-11-1)
(def-sesion ses-cpo-11-2-1 plan-cpo-11-2)
(def-sesion ses-cpo-11-2-2 plan-cpo-11-2)
(def-sesion ses-cpo-11-2-3 plan-cpo-11-2)
(def-sesion ses-cpo-11-3-1 plan-cpo-11-3)
(def-sesion ses-cpo-11-3-2 plan-cpo-11-3)
(def-sesion ses-cpo-11-3-3 plan-cpo-11-3)
(def-sesion ses-ing-11-1-1 plan-ing-11-1)
(def-sesion ses-ing-11-1-2 plan-ing-11-1)
(def-sesion ses-ing-11-2-1 plan-ing-11-2)
(def-sesion ses-ing-11-2-2 plan-ing-11-2)
(def-sesion ses-ing-11-3-1 plan-ing-11-3)
(def-sesion ses-ing-11-3-2 plan-ing-11-3)
(def-sesion ses-bio-11-1-1 plan-bio-11-1)
(def-sesion ses-bio-11-1-2 plan-bio-11-1)
(def-sesion ses-bio-11-1-3 plan-bio-11-1)
(def-sesion ses-bio-11-2-1 plan-bio-11-2)
(def-sesion ses-bio-11-2-2 plan-bio-11-2)
(def-sesion ses-bio-11-2-3 plan-bio-11-2)
(def-sesion ses-bio-11-3-1 plan-bio-11-3)
(def-sesion ses-bio-11-3-2 plan-bio-11-3)
(def-sesion ses-bio-11-3-3 plan-bio-11-3)
(def-sesion ses-qui-11-1-1 plan-qui-11-1)
(def-sesion ses-qui-11-1-2 plan-qui-11-1)
(def-sesion ses-qui-11-1-3 plan-qui-11-1)
(def-sesion ses-qui-11-2-1 plan-qui-11-2)
(def-sesion ses-qui-11-2-2 plan-qui-11-2)
(def-sesion ses-qui-11-2-3 plan-qui-11-2)
(def-sesion ses-qui-11-3-1 plan-qui-11-3)
(def-sesion ses-qui-11-3-2 plan-qui-11-3)
(def-sesion ses-qui-11-3-3 plan-qui-11-3)
(def-sesion ses-geo-11-1-1 plan-geo-11-1)
(def-sesion ses-geo-11-1-2 plan-geo-11-1)
(def-sesion ses-geo-11-2-1 plan-geo-11-2)
(def-sesion ses-geo-11-2-2 plan-geo-11-2)
(def-sesion ses-geo-11-3-1 plan-geo-11-3)
(def-sesion ses-geo-11-3-2 plan-geo-11-3)
(def-sesion ses-efi-11-1-1 plan-efi-11-1)
(def-sesion ses-efi-11-1-2 plan-efi-11-1)
(def-sesion ses-efi-11-2-1 plan-efi-11-2)
(def-sesion ses-efi-11-2-2 plan-efi-11-2)
(def-sesion ses-efi-11-3-1 plan-efi-11-3)
(def-sesion ses-efi-11-3-2 plan-efi-11-3)

;; 12mo grado
(def-sesion ses-mat-12-1-1 plan-mat-12-1)
(def-sesion ses-mat-12-1-2 plan-mat-12-1)
(def-sesion ses-mat-12-1-3 plan-mat-12-1)
(def-sesion ses-mat-12-1-4 plan-mat-12-1)
(def-sesion ses-mat-12-1-5 plan-mat-12-1)
(def-sesion ses-mat-12-2-1 plan-mat-12-2)
(def-sesion ses-mat-12-2-2 plan-mat-12-2)
(def-sesion ses-mat-12-2-3 plan-mat-12-2)
(def-sesion ses-mat-12-2-4 plan-mat-12-2)
(def-sesion ses-mat-12-2-5 plan-mat-12-2)
(def-sesion ses-mat-12-3-1 plan-mat-12-3)
(def-sesion ses-mat-12-3-2 plan-mat-12-3)
(def-sesion ses-mat-12-3-3 plan-mat-12-3)
(def-sesion ses-mat-12-3-4 plan-mat-12-3)
(def-sesion ses-mat-12-3-5 plan-mat-12-3)
(def-sesion ses-fis-12-1-1 plan-fis-12-1)
(def-sesion ses-fis-12-1-2 plan-fis-12-1)
(def-sesion ses-fis-12-1-3 plan-fis-12-1)
(def-sesion ses-fis-12-2-1 plan-fis-12-2)
(def-sesion ses-fis-12-2-2 plan-fis-12-2)
(def-sesion ses-fis-12-2-3 plan-fis-12-2)
(def-sesion ses-fis-12-3-1 plan-fis-12-3)
(def-sesion ses-fis-12-3-2 plan-fis-12-3)
(def-sesion ses-fis-12-3-3 plan-fis-12-3)
(def-sesion ses-inf-12-1-1 plan-inf-12-1)
(def-sesion ses-inf-12-1-2 plan-inf-12-1)
(def-sesion ses-inf-12-2-1 plan-inf-12-2)
(def-sesion ses-inf-12-2-2 plan-inf-12-2)
(def-sesion ses-inf-12-3-1 plan-inf-12-3)
(def-sesion ses-inf-12-3-2 plan-inf-12-3)
(def-sesion ses-lit-12-1-1 plan-lit-12-1)
(def-sesion ses-lit-12-1-2 plan-lit-12-1)
(def-sesion ses-lit-12-1-3 plan-lit-12-1)
(def-sesion ses-lit-12-1-4 plan-lit-12-1)
(def-sesion ses-lit-12-1-5 plan-lit-12-1)
(def-sesion ses-lit-12-2-1 plan-lit-12-2)
(def-sesion ses-lit-12-2-2 plan-lit-12-2)
(def-sesion ses-lit-12-2-3 plan-lit-12-2)
(def-sesion ses-lit-12-2-4 plan-lit-12-2)
(def-sesion ses-lit-12-2-5 plan-lit-12-2)
(def-sesion ses-lit-12-3-1 plan-lit-12-3)
(def-sesion ses-lit-12-3-2 plan-lit-12-3)
(def-sesion ses-lit-12-3-3 plan-lit-12-3)
(def-sesion ses-lit-12-3-4 plan-lit-12-3)
(def-sesion ses-lit-12-3-5 plan-lit-12-3)
(def-sesion ses-his-12-1-1 plan-his-12-1)
(def-sesion ses-his-12-1-2 plan-his-12-1)
(def-sesion ses-his-12-1-3 plan-his-12-1)
(def-sesion ses-his-12-1-4 plan-his-12-1)
(def-sesion ses-his-12-1-5 plan-his-12-1)
(def-sesion ses-his-12-2-1 plan-his-12-2)
(def-sesion ses-his-12-2-2 plan-his-12-2)
(def-sesion ses-his-12-2-3 plan-his-12-2)
(def-sesion ses-his-12-2-4 plan-his-12-2)
(def-sesion ses-his-12-2-5 plan-his-12-2)
(def-sesion ses-his-12-3-1 plan-his-12-3)
(def-sesion ses-his-12-3-2 plan-his-12-3)
(def-sesion ses-his-12-3-3 plan-his-12-3)
(def-sesion ses-his-12-3-4 plan-his-12-3)
(def-sesion ses-his-12-3-5 plan-his-12-3)
(def-sesion ses-cpo-12-1-1 plan-cpo-12-1)
(def-sesion ses-cpo-12-1-2 plan-cpo-12-1)
(def-sesion ses-cpo-12-2-1 plan-cpo-12-2)
(def-sesion ses-cpo-12-2-2 plan-cpo-12-2)
(def-sesion ses-cpo-12-3-1 plan-cpo-12-3)
(def-sesion ses-cpo-12-3-2 plan-cpo-12-3)
(def-sesion ses-ing-12-1-1 plan-ing-12-1)
(def-sesion ses-ing-12-1-2 plan-ing-12-1)
(def-sesion ses-ing-12-2-1 plan-ing-12-2)
(def-sesion ses-ing-12-2-2 plan-ing-12-2)
(def-sesion ses-ing-12-3-1 plan-ing-12-3)
(def-sesion ses-ing-12-3-2 plan-ing-12-3)
(def-sesion ses-bio-12-1-1 plan-bio-12-1)
(def-sesion ses-bio-12-1-2 plan-bio-12-1)
(def-sesion ses-bio-12-1-3 plan-bio-12-1)
(def-sesion ses-bio-12-2-1 plan-bio-12-2)
(def-sesion ses-bio-12-2-2 plan-bio-12-2)
(def-sesion ses-bio-12-2-3 plan-bio-12-2)
(def-sesion ses-bio-12-3-1 plan-bio-12-3)
(def-sesion ses-bio-12-3-2 plan-bio-12-3)
(def-sesion ses-bio-12-3-3 plan-bio-12-3)
(def-sesion ses-qui-12-1-1 plan-qui-12-1)
(def-sesion ses-qui-12-1-2 plan-qui-12-1)
(def-sesion ses-qui-12-1-3 plan-qui-12-1)
(def-sesion ses-qui-12-2-1 plan-qui-12-2)
(def-sesion ses-qui-12-2-2 plan-qui-12-2)
(def-sesion ses-qui-12-2-3 plan-qui-12-2)
(def-sesion ses-qui-12-3-1 plan-qui-12-3)
(def-sesion ses-qui-12-3-2 plan-qui-12-3)
(def-sesion ses-qui-12-3-3 plan-qui-12-3)
(def-sesion ses-efi-12-1-1 plan-efi-12-1)
(def-sesion ses-efi-12-1-2 plan-efi-12-1)
(def-sesion ses-efi-12-2-1 plan-efi-12-2)
(def-sesion ses-efi-12-2-2 plan-efi-12-2)
(def-sesion ses-efi-12-3-1 plan-efi-12-3)
(def-sesion ses-efi-12-3-2 plan-efi-12-3)


;; =====================================================================
;; DEFINICION DEL PROBLEMA
;; =====================================================================

(def-problema problema-saul
  :combinacion ubicacion
  :identidad sesion
  :variables (dia turno)
  :restricciones (restriccion-una-sesion-por-grupo
                  restriccion-una-sesion-por-profesor
                  restriccion-sin-repetir-asignatura-en-el-dia
                  restriccion-turno-doble-consecutivo
                  restriccion-sin-clases-el-dia-de-preparacion
                  restriccion-educacion-fisica-temprano
                  restriccion-tarde-solo-para-las-autorizadas
                  restriccion-contratado-solo-sus-dias
                  restriccion-frecuencia-exacta
                  restriccion-evitar-primer-turno-a-los-lejanos
                  restriccion-tope-diario-de-profesor))
