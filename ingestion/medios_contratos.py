"""Fuente dlt «Contratos adjudicados a empresas de medios» (tema `medios_contratos`).

Plataforma de Contratación del Sector Público (PLACSP, Ministerio de Hacienda),
sindicación de datos abiertos (Atom + CODICE), tres conjuntos:
  perfiles  sindicacion_643/licitacionesPerfilesContratanteCompleto3_AAAA[MM].zip
            licitaciones de los órganos con perfil alojado en PLACSP (sin menores)
  agregadas sindicacion_1044/PlataformasAgregadasSinMenores_AAAA[MM].zip
            plataformas autonómicas agregadas (Cataluña, Euskadi, Andalucía,
            C. de Madrid, Galicia, Navarra, La Rioja...), SIN contratos menores
  menores   sindicacion_1143/contratosMenoresPerfilesContratantes_AAAA[MM].zip
            contratos menores de los perfiles alojados en PLACSP (desde 2018)
Índice: https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx
Registro de órganos: https://contrataciondelsectorpublico.gob.es/datosabiertos/OrganosContratacion.xlsx

Método:
  - Cada ZIP contiene ficheros .atom de 500 entradas con las ACTUALIZACIONES del
    periodo: un contrato aparece una vez por cada modificación. Se lee en streaming
    (iterparse dentro del ZIP, en paralelo por fichero .atom) y se descarta todo
    salvo los resultados (TenderResult) cuyo adjudicatario interesa.
  - Interesa un adjudicatario si su NIF está en el padrón curado
    transform/seeds/medios_padron_nif.csv (es_medio 'si' o 'gris')  -> pcsp_contratos_medios
    o, sin estar en el padrón, si su nombre «parece» de un medio (regex) o su NIF
    está en la lista `nifs_extra`                                      -> pcsp_candidatos_medios
    (sirve para ampliar el padrón sin volver a descargar: el mart une las dos
    tablas y filtra por el padrón vigente). No se guardan personas físicas.
  - Deduplicado: clave (conjunto, expediente, órgano, lote, NIF) quedándose con la
    actualización más reciente (`fecha_actualizacion`). Merge en destino.
  - Nivel del órgano: cadena de dependencias de CODICE («ENTIDADES LOCALES»,
    «COMUNIDADES Y CIUDADES AUTÓNOMAS», «ADMINISTRACIÓN GENERAL DEL ESTADO»,
    «SOCIEDADES, FUNDACIONES Y CONSORCIOS ...»), registro de órganos (ubicación),
    ContractingPartyTypeCode y DIR3 (L01 + código INE = ayuntamiento, L02 =
    diputación, A01..A19 = CCAA con el mismo orden que el INE, E/EA = Estado).
    En la agregación no hay tipo ni NIF del órgano: plataforma + nombre.
  - cod_ccaa: DIR3 de CCAA o de municipio, si no el código postal del órgano
    (2 primeras cifras = provincia INE), si no la plataforma agregada.
  - Los ZIP se descargan EN SERIE (el WAF bloquea peticiones en paralelo), con
    timeout y reintentos, y se borran tras procesarlos.

Modos:
  medios_contratos()                       -> últimos 3 meses (ficheros mensuales,
                                              incluido el mes en curso, parcial)
  medios_contratos(meses=None, desde=2018) -> histórico: anuales desde `desde`
                                              hasta el año pasado + mensuales del año en curso
  cache_dir: guarda el resultado filtrado de cada ZIP (json.gz) y no lo vuelve a
  descargar (para reanudar la carga histórica).

Recursos:
  pcsp_contratos_medios   (merge, pk id_conjunto+expediente+organo_clave+lote+nif_adjudicatario)
  pcsp_candidatos_medios  (merge, misma clave)
  pcsp_cobertura          (merge, pk id_conjunto+periodo): entradas, contratos y órganos por fichero
  pcsp_organos            (replace): registro de órganos de contratación
"""

from __future__ import annotations

import csv
import gzip
import hashlib
import io
import json
import logging
import os
import re
import tempfile
import time
import unicodedata
import zipfile
from concurrent.futures import ProcessPoolExecutor
from datetime import date, datetime, timezone
from pathlib import Path
from xml.etree import ElementTree as ET

import dlt
import requests

log = logging.getLogger(__name__)

BASE = "https://contrataciondelsectorpublico.gob.es/sindicacion/"
CONJUNTOS = {
    "perfiles": "sindicacion_643/licitacionesPerfilesContratanteCompleto3",
    "agregadas": "sindicacion_1044/PlataformasAgregadasSinMenores",
    "menores": "sindicacion_1143/contratosMenoresPerfilesContratantes",
}
URL_ORGANOS = "https://contrataciondelsectorpublico.gob.es/datosabiertos/OrganosContratacion.xlsx"
CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)"}
PADRON = Path(__file__).resolve().parent.parent / "transform" / "seeds" / "medios_padron_nif.csv"
CLAVE = ["id_conjunto", "expediente", "organo_clave", "lote", "nif_adjudicatario"]

