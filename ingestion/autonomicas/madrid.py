"""Elecciones a la Asamblea de Madrid por sección censal (Comunidad de Madrid), 1991-2023.

Fuente: portal de datos abiertos de la Comunidad de Madrid (CKAN), licencia CC BY 4.0.
Hay un conjunto por elección, «Datos electorales elecciones autonómicas Comunidad de
Madrid <año>», con un CSV por MESA (1995-2023), p. ej.

    https://datos.comunidad.madrid/dataset/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2023

y la serie del Instituto de Estadística «Elecciones. Asamblea. Municipios» /
«… Votos por candidaturas. Municipios» (1991-2023, por municipio), que es lo único que
hay para 1991 y la referencia oficial con la que se cuadran los totales:

    https://datos.comunidad.madrid/dataset/elecciones_asamblea
    https://datos.comunidad.madrid/dataset/elecciones_asamblea_votos_por_candidaturas

Se descargan los recursos por su enlace directo de CKAN (el portal a veces pone un
captcha en la vista de descarga; el enlace /resource/<id>/download/ no lo tiene).

Qué hay por elección
- 1983 y 1987: nada por debajo del total regional. La metodología del Instituto de
  Estadística lo dice expresamente («no se dispone de la desagregación territorial para
  las elecciones de 1983 y 1987»): no están en PROCESOS.
- 1991: solo por municipio (serie del Instituto) y con las candidaturas agrupadas en
  IU, PP, PSOE y «Resto de partidos» (siglas tal cual). Horcajo de la Sierra-Aoslos
  viene con «-» y no se carga; el CERA («9999 Sin municipio asignado») tampoco.
- 1999: CSV por mesa pero SIN distrito ni sección (cod_muni;municipio;mesa;…): se suma
  por municipio.
- 1995, mayo 2003, octubre 2003 (repetición tras el «tamayazo»), 2007, 2011, 2015,
  2019, 2021 (adelantada al 4 de mayo) y 2023: por mesa con distrito y sección.

Trampas del CSV por mesa (el formato cambia casi cada vez)
- Codificación Windows-1252, separador «;», CRLF.
- cod_muni es el código INE sin la provincia: con ceros («001») hasta 2021 y sin ceros
  («1») en 2023; 901-903 son los municipios 289xx. Distrito y sección, igual.
  CUSEC = '28' + muni(3) + distrito(2) + sección(3).
- La mesa (U, A, B, C, D, E) no parte la sección: se suman todas.
- CERA: cod_muni 999 (1995-2003, con nombres de municipio basura) o 990 «Residentes
  ausentes» (2007-2023; distrito 99 desde 2011, distrito 1 en 2007). Se descarta.
- Cabeceras distintas cada año: minúsculas hasta 2021, «Votos_blancos» en 2023;
  «votos_blanco» o «votos_blancos»; a veces hay votos_validos, votos_interv, etc. Las
  columnas de partido son siempre las que van DESPUÉS de votos_total.
- Votos a candidaturas = suma de las columnas de partido. En 1999 votos_total no es
  candidaturas+blancos+nulos (sobran ~4.400): no se usa.
- 1995: blancos con decimal («6,0») y una mesa (La Acebeda) con «s»; ahí se sacan de
  votos_validos − candidaturas (= 0).
- Censo de escrutinio: desde 2015 la columna «electores» ya es censo + certificaciones
  (hay «censo_inicial» aparte); hasta 2011 «electores» es el censo y las certificaciones
  (certif_censales / certif_alta / certif_correc) van aparte y se suman. Así cuadra con
  el oficial en 2003-oct, 2011, 2015-2023 y queda a 2 electores en 2007.
- Siglas tal cual vienen en la cabecera («P.P.», «C`s», «FE de las JONS»…); en 2023 la
  cabecera dice «FE DE LAS JONS» y el CSV de candidaturas «FE DE LA JONS».
"""

import csv
import io
from datetime import date

import requests

from ingestion.autonomicas import cache

COD_CCAA = "13"
SLUG = "madrid"
FUENTE = ("https://datos.comunidad.madrid/dataset/"
          "datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2023")
