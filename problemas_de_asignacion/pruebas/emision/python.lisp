(in-package :pruebas-emision)

;; Posiciones: [día, turno] por cada sesión, con día 0 lunes, 1 martes, 2 jueves.
(defparameter *horarios* "
H = crear_horario([[0, 0], [0, 0], [0, 1], [2, 1]])
JUNTAS = crear_horario([[0, 0], [0, 0], [0, 0], [2, 1]])
SEPARADAS = crear_horario([[0, 0], [1, 0], [2, 0], [2, 1]])
")

(defun rechaza-emision (texto restricciones &rest fragmentos)
  "Exige que generar el modelo señale error-dsl con los FRAGMENTOS en su mensaje."
  (handler-case (progn (codigo-generado (modelo-de texto restricciones))
                       (error "No se rechazó: ~a" texto))
    (error-dsl (condicion)
      (dolist (fragmento fragmentos)
        (assert (search fragmento (princ-to-string condicion)) ()
                "El mensaje «~a» no contiene «~a»" condicion fragmento)))))

(defparameter *consultas* "
(def-consulta dos-por-fila ()
  :itera-sobre (u fila)
  :comprueba (op-igual (orden (turno u)) 1)
  :operacion (suma 2))
(def-consulta duracion-del-lunes ()
  :itera-sobre (u fila)
  :comprueba (op-igual (dia u) lunes)
  :operacion (suma (duracion (sesion u))))
(def-consulta medio-por-fila ()
  :itera-sobre (u fila)
  :comprueba (op-igual (orden (turno u)) 1)
  :operacion (suma 1/2))
(def-consulta semanas-distintas ()
  :itera-sobre (u fila)
  :comprueba (op-mayor (orden (turno u)) 0)
  :operacion (contar-distintos (semana (dia u))))
(def-consulta choque ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-igual (turno a) (turno b))
                     (op-distinto (sesion a) (sesion b)))
  :operacion (suma 1))
(def-consulta choque-doble ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-igual (turno a) (turno b))
                     (op-distinto (sesion a) (sesion b)))
  :operacion (suma 2))
(def-consulta choque-sin-distinto ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-igual (turno a) (turno b)))
  :operacion (suma 1))
(def-consulta choque-de-profesor-distinto ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-igual (turno a) (turno b))
                     (op-distinto (profesor (sesion a)) (profesor (sesion b))))
  :operacion (suma 1))
(def-consulta choque-por-variable ()
  :itera-sobre (p profesor)
  :pares (a b) fila
  :comprueba (op-y (op-igual (profesor (sesion a)) p)
                     (op-igual (profesor (sesion b)) p)
                     (op-igual (dia a) (dia b))
                     (op-igual (turno a) (turno b))
                     (op-distinto (sesion a) (sesion b)))
  :operacion (suma 1))
(def-consulta choque-de-dos-distintos ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-distinto (sesion a) (sesion b))
                     (op-distinto (turno a) (turno b)))
  :operacion (suma 1))
(def-consulta choque-que-suma-una-expresion ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-igual (turno a) (turno b)))
  :operacion (suma (duracion (sesion a))))
(def-consulta choque-con-filtro-en-una-fila ()
  :pares (a b) fila
  :comprueba (op-y (op-igual (dia a) (dia b))
                     (op-igual (duracion (sesion a)) (duracion (sesion b)))
                     (op-igual (duracion (sesion b)) 3))
  :operacion (suma 1))
(def-consulta todas-las-parejas ()
  :pares (a b) fila
  :comprueba (op-distinto (sesion a) (sesion b))
  :operacion (suma 1))
(def-consulta de-nombres-reservados (q)
  :itera-sobre (total fila)
  :comprueba (op-igual (dia total) q)
  :operacion (suma 1))
(def-consulta con-variable-final ()
  :itera-sobre (grupos fila) (valores turno)
  :comprueba (op-igual (turno grupos) valores)
  :operacion (suma 1))
(def-consulta calculada ()
  :itera-sobre (u fila)
  :comprueba (op-o (op-no (op-igual (dia u) martes)) (op-igual (orden (turno u)) 9))
  :operacion (suma (op-suma (op-division (op-multiplicacion (op-resta (duracion (sesion u)) 1) 4) 2) 1)))
