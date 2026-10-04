"""Fuente dlt de libertad de prensa y pluralismo de los medios (tema `medios_libertad`):
índices internacionales para comparar España con la UE y otros países.

1) Reporters sans frontières (RSF), Clasificación Mundial de la Libertad de Prensa:
   un CSV por edición (rsf.org/sites/default/files/import_classement/<año>.csv,
   2002-2010, 2012 = «2011-12», 2013 en adelante; no existe 2011). Puntuación y puesto
   mundial y, desde 2022, los cinco indicadores (contexto político, económico,
   legislativo, social y seguridad) con su puesto. Tres escalas no comparables entre sí:
   2002-2012 (0 = mejor, sin tope), 2013-2021 (0-100, 100 = mejor, como la publica hoy
   RSF) y 2022 en adelante (nueva metodología, 0-100). Condiciones de rsf.org: todos los
   derechos reservados; se reproducen las puntuaciones y puestos oficiales tal cual,
   citando a RSF, sin medias ni transformaciones propias. Los ficheros mezclan UTF-8
   con BOM y Windows-1252, separador ';' y coma decimal.
2) V-Dem vía Our World in Data (gráficos key-media-freedoms y
   freedom-of-expression-index): censura gubernamental de los medios (v2mecenefm),
   acoso a periodistas (v2meharjrn), autocensura de los medios (v2meslfcen), sesgo de
   los medios (v2mebias), en la escala latente del modelo de medida (más alto = más
   libertad, aprox. -4 a 4), e índice de libertad de expresión y fuentes alternativas
   de información (0-1). V-Dem CC BY-SA 4.0, OWID CC BY 4.0.
3) Media Pluralism Monitor (EUI, Centre for Media Pluralism and Media Freedom), edición
   en curso: ficha de cada país en cmpf.eui.eu/country/<pais>-<edición>/ (lista por la
   API de WordPress, tipo «country»): riesgo global y de las cuatro áreas (protección
   fundamental, pluralidad del mercado, independencia política, inclusión social), en
   % (0 = sin riesgo). CC BY 4.0. Las ediciones anteriores, que solo están en PDF,
   van en el seed medios_libertad_mpm_historico.
4) Consejo de Europa, Plataforma para la protección del periodismo y la seguridad de
   los periodistas (fom.coe.int): alertas por país y año desde 2015 (API pública del
   propio portal, fom-api.coe.int/api/Alerte/GetYearStats). OJO: «alertas» (nbAlerte)
   son las alertas activas; las resueltas van aparte (nbAlerteResolu) y el total del
   año es la suma (cuadra con el informe anual de las organizaciones socias). También
   las que siguen sin respuesta del Estado y los periodistas asesinados.

Recursos (replace): medios_libertad_rsf, medios_libertad_vdem, medios_libertad_mpm,
medios_libertad_coe_alertas.
"""

import csv
import datetime as dt
import html
import io
import logging
import re
import time

import dlt
import requests

log = logging.getLogger(__name__)

CABECERAS = {"User-Agent": "Mozilla/5.0 (compatible; SpainFacts; https://spainfacts.org)"}

RSF_URL = "https://rsf.org/sites/default/files/import_classement/{anio}.csv"
OWID_URL = "https://ourworldindata.org/grapher/{}.csv?v=1&csvType=full&useColumnShortNames=true"
VDEM_GRAFICOS = {
    # gráfico OWID -> {columna: indicador_id}
    "key-media-freedoms": {
        "v2mecenefm__estimate_best": "vdem_censura_medios",
        "v2meharjrn__estimate_best": "vdem_acoso_periodistas",
        "v2meslfcen__estimate_best": "vdem_autocensura_medios",
        "v2mebias__estimate_best": "vdem_sesgo_medios",
    },
    "freedom-of-expression-index": {
        "freeexpr_vdem__estimate_best": "vdem_libertad_expresion",
    },
}
CMPF_API = "https://cmpf.eui.eu/wp-json/wp/v2/country"
COE_API = "https://fom-api.coe.int/api"

RSF_INDICADORES = {
    # cabecera RSF -> (columna de puntuación, columna de puesto)
    "Political Context": ("politico", "Rank_Pol"),
    "Economic Context": ("economico", "Rank_Eco"),
    "Legal Context": ("legislativo", "Rank_Leg"),
    "Social Context": ("social", "Rank_Soc"),
    "Safety": ("seguridad", "Rank_Saf"),
}
MPM_AREAS = {
    "fundamental protection": "proteccion_fundamental",
    "market plurality": "pluralidad_mercado",
    "political independence": "independencia_politica",
    "social inclusiveness": "inclusion_social",
}


def _get(url: str, intentos: int = 4, **kw) -> requests.Response:
    for i in range(intentos):
        try:
            r = requests.get(url, timeout=120, headers=CABECERAS, **kw)
            r.raise_for_status()
            return r
        except requests.RequestException as e:
            if i == intentos - 1 or (getattr(e, "response", None) is not None and e.response.status_code in (403, 404)):
                raise
            log.warning("Reintento %s de %s: %s", i + 1, url, e)
            time.sleep(5 * (i + 1))


def _num(v):
    if v is None:
        return None
    v = str(v).strip().replace(",", ".")
    try:
        return float(v)
    except ValueError:
        return None


def _texto(contenido: bytes) -> str:
    try:
        return contenido.decode("utf-8-sig")
    except UnicodeDecodeError:
        return contenido.decode("cp1252", errors="replace")


