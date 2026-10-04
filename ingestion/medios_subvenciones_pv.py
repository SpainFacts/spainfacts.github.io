"""Fuente dlt «Subvenciones a medios - Gobierno Vasco» (tema `medios_subvenciones`).

El Gobierno Vasco NO publica en la BDNS sus ayudas a medios de comunicación, así
que se leen las resoluciones de concesión del Boletín Oficial del País Vasco (BOPV,
https://www.euskadi.eus/bopv), que traen la lista de beneficiarios e importes en
tablas (muchas en páginas apaisadas, con el texto girado 90º). Programas:

  - Hedabideak (Viceconsejería de Política Lingüística, Dpto. de Cultura y Política
    Lingüística): medios de comunicación en euskera, convocatorias plurianuales
    2016-2018, 2019-2021, 2022-2024 y 2025-2028. Una fila por proyecto y ANUALIDAD
    (anio = ejercicio de la anualidad; fecha_concesion = fecha de la resolución).
  - Euskera en medios que usan principalmente el castellano (diarios, ediciones
    digitales, radios de onda y agencias): convocatoria anual 2018-2025.
  - Ayudas directas COVID-19 a prensa y radio (Acuerdo de Consejo de Gobierno de
    23-11-2021, gestor: Dirección de Gabinete y Medios de Comunicación Social de
    Lehendakaritza) y ayudas a medios diarios por la COVID-19 de 2022 (Cultura).
  - Ayudas a medios diarios profesionales para minimizar el impacto de la IA
    generativa, 2024 y 2025 (Cultura y Política Lingüística). La de 2025 se
    modificó por Orden de 21-1-2026: se guarda el importe final (importe) y el
    inicial (importe_inicial).

Las resoluciones casi nunca traen NIF (solo las COVID). El NIF de las personas
jurídicas se asigna en dbt con la seed medios_subvenciones_pv_nif (nombre -> NIF,
revisada a mano). Personas físicas (beneficiarios sin forma jurídica): sin nombre.

Recurso: pv_concesiones_medios (merge, pk cod_concesion). Cada ejecución vuelve a
descargar y leer los PDF (son estables) y comprueba que la suma de cada tabla
cuadra con el total publicado en ella; si no, falla.
"""

import io
import logging
import re
import time
import unicodedata
from datetime import datetime, timezone

import dlt
import requests

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}
BOPV = "https://www.euskadi.eus/bopv2/datos/{}"

CULTURA_PL = "DEPARTAMENTO DE CULTURA Y POLÍTICA LINGÜÍSTICA / VICECONSEJERÍA DE POLÍTICA LINGÜÍSTICA"
CULTURA = "DEPARTAMENTO DE CULTURA Y POLÍTICA LINGÜÍSTICA"
HEDABIDEAK = "Hedabideak: consolidación, desarrollo y normalización de los medios de comunicación (proyectos comunicativos) en euskera"
EG = "Euskera en los medios de comunicación que utilizan principalmente el castellano (diarios, ediciones digitales, radios de onda y agencias de noticias)"
IA = "Ayudas a medios de comunicación diarios profesionales acreditados para minimizar el impacto negativo de la inteligencia artificial generativa"

