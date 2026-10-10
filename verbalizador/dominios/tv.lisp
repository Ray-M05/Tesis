;; =====================================================================
;; DOMINIO: PROGRAMACIÓN DE PARRILLA TELEVISIVA
;; Canal Habana — parrilla semanal
;; =====================================================================

;; =====================================================================
;; MIXINS
;; =====================================================================

(defclass* tiene-nombre ()
  (nombre))


;; =====================================================================
;; ENTIDADES ENUMERADAS
;; =====================================================================

;; Tipo de programa
(def-entidad tipo-programa () (codigo))

;; Día de emisión (nombre del día para visualización)
(def-entidad dia (tiene-nombre))

;; Bloque: posición en la parrilla diaria (un canal tiene N bloques por día)
;; Cada bloque tiene un número de orden y pertenece a un día concreto.
;; Dos bloques son consecutivos si tienen el mismo día y órdenes contiguos.
(def-entidad bloque () (dia orden))


;; =====================================================================
;; ENTIDADES DEL DOMINIO
;; =====================================================================

;; Canal de televisión
(def-entidad canal (tiene-nombre))

;; Programa: tiene nombre, tipo, duración en minutos y canal al que pertenece
(def-entidad programa (tiene-nombre) (tipo duracion canal))


;; =====================================================================
;; ENTIDAD COMBINACIÓN: EMISIÓN
;; Una emisión = un bloque + qué programa ocupa ese bloque
;; =====================================================================

(def-comb emision (bloque programa))


;; =====================================================================
;; CONSULTAS Y RESTRICCIONES
;; =====================================================================

;; Dos emisiones son consecutivas si están en el mismo día y sus bloques
;; tienen órdenes contiguos (orden e2 = orden e1 + 1).
;; La restricción exige que dos emisiones consecutivas no sean del mismo tipo.

;; ── Restricción dura ───────────────────────────────────────────────

;; Se itera sobre (c canal) para que 'canal' quede registrado como dominio
;; en el Horario, necesario para que def-minimizar ... canal funcione.
(def-consulta adyacentes-mismo-tipo ()
  :itera-sobre (c canal) (e1 emision) (e2 emision)
  :comprueba
  (op-and (op-igual (canal (programa e1)) c)
          (op-igual (canal (programa e2)) c)
          (op-igual (dia   (bloque e1))   (dia   (bloque e2)))
          (op-igual (tipo  (programa e1)) (tipo  (programa e2)))
          (op-igual (op-suma (orden (bloque e1)) 1)
                    (orden   (bloque e2))))
  :operacion suma
  :devuelve 1)

(defvar restriccion-sin-mismo-tipo-consecutivo
  (def-nppq (op-mayor adyacentes-mismo-tipo 0)))


;; ── Restricción blanda ─────────────────────────────────────────────

;; Pares consecutivos del mismo tipo en la parrilla de un canal concreto
(def-consulta consecutivos-por-canal (c)
  :itera-sobre (e1 emision) (e2 emision)
  :comprueba
  (op-and (op-igual (canal (programa e1)) c)
          (op-igual (canal (programa e2)) c)
          (op-igual (dia   (bloque e1))   (dia   (bloque e2)))
          (op-igual (tipo  (programa e1)) (tipo  (programa e2)))
          (op-igual (op-suma (orden (bloque e1)) 1)
                    (orden   (bloque e2))))
  :operacion suma
  :devuelve 1)

;; Minimizar el número de pares consecutivos del mismo tipo por canal
(defvar restriccion-minimizar-repeticion-de-tipo
  (def-minimizar consecutivos-por-canal canal))


;; =====================================================================
;; DATOS CONCRETOS
;; Parrilla del lunes de Canal Habana (secuencia real de bloques)
;; =====================================================================

;; ── Tipos de programa ──────────────────────────────────────────────
(def-tipo-programa tipo-informativo "informativo")
(def-tipo-programa tipo-musical     "musical")
(def-tipo-programa tipo-infantil    "infantil")
(def-tipo-programa tipo-revista     "revista")
(def-tipo-programa tipo-cine        "cine")
(def-tipo-programa tipo-deportes    "deportes")

;; ── Días de la semana ──────────────────────────────────────────────
(def-dia lunes     "Lunes")
(def-dia martes    "Martes")
(def-dia miercoles "Miercoles")
(def-dia jueves    "Jueves")
(def-dia viernes   "Viernes")
(def-dia sabado    "Sabado")
(def-dia domingo   "Domingo")

;; ── Canal ──────────────────────────────────────────────────────────
(def-canal canal-habana "Canal Habana")

;; ── Programas (nombre tipo duracion-en-minutos canal) ──────────────
(def-programa prog-el-tiempo         "El Tiempo y la Memoria" tipo-informativo   5 canal-habana)
(def-programa prog-coordenadas       "Coordenadas"            tipo-informativo   5 canal-habana)
(def-programa prog-hola-habana       "Revista Hola Habana"    tipo-revista      50 canal-habana)
(def-programa prog-decadas           "Decadas Milagrosas"     tipo-musical      30 canal-habana)
(def-programa prog-habana-noticiario "Habana Noticiario"      tipo-informativo  30 canal-habana)
(def-programa prog-power-rangers     "Power Rangers"          tipo-infantil     30 canal-habana)
(def-programa prog-cine-plus         "Cine+"                  tipo-cine         90 canal-habana)
(def-programa prog-deporte-total     "Deporte Total"          tipo-deportes     30 canal-habana)

