(in-package :pruebas-analisis)

(defun nodo-llamado (problema nombre)
  "Devuelve el nodo de la consulta NOMBRE, derivada del problema."
  (first (find nombre (dominios-de-parametros problema)
               :key (lambda (entrada) (symbol-name (slot-value (first entrada) 'nombre)))
               :test #'equal)))

(defun simetrica-en-p (problema nombre)
  "Dice si la consulta NOMBRE es simétrica entre sus dos filas."
  (let* ((nodo (nodo-llamado problema nombre))
         (filas (remove (problema-combinacion problema) (iteradores-de nodo)
                        :key #'second :test-not #'eq)))
    (simetrica-p (slot-value nodo 'comprobacion)
                 (first (first filas)) (first (second filas)))))

(defparameter *simetricas*
  '(("tesis" "CONFLICTOS-DE-HORARIO" "COLISIONES-DE-LOCAL")
    ("docentes" "COLISIONES-DE-PROFESOR" "COLISIONES-DE-AULA" "COLISIONES-DE-GRUPO")
    ("seder" "COLISIONES-DE-INSTALACION" "COLISIONES-DE-PROFESOR")
    ("saul" "COLISIONES-DE-GRUPO" "COLISIONES-DE-PROFESOR" "REPETICIONES-EN-EL-DIA")))

(defparameter *no-simetricas*
  '(("tv" "ADYACENTES-MISMO-TIPO" "CONSECUTIVOS-POR-CANAL")
    ("saul" "DOBLES-NO-CONSECUTIVOS")))

(assert (= (reduce #'+ (mapcar (lambda (x) (length (rest x))) *simetricas*)) 10))

(loop for (dominio . consultas) in *simetricas*
      do (dolist (consulta consultas)
           (assert (simetrica-en-p (problema-real dominio) consulta) () "~a" consulta)))

(loop for (dominio . consultas) in *no-simetricas*
      do (dolist (consulta consultas)
           (assert (not (simetrica-en-p (problema-real dominio) consulta)) () "~a" consulta)))

(defun simetrica-texto-p (condicion)
  "Dice si una condición escrita sobre las variables A y B es simétrica."
  (let* ((p (problema-de (format nil "(def-consulta m ()
                                        :pares (a b) fila
                                        :comprueba ~a
                                        :operacion (suma 1))
                                      (def-nppq r (op-mayor (m) 0))"
                                 condicion))))
    (simetrica-en-p p "M")))

;; El orden de los operandos y de los términos no importa.
(assert (simetrica-texto-p "(op-y (op-igual (dia a) (dia b)) (op-igual (turno b) (turno a)))"))
(assert (simetrica-texto-p "(op-distinto (sesion b) (sesion a))"))
(assert (simetrica-texto-p "(op-y (op-mayor (orden (dia a)) 1) (op-mayor (orden (dia b)) 1))"))
(assert (simetrica-texto-p "(op-y (op-mayor (orden (dia b)) 1) (op-mayor (orden (dia a)) 1))"))

;; Lo que depende del orden no es simétrico.
(assert (not (simetrica-texto-p "(op-mayor (orden (dia a)) (orden (dia b)))")))
(assert (not (simetrica-texto-p "(op-igual (op-suma (orden (dia a)) 1) (orden (dia b)))")))

;; Un filtro sobre una sola fila solo es simétrico si otra igualdad lo traslada a la otra.
(assert (not (simetrica-texto-p "(op-mayor (orden (dia a)) 1)")))
(assert (simetrica-texto-p "(op-y (op-igual (dia a) (dia b)) (op-mayor (orden (dia a)) 1))"))
(assert (not (simetrica-texto-p "(op-y (op-igual (turno a) (turno b))
                                         (op-mayor (orden (dia a)) 1))")))

;; Dos instancias distintas no son lo mismo, y la misma sí.
(assert (not (simetrica-texto-p "(op-y (op-igual (dia a) lunes) (op-igual (dia b) martes))")))
(assert (simetrica-texto-p "(op-y (op-igual (dia a) lunes) (op-igual (dia b) lunes))"))
