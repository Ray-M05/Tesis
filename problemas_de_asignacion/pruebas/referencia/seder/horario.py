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
class Turno:
    nombre: object = None
    orden: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Instalacion:
    nombre: object = None
    capacidad: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Carrera:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Anno:
    nombre: object = None
    carrera: object = None
    paridad: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Profesor:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Brigada:
    nombre: object = None
    anno: object = None
    profesor: object = None
    cantidad: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Indisponibilidad:
    anno: object = None
    turno: object = None
    def __str__(self): return f'(anno={self.anno}, turno={self.turno})'

@dataclass
class Ubicacion:
    brigada: object = None
    turno: object = None
    instalacion: object = None

@dataclass
class Horario:
    ubicacion: List = field(default_factory=list)
    indisponibilidad: List = field(default_factory=list)
    profesor: List = field(default_factory=list)
    turno: List = field(default_factory=list)
    instalacion: List = field(default_factory=list)



# ============================================================
# CONSULTAS
# ============================================================

def clases_en_turno_no_disponible(horario):
    count = 0
    for u in horario.ubicacion:
        for i in horario.indisponibilidad:
            if ((u.brigada.anno == i.anno) and (u.turno == i.turno)):
                count += 1
    return count

def brigadas_que_no_caben(horario):
    count = 0
    for u in horario.ubicacion:
        if (u.brigada.cantidad > u.instalacion.capacidad):
            count += 1
    return count

def colisiones_de_instalacion(horario):
    count = 0
    for u1 in horario.ubicacion:
        for u2 in horario.ubicacion:
            if ((u1.instalacion == u2.instalacion) and (u1.turno == u2.turno) and (u1.brigada.anno.paridad == u2.brigada.anno.paridad) and (u1.brigada != u2.brigada)):
                count += 1
    return count

def colisiones_de_profesor(horario):
    count = 0
    for p in horario.profesor:
        for u1 in horario.ubicacion:
            for u2 in horario.ubicacion:
                if ((u1.brigada.profesor == p) and (u2.brigada.profesor == p) and (u1.turno == u2.turno) and (u1.brigada.anno.paridad == u2.brigada.anno.paridad) and (u1.brigada != u2.brigada)):
                    count += 1
    return count

def brigadas_de_la_instalacion(horario, inst):
    count = 0
    for u in horario.ubicacion:
        if (u.instalacion == inst):
            count += 1
    return count

def brigadas_del_turno(horario, tur):
    count = 0
    for u in horario.ubicacion:
        if (u.turno == tur):
            count += 1
    return count

