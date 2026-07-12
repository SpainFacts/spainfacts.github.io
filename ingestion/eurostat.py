"""Fuente dlt para la API de diseminación de Eurostat (JSON-stat).

Deuda pública trimestral de España según el Protocolo de Déficit Excesivo
(dataset gov_10q_ggdebt: sector S13 = AAPP consolidadas, na_item GD = deuda
bruta total), en millones de euros y en % del PIB.
"""

import dlt
import requests

URL = (
    "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"
    "gov_10q_ggdebt?freq=Q&geo=ES&sector=S13&na_item=GD&unit={unit}&format=JSON&lang=EN"
)
UNIDADES = ["MIO_EUR", "PC_GDP"]


@dlt.source(name="eurostat")
def eurostat():
    @dlt.resource(name="eurostat_deuda", write_disposition="replace")
    def deuda():
        for unidad in UNIDADES:
            respuesta = requests.get(URL.format(unit=unidad), timeout=120)
            respuesta.raise_for_status()
            datos = respuesta.json()
            # Con freq/geo/sector/na_item/unit fijados a un único valor, el
            # índice plano de `value` coincide con el índice de la dimensión
            # temporal. La aserción protege contra filtros no unívocos.
            for dim in datos["id"]:
                if dim != "time":
                    assert datos["size"][datos["id"].index(dim)] == 1, (
                        f"la dimensión {dim} tiene más de un valor; el filtro no es unívoco"
                    )
            periodos = {v: k for k, v in datos["dimension"]["time"]["category"]["index"].items()}
            for indice, valor in datos["value"].items():
                yield {
                    "periodo": periodos[int(indice)],  # p. ej. "2025-Q3"
                    "unidad": unidad,
                    "valor": valor,
                }

    return [deuda]