# --- Códigos -------------------------------------------------------------------
PROV_CCAA = {
    "01": "16", "02": "08", "03": "10", "04": "01", "05": "07", "06": "11", "07": "04", "08": "09",
    "09": "07", "10": "11", "11": "01", "12": "10", "13": "08", "14": "01", "15": "12", "16": "08",
    "17": "09", "18": "01", "19": "08", "20": "16", "21": "01", "22": "02", "23": "01", "24": "07",
    "25": "09", "26": "17", "27": "12", "28": "13", "29": "01", "30": "14", "31": "15", "32": "12",
    "33": "03", "34": "07", "35": "05", "36": "12", "37": "07", "38": "05", "39": "06", "40": "07",
    "41": "01", "42": "07", "43": "09", "44": "02", "45": "08", "46": "10", "47": "07", "48": "16",
    "49": "07", "50": "02", "51": "18", "52": "19",
}
# Plataformas agregadas -> comunidad (cod INE)
PLATAFORMA_CCAA = [
    (r"catalunya|contractaciopublica\.cat|generalitat de catalunya", "09"),
    (r"euskadi|gobierno vasco|eusko", "16"),
    (r"andaluc", "01"),
    (r"comunidad de madrid|comunidad\.madrid", "13"),
    (r"ayuntamiento de madrid|sede\.madrid\.es|madrid\.es", "13"),
    (r"galicia|xunta|contratosdegalicia", "12"),
    (r"navarra", "15"),
    (r"rioja", "17"),
    (r"asturias", "03"),
    (r"castilla y le|jcyl", "07"),
    (r"murcia|carm\.es", "14"),
    (r"canarias", "05"),
]
CCAA_NOMBRES = [  # para la cadena de dependencias de CODICE
    (r"andaluc", "01"), (r"arag[oó]n", "02"), (r"asturias", "03"), (r"balear|illes", "04"),
    (r"canarias", "05"), (r"cantabria", "06"), (r"castilla y le[oó]n", "07"),
    (r"castilla.{0,3}la mancha", "08"), (r"catalu", "09"), (r"valencia", "10"),
    (r"extremadura", "11"), (r"galicia", "12"), (r"comunidad de madrid|madrid", "13"),
    (r"murcia", "14"), (r"navarra", "15"), (r"pa[ií]s vasco|euskadi", "16"), (r"rioja", "17"),
    (r"ceuta", "18"), (r"melilla", "19"),
]

# --- Candidatos por nombre (para revisión; NO entran en los totales) -------------
RE_CANDIDATO = re.compile(
    r"\bDIARI[OA]?\b|PERIODIC|\bRADIO\b|RADIOTELEVISI|TELEVISI|\bTV\b|\bTELE\b|PUBLICACION|\bPRENSA\b|"
    r"\bPREMSA\b|NOTICIAS|NOTICIES|\bEDICIONES\b|\bEDICIONS\b|EDITORIAL|\bMEDIA\b|\bMEDIOS\b|\bMITJANS\b|"
    r"\bONDA\b|EMISORA|COMUNICACION|COMUNICACIO\b|MULTIMEDIA|AUDIOVISUAL|REVISTA|SEMANARIO|"
    r"PRISA|VOCENTO|ATRESMEDIA|UNIPREX|MEDIASET|PUBLIESPANA|UNIDAD EDITORIAL|HENNEO|GODO\b|"
    r"VANGUARDIA|HERALDO|JOLY|ABSIDE|RADIO POPULAR|TITANIA|EUROPA PRESS|SERVIMEDIA|AGENCIA EFE|"
    r"20 MINUTOS|VEINTE MINUTOS|EL ESPANOL|ECOPRENSA|LIBERTAD DIGITAL|PROMECAL|FARO DE VIGO|"
    r"VOZ DE GALICIA|SOCIEDAD ESPANOLA DE RADIODIFUSION|PROMOTORA DE INFORMACIONES|CADENA SER|COPE\b|"
    r"EDITORA|PERIODISTIC|INFORMATIVO|MAGAZINE|XORNAL|IRRATI|TELEBISTA|HEDABIDE|KOMUNIKA|ARGITAL|SETMANARI|"
    r"\bFM\b|NORTE DE CASTILLA|FEDERICO DOMENECH|NUEVA RIOJA|^LA INFORMACION,? S|^EL COMERCIO,? S|"
    r"EDITORIAL CANTABRIA|IDEAL COMUNICACION|LA RAZON|AUDIOVISUAL ESPANOLA|PRENSA MALAGUENA|SMARTCLIP|"
    r"EL CORREO|SUPERDEPORTE|LA OPINION|EL PROGRESO|LA REGION,? S|DEIA\b|BERRIA\b|"
    r"EUSKALDUN|EL MUNDO|EXPANSION,? S|DOS MIL PALABRAS|EL CONFIDENCIAL|"
    r"VOZPOPULI|ESDIARIO|\bPRESS\b|\bNEWS\b|CRONICA|GACETA|\bECO DE\b|"
    r"MEDIAPRO|UNEDISA|GRUPO SERRA|ULTIMA HORA|CANARIAS7|DIARIO DE AVISOS|PROMOTORA DE MEDIOS"
)
RE_PERSONA_FISICA = re.compile(r"^(\d{8}[A-Z]|[XYZ]\d{7}[A-Z]|\d{7,8})$")