# ============================================================
# RESTRICCIONES SIMPLES / DURAS  (nppq / tqpq)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_solo_turnos_disponibles(horario):
    return clases_en_turno_no_disponible(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_la_brigada_cabe(horario):
    return brigadas_que_no_caben(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_una_brigada_por_instalacion(horario):
    return colisiones_de_instalacion(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_un_profesor_por_turno(horario):
    return colisiones_de_profesor(horario)

# ============================================================
# RESTRICCIONES DEBILES / BLANDAS  (ndpq / sbqp)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# OPTIMIZACIÓN — Minimizar
def restriccion_equilibrar_instalaciones(horario):
    valores = [brigadas_de_la_instalacion(horario, x) for x in horario.instalacion]
    return max(valores) if valores else 0

# OPTIMIZACIÓN — Minimizar
def restriccion_equilibrar_turnos(horario):
    valores = [brigadas_del_turno(horario, x) for x in horario.turno]
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
    costo += PESO_DURA   * restriccion_solo_turnos_disponibles(horario)
    costo += PESO_DURA   * restriccion_la_brigada_cabe(horario)
    costo += PESO_DURA   * restriccion_una_brigada_por_instalacion(horario)
    costo += PESO_DURA   * restriccion_un_profesor_por_turno(horario)
    # restricciones debiles / blandas
    costo += PESO_BLANDA * restriccion_equilibrar_instalaciones(horario)
    costo += PESO_BLANDA * restriccion_equilibrar_turnos(horario)
    return costo


def mostrar_modelo():
    """Imprime el modelo abstracto de optimizacion."""
    sep = '=' * 60
    print(sep)
    print('MODELO DE OPTIMIZACION')
    print(sep)
    print()
    print('INDICES Y CONJUNTOS:')
    print(f'  B  =  conjunto de brigadas      (|B| = {len(BRIGADAS)})')
    print(f'  T  =  conjunto de turno disponibles   (|T| = {len(LISTA_TURNO)})')
    print(f'  I  =  conjunto de instalacion disponibles   (|I| = {len(LISTA_INSTALACION)})')
    print(f'  I  =  conjunto de indisponibilidad   (|I| = {len(INDISPONIBILIDAD)})')
    print(f'  P  =  conjunto de profesor   (|P| = {len(PROFESOR)})')
    print(f'  T  =  conjunto de turno   (|T| = {len(TURNO)})')
    print(f'  I  =  conjunto de instalacion   (|I| = {len(INSTALACION)})')
    print()
    print('VARIABLES DE DECISION:')
    print('  Para cada brigada t ∈ B se asigna:')
    print('    turno_t ∈ T   (turno)')
    print('    instalacion_t ∈ I   (instalacion)')
    print()
    print('FUNCION OBJETIVO:')
    print('  minimizar z(h) donde:')
    print('    z(h) = 1000 · Σ_i incumpl_i(h)   [duras]')
    print('         + 1 · Σ_j incumpl_j(h)   [blandas]')
    print()
    print('RESTRICCIONES DURAS  (nppq / tqpq):')
    print('  R1  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    clases_en_turno_no_disponible(h) = 0')
    print('    donde:')
    print('      clases_en_turno_no_disponible(h) = Σ_{u∈UBICACION, i∈INDISPONIBILIDAD}  [((anno(brigada(u)) = anno(i)) ∧ (turno(u) = turno(i)))]')
    print()
    print('  R2  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    brigadas_que_no_caben(h) = 0')
    print('    donde:')
    print('      brigadas_que_no_caben(h) = Σ_{u∈UBICACION}  [(cantidad(brigada(u)) > capacidad(instalacion(u)))]')
    print()
    print('  R3  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    colisiones_de_instalacion(h) = 0')
    print('    donde:')
    print('      colisiones_de_instalacion(h) = Σ_{u1∈UBICACION, u2∈UBICACION}  [((instalacion(u1) = instalacion(u2)) ∧ (turno(u1) = turno(u2)) ∧ (paridad(anno(brigada(u1))) = paridad(anno(brigada(u2)))) ∧ (brigada(u1) ≠ brigada(u2)))]')
    print()
    print('  R4  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    colisiones_de_profesor(h) = 0')
    print('    donde:')
    print('      colisiones_de_profesor(h) = Σ_{p∈PROFESOR, u1∈UBICACION, u2∈UBICACION}  [((profesor(brigada(u1)) = p) ∧ (profesor(brigada(u2)) = p) ∧ (turno(u1) = turno(u2)) ∧ (paridad(anno(brigada(u1))) = paridad(anno(brigada(u2)))) ∧ (brigada(u1) ≠ brigada(u2)))]')
    print()
    print()
    print('RESTRICCIONES BLANDAS  (tdpq / sbqp / minimizar):')
    print('  R5  [OPTIMIZACIÓN — Minimizar]:')
    print('    minimizar  max_{{x ∈ INSTALACION}}  brigadas_de_la_instalacion(h, x)')
    print('    donde:')
    print('      brigadas_de_la_instalacion(h, inst) = Σ_{u∈UBICACION}  [(instalacion(u) = inst)]')
    print()
    print('  R6  [OPTIMIZACIÓN — Minimizar]:')
    print('    minimizar  max_{{x ∈ TURNO}}  brigadas_del_turno(h, x)')
    print('    donde:')
    print('      brigadas_del_turno(h, tur) = Σ_{u∈UBICACION}  [(turno(u) = tur)]')
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
        print(f'    BRIGADA : {asig.brigada}')
        print(f'    TURNO : {asig.turno}')
        print(f'    INSTALACION : {asig.instalacion}')
        print()
    print(sep)
    print('EVALUACION DE RESTRICCIONES')
    print(sep)
    costo_total = 0
    print('Restricciones simples / duras  (peso 1000):')
    v = restriccion_solo_turnos_disponibles(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_solo_turnos_disponibles: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_la_brigada_cabe(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_la_brigada_cabe: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_una_brigada_por_instalacion(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_una_brigada_por_instalacion: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_un_profesor_por_turno(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_un_profesor_por_turno: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    print('Restricciones debiles / blandas  (peso 1):')
    v = restriccion_equilibrar_instalaciones(horario)
    costo_total += PESO_BLANDA * v
    print(f'  restriccion_equilibrar_instalaciones: {v}  ->  costo: {PESO_BLANDA * v}')
    v = restriccion_equilibrar_turnos(horario)
    costo_total += PESO_BLANDA * v
    print(f'  restriccion_equilibrar_turnos: {v}  ->  costo: {PESO_BLANDA * v}')
    print(f'Costo total: {costo_total}')
    print(sep)


def _ent_a_dict(x):
    """Convierte entidad a dict JSON-serializable."""
    if x is None: return None
    if isinstance(x, (str, int, float, bool)): return x
    if hasattr(x, 'nombre'): return str(x)
    if hasattr(x, 'id'): return str(x)
    return {campo: _ent_a_dict(getattr(x, campo)) for campo in vars(x)}


def exportar_json(solucion, costo_total, archivo="seder/horario.json"):
    """Exporta el modelo matematico y el horario propuesto a JSON."""
    import json
    datos = {
        'modelo': {
            'conjuntos': {
                'B': len(BRIGADAS),
                'T': len(LISTA_TURNO),
                'I': len(LISTA_INSTALACION),
                'I': len(INDISPONIBILIDAD),
                'P': len(PROFESOR),
                'T': len(TURNO),
                'I': len(INSTALACION),
            },
            'peso_dura': 1000,
            'peso_blanda': 1,
            'restricciones_duras': ['restriccion_solo_turnos_disponibles', 'restriccion_la_brigada_cabe', 'restriccion_una_brigada_por_instalacion', 'restriccion_un_profesor_por_turno'],
            'restricciones_blandas': ['restriccion_equilibrar_instalaciones', 'restriccion_equilibrar_turnos'],
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

def crear_horario_aleatorio(brigadas, lista_turno, lista_instalacion, indisponibilidad, profesor, turno, instalacion):
    """Crea un horario asignando recursos aleatorios a cada brigada."""
    h = Horario()
    h.indisponibilidad = list(indisponibilidad)
    h.profesor = list(profesor)
    h.turno = list(turno)
    h.instalacion = list(instalacion)
    for ident in brigadas:
        h.ubicacion.append(Ubicacion(
            brigada=ident,
            turno=random.choice(lista_turno),
            instalacion=random.choice(lista_instalacion),
        ))
    return h

def crear_poblacion(brigadas, lista_turno, lista_instalacion, indisponibilidad, profesor, turno, instalacion, tamanio=POP_SIZE):
    return [crear_horario_aleatorio(brigadas, lista_turno, lista_instalacion, indisponibilidad, profesor, turno, instalacion) for _ in range(tamanio)]

def seleccion_torneo(poblacion, k=TORNEO_K):
    """Devuelve el mejor de k individuos elegidos al azar."""
    candidatos = random.sample(poblacion, min(k, len(poblacion)))
    return min(candidatos, key=evaluar)

def cruce(p1, p2):
    """Cruce de un punto: intercambia recursos (turno, instalacion) tras el corte."""
    n = len(p1.ubicacion)
    if n < 2:
        return copy.deepcopy(p1), copy.deepcopy(p2)
    corte = random.randint(1, n - 1)
    h1 = copy.deepcopy(p1)
    h2 = copy.deepcopy(p2)
    for i in range(corte, n):
        h1.ubicacion[i].turno, h2.ubicacion[i].turno = h2.ubicacion[i].turno, h1.ubicacion[i].turno
        h1.ubicacion[i].instalacion, h2.ubicacion[i].instalacion = h2.ubicacion[i].instalacion, h1.ubicacion[i].instalacion
    return h1, h2

def mutar(individuo, lista_turno, lista_instalacion, prob=PROB_MUTACION):
    """Reasigna aleatoriamente un recurso de un brigada al azar."""
    if random.random() >= prob:
        return individuo
    nuevo = copy.deepcopy(individuo)
    items = nuevo.ubicacion
    if not items:
        return nuevo
    item  = random.choice(items)
    campo = random.choice(["turno", "instalacion"])
    if campo == "turno": item.turno = random.choice(lista_turno)
    if campo == "instalacion": item.instalacion = random.choice(lista_instalacion)
    return nuevo

def algoritmo_genetico(brigadas, lista_turno, lista_instalacion, indisponibilidad, profesor, turno, instalacion,
                       tamanio_pob=POP_SIZE,
                       generaciones=GENERACIONES):
    """
    Genera y optimiza un horario que minimiza las restricciones
    incumplidas. Devuelve (mejor_horario, costo_final).
    """
    poblacion   = crear_poblacion(brigadas, lista_turno, lista_instalacion, indisponibilidad, profesor, turno, instalacion, tamanio_pob)
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
            nueva_pob.append(mutar(h1, lista_turno, lista_instalacion))
            if len(nueva_pob) < tamanio_pob:
                nueva_pob.append(mutar(h2, lista_turno, lista_instalacion))
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

# brigadas
BRIGADAS = [
    Brigada(nombre="MAT-1-A", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Matemática"), paridad=0), profesor=Profesor(nombre="profesor_01"), cantidad=32),
    Brigada(nombre="MAT-1-B", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Matemática"), paridad=0), profesor=Profesor(nombre="profesor_02"), cantidad=30),
    Brigada(nombre="COM-1-A", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Computación"), paridad=0), profesor=Profesor(nombre="profesor_01"), cantidad=28),
    Brigada(nombre="COM-1-B", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Computación"), paridad=0), profesor=Profesor(nombre="profesor_05"), cantidad=26),
    Brigada(nombre="COM-2-A", anno=Anno(nombre="2do", carrera=Carrera(nombre="Computación"), paridad=0), profesor=Profesor(nombre="profesor_03"), cantidad=35),
    Brigada(nombre="COM-2-B", anno=Anno(nombre="2do", carrera=Carrera(nombre="Computación"), paridad=0), profesor=Profesor(nombre="profesor_04"), cantidad=33),
    Brigada(nombre="QUI-1-A", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Química"), paridad=0), profesor=Profesor(nombre="profesor_03"), cantidad=24),
    Brigada(nombre="QUI-1-B", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Química"), paridad=0), profesor=Profesor(nombre="profesor_04"), cantidad=22),
    Brigada(nombre="BIO-2-A", anno=Anno(nombre="2do", carrera=Carrera(nombre="Biología"), paridad=0), profesor=Profesor(nombre="profesor_02"), cantidad=30),
    Brigada(nombre="BIO-2-B", anno=Anno(nombre="2do", carrera=Carrera(nombre="Biología"), paridad=0), profesor=Profesor(nombre="profesor_06"), cantidad=28),
    Brigada(nombre="GEO-1-A", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Geografía"), paridad=0), profesor=Profesor(nombre="profesor_05"), cantidad=25),
    Brigada(nombre="GEO-1-B", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Geografía"), paridad=0), profesor=Profesor(nombre="profesor_06"), cantidad=23),
    Brigada(nombre="MAT-2-A", anno=Anno(nombre="2do", carrera=Carrera(nombre="Matemática"), paridad=1), profesor=Profesor(nombre="profesor_07"), cantidad=34),
    Brigada(nombre="MAT-2-B", anno=Anno(nombre="2do", carrera=Carrera(nombre="Matemática"), paridad=1), profesor=Profesor(nombre="profesor_08"), cantidad=31),
    Brigada(nombre="FIS-1-A", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Física"), paridad=1), profesor=Profesor(nombre="profesor_07"), cantidad=27),
    Brigada(nombre="FIS-1-B", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Física"), paridad=1), profesor=Profesor(nombre="profesor_08"), cantidad=25),
    Brigada(nombre="FIS-2-A", anno=Anno(nombre="2do", carrera=Carrera(nombre="Física"), paridad=1), profesor=Profesor(nombre="profesor_09"), cantidad=29),
    Brigada(nombre="FIS-2-B", anno=Anno(nombre="2do", carrera=Carrera(nombre="Física"), paridad=1), profesor=Profesor(nombre="profesor_10"), cantidad=27),
    Brigada(nombre="QUI-2-A", anno=Anno(nombre="2do", carrera=Carrera(nombre="Química"), paridad=1), profesor=Profesor(nombre="profesor_11"), cantidad=22),
    Brigada(nombre="QUI-2-B", anno=Anno(nombre="2do", carrera=Carrera(nombre="Química"), paridad=1), profesor=Profesor(nombre="profesor_12"), cantidad=20),
    Brigada(nombre="BIO-1-A", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Biología"), paridad=1), profesor=Profesor(nombre="profesor_09"), cantidad=38),
    Brigada(nombre="BIO-1-B", anno=Anno(nombre="1ro", carrera=Carrera(nombre="Biología"), paridad=1), profesor=Profesor(nombre="profesor_10"), cantidad=36),
    Brigada(nombre="GEO-2-A", anno=Anno(nombre="2do", carrera=Carrera(nombre="Geografía"), paridad=1), profesor=Profesor(nombre="profesor_11"), cantidad=26),
    Brigada(nombre="GEO-2-B", anno=Anno(nombre="2do", carrera=Carrera(nombre="Geografía"), paridad=1), profesor=Profesor(nombre="profesor_12"), cantidad=24),
]

# pool de turno
LISTA_TURNO = [
    Turno(nombre="10:00", orden=1),
    Turno(nombre="11:00", orden=2),
    Turno(nombre="15:00", orden=3),
]

# pool de instalacion
LISTA_INSTALACION = [
    Instalacion(nombre="Terreno de fútbol", capacidad=60),
    Instalacion(nombre="Terreno de béisbol", capacidad=55),
    Instalacion(nombre="Pista de atletismo", capacidad=50),
    Instalacion(nombre="Gimnasio", capacidad=45),
    Instalacion(nombre="Cancha de baloncesto", capacidad=40),
    Instalacion(nombre="Cancha de voleibol", capacidad=35),
    Instalacion(nombre="Piscina", capacidad=30),
    Instalacion(nombre="Sala de pesas", capacidad=25),
]

# indisponibilidad
INDISPONIBILIDAD = [
    Indisponibilidad(anno=Anno(nombre="1ro", carrera=Carrera(nombre="Matemática"), paridad=0), turno=Turno(nombre="15:00", orden=3)),
    Indisponibilidad(anno=Anno(nombre="2do", carrera=Carrera(nombre="Matemática"), paridad=1), turno=Turno(nombre="10:00", orden=1)),
    Indisponibilidad(anno=Anno(nombre="2do", carrera=Carrera(nombre="Computación"), paridad=0), turno=Turno(nombre="11:00", orden=2)),
    Indisponibilidad(anno=Anno(nombre="2do", carrera=Carrera(nombre="Computación"), paridad=0), turno=Turno(nombre="15:00", orden=3)),
    Indisponibilidad(anno=Anno(nombre="1ro", carrera=Carrera(nombre="Física"), paridad=1), turno=Turno(nombre="11:00", orden=2)),
    Indisponibilidad(anno=Anno(nombre="1ro", carrera=Carrera(nombre="Química"), paridad=0), turno=Turno(nombre="10:00", orden=1)),
    Indisponibilidad(anno=Anno(nombre="2do", carrera=Carrera(nombre="Química"), paridad=1), turno=Turno(nombre="15:00", orden=3)),
    Indisponibilidad(anno=Anno(nombre="1ro", carrera=Carrera(nombre="Biología"), paridad=1), turno=Turno(nombre="10:00", orden=1)),
    Indisponibilidad(anno=Anno(nombre="1ro", carrera=Carrera(nombre="Biología"), paridad=1), turno=Turno(nombre="11:00", orden=2)),
    Indisponibilidad(anno=Anno(nombre="1ro", carrera=Carrera(nombre="Geografía"), paridad=0), turno=Turno(nombre="15:00", orden=3)),
    Indisponibilidad(anno=Anno(nombre="2do", carrera=Carrera(nombre="Geografía"), paridad=1), turno=Turno(nombre="10:00", orden=1)),
]

# profesor
PROFESOR = [
    Profesor(nombre="profesor_01"),
    Profesor(nombre="profesor_02"),
    Profesor(nombre="profesor_03"),
    Profesor(nombre="profesor_04"),
    Profesor(nombre="profesor_05"),
    Profesor(nombre="profesor_06"),
    Profesor(nombre="profesor_07"),
    Profesor(nombre="profesor_08"),
    Profesor(nombre="profesor_09"),
    Profesor(nombre="profesor_10"),
    Profesor(nombre="profesor_11"),
    Profesor(nombre="profesor_12"),
]

# turno
TURNO = [
    Turno(nombre="10:00", orden=1),
    Turno(nombre="11:00", orden=2),
    Turno(nombre="15:00", orden=3),
]

# instalacion
INSTALACION = [
    Instalacion(nombre="Terreno de fútbol", capacidad=60),
    Instalacion(nombre="Terreno de béisbol", capacidad=55),
    Instalacion(nombre="Pista de atletismo", capacidad=50),
    Instalacion(nombre="Gimnasio", capacidad=45),
    Instalacion(nombre="Cancha de baloncesto", capacidad=40),
    Instalacion(nombre="Cancha de voleibol", capacidad=35),
    Instalacion(nombre="Piscina", capacidad=30),
    Instalacion(nombre="Sala de pesas", capacidad=25),
]

# ============================================================
# PUNTO DE ENTRADA
# ============================================================

if __name__ == '__main__':
    mostrar_modelo()

    solucion, costo = algoritmo_genetico(BRIGADAS, LISTA_TURNO, LISTA_INSTALACION, INDISPONIBILIDAD, PROFESOR, TURNO, INSTALACION)

    print()
    mostrar_resultado(solucion)
    exportar_json(solucion, costo)
