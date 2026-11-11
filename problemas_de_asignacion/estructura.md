# Estructura del proyecto

Qué hace cada archivo y dónde está cada lógica.

```
problemas_de_asignacion/
├── problemas_de_asignacion.asd      definición del sistema
├── README.md                        portada: cómo correr y cargar
├── estructura.md                    este archivo
├── generar.lisp                     única entrada: genera y, si se pide, ejecuta
├── ejecuciones/README.md            cómo se pide una ejecución y qué es cada argumento
├── ejecuciones/<nombre>.lisp        pedidos guardados para repetirlos
├── decisiones-reimplementacion.md   decisiones tomadas y su motivo
├── src/
│   ├── paquetes.lisp                los paquetes
│   ├── dsl/                         el lenguaje
│   ├── analisis/                    el modelo intermedio
│   ├── emision/                     Python, LaTeX y Verbalizador
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
| `busqueda-local/python.lisp` | La clase `busqueda-local`, su operador `mejor-opcion-de-fila` y su bucle. |

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
