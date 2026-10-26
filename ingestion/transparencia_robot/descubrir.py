"""Descubrimiento y consolidación del censo de portales de las entidades locales.

Combina:
1. BDGEL (Hacienda SGFAL): código municipal/provincial, nombre, teléfono, CP, web y email.
2. DIR3 (CTT): NIF y correo electrónico oficial (validación de sedes).
3. Wikidata (propiedad P856): URL web de la entidad (con código INE P772).
4. Subdominios de plataformas comunes: *.sedelectronica.es, *.sedipualba.es, *.eadministracio.cat.

Genera el archivo censo_entidades.parquet con las entidades y sus URLs candidatas.
"""

from __future__ import annotations

import json
import logging
import os
import re
import unicodedata
from typing import Any, Dict, List

import openpyxl
import pyarrow as pa
import pyarrow.parquet as pq

from ingestion.transparencia_robot.tipos import Entidad

logger = logging.getLogger("transparencia_robot.descubrir")

DOMINIOS_GENERICOS_EMAIL = {
    "gmail.com", "yahoo.es", "hotmail.com", "yahoo.com", "telefonica.net",
    "hotmail.es", "outlook.es", "outlook.com", "terra.es", "ono.com",
    "wanadoo.es", "movistar.es", "icloud.com",
}


def normalizar_url(url: str | None) -> str | None:
    """Limpia y normaliza una URL."""
    if not url:
        return None
    u = url.strip()
    if not u or " " in u or "@" in u:
        return None
    # Descartar textos comunes erróneos en BDGEL
    u_lower = u.lower()
    if any(err in u_lower for err in ("no tiene", "sintiene", "notiene", "sinweb", "enconstruccion")):
        return None
    if not re.search(r"[a-z0-9-]+\.[a-z]{2,}", u_lower):
        return None
    if not u.startswith("http://") and not u.startswith("https://"):
        u = "https://" + u.lstrip("/")
    return u.rstrip("/")


def slugify_nombre(nombre: str) -> str:
    """Convierte el nombre del municipio en un slug compacto sin espacios ni acentos."""
    n = nombre.strip().lower()
    # Eliminar prefijos comunes
    n = re.sub(r"^(?:ayuntamiento|ajuntament|concello|udala|consello|alcald[ií]a)\s+(?:de\s+|d'|del\s+|da\s+)?", "", n)
    # Quitar tildes y diacríticos
    n = unicodedata.normalize("NFKD", n).encode("ascii", "ignore").decode("utf-8")
    # Dejar solo caracteres alfanuméricos
    slug = re.sub(r"[^a-z0-9]", "", n)
    return slug


def cargar_bdgel(ruta_bdgel: str) -> List[dict]:
    """Carga el archivo JSON de direcciones de la BDGEL."""
    with open(ruta_bdgel, "r", encoding="utf-8") as f:
        datos = json.load(f)
    return datos


def cargar_wikidata(ruta_wikidata: str) -> Dict[str, str]:
    """Carga el mapeo INE -> URL de Wikidata."""
    try:
        with open(ruta_wikidata, "r", encoding="utf-8") as f:
            return json.load(f)
    except UnicodeDecodeError:
        with open(ruta_wikidata, "r", encoding="latin-1") as f:
            return json.load(f)


def cargar_dir3(ruta_dir3: str) -> Dict[str, dict]:
    """Carga el XLSX de DIR3 y extrae NIF y contacto por código municipal/provincial."""
    wb = openpyxl.load_workbook(ruta_dir3, data_only=True)
    sheet = wb["Unidades EELL"]
    resultado: Dict[str, dict] = {}
    for r in range(3, sheet.max_row + 1):
        uid = sheet.cell(r, 2).value
        if not uid:
            continue
        uid_str = str(uid).strip()
        nif = sheet.cell(r, 18).value
        email = sheet.cell(r, 19).value
        nivel = str(sheet.cell(r, 6).value or "").strip()

        if uid_str.startswith("L01") and len(uid_str) >= 8:
            cod_mun = uid_str[3:8]
            resultado[cod_mun] = {
                "nif": str(nif).strip() if nif else None,
                "email": str(email).strip().lower() if email else None,
                "dir3": uid_str,
            }
        elif uid_str.startswith("L02") and len(uid_str) >= 5:
            cod_prov = uid_str[3:5]
            resultado[f"D{cod_prov}"] = {
                "nif": str(nif).strip() if nif else None,
                "email": str(email).strip().lower() if email else None,
                "dir3": uid_str,
            }
    return resultado


