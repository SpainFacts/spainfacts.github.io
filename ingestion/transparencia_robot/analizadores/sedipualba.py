"""Analizador para entidades que utilizan la plataforma Sedipualba (Dip. de Albacete).

Sedipualba se utiliza ampliamente en Albacete, Huesca, Valencia y municipios de Murcia y Navarra.
La sede aloja el enlace al portal de transparencia, que puede ser interno o redirigir a un portal
propio o de la diputación provincial.
"""

from __future__ import annotations

import logging
import urllib.parse
from typing import List

from bs4 import BeautifulSoup

from ingestion.transparencia_robot.analizadores.base import AnalizadorBase
from ingestion.transparencia_robot.cliente import ClienteHttp
from ingestion.transparencia_robot.huella import extraer_enlaces_transparencia
from ingestion.transparencia_robot.tipos import COMPROBACIONES, Entidad, Resultado

logger = logging.getLogger("transparencia_robot.analizadores.sedipualba")


class AnalizadorSedipualba(AnalizadorBase):
    """Analizador para sedes y portales de Sedipualba."""

    def analizar(
        self,
        entidad: Entidad,
        cliente: ClienteHttp,
        url_transparencia: str | None = None,
    ) -> List[Resultado]:
        resultados: List[Resultado] = []

        url_sede = entidad.url_sede or (f"https://{entidad.nombre.lower().replace(' ', '')}.sedipualba.es")

        # 1. Petición a la sede de Sedipualba para localizar el enlace de transparencia
        resp_sede, robots_prohibe, err = cliente.get(url_sede)
        if resp_sede is None or resp_sede.status_code >= 400:
            for c in COMPROBACIONES:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado="no_evaluable",
                        analizador="sedipualba",
                        url_evidencia=url_sede,
                        motivo=err or f"http_{resp_sede.status_code if resp_sede else 'sin_respuesta'}",
                        robots_prohibe=robots_prohibe,
                    )
                )
            return resultados

        enlaces_transp = extraer_enlaces_transparencia(resp_sede.url, resp_sede.text)

        url_portal = url_transparencia
        if not url_portal and enlaces_transp:
            url_portal = enlaces_transp[0][1]

        if not url_portal:
            # Sede accesible pero sin enlace visible a transparencia
            resultados.append(
                self.crear_resultado(
                    entidad,
                    "C0",
                    estado="no_consta",
                    analizador="sedipualba",
                    url_evidencia=resp_sede.url,
                    titulo_evidencia="Sede Sedipualba sin enlace a portal de transparencia",
                    robots_prohibe=robots_prohibe,
                    confianza="alta",
                )
            )
            for c in [k for k in COMPROBACIONES if k != "C0"]:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado="no_consta",
                        analizador="sedipualba",
                        url_evidencia=resp_sede.url,
                        motivo="sin_portal_de_transparencia_en_sede",
                        robots_prohibe=robots_prohibe,
                    )
                )
            return resultados

        # 2. Visitar el portal de transparencia encontrado
        resp_portal, robots_prohibe_portal, err_portal = cliente.get(url_portal)
        if resp_portal is None or resp_portal.status_code >= 400:
            resultados.append(
                self.crear_resultado(
                    entidad,
                    "C0",
                    estado="no_evaluable",
                    analizador="sedipualba",
                    url_evidencia=url_portal,
                    motivo=f"enlace_transparencia_caido_{err_portal or resp_portal.status_code if resp_portal else 'error'}",
                    robots_prohibe=robots_prohibe_portal,
                )
            )
            for c in [k for k in COMPROBACIONES if k != "C0"]:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado="no_evaluable",
                        analizador="sedipualba",
                        url_evidencia=url_portal,
                        motivo="portal_transparencia_no_responde",
                    )
                )
            return resultados

        # Delegar el análisis de contenidos al analizador genérico sobre la página destino
        from ingestion.transparencia_robot.analizadores.generico import AnalizadorGenerico
        analizador_gen = AnalizadorGenerico(ronda=self.ronda)
        return analizador_gen.analizar_html(entidad, resp_portal, analizador_nombre="sedipualba")
