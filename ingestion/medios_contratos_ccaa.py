"""Fuente dlt «Contratos a empresas de medios en las plataformas autonómicas» (tema `medios_contratos`, ampliación).

La sindicación de PLACSP (ingestion/medios_contratos.py) no trae los contratos MENORES de las
comunidades con plataforma propia (Cataluña, Euskadi, Andalucía, C. de Madrid, Galicia, Navarra,
La Rioja) ni de los entes que publican en ellas. Este módulo los toma de los datos abiertos de cada
plataforma y se queda solo con los adjudicatarios del padrón de medios
(transform/seeds/medios_padron_nif.csv, es_medio 'si' o 'gris').

Plataformas (columna `plataforma`):
  cat_pscp   Generalitat de Catalunya, «Publicacions a la Plataforma de serveis de contractació
             pública» (Socrata ybgg-dgi6, analisi.transparenciacatalunya.cat). CON NIF. Menores con
             volumen desde 2022-2023 (Generalitat, entes locales, universidades).
  cat_rpc    Generalitat de Catalunya, «Inscripcions al Registre públic de contractes» (Socrata
             hb6v-jcbf). SIN NIF: se casa por nombre normalizado. Menores desde 2021 (situació
             contractual = 'menor'). Importe sin IVA.
  eus_kontratazioa  Gobierno Vasco, API REST de la Plataforma KontratazioA
             (https://api.euskadi.eus/procurements/contracts/companies/{NIF}). CON NIF. Menores desde 2017.
  and_junta  Junta de Andalucía, «Contratación menor publicada en la Plataforma de Contratación de
             la Junta de Andalucía», CSV anual 2018-2026 (CKAN juntadeandalucia.es/datosabiertos). CON NIF.
  gal_xunta  Xunta de Galicia, Plataforma de Contratos Públicos de Galicia, tabla pública de
             contratos menores por organismo (https://www.contratosdegalicia.gal/api/v1/organismos/
             {id}/contratosmenores/table), organismos enlazados desde transparencia.xunta.gal. CON NIF.
             El importe lleva IVA (abundan 18.029 y 18.149 € = 14.900 y 14.999 € + 21 %): el importe sin
             IVA se estima (÷1,04 suscripciones y prensa, ÷1,21 resto).
  rio_car    Gobierno de La Rioja, «Contratos menores AAAA Comunidad Autónoma de La Rioja»
             (web.larioja.org/dato-abierto, opd-866..1175), 2021-2026. CON NIF. Importe del
             ejercicio CON IVA.
  mad_ayto   Ayuntamiento de Madrid, «Contratos menores» (datos.madrid.es 300253), CSV anual
             2018-2026. CON NIF. Importe CON IVA.
  bcn_ayto   Ajuntament de Barcelona, «Contractes menors de l'Ajuntament i ens municipals»
             (Open Data BCN), solo 2018 (después publica en la PSCP/RPC). CON NIF. Importe sin IVA
             (el conjunto se define como contratos de valor sin IVA inferior a 15.000/40.000 €).

  mad_cm     Comunidad de Madrid, buscador público del Portal de Contratación
             (contratos-publicos.comunidad.madrid/contratos?t=<NIF>&f[0]=tipo_publicacion:Contratos Menores
             y ficha /contrato/<ref>): consejerías, organismos y empresas públicas (Metro, Canal de
             Isabel II...). CON NIF. Importe sin y con IVA. Peticiones GET en serie cada 2,5 s; NO se usa
             la exportación CSV (captcha y módulo antibot). Si aparece un reto, se para (RetoAntibot).
  nav_portal Navarra, «Relaciones trimestrales de facturas» de contratos de menor cuantía (LF 2/2018,
             art. 81) del Portal de Contratación de Navarra (hacienda.navarra.es/sicpportal), 2018-2026:
             Gobierno de Navarra, sociedades públicas y entidades locales. Un documento PDF/Excel por
             entidad y trimestre, con formato propio; casi nunca trae NIF: se casa por nombre
             normalizado (metodo_casado 'nombre') o por NIF si aparece en la línea. Cada fila es una
             FACTURA (no un contrato) y el importe lleva IVA (sin IVA estimado). Los departamentos
             del Gobierno listan las facturas de más de 100 €.

Casado con el padrón:
  - metodo_casado = 'nif': NIF del adjudicatario en el padrón.
  - metodo_casado = 'nombre' (solo cat_rpc): nombre normalizado (mayúsculas, sin acentos ni
    puntuación, sin forma jurídica final) idéntico a un nombre conocido de un NIF del padrón
    (nombre del padrón, nombres con ese NIF en PLACSP y en la PSCP). Un nombre que en las fuentes
    con NIF aparece también con NIF de fuera del padrón es AMBIGUO y no se casa.
  - Candidatos (clase = 'candidato'): nombre con «pinta de medio» (regex de medios_contratos.py)
    pero NIF fuera del padrón. Para revisar. En cat_rpc y cat_pscp se guardan agregados por nombre
    (ccaa_candidatos_nombres); en el resto, fila a fila (ccaa_candidatos_medios).
  - No se guardan personas físicas.

Recursos:
  ccaa_contratos_medios    (merge, pk plataforma + id_contrato + nif_adjudicatario)
  ccaa_candidatos_medios   (merge, misma clave)
  ccaa_candidatos_nombres  (merge, pk plataforma + nombre_adjudicatario + nif_adjudicatario)
  ccaa_cobertura           (merge, pk plataforma + periodo): filas leídas, menores, casadas

La deduplicación frente a PLACSP (contratos menores de órganos que publican en los dos sitios, y
contratos no menores que ya llegan por la agregación) y entre cat_pscp y cat_rpc se hace en dbt
(medios_contratos_base). Aquí solo se marca es_menor.

Uso: medios_contratos_ccaa(plataformas=(...), desde=2018, cache_dir=...). cache_dir guarda el
resultado de cada paso (json.gz) para reanudar.
"""

from __future__ import annotations

import base64
import csv
import gzip
import hashlib
import io
import json
import logging
import re
import time
import zipfile
from datetime import date, datetime, timezone
from pathlib import Path
from urllib.parse import urlencode

import dlt
import requests

from ingestion.medios_contratos import (PROV_CCAA, RE_CANDIDATO, RE_PERSONA_FISICA, leer_padron, norm,
                                        norm_nif)

log = logging.getLogger(__name__)
CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}
PLATAFORMAS = ("cat_pscp", "cat_rpc", "eus_kontratazioa", "and_junta", "gal_xunta", "rio_car", "mad_ayto", "bcn_ayto",
               "mad_cm", "nav_portal")
CCAA_PLATAFORMA = {"cat_pscp": "09", "cat_rpc": "09", "eus_kontratazioa": "16", "and_junta": "01",
                   "gal_xunta": "12", "rio_car": "17", "mad_ayto": "13", "bcn_ayto": "09",
                   "mad_cm": "13", "nav_portal": "15"}
SOCRATA = "https://analisi.transparenciacatalunya.cat/resource/"
CLAVE = ["plataforma", "id_contrato", "nif_adjudicatario"]


# --- utilidades -------------------------------------------------------------------------------
def _get(url, params=None, intentos=6, timeout=(30, 300), sesion=None, **kw):
    s = sesion or requests
    for i in range(intentos):
        try:
            r = s.get(url, params=params, timeout=timeout, headers=kw.get("headers", CABECERAS))
            if r.status_code in (404, 400):
                return r
            if r.status_code == 429:  # límite de peticiones: esperar y reintentar sin gastar intento
                espera = int(r.headers.get("Retry-After") or 0) or 60
                log.warning("429 en %s: espero %d s", url[:100], espera)
                time.sleep(min(espera, 300))
                r = s.get(url, params=params, timeout=timeout, headers=kw.get("headers", CABECERAS))
            r.raise_for_status()
            return r
        except Exception as e:  # noqa: BLE001
            log.warning("GET %s intento %d: %s", url[:120], i + 1, e)
            time.sleep(5 * (i + 1) ** 2)
    raise RuntimeError(f"No se pudo descargar {url[:200]}")


def num(s):
    """Número en formato español o inglés, con símbolos (€, espacios)."""
    if s is None:
        return None
    if isinstance(s, (int, float)):
        return float(s)
    s = re.sub(r"[^0-9,.\-]", "", str(s))
    if not s or s in "-.,":
        return None
    if "," in s and "." in s:
        s = s.replace(".", "").replace(",", ".") if s.rfind(",") > s.rfind(".") else s.replace(",", "")
    elif "," in s:
        s = s.replace(",", ".")
    elif s.count(".") > 1:
        s = s.replace(".", "")
    try:
        return float(s)
    except ValueError:
        return None


def fecha(s):
    """'2024-03-10T00:00:00.000' | '10/03/2024' | '2024/03/10 00:00' | '10-03-2024' -> '2024-03-10'"""
    if not s:
        return None
    s = str(s).strip()
    m = re.match(r"(\d{4})[-/](\d{1,2})[-/](\d{1,2})", s)
    if m:
        y, mo, d = m.groups()
    else:
        m = re.match(r"(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})\b", s)
        if not m:
            return None
        d, mo, y = m.groups()
        if len(y) == 2:
            y = "20" + y
    try:
        return date(int(y), int(mo), int(d)).isoformat()
    except ValueError:
        return None


FORMAS = re.compile(
    r"(\s+(S ?A ?U|S ?A ?L|S ?A|S ?L ?U|S ?L ?L|S ?L ?P|S ?L|S ?C ?C ?L|S ?C ?P|S ?C|S COOP( ?V| ?G| ?AND)?|COOP|"
    r"SOCIEDAD (ANONIMA|LIMITADA|COOPERATIVA)( UNIPERSONAL| LABORAL)?|SOCIETAT (ANONIMA|LIMITADA|COOPERATIVA)( UNIPERSONAL)?|"
    r"UNIPERSONAL|SOCIETAT LIMITADA UNIPERSONAL|SLNE|AIE|SPA|SRL|GMBH|LTD))+$")


