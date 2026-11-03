# -*- coding: utf-8 -*-
# Generado automaticamente desde el AST

import sys, copy, random
from dataclasses import dataclass, field
from typing import List

# Forzar UTF-8 para poder mostrar simbolos matematicos
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')


# ============================================================
# ENTIDADES DEL DOMINIO
# ============================================================

@dataclass(unsafe_hash=True)
class Tiene_Nombre:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Dia:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Turno:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Asignatura:
    nombre: object = None
    frecuencia: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Profesor:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Aula:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Grupo:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Sesion:
    asignatura: object = None
    grupo: object = None
    profesor: object = None
    def __str__(self): return f'(asignatura={self.asignatura}, grupo={self.grupo}, profesor={self.profesor})'

@dataclass
class Clase:
    sesion: object = None
    aula: object = None
    dia: object = None
    turno: object = None

@dataclass
class Horario:
    clase: List = field(default_factory=list)
    profesor: List = field(default_factory=list)



# ============================================================
# CONSULTAS
# ============================================================

def colisiones_de_profesor(horario):
    count = 0
    for p in horario.profesor:
        for c1 in horario.clase:
            for c2 in horario.clase:
                if ((c1.sesion.profesor == p) and (c2.sesion.profesor == p) and (c1.dia == c2.dia) and (c1.turno == c2.turno) and (c1.aula != c2.aula)):
                    count += 1
    return count

def colisiones_de_aula(horario):
    count = 0
    for c1 in horario.clase:
        for c2 in horario.clase:
            if ((c1.aula == c2.aula) and (c1.dia == c2.dia) and (c1.turno == c2.turno) and (c1.sesion.grupo != c2.sesion.grupo)):
                count += 1
    return count

def colisiones_de_grupo(horario):
    count = 0
    for c1 in horario.clase:
        for c2 in horario.clase:
            if ((c1.sesion.grupo == c2.sesion.grupo) and (c1.dia == c2.dia) and (c1.turno == c2.turno) and (c1.aula != c2.aula)):
                count += 1
    return count

def dias_de_profesor(horario, prof):
    dias = set()
    for c in horario.clase:
        if (c.sesion.profesor == prof):
            dias.add(getattr(c, 'fecha', None) or getattr(c, 'dia', None))
    return len(dias)

