"""Captura la referencia semántica del sistema viejo.

Uso, desde esta carpeta:   python capturar.py tesis tv seder

Por cada dominio escribe en referencia/<dominio>/:
  modelo.txt    lo que imprime mostrar_modelo()
  valores.json  diez horarios aleatorios con semilla fija, como índices, y el
                valor de cada restricción en cada uno
"""
import json
import sys

from sistema_viejo import REFERENCIA, HorarioViejo

SEMILLAS = range(10)


def capturar(dominio):
    viejo = HorarioViejo(dominio)
    carpeta = REFERENCIA / dominio
    (carpeta / 'modelo.txt').write_text(viejo.modelo(), encoding='utf-8')

    horarios = []
    for semilla in SEMILLAS:
        horario = viejo.aleatorio(semilla)
        horarios.append({'semilla': semilla,
                         'filas': viejo.a_indices(horario),
                         'valores': viejo.valores(horario)})

    # La referencia solo sirve si cada horario se reconstruye exacto desde sus índices.
    for h in horarios:
        reconstruido = viejo.valores(viejo.desde_indices(h['filas']))
        assert reconstruido == h['valores'], f"{dominio}, semilla {h['semilla']}: no se reconstruye"

    datos = {'dominio': dominio,
             'identidad': viejo.identidad,
             'variables': viejo.variables,
             'restricciones': [{'nombre': n, 'dureza': d} for n, d in viejo.restricciones],
             'horarios': horarios}
    (carpeta / 'valores.json').write_text(json.dumps(datos, ensure_ascii=False, indent=1),
                                          encoding='utf-8')
    print(f'{dominio}: {len(horarios)} horarios, {len(viejo.restricciones)} restricciones, '
          f'reconstrucción comprobada')


if __name__ == '__main__':
    for dominio in sys.argv[1:]:
        capturar(dominio)
