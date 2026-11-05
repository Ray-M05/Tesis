# Estructura del proyecto

Qué hace cada archivo y dónde está cada lógica. Las capas que todavía no existen no aparecen.

```
problemas_de_asignacion/
├── problemas_de_asignacion.asd      definición del sistema
├── README.md                        portada: cómo correr y cargar
├── estructura.md                    este archivo
├── decisiones-reimplementacion.md   decisiones tomadas y su motivo
├── plan-etapa-1.md                  plan de implementación del DSL
├── src/
│   ├── paquetes.lisp                los paquetes
│   ├── dsl/                         el lenguaje
│   └── orquestacion/cargar.lisp     carga de un dominio
├── dominios/<dominio>/dominio.lisp  tv, tesis, docentes, seder, saul
└── pruebas/
    ├── correr.lisp                  ejecuta todas las pruebas
    ├── dsl/                         pruebas del lenguaje
    ├── referencia/                  salidas del sistema viejo
    └── factibles/                   horarios sin incumplimientos duros
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
| Los mixins | `src/dsl/entidades.lisp` | `defclass*`, `slots-de-padres` |
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

## Sistema

| Archivo | Qué hace |
|---|---|
| `problemas_de_asignacion.asd` | Dice qué archivos forman el sistema, en qué orden se cargan y que están en UTF-8. |
| `src/paquetes.lisp` | Define `dsl`, con las 27 palabras que ve un dominio; `dsl-ast`, con la implementación y lo que leen las capas siguientes; y `orquestacion`, con el cargador. |

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

## Carga: `src/orquestacion/`

| Archivo | Qué hace |
|---|---|
| `cargar.lisp` | `cargar-flujo` crea el paquete `DOMINIO-<NOMBRE>`, carga el dominio con registros nuevos y devuelve su problema, o lo rechaza si no tiene. `cargar-dominio` hace lo mismo desde un archivo en UTF-8 y toma el nombre de la carpeta. |

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

| Archivo | Qué hace |
|---|---|
| `correr.lisp` | Compila el sistema y ejecuta las pruebas de `dsl/`. Una prueba que falla termina el proceso con código 1. |
| `dsl/utiles.lisp` | Dominio base de las pruebas, y los ayudantes `carga` y `rechaza`. `carga` falla ante cualquier aviso. |
| `dsl/validacion.lisp` | Prueba la lectura de claves y la comprobación de nombres. |
| `dsl/nodos.lisp` | Prueba los nodos, la jerarquía de dureza, el tamaño del vocabulario, y que no queden accesores de nodos ni nodos borrados. |
| `dsl/entidades.lisp` | Prueba entidades, instancias y cargador: `clase` carga, `consulta` se rechaza y dos dominios no se mezclan. |
| `dsl/consultas.lisp` | Prueba consultas, condiciones y aplicación, con sus rechazos. |
| `dsl/restricciones.lisp` | Prueba los cuantificadores, `:para` y `:peso`, con sus rechazos. |
| `dsl/problema.lisp` | Prueba `def-problema`, el orden escrito y la foto, con sus rechazos. |
| `dsl/migracion.lisp` | Lee cada dominio viejo sin evaluarlo, calcula cómo debería quedar y exige que el nuevo sea igual, forma por forma. También compara las instancias cargadas y comprueba que `jornada` era todo profesor × día con tope 5. |
| `dsl/archivo/dominio.lisp` | Dominio mínimo para probar la carga desde un archivo en UTF-8. |
| `referencia/<dominio>/` | Lo que produjo el sistema viejo: `dominio.lisp`, `horario.py`, `descripcion.md` y, en tesis, tv y SEDER, `modelo.txt` y `valores.json`. |
| `referencia/sistema_viejo.py` | Abre un `horario.py` viejo sin ejecutar el genético, y evalúa sus restricciones sobre un horario. |
| `referencia/capturar.py` | Escribe `modelo.txt` y `valores.json` de cada dominio. |
| `referencia/diferencias-esperadas.md` | Lo que la reimplementación cambia a propósito. Cualquier otra diferencia es un error. |
| `factibles/buscar.py` | Búsqueda local que encuentra un horario sin incumplimientos duros. |
| `factibles/<dominio>.json` | Un horario factible de tesis, tv y SEDER, guardado como posiciones. |

## Documentos

| Archivo | Qué hace |
|---|---|
| `README.md` | Portada: mapa de capas, cómo correr las pruebas y cómo cargar un dominio. |
| `decisiones-reimplementacion.md` | Cada decisión tomada, con su motivo, y lo pendiente a implementar. |
| `plan-etapa-1.md` | Cómo se construyó el DSL, fase por fase, con la tabla de rechazos y los cambios por dominio. |
| `../plan-reimplementacion.md` | El plan general de las cinco capas. |
| `../deficiencias-por-capa.md` | El inventario de lo que se quiere corregir. |
| `../BASE-CONOCIMIENTO-tesis.md` | La base de conocimiento de la tesis. |
