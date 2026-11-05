(defclass* tiene-nombre () (nombre))
(def-entidad dia (tiene-nombre))
(def-entidad sesion () (numero))
(def-comb fila (sesion dia))
(def-dia miercoles "Miércoles")
(def-sesion s1 1)
(def-problema problema-de-archivo
  :combinacion fila :identidad sesion :variables (dia) :restricciones ())
