"""Elecciones a la Asamblea de Extremadura: municipios de toda la comunidad SOLO en 2015 y
secciones SOLO de la ciudad de Cáceres (2007, 2023 y 2025).

Qué publica (o publicó) la Junta de Extremadura
-----------------------------------------------
La Junta no tiene ningún archivo histórico de resultados por municipio ni por mesa. Cada
elección monta una web de resultados que desaparece al poco tiempo (comprobado el 12-10-2026):
- 1983-2011: no queda nada. Las webs de 2007 (www.resultados-elecciones2007.juntaex.es) y 2011
  no existen y la Wayback Machine solo guardó portadas vacías.
- 2015: http://resultadoelecciones2015.gobex.es (escrutinio PROVISIONAL de la Junta). El dominio
  ya no existe, pero la Wayback Machine guardó los PDF «Informe de mesas» de las dos provincias
  (mesas_badajoz.pdf y mesas_caceres.pdf, 28-5-2015): una columna por mesa, con su municipio,
  censo, votantes, nulos, blancos y votos de cada candidatura. Las 1.366 mesas (853 + 513) y los
  388 municipios. Es la ÚNICA autonómica con resultados por municipio de toda la comunidad.
- 2019: resultadosprovisionales2019.juntaex.es era una aplicación Angular; la Wayback solo
  guardó el JavaScript, no los datos.
- 2023: eleccionesasamblea2023.juntaex.es/es/descargas enlazaba el escrutinio DEFINITIVO por
  provincia (DatEscrut_Def_Auto_2023_Badajoz.xls y _Caceres.xls), pero ni el dominio ni los
  ficheros existen ya y la Wayback no los guardó.
- 2025: resultados.elecciones2025.juntaex.es solo daba municipio y comunidad, ya no resuelve en
  DNS y la Wayback no guardó las respuestas de su API (backend-difu). Los CSV para medios
  (prensa.elecciones2025.juntaex.es) iban con credenciales.
- El DOE / Boletín de la Asamblea (proclamación de la Junta Electoral de Extremadura) solo da
  totales por circunscripción. El IEEX (Instituto de Estadística) tiene un apartado
  «Participación ciudadana» con notas e infografías, pero ninguna tabla por municipio; su banco
  de datos y sus «Datos municipales» (Oracle BI) no tienen resultados electorales. datos.gob.es
  y el catálogo de datos abiertos de la Junta tampoco. Interior no publica las autonómicas.

Fuente 1 · 2015 por municipio (Junta de Extremadura, copia en la Wayback Machine)
----------------------------------------------------------------------------------
    http://web.archive.org/web/20150528200848id_/http://resultadoelecciones2015.gobex.es:80/10pdf/mesas_badajoz.pdf
    http://web.archive.org/web/20150528204238id_/http://resultadoelecciones2015.gobex.es:80/10pdf/mesas_caceres.pdf
El código de municipio sale del nombre, casado con la relación de municipios del INE
(diccionarioAA.xlsx). Trampas:
- La tabla tiene una columna por mesa y el nombre del municipio encima de la primera de sus
  mesas (solo una vez por bloque; se repite al cambiar de página). Hay que leer las letras en el
  orden del flujo del PDF: cada nombre es un objeto de texto, la segunda línea de los nombres
  largos («Arroyomolinos de la» / «Vera») va justo detrás de la primera, y algunos nombres
  vecinos se tocan sin espacio («Bodonal de la SierraBurguillos del Cerro»): se parten donde
  una mayúscula sigue a una minúscula.
- El distrito puede tener 2 cifras (Badajoz, distrito 10).
- Nombres de 2015 distintos del INE actual: Guadiana del Caudillo (hoy Guadiana), Higuera (hoy
  Higuera de Albalat), Aldehuela de Jerte (INE: «del Jerte»). Higuera lleva además la nota
  «Mesa con...» pegada al nombre.
- Censo = electores censados + certificaciones de alta. Sin CERA (el escrutinio provisional no
  lo incluye), así que los votos quedan algo por debajo de la proclamación oficial.
- Siendo provisional, alguna candidatura menor no cuadra con el definitivo (BA: 1.346 frente a
  1.245 oficiales en Badajoz; EXTREMADURA UNIDA 1.156 frente a 1.063).
- Los mismos PDF permitirían secciones de toda la comunidad (distrito-sección-mesa), pero con
  el seccionado de 2015; no se usan para no poner mapas de barrio de 2015 provisionales.

Fuente 2 · secciones de Cáceres ciudad (Ayuntamiento de Cáceres, SIG / IDE municipal)
-------------------------------------------------------------------------------------
El catálogo de datos abiertos del Ayuntamiento de Cáceres
(https://opendata.caceres.es/datosabiertos/catalogo/dataset/elecciones-autonomicas-de-2025,
y "-de-2023", "-de-2019", "-de-2007") publica una capa por elección en su GeoServer, con una
fila por sección censal del municipio (ya sumadas sus mesas) y geometría:

    https://ide.caceres.es/geoserver/elecciones/ows?service=WFS&version=1.0.0
        &request=GetFeature&typeName=elecciones:elecciones_autonomicas_{aaaa}&outputFormat=csv

Aviso legal del portal (https://opendata.caceres.es/aviso-legal.html): los datos «pueden
ser reutilizados y redistribuidos libremente». El dataset de CKAN no declara licencia.

Columnas 2023/2025: distrito (3 dígitos, «001»), seccion (3), censados, votos (= votantes,
incluye blancos y nulos), votos_blancos/votos_nulos (en 2023, votos_blan/votos_nulo), una
columna de votos por candidatura en minúsculas (psoe, pp, vox, podemos...), sus porcentajes
por_* (que se descartan), area, color y geom (polígono WKT; se descarta).
Columnas 2007: censo, tot_votos, votos_iu, votos_pp, votos_psoe, votos_otro (resto de
candidaturas sumadas), votos_blan, votos_nulo y por_*.

Trampas
-------
- 2019 NO se usa: la capa solo trae pp, psoe, up, cs y vox, sin blancos, nulos ni el resto
  de candidaturas (47.559 de 49.860 votantes), así que no se pueden calcular los votos a
  candidaturas.
- El distrito viene con 3 dígitos: el CUSEC usa los 2 últimos (10037 + "01" + "001").
- Las candidaturas son nombres de columna, no siglas oficiales: se traducen con SIGLAS a
  algo que entienda el seed elecciones_partidos_reglas (p. ej., podemos → PODEMOS-IU-AV,
  que es Unidas por Extremadura). Si aparece una columna nueva, se usa en mayúsculas.
- «votos» incluye blancos y nulos. Los votos a candidaturas se calculan sumando las
  columnas de partido, no restando. En 2023, la sección 02-004 tiene 1 voto más en
  «votos» que la suma de sus partes.
- El censo es el CER de residentes en cada sección; el CERA no se reparte por secciones.
- 2025: las secciones 04-026 y 06-006 son nuevas. Están en el seccionado del INE de 2026,
  pero no en el de 2025, que es el que usa probar() para esta elección.
- ide.caceres.es sirve el certificado sin el intermedio (Thawte TLS RSA CA G1): curl en
  Windows lo tolera y requests no. Se arma en caché un bundle certifi + intermedio
  (descargado de DigiCert) sin desactivar la verificación.
- Se desconoce si son datos del escrutinio provisional o del definitivo: la fuente no lo
  dice.
"""

