# Estructura del proyecto

Qué hace cada archivo y dónde está cada lógica. Las capas que todavía no existen no aparecen.

```
problemas_de_asignacion/
├── problemas_de_asignacion.asd      definición del sistema
├── README.md                        portada: cómo correr y cargar
├── estructura.md                    este archivo
├── generar.lisp                     única entrada: genera y, si se pide, ejecuta
├── ejecuciones/README.md            cómo se pide una ejecución y qué es cada argumento
├── ejecuciones/<nombre>.lisp        pedidos guardados para repetirlos; hoy, seder.lisp
├── decisiones-reimplementacion.md   decisiones tomadas y su motivo
├── plan-etapa-2.md                  plan de implementación del análisis
├── plan-etapa-3.md                  plan de implementación de la emisión
├── plan-etapa-4.md                  plan de implementación de las estrategias
├── plan-etapa-5.md                  plan de implementación de la orquestación
├── src/
│   ├── paquetes.lisp                los paquetes
│   ├── dsl/                         el lenguaje
│   ├── analisis/                    el modelo intermedio
│   ├── emision/                     Python, LaTeX y prosa
│   ├── estrategias/                 los programas que buscan un horario
│   └── orquestacion/                el pedido, la carga, la escritura y la ejecución
├── dominios/<dominio>/dominio.lisp  tv, tesis, docentes, seder, saul
├── dominios/saul/verbalizador.lisp  predicados de Saúl
├── pruebas/
│   ├── README.md                    qué comprueba cada archivo
│   ├── correr.lisp                  ejecuta todas las pruebas
│   ├── dsl/                         la migración de los dominios
│   ├── emision/                     completitud y comparación con el sistema viejo
│   ├── estrategias/                 pruebas de las estrategias y rendimiento.py
│   ├── orquestacion/                pruebas del pedido y de conducir
│   ├── referencia/                  dominios y valores del sistema viejo
│   └── factibles/                   horarios sin incumplimientos duros
└── salida/<dominio>/                avisos.txt; python/ con modelo.py, genetico.py,
                                     busqueda_local.py y corridas/; matematica/modelo.tex;
                                     verbalizador/descripcion.md
```

## Dónde está cada lógica

