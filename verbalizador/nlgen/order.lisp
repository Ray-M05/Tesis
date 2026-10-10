;; =====================================================================
;; order.lisp — Orden logico de las entidades
;; =====================================================================
;; generar-python recorre las entidades con maphash. A Python le da igual
;; el orden en que se declaren las clases, porque nadie lee el archivo de
;; arriba abajo buscando entender el dominio. A la prosa no le da igual:
;; no se puede decir "un programa tiene tipo" antes de haber dicho que es
;; un tipo de programa.
;;

;; =====================================================================
;; EL GRAFO DE REFERENCIAS
;; =====================================================================

(defun entity-refs (nombre)
  "Entidades a las que NOMBRE apunta desde sus slots.

   Se deduce mirando las instancias reales, no los nombres de los slots.
   El nombre no basta: en tv el slot 'tipo' apunta a la entidad
   'tipo-programa', y en tesis los slots tutor, oponente, presidente,
   vocal y secretario apuntan todos a 'profesor' sin que el nombre lo
   diga."
  (let ((slots (gethash nombre *slots-de-entidad*))
        (insts (instancias-de nombre))
        (refs  '()))
    (if insts
        ;; Caso normal. Se recorren todas las instancias y no solo la
        ;; primera, por si algun slot esta sin ligar en unas y en otras no.
        (dolist (inst insts)
          (dolist (s slots)
            (when (slot-boundp inst s)
              (let ((v (slot-value inst s)))
                (when (typep v 'ref-especifica-ent)
                  (let ((e (entidad-de-clase (class-name (class-of v)))))
                    (when e (pushnew e refs))))))))
        ;; Sin instancias. Es el caso de la entidad combinacion: nadie
        ;; crea emisiones, las produce el solver. Pero def-comb declara
        ;; sus componentes COMO slots, y esos si son nombres de entidad
        ;; por construccion, asi que el grafo se lee de ahi.
        (dolist (s slots)
          (when (gethash s *slots-de-entidad*) (pushnew s refs))))
    (nreverse refs)))


;; =====================================================================
;; ORDEN TOPOLOGICO
;; =====================================================================

(defun entity-order (nombres)
  "Ordena NOMBRES de modo que cada entidad aparezca despues de todas las
   que referencia. Si hubiera un ciclo, corta y degrada al orden base en
   vez de colgarse."
  (let ((refs   (make-hash-table))
        (estado (make-hash-table))
        (salida '()))

    ;; Grafo, una sola pasada sobre las instancias. Se calcula aqui y no
    ;; dentro del sort para no repetir el recorrido en cada comparacion.
    (dolist (n nombres)
      (setf (gethash n refs) (intersection (entity-refs n) nombres)))

    ;; Orden base determinista: primero las entidades que no dependen de
    ;; nada, y a igualdad de dependencias, alfabetico.
    (let ((base (sort (copy-list nombres)
                      (lambda (a b)
                        (let ((na (length (gethash a refs)))
                              (nb (length (gethash b refs))))
                          (if (= na nb)
                              (string< (symbol-name a) (symbol-name b))
                              (< na nb)))))))

      (labels ((visitar (n)
                 (case (gethash n estado)
                   ;; :en-curso significa que hemos vuelto a entrar en un
                   ;; nodo que todavia esta en la pila: es un ciclo. Se
                   ;; corta sin error; el orden saldra imperfecto pero el
                   ;; documento se genera.
                   ((:hecho :en-curso) nil)
                   (t (setf (gethash n estado) :en-curso)
                      (dolist (r (gethash n refs)) (visitar r))
                      (setf (gethash n estado) :hecho)
                      (push n salida)))))
        (dolist (n base) (visitar n))))

    (nreverse salida)))
