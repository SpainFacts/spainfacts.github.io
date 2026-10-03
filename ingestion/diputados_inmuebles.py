"""Fuente dlt: inmuebles y alquileres en las declaraciones de bienes de los diputados.

Pregunta: ¿cuántos diputados del Congreso declaran ser caseros?

Fuentes (Congreso de los Diputados, Registro de Intereses):
- Composición de la legislatura: buscador de diputados del Congreso
  (``/es/busqueda-de-diputados``, recurso ``searchDiputados``, JSON con
  codParlamentario, grupo, formación, circunscripción, alta y baja). Es la misma
  información que el fichero de datos abiertos ``DiputadosActivos``/
  ``DiputadosDeBaja`` (https://www.congreso.es/es/opendata/diputados), que no
  trae el identificador del diputado.
- Declaración de Bienes y Rentas (art. 160.2 LOREG): un PDF por diputado
  enlazado desde su ficha (``/docbienes/leg15/...pdf``). Son ESCANEOS (imagen
  con un sello del registro): pdfplumber no saca texto, así que cada página se
  rasteriza (pypdfium2) y se pasa por el OCR de Windows (Windows.Media.Ocr,
  es-ES; ver ingestion/ocr_windows.ps1). Si algún PDF trae texto, se usa
  pdfplumber directamente.
  Solo los diputados en activo tienen el enlace en su ficha: los dados de baja y
  los de la XIV Legislatura ya no lo muestran, de modo que el análisis cubre los
  diputados en activo de la XV.

Formulario (modelo común Congreso/Senado):
- "Bienes patrimoniales": filas de inmuebles de naturaleza urbana, rústica y
  propiedad de sociedades no cotizadas, con clase (piso, garaje, solar...),
  situación (provincia), fecha de adquisición y "derecho sobre el bien y título"
  (pleno dominio, ganancial, 50 %, nuda propiedad...).
- "Rentas percibidas": salariales, dividendos, intereses y "OTRAS rentas o
  percepciones de cualquier clase". NO hay una casilla de rendimientos del
  capital inmobiliario: los alquileres se declaran, cuando se declaran, como
  "otras rentas" con un concepto de texto libre ("alquiler vivienda",
  "arrendamiento local", "rendimientos capital inmobiliario"...). Se detectan
  por palabras clave en el concepto; el importe es el de esa fila.
  Las rentas son las del ejercicio anterior a la fecha de la declaración.

Proceso en dos partes (como ingestion/gem.py):
1. ``python -m ingestion.diputados_inmuebles --extraer`` (solo Windows): descarga
   lista, fichas y PDF con calma (caché en data/congreso_cache/, no versionada),
   hace el OCR, interpreta cada declaración y escribe los extractos versionados
   ingestion/datos/diputados_inmuebles_{declaraciones,inmuebles,rentas}.csv.
   ``--revisar <codParlamentario>`` imprime lo interpretado de una declaración.
2. Los recursos dlt leen SOLO esos extractos (sin red ni OCR): la carga en Dagster
   (Linux) es reproducible. Recursos con prefijo ``cong_``.

Definiciones (capas de "casero", calculadas en dbt):
- n_urbanos: filas de inmuebles urbanos (incluye garajes y trasteros).
- n_viviendas_urbanas: urbanos cuya clase es una vivienda (piso, casa, chalet...).
- urbanos_equivalentes: suma de la fracción de titularidad de cada urbano: el %
  declarado si consta; 0,5 si consta "ganancial" o "comunidad"/"proindiviso"
  sin %; 1 en el resto (pleno dominio, privativo, usufructo, nuda propiedad).
- rend_capital_inmobiliario_eur: suma de las rentas cuyo concepto es un alquiler.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import subprocess
import sys
import time
import unicodedata
from datetime import datetime
from pathlib import Path

import dlt
import requests

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE = REPO_ROOT / "data" / "congreso_cache"
DATOS = Path(__file__).resolve().parent / "datos"
EXT_DECL = DATOS / "diputados_inmuebles_declaraciones.csv"
EXT_INM = DATOS / "diputados_inmuebles_inmuebles.csv"
EXT_REN = DATOS / "diputados_inmuebles_rentas.csv"
OCR_PS1 = Path(__file__).resolve().parent / "ocr_windows.ps1"

BASE = "https://www.congreso.es"
UA = "Mozilla/5.0 (SpainFacts; datos abiertos; +https://spainfacts.org)"
LEG_ROMANO = {14: "XIV", 15: "XV"}
ESCALA = 2.5  # píxeles por punto PDF al rasterizar (≈180 ppp)

_ses = requests.Session()
_ses.headers["User-Agent"] = UA


# --------------------------------------------------------------------------- red
def _get(url: str, **kw) -> requests.Response:
    for intento in range(4):
        try:
            r = _ses.get(url, timeout=60, **kw)
            if r.status_code == 200:
                return r
            if r.status_code in (403, 404):
                r.raise_for_status()
        except requests.RequestException:
            if intento == 3:
                raise
        time.sleep(5 * (intento + 1))
    r.raise_for_status()
    return r


def lista_diputados(leg: int) -> list[dict]:
    """Todos los diputados de la legislatura (en activo y de baja) del buscador del Congreso."""
    destino = CACHE / f"lista_leg{leg}.json"
    if not destino.exists() or time.time() - destino.stat().st_mtime > 86400:
        url = (f"{BASE}/es/busqueda-de-diputados?p_p_id=diputadomodule&p_p_lifecycle=2&p_p_state=normal"
               "&p_p_mode=view&p_p_resource_id=searchDiputados&p_p_cacheability=cacheLevelPage")
        datos = {"_diputadomodule_idLegislatura": str(leg), "_diputadomodule_genero": "0",
                 "_diputadomodule_grupo": "all", "_diputadomodule_tipo": "2",
                 "_diputadomodule_nombre": "", "_diputadomodule_apellidos": "",
                 "_diputadomodule_formacion": "all", "_diputadomodule_filtroProvincias": "[]",
                 "_diputadomodule_nombreCircunscripcion": ""}
        r = _ses.post(url, data=datos, timeout=60)
        r.raise_for_status()
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_bytes(r.content)
    return json.loads(destino.read_text(encoding="utf-8"))["data"]


def enlace_bienes(leg: int, cod: int) -> str | None:
    """URL de la declaración de bienes y rentas INICIAL (la primera de la ficha) o None.

    La ficha enlaza todas: la inicial (``_000_``) y las modificaciones (``_001_``...). Las
    modificaciones suelen ser parciales ("en el resto me remito a la declaración anterior"), así que
    el análisis usa la inicial: misma foto para todos (inicio de la legislatura)."""
    todas = enlaces_bienes(leg, cod)
    return todas[0] if todas else None


def enlaces_bienes(leg: int, cod: int) -> list[str]:
    """Todas las declaraciones de bienes de la ficha, de la más antigua a la más reciente."""
    destino = CACHE / "fichas" / f"leg{leg}_{cod}.html"
    if not destino.exists():
        url = (f"{BASE}/es/busqueda-de-diputados?p_p_id=diputadomodule&p_p_lifecycle=0&p_p_state=normal"
               f"&p_p_mode=view&_diputadomodule_mostrarFicha=true&codParlamentario={cod}"
               f"&idLegislatura={LEG_ROMANO[leg]}")
        r = _get(url)
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_bytes(r.content)
        time.sleep(1.0)
    html = destino.read_text(encoding="utf-8", errors="replace")
    m = sorted(set(re.findall(r'href="(/docbienes/[^"]+\.pdf)"', html)),
               key=lambda u: (re.search(r"_(\d{8})\.pdf$", u).group(1), u))
    return [BASE + u for u in m]


def pdf_local(url: str) -> Path:
    destino = CACHE / "pdf" / url.split("/docbienes/")[1].replace("/", "_")
    if not destino.exists():
        r = _get(url)
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_bytes(r.content)
        time.sleep(1.0)
    return destino


# --------------------------------------------------------------------------- OCR
def paginas_ocr(pdf: Path) -> list[dict]:
    """Por página: {'ancho','alto','lineas':[{'t', 'w':[{'t','x','y','w','h'}]}], 'img'}."""
    import pdfplumber
    import pypdfium2

    carpeta = CACHE / "ocr" / pdf.stem
    carpeta.mkdir(parents=True, exist_ok=True)
    doc = pypdfium2.PdfDocument(str(pdf))
    n = len(doc)

    # ¿Trae texto de verdad? (los escaneos solo traen el sello "C.DIP ...")
    with pdfplumber.open(str(pdf)) as p:
        texto = "".join((pg.extract_text() or "") for pg in p.pages)
        con_texto = len(re.sub(r"\s", "", texto)) > 300 * n
        if con_texto and os.environ.get("DIPINM_USAR_TEXTO"):  # la capa de texto existente suele ser un OCR malo
            paginas = []
            for pg in p.pages:
                lineas = {}
                for w in pg.extract_words(keep_blank_chars=False):
                    clave = round(w["top"] / 3)
                    lineas.setdefault(clave, []).append(
                        {"t": w["text"], "x": int(w["x0"] * ESCALA), "y": int(w["top"] * ESCALA),
                         "w": int((w["x1"] - w["x0"]) * ESCALA), "h": int((w["bottom"] - w["top"]) * ESCALA)})
                paginas.append({"ancho": int(pg.width * ESCALA), "alto": int(pg.height * ESCALA),
                                "lineas": [{"t": " ".join(x["t"] for x in ws), "w": ws} for ws in lineas.values()],
                                "img": None, "origen": "texto"})
            return paginas

    pendientes = []
    for i in range(n):
        png = carpeta / f"p{i}.png"
        js = carpeta / f"p{i}.json"
        if not png.exists():
            doc[i].render(scale=ESCALA).to_pil().convert("L").save(png)
        if not js.exists():
            pendientes.append(f"{png}\t{js}")
    if pendientes:
        lista = carpeta / "lista.txt"
        lista.write_text("\n".join(pendientes), encoding="utf-8")
        subprocess.run(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(OCR_PS1),
                        str(lista)], check=True, capture_output=True, timeout=600)
    paginas = []
    for i in range(n):
        js = carpeta / f"p{i}.json"
        d = json.loads(js.read_text(encoding="utf-8-sig")) if js.exists() else {"ancho": 0, "alto": 0, "lineas": []}
        if isinstance(d.get("lineas"), dict):
            d["lineas"] = [d["lineas"]]
        for l in d["lineas"]:
            if isinstance(l.get("w"), dict):
                l["w"] = [l["w"]]
        d["img"] = str(carpeta / f"p{i}.png")
        _enderezar(d, carpeta / f"p{i}.png")
        d["origen"] = "ocr (el PDF traía capa de texto)" if con_texto else "ocr"
        paginas.append(d)
    return paginas


def _inclinacion(png: Path) -> float:
    """Ángulo (grados, antihorario) que endereza el escaneo: el que maximiza el perfil horizontal."""
    from PIL import Image

    im = Image.open(png).convert("L")
    pequena = im.resize((im.width // 4, im.height // 4)).point(lambda v: 255 if v < 200 else 0)
    mejor, angulo = -1.0, 0.0
    for k in range(-30, 31):
        a = k / 10
        rot = pequena.rotate(a, resample=Image.Resampling.BILINEAR, fillcolor=0)
        perfil = rot.resize((1, rot.height), Image.Resampling.BOX).tobytes()
        puntuacion = sum(v * v for v in perfil)
        if puntuacion > mejor:
            mejor, angulo = puntuacion, a
    return angulo


def _enderezar(d: dict, png: Path) -> None:
    """Si la página está torcida, guarda una copia enderezada y lleva a ella las cajas del OCR."""
    import math

    from PIL import Image

    fich = png.with_name(png.stem + "_ang.txt")
    if fich.exists():
        a = float(fich.read_text())
    else:
        a = _inclinacion(png)
        fich.write_text(str(a))
    if abs(a) < 0.15:
        return
    recta = png.with_name(png.stem + "_d.png")
    if not recta.exists():
        Image.open(png).convert("L").rotate(a, resample=Image.Resampling.BILINEAR, fillcolor=255).save(recta)
    cx, cy = d.get("ancho", 0) / 2, d.get("alto", 0) / 2
    t = math.radians(a)
    c, s = math.cos(t), math.sin(t)
    for l in d["lineas"]:
        for w in l["w"]:
            mx, my = w["x"] + w["w"] / 2 - cx, w["y"] + w["h"] / 2 - cy
            nx, ny = cx + mx * c + my * s, cy - mx * s + my * c
            w["x"], w["y"] = int(nx - w["w"] / 2), int(ny - w["h"] / 2)
    d["img"] = str(recta)
    d["inclinacion"] = a


# --------------------------------------------------------------------------- interpretación
def _norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode()
    return re.sub(r"\s+", " ", s).strip().lower()


_IMG_CACHE: dict = {}
_OSCURO = bytes(1 if v < 200 else 0 for v in range(256))


def _imagen(ruta):
    from PIL import Image

    if ruta not in _IMG_CACHE:
        _IMG_CACHE.clear()
        _IMG_CACHE[ruta] = Image.open(ruta).convert("L")
    return _IMG_CACHE[ruta]


def _reglas(img_path: str | None, x0: int, x1: int, y0: int, y1: int, horizontal: bool, umbral=0.6):
    """Posiciones de las líneas de la tabla (horizontales: y; verticales: x) en una banda.

    Una línea es una fila (o columna) con un tramo continuo de píxeles oscuros que ocupa al menos
    `umbral` del ancho de la banda. Las líneas de los escaneos son de 1 px, grises y algo
    inclinadas: se binariza con umbral alto (<200) y se engorda ±2 px en perpendicular, de modo
    que el texto (con huecos entre letras) no llega a formar tramos largos.
    """
    if not img_path:
        return []
    from PIL import Image, ImageChops

    img = _imagen(img_path)
    x0, x1 = max(0, int(x0)), min(img.width, int(x1))
    y0, y1 = max(0, int(y0)), min(img.height, int(y1))
    if x1 - x0 < 5 or y1 - y0 < 5:
        return []
    banda = img.crop((x0, y0, x1, y1))
    if not horizontal:
        banda = banda.transpose(Image.Transpose.TRANSPOSE)
    gruesa = banda
    for d in (-2, -1, 1, 2):
        gruesa = ImageChops.darker(gruesa, ImageChops.offset(banda, 0, d))
    w, h = gruesa.size
    datos = gruesa.tobytes().translate(_OSCURO)
    minimo = umbral * w
    pos, previo = [], -10
    for i in range(h):
        fila = datos[i * w:(i + 1) * w]
        if fila.count(1) < minimo:
            continue
        mayor = max((len(t) for t in fila.split(bytes(1))), default=0)
        if mayor >= minimo:
            if i - previo > 6:
                pos.append(i)
            previo = i
    base = y0 if horizontal else x0
    return [p + base + 2 for p in pos]


IMPORTE = re.compile(r"-?\d{1,3}(?:[.\s]\d{3})*(?:,\d{1,2})?|-?\d+(?:,\d{1,2})?")


def _importe(txt: str) -> float | None:
    t = txt.replace("€", "").replace("EUR", "").strip()
    t = re.sub(r"(?<=\d)\s+(?=\d{3}\b)", ".", t)
    m = re.findall(r"\d[\d.]*(?:,\d{1,2})?", t)
    if not m:
        return None
    v = max(m, key=len)
    # "55.348,17" / "2.900" / "1234,5" / "1234.56"
    if "," in v:
        v = v.replace(".", "").replace(",", ".")
    elif re.fullmatch(r"\d{1,3}(\.\d{3})+", v):
        v = v.replace(".", "")
    elif re.fullmatch(r"\d+\.\d{1,2}", v):
        pass
    else:
        v = v.replace(".", "")
    try:
        return float(v)
    except ValueError:
        return None


ALQUILER = re.compile(r"alquil|arrend|arriend|capital inmob|rendimiento.{0,25}inmueb|rentas? inmob|"
                      r"renta (del? )?(piso|local|vivienda|inmueble|nave|garaje|apartamento)|cesion.{0,12}(uso|vivienda|local)|"
                      r"apartamento turistico|vivienda turistica|vacacional", re.I)
NO_ALQUILER = re.compile(r"gasto|pago de alquiler|pagado|abonad|indemniz|vehiculo|coche|maquinaria|equipo|"
                         r"dividend|participaci|imputad|imputaci|a disposicion", re.I)


def _es_alquiler(renta: dict) -> bool:
    """Renta procedente de alquilar inmuebles (no dividendos de una inmobiliaria ni alquileres pagados)."""
    c = _norm(renta["concepto"])
    return bool(ALQUILER.search(c)) and not NO_ALQUILER.search(c)


VIVIENDA = re.compile(r"vivi?enda|piso|casa|chalet|apartamento|atico|duplex|adosad|unifamiliar|estudio|"
                      r"bajo\b|planta baja|loft|bungalow|caserio|masia|cortijo|residencial", re.I)
REMISION = re.compile(r"me remito|nos remitimos|remite a|vease|ver anexo|segun anexo|en anexo|anexo adjunto|"
                      r"ver declaracion|declaracion (anterior|correspondiente|de la xiv|presentada)|ver documento", re.I)
ANEXO = re.compile(r"garaje|plaza|aparcamiento|parking|trastero|cochera|cuarto|almacen", re.I)


def _palabras(pagina):
    for l in pagina["lineas"]:
        for w in l["w"]:
            yield w


def _lineas_en(pagina, x0, x1, y0, y1):
    """Texto (agrupado por línea OCR) cuyas palabras caen en el rectángulo."""
    res = []
    for l in pagina["lineas"]:
        ws = [w for w in l["w"] if x0 <= w["x"] + w["w"] / 2 <= x1 and y0 <= w["y"] + w["h"] / 2 <= y1]
        if ws:
            res.append((min(w["y"] for w in ws), min(w["x"] for w in ws), " ".join(w["t"] for w in ws)))
    return sorted(res)


def _buscar(pagina, patron, x_max=None):
    """Primera línea cuyo texto normalizado casa con el patrón: (x, y, línea)."""
    for l in pagina["lineas"]:
        if re.search(patron, _norm(l["t"])):
            w0 = l["w"][0]
            if x_max is None or w0["x"] <= x_max:
                return w0["x"], w0["y"], l
    return None


def _tabla_inmuebles(pagina):
    """Filas de inmuebles de una página con la tabla de "Bienes patrimoniales"."""
    titulo = _buscar(pagina, r"bienes patrimoniales")
    cab_clase = _buscar(pagina, r"c.ase y caract|y caracter.stica")
    if not cab_clase:
        return None
    ancho = pagina["ancho"]
    y_cab = cab_clase[1]
    fin = _buscar(pagina, r"depositos en cuentas|depositos en cuenta|otros tipos de imposic")
    y_fin = fin[1] - 10 if fin else pagina["alto"] - 300
    # Columna izquierda ("BIENES") y su etiqueta de sección
    etiquetas = []
    for patron, tipo in ((r"naturaleza urbana|^urbana\.?$", "urbano"), (r"naturaleza rustica|^rustica\.?$", "rustico"),
                         (r"propiedad de una|sociedad,?$", "sociedad")):
        e = _buscar(pagina, patron, x_max=cab_clase[0] - 50)
        if e:
            etiquetas.append((e[1], tipo, e[0]))
    if not etiquetas:
        # Página de continuación sin etiquetas: se asume urbana
        etiquetas = [(y_cab, "urbano", 150)]
    x_izq = min(e[2] for e in etiquetas)
    # Líneas verticales de la tabla (en la banda de las filas)
    vert = _reglas(pagina["img"], 0, ancho, y_cab + 60, y_fin, horizontal=False, umbral=0.5)
    vert = [v for v in vert if v > x_izq + 40]
    # Columnas: clase | situación | fecha | derecho
    cab = {k: _buscar(pagina, p) for k, p in (("sit", r"^situaci"), ("fecha", r"fecha de$|^fecha de"),
                                                ("der", r"derecho sobre"))}
    xs_cab = [cab_clase[0]] + [c[0] for c in cab.values() if c]
    if len(vert) >= 4:
        lim = sorted(vert)
        col_clase0 = lim[0]
        # límites a la derecha de cada cabecera
        def siguiente(x):
            mayores = [v for v in lim if v > x + 20]
            return mayores[0] if mayores else ancho
        c_clase = (col_clase0, siguiente(cab_clase[0]))
        c_sit = (c_clase[1], siguiente(c_clase[1] + 5))
        c_fecha = (c_sit[1], siguiente(c_sit[1] + 5))
        c_der = (c_fecha[1], siguiente(c_fecha[1] + 5) if siguiente(c_fecha[1] + 5) < ancho else ancho)
    else:
        xs = sorted(xs_cab)
        if len(xs) < 4:
            return None
        c_clase = (xs[0] - 80, xs[1] - 30)
        c_sit = (xs[1] - 30, xs[2] - 15)
        c_fecha = (xs[2] - 15, xs[3] - 10)
        c_der = (xs[3] - 10, ancho)
    # Líneas horizontales en las columnas de datos: separan filas
    horiz = _reglas(pagina["img"], c_clase[0] + 5, c_der[0] - 5, y_cab + 20, y_fin + 30, horizontal=True, umbral=0.6)
    # Fondo de la cabecera (la línea que la separa a veces no se detecta por la inclinación del escaneo)
    cabecera = [w["y"] + w["h"] for l in pagina["lineas"] if y_cab - 60 < l["w"][0]["y"] < y_cab + 80
                and re.search(r"adquisici|caracter|situaci|derecho sobre|el bien", _norm(l["t"])) for w in l["w"]]
    y_hb = (max(cabecera) if cabecera else y_cab + 40) + 3
    horiz = [y_hb] + [h for h in horiz if h > y_hb + 8]
    # Líneas que cruzan también la columna izquierda: separan secciones
    horiz_izq = set()
    for h in _reglas(pagina["img"], x_izq + 10, c_clase[0] - 10, y_cab + 20, y_fin + 30, horizontal=True, umbral=0.6):
        horiz_izq.add(h)
    if len(horiz) < 2:
        return None
    filas = []
    secciones = sorted(horiz_izq)

    def seccion_de(y):
        # sección = etiqueta situada entre las mismas líneas de sección que la fila
        lims = [y_cab] + secciones + [y_fin + 30]
        for a, b in zip(lims, lims[1:]):
            if a <= y < b:
                for ye, tipo, _ in etiquetas:
                    if a <= ye < b:
                        return tipo
        # sin líneas de sección: etiqueta más cercana por encima/debajo
        return min(etiquetas, key=lambda e: abs(e[0] - y))[1]

    for a, b in zip(horiz, horiz[1:]):
        if b - a < 25 or a < y_hb - 5:
            continue
        clase = " ".join(t for _, _, t in _lineas_en(pagina, *c_clase, a - 6, b - 6))
        sit = " ".join(t for _, _, t in _lineas_en(pagina, *c_sit, a - 6, b - 6))
        fecha = " ".join(t for _, _, t in _lineas_en(pagina, *c_fecha, a - 6, b - 6))
        der = " ".join(t for _, _, t in _lineas_en(pagina, *c_der, a - 6, b - 6))
        # Fila con contenido en cualquier columna (el OCR a veces pierde la clase pero no la fecha)
        if len(re.findall(r"[a-z0-9]", _norm(" ".join((clase, sit, fecha, der))))) < 2:
            continue  # vacía o solo rayas
        if re.fullmatch(r"\W*(ningun[oa]s?|nada|no|no tiene|no posee|sin bienes|no procede|n/?a|x+)\W*", _norm(clase)) and not sit.strip():
            continue  # "NINGUNO"
        if re.search(r"clase y caract|situaci.n$|fecha de adq", _norm(clase + " " + sit + " " + fecha)):
            continue
        filas.append({"tipo": seccion_de((a + b) / 2), "clase": clase, "situacion": sit,
                      "fecha_adquisicion": fecha, "derecho": der})
    return filas


NUMEROS = {"dos": 2, "tres": 3, "cuatro": 4, "cinco": 5, "seis": 6, "siete": 7, "ocho": 8, "nueve": 9, "diez": 10}


def _unidades(clase: str) -> int:
    """Inmuebles que agrupa una fila: "16 VIVIENDAS", "2 PLAZAS DE APARCAMIENTO", "dos pisos" -> 16, 2, 2."""
    m = re.match(r"\W*(\d{1,2}|dos|tres|cuatro|cinco|seis|siete|ocho|nueve|diez)\s+(viviendas|pisos|plazas|garajes|"
                 r"locales|trasteros|apartamentos|casas|naves|solares|fincas|parcelas|aparcamientos|chalets|"
                 r"inmuebles|edificios|oficinas|bajos|aticos|estudios)\b", _norm(clase))
    if not m:
        return 1
    n = NUMEROS.get(m.group(1)) or int(m.group(1))
    return n if 1 <= n <= 60 else 1


def _fraccion(derecho: str, clase: str) -> float:
    t = _norm(derecho + " " + clase)
    t = re.sub(r"(?<![\w.,])[il|]o\s*%", "10%", t)  # OCR: "IO%" = 10 %
    pct = re.findall(r"(\d{1,3}(?:[.,]\d{1,4})?)\s*%", t)
    if pct:
        v = float(pct[0].replace(",", "."))
        if 0 < v <= 100:
            return round(v / 100, 4)
    m = re.search(r"\b1\s*/\s*(\d{1,2})\b", t)
    if m and int(m.group(1)) > 1:
        return round(1 / int(m.group(1)), 4)
    for patron, v in ((r"tercera parte|\b3a?\.? parte", 1 / 3), (r"cuarta parte|\b4a?\.? parte", 0.25),
                      (r"quinta parte", 0.2), (r"sexta parte", 1 / 6)):
        if re.search(patron, t):
            return round(v, 4)
    if re.search(r"mitad", t):
        return 0.5
    # "NN% DEL DECLARANTE": el OCR de Windows a veces pierde el "NN%" a principio de línea;
    # "del declarante" sin porcentaje indica una cuota no leída: se asume el 50 %.
    if re.search(r"(^|\s)del (declarante|titular)", t):
        return 0.5
    if re.search(r"gananc|comunidad|proindiv|pro indiv|indivis|condomin|copropie|cotitular|conyuge|sociedad conyugal|"
                 r"compartid", t):
        return 0.5
    return 1.0


def _rentas(pagina):
    """Filas de la tabla "Rentas percibidas": (seccion, concepto, importe)."""
    ancla = _buscar(pagina, r"rentas percibidas|^rentas por|percepciones netas")
    if not ancla:
        return None
    w = pagina["ancho"]
    c_conc = _buscar(pagina, r"^concepto")
    c_eur = _buscar(pagina, r"^euros")
    fin = _buscar(pagina, r"cantidad pagada por irpf")
    y_fin = fin[1] - 10 if fin else pagina["alto"] - 400
    # Cabeceras grises que el OCR no lee: se sitúan por la etiqueta "Procedencia de las rentas"
    proc = _buscar(pagina, r"procedencia de")
    y0 = (c_conc[1] if c_conc else (proc[1] + 15 if proc else ancla[1] - 220)) + 30
    vert = _reglas(pagina["img"], 0, w, y0 + 20, y_fin - 20, horizontal=False, umbral=0.5)
    izq_conc = [v for v in vert if 0.17 * w < v < 0.45 * w]
    izq_eur = [v for v in vert if 0.6 * w < v < 0.9 * w]
    if not (izq_conc or c_conc) or not (izq_eur or c_eur):
        return None
    x_conc0 = (max(izq_conc) if izq_conc else c_conc[0] - 280) - 100
    x_eur0 = max(izq_eur) if izq_eur else c_eur[0] - 60
    secciones = []
    for patron, tipo in ((r"percepciones netas", "salarial"), (r"^dividendos", "dividendos"),
                         (r"^intereses o rendim", "intereses"), (r"^otras rentas", "otras")):
        e = _buscar(pagina, patron)
        if e:
            secciones.append((e[1], tipo))
    # Las etiquetas están centradas verticalmente: frontera = líneas horizontales en la columna izquierda
    izq = _reglas(pagina["img"], 140, x_conc0 + 80, y0, y_fin + 20, horizontal=True, umbral=0.6)
    lims = [y0] + izq + [y_fin + 20]

    def seccion_de(y):
        for a, b in zip(lims, lims[1:]):
            if a <= y < b:
                for ye, tipo in secciones:
                    if a <= ye < b:
                        return tipo
        return min(secciones, key=lambda e: abs(e[0] - y))[1] if secciones else "desconocida"

    filas = []
    horiz = _reglas(pagina["img"], x_conc0 + 120, x_eur0 - 10, y0 - 10, y_fin + 20, horizontal=True, umbral=0.6)
    if len(horiz) < 2:
        horiz = [y0, y_fin]
    for a, b in zip(horiz, horiz[1:]):
        if b - a < 18:
            continue
        conc = " ".join(t for _, _, t in _lineas_en(pagina, x_conc0 + 100, x_eur0, a + 2, b - 2))
        eur = " ".join(t for _, _, t in _lineas_en(pagina, x_eur0, pagina["ancho"], a + 2, b - 2))
        if not (conc.strip() or eur.strip()):
            continue
        filas.append({"seccion": seccion_de((a + b) / 2), "concepto": conc, "importe_txt": eur,
                      "importe_eur": _importe(eur)})
    return filas


def interpretar(paginas: list[dict]) -> dict:
    inmuebles, rentas, obs, notas = [], [], [], []
    hay_tabla_bienes = False
    for i, pg in enumerate(paginas):
        r = _rentas(pg)
        if r is not None:
            rentas += r
        t = _tabla_inmuebles(pg)
        if t is not None:
            hay_tabla_bienes = True
            inmuebles += t
        o = _buscar(pg, r"^observaciones")
        if o:
            obs += [x[2] for x in _lineas_en(pg, 0, pg["ancho"], o[1] + 100, pg["alto"] - 250)]
    texto = " ".join(l["t"] for pg in paginas for l in pg["lineas"])
    fecha = None
    m = re.search(r"presentaci.n de la credencial.{0,80}?(\d{1,2}/\d{1,2}/\d{4})", texto, re.I)
    return {"inmuebles": inmuebles, "rentas": rentas, "observaciones": " ".join(obs),
            "hay_tabla_bienes": hay_tabla_bienes, "hay_tabla_rentas": bool(rentas) or bool(
                any(_buscar(pg, r"rentas percibidas") for pg in paginas)),
            "n_paginas": len(paginas), "fecha_credencial": m.group(1) if m else None, "notas": notas}


# --------------------------------------------------------------------------- extracción completa
def _formacion(f: str) -> str:
    return (f or "").strip()


def extraer(leg: int = 15, limite: int | None = None, solo: list[int] | None = None) -> None:
    dips = lista_diputados(leg)
    if solo:
        dips = [d for d in dips if d["codParlamentario"] in solo]
    activos = [d for d in dips if not d.get("fchBaja")]
    decl_rows, inm_rows, ren_rows = [], [], []
    for n, d in enumerate(activos[:limite] if limite else activos):
        cod = d["codParlamentario"]
        base = {"legislatura": leg, "id_diputado": cod, "nombre": d["apellidosNombre"],
                "grupo_parlamentario": d["grupo"], "formacion": _formacion(d["formacion"]),
                "circunscripcion": d["nombreCircunscripcion"], "fecha_alta": d["fchAlta"]}
        try:
            url = enlace_bienes(leg, cod)
        except Exception as e:  # noqa: BLE001
            url, err = None, f"ficha: {e}"
        else:
            err = None if url else "la ficha no enlaza la declaración de bienes"
        todas = enlaces_bienes(leg, cod) if url else []
        fila = {**base, "url_pdf": url, "fecha_declaracion": None, "n_paginas": None,
                "origen_texto": None, "n_inmuebles": None, "n_urbanos": None, "n_rusticos": None,
                "n_sociedad": None, "n_viviendas_urbanas": None, "urbanos_equivalentes": None,
                "vivienda_habitual_declarada": None, "n_filas_rentas": None, "n_rentas_alquiler": None,
                "rend_capital_inmobiliario_eur": None, "menciona_alquiler_fuera_rentas": None,
                "ejercicio_rentas": None, "n_declaraciones_bienes": len(todas),
                "url_ultima_declaracion": todas[-1] if len(todas) > 1 else None,
                "extraccion_ok": False, "nota": err}
        if url:
            m = re.search(r"_(\d{8})\.pdf$", url)
            if m:
                fd = datetime.strptime(m.group(1), "%Y%m%d").date()
                fila["fecha_declaracion"] = fd.isoformat()
                fila["ejercicio_rentas"] = fd.year - 1
            try:
                pags = paginas_ocr(pdf_local(url))
                res = interpretar(pags)
            except Exception as e:  # noqa: BLE001
                fila["nota"] = f"lectura: {type(e).__name__}: {e}"[:300]
                res = None
            if res:
                # Filas que no son un inmueble sino una remisión ("me remito a la declaración de la
                # XIV Legislatura", "ver anexo"): se quitan y la declaración queda como no legible
                remision = [x for x in res["inmuebles"] if REMISION.search(_norm(x["clase"] + " " + x["derecho"]))
                            and not re.search(r"\d{4}", x["fecha_adquisicion"])]
                inm = [x for x in res["inmuebles"] if x not in remision]
                res["inmuebles"] = inm
                urb = [x for x in inm if x["tipo"] == "urbano"]
                for x in inm:
                    x["fraccion_titularidad"] = _fraccion(x["derecho"], x["clase"])
                    x["unidades"] = _unidades(x["clase"])
                    x["es_vivienda"] = bool(VIVIENDA.search(_norm(x["clase"]))) and not (
                        ANEXO.search(_norm(x["clase"])) and not re.search(r"vivienda|piso|casa|chalet", _norm(x["clase"])))
                    x["vivienda_habitual"] = bool(re.search(r"habitual", _norm(x["clase"] + " " + x["derecho"])))
                alq = [r for r in res["rentas"] if _es_alquiler(r)]
                fuera = ALQUILER.search(_norm(" ".join(x["clase"] + " " + x["derecho"] for x in inm)
                                              + " " + res["observaciones"]))
                ok = res["hay_tabla_bienes"] and res["hay_tabla_rentas"]
                notas = []
                if not res["hay_tabla_bienes"]:
                    notas.append("no se reconoce la tabla de bienes")
                if not res["hay_tabla_rentas"]:
                    notas.append("no se reconoce la tabla de rentas")
                if alq and any(r["importe_eur"] is None for r in alq):
                    notas.append("alquiler sin importe legible")
                if remision or REMISION.search(_norm(res["observaciones"])):
                    ok = False
                    notas.append("remite a otra declaración o a un anexo: " + _norm(
                        (remision[0]["clase"] if remision else res["observaciones"]))[:120])
                if not inm and re.search(r"inmueble|vivienda|\bpiso|domicilio|garaje|\blocal\b|finca|parcela|solar\b",
                                         _norm(res["observaciones"])) \
                        and not re.search(r"vendid|ya no aparece|no (tengo|tiene|posee)", _norm(res["observaciones"])):
                    ok = False
                    notas.append("describe inmuebles en observaciones y no en la tabla: " +
                                 _norm(res["observaciones"])[:120])
                if res["n_paginas"] > 6:
                    notas.append(f"{res['n_paginas']} páginas (anexos)")
                fila.update({
                    "n_paginas": res["n_paginas"], "origen_texto": pags[0].get("origen") if pags else None,
                    "n_inmuebles": sum(x["unidades"] for x in inm), "n_urbanos": sum(x["unidades"] for x in urb),
                    "n_rusticos": sum(x["unidades"] for x in inm if x["tipo"] == "rustico"),
                    "n_sociedad": sum(x["unidades"] for x in inm if x["tipo"] == "sociedad"),
                    "n_viviendas_urbanas": sum(x["unidades"] for x in urb if x["es_vivienda"]),
                    "urbanos_equivalentes": round(sum(x["unidades"] * x["fraccion_titularidad"] for x in urb), 3),
                    "vivienda_habitual_declarada": any(x["vivienda_habitual"] for x in inm),
                    "n_filas_rentas": len(res["rentas"]), "n_rentas_alquiler": len(alq),
                    "rend_capital_inmobiliario_eur": round(sum(r["importe_eur"] or 0 for r in alq), 2),
                    "menciona_alquiler_fuera_rentas": bool(fuera),
                    "extraccion_ok": ok, "nota": "; ".join(notas) or None,
                })
                for k, x in enumerate(inm):
                    inm_rows.append({"legislatura": leg, "id_diputado": cod, "orden": k + 1, **x})
                for k, r in enumerate(res["rentas"]):
                    ren_rows.append({"legislatura": leg, "id_diputado": cod, "orden": k + 1, **r,
                                     "es_alquiler": _es_alquiler(r)})
        decl_rows.append(fila)
        print(f"[{n + 1}/{len(activos)}] {cod} {d['apellidosNombre']}: {fila['n_inmuebles']} inm, "
              f"{fila['n_urbanos']} urb, alq={fila['rend_capital_inmobiliario_eur']} ok={fila['extraccion_ok']} "
              f"{fila['nota'] or ''}", flush=True)
    if solo or limite:
        return
    _escribir(EXT_DECL, decl_rows)
    _escribir(EXT_INM, inm_rows)
    _escribir(EXT_REN, ren_rows)


def _escribir(ruta: Path, filas: list[dict]) -> None:
    ruta.parent.mkdir(parents=True, exist_ok=True)
    cols = list(filas[0].keys()) if filas else []
    with ruta.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        w.writerows(filas)


def revisar(cod: int, leg: int = 15) -> None:
    url = enlace_bienes(leg, cod)
    print(url)
    res = interpretar(paginas_ocr(pdf_local(url)))
    print("INMUEBLES")
    for x in res["inmuebles"]:
        print("  ", x["tipo"], "|", x["clase"], "|", x["situacion"], "|", x["fecha_adquisicion"], "|", x["derecho"],
              "| frac", _fraccion(x["derecho"], x["clase"]))
    print("RENTAS")
    for r in res["rentas"]:
        print("  ", r["seccion"], "|", r["concepto"], "|", r["importe_txt"], "->", r["importe_eur"],
              "ALQ" if ALQUILER.search(_norm(r["concepto"])) else "")
    print("OBS:", res["observaciones"][:500])


# --------------------------------------------------------------------------- AEAT (población general)
AEAT = "https://sede.agenciatributaria.gob.es/AEAT/Contenidos_Comunes/La_Agencia_Tributaria/Estadisticas/Publicaciones/sites/irpf"
PARTIDAS_AEAT = {
    "102": "Ingresos íntegros de capital inmobiliario (inmuebles arrendados o cedidos)",
    "155": "Rentas inmobiliarias imputadas (inmuebles a disposición de sus titulares)",
    "156": "Rendimientos netos reducidos del capital inmobiliario",
}


def _aeat_html(url: str) -> str:
    import hashlib

    destino = CACHE / "aeat" / (hashlib.sha1(url.encode()).hexdigest()[:16] + ".html")
    if not destino.exists():
        r = _get(url)
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_bytes(r.content)
        time.sleep(1.0)
    return destino.read_text(encoding="utf-8", errors="replace")


def _enlaces(html_txt: str) -> list[tuple[str, str]]:
    import html as h

    return [(m.group(1), h.unescape(re.sub(r"<[^>]+>", "", m.group(2))).strip())
            for m in re.finditer(r'<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', html_txt, re.S)]


def _num_es(s: str) -> float | None:
    s = s.strip().replace(".", "").replace(",", ".")
    try:
        return float(s)
    except ValueError:
        return None


def aeat_irpf_inmobiliario(anios=range(2016, 2031)):
    """Estadística de los declarantes del IRPF (AEAT), por tramos de rendimiento:
    liquidaciones totales y con las partidas 102, 155 y 156 (territorio de régimen común)."""
    for anio in anios:
        base = f"{AEAT}/{anio}/"
        try:
            home = _aeat_html(base + "home.html")
        except Exception:  # noqa: BLE001  (año no publicado)
            continue
        url102 = None
        for href, _ in _enlaces(home):
            if href.startswith("mapa") and url102 is None:
                for h2, txt in _enlaces(_aeat_html(base + href)):
                    if re.match(r"102\.\s*Ingresos", txt) and h2.startswith("jrubik"):
                        url102 = base + h2
                        break
        if not url102:
            continue
        pag102 = _aeat_html(url102)
        urls = {"102": url102}
        for h2, txt in _enlaces(pag102):
            m = re.match(r"(155|156)\.", txt)
            if m and h2.startswith("jrubik") and m.group(1) not in urls:
                urls[m.group(1)] = base + h2
        for partida, url in urls.items():
            t = _aeat_html(url)
            if f"PARTIDA {partida}" not in t and f"partida {partida}" not in t.lower():
                continue
            for fila in re.findall(r"<tr[^>]*>(.*?)</tr>", t, re.S):
                c = [re.sub(r"<[^>]+>", "", x).strip() for x in re.findall(r"<t[hd][^>]*>(.*?)</t[hd]>", fila, re.S)]
                if len(c) == 8 and _num_es(c[1]) is not None:
                    yield {"anio": anio, "partida": partida, "partida_nombre": PARTIDAS_AEAT[partida],
                           "tramo": c[0], "liquidaciones_total": int(_num_es(c[1])),
                           "liquidaciones_partida": int(_num_es(c[3])), "importe_partida_eur": _num_es(c[5]),
                           "media_partida_eur": _num_es(c[7]), "url": url}


# --------------------------------------------------------------------------- dlt
def _leer(ruta: Path):
    if not ruta.exists():
        raise FileNotFoundError(f"Falta {ruta}: ejecuta python -m ingestion.diputados_inmuebles --extraer (Windows)")
    with ruta.open(encoding="utf-8", newline="") as f:
        yield from csv.DictReader(f)


def _tipar(fila: dict, enteros=(), reales=(), logicos=()) -> dict:
    out = {}
    for k, v in fila.items():
        v = None if v in ("", None) else v
        if v is not None and k in enteros:
            v = int(float(v))
        elif v is not None and k in reales:
            v = float(v)
        elif v is not None and k in logicos:
            v = v == "True"
        out[k] = v
    return out


@dlt.source(name="diputados_inmuebles")
def diputados_inmuebles():
    @dlt.resource(name="cong_declaraciones_bienes", write_disposition="replace")
    def cong_declaraciones_bienes():
        for f in _leer(EXT_DECL):
            yield _tipar(f, enteros=("legislatura", "id_diputado", "n_paginas", "n_inmuebles", "n_urbanos",
                                     "n_rusticos", "n_sociedad", "n_viviendas_urbanas", "n_filas_rentas",
                                     "n_rentas_alquiler", "ejercicio_rentas"),
                         reales=("urbanos_equivalentes", "rend_capital_inmobiliario_eur"),
                         logicos=("vivienda_habitual_declarada", "menciona_alquiler_fuera_rentas", "extraccion_ok"))

    @dlt.resource(name="cong_inmuebles_declarados", write_disposition="replace")
    def cong_inmuebles_declarados():
        for f in _leer(EXT_INM):
            yield _tipar(f, enteros=("legislatura", "id_diputado", "orden"), reales=("fraccion_titularidad",),
                         logicos=("es_vivienda", "vivienda_habitual"))

    @dlt.resource(name="cong_rentas_declaradas", write_disposition="replace")
    def cong_rentas_declaradas():
        for f in _leer(EXT_REN):
            yield _tipar(f, enteros=("legislatura", "id_diputado", "orden"), reales=("importe_eur",),
                         logicos=("es_alquiler",))

    @dlt.resource(name="cong_aeat_irpf_inmobiliario", write_disposition="replace")
    def cong_aeat_irpf_inmobiliario():
        yield from aeat_irpf_inmobiliario()

    return cong_declaraciones_bienes, cong_inmuebles_declarados, cong_rentas_declaradas, cong_aeat_irpf_inmobiliario


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--extraer", action="store_true")
    ap.add_argument("--leg", type=int, default=15)
    ap.add_argument("--limite", type=int)
    ap.add_argument("--solo", type=int, nargs="*")
    ap.add_argument("--revisar", type=int)
    ap.add_argument("--descargar", action="store_true", help="solo fichas, PDF y OCR (sin interpretar)")
    a = ap.parse_args()
    if a.descargar:
        for d in lista_diputados(a.leg):
            if d.get("fchBaja"):
                continue
            try:
                u = enlace_bienes(a.leg, d["codParlamentario"])
                if u:
                    paginas_ocr(pdf_local(u))
                print(d["codParlamentario"], u, flush=True)
            except Exception as e:  # noqa: BLE001
                print(d["codParlamentario"], "ERROR", e, flush=True)
    elif a.revisar:
        revisar(a.revisar, a.leg)
    elif a.extraer:
        extraer(a.leg, a.limite, a.solo)
