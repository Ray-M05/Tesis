(in-package :dsl-ast)

(defclass problema ()
  ((nombre        :initarg :nombre        :reader problema-nombre)
   (combinacion   :initarg :combinacion   :reader problema-combinacion)
   (identidad     :initarg :identidad     :reader problema-identidad)
   (variables     :initarg :variables     :reader problema-variables)
   (restricciones :initarg :restricciones :reader problema-restricciones)
   (entidades     :initarg :entidades     :reader problema-entidades)
   (slots         :initarg :slots         :reader problema-slots)
   (instancias    :initarg :instancias    :reader problema-instancias)))

(defun foto-de (tabla)
  "Copia una tabla de registro como lista de asociación, en orden de declaración."
  (mapcar (lambda (entidad) (cons entidad (copy-list (gethash entidad tabla))))
          *entidades*))

(defun exigir-combinacion (combinacion identidad variables que)
  "Exige una combinación cuyos componentes sean exactamente la identidad más las variables."
  (unless (member combinacion *combinaciones*)
    (rechazar "~a: ~s no es una combinación" que combinacion))
  (let ((componentes (gethash combinacion *slots-de-entidad*))
        (declarados (cons identidad variables)))
    (unless (and (= (length componentes) (length declarados))
                 (null (set-exclusive-or componentes declarados)))
      (rechazar "~a: los componentes de ~a son ~s, no la identidad más las variables ~s"
                que combinacion componentes declarados))
    (dolist (componente declarados)
      (unless (gethash componente *instancias-de-entidad*)
        (rechazar "~a: la entidad ~a no tiene instancias" que componente)))))

(defun resolver-restricciones (nombres que)
  "Devuelve los nodos de las restricciones nombradas, en el orden escrito."
  (mapcar (lambda (nombre)
            (unless (and (symbolp nombre) (boundp nombre)
                         (typep (symbol-value nombre) 'cuantificador-restriccion))
              (rechazar "~a: la restricción ~s no existe" que nombre))
            (when (> (count nombre nombres) 1)
              (rechazar "~a: la restricción ~a está repetida" que nombre))
            (symbol-value nombre))
          nombres))

(defun construir-problema (nombre combinacion identidad variables restricciones)
  "Valida el problema, le toma la foto del dominio y lo deja como problema cargado."
  (let ((que (format nil "problema ~a" nombre)))
    (when *problema-cargado*
      (rechazar "~a: el dominio ya tiene el problema ~a"
                que (problema-nombre *problema-cargado*)))
    (exigir-combinacion combinacion identidad variables que)
    (setf *problema-cargado*
          (make-instance 'problema
                         :nombre nombre
                         :combinacion combinacion
                         :identidad identidad
                         :variables variables
                         :restricciones (resolver-restricciones restricciones que)
                         :entidades (copy-list *entidades*)
                         :slots (foto-de *slots-de-entidad*)
                         :instancias (foto-de *instancias-de-entidad*)))))

(defmacro def-problema (nombre &rest cuerpo)
  "Define el problema del dominio, sin comillas y con las cuatro claves obligatorias."
  (let* ((que (format nil "problema ~a" nombre))
         (claves (repartir-claves cuerpo
                                  '(:combinacion :identidad :variables :restricciones)
                                  que)))
    (exigir-nombre-nuevo nombre que)
    `(defvar ,nombre
       (construir-problema ',nombre
                           ',(valor-unico claves :combinacion que)
                           ',(valor-unico claves :identidad que)
                           ',(valor-unico claves :variables que)
                           ',(valor-unico claves :restricciones que)))))