| Si buscas… | Está en | Función o macro |
|---|---|---|
| El vocabulario que ve un dominio | `src/paquetes.lisp` | paquete `dsl` |
| Lo que leen las capas siguientes | `src/paquetes.lisp` | paquete `dsl-ast` |
| El tipo de error del lenguaje | `src/dsl/validacion.lisp` | `error-dsl`, `rechazar` |
| Qué nombres puede usar un dominio | `src/dsl/validacion.lisp` | `exigir-nombre-propio`, `exigir-nombre-nuevo` |
| Que una variable no se repita | `src/dsl/validacion.lisp` | `exigir-variables` |
| Cómo se leen las claves `:x v v` | `src/dsl/validacion.lisp` | `repartir-claves`, `valor-unico` |
| Cómo se definen las clases de nodos | `src/dsl/macros-clase.lisp` | `def-clase`, `def-nodos`, `def-jerarquias`, `def-subclases` |
| Qué nodos existen | `src/dsl/nodos.lisp` | las clases del AST |
| De dónde sale la dureza | `src/dsl/nodos.lisp` | `restriccion-dura`, `restriccion-blanda`, `objetivo` |
| Los registros de un dominio | `src/dsl/entidades.lisp` | `*slots-de-entidad*`, `*instancias-de-entidad*` y demás |
| Que un dominio no vea los registros de otro | `src/dsl/entidades.lisp` | `con-registros-nuevos` |
| Que un dominio de iteración exista | `src/dsl/entidades.lisp` | `exigir-dominio`, `exigir-iteradores` |
| Los mixins | `src/dsl/entidades.lisp` | `def-mixin`, `slots-de-padres` |
| Definir una entidad o una combinación | `src/dsl/entidades.lisp` | `def-entidad`, `def-comb`, `formas-de-entidad` |
| Las funciones de acceso, como `(dia u)` | `src/dsl/entidades.lisp` | `formas-de-accesores` |
| Crear una instancia, su aridad y su nombre | `src/dsl/entidades.lisp` | `expandir-instancia` |
| Definir y validar una consulta | `src/dsl/consultas.lisp` | `def-consulta`, `expandir-consulta` |
| Validar `:pares` | `src/dsl/consultas.lisp` | `exigir-pares` |
| Validar `:operacion` | `src/dsl/consultas.lisp` | `exigir-operacion` |
| Ligar cada variable a su símbolo | `src/dsl/consultas.lisp` | `ligar-variables` |
| Usar una consulta, sus argumentos y que no esté dentro de otra | `src/dsl/consultas.lisp` | `aplicar-consulta` |
| Las condiciones reutilizables | `src/dsl/consultas.lisp` | `def-condicion` |
| Los seis cuantificadores | `src/dsl/restricciones.lisp` | `def-nppq`, `def-tqpq`, `def-ndpq`, `def-sbqp`, `def-minimizar`, `def-maximizar` |
| `:para` y la definición de una restricción | `src/dsl/restricciones.lisp` | `expandir-restriccion` |
| `:peso` | `src/dsl/restricciones.lisp` | `valor-de-peso` |
| Que un objetivo exija `:para` | `src/dsl/restricciones.lisp` | método `initialize-instance` sobre `objetivo` |
| Definir el problema | `src/dsl/problema.lisp` | `def-problema`, `construir-problema` |
| Que la combinación sea identidad más variables, sin dominios vacíos | `src/dsl/problema.lisp` | `exigir-combinacion` |
| Que cada restricción exista y no se repita | `src/dsl/problema.lisp` | `resolver-restricciones` |
| La foto de entidades, slots e instancias | `src/dsl/problema.lisp` | `foto-de`, clase `problema` |
| Cargar un dominio en su paquete | `src/orquestacion/cargar.lisp` | `cargar-dominio`, `cargar-flujo` |
| Convertir un problema en su modelo | `src/analisis/construir.lisp` | `construir-modelo` |
| Las clases del modelo | `src/analisis/modelo.lisp` | `modelo`, `aviso`, `restriccion-m`, `consulta-m` y sus subclases |
| Qué contiene cada nodo | `src/analisis/recorrido.lisp` | `hijos`, `recorrer` |
| Buscar nodos dentro de otro | `src/analisis/recorrido.lisp` | `nodos-de`, `aplanar` |
| Unir `:itera-sobre` y `:pares` | `src/analisis/tipos.lisp` | `iteradores-de` |
| A qué apunta un slot, y el rechazo de `nil` | `src/analisis/tipos.lisp` | `tipos-de-slots`, `tipo-de-valor` |
| El dominio de un parámetro | `src/analisis/tipos.lisp` | `dominios-de-parametros` |
| Las comparaciones sin sentido | `src/analisis/tipos.lisp` | `tipo-de` |
| Lógica en restricciones, número en objetivos | `src/analisis/tipos.lisp` | `tipo-exigido`, `exigir-tipos` |
| Si una ruta es decisión o dato | `src/analisis/atomos.lisp` | `decision-de`, `slot-de-decision` |
| Qué decisiones toca algo | `src/analisis/atomos.lisp` | `decisiones-de` |
| El papel de cada comparación de una pareja | `src/analisis/atomos.lisp` | `papel-de` |
| Si una condición es simétrica | `src/analisis/simetria.lisp` | `simetrica-p`, `canonica` |
| La celda y la clave de una pareja | `src/analisis/familias.lisp` | `datos-de-pareja` |
| A qué familia pertenece una consulta | `src/analisis/familias.lisp` | `clase-de-consulta`, `clasificar-consulta` |
| Cuándo se incumple una restricción | `src/analisis/normalizar.lisp` | `incumplimiento-de`, `negado`, `simplificar-incumplimiento` |
| Si es prohibición, cota, minimax o genérica | `src/analisis/normalizar.lisp` | `forma-de`, `normalizar-restriccion` |
| A qué entidades apunta cada una | `src/analisis/orden.lisp` | `referencias` |
| El orden de las entidades, y los ciclos | `src/analisis/orden.lisp` | `orden-topologico` |
| Los avisos | `src/analisis/construir.lisp` | `avisos-de-simetria`, `avisos-de-variables`, `avisos-de-restriccion` |
| Los dominios del modelo | `src/analisis/construir.lisp` | `dominios-usados` |
| Cargar las anotaciones de un dominio | `src/orquestacion/cargar.lisp` | `cargar-anotaciones` |
| Qué destinos y estrategias existen, y elegirlos por nombre | `src/orquestacion/elegir.lisp` | `clases-hoja`, `elegir` |
| Escribir cada destino en su carpeta, y los programas en la de python | `src/orquestacion/exportar.lisp` | `exportar`, `carpeta-de` |
| Leer la línea de comandos o un archivo de `ejecuciones/` | `src/orquestacion/pedido.lisp` | `pedido-de-argumentos`, `pedido-de-archivo` |
| Revisar nombres y parámetros antes de generar | `src/orquestacion/conducir.lisp` | `resolver`, `revisar-parametros` |
| Generar un dominio, guardar sus avisos y ejecutar sus corridas | `src/orquestacion/conducir.lisp` | `conducir`, `generar-dominio`, `escribir-avisos`, `ejecutar` |
| La entrada desde la terminal | `generar.lisp` | |
| Qué archivo escribe cada destino | junto al `emitir` de cada destino | `archivo-de` |
| Los destinos | `src/emision/destinos.lisp` | `python`, `matematica`, `verbalizador` |
| Las funciones que despachan por destino | `src/emision/generar-codigo.lisp` | `generar-codigo`, `simbolo`, `emitir-consulta`, `emitir-restriccion`, `emitir` |
| Lo que se suma cuando una cota se incumple con igualdad | `src/emision/generar-codigo.lisp` | `margen-de-incumplimiento` |
| Cuándo se incumple o se cumple un cuantificador | `src/emision/generar-codigo.lisp` | `condicion-incumplida`, `condicion-exigida` |
| Identificadores de Python y palabras reservadas | `src/emision/nombres.lisp` | `nombre-python`, `clase-python`, `constante-python` |
| Que dos nombres no choquen en Python | `src/emision/nombres.lisp` | `exigir-nombres-distintos` |
| Cómo se nombra una instancia | `src/emision/nombres.lisp` | `slots-de-etiqueta` |
| La sangría y los bucles de Python | `src/emision/python/expresiones.lisp` | `con-sangria`, `linea`, `emitir-bucles` |
| Comparar por identidad | `src/emision/python/datos.lisp` | `emitir-clase` |
| De posiciones a filas, y lo que las estrategias leen de la identidad y las decisiones | `src/emision/python/datos.lisp` | `emitir-crear-horario` |
| Qué restricciones son prohibiciones, de una fila o constantes | `src/emision/python/restricciones.lisp` | `prohibicion-dura-p`, `de-una-fila-p`, `emitir-grupos-de-restricciones` |
| Cuánto vale un choque y cuándo se agrupa | `src/emision/python/consultas.lisp` | `emitir-choque-agrupado`, `agrupable-p` |
| Cuánto vale cada restricción en Python | `src/emision/python/restricciones.lisp` | `emitir-restriccion` |
| `RESTRICCIONES` y `evaluar` | `src/emision/python/restricciones.lisp` | `emitir-evaluar` |
| Lo que imprime y exporta el resultado | `src/emision/python/resultado.lisp` | `emitir-mostrar-resultado`, `emitir-a-json` |
| Escribir LaTeX | `src/emision/matematica/expresiones.lisp` | `texto-latex`, `conjunto-latex` |
| La definición de una consulta en LaTeX | `src/emision/matematica/modelo.lisp` | `definicion`, `lineas-de-condicion` |
| Lo que exige y lo que cuesta una restricción en LaTeX | `src/emision/matematica/modelo.lisp` | `requisito`, `valor` |
| Género, número y ortografía | `src/emision/verbalizador/lexico.lisp` | `nombre-prosa`, `genero`, `sintagma` |
| Los predicados de un dominio | `src/emision/verbalizador/lexico.lisp` | `frase-de-predicado` |
| La traducción nodo a nodo a español | `src/emision/verbalizador/expresiones.lisp` | `generar-codigo`, `consulta->prosa`, `restriccion-literal` |
| Acortar «el plan de la sesión de u» a «su plan» | `src/emision/verbalizador/expresiones.lisp` | `acceso->prosa`, `acortable-p` |
| La frase de cada familia | `src/emision/verbalizador/familias.lisp` | `oracion`, `sustantivo` |
| La frase de cada restricción, o caer a lo literal | `src/emision/verbalizador/familias.lisp` | `idioma`, `restriccion->prosa` |
| Las secciones del documento | `src/emision/verbalizador/documento.lisp` | `emitir`, `entidad->prosa`, `datos->prosa`, `etiqueta` |
| Qué consultas no se listan en «Qué se mide» | `src/emision/verbalizador/documento.lisp` | `mecanicas` |
| Las funciones que despachan por estrategia y operador | `src/estrategias/estrategia.lisp` | `emitir-estrategia`, `emitir-operador`, `emitir-busqueda`, `operadores-de`, `argumentos-de` |
| El individuo, el costo con caché y las constantes calculadas una vez | `src/estrategias/estrategia.lisp` | `emitir-comunes` |
| Los argumentos de un programa y sus valores por defecto | `src/estrategias/estrategia.lisp` | `argumentos-de`, `emitir-argumentos` |
| El JSON de una corrida | `src/estrategias/estrategia.lisp` | `emitir-principal` |
| Los tres inicios, la selección, el cruce, las mutaciones y la parada | `src/estrategias/operadores.lisp` | un método de `emitir-operador` por clase |
| El bucle del genético y la elección de mutación | `src/estrategias/genetico/python.lisp` | `emitir-busqueda`, `emitir-mutar` |
| El paso de la búsqueda local y su bucle | `src/estrategias/busqueda-local/python.lisp` | `mejor-opcion-de-fila`, `emitir-busqueda` |
| Qué es cada argumento al ejecutar | `ejecuciones/README.md` | |
| Los criterios de la etapa 4 y el costo en minutos | `pruebas/estrategias/rendimiento.py` | `main` |

