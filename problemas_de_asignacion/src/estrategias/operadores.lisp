(in-package :estrategias)

;; Un inicio escribe f(azar, cantidad, opciones), que da CANTIDAD listas de posiciones.
;; OPCIONES tiene, por cada fila, sus opciones permitidas, o todas si no tiene ninguna.
(defclass inicio (operador) ())
(defclass inicio-voraz (inicio) ())
(defclass inicio-permitido (inicio) ())
(defclass inicio-aleatorio (inicio) ())

;; Una selección escribe f(azar, poblacion, evaluador, args), que da un individuo.
(defclass seleccion (operador) ())
(defclass torneo (seleccion)
  ((tamano :initarg :tamano :initform 5 :reader torneo-tamano)))

;; Un cruce escribe f(azar, a, b, args), que da dos listas de posiciones.
(defclass cruce (operador) ())
(defclass cruce-un-punto (cruce) ())

;; Una mutación escribe f(azar, posiciones, args), que da una lista nueva de posiciones.
(defclass mutacion (operador) ())
(defclass mover-filas (mutacion)
  ((radio :initarg :radio :initform 2 :reader mover-filas-radio)))
(defclass intercambio (mutacion)
  ((probabilidad :initarg :probabilidad :initform 0.3 :reader intercambio-probabilidad)))

;; Una parada escribe la clase que decide cuándo terminar. Toda parada se detiene en el óptimo,
;; en el máximo de iteraciones y por tiempo.
(defclass parada (operador)
  ((tiempo :initarg :tiempo :initform nil :reader parada-tiempo)))
(defclass parada-por-limite (parada) ())
(defclass parada-por-estancamiento (parada)
  ((estancamiento :initarg :estancamiento :reader parada-estancamiento)))

;; Un orden escribe f(azar, opciones), que da las filas en el orden en que se colocan.
(defclass orden (operador) ())
(defclass menos-opciones-primero (orden) ())

;; Un criterio escribe f(duras, blandas), que da con qué se compara el daño de dos celdas.
(defclass criterio (operador) ())
(defclass menor-dano (criterio) ())

;; Un desempate escribe una clase con elegir(azar, i, empatadas), que da una de las celdas
;; empatadas, y quitar(i), que avisa de que la fila i ya está puesta.
(defclass desempate (operador) ())
(defclass celda-menos-demandada (desempate) ())

;; Un daño escribe una clase con dano(fila), que da cuánto suben las duras y las blandas al
;; poner la fila, y poner(fila).
(defclass dano (operador) ())
(defclass dano-por-tablas (dano) ())

;; Un daño reversible escribe además quitar(fila); propio(fila), que da cuánto bajan las duras y
;; las blandas al quitar una fila puesta; y vecinas(fila).
(defclass dano-reversible (dano-por-tablas) ())

;; Una memoria escribe una clase con prohibida(i, opcion, paso), que dice si la fila i no puede
;; volver a opcion en ese paso, y marcar(i, opcion, paso).
(defclass memoria (operador) ())
(defclass tabu-corto (memoria)
  ((duracion :initarg :duracion :initform 10 :reader tabu-corto-duracion)))

;; Una permuta escribe f(azar, estado, i, companeras, tabu, paso, admitidas, criterio, args), que
;; intercambia las celdas de la fila i con las de una compañera y da las filas a las que pudo
;; cambiar el conflicto, o None si no intercambia.
(defclass permuta (operador) ())
(defclass permuta-de-clave (permuta)
  ((probabilidad :initarg :probabilidad :initform 0.25 :reader permuta-de-clave-probabilidad)))

(defmethod nombre-de-inicio ((inicio inicio-voraz)) "voraz")
(defmethod nombre-de-inicio ((inicio inicio-permitido)) "permitidos")
(defmethod nombre-de-inicio ((inicio inicio-aleatorio)) "aleatorio")

(defgeneric argumento-de-eleccion (mutacion)
  (:documentation "Devuelve el argumento con la probabilidad de elegir esta mutación frente a la primera."))

(defmethod argumento-de-eleccion ((mutacion intercambio)) "intercambio")

(defmethod argumentos-de ((operador torneo))
  (list (list "torneo" "int" (torneo-tamano operador) "Individuos que compiten en cada torneo.")))

(defmethod argumentos-de ((operador mover-filas))
  (list (list "radio" "int" (mover-filas-radio operador)
              "Cuántas filas cambia, como mucho, una mutación.")))

(defmethod argumentos-de ((operador intercambio))
  (list (list "intercambio" "float" (intercambio-probabilidad operador)
              "Probabilidad de que una mutación intercambie dos filas en vez de moverlas.")))

