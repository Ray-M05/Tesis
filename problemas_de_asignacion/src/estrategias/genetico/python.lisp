(in-package :estrategias)

(defclass genetico (estrategia)
  ((nombre      :initform "genetico")
   (descripcion :initform "Algoritmo genético sobre modelo.py.")
   (parada      :initform (make-instance 'parada-por-limite))
   (poblacion   :initarg :poblacion :initform 100 :reader genetico-poblacion)
   (generaciones :initarg :generaciones :initform 500 :reader genetico-generaciones)
   (probabilidad-de-cruce :initarg :probabilidad-de-cruce :initform 0.8
                          :reader genetico-probabilidad-de-cruce)
   (probabilidad-de-mutacion :initarg :probabilidad-de-mutacion :initform 0.15
                             :reader genetico-probabilidad-de-mutacion)
   (seleccion   :initarg :seleccion :initform (make-instance 'torneo) :reader genetico-seleccion)
   (cruce       :initarg :cruce :initform (make-instance 'cruce-un-punto) :reader genetico-cruce)
   (mutaciones  :initarg :mutaciones
                :initform (list (make-instance 'mover-filas) (make-instance 'intercambio))
                :reader genetico-mutaciones)))

(defmethod operadores-de ((estrategia genetico))
  (append (call-next-method)
          (list (genetico-seleccion estrategia) (genetico-cruce estrategia))
          (genetico-mutaciones estrategia)))

(defmethod maximo-de ((estrategia genetico)) "generaciones")

(defmethod argumentos-de ((estrategia genetico))
  (append (call-next-method)
          (list (list "poblacion" "int" (genetico-poblacion estrategia) "Individuos por generación.")
                (list "generaciones" "int" (genetico-generaciones estrategia)
                      "Máximo de generaciones.")
                (list "cruce" "float" (genetico-probabilidad-de-cruce estrategia)
                      "Probabilidad de cruzar cada pareja de padres.")
                (list "mutacion" "float" (genetico-probabilidad-de-mutacion estrategia)
                      "Probabilidad de mutar cada hijo."))))

(defun emitir-mutar (estrategia destino stream)
  "Define mutar: elige una mutación por su probabilidad, y si no, la primera."
  (destructuring-bind (primera &rest otras) (genetico-mutaciones estrategia)
    (linea destino stream "def mutar(azar, posiciones, args):")
    (con-sangria (destino)
      (when otras
        (linea destino stream "eleccion = azar.random()"))
      (loop for mutacion in otras
            collect (format nil "args.~a" (argumento-de-eleccion mutacion)) into limite
            do (linea destino stream "if eleccion < ~{~a~^ + ~}:" limite)
               (con-sangria (destino)
                 (linea destino stream "return ~a(azar, posiciones, args)" (funcion-de mutacion))))
      (linea destino stream "return ~a(azar, posiciones, args)" (funcion-de primera))))
  (terpri stream))

;; El mejor pasa siempre a la generación siguiente. Un padre que pasa sin cruce ni mutación
;; es el mismo individuo, así que conserva su costo.
(defmethod emitir-busqueda ((estrategia genetico) (destino python) stream)
  (emitir-mutar estrategia destino stream)
  (let ((seleccion (funcion-de (genetico-seleccion estrategia)))
        (cruce (funcion-de (genetico-cruce estrategia))))
    (emitir-lineas
     destino stream
     `("def buscar(args, azar, evaluador, parada, opciones):"
       ("poblacion = [Individuo(posiciones) for posiciones in INICIOS[args.inicio](azar, args.poblacion, opciones)]"
        "mejor = min(poblacion, key=evaluador.costo)"
        "generacion = sin_mejora = 0"
        "while True:"
        ("motivo = parada.motivo(generacion, sin_mejora, evaluador.valor(mejor))"
         "if motivo:"
         ("return mejor, generacion, motivo")
         "generacion += 1"
         "nueva = [mejor]"
         "while len(nueva) < args.poblacion:"
         (,(format nil "hijos = [~a(azar, poblacion, evaluador, args), ~:*~a(azar, poblacion, evaluador, args)]"
                   seleccion)
          "if azar.random() < args.cruce:"
          (,(format nil "hijos = [Individuo(posiciones) for posiciones in ~a(azar, hijos[0].posiciones, hijos[1].posiciones, args)]"
                    cruce))
          "for hijo in hijos:"
          ("if azar.random() < args.mutacion:"
           ("hijo = Individuo(mutar(azar, hijo.posiciones, args))")
           "nueva.append(hijo)"))
         "poblacion = nueva[:args.poblacion]"
         "candidato = min(poblacion, key=evaluador.costo)"
         "if evaluador.costo(candidato) < evaluador.costo(mejor):"
         ("mejor, sin_mejora = candidato, 0")
         "else:"
         ("sin_mejora += 1"))))))
  (terpri stream))
