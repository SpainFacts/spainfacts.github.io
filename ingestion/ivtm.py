"""Tarifas del IVTM (impuesto de circulación) de turismos, por municipio.

Fuente: Ministerio de Hacienda, Secretaría General de Financiación Autonómica
y Local, «Consulta de información impositiva municipal»
   https://serviciostelematicosext.hacienda.gob.es/SGFAL/ConsultaTipos/aspx/listado_municipiosm.aspx
Los ayuntamientos comunican cada año sus tipos y tarifas (IBI, IAE, ICIO,
IVTM, plusvalía) y la herramienta los enseña en una ficha por municipio.

Es una aplicación ASP.NET WebForms, sin API: hay que reproducir las
«postbacks» del formulario guardando la cookie de sesión y devolviendo los
campos ocultos (__VIEWSTATE, __EVENTVALIDATION...) de la página anterior:
  1) GET listado_municipiosm.aspx: provincias, municipios (de Albacete) y años.
  2) POST con __EVENTTARGET = lbProvincias y la provincia elegida: la página
     vuelve con la lista de municipios de esa provincia. Los valores de la
     lista son los 3 dígitos del código INE y el texto lleva el artículo al
     final («Hiruela (La)»), así que se comprueba también el nombre.
  3) POST con provincia, municipio, año y el botón «Consulta web municipio»:
     el servidor guarda la elección en la sesión y responde 302 a
     formulario_consultam2022.aspx, la ficha completa del municipio. Si no hay
     datos de ese año vuelve al listado con ?error=...
Con el estado de la página del paso 2 se pueden pedir varios municipios
seguidos de la misma provincia.

En la ficha, el cuadro «Vehículos de tracción mecánica (tarifas)» trae, para
turismos, las casillas C18-C22 (<8 CV, 8-11,99, 12-15,99, 16-19,99, >=20 CV
fiscales) con dos columnas: el año pedido (input C18...) y el anterior (span
C18_ant). Son las cuotas de la tarifa en euros al año, ya con el coeficiente
municipal (art. 95 TRLRHL: cuota mínima x coeficiente de hasta 2). Las
bonificaciones (vehículos eléctricos, históricos...) no aparecen.

Se pide el último año (ANIO); si el municipio no lo ha comunicado, el anterior.
Las fichas en bruto se guardan en data/ivtm_cache/ y no se vuelven a pedir.
Salida: transform/seeds/movilidad_ivtm_municipios.csv

Uso: python -m ingestion.ivtm
"""

import csv
import html
import logging
import re
import time
import unicodedata
from pathlib import Path

import requests

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE = REPO_ROOT / "data" / "ivtm_cache"
SALIDA = REPO_ROOT / "transform" / "seeds" / "movilidad_ivtm_municipios.csv"

log = logging.getLogger(__name__)

URL = "https://serviciostelematicosext.hacienda.gob.es/SGFAL/ConsultaTipos/aspx/listado_municipiosm.aspx"
CABECERAS = {"User-Agent": "spainfacts.org (datos abiertos; contacto en github.com/SpainFacts)"}
PAUSA = 1.5  # segundos entre peticiones al servidor de Hacienda
ANIO = 2026
P = "ctl00$MainContentPlaceHolder$"

# Municipios que se consultan: código INE (provincia + municipio) y nombre.
MUNICIPIOS = [
    ("28006", "Alcobendas"),
    ("28090", "Moralzarzal"),
    ("28080", "Majadahonda"),
    ("28169", "Venturada"),
    ("28125", "Robledo de Chavela"),
    ("28026", "Brunete"),
    ("28022", "Boadilla del Monte"),
    ("28093", "Navacerrada"),
    ("03069", "Finestrat"),
    ("28107", "Patones"),
    ("28046", "Collado Mediano"),
    ("28128", "Rozas de Puerto Real"),
    ("28079", "Madrid"),
    ("35025", "Tejeda"),
    ("35016", "Las Palmas de Gran Canaria"),
    ("08002", "Aguilar de Segarra"),
    ("08019", "Barcelona"),
    ("28069", "La Hiruela"),
    ("28151", "Torrelaguna"),
    ("29074", "Montejaque"),
    ("08178", "Rajadell"),
    ("07019", "Escorca"),
    ("45021", "Borox"),
    ("07040", "Palma"),
    ("30030", "Murcia"),
    ("03030", "Benidoleig"),
    ("46250", "València"),
    ("12103", "la Serratella"),
    ("29067", "Málaga"),
    ("08114", "Martorell"),
    ("03014", "Alicante/Alacant"),
    ("12040", "Castelló de la Plana"),
    ("45168", "Toledo"),
]

