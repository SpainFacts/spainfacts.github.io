"""Fuente dlt para los microdatos de vehículos de la DGT (MATRABA y parque).

1) Matriculaciones mensuales (desde enero de 2015)
   https://www.dgt.es/microdatos/salida/{AAAA}/{M}/vehiculos/matriculaciones/export_mensual_mat_{AAAAMM}.zip
   (mes sin cero a la izquierda en la carpeta). Un TXT de ancho fijo (714
   caracteres, latin-1, 69 campos) con una cabecera de una línea: diseño en
   dgt.es/.../matraba/MATRICULACIONES_MATRABA.pdf. Se publica hacia el día 15
   del mes siguiente. Diciembre de 2014 usa otro ancho (707) y se descarta.
   Solo cuentan las matriculaciones ordinarias (CLAVE_TRAMITE = 1): el fichero
   también trae matrículas temporales, su paso a definitivas y
   rematriculaciones. IND_NUEVO_USADO separa los nuevos de los usados
   importados, que también se matriculan por primera vez en España.

2) Parque de vehículos (fichero mensual, ~1,75 GB comprimido)
   https://www.dgt.es/microdatos/Parque/parque_vehiculos_{AAAAMM}.zip
   Un vehículo en alta por fila, separado por "|", con cabecera. Solo se
   procesa el último mes publicado (se lee en streaming sin descomprimir a
   disco) y se guarda agregado; cada ejecución mensual añade una foto.
   La DGT deja en blanco el municipio de los de menos de 10.000 habitantes.

Nada se carga en bruto: los ficheros se agregan al vuelo y los agregados de
cada mes se guardan en data/dgt_cache/ (no versionado), así que una recarga
completa no vuelve a descargar los históricos.

Recursos (merge por mes: volver a cargar un mes lo sustituye):
  dgt_matriculaciones           mes x municipio x grupo x energía x nuevo/usado x renting x titular
  dgt_matriculaciones_modelos   mes x grupo x energía x nuevo/usado x marca x modelo (España)
  dgt_parque                    mes x municipio (o provincia) x grupo x energía x distintivo x antigüedad
  dgt_parque_modelos            mes x grupo x energía x marca x modelo (España)
"""

import csv
import gzip
import io
import json
import logging
import re
import zipfile
from collections import Counter
from datetime import date, timedelta
from pathlib import Path

import dlt
import requests

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE = REPO_ROOT / "data" / "dgt_cache"

log = logging.getLogger(__name__)

URL_MAT = (
    "https://www.dgt.es/microdatos/salida/{anio}/{mes}/vehiculos/matriculaciones/"
    "export_mensual_mat_{anio}{mes:02d}.zip"
)
URL_MAT_DIA = (
    "https://www.dgt.es/microdatos/salida/{anio}/{mes}/vehiculos/matriculaciones/export_mat_{fecha}.zip"
)
URL_PARQUE = "https://www.dgt.es/microdatos/Parque/parque_vehiculos_{anio}{mes:02d}.zip"
PRIMER_MES = date(2015, 1, 1)
CABECERAS = {"User-Agent": "spainfacts.org (datos abiertos; contacto en github.com/SpainFacts)"}

# Anchos de los 69 campos del fichero de matriculaciones, en orden.
ANCHOS = [8, 1, 8, 30, 22, 1, 21, 2, 1, 5, 6, 6, 6, 3, 2, 2, 2, 2, 24, 2, 2, 1, 8, 5, 8, 1, 1, 9, 3,
          5, 30, 7, 3, 5, 1, 1, 1, 1, 1, 1, 11, 25, 25, 35, 70, 6, 6, 4, 4, 3, 8, 4, 4, 4, 6, 30, 50,
          35, 25, 35, 4, 4, 4, 1, 25, 1, 4, 25, 8]
_OFF = [0]
for _a in ANCHOS:
    _OFF.append(_OFF[-1] + _a)
LARGO_REGISTRO = _OFF[-1]  # 714


def _campo(linea: str, n: int) -> str:
    """Campo n (1-based, numeración del diseño de registro de la DGT)."""
    return linea[_OFF[n - 1]:_OFF[n]].strip()