# Cada resolución: pdf (ruta en bopv2/datos), fecha de la resolución, programa, órgano,
# tipo_ayuda (como la seed BDNS), modo de lectura y total publicado (para validar).
RESOLUCIONES = [
    dict(cod="2016/5568", pdf="2016/12/1605568a.pdf", fecha="2016-12-12", programa=HEDABIDEAK + " 2016-2018",
         organo="DEPARTAMENTO DE EDUCACIÓN, POLÍTICA LINGÜÍSTICA Y CULTURA / VICECONSEJERÍA DE POLÍTICA LINGÜÍSTICA",
         tipo_ayuda="lengua", modo="anualidades", anios=[2016, 2017, 2018], orden="entidad_proyecto"),
    # La resolución de 5-12-2019 (BOPV 2020/76) salió con los anexos de otra convocatoria;
    # los anexos buenos están en la corrección de errores de 14-1-2020 (BOPV 2020/235).
    dict(cod="2020/235", pdf="2020/01/2000235a.pdf", fecha="2019-12-05", programa=HEDABIDEAK + " 2019-2021",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="anualidades", anios=[2019, 2020, 2021], orden="entidad_proyecto"),
    dict(cod="2022/5504", pdf="2022/12/2205504a.pdf", fecha="2022-11-16", programa=HEDABIDEAK + " 2022-2024",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="anualidades", anios=[2022, 2023, 2024], orden="entidad_proyecto"),
    dict(cod="2025/5359", pdf="2025/12/2505359a.pdf", fecha="2025-11-27", programa=HEDABIDEAK + " 2025-2028",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="anualidades", anios=[2025, 2026, 2027, 2028], orden="entidad_proyecto"),
    dict(cod="2018/5403", pdf="2018/11/1805403a.pdf", fecha="2018-10-08", programa=EG + " 2018",
         organo="DEPARTAMENTO DE CULTURA Y POLÍTICA LINGÜÍSTICA / VICECONSEJERÍA DE POLÍTICA LINGÜÍSTICA",
         tipo_ayuda="lengua", modo="unico", anio=2018, orden="entidad_proyecto"),
    dict(cod="2020/75", pdf="2020/01/2000075a.pdf", fecha="2019-12-05", programa=EG + " 2019",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="unico", anio=2019, orden="entidad_proyecto"),
    dict(cod="2020/5086", pdf="2020/11/2005086a.pdf", fecha="2020-11-13", programa=EG + " 2020",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="unico", anio=2020, orden="entidad_proyecto"),
    dict(cod="2021/5976", pdf="2021/11/2105976a.pdf", fecha="2021-11-16", programa=EG + " 2021",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="unico", anio=2021, orden="entidad_proyecto"),
    dict(cod="2022/4515", pdf="2022/10/2204515a.pdf", fecha="2022-09-15", programa=EG + " 2022",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="unico", anio=2022, orden="entidad_proyecto"),
    dict(cod="2023/4466", pdf="2023/09/2304466a.pdf", fecha="2023-08-08", programa=EG + " 2023",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="unico", anio=2023, orden="entidad_proyecto"),
    dict(cod="2024/3809", pdf="2024/08/2403809a.pdf", fecha="2024-07-12", programa=EG + " 2024",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="unico", anio=2024, orden="entidad_proyecto"),
    dict(cod="2025/5358", pdf="2025/12/2505358a.pdf", fecha="2025-11-21", programa=EG + " 2025",
         organo=CULTURA_PL, tipo_ayuda="lengua", modo="unico", anio=2025, orden="entidad_proyecto"),
    dict(cod="2021/6167", pdf="2021/12/2106167a.pdf", fecha="2021-11-23",
         programa="Subvenciones directas 2021 a medios de comunicación de prensa y radio con sede o delegación en Euskadi por la afección económica de la COVID-19",
         organo="LEHENDAKARITZA / DIRECCIÓN DE GABINETE Y MEDIOS DE COMUNICACIÓN SOCIAL (Acuerdo de Consejo de Gobierno)",
         tipo_ayuda="estructural", modo="covid2021", anio=2021, orden="medio_entidad"),
    dict(cod="2022/5503", pdf="2022/12/2205503a.pdf", fecha="2022-12-02",
         programa="Ayudas 2022 a medios de comunicación diarios con motivo de la afección de la pandemia de la COVID-19",
         organo=CULTURA, tipo_ayuda="estructural", modo="unico", anio=2022, orden="exp_entidad"),
    dict(cod="2024/5192", pdf="2024/11/2405192a.pdf", fecha="2024-11-07", programa=IA + " 2024",
         organo=CULTURA, tipo_ayuda="digitalizacion_ia", modo="unico", anio=2024, orden="exp_entidad"),
    dict(cod="2025/3449", pdf="2025/08/2503449a.pdf", fecha="2025-07-29", programa=IA + " 2025",
         organo=CULTURA, tipo_ayuda="digitalizacion_ia", modo="unico", anio=2025, orden="exp_entidad",
         modificacion="2026/01/2600447a.pdf"),
]

