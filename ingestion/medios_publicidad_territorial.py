"""Fuente dlt de la publicidad institucional de las comunidades autónomas que la
publican por medio en formato estructurado (tema `medios_publicidad_territorial`).

Cinco fuentes, normalizadas a formato largo (una fila por organismo × medio ×
campaña cuando la fuente lo da):

- Cataluña (Generalitat): «Campanyes i promoció institucional de la
  Generalitat», Socrata 8d5a-6vsk (analisi.transparenciacatalunya.cat),
  2015-. Importe **neto**, sin IVA ni comisión de agencia (memoria anual de
  ejecución). Incluye las empresas públicas (FGC, Loteries de Catalunya / EAJA,
  ICF, Ports...). Tipus despesa «Creativitat» = creatividad, sin medio.
- Castilla y León (Junta): «Publicidad institucional», Opendatasoft
  (analisis.datosabiertos.jcyl.es), 2014-, año × consejería × medio × tipo.
  CC BY 4.0. La ficha no dice si lleva IVA (ver iva_incluido).
- Aragón (Gobierno): «Campañas de publicidad institucional», un Excel por año
  (desde 2026 por trimestre) en aragon.es, 2016-. Importes con IVA de lo
  adjudicado a cada medio. Las cabeceras cambian cada año: se localizan por
  nombre (ADJUDICATARIO, MEDIO..., GASTO/MEDIO, SUBTOTAL...).
- Navarra (Gobierno): «Publicidad institucional», un CSV por año en CKAN
  (datosabiertos.navarra.es), 2012-, CC BY 4.0. Cada CSV apila tablas
  (inversión por departamentos, por campañas y por medio dentro de cada tipo).
  Las filas de departamento suman el total (cuenta_en_total = true); las de
  medio son un desglose parcial (cuenta_en_total = false).
- Región de Murcia (CARM): «Publicidad institucional», JSON OData
  (datosabiertos.carm.es), 2017-, contratos con medio y empresa. Son importes
  contratados (con IVA), no ejecución.

Recurso (replace): pubt_gasto con columnas cod_ccaa (INE), anio,
organismo_pagador, es_empresa_publica, medio, grupo, tipo_medio, campana,
importe_eur, iva_incluido, base ('ejecutado'|'contratado'|'planificado'),
cuenta_en_total, fuente, nota.
"""

import csv
import io
import logging
import re
import unicodedata
from datetime import date, datetime

import dlt
import requests

log = logging.getLogger(__name__)

# Un agente de navegador «falso» lo corta el cortafuegos de Navarra: se usa uno propio.
CABECERAS = {"User-Agent": "Mozilla/5.0 (compatible; SpainFacts/1.0; +https://spainfacts.github.io)"}

URL_CAT = "https://analisi.transparenciacatalunya.cat/api/views/8d5a-6vsk/rows.csv?accessType=DOWNLOAD"
URL_CYL = ("https://analisis.datosabiertos.jcyl.es/api/explore/v2.1/catalog/datasets/"
           "publicidad-institucional/exports/json")
URL_AR_INDICE = "https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional"
URL_AR_RAIZ = "https://www.aragon.es"
URL_NAV = "https://datosabiertos.navarra.es/api/3/action/package_show?id=publicidad-institucional"
URL_MUR = "https://datosabiertos.carm.es/odata/transparencia/PUBLI_Institucional.json"