CABECERAS = {"User-Agent": "SpainFacts/1.0 (+https://spainfacts.github.io)"}

PROCESOS = [
    {"proceso": "A13199105", "fecha": date(1991, 5, 26), "eleccion": "Asamblea de Madrid, mayo de 1991"},
    {"proceso": "A13199505", "fecha": date(1995, 5, 28), "eleccion": "Asamblea de Madrid, mayo de 1995"},
    {"proceso": "A13199906", "fecha": date(1999, 6, 13), "eleccion": "Asamblea de Madrid, junio de 1999"},
    {"proceso": "A13200305", "fecha": date(2003, 5, 25), "eleccion": "Asamblea de Madrid, mayo de 2003"},
    {"proceso": "A13200310", "fecha": date(2003, 10, 26), "eleccion": "Asamblea de Madrid, octubre de 2003"},
    {"proceso": "A13200705", "fecha": date(2007, 5, 27), "eleccion": "Asamblea de Madrid, mayo de 2007"},
    {"proceso": "A13201105", "fecha": date(2011, 5, 22), "eleccion": "Asamblea de Madrid, mayo de 2011"},
    {"proceso": "A13201505", "fecha": date(2015, 5, 24), "eleccion": "Asamblea de Madrid, mayo de 2015"},
    {"proceso": "A13201905", "fecha": date(2019, 5, 26), "eleccion": "Asamblea de Madrid, mayo de 2019"},
    {"proceso": "A13202105", "fecha": date(2021, 5, 4), "eleccion": "Asamblea de Madrid, mayo de 2021"},
    {"proceso": "A13202305", "fecha": date(2023, 5, 28), "eleccion": "Asamblea de Madrid, mayo de 2023"},
]

_CKAN = "https://datos.comunidad.madrid/dataset/"
# CSV por mesa de cada elección (enlace directo /resource/<id>/download/).
URLS = {
    "A13199505": _CKAN + "8cd6c288-a517-4b5b-af60-36e0dc2e5a88/resource/0da8baf9-d326-4c79-9ba0-a1b0ecb8e41f/download/datos_electorales_elecciones_autonomicas_cm_1995.csv",
    "A13199906": _CKAN + "6adc27f5-93ac-4066-a011-56068c8de954/resource/d0c37184-84f4-4218-8d2c-c23926dcd9ec/download/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_1999.csv",
    "A13200305": _CKAN + "c882a4cd-7e90-48dd-b7fd-a481f8a6a719/resource/78ab15a5-1a31-4d27-9b81-1d9ee124c278/download/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_mayo_2003.csv",
    "A13200310": _CKAN + "2b3a2990-780b-4b79-b51f-bf0cd838d053/resource/1c848c72-efd8-46c3-be1d-e940409fb758/download/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_octubre_2003.csv",
    "A13200705": _CKAN + "ca19705e-ae0a-4773-b42e-5844bca264b8/resource/d8c7796d-4276-4fd5-9534-3a607f19ff06/download/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2007.csv",
    "A13201105": _CKAN + "519a9b2e-6590-42c3-8db0-a66329964c2d/resource/eaed6f44-e049-47f8-aee5-b2e16d7a60b9/download/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2011.csv",
    "A13201505": _CKAN + "876a42fb-18e4-4fde-a7fc-09ecb9dc28b8/resource/492abd37-a319-4606-a009-bd0f7dfc28a2/download/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2015.csv",
    "A13201905": _CKAN + "ea98e6c9-f1e0-472b-b2c4-f21e679e70ff/resource/642dd147-a4e4-4fa9-b82e-a0b4f50baab6/download/datos_electorales_elecciones_autonomicas_madrid_2019.csv",
    "A13202105": _CKAN + "08aac4de-ca28-4f9c-b45d-ef8457c4b5d2/resource/5e8cf4ad-b9f4-4ffd-a026-c27433e7815f/download/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2021.csv",
    "A13202305": _CKAN + "23a6a982-110a-4f87-859f-4c036e493aac/resource/9a7c670b-7d20-4ddd-93ba-d21ad5f85653/download/datos_electorales_elecciones_autonomicas_comunidad_de_madrid_2023.csv",
}
# Serie del Instituto de Estadística por municipio (1991-2023).
SERIE = {
    "participacion": _CKAN + "1e80b4d4-f949-4a60-bda1-9ac2ebc3a637/resource/b1136f11-47d4-4acc-8dc6-3e3ff3a9bb69/download/elecciones.-asamblea.-municipios.csv",
    "candidaturas": _CKAN + "6e1cd790-c1c0-42f0-99e1-b1f9879bde27/resource/d15a8810-704d-443d-ac24-3f6b14727324/download/elecciones.-asamblea.-votos-por-candidaturas.-municipios.csv",
}
SOLO_SERIE = {"A13199105"}          # sin fichero por mesa: municipios de la serie
CERA = {"990", "999"}


