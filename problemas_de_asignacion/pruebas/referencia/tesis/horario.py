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
class Grado:
    id: object = None
    def __str__(self): return str(self.id)

@dataclass(unsafe_hash=True)
class Profesor:
    nombre: object = None
    grado: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Estudiante:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Tribunal:
    estudiante: object = None
    tutor: object = None
    oponente: object = None
    presidente: object = None
    vocal: object = None
    secretario: object = None
    def __str__(self): return f'(estudiante={self.estudiante}, tutor={self.tutor}, oponente={self.oponente}, presidente={self.presidente}, vocal={self.vocal}, secretario={self.secretario})'

@dataclass(unsafe_hash=True)
class Fecha:
    dia: object = None
    mes: object = None
    def __str__(self): return f'(dia={self.dia}, mes={self.mes})'

@dataclass(unsafe_hash=True)
class Momento:
    hora: object = None
    def __str__(self): return str(self.hora)

@dataclass(unsafe_hash=True)
class Local:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass
class Asignacion:
    tribunal: object = None
    fecha: object = None
    momento: object = None
    local: object = None

@dataclass
class Horario:
    asignacion: List = field(default_factory=list)
    profesor: List = field(default_factory=list)



# ============================================================
# CONSULTAS
# ============================================================

def conflictos_de_horario(horario):
    count = 0
    for p in horario.profesor:
        for a1 in horario.asignacion:
            for a2 in horario.asignacion:
                if (((a1.tribunal.tutor == p) or (a1.tribunal.oponente == p) or (a1.tribunal.presidente == p) or (a1.tribunal.vocal == p) or (a1.tribunal.secretario == p)) and ((a2.tribunal.tutor == p) or (a2.tribunal.oponente == p) or (a2.tribunal.presidente == p) or (a2.tribunal.vocal == p) or (a2.tribunal.secretario == p)) and (a1.fecha == a2.fecha) and (a1.momento == a2.momento) and (a1.tribunal != a2.tribunal)):
                    count += 1
    return count

def colisiones_de_local(horario):
    count = 0
    for a1 in horario.asignacion:
        for a2 in horario.asignacion:
            if ((a1.local == a2.local) and (a1.fecha == a2.fecha) and (a1.momento == a2.momento) and (a1.tribunal != a2.tribunal)):
                count += 1
    return count

def dias_asistidos(horario, prof):
    dias = set()
    for asig in horario.asignacion:
        if ((asig.tribunal.tutor == prof) or (asig.tribunal.oponente == prof) or (asig.tribunal.presidente == prof) or (asig.tribunal.vocal == prof) or (asig.tribunal.secretario == prof)):
            dias.add(getattr(asig, 'fecha', None) or getattr(asig, 'dia', None))
    return len(dias)

# ============================================================
# RESTRICCIONES SIMPLES / DURAS  (nppq / tqpq)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_sin_conflictos_de_horario(horario):
    return conflictos_de_horario(horario)

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_un_local_por_defensa(horario):
    return colisiones_de_local(horario)

# ============================================================
# RESTRICCIONES DEBILES / BLANDAS  (ndpq / sbqp)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# OPTIMIZACIÓN — Minimizar
def restriccion_minimizar_carga_maxima(horario):
    valores = [dias_asistidos(horario, x) for x in horario.profesor]
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
    costo += PESO_DURA   * restriccion_sin_conflictos_de_horario(horario)
    costo += PESO_DURA   * restriccion_un_local_por_defensa(horario)
    # restricciones debiles / blandas
    costo += PESO_BLANDA * restriccion_minimizar_carga_maxima(horario)
    return costo


