"""Comprueba los criterios de la etapa 4 y calcula en minutos lo que costarían corridas más grandes.

Va aparte de correr.lisp porque tarda unos 40 minutos. Usa lo que hay en salida/:
    sbcl --script generar.lisp
    python pruebas/estrategias/rendimiento.py
Termina con código 1 si no se cumple algún criterio.
"""
import importlib.util
import json
import random
import statistics
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

SALIDA = Path(__file__).resolve().parents[2] / 'salida'


def correr(dominio, programa, *argumentos):
    """Ejecuta un programa en la carpeta del dominio y devuelve su JSON."""
    salida = subprocess.run([sys.executable, '-X', 'utf8', programa + '.py', *map(str, argumentos)],
                            cwd=SALIDA / dominio, capture_output=True, text=True, encoding='utf-8')
    if salida.returncode != 0:
        raise RuntimeError(salida.stderr)
    return json.loads(Path(salida.stdout.strip().splitlines()[-1]).read_text(encoding='utf-8'))


def en_paralelo(tareas):
    """Ejecuta (dominio, programa, argumentos...) a la vez. Los tiempos así medidos no valen."""
    with ThreadPoolExecutor(4) as hilos:
        return list(hilos.map(lambda tarea: correr(*tarea), tareas))


def resumen(corridas):
    duras = [c['duras'] for c in corridas]
    return (f"duras {duras}, media {statistics.mean(duras):.1f}; "
            f"blandas {[c['blandas'] for c in corridas]}; "
            f"iteraciones {[c['iteraciones'] for c in corridas]}")


def evaluaciones_por_individuo(corridas):
    return max(c['evaluaciones'] / c['individuos'] for c in corridas)


def cargar_modelo(dominio):
    spec = importlib.util.spec_from_file_location('modelo_' + dominio, SALIDA / dominio / 'modelo.py')
    modulo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modulo)
    return modulo


def milisegundos(funcion, veces):
    comienzo = time.perf_counter()
    for _ in range(veces):
        funcion()
    return (time.perf_counter() - comienzo) / veces * 1000


