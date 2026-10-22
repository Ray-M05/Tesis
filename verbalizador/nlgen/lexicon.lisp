;; =====================================================================
;; lexicon.lisp — Morfologia espanola y nombres de simbolos
;; =====================================================================
;; El equivalente de math-nombre (gen-utils.lisp), pero para prosa.
;; math-nombre solo hace string-downcase y - -> _, y produce
;; "tipo_programa". Para escribir espanol hace falta genero, numero y
;; articulo: un programa pero una emision, los bloques pero las fechas.
;;
;; Contiene tambien el registro de consultas (nodo -> simbolo), que en
;; el proyecto original vive en gen-ast-python.lisp guardando el nombre
;; ya convertido a identificador Python. Aqui se guarda el simbolo Lisp,
;; para poder lexicalizarlo.
;;

;; =====================================================================
;; UTILIDADES DE CADENA
;; =====================================================================

(defun replace-all (cadena patron reemplazo)
  "Reemplaza todas las apariciones de PATRON por REEMPLAZO en CADENA."
  (if (zerop (length patron))
      cadena
      (with-output-to-string (out)
        (loop with n = (length patron)
              for inicio = 0 then (+ pos n)
              for pos = (search patron cadena :start2 inicio)
              do (write-string cadena out :start inicio :end (or pos (length cadena)))
                 (when (null pos) (loop-finish))
                 (write-string reemplazo out)))))

(defun sufijo-p (palabra sufijo)
  "T si PALABRA termina en SUFIJO."
  (let ((lp (length palabra)) (ls (length sufijo)))
    (and (>= lp ls) (string= sufijo palabra :start2 (- lp ls)))))

