"""Analizador especializado para la plataforma Gestiona (esPúblico).

Gestiona concentra más del 60 % de los ayuntamientos de España (*.sedelectronica.es y
*.eadministracio.cat). Utiliza Apache Wicket con un árbol temático normalizado y recuento
de documentos por sección.
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

logger = logging.getLogger("transparencia_robot.analizadores.gestiona")

# Mapeo de términos de nodos temáticos en Gestiona a comprobaciones C0..C15
MAPEO_NODOS_GESTIONA = {
    "C1": re.compile(r"organizaci[oó]n|estructura|organigrama", re.I),
    "C2": re.compile(r"altos cargos|cargos electos|responsables|corporaci[oó]n|concejales|alcald", re.I),
    "C3": re.compile(r"retribucion|indemnizacion|asistencia|dietas", re.I),
    "C4": re.compile(r"presupuesto|3\.1\b|3\.1\.1\b", re.I),
    "C5": re.compile(r"ejecuci[oó]n|estabilidad", re.I),
    "C6": re.compile(r"cuentas anuales|cuenta general|liquidaci[oó]n", re.I),
    "C7": re.compile(r"contrat|contrato|licitaci[oó]n|perfil del contratante", re.I),
    "C8": re.compile(r"convenio|encomienda", re.I),
    "C9": re.compile(r"subvenci[oó]n|ayuda", re.I),
    "C10": re.compile(r"acta|pleno|acuerdos de pleno|sesi[oó]n", re.I),
    "C11": re.compile(r"bienes|actividades|registro de intereses|declaraci[oó]n de bienes", re.I),
    "C12": re.compile(r"plantilla|relaci[oó]n de puestos|rpt|personal y empleo", re.I),
    "C13": re.compile(r"patrimonio|inmueble|bienes inmuebles|inventario", re.I),
    "C14": re.compile(r"normativa|ordenanza|reglamento", re.I),
    "C15": re.compile(r"periodo medio de pago|pmp", re.I),
}


class AnalizadorGestiona(AnalizadorBase):
    """Analizador para portales Gestiona."""

    def analizar(
        self,
        entidad: Entidad,
        cliente: ClienteHttp,
        url_transparencia: str | None = None,
    ) -> List[Resultado]:
        resultados: List[Resultado] = []

        # Determinar URL de transparencia
        url_target = url_transparencia or entidad.url_transparencia
        if not url_target and entidad.url_sede:
            url_target = urllib.parse.urljoin(entidad.url_sede, "/transparency/")
        elif not url_target and entidad.url_web:
            url_target = urllib.parse.urljoin(entidad.url_web, "/transparency/")

        if not url_target:
            for c in COMPROBACIONES:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado="no_evaluable",
                        analizador="gestiona",
                        motivo="sin_url_sede_o_transparencia",
                    )
                )
            return resultados

        # Petición a la página de transparencia
        resp, robots_prohibe, err = cliente.get(url_target)
        if resp is None or resp.status_code >= 400:
            motivo_fallo = err or (f"http_{resp.status_code}" if resp else "sin_respuesta")
            for c in COMPROBACIONES:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        c,
                        estado="no_evaluable",
                        analizador="gestiona",
                        url_evidencia=url_target,
                        motivo=motivo_fallo,
                        robots_prohibe=robots_prohibe,
                    )
                )
            return resultados

        html = resp.text
        soup = BeautifulSoup(html, "html.parser")

        # C0: Portal accesible
        resultados.append(
            self.crear_resultado(
                entidad,
                "C0",
                estado="consta",
                analizador="gestiona",
                url_evidencia=resp.url,
                titulo_evidencia="Portal de transparencia Gestiona accesible",
                robots_prohibe=robots_prohibe,
                confianza="alta",
            )
        )

        # Extraer todos los nodos y enlaces del árbol
        elementos_arbol = []
        # Wicket suele usar elementos li, a, o div con clases de árbol
        for el in soup.find_all(["li", "div", "a", "tr"]):
            txt = el.get_text(" ", strip=True)
            if not txt:
                continue

            # Detectar recuento de documentos ej. (4) o [2]
            n_docs = None
            m_badge = re.search(r"\((\d+)\)|\[(\d+)\]", txt)
            if m_badge:
                n_docs = int(m_badge.group(1) or m_badge.group(2))

            # Extraer enlaces internos del nodo
            enlace = el.get("href") or (el.find("a") and el.find("a").get("href"))
            url_nodo = urllib.parse.urljoin(resp.url, enlace) if enlace else resp.url

            elementos_arbol.append({
                "texto": txt,
                "n_docs": n_docs,
                "url": url_nodo,
            })

        # Evaluar comprobaciones C1 a C15
        for cod_comp, regex_nodo in MAPEO_NODOS_GESTIONA.items():
            encontrado = False
            mejor_fecha: date | None = None
            mejor_regla: str | None = None
            mejor_titulo: str | None = None
            mejor_docs: int | None = None
            mejor_url: str | None = None

            for item in elementos_arbol:
                txt = item["texto"]
                if regex_nodo.search(txt):
                    encontrado = True
                    docs = item["n_docs"]
                    if docs is not None:
                        mejor_docs = max(mejor_docs or 0, docs)
                    mejor_titulo = txt[:120]
                    mejor_url = item["url"]

                    # Buscar fecha o año en el texto del nodo
                    d, regla = resolver_fecha_elemento(titulo=txt, texto_contenido=txt)
                    if d and (not mejor_fecha or d > mejor_fecha):
                        mejor_fecha = d
                        mejor_regla = regla

            if encontrado:
                # Si el nodo indica (0) documentos, cuenta como no_consta
                if mejor_docs == 0:
                    estado = "no_consta"
                    motivo = "seccion_existe_pero_sin_documentos"
                else:
                    estado = "consta"
                    motivo = None

                resultados.append(
                    self.crear_resultado(
                        entidad,
                        cod_comp,
                        estado=estado,
                        analizador="gestiona",
                        url_evidencia=mejor_url or resp.url,
                        fecha_ultima=mejor_fecha,
                        regla_fecha=mejor_regla,
                        titulo_evidencia=mejor_titulo,
                        n_elementos=mejor_docs,
                        motivo=motivo,
                        robots_prohibe=robots_prohibe,
                        confianza="alta" if mejor_docs is not None else "media",
                    )
                )
            else:
                resultados.append(
                    self.crear_resultado(
                        entidad,
                        cod_comp,
                        estado="no_consta",
                        analizador="gestiona",
                        url_evidencia=resp.url,
                        motivo="nodo_no_encontrado_en_arbol",
                        robots_prohibe=robots_prohibe,
                        confianza="media",
                    )
                )

        return resultados