RE_EXP = re.compile(r"^\d{3}[-.][A-Z]{2,3}\d?-\s*(\d{4})?$")
RE_EUR = re.compile(r"^\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?\s*€?$")
RE_NIF = re.compile(r"^[A-HJ-NP-SUVW]\d{7}[0-9A-J]$")
RE_TOTAL = re.compile(r"total|guztira", re.I)
# Formas jurídicas o palabras de entidad: si el nombre no tiene ninguna, se trata como persona física
RE_ENTIDAD = re.compile(
    r"\b(s\.?\s?l\.?u?|s\.?\s?a\.?u?|s\.?\s?a\.?\s?l|sl|sa|slu|sau|sal|koop|coop|cooperativa|kooperatiba|elkartea|elk|"
    r"elkarte|fundazioa|fundacion|fundación|asociaci[oó]n|asoc|kultur|taldea|bazkuna|sociedad|sdad|radio|irratia?|"
    r"irrati|telebista|hedabideak|komunikabideak|komunikazio|komunikazioa|ikusentzunezkoak|editorial|ediciones|"
    r"argitaletxea?|carmelitas|convento|universitario|unibertsitatea|u\.e\.u|ikastolak|klusterra|center|instituto|"
    r"europa press|prensa|medios|iniciativas|grupo|uniprex|diario|aldizkaria|elkartea|s\.?\s?coop|herri|ekimenekoa|"
    r"federazioa|federaci[oó]n)\b",
    re.I)
# Entidades sin forma jurídica reconocible en el nombre (revisadas a mano)
NO_PERSONA_FISICA = {"GEU Gasteiz Euskalduna"}


def _eur(s):
    s = (s or "").replace("€", "").replace(",,", ",").strip()
    if not s:
        return None
    return float(s.replace(".", "").replace(",", "."))


def _limpia(s):
    return " ".join((s or "").split()).strip(" ,;")


def es_persona_fisica(nombre: str) -> bool:
    nombre = unicodedata.normalize("NFC", nombre or "").strip()
    return nombre not in NO_PERSONA_FISICA and not RE_ENTIDAD.search(nombre)


def _rot_chars(chars, alto):
    out = []
    for c in chars:
        d = dict(c)
        # texto que se lee de abajo arriba (página apaisada): x' = alto - bottom, top' = x0
        d["x0"], d["x1"] = alto - c["bottom"], alto - c["top"]
        d["top"], d["bottom"] = c["x0"], c["x1"]
        d["doctop"] = d["top"]
        d["upright"] = True
        out.append(d)
    return out


def tablas_pdf(contenido: bytes):
    """Tablas del PDF (filas de celdas de texto), con las páginas apaisadas giradas a lectura normal."""
    import pdfplumber
    from pdfplumber.utils import extract_text

    res = []
    with pdfplumber.open(io.BytesIO(contenido)) as pdf:
        for pg in pdf.pages:
            girada = sum(1 for c in pg.chars if not c.get("upright")) > len(pg.chars) / 2
            for t in pg.find_tables():
                filas = []
                for row in t.rows:
                    celdas = []
                    for cb in row.cells:
                        if cb is None:
                            celdas.append(None)
                            continue
                        x0, top, x1, bottom = cb
                        ch = [c for c in pg.chars
                              if x0 <= (c["x0"] + c["x1"]) / 2 <= x1 and top <= (c["top"] + c["bottom"]) / 2 <= bottom]
                        if girada:
                            ch = _rot_chars(ch, pg.height)
                        celdas.append(" ".join(extract_text(ch, x_tolerance=1.5, y_tolerance=2).split()) if ch else "")
                    filas.append(celdas)
                if girada:
                    ncol = max(len(f) for f in filas)
                    filas = [list(reversed(x)) for x in zip(*[f + [None] * (ncol - len(f)) for f in filas])]
                res.append(filas)
    return res