def norm(s: str | None) -> str:
    s = unicodedata.normalize("NFKD", str(s or "")).encode("ascii", "ignore").decode().upper()
    return re.sub(r"\s+", " ", s).strip()


def norm_nif(s: str | None) -> str | None:
    if not s:
        return None
    s = re.sub(r"[^A-Z0-9]", "", s.upper())
    if s.startswith("ES") and len(s) == 11:  # IVA intracomunitario español
        s = s[2:]
    return s or None


def leer_padron(ruta: Path = PADRON) -> dict[str, dict]:
    if not ruta.exists():
        log.warning("No existe el padrón %s: solo se guardarán candidatos", ruta)
        return {}
    with open(ruta, encoding="utf-8") as f:
        return {norm_nif(r["nif"]): r for r in csv.DictReader(f)
                if r.get("nif") and r.get("es_medio", "").strip() in ("si", "gris")}


# --- Parser CODICE ---------------------------------------------------------------
def _ln(t):
    return t.rsplit("}", 1)[-1]


def _kids(e, name):
    return [c for c in e if _ln(c.tag) == name]


def _kid(e, name):
    if e is None:
        return None
    for c in e:
        if _ln(c.tag) == name:
            return c
    return None


def _path(e, *names):
    for n in names:
        e = _kid(e, n)
        if e is None:
            return None
    return e


def _txt(e):
    return e.text.strip() if e is not None and e.text and e.text.strip() else None


def _ids(p):
    out = {}
    if p is not None:
        for pi in _kids(p, "PartyIdentification"):
            i = _kid(pi, "ID")
            if i is not None and _txt(i):
                out.setdefault(i.get("schemeName", "?"), _txt(i))
    return out


def _num(s):
    try:
        return float(s) if s not in (None, "") else None
    except ValueError:
        return None


_W = {}  # estado de cada proceso trabajador


def _init_worker(nifs_padron, nifs_extra):
    _W["padron"] = set(nifs_padron)
    _W["extra"] = set(nifs_extra)


def _clasifica_adj(nif, nombre):
    """'padron' | 'candidato' | None"""
    if nif and nif in _W["padron"]:
        return "padron"
    if nif and RE_PERSONA_FISICA.match(nif):
        return None
    if nif and nif in _W["extra"]:
        return "candidato"
    if nombre and RE_CANDIDATO.search(norm(nombre)):
        return "candidato"
    return None