def _entero(v: str) -> int:
    v = (v or "").strip().replace(".", "").replace(",", ".")
    return int(float(v)) if v else 0


def _bajar(url: str, destino, inicio: bytes):
    if not destino.exists():
        r = requests.get(url, headers=CABECERAS, timeout=120)
        r.raise_for_status()
        if not r.content.startswith(inicio):
            raise ValueError(f"Respuesta inesperada (¿captcha?) al bajar {url}")
        destino.write_bytes(r.content)
    return destino.read_bytes().decode("cp1252")


def _mesas(proceso: str) -> tuple[list[str], list[dict]]:
    """Mesas sin CERA, ya normalizadas, y lista de siglas (CSV en caché)."""
    texto = _bajar(URLS[proceso], cache(SLUG) / f"{proceso}.csv", b"cod_muni;")
    lector = csv.reader(io.StringIO(texto), delimiter=";")
    cabecera = [c.strip() for c in next(lector)]
    if len(set(cabecera)) != len(cabecera):
        raise ValueError(f"{proceso}: columnas repetidas en la cabecera")
    baja = [c.lower() for c in cabecera]
    i_total = baja.index("votos_total")
    siglas = [c for c in cabecera[i_total + 1:] if c]
    col = {c: i for i, c in enumerate(baja)}
    i_blanco = next(i for i, c in enumerate(baja) if c.startswith("votos_blanco"))
    certifs = [i for i, c in enumerate(baja) if c.startswith("certif")]
    # Desde 2015 «electores» ya incluye las certificaciones (hay «censo_inicial» o, en
    # 2023, «censo» aparte); hasta 2011 no, y se suman.
    sumar_certif = "censo_inicial" not in col and "censo" not in col
    con_seccion = "seccion" in col
    i_partidos = [cabecera.index(s) for s in siglas]
    filas = []
    for f in lector:
        if not f or not f[0].strip():
            continue
        muni = f[col["cod_muni"]].strip().zfill(3)
        if muni in CERA:
            continue
        distrito = f[col["distrito"]].strip() if "distrito" in col else ""
        if distrito == "99":
            continue
        votos = {s: _entero(f[i]) for s, i in zip(siglas, i_partidos)}
        cand = sum(votos.values())
        try:
            blancos = _entero(f[i_blanco])
        except ValueError:            # 1995, La Acebeda: «s»
            blancos = _entero(f[col["votos_validos"]]) - cand
        censo = _entero(f[col["electores"]])
        if sumar_certif:
            censo += sum(_entero(f[i]) for i in certifs)
        filas.append({
            "cod_mun": "28" + muni,
            "cod_seccion": ("28" + muni + distrito.zfill(2) + f[col["seccion"]].strip().zfill(3)
                            if con_seccion else None),
            "censo": censo, "votos_blanco": blancos, "votos_nulos": _entero(f[col["votos_nulos"]]),
            "votos_candidaturas": cand, "votos": votos,
        })
    return siglas, filas