def norm_nombre(s: str | None) -> str:
    """Nombre normalizado para casar: sin acentos ni puntuación ni forma jurídica final."""
    s = norm(s)
    s = re.sub(r"(?<=\b[A-Z])\.(?=[A-Z]\b|\s|$)", "", s)  # S.A.U. -> SAU, S. L. -> S L
    s = s.replace("'", " ").replace("`", " ")
    s = re.sub(r"[^A-Z0-9 ]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    prev = None
    while prev != s:
        prev, s = s, FORMAS.sub("", s).strip()
    return s


def _es_persona(nif):
    return bool(nif and RE_PERSONA_FISICA.match(nif))


def _cache(cache_dir, nombre):
    return Path(cache_dir) / f"{nombre}.json.gz" if cache_dir else None


def _lee_cache(p):
    if p and p.exists():
        with gzip.open(p, "rt", encoding="utf-8") as fh:
            return json.load(fh)
    return None


def _escribe_cache(p, d):
    if p:
        p.parent.mkdir(parents=True, exist_ok=True)
        tmp = p.with_suffix(".tmp")
        with gzip.open(tmp, "wt", encoding="utf-8") as fh:
            json.dump(d, fh)
        tmp.replace(p)


# --- nivel del órgano -----------------------------------------------------------------------------
RE_LOCAL = re.compile(r"(?i)ayuntamiento|ajuntament|udala|concello|diputaci|consell comarcal|mancomun|"
                      r"cabildo|foru aldundia|diputaci[oó]n foral|municipal|consorci|area metropolitana|"
                      r"[aà]rea metropolitana|entitat municipal|cuadrilla|kuadrilla|comarca|batzarr|junta administrativa")
RE_EMPRESA = re.compile(r"(?i)\bS\.?\s?A\.?\s?U?\.?$|\bS\.?\s?L\.?\s?U?\.?$|\bS\.?A\.?\b|\bS\.?L\.?\b|sociedad|societat|"
                        r"fundaci|empresa p|ente p[uú]blico|entidad p[uú]blica empresarial|ens p[uú]blic|"
                        r"\bconsorci|ferrocarril|metro |radio|televisi|corporaci[oó]|\bE\.?P\.?E\b|agencia p[uú]blica empresarial|"
                        r"parque|instituto .* s\.a|limitada|an[oó]nima|\bente\b|\bdeporte.*s\.a|pmpa|epe\b")
# universidades (no consejerías «de Educación y Universidades»)
RE_UNIV = re.compile(r"(?i)^(universi|fundaci[oó] (de la |bosch|privada )?universi)|^(consorci|fundaci[oó]n?) .*universi(tat|dad|dade)\b(?!.*(conselle|consej|departament))")


def _nivel_por_nombre(nombre, ambito_admin):
    """ambito_admin: 'autonomico' | 'local'. Devuelve (nivel, ambito)."""
    n = nombre or ""
    if RE_UNIV.search(n):
        return "otro", "otro"
    if ambito_admin == "local":
        if re.search(r"(?i)ayuntamiento|ajuntament|udala|concello|diputaci|consell comarcal|cabildo|foru aldundia|"
                     r"mancomun|cuadrilla|kuadrilla|comarca|entitat municipal|junta administrativa", n) and not RE_EMPRESA.search(n):
            return "local", "local"
        if RE_EMPRESA.search(n):
            return "empresa_publica", "local"
        return "local", "local"
    if RE_EMPRESA.search(n):
        return "empresa_publica", "autonomico"
    return "autonomico", "autonomico"


def _mun_de_nif(nif):
    """NIF de ayuntamiento P + provincia (2) + municipio (3) + 00 + control -> código INE (5)."""
    nif = nif or ""
    if re.fullmatch(r"P\d{5}00[A-Z0-9]", nif) and nif[3:6] != "000":
        return nif[1:6]
    return None


# --- diccionario de nombres -----------------------------------------------------------------------
def diccionario_nombres(padron, extra_pares=(), md_pares=True):
    """{nombre_normalizado: nif} con los nombres conocidos de los NIF del padrón, sin ambigüedades.
    extra_pares: (nif, nombre) de fuentes con NIF (PSCP, KontratazioA...), incluidos NIF de fuera del
    padrón, para detectar nombres que comparten varias sociedades."""
    pares = [(nif, r.get("nombre")) for nif, r in padron.items()]
    if md_pares:
        try:
            import duckdb
            con = duckdb.connect("md:SpainFacts")
            for t in ("pcsp_contratos_medios", "pcsp_candidatos_medios"):
                pares += con.sql(f"select distinct nif_adjudicatario, nombre_adjudicatario from raw.{t} "
                                 "where nombre_adjudicatario is not null").fetchall()
            con.close()
        except Exception as e:  # noqa: BLE001
            log.warning("Sin nombres de PLACSP para el diccionario: %s", e)
    pares += list(extra_pares)
    por_nombre: dict[str, set] = {}
    for nif, nombre in pares:
        nif = norm_nif(nif)
        k = norm_nombre(nombre)
        if not nif or not k or _es_persona(nif):
            continue
        por_nombre.setdefault(k, set()).add(nif)
    dic, ambiguos = {}, {}
    for k, nifs in por_nombre.items():
        dentro = nifs & set(padron)
        if not dentro:
            continue
        # nombres demasiado genéricos para casar sin NIF
        if len(k) < 6 or len(k.split()) == 1 and len(k) < 9:
            ambiguos[k] = sorted(nifs)
            continue
        grupos = {padron[n].get("grupo") for n in dentro}
        if nifs - set(padron) or len(grupos) > 1:
            ambiguos[k] = sorted(nifs)
            continue
        nif = sorted(dentro)[0]
        # el nombre debe compartir alguna palabra distintiva con el nombre del padrón (o su grupo):
        # evita variantes falsas que vienen de filas con el NIF mal puesto (p. ej. «El Corte Inglés»
        # con el NIF de EITB Media en un contrato)
        if not (_palabras(k) & (_palabras(norm_nombre(padron[nif].get("nombre"))) | _palabras(norm_nombre(padron[nif].get("grupo"))))):
            ambiguos[k] = sorted(nifs)
            continue
        dic[k] = nif
    return dic, ambiguos


GENERICAS = {"EDICIONES", "EDICIONS", "SOCIEDAD", "SOCIETAT", "GRUPO", "GRUP", "COMUNICACION", "COMUNICACIO",
             "PUBLICACIONES", "PUBLICACIONS", "MEDIA", "MEDIOS", "PRENSA", "PREMSA", "EDITORIAL", "ESPANOLA", "ESPANYA",
             "CATALUNYA", "ANONIMA", "LIMITADA", "MULTIMEDIA", "SERVICIOS", "SERVEIS", "PRODUCCIONES", "PRODUCCIONS",
             "LOCAL", "LOCALES", "DIGITAL", "DIGITALS", "INDEPENDIENTES", "LOCALS", "MEDIOS", "CORPORACION",
             "CORPORACIO", "INFORMACION", "INFORMACIO", "INDEPENDIENTE", "AUDIOVISUAL", "AUDIOVISUALS", "SOLUTIONS",
             "DEL", "LES", "LOS", "LAS", "PER", "PARA", "AND", "THE"}


def _palabras(k):
    return {p for p in (k or "").split() if len(p) >= 3 and p not in GENERICAS}


def _token_like(k):
    """Palabra más distintiva del nombre, con las vocales y letras con tilde como comodín (_) para
    que el LIKE de Socrata case con y sin acentos."""
    stop = {"EDICIONES", "EDICIONS", "SOCIEDAD", "SOCIETAT", "GRUPO", "GRUP", "COMUNICACION", "COMUNICACIO",
            "PUBLICACIONES", "PUBLICACIONS", "MEDIA", "MEDIOS", "RADIO", "DIARIO", "DIARI", "PRENSA", "PREMSA",
            "TELEVISION", "TELEVISIO", "EDITORIAL", "ESPANOLA", "CATALUNYA", "ANONIMA", "LIMITADA", "MULTIMEDIA",
            "NOTICIAS", "AUDIOVISUAL", "AUDIOVISUALS", "SERVICIOS", "SERVEIS", "INFORMACION", "PRODUCCIONES"}
    pal = [p for p in k.split() if len(p) >= 4 and p not in stop] or [p for p in k.split() if len(p) >= 4] or k.split()
    p = max(pal, key=len)
    return re.sub(r"[AEIOUNC]", "_", p)


# --- Cataluña: PSCP (ybgg-dgi6) ------------------------------------------------------------------
PSCP_COLS = ("codi_expedient,nom_organ,codi_organ,codi_ine10,codi_dir3,nom_ambit,nom_departament_ens,procediment,"
             "denominacio,objecte_contracte,tipus_contracte,codi_cpv,identificacio_adjudicatari,"
             "denominacio_adjudicatari,import_adjudicacio_sense,import_adjudicacio_amb_iva,"
             "data_adjudicacio_contracte,data_formalitzacio_contracte,data_publicacio_contracte,"
             "enllac_publicacio,numero_lot,resultat,es_agregada,id_intern")
TOKENS_CAND = ["DIARI", "R_DIO", "PREMSA", "TELEVISI", "EDICION", "COMUNICACI", "MITJANS", "MEDIA", "PUBLICACI",
               "PERI_DIC", "NOTICI", "PRENSA", "EDITOR", "REVISTA", "AUDIOVISUAL", "TV", "ONDA", "FM", "IRRATI",
               "TELEBISTA", "PRESS", "NEWS", "XORNAL", "SETMANARI", "SEMANARIO", "EMISORA", "GACETA", "CR_NICA"]


def _socrata(dataset, params, pagina=50000):
    out, off = [], 0
    while True:
        p = dict(params, **{"$limit": pagina, "$offset": off})
        r = _get(SOCRATA + dataset + ".json", params=p, timeout=(30, 600))
        if r.status_code != 200:
            raise RuntimeError(f"Socrata {dataset}: {r.status_code} {r.text[:300]}")
        d = r.json()
        out += d
        if len(d) < pagina:
            return out
        off += pagina


def _split(v):
    return [x.strip() for x in str(v).split("||")] if v not in (None, "") else [None]


def _filas_pscp(regs, padron, clase_fn):
    filas = []
    for x in regs:
        nifs, noms = _split(x.get("identificacio_adjudicatari")), _split(x.get("denominacio_adjudicatari"))
        sins, cons = _split(x.get("import_adjudicacio_sense")), _split(x.get("import_adjudicacio_amb_iva"))
        for i, nif_raw in enumerate(nifs):
            nif = norm_nif(nif_raw)
            nombre = noms[i] if i < len(noms) else noms[0]
            clase = clase_fn(nif, nombre)
            if not clase:
                continue
            ambito = "local" if "local" in (x.get("nom_ambit") or "").lower() else "autonomico"
            org = x.get("nom_organ") or x.get("nom_departament_ens")
            nivel, amb = _nivel_por_nombre(org, ambito)
            if "universitat" in (x.get("nom_ambit") or "").lower():
                nivel, amb = "otro", "otro"
            elif "independents" in (x.get("nom_ambit") or "").lower() or "altres" in (x.get("nom_ambit") or "").lower():
                nivel, amb = ("otro", "otro") if nivel != "empresa_publica" else (nivel, amb)
            ine10 = x.get("codi_ine10") or ""
            cod_mun = ine10[:5] if amb == "local" and re.fullmatch(r"(08|17|25|43)\d{8}", ine10) else None
            enl = x.get("enllac_publicacio")
            filas.append(dict(
                plataforma="cat_pscp", id_contrato=f"{x.get('id_intern')}|{i}", expediente=x.get("codi_expedient"),
                organo=org, organo_id=ine10 or x.get("codi_organ"), organo_superior=x.get("nom_departament_ens"),
                dir3=x.get("codi_dir3"), nif_organo=None, nivel=nivel, ambito=amb, cod_ccaa="09", cod_municipio=cod_mun,
                objeto=x.get("objecte_contracte") or x.get("denominacio"), tipo_contrato=x.get("tipus_contracte"),
                procedimiento=x.get("procediment"), es_menor=x.get("procediment") == "Contracte menor",
                cpv=x.get("codi_cpv"), lote=x.get("numero_lot"), estado=x.get("resultat"),
                nif_adjudicatario=nif or "", nombre_adjudicatario=nombre, metodo_casado="nif",
                importe_sin_iva=num(sins[i] if i < len(sins) else None), importe_con_iva=num(cons[i] if i < len(cons) else None),
                importe_sin_iva_estimado=False,
                fecha_adjudicacion=fecha(x.get("data_adjudicacio_contracte")) or fecha(x.get("data_formalitzacio_contracte"))
                or fecha(x.get("data_publicacio_contracte")),
                url=enl.get("url") if isinstance(enl, dict) else enl, clase=clase, es_agregada=x.get("es_agregada")))
    return filas


def cat_pscp(padron, cache_dir=None, desde=2018):
    cf = _cache(cache_dir, "cat_pscp")
    if (d := _lee_cache(cf)) is not None:
        return d
    nifs = sorted(padron)
    regs = []
    for i in range(0, len(nifs), 60):
        lista = ",".join(f"'{n}'" for n in nifs[i:i + 60])
        regs += _socrata("ybgg-dgi6", {"$select": PSCP_COLS, "$where": f"identificacio_adjudicatari in ({lista})"})
    filas = _filas_pscp(regs, padron, lambda nif, nombre: "padron" if nif in padron else None)
    # pares (NIF, nombre) con pinta de medio: candidatos y diccionario de nombres
    w = " or ".join(f"upper(denominacio_adjudicatari) like '%{t}%'" for t in TOKENS_CAND)
    pares = _socrata("ybgg-dgi6", {"$select": "identificacio_adjudicatari, denominacio_adjudicatari, procediment, count(*) as n",
                                   "$where": f"({w})", "$group": "identificacio_adjudicatari, denominacio_adjudicatari, procediment"})
    pares_out = []
    for p in pares:
        nifs_p, noms_p = _split(p.get("identificacio_adjudicatari")), _split(p.get("denominacio_adjudicatari"))
        if len(nifs_p) != len(noms_p):  # lista de adjudicatarios descuadrada: no sirve para el diccionario
            continue
        for nif_raw, nombre in zip(nifs_p, noms_p):
            nif = norm_nif(nif_raw)
            if nif and not _es_persona(nif) and "*" not in (nif_raw or ""):
                pares_out.append(dict(nif=nif, nombre=nombre, procedimiento=p.get("procediment"), n=int(p.get("n") or 0)))
    filas = [f for f in filas if (f["fecha_adjudicacion"] or "9999")[:4] >= str(desde)]
    d = {"filas": filas, "pares": pares_out}
    _escribe_cache(cf, d)
    return d


# --- Cataluña: RPC (hb6v-jcbf) -------------------------------------------------------------------
RPC_COLS = ("exercici,subjecte_ambit,agrupacio_organisme,id_organisme_contractant,organisme_contractant,codi_expedient,"
            "procediment_adjudicacio,tipus_contracte,descripcio_expedient,numero_lot,codi_cpv,adjudicatari,"
            "import_adjudicacio,data_adjudicacio,contracte,situaci_contractual")


def cat_rpc(padron, dic, cache_dir=None, desde=2018):
    cf = _cache(cache_dir, "cat_rpc")
    if (d := _lee_cache(cf)) is not None:
        return d
    # 1) nombres de adjudicatario de menores que contienen la palabra distintiva de algún nombre del diccionario
    tokens = sorted({_token_like(k) for k in dic} | set(TOKENS_CAND))
    cfn = _cache(cache_dir, "cat_rpc_nombres")
    nombres = {k: tuple(v) for k, v in (_lee_cache(cfn) or {}).items()}
    for i in range(0, len(tokens) if not nombres else 0, 25):
        w = " or ".join(f"upper(adjudicatari) like '%{t}%'" for t in tokens[i:i + 25])
        for r in _socrata("hb6v-jcbf", {"$select": "adjudicatari, count(*) as n, sum(import_adjudicacio) as imp",
                                        "$where": f"situaci_contractual='menor' and ({w})", "$group": "adjudicatari"}):
            if r.get("adjudicatari"):
                nombres[r["adjudicatari"]] = (int(r.get("n") or 0), num(r.get("imp")))
        print(f"[medios_contratos_ccaa] cat_rpc tokens {i + 25}/{len(tokens)}: {len(nombres)} nombres", flush=True)
        time.sleep(1)
    _escribe_cache(cfn, nombres)
    casados = {n: dic[norm_nombre(n)] for n in nombres if norm_nombre(n) in dic}
    candidatos = [dict(plataforma="cat_rpc", nombre_adjudicatario=n, nif_adjudicatario="", n_contratos=c, importe=imp)
                  for n, (c, imp) in nombres.items() if n not in casados and RE_CANDIDATO.search(norm(n))]
    # 2) filas de los nombres casados
    regs = []
    lista = sorted(casados)
    for i in range(0, len(lista), 40):
        inn = ",".join("'" + n.replace("'", "''") + "'" for n in lista[i:i + 40])
        regs += _socrata("hb6v-jcbf", {"$select": RPC_COLS, "$where": f"situaci_contractual='menor' and adjudicatari in ({inn})"})
    filas = []
    for x in regs:
        nif = casados.get(x.get("adjudicatari"))
        if not nif:
            continue
        ambito = "local" if "local" in (x.get("subjecte_ambit") or "").lower() else "autonomico"
        nivel, amb = _nivel_por_nombre(x.get("organisme_contractant"), ambito)
        if "universitat" in (x.get("subjecte_ambit") or "").lower():
            nivel, amb = "otro", "otro"
        ine10 = x.get("id_organisme_contractant") or ""
        cod_mun = ine10[:5] if amb == "local" and re.fullmatch(r"(08|17|25|43)\d{8}", ine10) else None
        imp = num(x.get("import_adjudicacio"))
        filas.append(dict(
            plataforma="cat_rpc", id_contrato=hashlib.md5("|".join(str(x.get(c) or "") for c in (
                "id_organisme_contractant", "codi_expedient", "numero_lot", "adjudicatari", "import_adjudicacio",
                "data_adjudicacio", "descripcio_expedient")).encode()).hexdigest(), expediente=x.get("codi_expedient"),
            organo=x.get("organisme_contractant"), organo_id=ine10, organo_superior=x.get("agrupacio_organisme"),
            dir3=None, nif_organo=None, nivel=nivel, ambito=amb, cod_ccaa="09", cod_municipio=cod_mun,
            objeto=x.get("descripcio_expedient") or x.get("contracte"), tipo_contrato=x.get("tipus_contracte"),
            procedimiento=x.get("procediment_adjudicacio"), es_menor=True, cpv=x.get("codi_cpv"), lote=x.get("numero_lot"),
            estado=x.get("situaci_contractual"), nif_adjudicatario=nif, nombre_adjudicatario=x.get("adjudicatari"),
            metodo_casado="nombre", importe_sin_iva=imp, importe_con_iva=None, importe_sin_iva_estimado=False,
            fecha_adjudicacion=fecha(x.get("data_adjudicacio")), url="https://analisi.transparenciacatalunya.cat/d/hb6v-jcbf",
            clase="padron" if padron.get(nif) else "candidato", es_agregada=None))
    filas = [f for f in filas if (f["fecha_adjudicacion"] or "9999")[:4] >= str(desde)]
    d = {"filas": filas, "candidatos": candidatos, "nombres_leidos": len(nombres)}
    _escribe_cache(cf, d)
    return d


# --- Euskadi: KontratazioA ----------------------------------------------------------------------
EUS = "https://api.euskadi.eus/procurements/"


def _nivel_eus(org, padres, nif):
    """Nivel de un poder adjudicador de KontratazioA: (nivel, ambito, cod_municipio).
    Las diputaciones forales, Juntas Generales y sus organismos van como 'local' (igual que en
    medios_contratos.py), con nota en el mart."""
    texto = f"{org or ''} {padres or ''}"
    nif = nif or ""
    if re.search(r"(?i)gobierno vasco|eusko jaurlaritza|administraci[oó]n general de la c|osakidetza|"
                 r"parlamento vasco|ararteko|euskal irrati|eitb", texto) and not RE_LOCAL.search(org or ""):
        ambito = "autonomico"
    elif (RE_LOCAL.search(texto) or re.search(r"(?i)\blocal\b|foral|juntas generales|udal|bizkaia|gipuzkoa|araba|[aá]lava|"
                                               r"bilbao|vitoria|gasteiz|donostia|getxo|barakaldo|irun", texto)
          or nif.startswith("P")):
        ambito = "local"
    else:
        ambito = "autonomico"
    nivel, amb = _nivel_por_nombre(org, ambito)
    cod_mun = _mun_de_nif(nif) if amb == "local" else None
    return nivel, amb, cod_mun


def eus_kontratazioa(padron, cache_dir=None, desde=2018):
    cf = _cache(cache_dir, "eus_kontratazioa")
    if (d := _lee_cache(cf)) is not None:
        for f in d["filas"]:  # la regla de nivel puede haber cambiado desde que se hizo la caché
            f["nivel"], f["ambito"], f["cod_municipio"] = _nivel_eus(f["organo"], f["organo_superior"], f["nif_organo"])
        return d
    s = requests.Session()
    s.headers.update(CABECERAS)
    regs = []
    for nif in sorted(padron):
        pag = 1
        while True:
            r = _get(f"{EUS}contracts/companies/{nif}", params={"itemsOfPage": 50, "currentPage": pag}, sesion=s, timeout=(30, 120))
            if r.status_code != 200:
                break
            j = r.json()
            regs += [dict(it, _nif=nif) for it in j.get("items", [])]
            if pag >= (j.get("totalPages") or 1):
                break
            pag += 1
            time.sleep(0.6)
        time.sleep(0.6)
    # poderes adjudicadores
    autoridades = {}

    def autoridad(href):
        if not href:
            return {}
        if href not in autoridades:
            r = _get(href, sesion=s, timeout=(30, 120))
            a = r.json() if r.status_code == 200 else {}
            padres = [p.get("name") for p in a.get("_links", {}).get("contractingAuthorities", []) or [] if isinstance(p, dict)]
            autoridades[href] = dict(nombre=a.get("name"), nif=norm_nif(a.get("identificationNumber")),
                                     ambito_territorial=a.get("scope"), padres=padres)
        return autoridades[href]

    filas = []
    for x in regs:
        a = autoridad((x.get("_links", {}).get("contractingAuthority") or {}).get("href"))
        org = a.get("nombre")
        padres = " > ".join(p for p in a.get("padres") or [] if p)
        nivel, amb, cod_mun = _nivel_eus(org, padres, a.get("nif"))
        filas.append(dict(
            plataforma="eus_kontratazioa", id_contrato=x.get("id"), expediente=x.get("id"), organo=org,
            organo_id=a.get("nif"), organo_superior=padres or None, dir3=None, nif_organo=a.get("nif"),
            nivel=nivel, ambito=amb, cod_ccaa="16", cod_municipio=cod_mun, objeto=x.get("object"),
            tipo_contrato=(x.get("contractType") or {}).get("name"), procedimiento=(x.get("contractProcedureType") or {}).get("name"),
            es_menor=bool(x.get("minorContract")), cpv=x.get("CPV"), lote=None,
            estado=(x.get("contractProcedureStatus") or {}).get("name"), nif_adjudicatario=norm_nif(x.get("CIF")) or x["_nif"],
            nombre_adjudicatario=x.get("socialReason"), metodo_casado="nif",
            importe_sin_iva=num(x.get("awardAmountWithoutVAT")), importe_con_iva=num(x.get("awardAmount")),
            importe_sin_iva_estimado=False, fecha_adjudicacion=fecha(x.get("awardDate")) or fecha(x.get("companySignatureDate")),
            url=x.get("mainEntityOfPage"), clase="padron", es_agregada=None))
    hoy = date.today().isoformat()
    filas = [f for f in filas if str(desde) <= (f["fecha_adjudicacion"] or "0") <= hoy]  # hay fechas de 2031 (erratas)
    d = {"filas": filas, "pares": [dict(nif=f["nif_adjudicatario"], nombre=f["nombre_adjudicatario"]) for f in filas]}
    _escribe_cache(cf, d)
    return d


# --- ficheros: utilidades comunes ----------------------------------------------------------------
def _clase(nif, nombre, padron):
    if nif and nif in padron:
        return "padron"
    if not nif or _es_persona(nif):
        return None
    if nombre and RE_CANDIDATO.search(norm(nombre)):
        return "candidato"
    return None


def _texto(raw: bytes) -> str:
    for enc in ("utf-8-sig", "cp1252", "latin1"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("latin1", "replace")


def _iva(objeto):
    """Divisor para estimar el importe sin IVA cuando la fuente solo da el importe con IVA:
    4 % para prensa y suscripciones, 21 % para el resto."""
    o = norm(objeto)
    return 1.04 if re.search(r"SUSCRIP|SUBSCRIP|EJEMPLAR|PERIODICO|DIARIO .*(PAPEL|EDICION)|PRENSA DIARIA|KIOSKO|KIOSCO", o) else 1.21


# --- Andalucía ------------------------------------------------------------------------------------
AND_CKAN = "https://www.juntadeandalucia.es/datosabiertos/portal/api/3/action/package_show?id=contratacion-menor-plataforma-de-contratacion-andalucia-{anio}"


def and_junta(padron, cache_dir=None, desde=2018):
    filas, cobertura = [], []
    for anio in range(desde, date.today().year + 1):
        cf = _cache(cache_dir, f"and_junta_{anio}")
        if (d := _lee_cache(cf)) is None or anio >= date.today().year:
            r = _get(AND_CKAN.format(anio=anio))
            if r.status_code != 200 or not r.json().get("success"):
                log.info("Andalucía %s: sin conjunto", anio)
                continue
            res = [x for x in r.json()["result"]["resources"] if (x.get("format") or "").upper() == "CSV"]
            if not res:
                continue
            url = re.sub(r"^https?://[^/]+/datosabiertos", "https://www.juntadeandalucia.es/datosabiertos", res[0]["url"])
            raw = _get(url, timeout=(30, 900)).content
            if url.endswith(".zip") or raw[:2] == b"PK":
                with zipfile.ZipFile(io.BytesIO(raw)) as z:
                    raw = z.read(next(n for n in z.namelist() if n.lower().endswith(".csv")))
            t = _texto(raw)
            sep = "|" if t[:2000].count("|") > t[:2000].count(";") else ";"
            lector = csv.DictReader(io.StringIO(t), delimiter=sep)
            lector.fieldnames = [norm(c).replace(" ", "_") for c in lector.fieldnames]
            fs, n = [], 0
            for x in lector:
                n += 1
                x = {k: (v.strip() if isinstance(v, str) else v) for k, v in x.items() if k}
                nif = norm_nif(x.get("NIF_ADJUDICATARIO"))
                nombre = x.get("ADJUDICATARIO_DENOMINACION")
                clase = _clase(nif, nombre, padron)
                if not clase:
                    continue
                org = x.get("ORGANO_CONTRATACION")
                nivel, amb = _nivel_por_nombre(org, "autonomico")
                fs.append(dict(
                    plataforma="and_junta", id_contrato=f"{x.get('ID_EXPEDIENTE')}|{nif}|{x.get('IMPORTE_ADJUDICACION_SIN_IVA')}|{x.get('FECHA_ADJUDICACION')}",
                    expediente=x.get("NUM_EXPEDIENTE"), organo=org, organo_id=org, organo_superior=None, dir3=None,
                    nif_organo=None, nivel=nivel, ambito=amb, cod_ccaa="01", cod_municipio=None,
                    objeto=x.get("TITULO") or x.get("DESCRIPCION"), tipo_contrato=x.get("TIPO_CONTRATO"),
                    procedimiento=x.get("PROCEDIMIENTO_ADJUDICACION"), es_menor=True, cpv=None, lote=None,
                    estado=x.get("ESTADO"), nif_adjudicatario=nif, nombre_adjudicatario=nombre, metodo_casado="nif",
                    importe_sin_iva=num(x.get("IMPORTE_ADJUDICACION_SIN_IVA")), importe_con_iva=num(x.get("IMPORTE_ADJUDICACION_CON_IVA")),
                    importe_sin_iva_estimado=False,
                    fecha_adjudicacion=fecha(x.get("FECHA_ADJUDICACION")) or fecha(x.get("FECHA_FORMALIZACION")),
                    url=f"https://www.juntadeandalucia.es/haciendayadministracionpublica/apl/pdc_sirec/perfiles/menores/detalle-menor.jsf?idExpediente={x.get('ID_EXPEDIENTE')}",
                    clase=clase, es_agregada=None))
            d = {"filas": fs, "cob": dict(plataforma="and_junta", periodo=str(anio), filas_leidas=n, url=url)}
            _escribe_cache(cf, d)
        filas += d["filas"]
        cobertura.append(d["cob"])
    return {"filas": filas, "cobertura": cobertura}


# --- Galicia ----------------------------------------------------------------------------------------
GAL_TRANSP = "https://transparencia.xunta.gal/tema/informacion-economica-orzamentaria-e-estatistica/contratacion-publica/contratos-menores"
GAL_API = "https://www.contratosdegalicia.gal/api/v1/organismos/{org}/contratosmenores/table"
GAL_COLS = [("id", True), ("publicado", True), ("objeto", True), ("importe", True), ("nif", True), ("adjudicatario", True), ("duracion", False)]


def gal_organismos():
    """Organismos de la Xunta con contratos menores, de la página de transparencia: {id: (nombre, categoría)}."""
    html = _get(GAL_TRANSP).text
    out, cat = {}, "Consellerías"
    for m in re.finditer(r"<h3>([^<]+)</h3>|consultaOrganismo\.jsp\?[^\"']*?N=(\d+)[^\"']*[\"'][^>]*>([^<]+)</a>", html):
        if m.group(1):
            cat = m.group(1).strip()
        else:
            out.setdefault(int(m.group(2)), (m.group(3).strip(), cat))
    return out


def _gal_url(org, ds, de, start, length=100):
    p = [("draw", 1)]
    for i, (n, o) in enumerate(GAL_COLS):
        pr = f"columns[{i}]"
        p += [(f"{pr}[data]", n), (f"{pr}[name]", n), (f"{pr}[searchable]", "true"), (f"{pr}[orderable]", str(o).lower()),
              (f"{pr}[search][value]", ""), (f"{pr}[search][regex]", "false")]
    p += [("order[0][column]", 0), ("order[0][dir]", "asc"), ("start", start), ("length", length),
          ("search[value]", ""), ("search[regex]", "false"), ("datestart", ds), ("dateend", de)]
    return GAL_API.format(org=org) + "?" + urlencode(p)


# Organismos que ya no figuran en la página de transparencia (consellerías y entes de legislaturas
# anteriores) pero tienen contratos menores en la plataforma: sondeo de los id 1-800 (2026-10-03).
GAL_ORGANISMOS_HISTORICOS = (39, 80, 123, 129, 220, 282, 283, 286, 287, 412, 413, 417, 420, 428, 443, 444, 445,
                             447, 448, 487, 488, 489, 490, 491, 500, 526)


def _gal_nombre(org):
    try:
        t = _texto(_get(f"https://www.contratosdegalicia.gal/consultaOrganismo.jsp?lang=gl&ID=800&N={org}&OR={org}&S=CM",
                        timeout=(30, 60)).content)
        m = re.search(r"<title>[^:<]*:(?:&nbsp;|\s)*([^<]+?)\s+-\s+Contratos", t)
        return m.group(1).strip() if m else f"Organismo {org}"
    except Exception:  # noqa: BLE001
        return f"Organismo {org}"


def _gal_categoria(nombre):
    n = norm(nombre)
    if re.search(r"FUNDACI", n):
        return "Fundacións do sector público autonómico"
    if re.search(r"\bS\.?A\.?\b|SOCIEDADE|S\.L", n):
        return "Sociedades mercantís públicas autonómicas"
    if re.search(r"CONSORCIO", n):
        return "Consorcios autonómicos"
    if re.search(r"UNIVERSI", n):
        return "Universidades"
    return "Consellerías e outros organismos (histórico)"


def gal_xunta(padron, cache_dir=None, desde=2018, organismos_extra=GAL_ORGANISMOS_HISTORICOS):
    orgs = gal_organismos()
    for k in organismos_extra or ():
        if int(k) not in orgs:
            nombre = _gal_nombre(int(k))
            orgs[int(k)] = (nombre, _gal_categoria(nombre))
    hoy = date.today()
    meses = [(y, m) for y in range(desde, hoy.year + 1) for m in range(1, 13) if (y, m) <= (hoy.year, hoy.month)]

    def mes(ym):
        y, m = ym
        periodo = f"{y}{m:02d}"
        cf = _cache(cache_dir, f"gal_xunta_{periodo}")
        d = _lee_cache(cf)
        if d is None or (y, m) >= (hoy.year, hoy.month - 1):
            s = requests.Session()
            s.headers.update(dict(CABECERAS, Accept="application/json"))
            ds = date(y, m, 1)
            de = (date(y + (m == 12), m % 12 + 1, 1)).toordinal() - 1
            ds, de = ds.isoformat(), date.fromordinal(de).isoformat()
            fs, n = [], 0
            for org, (nombre_org, cat) in sorted(orgs.items()):
                start = 0
                while True:
                    r = None
                    for i in range(4):
                        try:
                            r = s.get(_gal_url(org, ds, de, start), timeout=(30, 120))
                            if r.status_code in (200, 204, 500):
                                break
                        except Exception:  # noqa: BLE001
                            pass
                        time.sleep(3 * (i + 1))
                    time.sleep(0.15)
                    if r is None or r.status_code != 200 or not r.text.startswith("{"):
                        break
                    j = r.json()
                    datos = j.get("data") or []
                    n += len(datos)
                    for x in datos:
                        nif = norm_nif(x.get("nif"))
                        nombre = (x.get("adjudicatario") or "").strip()
                        clase = _clase(nif, nombre, padron)
                        if not clase:
                            continue
                        if re.search(r"(?i)sociedade|fundaci|consorcio|ente p|S\.A|empresa", cat):
                            nivel, amb = "empresa_publica", "autonomico"
                        elif RE_UNIV.search(nombre_org) or re.search(r"(?i)universi", cat):
                            nivel, amb = "otro", "otro"
                        else:
                            nivel, amb = "autonomico", "autonomico"
                        fs.append(dict(
                            plataforma="gal_xunta", id_contrato=str(x.get("id")), expediente=str(x.get("id")),
                            organo=nombre_org, organo_id=str(org), organo_superior=cat, dir3=None, nif_organo=None,
                            nivel=nivel, ambito=amb, cod_ccaa="12", cod_municipio=None, objeto=x.get("objeto"),
                            tipo_contrato=None, procedimiento="Contrato menor", es_menor=True, cpv=None, lote=None,
                            estado=None, nif_adjudicatario=nif, nombre_adjudicatario=nombre, metodo_casado="nif",
                            importe_sin_iva=(num(x.get("importe")) or 0) / _iva(x.get("objeto")) if num(x.get("importe")) is not None else None,
                            importe_con_iva=num(x.get("importe")), importe_sin_iva_estimado=True,
                            fecha_adjudicacion=fecha(x.get("publicado")),
                            url=f"https://www.contratosdegalicia.gal/licitacion?N={x.get('id')}", clase=clase, es_agregada=None))
                    if len(datos) < 100 or start + 100 >= (j.get("recordsFiltered") or 0):
                        break
                    start += 100
            d = {"filas": fs, "cob": dict(plataforma="gal_xunta", periodo=periodo, filas_leidas=n, organismos=len(orgs))}
            _escribe_cache(cf, d)
            print(f"[medios_contratos_ccaa] gal_xunta {periodo}: {n} leídas, {len(fs)} filtradas", flush=True)
        return d

    # meses en paralelo (6 hilos; cada hilo pide en serie con pausas)
    from concurrent.futures import ThreadPoolExecutor
    filas, cobertura = [], []
    with ThreadPoolExecutor(6) as ex:
        for d in ex.map(mes, meses):
            filas += d["filas"]
            cobertura.append(d["cob"])
    return {"filas": filas, "cobertura": cobertura}


# --- La Rioja ---------------------------------------------------------------------------------------
RIO_OPD = {2021: 866, 2022: 910, 2023: 963, 2024: 979, 2025: 1151, 2026: 1175}


def rio_car(padron, cache_dir=None, desde=2018):
    filas, cobertura = [], []
    for anio, opd in RIO_OPD.items():
        if anio < desde:
            continue
        r = base64.b64encode(f"cd={opd}|cf=03".encode()).decode()
        url = f"https://ias1.larioja.org/opendata/download?r={r}"
        t = _texto(_get(url, timeout=(30, 600)).content)
        n, fs = 0, []
        for x in csv.DictReader(io.StringIO(t), delimiter=";"):
            n += 1
            nif = norm_nif(x.get("TERC_CIF"))
            nombre = (x.get("TERC_NOMBRE") or "").strip()
            clase = _clase(nif, nombre, padron)
            if not clase:
                continue
            con = num(x.get("IMPORTE_EJERCICIO"))
            fs.append(dict(
                plataforma="rio_car", id_contrato=f"{x.get('COD_CONTRATO')}|{anio}", expediente=x.get("COD_CONTRATO"),
                organo=(x.get("DEPARTAMENTO") or "").strip(), organo_id=(x.get("DEPARTAMENTO") or "").strip(), organo_superior="Gobierno de La Rioja",
                dir3=None, nif_organo=None, nivel="autonomico", ambito="autonomico", cod_ccaa="17", cod_municipio=None,
                objeto=x.get("CONCEPTO"), tipo_contrato=x.get("TIPO_EXPEDIENTE"), procedimiento="Contrato menor", es_menor=True,
                cpv=None, lote=None, estado=None, nif_adjudicatario=nif, nombre_adjudicatario=nombre, metodo_casado="nif",
                importe_sin_iva=con / _iva(x.get("CONCEPTO")) if con is not None else None, importe_con_iva=con,
                importe_sin_iva_estimado=True, fecha_adjudicacion=fecha(x.get("FECHA")),
                url=f"https://web.larioja.org/dato-abierto/datoabierto?n=opd-{opd}", clase=clase, es_agregada=None))
        filas += fs
        cobertura.append(dict(plataforma="rio_car", periodo=str(anio), filas_leidas=n, url=url))
    return {"filas": filas, "cobertura": cobertura}


# --- Ayuntamiento de Madrid ------------------------------------------------------------------------
MAD_CKAN = "https://datos.madrid.es/api/3/action/package_show?id=300253-0-contratos-actividad-menores"


def _col(cab, *patrones):
    for p in patrones:
        for c in cab:
            if re.search(p, norm(c)):
                return c
    return None


def mad_ayto(padron, cache_dir=None, desde=2018):
    res = _get(MAD_CKAN).json()["result"]["resources"]
    filas, cobertura = [], []
    for x in res:
        if (x.get("format") or "").upper() != "CSV":
            continue
        m = re.search(r"(20\d\d)", (x.get("description") or "") + " " + (x.get("name") or ""))
        anio_desc = int(m.group(1)) if m else None
        if anio_desc and anio_desc < desde:
            continue
        t = _texto(_get(x["url"], timeout=(30, 600)).content)
        lineas = t.splitlines()
        i0 = next((k for k, l in enumerate(lineas[:20]) if re.search(r"NIF|N\.I\.F|CIF", norm(l))), None)
        if i0 is None:
            continue
        lector = csv.DictReader(io.StringIO("\n".join(lineas[i0:])), delimiter=";")
        cab = lector.fieldnames
        c_nif = _col(cab, r"^NIF", r"^N\.I\.F", r"^CIF")
        c_nom = _col(cab, r"RAZON SOCIAL", r"CONTRATISTA", r"TERCERO", r"RAZON_SOCIAL")
        c_imp = _col(cab, r"IMPORTE ADJUDICACION", r"^\s*IMPORTE\s*$")
        c_fec = _col(cab, r"FECHA DE ADJUDICACION", r"FECHA APROBACION", r"F_APROBACION", r"FECH.? ?APRO")
        c_obj = _col(cab, r"OBJETO", r"TITULO DEL EXPEDIENTE")
        c_org = _col(cab, r"ORGANO DE CONTRATACION", r"ORG.CONTRATACION", r"ORG_CONTRATACION", r"DESCRIPCION")
        c_ent = _col(cab, r"ORGANISMO_CONTRATANTE", r"CENTRO - SECCION", r"^SECCION")
        c_exp = _col(cab, r"N\. DE EXPEDIENTE", r"NUMERO EXPEDIENTE", r"^EXPEDIENTE", r"N. EXPED", r"N EXPEDIENTE")
        c_reg = _col(cab, r"REGISTRO DE CONTRATO", r"RECON", r"^CONTRATO$")
        c_tip = _col(cab, r"TIPO DE CONTRATO", r"TIPO_CONTRATO", r"TIPO DE EXPEDIENTE")
        n, fs = 0, []
        for k, row in enumerate(lector):
            n += 1
            nif = norm_nif(row.get(c_nif))
            nombre = (row.get(c_nom) or "").strip()
            clase = _clase(nif, nombre, padron)
            if not clase:
                continue
            con = num(row.get(c_imp))
            obj = (row.get(c_obj) or "").strip()
            org = (row.get(c_ent) or row.get(c_org) or "").strip()
            fe = fecha(row.get(c_fec))
            nivel, amb = ("empresa_publica", "local") if re.search(r"(?i)empresa|S\.A|EMT|madrid destino|mercamadrid", org) else ("local", "local")
            fs.append(dict(
                plataforma="mad_ayto", id_contrato=f"{(row.get(c_reg) or '').strip() or (row.get(c_exp) or '').strip()}|{nif}|{con}|{fe}",
                expediente=(row.get(c_exp) or "").strip(), organo=org or "Ayuntamiento de Madrid", organo_id="28079",
                organo_superior="Ayuntamiento de Madrid", dir3="L01280796", nif_organo="P2807900B", nivel=nivel, ambito=amb,
                cod_ccaa="13", cod_municipio="28079", objeto=obj, tipo_contrato=(row.get(c_tip) or "").strip() if c_tip else None,
                procedimiento="Contrato menor", es_menor=True, cpv=None, lote=None, estado=None, nif_adjudicatario=nif,
                nombre_adjudicatario=nombre, metodo_casado="nif",
                importe_sin_iva=con / _iva(obj) if con is not None else None, importe_con_iva=con, importe_sin_iva_estimado=True,
                fecha_adjudicacion=fe, url="https://datos.madrid.es/dataset/300253-0-contratos-actividad-menores",
                clase=clase, es_agregada=None))
        fs = [f for f in fs if (f["fecha_adjudicacion"] or "9999")[:4] >= str(desde)]
        filas += fs
        cobertura.append(dict(plataforma="mad_ayto", periodo=str(anio_desc or x.get("name")), filas_leidas=n, url=x["url"]))
    return {"filas": filas, "cobertura": cobertura}


# --- Ajuntament de Barcelona (2018) ---------------------------------------------------------------
BCN_URL = "https://opendata-ajuntament.barcelona.cat/data/dataset/1121f3e2-bfb1-4dc4-9f39-1c5d1d72cba1/resource/69ae574f-adfc-4660-8f81-73103de169ff/download"


def bcn_ayto(padron, cache_dir=None, desde=2018):
    if desde > 2018:
        return {"filas": [], "cobertura": []}
    t = _texto(_get(BCN_URL, timeout=(30, 600)).content)
    lector = csv.DictReader(io.StringIO(t))
    lector.fieldnames = [re.sub(r"\s+", " ", c).strip() for c in lector.fieldnames]
    n, fs = 0, []
    for k, x in enumerate(lector):
        n += 1
        nif = norm_nif(x.get("NIF"))
        nombre = (x.get("Proveïdor") or "").strip()
        clase = _clase(nif, nombre, padron)
        if not clase:
            continue
        con = num(x.get("Import adjudicat"))
        obj = x.get("Objecte del contracte")
        tipus = x.get("Tipus ens") or ""
        nivel, amb = ("empresa_publica", "local") if re.search(r"(?i)societats|consorcis|fundaci|entitats p", tipus) else ("local", "local")
        fe = fecha(x.get("Data adjudicació"))
        fs.append(dict(
            plataforma="bcn_ayto", id_contrato=f"2018|{k}|{nif}", expediente=None, organo=x.get("Òrgan contractant"),
            organo_id="08019", organo_superior="Ajuntament de Barcelona", dir3=None, nif_organo="P0801900B", nivel=nivel,
            ambito=amb, cod_ccaa="09", cod_municipio="08019", objeto=obj, tipo_contrato=(x.get("Tipus Contracte") or "").strip(),
            procedimiento="Contracte menor", es_menor=True, cpv=None, lote=None, estado=None, nif_adjudicatario=nif,
            nombre_adjudicatario=nombre, metodo_casado="nif", importe_sin_iva=con,
            importe_con_iva=None, importe_sin_iva_estimado=False, fecha_adjudicacion=fe,
            url="https://opendata-ajuntament.barcelona.cat/data/ca/dataset/contractes-menors", clase=clase, es_agregada=None))
    return {"filas": fs, "cobertura": [dict(plataforma="bcn_ayto", periodo="2018", filas_leidas=n, url=BCN_URL)]}


# --- Comunidad de Madrid: buscador público del Portal de Contratación -----------------------------
# Listado: GET /contratos?t=<texto>&f[0]=tipo_publicacion:Contratos Menores&page=N (10 por página).
# El texto libre casa con el NIF del adjudicatario. Detalle: GET /contrato/<referencia>. NO se usa la
# exportación /buscador-contratos/csv (captcha y módulo «antibot») ni se envía el formulario con
# antibot_key: solo las URL de listado y detalle que sirve el portal a cualquier navegador.
MAD_CM = "https://contratos-publicos.comunidad.madrid"
UA_NAVEGADOR = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) "
                              "Chrome/128.0 Safari/537.36", "Accept-Language": "es-ES,es;q=0.9"}
