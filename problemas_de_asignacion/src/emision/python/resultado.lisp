(in-package :emision)

(defun emitir-cabecera (destino stream)
  "Escribe las importaciones y la cuenta de parejas de una celda."
  (linea destino stream "from collections import Counter")
  (linea destino stream "from dataclasses import dataclass")
  (terpri stream)
  (linea destino stream "def _parejas(valores):")
  (con-sangria (destino)
    (linea destino stream "k = len(valores)")
    (linea destino stream "iguales = sum(c * (c - 1) for c in Counter(valores).values())")
    (linea destino stream "return (k * (k - 1) - iguales) // 2"))
  (terpri stream))

(defun componentes-python (destino)
  "Devuelve los nombres en Python de los componentes de una fila."
  (let ((problema (modelo-problema (destino-modelo destino))))
    (mapcar #'nombre-python
            (slots-de-entidad (problema-combinacion problema) (destino-modelo destino)))))

(defun emitir-mostrar-resultado (destino stream)
  "Define mostrar_resultado: cada fila con el nombre de la combinación y el valor de cada restricción."
  (linea destino stream "def mostrar_resultado(horario):")
  (con-sangria (destino)
    (linea destino stream "for n, fila in enumerate(horario, 1):")
    (con-sangria (destino)
      (linea destino stream "print(f'~a {n}:')"
             (clase-python (problema-combinacion (modelo-problema (destino-modelo destino)))))
      (dolist (componente (componentes-python destino))
        (linea destino stream "print(f'  ~a: {fila.~a}')" componente componente)))
    (linea destino stream "for nombre, valor in evaluar(horario).items():")
    (con-sangria (destino)
      (linea destino stream "print(f'{nombre}: {valor}')")))
  (terpri stream))

(defun emitir-a-json (destino stream)
  "Define a_json: cada componente se guarda por su etiqueta, sin casos especiales."
  (linea destino stream "def a_json(horario):")
  (con-sangria (destino)
    (linea destino stream "filas = [{~{~a~^, ~}} for fila in horario]"
           (mapcar (lambda (componente) (format nil "'~a': str(fila.~a)" componente componente))
                   (componentes-python destino)))
    (linea destino stream "return {'horario': filas, 'valores': evaluar(horario)}"))
  (terpri stream))

(defmethod archivo-de ((destino python)) "modelo.py")

(defmethod emitir ((destino python) stream)
  (let ((modelo (destino-modelo destino)))
    (exigir-nombres-distintos modelo)
    (emitir-cabecera destino stream)
    (emitir-datos destino stream)
    (dolist (consulta (modelo-consultas modelo))
      (emitir-consulta consulta destino stream))
    (dolist (restriccion (modelo-restricciones modelo))
      (emitir-restriccion restriccion destino stream))
    (emitir-evaluar destino stream)
    (emitir-mostrar-resultado destino stream)
    (emitir-a-json destino stream)))