(def-nppq r-calculada (op-mayor (calculada) 0))
(def-nppq r-dos (op-mayor (dos-por-fila) 0))
(def-nppq r-duracion (op-mayor (duracion-del-lunes) 0))
(def-ndpq r-medio (op-mayor (medio-por-fila) 0) :peso 3/2)
(def-nppq r-semanas (op-mayor (semanas-distintas) 0))
(def-nppq r-choque (op-mayor (choque) 0))
(def-nppq r-choque-doble (op-mayor (choque-doble) 0))
(def-nppq r-sin-distinto (op-mayor (choque-sin-distinto) 0))
(def-nppq r-profesor-distinto (op-mayor (choque-de-profesor-distinto) 0))
(def-nppq r-por-variable (op-mayor (choque-por-variable) 0))
(def-nppq r-dos-distintos (op-mayor (choque-de-dos-distintos) 0))
(def-nppq r-expresion (op-mayor (choque-que-suma-una-expresion) 0))
(def-nppq r-filtro (op-mayor (choque-con-filtro-en-una-fila) 0))
(def-nppq r-todas (op-mayor (todas-las-parejas) 0))
(def-tqpq r-reservados (op-menor-igual (de-nombres-reservados d) 1) :para (d dia))
(def-nppq r-variable-final (op-mayor (con-variable-final) 0))
")

(defparameter *restricciones-de-consultas*
  '("r-calculada" "r-dos" "r-duracion" "r-medio" "r-semanas" "r-choque" "r-choque-doble" "r-sin-distinto"
    "r-profesor-distinto" "r-por-variable" "r-dos-distintos" "r-expresion" "r-filtro" "r-todas"
    "r-reservados" "r-variable-final"))

