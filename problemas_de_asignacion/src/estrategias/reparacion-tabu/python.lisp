(in-package :estrategias)

(defclass reparacion-tabu (estrategia-constructiva)
  ((nombre        :initform "reparacion_tabu")
   (descripcion   :initform "Reparación tabú sobre modelo.py.")
   (dano          :initform (make-instance 'dano-reversible))
   (memoria       :initarg :memoria :initform (make-instance 'tabu-corto)
                  :reader reparacion-tabu-memoria)
   (permuta       :initarg :permuta :initform (make-instance 'permuta-de-clave)
                  :reader reparacion-tabu-permuta)
   (arranques     :initarg :arranques :initform 10 :reader reparacion-tabu-arranques)
   (estancamiento :initarg :estancamiento :initform nil :reader reparacion-tabu-estancamiento)
   (pulido        :initarg :pulido :initform nil :reader reparacion-tabu-pulido)))

(defmethod operadores-de ((estrategia reparacion-tabu))
  (append (call-next-method)
          (list (reparacion-tabu-memoria estrategia) (reparacion-tabu-permuta estrategia))))

(defmethod argumentos-de ((estrategia reparacion-tabu))
  (append (call-next-method)
          (list (list "arranques" "int" (reparacion-tabu-arranques estrategia) "Máximo de arranques.")
                (list "estancamiento" "int" (reparacion-tabu-estancamiento estrategia)
                      "Pasos seguidos sin mejorar lo mejor del arranque que terminan la fase de las duras; sin valor, cinco por fila.")
                (list "pulido" "int" (reparacion-tabu-pulido estrategia)
                      "Pasos seguidos sin mejora que terminan la fase de las blandas; sin valor, uno por fila."))))

;; Para cada clave, las filas que la tienen en todas sus opciones y las celdas que alcanzan con
;; ella. Da por clave sus filas y su holgura; si es negativa, no hay solución.
(defun emitir-certificado (destino stream)
  "Define certificar(opciones), con las claves de modelo.CLAVES."
  (emitir-lineas
   destino stream
   '("def certificar(opciones):"
     ("filas, celdas = {}, {}"
      "for i in range(FILAS):"
      ("por_opcion = [{(nombre, clave): celda for nombre, claves in modelo.CLAVES.items()"
       ("for clave, celda in claves(modelo.crear_fila(i, opcion))} for opcion in opciones[i]]")
       "for clave in por_opcion[0]:"
       ("if all(clave in de_la_opcion for de_la_opcion in por_opcion):"
        ("filas.setdefault(clave, []).append(i)"
         "celdas.setdefault(clave, set()).update(de_la_opcion[clave] for de_la_opcion in por_opcion)")))
      "return {clave: (filas[clave], len(celdas[clave]) - len(filas[clave])) for clave in filas}")
     "")))

;; El horario que se repara: sus filas puestas en el daño y su (duras, blandas), que se lleva
;; sumando lo que cambia al sacar y meter cada fila.
(defun emitir-estado (estrategia destino stream)
  "Define Estado, el horario que se repara."
  (emitir-lineas
   destino stream
   `("class Estado:"
     ("def __init__(self, posiciones):"
      ("self.posiciones = list(posiciones)"
       "self.filas = [modelo.crear_fila(i, posicion) for i, posicion in enumerate(posiciones)]"
       "self.indices = {fila: i for i, fila in enumerate(self.filas)}"
       ,(format nil "self.dano = ~a()" (clase-de (estrategia-dano estrategia)))
       "for fila in self.filas:"
       ("self.dano.poner(fila)")
       "valores = modelo.evaluar(self.filas)"
       "self.valor = (sum(valores[nombre] for nombre, peso, _ in modelo.RESTRICCIONES if peso is None),"
       ("sum(peso * valores[nombre] for nombre, peso, _ in modelo.RESTRICCIONES if peso is not None))"))
      ""
      "def propio(self, i):"
      ("return self.dano.propio(self.filas[i])")
      ""
      "def afectadas(self, i):"
      ("return {i} | {self.indices[fila] for fila in self.dano.vecinas(self.filas[i])}")
      ""
      "def sacar(self, i):"
      ("fila = self.filas[i]"
       "self.dano.quitar(fila)"
       "del self.indices[fila]"
       "duras, blandas = self.dano.dano(fila)"
       "self.valor = (self.valor[0] - duras, self.valor[1] - blandas)")
      ""
      "def meter(self, i, opcion):"
      ("fila = modelo.crear_fila(i, opcion)"
       "duras, blandas = self.dano.dano(fila)"
       "self.dano.poner(fila)"
       "self.filas[i], self.posiciones[i], self.indices[fila] = fila, opcion, i"
       "self.valor = (self.valor[0] + duras, self.valor[1] + blandas)"))
     "")))

;; Contiene siempre a todas las filas en conflicto. Al elegir, descarta las que ya no lo están.
(defun emitir-candidatas (destino stream)
  "Define Candidatas, las filas que pueden estar en conflicto."
  (emitir-lineas
   destino stream
   '("class Candidatas:"
     ("def __init__(self):"
      ("self.lista = list(range(FILAS))"
       "self.dentro = set(self.lista)")
      ""
      "def anadir(self, filas):"
      ("for i in filas:"
       ("if i not in self.dentro:"
        ("self.dentro.add(i)"
         "self.lista.append(i)")))
      ""
      "def elegir(self, azar, en_conflicto):"
      ("while self.lista:"
       ("k = azar.randrange(len(self.lista))"
        "i = self.lista[k]"
        "if en_conflicto(i):"
        ("return i")
        "self.lista[k] = self.lista[-1]"
        "self.lista.pop()"
        "self.dentro.discard(i)")
       "return None"))
     "")))

(defun emitir-mejor (criterio destino stream)
  "Define Mejor, que guarda el mejor horario visto, las cuentas de la corrida y cada mejora."
  (emitir-lineas
   destino stream
   `("class Mejor:"
     ("def __init__(self, comienzo):"
      ("self.comienzo = comienzo"
       "self.valor = self.posiciones = None"
       "self.arranque = self.pasos = self.evaluaciones = 0"
       "self.mejoras = []")
      ""
      "def ver(self, estado):"
      (,(format nil "if self.valor is None or ~a(*estado.valor) < ~:*~a(*self.valor):" criterio)
       ("self.valor, self.posiciones = estado.valor, list(estado.posiciones)"
        "self.mejoras.append({'arranque': self.arranque, 'paso': self.pasos,"
        ("'segundos': round(time.perf_counter() - self.comienzo, 2),"
         "'duras': estado.valor[0], 'blandas': estado.valor[1]})"))))
     "")))

;; Lleva la fila a la celda de menor valor entre sus permitidas, sin la actual y sin las tabú, salvo
;; que una tabú mejore lo mejor del arranque. En la fase de las blandas no acepta duras.
(defun emitir-mover (criterio destino stream)
  "Define mover, el paso de mínimos conflictos, que da las filas a las que pudo cambiar el conflicto."
  (emitir-lineas
   destino stream
   `("def mover(azar, estado, i, opciones, tabu, paso, parte, del_arranque):"
     ("afectadas, actual = estado.afectadas(i), estado.posiciones[i]"
      "estado.sacar(i)"
      "valores = {}"
      "for opcion in opciones[i]:"
      ("if opcion != actual:"
       ("duras, blandas = estado.dano.dano(modelo.crear_fila(i, opcion))"
        ,(format nil "valor = ~a(estado.valor[0] + duras, estado.valor[1] + blandas)" criterio)
        ,(format nil "if (parte == 0 or estado.valor[0] + duras == 0) and (not tabu.prohibida(i, opcion, paso) or valor < ~a(*del_arranque)):" criterio)
        ("valores[opcion] = valor")))
      "if not valores:"
      ("estado.meter(i, actual)"
       "return set()")
      "menor = min(valores.values())"
      "estado.meter(i, azar.choice([opcion for opcion, valor in valores.items() if valor == menor]))"
      "tabu.marcar(i, actual, paso)"
      "return afectadas | estado.afectadas(i)")
     "")))

;; Da pasos sobre las filas en conflicto en una parte de (duras, blandas), 0 o 1, hasta LIMITE
;; pasos sin mejorar lo mejor del arranque. Si alguna restricción de esa parte no tiene
;; ocupaciones, cualquier fila puede entrar en conflicto tras un paso.
(defun emitir-reparar (estrategia destino stream)
  "Define reparar, una fase de la reparación."
  (let ((criterio (funcion-de (estrategia-criterio estrategia))))
    (emitir-lineas
     destino stream
     `("def reparar(azar, estado, opciones, admitidas, companeras, tabu, mejor, args, parte, limite):"
       ("sin_tablas = any(ocupaciones is None for _, peso, _, ocupaciones in estado.dano.vivas if (peso is None) == (parte == 0))"
        "candidatas = Candidatas()"
        "del_arranque, sin_mejora = estado.valor, 0"
        "while estado.valor[parte] > 0 and sin_mejora < limite:"
        ("i = candidatas.elegir(azar, lambda i: estado.propio(i)[parte] > 0)"
         "if i is None:"
         ("return")
         "mejor.pasos += 1"
         "afectadas = None"
         "if i in companeras:"
         (,(format nil "afectadas = ~a(azar, estado, i, companeras[i], tabu, mejor.pasos, admitidas, ~a, args)"
                   (funcion-de (reparacion-tabu-permuta estrategia)) criterio))
         "if afectadas is None:"
         ("afectadas = mover(azar, estado, i, opciones, tabu, mejor.pasos, parte, del_arranque)")
         "candidatas.anadir(range(FILAS) if sin_tablas else sorted(afectadas))"
         ,(format nil "if ~a(*estado.valor) < ~:*~a(*del_arranque):" criterio)
         ("del_arranque, sin_mejora = estado.valor, 0"
          "mejor.ver(estado)")
         "else:"
         ("sin_mejora += 1")))
       ""))))

;; Cada arranque construye con la pasada golosa, repara las duras y, si llega a 0, pule las
;; blandas. Hace al menos un arranque, y para en (0, 0) o al llegar a --arranques.
(defmethod emitir-busqueda ((estrategia reparacion-tabu) (destino python) stream)
  (let ((criterio (funcion-de (estrategia-criterio estrategia))))
    (emitir-certificado destino stream)
    (emitir-pasada estrategia destino stream "construir")
    (emitir-estado estrategia destino stream)
    (emitir-candidatas destino stream)
    (emitir-mejor criterio destino stream)
    (emitir-mover criterio destino stream)
    (emitir-reparar estrategia destino stream)
    (emitir-lineas
     destino stream
     `("def buscar(args, azar, opciones, comienzo):"
       ("admitidas = [set(de_la_fila) for de_la_fila in opciones]"
        "holguras = certificar(opciones)"
        "justas = {}"
        "for de_la_clave, holgura in holguras.values():"
        ("for i in de_la_clave:"
         ("if i not in justas or holgura < justas[i][0]:"
          ("justas[i] = (holgura, de_la_clave)")))
        "companeras = {i: [j for j in de_la_clave if j != i] for i, (_, de_la_clave) in justas.items() if len(de_la_clave) > 1}"
        "certificado = [{'restriccion': nombre, 'clave': [str(valor) for valor in clave], 'filas': len(de_la_clave), 'holgura': holgura}"
        ("for (nombre, clave), (de_la_clave, holgura) in holguras.items() if holgura <= 0]")
        "infactible = any(holgura < 0 for _, holgura in holguras.values())"
        "estancamiento = 5 * FILAS if args.estancamiento is None else args.estancamiento"
        "pulido = FILAS if args.pulido is None else args.pulido"
        "mejor = Mejor(comienzo)"
        "while True:"
        ("mejor.arranque += 1"
         "mejor.evaluaciones += 1"
         "estado = Estado(construir(args, azar, opciones)[0])"
         "mejor.ver(estado)"
         "if infactible:"
         ("return mejor, 'infactible', certificado")
         ,(format nil "tabu = ~a(args)" (clase-de (reparacion-tabu-memoria estrategia)))
         "reparar(azar, estado, opciones, admitidas, companeras, tabu, mejor, args, 0, estancamiento)"
         "if estado.valor[0] == 0:"
         ("reparar(azar, estado, opciones, admitidas, companeras, tabu, mejor, args, 1, pulido)")
         "if mejor.valor == (0, 0):"
         ("return mejor, 'optimo', certificado")
         "if mejor.arranque >= args.arranques:"
         ("return mejor, 'maximo', certificado")))
       ""))))

;; Como la de una estrategia constructiva, con lo que da el bucle de arranques.
(defmethod emitir-principal ((estrategia reparacion-tabu) (destino python) stream)
  (emitir-lineas
   destino stream
   '("args = leer_argumentos()"
     "azar = random.Random(args.semilla)"
     "comienzo = time.perf_counter()"
     "permitidas = opciones_permitidas()"
     "opciones = [de_la_fila or OPCIONES for de_la_fila in permitidas]"
     "mejor, motivo, certificado = buscar(args, azar, opciones, comienzo)"
     "salida = modelo.a_json(modelo.crear_horario(mejor.posiciones))"
     "duras = sum(salida['valores'][nombre] for nombre, peso, _ in modelo.RESTRICCIONES if peso is None)"
     "blandas = sum(peso * salida['valores'][nombre] for nombre, peso, _ in modelo.RESTRICCIONES if peso is not None)"
     "resultado = {"))
  (con-sangria (destino)
    (linea destino stream "'estrategia': ~s," (estrategia-nombre estrategia))
    (emitir-lineas destino stream
                   '("'argumentos': vars(args),"
                     "'motivo_de_parada': motivo,"
                     "'iteraciones': mejor.pasos,"
                     "'arranques': mejor.arranque,"
                     "'evaluaciones': mejor.evaluaciones + 1,"
                     "'segundos': round(time.perf_counter() - comienzo, 2),"
                     "'sin_opciones_permitidas': [str(modelo.IDENTIDADES[i]) for i, de_la_fila in enumerate(permitidas) if not de_la_fila],"
                     "'certificado': certificado,"
                     "'mejoras': mejor.mejoras,"
                     "'duras': duras,"
                     "'blandas': blandas,"
                     "'posiciones': [list(posicion) for posicion in mejor.posiciones],"
                     "**salida,")))
  (emitir-lineas destino stream '("}"))
  (emitir-guardar-corrida estrategia destino stream
                          "print(f'duras {duras}, blandas {blandas}, {mejor.arranque} arranques, {mejor.pasos} pasos, parada por {motivo}')"))
