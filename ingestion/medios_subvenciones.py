"""Fuente dlt para el bloque «Subvenciones a medios» (tema `medios_subvenciones`).

Base de Datos Nacional de Subvenciones (BDNS / SNPSAP, IGAE - Ministerio de
Hacienda), API REST pública sin clave:
  https://www.infosubvenciones.es/bdnstrans/api/   (spec: /bdnstrans/estaticos/doc/snpsap-api.json)

Método: lista curada de convocatorias de ayudas dirigidas a medios de
comunicación privados (seed transform/seeds/medios_subvenciones_convocatorias.csv,
filas con incluir = true). Por cada código BDNS:
  - GET /convocatorias?numConv=<cod>                      -> detalle (presupuesto, sectores...)
  - GET /concesiones/busqueda?numeroConvocatoria=<cod>     -> concesiones (pageSize 10000, paginado)

TRAMPA: la BDNS solo muestra las concesiones de los 4 últimos años naturales
(art. 20.8 LGS); hoy, desde 2022-01-01. Por eso los recursos son MERGE: lo que
la BDNS deje de enseñar se conserva en raw. Nunca cambiar a replace.

Personas físicas: la BDNS enmascara su NIF («***3548**»); aquí no se guarda su
nombre (null), solo cuentan en los agregados.

Recursos:
  bdns_concesiones_medios    (merge, pk cod_concesion)
  bdns_convocatorias_medios  (merge, pk cod_bdns)
"""

import csv
import logging
import re
import time
from datetime import datetime, timezone
from pathlib import Path

import dlt
import requests

log = logging.getLogger(__name__)

API = "https://www.infosubvenciones.es/bdnstrans/api/"
CABECERAS = {"User-Agent": "Mozilla/5.0 (spainfacts.org; datos abiertos)", "Accept": "application/json"}
SEED = Path(__file__).resolve().parent.parent / "transform" / "seeds" / "medios_subvenciones_convocatorias.csv"
PAGE_SIZE = 10000
RE_BENEF = re.compile(r"^\s*([A-Z0-9*]{7,10})\s+(.*)$")
# NIF de persona física: DNI (8 cifras + letra) o NIE (X/Y/Z + 7 cifras + letra), o enmascarado
RE_PF = re.compile(r"^(\*|\d{8}[A-Z]$|[XYZ]\d{7}[A-Z]$)")


def _get(ruta: str, **params):
    """GET con reintentos y espera creciente ante timeouts, 5xx o «ERR_MANTENIMIENTO_BBDD»."""
    params.setdefault("vpd", "GE")
    ultimo = None
    for intento in range(6):
        try:
            r = requests.get(API + ruta, params=params, headers=CABECERAS, timeout=90)
            r.raise_for_status()
            d = r.json()
            if isinstance(d, dict) and d.get("codigo"):
                raise RuntimeError(f"BDNS {d.get('codigo')}: {str(d.get('mensaje'))[:120]}")
            return d
        except Exception as e:  # noqa: BLE001
            ultimo = e
            espera = 10 * (intento + 1)
            log.warning("BDNS %s %s intento %d falló (%s); espero %ds", ruta, params, intento + 1, e, espera)
            time.sleep(espera)
    raise RuntimeError(f"BDNS {ruta} {params}: {ultimo}")


def convocatorias_incluidas() -> list[dict]:
    with open(SEED, encoding="utf-8") as f:
        filas = list(csv.DictReader(f))
    return [r for r in filas if str(r.get("incluir", "")).strip().lower() in ("true", "1", "t", "si", "sí")]


def _beneficiario(texto: str | None):
    texto = (texto or "").strip()
    m = RE_BENEF.match(texto)
    nif, nombre = (m.group(1), m.group(2).strip()) if m else (None, texto or None)
    es_pf = bool(nif and RE_PF.match(nif))
    return nif, (None if es_pf else nombre), es_pf


