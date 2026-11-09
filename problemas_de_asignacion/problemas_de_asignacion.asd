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
     (:module "analisis"
      :serial t
      :components ((:file "recorrido")
                   (:file "modelo")
                   (:file "tipos")
                   (:file "atomos")
                   (:file "simetria")
                   (:file "familias")
                   (:file "normalizar")
                   (:file "orden")
                   (:file "construir")))
     (:module "emision"
      :serial t
      :components ((:file "destinos")
                   (:file "generar-codigo")
                   (:file "nombres")
                   (:module "python"
                    :serial t
                    :components ((:file "expresiones")
                                 (:file "datos")
                                 (:file "consultas")
                                 (:file "restricciones")
                                 (:file "resultado")))
                   (:module "matematica"
                    :serial t
                    :components ((:file "expresiones")
                                 (:file "modelo")))
                   (:module "verbalizador"
                    :serial t
                    :components ((:file "lexico")
                                 (:file "expresiones")
                                 (:file "familias")
                                 (:file "documento")))))
     (:module "estrategias"
      :serial t
      :components ((:file "estrategia")
                   (:file "operadores")
                   (:module "genetico"
                    :components ((:file "python")))
                   (:module "busqueda-local"
                    :components ((:file "python")))))
     (:module "orquestacion"
      :serial t
      :components ((:file "cargar")
                   (:file "elegir")
                   (:file "exportar")
                   (:file "pedido")
                   (:file "conducir")))))))