# Provincia del domicilio del vehículo (código DGT de letras) -> código INE.
PROV_DGT_INE = {
    "VI": "01", "AB": "02", "A": "03", "AL": "04", "AV": "05", "BA": "06", "IB": "07", "PM": "07",
    "B": "08", "BU": "09", "CC": "10", "CA": "11", "CS": "12", "CR": "13", "CO": "14", "C": "15",
    "CU": "16", "GI": "17", "GE": "17", "GR": "18", "GU": "19", "SS": "20", "H": "21", "HU": "22",
    "J": "23", "LE": "24", "L": "25", "LO": "26", "LU": "27", "M": "28", "MA": "29", "MU": "30",
    "NA": "31", "OU": "32", "OR": "32", "O": "33", "P": "34", "GC": "35", "PO": "36", "SA": "37",
    "TF": "38", "S": "39", "SG": "40", "SE": "41", "SO": "42", "T": "43", "TE": "44", "TO": "45",
    "V": "46", "VA": "47", "BI": "48", "ZA": "49", "Z": "50", "CE": "51", "ML": "52",
}


def grupo_vehiculo(cod_tipo: str) -> str:
    """Grupo a partir del código de tipo DGT (anexo I del diseño de registro)."""
    t = (cod_tipo or "").upper()
    if t in ("40", "25"):
        return "turismo"  # los todoterreno cuentan como turismos, como en las series de la DGT
    if t in ("50", "51", "52", "53"):
        return "motocicleta"
    if t in ("90", "91", "92", "54"):
        return "ciclomotor"  # incluye cuatriciclos ligeros y pesados
    if t in ("20", "21", "24", "0G", "22", "23"):
        return "furgoneta"
    if t in ("30", "31", "32", "33", "34", "35", "36"):
        return "autobus"
    if t == "81" or (len(t) == 2 and t[0] in "01"):
        return "camion"
    if t in ("80", "82", "7H", "7I", "RH", "SH"):
        return "agricola"
    if t[:1] in ("R", "S"):
        return "remolque"
    if t[:1] == "7":
        return "especial"
    return "otros"


def energia(propulsion: str, cat_electrica: str) -> str:
    """Tipo de energía combinando la propulsión ITV y la categoría eléctrica."""
    cat = (cat_electrica or "").upper()
    p = (propulsion or "").upper()
    if cat == "BEV" or (p == "2" and cat in ("", "BEV")):
        return "bev"
    if cat in ("PHEV", "REEV"):
        return "phev"  # los de autonomía extendida se agrupan con los enchufables
    if cat == "FCEV" or p == "9":
        return "hidrogeno"
    if cat == "HEV":
        return "hev"  # incluye híbridos ligeros (mild hybrid)
    return {"0": "gasolina", "1": "diesel", "6": "gas", "7": "gas", "8": "gas", "A": "gas",
            "4": "gas"}.get(p, "otros")


def _meses(desde: date, hasta: date):
    d = desde
    while d <= hasta:
        yield d
        d = date(d.year + (d.month == 12), d.month % 12 + 1, 1)


def _dias(desde: date, hasta: date):
    """Días de `desde` a `hasta` (este excluido)."""
    d = desde
    while d < hasta:
        yield d
        d += timedelta(days=1)


def limpiar_modelo(marca: str, modelo: str) -> tuple[str, str]:
    """Normaliza espacios y quita la marca repetida al principio del modelo
    ("TOYOTA" / "TOYOTA COROLLA" -> "COROLLA")."""
    # la DGT enmascara con "¡" las marcas/modelos que permitirían identificar al titular
    marca = " ".join((marca or "").replace("¡", "").upper().split())
    modelo = " ".join((modelo or "").replace("¡", "").upper().split())
    if marca and modelo.startswith(marca + " "):
        modelo = modelo[len(marca) + 1:]
    return marca, modelo


