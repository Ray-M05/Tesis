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
    orden: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Grado:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Grupo:
    nombre: object = None
    grado: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Asignatura:
    nombre: object = None
    dia_preparacion: object = None
    educacion_fisica: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Aula:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Profesor:
    nombre: object = None
    vive_lejos: object = None
    es_contratado: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Plan:
    grupo: object = None
    asignatura: object = None
    profesor: object = None
    aula: object = None
    frecuencia: object = None
    admite_doble: object = None
    admite_tarde: object = None
    def __str__(self): return f'(grupo={self.grupo}, asignatura={self.asignatura}, profesor={self.profesor}, aula={self.aula}, frecuencia={self.frecuencia}, admite_doble={self.admite_doble}, admite_tarde={self.admite_tarde})'

@dataclass(unsafe_hash=True)
class Sesion:
    plan: object = None
    numero: object = None
    def __str__(self): return f'(plan={self.plan}, numero={self.numero})'

@dataclass(unsafe_hash=True)
class Ausencia:
    profesor: object = None
    dia: object = None
    def __str__(self): return f'(profesor={self.profesor}, dia={self.dia})'

@dataclass(unsafe_hash=True)
class Jornada:
    profesor: object = None
    dia: object = None
    tope: object = None
    def __str__(self): return f'(profesor={self.profesor}, dia={self.dia}, tope={self.tope})'

@dataclass
class Ubicacion:
    sesion: object = None
    dia: object = None
    turno: object = None

@dataclass
class Horario:
    ubicacion: List = field(default_factory=list)
    profesor: List = field(default_factory=list)
    ausencia: List = field(default_factory=list)
    jornada: List = field(default_factory=list)
    plan: List = field(default_factory=list)



# ============================================================
# CONSULTAS
# ============================================================

def colisiones_de_grupo(horario):
    count = 0
    for u1 in horario.ubicacion:
        for u2 in horario.ubicacion:
            if ((u1.sesion.plan.grupo == u2.sesion.plan.grupo) and (u1.dia == u2.dia) and (u1.turno == u2.turno) and (u1.sesion != u2.sesion)):
                count += 1
    return count

def colisiones_de_profesor(horario):
    count = 0
    for p in horario.profesor:
        for u1 in horario.ubicacion:
            for u2 in horario.ubicacion:
                if ((u1.sesion.plan.profesor == p) and (u2.sesion.plan.profesor == p) and (u1.dia == u2.dia) and (u1.turno == u2.turno) and (u1.sesion != u2.sesion)):
                    count += 1
    return count

def repeticiones_en_el_dia(horario):
    count = 0
    for u1 in horario.ubicacion:
        for u2 in horario.ubicacion:
            if ((u1.sesion.plan == u2.sesion.plan) and (u1.dia == u2.dia) and (u1.sesion.plan.admite_doble == 0) and (u1.sesion != u2.sesion)):
                count += 1
    return count

def dobles_no_consecutivos(horario):
    count = 0
    for u1 in horario.ubicacion:
        for u2 in horario.ubicacion:
            if ((u1.sesion.plan == u2.sesion.plan) and (u1.dia == u2.dia) and (u1.sesion.plan.admite_doble == 1) and (u2.turno.orden > u1.turno.orden) and (u2.turno.orden != (u1.turno.orden + 1))):
                count += 1
    return count

def sesiones_en_dia_de_preparacion(horario):
    count = 0
    for u in horario.ubicacion:
        if (u.dia == u.sesion.plan.asignatura.dia_preparacion):
            count += 1
    return count

def educacion_fisica_fuera_de_horario(horario):
    count = 0
    for u in horario.ubicacion:
        if ((u.sesion.plan.asignatura.educacion_fisica == 1) and (u.turno.orden > 3)):
            count += 1
    return count

def sesiones_de_tarde_no_autorizadas(horario):
    count = 0
    for u in horario.ubicacion:
        if ((u.sesion.plan.admite_tarde == 0) and (u.turno.orden > 5)):
            count += 1
    return count