import csv
import io
import re
import ssl
import time
import unicodedata
from datetime import date
from typing import Iterable

import requests

from ingestion.autonomicas import cache

COD_CCAA = "11"
SLUG = "extremadura"
FUENTE = "https://opendata.caceres.es/datosabiertos/catalogo/dataset/elecciones-autonomicas-de-2025"
COBERTURA = ("Municipios de toda Extremadura solo en 2015 (escrutinio provisional de la Junta, "
             "copia en la Wayback Machine); secciones solo de Cáceres ciudad (2007, 2023 y 2025). "
             "La Junta no conserva resultados por municipio ni por mesa del resto de autonómicas")

COD_MUN = "10037"  # Cáceres (INE)
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}
URL = ("https://ide.caceres.es/geoserver/elecciones/ows?service=WFS&version=1.0.0"
       "&request=GetFeature&typeName=elecciones%3Aelecciones_autonomicas_{anio}&outputFormat=csv")
# ide.caceres.es no envía el certificado intermedio (Thawte TLS RSA CA G1): Python falla
# con CERTIFICATE_VERIFY_FAILED. Se descarga de DigiCert (AIA) y se añade a certifi.
URL_INTERMEDIO = "http://cacerts.digicert.com/ThawteTLSRSACAG1.crt"

# 2015: «Informe de mesas» de la web de resultados provisionales de la Junta (Wayback)
URL_MESAS_2015 = "http://web.archive.org/web/{ts}id_/http://resultadoelecciones2015.gobex.es:80/10pdf/{fichero}"
MESAS_2015 = {"06": ("20150528200848", "mesas_badajoz.pdf"),
              "10": ("20150528204238", "mesas_caceres.pdf")}
