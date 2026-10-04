"""Planes de medios de la Comunidad de Madrid (Portal de Transparencia, «Gastos en
publicidad y comunicación institucional», recurso «Planes de medios»).

La Comunidad publica cada año un ZIP con un Excel por campaña y lote (lote 1 = medios
convencionales; lote 2 = digital), 2020-. Cada Excel trae una portada (consejería,
dirección general, campaña), un «óptico» (resumen por tipo de medio, a veces con IVA) y
una hoja por plan (prensa, radio, exterior, TV, digital...) con el soporte, la tarifa,
el descuento y el **neto** de cada inserción, y debajo «TOTAL NETO», «IVA» y «TOTAL».
Los formatos cambian entre campañas: aquí se localiza cada bloque cabecera..TOTAL NETO,
se elige la columna (o el par de columnas neto + producción) que cuadra con el total
del bloque y se emite una fila por línea del plan. La producción que el plan da aparte
(«PRODUCCIÓN» bajo el TOTAL NETO) se emite como fila sin medio.

Importes: neto (tras el descuento negociado), SIN IVA; el plan no indica la comisión de
la agencia de medios. Son PLANES (lo previsto), no ejecución: base = 'planificado'.

Se excluyen las campañas de Canal de Isabel II que aparecen en el ZIP de 2020: Canal
publica sus propios planes 2019-2025 (seed medios_publicidad_canal_planes) y los dos
coinciden (1,64 M€ en el ZIP frente a 1,82 M€ en los PDF de Canal, que traen además las
redes sociales y otra ola).
"""

import io
import logging
import re
import unicodedata
import zipfile
from datetime import date, datetime, time

import requests

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "Mozilla/5.0 (compatible; SpainFacts/1.0; +https://spainfacts.github.io)"}
URL_INDICE = "https://www.comunidad.madrid/transparencia/gastos-publicidad-y-comunicacion-institucional"


def norm(s) -> str:
    s = " ".join(str(s or "").split()).upper()
    return "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c))


def num(v):
    if isinstance(v, bool):
        return None
    if isinstance(v, (int, float)):
        return float(v)
    if isinstance(v, str):
        t = v.replace("€", "").replace("\xa0", "").strip()
        if re.fullmatch(r"-?\d{1,3}(\.\d{3})*(,\d+)?|-?\d+(,\d+)?", t):
            return float(t.replace(".", "").replace(",", "."))
    return None


CAB_SOP = re.compile(r"^(SOPORTE|SOPORTES|SITE|SITES|EMISORA|EMISORAS|CADENA|CADENAS|PLATAFORMA|MEDIO|MEDIOS|"
                     r"EXCLUSIVISTA|CINE|CINES|SALA|SALAS|REVISTA|REVISTAS|PUBLICACION)$")
NO_HOJA = re.compile(r"^(PORTADA|OPTICO|EVALUACI|RESUMEN|CONTROL|JUSTIFICA|MATERIAL|FOTO|RANKING|EVAL)")
# etiquetas de filas de total (no son soportes): «TOTAL NETO», «TOTAL MEDIOS», «IVA», «T. NETO + IVA»...
TOT = re.compile(r"^(TOTAL(:| NETO.*| MEDIOS.*| TV.*| TELEVISION.*| RADIO.*| PRENSA.*| EXTERIOR.*| DIGITAL.*|"
                 r" GENERAL.*| CAMPANA.*| INVERSION.*| PLAN.*| ONLINE.*| REVISTAS.*| CINE.*| PROXIMIDAD.*|"
                 r" FINAL.*| \+.*| CON .*| SIN .*|ES.*)?|SUBTOTAL.*|IVA( .*)?|21 ?%.*|T\. ?NETO.*|NETO|SUMA( .*)?|"
                 r"IMPORTE TOTAL.*)$")
TOTAL_NETO = re.compile(r"^(SUBTOTAL|TOTAL NETO|T\. ?NETO|TOTAL MEDIOS|TOTAL INVERSION NETA|TOTAL INVERSION|"
                        r"TOTAL NETO MEDIOS|TOTAL|SUBTOTAL NETO|TOTAL NETO FINAL|TOTAL PLAN|NETO TOTAL)$")
