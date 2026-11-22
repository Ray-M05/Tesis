;; Corridas pequeñas del genético, para comprobar que sigue dando lo mismo:
;; sbcl --script generar.lisp --archivo ejecuciones/comprobacion-docentes.lisp
(:dominio "docentes"
 :destinos (python)
 :estrategias ((genetico :generaciones 20))
 :semillas (0 1)
 :ejecutar t)