def _sumar(filas, clave: str):
    acc: dict[str, dict] = {}
    votos: dict[tuple[str, str], int] = {}
    for f in filas:
        a = acc.setdefault(f[clave], {clave: f[clave], "censo": 0, "votos_blanco": 0,
                                      "votos_nulos": 0, "votos_candidaturas": 0})
        for k in ("censo", "votos_blanco", "votos_nulos", "votos_candidaturas"):
            a[k] += f[k]
        for s, n in f["votos"].items():
            if n:
                votos[(f[clave], s)] = votos.get((f[clave], s), 0) + n
    return list(acc.values()), [{clave: c, "siglas": s, "votos": n} for (c, s), n in votos.items()]


def _con_seccion(proceso: str) -> bool:
    return proceso in URLS and proceso != "A13199906"


def secciones(proceso: str):
    if not _con_seccion(proceso):
        return []
    return _sumar(_mesas(proceso)[1], "cod_seccion")[0]


def votos(proceso: str):
    if not _con_seccion(proceso):
        return []
    return _sumar(_mesas(proceso)[1], "cod_seccion")[1]


# --- Serie del Instituto de Estadística (1991 y comprobación) -----------------------

def _serie(nombre: str) -> list[list[str]]:
    texto = _bajar(SERIE[nombre], cache(SLUG) / f"serie_{nombre}.csv", "Año".encode("cp1252"))
    return list(csv.reader(io.StringIO(texto), delimiter=";"))[1:]


def _serie_municipios(anio: str):
    """{cod_mun: {medida: valor}} y {cod_mun: {siglas: votos}} de la serie, sin CERA."""
    part: dict[str, dict] = {}
    cand: dict[str, dict] = {}
    for destino, nombre in ((part, "participacion"), (cand, "candidaturas")):
        for f in _serie(nombre):
            if f[0] != anio or f[1] != "Municipios" or f[2] == "9999":
                continue
            v = f[5].strip()
            destino.setdefault("28" + f[2][:3], {})[f[4]] = int(v) if v.lstrip("-").isdigit() else None
    return part, cand


def municipios(proceso: str):
    if proceso == "A13199906":
        return _sumar(_mesas(proceso)[1], "cod_mun")[0]
    if proceso not in SOLO_SERIE:
        return []
    part, _ = _serie_municipios(proceso[3:7])
    filas = []
    for cod, m in part.items():
        valores = [m.get(k) for k in ("Electores", "Votos en blanco", "Votos nulos", "Votos a candidaturas")]
        if None in valores:          # «-»: Horcajo de la Sierra-Aoslos en 1991
            continue
        filas.append({"cod_mun": cod, "censo": valores[0], "votos_blanco": valores[1],
                      "votos_nulos": valores[2], "votos_candidaturas": valores[3]})
    return filas


def votos_municipios(proceso: str):
    if proceso == "A13199906":
        return _sumar(_mesas(proceso)[1], "cod_mun")[1]
    if proceso not in SOLO_SERIE:
        return []
    _, cand = _serie_municipios(proceso[3:7])
    return [{"cod_mun": cod, "siglas": s, "votos": n}
            for cod, d in cand.items() for s, n in d.items() if n]


def comparar_oficial() -> None:
    """Totales del módulo (sin CERA) frente a la fila «Comunidad de Madrid» de la serie
    oficial del Instituto de Estadística (que incluye el CERA). La serie no tiene mayo de
    2003: su fila de 2003 es la repetición de octubre."""
    oficial: dict[str, dict] = {}
    for f in _serie("participacion"):
        if f[1] == "Comunidad de Madrid":
            oficial.setdefault(f[0], {})[f[4]] = int(f[5])
    print("\nproceso    | candidaturas módulo | oficial (con CERA) | diferencia")
    for p in PROCESOS:
        pr = p["proceso"]
        filas = list(secciones(pr)) or list(municipios(pr))
        n = sum(r["votos_candidaturas"] for r in filas)
        o = oficial.get(pr[3:7], {}).get("Votos a candidaturas") if pr != "A13200305" else None
        dif = f"{n - o:+,} ({100 * (n - o) / o:+.2f} %)" if o else "sin serie oficial"
        print(f"{pr} | {n:>19,} | {o or 0:>18,} | {dif}")


if __name__ == "__main__":
    from ingestion.autonomicas import probar
    import sys
    probar(sys.modules[__name__])
    comparar_oficial()
