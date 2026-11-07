(in-package :analisis)

(defclass modelo ()
  ((problema     :initarg :problema     :reader modelo-problema)
   (restricciones :initarg :restricciones :reader modelo-restricciones)
   (consultas    :initarg :consultas    :reader modelo-consultas)
   (tipos        :initarg :tipos        :reader modelo-tipos)
   (referencias  :initarg :referencias  :reader modelo-referencias)
   (orden        :initarg :orden        :reader modelo-orden)
   (dominios     :initarg :dominios     :reader modelo-dominios)
   (avisos       :initarg :avisos       :reader modelo-avisos)))

(defclass aviso ()
  ((motivo  :initarg :motivo  :reader aviso-motivo)
   (objeto  :initarg :objeto  :reader aviso-objeto)
   (mensaje :initarg :mensaje :reader aviso-mensaje)))

(defclass restriccion-m ()
  ((nombre     :initarg :nombre     :reader restriccion-nombre)
   (nodo       :initarg :nodo       :reader restriccion-nodo)
   (peso       :initarg :peso       :reader restriccion-peso)
   (variables  :initarg :variables  :reader restriccion-variables)
   (decisiones :initarg :decisiones :reader restriccion-decisiones)
   (consultas  :initarg :consultas  :reader restriccion-consultas)))

(defclass prohibicion (restriccion-m)
  ((medida :initarg :medida :reader restriccion-medida)))

(defclass cota (restriccion-m)
  ((medida         :initarg :medida         :reader restriccion-medida)
   (comparador     :initarg :comparador     :reader cota-comparador)
   (umbral         :initarg :umbral         :reader cota-umbral)
   (incumplimiento :initarg :incumplimiento :reader cota-incumplimiento)))

(defclass minimax (restriccion-m)
  ((medida :initarg :medida :reader restriccion-medida)))

(defclass restriccion-generica (restriccion-m) ())

(defclass consulta-m ()
  ((nombre     :initarg :nombre     :reader consulta-nombre)
   (nodo       :initarg :nodo       :reader consulta-nodo)
   (parametros :initarg :parametros :reader consulta-parametros)
   (iteradores :initarg :iteradores :reader consulta-iteradores)
   (condicion  :initarg :condicion  :reader consulta-condicion)
   (operacion  :initarg :operacion  :reader consulta-operacion)
   (decisiones :initarg :decisiones :reader consulta-decisiones)))

(defclass pareja (consulta-m)
  ((celda     :initarg :celda     :reader pareja-celda)
   (clave     :initarg :clave     :reader pareja-clave)
   (enlaces   :initarg :enlaces   :reader pareja-enlaces)
   (distintos :initarg :distintos :reader pareja-distintos)
   (filtros   :initarg :filtros   :reader pareja-filtros)
   (papeles   :initarg :papeles   :reader pareja-papeles)))

(defclass choque-por-parejas (pareja) ())

(defclass relacion-ordenada (pareja)
  ((adyacentes    :initarg :adyacentes    :reader relacion-adyacentes)
   (no-adyacentes :initarg :no-adyacentes :reader relacion-no-adyacentes)))

(defclass filtro-de-fila (consulta-m) ())

(defclass cruce-contra-tabla (consulta-m)
  ((tabla       :initarg :tabla       :reader cruce-tabla)
   (dimensiones :initarg :dimensiones :reader cruce-dimensiones)))

(defclass agrupacion (consulta-m)
  ((dimensiones :initarg :dimensiones :reader agrupacion-dimensiones)))

(defclass consulta-generica (consulta-m) ())
