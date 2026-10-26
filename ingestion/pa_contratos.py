"""Fuente dlt «Índice propio de publicidad activa: contratación» (tema `pa_contratos`).

Elaboración propia de SpainFacts. Mide, por órgano de contratación, año y
obligación, cuántos anuncios del perfil del contratante se publican fuera del
plazo legal (Ley 9/2017, de Contratos del Sector Público, LCSP):

  contratos_adjudicacion   anuncio de adjudicación en el perfil en 15 días
                           desde la adjudicación (art. 151.1 LCSP)
  contratos_formalizacion  anuncio de formalización en el perfil en 15 días
                           desde la formalización (art. 154.1 LCSP)
  contratos_menores        menores publicados «al menos trimestralmente»
                           (art. 63.4 LCSP). Regla interpretativa propia, por
                           analogía con el art. 154.4 (contratos basados en
                           acuerdos marco: «dentro de los 30 días siguientes
                           al fin de cada trimestre»): fuera de plazo si se
                           publica después del último día del mes siguiente
                           al cierre del trimestre de adjudicación.

Fuentes
  PLACSP (Ministerio de Hacienda), sindicación Atom + CODICE, los tres conjuntos
  que ya descarga `medios_contratos` (perfiles, agregadas, menores), y su
  registro de órganos (OrganosContratacion.xlsx). Se reutilizan su descarga en
  serie (el WAF bloquea peticiones en paralelo) y su parser.
  Cataluña: PSCP de la Generalitat (Socrata ybgg-dgi6), agregada en el servidor
  con SoQL ($group por órgano y expediente), porque sus entidades no publican
  en PLACSP y la agregación de PLACSP no trae menores ni fecha de adjudicación.

Método PLACSP (dos fases)
  1. Cada ZIP (anual o mensual) se lee en streaming y en paralelo por fichero
     .atom y se reduce a una fila compacta por entrada (expediente): órgano
     (NIF, DIR3, ID de plataforma, cadena de dependencias), fecha del hecho
     (primera AwardDate y primera Contract/IssueDate de sus TenderResult) y
     fecha del primer anuncio DOC_CAN_ADJ / DOC_FORM en el medio «Perfil del
     contratante». Las `deleted-entry` se guardan como bajas. El resultado de
     cada ZIP se guarda en `cache_dir` (parquet) y no se vuelve a descargar.
  2. Con DuckDB: cada ZIP trae las ACTUALIZACIONES del periodo, así que un
     expediente reaparece en varios ficheros; se deduplica por (conjunto,
     id de la entrada) quedándose con la última versión (`updated`), se quitan
     las anuladas y las borradas, se asigna el año por la fecha del hecho (no
     por el fichero) y se agrega por órgano, año y obligación.
  Ventana: el año `desde` hasta hoy. Solo se emiten años >= `desde` (un
  expediente no puede aparecer en ficheros anteriores a su hecho). Un año queda
  completo cuando la ventana incluye también el año siguiente (las
  publicaciones de diciembre llegan en enero).

Retraso = fecha del anuncio en el perfil − fecha del hecho, en días. Negativos
(anuncio con fecha anterior al hecho: errores de carga) -> 0 y se cuentan en
n_negativos. Sin anuncio en el perfil -> n_sin_anuncio (y cuenta como fuera de
plazo cuando el plazo ya venció). Solo cuentan los elementos cuyo plazo venció
antes de la fecha de corte (último `updated` leído); el resto, n_pendientes.

Entidad territorial del órgano (solo la administración matriz, por su NIF):
  Ayuntamiento  NIF del ayuntamiento (P + prov + mun + 00 + control) casado con
                el INE por los DIR3 L01 válidos del registro de órganos y de la
                propia sindicación; sin NIF, DIR3 L01 + INE de 5 cifras.
  Diputación    NIF P + prov + 00000 + control, o DIR3 L02 sin NIF.
  Cabildo/consell  NIF de los órganos con DIR3 L03 del registro.
  CCAA          DIR3 A01..A19 en el órgano o su cadena + NIF «S» (administración
                general) y cadena «COMUNIDADES Y CIUDADES AUTÓNOMAS» sin
                «SOCIEDADES, FUNDACIONES Y CONSORCIOS»; en la agregación (sin
                NIF), nivel autonómico según `nivel_organo` de medios_contratos.
  Organismos autónomos, consorcios, sociedades y fundaciones tienen NIF propio
  (y perfil propio) y NO se atribuyen a la entidad matriz.

Modos
  pa_contratos()                          año pasado + año en curso (mantenimiento)
  pa_contratos(desde=2024)                2024, 2025 y 2026
  pa_contratos(desde=2018)                histórico completo (≈12 GB, 2-3 h)
  pa_contratos(periodos_placsp=["202609"])  validación con un mes

Recursos
  pa_contratos_organos  (merge, pk fuente+obligacion+organo_clave+anio+cod_entidad; merge_key
                        fuente+anio: cada carga sustituye entero cada año recalculado)
                        n_total, n_fuera_plazo, n_sin_anuncio, n_negativos, n_pendientes,
                        n_sin_fecha, mediana_dias y dias_hist («dias:n,dias:n», tope 999) para
                        que dbt calcule la mediana por entidad sumando órganos
  pa_contratos_control  (merge, pk fuente+conjunto+periodo): MB, entradas, segundos y
                        recuento de entradas por método de atribución («atribucion|tipo|metodo»)
"""

from __future__ import annotations

import json
import logging
import os
import re
import tempfile
import time
import zipfile
from collections import Counter, defaultdict
from concurrent.futures import ProcessPoolExecutor
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from xml.etree import ElementTree as ET

import dlt

from ingestion.medios_contratos import (PROV_CCAA, _ccaa_texto, _ids, _kid, _kids, _ln, _path, _txt, _url, descarga,
                                        nivel_organo, norm_nif, organos_registro)

log = logging.getLogger(__name__)