TIPOS = [("PROX", "PRENSA PROXIMIDAD"), ("SUPLEM", "PRENSA"), ("REVIST", "REVISTAS"), ("PRENSA", "PRENSA"),
         ("GRAF", "PRENSA"), ("RADIO", "RADIO"), ("TELEVIS", "TELEVISIÓN"), (" TV", "TELEVISIÓN"),
         ("EXTERIOR", "EXTERIOR"), ("DIGITAL", "DIGITAL"), ("ONLINE", "DIGITAL"), ("REDES", "REDES SOCIALES"),
         ("CINE", "CINE"), ("PODCAST", "DIGITAL"), ("CORTO", "CINE")]
# líneas del óptico que son un tipo de medio, no un medio concreto
OPTICO_TIPOS = re.compile(r"^(PRENSA|RADIO|TELEVISION|TV|EXTERIOR|INTERNET|DIGITAL|ONLINE|REVISTAS?|CINE|"
                          r"GRAFICA|PRENSA PROXIMIDAD|PROXIMIDAD|REDES SOCIALES|SUPLEMENTOS|MEDIOS)\b")


def _tipo_de(hoja, cab):
    h = " " + norm(hoja)
    for k, v in TIPOS:
        if k in h:
            return v
    if "EMISORA" in cab or "CADENA" in cab:
        return "RADIO"
    if "SITE" in cab:
        return "DIGITAL"
    if "EXCLUSIVISTA" in cab:
        return "EXTERIOR"
    return None


def _col_neto(cab):
    """Columna del neto según la cabecera: la de más a la derecha, sin unitarios, tarifa ni IVA."""
    prefs = [r"NETO FINAL", r"TOTAL INVERSION NETA", r"INVERSION NETA", r"COSTE NETO", r"TOTAL NETO",
             r"IMPORTE NETO", r"^NETO$", r"^TOTAL$", r"^IMPORTE$", r"INVERSION"]
    for p in prefs:
        js = [j for j, c in enumerate(cab) if re.search(p, c) and "UNITARIO" not in c and "IVA" not in c
              and "TARIFA" not in c]
        if js:
            return js[-1]
    return None


def _portada(filas):
    txt = []
    for f in filas[:25]:
        for c in f:
            if isinstance(c, str) and c.strip():
                txt.append(" ".join(c.split()))
    cons = next((t for t in txt if re.match(r"(?i)^consejer", t) and len(t) > 12), None)
    if cons is None:
        i = next((k for k, t in enumerate(txt) if re.match(r"(?i)^consejer[ií]a:?$", t)), None)
        if i is not None and i + 1 < len(txt):
            cons = txt[i + 1]
    org = None
    for t in txt:
        nt = norm(t)
        if re.match(r"^(DIRECCION GENERAL|D\.? ?G\.?|AGENCIA|INSTITUTO|CANAL|METRO|CONSORCIO|SERVICIO|OFICINA|"
                    r"VICECONSEJERIA|FUNDACION|MUSEO|TELEMADRID|RADIO TELEVISION|SECRETARIA|ORGANISMO|AREA|"
                    r"SUBDIRECCION GENERAL|CENTRO|ENTE|IMIDRA|IMDEA|SERMAS|SUMMA|ESCUELA|ORQUESTA|"
                    r"COMUNIDAD DE MADRID -|MADRID 112|UNIVERSIDAD|HOSPITAL|ACADEMIA|INSTITUCION)", nt) \
                and "SUBDIRECCION DE COMUNICACION" not in nt:
            org = t
            break
    return cons, org, txt


def _es_cabecera(cn, fila=None):
    if any(CAB_SOP.match(c) or c.startswith("SOPORTE/") or c.startswith("SOPORTE /") for c in cn):
        return True
    # cabecera sin título en la columna del soporte («OTAS», vacía...): basta con la columna de neto
    if fila is not None and sum(1 for c in cn if c) >= 3 \
            and any(re.search(r"COSTE NETO|TOTAL NETO|INVERSION NETA|NETO FINAL", c) for c in cn) \
            and not any(isinstance(v, (int, float)) and not isinstance(v, bool) for v in fila):
        return True
    return False