(defmethod argumentos-de ((operador tabu-corto))
  (list (list "tabu" "int" (tabu-corto-duracion operador)
              "Pasos durante los que una fila no puede volver a la celda que acaba de dejar.")))

(defmethod argumentos-de ((operador permuta-de-clave))
  (list (list "permuta" "float" (permuta-de-clave-probabilidad operador)
              "Probabilidad de que un paso intente intercambiar la fila con otra de su clave más justa.")))

(defmethod argumentos-de ((operador parada))
  (list (list "tiempo" "float" (parada-tiempo operador)
              "Segundos tras los que se detiene; sin valor, no hay límite.")))

(defmethod argumentos-de ((operador parada-por-estancamiento))
  (append (call-next-method)
          (list (list "estancamiento" "int" (parada-estancamiento operador)
                      "Iteraciones seguidas sin mejora tras las que se detiene."))))

(defmethod emitir-operador :around ((operador operador) (destino python) stream)
  (call-next-method)
  (terpri stream))

(defmethod emitir-operador ((operador inicio-aleatorio) (destino python) stream)
  (emitir-lineas destino stream
                 `(,(format nil "def ~a(azar, cantidad, opciones):" (funcion-de operador))
                   ("return [[azar.choice(OPCIONES) for _ in range(FILAS)] for _ in range(cantidad)]"))))

(defmethod emitir-operador ((operador inicio-permitido) (destino python) stream)
  (emitir-lineas destino stream
                 `(,(format nil "def ~a(azar, cantidad, opciones):" (funcion-de operador))
                   ("return [[azar.choice(de_la_fila) for de_la_fila in opciones] for _ in range(cantidad)]"))))

;; Coloca primero las filas con menos opciones, cada una donde menos prohibiciones incumple
;; con las ya colocadas. El resto de la población sale de las opciones permitidas.
(defmethod emitir-operador ((operador inicio-voraz) (destino python) stream)
  (emitir-lineas destino stream
                 `(,(format nil "def ~a(azar, cantidad, opciones):" (funcion-de operador))
                   ("prohibiciones = [FUNCIONES[nombre] for nombre in modelo.PROHIBICIONES]"
                    "orden = sorted(range(FILAS), key=lambda i: (len(opciones[i]), azar.random()))"
                    "posiciones = [None] * FILAS"
                    "puestas = []"
                    "for i in orden:"
                    ("mejores, menor = [], None"
                     "for opcion in opciones[i]:"
                     ("nueva = modelo.crear_fila(i, opcion)"
                      "incumple = sum(funcion(puestas + [nueva]) for funcion in prohibiciones)"
                      "if menor is None or incumple < menor:"
                      ("mejores, menor = [], incumple")
                      "if incumple == menor:"
                      ("mejores.append((opcion, nueva))"))
                     "posiciones[i], nueva = azar.choice(mejores)"
                     "puestas.append(nueva)")
                    "resto = [[azar.choice(de_la_fila) for de_la_fila in opciones] for _ in range(cantidad - 1)]"
                    "return [posiciones] + resto"))))

(defmethod emitir-operador ((operador torneo) (destino python) stream)
  (emitir-lineas destino stream
                 `(,(format nil "def ~a(azar, poblacion, evaluador, args):" (funcion-de operador))
                   ("return min(azar.sample(poblacion, min(args.torneo, len(poblacion))), key=evaluador.costo)"))))

(defmethod emitir-operador ((operador cruce-un-punto) (destino python) stream)
  (emitir-lineas destino stream
                 `(,(format nil "def ~a(azar, a, b, args):" (funcion-de operador))
                   ("if FILAS < 2:"
                    ("return list(a), list(b)")
                    "corte = azar.randint(1, FILAS - 1)"
                    "return a[:corte] + b[corte:], b[:corte] + a[corte:]"))))

;; Cambia un campo al azar, sin mirar si el valor está permitido, en entre 1 y --radio filas.
(defmethod emitir-operador ((operador mover-filas) (destino python) stream)
  (emitir-lineas destino stream
                 `(,(format nil "def ~a(azar, posiciones, args):" (funcion-de operador))
                   ("nuevas = list(posiciones)"
                    "for i in azar.sample(range(FILAS), min(azar.randint(1, args.radio), FILAS)):"
                    ("fila = list(nuevas[i])"
                     "campo = azar.randrange(len(TAMANOS))"
                     "fila[campo] = azar.randrange(TAMANOS[campo])"
                     "nuevas[i] = tuple(fila)")
                    "return nuevas"))))