@dlt.source(name="medios_libertad")
def medios_libertad():
    @dlt.resource(name="medios_libertad_rsf", write_disposition="replace")
    def rsf():
        hoy = dt.date.today().year
        for anio in range(2002, hoy + 1):
            try:
                r = _get(RSF_URL.format(anio=anio))
            except requests.RequestException as e:
                log.info("RSF %s sin fichero (%s)", anio, e)
                continue
            texto = _texto(r.content)
            if not texto.lstrip().startswith(("ISO", "Year")):
                log.info("RSF %s no es un CSV", anio)
                continue
            lector = csv.DictReader(io.StringIO(texto), delimiter=";")
            cab = [c.strip() for c in lector.fieldnames]
            lector.fieldnames = cab
            col_punt = next(c for c in cab if c in ("Score N", "Score") or re.fullmatch(r"Score \d{4}", c))
            col_puesto = "Rank N" if "Rank N" in cab else "Rank"
            escala = "2002-2012" if anio <= 2012 else ("2013-2021" if anio <= 2021 else "2022")
            n = 0
            for f in lector:
                iso = (f.get("ISO") or "").strip()
                punt = _num(f.get(col_punt))
                if not re.fullmatch(r"[A-Z]{3}", iso) or punt is None:
                    continue
                fila = {
                    "edicion": anio,
                    "etiqueta_edicion": (f.get("Year (N)") or str(anio)).strip(),
                    "escala": escala,
                    "cod_pais": iso,
                    "pais_fuente": (f.get("Country_EN") or f.get("EN_country") or "").strip(),
                    "zona": (f.get("Zone") or "").strip(),
                    "puntuacion": punt,
                    "puesto": _num(f.get(col_puesto)),
                }
                for cabecera, (nombre, col_rank) in RSF_INDICADORES.items():
                    if cabecera in cab:
                        fila[f"{nombre}_puntuacion"] = _num(f.get(cabecera))
                        fila[f"{nombre}_puesto"] = _num(f.get(col_rank))
                n += 1
                yield fila
            log.info("RSF %s: %s países", anio, n)
            time.sleep(0.5)

    @dlt.resource(name="medios_libertad_vdem", write_disposition="replace")
    def vdem():
        for grafico, columnas in VDEM_GRAFICOS.items():
            lector = csv.DictReader(io.StringIO(_get(OWID_URL.format(grafico)).text))
            n = 0
            for fila in lector:
                if not re.fullmatch(r"[A-Z]{3}", fila.get("code") or "") or int(fila["year"]) < 1970:
                    continue
                for col, indicador_id in columnas.items():
                    v = _num(fila.get(col))
                    if v is None:
                        continue
                    n += 1
                    yield {"indicador_id": indicador_id, "cod_indicador": col.split("__")[0], "cod_pais": fila["code"],
                           "pais_fuente": fila["entity"], "anio": int(fila["year"]), "valor": v}
            log.info("V-Dem %s: %s filas", grafico, n)

    @dlt.resource(name="medios_libertad_mpm", write_disposition="replace")
    def mpm():
        paises = _get(CMPF_API, params={"per_page": 100, "_fields": "id,slug,link,title"}).json()
        n = 0
        for p in paises:
            m = re.search(r"-(\d{4})(?:-\d+)?/?$", p["link"])
            if not m:
                continue
            edicion = int(m.group(1))
            pagina = _get(p["link"]).text
            nombre = html.unescape(re.sub(r"\s*\d{4}$", "", p["title"]["rendered"]).strip())
            total = re.search(r"Risk score:\s*(\d{1,3})\s*%", pagina)
            if total:
                n += 1
                yield {"edicion": edicion, "pais_fuente": nombre, "area": "total", "riesgo_pct": float(total.group(1)),
                       "url": p["link"]}
            for nombre_area, v in re.findall(
                    r"<td>\s*([A-Za-z ]+?)\s*</td>\s*<td>\s*<span class='mpm-risk-score'>\s*(\d{1,3})\s*</span>", pagina):
                area = MPM_AREAS.get(nombre_area.strip().lower())
                if area:
                    n += 1
                    yield {"edicion": edicion, "pais_fuente": nombre, "area": area, "riesgo_pct": float(v),
                           "url": p["link"]}
            time.sleep(0.5)
        if n == 0:
            raise ValueError("MPM: no se encontró ninguna puntuación en las fichas de país de cmpf.eui.eu")
        log.info("MPM: %s filas", n)

    @dlt.resource(name="medios_libertad_coe_alertas", write_disposition="replace")
    def coe_alertas():
        paises = _get(f"{COE_API}/Pays").json()
        hoy = dt.date.today().year
        n = 0
        for p in paises:
            if not p.get("estPublier") or not p.get("libelleEN"):
                continue
            for anio in range(2015, hoy + 1):
                d = _get(f"{COE_API}/Alerte/GetYearStats",
                         params={"depuis2015": "false", "annee": anio, "idPays": p["identifiant"],
                                 "touteEurope": "false"}).json()
                n += 1
                yield {"id_pais_coe": p["identifiant"], "pais_fuente": p["libelleEN"], "anio": anio,
                       "alertas": d.get("nbAlerte"), "sin_respuesta": d.get("nbSansReponse"),
                       "resueltas": d.get("nbAlerteResolu"), "periodistas_asesinados": d.get("nbJournalisteTuee")}
                time.sleep(0.15)
        log.info("Consejo de Europa: %s filas país-año", n)

    return [rsf, vdem, mpm, coe_alertas]


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    from ingestion.destino import pipeline

    print(pipeline("medios_libertad").run(medios_libertad()))