MESES = {m: i + 1 for i, m in enumerate(("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
                                          "septiembre", "octubre", "noviembre", "diciembre"))}
RE_RETO = re.compile(r"(?i)g-recaptcha|hcaptcha|cf-challenge|challenge-platform|captcha-container|p[aá]gina bloqueada|"
                     r"access denied|request rejected")


class RetoAntibot(RuntimeError):
    pass


def _fecha_larga(s):
    """'22 de octubre del 2024' -> '2024-10-22' (y los formatos de fecha())."""
    if not s:
        return None
    m = re.search(r"(\d{1,2}) de ([a-záéíóú]+) de(?:l)? (\d{4})", s.lower())
    if m and m.group(2) in MESES:
        try:
            return date(int(m.group(3)), MESES[m.group(2)], int(m.group(1))).isoformat()
        except ValueError:
            return None
    return fecha(s)


def _get_educado(s, url, pausa=2.5):
    """GET en serie con pausa; si aparece un captcha o reto, para (RetoAntibot)."""
    for i in range(5):
        time.sleep(pausa)
        try:
            r = s.get(url, timeout=(30, 120))
        except Exception as e:  # noqa: BLE001
            log.warning("GET %s intento %d: %s", url[:120], i + 1, e)
            time.sleep(10 * (i + 1))
            continue
        if r.status_code in (403, 429) or (r.status_code == 200 and RE_RETO.search(r.text[:200000])):
            raise RetoAntibot(f"{r.status_code} con reto/captcha en {url}")
        if r.status_code == 404:
            return None
        if r.status_code >= 500:
            time.sleep(15 * (i + 1))
            continue
        return r.text
    raise RuntimeError(f"No se pudo descargar {url[:200]}")


