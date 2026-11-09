(in-package :pruebas-orquestacion)

;; Se escribe lo pedido y nada más.
(con-carpeta (salida)
  (assert (conducir-en salida '(:dominios ("tv") :destinos ("matematica"))))
  (assert (equal (archivos-de salida) '("tv/avisos.txt" "tv/matematica/modelo.tex"))))

(con-carpeta (salida)
  (assert (conducir-en salida '(:dominios ("tv") :estrategias (("genetico")))))
  (assert (equal (archivos-de salida)
                 '("tv/avisos.txt" "tv/matematica/modelo.tex" "tv/python/genetico.py"
                   "tv/python/modelo.py" "tv/verbalizador/descripcion.md"))))

;; Una estrategia sin python pedido trae python, porque importa modelo.py.
(con-carpeta (salida)
  (assert (conducir-en salida '(:dominios ("tv") :destinos ("matematica") :estrategias (("genetico")))))
  (assert (equal (archivos-de salida)
                 '("tv/avisos.txt" "tv/matematica/modelo.tex" "tv/python/genetico.py"
                   "tv/python/modelo.py"))))

;; Sin nombrar nada: los tres destinos y los dos programas. Al regenerar, corridas/ se conserva.
(con-carpeta (salida)
  (assert (conducir-en salida '(:dominios ("tv"))))
  (assert (equal (archivos-de salida)
                 '("tv/avisos.txt" "tv/matematica/modelo.tex" "tv/python/busqueda_local.py"
                   "tv/python/genetico.py" "tv/python/modelo.py" "tv/verbalizador/descripcion.md")))
  (let ((guardada (merge-pathnames "tv/python/corridas/guardada.json" salida)))
    (escribir-texto guardada "{}")
    (assert (conducir-en salida '(:dominios ("tv"))))
    (assert (probe-file guardada))))

;; Los avisos se guardan, y el verbalizador recibe las anotaciones del dominio.
(con-carpeta (salida)
  (assert (conducir-en salida '(:dominios ("saul") :destinos ("verbalizador"))))
  (assert (search "RESTRICCION-FRECUENCIA-EXACTA: no depende de ninguna decisión"
                  (leer-texto (merge-pathnames "saul/avisos.txt" salida))))
  (assert (search "y dice si vive lejos del centro"
                  (leer-texto (merge-pathnames "saul/verbalizador/descripcion.md" salida)))))

;; Unas anotaciones mal formadas se rechazan.
(con-carpeta (carpeta)
  (escribir-texto (merge-pathnames "verbalizador.lisp" carpeta) "(:predicados ((\"a\" 1)))")
  (rechaza (lambda () (cargar-anotaciones (merge-pathnames "dominio.lisp" carpeta)))
           ":predicados tiene que ser una lista de (slot frase)"))

;; Un pedido mal escrito se rechaza antes de generar nada.
(con-carpeta (salida)
  (rechaza (lambda () (conducir-en salida '(:dominios ("tv") :destinos ("nada")))) "no existe el destino")
  (assert (not (probe-file salida))))

;; Dos dominios con la misma entidad en la misma imagen, y uno roto entre ellos.
(defun dominio-con (sesion)
  (format nil "(def-entidad dia () (nombre))
(def-entidad sesion () (nombre))
(def-comb fila (sesion dia))
(def-dia lunes \"Lunes\")
(def-sesion s1 ~s)
(def-problema el-problema :combinacion fila :identidad sesion :variables (dia) :restricciones ())
" sesion))

(con-carpeta (raiz)
  (let ((dominios (merge-pathnames "dominios/" raiz))
        (salida (merge-pathnames "salida/" raiz)))
    (escribir-texto (merge-pathnames "a/dominio.lisp" dominios) (dominio-con "Sesión de a"))
    (escribir-texto (merge-pathnames "b/dominio.lisp" dominios) "(def-entidad dia ()")
    (escribir-texto (merge-pathnames "c/dominio.lisp" dominios) (dominio-con "Sesión de c"))
    (assert (not (conducir-en salida '(:destinos ("python")) dominios)))
    (let ((a (leer-texto (merge-pathnames "a/python/modelo.py" salida)))
          (c (leer-texto (merge-pathnames "c/python/modelo.py" salida))))
      (assert (and (search "Sesión de a" a) (not (search "Sesión de c" a))))
      (assert (and (search "Sesión de c" c) (not (search "Sesión de a" c)))))
    (assert (not (probe-file (merge-pathnames "b/" salida))))))

;; Ejecutar: sin semillas se usa la 0, y los parámetros llegan al programa.
(con-carpeta (salida)
  (let ((corridas (merge-pathnames "tv/python/corridas/*.json" salida)))
    (assert (conducir-en salida '(:dominios ("tv") :destinos ("python")
                                  :estrategias (("genetico" :generaciones 5 :inicio permitidos))
                                  :ejecutar t)))
    (let ((texto (leer-texto (first (directory corridas)))))
      (assert (search "\"semilla\": 0," texto))
      (assert (search "\"generaciones\": 5," texto))
      (assert (search "\"inicio\": \"permitidos\"," texto)))
    (assert (conducir-en salida '(:dominios ("tv") :destinos ("python") :estrategias (("genetico"))
                                  :semillas (1 2) :ejecutar t)))
    (assert (= (length (directory corridas)) 3))
    ;; Una corrida que termina mal hace fallar el pedido.
    (assert (not (conducir-en salida '(:dominios ("tv") :destinos ("python")
                                       :estrategias (("genetico" :inicio nada)) :ejecutar t))))))