# Casillas de la ficha -> columnas de salida (cuota anual en euros).
CASILLAS = {
    "C18": "turismo_menos_8",
    "C19": "turismo_8_12",
    "C20": "turismo_12_16",
    "C21": "turismo_16_20",
    "C22": "turismo_20_mas",
}
# Cuotas mínimas del art. 95.1 TRLRHL (coeficiente 1); el máximo es el doble.
MINIMAS = {"C18": 12.62, "C19": 34.08, "C20": 71.94, "C21": 89.61, "C22": 112.00}


def _normaliza(nombre: str) -> str:
    """Nombre comparable: sin tildes ni mayúsculas y con el artículo delante."""
    nombre = html.unescape(nombre).strip()
    m = re.fullmatch(r"(.*?)\s*\((\w+)\)", nombre)  # «Hiruela (La)» -> «La Hiruela»
    if m:
        nombre = f"{m.group(2)} {m.group(1)}"
    nombre = unicodedata.normalize("NFKD", nombre.lower())
    nombre = "".join(c for c in nombre if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]+", " ", nombre).strip()


def _ocultos(texto: str) -> dict:
    return {
        m.group(1): html.unescape(m.group(2))
        for m in re.finditer(r'<input type="hidden" name="([^"]+)" id="[^"]*" value="([^"]*)"', texto)
    }


def _opciones(texto: str, campo: str) -> dict:
    """{valor: texto} de las opciones de una lista del formulario."""
    m = re.search(rf'<select[^>]*name="{re.escape(P + campo)}".*?</select>', texto, re.S)
    if not m:
        return {}
    return {
        v: re.sub(r"^\d+\s+", "", html.unescape(t)).strip()
        for v, t in re.findall(r'<option[^>]*value="([^"]*)">([^<]*)</option>', m.group(0))
    }


class Consulta:
    """Sesión con la herramienta de Hacienda (cookie + estado del formulario)."""

    def __init__(self):
        self.s = requests.Session()
        self.s.headers.update(CABECERAS)
        self.ultima = 0.0
        self.provincia = None
        self.estado = None  # HTML del listado con la provincia ya elegida

    def _pide(self, metodo: str, **kw) -> requests.Response:
        espera = PAUSA - (time.monotonic() - self.ultima)
        if espera > 0:
            time.sleep(espera)
        r = self.s.request(metodo, URL, headers=CABECERAS, timeout=60, **kw)
        self.ultima = time.monotonic()
        if r.status_code in (403, 429) or "captcha" in r.text.lower():
            raise RuntimeError(f"Hacienda ha bloqueado la consulta ({r.status_code}); se para aquí")
        r.raise_for_status()
        return r

    def elige_provincia(self, prov: str):
        if self.provincia == prov:
            return
        inicio = self._pide("GET").text
        datos = _ocultos(inicio)
        datos.update({
            "__EVENTTARGET": P + "lbProvincias",
            "__EVENTARGUMENT": "",
            P + "lbProvincias": prov,
            P + "lbAno": str(ANIO),
        })
        self.estado = self._pide("POST", data=datos).text
        self.provincia = prov

    def municipios(self) -> dict:
        return _opciones(self.estado, "lbMunicipios")

    def ficha(self, prov: str, mun: str, anio: int) -> str | None:
        """HTML de la ficha del municipio, o None si no hay datos de ese año."""
        datos = _ocultos(self.estado)
        datos.update({
            P + "lbProvincias": prov,
            P + "lbMunicipios": mun,
            P + "lbAno": str(anio),
            P + "Boton_aceptar": "Consulta web municipio",
        })
        r = self._pide("POST", data=datos)
        if "formulario_consulta" not in r.url:
            return None
        return r.content.decode("utf-8", errors="replace")


