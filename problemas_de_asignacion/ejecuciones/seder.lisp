;; Tres semillas del SEDER con cada estrategia: sbcl --script generar.lisp --archivo ejecuciones/seder.lisp
(:dominio "seder"
 :destinos (python)
 :estrategias ((genetico :generaciones 100)
               (busqueda-local :tiempo 30))
 :semillas (0 1 2)
 :ejecutar t)
