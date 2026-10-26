"""Analizador para la plataforma Seu-e del Consorci AOC (seu-e.cat).

La Seu-e es la plataforma estándar de transparencia municipal en Cataluña (~70 % de los
municipios catalanes). Está construida sobre Liferay y estructura la información según
la Llei 19/2014 de transparència.
"""

from __future__ import annotations

import logging
import re
import urllib.parse
from datetime import date
from typing import List

from bs4 import BeautifulSoup

from ingestion.transparencia_robot.analizadores.base import AnalizadorBase
from ingestion.transparencia_robot.cliente import ClienteHttp
from ingestion.transparencia_robot.fechas import resolver_fecha_elemento
from ingestion.transparencia_robot.tipos import COMPROBACIONES, Entidad, Resultado

logger = logging.getLogger("transparencia_robot.analizadores.aoc_seue")

MAPEO_SEUE_CATEGORIAS = {
    "C1": re.compile(r"organitzaci[oó]|organigrama|estructura", re.I),
    "C2": re.compile(r"alts c[aà]rrecs|c[aà]rrecs electes|composici[oó]|consistori|regidors|alcalde", re.I),
    "C3": re.compile(r"retribucions|indemnitzacions|dietes", re.I),
    "C4": re.compile(r"pressupost|pressupostos", re.I),
    "C5": re.compile(r"execuci[oó] del pressupost|estabilitat", re.I),
    "C6": re.compile(r"comptes anuals|compte general|liquidaci[oó]", re.I),
    "C7": re.compile(r"contractes|perfil del contractant|licitacions", re.I),
    "C8": re.compile(r"convenis|enc[aà]rrecs", re.I),
    "C9": re.compile(r"subvencions|ajuts", re.I),
    "C10": re.compile(r"actes de ple|actes|ple municipal|ordres del dia", re.I),
    "C11": re.compile(r"declaracions de b[eé]ns|b[eé]ns i activitats|interessos", re.I),
    "C12": re.compile(r"plantilla|relaci[oó] de llocs de treball|rlt|empleats p[uú]blics", re.I),
    "C13": re.compile(r"patrimoni|inventari|b[eé]ns immobles", re.I),
    "C14": re.compile(r"normativa|ordenances|reglaments", re.I),
    "C15": re.compile(r"per[ií]ode mitj[aà] de pagament|pmp", re.I),
}


class AnalizadorAocSeue(AnalizadorBase):
    """Analizador para la Seu-e del Consorci AOC."""

    def analizar(
        self,
        entidad: Entidad,
        cliente: ClienteHttp,
        url_transparencia: str | None = None,
    ) -> List[Resultado]:
        resultados: List[Resultado] = []

        url_target = url_transparencia or entidad.url_transparencia
        if not url_target and entidad.url_web and "seu-e.cat" in entidad.url_web:
            url_target = entidad.url_web

        if not url_target:
            # Inferir URL estándar de la Seu-e por slug del municipio
            # seu-e.cat/ca/web/{slug}/govern-obert-i-transparencia
            nombre_slug = entidad.nombre.lower().replace(" ", "")
            url_target = f"https://seu-e.cat/ca/web/{nombre_slug}/govern-obert-i-transparencia"

        resp, robots_prohibe, err = cliente.get(url_target)
        if resp is None or resp.status_code >= 400:
            for c in COMPROBACIONES:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado="no_evaluable",
                        analizador="aoc_seue",
                        url_evidencia=url_target,
                        motivo=err or f"http_{resp.status_code if resp else 'sin_respuesta'}",
                        robots_prohibe=robots_prohibe,
                    )
                )
            return resultados

        # C0: Portal accesible
        resultados.append(
            self.crear_resultado(
                entidad,
                "C0",
                estado="consta",
                analizador="aoc_seue",
                url_evidencia=resp.url,
                titulo_evidencia="Seu-e AOC accesible",
                robots_prohibe=robots_prohibe,
                confianza="alta",
            )
        )

        soup = BeautifulSoup(resp.text, "html.parser")

        # Extraer enlaces y títulos de la navegación temática
        items_encontrados = []
        for a in soup.find_all("a", href=True):
            href = a["href"].strip()
            txt = a.get_text(" ", strip=True)
            if not txt or len(txt) < 3:
                continue
            url_completa = urllib.parse.urljoin(resp.url, href)
            items_encontrados.append((txt, url_completa))

        # Evaluar C1..C15
        for cod_comp, regex_cat in MAPEO_SEUE_CATEGORIAS.items():
            encontrado = False
            mejor_titulo: str | None = None
            mejor_url: str | None = None
            mejor_fecha: date | None = None
            mejor_regla: str | None = None

            for txt, u_href in items_encontrados:
                combinado = f"{txt} {u_href}"
                if regex_cat.search(combinado):
                    encontrado = True
                    mejor_titulo = txt[:120]
                    mejor_url = u_href

                    # Resolver fecha en el título o enlace
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
                        analizador="aoc_seue",
                        url_evidencia=mejor_url or resp.url,
                        fecha_ultima=mejor_fecha,
                        regla_fecha=mejor_regla,
                        titulo_evidencia=mejor_titulo,
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
                        analizador="aoc_seue",
                        url_evidencia=resp.url,
                        motivo="seccion_no_encontrada_en_seue",
                        robots_prohibe=robots_prohibe,
                        confianza="media",
                    )
                )

        return resultados