# Organismos que son empresas públicas o entes que venden bienes/servicios
# (sociedades mercantiles, entidades públicas empresariales, lotería...).
EMPRESAS = {
    "09": [  # Cataluña
        r"ferroca?r+ils de la generalitat", r"\bFGC\b", r"loteries de catalunya", r"jocs i apostes",
        r"\bEAJA\b", r"institut catal[àa] de finances", r"\bICF\b", r"ports de la generalitat",
        r"\bCIMALSA\b", r"actius de muntanya", r"\bAMSA\b", r"institut catal[àa] del s[òo]l",
        r"\bINCASOL\b", r"\bprodeca\b", r"teatre nacional de catalunya", r"circuits? de catalunya",
        r"avan[çc]sa", r"infraestructures\.cat", r"infraestructures de la generalitat",
        r"aeroports de catalunya", r"forestal catalana",
    ],
    # Aragón: SARGA, Aragón Plataforma Logística, Aragón Exterior... (el ITA y el
    # IAF son entidades de derecho público, no sociedades). Castilla y León,
    # Murcia y Navarra solo publican consejerías o departamentos (el Instituto
    # de Turismo de Murcia es entidad pública, no sociedad).
    "02": [r"\bSARGA\b", r"sociedad aragonesa de gesti[óo]n", r"plataforma log[íi]stica",
           r"arag[óo]n exterior", r"turismo de arag[óo]n", r"\bS\.A\.U?(\b|$)", r"\bS\.L\.U?(\b|$)"],
    "07": [r"\bSOMACYL\b", r"\bS\.A\.U?(\b|$)"],
    # Ayuntamiento de Madrid: EMT, EMVS, Madrid Destino, Mercamadrid... (S.A.)
    "28079": [r"\bS\.A\.?U?(\b|$)", r"empresa municipal", r"madrid destino", r"\bEMT\b", r"\bEMVS\b",
              r"mercamadrid", r"madrid calle 30"],
    # Ajuntament de Barcelona: BSM, Barcelona Activa, TMB, Turisme de Barcelona...
    "08019": [r"\bS\.A\.?U?(\b|$)", r"\bBSM\b", r"barcelona de serveis municipals", r"barcelona activa",
              r"\bTMB\b", r"transports metropolitans", r"\bSAU\b"],
    "14": [r"\bS\.A\.U?(\b|$)"],
    "15": [r"\bS\.A\.U?(\b|$)"],
}


def _es_empresa(cod: str, organismo: str | None) -> bool:
    if not organismo:
        return False
    return any(re.search(p, organismo, re.I) for p in EMPRESAS.get(cod, []))


def _get(url: str, **kw) -> requests.Response:
    r = requests.get(url, headers=CABECERAS, timeout=180, **kw)
    r.raise_for_status()
    return r


def _num(v):
    """Número desde texto español («1.234,56»), inglés («14,520.00 €») o float."""
    if v is None:
        return None
    if isinstance(v, (int, float)):
        return float(v)
    s = re.sub(r"[^0-9,.\-]", "", str(v))  # fuera €, espacios, NBSP y bytes raros
    if not s:
        return None
    if "," in s and "." in s:
        if s.rfind(",") > s.rfind("."):
            s = s.replace(".", "").replace(",", ".")
        else:
            s = s.replace(",", "")
    elif "," in s:
        # «1591,13» o «1.591» (miles) ya cubierto; coma sola = decimal
        s = s.replace(",", ".")
    elif s.count(".") > 1 or re.fullmatch(r"\d{1,3}\.\d{3}", s):
        s = s.replace(".", "")
    try:
        return float(s)
    except ValueError:
        return None


def _fila(cod, anio, organismo, medio, tipo_medio, importe, iva, base, fuente, *,
          grupo=None, campana=None, cuenta=True, nota=None, cod_municipio=None):
    org = " ".join(str(organismo).split()) if organismo else None
    return {
        "cod_ccaa": cod,
        "nivel": "local" if cod_municipio else "autonomico",
        "cod_municipio": cod_municipio,
        "anio": int(anio),
        "organismo_pagador": org,
        "es_empresa_publica": _es_empresa(cod_municipio or cod, org),
        "medio": " ".join(str(medio).split()) if medio not in (None, "") else None,
        "grupo": " ".join(str(grupo).split()) if grupo else None,
        "tipo_medio": " ".join(str(tipo_medio).split()) if tipo_medio else None,
        "campana": " ".join(str(campana).split())[:500] if campana else None,
        "importe_eur": float(importe),
        "iva_incluido": iva,
        "base": base,
        "cuenta_en_total": cuenta,
        "fuente": fuente,
        "nota": nota,
    }


