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
class Tipo_Programa:
    codigo: object = None
    def __str__(self): return str(self.codigo)

@dataclass(unsafe_hash=True)
class Dia:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Bloque:
    dia: object = None
    orden: object = None
    def __str__(self): return f'(dia={self.dia}, orden={self.orden})'

@dataclass(unsafe_hash=True)
class Canal:
    nombre: object = None
    def __str__(self): return str(self.nombre)

@dataclass(unsafe_hash=True)
class Programa:
    nombre: object = None
    tipo: object = None
    duracion: object = None
    canal: object = None
    def __str__(self): return str(self.nombre)

@dataclass
class Emision:
    bloque: object = None
    programa: object = None

@dataclass
class Horario:
    emision: List = field(default_factory=list)
    canal: List = field(default_factory=list)



# ============================================================
# CONSULTAS
# ============================================================

def adyacentes_mismo_tipo(horario):
    count = 0
    for c in horario.canal:
        for e1 in horario.emision:
            for e2 in horario.emision:
                if ((e1.programa.canal == c) and (e2.programa.canal == c) and (e1.bloque.dia == e2.bloque.dia) and (e1.programa.tipo == e2.programa.tipo) and ((e1.bloque.orden + 1) == e2.bloque.orden)):
                    count += 1
    return count

def consecutivos_por_canal(horario, c):
    count = 0
    for e1 in horario.emision:
        for e2 in horario.emision:
            if ((e1.programa.canal == c) and (e2.programa.canal == c) and (e1.bloque.dia == e2.bloque.dia) and (e1.programa.tipo == e2.programa.tipo) and ((e1.bloque.orden + 1) == e2.bloque.orden)):
                count += 1
    return count

# ============================================================
# RESTRICCIONES SIMPLES / DURAS  (nppq / tqpq)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# SIMPLE / DURA  (nppq) — No Puede Pasar Que
def restriccion_sin_mismo_tipo_consecutivo(horario):
    return adyacentes_mismo_tipo(horario)

# ============================================================
# RESTRICCIONES DEBILES / BLANDAS  (ndpq / sbqp)
# Cada función devuelve el numero de veces que se incumple.
# ============================================================

# OPTIMIZACIÓN — Minimizar
def restriccion_minimizar_repeticion_de_tipo(horario):
    valores = [consecutivos_por_canal(horario, x) for x in horario.canal]
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
    costo += PESO_DURA   * restriccion_sin_mismo_tipo_consecutivo(horario)
    # restricciones debiles / blandas
    costo += PESO_BLANDA * restriccion_minimizar_repeticion_de_tipo(horario)
    return costo


def mostrar_modelo():
    """Imprime el modelo abstracto de optimizacion."""
    sep = '=' * 60
    print(sep)
    print('MODELO DE OPTIMIZACION')
    print(sep)
    print()
    print('INDICES Y CONJUNTOS:')
    print(f'  B  =  conjunto de bloques      (|B| = {len(BLOQUES)})')
    print(f'  P  =  conjunto de programa disponibles   (|P| = {len(LISTA_PROGRAMA)})')
    print(f'  C  =  conjunto de canal   (|C| = {len(CANAL)})')
    print()
    print('VARIABLES DE DECISION:')
    print('  Para cada bloque t ∈ B se asigna:')
    print('    programa_t ∈ P   (programa)')
    print()
    print('FUNCION OBJETIVO:')
    print('  minimizar z(h) donde:')
    print('    z(h) = 1000 · Σ_i incumpl_i(h)   [duras]')
    print('         + 1 · Σ_j incumpl_j(h)   [blandas]')
    print()
    print('RESTRICCIONES DURAS  (nppq / tqpq):')
    print('  R1  [SIMPLE / DURA  (nppq) — No Puede Pasar Que]:')
    print('    adyacentes_mismo_tipo(h) = 0')
    print('    donde:')
    print('      adyacentes_mismo_tipo(h) = Σ_{c∈CANAL, e1∈EMISION, e2∈EMISION}  [((canal(programa(e1)) = c) ∧ (canal(programa(e2)) = c) ∧ (dia(bloque(e1)) = dia(bloque(e2))) ∧ (tipo(programa(e1)) = tipo(programa(e2))) ∧ ((orden(bloque(e1)) + 1) = orden(bloque(e2))))]')
    print()
    print()
    print('RESTRICCIONES BLANDAS  (tdpq / sbqp / minimizar):')
    print('  R2  [OPTIMIZACIÓN — Minimizar]:')
    print('    minimizar  max_{{x ∈ CANAL}}  consecutivos_por_canal(h, x)')
    print('    donde:')
    print('      consecutivos_por_canal(h, c) = Σ_{e1∈EMISION, e2∈EMISION}  [((canal(programa(e1)) = c) ∧ (canal(programa(e2)) = c) ∧ (dia(bloque(e1)) = dia(bloque(e2))) ∧ (tipo(programa(e1)) = tipo(programa(e2))) ∧ ((orden(bloque(e1)) + 1) = orden(bloque(e2))))]')
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
    for i, asig in enumerate(horario.emision, 1):
        print(f'  Defensa {i}:')
        print(f'    BLOQUE : {asig.bloque}')
        print(f'    PROGRAMA : {asig.programa}')
        print()
    print(sep)
    print('EVALUACION DE RESTRICCIONES')
    print(sep)
    costo_total = 0
    print('Restricciones simples / duras  (peso 1000):')
    v = restriccion_sin_mismo_tipo_consecutivo(horario)
    costo_total += PESO_DURA * v
    print(f'  restriccion_sin_mismo_tipo_consecutivo: {v} incumplimientos  ->  costo: {PESO_DURA * v}')
    print('Restricciones debiles / blandas  (peso 1):')
    v = restriccion_minimizar_repeticion_de_tipo(horario)
    costo_total += PESO_BLANDA * v
    print(f'  restriccion_minimizar_repeticion_de_tipo: {v}  ->  costo: {PESO_BLANDA * v}')
    print(f'Costo total: {costo_total}')
    print(sep)


