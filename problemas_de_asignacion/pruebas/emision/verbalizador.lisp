(in-package :pruebas-emision)

(defun documento-de (modelo &optional predicados)
  "Devuelve como texto el documento en español de MODELO."
  (with-output-to-string (flujo)
    (emitir (make-instance 'verbalizador :modelo modelo :predicados predicados) flujo)))

(defun ruta-de-dominio (dominio)
  "Devuelve la ruta del archivo de un dominio real."
  (merge-pathnames (format nil "../../dominios/~a/dominio.lisp" dominio) *aqui*))

(defun documento-del-dominio (dominio)
  "Devuelve el documento de un dominio real, con sus anotaciones, y su modelo."
  (let ((ruta (ruta-de-dominio dominio)))
    (let ((modelo (construir-modelo (cargar-dominio ruta))))
      (values (documento-de modelo (getf (cargar-anotaciones ruta) :predicados))
              modelo))))

(defun lineas-de (texto)
  "Devuelve las líneas no vacías de TEXTO."
  (remove "" (mapcar (lambda (linea) (string-right-trim '(#\Return) linea))
                     (uiop:split-string texto :separator '(#\Newline)))
          :test #'string=))

;; Las diferencias previstas con la referencia: dominio, línea vieja y línea nueva.
(defparameter *diferencias-previstas*
  '(("tesis"
     "**Días asistidos.** Se cuenta el número de días distintos en los que interviene."
     "**Días asistidos.** Se cuenta el número de fechas distintas en las que interviene.")
    ("tesis"
     "**Restricción minimizar carga máxima.** Se prefiere la solución que minimiza, para el profesor más cargado, el número de días distintos en los que interviene."
     "**Restricción minimizar carga máxima.** Se prefiere la solución que minimiza, para el profesor más cargado, el número de fechas distintas en las que interviene.")
    ("saul" "Una sesión tiene plan y número." "Una sesión tiene plan.")
    ("saul" "Una jornada tiene profesor, día y tope." nil)
    ("saul" "Hay 130 jornadas." nil)
    ("saul"
     "**Restricción tope diario de profesor.** El número de ubicaciones de cada jornada no puede superar su tope."
     "**Restricción tope diario de profesor.** El número de ubicaciones de cada profesor y cada día no puede superar 5.")))

(defun informar-diferencias (dominio texto)
  "Imprime lo que difiere de la referencia, sin contar lo previsto. Es un informe, no una condición."
  (let* ((referencia (uiop:read-file-string
                      (merge-pathnames (format nil "../referencia/~a/descripcion.md" dominio) *aqui*)
                      :external-format :utf-8))
         (viejas (lineas-de referencia))
         (nuevas (lineas-de texto))
         (previstas (remove dominio *diferencias-previstas* :key #'first :test-not #'string=)))
    (dolist (linea (set-difference viejas nuevas :test #'string=))
      (unless (find linea previstas :key #'second :test #'string=)
        (format t "diferencia de prosa, ~a, antes: ~a~%" dominio linea)))
    (dolist (linea (set-difference nuevas viejas :test #'string=))
      (unless (find linea previstas :key #'third :test #'equal)
        (format t "diferencia de prosa, ~a, ahora: ~a~%" dominio linea)))))

;; Lo que comprobaba el verbalizador sobre su propio documento, en los cinco dominios.
(dolist (dominio '("tv" "tesis" "docentes" "seder" "saul"))
  (multiple-value-bind (texto modelo) (documento-del-dominio dominio)
    (let ((emision::*verbalizador* (make-instance 'verbalizador :modelo modelo)))
      (no-contiene texto " de el " " a el " "NIL")
      ;; Toda entidad, consulta no mecánica y restricción aparece.
      (dolist (entidad (modelo-orden modelo))
        (assert (search (emision::nombre-prosa entidad) texto :test #'char-equal) ()
                "~a: falta la entidad ~a" dominio entidad))
      (dolist (restriccion (modelo-restricciones modelo))
        (assert (search (emision::nombre-prosa (restriccion-nombre restriccion)) texto
                        :test #'char-equal)
                () "~a: falta ~a" dominio restriccion))
      (dolist (consulta (set-difference (modelo-consultas modelo) (emision::mecanicas)))
        (assert (search (emision::nombre-prosa (consulta-nombre consulta)) texto :test #'char-equal)
                () "~a: falta ~a" dominio consulta))
      ;; Nadie se menciona antes de presentarse.
      (let ((orden (modelo-orden modelo)))
        (loop for (entidad . referidas) in (modelo-referencias modelo)
              do (dolist (referida referidas)
                   (assert (< (position referida orden) (position entidad orden)))))))
    ;; Las 26 restricciones se escriben con su frase, no nodo a nodo.
    (no-contiene texto "lo siguiente: el número de casos" "el número de casos," "maximiza el mínimo"
                 "No puede pasar lo siguiente" "Tiene que pasar lo siguiente"
                 "No debe pasar lo siguiente" "Sería bueno lo siguiente" "minimiza el máximo")
    (informar-diferencias dominio texto)))

;; Las anotaciones de Saúl hablan como predicados.
(let ((texto (documento-del-dominio "saul")))
  (contiene texto
            "Un plan tiene grupo, asignatura, profesor, aula y frecuencia, y dice si admite turno doble y si admite turnos de tarde."
            "Un profesor tiene nombre, y dice si vive lejos del centro y si es contratado."
            "**Dobles no consecutivos.** Se cuenta el número de pares de ubicaciones del mismo plan con el mismo día en turnos no consecutivos, cuando el plan admite turno doble."))
(assert (null (cargar-anotaciones (ruta-de-dominio "tv"))))

;; Morfología.
(let ((emision::*verbalizador* (make-instance 'verbalizador
                                     :modelo (modelo-de "(def-nppq r (op-mayor (de-dia d) 0) :para (d dia))" '("r"))
                                     :predicados '(("es-activo" "es activo")))))
  (flet ((nombre (texto &rest claves)
           (apply #'emision::nombre-prosa (intern texto :keyword) claves))
         (sintagma (texto &rest claves)
           (apply #'emision::sintagma (intern texto :keyword) claves)))
    (assert (equal (nombre "DIA") "día"))
    (assert (equal (nombre "DIA" :plural t) "días"))
    (assert (equal (nombre "RESTRICCION") "restricción"))
    (assert (equal (nombre "EMISOR" :plural t) "emisores"))
    (assert (equal (nombre "LUZ" :plural t) "luces"))
    (assert (equal (nombre "PLAN" :plural t) "planes"))
    (assert (equal (nombre "COLISION" :plural t) "colisiones"))
    (assert (equal (nombre "TIPO-PROGRAMA") "tipo de programa"))
    (assert (equal (nombre "TIPO-PROGRAMA" :plural t) "tipos de programa"))
    (assert (equal (nombre "EDUCACION-FISICA") "educación física"))
    (assert (equal (nombre "EDUCACION-FISICA" :plural t) "educaciones físicas"))
    (assert (equal (nombre "COLISIONES-DE-PROFESOR") "colisiones de profesor"))
    (assert (equal (nombre "UNO-DOS-TRES") "uno dos tres"))
    (assert (equal (nombre "ES-ACTIVO") "es activo"))
    (assert (equal (sintagma "AULA") "un aula"))
    (assert (equal (sintagma "AULA" :definido t) "el aula"))
    (assert (equal (sintagma "AULA" :definido t :plural t) "las aulas"))
    (assert (equal (sintagma "FECHA" :plural t) "unas fechas"))
    (assert (equal (sintagma "TURNO" :plural t) "unos turnos"))
    (assert (equal (sintagma "TIPO-PROGRAMA" :definido t) "el tipo de programa"))
    (assert (equal (sintagma "DIA-PREPARACION" :definido t) "el día de preparación"))
    (assert (equal (sintagma "CIUDAD") "una ciudad"))
    (assert (equal (emision::enumerar '("a")) "a"))
    (assert (equal (emision::enumerar '("a" "b" "c") "o") "a, b o c"))
    (assert (equal (emision::contraer "de el día a el turno") "del día al turno"))
    (assert (equal (emision::capitalizar "un tipo de programa") "Un tipo de programa"))
    (assert (equal (emision::numero->prosa 20) "veinte"))
    (assert (equal (emision::numero->prosa 21) "21"))))

;; Un dominio con otros nombres: cada familia, cada forma y la capa literal, con su frase exacta.
(let ((texto (documento-de (modelo-de "
(def-entidad ausencia () (dia turno))
(def-ausencia a1 lunes t1)
(def-consulta choque ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b)) (op-igual (turno a) (turno b))
                     (op-distinto (sesion a) (sesion b)))
  :operacion (suma 1))
(def-consulta choque-de-dato ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (profesor (sesion a)) (profesor (sesion b)))
                     (op-igual (dia a) (dia b))
                     (op-distinto (turno a) (turno b)))
  :operacion (suma 1))
(def-consulta choque-de-papel ()
  :itera-sobre (p profesor)
  :pares (a b) fila
  :comprueba (op-y (op-o (op-igual (profesor (sesion a)) p) (op-igual (profesor (sesion a)) p))
                     (op-o (op-igual (profesor (sesion b)) p) (op-igual (profesor (sesion b)) p))
                     (op-igual (dia a) (dia b)))
  :operacion (suma 1))
(def-consulta choque-con-filtro ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-igual (duracion (sesion a)) (duracion (sesion b)))
                     (op-mayor (duracion (sesion a)) 2))
  :operacion (suma 1))
(def-consulta consecutivas ()
  :itera-sobre (a fila) (b fila)
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-igual (op-suma (orden (turno a)) 1) (orden (turno b))))
  :operacion (suma 1))
(def-consulta no-consecutivas ()
  :itera-sobre (a fila) (b fila)
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-distinto (orden (turno a)) (op-suma (orden (turno b)) 1))
                     (op-mayor (orden (turno a)) (orden (turno b))))
  :operacion (suma 1))
(def-consulta tardias ()
  :itera-sobre (u fila)
  :comprueba (op-y (op-mayor (orden (turno u)) 3) (op-igual (dia u) lunes))
  :operacion (suma 1))
(def-consulta cruzadas ()
  :itera-sobre (u fila) (x ausencia)
  :comprueba (op-y (op-igual (dia u) (dia x)) (op-igual (turno u) (turno x)))
  :operacion (suma 1))
(def-consulta sin-frase ()
  :pares (a b) fila
  :comprueba (op-distinto (sesion a) (sesion b))
  :operacion (suma 1))
(def-consulta semanas-sin-parametro ()
  :itera-sobre (u fila)
  :comprueba (op-mayor (orden (turno u)) 0)
  :operacion (contar-distintos (semana (dia u))))
(def-consulta semanas-de-profesor (p)
  :itera-sobre (u fila)
  :comprueba (op-igual (profesor (sesion u)) p)
  :operacion (contar-distintos (semana (dia u))))
(def-consulta turnos-de-profesor (p)
  :itera-sobre (u fila)
  :comprueba (op-igual (profesor (sesion u)) p)
  :operacion (contar-distintos (turno u)))
(def-consulta choque-por-dia (d)
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) d) (op-igual (dia b) d) (op-igual (turno a) (turno b)))
  :operacion (suma 1))
(def-consulta sobrecarga (d)
  :itera-sobre (u fila)
  :comprueba (op-igual (dia u) d)
  :operacion (suma 1))
(def-consulta por-turno (x)
  :itera-sobre (u fila)
  :comprueba (op-igual (turno u) x)
  :operacion (suma 1))
(def-consulta por-dia-y-turno (d t2)
  :itera-sobre (u fila)
  :comprueba (op-y (op-igual (dia u) d) (op-igual (turno u) t2))
  :operacion (suma 1))
(def-consulta semanas-de-dos (p d)
  :itera-sobre (u fila)
  :comprueba (op-y (op-igual (profesor (sesion u)) p) (op-igual (dia u) d))
  :operacion (contar-distintos (semana (dia u))))
(def-consulta de-dia-y-turno (d t2)
  :itera-sobre (u fila)
  :comprueba (op-y (op-igual (dia u) d) (op-igual (turno u) t2))
  :operacion (suma 1))
(def-nppq r-choque (op-mayor (choque) 0))
(def-nppq r-dato (op-mayor (choque-de-dato) 0))
(def-nppq r-papel (op-mayor (choque-de-papel) 0))
(def-ndpq r-filtro (op-mayor (choque-con-filtro) 0))
(def-nppq r-consecutivas (op-mayor (consecutivas) 0))
(def-nppq r-no-consecutivas (op-mayor (no-consecutivas) 0))
(def-nppq r-tardias (op-mayor (tardias) 0))
(def-nppq r-cruzadas (op-mayor (cruzadas) 0))
(def-nppq r-sin-frase (op-mayor (sin-frase) 0))
(def-nppq r-semanas (op-mayor (semanas-sin-parametro) 0))
(def-tqpq r-mayor-uno (op-mayor-igual (tardias) 1))
(def-nppq r-al-menos-una (op-mayor-igual (tardias) 1))
(def-nppq r-al-reves (op-menor 0 (tardias)))
(def-nppq c-sobrecarga (op-mayor (sobrecarga d) 5) :para (d dia))
(def-minimizar o-turno (por-turno x) :para (x turno))
(def-minimizar o-por-dos (por-dia-y-turno d t2) :para (d dia) (t2 turno))
(def-minimizar o-semanas-de-dos (semanas-de-dos p d) :para (p profesor) (d dia))
(def-tqpq r-cero (op-menor-igual (tardias) 0))
(def-tqpq c-igual (op-igual (de-dia d) 2) :para (d dia))
(def-sbqp c-tope (op-menor-igual (de-dia d) 5) :para (d dia))
(def-sbqp c-dos (op-menor-igual (de-dia-y-turno d t2) 5) :para (d dia) (t2 turno))
(def-tqpq c-suelo (op-mayor-igual (de-dia d) 1) :para (d dia))
(def-tqpq c-menor (op-menor (de-dia d) 9) :para (d dia))
(def-tqpq c-mayor (op-mayor (de-dia d) 0) :para (d dia))
(def-tqpq c-atributo (op-igual (de-dia d) (numero (semana d))) :para (d dia))
(def-tqpq c-distinto (op-distinto (de-dia d) 2) :para (d dia))
(def-nppq c-prohibida (op-mayor (de-dia d) 5) :para (d dia))
(def-tqpq c-compuesta (op-igual (de-dia d) (op-suma 1 1)) :para (d dia))
(def-minimizar o-reparto (de-dia d) :para (d dia))
(def-minimizar o-cargado (semanas-de-profesor p) :para (p profesor))
(def-minimizar o-cargado-m (turnos-de-profesor p) :para (p profesor))
(def-minimizar o-afectado (choque-por-dia d) :para (d dia))
(def-minimizar o-otro-dominio (de-dia d) :para (d turno))
(def-maximizar o-maximizar (de-dia d) :para (d dia))
(def-minimizar o-sin-frase (op-suma (de-dia d) 1) :para (d dia))
(def-minimizar o-dos-variables (de-dia-y-turno d t2) :para (d dia) (t2 turno))
(def-tqpq g-tqpq (op-y (op-mayor (de-dia d) 0) (op-menor (de-dia d) 3)) :para (d dia))
(def-ndpq g-ndpq (op-o (op-mayor (tardias) 0) (op-no (op-menor (tardias) 3))))
(def-sbqp g-sbqp (op-mayor (op-resta (tardias) 1) (op-multiplicacion (tardias) (op-division 1 2))))
"
                                      '("r-choque" "r-dato" "r-papel" "r-filtro" "r-consecutivas"
                                        "r-no-consecutivas" "r-tardias" "r-cruzadas" "r-sin-frase"
                                        "r-semanas" "r-mayor-uno" "r-al-menos-una" "r-al-reves" "c-sobrecarga"
                                        "o-turno" "o-por-dos" "o-semanas-de-dos" "r-cero" "c-igual" "c-tope" "c-dos"
                                        "c-suelo" "c-menor" "c-mayor" "c-atributo" "c-distinto"
                                        "c-prohibida" "c-compuesta" "o-reparto" "o-cargado"
                                        "o-cargado-m" "o-afectado" "o-maximizar" "o-sin-frase"
                                        "o-dos-variables" "g-tqpq" "g-ndpq" "g-sbqp")))))
  (contiene texto
            ;; Datos y entidades.
            "Una vacia no tiene atributos."
            "Una fila está formada por una sesión, un día y un turno."
            "Hay dos semanas: 1 y 2."
            "Hay un aula: (nombre A1, edificio Norte, capacidad 30)."
            "Hay dos profesores: (nombre Peña \"Ana\", apellido Paz) y (nombre Luis, apellido Rey)."
            "Cada fila del horario es una fila. Se decide, para cada sesión, qué día y qué turno le corresponden."
            ;; Parejas, como oración y como sintagma.
            "No puede haber dos filas distintas con el mismo día y el mismo turno."
            "Se cuenta el número de pares de filas distintas con el mismo día y el mismo turno."
            "No puede haber dos filas de turnos distintos del mismo profesor con el mismo día."
            "No puede haber dos filas que compartan un profesor con el mismo día."
            "No debe pasar"
            "No puede haber dos filas consecutivas con el mismo día."
            "No puede haber dos filas con el mismo día en turnos no consecutivos."
            ;; Filas y cruces.
            "Ninguna fila puede cumplir lo siguiente: el orden de su turno es mayor que 3 y su día es igual a Lunes."
            "Se cuenta el número de filas en que el orden de su turno es mayor que 3 y su día es igual a Lunes."
            "Ninguna fila puede coincidir con una ausencia en el día y el turno."
            "Se cuenta el número de filas que coinciden con una ausencia en el día y el turno."
            ;; Capa literal de consultas.
            "No puede pasar lo siguiente: el número de casos, para cada fila a y cada fila b, en que la sesión de a es diferente de la sesión de b es mayor que 0."
            "Se cuenta el número de casos, para cada fila a y cada fila b, en que la sesión de a es diferente de la sesión de b."
            "No puede pasar lo siguiente: el número de semanas distintas, para cada fila u, en que el orden del turno de u es mayor que 0 es mayor que 0."
            "Se cuenta el número de semanas distintas, para cada fila u, en que el orden del turno de u es mayor que 0."
            ;; Cuantificadores: lo que no es (op-mayor consulta 0) no usa la frase de la familia.
            "Tiene que pasar lo siguiente: el número de casos, para cada fila u, en que el orden del turno de u es mayor que 3 y el día de u es igual a Lunes es menor o igual que 0."
            ;; Cotas.
            "**C igual.** El número de filas de cada día debe ser igual a 2."
            "**C de tope.** El número de filas de cada día no puede superar 5."
            "**C de dos.** El número de filas de cada día y cada turno no puede superar 5."
            "**C de suelo.** El número de filas de cada día no puede quedar por debajo de 1."
            "**C de menor.** El número de filas de cada día tiene que ser menor que 9."
            "**C de mayor.** El número de filas de cada día tiene que ser mayor que 0."
            "**C de atributo.** El número de filas de cada día debe ser igual a su número."
            "**C de distinto.** Tiene que pasar lo siguiente: el número de casos, dado d, para cada fila u, en que el día de u es igual a d es diferente de 2."
            "**C prohibida.** No puede pasar lo siguiente: el número de casos, dado d, para cada fila u, en que el día de u es igual a d es mayor que 5."
            "**C de compuesta.** Tiene que pasar lo siguiente: el número de casos, dado d, para cada fila u, en que el día de u es igual a d es igual a la suma de 1 y 1."
            ;; Objetivos.
            "**O reparto.** Se prefiere el reparto que reduce el número máximo de sesiones en un mismo día."
            "**O cargado.** Se prefiere la solución que minimiza, para el profesor más cargado, el número de semanas distintas en las que interviene."
            "**O cargado m.** Se prefiere la solución que minimiza, para el profesor más cargado, el número de turnos distintos en los que interviene."
            "**O afectado.** Se prefiere la solución que minimiza, para el día más afectado, el número de pares de filas con el mismo turno y el mismo día."
            "**O maximizar.** Se prefiere la solución que maximiza el mínimo, entre los días, del número de casos, dado d, para cada fila u, en que el día de u es igual a d."
            "**O sin frase.** Se prefiere la solución que minimiza el máximo, entre los días, de la suma del número de casos,"
            "**O dos variables.** Se prefiere la solución que minimiza el máximo, entre los días y los turnos, del número de casos,"
            "**R al menos una.** No puede pasar lo siguiente: el número de casos, para cada fila u, en que el orden del turno de u es mayor que 3 y el día de u es igual a Lunes es mayor o igual que 1."
            "**R al reves.** No puede pasar lo siguiente: 0 es menor que el número de casos,"
            "**O turno.** Se prefiere el reparto que reduce el número máximo de sesiones en un mismo turno."
            "**Por turno.** Se cuenta el número de sesiones que caen en un mismo turno."
            "**Por día y turno.** Se cuenta el número de filas en que su día es igual a d y su turno es igual a t2."
            "**O semanas de dos.** Se prefiere la solución que minimiza el máximo, entre los profesores y los días, del número de semanas distintas,"
            ;; La medida de una prohibición con :para sí se lista.
            "**Sobrecarga.** Se cuenta"
            ;; Medidas de las cotas: no se listan.
            "**Tardias.** Se cuenta"
            "### Preferencias"
            ;; Genéricas.
            "**G de tqpq.** Tiene que pasar lo siguiente: "
            "**G de ndpq.** No debe pasar lo siguiente: "
            "no se cumple que"
            "**G de sbqp.** Sería bueno lo siguiente: la diferencia entre "
            "el producto del "
            "el cociente de 1 entre 2")
  (no-contiene texto "**De día.**" "**De día y turno.**"))

;; Una dimensión que no es la entidad recorrida no puede usar la frase del reparto.
(let ((texto (documento-de (construir-modelo (pruebas-dsl::carga "
(def-entidad persona () (nombre))
(def-entidad sesion () (tutor))
(def-entidad dia () (nombre))
(def-comb fila (sesion dia))
(def-persona ana \"Ana\")
(def-sesion s1 ana)
(def-dia lunes \"Lunes\")
(def-consulta por-tutor (p)
  :itera-sobre (u fila)
  :comprueba (op-igual (tutor (sesion u)) p)
  :operacion (suma 1))
(def-minimizar o-tutor (por-tutor p) :para (p persona))
(def-problema el-problema :combinacion fila :identidad sesion :variables (dia)
  :restricciones (o-tutor))")))))
  (contiene texto
            "**O tutor.** Se prefiere la solución que minimiza el máximo, entre las personas, del número de casos,"
            "**Por tutor.** Se cuenta el número de sesiones que caen en un mismo tutor."))

;; Lo que escribe exportar, con las anotaciones de Saúl.
(let ((ruta (ruta-de-dominio "saul")))
  (con-carpeta (carpeta)
    (exportar (construir-modelo (cargar-dominio ruta)) carpeta (cargar-anotaciones ruta))
    (contiene (uiop:read-file-string (merge-pathnames "descripcion.md" carpeta)
                                     :external-format :utf-8)
              "y dice si vive lejos del centro")
    (contiene (uiop:read-file-string (merge-pathnames "modelo.tex" carpeta)
                                     :external-format :utf-8)
              "\\subsubsection*{Sujeto a}")
    (contiene (uiop:read-file-string (merge-pathnames "modelo.py" carpeta)
                                     :external-format :utf-8)
              "def evaluar(horario):")))

;; Unas anotaciones mal formadas se rechazan.
(con-carpeta (carpeta)
  (ensure-directories-exist carpeta)
  (with-open-file (flujo (merge-pathnames "verbalizador.lisp" carpeta)
                         :direction :output :external-format :utf-8)
    (write-string "(:predicados ((\"a\" 1)))" flujo))
  (handler-case (progn (cargar-anotaciones (merge-pathnames "dominio.lisp" carpeta))
                       (error "No se rechazaron las anotaciones"))
    (error-dsl ())))