def _mad_listado(s, texto, max_pag=60):
    from urllib.parse import quote
    refs, pag = [], 0
    while pag < max_pag:
        url = (f"{MAD_CM}/contratos?t={quote(texto)}&f%5B0%5D=tipo_publicacion%3AContratos%20Menores"
               + (f"&page={pag}" if pag else ""))
        t = _get_educado(s, url)
        if not t:
            break
        nuevos = re.findall(r'href="/contrato/([^"#?]+)"', t)
        refs += [x for x in nuevos if x not in refs]
        m = re.search(r"Mostrando \d+ - (\d+) de (\d+)", t)
        if not m or int(m.group(1)) >= int(m.group(2)) or not nuevos:
            break
        pag += 1
    return refs


def _mad_detalle(s, ref):
    from html import unescape
    t = _get_educado(s, f"{MAD_CM}/contrato/{ref}")
    if not t:
        return None
    pares = [(re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]+>", " ", a))).strip(),
              re.sub(r"\s+", " ", unescape(re.sub(r"<[^>]+>", " ", b))).strip())
             for a, b in re.findall(r'<div class="field__label">(.*?)</div>\s*<div class="field__item">(.*?)</div>', t, re.S)]
    cab, adj, actual = {}, [], None
    for k, v in pares:
        if k == "NIF del adjudicatario":
            actual = {"nif": v}
            adj.append(actual)
        elif actual is not None and k in ("Nombre o razón social del adjudicatario", "Fecha del contrato",
                                          "Importe adjudicación (sin IVA)", "Importe adjudicación (con IVA)", "Nº Ofertas",
                                          "Duración del contrato", "Lote", "Número de lote"):
            actual[k] = v
        else:
            cab.setdefault(k, v)
    return {"cab": cab, "adj": adj}