(defmethod emitir-operador ((operador intercambio) (destino python) stream)
  (emitir-lineas destino stream
                 `(,(format nil "def ~a(azar, posiciones, args):" (funcion-de operador))
                   ("nuevas = list(posiciones)"
                    "if FILAS > 1:"
                    ("i, j = azar.sample(range(FILAS), 2)"
                     "nuevas[i], nuevas[j] = nuevas[j], nuevas[i]")
                    "return nuevas"))))

(defun emitir-parada (operador destino stream estancamiento)
  "Escribe la clase de una parada; con ESTANCAMIENTO, también se detiene tras iteraciones sin mejora."
  (emitir-lineas destino stream
                 `(,(format nil "class ~a:" (clase-python (class-name (class-of operador))))
                   ("def __init__(self, maximo, args):"
                    ("self.maximo = maximo"
                     ,@(when estancamiento '("self.estancamiento = args.estancamiento"))
                     "self.tiempo = args.tiempo"
                     "self.comienzo = time.perf_counter()")
                    ""
                    "def segundos(self):"
                    ("return time.perf_counter() - self.comienzo")
                    ""
                    "def motivo(self, iteracion, sin_mejora, valor):"
                    ("_, duras, blandas = valor"
                     "if duras == 0 and blandas == 0:"
                     ("return 'optimo'")
                     ,@(when estancamiento
                         '("if sin_mejora >= self.estancamiento:"
                           ("return 'estancamiento'")))
                     "if iteracion >= self.maximo:"
                     ("return 'maximo'")
                     "if self.tiempo is not None and self.segundos() >= self.tiempo:"
                     ("return 'tiempo'")
                     "return None")))))

(defmethod emitir-operador ((operador parada-por-limite) (destino python) stream)
  (emitir-parada operador destino stream nil))

(defmethod emitir-operador ((operador parada-por-estancamiento) (destino python) stream)
  (emitir-parada operador destino stream t))

(defmethod emitir-operador ((operador menos-opciones-primero) (destino python) stream)
  (emitir-lineas destino stream
                 `(,(format nil "def ~a(azar, opciones):" (funcion-de operador))
                   ("return sorted(range(FILAS), key=lambda i: (len(opciones[i]), azar.random()))"))))

(defmethod emitir-operador ((operador menor-dano) (destino python) stream)
  (emitir-lineas destino stream
                 `(,(format nil "def ~a(duras, blandas):" (funcion-de operador))
                   ("return (duras, blandas)"))))

;; La demanda de una ocupación es cuántas filas pendientes podrían tomarla. Cuentan las
;; ocupaciones de las duras, y una fila cuenta una vez por ocupación.
(defmethod emitir-operador ((operador celda-menos-demandada) (destino python) stream)
  (emitir-lineas
   destino stream
   `(,(format nil "class ~a:" (clase-de operador))
     ("def __init__(self, opciones):"
      ("duras = [(nombre, modelo.OCUPACIONES[nombre]) for nombre, peso, _ in modelo.RESTRICCIONES"
       ("if peso is None and nombre in modelo.OCUPACIONES]")
       "self.claves = [{opcion: {(nombre, clave) for nombre, ocupaciones in duras"
       ("for clave in ocupaciones(modelo.crear_fila(i, opcion))}"
        "for opcion in opciones[i]} for i in range(FILAS)]")
       "self.propias = [set().union(*claves.values()) for claves in self.claves]"
       "self.demanda = {}"
       "for propias in self.propias:"
       ("for clave in propias:"
        ("self.demanda[clave] = self.demanda.get(clave, 0) + 1")))
      ""
      "def elegir(self, azar, i, empatadas):"
      ("demandas = {opcion: sum(self.demanda[clave] - 1 for clave in self.claves[i][opcion])"
       ("for opcion in empatadas}")
       "menor = min(demandas.values())"
       "return azar.choice([opcion for opcion in empatadas if demandas[opcion] == menor])")
      ""
      "def quitar(self, i):"
      ("for clave in self.propias[i]:"
       ("self.demanda[clave] -= 1"))))))

;; Una restricción con ocupaciones se evalúa sobre la fila y las vecinas, las filas puestas que
;; comparten alguna ocupación con ella. Sin ocupaciones, sobre todas las filas puestas.
(defmethod emitir-operador ((operador dano-por-tablas) (destino python) stream)
  (emitir-lineas
   destino stream
   `(,(format nil "class ~a:" (clase-de operador))
     ("def __init__(self):"
      ("self.vivas = [(nombre, peso, funcion, modelo.OCUPACIONES.get(nombre))"
       ("for nombre, peso, funcion in modelo.RESTRICCIONES if nombre not in modelo.CONSTANTES]")
       "self.puestas = []"
       "self.tablas = {nombre: {} for nombre, _, _, ocupaciones in self.vivas if ocupaciones}"
       "self.valores = {nombre: funcion([]) for nombre, _, funcion, ocupaciones in self.vivas if not ocupaciones}")
      ""
      "def cambio(self, viva, fila):"
      ("nombre, _, funcion, ocupaciones = viva"
       "if not ocupaciones:"
       ("return funcion(self.puestas + [fila]) - self.valores[nombre]")
       "tabla = self.tablas[nombre]"
       "vecinas = list(dict.fromkeys(otra for clave in ocupaciones(fila) for otra in tabla.get(clave, ())))"
       "return funcion(vecinas + [fila]) - funcion(vecinas)")
      ""
      "def dano(self, fila):"
      ("duras = blandas = 0"
       "for viva in self.vivas:"
       ("cambio = self.cambio(viva, fila)"
        "if viva[1] is None:"
        ("duras += cambio")
        "else:"
        ("blandas += viva[1] * cambio"))
       "return duras, blandas")
      ""
      "def poner(self, fila):"
      ("self.puestas.append(fila)"
       "for nombre, _, funcion, ocupaciones in self.vivas:"
       ("if ocupaciones:"
        ("for clave in ocupaciones(fila):"
         ("self.tablas[nombre].setdefault(clave, []).append(fila)"))
        "else:"
        ("self.valores[nombre] = funcion(self.puestas)")))))))

