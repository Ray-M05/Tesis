;; Corridas pequeñas del genético, para comprobar que sigue dando lo mismo:
;; sbcl --script generar.lisp --archivo ejecuciones/comprobacion-seder.lisp
(:dominio "seder"
 :destinos (python)
 :estrategias ((genetico :generaciones 20))
 :semillas (0 1)
 :ejecutar t)