URL_PLACSP = "https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx"
URL_PSCP = "https://analisi.transparenciacatalunya.cat/Sector-P-blic/Contractaci-p-blica-a-Catalunya-publicacions-a-la-/ybgg-dgi6"
SOCRATA = "https://analisi.transparenciacatalunya.cat/resource/ybgg-dgi6.json"
CONJUNTOS = ("perfiles", "agregadas", "menores")
TOPE_DIAS = 999  # el histograma agrupa en 999 los retrasos mayores
PLAZO_DIAS = 15
CLAVE = ["fuente", "obligacion", "organo_clave", "anio"]

# Columnas de la fila compacta de la fase 1 (una por entrada de la sindicación)
COLS = ["conjunto", "fichero", "entry_id", "borrada", "updated", "expediente", "nif", "dir3", "id_plat", "id_oc_plat",
        "organo", "plataforma", "cp", "tipo_code", "padres", "padres_dir3", "estado", "procedimiento", "sistema",
        "n_resultados", "fecha_adj", "fecha_form", "pub_adj", "pub_adj_otro", "pub_form", "pub_form_otro"]


# --- Fase 1: una fila compacta por entrada -----------------------------------------
def _fecha(s):
    """AAAA-MM-DD válida y razonable (2000..2100) o None."""
    if not s or not re.match(r"\d{4}-\d\d-\d\d", s):
        return None
    try:
        d = date.fromisoformat(s[:10])
    except ValueError:
        return None
    return s[:10] if 2000 <= d.year <= 2100 else None


def _min(a, b):
    return b if a is None or (b is not None and b < a) else a


def _fila(en, conjunto, fichero):
    cfs = _kid(en, "ContractFolderStatus")
    if cfs is None:
        return None
    lcp = _kid(cfs, "LocatedContractingParty")
    party = _kid(lcp, "Party")
    oids = _ids(party)
    chain, dir3s = [], []
    p = _kid(lcp, "ParentLocatedParty")
    while p is not None:
        chain.append(_txt(_path(p, "PartyName", "Name")) or "")
        d = _ids(p).get("DIR3")
        if d:
            dir3s.append(d)
        p = _kid(p, "ParentLocatedParty")
    fadj = fform = None
    trs = _kids(cfs, "TenderResult")
    for tr in trs:
        fadj = _min(fadj, _fecha(_txt(_kid(tr, "AwardDate"))))
        fform = _min(fform, _fecha(_txt(_path(tr, "Contract", "IssueDate"))))
    pubs = {}
    for v in _kids(cfs, "ValidNoticeInfo"):
        t = _txt(_kid(v, "NoticeTypeCode"))
        if t not in ("DOC_CAN_ADJ", "DOC_FORM"):
            continue
        for a in _kids(v, "AdditionalPublicationStatus"):
            medio = (_txt(_kid(a, "PublicationMediaName")) or "").lower()
            k = (t, medio.startswith("perfil"))
            for ref in _kids(a, "AdditionalPublicationDocumentReference"):
                pubs[k] = _min(pubs.get(k), _fecha(_txt(_kid(ref, "IssueDate"))))
    tp = _kid(cfs, "TenderingProcess")
    return dict(
        conjunto=conjunto, fichero=fichero, entry_id=_txt(_kid(en, "id")), borrada=False,
        updated=_txt(_kid(en, "updated")), expediente=_txt(_kid(cfs, "ContractFolderID")),
        nif=norm_nif(oids.get("NIF")), dir3=oids.get("DIR3"), id_plat=oids.get("ID_PLATAFORMA"),
        id_oc_plat=oids.get("ID_OC_PLAT"), organo=_txt(_path(party, "PartyName", "Name")),
        plataforma=_txt(_path(party, "AgentParty", "PartyName", "Name")),
        cp=_txt(_path(party, "PostalAddress", "PostalZone")), tipo_code=_txt(_kid(lcp, "ContractingPartyTypeCode")),
        padres=" > ".join(chain) or None, padres_dir3=" > ".join(dir3s) or None,
        estado=_txt(_kid(cfs, "ContractFolderStatusCode")), procedimiento=_txt(_kid(tp, "ProcedureCode")),
        sistema=_txt(_kid(tp, "ContractingSystemCode")), n_resultados=len(trs),
        fecha_adj=fadj, fecha_form=fform,
        pub_adj=pubs.get(("DOC_CAN_ADJ", True)), pub_adj_otro=pubs.get(("DOC_CAN_ADJ", False)),
        pub_form=pubs.get(("DOC_FORM", True)), pub_form_otro=pubs.get(("DOC_FORM", False)),
    )


def _procesa_atoms(args):
    zpath, nombres, conjunto, fichero = args
    filas = []
    with zipfile.ZipFile(zpath) as z:
        for name in nombres:
            with z.open(name) as fh:
                for _, el in ET.iterparse(fh, events=("end",)):
                    t = _ln(el.tag)
                    if t == "entry":
                        f = _fila(el, conjunto, fichero)
                        if f:
                            filas.append(f)
                        el.clear()
                    elif t == "deleted-entry":
                        filas.append(dict(conjunto=conjunto, fichero=fichero, entry_id=el.get("ref"), borrada=True,
                                          updated=el.get("when")))
                        el.clear()
    return filas


def extrae_zip(zpath, conjunto, fichero, workers=None):
    """Lee un ZIP de PLACSP y devuelve sus filas compactas (lista de dict)."""
    with zipfile.ZipFile(zpath) as z:
        atoms = [n for n in z.namelist() if n.endswith(".atom")]
    workers = workers or max(1, min(16, (os.cpu_count() or 2) - 2))
    lotes = [(zpath, atoms[i:i + 8], conjunto, fichero) for i in range(0, len(atoms), 8)]
    filas = []
    if workers == 1 or len(lotes) == 1:
        for r in map(_procesa_atoms, lotes):
            filas.extend(r)
    else:
        with ProcessPoolExecutor(workers) as ex:
            for r in ex.map(_procesa_atoms, lotes):
                filas.extend(r)
    return filas


def _a_parquet(filas, ruta: Path):
    import pyarrow as pa
    import pyarrow.parquet as pq
    cols = {c: [f.get(c) for f in filas] for c in COLS}
    tipos = {c: pa.string() for c in COLS}
    tipos["borrada"] = pa.bool_()
    tipos["n_resultados"] = pa.int32()
    t = pa.table({c: pa.array(cols[c], type=tipos[c]) for c in COLS})
    tmp = ruta.with_suffix(".tmp")
    pq.write_table(t, tmp, compression="zstd")
    tmp.replace(ruta)