def construir_censo(cache_dir: str = "data/transparencia_robot_cache") -> List[Entidad]:
    """Cruza BDGEL, DIR3 y Wikidata para consolidar la lista completa de Entidades."""
    ruta_bdgel = os.path.join(cache_dir, "bdgel_direcciones.json")
    ruta_dir3 = os.path.join(cache_dir, "dir3_eell.xlsx")
    ruta_wikidata = os.path.join(cache_dir, "wikidata_p856.json")

    logger.info("Cargando fuentes de descubrimiento...")
    bdgel_filas = cargar_bdgel(ruta_bdgel)
    dir3_map = cargar_dir3(ruta_dir3)
    wikidata_map = cargar_wikidata(ruta_wikidata)

    entidades: List[Entidad] = []

    for r in bdgel_filas:
        tipo_princ = r.get("tipoEntePrincipalCodigo")
        tipo_dep = r.get("tipoEntePrincipalODependienteCodigo")

        es_ayto = (tipo_princ == "A" and tipo_dep == "A")
        es_dip = (tipo_princ == "D" and tipo_dep == "D")

        if not (es_ayto or es_dip):
            continue

        prov_cod = str(r.get("provinciaCodigo", "")).zfill(2)
        corp_cod = str(r.get("corporacion", "")).zfill(3)
        nombre = str(r.get("nombreCorporacion", "")).strip()
        ca_cod = str(r.get("caCodigo", "")).zfill(2)

        if es_ayto:
            cod_entidad = f"{prov_cod}{corp_cod}"
            tipo_entidad = "Ayuntamiento"
            cod_mun = cod_entidad
            cod_prov = prov_cod
        else:
            tipo_entidad = "Diputación provincial" if corp_cod == "000" else "Cabildo o consell insular"
            cod_entidad = f"D{prov_cod}" if corp_cod == "000" else f"I{prov_cod}{corp_cod}"
            cod_mun = None
            cod_prov = prov_cod

        # Datos de contacto de BDGEL
        tel = str(r.get("telefono", "")).strip() or None
        cp = str(r.get("codigoPostal", "")).strip() or None
        web_bdgel = normalizar_url(r.get("siteWeb"))
        email_bdgel = str(r.get("email", "")).strip().lower() or None

        # Datos de DIR3
        dir3_info = dir3_map.get(cod_entidad, {})
        nif = dir3_info.get("nif")
        email_dir3 = dir3_info.get("email")

        # Datos de Wikidata
        web_wiki = normalizar_url(wikidata_map.get(cod_entidad))

        # Candidatas con puntuación
        candidatas: List[dict] = []
        if web_bdgel:
            candidatas.append({
                "url": web_bdgel,
                "origen": "bdgel",
                "puntuacion": 90,
                "motivo": "siteWeb en registro BDGEL de Hacienda",
            })
        if web_wiki:
            candidatas.append({
                "url": web_wiki,
                "origen": "wikidata",
                "puntuacion": 80,
                "motivo": "Propiedad P856 en Wikidata",
            })

        # Extraer dominio de correo si es propio
        email_usar = email_dir3 or email_bdgel
        if email_usar and "@" in email_usar:
            dom = email_usar.split("@")[1].strip()
            if dom and dom not in DOMINIOS_GENERICOS_EMAIL and "." in dom:
                url_email = f"https://{dom}"
                candidatas.append({
                    "url": url_email,
                    "origen": "email_dominio",
                    "puntuacion": 70,
                    "motivo": "Dominio institucional del correo oficial",
                })

        # Plataformas por slug
        slug = slugify_nombre(nombre)
        plataforma_detectada = None
        url_sede = None
        url_transp = None

        if es_ayto and slug:
            # Subdominios comunes
            candidatas.append({
                "url": f"https://{slug}.sedelectronica.es",
                "origen": "gestiona_slug",
                "puntuacion": 65,
                "motivo": "Subdominio inferido en Gestiona (esPúblico)",
            })
            candidatas.append({
                "url": f"https://{slug}.sedipualba.es",
                "origen": "sedipualba_slug",
                "puntuacion": 60,
                "motivo": "Subdominio inferido en Sedipualba",
            })
            if prov_cod in ("08", "17", "25", "43", "07"):
                candidatas.append({
                    "url": f"https://{slug}.eadministracio.cat",
                    "origen": "eadmin_slug",
                    "puntuacion": 65,
                    "motivo": "Subdominio inferido en eAdministracio (Cataluña/Baleares)",
                })

        # Elegir la mejor URL web: priorizar BDGEL o Wikidata
        url_web = web_bdgel or web_wiki
        if not url_web and candidatas:
            candidatas_ordenadas = sorted(candidatas, key=lambda x: x["puntuacion"], reverse=True)
            url_web = candidatas_ordenadas[0]["url"]

        plataforma_detectada = None
        url_sede = None
        url_transp = None

        if url_web:
            u_web_lower = url_web.lower()
            if "sedelectronica.es" in u_web_lower or "eadministracio.cat" in u_web_lower:
                plataforma_detectada = "gestiona"
                url_sede = url_web
            elif "sedipualba.es" in u_web_lower:
                plataforma_detectada = "sedipualba"
                url_sede = url_web
            elif "seu-e.cat" in u_web_lower:
                plataforma_detectada = "aoc_seue"
                url_transp = url_web
            elif "dipucr.es" in u_web_lower:
                plataforma_detectada = "dipucr"
                url_transp = url_web

        entidad = Entidad(
            tipo_entidad=tipo_entidad,
            cod_entidad=cod_entidad,
            nombre=nombre,
            cod_mun=cod_mun,
            cod_prov=cod_prov,
            cod_ccaa=ca_cod,
            nif=nif,
            telefono=tel,
            cp=cp,
            urls_candidatas=candidatas,
            url_web=url_web,
            url_sede=url_sede,
            url_transparencia=url_transp,
            plataforma=plataforma_detectada,
        )
        entidades.append(entidad)

    logger.info("Total entidades consolidadas en el censo: %d", len(entidades))
    return entidades


