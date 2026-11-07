(in-package :analisis)

(defun referencias (problema tipos)
  "Devuelve (entidad . entidades a las que apunta), sacado de los tipos de sus slots."
  (mapcar (lambda (entidad)
            (cons entidad
                  (remove-duplicates
                   (loop for ((dueno . nil) . tipo) in tipos
                         when (and (eq dueno entidad) (member tipo (problema-entidades problema)))
                           collect tipo)
                   :from-end t)))
          (problema-entidades problema)))

(defun orden-base (referencias)
  "Ordena las entidades: primero las que dependen de menos y, a igualdad, por nombre."
  (flet ((cuantas (entidad) (length (cdr (assoc entidad referencias)))))
    (sort (mapcar #'first referencias)
          (lambda (a b)
            (if (= (cuantas a) (cuantas b))
                (string< (symbol-name a) (symbol-name b))
                (< (cuantas a) (cuantas b)))))))

(defun orden-topologico (referencias)
  "Ordena las entidades de modo que cada una vaya después de las que referencia."
  (let ((orden '()))
    (labels ((visitar (entidad camino)
               (let ((repetida (member entidad camino)))
                 (when repetida
                   (rechazar "entidades: hay un ciclo: ~{~a~^ -> ~}"
                             (append (reverse (ldiff camino (rest repetida))) (list entidad)))))
               (unless (member entidad orden)
                 (dolist (referida (cdr (assoc entidad referencias)))
                   (visitar referida (cons entidad camino)))
                 (push entidad orden))))
      (dolist (entidad (orden-base referencias))
        (visitar entidad '())))
    (reverse orden)))
