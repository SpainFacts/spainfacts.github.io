"""Gestor de robots.txt para el robot de transparencia de SpainFacts.

Cumple el RFC 9309 mediante la biblioteca Protego (reglas con comodines, fin de línea $,
y precedencia de la regla más específica).
"""

from __future__ import annotations

import logging
import time
import urllib.parse
from typing import Dict, Tuple

import requests
from protego import Protego

logger = logging.getLogger("transparencia_robot.robots")

DEFAULT_USER_AGENT = "SpainFactsTransparenciaBot/1.0 (+https://spainfacts.org/robot-transparencia)"


class RobotsManager:
    """Gestiona la descarga, análisis y caché de archivos robots.txt."""

    def __init__(
        self,
        user_agent: str = DEFAULT_USER_AGENT,
        session: requests.Session | None = None,
        cache_ttl_seconds: int = 86400,
        timeout: int = 10,
    ) -> None:
        self.user_agent = user_agent
        self.session = session or requests.Session()
        self.cache_ttl = cache_ttl_seconds
        self.timeout = timeout
        # netloc -> (parsed_protego, timestamp, http_status_or_err)
        self._cache: Dict[str, Tuple[Protego, float, int | str]] = {}

    def _get_base_url(self, url: str) -> Tuple[str, str]:
        parsed = urllib.parse.urlparse(url)
        scheme = parsed.scheme or "https"
        netloc = parsed.netloc
        base = f"{scheme}://{netloc}"
        return base, netloc

    def fetch_robots(self, url: str) -> Tuple[Protego, int | str]:
        """Obtiene y analiza el robots.txt del host de la URL dada."""
        base_url, netloc = self._get_base_url(url)
        now = time.time()

        if netloc in self._cache:
            rp, ts, code = self._cache[netloc]
            if now - ts < self.cache_ttl:
                return rp, code

        robots_url = f"{base_url}/robots.txt"
        headers = {
            "User-Agent": self.user_agent,
            "Accept": "text/plain, */*",
        }

        try:
            resp = self.session.get(robots_url, headers=headers, timeout=self.timeout, allow_redirects=True)
            status = resp.status_code
            if status == 200 and resp.text:
                rp = Protego.parse(resp.text)
            elif status in (401, 403):
                # Si el robots.txt está prohibido expresamente, se asume bloqueo preventivo
                rp = Protego.parse("User-agent: *\nDisallow: /")
            elif status == 404:
                # 404 significa que no hay restricciones
                rp = Protego.parse("User-agent: *\nAllow: /")
            elif 500 <= status < 600:
                # Error de servidor temporal
                rp = Protego.parse("User-agent: *\nAllow: /")
            else:
                rp = Protego.parse("User-agent: *\nAllow: /")
            self._cache[netloc] = (rp, now, status)
            return rp, status
        except Exception as e:
            logger.debug("No se pudo obtener robots.txt de %s: %s", base_url, e)
            rp = Protego.parse("User-agent: *\nAllow: /")
            self._cache[netloc] = (rp, now, "ERR")
            return rp, "ERR"

    def can_fetch(self, url: str) -> Tuple[bool, float | None, int | str]:
        """Comprueba si la URL está permitida por robots.txt y devuelve (permitido, crawl_delay, status)."""
        rp, status = self.fetch_robots(url)
        try:
            allowed = rp.can_fetch(url, self.user_agent)
            delay = rp.crawl_delay(self.user_agent)
            return allowed, delay, status
        except Exception as e:
            logger.debug("Error evaluando can_fetch con Protego en %s: %s", url, e)
            return True, None, "EVAL_ERR"