def sesiones_en_dia_sin_asistencia(horario):
    count = 0
    for u in horario.ubicacion:
        for a in horario.ausencia:
            if ((u.sesion.plan.profesor == a.profesor) and (u.dia == a.dia)):
                count += 1
    return count

def sesiones_del_plan(horario, pl):
    count = 0
    for u in horario.ubicacion:
        if (u.sesion.plan == pl):
            count += 1
    return count

def primeros_turnos_de_lejanos(horario):
    count = 0
    for u in horario.ubicacion:
        if ((u.sesion.plan.profesor.vive_lejos == 1) and (u.turno.orden == 1)):
            count += 1
    return count

def sesiones_de_la_jornada(horario, jornada):
    count = 0
    for u in horario.ubicacion:
        if ((u.sesion.plan.profesor == jornada.profesor) and (u.dia == jornada.dia)):
            count += 1
    return count

# ============================================================
# RESTRICCIONES SIMPLES / DURAS  (nppq / tqpq)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_una_sesion_por_grupo(horario):
    return colisiones_de_grupo(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_una_sesion_por_profesor(horario):
    return colisiones_de_profesor(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_sin_repetir_asignatura_en_el_dia(horario):
    return repeticiones_en_el_dia(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_turno_doble_consecutivo(horario):
    return dobles_no_consecutivos(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_sin_clases_el_dia_de_preparacion(horario):
    return sesiones_en_dia_de_preparacion(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_educacion_fisica_temprano(horario):
    return educacion_fisica_fuera_de_horario(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_tarde_solo_para_las_autorizadas(horario):
    return sesiones_de_tarde_no_autorizadas(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_contratado_solo_sus_dias(horario):
    return sesiones_en_dia_sin_asistencia(horario)

# SIMPLE / DURA  (tqpq) — Tiene Que Pasar Que
def restriccion_frecuencia_exacta(horario):
    count = 0
    for pl in horario.plan:
        if not (sesiones_del_plan(horario, pl) == pl.frecuencia):
            count += 1
    return count

# ============================================================
# RESTRICCIONES DEBILES / BLANDAS  (ndpq / sbqp)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# DEBIL  / BLANDA (ndpq) — No Debe Pasar Que
def restriccion_evitar_primer_turno_a_los_lejanos(horario):
    return primeros_turnos_de_lejanos(horario)

# DEBIL  / BLANDA (sbqp) — Solo Bien Para Que
def restriccion_tope_diario_de_profesor(horario):
    count = 0
    for jornada in horario.jornada:
        if not (sesiones_de_la_jornada(horario, jornada) <= jornada.tope):
            count += 1
    return count

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
    costo += PESO_DURA   * restriccion_una_sesion_por_grupo(horario)
    costo += PESO_DURA   * restriccion_una_sesion_por_profesor(horario)
    costo += PESO_DURA   * restriccion_sin_repetir_asignatura_en_el_dia(horario)
    costo += PESO_DURA   * restriccion_turno_doble_consecutivo(horario)
    costo += PESO_DURA   * restriccion_sin_clases_el_dia_de_preparacion(horario)
    costo += PESO_DURA   * restriccion_educacion_fisica_temprano(horario)
    costo += PESO_DURA   * restriccion_tarde_solo_para_las_autorizadas(horario)
    costo += PESO_DURA   * restriccion_contratado_solo_sus_dias(horario)
    costo += PESO_DURA   * restriccion_frecuencia_exacta(horario)
    # restricciones debiles / blandas
    costo += PESO_BLANDA * restriccion_evitar_primer_turno_a_los_lejanos(horario)
    costo += PESO_BLANDA * restriccion_tope_diario_de_profesor(horario)
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
    print(f'  D  =  conjunto de dia disponibles   (|D| = {len(LISTA_DIA)})')
    print(f'  T  =  conjunto de turno disponibles   (|T| = {len(LISTA_TURNO)})')
    print(f'  P  =  conjunto de profesor   (|P| = {len(PROFESOR)})')
    print(f'  A  =  conjunto de ausencia   (|A| = {len(AUSENCIA)})')
    print(f'  J  =  conjunto de jornada   (|J| = {len(JORNADA)})')
    print(f'  P  =  conjunto de plan   (|P| = {len(PLAN)})')
    print()
    print('VARIABLES DE DECISION:')
    print('  Para cada sesion t ∈ S se asigna:')
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
    print('    colisiones_de_grupo(h) = 0')
    print('    donde:')
    print('      colisiones_de_grupo(h) = Σ_{u1∈UBICACION, u2∈UBICACION}  [((grupo(plan(sesion(u1))) = grupo(plan(sesion(u2)))) ∧ (dia(u1) = dia(u2)) ∧ (turno(u1) = turno(u2)) ∧ (sesion(u1) ≠ sesion(u2)))]')
    print()
    print('  R2  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    colisiones_de_profesor(h) = 0')
    print('    donde:')
    print('      colisiones_de_profesor(h) = Σ_{p∈PROFESOR, u1∈UBICACION, u2∈UBICACION}  [((profesor(plan(sesion(u1))) = p) ∧ (profesor(plan(sesion(u2))) = p) ∧ (dia(u1) = dia(u2)) ∧ (turno(u1) = turno(u2)) ∧ (sesion(u1) ≠ sesion(u2)))]')
    print()
    print('  R3  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    repeticiones_en_el_dia(h) = 0')
    print('    donde:')
    print('      repeticiones_en_el_dia(h) = Σ_{u1∈UBICACION, u2∈UBICACION}  [((plan(sesion(u1)) = plan(sesion(u2))) ∧ (dia(u1) = dia(u2)) ∧ (admite_doble(plan(sesion(u1))) = 0) ∧ (sesion(u1) ≠ sesion(u2)))]')
    print()
    print('  R4  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    dobles_no_consecutivos(h) = 0')
    print('    donde:')
    print('      dobles_no_consecutivos(h) = Σ_{u1∈UBICACION, u2∈UBICACION}  [((plan(sesion(u1)) = plan(sesion(u2))) ∧ (dia(u1) = dia(u2)) ∧ (admite_doble(plan(sesion(u1))) = 1) ∧ (orden(turno(u2)) > orden(turno(u1))) ∧ (orden(turno(u2)) ≠ (orden(turno(u1)) + 1)))]')
    print()
    print('  R5  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    sesiones_en_dia_de_preparacion(h) = 0')
    print('    donde:')
    print('      sesiones_en_dia_de_preparacion(h) = Σ_{u∈UBICACION}  [(dia(u) = dia_preparacion(asignatura(plan(sesion(u)))))]')
    print()
    print('  R6  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    educacion_fisica_fuera_de_horario(h) = 0')
    print('    donde:')
    print('      educacion_fisica_fuera_de_horario(h) = Σ_{u∈UBICACION}  [((educacion_fisica(asignatura(plan(sesion(u)))) = 1) ∧ (orden(turno(u)) > 3))]')
    print()
    print('  R7  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    sesiones_de_tarde_no_autorizadas(h) = 0')
    print('    donde:')
    print('      sesiones_de_tarde_no_autorizadas(h) = Σ_{u∈UBICACION}  [((admite_tarde(plan(sesion(u))) = 0) ∧ (orden(turno(u)) > 5))]')
    print()
    print('  R8  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    sesiones_en_dia_sin_asistencia(h) = 0')
    print('    donde:')
    print('      sesiones_en_dia_sin_asistencia(h) = Σ_{u∈UBICACION, a∈AUSENCIA}  [((profesor(plan(sesion(u))) = profesor(a)) ∧ (dia(u) = dia(a)))]')
    print()
    print('  R9  [SIMPLE / DURA  (tqpq) — Tiene Que Pasar Que]:')
    print('    (sesiones_del_plan(h, pl) = frecuencia(?))')
    print()
    print()
    print('RESTRICCIONES BLANDAS  (tdpq / sbqp / minimizar):')
    print('  R10  [DEBIL  / BLANDA (ndpq) — No Debe Pasar Que]:')
    print('    (primeros_turnos_de_lejanos(h) > 0)')
    print('    donde:')
    print('      primeros_turnos_de_lejanos(h) = Σ_{u∈UBICACION}  [((vive_lejos(profesor(plan(sesion(u)))) = 1) ∧ (orden(turno(u)) = 1))]')
    print()
    print('  R11  [DEBIL  / BLANDA (sbqp) — Solo Bien Para Que]:')
    print('    (sesiones_de_la_jornada(h, jornada) ≤ tope(?))')
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
    for i, asig in enumerate(horario.ubicacion, 1):
        print(f'  Defensa {i}:')
        print(f'    SESION : {asig.sesion}')
        print(f'    DIA : {asig.dia}')
        print(f'    TURNO : {asig.turno}')
        print()
    print(sep)
    print('EVALUACION DE RESTRICCIONES')
    print(sep)
    costo_total = 0
    print('Restricciones simples / duras  (peso 1000):')
    v = restriccion_una_sesion_por_grupo(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_una_sesion_por_grupo: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_una_sesion_por_profesor(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_una_sesion_por_profesor: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_sin_repetir_asignatura_en_el_dia(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_sin_repetir_asignatura_en_el_dia: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_turno_doble_consecutivo(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_turno_doble_consecutivo: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_sin_clases_el_dia_de_preparacion(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_sin_clases_el_dia_de_preparacion: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_educacion_fisica_temprano(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_educacion_fisica_temprano: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_tarde_solo_para_las_autorizadas(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_tarde_solo_para_las_autorizadas: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_contratado_solo_sus_dias(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_contratado_solo_sus_dias: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_frecuencia_exacta(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_frecuencia_exacta: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    print('Restricciones debiles / blandas  (peso 1):')
    v = restriccion_evitar_primer_turno_a_los_lejanos(horario)
    costo_total += PESO_BLANDA * v
    print(f'  restriccion_evitar_primer_turno_a_los_lejanos: {v}  ->  costo: {PESO_BLANDA * v}')
    v = restriccion_tope_diario_de_profesor(horario)
    costo_total += PESO_BLANDA * v
    print(f'  restriccion_tope_diario_de_profesor: {v}  ->  costo: {PESO_BLANDA * v}')
    print(f'Costo total: {costo_total}')
    print(sep)


def _ent_a_dict(x):
    """Convierte entidad a dict JSON-serializable."""
    if x is None: return None
    if isinstance(x, (str, int, float, bool)): return x
    if hasattr(x, 'nombre'): return str(x)
    if hasattr(x, 'id'): return str(x)
    return {campo: _ent_a_dict(getattr(x, campo)) for campo in vars(x)}


def exportar_json(solucion, costo_total, archivo="saul/horario.json"):
    """Exporta el modelo matematico y el horario propuesto a JSON."""
    import json
    datos = {
        'modelo': {
            'conjuntos': {
                'S': len(SESIONS),
                'D': len(LISTA_DIA),
                'T': len(LISTA_TURNO),
                'P': len(PROFESOR),
                'A': len(AUSENCIA),
                'J': len(JORNADA),
                'P': len(PLAN),
            },
            'peso_dura': 1000,
            'peso_blanda': 1,
            'restricciones_duras': ['restriccion_una_sesion_por_grupo', 'restriccion_una_sesion_por_profesor', 'restriccion_sin_repetir_asignatura_en_el_dia', 'restriccion_turno_doble_consecutivo', 'restriccion_sin_clases_el_dia_de_preparacion', 'restriccion_educacion_fisica_temprano', 'restriccion_tarde_solo_para_las_autorizadas', 'restriccion_contratado_solo_sus_dias', 'restriccion_frecuencia_exacta'],
            'restricciones_blandas': ['restriccion_evitar_primer_turno_a_los_lejanos', 'restriccion_tope_diario_de_profesor'],
        },
        'horario': [_ent_a_dict(asig) for asig in solucion.ubicacion],
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

def crear_horario_aleatorio(sesions, lista_dia, lista_turno, profesor, ausencia, jornada, plan):
    """Crea un horario asignando recursos aleatorios a cada sesion."""
    h = Horario()
    h.profesor = list(profesor)
    h.ausencia = list(ausencia)
    h.jornada = list(jornada)
    h.plan = list(plan)
    for ident in sesions:
        h.ubicacion.append(Ubicacion(
            sesion=ident,
            dia=random.choice(lista_dia),
            turno=random.choice(lista_turno),
        ))
    return h

def crear_poblacion(sesions, lista_dia, lista_turno, profesor, ausencia, jornada, plan, tamanio=POP_SIZE):
    return [crear_horario_aleatorio(sesions, lista_dia, lista_turno, profesor, ausencia, jornada, plan) for _ in range(tamanio)]

def seleccion_torneo(poblacion, k=TORNEO_K):
    """Devuelve el mejor de k individuos elegidos al azar."""
    candidatos = random.sample(poblacion, min(k, len(poblacion)))
    return min(candidatos, key=evaluar)

def cruce(p1, p2):
    """Cruce de un punto: intercambia recursos (dia, turno) tras el corte."""
    n = len(p1.ubicacion)
    if n < 2:
        return copy.deepcopy(p1), copy.deepcopy(p2)
    corte = random.randint(1, n - 1)
    h1 = copy.deepcopy(p1)
    h2 = copy.deepcopy(p2)
    for i in range(corte, n):
        h1.ubicacion[i].dia, h2.ubicacion[i].dia = h2.ubicacion[i].dia, h1.ubicacion[i].dia
        h1.ubicacion[i].turno, h2.ubicacion[i].turno = h2.ubicacion[i].turno, h1.ubicacion[i].turno
    return h1, h2

def mutar(individuo, lista_dia, lista_turno, prob=PROB_MUTACION):
    """Reasigna aleatoriamente un recurso de un sesion al azar."""
    if random.random() >= prob:
        return individuo
    nuevo = copy.deepcopy(individuo)
    items = nuevo.ubicacion
    if not items:
        return nuevo
    item  = random.choice(items)
    campo = random.choice(["dia", "turno"])
    if campo == "dia": item.dia = random.choice(lista_dia)
    if campo == "turno": item.turno = random.choice(lista_turno)
    return nuevo

def algoritmo_genetico(sesions, lista_dia, lista_turno, profesor, ausencia, jornada, plan,
                       tamanio_pob=POP_SIZE,
                       generaciones=GENERACIONES):
    """
    Genera y optimiza un horario que minimiza las restricciones
    incumplidas. Devuelve (mejor_horario, costo_final).
    """
    poblacion   = crear_poblacion(sesions, lista_dia, lista_turno, profesor, ausencia, jornada, plan, tamanio_pob)
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
            nueva_pob.append(mutar(h1, lista_dia, lista_turno))
            if len(nueva_pob) < tamanio_pob:
                nueva_pob.append(mutar(h2, lista_dia, lista_turno))
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
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Defensa Civil", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Defensa Civil", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Defensa Civil", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Defensa Civil", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Defensa Civil", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Defensa Civil", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Artística", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Artística", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Artística", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Artística", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Artística", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Artística", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=4, admite_doble=0, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 11-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 11-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 11-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 11-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 11-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 11-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=4),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0), numero=5),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=2, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=1), numero=3),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=2),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=1),
    Sesion(plan=Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0), numero=2),
]

# pool de dia
LISTA_DIA = [
    Dia(nombre="Lunes"),
    Dia(nombre="Martes"),
    Dia(nombre="Miércoles"),
    Dia(nombre="Jueves"),
    Dia(nombre="Viernes"),
]

# pool de turno
LISTA_TURNO = [
    Turno(nombre="T1", orden=1),
    Turno(nombre="T2", orden=2),
    Turno(nombre="T3", orden=3),
    Turno(nombre="T4", orden=4),
    Turno(nombre="T5", orden=5),
    Turno(nombre="T6", orden=6),
    Turno(nombre="T7", orden=7),
]

# profesor
PROFESOR = [
    Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0),
    Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0),
    Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1),
    Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0),
    Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0),
    Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1),
    Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1),
    Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0),
    Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0),
]

