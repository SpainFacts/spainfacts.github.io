"""Fuente dlt para la estadística de criminalidad del Ministerio del Interior.

Portal Estadístico de Criminalidad (Secretaría de Estado de Seguridad):
https://estadisticasdecriminalidad.ses.mir.es. Usa el motor JAXI del INE, que
sirve cada tabla como CSV plano (UTF-8, ";", miles con "." y decimales con ","):
  .../sec/jaxiPx/files/_px/es/csv_bdsc/<carpeta>/l0/<id>.csv_bdsc?nocab=1

1) Serie anual de infracciones penales conocidas, 2010-último año, por
   comunidad (Datos1/01001) y provincia (Datos1/01002) y 44 tipologías.
   Incluye los datos de Mossos d'Esquadra, Ertzaintza y Policía Foral.

2) Balance de Criminalidad por municipio (los de más de 20.000 habitantes,
   islas, provincias y comunidades), con su código INE:
   - el fichero del cuarto trimestre de cada año da el año completo (y el
     anterior): DatosBalanceAnt/l0/AA09012 con AA = 10 (2019), 11 (2020),
     12 (2021), 13 (2022), 14 (2023), 15 (2025 y 2024);
   - DatosBalanceAct/l0/09006 = el último trimestre publicado (acumulado del
     año en curso y del mismo periodo del anterior).
   En 2019 cambió la clasificación (la cibercriminalidad se cuenta aparte):
   los totales antes y después no son del todo comparables.

Son hechos CONOCIDOS por las fuerzas de seguridad (denunciados o descubiertos),
no delitos cometidos: dependen también de la propensión a denunciar.

Recursos (replace):
  ses_criminalidad_anual   año x comunidad/provincia x tipología
  ses_balance_municipios   periodo x territorio (con código INE si es municipio) x tipología
"""

import csv
import io
import logging
import re
import unicodedata

import dlt
import requests

log = logging.getLogger(__name__)

BASE = "https://estadisticasdecriminalidad.ses.mir.es/sec/jaxiPx/files/_px/es/csv_bdsc/{ruta}.csv_bdsc?nocab=1"
CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}

SERIES_ANUALES = {"ccaa": "Datos1/l0/01001", "provincia": "Datos1/l0/01002"}
# Ficheros del cuarto trimestre con el año completo por municipio, y el último publicado
BALANCES = [f"DatosBalanceAnt/l0/{aa}09012" for aa in (10, 11, 12, 13, 14, 15)] + ["DatosBalanceAct/l0/09006"]


def _filas(ruta: str):
    r = requests.get(BASE.format(ruta=ruta), headers=CABECERAS, timeout=180)
    r.raise_for_status()
    if "text/html" in r.headers.get("Content-Type", ""):
        raise ValueError(f"{ruta}: el portal devolvió HTML en lugar del CSV")
    lector = csv.reader(io.StringIO(r.content.decode("utf-8-sig")), delimiter=";")
    next(lector)
    yield from lector


def _numero(texto: str) -> float | None:
    texto = (texto or "").strip().replace(".", "").replace(",", ".")
    try:
        return float(texto)
    except ValueError:
        return None


# Nombres antiguos que no aparecen en los ficheros con código (cambio de nombre oficial
# o municipio que dejó de figurar); códigos comprobados en el padrón del INE.
ALIAS_MUNICIPIOS = {"santa eulalia del rio": "07054", "baranain": "31901"}


def _clave(nombre: str) -> str:
    """Nombre sin tildes, minúsculas y sin artículos entre paréntesis para casar municipios."""
    nombre = "".join(c for c in unicodedata.normalize("NFD", nombre) if unicodedata.category(c) != "Mn")
    return re.sub(r"\s+", " ", nombre.lower()).strip()


def _variantes(nombre: str) -> set[str]:
    """Formas con las que el mismo municipio aparece en ficheros de distintos años:
    'Almazora/Almassora' -> las dos; 'Porriño (O)' -> 'o porriño'; 'Valle de Egüés/Eguesibar' -> 'egues'."""
    formas = {_clave(nombre)}
    for parte in nombre.split("/"):
        parte = parte.strip()
        formas.add(_clave(parte))
        m = re.match(r"^(.+?) \((\w+)\)$", parte) or re.match(r"^(.+?), (\w+)$", parte)
        if m:  # "Porriño (O)" / "Porriño, O" -> "o porriño"
            formas.add(_clave(f"{m.group(2)} {m.group(1)}"))
        m = re.match(r"^valle de (.+)$", _clave(parte))
        if m:
            formas.add(m.group(1))
    return formas


