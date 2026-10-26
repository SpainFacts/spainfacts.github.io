"""Analizador genérico para portales de transparencia municipales y provinciales.

Apto para CMS habituales (WordPress, Drupal, Liferay, Plone, Joomla) y desarrollos a medida.
Inspecciona menús, subsecciones, listas de documentos y enlaces de transparencia en las 4
lenguas oficiales (castellano, catalán, gallego y euskera).
"""

from __future__ import annotations

import logging
import re
import urllib.parse
from datetime import date
from typing import List

import requests
from bs4 import BeautifulSoup

from ingestion.transparencia_robot.analizadores.base import AnalizadorBase
from ingestion.transparencia_robot.cliente import ClienteHttp
from ingestion.transparencia_robot.fechas import resolver_fecha_elemento
from ingestion.transparencia_robot.huella import (
    es_reto_waf,
    extraer_enlaces_transparencia,
)
from ingestion.transparencia_robot.tipos import COMPROBACIONES, Entidad, Resultado

logger = logging.getLogger("transparencia_robot.analizadores.generico")

MAPEO_GENERICO_REGEX = {
    "C1": re.compile(
        r"\b(organigrama|estructura organizativa|organizaci[oó]n municipal|organitzaci[oó]|antolaketa)\b",
        re.I,
    ),
    "C2": re.compile(
        r"\b(corporaci[oó]n|concejales|regidors|kargu hautetsiak|alcald[ií]a|consistori|miembros de la corporaci[oó]n|altos cargos)\b",
        re.I,
    ),
    "C3": re.compile(
        r"\b(retribucion|retribucions|ordainsariak|indemnizacion|indemnitzacions|dietas|dedicaci[oó]n exclusiva)\b",
        re.I,
    ),
    "C4": re.compile(
        r"\b(presupuesto|presupuestos|pressupost|pressupostos|aurrekontu|aurrekontuak)\b",
        re.I,
    ),
    "C5": re.compile(
        r"\b(ejecuci[oó]n presupuestaria|estabilidad presupuestaria|execuci[oó] del pressupost|aurrekontuaren gauzatzea)\b",
        re.I,
    ),
    "C6": re.compile(
        r"\b(cuenta general|cuentas anuales|liquidaci[oó]n del presupuesto|compte general|kontu orokorra)\b",
        re.I,
    ),
    "C7": re.compile(
        r"\b(perfil del contratante|contratos|contrataci[oó]n|contractes|kontratuak|licitaciones|contratos menores)\b",
        re.I,
    ),
    "C8": re.compile(
        r"\b(convenios|encomiendas de gesti[oó]n|convenis|hitzarmenak)\b",
        re.I,
    ),
    "C9": re.compile(
        r"\b(subvenciones|ayudas p[uú]blicas|subvencions|dirulaguntzak|ayudas concedidas)\b",
        re.I,
    ),
    "C10": re.compile(
        r"\b(actas de pleno|actas del pleno|actes de ple|osoko bilkurako aktak|sesiones plenarias)\b",
        re.I,
    ),
    "C11": re.compile(
        r"\b(declaraci[oó]n de bienes|declaraciones de bienes|registro de intereses|b[eé]ns i activitats|ondasun aitortza)\b",
        re.I,
    ),
    "C12": re.compile(
        r"\b(relaci[oó]n de puestos de trabajo|rpt|plantilla de personal|relaci[oó] de llocs de treball|lanpostuen zerrenda|oferta de empleo p[uú]blico)\b",
        re.I,
    ),
    "C13": re.compile(
        r"\b(inventario de bienes|patrimonio municipal|bienes inmuebles|inventari de b[eé]ns|ondasunen inbentarioa)\b",
        re.I,
    ),
    "C14": re.compile(
        r"\b(ordenanzas|reglamentos|normativa municipal|ordenances|ordenantzak)\b",
        re.I,
    ),
    "C15": re.compile(
        r"\b(periodo medio de pago|pmp|per[ií]ode mitj[aà] de pagament|ordaintzeko batez besteko epea)\b",
        re.I,
    ),
}