# ---------------------------------------------------------------- Cataluña
def _cataluna():
    texto = _get(URL_CAT).content.decode("utf-8-sig")
    lector = csv.reader(io.StringIO(texto))
    cab = [" ".join(c.split()).lower() for c in next(lector)]

    def col(pref):
        return next(i for i, c in enumerate(cab) if c.startswith(pref))

    i_a, i_o, i_c, i_t = col("període"), col("òrgan"), col("campanya"), col("tipus despesa")
    i_tm, i_s, i_i = col("tipus mitjà"), col("suport"), col("import net")
    for r in lector:
        if len(r) <= i_i:
            continue
        imp = _num(r[i_i])
        m = re.match(r"\d{4}", r[i_a] or "")
        if imp is None or not m:
            continue
        creat = (r[i_t] or "").lower().startswith("creativ")
        yield _fila(
            "09", m.group(0), r[i_o], None if creat else r[i_s],
            "CREATIVITAT" if creat else r[i_tm], imp, False, "ejecutado",
            "Generalitat de Catalunya, Campanyes i promoció institucional (Socrata 8d5a-6vsk)",
            campana=r[i_c],
            nota="Import net: sin IVA ni comisión de agencia",
        )


# ---------------------------------------------------------- Castilla y León
def _cyl():
    for r in _get(URL_CYL).json():
        imp = _num(r.get("importe"))
        anio = str(r.get("ano") or "")[:4]
        if imp is None or not anio.isdigit():
            continue
        yield _fila(
            "07", anio, r.get("consejeria"), r.get("medio"), r.get("tipo"), imp, None, "ejecutado",
            "Junta de Castilla y León, Publicidad institucional (Opendatasoft publicidad-institucional, CC BY 4.0)",
            nota="La ficha no indica si el importe lleva IVA",
        )


# ------------------------------------------------------------------ Aragón
def _ar_filas(contenido: bytes, nombre: str):
    """(hoja, filas) de un xls o xlsx."""
    if nombre.lower().endswith(".xls"):
        import xlrd

        wb = xlrd.open_workbook(file_contents=contenido)
        for sh in wb.sheets():
            filas = []
            for i in range(sh.nrows):
                fila = []
                for j, c in enumerate(sh.row(i)):
                    v = c.value
                    if c.ctype == xlrd.XL_CELL_DATE:
                        v = datetime(*xlrd.xldate_as_tuple(v, wb.datemode))
                    fila.append(v)
                filas.append(fila)
            yield sh.name, filas
    else:
        import openpyxl

        wb = openpyxl.load_workbook(io.BytesIO(contenido), read_only=True, data_only=True)
        for ws in wb.worksheets:
            yield ws.title, [list(r) for r in ws.iter_rows(values_only=True)]


def _norm(s) -> str:
    s = " ".join(str(s or "").split()).upper()
    # sin tildes (también À, È, Ò catalanas), conservando la Ñ
    s = s.replace("Ñ", "\0")
    s = "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))
    return s.replace("\0", "Ñ")


def _anio_de(v):
    if isinstance(v, (datetime, date)):
        return v.year
    return None


