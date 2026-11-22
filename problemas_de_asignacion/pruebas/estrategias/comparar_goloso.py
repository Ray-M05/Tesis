"""Compara el goloso con el voraz actual y con la búsqueda local en los cinco dominios.

Va aparte de correr.lisp. Usa las corridas que hay en salida/:
    sbcl --script generar.lisp --archivo ejecuciones/goloso-<dominio>.lisp
    sbcl --script generar.lisp <dominio> --estrategias busqueda-local --ejecutar --semillas 0 1 2
    python pruebas/estrategias/comparar_goloso.py
El voraz actual es la búsqueda local con --pasos 0, que devuelve su arranque sin dar ningún paso.
Termina con código 1 si no se cumple algún criterio de plan_goloso.md.
"""
import collections
import importlib.util
import json
import statistics
import sys
from pathlib import Path

SALIDA = Path(__file__).resolve().parents[2] / 'salida'
DOMINIOS = ['tv', 'tesis', 'seder', 'docentes', 'saul']
POR_DEFECTO = {'inicio': 'voraz', 'penalizacion': 1000, 'estancamiento': 2000, 'tiempo': None, 'ruido': 0,
               'pasos': 100000}
SEMILLAS = {'goloso': range(25), 'voraz actual': range(25), 'búsqueda local': range(3)}


def grupo_de(corrida):
    """Dice a qué se compara la corrida, o None si es otra cosa."""
    argumentos = {clave: valor for clave, valor in corrida['argumentos'].items() if clave != 'semilla'}
    if corrida['estrategia'] == 'goloso':
        return 'goloso'
    if corrida['estrategia'] == 'busqueda_local' and argumentos == dict(POR_DEFECTO, pasos=0):
        return 'voraz actual'
    if corrida['estrategia'] == 'busqueda_local' and argumentos == POR_DEFECTO:
        return 'búsqueda local'
    return None


def corridas(dominio):
    """Devuelve, por grupo, la última corrida de cada una de sus semillas."""
    ultimas = {}
    for ruta in sorted((SALIDA / dominio / 'python' / 'corridas').glob('*.json')):
        corrida = json.loads(ruta.read_text(encoding='utf-8'))
        grupo = grupo_de(corrida)
        if grupo and corrida['argumentos']['semilla'] in SEMILLAS[grupo]:
            ultimas[grupo, corrida['argumentos']['semilla']] = corrida
    por_grupo = collections.defaultdict(list)
    for (grupo, _), corrida in ultimas.items():
        por_grupo[grupo].append(corrida)
    return por_grupo


def cargar_modelo(dominio):
    spec = importlib.util.spec_from_file_location('modelo_' + dominio, SALIDA / dominio / 'python' / 'modelo.py')
    modulo = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modulo)
    return modulo


def media(valores):
    return statistics.mean(valores) if valores else float('nan')


def principal():
    todas = {dominio: corridas(dominio) for dominio in DOMINIOS}
    print('| Dominio | Estrategia | Semillas | Duras: media (rango) | Blandas: media | Segundos: media |')
    print('|---|---|---|---|---|---|')
    for dominio, por_grupo in todas.items():
        for grupo in SEMILLAS:
            lista = por_grupo.get(grupo, [])
            if lista:
                duras = [c['duras'] for c in lista]
                print(f"| {dominio} | {grupo} | {len(lista)} | {media(duras):.1f} ({min(duras)}–{max(duras)}) | "
                      f"{media([c['blandas'] for c in lista]):.1f} | {media([c['segundos'] for c in lista]):.2f} |")

    modelo = cargar_modelo('saul')
    duras = [nombre for nombre, peso, _ in modelo.RESTRICCIONES if peso is None]
    print('\nSaúl, media de cada dura:')
    for grupo in ('goloso', 'voraz actual'):
        lista = todas['saul'].get(grupo, [])
        print(f'  {grupo}:', {nombre: round(media([c['valores'][nombre] for c in lista]), 1)
                              for nombre in duras if any(c['valores'][nombre] for c in lista)})
    print('  goloso, filas forzadas:', round(media([len(c['filas_forzadas']) for c in todas['saul']['goloso']]), 1))

    print('\nDocentes, filas en la misma aula, día y turno, como mucho:')
    for grupo in ('goloso', 'voraz actual'):
        lista = todas['docentes'].get(grupo, [])
        print(f'  {grupo}:', max((collections.Counter(map(tuple, c['posiciones'])).most_common(1)[0][1]
                                  for c in lista), default=None))

    fallos = []
    for dominio, por_grupo in todas.items():
        goloso, voraz = por_grupo.get('goloso', []), por_grupo.get('voraz actual', [])
        if len(goloso) != 25 or len(voraz) != 25:
            fallos.append(f'{dominio}: faltan corridas')
            continue
        blandas_goloso, blandas_voraz = media([c['blandas'] for c in goloso]), media([c['blandas'] for c in voraz])
        if dominio != 'saul' and any(c['duras'] for c in goloso):
            fallos.append(f'{dominio}: el goloso deja duras')
        una_fila = cargar_modelo(dominio).DE_UNA_FILA
        if any(c['valores'][nombre] for c in goloso if not c['sin_opciones_permitidas'] for nombre in una_fila):
            fallos.append(f'{dominio}: el goloso incumple una restricción de una fila')
        if blandas_goloso > blandas_voraz or (dominio != 'tv' and blandas_goloso == blandas_voraz):
            fallos.append(f'{dominio}: el goloso no baja las blandas')
        if dominio == 'saul':
            if media([c['duras'] for c in goloso]) >= media([c['duras'] for c in voraz]):
                fallos.append('saul: el goloso no baja las duras')
            if media([c['segundos'] for c in goloso]) >= media([c['segundos'] for c in voraz]):
                fallos.append('saul: el goloso no es más rápido')
    print('\nCriterios:', 'se cumplen todos' if not fallos else '; '.join(fallos))
    return 1 if fallos else 0


if __name__ == '__main__':
    sys.exit(principal())