def _bloques_hoja(hoja, filas, meta):
    """Bloques cabecera..TOTAL NETO de una hoja; elige la(s) columna(s) que cuadran con el total."""
    out = []
    i, n = 0, len(filas)
    while i < n:
        cn = [norm(c) if isinstance(c, str) else "" for c in filas[i]]
        if not _es_cabecera(cn, filas[i]):
            i += 1
            continue
        hdr = i
        js = next((j for j, c in enumerate(cn) if (CAB_SOP.match(c) or c.startswith("SOPORTE")) and c != "EXCLUSIVISTA"), None)
        jx = next((j for j, c in enumerate(cn) if c == "EXCLUSIVISTA"), None)
        if js is None:
            js = jx
        if js is None:
            for r2 in range(i + 1, min(i + 8, n)):
                f2 = filas[r2]
                cs = [j for j, c in enumerate(f2) if isinstance(c, str) and c.strip() and num(c) is None]
                if cs and any(num(c) is not None for c in f2):
                    js = cs[0]
                    break
        jg = next((j for j, c in enumerate(cn) if c == "GRUPO"), None)
        jf = next((j for j, c in enumerate(cn) if c.startswith("FORMATO") or c in ("EMPLAZAMIENTO", "PROGRAMA")), None)
        cab2 = cn + [norm(c) if isinstance(c, str) else "" for c in (filas[i + 1] if i + 1 < n else [])]
        tipo = _tipo_de(hoja, cab2)
        jn_cab = _col_neto(cn)
        # total del bloque
        k, total, tcol = i + 1, None, None
        while k < n:
            ck = [norm(c) if isinstance(c, str) else "" for c in filas[k]]
            if _es_cabecera(ck, filas[k]) and k > i + 2:
                break
            hit = next(((j, c) for j, c in enumerate(ck) if c and TOTAL_NETO.match(c) and "IVA" not in c), None)
            if hit:
                vals = [(j, num(v)) for j, v in enumerate(filas[k]) if j > hit[0] and num(v) is not None]
                if vals:
                    tcol, total = vals[-1]
                    if "NETO" not in hit[1]:  # mejor un «T. NETO» de las filas siguientes, si lo hay
                        for k3 in range(k + 1, min(k + 4, n)):
                            ck3 = [norm(c) if isinstance(c, str) else "" for c in filas[k3]]
                            h3 = next(((j, c) for j, c in enumerate(ck3)
                                       if c and TOTAL_NETO.match(c) and "NETO" in c and "IVA" not in c), None)
                            if h3:
                                v3 = [(j, num(v)) for j, v in enumerate(filas[k3]) if j > h3[0] and num(v) is not None]
                                if v3:
                                    tcol, total = v3[-1]
                                    k = k3
                                break
                    break
            k += 1
        fin = k
        produccion = None
        if total is not None:
            for k2 in range(k + 1, min(k + 4, n)):
                ck2 = [norm(c) if isinstance(c, str) else "" for c in filas[k2]]
                h2 = next((j for j, c in enumerate(ck2) if c.startswith("PRODUCCI")), None)
                if h2 is not None:
                    vv = [num(v) for j, v in enumerate(filas[k2]) if j > h2 and num(v) is not None]
                    if vv and vv[0] > 0:
                        produccion = vv[0]
                    break
                if any("IVA" in c for c in ck2):
                    break
        datos = []
        ult_s = ult_x = ult_g = None
        for r in range(hdr + 1, min(fin, n)):
            f = filas[r]
            ck = [norm(c) if isinstance(c, str) else "" for c in f]
            if any(TOT.match(c) for c in ck if c):
                continue
            s = f[js] if js is not None and js < len(f) else None
            s = " ".join(s.split()) if isinstance(s, str) and s.strip() else None
            x = f[jx] if jx is not None and jx < len(f) else None
            x = " ".join(x.split()) if isinstance(x, str) and x.strip() else None
            g = f[jg] if jg is not None and jg < len(f) else None
            g = " ".join(g.split()) if isinstance(g, str) and g.strip() else None
            if s and norm(s) not in ("CAMPANA", "SECCION"):
                ult_s, ult_g = s, g
            if x:
                ult_x = x
            if not ult_s or not any(isinstance(c, str) and c.strip() and num(c) is None for c in f):
                continue  # filas de subtotales de inserciones (solo números)
            fm = f[jf] if jf is not None and jf < len(f) else None
            datos.append((f, ult_s, ult_x, g or ult_g, fm))

        def suma(cols):
            return sum(sum(num(f[c]) or 0 for c in cols if c < len(f)) for f, *_ in datos)

        elegido, verif = None, False
        if total is not None and datos:
            ncol = max(len(f) for f, *_ in datos)
            cands = [[tcol]] + [[c] for c in range(ncol) if c != tcol] + [[c, c + 1] for c in range(ncol - 1)] \
                + ([[jn_cab]] if jn_cab is not None else [])
            for cols in cands:
                if abs(suma(cols) - total) < 1.0:
                    elegido, verif = cols, True
                    break
        if elegido is None:
            elegido = [jn_cab] if jn_cab is not None else ([tcol] if tcol is not None else None)
        if elegido is not None:
            for f, so, ex, g, fm in datos:
                v = sum(num(f[c]) or 0 for c in elegido if c < len(f))
                if not v:
                    continue
                medio, sop_ext = (ex or so, so) if jx is not None and js != jx else (so, None)
                out.append(dict(meta, tipo_medio=tipo, medio=medio, soporte_exterior=sop_ext, grupo=g,
                                formato=" ".join(str(fm).split())[:120] if fm not in (None, "") else None,
                                importe=round(v, 2), cuadra_bloque=verif))
            if produccion and verif:
                out.append(dict(meta, tipo_medio="PRODUCCIÓN", medio=None, soporte_exterior=None, grupo=None,
                                formato=f"Producción ({tipo or hoja})", importe=round(produccion, 2),
                                cuadra_bloque=True))
        i = max(fin, i + 1)
    return out


