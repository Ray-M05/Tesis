;; =====================================================================
;; DOMINIO: HORARIO DE EDUCACION FISICA DEL SEDER
;; Un solo dia a la semana, tres turnos, semana par y semana impar
;; =====================================================================
;; Este archivo solo DECLARA. No carga infraestructura, no genera codigo
;; y no imprime nada. El orden de carga y los efectos viven en run.lisp.
;;
;; Derivado de generador-horarios/seder/dominio.lisp del proyecto principal,
;; quitando los load, mostrar-problema, generar-python y sb-ext:exit. Si uno
;; de los dos cambia hay que volver a derivarlo.
;;
;; La descripcion de partida es descripcion-seder.md. Los datos son un juego
;; de ejemplo: los reales estan pendientes (datos-seder.md).
;; =====================================================================

;; -- Cargar infraestructura -----------------------------------------

;; =====================================================================
;; MIXINS
;; =====================================================================

(defclass* tiene-nombre ()
  (nombre))


;; =====================================================================
;; ENTIDADES ENUMERADAS
;; =====================================================================

;; Turno de clase. La descripcion los llama horarios: las diez, las once y
;; las tres. Aqui se llaman turnos porque 'horario' es el nombre de la clase
;; Python que representa el horario completo, y una entidad con ese nombre
;; generaria una clase Horario que tapa la del generador.
;; El orden es lo unico del reloj que entra en el modelo.
(def-entidad turno (tiene-nombre) (orden))

;; Instalacion donde se da la clase, con su capacidad en estudiantes.
(def-entidad instalacion (tiene-nombre) (capacidad))


;; =====================================================================
;; ENTIDADES DEL DOMINIO
;; =====================================================================

;; Carrera. Solo lleva nombre: desde que cada anno declara su paridad y sus
;; turnos, la carrera no tiene ningun dato propio. Se conserva porque el anno
;; necesita decir a que carrera pertenece y porque la salida nombra carreras.
(def-entidad carrera (tiene-nombre))

;; Anno de una carrera. Declara las dos cosas que antes declaraba la carrera:
;;   paridad   0 = semana par, 1 = semana impar
;; Los turnos disponibles NO viven aqui: ver la entidad indisponibilidad.
;; El nombre es imprescindible, no decorativo. El Python generado compara las
;; entidades por valor, asi que sin el, el primero y el segundo anno de una
;; carrera que coincidieran en paridad serian el mismo anno para el generador,
;; y las indisponibilidades de uno se aplicarian al otro. Paso de verdad con
;; Computacion (los dos annos en semana par) y con Fisica (los dos en impar).
(def-entidad anno (tiene-nombre) (carrera paridad))

;; Profesor. Viene asignado a sus brigadas; el generador no lo decide.
(def-entidad profesor (tiene-nombre))

;; Brigada. Es la identidad del horario: hay una ubicacion por brigada.
;; Lleva su anno, su profesor y su cantidad de estudiantes.
(def-entidad brigada (tiene-nombre) (anno profesor cantidad))

;; Indisponibilidad: un turno que un anno NO tiene disponible.
;; Se declaran las indisponibilidades y no las disponibilidades porque el
;; lenguaje cuenta coincidencias: "existe una indisponibilidad que casa con
;; esta ubicacion" es contable, "no existe ninguna disponibilidad que case"
;; no lo es. Es el mismo recurso que la entidad ausencia del dominio de Saul,
;; que declara los dias en que un profesor contratado NO asiste.
;; Un anno que declara los tres turnos no genera ninguna indisponibilidad.
(def-entidad indisponibilidad () (anno turno))


;; =====================================================================
;; ENTIDAD COMBINACION: UBICACION
;; Una ubicacion = una brigada + donde y cuando recibe su clase
;; =====================================================================

(def-comb ubicacion (brigada turno instalacion))


;; =====================================================================
;; CONSULTAS Y RESTRICCIONES
;; =====================================================================

;; -- Restricciones duras --------------------------------------------

;; 1. Una brigada solo recibe clase en un turno que su anno tenga disponible.
(def-consulta clases-en-turno-no-disponible ()
  :itera-sobre (u ubicacion) (i indisponibilidad)
  :comprueba
  (op-and (op-igual (anno (brigada u)) (anno i))
          (op-igual (turno u)          (turno i)))
  :operacion suma
  :devuelve 1)

