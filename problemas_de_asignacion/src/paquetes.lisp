(defpackage :dsl
  (:use)
  (:export #:def-entidad #:def-comb #:defclass*
           #:def-consulta #:def-condicion #:def-problema
           #:def-nppq #:def-tqpq #:def-ndpq #:def-sbqp #:def-minimizar #:def-maximizar
           #:suma #:contar-distintos
           #:op-and #:op-or #:op-not
           #:op-igual #:op-distinto #:op-mayor #:op-menor #:op-mayor-igual #:op-menor-igual
           #:op-suma #:op-resta #:op-multiplicacion #:op-division))

(defpackage :dsl-ast
  (:use :cl :dsl)
  (:export #:error-dsl #:rechazar
           #:con-registros-nuevos #:*problema-cargado*
           #:problema #:problema-nombre #:problema-combinacion #:problema-identidad
           #:problema-variables #:problema-restricciones #:problema-entidades
           #:problema-slots #:problema-instancias
           #:nodo-ast #:ref-gen-entidad #:nombre-entidad #:ref-especifica-ent
           #:acceso-a-atributo-de-entidad #:atributo #:entidad
           #:consulta-simple #:nombre #:args #:variable-iteracion #:dominio-iteracion
           #:variables-pares #:dominio-pares #:comprobacion #:operacion
           #:aplicacion-de-consulta #:consulta #:argumentos
           #:operacion-de-consulta #:expresion
           #:cuantificador-restriccion #:para #:peso
           #:restriccion-dura #:restriccion-ponderada #:restriccion-blanda #:objetivo
           #:nppq #:tqpq #:ndpq #:sbqp #:minimizar #:maximizar
           #:operacion-binaria #:operando-izq #:operando-der
           #:operacion-unaria #:operando
           #:operacion-aritmetica #:comprobacion-aritmetica
           #:operacion-logica-binaria #:operacion-logica-unaria))

(defpackage :orquestacion
  (:use :cl :dsl-ast)
  (:export #:cargar-dominio #:cargar-flujo))
