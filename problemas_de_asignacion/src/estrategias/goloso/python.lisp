(in-package :estrategias)

(defclass goloso (estrategia-constructiva)
  ((nombre      :initform "goloso")
   (descripcion :initform "Estrategia golosa de una pasada sobre modelo.py.")))

;; Cada fila, en el orden del operador de orden, va a la celda de menor daño, y entre las
;; empatadas elige el desempate. Una fila es forzada si su celda añadía duras.
(defmethod emitir-busqueda ((estrategia goloso) (destino python) stream)
  (let ((criterio (funcion-de (estrategia-criterio estrategia))))
    (emitir-lineas
     destino stream
     `("def buscar(args, azar, opciones):"
       (,(format nil "dano = ~a()" (clase-de (estrategia-dano estrategia)))
        ,(format nil "desempate = ~a(opciones)" (clase-de (estrategia-desempate estrategia)))
        "posiciones, forzadas = [None] * FILAS, []"
        ,(format nil "for i in ~a(azar, opciones):" (funcion-de (estrategia-orden estrategia)))
        ("filas = {opcion: modelo.crear_fila(i, opcion) for opcion in opciones[i]}"
         "danos = {opcion: dano.dano(fila) for opcion, fila in filas.items()}"
         ,(format nil "menor = min(~a(*valor) for valor in danos.values())" criterio)
         ,(format nil "empatadas = [opcion for opcion in opciones[i] if ~a(*danos[opcion]) == menor]" criterio)
         "posiciones[i] = desempate.elegir(azar, i, empatadas)"
         "dano.poner(filas[posiciones[i]])"
         "desempate.quitar(i)"
         "if danos[posiciones[i]][0] > 0:"
         ("forzadas.append(i)"))
        "return posiciones, forzadas"))))
  (terpri stream))