def _cuotas(ficha: str) -> dict:
    """Cuotas de turismos del año pedido (los input C18-C22; el span _ant es el año anterior)."""
    fila = {}
    for casilla, columna in CASILLAS.items():
        m = re.search(rf'<input name="{re.escape(P + casilla)}"[^>]*value="([^"]*)"', ficha)
        valor = m.group(1).strip() if m else ""
        if "," in valor:  # coma decimal, punto de miles
            valor = valor.replace(".", "").replace(",", ".")
        fila[columna] = float(valor) if valor else None
    return fila


def _codigo_ficha(ficha: str) -> str:
    m = re.search(r'id="MainContentPlaceHolder_LBL_codigo"[^>]*>([^<]*)<', ficha)
    return m.group(1).replace("-", "").strip() if m else ""


def _busca_municipio(consulta: Consulta, cod: str, nombre: str) -> str | None:
    """Código de 3 dígitos en la herramienta: el del INE si el nombre cuadra; si no, por nombre."""
    opciones = consulta.municipios()
    buscado = _normaliza(nombre)
    if cod[2:] in opciones:
        if _normaliza(opciones[cod[2:]]) != buscado:
            log.warning("%s: la herramienta lo llama «%s» (esperado «%s»)", cod, opciones[cod[2:]], nombre)
        return cod[2:]
    for valor, texto in opciones.items():
        if _normaliza(texto) == buscado:
            log.warning("%s %s: aparece con otro código (%s)", cod, nombre, valor)
            return valor
    return None


def descarga() -> tuple[list[dict], list[str]]:
    CACHE.mkdir(parents=True, exist_ok=True)
    consulta = Consulta()
    filas, fallos = [], []
    for cod, nombre in sorted(MUNICIPIOS, key=lambda x: x[0]):
        prov = cod[:2]
        fila = None
        for anio in (ANIO, ANIO - 1):
            cache = CACHE / f"{cod}_{anio}.html"
            sin_datos = CACHE / f"{cod}_{anio}.sindatos"
            if sin_datos.exists():
                continue
            if cache.exists():
                ficha = cache.read_text(encoding="utf-8")
            else:
                consulta.elige_provincia(prov)
                mun = _busca_municipio(consulta, cod, nombre)
                if mun is None:
                    log.error("%s %s: no está en la lista de la provincia %s", cod, nombre, prov)
                    break
                ficha = consulta.ficha(prov, mun, anio)
                if ficha is None:
                    log.info("%s %s: sin datos de %s", cod, nombre, anio)
                    sin_datos.touch()
                    continue
                cache.write_text(ficha, encoding="utf-8")
            if _codigo_ficha(ficha) not in ("", prov + cod[2:]):
                log.warning("%s: la ficha es del municipio %s", cod, _codigo_ficha(ficha))
            cuotas = _cuotas(ficha)
            if all(v is None for v in cuotas.values()):
                log.info("%s %s: ficha de %s sin tarifas de IVTM", cod, nombre, anio)
                continue
            fila = {"cod_mun": cod, "municipio": nombre, "anio": anio, **cuotas}
            break
        if fila is None:
            fallos.append(f"{cod} {nombre}")
            continue
        for casilla, columna in CASILLAS.items():
            v = fila[columna]
            if v is not None and not (MINIMAS[casilla] - 0.01 <= v <= 2 * MINIMAS[casilla] + 0.01):
                log.warning("%s %s: %s = %s fuera del rango legal [%s, %s]",
                            cod, nombre, columna, v, MINIMAS[casilla], 2 * MINIMAS[casilla])
        filas.append(fila)
        log.info("%s %s (%s): %s", cod, nombre, fila["anio"], [fila[c] for c in CASILLAS.values()])
    return filas, fallos


def escribe(filas: list[dict]):
    columnas = ["cod_mun", "municipio", "anio", *CASILLAS.values()]
    with SALIDA.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=columnas, lineterminator="\n")
        w.writeheader()
        for fila in filas:
            w.writerow({k: ("" if fila[k] is None else f"{fila[k]:.2f}" if k in CASILLAS.values() else fila[k])
                        for k in columnas})


def main():
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    filas, fallos = descarga()
    escribe(filas)
    log.info("%d municipios escritos en %s", len(filas), SALIDA.relative_to(REPO_ROOT))
    if fallos:
        log.warning("Sin datos: %s", ", ".join(fallos))


if __name__ == "__main__":
    main()
