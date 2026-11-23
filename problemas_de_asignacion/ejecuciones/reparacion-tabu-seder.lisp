;; La reparación tabú con sus valores por defecto y 10 semillas:
;; sbcl --script generar.lisp --archivo ejecuciones/reparacion-tabu-seder.lisp
(:dominio "seder"
 :destinos (python)
 :estrategias (reparacion-tabu)
 :semillas (0 1 2 3 4 5 6 7 8 9)
 :ejecutar t)