def _aragon_fichero(contenido: bytes, nombre: str, anio_fichero: int):
    for hoja, filas in _ar_filas(contenido, nombre):
        if "TOTAL" in _norm(hoja) and "CPI" in _norm(hoja) and "IMPORTE" in _norm(hoja):
            continue  # hoja resumen por trimestres (se usa solo para comprobar)
        # fila de cabecera: la primera que nombra el medio o el adjudicatario
        ih = next((i for i, f in enumerate(filas[:15])
                   if any(k in _norm(c) for c in f for k in ("ADJUDICATARIO", "MEDIO"))), None)
        if ih is None:
            continue
        cab = [_norm(c) for c in filas[ih]]

        def idx(*claves, excluir=()):
            for k in claves:
                for j, c in enumerate(cab):
                    if c.startswith(k) and not any(e in c for e in excluir):
                        return j
            return None

        j_dep = idx("DEPARTAMENTO")
        j_camp = idx("DENOMINACION", "CAMPAÑA")
        j_adj = idx("ADJUDICATARIO")
        j_med = idx("MEDIOS DE COMUNICACION", "MEDIO DE COMUNICACION", "MEDIOS")
        if j_med == j_adj:
            j_med = None
        j_ini = idx("FECHA INICIO", "INICIO")
        j_desc = idx("DESCRIPCION")
        # importe por medio: por orden de preferencia; «TOTAL GASTO CAMPAÑA» es
        # el total de la campaña repetido y se descarta
        js_imp = [j for j in (idx("GASTO POR MEDIO"), idx("GASTO/MEDIO"), idx("IMPORTE TOTAL"),
                              idx("IMPORTE"), idx("SUBTOTAL"), idx("TOTAL", excluir=("CAMPAÑA",)))
                  if j is not None]
        js_imp = list(dict.fromkeys(js_imp))
        dep = camp = None
        for f in filas[ih + 1:]:
            f = list(f) + [None] * (len(cab) - len(f))
            txt = " ".join(_norm(c) for c in f if isinstance(c, str))
            if not txt and all(c in (None, "") for c in f):
                continue
            if re.match(r"^(TOTAL|SUMA)\b", _norm(f[0]) or _norm(f[1] if len(f) > 1 else "")):
                continue
            if j_dep is not None and f[j_dep] not in (None, ""):
                dep = f[j_dep]
            if j_camp is not None and f[j_camp] not in (None, ""):
                camp = f[j_camp]
            imp = None
            for j in js_imp:
                v = f[j]
                if isinstance(v, (int, float)) and not isinstance(v, bool):
                    imp = float(v)
                    break
                if isinstance(v, str) and re.fullmatch(r"[\d\.,\s€]+", v.strip() or "x"):
                    imp = _num(v)
                    break
            if imp is None or imp == 0:
                continue
            adj = f[j_adj] if j_adj is not None else None
            med = f[j_med] if j_med is not None else None
            adj = adj if adj not in ("", None) else None
            med = med if med not in ("", None) else None
            propia = [f[j] for j in (j_camp, j_dep, j_desc) if j is not None and f[j] not in (None, "")]
            if not adj and not med and not propia:
                continue  # filas de subtotal de campaña (importe sin medio ni campaña)
            if re.search(r"\bTOTAL\b", txt):
                continue  # «IMPORTE TOTAL CAMPAÑAS ... TRIMESTRE», «Total 3er trimestre»
            if adj and med:
                medio, tipo = adj, med
            else:
                medio, tipo = adj or med, None
            anio = anio_fichero or _anio_de(f[j_ini] if j_ini is not None else None)
            yield _fila(
                "02", anio, dep, medio, tipo, imp, True, "contratado",
                f"Gobierno de Aragón, Campañas de publicidad institucional ({nombre}, hoja {hoja})",
                campana=camp,
                nota="Importe adjudicado a cada medio, con IVA",
            )


def _aragon():
    html = _get(URL_AR_INDICE).text
    hrefs = sorted(set(re.findall(r'href="(/documents/[^"]+?\.xlsx?[^"]*)"', html, re.I)))
    for href in hrefs:
        href = href.replace("&amp;", "&")
        nombre = href.split("/")[4] if len(href.split("/")) > 4 else href
        m = re.search(r"(20\d\d)", nombre)
        if not m:
            continue
        try:
            contenido = _get(URL_AR_RAIZ + href).content
        except requests.HTTPError as e:
            log.warning("Aragón: no se pudo bajar %s (%s)", nombre, e)
            continue
        yield from _aragon_fichero(contenido, nombre, int(m.group(1)))