def _baja(ruta: str) -> bytes:
    url = BOPV.format(ruta)
    for intento in range(4):
        try:
            r = requests.get(url, headers=CABECERAS, timeout=90)
            r.raise_for_status()
            if not r.content.startswith(b"%PDF"):
                raise RuntimeError("no es un PDF")
            time.sleep(1.5)
            return r.content
        except Exception as e:  # noqa: BLE001
            log.warning("BOPV %s intento %d: %s", url, intento + 1, e)
            time.sleep(5 * (intento + 1))
    raise RuntimeError(f"No se pudo descargar {url}")


def lee_resolucion(res: dict, contenido: bytes, modificacion: bytes | None = None):
    """Devuelve (filas, comprobaciones). filas: una por proyecto/beneficiario (y anualidad).
    comprobaciones: lista de (tabla, suma_leida, total_publicado)."""
    finales = {}
    if modificacion:
        for tabla in tablas_pdf(modificacion):
            for f in tabla:
                txt = [_limpia(c) for c in f if c and _limpia(c)]
                exp = next((t for t in txt if RE_EXP.match(t)), None)
                imp = [t for t in txt if RE_EUR.match(t) and "," in t]
                if exp and len(imp) >= 2:
                    finales[exp.replace(" ", "")] = (_eur(imp[0]), _eur(imp[1]))

    filas, comprob = [], []
    n_anios = len(res.get("anios") or [])
    # suma acumulada desde el último «Total»: las tablas largas siguen en la página siguiente
    suma = 0.0

    def _cierra(total_pub, it):
        nonlocal suma
        if suma:  # los cuadros resumen (sin filas propias) no se comprueban
            comprob.append((it, round(suma, 2), total_pub))
        suma = 0.0

    for it, tabla in enumerate(tablas_pdf(contenido)):
        previo = None
        for f in tabla:
            pos = [(i, _limpia(c)) for i, c in enumerate(f) if c is not None and _limpia(c)]
            txt = [t for _, t in pos]
            if not txt:
                continue
            # «Total Línea 1 5.944.257,27» viene a veces en una sola celda
            if len(txt) == 1 and RE_TOTAL.search(txt[0]):
                m = re.search(r"(\d{1,3}(?:\.\d{3})+,\d{2})", txt[0])
                if m:
                    _cierra(_eur(m.group(1)), it)
                continue
            importes = [t for t in txt if RE_EUR.match(t) and ("," in t or "€" in t or "." in t)]
            exp = next((t for t in txt if RE_EXP.match(t)), None)
            nif = next((t for t in txt if RE_NIF.match(t)), None)
            if any(RE_TOTAL.search(t) for t in txt):
                if importes:
                    if res["modo"] == "anualidades":
                        _cierra(_eur(importes[n_anios]) if len(importes) > n_anios else None, it)
                    elif res["modo"] == "covid2021":
                        _cierra(_eur(importes[-1]), it)
                    else:
                        _cierra(_eur(importes[0]), it)
                continue
            textos = [t for t in txt if not RE_EUR.match(t) and not RE_EXP.match(t) and not RE_NIF.match(t)]
            if res["modo"] == "covid2021":
                if not nif or not importes:
                    continue
                medio, entidad = (textos + ["", ""])[:2]
                proyecto, imp = medio, _eur(importes[-1])
            elif not exp:
                # continuación de un nombre partido en dos filas
                # (se añade a la entidad o al proyecto según la columna en que cae el texto)
                if previo is not None and textos and not importes:
                    grupo = ([g for g in filas if g["cod_concesion"].rsplit("-", 1)[0] == previo["cod_concesion"].rsplit("-", 1)[0]]
                             if res["modo"] == "anualidades" else [previo])
                    for i, t in pos:
                        campo = "beneficiario_nombre_bopv" if i <= previo["_col_entidad"] else "proyecto"
                        for g in grupo:
                            g[campo] = _limpia((g[campo] or "") + " " + t)
                continue
            else:
                if res["orden"] == "exp_entidad":
                    entidad = textos[0] if textos else ""
                    proyecto = textos[1] if len(textos) > 1 else None
                else:
                    entidad = textos[0] if textos else ""
                    proyecto = textos[1] if len(textos) > 1 else None
                if not importes:
                    continue
            exp_c = (exp or "").replace(" ", "").replace(".", "-")
            base = dict(
                cod_bopv=res["cod"], url_bopv=BOPV.format(res["pdf"]), convocatoria=res["programa"],
                fecha_concesion=res["fecha"], organo=res["organo"], tipo_ayuda=res["tipo_ayuda"],
                expediente=exp_c or None, linea=(exp_c.split("-")[1] if exp_c.count("-") >= 2 else None),
                beneficiario_nif=nif, beneficiario_nombre_bopv=entidad, proyecto=proyecto,
                _col_entidad=next((i for i, t in pos if t == entidad), 0),
            )
            if res["modo"] == "anualidades":
                anuales = [_eur(x) for x in importes[:n_anios]]
                total = _eur(importes[n_anios]) if len(importes) > n_anios else None
                if total is not None and abs(sum(anuales) - total) > 0.05:
                    raise RuntimeError(f"{res['cod']} {exp_c}: anualidades {anuales} no suman {total}")
                suma += total if total is not None else sum(anuales)
                for anio, imp in zip(res["anios"], anuales):
                    filas.append(dict(base, cod_concesion=f"BOPV-{res['cod'].replace('/', '-')}-{exp_c}-{anio}",
                                      anio=anio, importe=imp, importe_inicial=imp, importe_total_resolucion=total))
                previo = filas[-1]
            else:
                imp = _eur(importes[0]) if res["modo"] != "covid2021" else _eur(importes[-1])
                inicial = imp
                if finales and exp_c in finales:
                    inicial, imp = finales[exp_c]
                suma += inicial
                clave = exp_c or nif
                filas.append(dict(base, cod_concesion=f"BOPV-{res['cod'].replace('/', '-')}-{clave}",
                                  anio=res["anio"], importe=imp, importe_inicial=inicial, importe_total_resolucion=imp))
                previo = filas[-1]
    if suma:
        comprob.append(("final", round(suma, 2), None))  # filas sin «Total» detrás: no cuadra
    return filas, comprob