def lista_periodos(desde: int | None = None, hoy: date | None = None) -> list[str]:
    """Ficheros de PLACSP: anuales de `desde` al año pasado + mensuales del año en curso.
    Por defecto `desde` = año pasado (mantenimiento: recalcula el año cerrado y el en curso)."""
    hoy = hoy or date.today()
    desde = desde or hoy.year - 1
    return [str(a) for a in range(desde, hoy.year)] + [f"{hoy.year}{m:02d}" for m in range(1, hoy.month + 1)]


def fase1(periodos, conjuntos=CONJUNTOS, cache_dir=None, tmp_dir=None, workers=None, refrescar_mes_en_curso=True):
    """Descarga (en serie) y reduce cada ZIP a un parquet en cache_dir. Devuelve (parquets, control)."""
    cache = Path(cache_dir or Path(tempfile.gettempdir()) / "pa_contratos_cache")
    cache.mkdir(parents=True, exist_ok=True)
    tmp = Path(tmp_dir or tempfile.gettempdir()) / "pa_contratos_zip"
    tmp.mkdir(parents=True, exist_ok=True)
    mes_actual = date.today().strftime("%Y%m")
    rutas, control = [], []
    for periodo in periodos:
        for conjunto in conjuntos:
            if conjunto == "menores" and periodo < "2018":
                continue
            pq = cache / f"{conjunto}_{periodo}.parquet"
            meta = cache / f"{conjunto}_{periodo}.json"
            # el mes en curso (y el anterior, que aún puede cambiar) se vuelve a leer
            vivo = refrescar_mes_en_curso and len(periodo) == 6 and periodo >= _mes_anterior(mes_actual)
            if pq.exists() and meta.exists() and not (vivo and _antiguedad_h(meta) > 20):
                rutas.append(str(pq))
                control.append(json.loads(meta.read_text(encoding="utf-8")))
                continue
            zp = tmp / f"{conjunto}_{periodo}.zip"
            t0 = time.time()
            if not descarga(_url(conjunto, periodo), zp):
                log.info("%s %s: no publicado", conjunto, periodo)
                continue
            mb = zp.stat().st_size / 2**20
            t1 = time.time()
            try:
                filas = extrae_zip(str(zp), conjunto, periodo, workers)
            finally:
                zp.unlink(missing_ok=True)
            _a_parquet(filas, pq)
            st = dict(fuente="placsp", conjunto=conjunto, periodo=periodo, mb=round(mb, 1), entradas=len(filas),
                      borradas=sum(bool(f.get("borrada")) for f in filas), segundos_descarga=round(t1 - t0),
                      segundos_proceso=round(time.time() - t1), cargado_en=datetime.now(timezone.utc).isoformat())
            meta.write_text(json.dumps(st), encoding="utf-8")
            print(f"[pa_contratos] {conjunto} {periodo}: {st}", flush=True)
            rutas.append(str(pq))
            control.append(st)
    return rutas, control


def _mes_anterior(ym):
    y, m = int(ym[:4]), int(ym[4:])
    return f"{y}{m - 1:02d}" if m > 1 else f"{y - 1}12"


def _antiguedad_h(p: Path):
    return (time.time() - p.stat().st_mtime) / 3600


# --- Entidad territorial del órgano --------------------------------------------------
# Cabildos y consells insulares: DIR3 L03 -> NIF de la corporación (registro de órganos)
CABILDOS = {
    "L03070001": ("P0702400C", "Consell Insular de Formentera"),
    "L03070006": ("S0733001B", "Consell Insular d'Eivissa"),
    "L03070008": ("S0711002F", "Consell Insular de Mallorca"),
    "L03070009": ("S0733002J", "Consell Insular de Menorca"),
    "L03350002": ("P3500003C", "Cabildo Insular de Fuerteventura"),
    "L03350004": ("P3500001G", "Cabildo Insular de Gran Canaria"),
    "L03350007": ("P3500002E", "Cabildo Insular de Lanzarote"),
    "L03380003": ("P3800004H", "Cabildo Insular de La Gomera"),
    "L03380005": ("P3800003J", "Cabildo Insular de El Hierro"),
    "L03380010": ("P3800002B", "Cabildo Insular de La Palma"),
    "L03380011": ("P3800001D", "Cabildo Insular de Tenerife"),
}
RE_NIF_AYTO = re.compile(r"P(\d{2})(?!000)\d{3}00[A-Z0-9]")
RE_NIF_DIP = re.compile(r"P(\d{2})00000[A-Z0-9]")
RE_L01 = re.compile(r"L01(\d{5})\d")
RE_L02 = re.compile(r"L020000(\d{2})")
RE_A = re.compile(r"A(0[1-9]|1[0-9])\d{6,7}")
CEUTA_MELILLA = {"51001": "C18", "52001": "C19"}
RE_CCAA_CORE = re.compile(r"(?i)^\s*(conseller|consejer|conselh|kontseilu|vicepresiden|presiden|secretar|direcci|"
                          r"delegaci|viceconsejer|viceconseller|departament|servicio de |servizo de |gabinete)")
RE_CCAA_DEP = re.compile(r"(?i)agencia|axencia|ag[eè]ncia|instituto|institut\b|\bente\b|empresa|sociedad|sociedade|"
                         r"\bS\.?A\.?U?\b|S\.L\.|fundaci|consorci|hospital|servicio \w+ de salud|"
                         r"servizo galego de sa[uú]de|SERGAS|SERMAS|osakidetza")
RE_ORGANO_AYTO = re.compile(r"(?i)ayuntamiento|alcald|concello|ajuntament|udala|pleno|junta de gobierno|concejal|"
                            r"tenencia de alcald|teniente de alcalde")
RE_DEPENDIENTE = re.compile(r"(?i)organismo|patronato|instituto|fundaci|gerencia|consorcio|empresa|sociedad|"
                            r"agencia|mancomunidad|entidad local|\b(?:ela|e\.l\.a\.?)\b|eatim|consejo rector|consejo de administraci|"
                            r"junta vecinal|junta administrativa|comarca")