def exportar_censo_parquet(
    entidades: List[Entidad],
    ruta_salida: str = "data/transparencia_robot_cache/censo_entidades.parquet",
) -> None:
    """Exporta la lista de Entidades a un archivo Parquet usando DuckDB."""
    os.makedirs(os.path.dirname(os.path.abspath(ruta_salida)), exist_ok=True)
    filas = []
    for e in entidades:
        filas.append({
            "cod_entidad": e.cod_entidad,
            "tipo_entidad": e.tipo_entidad,
            "nombre": e.nombre,
            "cod_mun": e.cod_mun,
            "cod_prov": e.cod_prov,
            "cod_ccaa": e.cod_ccaa,
            "nif": e.nif,
            "telefono": e.telefono,
            "cp": e.cp,
            "url_web": e.url_web,
            "url_sede": e.url_sede,
            "url_transparencia": e.url_transparencia,
            "plataforma": e.plataforma,
            "n_candidatas": len(e.urls_candidatas),
            "candidatas_json": json.dumps(e.urls_candidatas, ensure_ascii=False),
        })

    table = pa.Table.from_pylist(filas)
    pq.write_table(table, ruta_salida, compression="zstd")
    logger.info("Censo exportado a %s (%d filas)", ruta_salida, len(filas))


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
    ee = construir_censo()
    exportar_censo_parquet(ee)
    print(f"Censo completado con éxito: {len(ee)} entidades.")