(defvar restriccion-solo-turnos-disponibles
  (def-nppq (op-mayor clases-en-turno-no-disponible 0)))


;; 2. Una brigada no puede recibir clase en una instalacion cuya capacidad
;;    sea menor que su cantidad de estudiantes.
;;    Compara dos numeros que son dato: la cantidad de la brigada, que es la
;;    identidad, y la capacidad de la instalacion, que es el valor elegido.
(def-consulta brigadas-que-no-caben ()
  :itera-sobre (u ubicacion)
  :comprueba
  (op-mayor (cantidad (brigada u)) (capacidad (instalacion u)))
  :operacion suma
  :devuelve 1)

(defvar restriccion-la-brigada-cabe
  (def-nppq (op-mayor brigadas-que-no-caben 0)))


;; 3. Dos brigadas no pueden usar la misma instalacion en el mismo turno de la
;;    misma paridad.
;;    La paridad es dato y entra como una igualdad mas: dos brigadas de semanas
;;    distintas nunca coinciden, asi que la paridad duplica la capacidad del
;;    sistema sin que el generador decida nada.
(def-consulta colisiones-de-instalacion ()
  :itera-sobre (u1 ubicacion) (u2 ubicacion)
  :comprueba
  (op-and (op-igual    (instalacion u1) (instalacion u2))
          (op-igual    (turno u1) (turno u2))
          (op-igual    (paridad (anno (brigada u1)))
                       (paridad (anno (brigada u2))))
          (op-distinto (brigada u1) (brigada u2)))
  :operacion suma
  :devuelve 1)

(defvar restriccion-una-brigada-por-instalacion
  (def-nppq (op-mayor colisiones-de-instalacion 0)))


;; 4. Un profesor no puede dar clase a dos brigadas en el mismo turno de la
;;    misma paridad.
;;    Se itera explicitamente sobre (p profesor) para que 'profesor' quede
;;    registrado como dominio del Horario.
(def-consulta colisiones-de-profesor ()
  :itera-sobre (p profesor) (u1 ubicacion) (u2 ubicacion)
  :comprueba
  (op-and (op-igual    (profesor (brigada u1)) p)
          (op-igual    (profesor (brigada u2)) p)
          (op-igual    (turno u1) (turno u2))
          (op-igual    (paridad (anno (brigada u1)))
                       (paridad (anno (brigada u2))))
          (op-distinto (brigada u1) (brigada u2)))
  :operacion suma
  :devuelve 1)

(defvar restriccion-un-profesor-por-turno
  (def-nppq (op-mayor colisiones-de-profesor 0)))


;; NOTA: "cada brigada recibe exactamente una clase a la semana" no se declara.
;; Es estructural: hay una ubicacion por brigada y toda identidad recibe valor,
;; asi que el conteo da siempre uno y la restriccion no se puede incumplir.
;; Tampoco se puede escribir. Habria que cuantificarla sobre la brigada con
;; def-tqpq, y la brigada es el slot identidad: el generador excluye la
;; identidad de los dominios del Horario, de modo que el bucle saldria como
;; "for b in horario.brigada" sobre un campo que la clase Horario no tiene.
;; En el dominio de Saul la restriccion equivalente si se declara porque alli
;; se cuantifica sobre el plan, que no es la identidad.


;; -- Restricciones blandas ------------------------------------------

;; Brigadas que acaban en una instalacion concreta.
(def-consulta brigadas-de-la-instalacion (inst)
  :itera-sobre (u ubicacion)
  :comprueba
  (op-igual (instalacion u) inst)
  :operacion suma
  :devuelve 1)

;; Equilibrar la ocupacion entre instalaciones: minimizar el maximo numero de
;; brigadas que recibe una instalacion.
;; Se equilibra en numero de brigadas y no en estudiantes porque el generador
;; ignora el :devuelve de la consulta y siempre incrementa de uno en uno.
(defvar restriccion-equilibrar-instalaciones
  (def-minimizar brigadas-de-la-instalacion instalacion))


;; Brigadas que acaban en un turno concreto.
(def-consulta brigadas-del-turno (tur)
  :itera-sobre (u ubicacion)
  :comprueba
  (op-igual (turno u) tur)
  :operacion suma
  :devuelve 1)

