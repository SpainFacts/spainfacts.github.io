"""Analizador para la plataforma de portales de la Diputación de Ciudad Real (dipucr).

Dispone de una API JSON pública con códigos de indicadores (ITA) y fechas estructuradas
de publicación (/api/publicas/...).
"""

from __future__ import annotations

import logging
import urllib.parse
from datetime import date
from typing import Any, Dict, List

from ingestion.transparencia_robot.analizadores.base import AnalizadorBase
from ingestion.transparencia_robot.cliente import ClienteHttp
from ingestion.transparencia_robot.fechas import parse_fecha_iso
from ingestion.transparencia_robot.tipos import COMPROBACIONES, Entidad, Resultado

logger = logging.getLogger("transparencia_robot.analizadores.dipucr")

# Mapeo de categorías o descripciones de la API dipucr a comprobaciones C0..C15
MAPEO_DIPUCR_AREAS = {
    "C1": ["organigrama", "estructura", "organización"],
    "C2": ["cargos electos", "identificación", "perfil", "trayectoria"],
    "C3": ["retribuciones", "indemnizaciones", "dietas"],
    "C4": ["presupuesto", "presupuestos"],
    "C5": ["ejecución", "estabilidad presupuestaria"],
    "C6": ["cuentas anuales", "cuenta general", "liquidación"],
    "C7": ["contratos", "licitaciones", "perfil del contratante"],
    "C8": ["convenios", "encomiendas"],
    "C9": ["subvenciones", "ayudas"],
    "C10": ["actas de pleno", "plenos", "sesiones plenarias"],
    "C11": ["declaraciones de bienes", "registro de intereses"],
    "C12": ["plantilla", "relación de puestos de trabajo", "rpt"],
    "C13": ["patrimonio", "inventario de bienes"],
    "C14": ["normativa", "ordenanzas", "reglamentos"],
    "C15": ["periodo medio de pago", "pmp"],
}


class AnalizadorDipuCR(AnalizadorBase):
    """Analizador mediante la API JSON de Diputación de Ciudad Real."""

    def analizar(
        self,
        entidad: Entidad,
        cliente: ClienteHttp,
        url_transparencia: str | None = None,
    ) -> List[Resultado]:
        resultados: List[Resultado] = []

        url_base = url_transparencia or entidad.url_transparencia or entidad.url_web
        if not url_base:
            for c in COMPROBACIONES:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado="no_evaluable",
                        analizador="dipucr",
                        motivo="sin_url",
                    )
                )
            return resultados

        parsed = urllib.parse.urlparse(url_base)
        base_host = f"{parsed.scheme}://{parsed.netloc}"

        # Intentar obtener el ID de entidad de la URL o deducirlo del INE
        entidad_id = entidad.cod_mun[-3:] if entidad.cod_mun else "1"

        api_indicadores_url = f"{base_host}/api/publicas/entidades/{entidad_id}/indicadores"
        resp, robots_prohibe, err = cliente.get(api_indicadores_url)

        # Si falla por el ID, intentar con la ruta del portal principal
        if resp is None or resp.status_code != 200:
            api_indicadores_url = f"{base_host}/api/publicas/indicadores"
            resp, robots_prohibe, err = cliente.get(api_indicadores_url)

        if resp is None or resp.status_code != 200:
            for c in COMPROBACIONES:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado="no_evaluable",
                        analizador="dipucr",
                        url_evidencia=api_indicadores_url,
                        motivo=err or f"http_{resp.status_code if resp else 'error'}",
                        robots_prohibe=robots_prohibe,
                    )
                )
            return resultados

        # C0: Portal y API accesibles
        resultados.append(
            self.crear_resultado(
                entidad,
                "C0",
                estado="consta",
                analizador="dipucr",
                url_evidencia=base_host,
                titulo_evidencia="Portal y API de Transparencia DipuCR accesibles",
                robots_prohibe=robots_prohibe,
                confianza="alta",
            )
        )

        try:
            indicadores_json = resp.json()
        except Exception:
            indicadores_json = []

        # Obtener también las últimas publicaciones para fechas exactas
        api_ultimas_url = f"{base_host}/api/publicas/ultimas?entidad_id={entidad_id}"
        resp_ultimas, _, _ = cliente.get(api_ultimas_url)
        ultimas_json = []
        if resp_ultimas and resp_ultimas.status_code == 200:
            try:
                ultimas_json = resp_ultimas.json()
            except Exception:
                ultimas_json = []

        # Indexar publicaciones recientes por texto / clave
        fechas_publicaciones: Dict[str, date] = {}
        for pub in ultimas_json:
            f_str = pub.get("fecha_publicacion") or pub.get("fecha")
            titulo_pub = (pub.get("titulo") or pub.get("nombre") or "").lower()
            if f_str and titulo_pub:
                d = parse_fecha_iso(f_str)
                if d:
                    fechas_publicaciones[titulo_pub] = d

        # Evaluar C1..C15 cruzando los indicadores devueltos por la API
        for cod_comp, keywords in MAPEO_DIPUCR_AREAS.items():
            encontrado = False
            mejor_fecha: date | None = None
            mejor_titulo: str | None = None
            n_docs: int | None = None

            for ind in (indicadores_json if isinstance(indicadores_json, list) else []):
                nombre_ind = (ind.get("nombre") or ind.get("descripcion") or "").lower()
                if any(kw in nombre_ind for kw in keywords):
                    encontrado = True
                    mejor_titulo = (ind.get("nombre") or ind.get("descripcion"))[:120]
                    # Documentos asociados
                    n_docs = ind.get("total_documentos") or ind.get("num_publicaciones") or 1

                    # Buscar fecha en las últimas publicaciones
                    for t_pub, d_pub in fechas_publicaciones.items():
                        if any(kw in t_pub for kw in keywords):
                            if not mejor_fecha or d_pub > mejor_fecha:
                                mejor_fecha = d_pub

            if encontrado:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        cod_comp,
                        estado="consta",
                        analizador="dipucr",
                        url_evidencia=api_indicadores_url,
                        fecha_ultima=mejor_fecha,
                        regla_fecha="plataforma" if mejor_fecha else None,
                        titulo_evidencia=mejor_titulo,
                        n_elementos=n_docs,
                        robots_prohibe=robots_prohibe,
                        confianza="alta",
                    )
                )
            else:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        cod_comp,
                        estado="no_consta",
                        analizador="dipucr",
                        url_evidencia=api_indicadores_url,
                        motivo="indicador_no_presente_en_api",
                        robots_prohibe=robots_prohibe,
                        confianza="alta",
                    )
                )

        return resultados
