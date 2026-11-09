(in-package :pruebas-estrategias)

(defun comprobar-primario (funcion argumentos que)
  "Exige que FUNCION tenga un método primario aplicable a ARGUMENTOS: un :around no basta."
  (assert (find-if (lambda (metodo) (null (method-qualifiers metodo)))
                   (compute-applicable-methods funcion argumentos))
          () "~a no tiene método de ~a" que funcion))

(let ((destino (allocate-instance (find-class 'python))))
  (dolist (clase (hojas-de 'operador))
    (comprobar-primario #'emitir-operador (list (allocate-instance clase) destino nil) clase))
  (dolist (clase (hojas-de 'estrategia))
    (let ((estrategia (allocate-instance clase)))
      (comprobar-primario #'emitir-estrategia (list estrategia destino nil) clase)
      (comprobar-primario #'estrategias::emitir-busqueda (list estrategia destino nil) clase)
      (comprobar-primario #'estrategias::maximo-de (list estrategia) clase))))

(dolist (clase (hojas-de 'estrategias::inicio))
  (comprobar-primario #'estrategias::nombre-de-inicio (list (allocate-instance clase)) clase))

;; Toda mutación salvo la primera necesita su probabilidad de ser elegida.
(dolist (mutacion (rest (estrategias::genetico-mutaciones (make-instance 'genetico))))
  (comprobar-primario #'estrategias::argumento-de-eleccion (list mutacion) (class-of mutacion)))

(assert (= (length (hojas-de 'operador)) 10))
(comprobar-sin-defecto #'emitir-operador '(0 1))
(comprobar-sin-defecto #'emitir-estrategia '(0 1))
(comprobar-sin-defecto #'estrategias::emitir-busqueda '(0 1))
(comprobar-sin-defecto #'argumentos-de '(0))

;; ejecuciones/README.md explica todos los argumentos.
(let ((texto (uiop:read-file-string (merge-pathnames "../../ejecuciones/README.md" pruebas-emision::*aqui*)
                                    :external-format :utf-8)))
  (dolist (estrategia (list (make-instance 'genetico) (make-instance 'busqueda-local)))
    (dolist (argumento (argumentos-de estrategia))
      (assert (search (format nil "| `--~a` |" (first argumento)) texto) ()
              "ejecuciones/README.md no explica --~a" (first argumento)))))