;; Equilibrar la carga entre turnos: minimizar el maximo numero de brigadas
;; que cae en un mismo turno.
;; Las dos blandas comparten el peso PESO_BLANDA: el objetivo del generador es
;; plano y no se pueden ponderar una contra otra.
(defvar restriccion-equilibrar-turnos
  (def-minimizar brigadas-del-turno turno))


;; =====================================================================
;; DATOS CONCRETOS
;; Juego de ejemplo. Pendiente de los datos reales (datos-seder.md).
;; =====================================================================

;; ---- Turnos ------------------------------------------------------
(def-turno t-10 "10:00" 1)
(def-turno t-11 "11:00" 2)
(def-turno t-15 "15:00" 3)

;; ---- Instalaciones: nombre y capacidad en estudiantes ------------
(def-instalacion inst-futbol    "Terreno de fútbol"      60)
(def-instalacion inst-beisbol   "Terreno de béisbol"     55)
(def-instalacion inst-atletismo "Pista de atletismo"     50)
(def-instalacion inst-gimnasio  "Gimnasio"               45)
(def-instalacion inst-baloncest "Cancha de baloncesto"   40)
(def-instalacion inst-voleibol  "Cancha de voleibol"     35)
(def-instalacion inst-piscina   "Piscina"                30)
(def-instalacion inst-pesas     "Sala de pesas"          25)

;; ---- Carreras ----------------------------------------------------
(def-carrera carr-mat "Matemática")
(def-carrera carr-com "Computación")
(def-carrera carr-fis "Física")
(def-carrera carr-qui "Química")
(def-carrera carr-bio "Biología")
(def-carrera carr-geo "Geografía")

;; ---- Annos: nombre, carrera y paridad (0 = par, 1 = impar) -------
(def-anno anno-mat-1 "1ro" carr-mat 0)
(def-anno anno-mat-2 "2do" carr-mat 1)
(def-anno anno-com-1 "1ro" carr-com 0)
(def-anno anno-com-2 "2do" carr-com 0)
(def-anno anno-fis-1 "1ro" carr-fis 1)
(def-anno anno-fis-2 "2do" carr-fis 1)
(def-anno anno-qui-1 "1ro" carr-qui 0)
(def-anno anno-qui-2 "2do" carr-qui 1)
(def-anno anno-bio-1 "1ro" carr-bio 1)
(def-anno anno-bio-2 "2do" carr-bio 0)
(def-anno anno-geo-1 "1ro" carr-geo 0)
(def-anno anno-geo-2 "2do" carr-geo 1)

;; ---- Indisponibilidades: turno que un anno NO tiene disponible ---
;; mat-1 da a las 10 y a las 11
(def-indisponibilidad indisp-mat-1-t15 anno-mat-1 t-15)
;; mat-2 da a las 11 y a las 15
(def-indisponibilidad indisp-mat-2-t10 anno-mat-2 t-10)
;; com-1 da en los tres turnos: sin indisponibilidades
;; com-2 solo da a las 10
(def-indisponibilidad indisp-com-2-t11 anno-com-2 t-11)
(def-indisponibilidad indisp-com-2-t15 anno-com-2 t-15)
;; fis-1 da a las 10 y a las 15
(def-indisponibilidad indisp-fis-1-t11 anno-fis-1 t-11)
;; fis-2 da en los tres turnos: sin indisponibilidades
;; qui-1 da a las 11 y a las 15
(def-indisponibilidad indisp-qui-1-t10 anno-qui-1 t-10)
;; qui-2 da a las 10 y a las 11
(def-indisponibilidad indisp-qui-2-t15 anno-qui-2 t-15)
;; bio-1 solo da a las 15
(def-indisponibilidad indisp-bio-1-t10 anno-bio-1 t-10)
(def-indisponibilidad indisp-bio-1-t11 anno-bio-1 t-11)
;; bio-2 da en los tres turnos: sin indisponibilidades
;; geo-1 da a las 10 y a las 11
(def-indisponibilidad indisp-geo-1-t15 anno-geo-1 t-15)
;; geo-2 da a las 11 y a las 15
(def-indisponibilidad indisp-geo-2-t10 anno-geo-2 t-10)

