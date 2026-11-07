(in-package :emision)

(defvar *verbalizador*)

(defun reemplazar (cadena patron reemplazo)
  "Reemplaza todas las apariciones de PATRON en CADENA."
  (with-output-to-string (salida)
    (loop with n = (length patron)
          for inicio = 0 then (+ posicion n)
          for posicion = (search patron cadena :start2 inicio)
          do (write-string cadena salida :start inicio :end (or posicion (length cadena)))
             (when (null posicion) (loop-finish))
             (write-string reemplazo salida))))

(defun sufijo-p (palabra sufijo)
  "Dice si PALABRA termina en SUFIJO."
  (let ((lp (length palabra)) (ls (length sufijo)))
    (and (>= lp ls) (string= sufijo palabra :start2 (- lp ls)))))

(defun contraer (cadena)
  "Aplica las contracciones sobre la cadena ya compuesta: de el -> del, a el -> al."
  (let ((rodeada (concatenate 'string " " cadena " ")))
    (string-trim " " (reemplazar (reemplazar rodeada " de el " " del ") " a el " " al "))))

(defun partir (cadena caracter)
  "Parte CADENA por CARACTER."
  (let ((partes '()) (inicio 0))
    (loop for posicion = (position caracter cadena :start inicio)
          do (push (subseq cadena inicio (or posicion (length cadena))) partes)
             (if posicion (setf inicio (1+ posicion)) (return)))
    (nreverse partes)))

(defun enumerar (elementos &optional (conjuncion "y"))
  "Escribe una enumeración: a, b y c."
  (cond ((null elementos) "")
        ((null (rest elementos)) (first elementos))
        (t (format nil "~{~a~^, ~} ~a ~a"
                   (butlast elementos) conjuncion (first (last elementos))))))

(defvar *lexico* (make-hash-table :test #'equal)
  "Palabra del idioma -> plist (:sing :plur :gen :art-m). Solo lo que las reglas no aciertan.")

(defun definir-palabra (texto &key sing plur gen art-m)
  "Registra una palabra. ART-M da artículo masculino en singular: el aula, un aula, la misma aula."
  (setf (gethash texto *lexico*)
        (append (when sing (list :sing sing))
                (when plur (list :plur plur))
                (when gen (list :gen gen))
                (when art-m (list :art-m t)))))

(definir-palabra "dia"        :sing "día"        :plur "días"         :gen :m)
(definir-palabra "programa"   :sing "programa"   :plur "programas"    :gen :m)
(definir-palabra "emision"    :sing "emisión"    :plur "emisiones"    :gen :f)
(definir-palabra "duracion"   :sing "duración"   :plur "duraciones"   :gen :f)
(definir-palabra "codigo"     :sing "código"     :plur "códigos"      :gen :m)
(definir-palabra "orden"      :sing "orden"      :plur "órdenes"      :gen :m)
(definir-palabra "asignacion" :sing "asignación" :plur "asignaciones" :gen :f)
(definir-palabra "sesion"     :sing "sesión"     :plur "sesiones"     :gen :f)
(definir-palabra "dias"       :sing "días"       :plur "días"         :gen :m)
(definir-palabra "clase"      :sing "clase"      :plur "clases"       :gen :f)
(definir-palabra "aula"       :sing "aula"       :plur "aulas"        :gen :f :art-m t)
(definir-palabra "anno"       :sing "año"        :plur "años"         :gen :m)

(defvar *grafia* (make-hash-table :test #'equal)
  "Palabra sin acento -> palabra acentuada. Una entrada sirve para todo compuesto que la contenga.")

(defun definir-grafia (&rest pares)
  "Registra pares de palabra sin acento y palabra acentuada."
  (loop for (sin con) on pares by #'cddr
        do (setf (gethash sin *grafia*) con)))

(definir-grafia
  "dia" "día" "dias" "días" "codigo" "código"
  "numero" "número" "ultimo" "último" "practica" "práctica"
  "maxima" "máxima" "minima" "mínima"
  "maximo" "máximo" "minimo" "mínimo"
  "fisica" "física" "fisicas" "físicas"
  "politica" "política" "politicas" "políticas"
  "quimica" "química" "matematica" "matemática"
  "informatica" "informática" "artistica" "artística"
  "practico" "práctico" "teorica" "teórica"
  "biologia" "biología" "geografia" "geografía"
  "ingles" "inglés" "miercoles" "miércoles"
  "sabado" "sábado" "examen" "examen")

(defun escribir-palabra (palabra)
  "Devuelve la ortografía de una palabra: la tabla manda, y si no, -cion y -sion llevan acento."
  (or (gethash palabra *grafia*)
      (let ((n (length palabra)))
        (cond ((sufijo-p palabra "cion") (concatenate 'string (subseq palabra 0 (- n 4)) "ción"))
              ((sufijo-p palabra "sion") (concatenate 'string (subseq palabra 0 (- n 4)) "sión"))
              (t palabra)))))

(defun pluralizar (palabra)
  "Devuelve el plural regular de una palabra."
  (let ((n (length palabra)))
    (cond ((zerop n) palabra)
          ((sufijo-p palabra "ión") (concatenate 'string (subseq palabra 0 (- n 3)) "iones"))
          ((sufijo-p palabra "z") (concatenate 'string (subseq palabra 0 (1- n)) "ces"))
          ((find (char palabra (1- n)) "aeiouáéíóu") (concatenate 'string palabra "s"))
          (t (concatenate 'string palabra "es")))))

(defun nombre-de (simbolo)
  "Devuelve el texto con el que un símbolo se busca en las tablas."
  (string-downcase (symbol-name simbolo)))

(defun frase-de-predicado (simbolo &key negada)
  "Devuelve lo que dice un slot booleano de su entidad, según las anotaciones del dominio."
  (let ((frase (second (assoc (nombre-de simbolo) (destino-predicados *verbalizador*)
                              :test #'string=))))
    (when frase
      (if negada (concatenate 'string "no " frase) frase))))

(defparameter *palabras-funcionales*
  '("de" "del" "a" "al" "en" "con" "sin" "por" "para" "y" "o" "no"
    "que" "el" "la" "los" "las" "un" "una" "se" "su" "sus"
    "mismo" "misma" "solo" "sola" "cada" "todo" "toda")
  "Si un símbolo lleva alguna, el autor ya escribió una frase y no se toca.")

(defparameter *sufijos-de-adjetivo*
  '("ico" "ica" "icos" "icas" "ivo" "iva" "ivos" "ivas"
    "oso" "osa" "osos" "osas" "al" "ales" "ar" "ares"
    "ante" "antes" "ente" "entes" "ado" "ada" "ados" "adas"
    "ido" "ida" "idos" "idas" "il" "iles" "able" "ables")
  "Terminaciones típicas de adjetivo. Deciden entre yuxtaponer y poner «de».")

(defun adjetivo-p (palabra)
  "Dice si PALABRA tiene terminación de adjetivo."
  (some (lambda (sufijo) (sufijo-p palabra sufijo)) *sufijos-de-adjetivo*))

(defun palabra-funcional-p (palabra)
  "Dice si PALABRA es una palabra funcional."
  (member palabra *palabras-funcionales* :test #'string=))

(defun partes-de (simbolo)
  "Devuelve los segmentos de un símbolo, con la ortografía ya corregida."
  (mapcar #'escribir-palabra (partir (nombre-de simbolo) #\-)))

(defun clase-de-compuesto (simbolo partes)
  "Devuelve qué es un símbolo: :simple, :frase, :adjetivo o :nominal. Con tres segmentos es una frase."
  (cond ((null (rest partes)) :simple)
        ((frase-de-predicado simbolo) :frase)
        ((some #'palabra-funcional-p partes) :frase)
        ((cddr partes) :frase)
        ((adjetivo-p (second partes)) :adjetivo)
        (t :nominal)))

(defun nombre-prosa (simbolo &key plural)
  "Convierte un símbolo en un sintagma. En plural solo flexiona lo que debe: tipos de programa."
  (let ((entrada (gethash (nombre-de simbolo) *lexico*)))
    (or (getf entrada (if plural :plur :sing))
        (let* ((partes (partes-de simbolo))
               (clase (clase-de-compuesto simbolo partes))
               (cabeza (if plural (pluralizar (first partes)) (first partes)))
               (resto (rest partes)))
          (cond ((eq clase :simple) cabeza)
                ((eq clase :nominal) (format nil "~a de ~{~a~^ ~}" cabeza resto))
                ((eq clase :adjetivo)
                 (format nil "~a~{ ~a~}" cabeza (if plural (mapcar #'pluralizar resto) resto)))
                (t (format nil "~a~{ ~a~}" cabeza resto)))))))

(defun genero-de-palabra (palabra)
  "Devuelve el género de una palabra suelta por su terminación."
  (if (some (lambda (sufijo) (sufijo-p palabra sufijo))
            '("ción" "sión" "dad" "tad" "tud" "umbre" "ez" "a"))
      :f
      :m))

(defun genero-de-texto (texto)
  "Devuelve el género: la tabla manda; si no, lo fija el primer segmento, que es el núcleo."
  (or (getf (gethash texto *lexico*) :gen)
      (let ((partes (partir texto #\-)))
        (if (rest partes)
            (genero-de-texto (first partes))
            (genero-de-palabra (escribir-palabra texto))))))

(defun genero (simbolo)
  "Devuelve el género gramatical de un símbolo."
  (genero-de-texto (nombre-de simbolo)))

(defun femenino-p (simbolo)
  "Dice si un símbolo es femenino."
  (eq :f (genero simbolo)))

(defun articulo (simbolo &key definido plural)
  "Devuelve el artículo: el, la, los, las, un, una, unos o unas."
  (let ((femenino (and (femenino-p simbolo)
                       (not (and (getf (gethash (nombre-de simbolo) *lexico*) :art-m)
                                 (not plural))))))
    (cond ((and definido plural) (if femenino "las" "los"))
          (definido (if femenino "la" "el"))
          (plural (if femenino "unas" "unos"))
          (t (if femenino "una" "un")))))

(defun sintagma (simbolo &key definido plural)
  "Escribe el artículo y el nombre: un programa, las emisiones."
  (format nil "~a ~a"
          (articulo simbolo :definido definido :plural plural)
          (nombre-prosa simbolo :plural plural)))

(defun variable-prosa (simbolo)
  "Escribe una variable tal cual."
  (string-downcase (symbol-name simbolo)))