# Relación de municipios del INE (se prueba la edición más reciente primero)
URLS_DICCIONARIO = [f"https://www.ine.es/daco/daco42/codmun/diccionario{aa:02d}.xlsx" for aa in (27, 26, 25, 24)]
# Nombre de 2015 (normalizado) -> nombre del INE actual (normalizado)
ALIAS_MUNICIPIOS = {
    "guadiana del caudillo": "guadiana",
    "higuera": "higuera de albalat",
    "aldehuela de jerte": "aldehuela del jerte",
}

PROCESOS = [
    {"proceso": "A11200705", "fecha": date(2007, 5, 27),
     "eleccion": "Asamblea de Extremadura, mayo de 2007 (solo Cáceres ciudad)"},
    {"proceso": "A11201505", "fecha": date(2015, 5, 24),
     "eleccion": "Asamblea de Extremadura, mayo de 2015"},
    {"proceso": "A11202305", "fecha": date(2023, 5, 28),
     "eleccion": "Asamblea de Extremadura, mayo de 2023 (solo Cáceres ciudad)"},
    {"proceso": "A11202512", "fecha": date(2025, 12, 21),
     "eleccion": "Asamblea de Extremadura, diciembre de 2025 (solo Cáceres ciudad)"},
]
SECCIONES_CACERES = {"A11200705", "A11202305", "A11202512"}
MUNICIPIOS = {"A11201505"}

# Columnas que no son candidaturas
NO_PARTIDO = {"FID", "geom", "distrito", "seccion", "censados", "censo", "votos", "tot_votos",
              "area", "color", "votos_blancos", "votos_nulos", "votos_blan", "votos_nulo",
              "por_participacion", "por_parti", "por_partic"}

# Columna de la capa -> siglas de la candidatura
SIGLAS = {
    "pp": "PP",
    "psoe": "PSOE",
    "vox": "VOX",
    "podemos": "PODEMOS-IU-AV",          # Unidas por Extremadura (Podemos-IU-Alianza Verde)
    "cs": "CS",
    "ued_syt": "UED-SYT",                # Una Extremadura Digna-Soberanía y Trabajo
    "ued": "UED",
    "juntos_levanta": "JUEX-LEVANTA",    # Juntos por Extremadura-Levanta Extremadura
    "juex": "JUEX",                      # Juntos por Extremadura
    "levanta": "LEVANTA",                # Levanta Extremadura
    "extremadura_unida": "EXTREMADURA UNIDA",
    "nex": "NEX",                        # Nuevo Extremeñismo-Adelante Extremadura
    "mundo_justo": "PUM+J",              # Por un Mundo Más Justo
    "pumj": "PUM+J",
    "pacma": "PACMA",
    "caceres_vi": "CACERES VIVA",
    "somos_cc": "SOMOS CC",
    "pex_ext": "PEX-EXT",
    # 2007
    "votos_pp": "PP",                    # PP-EU
    "votos_psoe": "PSOE",                # PSOE-Regionalistas
    "votos_iu": "IU",                    # IU-SIEX
    "votos_otro": "OTROS",               # resto de candidaturas, sumadas por la fuente
}


def _anio(proceso: str) -> int:
    for p in PROCESOS:
        if p["proceso"] == proceso:
            return p["fecha"].year
    raise ValueError(f"Proceso desconocido: {proceso}")


