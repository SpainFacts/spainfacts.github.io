"""Cliente HTTP respetuoso y auditable para el robot de portales de transparencia.

Características:
- Identificación clara: User-Agent SpainFactsTransparenciaBot/1.0.
- Comprobación y registro de robots.txt con Protego.
- Limitación de tasa (rate-limiting) por host y por plataforma multi-inquilino.
- Soporte para archivo de evidencias en formato estándar WARC (warcio).
- Manejo robusto de errores TLS, caídas de red y reintentos con espera exponencial.
"""

from __future__ import annotations

import io
import logging
import os
import re
import threading
import time
import urllib.parse
from typing import Tuple

import requests
import urllib3
from requests.adapters import HTTPAdapter
from urllib3.util import Retry
from warcio.statusandheaders import StatusAndHeaders
from warcio.warcwriter import WARCWriter

from ingestion.transparencia_robot.robots import DEFAULT_USER_AGENT, RobotsManager

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

logger = logging.getLogger("transparencia_robot.cliente")

# Dominios de plataformas multi-inquilino que comparten infraestructura
PLATAFORMAS_COMPARTIDAS = (
    "sedelectronica.es",
    "eadministracio.cat",
    "sedipualba.es",
    "seu-e.cat",
    "transparencialocal.gob.es",
    "dipucr.es",
    "animsa.es",
)


class ClienteHttp:
    """Cliente HTTP con control de tasa, integración de robots.txt y guardado WARC."""

    def __init__(
        self,
        user_agent: str = DEFAULT_USER_AGENT,
        pausa_host_segundos: float = 2.0,
        pausa_plataforma_segundos: float = 1.0,
        warc_path: str | None = None,
        timeout: int = 30,
    ) -> None:
        self.user_agent = user_agent
        self.pausa_host = pausa_host_segundos
        self.pausa_plataforma = pausa_plataforma_segundos
        self.timeout = timeout
        self.warc_path = warc_path

        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": self.user_agent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "es-ES,es;q=0.9,ca;q=0.8,gl;q=0.7,eu;q=0.6",
        })

        retries = Retry(
            total=2,
            connect=0,
            read=0,
            redirect=3,
            status_forcelist=[429, 500, 502, 503, 504],
            raise_on_status=False,
        )
        adapter = HTTPAdapter(max_retries=retries)
        self.session.mount("https://", adapter)
        self.session.mount("http://", adapter)

        self.robots = RobotsManager(user_agent=self.user_agent, session=self.session)

        # Control de tiempo de peticiones
        self._lock = threading.Lock()
        self._ultimas_peticiones_host: dict[str, float] = {}
        self._ultimas_peticiones_plataforma: dict[str, float] = {}

        # Escritor WARC
        self._warc_file = None
        self._warc_writer = None
        if self.warc_path:
            os.makedirs(os.path.dirname(os.path.abspath(self.warc_path)), exist_ok=True)
            self._warc_file = open(self.warc_path, "ab")
            self._warc_writer = WARCWriter(self._warc_file, gzip=True)

    def close(self) -> None:
        if self._warc_file:
            try:
                self._warc_file.close()
            except Exception:
                pass
        self.session.close()

    def _esperar_turno(self, url: str) -> None:
        """Aplica las pausas de cortesía según host y plataforma multi-inquilino."""
        parsed = urllib.parse.urlparse(url)
        netloc = parsed.netloc.lower()

        # Determinar si pertenece a una plataforma multi-inquilino
        plataforma_encontrada = None
        for p in PLATAFORMAS_COMPARTIDAS:
            if netloc.endswith(p):
                plataforma_encontrada = p
                break

        with self._lock:
            now = time.time()
            demora = 0.0

            # 1. Comprobar host
            ultimo_host = self._ultimas_peticiones_host.get(netloc, 0.0)
            tiempo_desde_host = now - ultimo_host
            if tiempo_desde_host < self.pausa_host:
                demora = max(demora, self.pausa_host - tiempo_desde_host)

            # 2. Comprobar plataforma global
            if plataforma_encontrada:
                ultimo_plat = self._ultimas_peticiones_plataforma.get(plataforma_encontrada, 0.0)
                tiempo_desde_plat = now - ultimo_plat
                if tiempo_desde_plat < self.pausa_plataforma:
                    demora = max(demora, self.pausa_plataforma - tiempo_desde_plat)

            if demora > 0:
                time.sleep(demora)

            marcador = time.time()
            self._ultimas_peticiones_host[netloc] = marcador
            if plataforma_encontrada:
                self._ultimas_peticiones_plataforma[plataforma_encontrada] = marcador

    def _grabar_warc(self, resp: requests.Response) -> None:
        """Guarda la respuesta HTTP en el archivo WARC activo."""
        if not self._warc_writer:
            return
        try:
            headers_list = [(k, v) for k, v in resp.headers.items()]
            status_line = f"{resp.status_code} {resp.reason or 'OK'}"
            http_headers = StatusAndHeaders(status_line, headers_list, protocol="HTTP/1.1")
            payload = io.BytesIO(resp.content)
            record = self._warc_writer.create_warc_record(
                resp.url,
                "response",
                payload=payload,
                http_headers=http_headers,
            )
            with self._lock:
                self._warc_writer.write_record(record)
                if self._warc_file:
                    self._warc_file.flush()
        except Exception as e:
            logger.debug("Error grabando WARC para %s: %s", resp.url, e)

    def get(
        self,
        url: str,
        respetar_robots: bool = False,
        timeout: int | None = None,
    ) -> Tuple[requests.Response | None, bool, str | None]:
        """Realiza una petición GET.

        Devuelve:
            (respuesta, robots_prohibe, error_o_motivo)
        """
        if not url.startswith("http://") and not url.startswith("https://"):
            url = "https://" + url.lstrip("/")

        allowed, delay, robots_code = self.robots.can_fetch(url)
        robots_prohibe = not allowed

        if respetar_robots and robots_prohibe:
            return None, True, "robots_disallow"

        # Respetar crawl-delay del robots.txt si es superior al configurado
        if delay and delay > self.pausa_host:
            time.sleep(min(delay, 10.0))

        self._esperar_turno(url)

        t = timeout or self.timeout
        try:
            resp = self.session.get(url, timeout=t, allow_redirects=True, verify=True)
            self._grabar_warc(resp)
            return resp, robots_prohibe, None
        except requests.exceptions.SSLError:
            # Reintento sin verificar SSL (muchos ayuntamientos tienen certificados caducados o mal configurados)
            try:
                resp = self.session.get(url, timeout=t, allow_redirects=True, verify=False)
                self._grabar_warc(resp)
                return resp, robots_prohibe, "ssl_insecure"
            except Exception as e2:
                return None, robots_prohibe, f"ssl_error: {type(e2).__name__}"
        except requests.exceptions.Timeout:
            return None, robots_prohibe, "timeout"
        except requests.exceptions.ConnectionError as ce:
            return None, robots_prohibe, f"connection_error: {type(ce).__name__}"
        except Exception as e:
            return None, robots_prohibe, f"error: {type(e).__name__}"
