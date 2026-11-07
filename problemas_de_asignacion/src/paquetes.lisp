(defpackage :dsl
  (:use)
  (:export #:def-entidad #:def-comb #:def-mixin
           #:def-consulta #:def-condicion #:def-problema
           #:def-nppq #:def-tqpq #:def-ndpq #:def-sbqp #:def-minimizar #:def-maximizar
           #:suma #:contar-distintos
           #:op-y #:op-o #:op-no
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
           #:consulta-simple #:nombre #:parametros #:variable-iteracion #:dominio-iteracion
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

(defpackage :analisis
  (:use :cl :dsl :dsl-ast)
  (:export #:construir-modelo
           #:hijos #:recorrer #:nodos-de #:aplanar #:camino #:variables-usadas
           #:negado #:duenos-de-instancias
           #:modelo #:modelo-problema #:modelo-restricciones #:modelo-consultas #:modelo-tipos
           #:modelo-referencias #:modelo-orden #:modelo-dominios #:modelo-avisos
           #:aviso #:aviso-motivo #:aviso-objeto #:aviso-mensaje
           #:restriccion-m #:restriccion-nombre #:restriccion-nodo #:restriccion-peso
           #:restriccion-variables #:restriccion-decisiones #:restriccion-consultas
           #:restriccion-medida
           #:prohibicion #:minimax #:restriccion-generica
           #:cota #:cota-comparador #:cota-umbral #:cota-incumplimiento
           #:consulta-m #:consulta-nombre #:consulta-nodo #:consulta-parametros
           #:consulta-iteradores #:consulta-condicion #:consulta-operacion #:consulta-decisiones
           #:pareja #:pareja-celda #:pareja-clave #:pareja-enlaces #:pareja-distintos
           #:pareja-filtros #:pareja-papeles
           #:choque-por-parejas
           #:relacion-ordenada #:relacion-adyacentes #:relacion-no-adyacentes
           #:filtro-de-fila
           #:cruce-contra-tabla #:cruce-tabla #:cruce-dimensiones
           #:agrupacion #:agrupacion-dimensiones
           #:consulta-generica))

(defpackage :emision
  (:use :cl :dsl :dsl-ast :analisis)
  (:export #:destino #:destino-modelo #:python #:matematica #:verbalizador
           #:generar-codigo #:simbolo #:emitir-consulta #:emitir-restriccion #:emitir
           #:nombre-python #:clase-python #:constante-python #:slots-de-etiqueta))

(defpackage :orquestacion
  (:use :cl :dsl-ast)
  (:import-from :emision #:emitir #:python #:matematica #:verbalizador)
  (:export #:cargar-dominio #:cargar-flujo #:cargar-anotaciones #:exportar))