# ----------------------------------------------------------------- Navarra
# Tablas apiladas que no son de medios: por departamento (totalizan), por
# campaña o tipo de campaña, resúmenes por canal/soporte y creatividad.
NAV_DEPARTAMENTOS = re.compile(r"(gasto|inversi[óo]n publicitaria) por departamentos|publicidad departamental", re.I)
NAV_NO_MEDIO = re.compile(
    r"campa[ñn]a|anuncios|acciones|principales|menores|contratos menores|tipo de|"
    r"por canales|soportes publicitarios|publicidad de avisos|publicidad institucional$|"
    r"creatividad|prensa\. por tipo", re.I)


# 2013-2015: la tabla por departamentos solo cubre una parte (sin la publicidad
# de turismo ni los avisos) y las demás tablas no cuadran entre sí: sin total.
NAV_SIN_TOTAL = {2013, 2014, 2015}


def _navarra():
    recursos = _get(URL_NAV).json()["result"]["resources"]
    for res in recursos:
        url = res.get("url") or ""
        m = re.search(r"(20\d\d)", res.get("name", "") + url)
        if not url.lower().endswith(".csv") or not m:
            continue
        anio = int(m.group(1))
        raw = _get(url).content
        try:
            texto = raw.decode("utf-8-sig")
        except UnicodeDecodeError:
            texto = raw.decode("cp1252", errors="replace")  # 2025 viene en Windows-1252 (€ = 0x80)
        sep = ";" if texto.count(";") > texto.count(",") else ","
        for r in csv.reader(io.StringIO(texto), delimiter=sep):
            if len(r) < 3:
                continue
            destino, importe, tabla = r[0].strip(), _num(r[1]), " ".join(r[-1].split())
            if importe is None or not destino or destino.lower() in ("destino", "total"):
                continue
            fuente = f"Gobierno de Navarra, Publicidad institucional {anio} (CKAN publicidad-institucional, CC BY 4.0)"
            if NAV_DEPARTAMENTOS.search(tabla):
                completa = anio not in NAV_SIN_TOTAL
                yield _fila("15", anio, destino, None, None, importe, None, "ejecutado", fuente,
                            cuenta=completa,
                            nota="Fila de la tabla «inversión publicitaria por departamentos»: suma el total" if completa
                            else "Tabla por departamentos incompleta en este año (deja fuera turismo y avisos): no suma el total")
            elif anio >= 2016 and not NAV_NO_MEDIO.search(tabla):
                # antes de 2016 las tablas por medio se solapan (resúmenes por
                # canal, turismo aparte, filas de total): no se cargan
                yield _fila("15", anio, "Gobierno de Navarra (todos los departamentos)", destino, tabla,
                            importe, None, "ejecutado", fuente, cuenta=False,
                            nota="Desglose por medio sin cruce con el departamento; no suma el total")


# ------------------------------------------------------------------ Murcia
def _murcia():
    datos = _get(URL_MUR).json()
    if isinstance(datos, dict):
        datos = datos.get("value") or datos.get("d") or []
    for r in datos:
        if not isinstance(r, list) or len(r) < 7:
            continue
        anio, cons, modalidad, objeto, importe, medio_txt, empresa = r[:7]
        imp = _num(importe)
        if imp is None or not str(anio).strip()[:4].isdigit():
            continue
        medio_txt = " ".join(str(medio_txt or "").split()).rstrip(".")
        tipo, _, medio = medio_txt.partition(":")
        if not medio:
            tipo, medio = None, medio_txt
        yield _fila(
            "14", str(anio).strip()[:4], cons, medio.strip() or None, (tipo or "").strip() or modalidad, imp,
            True, "contratado",
            "CARM, Publicidad institucional (datosabiertos.carm.es PUBLI_Institucional.json)",
            grupo=empresa, campana=objeto,
            nota=f"Contrato ({modalidad}); importe contratado con IVA, no ejecución",
        )