def _parse_entry(en, conjunto):
    """Devuelve (filas, n_resultados_con_nif, clave_contrato, clave_organo)."""
    cfs = _kid(en, "ContractFolderStatus")
    if cfs is None:
        return [], 0, None, None
    trs = _kids(cfs, "TenderResult")
    lcp = _kid(cfs, "LocatedContractingParty")
    party = _kid(lcp, "Party")
    oids = _ids(party)
    org_nombre = _txt(_path(party, "PartyName", "Name"))
    expediente = _txt(_kid(cfs, "ContractFolderID")) or ""
    org_clave = oids.get("NIF") or oids.get("ID_OC_PLAT") or oids.get("ID_PLATAFORMA") or norm(org_nombre)
    # primero: ¿algún adjudicatario interesa?
    sel, n_nif = [], 0
    for tr in trs:
        for wp in _kids(tr, "WinningParty"):
            ids = _ids(wp)
            nif = norm_nif(ids.get("NIF") or (next(iter(ids.values())) if ids else None))
            if nif:
                n_nif += 1
            nombre = _txt(_path(wp, "PartyName", "Name"))
            c = _clasifica_adj(nif, nombre)
            if c:
                sel.append((tr, nif, nombre, c, next(iter(ids.keys()), None) if ids else None))
    clave_c = (expediente, org_clave) if trs else None
    if not sel:
        return [], n_nif, clave_c, org_clave
    lk = _kid(en, "link")
    chain, dir3s = [], []
    p = _kid(lcp, "ParentLocatedParty")
    while p is not None:
        chain.append(_txt(_path(p, "PartyName", "Name")) or "")
        d = _ids(p).get("DIR3")
        if d:
            dir3s.append(d)
        p = _kid(p, "ParentLocatedParty")
    pp = _kid(cfs, "ProcurementProject")
    ba = _kid(pp, "BudgetAmount")
    lot_cpv = {}
    for lot in _kids(cfs, "ProcurementProjectLot"):
        lpp = _kid(lot, "ProcurementProject")
        lot_cpv[_txt(_kid(lot, "ID"))] = " ".join(filter(None, (
            _txt(_kid(r, "ItemClassificationCode")) for r in _kids(lpp, "RequiredCommodityClassification")))) if lpp is not None else None
    base = dict(
        id_conjunto=conjunto,
        entry_id=_txt(_kid(en, "id")),
        fecha_actualizacion=_txt(_kid(en, "updated")),
        url=lk.get("href") if lk is not None else None,
        expediente=expediente,
        estado=_txt(_kid(cfs, "ContractFolderStatusCode")),
        organo=org_nombre,
        organo_clave=org_clave,
        nif_organo=norm_nif(oids.get("NIF")),
        dir3=oids.get("DIR3"),
        id_plataforma_organo=oids.get("ID_PLATAFORMA"),
        id_oc_plat=oids.get("ID_OC_PLAT"),
        plataforma=_txt(_path(party, "AgentParty", "PartyName", "Name")),
        tipo_organo_code=_txt(_kid(lcp, "ContractingPartyTypeCode")),
        organo_padres=" > ".join(chain) or None,
        organo_padres_dir3=" > ".join(dir3s) or None,
        organo_ciudad=_txt(_path(party, "PostalAddress", "CityName")),
        organo_cp=_txt(_path(party, "PostalAddress", "PostalZone")),
        objeto=_txt(_kid(pp, "Name")),
        tipo_contrato=_txt(_kid(pp, "TypeCode")),
        subtipo_contrato=_txt(_kid(pp, "SubTypeCode")),
        presupuesto_sin_iva=_num(_txt(_kid(ba, "TaxExclusiveAmount"))),
        valor_estimado=_num(_txt(_kid(ba, "EstimatedOverallContractAmount"))),
        cpv=" ".join(filter(None, (_txt(_kid(r, "ItemClassificationCode")) for r in _kids(pp, "RequiredCommodityClassification")))) or None,
        procedimiento=_txt(_path(cfs, "TenderingProcess", "ProcedureCode")),
        es_menor=conjunto == "menores",
        n_resultados=len(trs),
    )
    filas = []
    for tr, nif, nombre, clase, idtipo in sel:
        atp = _kid(tr, "AwardedTenderedProject")
        lmt = _kid(atp, "LegalMonetaryTotal")
        lote = _txt(_kid(atp, "ProcurementProjectLotID")) or ""
        f = dict(base)
        f.update(
            clase=clase,
            lote=lote,
            cpv_lote=lot_cpv.get(lote) or None,
            resultado_code=_txt(_kid(tr, "ResultCode")),
            fecha_adjudicacion=_txt(_kid(tr, "AwardDate")),
            n_ofertas=_num(_txt(_kid(tr, "ReceivedTenderQuantity"))),
            nif_adjudicatario=nif or "",
            tipo_id_adjudicatario=idtipo,
            nombre_adjudicatario=nombre,
            n_adjudicatarios=len(_kids(tr, "WinningParty")),
            importe_adjudicado_sin_iva=_num(_txt(_kid(lmt, "TaxExclusiveAmount"))),
            importe_adjudicado_con_iva=_num(_txt(_kid(lmt, "PayableAmount"))),
        )
        filas.append(f)
    return filas, n_nif, clave_c, org_clave


def _procesa_atoms(args):
    zpath, nombres, conjunto = args
    filas, st = [], {"entradas": 0, "borradas": 0, "adj_con_nif": 0}
    contratos, organos = set(), set()
    with zipfile.ZipFile(zpath) as z:
        for name in nombres:
            with z.open(name) as fh:
                for _, el in ET.iterparse(fh, events=("end",)):
                    t = _ln(el.tag)
                    if t == "entry":
                        st["entradas"] += 1
                        fs, n_nif, cc, oc = _parse_entry(el, conjunto)
                        filas.extend(fs)
                        st["adj_con_nif"] += n_nif
                        if cc:
                            contratos.add(int.from_bytes(hashlib.blake2b(repr(cc).encode(), digest_size=8).digest(), 'big'))
                        if oc and n_nif:
                            organos.add(oc)
                        el.clear()
                    elif t == "deleted-entry":
                        st["borradas"] += 1
                        el.clear()
    return filas, st, contratos, organos