;; Consultas: cada operación y cada forma de pareja, con su valor exacto.
(let ((modelo (modelo-de *consultas* *restricciones-de-consultas*)))
  (comprobar-en-python modelo (concatenate 'string *horarios* "
assert calculada(H) == 3 + 3 + 5 + 5
assert calculada(crear_horario([[1, 0], [0, 0], [0, 0], [0, 0]])) == 3 + 5 + 5
assert dos_por_fila(H) == 4
assert duracion_del_lunes(H) == 7
assert medio_por_fila(H) == 1.0
assert semanas_distintas(H) == 2
assert choque(H) == 1
assert choque(JUNTAS) == 3
assert choque(SEPARADAS) == 0
assert choque_doble(JUNTAS) == 6
assert choque_sin_distinto(JUNTAS) == 3
assert choque_de_profesor_distinto(JUNTAS) == 2
assert choque_de_profesor_distinto(H) == 0
assert choque_por_variable(JUNTAS) == 1
assert choque_por_variable(H) == 1
assert choque_de_dos_distintos(H) == 2
assert choque_de_dos_distintos(JUNTAS) == 0
assert choque_que_suma_una_expresion(JUNTAS) == 2 + 2 + 2
assert choque_con_filtro_en_una_fila(crear_horario([[0, 0], [0, 0], [1, 0], [1, 0]])) == 1
assert todas_las_parejas(H) == 6
assert de_nombres_reservados(H, LUNES) == 3
assert con_variable_final(H) == 4
"))
  (let ((codigo (codigo-generado modelo)))
    (flet ((cuerpo-de (funcion)
             (let ((inicio (search (format nil "def ~a(" funcion) codigo)))
               (subseq codigo inicio (search "return" codigo :start2 inicio)))))
      ;; Se agrupa solo cuando es exacto.
      (assert (search "_parejas" (cuerpo-de "choque")))
      (assert (search "_parejas" (cuerpo-de "choque_por_variable")))
      (assert (search "_parejas" (cuerpo-de "choque_doble")))
      (assert (not (search "_parejas" (cuerpo-de "choque_de_dos_distintos"))))
      (assert (not (search "_parejas" (cuerpo-de "choque_que_suma_una_expresion"))))
      (assert (search "[i + 1:]" (cuerpo-de "todas_las_parejas"))))))

;; Cotas: los seis comparadores, en requisitos y en prohibiciones.
;; Con H, lunes tiene 3 filas, martes 0 y jueves 1.
(let ((modelo (modelo-de "
(def-tqpq c-menor-igual (op-menor-igual (de-dia d) 1) :para (d dia))
(def-tqpq c-menor (op-menor (de-dia d) 1) :para (d dia))
(def-sbqp c-mayor-igual (op-mayor-igual (de-dia d) 1) :para (d dia))
(def-sbqp c-mayor (op-mayor (de-dia d) 1) :para (d dia))
(def-tqpq c-igual (op-igual (de-dia d) 1) :para (d dia))
(def-tqpq c-distinto (op-distinto (de-dia d) 1) :para (d dia))
(def-nppq p-mayor (op-mayor (de-dia d) 1) :para (d dia))
(def-nppq p-mayor-igual-uno (op-mayor-igual (de-dia d) 1) :para (d dia))
(def-ndpq p-igual (op-igual (de-dia d) 1) :para (d dia))
(def-tqpq c-al-reves (op-mayor-igual 1 (de-dia d)) :para (d dia))
(def-tqpq c-con-atributo (op-igual (de-dia d) (numero (semana d))) :para (d dia))
"
                         '("c-menor-igual" "c-menor" "c-mayor-igual" "c-mayor" "c-igual" "c-distinto"
                           "p-mayor" "p-mayor-igual-uno" "p-igual" "c-al-reves" "c-con-atributo"))))
  (assert (every (lambda (restriccion) (typep restriccion 'cota)) (modelo-restricciones modelo)))
  (comprobar-en-python modelo (concatenate 'string *horarios* "
assert c_menor_igual(H) == 2
assert c_menor(H) == 3 + 1
assert c_mayor_igual(H) == 1
assert c_mayor(H) == 2 + 1
assert c_igual(H) == 2 + 1
assert c_distinto(H) == 1
assert p_mayor(H) == 2
assert p_mayor_igual_uno(H) == 3 + 1
assert p_igual(H) == 1
assert c_al_reves(H) == 2
assert c_con_atributo(H) == 2 + 1 + 1
")))

;; Objetivos y restricciones genéricas.
(let ((modelo (modelo-de "
(def-consulta de-profesor-y-dia (p d)
  :itera-sobre (u fila)
  :comprueba (op-y (op-igual (profesor (sesion u)) p) (op-igual (dia u) d))
  :operacion (suma 1))
(def-minimizar o-max (de-dia d) :para (d dia) :peso 2)
(def-maximizar o-min (de-profesor p) :para (p profesor))
(def-minimizar o-dos-variables (de-profesor-y-dia p d) :para (p profesor) (d dia))
(def-minimizar o-sin-consulta (op-suma 1 2) :para (d dia))
(def-maximizar o-sin-consulta-max (op-suma 1 2) :para (d dia))
(def-tqpq g-tqpq (op-y (op-mayor (de-dia d) 0) (op-menor (de-dia d) 3)) :para (d dia))
(def-nppq g-nppq (op-y (op-mayor (de-dia d) 0) (op-menor (de-dia d) 3)) :para (d dia))
(def-sbqp g-sbqp (op-y (op-mayor (de-dia d) 0) (op-menor (de-dia d) 3)) :para (d dia))
(def-ndpq g-ndpq (op-y (op-mayor (de-dia d) 0) (op-menor (de-dia d) 3)) :para (d dia))
(def-consulta filas-totales ()
  :itera-sobre (u fila)
  :comprueba (op-mayor (orden (turno u)) 0)
  :operacion (suma 1))
(def-nppq g-sin-para (op-y (op-mayor (filas-totales) 0) (op-no (op-mayor (filas-totales) 9))))
"
                         '("o-max" "o-min" "o-dos-variables" "o-sin-consulta" "o-sin-consulta-max"
                           "g-tqpq" "g-nppq" "g-sbqp" "g-ndpq" "g-sin-para"))))
  (assert (= 3 (count-if (lambda (restriccion) (typep restriccion 'minimax))
                         (modelo-restricciones modelo))))
  (assert (= 7 (count-if (lambda (restriccion) (typep restriccion 'restriccion-generica))
                         (modelo-restricciones modelo))))
  (comprobar-en-python modelo (concatenate 'string *horarios* "
assert o_max(H) == 3
assert o_min(H) == -2
assert o_dos_variables(H) == 2
assert o_sin_consulta(H) == 3
assert o_sin_consulta_max(H) == -3
assert g_tqpq(H) == 2
assert g_nppq(H) == 1
assert g_sbqp(H) == 2
assert g_ndpq(H) == 1
assert g_sin_para(H) == 1
assert RESTRICCIONES[0][1] == 2
assert RESTRICCIONES[1][1] == 1
assert RESTRICCIONES[5][1] is None
assert list(evaluar(H)) == [nombre for nombre, _, _ in RESTRICCIONES]
assert evaluar(H)['o_max'] == 3
")))

;; Datos: identidad, orden, etiquetas, textos y nombres reservados.
(let ((modelo (modelo-de "(def-nppq r (op-mayor (de-dia d) 0) :para (d dia))" '("r"))))
  (comprobar-en-python modelo (concatenate 'string *horarios* "
import json
assert S1 is SESION[0] and S2 is SESION[1]
assert S1.duracion == S2.duracion and S1.profesor is S2.profesor
assert S1 != S2
assert len({S1, S2, S3, S4}) == 4
assert S1 == SESION[0]
assert DIA == [LUNES, MARTES, JUEVES]
assert H[0].sesion is S1 and H[3].dia is JUEVES and H[3].turno is T2
assert str(LUNES) == 'Lunes'
assert str(SEM2) == '2'
assert ANA.nombre == 'Peña \"Ana\"'
assert str(ANA) == '(nombre=Peña \"Ana\", apellido=Paz)'
assert str(AULA_1) == '(nombre=A1, edificio=Norte, capacidad=30)'
assert T1.global_ == 0
assert str(T1) == '(orden=1, global_=0)'
assert VACIA == [] and Vacia() is not None
assert Fila.__name__ == 'Fila'
datos = a_json(H)
json.dumps(datos, ensure_ascii=False)
assert datos['horario'][0]['dia'] == 'Lunes'
assert datos['valores'] == evaluar(H)
mostrar_resultado(H)
")))

;; Lo que se imprime sale del modelo.
(let* ((modelo (modelo-de "(def-nppq r (op-mayor (de-dia d) 0) :para (d dia))" '("r")))
       (salida (con-carpeta (carpeta)
                 (exportar modelo carpeta)
                 (with-open-file (flujo (merge-pathnames "prueba.py" carpeta)
                                        :direction :output :external-format :utf-8)
                   (format flujo "from modelo import *~%~a~%mostrar_resultado(H)~%" *horarios*))
                 (ejecutar-python carpeta "prueba.py"))))
  (assert (search "Fila 1:" salida))
  (assert (search "  dia: Lunes" salida))
  (assert (search "r: 4" salida)))

;; Nombres.
(assert (equal (nombre-python 'tipo-programa) "tipo_programa"))
(assert (equal (nombre-python (make-symbol "PASS")) "pass_"))
(assert (equal (nombre-python (make-symbol "Q")) "q_"))
(assert (equal (nombre-python (make-symbol "AÑO")) "año"))
(assert (equal (clase-python 'tipo-programa) "Tipo_Programa"))
(assert (equal (clase-python (make-symbol "NONE")) "None_"))
(assert (equal (constante-python 'tipo-programa) "TIPO_PROGRAMA"))
(assert (equal (constante-python (make-symbol "RESTRICCIONES")) "RESTRICCIONES_"))
(dolist (invalido '("3A" "A B" "Q?" ""))
  (handler-case (progn (nombre-python (make-symbol invalido))
                       (error "No se rechazó: ~s" invalido))
    (error-dsl ())))

(rechaza-emision "
(def-consulta a-b ()
  :itera-sobre (u fila)
  :comprueba (op-igual (orden (turno u)) 1)
  :operacion (suma 1))
(def-nppq a_b (op-mayor (a-b) 0))"
                 '("a_b") "funciones" "a_b")
(rechaza-emision "
(def-turno t-3 3 0)
(def-turno t_3 3 0)
(def-nppq r (op-mayor (de-dia d) 0) :para (d dia))"
                 '("r") "constantes" "T_3")

;; Una instancia dentro de una condición se escribe por su nombre.
(assert (search "== LUNES"
                (codigo-generado
                 (modelo-de "
(def-consulta del-lunes ()
  :itera-sobre (u fila)
  :comprueba (op-igual (dia u) lunes)
  :operacion (suma 1))
(def-nppq r (op-mayor (del-lunes) 0))"
                            '("r")))))
