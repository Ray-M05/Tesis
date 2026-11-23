"""Compara la reparación tabú con el genético y la búsqueda local en los cinco dominios.

Va aparte de correr.lisp. Usa las corridas que hay en salida/:
    sbcl --script generar.lisp --archivo ejecuciones/reparacion-tabu-<dominio>.lisp
    python pruebas/estrategias/comparar_reparacion_tabu.py
Las del genético y la búsqueda local son las guardadas con sus valores por defecto. Las del goloso
solo sirven para comprobar que la reparación tabú nunca queda peor con la misma semilla.
Termina con código 1 si no se cumple algún criterio de plan_reparacion.md.
"""
import collections
import importlib.util
import json
import statistics
import sys
from pathlib import Path

SALIDA = Path(__file__).resolve().parents[2] / 'salida'
DOMINIOS = ['tv', 'tesis', 'seder', 'docentes', 'saul']
POR_DEFECTO = {
    'reparacion_tabu': {'tabu': 10, 'permuta': 0.25, 'arranques': 10, 'estancamiento': None, 'pulido': None},
    'genetico': {'inicio': 'voraz', 'penalizacion': 1000, 'tiempo': None, 'torneo': 5, 'radio': 2,
                 'intercambio': 0.3, 'poblacion': 100, 'generaciones': 500, 'cruce': 0.8, 'mutacion': 0.15},
    'busqueda_local': {'inicio': 'voraz', 'penalizacion': 1000, 'estancamiento': 2000, 'tiempo': None,
                       'ruido': 0, 'pasos': 100000},
    'goloso': {},
}
GRUPOS = {'reparacion_tabu': 'reparación tabú', 'genetico': 'genético', 'busqueda_local': 'búsqueda local',
          'goloso': 'goloso'}
SEMILLAS = {'reparación tabú': range(10), 'genético': range(20), 'búsqueda local': range(3), 'goloso': range(10)}
TABLA = ['reparación tabú', 'genético', 'búsqueda local']


def grupo_de(corrida):
    """Dice a qué se compara la corrida, o None si se hizo con otros argumentos."""
    argumentos = {clave: valor for clave, valor in corrida['argumentos'].items() if clave != 'semilla'}
    if argumentos == POR_DEFECTO.get(corrida['estrategia']):
        return GRUPOS[corrida['estrategia']]
    return None


def corridas(dominio):
    """Devuelve, por grupo, la última corrida de cada una de sus semillas, ordenadas por semilla."""
    ultimas = {}
    for ruta in sorted((SALIDA / dominio / 'python' / 'corridas').glob('*.json')):
        corrida = json.loads(ruta.read_text(encoding='utf-8'))
        grupo = grupo_de(corrida)
        if grupo and corrida['argumentos']['semilla'] in SEMILLAS[grupo]:
            ultimas[grupo, corrida['argumentos']['semilla']] = corrida
    por_grupo = collections.defaultdict(list)
    for (grupo, _), corrida in sorted(ultimas.items(), key=lambda par: par[0]):
        por_grupo[grupo].append(corrida)
    return por_grupo


def cargar_modelo(dominio):
    spec = importlib.util.spec_from_file_location('modelo_' + dominio, SALIDA / dominio / 'python' / 'modelo.py')
    modulo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modulo)
    return modulo


def media(valores):
    return statistics.mean(valores) if valores else float('nan')


def resumen(valores):
    return f'{media(valores):.1f} ({min(valores)}–{max(valores)})'


def segundos_a_cero(corrida):
    """Los segundos de la primera mejora con 0 duras, o None si no llegó."""
    return next((mejora['segundos'] for mejora in corrida['mejoras'] if mejora['duras'] == 0), None)