class AnalizadorGenerico(AnalizadorBase):
    """Analizador para páginas y portales genéricos de transparencia."""

    def analizar(
        self,
        entidad: Entidad,
        cliente: ClienteHttp,
        url_transparencia: str | None = None,
    ) -> List[Resultado]:
        resultados: List[Resultado] = []

        # 1. Determinar URL a inspeccionar
        url_target = url_transparencia or entidad.url_transparencia or entidad.url_web

        if not url_target:
            for c in COMPROBACIONES:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado="no_evaluable",
                        analizador="generico",
                        motivo="sin_url_de_acceso",
                    )
                )
            return resultados

        resp, robots_prohibe, err = cliente.get(url_target)
        if resp is None or resp.status_code >= 400:
            if resp and es_reto_waf(resp.status_code, resp.text):
                estado_comprob = "verificacion_humana"
                motivo_comprob = "reto_waf_o_bloqueo_antibot"
            else:
                estado_comprob = "no_evaluable"
                motivo_comprob = err or f"http_{resp.status_code if resp else 'sin_respuesta'}"

            for c in COMPROBACIONES:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado=estado_comprob,
                        analizador="generico",
                        url_evidencia=url_target,
                        motivo=motivo_comprob,
                        robots_prohibe=robots_prohibe,
                    )
                )
            return resultados

        # Si llegamos a una portada genérica, buscar enlace de transparencia
        enlaces_transp = extraer_enlaces_transparencia(resp.url, resp.text)
        if enlaces_transp and not url_transparencia:
            mejor_enlace_transp = enlaces_transp[0][1]
            if mejor_enlace_transp != resp.url:
                resp_sub, r_prohibe_sub, err_sub = cliente.get(mejor_enlace_transp)
                if resp_sub and resp_sub.status_code == 200:
                    resp = resp_sub
                    robots_prohibe = r_prohibe_sub

        return self.analizar_html(entidad, resp, robots_prohibe=robots_prohibe, analizador_nombre="generico")

    def analizar_html(
        self,
        entidad: Entidad,
        resp: requests.Response,
        robots_prohibe: bool | None = None,
        analizador_nombre: str = "generico",
    ) -> List[Resultado]:
        """Analiza un objeto Response ya descargado."""
        resultados: List[Resultado] = []

        # C0: Portal accesible
        resultados.append(
            self.crear_resultado(
                entidad,
                "C0",
                estado="consta",
                analizador=analizador_nombre,
                url_evidencia=resp.url,
                titulo_evidencia="Portal o sección de transparencia accesible",
                robots_prohibe=robots_prohibe,
                confianza="alta",
            )
        )

        soup = BeautifulSoup(resp.text, "html.parser")

        # Recoger enlaces, listas y párrafos
        elementos_documentales: list[dict] = []
        for el in soup.find_all(["a", "li", "tr", "div", "p"]):
            txt = el.get_text(" ", strip=True)
            if not txt or len(txt) < 3:
                continue

            href = el.get("href") or (el.find("a") and el.find("a").get("href"))
            url_abs = urllib.parse.urljoin(resp.url, href) if href else resp.url

            elementos_documentales.append({
                "texto": txt,
                "url": url_abs,
            })

        # Evaluar C1..C15
        for cod_comp, regex_kw in MAPEO_GENERICO_REGEX.items():
            encontrado = False
            mejor_fecha: date | None = None
            mejor_regla: str | None = None
            mejor_titulo: str | None = None
            mejor_url: str | None = None

            for doc in elementos_documentales:
                txt = doc["texto"]
                if regex_kw.search(txt):
                    encontrado = True
                    mejor_titulo = txt[:120]
                    mejor_url = doc["url"]

                    d, regla = resolver_fecha_elemento(titulo=txt, texto_contenido=txt)
                    if d and (not mejor_fecha or d > mejor_fecha):
                        mejor_fecha = d
                        mejor_regla = regla

            if encontrado:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        cod_comp,
                        estado="consta",
                        analizador=analizador_nombre,
                        url_evidencia=mejor_url or resp.url,
                        fecha_ultima=mejor_fecha,
                        regla_fecha=mejor_regla,
                        titulo_evidencia=mejor_titulo,
                        robots_prohibe=robots_prohibe,
                        confianza="alta" if mejor_fecha else "media",
                    )
                )
            else:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        cod_comp,
                        estado="no_consta",
                        analizador=analizador_nombre,
                        url_evidencia=resp.url,
                        motivo="seccion_o_documento_no_localizado",
                        robots_prohibe=robots_prohibe,
                        confianza="media",
                    )
                )

        return resultados