# ausencia
AUSENCIA = [
    Ausencia(profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Martes")),
    Ausencia(profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Jueves")),
    Ausencia(profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Lunes")),
    Ausencia(profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Viernes")),
    Ausencia(profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Lunes")),
    Ausencia(profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Jueves")),
]

# jornada
JORNADA = [
    Jornada(profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Lunes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Martes"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Miércoles"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Jueves"), tope=5),
    Jornada(profesor=Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0), dia=Dia(nombre="Viernes"), tope=5),
]

# plan
PLAN = [
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_A", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Y", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=4, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=4, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_G", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=4, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Defensa Civil", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Defensa Civil", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Defensa Civil", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_P", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-1"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-2"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 10-3"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Artística", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Artística", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Cultura Artística", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_V", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 10-3"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="10-1", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-2", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="10-3", grado=Grado(nombre="10mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_B", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_D", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=4, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=4, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_H", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=4, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_J", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_L", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_N", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Q", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_Z", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-1"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-2"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_S", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 11-3"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 11-1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 11-2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Geografía", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_U", vive_lejos=0, es_contratado=1), aula=Aula(nombre="Aula 11-3"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="11-1", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-2", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="11-3", grado=Grado(nombre="11no grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_W", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Matemática", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_C", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Física", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_E", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Informática", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_F", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Laboratorio 2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Literatura y Lengua", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_I", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Historia", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_K", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=5, admite_doble=1, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Cultura Política", dia_preparacion=Dia(nombre="Viernes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_M", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Idioma Extranjero (Inglés)", dia_preparacion=Dia(nombre="Lunes"), educacion_fisica=0), profesor=Profesor(nombre="profesor_O", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=2, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Biología", dia_preparacion=Dia(nombre="Miércoles"), educacion_fisica=0), profesor=Profesor(nombre="profesor_R", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-1"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-2"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Química", dia_preparacion=Dia(nombre="Jueves"), educacion_fisica=0), profesor=Profesor(nombre="profesor_T", vive_lejos=1, es_contratado=0), aula=Aula(nombre="Aula 12-3"), frecuencia=3, admite_doble=0, admite_tarde=1),
    Plan(grupo=Grupo(nombre="12-1", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-2", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0),
    Plan(grupo=Grupo(nombre="12-3", grado=Grado(nombre="12mo grado")), asignatura=Asignatura(nombre="Educación Física", dia_preparacion=Dia(nombre="Martes"), educacion_fisica=1), profesor=Profesor(nombre="profesor_X", vive_lejos=0, es_contratado=0), aula=Aula(nombre="Terreno deportivo"), frecuencia=2, admite_doble=0, admite_tarde=0),
]

# ============================================================
# PUNTO DE ENTRADA
# ============================================================

if __name__ == '__main__':
    mostrar_modelo()

    solucion, costo = algoritmo_genetico(SESIONS, LISTA_DIA, LISTA_TURNO, PROFESOR, AUSENCIA, JORNADA, PLAN)

    print()
    mostrar_resultado(solucion)
    exportar_json(solucion, costo)