# Palabras que algunas marcas (sobre todo las de Stellantis: Peugeot, Citroën,
# Opel, DS) escriben en MODELO_ITV detrás del nombre comercial: acabados,
# motores, cajas de cambio y carrocerías. MODELO_ITV tiene 22 caracteres, así
# que la última palabra suele llegar cortada ("ELÉCTRIC", "AIRCR", "HYBR").
RUIDO_MODELO = {
    "5P", "3P", "ALLURE", "STYLE", "GT", "EDITION", "EXCLUSIVE", "ACTIVE", "BUSINESS", "GS", "YES",
    "MAX", "PLUS", "YOU", "HYBRID", "TURBO", "GASOLINA", "BLUEHDI", "PURETECH", "ELÉCTRICO",
    "ELECTRIC", "S&S", "MT6", "EAT8", "EDC", "XHL", "XHT", "1.2", "1.2T", "1.5", "TALLA",
    "BLUEHDI", "SHINE", "FEEL", "C-SERIES", "ELECTRIQUE", "AUTOMATICO", "AUT",
}
# Una misma marca escrita de dos formas en las fichas
ALIAS_MARCA = {
    "DS AUTOMOBILES": "DS", "CITROËN": "CITROEN",
    "MERCEDES BENZ": "MERCEDES-BENZ", "MERCEDES BENZ AG": "MERCEDES-BENZ", "MERCEDES": "MERCEDES-BENZ",
}
MARCAS_STELLANTIS = {"PEUGEOT", "CITROEN", "CITROËN", "OPEL", "DS", "DS AUTOMOBILES"}
# Palabras que solo dicen el tipo de motor (ya está en la columna energia)
MOTORIZACION = {"HYBRID", "HYBRID+", "E-HYBRID", "DM-I", "DM-I+", "PHEV", "HEV", "MHEV", "EV", "BEV",
                "ELECTRIC", "ELÉCTRICO", "ELECTRICO", "E-TENSE", "PLUG-IN", "E-TECH"}


