(in-package :pruebas-analisis)

(defun orden-de (dominio)
  "Calcula el orden de las entidades de uno de los cinco dominios."
  (let ((p (problema-real dominio)))
    (nombres (orden-topologico (referencias p (tipos-de-slots p))))))

;; El mismo orden que la prosa de referencia, sin jornada en Saúl.
(loop for (dominio . orden)
        in '(("tv" "CANAL" "DIA" "TIPO-PROGRAMA" "BLOQUE" "PROGRAMA" "EMISION")
             ("tesis" "ESTUDIANTE" "FECHA" "GRADO" "LOCAL" "MOMENTO" "PROFESOR" "TRIBUNAL"
              "ASIGNACION")
             ("docentes" "ASIGNATURA" "AULA" "DIA" "GRUPO" "PROFESOR" "TURNO" "SESION" "CLASE")
             ("seder" "CARRERA" "INSTALACION" "PROFESOR" "TURNO" "ANNO" "BRIGADA"
              "INDISPONIBILIDAD" "UBICACION")
             ("saul" "AULA" "DIA" "GRADO" "PROFESOR" "TURNO" "ASIGNATURA" "GRUPO" "PLAN" "SESION"
              "AUSENCIA" "UBICACION"))
      do (assert (equal (orden-de dominio) orden) () "~a: ~a" dominio (orden-de dominio)))

;; Referencias: salen de las instancias, y en la combinación, de sus componentes.
(let* ((p (problema-real "saul"))
       (de-saul (nombres (referencias p (tipos-de-slots p)))))
  (flet ((de (entidad) (cdr (assoc entidad de-saul :test #'equal))))
    (assert (equal (de "PLAN") '("GRUPO" "ASIGNATURA" "PROFESOR" "AULA")))
    (assert (equal (de "UBICACION") '("SESION" "DIA" "TURNO")))
    (assert (equal (de "SESION") '("PLAN")))
    (assert (null (de "DIA")))))

;; Varios slots que apuntan a la misma entidad cuentan como una sola referencia.
(let ((p (problema-real "tesis")))
  (assert (equal (cdr (assoc "TRIBUNAL" (nombres (referencias p (tipos-de-slots p))) :test #'equal))
                 '("ESTUDIANTE" "PROFESOR"))))

;; Cada entidad va después de las que referencia, sin importar cómo se declaren.
(assert (equal (orden-topologico '((c b) (b a) (a))) '(a b c)))
(assert (equal (orden-topologico '((a c) (b) (c b))) '(b c a)))
(assert (equal (orden-topologico '((z) (m) (a))) '(a m z)))
(assert (equal (orden-topologico '((a b c) (b c) (c))) '(c b a)))

(flet ((rechaza-ciclo (referencias &rest fragmentos)
         (handler-case (progn (orden-topologico referencias)
                              (error "No se rechazó: ~a" referencias))
           (error-dsl (condicion)
             (let ((mensaje (princ-to-string condicion)))
               (dolist (fragmento fragmentos)
                 (assert (search fragmento mensaje) () "~a" mensaje)))))))
  (rechaza-ciclo '((a b) (b a)) "ciclo" "A -> B -> A")
  (rechaza-ciclo '((a a)) "ciclo" "A -> A")
  (rechaza-ciclo '((x a) (a b) (b c) (c b)) "ciclo" "B -> C -> B"))