@dlt.source(name="medios_subvenciones")
def medios_subvenciones():
    lista = convocatorias_incluidas()
    ahora = datetime.now(timezone.utc).isoformat(timespec="seconds")

    @dlt.resource(name="bdns_convocatorias_medios", write_disposition="merge", primary_key="cod_bdns")
    def bdns_convocatorias_medios():
        for c in lista:
            cod = c["cod_bdns"].strip()
            d = _get("convocatorias", numConv=cod)
            organo = d.get("organo") or {}
            yield {
                "cod_bdns": cod,
                "id_convocatoria": d.get("id"),
                "titulo": d.get("descripcion"),
                "titulo_cooficial": d.get("descripcionLeng"),
                "fecha_recepcion": d.get("fechaRecepcion"),
                "presupuesto_total": float(d["presupuestoTotal"]) if d.get("presupuestoTotal") is not None else None,
                "mrr": d.get("mrr"),
                "tipo_convocatoria": d.get("tipoConvocatoria"),
                "sectores": ",".join(s.get("codigo") or "" for s in d.get("sectores") or []),
                "regiones": "; ".join(s.get("descripcion") or "" for s in d.get("regiones") or []),
                "tipos_beneficiarios": "; ".join(s.get("descripcion") or "" for s in d.get("tiposBeneficiarios") or []),
                "instrumentos": "; ".join((s.get("descripcion") or "").strip() for s in d.get("instrumentos") or []),
                "finalidad": d.get("descripcionFinalidad"),
                "reglamento": (d.get("reglamento") or {}).get("descripcion") if isinstance(d.get("reglamento"), dict) else d.get("reglamento"),
                "url_bases": d.get("urlBasesReguladoras"),
                "organo_nivel1": organo.get("nivel1"),
                "organo_nivel2": organo.get("nivel2"),
                "organo_nivel3": organo.get("nivel3"),
                "descargado": ahora,
            }
            time.sleep(0.3)

    @dlt.resource(name="bdns_concesiones_medios", write_disposition="merge", primary_key="cod_concesion")
    def bdns_concesiones_medios():
        for c in lista:
            cod = c["cod_bdns"].strip()
            pagina, total = 0, None
            while True:
                d = _get("concesiones/busqueda", numeroConvocatoria=cod, page=pagina, pageSize=PAGE_SIZE)
                filas = d.get("content") or []
                total = d.get("totalElements")
                for r in filas:
                    # la búsqueda por número puede traer convocatorias con el mismo prefijo: filtra exacto
                    if str(r.get("numeroConvocatoria")) != cod:
                        continue
                    nif, nombre, es_pf = _beneficiario(r.get("beneficiario"))
                    fecha = r.get("fechaConcesion")
                    yield {
                        "cod_concesion": r.get("codConcesion") or f"ID{r.get('id')}",
                        "id_concesion": r.get("id"),
                        "cod_bdns": cod,
                        "fecha_concesion": fecha,
                        "anio": int(fecha[:4]) if fecha else None,
                        "beneficiario_nif": nif,
                        "beneficiario_nombre": nombre,
                        "es_persona_fisica": es_pf,
                        "importe": float(r["importe"]) if r.get("importe") is not None else None,
                        "ayuda_equivalente": float(r["ayudaEquivalente"]) if r.get("ayudaEquivalente") is not None else None,
                        "instrumento": (r.get("instrumento") or "").strip() or None,
                        "concedente_nivel1": r.get("nivel1"),
                        "concedente_nivel2": r.get("nivel2"),
                        "concedente_nivel3": r.get("nivel3"),
                        "fecha_alta": r.get("fechaAlta"),
                        "descargado": ahora,
                    }
                pagina += 1
                if d.get("last", True) or pagina >= (d.get("totalPages") or 1):
                    break
            log.info("BDNS %s: %s concesiones", cod, total)
            time.sleep(0.3)

    return bdns_convocatorias_medios, bdns_concesiones_medios