def _optico(filas):
    """(suma neta del óptico sin IVA, [(línea, neto)]) o (None, [])."""
    for i, f in enumerate(filas[:30]):
        cn = [norm(c) for c in f]
        if "MEDIO" in cn or "MEDIOS" in cn:
            con_iva = any("IVA" in c for c in cn)
            jt = next((j for j, c in enumerate(cn) if "TOTAL" in c or "INVERSION" in c or "NETO" in c), None)
            if jt is None:
                return None, []
            lineas = []
            for g in filas[i + 1:]:
                if len(g) <= jt:
                    continue
                lab = next((" ".join(c.split()) for c in g if isinstance(c, str) and c.strip()), "")
                v = num(g[jt])
                if v is None or not lab or TOT.match(norm(lab)):
                    continue
                lineas.append((lab, v / 1.21 if con_iva else v))
            return sum(v for _, v in lineas), lineas
    return None, []


def procesa_fichero(nombre: str, hojas, anio: int):
    """Filas de un Excel de plan de medios + controles (suma del óptico, consejería, organismo)."""
    partes = nombre.replace("\\", "/").split("/")
    carpeta = partes[-2] if len(partes) >= 2 else ""
    fich = partes[-1]
    campana = re.sub(r"^(AO|C|A\.O\.?)\s+", "", carpeta.strip()).strip()
    es_ao = bool(re.match(r"^A\.?O\b", carpeta.strip(), re.I))
    m = re.search(r"(?i)lote\s*[_\.]?\s*(\d)", fich)
    lote = int(m.group(1)) if m else None
    cons = org = None
    portada_txt = []
    optico, opt_lineas = None, []
    filas_out = []
    meta = None
    for hoja, filas in hojas:
        nh = norm(hoja)
        if nh.startswith("PORTADA"):
            cons, org, portada_txt = _portada(filas)
            continue
        if nh.startswith("OPTICO"):
            s, ls = _optico(filas)
            if s is not None:
                optico = (optico or 0) + s
                opt_lineas += ls
            continue
        if NO_HOJA.match(nh):
            continue
        meta = dict(anio=anio, carpeta=carpeta, fichero=fich, hoja=hoja, campana=campana,
                    anuncio_oficial=es_ao, lote=lote, consejeria=cons, organismo=org)
        filas_out.extend(_bloques_hoja(hoja, filas, meta))
    if not filas_out:
        # planes digitales con la tabla de soportes en la hoja «OPTICO»
        for hoja, filas in hojas:
            nh = norm(hoja)
            if nh.startswith("OPTICO") and "RESUMEN" not in nh:
                filas_out.extend(_bloques_hoja(hoja, filas, dict(anio=anio, carpeta=carpeta, fichero=fich, hoja=hoja,
                                                                 campana=campana, anuncio_oficial=es_ao, lote=lote,
                                                                 consejeria=cons, organismo=org)))
    if not filas_out and opt_lineas:
        # último recurso: las líneas del óptico (un medio concreto o un tipo de medio)
        for lab, v in opt_lineas:
            es_tipo = bool(OPTICO_TIPOS.match(norm(lab)))
            filas_out.append(dict(anio=anio, carpeta=carpeta, fichero=fich, hoja="OPTICO", campana=campana,
                                  anuncio_oficial=es_ao, lote=lote, consejeria=cons, organismo=org,
                                  tipo_medio=lab if es_tipo else ("DIGITAL" if lote == 2 else None),
                                  medio=None if es_tipo else lab, soporte_exterior=None, grupo=None,
                                  formato="Línea del óptico (el plan no detalla soportes en formato legible)",
                                  importe=round(v, 2), cuadra_bloque=True))
    return filas_out, {"optico": optico, "consejeria": cons, "organismo": org, "portada": portada_txt}