def _get(url: str, **kw) -> requests.Response:
    """GET con reintentos (la Wayback Machine devuelve 429/5xx a ratos)."""
    timeout = kw.pop("timeout", 300)
    for intento in range(5):
        try:
            r = requests.get(url, headers=CABECERAS, timeout=timeout, **kw)
            if r.status_code not in (429, 500, 502, 503, 504):
                r.raise_for_status()
                return r
        except requests.ConnectionError:
            if intento == 4:
                raise
        time.sleep(10 * (intento + 1))
    r.raise_for_status()
    return r


# --- Cáceres ciudad: secciones ---------------------------------------------------------------

def _ca_bundle() -> str:
    """certifi + el intermedio que ide.caceres.es no envía (verificación TLS intacta)."""
    destino = cache(SLUG) / "ca_bundle_caceres.pem"
    if not destino.exists():
        import certifi
        der = requests.get(URL_INTERMEDIO, headers=CABECERAS, timeout=60).content
        pem = ssl.DER_cert_to_PEM_cert(der) if not der.startswith(b"-----") else der.decode()
        destino.write_text(open(certifi.where(), encoding="utf-8").read() + "\n" + pem,
                           encoding="utf-8")
    return str(destino)


def _filas(proceso: str) -> list[dict]:
    anio = _anio(proceso)
    f = cache(SLUG) / f"caceres_autonomicas_{anio}.csv"
    if not f.exists():
        r = requests.get(URL.format(anio=anio), headers=CABECERAS, timeout=180,
                         verify=_ca_bundle())
        r.raise_for_status()
        if not r.content.startswith(b"FID,"):
            raise RuntimeError(f"Respuesta inesperada del GeoServer de Cáceres: {r.content[:200]!r}")
        f.write_bytes(r.content)
    csv.field_size_limit(1 << 30)  # la geometría WKT es muy larga
    with open(f, encoding="utf-8", newline="") as fh:
        return list(csv.DictReader(io.StringIO(fh.read())))


def _partidos(fila: dict) -> list[str]:
    return [c for c in fila if c not in NO_PARTIDO and not c.startswith("por_")]


def _cod_seccion(fila: dict) -> str:
    d, s = fila["distrito"].strip(), fila["seccion"].strip()
    if len(d) == 3 and d.startswith("0"):
        d = d[1:]
    if len(d) != 2 or len(s) != 3 or not (d + s).isdigit():
        raise ValueError(f"Sección con formato inesperado: distrito={d!r} seccion={s!r}")
    return COD_MUN + d + s


def secciones(proceso: str) -> Iterable[dict]:
    if proceso not in SECCIONES_CACERES:
        return []
    acum: dict[str, dict] = {}
    for f in _filas(proceso):
        cod = _cod_seccion(f)
        blanco = int(f.get("votos_blancos") or f.get("votos_blan") or 0)
        nulos = int(f.get("votos_nulos") or f.get("votos_nulo") or 0)
        cand = sum(int(f[c] or 0) for c in _partidos(f))
        a = acum.setdefault(cod, {"cod_seccion": cod, "censo": 0, "votos_blanco": 0,
                                  "votos_nulos": 0, "votos_candidaturas": 0})
        a["censo"] += int(f.get("censados") or f.get("censo") or 0)
        a["votos_blanco"] += blanco
        a["votos_nulos"] += nulos
        a["votos_candidaturas"] += cand
    return list(acum.values())


def votos(proceso: str) -> Iterable[dict]:
    if proceso not in SECCIONES_CACERES:
        return []
    acum: dict[tuple[str, str], int] = {}
    for f in _filas(proceso):
        cod = _cod_seccion(f)
        for c in _partidos(f):
            n = int(f[c] or 0)
            siglas = SIGLAS.get(c, c.upper())
            acum[(cod, siglas)] = acum.get((cod, siglas), 0) + n
    return [{"cod_seccion": c, "siglas": s, "votos": n} for (c, s), n in acum.items() if n]


# --- 2015: municipios de toda la comunidad ---------------------------------------------------

CODIGO_MESA = re.compile(r"^(\d{1,2})-(\d{3})-([A-Z])$")
ETIQUETA_PARTIDO = re.compile(r"^(.+?) \((\d+)\)$")


