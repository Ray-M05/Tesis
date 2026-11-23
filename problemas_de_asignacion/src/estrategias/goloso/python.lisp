(in-package :estrategias)

(defclass goloso (estrategia-constructiva)
  ((nombre      :initform "goloso")
   (descripcion :initform "Estrategia golosa de una pasada sobre modelo.py.")))

(defmethod emitir-busqueda ((estrategia goloso) (destino python) stream)
  (emitir-pasada estrategia destino stream "buscar"))