(defun contract (cadena)
  "Contracciones del espanol: 'de el' -> 'del', 'a el' -> 'al'.
   Se aplica al final, sobre la cadena ya compuesta. Es idempotente."
  (let ((s (concatenate 'string " " cadena " ")))
    (string-trim " "
      (replace-all (replace-all s " de el " " del ")
                   " a el " " al "))))

(defun split-char (cadena ch)
  "Parte CADENA por CH.  \"a-b-c\" -> (\"a\" \"b\" \"c\")"
  (let ((partes '()) (inicio 0))
    (loop for pos = (position ch cadena :start inicio)
          do (push (subseq cadena inicio (or pos (length cadena))) partes)
             (if pos (setf inicio (1+ pos)) (return)))
    (nreverse partes)))

(defun join-nl (items &optional (conjuncion "y"))
  "(a b c) -> \"a, b y c\".  Enumeracion en espanol."
  (cond ((null items)       "")
        ((null (cdr items)) (first items))
        (t (format nil "~{~a~^, ~} ~a ~a"
                   (butlast items) conjuncion (car (last items))))))


;; =====================================================================
;; TABLA DE EXCEPCIONES
;; =====================================================================
;; Solo entra aqui lo que las reglas NO aciertan. Tres motivos posibles:
;;   - acentos, que los simbolos del DSL no llevan  (dia -> dia acentuado)
;;   - genero contra la regla                       (programa es masculino)
;;   - plural irregular                             (orden -> ordenes)
;;   - preposicion interna                          (tipo-programa)

(defvar *lexicon* (make-hash-table)
  "Simbolo -> plist (:sing :plur :gen). Excepciones a las reglas.")

(defun def-word (sym &key sing plur gen art-m)
  "ART-M fuerza articulo masculino en singular. Es la regla del espanol
   para los femeninos que empiezan por a tonica: 'el aula', 'un aula',
   pero 'las aulas' y 'la misma aula'."
  (setf (gethash sym *lexicon*)
        (append (when sing  (list :sing sing))
                (when plur  (list :plur plur))
                (when gen   (list :gen  gen))
                (when art-m (list :art-m t)))))

(defun lex (sym clave)
  (getf (gethash sym *lexicon*) clave))

;; --- Excepciones comunes a los dominios -----------------------------
;; tipo-programa ya NO necesita entrada: la regla de compuestos nominales
;; produce "tipo de programa" y el genero sale del nucleo.
(def-word 'dia           :sing "día"              :plur "días"              :gen :m)
(def-word 'programa      :sing "programa"         :plur "programas"         :gen :m)
(def-word 'emision       :sing "emisión"          :plur "emisiones"         :gen :f)
(def-word 'duracion      :sing "duración"         :plur "duraciones"        :gen :f)
(def-word 'codigo        :sing "código"           :plur "códigos"           :gen :m)
(def-word 'orden         :sing "orden"            :plur "órdenes"           :gen :m)
;; tesis / docentes
(def-word 'asignacion    :sing "asignación"       :plur "asignaciones"      :gen :f)
(def-word 'sesion        :sing "sesión"           :plur "sesiones"          :gen :f)
(def-word 'dias          :sing "días"             :plur "días"              :gen :m)
(def-word 'clase         :sing "clase"            :plur "clases"            :gen :f)
(def-word 'aula          :sing "aula"             :plur "aulas"             :gen :f
                                                                            :art-m t)
(def-word 'anno          :sing "año"              :plur "años"              :gen :m)


;; =====================================================================
;; ORTOGRAFIA POR PALABRA
;; =====================================================================
;; *lexicon* indexa el simbolo ENTERO, y por eso no llega a los simbolos
;; compuestos: restriccion-sin-mismo-tipo-consecutivo tendria que estar
;; escrito completo en la tabla para que "restriccion" saliera acentuado.
;; Esta tabla trabaja palabra a palabra sobre los segmentos del simbolo,
;; asi que una entrada sirve para todos los simbolos que la contengan.
;;
;; Solo ortografia: no dice nada de genero ni de numero.

(defvar *spelling* (make-hash-table :test #'equal)
  "Palabra sin acento -> palabra acentuada.")

(defun def-spelling (&rest pares)
  (loop for (sin con) on pares by #'cddr
        do (setf (gethash sin *spelling*) con)))

;; Solo lo que la regla de abajo no alcanza.
(def-spelling
  "dia"    "día"      "dias"    "días"     "codigo"   "código"
  "numero" "número"   "ultimo"  "último"   "practica" "práctica"
  "maxima" "máxima"   "minima"  "mínima"
  "maximo" "máximo"   "minimo"  "mínimo"
  ;; Esdrujulas en -ico/-ica, que ninguna regla de terminacion alcanza
  ;; porque la terminacion por si sola no dice donde cae el acento.
  "fisica"      "física"      "fisicas"      "físicas"
  "politica"    "política"    "politicas"    "políticas"
  "quimica"     "química"     "matematica"   "matemática"
  "informatica" "informática" "artistica"    "artística"
  "practico"    "práctico"    "teorica"      "teórica"
  ;; Otras
  "biologia"  "biología"   "geografia" "geografía"
  "ingles"    "inglés"     "miercoles" "miércoles"
  "sabado"    "sábado"     "examen"    "examen")

(defun spell (palabra)
  "Ortografia de una palabra suelta. La tabla manda; si no hay entrada,
   se aplica la regla -cion/-sion -> -ción/-sión, que en espanol es muy
   productiva y cubre restriccion, repeticion, emision, asignacion,
   duracion, sesion, colision... sin una entrada por cada una.
   Los plurales no la disparan ('colisiones' ya es correcto)."
  (or (gethash palabra *spelling*)
      (let ((n (length palabra)))
        (cond ((sufijo-p palabra "cion")
               (concatenate 'string (subseq palabra 0 (- n 4)) "ción"))
              ((sufijo-p palabra "sion")
               (concatenate 'string (subseq palabra 0 (- n 4)) "sión"))
              (t palabra)))))


;; =====================================================================
;; REGLAS DE MORFOLOGIA
;; =====================================================================

(defun pluralizar (palabra)
  "Plural regular del espanol."
  (let ((n (length palabra)))
    (cond ((zerop n) palabra)
          ;; emisión -> emisiones  (cae el acento)
          ((sufijo-p palabra "ión")
           (concatenate 'string (subseq palabra 0 (- n 3)) "iones"))
          ;; vez -> veces
          ((sufijo-p palabra "z")
           (concatenate 'string (subseq palabra 0 (1- n)) "ces"))
          ;; vocal -> +s ; consonante -> +es
          ((find (char palabra (1- n)) "aeiouáéíóu") (concatenate 'string palabra "s"))
          (t (concatenate 'string palabra "es")))))

;; =====================================================================
;; PREDICADOS
;; =====================================================================
;; Un slot booleano 0/1 no es un sustantivo: es algo que la entidad HACE
;; o ES. Ninguna regla puede deducir de ADMITE-DOBLE que "admite" es un
;; verbo, asi que es un hecho lexico y vive en una tabla, igual que las
;; excepciones de genero. Lo usan dos sitios: expr.lisp, para convertir
;; (op-igual (admite-doble x) 0) en "x no admite turno doble", y
;; document.lisp, para listar estos slots aparte en la seccion Entidades.

(defvar *predicates* (make-hash-table)
  "Simbolo de slot booleano -> frase verbal en afirmativo.")

(defun def-predicate (sym frase)
  (setf (gethash sym *predicates*) frase))

(defun predicate-phrase (sym &key negated)
  (let ((f (gethash sym *predicates*)))
    (when f (if negated (concatenate 'string "no " f) f))))

(def-predicate 'admite-doble     "admite turno doble")
(def-predicate 'admite-tarde     "admite turnos de tarde")
(def-predicate 'vive-lejos       "vive lejos del centro")
(def-predicate 'es-contratado    "es contratado")
(def-predicate 'educacion-fisica "es educación física")


;; =====================================================================
;; COMPUESTOS
;; =====================================================================
;; Un simbolo de varios segmentos puede ser tres cosas distintas, y el
;; espanol las escribe de tres formas:
;;
;;   frase ya hecha por el autor   colisiones-de-profesor -> tal cual
;;   sustantivo + adjetivo         educacion-fisica       -> yuxtapuestos
;;   sustantivo + sustantivo       dia-preparacion        -> con "de"
;;
;; Las dos primeras se detectan por reglas generales: la presencia de una
;; palabra funcional, y la terminacion tipica de adjetivo. Lo que queda
;; es un compuesto nominal y lleva nexo.

(defvar *function-words*
  '("de" "del" "a" "al" "en" "con" "sin" "por" "para" "y" "o" "no"
    "que" "el" "la" "los" "las" "un" "una" "se" "su" "sus"
    "mismo" "misma" "solo" "sola" "cada" "todo" "toda")
  "Si el simbolo lleva alguna, el autor ya escribio una frase: no se toca.")

(defvar *adjective-suffixes*
  '("ico" "ica" "icos" "icas" "ivo" "iva" "ivos" "ivas"
    "oso" "osa" "osos" "osas" "al" "ales" "ar" "ares"
    "ante" "antes" "ente" "entes" "ado" "ada" "ados" "adas"
    "ido" "ida" "idos" "idas" "il" "iles" "able" "ables")
  "Terminaciones tipicas de adjetivo. Decide entre yuxtaponer y poner 'de'.")

(defun adjective-p (palabra)
  (some (lambda (s) (sufijo-p palabra s)) *adjective-suffixes*))

(defun function-word-p (palabra)
  (member palabra *function-words* :test #'string=))

(defun symbol-parts (sym)
  "Segmentos del simbolo con la ortografia ya corregida."
  (mapcar #'spell (split-char (string-downcase (symbol-name sym)) #\-)))

(defun compound-kind (sym partes)
  "Que clase de compuesto es: :simple, :frase, :adjetivo o :nominal.

   El nexo solo se insinua en compuestos de DOS segmentos. Con tres o mas
   el autor esta escribiendo una frase, no un compuesto, y meterle 'de'
   la estropea: restriccion-educacion-fisica-temprano no es 'restricción
   de educación física temprano'."
  (cond ((null (cdr partes))                 :simple)
        ((gethash sym *predicates*)          :frase)
        ((some #'function-word-p partes)     :frase)
        ((cddr partes)                       :frase)
        ((adjective-p (second partes))       :adjetivo)
        (t                                   :nominal)))

(defun head-symbol (sym)
  "Nucleo de un compuesto, como simbolo. El espanol toma de el el genero:
   'el día de preparación', no 'la día preparación'."
  (let ((partes (split-char (symbol-name sym) #\-)))
    (if (cdr partes) (intern (first partes)) sym)))

(defun nl-name (sym &key plural)
  "Simbolo -> sintagma. *lexicon* manda; si no, se compone por reglas.
   En plural solo flexiona lo que debe: 'tipos de programa' y no
   'tipo de programas'."
  (or (if plural (lex sym :plur) (lex sym :sing))
      (let* ((partes (symbol-parts sym))
             (clase  (compound-kind sym partes))
             (cabeza (if plural (pluralizar (first partes)) (first partes)))
             (resto  (rest partes)))
        (case clase
          (:simple    cabeza)
          ;; El nexo bloquea la flexion de lo que va detras.
          (:nominal   (format nil "~a de ~{~a~^ ~}" cabeza resto))
          ;; El adjetivo concuerda con el nucleo.
          (:adjetivo  (format nil "~a~{ ~a~}"
                              cabeza (if plural (mapcar #'pluralizar resto) resto)))
          ;; Frase del autor: se respeta tal cual, solo flexiona el nucleo.
          (t          (format nil "~a~{ ~a~}" cabeza resto))))))

(defun word-gender (w)
  "Genero por terminacion de una palabra suelta."
  (if (or (sufijo-p w "ción") (sufijo-p w "sión")
          (sufijo-p w "dad")  (sufijo-p w "tad")
          (sufijo-p w "tud")  (sufijo-p w "umbre")
          (sufijo-p w "ez")   (sufijo-p w "a"))
      :f
      :m))

(defun nl-gender (sym)
  "Genero gramatical. La tabla manda; si no, lo fija el NUCLEO del
   compuesto, no la ultima palabra: el genero de 'día de preparación'
   es el de 'día'."
  (or (lex sym :gen)
      (let ((h (head-symbol sym)))
        (if (eq h sym)
            (word-gender (nl-name sym))
            (nl-gender h)))))

(defun nl-article (sym &key definite plural)
  "el / la / los / las / un / una / unos / unas, segun genero y numero.
   :art-m invierte el articulo en singular (el aula, un aula)."
  (let ((f (and (eq :f (nl-gender sym))
                (not (and (lex sym :art-m) (not plural))))))
    (cond ((and definite plural) (if f "las"  "los"))
          (definite              (if f "la"   "el"))
          (plural                (if f "unas" "unos"))
          (t                     (if f "una"  "un")))))

(defun nl-noun (sym &key definite plural (article t))
  "Sintagma nominal completo: 'un programa', 'las emisiones', 'bloque'."
  (if article
      (format nil "~a ~a"
              (nl-article sym :definite definite :plural plural)
              (nl-name    sym :plural plural))
      (nl-name sym :plural plural)))

(defun nl-var (sym)
  "Variable de iteracion o parametro: e1, e2, c, prof. Se deja tal cual."
  (string-downcase (symbol-name sym)))


;; =====================================================================
;; REGISTRO DE CONSULTAS
;; =====================================================================
;; expr->nl encuentra nodos consulta-simple dentro de las restricciones
;; y necesita saber como se llaman. El AST no lo guarda: el nombre vive
;; en el defvar del dominio.

(defvar *query-registry* (make-hash-table)
  "Nodo consulta-simple -> simbolo Lisp de su nombre.")

(defun register-query (sym nodo)
  (setf (gethash nodo *query-registry*) sym))

(defun query-name (nodo)
  (gethash nodo *query-registry*))

(defun register-queries (problema)
  "Llena el registro con las consultas declaradas en el problema."
  (clrhash *query-registry*)
  (dolist (sym (problema-horario-consultas problema))
    (when (boundp sym)
      (register-query sym (symbol-value sym)))))