def modelo_comercial(marca: str, modelo: str) -> str:
    """Nombre comercial a partir del MODELO_ITV de la ficha técnica, para que
    un mismo coche no quede repartido en varias filas del ranking.

    Casos reales (turismos nuevos, 2025-2026):
      PEUGEOT  "208 5P ALLURE HYBRID 1"   y "208 5P STYLE HYBRID 11"   -> "208"
      PEUGEOT  "E-2008 ALLURE ELÉCTRIC"                                   (¿"2008" o "E-2008"?)
      PEUGEOT  "NUEVO 308 5P ALLURE HY"                                   -> "308"
      CITROEN  "NUEVO CITROËN C3 AIRCR" y "NUEVO C3 AIRCROSS HYBR"     -> "C3 AIRCROSS"
      CITROEN  "BERLINGOÁTALLA M BLUEH" (sic, sin espacio)               -> "BERLINGO"
      OPEL     "CORSA GS 1.2T XHL MT6"  y "CORSA EDITION 1.2T XHL"     -> "CORSA"
      HYUNDAI  "KONA, KAUAI"            y "TUCSON,IX35"                  -> "KONA" / "TUCSON"
      Y los que ya vienen limpios y NO deben tocarse:
      BYD "SEAL U DM-I" / "SEAL 6 DM-I TOURING", CUPRA "LEON SP", MG "MG3 HYBRID+", KIA "EV3"

    El tipo de motor ya se filtra aparte (columna energia), así que el nombre
    no necesita decir si es híbrido o eléctrico.
    """
    marca = (marca or "").upper()
    texto = (modelo or "").upper().split(",")[0]  # "KONA, KAUAI" -> "KONA"
    if marca.startswith("DS"):
        # "7 BLUEHDI PALLAS", "N 4 HYBRID ÉTOILE" (el DS N°4), "DS 3 HYBRID" -> "DS 7", "DS 4", "DS 3"
        numero = re.search(r"(?<![\w.])(\d)(?![\w.])", texto)
        if numero:
            return f"DS {numero.group(1)}"
    if marca in MARCAS_STELLANTIS:
        texto = re.sub(r"(?<=[A-Z])Á(?=[A-Z])", " ", texto)  # "BERLINGOÁTALLA" -> "BERLINGO TALLA"
    palabras = texto.split()
    marca_normal = ALIAS_MARCA.get(marca, marca)
    # Marcas alemanas y Lexus: la primera palabra es el modelo y el resto, el motor
    if palabras and marca_normal == "MERCEDES-BENZ":
        # "GLC 300 DE 4MATIC" -> "GLC"; "A 180" -> "CLASE A"; "EQA 250+" -> "EQA"
        if palabras[0] == "AMG" and len(palabras) > 1:
            return "AMG " + palabras[1]
        return f"CLASE {palabras[0]}" if len(palabras[0]) == 1 else palabras[0]
    if palabras and marca_normal == "BMW":
        # "X1 SDRIVE18D" -> "X1"; "120D" / "118D" -> "SERIE 1"
        if palabras[0] == "SERIE" and len(palabras) > 1:
            return "SERIE " + palabras[1][0]
        return f"SERIE {palabras[0][0]}" if re.fullmatch(r"\d{3}[A-Z]*", palabras[0]) else palabras[0]
    if palabras and marca_normal == "AUDI":
        return palabras[0]  # "A3 SPORTBACK PHEV 150" -> "A3"
    if palabras and marca_normal == "LEXUS":
        return re.sub(r"^([A-Z]{2})\d{3}H\+?$", r"\1", palabras[0])  # "NX350H" -> "NX"
    if marca_normal.startswith("LYNK") and texto.startswith("LYNK & CO "):
        palabras = texto[len("LYNK & CO "):].split()
    if marca_normal == "HYUNDAI" and len(palabras) > 1 and palabras[0] == "I" and palabras[1].isdigit():
        palabras = ["I" + palabras[1]] + palabras[2:]  # "I 30" -> "I30"
    # "NUEVO", la marca repetida ("NUEVO CITROËN C3") y el prefijo eléctrico ("E-2008", "Ë-C3")
    quitar = {"NUEVO", "NUEVA", "NEW"} | ({marca, marca.replace("OE", "OË")} if len(marca) > 2 else set())
    while palabras and palabras[0] in quitar:
        palabras.pop(0)
    if palabras and marca in MARCAS_STELLANTIS:
        palabras[0] = re.sub(r"^[EË]-(?=\w)", "", palabras[0])
        palabras[0] = re.sub(r"^N(?=\d)", "", palabras[0])  # "N2008" (Nuevo 2008, 2023) -> "2008"

    limpias = []
    for i, p in enumerate(palabras):
        # Motorización (se filtra aparte con la columna energia), en todas las marcas
        if p in MOTORIZACION or re.fullmatch(r"E-HYBRID\d*|\d+KW", p):
            continue
        if i > 0 and i == len(palabras) - 1 and len(p) >= 3 and any(m.startswith(p) for m in MOTORIZACION):
            continue  # motor cortado a los 22 caracteres: "5 E-TECH ELECT"
        if marca in MARCAS_STELLANTIS and i > 0:
            ultima = i == len(palabras) - 1
            if p in RUIDO_MODELO or re.match(r"^\d", p) or p.startswith("TURBO"):
                break  # empieza el acabado o el motor: "208 5P ALLURE...", "COMBO 100 CV..."
            if ultima and len(p) >= 2 and any(r.startswith(p) for r in RUIDO_MODELO | MOTORIZACION):
                break  # palabra cortada a los 22 caracteres: "HYBR", "ELÉCTRIC", "BLUEH"
            if ultima and len(p) >= 3 and "AIRCROSS".startswith(p):
                p = "AIRCROSS"  # "C3 AIRCR"
        limpias.append(p)
    return " ".join(limpias) or " ".join(palabras) or modelo


def _mes_anterior(d: date) -> date:
    return date(d.year - (d.month == 1), (d.month - 2) % 12 + 1, 1)


def _descargar(url: str, destino: Path) -> bool:
    """Descarga a disco en streaming. False si el fichero aún no existe."""
    with requests.get(url, headers=CABECERAS, stream=True, timeout=120) as r:
        if r.status_code == 404:
            return False
        r.raise_for_status()
        if "zip" not in r.headers.get("Content-Type", "zip"):
            return False  # página HTML de error en lugar del fichero
        tmp = destino.with_suffix(".part")
        with open(tmp, "wb") as f:
            for trozo in r.iter_content(1 << 20):
                f.write(trozo)
        tmp.replace(destino)
    return True


def _leer_cache(ruta: Path):
    with gzip.open(ruta, "rt", encoding="utf-8") as f:
        return json.load(f)


def _guardar_cache(ruta: Path, datos) -> None:
    ruta.parent.mkdir(parents=True, exist_ok=True)
    tmp = ruta.with_suffix(".tmp")
    with gzip.open(tmp, "wt", encoding="utf-8") as f:
        json.dump(datos, f, ensure_ascii=False)
    tmp.replace(ruta)


# --------------------------------------------------------------------------
# Matriculaciones
# --------------------------------------------------------------------------