def _nivel_mad(org):
    o = org or ""
    if re.search(r"(?i)ayuntamiento|mancomunidad|municipal", o):
        return _nivel_por_nombre(o, "local")
    if re.search(r"(?i)canal de isabel|metro de madrid|telemadrid|radio televisi[oó]n madrid|empresa p[uú]blica|"
                 r"sociedad an[oó]nima|\bS\.?A\.?\b|fundaci[oó]n|consorcio|obras de madrid|nuevo arpegio|"
                 r"madrid (activa|excelente)|ente p[uú]blico", o):
        return "empresa_publica", "autonomico"
    if RE_UNIV.search(o):
        return "otro", "otro"
    return "autonomico", "autonomico"


def mad_cm(padron, cache_dir=None, desde=2018, por_nombre=False, refresco_dias=25):
    """Contratos menores de la Comunidad de Madrid (consejerías, organismos y empresas públicas como
    Metro, Canal de Isabel II o Radio Televisión Madrid) adjudicados a los NIF del padrón."""
    cl = _cache(cache_dir, "mad_cm_listados")
    cd = _cache(cache_dir, "mad_cm_detalles")
    listados = _lee_cache(cl) or {}
    detalles = _lee_cache(cd) or {}
    s = requests.Session()
    s.headers.update(UA_NAVEGADOR)
    # cada búsqueda guarda su fecha; se repite pasados `refresco_dias` (contratos nuevos)
    fechas = listados.pop("__fechas__", None) or {}
    hoy = date.today()
    for k in listados:
        fechas.setdefault(k, hoy.isoformat())
    viejo = (hoy.toordinal() - refresco_dias)
    # los NIF con contratos se repiten cada `refresco_dias`; los que no tenían ninguno, cada 90 días
    pendientes = [n for n in sorted(padron) if n not in listados or date.fromisoformat(fechas[n]).toordinal()
                  < (viejo if listados[n] else hoy.toordinal() - 90)]

    def _guarda():
        _escribe_cache(cl, dict(listados, __fechas__=fechas))

    try:
        for i, nif in enumerate(pendientes):
            listados[nif] = _mad_listado(s, nif)
            fechas[nif] = hoy.isoformat()
            if i % 25 == 0:
                _guarda()
                print(f"[medios_contratos_ccaa] mad_cm NIF {i}/{len(pendientes)}: "
                      f"{sum(map(len, listados.values()))} referencias", flush=True)
        _guarda()
        # por nombre (solo NIF sin resultados y con nombre distintivo): el detalle confirma el NIF
        if por_nombre:
            for nif, r in sorted(padron.items()):
                k = f"nombre:{nif}"
                nom = norm_nombre(r.get("nombre"))
                if listados.get(nif) or (k in listados and date.fromisoformat(fechas[k]).toordinal() >= viejo) or len(nom) < 8 or len(_palabras(nom)) == 0:
                    continue
                listados[k] = _mad_listado(s, nom, max_pag=10)
                fechas[k] = hoy.isoformat()
                if len(listados) % 25 == 0:
                    _guarda()
            _guarda()
        refs = sorted({x for k, v in listados.items() for x in v})
        for i, ref in enumerate([x for x in refs if x not in detalles]):
            detalles[ref] = _mad_detalle(s, ref)
            if i % 25 == 0:
                _escribe_cache(cd, detalles)
                print(f"[medios_contratos_ccaa] mad_cm detalle {i}/{len(refs)}", flush=True)
        _escribe_cache(cd, detalles)
    except RetoAntibot as e:
        _guarda()
        _escribe_cache(cd, detalles)
        log.error("mad_cm: el portal muestra un reto o captcha; paro (%s)", e)
        raise
    filas = _mad_filas(detalles, padron, desde)
    cob = [dict(plataforma="mad_cm", periodo="todo", filas_leidas=len(detalles),
                url=f"{MAD_CM}/contratos (búsqueda por NIF, filtro Contratos Menores)")]
    return {"filas": filas, "cobertura": cob}