def cod_cabildo(dir3):
    return "I" + dir3[3:5] + dir3[6:9]


# Relación de municipios del INE: dígito de control (valida los DIR3 L01 = L01 + INE + DC)
# y nombres (casa por nombre los NIF de ayuntamiento que nunca traen un DIR3 válido)
URL_INE_DICC = "https://www.ine.es/daco/daco42/codmun/diccionario{yy}.xlsx"
_INE: dict = {}
_ARTICULOS = r"(el|la|los|las|l|o|a|os|as|es|sa|ses|els|lo|les|en|na)"


def clave_nombre(s):
    """Clave de comparación de nombres de municipio: sin tildes, sin artículos (delante o
    detrás, «Pobla de Vallbona, la»), solo letras y números."""
    import unicodedata
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    s = re.sub(rf",\s*{_ARTICULOS}\s*'?\s*$", "", s.strip())
    s = re.sub(rf"^{_ARTICULOS}(\s+|')", "", s)
    return re.sub(r"[^a-z0-9]", "", s)


def municipios_ine():
    """{'dc': {ine: dc}, 'nombres': {(prov, clave): ine}} o {} si no se puede descargar."""
    if _INE:
        return _INE
    import io

    import openpyxl
    import requests
    hoy = date.today()
    for yy in (hoy.year % 100, hoy.year % 100 - 1):
        try:
            r = requests.get(URL_INE_DICC.format(yy=f"{yy:02d}"), timeout=(30, 120))
            if r.status_code != 200:
                continue
            ws = openpyxl.load_workbook(io.BytesIO(r.content), read_only=True).worksheets[0]
            dc, nombres, repes = {}, {}, set()
            for row in ws.iter_rows(values_only=True):
                if not row or not (row[1] and row[2] and str(row[1]).isdigit() and str(row[2]).isdigit()):
                    continue
                ine = f"{int(row[1]):02d}{int(row[2]):03d}"
                dc[ine] = str(row[3])
                for variante in str(row[4]).split("/"):
                    k = (ine[:2], clave_nombre(variante))
                    if k in nombres and nombres[k] != ine:
                        repes.add(k)
                    nombres[k] = ine
            for k in repes:
                nombres.pop(k, None)
            _INE.update(dc=dc, nombres=nombres)
            log.info("Relación de municipios del INE 20%02d: %d municipios", yy, len(dc))
            return _INE
        except Exception as e:  # noqa: BLE001
            log.warning("Relación de municipios del INE no disponible: %s", e)
    return _INE


def _ine_l01(d):
    d = re.sub(r"^LO1", "L01", d or "")  # errata frecuente: letra O en lugar de cero
    m = RE_L01.fullmatch(d)
    if not m or m.group(1)[:2] not in PROV_CCAA:
        return None
    dc = _INE.get("dc")
    if dc and dc.get(m.group(1)) != d[-1]:  # INE inexistente o dígito de control erróneo
        return None
    return m.group(1)


def _ine_por_nombre(o, prov):
    """INE del municipio por el nombre de la cadena («Illescas > Ayuntamientos > Toledo»)."""
    nombres = _INE.get("nombres")
    if not nombres:
        return None
    partes = [x.strip() for x in (o.get("padres") or "").split(" > ")]
    cand = []
    if len(partes) > 1 and partes[1].lower() == "ayuntamientos":
        cand.append(partes[0])
    m = re.search(r"(?i)\b(?:ayuntamiento|concello|ajuntament|udala)\s+(?:de|d'|del)\s*(.+)$", o.get("organo") or "")
    if m:
        cand.append(m.group(1))
    for c in cand:
        ine = nombres.get((prov, clave_nombre(c)))
        if ine:
            return ine
    return None


def mapa_nif_ine(pares):
    """NIF de ayuntamiento -> INE, por votos de pares (nif, dir3) con DIR3 L01 válido y
    la misma provincia en el NIF y en el DIR3."""
    votos = defaultdict(Counter)
    for nif, d3 in pares:
        ine = _ine_l01(d3)
        m = RE_NIF_AYTO.fullmatch(nif or "")
        if ine and m and m.group(1) == ine[:2]:
            votos[nif][ine] += 1
    return {nif: c.most_common(1)[0][0] for nif, c in votos.items()}


