(in-package :estrategias)

;; Un paso escribe f(azar, actual, evaluador, opciones, args), que da el individuo siguiente.
(defclass paso (operador) ())

;; Elige una fila al azar y le da, entre sus opciones permitidas, la de menor costo,
;; desempatando al azar. Con probabilidad --ruido le da una cualquiera de ellas.
(defclass mejor-opcion-de-fila (paso)
  ((ruido :initarg :ruido :initform 0 :reader paso-ruido)))

(defmethod argumentos-de ((operador mejor-opcion-de-fila))
  (list (list "ruido" "float" (paso-ruido operador)
              "Probabilidad de que un paso dé a la fila una opción al azar en vez de la mejor.")))

(defmethod emitir-operador ((operador mejor-opcion-de-fila) (destino python) stream)
  (emitir-lineas
   destino stream
   `(,(format nil "def ~a(azar, actual, evaluador, opciones, args):" (funcion-de operador))
     ("i = azar.randrange(FILAS)"
      "if azar.random() < args.ruido:"
      ("opcion = azar.choice(opciones[i])"
       "return Individuo(actual.posiciones[:i] + [opcion] + actual.posiciones[i + 1:])")
      "vecinos = [actual] + [Individuo(actual.posiciones[:i] + [opcion] + actual.posiciones[i + 1:])"
      ("for opcion in opciones[i] if opcion != actual.posiciones[i]]")
      "menor = min(evaluador.costo(vecino) for vecino in vecinos)"
      "return azar.choice([vecino for vecino in vecinos if evaluador.costo(vecino) == menor])"))))

(defclass busqueda-local (estrategia)
  ((nombre      :initform "busqueda_local")
   (descripcion :initform "Búsqueda local sobre modelo.py.")
   (parada      :initform (make-instance 'parada-por-estancamiento :estancamiento 2000))
   (pasos       :initarg :pasos :initform 100000 :reader busqueda-local-pasos)
   (paso        :initarg :paso :initform (make-instance 'mejor-opcion-de-fila)
                :reader busqueda-local-paso)))

(defmethod operadores-de ((estrategia busqueda-local))
  (append (call-next-method) (list (busqueda-local-paso estrategia))))

(defmethod maximo-de ((estrategia busqueda-local)) "pasos")

(defmethod argumentos-de ((estrategia busqueda-local))
  (append (call-next-method)
          (list (list "pasos" "int" (busqueda-local-pasos estrategia) "Máximo de pasos."))))

;; Recuerda el mejor horario visto, porque con ruido el actual puede empeorar.
(defmethod emitir-busqueda ((estrategia busqueda-local) (destino python) stream)
  (emitir-lineas
   destino stream
   `("def buscar(args, azar, evaluador, parada, opciones):"
     ("actual = mejor = Individuo(INICIOS[args.inicio](azar, 1, opciones)[0])"
      "pasos = sin_mejora = 0"
      "while True:"
      ("motivo = parada.motivo(pasos, sin_mejora, evaluador.valor(mejor))"
       "if motivo:"
       ("return mejor, pasos, motivo")
       "pasos += 1"
       ,(format nil "actual = ~a(azar, actual, evaluador, opciones, args)"
                (funcion-de (busqueda-local-paso estrategia)))
       "if evaluador.costo(actual) < evaluador.costo(mejor):"
       ("mejor, sin_mejora = actual, 0")
       "else:"
       ("sin_mejora += 1")))))
  (terpri stream))