def agregar_matriculaciones(lineas) -> dict:
    """Agrega las líneas de un fichero mensual. Devuelve dos listas de filas."""
    territorio = Counter()
    co2 = Counter()
    co2_n = Counter()
    modelos = Counter()
    descartadas = Counter()
    for linea in lineas:
        linea = linea.rstrip("\r\n")
        if len(linea) != LARGO_REGISTRO:
            descartadas["ancho"] += 1
            continue
        if _campo(linea, 22) != "1":
            descartadas["tramite"] += 1
            continue
        grupo = grupo_vehiculo(_campo(linea, 8))
        ener = energia(_campo(linea, 9), _campo(linea, 54))
        nu = _campo(linea, 26) or "N"
        renting = _campo(linea, 35) == "S"
        titular = {"D": "fisica", "X": "juridica"}.get(_campo(linea, 27), "desconocido")
        cod_mun = _campo(linea, 30)
        cod_mun = cod_mun.zfill(5) if cod_mun.isdigit() and int(cod_mun) > 0 else None
        cod_prov = cod_mun[:2] if cod_mun else PROV_DGT_INE.get(_campo(linea, 20))
        clave = (cod_prov, cod_mun, grupo, ener, nu, renting, titular)
        territorio[clave] += 1
        emis = _campo(linea, 34)
        if emis.isdigit() and 0 < int(emis) < 1000:
            co2[clave] += int(emis)
            co2_n[clave] += 1
        marca, modelo = limpiar_modelo(_campo(linea, 4), _campo(linea, 5))
        modelos[(grupo, ener, nu, marca, modelo)] += 1
    if descartadas:
        log.info("Matriculaciones descartadas: %s", dict(descartadas))
    return {
        "territorio": [list(k) + [n, co2[k], co2_n[k]] for k, n in territorio.items()],
        "modelos": [list(k) + [n] for k, n in modelos.items()],
    }


def _lineas_zip(zip_tmp: Path):
    """Líneas de registro del .txt de un zip de matriculaciones (sin la cabecera)."""
    with zipfile.ZipFile(zip_tmp) as z:
        nombre = next(n for n in z.namelist() if n.lower().endswith(".txt"))
        with z.open(nombre) as f:
            texto = io.TextIOWrapper(f, encoding="latin-1", newline="")
            next(texto)  # cabecera "Vehículos matriculados. Letras de la serie..."
            yield from texto


def _lineas_diarias(mes: date):
    """Todas las líneas del mes a partir de los ficheros diarios, o None si aún no está completo.

    La DGT publica el fichero diario al día siguiente, pero el mensual tarda unas dos
    semanas: sin esto, el mes anterior no aparece hasta mediados del siguiente. Los días
    sin actividad (fines de semana, festivos) no tienen fichero; como se publican en
    orden, el mes está completo si ya hay fichero del último día o de alguno posterior.
    """
    siguiente = date(mes.year + (mes.month == 12), mes.month % 12 + 1, 1)

    def _bajar(dia: date) -> Path | None:
        zip_tmp = CACHE / "tmp" / f"mat_{dia:%Y%m%d}.zip"
        if zip_tmp.exists() or _descargar(
            URL_MAT_DIA.format(anio=dia.year, mes=dia.month, fecha=f"{dia:%Y%m%d}"), zip_tmp
        ):
            return zip_tmp
        return None

    cierre = [_bajar(d) for d in _dias(siguiente - timedelta(days=1), siguiente + timedelta(days=4))]
    if not any(cierre):
        log.info("Matriculaciones diarias de %s aún sin cerrar", f"{mes:%Y-%m}")
        return None
    for z in cierre[1:]:
        if z:
            z.unlink()  # días del mes siguiente: solo servían para saber que el mes cerró
    zips = [z for z in map(_bajar, _dias(mes, siguiente)) if z]

    def _todas():
        for z in zips:
            yield from _lineas_zip(z)
            z.unlink()

    return _todas()