def _dedup(filas):
    mejor = {}
    for f in filas:
        k = tuple(f.get(c) or "" for c in CLAVE)
        if k not in mejor or (f.get("fecha_actualizacion") or "") >= (mejor[k].get("fecha_actualizacion") or ""):
            mejor[k] = f
    return list(mejor.values())


def procesa_zip(zpath, conjunto, nifs_padron, nifs_extra=(), workers=None):
    """Lee un ZIP de PLACSP y devuelve (filas filtradas y deduplicadas, estadísticas)."""
    t0 = time.time()
    with zipfile.ZipFile(zpath) as z:
        atoms = [n for n in z.namelist() if n.endswith(".atom")]
    workers = workers or max(1, min(16, (os.cpu_count() or 2) - 2))
    lotes = [atoms[i:i + 8] for i in range(0, len(atoms), 8)]
    filas, st, contratos, organos = [], {"entradas": 0, "borradas": 0, "adj_con_nif": 0}, set(), set()
    if workers == 1 or len(lotes) == 1:
        _init_worker(nifs_padron, nifs_extra)
        res = map(_procesa_atoms, [(zpath, l, conjunto) for l in lotes])
        for f, s, c, o in res:
            filas.extend(f); contratos |= c; organos |= o
            for k in st:
                st[k] += s[k]
    else:
        with ProcessPoolExecutor(workers, initializer=_init_worker, initargs=(list(nifs_padron), list(nifs_extra))) as ex:
            for f, s, c, o in ex.map(_procesa_atoms, [(zpath, l, conjunto) for l in lotes]):
                filas.extend(f); contratos |= c; organos |= o
                for k in st:
                    st[k] += s[k]
    filas = _dedup(filas)
    st.update(ficheros_atom=len(atoms), contratos_distintos=len(contratos), organos_con_adjudicacion=len(organos),
              filas_padron=sum(f["clase"] == "padron" for f in filas),
              filas_candidatos=sum(f["clase"] == "candidato" for f in filas), segundos=round(time.time() - t0))
    return filas, st


# --- Descarga --------------------------------------------------------------------
def _url(conjunto, periodo):
    return f"{BASE}{CONJUNTOS[conjunto]}_{periodo}.zip"


def descarga(url, destino: Path, intentos=4) -> bool:
    """Descarga en streaming con timeout. False si el fichero no existe (404)."""
    for i in range(intentos):
        try:
            with requests.get(url, stream=True, timeout=(30, 180), headers=CABECERAS) as r:
                if r.status_code == 404:
                    return False
                r.raise_for_status()
                if "zip" not in (r.headers.get("Content-Type") or "zip"):
                    raise RuntimeError(f"respuesta no ZIP: {r.headers.get('Content-Type')}")
                tmp = destino.with_suffix(".part")
                with open(tmp, "wb") as fh:
                    for chunk in r.iter_content(1 << 20):
                        fh.write(chunk)
            zipfile.ZipFile(tmp).close()  # valida
            tmp.replace(destino)
            return True
        except Exception as e:  # noqa: BLE001
            log.warning("Descarga %s intento %d: %s", url, i + 1, e)
            for p in (destino, destino.with_suffix(".part")):
                p.unlink(missing_ok=True)
            time.sleep(30 * (i + 1))
    raise RuntimeError(f"No se pudo descargar {url}")


def periodos(meses: int | None = 3, desde: int = 2018, hoy: date | None = None) -> list[str]:
    hoy = hoy or date.today()
    if meses is not None:
        out, y, m = [], hoy.year, hoy.month
        for _ in range(meses + 1):  # el mes en curso (parcial) + los N anteriores
            out.append(f"{y}{m:02d}")
            y, m = (y, m - 1) if m > 1 else (y - 1, 12)
        return sorted(out)
    return [str(a) for a in range(desde, hoy.year)] + [f"{hoy.year}{m:02d}" for m in range(1, hoy.month + 1)]


