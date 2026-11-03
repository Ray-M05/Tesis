# problemas_de_asignacion

Reimplementación por capas del DSL de problemas de asignación con restricciones y de su generador de código. Sustituye a `restrictions_language-main/` y a `verbalizador/`, que siguen en local como referencia de solo lectura y no se modifican.

- **Qué se corrige:** [`deficiencias-por-capa.md`](../deficiencias-por-capa.md)
- **Cómo y en qué orden:** [`plan-reimplementacion.md`](../plan-reimplementacion.md)

## Capas

| Capa | Carpeta | Qué hace | Estado |
|---|---|---|---|
| 1. DSL | `src/dsl/` | el lenguaje que escribe el usuario | pendiente |
| 2. Análisis | `src/analisis/` | el modelo intermedio que leen todos los backends | pendiente |
| 3. Emisión | `src/emision/` | un destino por lenguaje: Python, notación matemática, español | pendiente |
| 4. Estrategias | `src/estrategias/` | cómo se busca la solución | pendiente |
| 5. Orquestación | `src/orquestacion/` | qué se genera, en qué orden y dónde | pendiente |

Las carpetas se crean en la etapa que las llena.

## Etapa 0: la referencia

`pruebas/referencia/<dominio>/` guarda lo que produce el sistema viejo, para comprobar que la versión nueva dice lo mismo:

| Archivo | Qué es | Dominios |
|---|---|---|
| `dominio.lisp` | la fuente que produjo la referencia | los cinco |
| `horario.py` | el Python generado | los cinco |
| `descripcion.md` | la prosa del verbalizador | los cinco |
| `modelo.txt` | lo que imprime `mostrar_modelo()` | tesis, tv, SEDER |
| `valores.json` | diez horarios con semilla fija, como índices, y el valor de cada restricción | tesis, tv, SEDER |

`pruebas/factibles/<dominio>.json` guarda un horario sin incumplimientos duros por dominio: tesis, tv y SEDER.

Docentes y Saúl no se ejecutan (decisión D0.6): de ellos solo se copian los artefactos.

Lo que la reimplementación cambia a propósito está en [`pruebas/referencia/diferencias-esperadas.md`](pruebas/referencia/diferencias-esperadas.md). Cualquier otra diferencia es un error.

### Regenerar la referencia

```bash
cd pruebas/referencia && python capturar.py tesis tv seder
cd pruebas/factibles && python buscar.py tesis tv seder
```

`capturar.py` tarda unos segundos. `buscar.py` tarda minuto y medio, sobre todo por tesis.

## Decisiones tomadas

| ID | Decisión |
|---|---|
| D0.1 | La carpeta se llama `problemas_de_asignacion/`. |
| D0.2 | `restrictions_language-main/` queda en local, sin versionar, y no se modifica. |
| D0.3 | Los documentos de la tesis se colocan a mano; el plan no los mueve. |
| D0.4 | Variables, funciones y carpetas en español. |
| D0.5 | Archivos en UTF-8 sin BOM. |
| D0.6 | Docentes y Saúl no se ejecutan para la referencia. |