## Sistema

| Archivo | Qué hace |
|---|---|
| `problemas_de_asignacion.asd` | Dice qué archivos forman el sistema, en qué orden se cargan y que están en UTF-8. |
| `generar.lisp` | La única entrada. Carga el sistema, convierte sus argumentos en un pedido, llama a `conducir` y sale con código 1 si el pedido está mal escrito o algo falló. |
| `src/paquetes.lisp` | Define `dsl`, con las 27 palabras que ve un dominio; `dsl-ast`, con la implementación y lo que leen las capas siguientes; `analisis`, con el modelo; `emision`, con los destinos; `estrategias`, con los programas que buscan; y `orquestacion`, con el pedido, el cargador y la escritura. |

## Lenguaje: `src/dsl/`

| Archivo | Qué hace |
|---|---|
| `validacion.lisp` | Define `error-dsl` y las comprobaciones que comparten las demás piezas: nombres, variables y lectura de claves. |
| `macros-clase.lisp` | Define las macros que crean las clases del AST y sus constructores. No generan funciones de acceso. |
| `nodos.lisp` | Declara los nodos: acceso a un atributo, consulta, aplicación de una consulta, operaciones de consulta, cuantificadores y operaciones lógicas, relacionales y aritméticas. No tiene lógica. |
| `entidades.lisp` | Guarda los registros de la carga en curso y define mixins, entidades, combinaciones e instancias. Una entidad genera su clase, su variable, un accesor por slot y la macro `DEF-<ENTIDAD>`. |
| `consultas.lisp` | Valida y define las consultas y las condiciones. Una consulta crea su nodo una vez y define una función que, al llamarla, comprueba su uso y devuelve un nodo de aplicación. |
| `restricciones.lisp` | Define los seis cuantificadores sobre una sola función de expansión. Cada uno dice qué claves admite: las duras, `:para`; las blandas y los objetivos, `:para` y `:peso`. |
| `problema.lisp` | Define la clase `problema`, valida la combinación y las restricciones, y copia los registros en el orden escrito. |