def entidad(o, nif_ine, ine_nif):
    """(tipo_entidad, cod_entidad, metodo) del órgano, o (None, None, motivo)."""
    nif, d3 = o.get("nif"), o.get("dir3") or ""
    padres = (o.get("padres") or "").upper()
    padres_d3 = [x for x in (o.get("padres_dir3") or "").split(" > ") if x]
    sociedad = "SOCIEDADES, FUNDACIONES Y CONSORCIOS" in padres
    # Formentera: el Consell Insular es también el ayuntamiento (como en PMP_NET, va al 07024)
    if nif == CABILDOS["L03070001"][0] or (not nif and d3 == "L03070001"):
        return "Ayuntamiento", "07024", "formentera"
    for k, (n, _) in CABILDOS.items():
        if nif == n or (not nif and d3 == k):
            return "Cabildo o consell insular", cod_cabildo(k), "nif" if nif else "dir3"
    if nif:
        if nif in nif_ine:
            ine = nif_ine[nif]
            if ine in CEUTA_MELILLA:
                return "Comunidad autónoma", CEUTA_MELILLA[ine], "nif"
            return "Ayuntamiento", ine, "nif"
        m = RE_NIF_DIP.fullmatch(nif)
        if m and m.group(1) in PROV_CCAA:
            return "Diputación provincial", "D" + m.group(1), "nif"
        m = RE_NIF_AYTO.fullmatch(nif)
        if m and (RE_DEPENDIENTE.search(o.get("organo") or "")
                  or RE_DEPENDIENTE.search((o.get("padres") or "").split(" > ")[0])):
            return None, None, "nif_ayto_entidad_menor_u_otra"  # EATIM, mancomunidad... con NIF de forma municipal
        if m:
            # NIF de ayuntamiento que nunca aparece con un DIR3 L01 válido: DIR3 del propio
            # órgano, nombre del municipio en la cadena o, por último, los dígitos del NIF
            # (coinciden con el INE salvo excepciones: solo si ese INE no tiene ya otro NIF)
            ine = _ine_l01(d3)
            if ine and ine[:2] == m.group(1):
                metodo = "nif_dir3"
            else:
                ine = _ine_por_nombre(o, m.group(1))
                metodo = "nif_nombre"
                if not ine:
                    ine, metodo = nif[1:6], "nif_digitos"
                    if ine_nif.get(ine, nif) != nif or (_INE.get("dc") and ine not in _INE["dc"]):
                        return None, None, "nif_ayto_sin_ine"
            if ine in CEUTA_MELILLA:
                return "Comunidad autónoma", CEUTA_MELILLA[ine], metodo
            return "Ayuntamiento", ine, metodo
        if nif.startswith("S") and not sociedad and "COMUNIDADES Y CIUDADES AUT" in padres:
            for x in [d3] + padres_d3:
                m = RE_A.fullmatch(x)
                if m:
                    return "Comunidad autónoma", "C" + m.group(1), "nif_s_dir3"
            # sin DIR3 autonómico: comunidad por el nombre en la cadena («Junta de
            # Extremadura», «Ciudad Autónoma de Melilla»...) o por la provincia del NIF
            cc = _ccaa_texto(o.get("padres")) or PROV_CCAA.get(nif[1:3])
            if cc:
                return "Comunidad autónoma", "C" + cc, "nif_s_texto"
            return None, None, "ccaa_sin_dir3"
        # NIF fuera del patrón pero DIR3 L01 válido y órgano de gobierno del ayuntamiento
        # (municipios segregados con NIF P+prov+000+nn, p. ej. Pozo Cañada P0200010G)
        # (municipios nuevos o segregados con NIF P+prov+000+nn: Pozo Cañada, Cerdedo-Cotobade)
        nombre = o.get("organo") or ""
        primero = (o.get("padres") or "").split(" > ")[0]
        if nif.startswith("P") and RE_ORGANO_AYTO.search(nombre) and not RE_DEPENDIENTE.search(nombre) \
                and not RE_DEPENDIENTE.search(primero):
            ine, metodo = _ine_l01(d3), "dir3_nombre"
            if not ine and " > Ayuntamientos" in (o.get("padres") or ""):
                ine, metodo = _ine_por_nombre(o, nif[1:3]), "nombre"
            if ine:
                if ine in CEUTA_MELILLA:
                    return "Comunidad autónoma", CEUTA_MELILLA[ine], metodo
                return "Ayuntamiento", ine, metodo
        return None, None, "nif_otro"
    # sin NIF (plataformas agregadas): DIR3 del órgano o nivel autonómico
    ine = _ine_l01(d3)
    if ine:
        if ine in CEUTA_MELILLA:
            return "Comunidad autónoma", CEUTA_MELILLA[ine], "dir3"
        return "Ayuntamiento", ine, "dir3"
    m = RE_L02.fullmatch(d3)
    if m and m.group(1) in PROV_CCAA:
        return "Diputación provincial", "D" + m.group(1), "dir3"
    if o.get("conjunto") == "agregadas":
        # sin NIF: la administración general de la comunidad se reconoce por el nombre del
        # órgano (consejerías, direcciones generales, delegaciones...); agencias, servicios
        # de salud, hospitales, entes y sociedades quedan fuera, como en los perfiles
        nivel, _amb, cod_ccaa, _mun = nivel_organo(dict(
            o, id_conjunto="agregadas", organo_padres=o.get("padres"), organo_padres_dir3=o.get("padres_dir3"),
            organo_cp=o.get("cp"), tipo_organo_code=o.get("tipo_code"), id_plataforma_organo=o.get("id_plat")))
        m = RE_A.fullmatch(d3)
        cc = m.group(1) if m else cod_ccaa
        nombre = o.get("organo") or ""
        if cc and nivel != "local" and RE_CCAA_CORE.match(nombre) and not RE_CCAA_DEP.search(nombre):
            return "Comunidad autónoma", "C" + cc, "agregada_nombre"
        return None, None, "agregada_" + (nivel or "otro")
    m = RE_A.fullmatch(d3)
    if m and not sociedad and "COMUNIDADES Y CIUDADES AUT" in padres:
        return "Comunidad autónoma", "C" + m.group(1), "dir3"
    return None, None, "sin_nif"