def _mad_filas(detalles, padron, desde=2018):
    filas = []
    for ref, d in detalles.items():
        if not d:
            continue
        cab = d["cab"]
        if "menor" not in norm(cab.get("Tipo de publicación") or cab.get("Procedimiento de adjudicación") or "").lower():
            continue
        jer = [x.strip() for x in (cab.get("Entidad adjudicadora") or "").split("··>") if x.strip()]
        org = jer[-1] if jer else None
        nivel, amb = _nivel_mad(org)
        for j, a in enumerate(d["adj"]):
            nif = norm_nif(a.get("nif"))
            nombre = a.get("Nombre o razón social del adjudicatario")
            clase = _clase(nif, nombre, padron)
            if not clase:
                continue
            fe = _fecha_larga(a.get("Fecha del contrato")) or _fecha_larga(cab.get("Fecha de publicación"))
            filas.append(dict(
                plataforma="mad_cm", id_contrato=f"{ref}|{j}", expediente=cab.get("Número de expediente"), organo=org,
                organo_id=cab.get("Código de la entidad adjudicadora") or org, organo_superior=" > ".join(jer[:-1]) or "Comunidad de Madrid",
                dir3=None, nif_organo=None, nivel=nivel, ambito=amb, cod_ccaa="13",
                cod_municipio=None, objeto=cab.get("Objeto del contrato"), tipo_contrato=cab.get("Tipo de contrato"),
                procedimiento=cab.get("Procedimiento de adjudicación") or "Contratos menores", es_menor=True, cpv=cab.get("Código CPV"),
                lote=a.get("Lote") or a.get("Número de lote"), estado=cab.get("Situación"), nif_adjudicatario=nif,
                nombre_adjudicatario=nombre, metodo_casado="nif",
                importe_sin_iva=num(a.get("Importe adjudicación (sin IVA)")), importe_con_iva=num(a.get("Importe adjudicación (con IVA)")),
                importe_sin_iva_estimado=False, fecha_adjudicacion=fe, url=f"{MAD_CM}/contrato/{ref}", clase=clase, es_agregada=None))
    return [f for f in filas if (f["fecha_adjudicacion"] or "9999")[:4] >= str(desde)]


# --- Navarra: relaciones trimestrales de facturas de contratos de menor cuantía --------------------
# Ley Foral 2/2018 de Contratos Públicos, art. 81: las entidades sometidas publican cada trimestre en el
# Portal de Contratación de Navarra la relación de los contratos de menor cuantía (los departamentos del
# Gobierno, las facturas de más de 100 €; el resto, con su propio criterio). Buscador público (formulario ASP.NET con
# POST normal, sin captcha): hacienda.navarra.es/sicpportal/mtoBuscadorFacturasTrimestrales.aspx
# (campos Entidad y Año; 20 resultados por página). Cada documento (PDF o Excel, con formato propio de
# cada entidad) se descarga de mtoGenerarDocumentoFacturaTrimestral.aspx?UID=..., se extrae su texto y
# se guarda en la caché (no el fichero). La mayoría NO trae el NIF del proveedor: se casa por nombre
# normalizado con el diccionario de nombres del padrón (metodo_casado = 'nombre'), o por NIF si aparece.
NAV_BUSCADOR = "https://hacienda.navarra.es/sicpportal/mtoBuscadorFacturasTrimestrales.aspx"
NAV_DOC = "https://hacienda.navarra.es/sicpportal/mtoGenerarDocumentoFacturaTrimestral.aspx?UID="
RE_IMPORTE = re.compile(r"(?<![\d.,/])-?(?:\d{1,3}(?:\.\d{3})+|\d+),\d{1,2}(?![\d,])(?!\s*%)")
RE_FECHA = re.compile(r"\b(\d{1,2})[/.-](\d{1,2})[/.-](20\d\d)\b")
RE_NIF = re.compile(r"\b[ABCDEFGHJNPQRSUVW]\d{7}[0-9A-J]\b")
NAV_GENERICAS = {"DIARIA", "DIARIO", "DIARIOS", "RADIO", "RADIOS", "REVISTA", "REVISTAS", "NOTICIAS", "TELEVISION",
                 "PERIODICO", "PERIODICOS", "EDICIONES", "PUBLICIDAD", "EDITORES", "INFORMATIVOS", "INFORMATIVO",
                 "ESPANA", "NACIONAL", "PRESS", "NEWS", "ONLINE", "GLOBAL", "GRUPO", "TIERRA"}
PREP = {"EN", "DE", "DEL", "AL", "A", "CON", "PARA", "POR", "Y", "E", "LA", "EL", "LOS", "LAS", "SUSCRIPCION",
        "ANUNCIO", "ANUNCIOS", "PUBLICIDAD", "INSERCION", "SEGUN", "VIA", "TRAVES"}


def _nav_hidden(t):
    return dict(re.findall(r'<input type="hidden" name="([^"]+)" id="[^"]+" value="([^"]*)"', t))


def _nav_filas_listado(t):
    from html import unescape
    return [dict(entidad=unescape(m.group(1)).strip(), anio=m.group(2), uid=m.group(3), titulo=unescape(m.group(4)).strip())
            for m in re.finditer(r"FT1\">(.*?)</td><td class=\"contratosModificadosFilaGridFT2\">(\d*)</td><td class=\""
                                 r"contratosModificadosFilaGridFT3\"><a href='mtoGenerarDocumentoFacturaTrimestral\.aspx\?UID="
                                 r"([^']+)'>(.*?)</a>", t, re.S)]


def nav_listado(anio, sesion=None):
    s = sesion or requests.Session()
    s.headers.update(UA_NAVEGADOR)
    r = s.get(NAV_BUSCADOR, timeout=(30, 120))
    if RE_RETO.search(r.text):
        raise RetoAntibot("reto en el buscador de Navarra")
    h = _nav_hidden(r.text)
    h.update({"txtEntidad": "", "txtAnio": str(anio), "btnEnviar": "Buscar"})
    r = s.post(NAV_BUSCADOR, data=h, timeout=(30, 300))
    res = _nav_filas_listado(r.text)
    m = re.search(r'lblCuentaPaginas">(\d+)', r.text)
    for _ in range(2, (int(m.group(1)) if m else 1) + 1):
        time.sleep(1.5)
        h = _nav_hidden(r.text)
        h.update({"txtEntidad": "", "txtAnio": str(anio), "btnSiguiente.x": "5", "btnSiguiente.y": "5"})
        r = s.post(NAV_BUSCADOR, data=h, timeout=(30, 300))
        res += _nav_filas_listado(r.text)
    return res


