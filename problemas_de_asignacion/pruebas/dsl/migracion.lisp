(in-package :pruebas-dsl)

(defpackage :lector (:use))

(defparameter *raiz*
  (truename (merge-pathnames "../../" (make-pathname :name nil :type nil :defaults *load-truename*))))

(defparameter *cambios*
  '(("tv"
     :instancias 78 :restricciones 2
     :reemplazos
     (("RESTRICCION-MINIMIZAR-REPETICION-DE-TIPO"
       "(def-minimizar restriccion-minimizar-repeticion-de-tipo
          (consecutivos-por-canal c)
          :para (c canal))")))
    ("tesis"
     :instancias 81 :restricciones 3
     :pares ("CONFLICTOS-DE-HORARIO" "COLISIONES-DE-LOCAL")
     :distintos (("DIAS-ASISTIDOS" "(fecha asig)"))
     :reemplazos
     (("RESTRICCION-MINIMIZAR-CARGA-MAXIMA"
       "(def-minimizar restriccion-minimizar-carga-maxima
          (dias-asistidos p)
          :para (p profesor))")))
    ("docentes"
     :instancias 108 :restricciones 4
     :pares ("COLISIONES-DE-PROFESOR" "COLISIONES-DE-AULA" "COLISIONES-DE-GRUPO")
     :distintos (("DIAS-DE-PROFESOR" "(dia c)"))
     :borradas ("CLASES-DE-ASIGNATURA" "RESTRICCION-FRECUENCIA-EXACTA")
     :reemplazos
     (("RESTRICCION-MINIMIZAR-DIAS-DE-VIAJE"
       "(def-minimizar restriccion-minimizar-dias-de-viaje
          (dias-de-profesor p)
          :para (p profesor))")))
    ("seder"
     :instancias 76 :restricciones 6
     :pares ("COLISIONES-DE-INSTALACION" "COLISIONES-DE-PROFESOR")
     :reemplazos
     (("RESTRICCION-EQUILIBRAR-INSTALACIONES"
       "(def-minimizar restriccion-equilibrar-instalaciones
          (brigadas-de-la-instalacion i)
          :para (i instalacion))")
      ("RESTRICCION-EQUILIBRAR-TURNOS"
       "(def-minimizar restriccion-equilibrar-turnos
          (brigadas-del-turno tu)
          :para (tu turno))")))
    ("saul"
     :instancias 480 :restricciones 11
     :pares ("COLISIONES-DE-GRUPO" "COLISIONES-DE-PROFESOR" "REPETICIONES-EN-EL-DIA")
     :borradas ("JORNADA")
     :reemplazos
     (("RESTRICCION-FRECUENCIA-EXACTA"
       "(def-tqpq restriccion-frecuencia-exacta
          (op-igual (sesiones-del-plan pl) (frecuencia pl))
          :para (pl plan))")
      ("SESIONES-DE-LA-JORNADA"
       "(def-consulta sesiones-del-dia (p d)
          :itera-sobre (u ubicacion)
          :comprueba (op-and (op-igual (profesor (plan (sesion u))) p)
                             (op-igual (dia u) d))
          :operacion (suma 1))")
      ("RESTRICCION-TOPE-DIARIO-DE-PROFESOR"
       "(def-sbqp restriccion-tope-diario-de-profesor
          (op-menor-igual (sesiones-del-dia p d) 5)
          :para (p profesor) (d dia))")))))

(defun leer (texto)
  "Lee una forma en el paquete vacío en que se comparan los dominios."
  (let ((*package* (find-package :lector))
        (*read-eval* nil))
    (read-from-string texto)))

(defun formas-de (ruta)
  "Lee todas las formas de un archivo sin evaluarlas."
  (with-open-file (flujo ruta :external-format :utf-8)
    (let ((*package* (find-package :lector))
          (*read-eval* nil))
      (loop for forma = (read flujo nil flujo)
            until (eq forma flujo)
            collect forma))))

(defun simbolo (texto)
  "Devuelve el símbolo del paquete de comparación."
  (intern texto :lector))

(defun nombre-de (forma)
  "Devuelve el nombre del segundo elemento de una forma, si es un símbolo."
  (let ((segundo (second forma)))
    (and (symbolp segundo) (symbol-name segundo))))

(defun operacion-esperada (nombre claves cambios)
  "Traduce :operacion y :devuelve a la forma con la expresión dentro."
  (let ((operacion (symbol-name (first (getf claves :operacion))))
        (distinto (assoc nombre (getf cambios :distintos) :test #'equal)))
    (cond (distinto
           (assert (equal operacion "CONTAR-DISTINTOS-DIAS"))
           (list (simbolo "CONTAR-DISTINTOS") (leer (second distinto))))
          (t
           (assert (equal operacion "SUMA"))
           (list (simbolo "SUMA") (first (getf claves :devuelve)))))))

(defun consulta-esperada (forma cambios)
  "Traduce una def-consulta vieja según las reglas de la migración."
  (destructuring-bind (nombre parametros &rest cuerpo) (rest forma)
    (let* ((claves (dsl-ast::repartir-claves
                    cuerpo '(:itera-sobre :comprueba :operacion :devuelve) "consulta vieja"))
           (iteradores (getf claves :itera-sobre))
           (comprobacion (first (getf claves :comprueba))))
      (if (null iteradores)
          (list (simbolo "DEF-CONDICION") nombre parametros comprobacion)
          (let ((pares-p (member (symbol-name nombre) (getf cambios :pares) :test #'equal)))
            (when pares-p
              (assert (eq (second (first (last iteradores)))
                          (second (first (last iteradores 2))))))
            `(,(simbolo "DEF-CONSULTA") ,nombre ,parametros
              ,@(let ((fuera (if pares-p (butlast iteradores 2) iteradores)))
                  (when fuera `(:itera-sobre ,@fuera)))
              ,@(when pares-p
                  (let ((ultimos (last iteradores 2)))
                    `(:pares ,(mapcar #'first ultimos) ,(second (first ultimos)))))
              :comprueba ,comprobacion
              :operacion ,(operacion-esperada (symbol-name nombre) claves cambios)))))))

(defun restriccion-esperada (forma)
  "Traduce (defvar r (def-q (op-mayor q 0))) a (def-q r (op-mayor (q) 0))."
  (destructuring-bind (cuantificador comprobacion &rest resto) (third forma)
    (assert (null resto) () "Falta el reemplazo de ~a" (second forma))
    (destructuring-bind (comparador consulta cero) comprobacion
      (list cuantificador (second forma) (list comparador (list consulta) cero)))))

(defun problema-esperado (forma cambios)
  "Traduce def-problema-horario a def-problema y comprueba que no había pesos propios."
  (let* ((viejo (rest (third forma)))
         (citado (lambda (clave) (second (getf viejo clave))))
         (seguir (lambda (nombre)
                   (not (member (symbol-name nombre) (getf cambios :borradas) :test #'equal)))))
    (assert (= (getf viejo :peso-blanda) 1))
    `(,(simbolo "DEF-PROBLEMA") ,(second forma)
      :combinacion ,(funcall citado :entidad-horario)
      :identidad ,(funcall citado :slot-identidad)
      :variables ,(funcall citado :slots-variables)
      :restricciones ,(remove-if-not seguir
                                     (append (funcall citado :restricciones-duras)
                                             (funcall citado :restricciones-blandas))))))

(defun forma-esperada (forma cambios)
  "Devuelve la forma nueva que corresponde a una vieja, o nil si desaparece."
  (let* ((cabeza (symbol-name (first forma)))
         (nombre (nombre-de forma))
         (reemplazo (assoc nombre (getf cambios :reemplazos) :test #'equal))
         (borradas (getf cambios :borradas)))
    (cond ((member cabeza '("LOAD" "MOSTRAR-PROBLEMA" "GENERAR-PYTHON" "EXIT") :test #'equal)
           nil)
          ((or (member nombre borradas :test #'equal)
               (member cabeza
                       (mapcar (lambda (b) (concatenate 'string "DEF-" b)) borradas)
                       :test #'equal))
           nil)
          (reemplazo
           (leer (second reemplazo)))
          ((equal cabeza "DEF-CONSULTA")
           (consulta-esperada forma cambios))
          ((and (equal cabeza "DEFVAR")
                (equal (symbol-name (first (third forma))) "DEF-PROBLEMA-HORARIO"))
           (problema-esperado forma cambios))
          ((equal cabeza "DEFVAR")
           (restriccion-esperada forma))
          (t forma))))

(defun comprobar-formas (dominio esperadas nuevas)
  "Exige que las formas nuevas sean las esperadas, en el mismo orden."
  (loop for esperada in esperadas
        for nueva in nuevas
        do (assert (equal esperada nueva) ()
                   "~a: se esperaba~%~s~%y hay~%~s" dominio esperada nueva))
  (assert (= (length esperadas) (length nuevas)) ()
          "~a: se esperaban ~a formas y hay ~a" dominio (length esperadas) (length nuevas)))

(defun instancias-esperadas (formas)
  "Calcula de las formas la lista de asociación de instancias por entidad."
  (let ((entidades (loop for forma in formas
                         when (member (symbol-name (first forma)) '("DEF-ENTIDAD" "DEF-COMB")
                                      :test #'equal)
                           collect (nombre-de forma))))
    (mapcar (lambda (entidad)
              (let ((constructor (concatenate 'string "DEF-" entidad)))
                (cons entidad
                      (loop for forma in formas
                            when (equal (symbol-name (first forma)) constructor)
                              collect (nombre-de forma)))))
            entidades)))

(defun comprobar-dominio (dominio cambios)
  "Compara un dominio migrado con su referencia y lo carga sin avisos."
  (let* ((referencia (format nil "pruebas/referencia/~a/dominio.lisp" dominio))
         (nuevo (merge-pathnames (format nil "dominios/~a/dominio.lisp" dominio) *raiz*))
         (viejas (formas-de (merge-pathnames referencia *raiz*)))
         (esperadas (remove nil (mapcar (lambda (forma) (forma-esperada forma cambios)) viejas)))
         (problema (handler-bind ((warning (lambda (aviso)
                                             (error "~a: aviso al cargar: ~a" dominio aviso))))
                     (cargar-dominio nuevo)))
         (instancias (mapcar (lambda (par) (cons (symbol-name (car par)) (simbolos (cdr par))))
                             (problema-instancias problema))))
    (comprobar-formas dominio esperadas (formas-de nuevo))
    (assert (equal instancias (instancias-esperadas esperadas)) () "~a: instancias" dominio)
    (assert (= (reduce #'+ (mapcar (lambda (par) (length (cdr par))) instancias))
               (getf cambios :instancias))
            () "~a: número de instancias" dominio)
    (assert (= (length (problema-restricciones problema)) (getf cambios :restricciones))
            () "~a: número de restricciones" dominio)))

(defun comprobar-jornadas ()
  "Exige que las jornadas viejas sean todo profesor por día y que su tope sea siempre 5."
  (let* ((formas (remove-if-not #'consp
                                (formas-de (merge-pathnames "pruebas/referencia/saul/dominio.lisp"
                                                            *raiz*))))
         (de (lambda (cabeza)
               (remove cabeza formas :key (lambda (forma) (symbol-name (first forma)))
                                     :test-not #'equal)))
         (jornadas (funcall de "DEF-JORNADA"))
         (pares (remove-duplicates (mapcar (lambda (j) (list (third j) (fourth j))) jornadas)
                                   :test #'equal)))
    (assert (= (length jornadas) (length pares)
               (* (length (funcall de "DEF-PROFESOR")) (length (funcall de "DEF-DIA")))))
    (assert (every (lambda (j) (eql (fifth j) 5)) jornadas))))

(comprobar-jornadas)

(assert (= (reduce #'+ (mapcar (lambda (cambios) (length (getf (rest cambios) :pares))) *cambios*))
           10))

(dolist (cambios *cambios*)
  (comprobar-dominio (first cambios) (rest cambios)))