def _ejecuta(meses, desde, conjuntos, cache_dir, nifs_extra, tmp_dir, workers):
    padron = leer_padron()
    nifs_padron = set(padron)
    nifs_extra = {norm_nif(n) for n in nifs_extra if n} - nifs_padron
    tmp = Path(tmp_dir or tempfile.gettempdir()) / "medios_contratos_zip"
    tmp.mkdir(parents=True, exist_ok=True)
    cache = Path(cache_dir) if cache_dir else None
    if cache:
        cache.mkdir(parents=True, exist_ok=True)
    todas, cobertura = [], []
    for periodo in periodos(meses, desde):
        for conjunto in conjuntos:
            if conjunto == "menores" and periodo < "2018":
                continue
            cf = cache / f"{conjunto}_{periodo}.json.gz" if cache else None
            if cf and cf.exists():
                with gzip.open(cf, "rt", encoding="utf-8") as fh:
                    d = json.load(fh)
                filas, st = d["filas"], d["stats"]
            else:
                zp = tmp / f"{conjunto}_{periodo}.zip"
                t0 = time.time()
                if not descarga(_url(conjunto, periodo), zp):
                    log.info("%s %s: no publicado", conjunto, periodo)
                    continue
                mb = zp.stat().st_size / 2**20
                try:
                    filas, st = procesa_zip(str(zp), conjunto, nifs_padron, nifs_extra, workers)
                finally:
                    zp.unlink(missing_ok=True)
                st.update(mb=round(mb, 1), segundos_descarga=round(time.time() - t0) - st["segundos"])
                if cf:
                    with gzip.open(cf, "wt", encoding="utf-8") as fh:
                        json.dump({"filas": filas, "stats": st}, fh)
            # reclasifica con el padrón vigente (la caché pudo hacerse con otro)
            for f in filas:
                f["clase"] = "padron" if f["nif_adjudicatario"] in nifs_padron else "candidato"
            st = dict(st, filas_padron=sum(f["clase"] == "padron" for f in filas),
                      filas_candidatos=sum(f["clase"] == "candidato" for f in filas))
            log.info("%s %s: %s", conjunto, periodo, st)
            print(f"[medios_contratos] {conjunto} {periodo}: {st}", flush=True)
            for f in filas:
                f["fichero_periodo"] = periodo
            todas.extend(filas)
            cobertura.append(dict(id_conjunto=conjunto, periodo=periodo,
                                  cargado_en=datetime.now(timezone.utc).isoformat(), **st))
    todas = _dedup(todas)
    _enriquece(todas)
    return todas, cobertura


# --- Nivel administrativo y territorio --------------------------------------------
_ORGANOS: dict[str, dict] = {}


def organos_registro() -> list[dict]:
    """Registro de órganos de contratación de PLACSP (xlsx, cabecera en la fila 6)."""
    import openpyxl
    r = requests.get(URL_ORGANOS, timeout=(30, 180), headers=CABECERAS)
    r.raise_for_status()
    wb = openpyxl.load_workbook(io.BytesIO(r.content), read_only=True, data_only=True)
    ws = wb.worksheets[0]
    filas, cab = [], None
    for row in ws.iter_rows(values_only=True):
        vals = [None if v is None else str(v).strip() for v in row]
        if cab is None:
            if vals and "ID Plataforma" in vals:
                cab = vals
            continue
        d = dict(zip(cab, vals))
        if not d.get("ID Plataforma"):
            continue
        idp = d["ID Plataforma"]
        try:
            idp = str(int(float(idp)))
        except ValueError:
            pass
        filas.append(dict(
            id_plataforma=idp, nombre=d.get("Nombre Órgano Contratación"),
            ubicacion=d.get("Ubicación sector público"), dependencia_1=d.get("Dependencia primer nivel"),
            dependencia_2=d.get("Dependencia segundo nivel"), nif=norm_nif(d.get("NIF")), dir3=d.get("DIR3"),
            codigo_postal=d.get("Código Postal"), medio_propio=d.get("Medio Propio"), activo=d.get("Activo / Inactivo")))
    return filas


def _registro():
    if not _ORGANOS:
        try:
            for o in organos_registro():
                _ORGANOS[o["id_plataforma"]] = o
                if o.get("dir3"):
                    _ORGANOS.setdefault("dir3:" + o["dir3"], o)
                if o.get("nif"):
                    _ORGANOS.setdefault("nif:" + o["nif"], o)
        except Exception as e:  # noqa: BLE001
            log.warning("Registro de órganos no disponible: %s", e)
            _ORGANOS["_"] = {}
    return _ORGANOS


def _ccaa_texto(texto):
    t = (texto or "").lower()
    for rx, c in CCAA_NOMBRES:
        if re.search(rx, t):
            return c
    return None