def _nav_extrae(raw: bytes):
    """Texto de un documento: {'tipo', 'lineas': [str], 'celdas': [[str]]} (celdas solo en hojas de cálculo)."""
    if raw[:4] == b"%PDF":
        import pdfplumber
        lineas = []
        with pdfplumber.open(io.BytesIO(raw)) as pdf:
            for p in pdf.pages:
                lineas += (p.extract_text() or "").splitlines()
        return {"tipo": "pdf", "lineas": lineas, "celdas": []}
    if raw[:2] == b"PK":
        try:
            import openpyxl
            wb = openpyxl.load_workbook(io.BytesIO(raw), read_only=True, data_only=True)
            celdas = []
            for ws in wb.worksheets:
                for row in ws.iter_rows(values_only=True):
                    fila = ["" if v is None else (v.strftime("%d/%m/%Y") if hasattr(v, "strftime") else
                                                  (f"{v:.2f}".replace(".", ",") if isinstance(v, float) else str(v))) for v in row]
                    if any(fila):
                        celdas.append(fila)
            return {"tipo": "xlsx", "lineas": [" ".join(c for c in f if c) for f in celdas], "celdas": celdas}
        except Exception:  # noqa: BLE001
            return {"tipo": "zip_u_otro", "lineas": [], "celdas": []}
    if raw[:8] == b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1":
        try:
            import xlrd
            wb = xlrd.open_workbook(file_contents=raw)
            celdas = []
            for sh in wb.sheets():
                for i in range(sh.nrows):
                    fila = []
                    for c in sh.row(i):
                        if c.ctype == xlrd.XL_CELL_DATE:
                            fila.append(xlrd.xldate_as_datetime(c.value, wb.datemode).strftime("%d/%m/%Y"))
                        elif c.ctype == xlrd.XL_CELL_NUMBER:
                            fila.append(f"{c.value:.2f}".replace(".", ","))
                        else:
                            fila.append(str(c.value or "").strip())
                    if any(fila):
                        celdas.append(fila)
            return {"tipo": "xls", "lineas": [" ".join(c for c in f if c) for f in celdas], "celdas": celdas}
        except Exception:  # noqa: BLE001
            return {"tipo": "doc_u_otro", "lineas": [], "celdas": []}
    t = _texto(raw)
    if "<html" in t[:2000].lower():
        return {"tipo": "html", "lineas": [], "celdas": []}
    return {"tipo": "texto", "lineas": t.splitlines(), "celdas": []}


def _nav_extrae_guarda(raw, meta, ruta, status):
    try:
        ext = _nav_extrae(raw) if status == 200 else {"tipo": f"http_{status}", "lineas": [], "celdas": []}
    except Exception as e:  # noqa: BLE001
        ext = {"tipo": f"error {type(e).__name__}", "lineas": [], "celdas": []}
    ext.update(meta)
    _escribe_cache(Path(ruta), ext)


def nav_descarga(cache_dir, desde=2018, pausa=1.5):
    """Lista los documentos de cada año y extrae el texto de los que no están en la caché."""
    base = Path(cache_dir) / "nav_portal"
    base.mkdir(parents=True, exist_ok=True)
    hoy = date.today()
    s = requests.Session()
    s.headers.update(UA_NAVEGADOR)
    docs = []
    for anio in range(desde, hoy.year + 1):
        cf = base / f"listado_{anio}.json.gz"
        lst = _lee_cache(cf)
        if lst is None or anio >= hoy.year - 1:
            lst = nav_listado(anio, s)
            _escribe_cache(cf, lst)
            time.sleep(pausa)
        docs += lst
    # descarga en serie (una petición cada `pausa` s) y extracción del texto en paralelo (CPU)
    from concurrent.futures import ProcessPoolExecutor
    vistos, pend = set(), []
    for d in docs:
        if d["uid"] not in vistos and not (base / f"{d['uid']}.json.gz").exists():
            vistos.add(d["uid"])
            pend.append(d)
    futuros = []
    with ProcessPoolExecutor(4) as ex:
        for i, d in enumerate(pend):
            time.sleep(pausa)
            try:
                r = _get(NAV_DOC + d["uid"], timeout=(30, 300), intentos=3, headers=UA_NAVEGADOR)
            except Exception as e:  # noqa: BLE001
                log.warning("Navarra %s: %s", d["uid"], e)
                continue
            meta = dict(d, bytes=len(r.content), nombre_fichero=r.headers.get("Content-Disposition"))
            futuros.append(ex.submit(_nav_extrae_guarda, r.content if r.status_code == 200 else b"", meta,
                                     str(base / f"{d['uid']}.json.gz"), r.status_code))
            futuros = [f for f in futuros if not f.done()]
            if i % 50 == 0:
                print(f"[medios_contratos_ccaa] nav_portal documento {i}/{len(pend)}", flush=True)
        for f in futuros:
            f.result()
    return docs


def _nav_nivel(entidad):
    e = entidad or ""
    if re.search(r"(?i)universidad", e):
        return "otro", "otro"
    if re.search(r"(?i)departamento|servicio navarro|instituto navarro|parlamento|c[aá]mara de comptos|defensor del pueblo|"
                 r"consejo de navarra|agencia navarra|hacienda foral|osasunbidea|gobierno de navarra|euskarabidea|"
                 r"instituto de salud p|nafar|administraci[oó]n de la comunidad", e):
        return "autonomico", "autonomico"
    local = re.search(r"(?i)ayuntamiento|udala|concejo|kontzeju|mancomunidad|junta general|junta municipal|valle|cendea|"
                      r"zendea|municipal|comarca de pamplona|entidad p[uú]blica local|patronato|"
                      r"agrupaci[oó]n|consorcio .*(ribera|zona|comarca|desarrollo)|gerencia de urbanismo", e)
    empresa = re.search(r"(?i)\bS\.?\s?A\.?\b|\bS\.?\s?L\.?\b|S\.L\.U|sociedad|fundaci[oó]n|\bSA\b|\bSL\b|SLU|consorcio|"
                        r"empresa|mercairu|nasertic|tracasa|nasuvinsa|nilsa|sodena|cpen|animsa|gesti[oó]n ambiental", e)
    if local:
        return ("empresa_publica", "local") if empresa and not re.search(r"(?i)ayuntamiento|udala|concejo|mancomunidad", e) else ("local", "local")
    if empresa:
        return "empresa_publica", "autonomico"
    return "local", "local"  # municipios que figuran solo con su nombre (LEOZ/LEOTZ, Arantza...)


def _nav_trimestre(titulo, anio):
    t = norm(titulo or "")
    m = (re.search(r"\b([1-4])\s*(?:º|O|ER|ER\.|T\b|TRIM|\. HIRU|\. HH|ST|ND|RD|TH)", t)
         or re.search(r"TRIMESTRE\s*([1-4])", t) or re.search(r"\b([1-4])\s*TRIMESTRE", t))
    q = int(m.group(1)) if m else None
    if not q:
        for k, v in (("PRIMER", 1), ("SEGUNDO", 2), ("TERCER", 3), ("CUARTO", 4)):
            if k in t:
                q = v
    if not anio:
        return None
    return date(int(anio), 3 * q, 28).isoformat() if q else f"{int(anio)}-12-31"


def _nav_regex(dic):
    claves = sorted(dic, key=len, reverse=True)
    return re.compile(r"(?<![A-Z0-9])(" + "|".join(re.escape(k) for k in claves) + r")(?![A-Z0-9])")


def _nav_norm_linea(s):
    s = norm(s)
    s = re.sub(r"(?<=\b[A-Z])\.(?=[A-Z]\b|\s|$)", "", s)
    s = s.replace("'", " ").replace("`", " ")
    return re.sub(r"\s+", " ", re.sub(r"[^A-Z0-9 ]", " ", s)).strip()


def _nav_importe(linea):
    """Importe de la factura: el último antes de la primera fecha (formato SAP del Gobierno: acumulado,
    importe con IVA, fecha...) o, si no hay fecha antes, el último de la línea."""
    f = RE_FECHA.search(linea)
    antes = RE_IMPORTE.findall(linea[:f.start()]) if f else []
    imps = antes or RE_IMPORTE.findall(linea)
    return num(imps[-1]) if imps else None


