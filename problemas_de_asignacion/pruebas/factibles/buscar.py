"""Busca un horario sin incumplimientos duros, con las funciones viejas.

Uso, desde esta carpeta:   python buscar.py tesis tv seder

Búsqueda local de mínimos conflictos: elige una fila al azar y le da la
combinación de valores que menos duras incumple; con probabilidad RUIDO, una al
azar, para salir de los óptimos locales. Evalúa con las propias funciones
generadas, así que lo que encuentra es factible para el sistema viejo.

Escribe factibles/<dominio>.json con el horario en índices, como valores.json.
Docentes y Saúl no se ejecutan.
"""
import itertools
import json
import random
import sys
import time
from pathlib import Path

AQUI = Path(__file__).resolve().parent
sys.path.insert(0, str(AQUI.parent))
from referencia.sistema_viejo import HorarioViejo  # noqa: E402

SEMILLA = 0
RUIDO = 0.1
LIMITE_SEGUNDOS = 300


def asignar(fila, variables, valores):
    for v, x in zip(variables, valores):
        setattr(fila, v, x)


def buscar(dominio):
    viejo = HorarioViejo(dominio)
    azar = random.Random(SEMILLA)
    horario = viejo.aleatorio(SEMILLA)
    filas = viejo.filas(horario)
    opciones = list(itertools.product(*viejo.listas))

    inicio, pasos = time.time(), 0
    duras = viejo.duras(horario)
    while duras > 0 and time.time() - inicio < LIMITE_SEGUNDOS:
        fila = azar.choice(filas)
        if azar.random() < RUIDO:
            elegida = azar.choice(opciones)
        else:
            mejores, mejor = [], None
            for opcion in opciones:
                asignar(fila, viejo.variables, opcion)
                costo = viejo.duras(horario)
                if mejor is None or costo < mejor:
                    mejores, mejor = [opcion], costo
                elif costo == mejor:
                    mejores.append(opcion)
            elegida = azar.choice(mejores)
        asignar(fila, viejo.variables, elegida)
        duras = viejo.duras(horario)
        pasos += 1

    segundos = round(time.time() - inicio, 1)
    if duras > 0:
        print(f'{dominio}: sin factible en {segundos} s ({pasos} pasos); quedan {duras} duras')
        return

    # Comprobación independiente: reconstruir desde los índices y volver a evaluar.
    indices = viejo.a_indices(horario)
    reconstruido = viejo.desde_indices(indices)
    assert viejo.duras(reconstruido) == 0, f'{dominio}: la reconstrucción no es factible'

    datos = {'dominio': dominio, 'semilla': SEMILLA, 'pasos': pasos, 'segundos': segundos,
             'filas': indices, 'valores': viejo.valores(reconstruido)}
    (AQUI / f'{dominio}.json').write_text(json.dumps(datos, ensure_ascii=False, indent=1),
                                          encoding='utf-8')
    print(f'{dominio}: factible en {segundos} s ({pasos} pasos), comprobado; valores {datos["valores"]}')


if __name__ == '__main__':
    for dominio in sys.argv[1:]:
        buscar(dominio)
