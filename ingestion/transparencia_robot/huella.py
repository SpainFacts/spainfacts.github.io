"""Identificación de huella de plataforma y detección de enlaces de transparencia.

Reconoce las principales plataformas municipales:
- Gestiona (esPúblico, *.sedelectronica.es, *.eadministracio.cat)
- Seu-e (Consorci AOC, seu-e.cat)
- Sedipualba (Dip. Albacete, *.sedipualba.es)
- Dip. Ciudad Real (*-transparencia.dipucr.es, API pública)
- ANIMSA (Navarra, transparencia.animsa.es)
- Expert@ (Región de Murcia)
- SXC Galicia (sede.*.gal/sxc/)
- EPRINSA (Dip. Córdoba, transparencia.*.es)
- Gobierno de La Rioja (ayto*.larioja.org)
- Transparencia Local FEMP/Hacienda (*.transparencialocal.gob.es)
- Portales genéricos (WordPress, Drupal, Liferay, Plone, portales propios)
"""

from __future__ import annotations

import re
import urllib.parse
from typing import List, Tuple

from bs4 import BeautifulSoup

# Patrones para identificar plataformas por URL y contenido HTML
PATRONES_PLATAFORMA = {
    "gestiona": [
        re.compile(r"sedelectronica\.es|eadministracio\.cat|espublico\.com|portaltransparencia\.eu", re.I),
        re.compile(r"gestiona|wicket:interface", re.I),
    ],
    "aoc_seue": [
        re.compile(r"seu-e\.cat|consorciaoc|govern-obert-i-transparencia", re.I),
    ],
    "sedipualba": [
        re.compile(r"sedipualba\.es|dipualba\.es", re.I),
    ],
    "dipucr": [
        re.compile(r"transparencia\.dipucr\.es|dipucr\.es/portal/", re.I),
    ],
    "animsa": [
        re.compile(r"transparencia\.animsa\.es|animsa\.es", re.I),
    ],
    "expert_murcia": [
        re.compile(r"regiondemurcia\.es/web/transparencia|expert@", re.I),
    ],
    "sxc_galicia": [
        re.compile(r"sede\.[^/]+\.gal/sxc/|/sxc/gl/portal_transparencia", re.I),
    ],
    "eprinsa": [
        re.compile(r"eprinsa|transparencia\.[^/]+\.es/feed/", re.I),
    ],
    "larioja_wp": [
        re.compile(r"ayto[^/]+\.larioja\.org", re.I),
    ],
    "transparencialocal": [
        re.compile(r"transparencialocal\.gob\.es", re.I),
    ],
}

# Palabras clave multilingües de transparencia y gobierno abierto
RE_TRANSPARENCIA_LINK = re.compile(
    r"\b("
    r"transparencia|transpar[eè]ncia|transparenc|transpar|"
    r"gardentasun|gardentasuna|"
    r"goberno aberto|gobierno abierto|govern obert|"
    r"portal de transparencia|portal-transp|"
    r"publicidad activa|publicitat activa|publiscidade activa"
    r")\b",
    re.I,
)

# Detección de retos anti-bot / WAF
RE_WAF_CHALLENGE = re.compile(
    r"aws waf|cf-chl-bypass|challenge-form|cloudflare|recaptcha|hcaptcha|bot detection|access denied",
    re.I,
)


def detectar_plataforma(url: str, html: str | None = None) -> str:
    """Identifica el tipo de plataforma según la URL y el contenido HTML."""
    texto_evaluar = url
    if html:
        # Tomar los primeros 30KB de HTML para no saturar memoria
        texto_evaluar += " " + html[:30000]

    for plataforma, regex_list in PATRONES_PLATAFORMA.items():
        for rgx in regex_list:
            if rgx.search(texto_evaluar):
                return plataforma

    # Detección secundaria por gestores de contenido conocidos
    if html:
        h_lower = html[:15000].lower()
        if "wp-content" in h_lower or "wordpress" in h_lower:
            return "generico_wordpress"
        if "drupal" in h_lower:
            return "generico_drupal"
        if "liferay" in h_lower:
            return "generico_liferay"
        if "plone" in h_lower:
            return "generico_plone"

    return "generico"


def es_reto_waf(status_code: int, html: str | None = None) -> bool:
    """Determina si la respuesta corresponde a un cortafuegos o reto anti-robots."""
    if status_code == 202:
        return True  # Reto AWS WAF típico (ej. Málaga)
    if status_code in (403, 429) and html and RE_WAF_CHALLENGE.search(html[:10000]):
        return True
    return False


def extraer_enlaces_transparencia(url_base: str, html: str) -> List[Tuple[str, str]]:
    """Extrae enlaces que apuntan a secciones o portales de transparencia.

    Devuelve:
        Lista de tuplas (texto_enlace, url_absoluta)
    """
    if not html:
        return []

    soup = BeautifulSoup(html, "html.parser")
    enlaces_encontrados: list[Tuple[str, str]] = []
    vistos: set[str] = set()

    for a in soup.find_all("a", href=True):
        href = a["href"].strip()
        if not href or href.startswith("#") or href.startswith("javascript:") or href.startswith("mailto:"):
            continue

        texto = a.get_text(" ", strip=True) or a.get("title") or ""
        combinado = f"{texto} {href}"

        if RE_TRANSPARENCIA_LINK.search(combinado):
            url_abs = urllib.parse.urljoin(url_base, href)
            # Normalizar URL
            url_abs = url_abs.split("#")[0]
            if url_abs not in vistos:
                vistos.add(url_abs)
                enlaces_encontrados.append((texto[:80], url_abs))

    return enlaces_encontrados
