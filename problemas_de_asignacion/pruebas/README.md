# Pruebas

```bash
sbcl --script pruebas/correr.lisp               # todas, unos 30 s; código 1 si alguna falla
python pruebas/estrategias/rendimiento.py       # aparte, unos 40 min; usa lo que hay en salida/
```

## Qué comprueba cada archivo

| Archivo | Comprueba |
|---|---|
| `correr.lisp` | Carga el sistema y ejecuta todas las demás, en orden. |
| `dsl/utiles.lisp` | Ayudantes: cargar un dominio escrito como texto. |
| `dsl/migracion.lisp` | Que cada `dominios/<d>/dominio.lisp` es la copia congelada de `referencia/<d>/dominio.lisp` con solo los cambios anotados, y que carga sin avisos. |
| `emision/utiles.lisp` | Ayudantes: carpeta temporal, dominio de prueba, modelo de un dominio real, ejecutar Python. |
| `emision/completitud.lisp` | Que cada nodo, familia, forma de restricción y destino tiene su método, y que no hay métodos por defecto que tapen uno que falta. |
| `emision/referencia.lisp` + `comparar.py` | Que `modelo.py` de los cinco dominios da los mismos valores que el sistema viejo, salvo las diferencias de `referencia/diferencias-esperadas.md`. |
| `estrategias/utiles.lisp` | Ayudantes: generar los programas, correrlos y el dominio pequeño. |
| `estrategias/completitud.lisp` | Que cada operador y estrategia tiene sus métodos y que el README de `ejecuciones/` explica cada argumento. |
| `estrategias/comunes.lisp` | Lo común a las dos estrategias: semilla obligatoria, arranques, costo, caché de evaluaciones. |
| `estrategias/genetico.lisp` | El genético: reproducible, cada motivo de parada, sus operadores y los dominios reales. |
| `estrategias/busqueda-local.lisp` | La búsqueda local: reproducible, su paso, su parada y los dominios reales. |
| `estrategias/rendimiento.py` | Los criterios de la etapa 4 y lo que tardan las corridas, con proyecciones. No está en `correr.lisp`. |
| `orquestacion/utiles.lisp` | Ayudantes: escribir archivos, listar lo generado, conducir sin imprimir. |
| `orquestacion/pedido.lisp` | La línea de comandos, los archivos de `ejecuciones/` y sus errores, y que los de `ejecuciones/` son válidos. |
| `orquestacion/conducir.lisp` | Que se genera solo lo pedido, los avisos, que `corridas/` sobrevive, que dos dominios no se mezclan, que un dominio roto no para a los demás y que se ejecuta con sus semillas y parámetros. |

## Datos

| Archivo | Qué es |
|---|---|
| `referencia/<d>/dominio.lisp` | Copia congelada del dominio del sistema viejo. No se modifica. |
| `referencia/<d>/valores.json` | Diez horarios por dominio con el valor de cada restricción según el sistema viejo. |
| `referencia/diferencias-esperadas.md` | Las diferencias con el sistema viejo que se aceptan, y por qué. |
| `factibles/<d>.json` | Un horario sin duras de tv, tesis y SEDER, para comparar valores fuera del azar. |