def _normalizar_periodo(texto: str) -> tuple[int | None, str | None]:
    """'enero--diciembre 2023' -> (2023, 'enero-diciembre'); 'Variación %...' -> (None, None)."""
    t = re.sub(r"-+", "-", texto.strip().lower())
    m = re.match(r"^(enero-[a-z]+) (\d{4})$", t)
    return (int(m.group(2)), m.group(1)) if m else (None, None)


@dlt.source(name="criminalidad")
def criminalidad():
    @dlt.resource(name="ses_criminalidad_anual", write_disposition="replace")
    def anual():
        for nivel, ruta in SERIES_ANUALES.items():
            for territorio, tipologia, periodo, total in _filas(ruta):
                yield {"nivel": nivel, "territorio": territorio.strip(), "tipologia": tipologia.strip(),
                       "anio": int(periodo), "infracciones": _numero(total)}

    @dlt.resource(name="ses_balance_municipios", write_disposition="replace")
    def balance():
        vistos = set()
        # Hasta 2022 los municipios vienen como "- Municipio de Adra" (sin código);
        # desde 2023 como "04003 Adra". El diccionario nombre -> código se llena
        # con los ficheros nuevos, que se leen primero.
        codigos: dict[tuple[str, str], str] = {}
        codigos_nombre: dict[str, set[str]] = {}
        # del más reciente al más antiguo: cada (periodo, territorio, tipología)
        # se toma del fichero más nuevo que lo contenga (las cifras se revisan)
        for ruta in reversed(BALANCES):
            try:
                filas = list(_filas(ruta))
            except (requests.HTTPError, ValueError) as e:
                log.warning("Balance %s no disponible: %s", ruta, e)
                continue
            provincia = ""
            sin_codigo = set()
            for territorio, tipologia, periodo, total in filas:
                territorio = territorio.strip()
                limpio = territorio.lstrip("- ").strip()
                m = re.match(r"^(\d{5}) (.+)$", limpio)
                if m:
                    nivel, cod, nombre = "municipio", m.group(1), m.group(2)
                    for variante in _variantes(nombre):
                        codigos[(provincia, variante)] = cod
                        codigos_nombre.setdefault(variante, set()).add(cod)
                elif limpio.lower().startswith(("municipio de ", "municipo de ")):  # sic, errata en 2020
                    nivel, nombre = "municipio", limpio.split(" de ", 1)[1]
                    cod = codigos.get((provincia, _clave(nombre))) or ALIAS_MUNICIPIOS.get(_clave(nombre))
                    if cod is None and len(codigos_nombre.get(_clave(nombre), ())) == 1:
                        cod = next(iter(codigos_nombre[_clave(nombre)]))
                    if cod is None:
                        sin_codigo.add(nombre)
                elif limpio.lower().startswith("provincia de "):
                    nivel, cod, nombre = "provincia", None, limpio[13:]
                    provincia = _clave(nombre)
                elif limpio.lower().startswith("isla "):
                    nivel, cod, nombre = "isla", None, limpio
                elif limpio.upper() == "TOTAL NACIONAL":
                    nivel, cod, nombre = "pais", "00", limpio
                else:
                    nivel, cod, nombre = "ccaa", None, limpio
                anio, tramo = _normalizar_periodo(periodo)
                if anio is None:
                    continue  # filas de variación porcentual
                clave = (anio, tramo, nivel, cod or nombre, tipologia.strip())
                if clave in vistos:
                    continue
                vistos.add(clave)
                yield {"fichero": ruta, "anio": anio, "periodo": tramo, "nivel": nivel, "cod_mun": cod if nivel == "municipio" else None,
                       "territorio": nombre, "tipologia": tipologia.strip(), "infracciones": _numero(total)}
            if sin_codigo:
                log.warning("%s: %d municipios sin código INE: %s", ruta, len(sin_codigo), sorted(sin_codigo)[:10])

    return anual, balance


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("criminalidad").run(criminalidad()))