def _ent_a_dict(x):
    """Convierte entidad a dict JSON-serializable."""
    if x is None: return None
    if isinstance(x, (str, int, float, bool)): return x
    if hasattr(x, 'nombre'): return str(x)
    if hasattr(x, 'id'): return str(x)
    return {campo: _ent_a_dict(getattr(x, campo)) for campo in vars(x)}


def exportar_json(solucion, costo_total, archivo="tv/horario.json"):
    """Exporta el modelo matematico y el horario propuesto a JSON."""
    import json
    datos = {
        'modelo': {
            'conjuntos': {
                'B': len(BLOQUES),
                'P': len(LISTA_PROGRAMA),
                'C': len(CANAL),
            },
            'peso_dura': 1000,
            'peso_blanda': 1,
            'restricciones_duras': ['restriccion_sin_mismo_tipo_consecutivo'],
            'restricciones_blandas': ['restriccion_minimizar_repeticion_de_tipo'],
        },
        'horario': [_ent_a_dict(asig) for asig in solucion.emision],
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

def crear_horario_aleatorio(bloques, lista_programa, canal):
    """Crea un horario asignando recursos aleatorios a cada bloque."""
    h = Horario()
    h.canal = list(canal)
    for ident in bloques:
        h.emision.append(Emision(
            bloque=ident,
            programa=random.choice(lista_programa),
        ))
    return h

def crear_poblacion(bloques, lista_programa, canal, tamanio=POP_SIZE):
    return [crear_horario_aleatorio(bloques, lista_programa, canal) for _ in range(tamanio)]

def seleccion_torneo(poblacion, k=TORNEO_K):
    """Devuelve el mejor de k individuos elegidos al azar."""
    candidatos = random.sample(poblacion, min(k, len(poblacion)))
    return min(candidatos, key=evaluar)

def cruce(p1, p2):
    """Cruce de un punto: intercambia recursos (programa) tras el corte."""
    n = len(p1.emision)
    if n < 2:
        return copy.deepcopy(p1), copy.deepcopy(p2)
    corte = random.randint(1, n - 1)
    h1 = copy.deepcopy(p1)
    h2 = copy.deepcopy(p2)
    for i in range(corte, n):
        h1.emision[i].programa, h2.emision[i].programa = h2.emision[i].programa, h1.emision[i].programa
    return h1, h2

def mutar(individuo, lista_programa, prob=PROB_MUTACION):
    """Reasigna aleatoriamente un recurso de un bloque al azar."""
    if random.random() >= prob:
        return individuo
    nuevo = copy.deepcopy(individuo)
    items = nuevo.emision
    if not items:
        return nuevo
    item  = random.choice(items)
    campo = random.choice(["programa"])
    if campo == "programa": item.programa = random.choice(lista_programa)
    return nuevo

def algoritmo_genetico(bloques, lista_programa, canal,
                       tamanio_pob=POP_SIZE,
                       generaciones=GENERACIONES):
    """
    Genera y optimiza un horario que minimiza las restricciones
    incumplidas. Devuelve (mejor_horario, costo_final).
    """
    poblacion   = crear_poblacion(bloques, lista_programa, canal, tamanio_pob)
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
            nueva_pob.append(mutar(h1, lista_programa))
            if len(nueva_pob) < tamanio_pob:
                nueva_pob.append(mutar(h2, lista_programa))
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

# bloques
BLOQUES = [
    Bloque(dia=Dia(nombre="Lunes"), orden=1),
    Bloque(dia=Dia(nombre="Lunes"), orden=2),
    Bloque(dia=Dia(nombre="Lunes"), orden=3),
    Bloque(dia=Dia(nombre="Lunes"), orden=4),
    Bloque(dia=Dia(nombre="Lunes"), orden=5),
    Bloque(dia=Dia(nombre="Lunes"), orden=6),
    Bloque(dia=Dia(nombre="Lunes"), orden=7),
    Bloque(dia=Dia(nombre="Lunes"), orden=8),
    Bloque(dia=Dia(nombre="Martes"), orden=1),
    Bloque(dia=Dia(nombre="Martes"), orden=2),
    Bloque(dia=Dia(nombre="Martes"), orden=3),
    Bloque(dia=Dia(nombre="Martes"), orden=4),
    Bloque(dia=Dia(nombre="Martes"), orden=5),
    Bloque(dia=Dia(nombre="Martes"), orden=6),
    Bloque(dia=Dia(nombre="Martes"), orden=7),
    Bloque(dia=Dia(nombre="Martes"), orden=8),
    Bloque(dia=Dia(nombre="Miercoles"), orden=1),
    Bloque(dia=Dia(nombre="Miercoles"), orden=2),
    Bloque(dia=Dia(nombre="Miercoles"), orden=3),
    Bloque(dia=Dia(nombre="Miercoles"), orden=4),
    Bloque(dia=Dia(nombre="Miercoles"), orden=5),
    Bloque(dia=Dia(nombre="Miercoles"), orden=6),
    Bloque(dia=Dia(nombre="Miercoles"), orden=7),
    Bloque(dia=Dia(nombre="Miercoles"), orden=8),
    Bloque(dia=Dia(nombre="Jueves"), orden=1),
    Bloque(dia=Dia(nombre="Jueves"), orden=2),
    Bloque(dia=Dia(nombre="Jueves"), orden=3),
    Bloque(dia=Dia(nombre="Jueves"), orden=4),
    Bloque(dia=Dia(nombre="Jueves"), orden=5),
    Bloque(dia=Dia(nombre="Jueves"), orden=6),
    Bloque(dia=Dia(nombre="Jueves"), orden=7),
    Bloque(dia=Dia(nombre="Jueves"), orden=8),
    Bloque(dia=Dia(nombre="Viernes"), orden=1),
    Bloque(dia=Dia(nombre="Viernes"), orden=2),
    Bloque(dia=Dia(nombre="Viernes"), orden=3),
    Bloque(dia=Dia(nombre="Viernes"), orden=4),
    Bloque(dia=Dia(nombre="Viernes"), orden=5),
    Bloque(dia=Dia(nombre="Viernes"), orden=6),
    Bloque(dia=Dia(nombre="Viernes"), orden=7),
    Bloque(dia=Dia(nombre="Viernes"), orden=8),
    Bloque(dia=Dia(nombre="Sabado"), orden=1),
    Bloque(dia=Dia(nombre="Sabado"), orden=2),
    Bloque(dia=Dia(nombre="Sabado"), orden=3),
    Bloque(dia=Dia(nombre="Sabado"), orden=4),
    Bloque(dia=Dia(nombre="Sabado"), orden=5),
    Bloque(dia=Dia(nombre="Sabado"), orden=6),
    Bloque(dia=Dia(nombre="Sabado"), orden=7),
    Bloque(dia=Dia(nombre="Sabado"), orden=8),
    Bloque(dia=Dia(nombre="Domingo"), orden=1),
    Bloque(dia=Dia(nombre="Domingo"), orden=2),
    Bloque(dia=Dia(nombre="Domingo"), orden=3),
    Bloque(dia=Dia(nombre="Domingo"), orden=4),
    Bloque(dia=Dia(nombre="Domingo"), orden=5),
    Bloque(dia=Dia(nombre="Domingo"), orden=6),
    Bloque(dia=Dia(nombre="Domingo"), orden=7),
    Bloque(dia=Dia(nombre="Domingo"), orden=8),
]

# pool de programa
LISTA_PROGRAMA = [
    Programa(nombre="El Tiempo y la Memoria", tipo=Tipo_Programa(codigo="informativo"), duracion=5, canal=Canal(nombre="Canal Habana")),
    Programa(nombre="Coordenadas", tipo=Tipo_Programa(codigo="informativo"), duracion=5, canal=Canal(nombre="Canal Habana")),
    Programa(nombre="Revista Hola Habana", tipo=Tipo_Programa(codigo="revista"), duracion=50, canal=Canal(nombre="Canal Habana")),
    Programa(nombre="Decadas Milagrosas", tipo=Tipo_Programa(codigo="musical"), duracion=30, canal=Canal(nombre="Canal Habana")),
    Programa(nombre="Habana Noticiario", tipo=Tipo_Programa(codigo="informativo"), duracion=30, canal=Canal(nombre="Canal Habana")),
    Programa(nombre="Power Rangers", tipo=Tipo_Programa(codigo="infantil"), duracion=30, canal=Canal(nombre="Canal Habana")),
    Programa(nombre="Cine+", tipo=Tipo_Programa(codigo="cine"), duracion=90, canal=Canal(nombre="Canal Habana")),
    Programa(nombre="Deporte Total", tipo=Tipo_Programa(codigo="deportes"), duracion=30, canal=Canal(nombre="Canal Habana")),
]

# canal
CANAL = [
    Canal(nombre="Canal Habana"),
]

# ============================================================
# PUNTO DE ENTRADA
# ============================================================

if __name__ == '__main__':
    mostrar_modelo()

    solucion, costo = algoritmo_genetico(BLOQUES, LISTA_PROGRAMA, CANAL)

    print()
    mostrar_resultado(solucion)
    exportar_json(solucion, costo)
