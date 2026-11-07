"""Compara el modelo.py de la carpeta actual con los valores del sistema viejo.

Uso, desde la carpeta del modelo generado:   python comparar.py <dominio>
Las diferencias permitidas son las de pruebas/referencia/diferencias-esperadas.md.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, '.')
import modelo

PRUEBAS = Path(__file__).resolve().parent.parent

# Valen la mitad: cada pareja se cuenta una vez.
CHOQUES = {
    'restriccion_sin_conflictos_de_horario', 'restriccion_un_local_por_defensa',
    'restriccion_un_grupo_por_aula', 'restriccion_una_clase_por_grupo',
    'restriccion_un_aula_por_profesor',
    'restriccion_una_sesion_por_grupo', 'restriccion_una_sesion_por_profesor',
    'restriccion_sin_repetir_asignatura_en_el_dia',
    'restriccion_un_profesor_por_turno', 'restriccion_una_brigada_por_instalacion',
}

# Valen lo que falta para cumplirlas: cero en los mismos casos, y nunca menos que 1 por elemento.
COTAS = {'restriccion_tope_diario_de_profesor', 'restriccion_frecuencia_exacta'}

# Valor exacto de una cota, calculado aparte contando filas: (dominio, semilla, restricción).
EXACTOS = {('saul', 0, 'restriccion_tope_diario_de_profesor'): 9}


def coincide(nombre, viejo, nuevo):
    if nombre in CHOQUES:
        return viejo == 2 * nuevo
    if nombre in COTAS:
        return (viejo == 0) == (nuevo == 0) and nuevo >= viejo
    return viejo == nuevo


def comparar(dominio):
    datos = json.loads((PRUEBAS / 'referencia' / dominio / 'valores.json').read_text(encoding='utf-8'))
    nombres = [r['nombre'] for r in datos['restricciones']]
    nuevos = [nombre for nombre, _, _ in modelo.RESTRICCIONES]
    assert sorted(nombres) == sorted(nuevos), f'{dominio}: {nombres} frente a {nuevos}'
    dureza = {r['nombre']: r['dureza'] for r in datos['restricciones']}
    for nombre, peso, _ in modelo.RESTRICCIONES:
        assert (peso is None) == (dureza[nombre] == 'dura'), f'{dominio}: dureza de {nombre}'

    errores = []
    for referencia in datos['horarios']:
        valores = modelo.evaluar(modelo.crear_horario(referencia['filas']))
        for nombre, viejo in referencia['valores'].items():
            if not coincide(nombre, viejo, valores[nombre]):
                errores.append(f"semilla {referencia['semilla']}, {nombre}: viejo {viejo}, nuevo {valores[nombre]}")
            exacto = EXACTOS.get((dominio, referencia['semilla'], nombre))
            if exacto is not None and valores[nombre] != exacto:
                errores.append(f"semilla {referencia['semilla']}, {nombre}: {valores[nombre]} y se esperaba {exacto}")
    assert not errores, '\n'.join(errores)

    factible = PRUEBAS / 'factibles' / f'{dominio}.json'
    if factible.exists():
        filas = json.loads(factible.read_text(encoding='utf-8'))['filas']
        valores = modelo.evaluar(modelo.crear_horario(filas))
        for nombre, peso, _ in modelo.RESTRICCIONES:
            assert peso is not None or valores[nombre] == 0, f'{dominio}: factible con {nombre} = {valores[nombre]}'


if __name__ == '__main__':
    comparar(sys.argv[1])