## Análisis: `src/analisis/`

`construir-modelo` recibe un `problema` y devuelve un modelo inmutable, que leerán los destinos. No genera nada ni lee los registros globales.

| Archivo | Qué hace |
|---|---|
| `recorrido.lisp` | Define `hijos`, con un método por clase de nodo y ninguno sobre `t`, y lo que recorre el árbol sobre él. |
| `modelo.lisp` | Declara las clases, sin lógica. Las formas de una restricción son `prohibicion`, `cota`, `minimax` y `restriccion-generica`. Las familias de una consulta son `choque-por-parejas`, `relacion-ordenada`, `filtro-de-fila`, `cruce-contra-tabla`, `agrupacion` y `consulta-generica`. |
| `tipos.lisp` | Une los iteradores, deduce el tipo de cada slot y el dominio de cada parámetro, y calcula el tipo de cada expresión. Rechaza `nil`, los slots mezclados, los slots inexistentes y las comparaciones sin sentido. |
| `atomos.lisp` | Saca la ruta y la raíz de un acceso, decide si es decisión o dato, y da su papel a cada comparación de una pareja: celda, clave, distinto, adyacente, no adyacente, orden, filtro, enlace o papeles. |
| `simetria.lisp` | Convierte una condición en una forma comparable y dice si intercambiar las dos filas la cambia, después de aplicar sus propias igualdades. |
| `familias.lisp` | Reconoce la familia de una consulta por su estructura y crea su objeto. Lo que no encaja queda en `consulta-generica`. |
| `normalizar.lisp` | Pone la consulta a la izquierda, calcula cuándo se incumple la restricción y crea su objeto, enlazado con sus consultas. |
| `orden.lisp` | Calcula a qué entidades apunta cada una y las ordena. Un ciclo es un error. |
| `construir.lisp` | Une todo: tipos, consultas, restricciones, orden, dominios y los cuatro avisos. |

