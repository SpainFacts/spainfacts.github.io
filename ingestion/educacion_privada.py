"""Fuente dlt de educación pública, concertada y privada por comunidad autónoma.

Todo sale de las tablas PC-Axis (.px) de descarga directa de los dos ministerios, sin formularios:

  Ministerio de Educación, Formación Profesional y Deportes — EDUCAbase
  (https://estadisticas.educacion.gob.es/EducaJaxiPx/files/_px/es/px/<ruta>.px?nocab=1)

  educacion_privada_alumnado_curso   Estadística de las Enseñanzas no universitarias, resultados
                                     detallados de cada curso (tabla 1.1 «gen-todas/todas_01»):
                                     alumnado de régimen general por titularidad/financiación
                                     (pública, privada concertada, privada no concertada),
                                     comunidad y enseñanza. Desde 2011-12 (antes no hay .px).
  educacion_privada_alumnado_serie   Series de la misma estadística (AlumnadoGen/alumnado_N_NN):
                                     alumnado por titularidad (solo pública / privada), comunidad
                                     y curso, desde 1990-91, una tabla por enseñanza. Incluye el
                                     último curso de avance («2025-26 (*)»).
  educacion_privada_gasto_conciertos Estadística del Gasto Público en Educación, serie 7: gasto en
                                     conciertos y subvenciones a la enseñanza privada por
                                     administración educativa (Ministerio y consejerías), 1992-.
  educacion_privada_gasto_admin      Misma estadística, serie 1: gasto público en educación por
                                     tipo de administración (consejerías de educación), 1992-.

  educacion_privada_gasto_transferencias  Misma estadística, tabla anual de transferencias de las
                                     administraciones educativas a centros privados por enseñanza
                                     (infantil, primaria, ESO, bachillerato, FP, especial, universidad).
  educacion_privada_fp_ciclos        Misma estadística, tablas de FP «por comunidad autónoma/provincia,
                                     ciclo formativo y titularidad» (gen-ciclos-fp): alumnado de FP
                                     básica, de grado medio y superior (presencial y a distancia) por
                                     ciclo y familia profesional, pública / privada, desde 2016-17.

  Ministerio de Ciencia, Innovación y Universidades — SIIU
  (https://estadisticas.ciencia.gob.es/jaxiPx/files/_px/es/px/<ruta>.px?nocab=1)

  educacion_privada_univ_matriculados Estadística de Estudiantes Universitarios, series históricas
                                     por comunidad (HIST_GRADO y HIST_MASTER, *_matric_sexo_rama_ca):
                                     matriculados por tipo (pública/privada) y modalidad
                                     (presencial/no presencial) de la universidad; ambos sexos y
                                     todas las ramas. Grado (con licenciaturas y diplomaturas)
                                     desde 1985-86 y máster desde 2006-07.
  educacion_privada_univ_numero      Estadística de Universidades, Centros y Titulaciones
                                     (EUCT/ESTR/px_euct_estr_univ_ca): número de universidades con
                                     actividad por comunidad, tipo y modalidad, desde 2015-16.
  educacion_privada_ruct_universidades  Registro de Universidades, Centros y Títulos (RUCT): ficha de
                                     cada universidad (tipo, ánimo de lucro, comunidad y norma de
                                     creación o reconocimiento con su fecha).
"""

import datetime as dt
import itertools
import logging
import re

import dlt
import requests

log = logging.getLogger(__name__)

EDUCA = "https://estadisticas.educacion.gob.es/EducaJaxiPx/files/_px/es/px/"
CIENCIA = "https://estadisticas.ciencia.gob.es/jaxiPx/files/_px/es/px/"
H = {"User-Agent": "Mozilla/5.0 (SpainFacts; datos abiertos)"}

# Series de alumnado por titularidad (pública / privada) y comunidad: fichero -> enseñanza
SERIES_ALUMNADO = {
    "alumnado_1_01": "Total régimen general",
    "alumnado_2_01": "E. Infantil",
    "alumnado_2_03": "E. Infantil primer ciclo",
    "alumnado_2_04": "E. Infantil segundo ciclo",
    "alumnado_3_01": "E. Primaria",
    "alumnado_3_05": "Educación Especial",
    "alumnado_4_01": "ESO",
    "alumnado_5_01": "Bachillerato",
    "alumnado_6_01": "FP Grado Básico",
    "alumnado_6_05": "FP Grado Medio presencial",
    "alumnado_6_07": "FP Grado Medio a distancia",
    "alumnado_6_13": "FP Grado Superior presencial",
    "alumnado_6_15": "FP Grado Superior a distancia",
}


