;; El goloso frente al voraz actual, que es la búsqueda local sin pasos, con 25 semillas:
;; sbcl --script generar.lisp --archivo ejecuciones/goloso-saul.lisp
(:dominio "saul"
 :destinos (python)
 :estrategias (goloso
               (busqueda-local :pasos 0))
 :semillas (0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24)
 :ejecutar t)