# --- Fase 2: deduplicar y agregar -------------------------------------------------------
SQL_OBLIGACIONES = """
with base as (
    select u.*, m.tipo_entidad, m.cod_entidad,
        coalesce(u.id_plat, u.id_oc_plat, u.dir3, u.nif, u.organo) as organo_clave
    from u join mapa m on m.sig = u.sig
    where m.cod_entidad is not null and coalesce(u.estado, '') <> 'ANUL'
),
elementos as (
    -- adjudicación (art. 151.1): solo perfiles (la agregación no trae AwardDate)
    select 'contratos_adjudicacion' as obligacion, conjunto, organo_clave, tipo_entidad, cod_entidad, organo,
        fecha_adj::date as f, pub_adj::date as p, fecha_adj::date + 15 as plazo
    from base
    where conjunto = 'perfiles' and fecha_adj is not null
      and coalesce(sistema, '0') not in ('3', '4') and coalesce(procedimiento, '') not in ('7', '12')
    union all
    -- formalización (art. 154.1): perfiles y agregadas
    select 'contratos_formalizacion', conjunto, organo_clave, tipo_entidad, cod_entidad, organo,
        fecha_form::date, pub_form::date, fecha_form::date + 15
    from base
    where conjunto in ('perfiles', 'agregadas') and fecha_form is not null
      and coalesce(sistema, '0') not in ('3', '4') and coalesce(procedimiento, '') not in ('7', '12')
    union all
    -- menores (art. 63.4): último día del mes siguiente al cierre del trimestre de adjudicación
    select 'contratos_menores', conjunto, organo_clave, tipo_entidad, cod_entidad, organo,
        fecha_adj::date, coalesce(pub_adj, pub_adj_otro)::date,
        last_day(make_date(year(fecha_adj::date), 3 * quarter(fecha_adj::date), 1) + interval 1 month)::date
    from base
    where conjunto = 'menores' and fecha_adj is not null
),
marcados as (
    select *, year(f) as anio,
        plazo <= $corte::date as vencido,
        p is not null and p < f as negativo,
        least(greatest(p - f, 0), TOPE) as dias,
        -- menores sin fecha de anuncio: están publicados (vienen en la sindicación) pero sin
        -- fecha; no cuentan. En adjudicación y formalización, sin anuncio en el perfil = no consta
        obligacion = 'contratos_menores' and p is null as sin_fecha
    from elementos
    where year(f) between $desde and year($corte::date) and f <= $corte::date
),
hist as (
    select obligacion, organo_clave, cod_entidad, anio, dias, count(*) as n
    from marcados where vencido and p is not null group by all
),
hist_txt as (
    select obligacion, organo_clave, cod_entidad, anio, string_agg(dias || ':' || n, ',' order by dias) as dias_hist
    from hist group by all
)
select
    'placsp' as fuente, m.obligacion, m.organo_clave, m.cod_entidad, m.anio,
    any_value(m.tipo_entidad) as tipo_entidad, mode(m.organo) as organo,
    string_agg(distinct m.conjunto, ',') as conjuntos,
    count(*) filter (where m.vencido and not m.sin_fecha) as n_total,
    count(*) filter (where m.vencido and not m.sin_fecha and (m.p is null or m.p > m.plazo)) as n_fuera_plazo,
    count(*) filter (where m.vencido and m.p is null and not m.sin_fecha) as n_sin_anuncio,
    count(*) filter (where m.vencido and m.negativo) as n_negativos,
    count(*) filter (where not m.vencido) as n_pendientes,
    count(*) filter (where m.sin_fecha) as n_sin_fecha,
    median(m.dias) filter (where m.vencido and m.p is not null) as mediana_dias,
    min(m.f) as primera_fecha, max(m.f) as ultima_fecha,
    any_value(h.dias_hist) as dias_hist
from marcados m
left join hist_txt h using (obligacion, organo_clave, cod_entidad, anio)
group by m.obligacion, m.organo_clave, m.cod_entidad, m.anio
"""


def fase2(rutas, desde, registro=None):
    """Deduplica las filas compactas y agrega por órgano, año y obligación.
    Devuelve (filas, control, fecha_corte)."""
    import duckdb
    con = duckdb.connect()
    con.execute("set preserve_insertion_order = false")
    lista = "[" + ",".join("'" + r.replace("\\", "/").replace("'", "''") + "'" for r in rutas) + "]"
    con.execute(f"create table t as select * from read_parquet({lista})")
    # última versión de cada entrada; fuera las que acaban borradas
    con.execute("""
        create table u as
        select *, md5(concat_ws('|', conjunto, nif, dir3, id_plat, id_oc_plat, organo, plataforma, cp, tipo_code,
                                padres, padres_dir3)) as sig
        from t
        where entry_id is not null
        qualify row_number() over (partition by conjunto, entry_id
                                   order by try_cast(updated as timestamptz) desc nulls last, borrada desc) = 1
    """)
    con.execute("delete from u where borrada")
    corte = con.execute("select max(try_cast(updated as timestamptz))::date from t "
                        "where conjunto <> 'agregadas' and not borrada").fetchone()[0]
    # NIF -> INE con el registro de órganos y la propia sindicación
    municipios_ine()
    reg = registro if registro is not None else _registro_seguro()
    pares = [(o.get("nif"), o.get("dir3")) for o in reg]
    pares += con.execute("select nif, dir3 from u where nif is not null and dir3 like 'L01%'").fetchall()
    nif_ine = mapa_nif_ine(pares)
    ine_nif = {}
    for n, i in sorted(nif_ine.items()):
        ine_nif.setdefault(i, n)
    cols = ["sig", "conjunto", "nif", "dir3", "id_plat", "id_oc_plat", "organo", "plataforma", "cp", "tipo_code",
            "padres", "padres_dir3"]
    sigs = con.execute(f"select {', '.join(cols)}, count(*) from u group by all").fetchall()
    mapa, metodos = [], Counter()
    for r in sigs:
        o = dict(zip(cols, r[:-1]))
        tipo, cod, metodo = entidad(o, nif_ine, ine_nif)
        metodos[(o["conjunto"], tipo or "-", metodo)] += r[-1]
        mapa.append((o["sig"], tipo, cod))
    import pyarrow as pa
    mapa_pa = pa.table({k: pa.array([m[i] for m in mapa], type=pa.string())
                        for i, k in enumerate(("sig", "tipo_entidad", "cod_entidad"))})  # noqa: F841
    con.execute("create table mapa as select * from mapa_pa")
    res = con.execute(SQL_OBLIGACIONES.replace("TOPE", str(TOPE_DIAS)), {"corte": corte, "desde": desde})
    nombres = [d[0] for d in res.description]
    filas = [dict(zip(nombres, r)) for r in res.fetchall()]
    for f in filas:
        f["fecha_corte"] = corte
        f["mediana_dias"] = float(f["mediana_dias"]) if f["mediana_dias"] is not None else None
    control = [dict(fuente="placsp", conjunto=c, periodo=f"atribucion|{t}|{m}", entradas=n)
               for (c, t, m), n in metodos.items()]
    log.info("Fase 2: %d filas, corte %s", len(filas), corte)
    return filas, control, corte


def _registro_seguro():
    try:
        return organos_registro()
    except Exception as e:  # noqa: BLE001
        log.warning("Registro de órganos no disponible: %s", e)
        return []


# --- Cataluña: PSCP (Socrata ybgg-dgi6), agregada en el servidor ---------------------------
# Una fila del conjunto es un lote publicado. Los menores se publican casi todos de forma
# agregada («Publicació agregada de contractes», fecha data_publicacio_contracte); el resto
# de contratos tiene fecha de publicación de la adjudicación y de la formalización.
ORG_PSCP = "codi_organ, nom_organ, codi_ine10, codi_dir3, nom_ambit, nom_departament_ens"
NO_BASADOS = ("procediment is not null and procediment != 'Contracte menor' and es_agregada = 'NO' "
              "and (racionalitzacio_contractacio is null or (racionalitzacio_contractacio not like 'Contracte basat%' "
              "and racionalitzacio_contractacio not like 'Espec%'))")