# --------------------------------------------------- Ayuntamiento de Madrid
URL_MAD = "https://datos.madrid.es/api/3/action/package_show?id=300024-0-publicidad-institucional"


def _madrid():
    """Excel anuales «Nacional» e «Internacional» (datos.madrid.es 300024, CC BY):
    hoja UNIDAD_MEDIO_SOPORTE con unidad × medio (tipo) × soporte (cabecera) ×
    importe sin y con IVA. Desde 2017 (2016 nacional trae otro formato: se omite).
    Se guarda el importe SIN IVA para compararlo con Cataluña y la C. Valenciana."""
    recursos = _get(URL_MAD).json()["result"]["resources"]
    import openpyxl

    for res in recursos:
        m = re.search(r"(Nacional|Internacional)\. (20\d\d)$", res.get("description") or "")
        if not m or int(m.group(2)) < 2017:  # 2016 nacional viene en otro formato: sin el año completo
            continue
        ambito, anio = m.group(1), int(m.group(2))
        try:
            wb = openpyxl.load_workbook(io.BytesIO(_get(res["url"]).content), read_only=True, data_only=True)
        except Exception as e:  # noqa: BLE001
            log.warning("Madrid: no se pudo leer %s %s (%s)", ambito, anio, e)
            continue
        hoja = next((ws for ws in wb.worksheets if re.match(r"UNIDAD[_ ]MEDIO", ws.title, re.I)), None)
        if hoja is None:
            log.warning("Madrid %s %s: sin hoja UNIDAD_MEDIO_SOPORTE (formato antiguo), se omite", ambito, anio)
            continue
        filas = list(hoja.iter_rows(values_only=True))
        cab = [_norm(c) for c in filas[0]]
        j_u = next(j for j, c in enumerate(cab) if c.startswith("UNIDAD"))
        j_m = next(j for j, c in enumerate(cab) if c == "MEDIO")
        j_s = next(j for j, c in enumerate(cab) if c.startswith("SOPORTE"))
        j_i = next(j for j, c in enumerate(cab) if "SIN IVA" in c or "IVA NO INCLUIDO" in c)
        for f in filas[1:]:
            if not f or len(f) <= j_i or not isinstance(f[j_i], (int, float)) or not f[j_u]:
                continue
            if re.match(r"^TOTAL", _norm(f[j_u])):
                continue
            yield _fila(
                "13", anio, f[j_u], f[j_s], f[j_m], f[j_i], False, "ejecutado",
                f"Ayuntamiento de Madrid, Publicidad institucional. {ambito}. {anio} (datos.madrid.es 300024, CC BY 4.0)",
                cod_municipio="28079",
                nota=f"Campañas {ambito.lower()}es; importe ejecutado SIN IVA (la fuente da también el importe con IVA)",
            )


# ------------------------------------------------- Ajuntament de Barcelona
URL_BCN = "https://opendata-ajuntament.barcelona.cat/data/api/3/action/package_show?id=campanyes-publicitat-institucional"
BCN_TIPOS = {"PREMSA DIARIA", "RADIO", "EMISSORES DE RADIO", "REVISTES", "TELEVISIO", "CINEMA", "EXTERIOR",
             "PROXIMITAT REVISTES", "INTERNET", "DIGITAL", "ACCIONS ESPECIALS"}