;; Las mismas tablas que el daño del goloso, con lo que hace falta para sacar una fila puesta.
(defmethod emitir-operador ((operador dano-reversible) (destino python) stream)
  (call-next-method)
  (emitir-lineas
   destino stream
   '((""
      "def quitar(self, fila):"
      ("self.puestas.remove(fila)"
       "for nombre, _, funcion, ocupaciones in self.vivas:"
       ("if ocupaciones:"
        ("for clave in ocupaciones(fila):"
         ("self.tablas[nombre][clave].remove(fila)"))
        "else:"
        ("self.valores[nombre] = funcion(self.puestas)")))
      ""
      "def propio(self, fila):"
      ("self.quitar(fila)"
       "valor = self.dano(fila)"
       "self.poner(fila)"
       "return valor")
      ""
      "def vecinas(self, fila):"
      ("return {otra for nombre, _, _, ocupaciones in self.vivas if ocupaciones"
       ("for clave in ocupaciones(fila) for otra in self.tablas[nombre].get(clave, ()) if otra is not fila}"))))))

(defmethod emitir-operador ((operador tabu-corto) (destino python) stream)
  (emitir-lineas
   destino stream
   `(,(format nil "class ~a:" (clase-de operador))
     ("def __init__(self, args):"
      ("self.duracion = args.tabu"
       "self.hasta = {}")
      ""
      "def prohibida(self, i, opcion, paso):"
      ("return paso <= self.hasta.get((i, opcion), -1)")
      ""
      "def marcar(self, i, opcion, paso):"
      ("self.hasta[i, opcion] = paso + self.duracion")))))

;; Prueba las compañeras en orden al azar y se queda con la primera que no sale de su dominio,
;; no es tabú y no empeora. Si empeora, deshace el intercambio.
(defmethod emitir-operador ((operador permuta-de-clave) (destino python) stream)
  (emitir-lineas
   destino stream
   `(,(format nil "def ~a(azar, estado, i, companeras, tabu, paso, admitidas, criterio, args):"
              (funcion-de operador))
     ("if azar.random() >= args.permuta:"
      ("return None")
      "for j in azar.sample(companeras, len(companeras)):"
      ("a, b = estado.posiciones[j], estado.posiciones[i]"
       "if a == b or a not in admitidas[i] or b not in admitidas[j] or tabu.prohibida(i, a, paso) or tabu.prohibida(j, b, paso):"
       ("continue")
       "antes, afectadas = estado.valor, estado.afectadas(i) | estado.afectadas(j)"
       "estado.sacar(i)"
       "estado.sacar(j)"
       "estado.meter(i, a)"
       "estado.meter(j, b)"
       "if criterio(*estado.valor) <= criterio(*antes):"
       ("tabu.marcar(i, b, paso)"
        "tabu.marcar(j, a, paso)"
        "return afectadas | estado.afectadas(i) | estado.afectadas(j)")
       "estado.sacar(i)"
       "estado.sacar(j)"
       "estado.meter(i, b)"
       "estado.meter(j, a)")
      "return None"))))