NO_ANULADOS = "(fase_publicacio is null or fase_publicacio not like 'Anul%')"
RE_GENCAT_UNIDAD = re.compile(r"^(Centres educatius - Serveis Territorials|Serveis Territorials|Direcci[óo] General|"
                              r"Secretaria General|Secretaria d)")


def _soql(params):
    from ingestion.medios_contratos_ccaa import _socrata
    return _socrata("ybgg-dgi6", params)


def entidad_pscp(r, dir3_departaments=()):
    """(tipo_entidad, cod_entidad) del órgano de la PSCP o (None, None)."""
    ine10 = r.get("codi_ine10") or ""
    ambit = (r.get("nom_ambit") or "").lower()
    organ = r.get("nom_organ") or ""
    d3 = r.get("codi_dir3") or ""
    if "local" in ambit:
        if re.fullmatch(r"(08|17|25|43)\d{4}000\d", ine10):  # INE (5) + DC + 000 + control = el ayuntamiento
            return "Ayuntamiento", ine10[:5]
        m = RE_L02.fullmatch(d3)
        if organ.startswith("Diputaci") and m:
            return "Diputación provincial", "D" + m.group(1)
        return None, None
    if ambit.startswith("departaments"):
        dep = r.get("nom_departament_ens") or ""
        if organ.startswith("Departament") or (dep.startswith("Departament") and RE_GENCAT_UNIDAD.match(organ)) \
                or (d3 and d3 in dir3_departaments):
            return "Comunidad autónoma", "C09"
    return None, None


def _corte_pscp():
    from ingestion.medios_contratos_ccaa import _get
    try:
        meta = _get("https://analisi.transparenciacatalunya.cat/api/views/ybgg-dgi6.json").json()
        return datetime.fromtimestamp(meta["rowsUpdatedAt"], tz=timezone.utc).date()
    except Exception:  # noqa: BLE001
        return date.today() - timedelta(days=1)


