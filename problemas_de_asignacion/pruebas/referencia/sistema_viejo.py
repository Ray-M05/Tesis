"""Acceso genérico a un horario.py generado por el sistema viejo.

Todo se deduce de las convenciones del generador viejo, sin nada propio de un
dominio: la firma de crear_horario_aleatorio da las listas de datos y las
variables, y las líneas de evaluar dan las restricciones y su dureza.
"""
import contextlib
import importlib.util
import inspect
import io
import random
import re
from pathlib import Path

REFERENCIA = Path(__file__).resolve().parent


class HorarioViejo:
    def __init__(self, dominio):
        self.dominio = dominio
        ruta = REFERENCIA / dominio / 'horario.py'
        spec = importlib.util.spec_from_file_location(f'viejo_{dominio}', ruta)
        self.m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.m)  # __name__ no es '__main__': no corre el genético

        parametros = list(inspect.signature(self.m.crear_horario_aleatorio).parameters)
        self.args = [getattr(self.m, p.upper()) for p in parametros]
        self.identidad = parametros[0][:-1]  # el generador viejo pluraliza con una 's'
        self.variables = [p[len('lista_'):] for p in parametros if p.startswith('lista_')]
        self.listas = [getattr(self.m, 'LISTA_' + v.upper()) for v in self.variables]

        fuente = inspect.getsource(self.m.evaluar)
        self.restricciones = [
            (nombre, 'dura' if peso == 'DURA' else 'blanda')
            for peso, nombre in re.findall(r'PESO_(DURA|BLANDA)\s*\*\s*(\w+)\(horario\)', fuente)]

    def aleatorio(self, semilla):
        random.seed(semilla)
        return self.m.crear_horario_aleatorio(*self.args)

    def filas(self, horario):
        """La lista de filas: la del Horario cuyos elementos tienen identidad y variables."""
        campos = [self.identidad, *self.variables]
        for lista in vars(horario).values():
            if lista and all(hasattr(lista[0], c) for c in campos):
                return lista
        raise ValueError(f'{self.dominio}: no se encuentran las filas del horario')

    def a_indices(self, horario):
        """Cada fila como las posiciones de sus valores en su lista de datos."""
        return [[next(k for k, x in enumerate(lista) if x is getattr(fila, v))
                 for v, lista in zip(self.variables, self.listas)]
                for fila in self.filas(horario)]

    def desde_indices(self, indices):
        """Reconstruye un horario. Las filas salen en el orden de las identidades."""
        horario = self.aleatorio(0)
        filas = self.filas(horario)
        assert len(filas) == len(indices), 'distinto número de filas'
        for fila, posiciones in zip(filas, indices):
            for v, lista, k in zip(self.variables, self.listas, posiciones):
                setattr(fila, v, lista[k])
        return horario

    def valores(self, horario):
        return {nombre: getattr(self.m, nombre)(horario) for nombre, _ in self.restricciones}

    def duras(self, horario):
        return sum(getattr(self.m, nombre)(horario)
                   for nombre, dureza in self.restricciones if dureza == 'dura')

    def modelo(self):
        texto = io.StringIO()
        with contextlib.redirect_stdout(texto):
            self.m.mostrar_modelo()
        return texto.getvalue()