def nivel_organo(f, reg=None):
    """(nivel, ambito, cod_ccaa, cod_municipio)
    nivel: estatal | autonomico | local | empresa_publica | otro
    ambito (administración de la que depende): estatal | autonomico | local | otro"""
    reg = reg or {}
    padres = (f.get("organo_padres") or "")
    nombre = f.get("organo") or ""
    texto = (padres + " > " + nombre)
    up = norm(texto)
    code = f.get("tipo_organo_code")
    dir3s = [d for d in [f.get("dir3")] + (f.get("organo_padres_dir3") or "").split(" > ") if d]
    o = (reg.get(f.get("id_plataforma_organo") or "") or reg.get("dir3:" + (f.get("dir3") or ""))
         or reg.get("nif:" + (f.get("nif_organo") or "")) or {})
    if o.get("dir3") and o["dir3"] not in dir3s:
        dir3s.append(o["dir3"])
    ubic = norm(o.get("ubicacion")) + " " + norm(o.get("dependencia_1"))
    segmentos = {norm(x) for x in padres.split(" > ")}
    nivel = ambito = None
    if "SOCIEDADES, FUNDACIONES Y CONSORCIOS ESTATALES" in up or "CONSORCIOS ESTATALES" in ubic:
        nivel, ambito = "empresa_publica", "estatal"
    elif "SOCIEDADES, FUNDACIONES Y CONSORCIOS COMUNIDADES" in up or "CONSORCIOS COMUNIDADES" in ubic:
        nivel, ambito = "empresa_publica", "autonomico"
    elif "SOCIEDADES, FUNDACIONES Y CONSORCIOS ENTIDADES LOCALES" in up or "CONSORCIOS ENTIDADES LOCALES" in ubic:
        nivel, ambito = "empresa_publica", "local"
    elif segmentos & {"UNIVERSIDADES", "INSTITUCIONES INDEPENDIENTES"} or "MUTUAS DE ACCIDENTES" in up             or ubic.startswith("OTRAS ENTIDADES") and re.search(r"UNIVERSIDAD|INSTITUCIONES", norm(o.get("dependencia_1"))):
        nivel, ambito = "otro", "otro"
    elif "ENTIDADES LOCALES" in up or ubic.startswith("ENTIDADES LOCALES"):
        nivel, ambito = "local", "local"
    elif "COMUNIDADES Y CIUDADES AUTONOMAS" in up or ubic.startswith("COMUNIDADES Y CIUDADES"):
        nivel, ambito = "autonomico", "autonomico"
    elif "ADMINISTRACION GENERAL DEL ESTADO" in up or ubic.startswith("ADMINISTRACION GENERAL"):
        nivel, ambito = "estatal", "estatal"
    elif code in ("1",):
        nivel, ambito = "estatal", "estatal"
    elif code in ("2",):
        nivel, ambito = "autonomico", "autonomico"
    elif code in ("3",):
        nivel, ambito = "local", "local"
    elif code in ("9", "6"):
        nivel, ambito = "empresa_publica", "estatal"
    elif code in ("10", "7"):
        nivel, ambito = "empresa_publica", "autonomico"
    elif code in ("11", "8"):
        nivel, ambito = "empresa_publica", "local"
    elif f.get("id_conjunto") == "agregadas":
        if re.search(r"(?i)administraci[oó] local|ajuntament|ayuntamiento|udala|concello|diputaci|consell comarcal|"
                     r"mancomun|cabildo|foru aldundia|municipal|entitats de l.administraci|consorci", texto):
            nivel, ambito = "local", "local"
        elif re.search(r"(?i)universi", texto):
            nivel, ambito = "otro", "otro"
        elif re.search(r"(?i)\bS\.?A\.?U?\b|S\.L\.|sociedad|societat|fundaci|empresa p|ente p|agencia p|entidad p|"
                       r"consorcio|ens p[uú]blic|institut catal|ferrocarrils|metro de|canal de isabel|radio|televisi", nombre):
            nivel, ambito = "empresa_publica", "autonomico"
        else:
            nivel, ambito = "autonomico", "autonomico"
    else:
        d0 = dir3s[0] if dir3s else ""
        if d0.startswith("L"):
            nivel, ambito = "local", "local"
        elif d0.startswith("A"):
            nivel, ambito = "autonomico", "autonomico"
        elif d0.startswith("E"):
            nivel, ambito = "estatal", "estatal"
        else:
            nivel, ambito = "otro", "otro"
    # municipio y comunidad
    cod_mun = None
    for d in dir3s:
        if re.fullmatch(r"L01\d{6}", d):
            cod_mun = d[3:8]
            break
    nif_o = f.get("nif_organo") or o.get("nif") or ""
    if not cod_mun and ambito == "local" and re.fullmatch(r"P\d{5}00[A-Z]", nif_o) and nif_o[3:6] != "000":
        cod_mun = nif_o[1:6]  # NIF de ayuntamiento: P + código INE + 00 + control
    cod_ccaa = None
    if cod_mun:
        cod_ccaa = PROV_CCAA.get(cod_mun[:2])
    if not cod_ccaa:
        for d in dir3s:
            if re.fullmatch(r"A(0[1-9]|1[0-9])\d+", d):
                cod_ccaa = d[1:3]
                break
            if re.fullmatch(r"L0[23]\d{6}", d) and d[-2:] in PROV_CCAA:
                cod_ccaa = PROV_CCAA[d[-2:]]  # diputación / cabildo: L02 0000 + provincia
                break
    if not cod_ccaa and ambito in ("autonomico", "local"):
        cod_ccaa = _ccaa_texto(padres) or None
    if not cod_ccaa and f.get("id_conjunto") == "agregadas":
        t = ((f.get("plataforma") or "") + " " + (f.get("url") or "")).lower()
        for rx, c in PLATAFORMA_CCAA:
            if re.search(rx, t):
                cod_ccaa = c
                break
    if not cod_ccaa:
        cp = re.sub(r"\D", "", f.get("organo_cp") or o.get("codigo_postal") or "")
        if len(cp) == 5:
            cod_ccaa = PROV_CCAA.get(cp[:2])
    return nivel, ambito, cod_ccaa, cod_mun