def hojas_xlsx(contenido: bytes):
    """[(título, filas)] con los valores de un xlsx (sin fechas de calendario)."""
    import openpyxl

    wb = openpyxl.load_workbook(io.BytesIO(contenido), read_only=True, data_only=True)
    hojas = []
    for ws in wb.worksheets:
        filas = []
        for r in ws.iter_rows(values_only=True):
            r = [None if isinstance(c, (datetime, date, time)) else c for c in r]
            while r and r[-1] in (None, ""):
                r.pop()
            filas.append(r)
        while filas and not filas[-1]:
            filas.pop()
        hojas.append((ws.title, filas))
    wb.close()
    return hojas


def _nombre_zip(info: zipfile.ZipInfo) -> str:
    """Los ZIP no marcan UTF-8: los nombres vienen en CP850 (2023) o CP1252 según el año."""
    n = info.filename
    if info.flag_bits & 0x800:
        return n
    try:
        crudo = n.encode("cp437")
    except UnicodeEncodeError:
        return n
    cands = []
    for cod in ("cp1252", "cp850"):
        try:
            cands.append(crudo.decode(cod))
        except UnicodeDecodeError:
            pass
    # el que tenga más letras españolas y menos símbolos raros
    def nota(s):
        return sum(c in "áéíóúÁÉÍÓÚñÑüÜ" for c in s) - 3 * sum(c in "¥¤¢‚àÐ" for c in s)
    return max(cands, key=nota) if cands else n


def _bonito(s: str | None) -> str | None:
    """«CONSEJERÍA DE CULTURA y TURISMO» -> «Consejería de Cultura y Turismo»."""
    if not s:
        return None
    s = " ".join(s.split()).strip(" .:-")
    s = re.sub(r"\s*\((Comunidad de Madrid|CM)\)\s*$", "", s, flags=re.I)
    s = re.sub(r"\s*,\s*", ", ", s).replace(" ,", ",")
    menores = {"de", "del", "la", "las", "el", "los", "y", "e", "a", "en", "para"}
    pal = s.lower().split(" ")
    out = [p if (k and p in menores) else (p[:1].upper() + p[1:]) for k, p in enumerate(pal)]
    return " ".join(out)


def organismo_pagador(cons, org):
    cons, org = _bonito(cons), _bonito(org)
    if cons and org and norm(org) not in norm(cons):
        return f"{cons} - {org}"
    return cons or org or "Comunidad de Madrid (el plan no indica la consejería)"


EMPRESAS_CM = [r"canal de isabel", r"\bmetro de madrid\b", r"telemadrid", r"radio televisi[óo]n madrid",
               r"consorcio regional de transportes", r"\bCRTM\b", r"\bARPEGIO\b", r"obras de madrid",
               r"\bMINTRA\b", r"turmadrid", r"nuevo arpegio"]


