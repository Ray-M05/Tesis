(in-package :pruebas-emision)

(defun latex-de (modelo)
  "Devuelve como texto el modelo.tex de MODELO."
  (with-output-to-string (flujo)
    (emitir (make-instance 'matematica :modelo modelo) flujo)))

(defun modelo-del-dominio (dominio)
  "Construye el modelo de un dominio real."
  (construir-modelo
   (cargar-dominio (merge-pathnames (format nil "../../dominios/~a/dominio.lisp" dominio) *aqui*))))

(defun contiene (texto &rest fragmentos)
  "Exige que TEXTO contenga todos los FRAGMENTOS."
  (dolist (fragmento fragmentos)
    (assert (search fragmento texto) () "Falta «~a» en:~%~a" fragmento texto)))

(defun no-contiene (texto &rest fragmentos)
  "Exige que TEXTO no contenga ninguno de los FRAGMENTOS."
  (dolist (fragmento fragmentos)
    (assert (not (search fragmento texto)) () "Sobra «~a» en:~%~a" fragmento texto)))

(defun llaves-equilibradas-p (texto)
  "Dice si las llaves sin escapar de TEXTO están equilibradas."
  (let ((nivel 0) (anterior nil))
    (loop for caracter across texto
          do (unless (eql anterior #\\)
               (case caracter
                 (#\{ (incf nivel))
                 (#\} (decf nivel))))
             (when (minusp nivel)
               (return-from llaves-equilibradas-p nil))
             (setf anterior caracter))
    (zerop nivel)))

(defun comprobar-compilacion (texto)
  "Compila TEXTO con pdflatex si hay uno, en PDFLATEX o en el PATH. Si no, avisa."
  (con-carpeta (carpeta)
    (ensure-directories-exist carpeta)
    (with-open-file (flujo (merge-pathnames "prueba.tex" carpeta)
                           :direction :output :external-format :utf-8)
      (format flujo "\\documentclass{article}~%\\usepackage[utf8]{inputenc}~%\\usepackage[T1]{fontenc}~%~
                     \\usepackage{amsmath}~%\\begin{document}~%~a~%\\end{document}~%" texto))
    (let ((proceso (handler-case
                       (sb-ext:run-program (or (uiop:getenv "PDFLATEX") "pdflatex")
                                           '("-interaction=nonstopmode" "-halt-on-error" "prueba.tex")
                                           :search t :directory carpeta :output nil :error nil)
                     (error ()
                       (format t "aviso: sin pdflatex, no se compila el modelo~%")
                       nil))))
      (when proceso
        (assert (zerop (sb-ext:process-exit-code proceso)) () "LaTeX no compila:~%~a" texto)))))

;; Los cinco dominios: forma del documento.
(dolist (dominio '("tv" "tesis" "docentes" "seder" "saul"))
  (let* ((modelo (modelo-del-dominio dominio))
         (latex (latex-de modelo)))
    (contiene latex "\\subsubsection*{Conjuntos}" "\\subsubsection*{Decisiones}"
              "\\subsubsection*{Objetivo}" "\\subsubsection*{Sujeto a}")
    (no-contiene latex "?" "1000")
    (assert (llaves-equilibradas-p latex) () "~a: llaves" dominio)
    ;; Toda restricción está, con todas sus consultas.
    (dolist (restriccion (modelo-restricciones modelo))
      (contiene latex (emision::nombre-latex (restriccion-nombre restriccion)))
      (dolist (consulta (restriccion-consultas restriccion))
        (contiene latex (format nil "~a = " (emision::firma-de-consulta consulta)))))
    (comprobar-compilacion latex)))

;; Lo que el modelo tenía mal: pruebas/referencia/diferencias-esperadas.md.
(let ((latex (latex-de (modelo-del-dominio "saul"))))
  (contiene latex
            "\\forall\\, \\textit{pl} \\in \\text{PLAN}:\\quad \\textit{sesiones\\_del\\_plan}(h, \\textit{pl}) = \\textit{frecuencia}(\\textit{pl})"
            "\\forall\\, \\textit{p} \\in \\text{PROFESOR},\\ \\forall\\, \\textit{d} \\in \\text{DIA}:\\quad \\textit{sesiones\\_del\\_dia}(h, \\textit{p}, \\textit{d}) \\le 5"
            "\\textit{primeros\\_turnos\\_de\\_lejanos}(h) = 0"
            "\\textit{sesiones\\_del\\_dia}(h, \\textit{p}, \\textit{d}) = \\sum_{"
            "\\textit{sesiones\\_del\\_plan}(h, \\textit{pl}) = \\sum_{")
  (no-contiene latex "tdpq" "jornada"))

(contiene (latex-de (modelo-del-dominio "docentes"))
          "|\\{\\, \\textit{dia}(\\textit{c}) :")

(let ((latex (latex-de (modelo-del-dominio "seder"))))
  (contiene latex "|\\text{INSTALACION}|" "|\\text{INDISPONIBILIDAD}|" "|\\text{TURNO}|"))

(contiene (latex-de (modelo-del-dominio "tesis"))
          "\\subseteq \\text{ASIGNACION}"
          "|\\{\\, \\textit{fecha}(\\textit{asig}) :")

;; Cada forma, con su valor y su requisito.
(let ((latex (latex-de (modelo-de "
(def-consulta dos-por-fila ()
  :itera-sobre (u fila)
  :comprueba (op-y (op-igual (orden (turno u)) 1)
                     (op-o (op-igual (dia u) lunes) (op-no (op-igual (nombre (profesor (sesion u))) \"Ñu_%\"))))
  :operacion (suma 2))
(def-consulta calculada ()
  :itera-sobre (u fila)
  :comprueba (op-mayor (orden (turno u)) 0)
  :operacion (suma (op-suma (op-division (op-multiplicacion (op-resta (duracion (sesion u)) 1) 4) 2) 1/2)))
(def-consulta de-par ()
  :itera-sobre (p profesor)
  :pares (a b) fila
  :comprueba (op-y (op-igual (profesor (sesion a)) p) (op-igual (profesor (sesion b)) p)
                     (op-igual (dia a) (dia b)) (op-distinto (sesion a) (sesion b)))
  :operacion (suma 1))
(def-consulta de-orden ()
  :itera-sobre (a fila) (b fila)
  :comprueba (op-mayor (orden (turno a)) (orden (turno b)))
  :operacion (suma 1))
(def-nppq p-dura (op-mayor (dos-por-fila) 0))
(def-ndpq p-blanda (op-mayor (calculada) 0) :peso 2)
(def-nppq p-par (op-mayor (de-par) 0))
(def-nppq p-orden (op-mayor (de-orden) 0))
(def-sbqp c-menor-igual (op-menor-igual (de-dia d) 5) :para (d dia))
(def-sbqp c-mayor (op-mayor (de-dia d) 5) :para (d dia))
(def-ndpq c-prohibida (op-mayor (de-dia d) 5) :para (d dia))
(def-tqpq c-sin-para (op-menor-igual (dos-por-fila) 5))
(def-minimizar o-min (de-dia d) :para (d dia))
(def-maximizar o-max (de-profesor p) :para (p profesor))
(def-minimizar o-sin-consulta (op-suma 1 2) :para (d dia))
(def-tqpq g-tqpq (op-y (op-mayor (de-dia d) 0) (op-menor (de-dia d) 3)) :para (d dia))
(def-nppq g-nppq (op-y (op-mayor (de-dia d) 0) (op-menor (de-dia d) 3)) :para (d dia))
(def-sbqp g-sbqp (op-y (op-mayor (de-dia d) 0) (op-menor (de-dia d) 3)) :para (d dia))
(def-ndpq g-ndpq (op-y (op-mayor (de-dia d) 0) (op-menor (de-dia d) 3)) :para (d dia))
"
                                  '("p-dura" "p-blanda" "p-par" "p-orden" "c-menor-igual" "c-mayor"
                                    "c-prohibida" "c-sin-para" "o-min" "o-max" "o-sin-consulta"
                                    "g-tqpq" "g-nppq" "g-sbqp" "g-ndpq")))))
  (contiene latex
            ;; Definiciones de consulta.
            "\\textit{dos\\_por\\_fila}(h) = \\sum_{\\textit{u} \\in \\text{FILA}} 2 \\cdot [\\, & \\textit{orden}(\\textit{turno}(\\textit{u})) = 1"
            "\\land\\ & (\\textit{dia}(\\textit{u}) = \\text{lunes} \\lor \\neg(\\textit{nombre}(\\textit{profesor}(\\textit{sesion}(\\textit{u}))) = \\text{``Ñu\\_\\%''}))\\,]"
            "((((\\textit{duracion}(\\textit{sesion}(\\textit{u})) - 1) \\cdot 4) / 2) + 0.5) \\cdot [\\,"
            "\\textit{de\\_par}(h) = \\sum_{\\textit{p} \\in \\text{PROFESOR},\\ \\{\\textit{a}, \\textit{b}\\} \\subseteq \\text{FILA}} [\\,"
            "\\textit{de\\_orden}(h) = \\sum_{\\textit{a} \\in \\text{FILA},\\ \\textit{b} \\in \\text{FILA}} [\\,"
            ;; Prohibiciones.
            "\\textit{dos\\_por\\_fila}(h) = 0"
            "\\textit{calculada}(h) = 0"
            "v_{2}(h) = \\textit{calculada}(h)"
            ;; Cotas: el requisito y su costo.
            "\\forall\\, \\textit{d} \\in \\text{DIA}:\\quad \\textit{de\\_dia}(h, \\textit{d}) \\le 5"
            "v_{5}(h) = \\sum_{\\textit{d} \\in \\text{DIA}} [\\textit{de\\_dia}(h, \\textit{d}) > 5] \\cdot (|\\textit{de\\_dia}(h, \\textit{d}) - 5|)"
            "\\forall\\, \\textit{d} \\in \\text{DIA}:\\quad \\textit{de\\_dia}(h, \\textit{d}) > 5"
            "v_{6}(h) = \\sum_{\\textit{d} \\in \\text{DIA}} [\\textit{de\\_dia}(h, \\textit{d}) \\le 5] \\cdot (|\\textit{de\\_dia}(h, \\textit{d}) - 5| + 1)"
            "v_{7}(h) = \\sum_{\\textit{d} \\in \\text{DIA}} [\\textit{de\\_dia}(h, \\textit{d}) > 5]"
            ;; Objetivos.
            "v_{9}(h) = \\max_{\\textit{d} \\in \\text{DIA}} \\textit{de\\_dia}(h, \\textit{d})"
            "v_{10}(h) = -\\min_{\\textit{p} \\in \\text{PROFESOR}} \\textit{de\\_profesor}(h, \\textit{p})"
            "v_{11}(h) = \\max_{\\textit{d} \\in \\text{DIA}} (1 + 2)"
            ;; Genéricas: lo exigido y lo que cuesta.
            "\\forall\\, \\textit{d} \\in \\text{DIA}:\\quad (\\textit{de\\_dia}(h, \\textit{d}) > 0 \\land \\textit{de\\_dia}(h, \\textit{d}) < 3)"
            "\\forall\\, \\textit{d} \\in \\text{DIA}:\\quad \\neg((\\textit{de\\_dia}(h, \\textit{d}) > 0 \\land \\textit{de\\_dia}(h, \\textit{d}) < 3))"
            "v_{14}(h) = \\sum_{\\textit{d} \\in \\text{DIA}} [\\neg((\\textit{de\\_dia}(h, \\textit{d}) > 0 \\land \\textit{de\\_dia}(h, \\textit{d}) < 3))]"
            "v_{15}(h) = \\sum_{\\textit{d} \\in \\text{DIA}} [(\\textit{de\\_dia}(h, \\textit{d}) > 0 \\land \\textit{de\\_dia}(h, \\textit{d}) < 3)]"
            ;; Objetivo: solo blandas, con su peso.
            "\\min_{h}\\ 2 \\cdot v_{2}(h) + 1 \\cdot v_{5}(h)")
  ;; Una blanda no va entre las duras.
  (assert (= 1 (loop with inicio = 0
                     for posicion = (search "\\paragraph{R2." latex :start2 inicio)
                     while posicion
                     count t
                     do (setf inicio (1+ posicion)))))
  (assert (> (search "\\paragraph{R2." latex) (search "Restricciones blandas" latex)))
  ;; Una dura no tiene valor en el objetivo.
  (no-contiene latex "v_{1}(h)" "v_{3}(h)" "v_{12}(h)" "v_{13}(h)")
  (assert (llaves-equilibradas-p latex))
  (comprobar-compilacion latex))

;; Sin blandas no hay objetivo que minimizar.
(contiene (latex-de (modelo-de "(def-nppq r (op-mayor (de-dia d) 0) :para (d dia))" '("r")))
          "Basta cumplir las restricciones."
          "fila $x \\in \\text{FILA}$ por cada elemento de $\\text{SESION}$"
          "\\textit{dia}(x) &\\in \\text{DIA}"
          "|\\text{SESION}| &= 4")

(assert (equal (emision::texto-latex "a_b%$&#{}\\~^") "a\\_b\\%\\$\\&\\#\\{\\}\\textbackslash{}\\textasciitilde{}\\textasciicircum{}"))