def _matriculaciones_mes(mes: date, refrescar: bool) -> dict | None:
    cache = CACHE / "matriculaciones" / f"{mes:%Y%m}.json.gz"
    # Mes montado con ficheros diarios: provisional hasta que salga el mensual.
    cache_diaria = CACHE / "matriculaciones" / f"{mes:%Y%m}.diario.json.gz"
    if cache.exists() and not refrescar:
        return _leer_cache(cache)
    zip_tmp = CACHE / "tmp" / f"mat_{mes:%Y%m}.zip"
    zip_tmp.parent.mkdir(parents=True, exist_ok=True)
    if _descargar(URL_MAT.format(anio=mes.year, mes=mes.month), zip_tmp):
        datos = agregar_matriculaciones(_lineas_zip(zip_tmp))
        zip_tmp.unlink()
        _guardar_cache(cache, datos)
        cache_diaria.unlink(missing_ok=True)
        return datos
    if cache_diaria.exists():
        return _leer_cache(cache_diaria)
    lineas = _lineas_diarias(mes)
    if lineas is None:
        return None
    log.info("Matriculaciones %s: sin fichero mensual aún, uso los diarios", f"{mes:%Y-%m}")
    datos = agregar_matriculaciones(lineas)
    _guardar_cache(cache_diaria, datos)
    return datos


def _meses_matriculaciones(meses_recientes: int):
    """Meses a cargar: todos desde 2015; los `meses_recientes` últimos se vuelven a pedir."""
    hoy = date.today().replace(day=1)
    ultimo = _mes_anterior(hoy)
    todos = list(_meses(PRIMER_MES, ultimo))
    for i, mes in enumerate(todos):
        refrescar = i >= len(todos) - meses_recientes
        datos = _matriculaciones_mes(mes, refrescar)
        if datos is None:
            log.info("Matriculaciones %s no disponibles (aún no publicadas o error temporal de la DGT; se reintentará)", f"{mes:%Y-%m}")
            continue
        yield mes, datos


_CLAVE_MES = {"disposition": "merge", "strategy": "delete-insert"}


@dlt.source(name="dgt")
def dgt(meses_recientes: int = 2, parque: bool = True):
    meses = None

    def _cargar_meses():
        nonlocal meses
        if meses is None:
            meses = list(_meses_matriculaciones(meses_recientes))
        return meses

    @dlt.resource(name="dgt_matriculaciones", write_disposition=_CLAVE_MES, merge_key="mes")
    def matriculaciones():
        for mes, datos in _cargar_meses():
            for cod_prov, cod_mun, grupo, ener, nu, renting, titular, n, co2, co2_n in datos["territorio"]:
                yield {
                    "mes": mes, "cod_prov": cod_prov, "cod_mun": cod_mun, "grupo": grupo,
                    "energia": ener, "nuevo_usado": nu, "renting": renting, "titular": titular,
                    "matriculaciones": n, "co2_suma": co2, "co2_n": co2_n,
                }

    @dlt.resource(name="dgt_matriculaciones_modelos", write_disposition=_CLAVE_MES, merge_key="mes")
    def matriculaciones_modelos():
        for mes, datos in _cargar_meses():
            for grupo, ener, nu, marca, modelo, n in datos["modelos"]:
                yield {
                    "mes": mes, "grupo": grupo, "energia": ener, "nuevo_usado": nu,
                    "marca": ALIAS_MARCA.get(marca, marca), "modelo": modelo_comercial(marca, modelo),
                    "modelo_ficha": modelo,
                    "matriculaciones": n,
                }

    recursos = [matriculaciones, matriculaciones_modelos]
    if parque:
        recursos += list(_recursos_parque())
    return recursos


# --------------------------------------------------------------------------
# Parque
# --------------------------------------------------------------------------

def _tramo_antiguedad(fecha_matr: str, mes: date) -> str:
    """'dd/mm/aaaa' -> tramo de antigüedad a la fecha del fichero."""
    try:
        anio = int(fecha_matr[-4:])
    except ValueError:
        return "desconocida"
    edad = mes.year - anio
    if edad < 0 or anio < 1900:
        return "desconocida"
    for tope, tramo in ((4, "0-4"), (9, "5-9"), (14, "10-14"), (19, "15-19")):
        if edad <= tope:
            return tramo
    return "20+"