;; ── Bloques de la parrilla ─────────────────────────────────────────
;; Cada bloque es una posición en la parrilla de un día concreto.
;; El número de bloques por día debe coincidir con el número de programas
;; que se emiten en ese día. Aquí se define la parrilla del lunes como ejemplo
;; completo; los demás días usan la misma secuencia de bloques.

(def-bloque bloque-lunes-1 lunes 1)
(def-bloque bloque-lunes-2 lunes 2)
(def-bloque bloque-lunes-3 lunes 3)
(def-bloque bloque-lunes-4 lunes 4)
(def-bloque bloque-lunes-5 lunes 5)
(def-bloque bloque-lunes-6 lunes 6)
(def-bloque bloque-lunes-7 lunes 7)
(def-bloque bloque-lunes-8 lunes 8)

(def-bloque bloque-martes-1 martes 1)
(def-bloque bloque-martes-2 martes 2)
(def-bloque bloque-martes-3 martes 3)
(def-bloque bloque-martes-4 martes 4)
(def-bloque bloque-martes-5 martes 5)
(def-bloque bloque-martes-6 martes 6)
(def-bloque bloque-martes-7 martes 7)
(def-bloque bloque-martes-8 martes 8)

(def-bloque bloque-miercoles-1 miercoles 1)
(def-bloque bloque-miercoles-2 miercoles 2)
(def-bloque bloque-miercoles-3 miercoles 3)
(def-bloque bloque-miercoles-4 miercoles 4)
(def-bloque bloque-miercoles-5 miercoles 5)
(def-bloque bloque-miercoles-6 miercoles 6)
(def-bloque bloque-miercoles-7 miercoles 7)
(def-bloque bloque-miercoles-8 miercoles 8)

(def-bloque bloque-jueves-1 jueves 1)
(def-bloque bloque-jueves-2 jueves 2)
(def-bloque bloque-jueves-3 jueves 3)
(def-bloque bloque-jueves-4 jueves 4)
(def-bloque bloque-jueves-5 jueves 5)
(def-bloque bloque-jueves-6 jueves 6)
(def-bloque bloque-jueves-7 jueves 7)
(def-bloque bloque-jueves-8 jueves 8)

(def-bloque bloque-viernes-1 viernes 1)
(def-bloque bloque-viernes-2 viernes 2)
(def-bloque bloque-viernes-3 viernes 3)
(def-bloque bloque-viernes-4 viernes 4)
(def-bloque bloque-viernes-5 viernes 5)
(def-bloque bloque-viernes-6 viernes 6)
(def-bloque bloque-viernes-7 viernes 7)
(def-bloque bloque-viernes-8 viernes 8)

(def-bloque bloque-sabado-1 sabado 1)
(def-bloque bloque-sabado-2 sabado 2)
(def-bloque bloque-sabado-3 sabado 3)
(def-bloque bloque-sabado-4 sabado 4)
(def-bloque bloque-sabado-5 sabado 5)
(def-bloque bloque-sabado-6 sabado 6)
(def-bloque bloque-sabado-7 sabado 7)
(def-bloque bloque-sabado-8 sabado 8)

(def-bloque bloque-domingo-1 domingo 1)
(def-bloque bloque-domingo-2 domingo 2)
(def-bloque bloque-domingo-3 domingo 3)
(def-bloque bloque-domingo-4 domingo 4)
(def-bloque bloque-domingo-5 domingo 5)
(def-bloque bloque-domingo-6 domingo 6)
(def-bloque bloque-domingo-7 domingo 7)
(def-bloque bloque-domingo-8 domingo 8)


;; =====================================================================
;; DEFINICIÓN DEL PROBLEMA
;; =====================================================================
;; Este archivo solo DECLARA. No carga infraestructura, no genera codigo
;; y no imprime nada. El orden de carga y los efectos viven en run.lisp.
;; =====================================================================

(defvar problema-tv
  (def-problema-horario
    ;; Entidad combinación: lo que constituye una fila de la parrilla
    :entidad-horario   'emision
    ;; Slot identidad: hay una emisión POR bloque
    :slot-identidad    'bloque
    ;; Slots variables: el GA asigna un programa a cada bloque
    :slots-variables   '(programa)
    ;; Consultas registradas en el AST
    :consultas         '(adyacentes-mismo-tipo consecutivos-por-canal)
    ;; Restricciones duras
    :restricciones-duras   '(restriccion-sin-mismo-tipo-consecutivo)
    ;; Restricciones blandas
    :restricciones-blandas '(restriccion-minimizar-repeticion-de-tipo)
    :peso-dura   1000
    :peso-blanda    1))