def mostrar_modelo():
    """Imprime el modelo abstracto de optimizacion."""
    sep = '=' * 60
    print(sep)
    print('MODELO DE OPTIMIZACION')
    print(sep)
    print()
    print('INDICES Y CONJUNTOS:')
    print(f'  T  =  conjunto de tribunals      (|T| = {len(TRIBUNALS)})')
    print(f'  F  =  conjunto de fecha disponibles   (|F| = {len(LISTA_FECHA)})')
    print(f'  M  =  conjunto de momento disponibles   (|M| = {len(LISTA_MOMENTO)})')
    print(f'  L  =  conjunto de local disponibles   (|L| = {len(LISTA_LOCAL)})')
    print(f'  P  =  conjunto de profesor   (|P| = {len(PROFESOR)})')
    print()
    print('VARIABLES DE DECISION:')
    print('  Para cada tribunal t ∈ T se asigna:')
    print('    fecha_t ∈ F   (fecha)')
    print('    momento_t ∈ M   (momento)')
    print('    local_t ∈ L   (local)')
    print()
    print('FUNCION OBJETIVO:')
    print('  minimizar z(h) donde:')
    print('    z(h) = 1000 · Σ_i incumpl_i(h)   [duras]')
    print('         + 1 · Σ_j incumpl_j(h)   [blandas]')
    print()
    print('RESTRICCIONES DURAS  (nppq / tqpq):')
    print('  R1  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    conflictos_de_horario(h) = 0')
    print('    donde:')
    print('      conflictos_de_horario(h) = Σ_{p∈PROFESOR, a1∈ASIGNACION, a2∈ASIGNACION}  [(((tutor(tribunal(a1)) = p) ∨ (oponente(tribunal(a1)) = p) ∨ (presidente(tribunal(a1)) = p) ∨ (vocal(tribunal(a1)) = p) ∨ (secretario(tribunal(a1)) = p)) ∧ ((tutor(tribunal(a2)) = p) ∨ (oponente(tribunal(a2)) = p) ∨ (presidente(tribunal(a2)) = p) ∨ (vocal(tribunal(a2)) = p) ∨ (secretario(tribunal(a2)) = p)) ∧ (fecha(a1) = fecha(a2)) ∧ (momento(a1) = momento(a2)) ∧ (tribunal(a1) ≠ tribunal(a2)))]')
    print()
    print('  R2  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    colisiones_de_local(h) = 0')
    print('    donde:')
    print('      colisiones_de_local(h) = Σ_{a1∈ASIGNACION, a2∈ASIGNACION}  [((local(a1) = local(a2)) ∧ (fecha(a1) = fecha(a2)) ∧ (momento(a1) = momento(a2)) ∧ (tribunal(a1) ≠ tribunal(a2)))]')
    print()
    print()
    print('RESTRICCIONES BLANDAS  (tdpq / sbqp / minimizar):')
    print('  R3  [OPTIMIZACIÓN — Minimizar]:')
    print('    minimizar  max_{{x ∈ PROFESOR}}  dias_asistidos(h, x)')
    print('    donde:')
    print('      dias_asistidos(h, prof) = |{ fecha(asig) : asig∈ASIGNACION,  ((tutor(tribunal(asig)) = prof) ∨ (oponente(tribunal(asig)) = prof) ∨ (presidente(tribunal(asig)) = prof) ∨ (vocal(tribunal(asig)) = prof) ∨ (secretario(tribunal(asig)) = prof)) }|')
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
    for i, asig in enumerate(horario.asignacion, 1):
        print(f'  Defensa {i}:')
        print(f'    TRIBUNAL : {asig.tribunal}')
        print(f'    FECHA : {asig.fecha}')
        print(f'    MOMENTO : {asig.momento}')
        print(f'    LOCAL : {asig.local}')
        print()
    print(sep)
    print('EVALUACION DE RESTRICCIONES')
    print(sep)
    costo_total = 0
    print('Restricciones simples / duras  (peso 1000):')
    v = restriccion_sin_conflictos_de_horario(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_sin_conflictos_de_horario: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    v = restriccion_un_local_por_defensa(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_un_local_por_defensa: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    print('Restricciones debiles / blandas  (peso 1):')
    v = restriccion_minimizar_carga_maxima(horario)
    costo_total += PESO_BLANDA * v
    print(f'  restriccion_minimizar_carga_maxima: {v}  ->  costo: {PESO_BLANDA * v}')
    print(f'Costo total: {costo_total}')
    print(sep)


def _ent_a_dict(x):
    """Convierte entidad a dict JSON-serializable."""
    if x is None: return None
    if isinstance(x, (str, int, float, bool)): return x
    if hasattr(x, 'nombre'): return str(x)
    if hasattr(x, 'id'): return str(x)
    return {campo: _ent_a_dict(getattr(x, campo)) for campo in vars(x)}


def exportar_json(solucion, costo_total, archivo="tesis/horario.json"):
    """Exporta el modelo matematico y el horario propuesto a JSON."""
    import json
    datos = {
        'modelo': {
            'conjuntos': {
                'T': len(TRIBUNALS),
                'F': len(LISTA_FECHA),
                'M': len(LISTA_MOMENTO),
                'L': len(LISTA_LOCAL),
                'P': len(PROFESOR),
            },
            'peso_dura': 1000,
            'peso_blanda': 1,
            'restricciones_duras': ['restriccion_sin_conflictos_de_horario', 'restriccion_un_local_por_defensa'],
            'restricciones_blandas': ['restriccion_minimizar_carga_maxima'],
        },
        'horario': [_ent_a_dict(asig) for asig in solucion.asignacion],
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

def crear_horario_aleatorio(tribunals, lista_fecha, lista_momento, lista_local, profesor):
    """Crea un horario asignando recursos aleatorios a cada tribunal."""
    h = Horario()
    h.profesor = list(profesor)
    for ident in tribunals:
        h.asignacion.append(Asignacion(
            tribunal=ident,
            fecha=random.choice(lista_fecha),
            momento=random.choice(lista_momento),
            local=random.choice(lista_local),
        ))
    return h

def crear_poblacion(tribunals, lista_fecha, lista_momento, lista_local, profesor, tamanio=POP_SIZE):
    return [crear_horario_aleatorio(tribunals, lista_fecha, lista_momento, lista_local, profesor) for _ in range(tamanio)]

def seleccion_torneo(poblacion, k=TORNEO_K):
    """Devuelve el mejor de k individuos elegidos al azar."""
    candidatos = random.sample(poblacion, min(k, len(poblacion)))
    return min(candidatos, key=evaluar)

def cruce(p1, p2):
    """Cruce de un punto: intercambia recursos (fecha, momento, local) tras el corte."""
    n = len(p1.asignacion)
    if n < 2:
        return copy.deepcopy(p1), copy.deepcopy(p2)
    corte = random.randint(1, n - 1)
    h1 = copy.deepcopy(p1)
    h2 = copy.deepcopy(p2)
    for i in range(corte, n):
        h1.asignacion[i].fecha, h2.asignacion[i].fecha = h2.asignacion[i].fecha, h1.asignacion[i].fecha
        h1.asignacion[i].momento, h2.asignacion[i].momento = h2.asignacion[i].momento, h1.asignacion[i].momento
        h1.asignacion[i].local, h2.asignacion[i].local = h2.asignacion[i].local, h1.asignacion[i].local
    return h1, h2

def mutar(individuo, lista_fecha, lista_momento, lista_local, prob=PROB_MUTACION):
    """Reasigna aleatoriamente un recurso de un tribunal al azar."""
    if random.random() >= prob:
        return individuo
    nuevo = copy.deepcopy(individuo)
    items = nuevo.asignacion
    if not items:
        return nuevo
    item  = random.choice(items)
    campo = random.choice(["fecha", "momento", "local"])
    if campo == "fecha": item.fecha = random.choice(lista_fecha)
    if campo == "momento": item.momento = random.choice(lista_momento)
    if campo == "local": item.local = random.choice(lista_local)
    return nuevo

def algoritmo_genetico(tribunals, lista_fecha, lista_momento, lista_local, profesor,
                       tamanio_pob=POP_SIZE,
                       generaciones=GENERACIONES):
    """
    Genera y optimiza un horario que minimiza las restricciones
    incumplidas. Devuelve (mejor_horario, costo_final).
    """
    poblacion   = crear_poblacion(tribunals, lista_fecha, lista_momento, lista_local, profesor, tamanio_pob)
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
            nueva_pob.append(mutar(h1, lista_fecha, lista_momento, lista_local))
            if len(nueva_pob) < tamanio_pob:
                nueva_pob.append(mutar(h2, lista_fecha, lista_momento, lista_local))
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

# tribunals
TRIBUNALS = [
    Tribunal(estudiante=Estudiante(nombre="Angel Daniel Alonso Guevara"), tutor=Profesor(nombre="Carmen T. Fernandez Montoto", grado=Grado(id="MSc")), oponente=Profesor(nombre="Aracelys Garcia Armenteros", grado=Grado(id="MSc")), presidente=Profesor(nombre="Alberto Fernandez Oliva", grado=Grado(id="Dr")), vocal=Profesor(nombre="Dennis Daniel Gonzalez Duran", grado=Grado(id="Lic")), secretario=Profesor(nombre="Alejandro Labourdette-Lantigua Soto", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Adrian Hernandez Castellanos"), tutor=Profesor(nombre="Alejandra Monzon Pena", grado=Grado(id="Lic")), oponente=Profesor(nombre="Rodrigo Garcia Gomez", grado=Grado(id="Lic")), presidente=Profesor(nombre="Amanada Noris Hernandez", grado=Grado(id="Lic")), vocal=Profesor(nombre="Daniel Abad Fundora", grado=Grado(id="Lic")), secretario=Profesor(nombre="Kevin Manzano Rodriguez", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Laura Martir Beltran"), tutor=Profesor(nombre="Alejandra Monzon Pena", grado=Grado(id="Lic")), oponente=Profesor(nombre="Rodrigo Garcia Gomez", grado=Grado(id="Lic")), presidente=Profesor(nombre="Amanada Noris Hernandez", grado=Grado(id="Lic")), vocal=Profesor(nombre="Daniel Abad Fundora", grado=Grado(id="Lic")), secretario=Profesor(nombre="Kevin Manzano Rodriguez", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Noel Perez Calvo"), tutor=Profesor(nombre="Fernando Raul Rodriguez Flores", grado=Grado(id="MSc")), oponente=Profesor(nombre="David Guaty Dominguez", grado=Grado(id="Lic")), presidente=Profesor(nombre="Rodrigo Garcia Gomez", grado=Grado(id="Lic")), vocal=Profesor(nombre="Alejandra Monzon Pena", grado=Grado(id="Lic")), secretario=Profesor(nombre="Lazaro Daniel Gonzalez Martinez", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Claudia Hernandez Perez y Joel Aparicio Tamayo"), tutor=Profesor(nombre="Celia T. Gonzalez Gonzales", grado=Grado(id="MSc")), oponente=Profesor(nombre="Alejandro Beltran Varela", grado=Grado(id="Lic")), presidente=Profesor(nombre="Ayme Marrero Severo", grado=Grado(id="Dra")), vocal=Profesor(nombre="Daniel Alejandro Valdes Perez", grado=Grado(id="Lic")), secretario=Profesor(nombre="Joanna Campbell Amos", grado=Grado(id="MSc"))),
    Tribunal(estudiante=Estudiante(nombre="Dario Hernandez Cubilla"), tutor=Profesor(nombre="Aracelys Garcia Armenteros", grado=Grado(id="MSc")), oponente=Profesor(nombre="Alejandro Labourdette-Lantigua Soto", grado=Grado(id="Lic")), presidente=Profesor(nombre="Ayme Marrero Severo", grado=Grado(id="Dra")), vocal=Profesor(nombre="Alejandro Beltran Varela", grado=Grado(id="Lic")), secretario=Profesor(nombre="Roberto Marti Cedeno", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Richard Alejandro Matos Arderi"), tutor=Profesor(nombre="Celia T. Gonzalez Gonzales", grado=Grado(id="MSc")), oponente=Profesor(nombre="Aracelys Garcia Armenteros", grado=Grado(id="MSc")), presidente=Profesor(nombre="Wilfredo Morales Lezca", grado=Grado(id="MSc")), vocal=Profesor(nombre="Alejandro Beltran Varela", grado=Grado(id="Lic")), secretario=Profesor(nombre="Roberto Marti Cedeno", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Melani Forsythe Matos"), tutor=Profesor(nombre="Marta Lourdes Baguer Diaz-Romanach", grado=Grado(id="DraC")), oponente=Profesor(nombre="Javier Rodriguez Sanchez", grado=Grado(id="Lic")), presidente=Profesor(nombre="Alejandro Sanchez Castellanos", grado=Grado(id="DrC")), vocal=Profesor(nombre="Dennis Daniel Gonzalez Duran", grado=Grado(id="Lic")), secretario=Profesor(nombre="Ana Paula Gonzalez Munoz", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Mauro Eduardo Campver Barrios"), tutor=Profesor(nombre="Marta Lourdes Baguer Diaz-Romanach", grado=Grado(id="DraC")), oponente=Profesor(nombre="Fernando Raul Rodriguez Flores", grado=Grado(id="MSc")), presidente=Profesor(nombre="Alejandro Piad Morfis", grado=Grado(id="DrC")), vocal=Profesor(nombre="Dennis Daniel Gonzalez Duran", grado=Grado(id="Lic")), secretario=Profesor(nombre="Ana Paula Gonzalez Munoz", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Jose Miguel Leyva De La Cruz"), tutor=Profesor(nombre="Alejandro Beltran Varela", grado=Grado(id="Lic")), oponente=Profesor(nombre="Aracelys Garcia Armenteros", grado=Grado(id="MSc")), presidente=Profesor(nombre="Amanada Noris Hernandez", grado=Grado(id="Lic")), vocal=Profesor(nombre="Gabriel Fundora", grado=Grado(id="Dr")), secretario=Profesor(nombre="Juan Miguel Perez Martinez", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Jossue Arteche Munoz"), tutor=Profesor(nombre="Fernando Raul Rodriguez Flores", grado=Grado(id="MSc")), oponente=Profesor(nombre="Ariel Gonzalez Gomez", grado=Grado(id="Lic")), presidente=Profesor(nombre="Alejandro Piad Morfis", grado=Grado(id="DrC")), vocal=Profesor(nombre="Daniel Abad Fundora", grado=Grado(id="Lic")), secretario=Profesor(nombre="Rodrigo Garcia Gomez", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Amalia Beatriz Valiente Hinojosa"), tutor=Profesor(nombre="Fernando Raul Rodriguez Flores", grado=Grado(id="MSc")), oponente=Profesor(nombre="Alejandra Monzon Pena", grado=Grado(id="Lic")), presidente=Profesor(nombre="Javier Rodriguez Sanchez", grado=Grado(id="Lic")), vocal=Profesor(nombre="Merling Sabater Ramirez", grado=Grado(id="Lic")), secretario=Profesor(nombre="Rocio Ortiz Gancedo", grado=Grado(id="Lic"))),
    Tribunal(estudiante=Estudiante(nombre="Luis Ernesto Amat Cardenas"), tutor=Profesor(nombre="Roberto Marti Cedeno", grado=Grado(id="Lic")), oponente=Profesor(nombre="Daniel Toledo Martinez", grado=Grado(id="Lic")), presidente=Profesor(nombre="Alejandro Piad Morfis", grado=Grado(id="DrC")), vocal=Profesor(nombre="Alejandro Labourdette-Lantigua Soto", grado=Grado(id="Lic")), secretario=Profesor(nombre="Carlos David Muniz Chall", grado=Grado(id="Lic"))),
]

# pool de fecha
LISTA_FECHA = [
    Fecha(dia=5, mes=6),
    Fecha(dia=8, mes=6),
    Fecha(dia=10, mes=6),
]

# pool de momento
LISTA_MOMENTO = [
    Momento(hora=930),
    Momento(hora=1000),
    Momento(hora=1030),
    Momento(hora=1130),
    Momento(hora=1200),
    Momento(hora=1230),
    Momento(hora=1330),
]

# pool de local
LISTA_LOCAL = [
    Local(nombre="Postgrado"),
    Local(nombre="Salon decanato"),
    Local(nombre="Francofonia"),
    Local(nombre="Francofomia"),
]

# profesor
PROFESOR = [
    Profesor(nombre="Carmen T. Fernandez Montoto", grado=Grado(id="MSc")),
    Profesor(nombre="Alberto Fernandez Oliva", grado=Grado(id="Dr")),
    Profesor(nombre="Alejandro Labourdette-Lantigua Soto", grado=Grado(id="Lic")),
    Profesor(nombre="Dennis Daniel Gonzalez Duran", grado=Grado(id="Lic")),
    Profesor(nombre="Aracelys Garcia Armenteros", grado=Grado(id="MSc")),
    Profesor(nombre="Alejandra Monzon Pena", grado=Grado(id="Lic")),
    Profesor(nombre="Fernando Raul Rodriguez Flores", grado=Grado(id="MSc")),
    Profesor(nombre="Amanada Noris Hernandez", grado=Grado(id="Lic")),
    Profesor(nombre="Kevin Manzano Rodriguez", grado=Grado(id="Lic")),
    Profesor(nombre="Daniel Abad Fundora", grado=Grado(id="Lic")),
    Profesor(nombre="Rodrigo Garcia Gomez", grado=Grado(id="Lic")),
    Profesor(nombre="Lazaro Daniel Gonzalez Martinez", grado=Grado(id="Lic")),
    Profesor(nombre="David Guaty Dominguez", grado=Grado(id="Lic")),
    Profesor(nombre="Celia T. Gonzalez Gonzales", grado=Grado(id="MSc")),
    Profesor(nombre="Wilfredo Morales Lezca", grado=Grado(id="MSc")),
    Profesor(nombre="Ayme Marrero Severo", grado=Grado(id="Dra")),
    Profesor(nombre="Joanna Campbell Amos", grado=Grado(id="MSc")),
    Profesor(nombre="Daniel Alejandro Valdes Perez", grado=Grado(id="Lic")),
    Profesor(nombre="Alejandro Beltran Varela", grado=Grado(id="Lic")),
    Profesor(nombre="Roberto Marti Cedeno", grado=Grado(id="Lic")),
    Profesor(nombre="Marta Lourdes Baguer Diaz-Romanach", grado=Grado(id="DraC")),
    Profesor(nombre="Lydia Amalia Castro Odio", grado=Grado(id="DraC")),
    Profesor(nombre="Alejandro Sanchez Castellanos", grado=Grado(id="DrC")),
    Profesor(nombre="Ana Paula Gonzalez Munoz", grado=Grado(id="Lic")),
    Profesor(nombre="Alejandro Piad Morfis", grado=Grado(id="DrC")),
    Profesor(nombre="Madeylis Maria Perez Acosta", grado=Grado(id="MSc")),
    Profesor(nombre="Juan Miguel Perez Martinez", grado=Grado(id="Lic")),
    Profesor(nombre="Gabriel Fundora", grado=Grado(id="Dr")),
    Profesor(nombre="Ariel Gonzalez Gomez", grado=Grado(id="Lic")),
    Profesor(nombre="Rocio Ortiz Gancedo", grado=Grado(id="Lic")),
    Profesor(nombre="Merling Sabater Ramirez", grado=Grado(id="Lic")),
    Profesor(nombre="Carlos David Muniz Chall", grado=Grado(id="Lic")),
    Profesor(nombre="Daniel Toledo Martinez", grado=Grado(id="Lic")),
    Profesor(nombre="Javier Rodriguez Sanchez", grado=Grado(id="Lic")),
    Profesor(nombre="Gabriel Hernandez Rodriguez", grado=Grado(id="Lic")),
]

# ============================================================
# PUNTO DE ENTRADA
# ============================================================

if __name__ == '__main__':
    mostrar_modelo()

    solucion, costo = algoritmo_genetico(TRIBUNALS, LISTA_FECHA, LISTA_MOMENTO, LISTA_LOCAL, PROFESOR)

    print()
    mostrar_resultado(solucion)
    exportar_json(solucion, costo)