@dlt.source(name="medios_subvenciones_pv")
def medios_subvenciones_pv():
    ahora = datetime.now(timezone.utc).isoformat(timespec="seconds")

    @dlt.resource(name="pv_concesiones_medios", write_disposition="merge", primary_key="cod_concesion")
    def pv_concesiones_medios():
        for res in RESOLUCIONES:
            contenido = _baja(res["pdf"])
            modif = _baja(res["modificacion"]) if res.get("modificacion") else None
            filas, comprob = lee_resolucion(res, contenido, modif)
            for it, suma, total in comprob:
                if total is not None and abs(suma - total) > 0.05:
                    raise RuntimeError(f"BOPV {res['cod']} tabla {it}: suma leída {suma} != total publicado {total}")
            vistos = set()
            for f in filas:
                if f["cod_concesion"] in vistos:
                    raise RuntimeError(f"Clave repetida {f['cod_concesion']}")
                vistos.add(f["cod_concesion"])
                pf = es_persona_fisica(f["beneficiario_nombre_bopv"])
                f.pop("_col_entidad", None)
                yield dict(
                    f,
                    beneficiario_nombre_bopv=None if pf else f["beneficiario_nombre_bopv"],
                    proyecto=None if pf else f["proyecto"],
                    es_persona_fisica=pf,
                    concedente_nivel1="AUTONOMICA",
                    concedente_nivel2="PAÍS VASCO",
                    concedente_nivel3=f["organo"],
                    modificacion_url=BOPV.format(res["modificacion"]) if res.get("modificacion") else None,
                    descargado=ahora,
                )
            log.info("BOPV %s: %d filas", res["cod"], len(filas))

    return pv_concesiones_medios
