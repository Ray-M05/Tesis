(defsystem "problemas_de_asignacion"
  :description "DSL de problemas de asignación con restricciones y su generador de código"
  :encoding :utf-8
  :serial t
  :components
  ((:module "src"
    :serial t
    :components
    ((:file "paquetes")
     (:module "dsl"
      :serial t
      :components ((:file "validacion")
                   (:file "macros-clase")
                   (:file "nodos")
                   (:file "entidades")
                   (:file "consultas")
                   (:file "restricciones")
                   (:file "problema")))
     (:module "orquestacion"
      :components ((:file "cargar")))))))