def _norm(nombre: str) -> str:
    """Nombre de municipio comparable: sin tildes, minúsculas y artículo delante."""
    s = re.sub(r"\s*Mesa con\.\.\.$", "", nombre)
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower()
    m = re.match(r"^(.*), (la|el|los|las)$", s)  # INE: «Haba, La» -> «la haba»
    if m:
        s = f"{m.group(2)} {m.group(1)}"
    s = re.sub(r"[^a-z0-9]+", " ", s).strip()
    return ALIAS_MUNICIPIOS.get(s, s)


def _codigos_ine() -> dict[tuple[str, str], str]:
    """(provincia, nombre normalizado) -> código INE, de la relación de municipios del INE."""
    import openpyxl

    destinos = sorted(cache(SLUG).glob("ine_diccionario*.xlsx"))
    if destinos:
        contenido = destinos[-1].read_bytes()
    else:
        for url in URLS_DICCIONARIO:
            r = requests.get(url, headers=CABECERAS, timeout=120)
            if r.status_code == 200 and r.content[:2] == b"PK":
                contenido = r.content
                (cache(SLUG) / f"ine_{url.rsplit('/', 1)[-1]}").write_bytes(contenido)
                break
        else:
            raise RuntimeError("No se encontró ningún diccionario de municipios del INE")
    hoja = openpyxl.load_workbook(io.BytesIO(contenido), read_only=True).active
    out = {}
    for fila in hoja.iter_rows(values_only=True):
        if fila and fila[1] in ("06", "10") and fila[2]:
            out[(fila[1], _norm(str(fila[4])))] = fila[1] + str(fila[2]).zfill(3)
    return out


def _nombres_bloque(letras: list[dict], columnas: list[dict]) -> dict[int, str]:
    """Nombres de municipio encima de una fila de mesas -> índice de su primera columna.

    Las letras van en el orden del flujo del PDF: cada nombre es un objeto de texto y la
    segunda línea de un nombre largo va justo detrás de la primera."""
    inicios = [c["x0"] - 2 for c in columnas]  # el nombre empieza 2 pt a la izquierda del código
    trozos: list[list] = []  # [x0, top, texto]
    prev = None
    for ch in letras:
        nuevo = prev is None or abs(ch["top"] - prev["top"]) > 1 or (
            prev["text"] != " " and (ch["x0"] - prev["x1"] > 0.3 or ch["x0"] < prev["x0"]
                                     or (ch["text"].isupper() and prev["text"].islower())))
        if nuevo:
            trozos.append([ch["x0"], ch["top"], ch["text"]])
        else:
            trozos[-1][2] += ch["text"]
        prev = ch
    if not trozos:
        return {}
    primera_linea = min(t[1] for t in trozos)
    grupos: list[list] = []
    for x0, top, txt in trozos:
        if top > primera_linea + 3 and grupos:  # segunda línea del nombre anterior
            grupos[-1][1] += " " + txt
        else:
            col = min(range(len(columnas)), key=lambda i: abs(inicios[i] - x0))
            grupos.append([col, txt])
    return {c: " ".join(t.split()) for c, t in grupos}


def _mesas_pdf(contenido: bytes) -> list[dict]:
    """Lee el «Informe de mesas» de 2015: una fila por mesa con su municipio y sus valores."""
    import pdfplumber

    out = []
    municipio = None
    with pdfplumber.open(io.BytesIO(contenido)) as doc:
        for page in doc.pages:
            palabras = page.extract_words(x_tolerance=1)
            filas_cod: dict[int, list] = {}
            for w in palabras:
                if CODIGO_MESA.match(w["text"]):
                    filas_cod.setdefault(round(w["top"]), []).append(w)
            tops = sorted(filas_cod)
            for i, t in enumerate(tops):
                columnas = sorted(filas_cod[t], key=lambda w: w["x0"])
                fin = tops[i + 1] - 30 if i + 1 < len(tops) else page.height - 25
                letras = [c for c in page.chars if t - 30 < c["top"] < t - 5 and c["x0"] > 148]
                nombres = _nombres_bloque(letras, columnas)
                filas: dict[int, list] = {}
                for w in palabras:
                    if t + 3 < w["top"] < fin:
                        filas.setdefault(round(w["top"]), []).append(w)
                datos = []
                for ft in sorted(filas):
                    ws = sorted(filas[ft], key=lambda w: w["x0"])
                    etiqueta = " ".join(w["text"] for w in ws if w["x1"] < 150)
                    nums = [w for w in ws if w["x0"] >= 150]
                    if not etiqueta or not nums:
                        continue
                    if len(nums) != len(columnas):
                        raise ValueError(f"Página {page.page_number}, fila {etiqueta!r}: "
                                         f"{len(nums)} valores para {len(columnas)} mesas")
                    datos.append((etiqueta, [int(w["text"].replace(".", "")) for w in nums]))
                for j, c in enumerate(columnas):
                    municipio = nombres.get(j, municipio)  # sin nombre: sigue el municipio anterior
                    out.append({"municipio": municipio, "mesa": c["text"],
                                "valores": {e: v[j] for e, v in datos}})
    return out