# ---------------------------------------------------------------------------------------------
# Lector de PC-Axis
# ---------------------------------------------------------------------------------------------
def _cadenas(valor: str) -> list[str]:
    return re.findall(r'"((?:[^"]|"")*)"', valor)


def parse_px(contenido: bytes) -> dict:
    """Devuelve {'dims': [(nombre, [valores])...], 'codes': {dim: [códigos]}, 'data': [float|None],
    'meta': {clave: texto}} con las dimensiones en el orden del cubo (STUB y luego HEADING)."""
    texto = contenido.decode("iso-8859-15")
    pos = texto.index("DATA=")
    cabecera, datos = texto[:pos], texto[pos + 5:]
    entradas, i, n = {}, 0, len(cabecera)
    while i < n:
        j = cabecera.find("=", i)
        if j < 0:
            break
        clave = cabecera[i:j].strip()
        k, dentro = j + 1, False
        while k < n and (dentro or cabecera[k] != ";"):
            if cabecera[k] == '"':
                dentro = not dentro
            k += 1
        entradas[clave] = cabecera[j + 1:k]
        i = k + 1
    valores, codigos, meta = {}, {}, {}
    for clave, v in entradas.items():
        m = re.match(r'(VALUES|CODES)\("(.*)"\)$', clave)
        if m:
            (valores if m.group(1) == "VALUES" else codigos)[m.group(2)] = _cadenas(v)
        else:
            meta[clave] = "".join(_cadenas(v)) if '"' in v else v.strip()
    orden = _cadenas(entradas.get("STUB", "")) + _cadenas(entradas.get("HEADING", ""))
    data = []
    for tok in datos.replace(";", " ").split():
        tok = tok.strip('"')
        try:
            data.append(float(tok))
        except ValueError:
            data.append(None)  # '.', '..', '-': dato no disponible o secreto
    dims = [(d, valores[d]) for d in orden]
    total = 1
    for _, vs in dims:
        total *= len(vs)
    if len(data) != total:
        raise ValueError(f"PC-Axis: {len(data)} datos para un cubo de {total}")
    return {"dims": dims, "codes": codigos, "data": data, "meta": meta}


def _celdas(px: dict):
    """(dict dimensión -> valor, dato) para cada celda del cubo."""
    nombres = [d for d, _ in px["dims"]]
    for combinacion, dato in zip(itertools.product(*[vs for _, vs in px["dims"]]), px["data"]):
        yield dict(zip(nombres, combinacion)), dato


def _descargar(url: str) -> bytes | None:
    r = requests.get(url, headers=H, timeout=300)
    r.raise_for_status()
    # Si el fichero no existe, el servidor contesta 200 con una página HTML de error
    return r.content if r.content.lstrip().startswith(b"AXIS-VERSION") else None


def _px(url: str) -> dict:
    contenido = _descargar(url)
    if contenido is None:
        raise ValueError(f"No es un fichero PC-Axis: {url}")
    return parse_px(contenido)


def _dim(celda: dict, prefijo: str) -> str:
    """Valor de la dimensión cuyo nombre empieza por prefijo (los nombres cambian entre años)."""
    for k, v in celda.items():
        if k.startswith(prefijo):
            return v
    raise KeyError(prefijo)