;; ---- Profesores --------------------------------------------------
;; Cada profesor lleva dos brigadas de la misma paridad. Es lo que hace que
;; la restriccion de choque de profesor tenga algo que restringir: si cada
;; brigada tuviera profesor propio, la restriccion no prohibiria nada.
(def-profesor prof-01 "profesor_01")
(def-profesor prof-02 "profesor_02")
(def-profesor prof-03 "profesor_03")
(def-profesor prof-04 "profesor_04")
(def-profesor prof-05 "profesor_05")
(def-profesor prof-06 "profesor_06")
(def-profesor prof-07 "profesor_07")
(def-profesor prof-08 "profesor_08")
(def-profesor prof-09 "profesor_09")
(def-profesor prof-10 "profesor_10")
(def-profesor prof-11 "profesor_11")
(def-profesor prof-12 "profesor_12")

;; ---- Brigadas: nombre, anno, profesor, cantidad ------------------
;; Semana par
(def-brigada br-mat-1-a "MAT-1-A" anno-mat-1 prof-01 32)
(def-brigada br-mat-1-b "MAT-1-B" anno-mat-1 prof-02 30)
(def-brigada br-com-1-a "COM-1-A" anno-com-1 prof-01 28)
(def-brigada br-com-1-b "COM-1-B" anno-com-1 prof-05 26)
(def-brigada br-com-2-a "COM-2-A" anno-com-2 prof-03 35)
(def-brigada br-com-2-b "COM-2-B" anno-com-2 prof-04 33)
(def-brigada br-qui-1-a "QUI-1-A" anno-qui-1 prof-03 24)
(def-brigada br-qui-1-b "QUI-1-B" anno-qui-1 prof-04 22)
(def-brigada br-bio-2-a "BIO-2-A" anno-bio-2 prof-02 30)
(def-brigada br-bio-2-b "BIO-2-B" anno-bio-2 prof-06 28)
(def-brigada br-geo-1-a "GEO-1-A" anno-geo-1 prof-05 25)
(def-brigada br-geo-1-b "GEO-1-B" anno-geo-1 prof-06 23)

;; Semana impar
(def-brigada br-mat-2-a "MAT-2-A" anno-mat-2 prof-07 34)
(def-brigada br-mat-2-b "MAT-2-B" anno-mat-2 prof-08 31)
(def-brigada br-fis-1-a "FIS-1-A" anno-fis-1 prof-07 27)
(def-brigada br-fis-1-b "FIS-1-B" anno-fis-1 prof-08 25)
(def-brigada br-fis-2-a "FIS-2-A" anno-fis-2 prof-09 29)
(def-brigada br-fis-2-b "FIS-2-B" anno-fis-2 prof-10 27)
(def-brigada br-qui-2-a "QUI-2-A" anno-qui-2 prof-11 22)
(def-brigada br-qui-2-b "QUI-2-B" anno-qui-2 prof-12 20)
(def-brigada br-bio-1-a "BIO-1-A" anno-bio-1 prof-09 38)
(def-brigada br-bio-1-b "BIO-1-B" anno-bio-1 prof-10 36)
(def-brigada br-geo-2-a "GEO-2-A" anno-geo-2 prof-11 26)
(def-brigada br-geo-2-b "GEO-2-B" anno-geo-2 prof-12 24)


;; =====================================================================
;; PROBLEMA
;; =====================================================================

(defvar problema-seder
  (def-problema-horario
    ;; Entidad combinacion: lo que constituye una fila del horario
    :entidad-horario   'ubicacion
    ;; Slot identidad: hay una ubicacion POR brigada
    :slot-identidad    'brigada
    ;; Slots variables: el GA elige turno e instalacion para cada brigada
    :slots-variables   '(turno instalacion)
    ;; Consultas registradas en el AST
    :consultas         '(clases-en-turno-no-disponible
                         brigadas-que-no-caben
                         colisiones-de-instalacion
                         colisiones-de-profesor
                         brigadas-de-la-instalacion
                         brigadas-del-turno)
    ;; Restricciones duras
    :restricciones-duras   '(restriccion-solo-turnos-disponibles
                             restriccion-la-brigada-cabe
                             restriccion-una-brigada-por-instalacion
                             restriccion-un-profesor-por-turno)
    ;; Restricciones blandas
    :restricciones-blandas '(restriccion-equilibrar-instalaciones
                             restriccion-equilibrar-turnos)
    :peso-dura   1000
    :peso-blanda    1))


;; =====================================================================
;; GENERAR CODIGO PYTHON
;; =====================================================================