def _municipios_2015() -> list[dict]:
    """Una fila por municipio y concepto (censo, blancos... y cada candidatura), en caché."""
    f = cache(SLUG) / "autonomicas_2015_municipios.csv"
    if not f.exists():
        codigos = _codigos_ine()
        filas = []
        for prov, (ts, fichero) in MESAS_2015.items():
            pdf = cache(SLUG) / f"2015_{fichero}"
            if not pdf.exists():
                r = _get(URL_MESAS_2015.format(ts=ts, fichero=fichero))
                if not r.content.startswith(b"%PDF"):
                    raise RuntimeError(f"Respuesta inesperada de la Wayback para {fichero}: {r.content[:200]!r}")
                pdf.write_bytes(r.content)
            mesas = _mesas_pdf(pdf.read_bytes())
            vistas = set()
            acum: dict[tuple[str, str], int] = {}
            for m in mesas:
                cod = codigos.get((prov, _norm(m["municipio"] or "")))
                if not cod:
                    raise ValueError(f"Municipio de 2015 sin código INE: {m['municipio']!r} ({fichero})")
                if (cod, m["mesa"]) in vistas:
                    raise ValueError(f"Mesa repetida: {cod} {m['mesa']} ({fichero})")
                vistas.add((cod, m["mesa"]))
                v = m["valores"]
                conceptos = {
                    "_censo": v["Electores censados"] + v["Certif. censales de alta"],
                    "_votantes": v["Total votantes"],
                    "_blanco": v["Votos en blanco"],
                    "_nulos": v["Votos nulos"],
                }
                for etiqueta, n in v.items():
                    p = ETIQUETA_PARTIDO.match(etiqueta)
                    if p:
                        conceptos[p.group(1).replace("`", "'")] = n
                for k, n in conceptos.items():
                    acum[(cod, k)] = acum.get((cod, k), 0) + n
            filas += [{"cod_mun": c, "concepto": k, "valor": n} for (c, k), n in sorted(acum.items())]
        with open(f, "w", encoding="utf-8", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=["cod_mun", "concepto", "valor"])
            w.writeheader()
            w.writerows(filas)
    with open(f, encoding="utf-8", newline="") as fh:
        return [{**r, "valor": int(r["valor"])} for r in csv.DictReader(fh)]


def municipios(proceso: str) -> Iterable[dict]:
    if proceso not in MUNICIPIOS:
        return []
    acum: dict[str, dict] = {}
    for r in _municipios_2015():
        a = acum.setdefault(r["cod_mun"], {"cod_mun": r["cod_mun"], "censo": 0, "votos_blanco": 0,
                                           "votos_nulos": 0, "votos_candidaturas": 0})
        k = r["concepto"]
        if k == "_censo":
            a["censo"] += r["valor"]
        elif k == "_blanco":
            a["votos_blanco"] += r["valor"]
        elif k == "_nulos":
            a["votos_nulos"] += r["valor"]
        elif not k.startswith("_"):
            a["votos_candidaturas"] += r["valor"]
    return list(acum.values())


def votos_municipios(proceso: str) -> Iterable[dict]:
    if proceso not in MUNICIPIOS:
        return []
    return [{"cod_mun": r["cod_mun"], "siglas": r["concepto"], "votos": r["valor"]}
            for r in _municipios_2015() if not r["concepto"].startswith("_") and r["valor"]]


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