def agregar_parque(filas, mes: date) -> dict:
    """filas: iterable de listas del CSV del parque; la primera es la cabecera."""
    filas = iter(filas)
    col = {c.strip().upper(): i for i, c in enumerate(next(filas))}
    i_prov, i_mun, i_sub = col["PROVINCIA"], col["MUNICIPIO"], col["SUBTIPO_DGT"]
    i_prop, i_cat, i_dist = col["PROPULSION"], col["CATELECT"], col["TIPO_DISTINTIVO"]
    i_fecha, i_marca, i_modelo = col["FECHA_MATR"], col["MARCA"], col["MODELO"]
    ancho = max(col.values()) + 1
    territorio = Counter()
    modelos = Counter()
    for f in filas:
        if len(f) < ancho:
            continue
        grupo = grupo_vehiculo(f[i_sub].strip())
        ener = energia(f[i_prop].strip(), f[i_cat].strip())
        mun = f[i_mun].strip()
        cod_mun = mun.zfill(5) if mun.isdigit() and int(mun) > 0 else None
        prov = f[i_prov].strip()
        cod_prov = cod_mun[:2] if cod_mun else (prov.zfill(2) if prov.isdigit() and 0 < int(prov) <= 52 else None)
        # "DISTINTIVO C", "DISTINTIVO ECO", "DISTINTIVO CERO"... -> C, ECO, CERO; vacío = sin distintivo
        distintivo = f[i_dist].strip().upper().replace("DISTINTIVO", "").split()
        distintivo = distintivo[0] if distintivo else "SIN"
        tramo = _tramo_antiguedad(f[i_fecha].strip(), mes)
        territorio[(cod_prov, cod_mun, grupo, ener, distintivo, tramo)] += 1
        modelos[(grupo, ener) + limpiar_modelo(f[i_marca], f[i_modelo])] += 1
    return {
        "territorio": [list(k) + [n] for k, n in territorio.items()],
        "modelos": [list(k) + [n] for k, n in modelos.items()],
    }


def _parque_mes(mes: date) -> dict | None:
    cache = CACHE / "parque" / f"{mes:%Y%m}.json.gz"
    if cache.exists():
        return _leer_cache(cache)
    zip_tmp = CACHE / "tmp" / f"parque_{mes:%Y%m}.zip"
    zip_tmp.parent.mkdir(parents=True, exist_ok=True)
    if not zip_tmp.exists() and not _descargar(URL_PARQUE.format(anio=mes.year, mes=mes.month), zip_tmp):
        return None
    with zipfile.ZipFile(zip_tmp) as z:
        nombre = next(n for n in z.namelist() if n.lower().endswith(".txt"))
        with z.open(nombre) as f:
            texto = io.TextIOWrapper(f, encoding="latin-1", newline="")
            datos = agregar_parque(csv.reader(texto, delimiter="|", quoting=csv.QUOTE_NONE), mes)
    zip_tmp.unlink()
    _guardar_cache(cache, datos)
    return datos


def _ultimo_parque():
    """Último fichero de parque publicado (se publica hacia el día 5 del mes siguiente)."""
    mes = _mes_anterior(date.today().replace(day=1))
    for _ in range(3):
        datos = _parque_mes(mes)
        if datos is not None:
            return mes, datos
        mes = _mes_anterior(mes)
    return None


def _recursos_parque():
    foto = None

    def _foto():
        nonlocal foto
        if foto is None:
            foto = _ultimo_parque() or (None, None)
        return foto

    @dlt.resource(name="dgt_parque", write_disposition=_CLAVE_MES, merge_key="mes")
    def parque():
        mes, datos = _foto()
        if datos is None:
            return
        for cod_prov, cod_mun, grupo, ener, distintivo, tramo, n in datos["territorio"]:
            yield {
                "mes": mes, "cod_prov": cod_prov, "cod_mun": cod_mun, "grupo": grupo,
                "energia": ener, "distintivo": distintivo, "antiguedad": tramo, "vehiculos": n,
            }

    @dlt.resource(name="dgt_parque_modelos", write_disposition=_CLAVE_MES, merge_key="mes")
    def parque_modelos():
        mes, datos = _foto()
        if datos is None:
            return
        for grupo, ener, marca, modelo, n in datos["modelos"]:
            yield {
                "mes": mes, "grupo": grupo, "energia": ener, "marca": ALIAS_MARCA.get(marca, marca),
                "modelo": modelo_comercial(marca, modelo), "modelo_ficha": modelo, "vehiculos": n,
            }

    return parque, parque_modelos


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("dgt").run(dgt()))