def _barcelona():
    """CSV anuales (opendata-ajuntament.barcelona.cat, CC BY 4.0): campaña × tipo
    de medio (sin cabecera concreta). 2012-2023 en formato largo (CONCEPTE,
    MITJÀ, IMPORT); 2024 en ancho, una columna por tipo de medio."""
    for res in _get(URL_BCN).json()["result"]["resources"]:
        url = res.get("url") or ""
        m = re.search(r"(20\d\d)", res.get("name") or url)
        if not url.lower().endswith(".csv") or not m:
            continue
        anio = int(m.group(1))
        raw = _get(url).content
        try:
            texto = raw.decode("utf-8-sig")
        except UnicodeDecodeError:
            texto = raw.decode("cp1252", errors="replace")
        sep = ";" if texto.count(";") > texto.count(",") else ","
        filas = list(csv.reader(io.StringIO(texto), delimiter=sep))
        ih = next(i for i, f in enumerate(filas[:15])
                  if any("CAMPANY" in _norm(c) for c in f) and sum(1 for c in f if c.strip()) >= 3)
        cab = [_norm(c) for c in filas[ih]]
        fuente = f"Ajuntament de Barcelona, Campanyes de publicitat institucional {anio} (Open Data BCN, CC BY 4.0)"
        nota = "Por tipo de medio, sin cabecera concreta; la fuente no indica si lleva IVA"
        if "MITJA" in cab and "IMPORT" in cab:  # formato largo
            j_c = next(j for j, c in enumerate(cab) if "CAMPANY" in c)
            j_con = cab.index("CONCEPTE") if "CONCEPTE" in cab else None
            j_m, j_i = cab.index("MITJA"), cab.index("IMPORT")
            j_ord = cab.index("ORDENANT") if "ORDENANT" in cab else None
            for f in filas[ih + 1:]:
                if len(f) <= j_i:
                    continue
                imp = _num(f[j_i])
                if not imp:
                    continue
                concepte = _norm(f[j_con]) if j_con is not None else "MITJANS"
                tipo = f[j_m] if concepte.startswith("MITJA") else (f[j_con] or "CREATIVITAT")
                yield _fila("09", anio, (f[j_ord] if j_ord is not None else None) or "Ajuntament de Barcelona",
                            None, tipo, imp, None, "ejecutado", fuente, campana=f[j_c],
                            cod_municipio="08019", nota=nota)
        else:  # formato ancho (2024)
            j_c = next(j for j, c in enumerate(cab) if "CAMPANY" in c)
            cols = [(j, c) for j, c in enumerate(cab) if c in BCN_TIPOS or c.startswith("TOTAL CREATIVITAT")]
            for f in filas[ih + 1:]:
                if len(f) <= j_c or not f[j_c].strip() or _norm(f[j_c]).startswith("TOTAL"):
                    continue
                for j, c in cols:
                    imp = _num(f[j]) if j < len(f) else None
                    if not imp:
                        continue
                    tipo = "CREATIVITAT, PRODUCCIÓ, DISTRIBUCIONS I SEGUIMENT" if c.startswith("TOTAL CREAT") else filas[ih][j]
                    yield _fila("09", anio, "Ajuntament de Barcelona", None, tipo, imp, None, "ejecutado",
                                fuente, campana=f[j_c], cod_municipio="08019", nota=nota)


FUENTES = {"madrid_ayto": _madrid, "barcelona_ayto": _barcelona, "cataluna": _cataluna, "castilla_leon": _cyl, "aragon": _aragon, "navarra": _navarra, "murcia": _murcia}


@dlt.source(name="medios_publicidad_territorial")
def medios_publicidad_territorial():
    @dlt.resource(name="pubt_gasto", write_disposition="replace",
                  columns={"iva_incluido": {"data_type": "bool", "nullable": True},
                           "grupo": {"data_type": "text", "nullable": True},
                           "medio": {"data_type": "text", "nullable": True},
                           "tipo_medio": {"data_type": "text", "nullable": True},
                           "campana": {"data_type": "text", "nullable": True},
                           "nota": {"data_type": "text", "nullable": True},
                           "importe_eur": {"data_type": "double"}})
    def pubt_gasto():
        for nombre, fn in FUENTES.items():
            n = 0
            try:
                for fila in fn():
                    n += 1
                    yield fila
            except Exception:
                # con replace, seguir sin una fuente la borraría de raw: mejor fallar
                log.error("medios_publicidad_territorial: falla la fuente %s", nombre)
                raise
            log.info("medios_publicidad_territorial: %s -> %d filas", nombre, n)

    return pubt_gasto
