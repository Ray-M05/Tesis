(in-package :estrategias)

(defclass operador () ()
  (:documentation "Una pieza de una estrategia, que escribe su propia función."))

(defclass estrategia ()
  ((nombre       :initarg :nombre       :reader estrategia-nombre)
   (descripcion  :initarg :descripcion  :reader estrategia-descripcion)
   (penalizacion :initarg :penalizacion :initform 1000 :reader estrategia-penalizacion)
   (inicios      :initarg :inicios      :reader estrategia-inicios
                 :initform (list (make-instance 'inicio-voraz)
                                 (make-instance 'inicio-permitido)
                                 (make-instance 'inicio-aleatorio)))
   (inicio       :initarg :inicio       :initform "voraz" :reader estrategia-inicio)
   (parada       :initarg :parada       :reader estrategia-parada)))

(defgeneric emitir-operador (operador destino stream)
  (:documentation "Escribe la función de un operador."))

(defgeneric emitir-estrategia (estrategia destino stream)
  (:documentation "Escribe el programa completo de una estrategia."))

(defgeneric emitir-busqueda (estrategia destino stream)
  (:documentation "Escribe buscar, que devuelve el mejor individuo, las iteraciones y el motivo de parada."))

(defgeneric operadores-de (estrategia)
  (:documentation "Devuelve los operadores que usa la estrategia, en el orden en que se escriben."))

(defgeneric argumentos-de (objeto)
  (:documentation "Devuelve los argumentos que lee el programa: (nombre tipo valor ayuda opciones)."))

(defgeneric nombre-de-inicio (inicio)
  (:documentation "Devuelve el valor de --inicio que elige este inicio."))

(defgeneric maximo-de (estrategia)
  (:documentation "Devuelve el nombre del argumento que limita las iteraciones."))

(defun funcion-de (operador)
  "Devuelve el nombre en Python de la función de un operador: el de su clase."
  (nombre-python (class-name (class-of operador))))

(defun emitir-lineas (destino stream lineas)
  "Escribe LINEAS; una sublista va con un nivel más de sangría y un texto vacío deja una línea en blanco."
  (dolist (elemento lineas)
    (cond ((listp elemento)
           (con-sangria (destino) (emitir-lineas destino stream elemento)))
          ((string= elemento "") (terpri stream))
          (t (linea destino stream "~a" elemento)))))

(defmethod operadores-de ((estrategia estrategia))
  (append (estrategia-inicios estrategia) (list (estrategia-parada estrategia))))

(defmethod argumentos-de ((operador operador)) nil)

(defmethod argumentos-de ((estrategia estrategia))
  (append
   (list (list "semilla" "int" :obligatoria "Semilla del generador de números al azar.")
         (list "inicio" "str" (estrategia-inicio estrategia) "Cómo se arranca."
               (mapcar #'nombre-de-inicio (estrategia-inicios estrategia)))
         (list "penalizacion" "float" (estrategia-penalizacion estrategia)
               "Lo que cuesta cada unidad de las duras frente a las blandas."))
   (mapcan #'argumentos-de (operadores-de estrategia))))

(defun valor-python (valor)
  "Escribe el valor por defecto de un argumento."
  (cond ((eq valor :obligatoria) "required=True")
        ((null valor) "default=None")
        ((stringp valor) (format nil "default=~s" valor))
        (t (format nil "default=~a" valor))))

(defun emitir-argumentos (estrategia destino stream)
  "Define leer_argumentos, con un argumento por cada uno de ARGUMENTOS-DE."
  (linea destino stream "def leer_argumentos():")
  (con-sangria (destino)
    (linea destino stream "lector = argparse.ArgumentParser(description=~s)"
           (estrategia-descripcion estrategia))
    (loop for (nombre tipo valor ayuda opciones) in (argumentos-de estrategia)
          do (linea destino stream "lector.add_argument('--~a', type=~a, ~a~@[, choices=[~{~s~^, ~}]~], help=~s)"
                    nombre tipo (valor-python valor) opciones
                    (if (eq valor :obligatoria)
                        ayuda
                        (format nil "~a Por defecto: %(default)s." ayuda))))
    (linea destino stream "return lector.parse_args()"))
  (terpri stream))

(defun emitir-cabecera (estrategia destino stream)
  "Escribe la descripción, las importaciones y lo que se lee de modelo.py."
  (linea destino stream "\"\"\"~a Se ejecuta con: python ~a.py --semilla 0\"\"\""
         (estrategia-descripcion estrategia) (estrategia-nombre estrategia))
  (emitir-lineas destino stream
                 '("import argparse"
                   "import itertools"
                   "import json"
                   "import random"
                   "import time"
                   "from pathlib import Path"
                   ""
                   "import modelo"
                   ""
                   "FUNCIONES = {nombre: funcion for nombre, _, funcion in modelo.RESTRICCIONES}"
                   "TAMANOS = [len(dominio) for dominio in modelo.DOMINIOS_DE_DECISION]"
                   "OPCIONES = list(itertools.product(*(range(tamano) for tamano in TAMANOS)))"
                   "FILAS = len(modelo.IDENTIDADES)"
                   "")))

(defun emitir-comunes (destino stream)
  "Escribe el individuo, el evaluador con las constantes ya calculadas y las opciones permitidas."
  (emitir-lineas destino stream
                 '("class Individuo:"
                   ("creados = 0"
                    ""
                    "def __init__(self, posiciones):"
                    ("self.posiciones = posiciones"
                     "self.valor = None"
                     "Individuo.creados += 1"))
                   ""
                   "class Evaluador:"
                   ("def __init__(self, penalizacion):"
                    ("self.penalizacion = penalizacion"
                     "self.evaluaciones = 0"
                     "horario = modelo.crear_horario([OPCIONES[0]] * FILAS)"
                     "fijas = [(peso, funcion(horario)) for nombre, peso, funcion in modelo.RESTRICCIONES if nombre in modelo.CONSTANTES]"
                     "self.duras_fijas = sum(valor for peso, valor in fijas if peso is None)"
                     "self.blandas_fijas = sum(peso * valor for peso, valor in fijas if peso is not None)"
                     "variables = [(peso, funcion) for nombre, peso, funcion in modelo.RESTRICCIONES if nombre not in modelo.CONSTANTES]"
                     "self.duras = [funcion for peso, funcion in variables if peso is None]"
                     "self.blandas = [(peso, funcion) for peso, funcion in variables if peso is not None]")
                    ""
                    "def valor(self, individuo):"
                    ("if individuo.valor is None:"
                     ("self.evaluaciones += 1"
                      "horario = modelo.crear_horario(individuo.posiciones)"
                      "duras = self.duras_fijas + sum(funcion(horario) for funcion in self.duras)"
                      "blandas = self.blandas_fijas + sum(peso * funcion(horario) for peso, funcion in self.blandas)"
                      "individuo.valor = (self.penalizacion * duras + blandas, duras, blandas)")
                     "return individuo.valor")
                    ""
                    "def costo(self, individuo):"
                    ("return self.valor(individuo)[0]"))
                   ""
                   "def opciones_permitidas():"
                   ("de_una_fila = [FUNCIONES[nombre] for nombre in modelo.DE_UNA_FILA]"
                    "return [[opcion for opcion in OPCIONES"
                    ("if all(funcion([modelo.crear_fila(i, opcion)]) == 0 for funcion in de_una_fila)]"
                     "for i in range(FILAS)]"))
                   "")))

(defun emitir-tabla-de-inicios (estrategia destino stream)
  "Define INICIOS, que da la función de cada valor de --inicio."
  (linea destino stream "INICIOS = {~{~a~^, ~}}"
         (mapcar (lambda (inicio) (format nil "~s: ~a" (nombre-de-inicio inicio) (funcion-de inicio)))
                 (estrategia-inicios estrategia)))
  (terpri stream))

(defun emitir-principal (estrategia destino stream)
  "Define principal, que lee los argumentos, busca y guarda la corrida en corridas/."
  (linea destino stream "def principal():")
  (con-sangria (destino)
    (emitir-lineas destino stream
                   '("args = leer_argumentos()"
                     "azar = random.Random(args.semilla)"))
    (linea destino stream "parada = ~a(args.~a, args)"
           (clase-python (class-name (class-of (estrategia-parada estrategia))))
           (maximo-de estrategia))
    (emitir-lineas destino stream
                   '("evaluador = Evaluador(args.penalizacion)"
                     "permitidas = opciones_permitidas()"
                     "opciones = [de_la_fila or OPCIONES for de_la_fila in permitidas]"
                     "mejor, iteraciones, motivo = buscar(args, azar, evaluador, parada, opciones)"
                     "costo, duras, blandas = evaluador.valor(mejor)"
                     "resultado = {"))
    (con-sangria (destino)
      (linea destino stream "'estrategia': ~s," (estrategia-nombre estrategia))
      (emitir-lineas destino stream
                     '("'argumentos': vars(args),"
                       "'motivo_de_parada': motivo,"
                       "'iteraciones': iteraciones,"
                       "'individuos': Individuo.creados,"
                       "'evaluaciones': evaluador.evaluaciones,"
                       "'segundos': round(parada.segundos(), 2),"
                       "'sin_opciones_permitidas': [str(modelo.IDENTIDADES[i]) for i, de_la_fila in enumerate(permitidas) if not de_la_fila],"
                       "'costo': costo,"
                       "'duras': duras,"
                       "'blandas': blandas,"
                       "'posiciones': [list(posicion) for posicion in mejor.posiciones],"
                       "**modelo.a_json(modelo.crear_horario(mejor.posiciones)),")))
    (emitir-lineas destino stream
                   '("}"
                     "carpeta = Path(__file__).resolve().parent / 'corridas'"
                     "carpeta.mkdir(exist_ok=True)"
                     "marca = time.strftime('%Y%m%d-%H%M%S')"))
    (linea destino stream "ruta = carpeta / f'~a-semilla-{args.semilla}-{marca}.json'"
           (estrategia-nombre estrategia))
    (emitir-lineas destino stream
                   '("ruta.write_text(json.dumps(resultado, ensure_ascii=False, indent=2), encoding='utf-8')"
                     "print(f'duras {duras}, blandas {blandas}, {iteraciones} iteraciones, parada por {motivo}')"
                     "print(ruta)")))
  (terpri stream)
  (emitir-lineas destino stream
                 '("if __name__ == '__main__':"
                   ("principal()"))))

(defmethod emitir-estrategia ((estrategia estrategia) (destino python) stream)
  (emitir-cabecera estrategia destino stream)
  (emitir-comunes destino stream)
  (dolist (operador (operadores-de estrategia))
    (emitir-operador operador destino stream))
  (emitir-tabla-de-inicios estrategia destino stream)
  (emitir-busqueda estrategia destino stream)
  (emitir-argumentos estrategia destino stream)
  (emitir-principal estrategia destino stream))