def _enriquece(filas):
    reg = _registro() if filas else {}
    for f in filas:
        f["nivel"], f["ambito"], f["cod_ccaa"], f["cod_municipio"] = nivel_organo(f, reg)
        fa, fu = (f.get("fecha_adjudicacion") or "")[:10], (f.get("fecha_actualizacion") or "")[:10]
        # erratas de AwardDate (años 16, 202, 2105...): se usa la fecha de actualización
        f["fecha_referencia"] = (fa if re.fullmatch(r"20[1-9]\d-\d\d-\d\d", fa) and fa[:4] <= fu[:4] else fu) or None
        f["anio"] = int(f["fecha_referencia"][:4]) if f.get("fecha_referencia") else None


# --- Fuente dlt --------------------------------------------------------------------
COLUMNAS = {
    "importe_adjudicado_sin_iva": {"data_type": "double"},
    "importe_adjudicado_con_iva": {"data_type": "double"},
    "presupuesto_sin_iva": {"data_type": "double"},
    "valor_estimado": {"data_type": "double"},
    "n_ofertas": {"data_type": "double"},
    "anio": {"data_type": "bigint"},
    "cod_municipio": {"data_type": "text"},
    "cod_ccaa": {"data_type": "text"},
    "fecha_adjudicacion": {"data_type": "text"},
    "fecha_referencia": {"data_type": "text"},
    "cpv_lote": {"data_type": "text"},
    "dir3": {"data_type": "text"},
    "organo_padres": {"data_type": "text"},
    "organo_padres_dir3": {"data_type": "text"},
    "id_oc_plat": {"data_type": "text"},
    "plataforma": {"data_type": "text"},
    "id_plataforma_organo": {"data_type": "text"},
    "nif_organo": {"data_type": "text"},
    "tipo_organo_code": {"data_type": "text"},
    "organo_cp": {"data_type": "text"},
    "organo_ciudad": {"data_type": "text"},
    "subtipo_contrato": {"data_type": "text"},
}


@dlt.source(name="medios_contratos")
def medios_contratos(meses: int | None = 3, desde: int = 2018, conjuntos: tuple = ("perfiles", "agregadas", "menores"),
                     cache_dir: str | None = None, nifs_extra: tuple = (), tmp_dir: str | None = None,
                     workers: int | None = None, organos: bool = True):
    memo = {}

    def datos():
        if "r" not in memo:
            memo["r"] = _ejecuta(meses, desde, conjuntos, cache_dir, nifs_extra, tmp_dir, workers)
        return memo["r"]

    @dlt.resource(name="pcsp_contratos_medios", write_disposition="merge", primary_key=CLAVE, columns=COLUMNAS)
    def pcsp_contratos_medios():
        yield [f for f in datos()[0] if f["clase"] == "padron"]

    @dlt.resource(name="pcsp_candidatos_medios", write_disposition="merge", primary_key=CLAVE, columns=COLUMNAS)
    def pcsp_candidatos_medios():
        yield [f for f in datos()[0] if f["clase"] == "candidato"]

    @dlt.resource(name="pcsp_cobertura", write_disposition="merge", primary_key=["id_conjunto", "periodo"])
    def pcsp_cobertura():
        yield datos()[1]

    @dlt.resource(name="pcsp_organos", write_disposition="replace")
    def pcsp_organos():
        reg = _registro()
        yield [o for k, o in reg.items() if k == o.get("id_plataforma")] if "_" not in reg else []

    res = [pcsp_contratos_medios, pcsp_candidatos_medios, pcsp_cobertura]
    if organos:
        res.append(pcsp_organos)
    return res