## Emisión: `src/emision/`

Traduce el modelo a cada lenguaje. Un destino es una clase, y nadie lee los registros globales.

| Archivo | Qué hace |
|---|---|
| `destinos.lisp` | Las clases `destino`, `infijo`, `python`, `matematica` y `verbalizador`, y la tabla que dice qué símbolo nombra a cada instancia. |
| `generar-codigo.lisp` | Las funciones genéricas, sin métodos sobre `t`, lo que Python y LaTeX comparten y el valor de `margen-de-incumplimiento`. `archivo-de` dice qué archivo escribe cada destino; su método va junto al `emitir` de cada uno. |
| `nombres.lisp` | Los identificadores de Python, las palabras reservadas, el rechazo de nombres que chocarían y la regla de la etiqueta. |

### `python/`: genera `modelo.py`

| Archivo | Qué hace |
|---|---|
| `expresiones.lisp` | Cómo se escribe cada nodo. También la sangría y los bucles, con `i < j` en los pares. |
| `datos.lisp` | Las clases con `eq=False` y `__str__`, una constante por instancia, las listas en orden declarado, `IDENTIDADES`, `DOMINIOS_DE_DECISION`, `crear_fila` y `crear_horario`. |
| `consultas.lisp` | El cuerpo con bucles de toda consulta y, en un choque, el recuento por celda cuando es exacto. |
| `restricciones.lisp` | Una emisión por forma, `RESTRICCIONES` y `evaluar`, que devuelve valores sin ponderar. También las listas de nombres que leen las estrategias: `PROHIBICIONES`, las duras con forma de prohibición; `DE_UNA_FILA`, las que se comprueban con una sola fila; y `CONSTANTES`, las que no dependen de ninguna decisión. |
| `resultado.lisp` | `_parejas`, `mostrar_resultado`, `a_json` y el archivo completo. |

### `matematica/`: genera `modelo.tex`

| Archivo | Qué hace |
|---|---|
| `expresiones.lisp` | Cómo se escribe cada nodo en LaTeX, y el escape de sus caracteres especiales. |
| `modelo.lisp` | Conjuntos, decisiones, objetivo y restricciones. Cada restricción con su requisito, su valor si es blanda y sus consultas. |

### `verbalizador/`: genera `descripcion.md`

| Archivo | Qué hace |
|---|---|
| `lexico.lisp` | Morfología y palabras del idioma, con claves de texto y sin nada de un dominio. |
| `expresiones.lisp` | La capa literal: traduce nodo a nodo. Sus variables de contexto solo se ligan aquí. |
| `familias.lisp` | La frase de cada familia y de cada restricción. Si no hay frase, se cae a la capa literal. |
| `documento.lisp` | Entidades, datos, qué se decide, qué se mide y restricciones. |

## Estrategias: `src/estrategias/`

Cada estrategia escribe un programa de Python que importa `modelo.py` y no sabe nada del dominio. Una estrategia y cada operador son objetos; cada uno escribe su parte con un método.

| Archivo | Qué hace |
|---|---|
| `estrategia.lisp` | La clase `estrategia`, con la penalización, los tres inicios y la parada; las funciones genéricas; y lo que toda estrategia escribe igual: el individuo, el evaluador, las opciones permitidas, los argumentos y el JSON de la corrida. |
| `operadores.lisp` | Las clases de operador y su Python: `inicio-voraz`, `inicio-permitido`, `inicio-aleatorio`, `torneo`, `cruce-un-punto`, `mover-filas`, `intercambio`, `parada-por-limite` y `parada-por-estancamiento`. Cada uno declara sus argumentos. |
| `genetico/python.lisp` | La clase `genetico`, con sus parámetros y operadores, la elección de mutación y el bucle con elitismo. |
| `busqueda-local/python.lisp` | La clase `busqueda-local`, su operador `mejor-opcion-de-fila` y su bucle. Está entera en este archivo: añadirla no cambió nada de los anteriores, y el `genetico.py` generado salió idéntico. |