def costo_de_evaluar(modelo, factor, solo_prohibiciones=False, mitad=False):
    """Milisegundos de crear y evaluar un horario al azar con FACTOR veces las filas de Saúl."""
    identidades = modelo.IDENTIDADES
    modelo.IDENTIDADES = identidades * factor
    filas = len(modelo.IDENTIDADES) // (2 if mitad else 1)
    azar = random.Random(0)
    posiciones = [tuple(azar.randrange(len(d)) for d in modelo.DOMINIOS_DE_DECISION) for _ in range(filas)]
    funciones = [f for n, p, f in modelo.RESTRICCIONES
                 if (n in modelo.PROHIBICIONES if solo_prohibiciones else n not in modelo.CONSTANTES)]
    tiempo = milisegundos(lambda: [f(modelo.crear_horario(posiciones)) for f in funciones], max(2, 20 // factor))
    modelo.IDENTIDADES = identidades
    return tiempo


def main():
    fallos = []

    print('== Criterios (corridas en paralelo: sus tiempos no valen)')
    seder = en_paralelo([('seder', 'genetico', '--semilla', s) for s in range(20)])
    ceros = sum(c['duras'] == 0 for c in seder)
    print(f'SEDER, genético, 20 semillas: {ceros} de 20 en 0 duras')
    if ceros < 18:
        fallos.append('SEDER no llega a 18 de 20')
    saul = en_paralelo([('saul', 'genetico', '--semilla', s) for s in range(3)])
    print('Saúl, genético, 3 semillas:', resumen(saul))
    if max(c['duras'] for c in saul) > 17:
        fallos.append('Saúl pasa de 17 duras')
    por_individuo = evaluaciones_por_individuo(seder + saul)
    print(f'Evaluaciones por individuo creado: {por_individuo:.2f} como mucho')
    if por_individuo > 1:
        fallos.append('más de una evaluación por individuo')

    print('\n== Otros arranques y la búsqueda local (en paralelo)')
    for inicio in ('permitidos', 'aleatorio'):
        corridas = en_paralelo([('seder', 'genetico', '--semilla', s, '--inicio', inicio) for s in range(20)])
        print(f'SEDER, genético con --inicio {inicio}: {sum(c["duras"] == 0 for c in corridas)} de 20')
    corridas = en_paralelo([('seder', 'busqueda_local', '--semilla', s) for s in range(20)])
    print(f'SEDER, búsqueda local: {sum(c["duras"] == 0 for c in corridas)} de 20')
    corridas = en_paralelo([('saul', 'busqueda_local', '--semilla', s, '--tiempo', 120) for s in range(3)])
    print('Saúl, búsqueda local con 120 s:', resumen(corridas))

    print('\n== Valores por defecto en cada dominio, una corrida cada vez')
    for dominio in ('tv', 'tesis', 'docentes', 'seder', 'saul'):
        corrida = correr(dominio, 'genetico', '--semilla', 0)
        print(f'{dominio}: {corrida["segundos"] / 60:.1f} min, {corrida["iteraciones"]} generaciones, '
              f'{corrida["duras"]} duras, {corrida["blandas"]} blandas')

    print('\n== Tiempo por generación de Saúl, una corrida cada vez')
    arranque_voraz = correr('saul', 'genetico', '--semilla', 0, '--generaciones', 0)['segundos']
    por_generacion = {}
    arranque = {}
    for poblacion, generaciones in ((100, 20), (500, 5)):
        base = ['--semilla', 0, '--inicio', 'permitidos', '--poblacion', poblacion]
        arranque[poblacion] = correr('saul', 'genetico', *base, '--generaciones', 0)['segundos']
        con = correr('saul', 'genetico', *base, '--generaciones', generaciones)['segundos']
        por_generacion[poblacion] = (con - arranque[poblacion]) / generaciones
    voraz = arranque_voraz - arranque[100]
    print(f'Voraz: {voraz:.1f} s. Una generación: {por_generacion[100]:.2f} s con 100 individuos '
          f'y {por_generacion[500]:.2f} s con 500')
    print('\n| Generaciones | Población 100 | Población 500 |')
    print('|---|---|---|')
    for generaciones in (500, 2000, 10000):
        minutos = [(voraz + arranque[p] + generaciones * por_generacion[p]) / 60 for p in (100, 500)]
        print(f'| {generaciones} | {minutos[0]:.0f} min | {minutos[1]:.0f} min |')

    print('\n== Saúl con distintas poblaciones y generaciones, medido con tres corridas a la vez')
    combinaciones = [(500, 500), (100, 2000), (50, 2000), (200, 500), (100, 500), (50, 500)]
    with ThreadPoolExecutor(3) as hilos:
        corridas = list(hilos.map(lambda pg: correr('saul', 'genetico', '--semilla', 0, '--poblacion', pg[0],
                                                      '--generaciones', pg[1]), combinaciones))
    print('| Población | Generaciones | Minutos | Duras | Blandas |')
    print('|---|---|---|---|---|')
    for (poblacion, generaciones), corrida in sorted(zip(combinaciones, corridas)):
        print(f'| {poblacion} | {generaciones} | {corrida["segundos"] / 60:.1f} | {corrida["duras"]} '
              f'| {corrida["blandas"]} |')

    print('\n== Proyección con instancias más grandes, 500 generaciones y población 100')
    modelo = cargar_modelo('saul')
    evaluar = {k: costo_de_evaluar(modelo, k) for k in (1, 2, 5)}
    parcial = {k: costo_de_evaluar(modelo, k, solo_prohibiciones=True, mitad=True) for k in (1, 2, 5)}
    print('| Filas | Evaluar un horario | Voraz | 500 generaciones |')
    print('|---|---|---|---|')
    for k in (1, 2, 5):
        generacion = por_generacion[100] * evaluar[k] / evaluar[1]
        voraz_k = voraz * k * parcial[k] / parcial[1]
        print(f'| ×{k} ({len(modelo.IDENTIDADES) * k}) | {evaluar[k]:.1f} ms | {voraz_k / 60:.1f} min '
              f'| {500 * generacion / 60:.0f} min |')
    print('Supone las mismas generaciones; una instancia más grande seguramente necesita más.')

    if fallos:
        print('\nNo se cumple:', '; '.join(fallos))
        sys.exit(1)
    print('\nSe cumplen los criterios.')


if __name__ == '__main__':
    main()