def _plazo_menor(f: date) -> date:
    """Último día del mes siguiente al cierre del trimestre de adjudicación."""
    m = 3 * ((f.month - 1) // 3 + 1) + 1
    y = f.year + (m > 12)
    m = m - 12 if m > 12 else m
    return (date(y + (m == 12), 1 if m == 12 else m + 1, 1) - timedelta(days=1))


def _d(s):
    return date.fromisoformat(s[:10]) if s else None


def pscp(desde: int, hasta: int | None = None):
    """Filas agregadas por órgano, año y obligación para Cataluña (fuente 'pscp')."""
    corte = _corte_pscp()
    hasta = hasta or corte.year
    t0 = time.time()
    acum = {}  # (obligacion, organo_clave, cod_entidad, anio) -> dict
    hist = defaultdict(Counter)
    control = []

    def suma(obl, r, tipo, cod, anio, f, p, plazo, n=1, dias=None):
        k = (obl, r.get("codi_organ") or r.get("codi_ine10") or r.get("nom_organ"), cod, anio)
        a = acum.setdefault(k, dict(fuente="pscp", obligacion=obl, organo_clave=k[1], cod_entidad=cod, anio=anio,
                                    tipo_entidad=tipo, organo=r.get("nom_organ"), conjuntos="pscp", n_total=0,
                                    n_fuera_plazo=0, n_sin_anuncio=0, n_negativos=0, n_pendientes=0, n_sin_fecha=0,
                                    primera_fecha=None, ultima_fecha=None))
        if plazo > corte:
            a["n_pendientes"] += n
            return
        if p is None:
            a["n_total"] += n
            a["n_fuera_plazo"] += n
            a["n_sin_anuncio"] += n
            return
        a["n_total"] += n
        if p > plazo:
            a["n_fuera_plazo"] += n
        dd = (p - f).days if dias is None else dias
        if dd < 0:
            a["n_negativos"] += n
        hist[k][min(max(dd, 0), TOPE_DIAS)] += n
        a["primera_fecha"] = min(filter(None, [a["primera_fecha"], f]))
        a["ultima_fecha"] = max(filter(None, [a["ultima_fecha"], f]))

    for anio in range(desde, hasta + 1):
        ini, fin = f"{anio}-01-01T00:00:00", f"{anio}-12-31T23:59:59"
        # organos con actividad ese año: para la lista de DIR3 de los departamentos
        orgs = _soql({"$select": ORG_PSCP + ", count(*) as n", "$group": ORG_PSCP, "$order": ORG_PSCP,
                      "$where": f"data_adjudicacio_contracte between '{ini}' and '{fin}'"})
        d3dep = {o.get("codi_dir3") for o in orgs if (o.get("nom_organ") or "").startswith("Departament")
                 and (o.get("nom_ambit") or "").lower().startswith("departaments") and o.get("codi_dir3")}
        d3dep -= {None, "", "A99999999", "A999999999", "A9999999"}
        for obl, cf, cp in (("contratos_adjudicacion", "data_adjudicacio_contracte", "data_publicacio_adjudicacio"),
                            ("contratos_formalizacion", "data_formalitzacio_contracte", "data_publicacio_formalitzacio")):
            regs = _soql({"$select": f"{ORG_PSCP}, codi_expedient, min({cf}) as f, min({cp}) as p",
                          "$where": f"{NO_BASADOS} and {NO_ANULADOS} and {cf} between '{ini}' and '{fin}'",
                          "$group": f"{ORG_PSCP}, codi_expedient", "$order": f"{ORG_PSCP}, codi_expedient"})
            for r in regs:
                tipo, cod = entidad_pscp(r, d3dep)
                f = _d(r.get("f"))
                if not cod or not f or f > corte:
                    continue
                suma(obl, r, tipo, cod, anio, f, _d(r.get("p")), f + timedelta(days=PLAZO_DIAS))
            control.append(dict(fuente="pscp", conjunto=obl, periodo=str(anio), entradas=len(regs)))
        pub = "coalesce(data_publicacio_contracte, data_publicacio_adjudicacio)"
        regs = _soql({"$select": f"{ORG_PSCP}, date_trunc_ym(data_adjudicacio_contracte) as m_adj, "
                                 f"date_trunc_ym({pub}) as m_pub, date_diff_d({pub}, data_adjudicacio_contracte) as d, "
                                 "count(*) as n",
                      "$where": f"procediment = 'Contracte menor' and {NO_ANULADOS} and "
                                f"data_adjudicacio_contracte between '{ini}' and '{fin}'",
                      "$group": f"{ORG_PSCP}, m_adj, m_pub, d", "$order": f"{ORG_PSCP}, m_adj, m_pub, d"})
        for r in regs:
            tipo, cod = entidad_pscp(r, d3dep)
            m_adj = _d(r.get("m_adj"))
            if not cod or not m_adj:
                continue
            plazo = _plazo_menor(m_adj)
            n = int(r.get("n") or 0)
            if r.get("m_pub") is None:  # menor sin fecha de publicación: no cuenta (como en PLACSP)
                k = ("contratos_menores", r.get("codi_organ") or r.get("codi_ine10") or r.get("nom_organ"), cod, anio)
                suma("contratos_menores", r, tipo, cod, anio, m_adj, None, date.max, n=0)
                acum[k]["n_sin_fecha"] += n
                continue
            # con el mes de publicación basta para saber si pasa del último día del mes del plazo
            m_pub = _d(r.get("m_pub"))
            d = int(float(r.get("d")))
            suma("contratos_menores", r, tipo, cod, anio, m_adj, m_pub if m_pub > plazo.replace(day=1) else plazo,
                 plazo, n=n, dias=d)
        control.append(dict(fuente="pscp", conjunto="contratos_menores", periodo=str(anio), entradas=len(regs)))
        log.info("PSCP %s: %d órganos, %.0f s", anio, len(orgs), time.time() - t0)
    filas = []
    for k, a in acum.items():
        h = hist.get(k)
        a["dias_hist"] = ",".join(f"{d}:{n}" for d, n in sorted(h.items())) if h else None
        a["mediana_dias"] = _mediana_hist(h) if h else None
        a["fecha_corte"] = corte
        filas.append(a)
    for c in control:
        c["cargado_en"] = datetime.now(timezone.utc).isoformat()
    return filas, control, corte


def _mediana_hist(h: Counter):
    """Mediana (como median() de DuckDB: media de los dos centrales si n es par)."""
    tot = sum(h.values())
    if not tot:
        return None
    orden = sorted(h.items())

    def kth(k):  # k-ésimo (0-based)
        acc = 0
        for d, n in orden:
            acc += n
            if acc > k:
                return d
    return (kth((tot - 1) // 2) + kth(tot // 2)) / 2


# --- Fuente dlt --------------------------------------------------------------------
COLUMNAS = {
    "fuente": {"data_type": "text"}, "obligacion": {"data_type": "text"}, "organo_clave": {"data_type": "text"},
    "cod_entidad": {"data_type": "text"}, "anio": {"data_type": "bigint"}, "tipo_entidad": {"data_type": "text"},
    "organo": {"data_type": "text"}, "conjuntos": {"data_type": "text"},
    "n_total": {"data_type": "bigint"}, "n_fuera_plazo": {"data_type": "bigint"},
    "n_sin_anuncio": {"data_type": "bigint"}, "n_negativos": {"data_type": "bigint"},
    "n_pendientes": {"data_type": "bigint"}, "n_sin_fecha": {"data_type": "bigint"},
    "mediana_dias": {"data_type": "double"}, "primera_fecha": {"data_type": "date"},
    "ultima_fecha": {"data_type": "date"}, "dias_hist": {"data_type": "text"}, "fecha_corte": {"data_type": "date"},
}


@dlt.source(name="pa_contratos")
def pa_contratos(desde: int | None = None, periodos_placsp: list | None = None, fuentes: tuple = ("placsp", "pscp"),
                 cache_dir: str | None = None, tmp_dir: str | None = None, workers: int | None = None):
    """desde: primer año (por defecto el año pasado). periodos_placsp: lista explícita de
    ficheros de PLACSP («2025», «202609»...) en lugar de los de la ventana."""
    desde = desde or date.today().year - 1
    memo = {}

    def datos():
        if "r" not in memo:
            filas, control = [], []
            if "placsp" in fuentes:
                per = periodos_placsp or lista_periodos(desde)
                rutas, ctl = fase1(per, cache_dir=cache_dir, tmp_dir=tmp_dir, workers=workers)
                d0 = min(int(p[:4]) for p in per) if periodos_placsp else desde
                f, ctl2, _ = fase2(rutas, d0)
                filas += f
                control += ctl + ctl2
            if "pscp" in fuentes:
                f, ctl, _ = pscp(desde)
                filas += f
                control += ctl
            memo["r"] = (filas, control)
        return memo["r"]

    # merge_key (fuente, anio): cada carga sustituye entero cada año que recalcula (un órgano que
    # cambia de entidad o deja de aparecer no deja filas viejas)
    @dlt.resource(name="pa_contratos_organos", write_disposition="merge", primary_key=CLAVE + ["cod_entidad"],
                  merge_key=["fuente", "anio"], columns=COLUMNAS)
    def pa_contratos_organos():
        yield datos()[0]

    @dlt.resource(name="pa_contratos_control", write_disposition="merge", primary_key=["fuente", "conjunto", "periodo"])
    def pa_contratos_control():
        yield datos()[1]

    return [pa_contratos_organos, pa_contratos_control]


if __name__ == "__main__":
    import argparse

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    ap = argparse.ArgumentParser(description="Índice propio de publicidad activa: contratación (PLACSP + PSCP)")
    ap.add_argument("--desde", type=int, default=None, help="primer año (por defecto, el año pasado)")
    ap.add_argument("--periodos", default=None, help="ficheros PLACSP separados por comas (p. ej. 202609)")
    ap.add_argument("--fuentes", default="placsp,pscp")
    ap.add_argument("--cache-dir", default=None)
    ap.add_argument("--tmp-dir", default=None)
    a = ap.parse_args()
    from ingestion.destino import pipeline

    src = pa_contratos(desde=a.desde, periodos_placsp=a.periodos.split(",") if a.periodos else None,
                       fuentes=tuple(a.fuentes.split(",")), cache_dir=a.cache_dir, tmp_dir=a.tmp_dir)
    print(pipeline("pa_contratos").run(src))