# ---------------------------------------------------------------------------------------------
@dlt.source(name="educacion_privada")
def educacion_privada():
    @dlt.resource(name="educacion_privada_alumnado_curso", write_disposition="replace")
    def alumnado_curso():
        for ini in range(2011, dt.date.today().year + 1):
            curso = f"{ini}-{ini + 1}"
            url = f"{EDUCA}no-universitaria/alumnado/matriculado/{curso}-rd/gen-todas/l0/todas_01.px?nocab=1"
            contenido = _descargar(url)
            if contenido is None:
                log.info("Sin resultados detallados para %s", curso)
                continue
            px = parse_px(contenido)
            filas = 0
            for celda, dato in _celdas(px):
                territorio = _dim(celda, "Comunidad")
                if _dim(celda, "Sexo") != "AMBOS SEXOS" or not re.match(r"^\d\d ", territorio):
                    continue  # solo ambos sexos y comunidades (no provincias)
                if dato is None:
                    continue
                filas += 1
                yield {
                    "curso": curso,
                    "cod_ccaa": territorio[:2],
                    "territorio": territorio[3:],
                    "titularidad": _dim(celda, "Titularidad"),
                    "ensenanza": _dim(celda, "Enseñanza"),
                    "alumnos": dato,
                    "url": url,
                }
            log.info("%s: %d filas", curso, filas)

    @dlt.resource(name="educacion_privada_alumnado_serie", write_disposition="replace")
    def alumnado_serie():
        for fichero, ensenanza in SERIES_ALUMNADO.items():
            url = f"{EDUCA}no-universitaria/alumnado/matriculado/series/AlumnadoGen/l0/{fichero}.px?nocab=1"
            px = _px(url)
            for celda, dato in _celdas(px):
                if dato is None:
                    continue
                periodo = _dim(celda, "periodo")
                yield {
                    "tabla": fichero,
                    "ensenanza": ensenanza,
                    "titularidad": _dim(celda, "Titularidad"),
                    "territorio": _dim(celda, "Comunidad"),
                    "periodo": periodo,
                    "es_avance": "(*)" in periodo,
                    "alumnos": dato,
                }

    @dlt.resource(name="educacion_privada_gasto_conciertos", write_disposition="replace")
    def gasto_conciertos():
        px = _px(f"{EDUCA}economicas/gasto/series/l0/series_07.px?nocab=1")
        for celda, dato in _celdas(px):
            if dato is None:
                continue
            yield {
                "administracion": _dim(celda, "Administración"),
                "anio": int(_dim(celda, "periodo")),
                "miles_eur": dato,
            }

    @dlt.resource(name="educacion_privada_gasto_admin", write_disposition="replace")
    def gasto_admin():
        px = _px(f"{EDUCA}economicas/gasto/series/l0/series_01.px?nocab=1")
        for celda, dato in _celdas(px):
            if dato is None:
                continue
            yield {
                "cobertura": _dim(celda, "Cobertura"),
                "administracion": _dim(celda, "Tipo de administración"),
                "anio": int(_dim(celda, "periodo")),
                "miles_eur": dato,
            }

    @dlt.resource(name="educacion_privada_univ_matriculados", write_disposition="replace")
    def univ_matriculados():
        tablas = [
            ("Grado", "HIST_GRADO/l0/px_estu_hist_grado_matric_sexo_rama_ca.px"),
            ("Máster", "HIST_MASTER/l0/px_estu_hist_master_matric_sexo_rama_ca.px"),
        ]
        for nivel, ruta in tablas:
            px = _px(f"{CIENCIA}Universitaria/ESTU/{ruta}?nocab=1")
            ccaa = dict(zip(dict(px["dims"])["Comunidad autónoma"], px["codes"]["Comunidad autónoma"]))
            for celda, dato in _celdas(px):
                if dato is None or celda["Sexo"] != "Ambos sexos" or celda["Rama de enseñanza"] != "Total":
                    continue
                nivel_px = celda.get("Nivel académico", "Total")
                if nivel_px not in ("Total", "Grado"):
                    continue
                yield {
                    "nivel": nivel,
                    "nivel_academico": nivel_px,
                    "cod_siiu": ccaa[celda["Comunidad autónoma"]],
                    "territorio": celda["Comunidad autónoma"],
                    "tipo_universidad": celda["Tipo de universidad"],
                    "modalidad": celda["Modalidad de la universidad"],
                    "curso": celda["Periodo"],
                    "estudiantes": dato,
                }

    @dlt.resource(name="educacion_privada_univ_numero", write_disposition="replace")
    def univ_numero():
        px = _px(f"{CIENCIA}Universitaria/EUCT/ESTR/l0/px_euct_estr_univ_ca.px?nocab=1")
        ccaa = dict(zip(dict(px["dims"])["Comunidad autónoma"], px["codes"]["Comunidad autónoma"]))
        for celda, dato in _celdas(px):
            if dato is None:
                continue
            yield {
                "cod_siiu": ccaa[celda["Comunidad autónoma"]],
                "territorio": celda["Comunidad autónoma"],
                "tipo_universidad": celda["Tipo de universidad"],
                "modalidad": celda["Modalidad de la universidad"],
                "curso": celda["Periodo"],
                "universidades": dato,
            }

    @dlt.resource(name="educacion_privada_gasto_transferencias", write_disposition="replace")
    def gasto_transferencias():
        """Tabla anual «Transferencias de las Administraciones Educativas a centros educativos de
        titularidad privada por administración educativa y enseñanza» de la Estadística del Gasto
        Público en Educación (economicas/gasto/<año>). Su número cambia (gasto06 en 2024, gasto07
        antes): se busca por título en el índice de cada año."""
        indice = "https://estadisticas.educacion.gob.es/EducaDynPx/educabase/index.htm?type=pcaxis&path=/economicas/gasto/{}&file=pcaxis&l=s0"
        for anio in range(2000, dt.date.today().year + 1):
            t = requests.get(indice.format(anio), headers=H, timeout=120).text
            ruta = None
            for m in re.finditer(r'Tabla\.htm\?path=([^"&]*)&amp;file=([^"&]*)&amp;[^>]*>(.*?)</a>', t, re.S):
                titulo = " ".join(re.sub(r"<[^>]*>", " ", m.group(3)).split()).lower()
                if titulo.startswith("transferencias") and "titularidad privada" in titulo:
                    ruta = m.group(1) + m.group(2)
            if not ruta:
                continue
            url = f"{EDUCA}{ruta.lstrip('/')}?nocab=1"
            px = _px(url)
            for celda, dato in _celdas(px):
                if dato is None:
                    continue
                yield {
                    "anio": anio,
                    "administracion": _dim(celda, "Administración"),
                    "ensenanza": _dim(celda, "Enseñanza"),
                    "miles_eur": dato,
                    "url": url,
                }

    @dlt.resource(name="educacion_privada_ruct_universidades", write_disposition="replace")
    def ruct_universidades():
        """Ficha de cada universidad en el Registro de Universidades, Centros y Títulos (RUCT,
        https://www.educacion.gob.es/ruct/universidad.action?codigoUniversidad=NNN): tipo
        (pública/privada), ánimo de lucro, comunidad, y la norma de creación o reconocimiento
        (boletín, tipo de disposición y fechas). Se recorren los códigos 001-150; los que no
        existen devuelven una ficha vacía."""
        import html as html_mod

        campos = {
            "Código de la universidad": "codigo", "Acrónimo": "acronimo", "Tipo": "tipo",
            "Con ánimo de lucro": "animo_lucro", "Administración Educativa Responsable": "administracion",
            "Comunidad Autónoma": "comunidad", "Provincia": "provincia", "Municipio": "municipio",
            "Tipo Boletín": "boletin", "Año publicación": "anio_publicacion",
            "Tipo disposición": "tipo_disposicion", "Fecha disposición": "fecha_disposicion",
            "Fecha publicación": "fecha_publicacion", "Fecha entrada en Vigor": "fecha_vigor",
        }
        for n in range(1, 151):
            codigo = f"{n:03d}"
            url = f"https://www.educacion.gob.es/ruct/universidad.action?codigoUniversidad={codigo}&actual=universidades"
            r = requests.get(url, headers=H, timeout=60)
            if r.status_code != 200:
                continue
            texto = html_mod.unescape(re.sub(r"<[^>]*>", "\n", r.content.decode("iso-8859-1", "replace")))
            lineas = [x.strip() for x in texto.splitlines() if x.strip()]
            fila = {}
            for i, x in enumerate(lineas[:-1]):
                clave = x.rstrip(":").strip()
                if x.endswith(":") and clave in campos and campos[clave] not in fila:
                    valor = lineas[i + 1]
                    fila[campos[clave]] = None if valor.endswith(":") else valor
            if fila.get("codigo") != codigo:
                continue
            i = lineas.index("Datos de identificación") if "Datos de identificación" in lineas else -1
            fila["nombre"] = lineas[i - 1] if i > 0 else None
            fila["url"] = url
            yield fila

    @dlt.resource(name="educacion_privada_fp_ciclos", write_disposition="replace")
    def fp_ciclos():
        """Alumnado de FP por ciclo formativo (agrupados por familia profesional), titularidad
        (todos / públicos / privados) y comunidad: tablas «por comunidad autónoma/provincia,
        ciclo formativo y titularidad» de gen-ciclos-fp de cada curso (desde 2016-17; antes
        solo se publican por ciclo para el total nacional). Se localizan en el índice de
        EDUCAbase porque su número cambia entre cursos."""
        indice = "https://estadisticas.educacion.gob.es/EducaDynPx/educabase/index.htm?type=pcaxis&path={}&file=pcaxis&l=s0"
        for ini in range(2016, dt.date.today().year + 1):
            curso = f"{ini}-{ini + 1}"
            carpeta = f"/no-universitaria/alumnado/matriculado/{curso}-rd/gen-ciclos-fp"
            t = requests.get(indice.format(carpeta), headers=H, timeout=120).text
            tablas = []
            for m in re.finditer(r'Tabla\.htm\?path=([^"&]*)&amp;file=([^"&]*)&amp;[^>]*>(.*?)</a>', t, re.S):
                titulo = " ".join(re.sub(r"<[^>]*>", " ", m.group(3)).split())
                tl = titulo.lower()
                if "ciclo formativo" in tl and "titularidad" in tl and "comunidad" in tl and "sexo" not in tl:
                    tablas.append((m.group(1) + m.group(2), titulo))
            if not tablas:
                log.info("Sin tablas de FP por ciclo para %s", curso)
                continue
            for ruta, titulo in tablas:
                tl = titulo.lower()
                grado = "Básico" if "básico" in tl else "Medio" if "grado medio" in tl else "Superior"
                modalidad = "A distancia" if "distancia" in tl else "Presencial"
                plan = "LOGSE" if "logse" in tl else "LOE" if "plan loe" in tl else None
                url = f"{EDUCA}{ruta.lstrip('/')}?nocab=1"
                px = _px(url)
                nombres = [d for d, _ in px["dims"]]
                d_ciclo = next(d for d in nombres if d.startswith("Ciclo"))
                # familia de cada ciclo: la última fila en mayúsculas que lo precede
                # (en 2022-23 un ciclo de FP básica se llama igual que su familia, en mayúsculas:
                # la repetición es el ciclo, no otra fila de familia)
                familia, familias, es_fam = None, {}, {}
                sin_codigo = lambda x: re.sub(r"^\d+\s*", "", (x or "").strip())  # noqa: E731
                for k, v in enumerate(dict(px["dims"])[d_ciclo]):
                    if v.strip() == v.strip().upper() and sin_codigo(v) != sin_codigo(familia):
                        familia = v.strip()
                        es_fam[k] = True
                    familias[k] = familia
                pos_ciclo = nombres.index(d_ciclo)
                rangos = [range(len(vs)) for _, vs in px["dims"]]
                # índices (no nombres) porque un nombre de ciclo puede repetirse
                for idx, dato in zip(itertools.product(*rangos), px["data"]):
                    celda = {d: px["dims"][i][1][j] for i, (d, j) in enumerate(zip(nombres, idx))}
                    territorio = _dim(celda, "Comunidad")
                    # el total nacional se llama '00 TOTAL' o, en FP básica 2019-2022, 'TODOS LOS CENTROS'
                    if territorio in ("TODOS LOS CENTROS", "TOTAL"):
                        territorio = "00 TOTAL"
                    if dato is None or not re.match(r"^\d\d ", territorio):
                        continue
                    k = idx[pos_ciclo]
                    yield {
                        "curso": curso,
                        "grado": grado,
                        "modalidad": modalidad,
                        "plan": plan,
                        "cod_ccaa": territorio[:2],
                        "titularidad": _dim(celda, "Titularidad"),
                        "familia": familias[k],
                        "ciclo": celda[d_ciclo].strip(),
                        "es_familia": es_fam.get(k, False),
                        "alumnos": dato,
                        "url": url,
                    }

    return (alumnado_curso, alumnado_serie, gasto_conciertos, gasto_admin, univ_matriculados,
            univ_numero, fp_ciclos, gasto_transferencias, ruct_universidades)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("educacion_privada").run(educacion_privada()))