def nav_portal(padron, cache_dir=None, desde=2018, dic=None, descargar=True):
    if not cache_dir:
        raise ValueError("nav_portal necesita cache_dir")
    if descargar:
        docs = nav_descarga(cache_dir, desde)
    else:
        docs = [x for a in range(desde, date.today().year + 1)
                for x in (_lee_cache(Path(cache_dir) / "nav_portal" / f"listado_{a}.json.gz") or [])]
    if dic is None:
        dic, _ = diccionario_nombres(padron)
    # nombres demasiado genéricos para buscarlos dentro de una línea de texto libre
    dic = {k: v for k, v in dic.items() if len(k) >= 8 and _palabras(k) - NAV_GENERICAS}
    rx = _nav_regex(dic)
    base = Path(cache_dir) / "nav_portal"
    filas, cobertura, ocur = [], {}, {}
    vistos = set()
    for d in docs:
        if d["uid"] in vistos:
            continue
        vistos.add(d["uid"])
        ext = _lee_cache(base / f"{d['uid']}.json.gz")
        if not ext:
            continue
        anio = int(d["anio"]) if str(d.get("anio") or "").isdigit() else None
        cob = cobertura.setdefault(str(anio), dict(plataforma="nav_portal", periodo=str(anio), filas_leidas=0, documentos=0,
                                                   documentos_sin_texto=0, url=NAV_BUSCADOR))
        cob["documentos"] += 1
        if not ext.get("lineas"):
            cob["documentos_sin_texto"] += 1
        cob["filas_leidas"] += len(ext.get("lineas") or [])
        nivel, amb = _nav_nivel(d["entidad"])
        f_trim = _nav_trimestre(d["titulo"], anio)
        lineas = ext.get("lineas") or []
        celdas = ext.get("celdas") or []
        ocur = {}
        col_imp = None
        for k, linea in enumerate(lineas):
            if celdas and k < len(celdas):
                # cabecera de hoja de cálculo: «Importe IVA incluido» (formato del Gobierno: la primera
                # columna de importe es el acumulado por proveedor) o, si no, la única columna «Importe»
                cab = [norm(c) for c in celdas[k]]
                if any("IMPORTE" in c for c in cab) and sum(bool(c) and not RE_IMPORTE.search(c) for c in cab) >= 3:
                    cands = [i for i, c in enumerate(cab) if "IMPORTE" in c and "IVA INCLUIDO" in c]
                    cands = cands or [i for i, c in enumerate(cab) if "IMPORTE" in c and "ACUMULADO" not in c
                                      and "SIN IVA" not in c and "BASE" not in c]
                    col_imp = cands[-1] if cands else None
                    continue
            L = _nav_norm_linea(linea)
            nif, metodo, nombre = None, None, None
            for n in RE_NIF.findall(norm(linea).replace(" ", " ")):
                if n in padron:
                    nif, metodo = n, "nif"
                    break
            if not nif:
                m = rx.search(L)
                if m:
                    prev = L[:m.start()].split()
                    # el nombre debe ser el tercero (al principio, tras un número/NIF o en una celda propia),
                    # no una mención en el texto («anuncio en Diario de Navarra»)
                    en_celda = bool(celdas) and k < len(celdas) and any(_nav_norm_linea(c).startswith(m.group(1)) for c in celdas[k])
                    if en_celda or not prev or not prev[-1].isalpha() or (prev[-1] not in PREP and len(prev) <= 1):
                        nif, metodo, nombre = dic[m.group(1)], "nombre", m.group(1)
            if not nif:
                continue
            if re.match(r"(SUB)?TOTAL|SUMA|ACUMULADO", L) or " TOTAL " in f" {L[:max(0, (rx.search(L) or re.search('$', L)).start())]} ":
                continue  # líneas de total por proveedor (repiten las facturas)
            imp = _nav_importe(linea)
            if col_imp is not None and k < len(celdas) and col_imp < len(celdas[k]):
                # hoja de cálculo con cabecera: la columna del importe, si la celda es un número
                v = str(celdas[k][col_imp]).strip().replace("€", "").strip()
                if re.fullmatch(r"-?\d{1,3}(\.\d{3})*(,\d{1,2})?|-?\d+(,\d{1,2})?", v):
                    imp = num(v)
            # importe nulo o inverosímil para un contrato de menor cuantía (texto superpuesto en el PDF)
            if imp is None or imp < 1 or imp > 60000:
                continue
            # fila acumulada (columnas por trimestre y total del año en curso: NICDO y otras): el
            # documento de cada trimestre repite y amplía el anterior
            imps = [num(x) for x in RE_IMPORTE.findall(linea)]
            acumulado = len(imps) >= 3 and abs(sum(imps[:-1]) - imps[-1]) < 1
            fm = RE_FECHA.search(linea)
            fe = None
            if fm:
                try:
                    fe = date(int(fm.group(3)), int(fm.group(2)), int(fm.group(1))).isoformat()
                except ValueError:
                    fe = None
            if not fe or not anio or abs(int(fe[:4]) - anio) > 1:
                fe = f_trim
            org = d["entidad"]
            # número de operación contable (Ayuntamiento de Pamplona y otros: 2019003346) para casar la
            # misma factura publicada en dos documentos con formatos distintos
            numop = re.search(r"(?<!\d)(20[12]\d{7})(?!\d)", linea)
            if numop:
                clave = f"{org}|{nif}|{imp:.2f}|op{numop.group(1)}"
            else:
                base_k = f"{org}|{nif}|{imp:.2f}|{fe}"
                ocur[base_k] = ocur.get(base_k, -1) + 1  # repeticiones dentro del mismo documento
                clave = f"{base_k}|{ocur[base_k]}"
            filas.append(dict(
                plataforma="nav_portal",
                id_contrato=hashlib.md5(clave.encode()).hexdigest(),
                expediente=numop.group(1) if numop else None, organo=org, organo_id=org, organo_superior=d["titulo"],
                dir3=None, nif_organo=None,
                nivel=nivel, ambito=amb, cod_ccaa="15", cod_municipio=None, objeto=linea.strip()[:500],
                tipo_contrato=None, procedimiento="Contrato de menor cuantía (relación trimestral de facturas)", es_menor=True,
                cpv=None, lote=None, estado=None, nif_adjudicatario=nif,
                nombre_adjudicatario=nombre or (padron.get(nif) or {}).get("nombre"), metodo_casado=metodo,
                importe_sin_iva=imp / _iva(linea), importe_con_iva=imp, importe_sin_iva_estimado=True,
                fecha_adjudicacion=fe, url=NAV_DOC + d["uid"], clase="padron", es_agregada=None,
                _acum=acumulado, _uid=d["uid"], _ftrim=f_trim or "", _anio=anio))
    # entidades-año con filas acumuladas: solo cuenta el último documento del año (el más completo)
    acum = {(f["organo"], f["_anio"]) for f in filas if f["_acum"]}
    ultimo = {}
    for f in filas:
        k = (f["organo"], f["_anio"])
        if k in acum and (f["_ftrim"], f["_uid"]) > ultimo.get(k, ("", "")):
            ultimo[k] = (f["_ftrim"], f["_uid"])
    filas = [f for f in filas if (f["organo"], f["_anio"]) not in acum or f["_uid"] == ultimo[(f["organo"], f["_anio"])][1]]
    for f in filas:
        for c in ("_acum", "_uid", "_ftrim", "_anio"):
            f.pop(c, None)
    # misma clave en varios documentos (relaciones republicadas o acumuladas): una sola fila
    filas = list({f["id_contrato"]: f for f in filas}.values())
    filas = [f for f in filas if (f["fecha_adjudicacion"] or "9999")[:4] >= str(desde)]
    return {"filas": filas, "cobertura": list(cobertura.values())}


# --- ejecución -------------------------------------------------------------------------------------
def _ejecuta(plataformas, desde, cache_dir):
    padron = leer_padron()
    out, cand_nombres, cobertura = [], [], []
    ahora = datetime.now(timezone.utc).isoformat()
    pares = []
    if "cat_pscp" in plataformas or "cat_rpc" in plataformas:
        d = cat_pscp(padron, cache_dir, desde)
        pares += [(p["nif"], p["nombre"]) for p in d["pares"]]
        pares += [(f["nif_adjudicatario"], f["nombre_adjudicatario"]) for f in d["filas"]]
        if "cat_pscp" in plataformas:
            out += d["filas"]
            vistos = {(f["nif_adjudicatario"], f["nombre_adjudicatario"]) for f in d["filas"]}
            agg = {}
            for p in d["pares"]:
                if p["nif"] in padron or (p["nif"], p["nombre"]) in vistos or not RE_CANDIDATO.search(norm(p["nombre"])):
                    continue
                a = agg.setdefault((p["nif"], p["nombre"]), dict(plataforma="cat_pscp", nombre_adjudicatario=p["nombre"],
                                                                 nif_adjudicatario=p["nif"], n_contratos=0, n_menores=0, importe=None))
                a["n_contratos"] += p["n"]
                a["n_menores"] += p["n"] if p["procedimiento"] == "Contracte menor" else 0
            cand_nombres += list(agg.values())
            cobertura.append(dict(plataforma="cat_pscp", periodo="todo", filas_padron=sum(f["clase"] == "padron" for f in d["filas"])))
    for nombre, fn in (("eus_kontratazioa", eus_kontratazioa), ("and_junta", and_junta), ("gal_xunta", gal_xunta),
                       ("rio_car", rio_car), ("mad_ayto", mad_ayto), ("bcn_ayto", bcn_ayto), ("mad_cm", mad_cm)):
        if nombre not in plataformas:
            continue
        t0 = time.time()
        d = fn(padron, cache_dir, desde)
        out += d["filas"]
        pares += [(p["nif"], p["nombre"]) for p in d.get("pares", [])]
        pares += [(f["nif_adjudicatario"], f["nombre_adjudicatario"]) for f in d["filas"]]
        cobertura += d.get("cobertura", []) or [dict(plataforma=nombre, periodo="todo")]
        print(f"[medios_contratos_ccaa] {nombre}: {len(d['filas'])} filas en {round(time.time() - t0)} s", flush=True)
    dic = None
    if "cat_rpc" in plataformas or "nav_portal" in plataformas:
        dic, ambiguos = diccionario_nombres(padron, pares)
    if "nav_portal" in plataformas:
        t0 = time.time()
        d = nav_portal(padron, cache_dir, desde, dic=dic)
        out += d["filas"]
        cobertura += d["cobertura"]
        print(f"[medios_contratos_ccaa] nav_portal: {len(d['filas'])} filas en {round(time.time() - t0)} s", flush=True)
    if "cat_rpc" in plataformas:
        d = cat_rpc(padron, dic, cache_dir, desde)
        out += d["filas"]
        cand_nombres += d["candidatos"]
        cobertura.append(dict(plataforma="cat_rpc", periodo="todo", filas_leidas=d.get("nombres_leidos"),
                              filas_padron=len(d["filas"]), nombres_diccionario=len(dic), nombres_ambiguos=len(ambiguos)))
        print(f"[medios_contratos_ccaa] cat_rpc: {len(d['filas'])} filas; diccionario {len(dic)} nombres, {len(ambiguos)} ambiguos", flush=True)
    # cachés antiguas de Galicia: el importe de contratosdegalicia.gal lleva IVA (abundan 18.029 y 18.149 €,
    # 14.900 y 14.999 € más el 21 %, cuando el límite del menor es 15.000 € sin IVA)
    for f in out:
        if f.get("plataforma") == "gal_xunta" and not f.get("importe_sin_iva_estimado"):
            con = f.get("importe_sin_iva")
            f["importe_con_iva"] = con
            f["importe_sin_iva"] = con / _iva(f.get("objeto")) if con is not None else None
            f["importe_sin_iva_estimado"] = True
    # cachés hechas con la regla antigua de universidades: una consejería «... y Universidades» no es 'otro'
    for f in out:
        if f.get("nivel") == "otro" and re.search(r"(?i)conselle|consej|departament|delegaci", f.get("organo") or "")                 and not RE_UNIV.search(f.get("organo") or ""):
            f["nivel"], f["ambito"] = "autonomico", "autonomico"
    # deduplicado por clave y año
    mejor = {}
    for f in out:
        f["nif_adjudicatario"] = f.get("nif_adjudicatario") or ""
        f["id_contrato"] = str(f.get("id_contrato") or "")
        f["anio"] = int(f["fecha_adjudicacion"][:4]) if f.get("fecha_adjudicacion") else None
        f["nombre_normalizado"] = norm_nombre(f.get("nombre_adjudicatario"))
        f["cargado_en"] = ahora
        mejor[tuple(f[c] for c in CLAVE)] = f
    filas = list(mejor.values())
    for c in cobertura:
        c.setdefault("cargado_en", ahora)
    return filas, cand_nombres, cobertura


COLUMNAS = {
    "importe_sin_iva": {"data_type": "double"}, "importe_con_iva": {"data_type": "double"},
    "anio": {"data_type": "bigint"}, "cod_municipio": {"data_type": "text"}, "cod_ccaa": {"data_type": "text"},
    "fecha_adjudicacion": {"data_type": "text"}, "dir3": {"data_type": "text"}, "nif_organo": {"data_type": "text"},
    "organo_superior": {"data_type": "text"}, "cpv": {"data_type": "text"}, "lote": {"data_type": "text"},
    "estado": {"data_type": "text"}, "tipo_contrato": {"data_type": "text"}, "es_agregada": {"data_type": "text"},
    "expediente": {"data_type": "text"}, "organo_id": {"data_type": "text"},
}


@dlt.source(name="medios_contratos_ccaa")
def medios_contratos_ccaa(plataformas: tuple = PLATAFORMAS, desde: int = 2018, cache_dir: str | None = None):
    memo = {}

    def datos():
        if "r" not in memo:
            memo["r"] = _ejecuta(plataformas, desde, cache_dir)
        return memo["r"]

    @dlt.resource(name="ccaa_contratos_medios", write_disposition="merge", primary_key=CLAVE, columns=COLUMNAS)
    def ccaa_contratos_medios():
        yield [f for f in datos()[0] if f["clase"] == "padron"]

    @dlt.resource(name="ccaa_candidatos_medios", write_disposition="merge", primary_key=CLAVE, columns=COLUMNAS)
    def ccaa_candidatos_medios():
        yield [f for f in datos()[0] if f["clase"] == "candidato"]

    @dlt.resource(name="ccaa_candidatos_nombres", write_disposition="merge",
                  primary_key=["plataforma", "nombre_adjudicatario", "nif_adjudicatario"],
                  columns={"importe": {"data_type": "double"}, "n_menores": {"data_type": "bigint"}})
    def ccaa_candidatos_nombres():
        yield datos()[1]

    @dlt.resource(name="ccaa_cobertura", write_disposition="merge", primary_key=["plataforma", "periodo"])
    def ccaa_cobertura():
        yield datos()[2]

    return [ccaa_contratos_medios, ccaa_candidatos_medios, ccaa_candidatos_nombres, ccaa_cobertura]