# ============================================================
# RESTRICCIONES SIMPLES / DURAS  (nppq / tqpq)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_un_aula_por_profesor(horario):
    return colisiones_de_profesor(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_un_grupo_por_aula(horario):
    return colisiones_de_aula(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_una_clase_por_grupo(horario):
    return colisiones_de_grupo(horario)

# ============================================================
# RESTRICCIONES DEBILES / BLANDAS  (ndpq / sbqp)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# OPTIMIZACIÓN — Minimizar
def restriccion_minimizar_dias_de_viaje(horario):
    valores = [dias_de_profesor(horario, x) for x in horario.profesor]
    return max(valores) if valores else 0

# ============================================================
# MODELO MATEMATICO
#   costo = PESO_DURA   * sum(violaciones duras)
#         + PESO_BLANDA * sum(violaciones blandas)
# ============================================================

PESO_DURA   = 1000
PESO_BLANDA = 1

def evaluar(horario):
    costo = 0
    # restricciones simples / duras
    costo += PESO_DURA   * restriccion_un_aula_por_profesor(horario)
    costo += PESO_DURA   * restriccion_un_grupo_por_aula(horario)
    costo += PESO_DURA   * restriccion_una_clase_por_grupo(horario)
    # restricciones debiles / blandas
    costo += PESO_BLANDA * restriccion_minimizar_dias_de_viaje(horario)
    return costo


def mostrar_modelo():
    """Imprime el modelo abstracto de optimizacion."""
    sep = '=' * 60
    print(sep)
    print('MODELO DE OPTIMIZACION')
    print(sep)
    print()
    print('INDICES Y CONJUNTOS:')
    print(f'  S  =  conjunto de sesions      (|S| = {len(SESIONS)})')
    print(f'  A  =  conjunto de aula disponibles   (|A| = {len(LISTA_AULA)})')
    print(f'  D  =  conjunto de dia disponibles   (|D| = {len(LISTA_DIA)})')
    print(f'  T  =  conjunto de turno disponibles   (|T| = {len(LISTA_TURNO)})')
    print(f'  P  =  conjunto de profesor   (|P| = {len(PROFESOR)})')
    print()
    print('VARIABLES DE DECISION:')
    print('  Para cada sesion t ∈ S se asigna:')
    print('    aula_t ∈ A   (aula)')
    print('    dia_t ∈ D   (dia)')
    print('    turno_t ∈ T   (turno)')
    print()
    print('FUNCION OBJETIVO:')
    print('  minimizar z(h) donde:')
    print('    z(h) = 1000 · Σ_i incumpl_i(h)   [duras]')
    print('         + 1 · Σ_j incumpl_j(h)   [blandas]')
    print()
    print('RESTRICCIONES DURAS  (nppq / tqpq):')
    print('  R1  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    colisiones_de_profesor(h) = 0')
    print('    donde:')
    print('      colisiones_de_profesor(h) = Σ_{p∈PROFESOR, c1∈CLASE, c2∈CLASE}  [((profesor(sesion(c1)) = p) ∧ (profesor(sesion(c2)) = p) ∧ (dia(c1) = dia(c2)) ∧ (turno(c1) = turno(c2)) ∧ (aula(c1) ≠ aula(c2)))]')
    print()
    print('  R2  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    colisiones_de_aula(h) = 0')
    print('    donde:')
    print('      colisiones_de_aula(h) = Σ_{c1∈CLASE, c2∈CLASE}  [((aula(c1) = aula(c2)) ∧ (dia(c1) = dia(c2)) ∧ (turno(c1) = turno(c2)) ∧ (grupo(sesion(c1)) ≠ grupo(sesion(c2))))]')
    print()
    print('  R3  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    colisiones_de_grupo(h) = 0')
    print('    donde:')
    print('      colisiones_de_grupo(h) = Σ_{c1∈CLASE, c2∈CLASE}  [((grupo(sesion(c1)) = grupo(sesion(c2))) ∧ (dia(c1) = dia(c2)) ∧ (turno(c1) = turno(c2)) ∧ (aula(c1) ≠ aula(c2)))]')
    print()
    print()
    print('RESTRICCIONES BLANDAS  (tdpq / sbqp / minimizar):')
    print('  R4  [OPTIMIZACIÓN — Minimizar]:')
    print('    minimizar  max_{{x ∈ PROFESOR}}  dias_de_profesor(h, x)')
    print('    donde:')
    print('      dias_de_profesor(h, prof) = |{ fecha(c) : c∈CLASE,  (profesor(sesion(c)) = prof) }|')
    print()
    print()
    print(sep)


def mostrar_resultado(horario):
    """Imprime el horario decidido y cuantas restricciones se incumplen."""
    sep = '=' * 60
    print(sep)
    print('HORARIO PROPUESTO POR LA METAHEURISTICA')
    print(sep)
    print()
    for i, asig in enumerate(horario.clase, 1):
        print(f'  Defensa {i}:')
        print(f'    SESION : {asig.sesion}')
        print(f'    AULA : {asig.aula}')
        print(f'    DIA : {asig.dia}')
        print(f'    TURNO : {asig.turno}')
        print()
    print(sep)
    print('EVALUACION DE RESTRICCIONES')
    print(sep)
    costo_total = 0
    print('Restricciones simples / duras  (peso 1000):')
    v = restriccion_un_aula_por_profesor(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_un_aula_por_profesor: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_un_grupo_por_aula(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_un_grupo_por_aula: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_una_clase_por_grupo(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_una_clase_por_grupo: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    print('Restricciones debiles / blandas  (peso 1):')
    v = restriccion_minimizar_dias_de_viaje(horario)
    costo_total += PESO_BLANDA * v
    print(f'  restriccion_minimizar_dias_de_viaje: {v}  ->  costo: {PESO_BLANDA * v}')
    print(f'Costo total: {costo_total}')
    print(sep)


def _ent_a_dict(x):
    """Convierte entidad a dict JSON-serializable."""
    if x is None: return None
    if isinstance(x, (str, int, float, bool)): return x
    if hasattr(x, 'nombre'): return str(x)
    if hasattr(x, 'id'): return str(x)
    return {campo: _ent_a_dict(getattr(x, campo)) for campo in vars(x)}


def exportar_json(solucion, costo_total, archivo="docentes/horario.json"):
    """Exporta el modelo matematico y el horario propuesto a JSON."""
    import json
    datos = {
        'modelo': {
            'conjuntos': {
                'S': len(SESIONS),
                'A': len(LISTA_AULA),
                'D': len(LISTA_DIA),
                'T': len(LISTA_TURNO),
                'P': len(PROFESOR),
            },
            'peso_dura': 1000,
            'peso_blanda': 1,
            'restricciones_duras': ['restriccion_un_aula_por_profesor', 'restriccion_un_grupo_por_aula', 'restriccion_una_clase_por_grupo'],
            'restricciones_blandas': ['restriccion_minimizar_dias_de_viaje'],
        },
        'horario': [_ent_a_dict(asig) for asig in solucion.clase],
        'costo_total': costo_total,
    }
    with open(archivo, 'w', encoding='utf-8') as f:
        json.dump(datos, f, ensure_ascii=False, indent=2)
    print(f'Horario exportado a: {archivo}')


# ============================================================
# ALGORITMO GENETICO
# ============================================================

POP_SIZE      = 100
GENERACIONES  = 500
PROB_CRUCE    = 0.8
PROB_MUTACION = 0.15
TORNEO_K      = 5

def crear_horario_aleatorio(sesions, lista_aula, lista_dia, lista_turno, profesor):
    """Crea un horario asignando recursos aleatorios a cada sesion."""
    h = Horario()
    h.profesor = list(profesor)
    for ident in sesions:
        h.clase.append(Clase(
            sesion=ident,
            aula=random.choice(lista_aula),
            dia=random.choice(lista_dia),
            turno=random.choice(lista_turno),
        ))
    return h

def crear_poblacion(sesions, lista_aula, lista_dia, lista_turno, profesor, tamanio=POP_SIZE):
    return [crear_horario_aleatorio(sesions, lista_aula, lista_dia, lista_turno, profesor) for _ in range(tamanio)]

def seleccion_torneo(poblacion, k=TORNEO_K):
    """Devuelve el mejor de k individuos elegidos al azar."""
    candidatos = random.sample(poblacion, min(k, len(poblacion)))
    return min(candidatos, key=evaluar)

def cruce(p1, p2):
    """Cruce de un punto: intercambia recursos (aula, dia, turno) tras el corte."""
    n = len(p1.clase)
    if n < 2:
        return copy.deepcopy(p1), copy.deepcopy(p2)
    corte = random.randint(1, n - 1)
    h1 = copy.deepcopy(p1)
    h2 = copy.deepcopy(p2)
    for i in range(corte, n):
        h1.clase[i].aula, h2.clase[i].aula = h2.clase[i].aula, h1.clase[i].aula
        h1.clase[i].dia, h2.clase[i].dia = h2.clase[i].dia, h1.clase[i].dia
        h1.clase[i].turno, h2.clase[i].turno = h2.clase[i].turno, h1.clase[i].turno
    return h1, h2

def mutar(individuo, lista_aula, lista_dia, lista_turno, prob=PROB_MUTACION):
    """Reasigna aleatoriamente un recurso de un sesion al azar."""
    if random.random() >= prob:
        return individuo
    nuevo = copy.deepcopy(individuo)
    items = nuevo.clase
    if not items:
        return nuevo
    item  = random.choice(items)
    campo = random.choice(["aula", "dia", "turno"])
    if campo == "aula": item.aula = random.choice(lista_aula)
    if campo == "dia": item.dia = random.choice(lista_dia)
    if campo == "turno": item.turno = random.choice(lista_turno)
    return nuevo

def algoritmo_genetico(sesions, lista_aula, lista_dia, lista_turno, profesor,
                       tamanio_pob=POP_SIZE,
                       generaciones=GENERACIONES):
    """
    Genera y optimiza un horario que minimiza las restricciones
    incumplidas. Devuelve (mejor_horario, costo_final).
    """
    poblacion   = crear_poblacion(sesions, lista_aula, lista_dia, lista_turno, profesor, tamanio_pob)
    mejor       = min(poblacion, key=evaluar)
    mejor_costo = evaluar(mejor)
    print(f'Generacion  0: costo inicial = {mejor_costo}')

    for gen in range(generaciones):
        nueva_pob = [copy.deepcopy(mejor)]  # elitismo
        while len(nueva_pob) < tamanio_pob:
            p1 = seleccion_torneo(poblacion)
            p2 = seleccion_torneo(poblacion)
            if random.random() < PROB_CRUCE:
                h1, h2 = cruce(p1, p2)
            else:
                h1, h2 = copy.deepcopy(p1), copy.deepcopy(p2)
            nueva_pob.append(mutar(h1, lista_aula, lista_dia, lista_turno))
            if len(nueva_pob) < tamanio_pob:
                nueva_pob.append(mutar(h2, lista_aula, lista_dia, lista_turno))
        poblacion   = nueva_pob
        candidato   = min(poblacion, key=evaluar)
        costo_c     = evaluar(candidato)
        if costo_c < mejor_costo:
            mejor       = candidato
            mejor_costo = costo_c
        if (gen + 1) % 50 == 0 or mejor_costo == 0:
            print(f'Generacion {gen + 1:>4}: mejor costo = {mejor_costo}')
        if mejor_costo == 0:
            print('Solucion perfecta encontrada.')
            break

    return mejor, mejor_costo


# ============================================================
# DATOS DEL DOMINIO (constantes de módulo)
# ============================================================

# sesions
SESIONS = [
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Filosofia C", frecuencia=2), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Ana Garcia Fernandez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I C", frecuencia=2), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I C", frecuencia=2), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Programacion C", frecuencia=1), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion C", frecuencia=1), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion C", frecuencia=1), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion C", frecuencia=1), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion C", frecuencia=1), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Logica C", frecuencia=1), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Miguel Diaz Morales")),
    Sesion(asignatura=Asignatura(nombre="Logica C", frecuencia=1), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Miguel Diaz Morales")),
    Sesion(asignatura=Asignatura(nombre="Logica C", frecuencia=1), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Miguel Diaz Morales")),
    Sesion(asignatura=Asignatura(nombre="Logica C", frecuencia=1), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Miguel Diaz Morales")),
    Sesion(asignatura=Asignatura(nombre="Logica C", frecuencia=1), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Miguel Diaz Morales")),
    Sesion(asignatura=Asignatura(nombre="Educacion Fisica I", frecuencia=1), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Rosa Gonzalez Blanco")),
    Sesion(asignatura=Asignatura(nombre="Educacion Fisica I", frecuencia=1), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Rosa Gonzalez Blanco")),
    Sesion(asignatura=Asignatura(nombre="Educacion Fisica I", frecuencia=1), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Rosa Gonzalez Blanco")),
    Sesion(asignatura=Asignatura(nombre="Educacion Fisica I", frecuencia=1), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Rosa Gonzalez Blanco")),
    Sesion(asignatura=Asignatura(nombre="Educacion Fisica I", frecuencia=1), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Rosa Gonzalez Blanco")),
    Sesion(asignatura=Asignatura(nombre="Algebra I CP", frecuencia=1), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I CP", frecuencia=1), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I CP", frecuencia=1), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I CP", frecuencia=1), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Algebra I CP", frecuencia=1), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Luis Lopez Rodriguez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I CP", frecuencia=1), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I CP", frecuencia=1), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I CP", frecuencia=1), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I CP", frecuencia=1), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Analisis Matematico I CP", frecuencia=1), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Maria Martinez Perez")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Programacion CP", frecuencia=2), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Carlos Hernandez Diaz")),
    Sesion(asignatura=Asignatura(nombre="Logica CP", frecuencia=1), grupo=Grupo(nombre="C111"), profesor=Profesor(nombre="Miguel Diaz Morales")),
    Sesion(asignatura=Asignatura(nombre="Logica CP", frecuencia=1), grupo=Grupo(nombre="C112"), profesor=Profesor(nombre="Miguel Diaz Morales")),
    Sesion(asignatura=Asignatura(nombre="Logica CP", frecuencia=1), grupo=Grupo(nombre="C113"), profesor=Profesor(nombre="Miguel Diaz Morales")),
    Sesion(asignatura=Asignatura(nombre="Logica CP", frecuencia=1), grupo=Grupo(nombre="C121"), profesor=Profesor(nombre="Miguel Diaz Morales")),
    Sesion(asignatura=Asignatura(nombre="Logica CP", frecuencia=1), grupo=Grupo(nombre="C122"), profesor=Profesor(nombre="Miguel Diaz Morales")),
]

# pool de aula
LISTA_AULA = [
    Aula(nombre="Aula 1"),
    Aula(nombre="Aula 2"),
    Aula(nombre="Aula 5"),
    Aula(nombre="Aula 6"),
    Aula(nombre="Laboratorio de Computacion"),
    Aula(nombre="SEDER"),
]

# pool de dia
LISTA_DIA = [
    Dia(nombre="Lunes"),
    Dia(nombre="Martes"),
    Dia(nombre="Miercoles"),
    Dia(nombre="Jueves"),
    Dia(nombre="Viernes"),
]

# pool de turno
LISTA_TURNO = [
    Turno(nombre="T1"),
    Turno(nombre="T2"),
    Turno(nombre="T3"),
    Turno(nombre="T4"),
    Turno(nombre="T5"),
    Turno(nombre="T6"),
]

# profesor
PROFESOR = [
    Profesor(nombre="Ana Garcia Fernandez"),
    Profesor(nombre="Luis Lopez Rodriguez"),
    Profesor(nombre="Maria Martinez Perez"),
    Profesor(nombre="Carlos Hernandez Diaz"),
    Profesor(nombre="Rosa Gonzalez Blanco"),
    Profesor(nombre="Miguel Diaz Morales"),
]

# ============================================================
# PUNTO DE ENTRADA
# ============================================================

if __name__ == '__main__':
    mostrar_modelo()

    solucion, costo = algoritmo_genetico(SESIONS, LISTA_AULA, LISTA_DIA, LISTA_TURNO, PROFESOR)

    print()
    mostrar_resultado(solucion)
    exportar_json(solucion, costo)