def es_empresa_cm(texto: str | None) -> bool:
    return bool(texto) and any(re.search(p, texto, re.I) for p in EMPRESAS_CM)


def es_canal_isabel(carpeta: str, portada_txt) -> bool:
    if re.match(r"(?i)^C\s+CANAL\s", carpeta.strip()):
        return True
    return any(re.search(r"(?i)canal (de )?isabel", t) for t in portada_txt)


def zips_indice() -> list[tuple[int, str]]:
    html = requests.get(URL_INDICE, headers=CABECERAS, timeout=120).text
    urls = sorted(set(re.findall(r'href="([^"]*planes_de_medios[^"]*excel[^"]*\.zip)"', html, re.I)))
    out = []
    for u in urls:
        m = re.search(r"planes_de_medios_(20\d\d)", u)
        if m:
            out.append((int(m.group(1)), u if u.startswith("http") else "https://www.comunidad.madrid" + u))
    return out


def _ficheros_zip(contenido: bytes, anio: int):
    z = zipfile.ZipFile(io.BytesIO(contenido))
    for info in z.infolist():
        nombre = _nombre_zip(info)
        if not nombre.lower().endswith(".xlsx") or "system volume" in nombre.lower():
            continue
        try:
            yield nombre, hojas_xlsx(z.read(info))
        except Exception as e:  # noqa: BLE001
            log.warning("Comunidad de Madrid %s: no se pudo leer %s (%s)", anio, nombre, e)


def filas_planes(anio: int, ficheros):
    """Filas normalizadas de los planes de un año a partir de (nombre, hojas)."""
    n_fich = n_canal = 0
    for nombre, hojas in ficheros:
        filas, ctl = procesa_fichero(nombre, hojas, anio)
        carpeta = nombre.replace("\\", "/").split("/")[-2] if "/" in nombre else ""
        if es_canal_isabel(carpeta, ctl["portada"]):
            n_canal += 1
            continue  # Canal de Isabel II: va con sus propios planes (seed), no se duplica
        n_fich += 1
        suma = sum(f["importe"] for f in filas)
        cuadra_fich = ctl["optico"] is not None and abs(suma - ctl["optico"]) < 2
        org = organismo_pagador(ctl["consejeria"], ctl["organismo"])
        emp = es_empresa_cm(org) or es_empresa_cm(" ".join(ctl["portada"][:6]))
        for f in filas:
            camp = f["campana"]
            if f["anuncio_oficial"]:
                camp = f"Anuncio oficial: {camp}"
            if f["lote"]:
                camp = f"{camp} (lote {f['lote']})"
            medio = f["medio"]
            if f.get("soporte_exterior") and f["soporte_exterior"] != medio:
                formato = f"{f['soporte_exterior']}; {f['formato']}" if f.get("formato") else f["soporte_exterior"]
            else:
                formato = f.get("formato")
            yield {
                "anio": anio,
                "organismo_pagador": org,
                "es_empresa_publica": emp,
                "medio": medio,
                "grupo": f.get("grupo"),
                "tipo_medio": f.get("tipo_medio"),
                "campana": camp,
                "importe": f["importe"],
                "cuadra": cuadra_fich,
                "fuente": (f"Comunidad de Madrid, Planes de medios {anio} (Portal de Transparencia, ZIP Excel): "
                           f"{carpeta}/{f['fichero']}, hoja «{f['hoja']}»"),
                "nota": ("Plan de medios: importe neto (tras descuento) sin IVA; no consta la comisión de agencia. "
                         "Planificado, no ejecutado"
                         + ("" if cuadra_fich else "; el fichero no cuadra con su óptico o no lo trae")
                         + (f". Formato: {formato[:150]}" if formato else "")),
            }
    log.info("Comunidad de Madrid %s: %d ficheros (%d de Canal de Isabel II omitidos)", anio, n_fich, n_canal)


def planes_cm():
    """Descarga los ZIP de Excel de todos los años publicados y genera las filas normalizadas."""
    for anio, url in zips_indice():
        log.info("Comunidad de Madrid: descargando planes de medios %s (%s)", anio, url)
        r = requests.get(url, headers=CABECERAS, timeout=900)
        r.raise_for_status()
        yield from filas_planes(anio, _ficheros_zip(r.content, anio))