def principal():
    todas = {dominio: corridas(dominio) for dominio in DOMINIOS}
    print('| Dominio | Estrategia | Semillas | Duras: media (rango) | Blandas: media (rango) | Segundos: media |')
    print('|---|---|---|---|---|---|')
    for dominio, por_grupo in todas.items():
        for grupo in TABLA:
            lista = por_grupo.get(grupo, [])
            if lista:
                print(f"| {dominio} | {grupo} | {len(lista)} | {resumen([c['duras'] for c in lista])} | "
                      f"{resumen([c['blandas'] for c in lista])} | {media([c['segundos'] for c in lista]):.2f} |")

    print('\nReparación tabú, por dominio:')
    for dominio, por_grupo in todas.items():
        lista = por_grupo.get('reparación tabú', [])
        if lista:
            motivos = collections.Counter(c['motivo_de_parada'] for c in lista)
            pasos = sum(c['iteraciones'] for c in lista)
            print(f"  {dominio}: arranques {media([c['arranques'] for c in lista]):.1f}, "
                  f"pasos {media([c['iteraciones'] for c in lista]):.0f}, "
                  f"pasos por segundo {pasos / sum(c['segundos'] for c in lista):.0f}, "
                  f"motivos {dict(motivos)}, claves sin holgura {len(lista[0]['certificado'])}")

    saul = todas['saul'].get('reparación tabú', [])
    modelo = cargar_modelo('saul')
    duras = [nombre for nombre, peso, _ in modelo.RESTRICCIONES if peso is None]
    print('\nSaúl, reparación tabú:')
    print('  en 0 duras:', sum(1 for c in saul if c['duras'] == 0), 'de', len(saul))
    a_cero = [segundos_a_cero(c) for c in saul]
    print('  segundos hasta 0 duras, por semilla:', a_cero)
    alcanzados = [s for s in a_cero if s is not None]
    if alcanzados:
        print(f'  media {media(alcanzados):.1f}, mediana {statistics.median(alcanzados):.1f}, '
              f'rango {min(alcanzados)}–{max(alcanzados)}')
    print('  arranque en que llegó a 0 duras:',
          [next((m['arranque'] for m in c['mejoras'] if m['duras'] == 0), None) for c in saul])
    print('  duras que quedan, media:', {nombre: round(media([c['valores'][nombre] for c in saul]), 1)
                                         for nombre in duras if any(c['valores'][nombre] for c in saul)})
    print('  blandas, media:', {nombre: round(media([c['valores'][nombre] for c in saul]), 1)
                                for nombre, peso, _ in modelo.RESTRICCIONES if peso is not None})
    if saul:
        print('  claves con holgura 0:', [(c['restriccion'], [valor if len(valor) < 20 else '(plan)' for valor in c['clave']])
                                         for c in saul[0]['certificado']])

    fallos = []
    for dominio, por_grupo in todas.items():
        reparacion = por_grupo.get('reparación tabú', [])
        if len(reparacion) != 10:
            fallos.append(f'{dominio}: faltan corridas de la reparación tabú')
            continue
        goloso = {c['argumentos']['semilla']: c for c in por_grupo.get('goloso', [])}
        for corrida in reparacion:
            otra = goloso.get(corrida['argumentos']['semilla'])
            if otra is None:
                fallos.append(f"{dominio}: falta el goloso con la semilla {corrida['argumentos']['semilla']}")
            elif (corrida['duras'], corrida['blandas']) > (otra['duras'], otra['blandas']):
                fallos.append(f"{dominio}: peor que el goloso con la semilla {corrida['argumentos']['semilla']}")
        if dominio != 'saul' and any(c['duras'] for c in reparacion):
            fallos.append(f'{dominio}: la reparación tabú deja duras')
        una_fila = cargar_modelo(dominio).DE_UNA_FILA
        if any(c['valores'][nombre] for c in reparacion if not c['sin_opciones_permitidas'] for nombre in una_fila):
            fallos.append(f'{dominio}: incumple una restricción de una fila')
        if any(c['motivo_de_parada'] == 'infactible' for c in reparacion):
            fallos.append(f'{dominio}: el certificado dice que no cabe')
    local = todas['saul'].get('búsqueda local', [])
    if saul and local:
        if media([c['duras'] for c in saul]) >= media([c['duras'] for c in local]):
            fallos.append('saul: no baja las duras de la búsqueda local')
        if media([c['segundos'] for c in saul]) >= media([c['segundos'] for c in local]):
            fallos.append('saul: no es más rápida que la búsqueda local')
        if sum(c['iteraciones'] for c in saul) / sum(c['segundos'] for c in saul) < 100:
            fallos.append('saul: menos de 100 pasos por segundo')
    else:
        fallos.append('saul: faltan corridas para comparar')
    print('\nCriterios:', 'se cumplen todos' if not fallos else '; '.join(fallos))
    return 1 if fallos else 0


if __name__ == '__main__':
    sys.exit(principal())