## Orquestación: `src/orquestacion/`

Un pedido nombra dominios, destinos, estrategias con sus parámetros, semillas y si se ejecuta. Lo que no nombra va entero. El flujo es: `generar.lisp` → `pedido-de-argumentos` o `pedido-de-archivo` → `conducir` → `resolver` → por cada dominio, `generar-dominio`: cargar, avisos, `exportar` y, si se pide, `ejecutar`.

| Archivo | Qué hace |
|---|---|
| `cargar.lisp` | `cargar-flujo` crea el paquete `DOMINIO-<NOMBRE>`, carga el dominio con registros nuevos y devuelve su problema, o lo rechaza si no tiene. `cargar-dominio` hace lo mismo desde un archivo en UTF-8 y toma el nombre de la carpeta. `cargar-anotaciones` lee las del verbalizador. |
| `elegir.lisp` | `clases-hoja` saca las opciones de las clases que existen; `elegir` convierte nombres en clases, o devuelve todas, y rechaza un nombre que no existe con la lista de los que hay. No hay tablas escritas a mano. |
| `exportar.lisp` | `exportar` escribe cada destino pedido en `<carpeta>/<destino>/<archivo-de>` y los programas de las estrategias en `python/`, que se escribe siempre que haya estrategias. Los programas llevan los valores por defecto de sus clases. |
| `pedido.lisp` | Convierte la línea de comandos o un archivo de `ejecuciones/` en un pedido. El archivo se lee sin evaluar, en un paquete aparte, y tiene un solo dominio. `--archivo` no se mezcla con otras opciones. |
| `conducir.lisp` | `resolver` pasa los nombres a clases y revisa los parámetros contra `argumentos-de`. `conducir` recorre los dominios: carga, imprime los avisos y los escribe en `avisos.txt`, exporta y, si se pide, ejecuta cada estrategia con cada semilla, una tras otra, con la 0 si no hay ninguna. Un dominio o una corrida que falla se informa y se sigue; devuelve nil si algo falló. |

## Dominios: `dominios/`

Cada `dominio.lisp` es la única fuente de su problema y solo lo describe: entidades, combinación, consultas, restricciones, datos y `def-problema`. No carga nada ni genera nada.

| Dominio | Problema | Instancias | Restricciones |
|---|---|---|---|
| `tv/` | parrilla televisiva | 78 | 2 |
| `tesis/` | defensas de tesis | 81 | 3 |
| `docentes/` | horario docente universitario | 108 | 4 |
| `seder/` | educación física del SEDER | 76 | 6 |
| `saul/` | preuniversitario Saúl | 480 | 11 |

## Pruebas: `pruebas/`

Qué comprueba cada archivo está en [`pruebas/README.md`](pruebas/README.md). Al cerrar la etapa 5 se quitaron las pruebas de piezas sueltas y las herramientas de una sola vez; quedan la migración, la completitud, la comparación con el sistema viejo, las estrategias y la orquestación.

## Documentos

| Archivo | Qué hace |
|---|---|
| `README.md` | Portada: mapa de capas, cómo correr las pruebas y cómo cargar un dominio. |
| `decisiones-reimplementacion.md` | Cada decisión tomada, con su motivo, y lo pendiente a implementar. |
| `plan-etapa-2.md` | Cómo se construyó el análisis, fase por fase, con lo esperado de cada dominio y las tablas de rechazos y avisos. |
| `plan-etapa-3.md` | Cómo se construyó la emisión, fase por fase, y el destino de cada función del verbalizador. |
| `plan-etapa-4.md` | Cómo se construyeron las estrategias, con las mediciones. |
| `plan-etapa-5.md` | Cómo se construyó la orquestación y la limpieza de `pruebas/`. |
| `../plan-reimplementacion.md` | El plan general de las cinco capas. |
| `../deficiencias-por-capa.md` | El inventario de lo que se quiere corregir. |
| `../BASE-CONOCIMIENTO-tesis.md` | La base de conocimiento de la tesis. |
