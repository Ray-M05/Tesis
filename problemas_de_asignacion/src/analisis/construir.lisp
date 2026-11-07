(in-package :analisis)

(defun dominios-usados (problema consultas restricciones)
  "Devuelve los componentes de la combinación y lo que se recorre, sin la combinación misma."
  (let ((combinacion (problema-combinacion problema)))
    (remove combinacion
            (remove-duplicates
             (append (cdr (assoc combinacion (problema-slots problema)))
                     (mapcar #'second (mapcan (lambda (consulta)
                                                (copy-list (consulta-iteradores consulta)))
                                              consultas))
                     (mapcar #'second (mapcan (lambda (restriccion)
                                                (copy-list (restriccion-variables restriccion)))
                                              restricciones)))
             :from-end t))))

(defun variables-usadas (nodo)
  "Devuelve las variables que aparecen en NODO. De una consulta aplicada solo cuentan sus argumentos."
  (cond ((symbolp nodo) (and nodo (list nodo)))
        ((typep nodo 'aplicacion-de-consulta) (copy-list (slot-value nodo 'argumentos)))
        (t (mapcan #'variables-usadas (hijos nodo)))))

(defun crear-aviso (motivo objeto control &rest argumentos)
  "Crea un aviso cuyo mensaje empieza por el nombre del objeto."
  (make-instance 'aviso
                 :motivo motivo
                 :objeto objeto
                 :mensaje (format nil "~a: ~?" objeto control argumentos)))

(defun avisos-de-variables (nombre nodo variables)
  "Avisa de cada una de VARIABLES que no aparece en NODO."
  (let ((usadas (variables-usadas nodo)))
    (loop for (variable) in variables
          unless (member variable usadas)
            collect (crear-aviso :variable-sin-usar nombre
                                 "la variable ~a no se usa" variable))))

(defun avisos-de-simetria (consulta problema)
  "Avisa de un choque simétrico sin :pares y de un :pares cuya condición depende del orden."
  (let* ((iteradores (consulta-iteradores consulta))
         (parejas (remove-if-not #'third iteradores))
         (filas (remove (problema-combinacion problema) iteradores
                        :key #'second :test-not #'eq))
         (nombre (consulta-nombre consulta))
         (condicion (consulta-condicion consulta)))
    (flet ((simetrica (dos)
             (simetrica-p condicion (first (first dos)) (first (second dos)))))
      (cond ((and parejas (not (simetrica parejas)))
             (list (crear-aviso :pares-con-orden nombre
                                "usa :pares, pero su condición depende del orden y puede perder casos")))
            ((and (null parejas) (= (length filas) 2) (simetrica filas))
             (list (crear-aviso :simetrica-sin-pares nombre
                                "su condición es simétrica y sin :pares cuenta dos veces cada caso")))))))

(defun avisos-de-consulta (consulta problema)
  "Reúne los avisos de una consulta."
  (append (avisos-de-simetria consulta problema)
          (avisos-de-variables (consulta-nombre consulta)
                               (consulta-nodo consulta)
                               (append (consulta-iteradores consulta)
                                       (consulta-parametros consulta)))))

(defun avisos-de-restriccion (restriccion)
  "Reúne los avisos de una restricción."
  (append (unless (restriccion-decisiones restriccion)
            (list (crear-aviso :restriccion-constante (restriccion-nombre restriccion)
                               "no depende de ninguna decisión: da lo mismo en todo horario")))
          (avisos-de-variables (restriccion-nombre restriccion)
                               (slot-value (restriccion-nodo restriccion) 'comprobacion)
                               (restriccion-variables restriccion))))

(defun construir-modelo (problema)
  "Convierte un problema en su modelo intermedio, sin modificarlo."
  (let* ((tipos (tipos-de-slots problema))
         (parametros (dominios-de-parametros problema)))
    (exigir-tipos problema tipos parametros)
    (let* ((consultas (loop for (nodo . de-la-consulta) in parametros
                            collect (clasificar-consulta nodo de-la-consulta problema)))
           (restricciones (mapcar (lambda (nodo)
                                    (normalizar-restriccion nodo consultas problema))
                                  (problema-restricciones problema)))
           (referencias (referencias problema tipos)))
      (make-instance 'modelo
                     :problema problema
                     :restricciones restricciones
                     :consultas consultas
                     :tipos tipos
                     :referencias referencias
                     :orden (orden-topologico referencias)
                     :dominios (dominios-usados problema consultas restricciones)
                     :avisos (append (mapcan (lambda (consulta)
                                               (avisos-de-consulta consulta problema))
                                             consultas)
                                     (mapcan #'avisos-de-restriccion restricciones))))))
