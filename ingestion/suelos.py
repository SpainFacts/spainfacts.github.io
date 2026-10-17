"""Fuente dlt de los suelos agrarios de España y de Europa (tema `suelos`).

Qué suelo hay debajo de los cultivos: textura (arcilloso, franco, arenoso...), grupo de suelo de
la clasificación WRB (calcisoles, cambisoles...), pH y carbono orgánico, por provincia, comunidad,
país europeo y tipo de cultivo. Todo se calcula sobre una rejilla de 1 km en la proyección
europea de igual área (ETRS89-LAEA, EPSG:3035), así que cada celda pesa lo mismo.

1) SoilGrids 2.0 (ISRIC, CC BY 4.0), https://files.isric.org/soilgrids/latest/:
   - data_aggregated/1000m: arcilla, limo y arena (g/kg), pH en agua (pH x 10) y carbono orgánico
     del suelo (dg/kg), medias a 1 km de los mapas de 250 m, en Goode Homolosine. Se toman las
     capas 0-5, 5-15 y 15-30 cm y se promedian por espesor (5, 10 y 15 cm): la capa arable.
   - data/wrb/MostProbable.vrt: grupo de suelo WRB más probable (0..29 por orden alfabético del
     grupo: Acrisols, Albeluvisols...), 250 m en EPSG:4326; se lee la vista general de 500 m.
   SoilGrids es un modelo estadístico (perfiles de suelo + covariables de satélite), no un
   muestreo: suaviza los extremos y vale para comparar zonas, no parcelas.
2) CORINE Land Cover 2018 (Copernicus, EEA), servicio de mapas de la EEA
   (image.discomap.eea.europa.eu, CLC2018_LAEA, capa ráster 100 m). El servicio no da los
   códigos, pero pinta cada clase con su color oficial y sin suavizar: se pide la imagen a 250 m
   (16 muestras por celda de 1 km) y se traduce el color a la clase. La superficie agraria son
   las clases 2xx (tierras de labor, cultivos permanentes, prados y zonas agrícolas
   heterogéneas, dehesas incluidas). Unidad mínima cartografiada: 25 ha.
3) Fronteras: provincias de static/geo/provincias.geojson (con el código INE de la comunidad) y
   países de GISCO (Eurostat, CNTR_RG_20M_2020 en EPSG:3035; Grecia = EL, Reino Unido = UK).

Recursos (replace):
  suelos_medias   ámbito (pais/ccaa/provincia), código, cultivo: km² agrarios y medias de
                  arcilla, limo, arena, pH, carbono y materia orgánica
  suelos_clases   ámbito, código, cultivo, dimensión (textura, textura_grupo, ph, mo, wrb),
                  clase: km² agrarios
  suelos_rejilla  celdas de 10 km de España con superficie agraria: textura, grupo WRB y
                  cultivo dominantes y medias
  suelos_municipio  municipio (código INE) y cultivo: km² del término y agrarios, medias, clases
                  dominantes y % de tierras fuertes, arcillosas, arenosas, básicas, ácidas y
                  calcisoles. La superficie sale de las muestras de 250 m de CORINE dentro de cada
                  término (static/geo/municipios.geojson) y el suelo, de su celda de 1 km.

El cálculo (unos 4 minutos y 2 GB de memoria, casi todo descargas) se guarda en data/suelos_cache/: los mapas de
SoilGrids y CORINE 2018 no cambian, solo se rehace si se borra la caché o si cambia VERSION.
"""

import io
import json
import logging
import time
from pathlib import Path

import dlt
import numpy as np
import requests

log = logging.getLogger(__name__)

REPO_ROOT = Path(__file__).resolve().parent.parent
CACHE = REPO_ROOT / "data" / "suelos_cache"
VERSION = 2  # súbela si cambia el cálculo para que no se use la caché

CABECERAS = {"User-Agent": "spainfacts.org (datos abiertos; contacto en github.com/SpainFacts)"}
SOILGRIDS = "https://files.isric.org/soilgrids/latest/"
CLC_EXPORT = "https://image.discomap.eea.europa.eu/arcgis/rest/services/Corine/CLC2018_LAEA/MapServer/export"
GISCO = "https://gisco-services.ec.europa.eu/distribution/v2/countries/geojson/CNTR_RG_20M_2020_3035.geojson"

# Rejillas de 1 km en EPSG:3035: (x mínima, y máxima, ancho, alto) en km. Europa llega de
# Portugal y Islandia excluida a Chipre y del Cabo Norte a Malta; Canarias va aparte.
REJILLAS = {
    "europa": (2500, 5520, 4100, 4120),
    "canarias": (1520, 1230, 550, 380),
}
CELDA = 1000  # m
SUB = 4  # muestras de CORINE por lado de celda (250 m)

PROFUNDIDADES = [("0-5cm", 5), ("5-15cm", 10), ("15-30cm", 15)]
VARIABLES = ["clay", "silt", "sand", "phh2o", "soc"]

# Colores oficiales de la leyenda CORINE -> clase
CLC_COLORES = {
    (230, 0, 77): 111, (255, 0, 0): 112, (204, 77, 242): 121, (204, 0, 0): 122, (230, 204, 204): 123,
    (230, 204, 230): 124, (166, 0, 204): 131, (166, 77, 0): 132, (255, 77, 255): 133, (255, 166, 255): 141,
    (255, 230, 255): 142, (255, 255, 168): 211, (255, 255, 0): 212, (230, 230, 0): 213, (230, 128, 0): 221,
    (242, 166, 77): 222, (230, 166, 0): 223, (230, 230, 77): 231, (255, 230, 166): 241, (255, 230, 77): 242,
    (230, 204, 77): 243, (242, 204, 166): 244, (128, 255, 0): 311, (0, 166, 0): 312, (77, 255, 0): 313,
    (204, 242, 77): 321, (166, 255, 128): 322, (166, 230, 77): 323, (166, 242, 0): 324, (230, 230, 230): 331,
    (204, 204, 204): 332, (204, 255, 204): 333, (0, 0, 0): 334, (166, 230, 204): 335, (166, 166, 255): 411,
    (77, 77, 255): 412, (204, 204, 255): 421, (230, 230, 255): 422, (166, 166, 230): 423, (0, 204, 242): 511,
    (128, 242, 230): 512, (0, 255, 166): 521, (166, 255, 230): 522, (230, 242, 255): 523,
}
# Clases agrarias de CORINE -> cultivo de la web (orden = índice)
CULTIVOS = ["Secano", "Regadío", "Arrozal", "Viñedo", "Frutales", "Olivar", "Prados", "Mosaico de cultivos", "Dehesa"]
CLC_CULTIVO = {211: 0, 212: 1, 213: 2, 221: 3, 222: 4, 223: 5, 231: 6, 241: 7, 242: 7, 243: 7, 244: 8}

# Texturas del triángulo del USDA, en el orden de las condiciones de `textura`
TEXTURAS = ["Arenosa", "Arenoso-franca", "Franco-arenosa", "Franca", "Franco-limosa", "Limosa",
            "Franco-arcillo-arenosa", "Franco-arcillosa", "Franco-arcillo-limosa", "Arcillo-arenosa",
            "Arcillo-limosa", "Arcillosa"]
GRUPO_TEXTURA = ["Arenosa (ligera)"] * 3 + ["Franca (media)"] * 3 + ["Franco-arcillosa"] * 3 + ["Arcillosa (pesada)"] * 3
GRUPOS_TEXTURA = list(dict.fromkeys(GRUPO_TEXTURA))
PH_CLASES = ["Muy ácido (< 5,5)", "Ácido (5,5-6,5)", "Neutro (6,5-7,5)", "Básico (7,5-8,5)", "Muy básico (> 8,5)"]
PH_CORTES = [5.5, 6.5, 7.5, 8.5]
MO_CLASES = ["Muy pobre (< 1 %)", "Pobre (1-2 %)", "Normal (2-4 %)", "Rico (> 4 %)"]
MO_CORTES = [1, 2, 4]
# Grupos de suelo WRB de SoilGrids (código 0..29) con su nombre en castellano
WRB = ["Acrisoles", "Albeluvisoles", "Alisoles", "Andosoles", "Arenosoles", "Calcisoles", "Cambisoles",
       "Chernozems", "Criosoles", "Durisoles", "Ferralsoles", "Fluvisoles", "Gleysoles", "Gipsisoles",
       "Histosoles", "Kastanozems", "Leptosoles", "Lixisoles", "Luvisoles", "Nitisoles", "Phaeozems",
       "Planosoles", "Plintosoles", "Podzoles", "Regosoles", "Solonchaks", "Solonetz", "Stagnosoles",
       "Umbrisoles", "Vertisoles"]
# Materia orgánica = carbono orgánico x 1,724 (factor de Van Bemmelen, el de los análisis agrarios)
MO_FACTOR = 1.724


def _get(url: str, intentos: int = 4, **kw) -> requests.Response:
    for i in range(intentos):
        try:
            r = requests.get(url, headers=CABECERAS, timeout=180, **kw)
            r.raise_for_status()
            return r
        except requests.RequestException as e:
            if i == intentos - 1:
                raise
            log.warning("Reintento %s de %s: %s", i + 1, url[:120], e)
            time.sleep(10 * (i + 1))


def _rejilla(nombre: str):
    from rasterio.transform import from_origin

    x0, y1, ancho, alto = REJILLAS[nombre]
    return from_origin(x0 * 1000, y1 * 1000, CELDA, CELDA), ancho, alto


# ------------------------------------------------------------------ SoilGrids

def _leer_soilgrids(url: str, nombre: str, overview: int | None = None) -> np.ndarray:
    """Lee una capa de SoilGrids reproyectada a la rejilla (vecino más próximo), en float32 con NaN."""
    import rasterio
    from rasterio.enums import Resampling
    from rasterio.vrt import WarpedVRT

    transform, ancho, alto = _rejilla(nombre)
    opciones = {"OVERVIEW_LEVEL": overview} if overview is not None else {}
    with rasterio.Env(GDAL_DISABLE_READDIR_ON_OPEN="YES" if overview is not None else "EMPTY_DIR", GDAL_HTTP_MULTIRANGE="YES",
                      GDAL_HTTP_MERGE_CONSECUTIVE_RANGES="YES", GDAL_CACHEMAX=1024,
                      GDAL_HTTP_MAX_RETRY="5", GDAL_HTTP_RETRY_DELAY="5", CPL_VSIL_CURL_CHUNK_SIZE=1048576):
        with rasterio.open("/vsicurl/" + url, **opciones) as src:
            nodata = src.nodata
            with WarpedVRT(src, crs="EPSG:3035", transform=transform, width=ancho, height=alto,
                           resampling=Resampling.nearest, src_nodata=nodata, nodata=nodata) as vrt:
                a = vrt.read(1).astype(np.float32)
    if nodata is not None:
        a[a == nodata] = np.nan
    return a


def capa_superficial(variable: str, nombre: str) -> np.ndarray:
    """Media ponderada por espesor de 0 a 30 cm de una variable de SoilGrids."""
    suma = None
    peso = None
    for prof, espesor in PROFUNDIDADES:
        url = f"{SOILGRIDS}data_aggregated/1000m/{variable}/{variable}_{prof}_mean_1000.tif"
        a = _leer_soilgrids(url, nombre)
        ok = ~np.isnan(a)
        if suma is None:
            suma = np.zeros_like(a)
            peso = np.zeros_like(a)
        suma[ok] += a[ok] * espesor
        peso[ok] += espesor
        log.info("SoilGrids %s %s (%s): %.1f %% con dato", variable, prof, nombre, ok.mean() * 100)
    with np.errstate(invalid="ignore", divide="ignore"):
        return np.where(peso > 0, suma / peso, np.nan).astype(np.float32)


def wrb(nombre: str) -> np.ndarray:
    a = _leer_soilgrids(f"{SOILGRIDS}data/wrb/MostProbable.vrt", nombre, overview=0)
    a[(a < 0) | (a >= len(WRB))] = np.nan
    return a


# ------------------------------------------------------------------ CORINE

def corine(nombre: str, ventana=None):
    """Recuento de muestras de 250 m de cada cultivo por celda de 1 km: (len(CULTIVOS), alto, ancho) uint8.

    Con `ventana` = (fila0, fila1, col0, col1) en celdas de 1 km devuelve además las muestras de
    250 m de esa ventana (índice del cultivo o -1 si no es agraria), para el cálculo por municipio.
    """
    from PIL import Image

    x0, y1, ancho, alto = REJILLAS[nombre]
    lut = np.zeros(256 ** 3, dtype=np.int16) - 1
    for (r, g, b), clase in CLC_COLORES.items():
        if clase in CLC_CULTIVO:
            lut[(r << 16) | (g << 8) | b] = CLC_CULTIVO[clase]
    cuenta = np.zeros((len(CULTIVOS), alto, ancho), dtype=np.uint8)
    if ventana:
        f0, f1, c0, c1 = ventana
        fina = np.full(((f1 - f0) * SUB, (c1 - c0) * SUB), -1, dtype=np.int8)
    paso = 1000  # km por imagen (4.000 px de 250 m: el servicio admite 4.096)
    for ty in range(0, alto, paso):
        for tx in range(0, ancho, paso):
            w, h = min(paso, ancho - tx), min(paso, alto - ty)
            bbox = ((x0 + tx) * 1000, (y1 - ty - h) * 1000, (x0 + tx + w) * 1000, (y1 - ty) * 1000)
            r = _get(CLC_EXPORT, params={
                "bbox": ",".join(str(v) for v in bbox), "bboxSR": 3035, "imageSR": 3035,
                "size": f"{w * SUB},{h * SUB}", "layers": "show:1", "format": "png24",
                "transparent": "false", "f": "image"})
            im = np.asarray(Image.open(io.BytesIO(r.content)).convert("RGB"), dtype=np.uint32)
            if im.shape[:2] != (h * SUB, w * SUB):
                raise ValueError(f"CORINE devolvió {im.shape} en vez de {(h * SUB, w * SUB)}")
            cls = lut[(im[..., 0] << 16) | (im[..., 1] << 8) | im[..., 2]]
            bloques = cls.reshape(h, SUB, w, SUB).transpose(0, 2, 1, 3).reshape(h, w, SUB * SUB)
            for k in range(len(CULTIVOS)):
                cuenta[k, ty:ty + h, tx:tx + w] = (bloques == k).sum(axis=2)
            if ventana:
                # Parte de la imagen que cae dentro de la ventana (en celdas de 1 km)
                a0, a1 = max(f0, ty), min(f1, ty + h)
                b0, b1 = max(c0, tx), min(c1, tx + w)
                if a0 < a1 and b0 < b1:
                    fina[(a0 - f0) * SUB:(a1 - f0) * SUB, (b0 - c0) * SUB:(b1 - c0) * SUB] =                         cls[(a0 - ty) * SUB:(a1 - ty) * SUB, (b0 - tx) * SUB:(b1 - tx) * SUB]
            log.info("CORINE %s: imagen %s,%s (%s km x %s km)", nombre, tx, ty, w, h)
    return (cuenta, fina) if ventana else cuenta


# ------------------------------------------------------------------ fronteras

def _rasterizar(formas, nombre: str) -> np.ndarray:
    from rasterio.features import rasterize

    transform, ancho, alto = _rejilla(nombre)
    if not formas:
        return np.zeros((alto, ancho), dtype=np.int16)
    return rasterize(formas, out_shape=(alto, ancho), transform=transform, fill=0, dtype="int16")


def provincias(nombre: str):
    """Ráster con el código INE de provincia (0 fuera de España) y el mapa provincia -> comunidad."""
    from rasterio.warp import transform_geom

    geo = json.loads((REPO_ROOT / "static" / "geo" / "provincias.geojson").read_text(encoding="utf-8"))
    formas, a_ccaa = [], {}
    for f in geo["features"]:
        p = f["properties"]
        cod = int(p["cod_prov"])
        a_ccaa[f"{cod:02d}"] = p["cod_ccaa"]
        formas.append((transform_geom("EPSG:4326", "EPSG:3035", f["geometry"]), cod))
    return _rasterizar(formas, nombre), a_ccaa


def municipios(nombre: str, ventana):
    """Ráster de 250 m de la ventana con el índice de municipio (0 fuera) y la lista de códigos INE."""
    from rasterio.features import rasterize
    from rasterio.transform import from_origin
    from rasterio.warp import transform_geom

    x0, y1, _, _ = REJILLAS[nombre]
    f0, f1, c0, c1 = ventana
    transform = from_origin((x0 + c0) * 1000, (y1 - f0) * 1000, CELDA / SUB, CELDA / SUB)
    geo = json.loads((REPO_ROOT / "static" / "geo" / "municipios.geojson").read_text(encoding="utf-8"))
    codigos = [""]
    formas = []
    for f in geo["features"]:
        codigos.append(f["properties"]["cod_mun"])
        formas.append((transform_geom("EPSG:4326", "EPSG:3035", f["geometry"]), len(codigos) - 1))
    r = rasterize(formas, out_shape=((f1 - f0) * SUB, (c1 - c0) * SUB), transform=transform, fill=0, dtype="int32")
    return r, codigos


def paises(nombre: str):
    """Ráster con un índice de país (0 fuera) y la lista de códigos de GISCO (Eurostat)."""
    geo = _get(GISCO).json()
    codigos = [""]
    formas = []
    for f in geo["features"]:
        cod = f["properties"]["CNTR_ID"]
        codigos.append(cod)
        formas.append((f["geometry"], len(codigos) - 1))
    return _rasterizar(formas, nombre), codigos


# ------------------------------------------------------------------ clasificación

def textura(arcilla: np.ndarray, limo: np.ndarray, arena: np.ndarray) -> np.ndarray:
    """Clase textural del USDA (índice en TEXTURAS, -1 sin dato) a partir de los porcentajes."""
    c, si, sa = arcilla, limo, arena
    condiciones = [
        si + 1.5 * c < 15,
        (si + 2 * c < 30),
        ((c >= 7) & (c < 20) & (sa > 52)) | ((c < 7) & (si < 50)),
        (c >= 7) & (c < 27) & (si >= 28) & (si < 50) & (sa <= 52),
        ((si >= 50) & (c >= 12) & (c < 27)) | ((si >= 50) & (si < 80) & (c < 12)),
        (si >= 80) & (c < 12),
        (c >= 20) & (c < 35) & (si < 28) & (sa > 45),
        (c >= 27) & (c < 40) & (sa > 20) & (sa <= 45),
        (c >= 27) & (c < 40) & (sa <= 20),
        (c >= 35) & (sa > 45),
        (c >= 40) & (si >= 40),
        c >= 40,
    ]
    out = np.select(condiciones, list(range(len(TEXTURAS))), default=-1).astype(np.int8)
    out[np.isnan(c) | np.isnan(si) | np.isnan(sa)] = -1
    return out


def _bandas(x: np.ndarray, cortes) -> np.ndarray:
    out = np.digitize(x, cortes).astype(np.int8)
    out[np.isnan(x)] = -1
    return out


# ------------------------------------------------------------------ cálculo

def suelo(nombre: str) -> dict:
    """Variables de suelo de la rejilla: porcentajes, pH, carbono (g/kg) y clases."""
    v = {var: capa_superficial(var, nombre) for var in VARIABLES}
    total = v["clay"] + v["silt"] + v["sand"]
    with np.errstate(invalid="ignore", divide="ignore"):
        ok = total > 0
        arcilla = np.where(ok, v["clay"] / total * 100, np.nan)
        limo = np.where(ok, v["silt"] / total * 100, np.nan)
        arena = np.where(ok, v["sand"] / total * 100, np.nan)
    ph = v["phh2o"] / 10
    ph[(ph < 2) | (ph > 11)] = np.nan
    carbono = v["soc"] / 10  # g/kg
    mo = carbono * MO_FACTOR / 10  # %
    tex = textura(arcilla, limo, arena)
    grupo = np.where(tex >= 0, tex // 3, -1).astype(np.int8)
    return {
        "arcilla": arcilla.astype(np.float32), "limo": limo.astype(np.float32), "arena": arena.astype(np.float32),
        "ph": ph.astype(np.float32), "carbono": carbono.astype(np.float32), "mo": mo.astype(np.float32),
        "textura": tex, "textura_grupo": grupo, "ph_clase": _bandas(ph, PH_CORTES), "mo_clase": _bandas(mo, MO_CORTES),
        "wrb": np.where(np.isnan(w := wrb(nombre)), -1, w).astype(np.int8),
    }


MEDIAS = ["arcilla", "limo", "arena", "ph", "carbono", "mo"]
DIMENSIONES = {
    "textura": ("textura", TEXTURAS),
    "textura_grupo": ("textura_grupo", GRUPOS_TEXTURA),
    "ph": ("ph_clase", PH_CLASES),
    "mo": ("mo_clase", MO_CLASES),
    "wrb": ("wrb", WRB),
}


def _agregar(unidad: np.ndarray, n_unidades: int, pesos: np.ndarray, s: dict):
    """Por unidad (0 = fuera) y cultivo (-1 = toda la superficie agraria): km² y medias; km² por clase.

    `pesos` = recuento de muestras de cada cultivo (len(CULTIVOS), alto, ancho); km² = recuento / 16.
    """
    sel = unidad > 0
    u = unidad[sel].astype(np.int64)
    p = pesos[:, sel].astype(np.float64) / (SUB * SUB)
    p = np.vstack([p.sum(axis=0, keepdims=True), p])  # fila 0 = toda la superficie agraria
    medias, clases = {}, {}
    for k in range(p.shape[0]):
        w = p[k]
        km2 = np.bincount(u, weights=w, minlength=n_unidades)
        medias[k] = {"km2": km2, "total": np.bincount(u, minlength=n_unidades).astype(float)}
        for var in MEDIAS:
            x = s[var][sel].astype(np.float64)
            ok = ~np.isnan(x)
            num = np.bincount(u[ok], weights=w[ok] * x[ok], minlength=n_unidades)
            den = np.bincount(u[ok], weights=w[ok], minlength=n_unidades)
            with np.errstate(invalid="ignore", divide="ignore"):
                medias[k][var] = np.where(den > 0, num / den, np.nan)
        for dim, (campo, nombres) in DIMENSIONES.items():
            c = s[campo][sel].astype(np.int64)
            ok = c >= 0
            m = np.bincount(u[ok] * len(nombres) + c[ok], weights=w[ok], minlength=n_unidades * len(nombres))
            clases[(k, dim)] = m.reshape(n_unidades, len(nombres))
    return medias, clases


def _filas(ambito: str, codigos: list, medias: dict, clases: dict, minimo_km2: float = 1.0):
    """Convierte la agregación en filas de suelos_medias y suelos_clases."""
    f_medias, f_clases = [], []
    for k, m in medias.items():
        cultivo = "Toda la superficie agraria" if k == 0 else CULTIVOS[k - 1]
        for i, cod in enumerate(codigos):
            if not cod or m["km2"][i] < minimo_km2:
                continue
            fila = {"ambito": ambito, "cod": cod, "cultivo": cultivo, "superficie_km2": round(float(m["km2"][i]), 2),
                    "superficie_total_km2": round(float(m["total"][i]), 2)}
            for var in MEDIAS:
                val = m[var][i]
                fila[var] = None if np.isnan(val) else round(float(val), 3)
            f_medias.append(fila)
            for dim, (_, nombres) in DIMENSIONES.items():
                for j, clase in enumerate(nombres):
                    km2 = float(clases[(k, dim)][i, j])
                    if km2 > 0:
                        f_clases.append({"ambito": ambito, "cod": cod, "cultivo": cultivo, "dimension": dim,
                                         "clase": clase, "orden": j, "superficie_km2": round(km2, 2)})
    return f_medias, f_clases


def _rejilla_10km(nombre: str, pesos: np.ndarray, s: dict, prov: np.ndarray) -> list[dict]:
    """Celdas de 10 km de España con al menos 5 km² agrarios: dominantes y medias."""
    from rasterio.warp import transform as reproyectar

    transform, ancho, alto = _rejilla(nombre)
    agr = pesos.sum(axis=0).astype(np.float64) / (SUB * SUB)
    agr[prov <= 0] = 0
    by, bx = np.indices((alto, ancho))
    bloque = (by // 10) * ((ancho + 9) // 10) + (bx // 10)
    nb = ((alto + 9) // 10) * ((ancho + 9) // 10)
    sel = agr > 0
    b = bloque[sel]
    w = agr[sel]
    km2 = np.bincount(b, weights=w, minlength=nb)
    res = {"km2": km2}
    for var in ["arcilla", "ph", "mo"]:
        x = s[var][sel].astype(np.float64)
        ok = ~np.isnan(x)
        num = np.bincount(b[ok], weights=w[ok] * x[ok], minlength=nb)
        den = np.bincount(b[ok], weights=w[ok], minlength=nb)
        with np.errstate(invalid="ignore", divide="ignore"):
            res[var] = np.where(den > 0, num / den, np.nan)

    def dominante(campo, n):
        c = s[campo][sel].astype(np.int64)
        ok = c >= 0
        m = np.bincount(b[ok] * n + c[ok], weights=w[ok], minlength=nb * n).reshape(nb, n)
        return np.where(m.sum(axis=1) > 0, m.argmax(axis=1), -1)

    tex = dominante("textura", len(TEXTURAS))
    gru = dominante("textura_grupo", len(GRUPOS_TEXTURA))
    wr = dominante("wrb", len(WRB))
    pc = pesos[:, sel].astype(np.float64)
    cult = np.vstack([np.bincount(b, weights=pc[k], minlength=nb) for k in range(len(CULTIVOS))]).argmax(axis=0)
    pv = np.bincount(b * 60 + prov[sel].astype(np.int64), weights=w, minlength=nb * 60).reshape(nb, 60).argmax(axis=1)

    filas = []
    cols = (ancho + 9) // 10
    idx = np.nonzero(km2 >= 5)[0]
    xs = transform.c + ((idx % cols) * 10 + np.minimum(10, ancho - (idx % cols) * 10) / 2) * CELDA
    ys = transform.f - ((idx // cols) * 10 + np.minimum(10, alto - (idx // cols) * 10) / 2) * CELDA
    lon, lat = reproyectar("EPSG:3035", "EPSG:4326", xs.tolist(), ys.tolist())
    for n, i in enumerate(idx):
        def r(v, d):
            return None if np.isnan(v) else round(float(v), d)
        filas.append({
            "celda": f"{nombre[:2]}{int(i)}", "lon": round(lon[n], 4), "lat": round(lat[n], 4),
            "cod_prov": f"{int(pv[i]):02d}", "superficie_agraria_km2": round(float(km2[i]), 1),
            "textura": TEXTURAS[tex[i]] if tex[i] >= 0 else None,
            "textura_grupo": GRUPOS_TEXTURA[gru[i]] if gru[i] >= 0 else None,
            "wrb": WRB[wr[i]] if wr[i] >= 0 else None,
            "cultivo": CULTIVOS[cult[i]],
            "arcilla": r(res["arcilla"][i], 1), "ph": r(res["ph"][i], 2), "mo": r(res["mo"][i], 2),
        })
    return filas


def _ventana(prov: np.ndarray):
    """Rectángulo (fila0, fila1, col0, col1) de celdas de 1 km que contiene España en la rejilla."""
    filas = np.nonzero(prov.any(axis=1))[0]
    cols = np.nonzero(prov.any(axis=0))[0]
    return int(filas[0]), int(filas[-1]) + 1, int(cols[0]), int(cols[-1]) + 1


def _municipios_filas(fina: np.ndarray, mun: np.ndarray, codigos: list, s: dict, ventana) -> list[dict]:
    """Suelo agrario de cada municipio y cultivo con las muestras de 250 m de CORINE.

    El suelo de cada muestra es el de su celda de 1 km de SoilGrids; la superficie, la de las
    muestras agrarias que caen dentro del término municipal (1/16 de km² cada una).
    """
    f0, _, c0, _ = ventana
    n = len(codigos)
    ancho = mun.shape[1]
    m = mun.ravel()
    f = fina.ravel()
    total = np.bincount(m[m > 0], minlength=n) / (SUB * SUB)
    idx = np.nonzero((m > 0) & (f >= 0))[0]
    mm = m[idx].astype(np.int64)
    ff = f[idx].astype(np.int64)
    celda_f = f0 + (idx // ancho) // SUB
    celda_c = c0 + (idx % ancho) // SUB
    x = {var: s[var][celda_f, celda_c].astype(np.float64) for var in MEDIAS}
    cl = {campo: s[campo][celda_f, celda_c].astype(np.int64) for campo in ("textura", "textura_grupo", "wrb", "ph_clase")}
    del idx
    filas = []
    for k in [-1] + list(range(len(CULTIVOS))):
        sel = np.ones_like(mm, dtype=bool) if k < 0 else ff == k
        u = mm[sel]
        km2 = np.bincount(u, minlength=n) / (SUB * SUB)
        med = {}
        for var in MEDIAS:
            v = x[var][sel]
            ok = ~np.isnan(v)
            num = np.bincount(u[ok], weights=v[ok], minlength=n)
            den = np.bincount(u[ok], minlength=n)
            with np.errstate(invalid="ignore", divide="ignore"):
                med[var] = np.where(den > 0, num / den, np.nan)
        reparto = {}
        for campo in cl:
            c = cl[campo][sel]
            ok = c >= 0
            nc = int(cl[campo].max()) + 1 if cl[campo].size else 1
            nc = max(nc, len(TEXTURAS) if campo == "textura" else len(WRB) if campo == "wrb" else 5)
            reparto[campo] = np.bincount(u[ok] * nc + c[ok], minlength=n * nc).reshape(n, nc)
        for i in range(1, n):
            if k >= 0 and km2[i] < 0.0625:
                continue
            if k < 0 and total[i] <= 0:
                continue

            def pct(campo, cond):
                r = reparto[campo][i]
                tot = r.sum()
                return round(100.0 * r[cond].sum() / tot, 1) if tot else None

            def dominante(campo, nombres):
                r = reparto[campo][i]
                return nombres[int(r.argmax())] if r.sum() else None

            def red(v, d):
                return None if np.isnan(v) else round(float(v), d)

            gr = np.arange(reparto["textura_grupo"].shape[1])
            ph = np.arange(reparto["ph_clase"].shape[1])
            filas.append({
                "cod_mun": codigos[i],
                "cultivo": "Toda la superficie agraria" if k < 0 else CULTIVOS[k],
                "superficie_total_km2": round(float(total[i]), 3),
                "superficie_km2": round(float(km2[i]), 3),
                "arcilla": red(med["arcilla"][i], 2), "limo": red(med["limo"][i], 2), "arena": red(med["arena"][i], 2),
                "ph": red(med["ph"][i], 3), "carbono": red(med["carbono"][i], 3), "mo": red(med["mo"][i], 3),
                "textura_dominante": dominante("textura", TEXTURAS),
                "grupo_textura_dominante": dominante("textura_grupo", GRUPOS_TEXTURA),
                "wrb_dominante": dominante("wrb", WRB),
                "pct_fuertes": pct("textura_grupo", gr >= 2),
                "pct_arcillosa": pct("textura_grupo", gr == 3),
                "pct_arenosa": pct("textura_grupo", gr == 0),
                "pct_basico": pct("ph_clase", ph >= 3),
                "pct_acido": pct("ph_clase", ph <= 1),
                "pct_calcisoles": pct("wrb", np.arange(reparto["wrb"].shape[1]) == WRB.index("Calcisoles")),
            })
    return filas


def calcular() -> dict:
    cache = CACHE / f"resultado_v{VERSION}.json"
    if cache.exists():
        return json.loads(cache.read_text(encoding="utf-8"))
    CACHE.mkdir(parents=True, exist_ok=True)
    medias, clases, rejilla, municipales = [], [], [], []
    acumulado_es = None
    for nombre in REJILLAS:
        t = time.time()
        s = suelo(nombre)
        prov, a_ccaa = provincias(nombre)
        ventana = _ventana(prov)
        pesos, fina = corine(nombre, ventana)
        mun, cods_mun = municipios(nombre, ventana)
        municipales += _municipios_filas(fina, mun, cods_mun, s, ventana)
        del fina, mun
        pais, codigos = paises(nombre)
        # España: Ceuta y Melilla quedan fuera de la rejilla europea; las provincias mandan sobre GISCO
        es = codigos.index("ES")
        pais[prov > 0] = es
        pais[(pais == es) & (prov <= 0)] = 0
        # Provincias y comunidades
        m, c = _agregar(prov, 60, pesos, s)
        fm, fc = _filas("provincia", [f"{i:02d}" if i else "" for i in range(60)], m, c)
        medias += fm
        clases += fc
        cods_ccaa = sorted(set(a_ccaa.values()))
        mapa_ccaa = np.zeros(60, dtype=np.int16)
        for p_cod, cc in a_ccaa.items():
            mapa_ccaa[int(p_cod)] = cods_ccaa.index(cc) + 1
        m, c = _agregar(mapa_ccaa[np.clip(prov, 0, 59)], len(cods_ccaa) + 1, pesos, s)
        fm, fc = _filas("ccaa", [""] + cods_ccaa, m, c)
        medias += fm
        clases += fc
        # Países (España se suma entre rejillas abajo)
        m, c = _agregar(pais, len(codigos), pesos, s)
        if acumulado_es is None:
            acumulado_es = (m, c, es)
        else:
            m0, c0, es0 = acumulado_es
            for k in m:
                tot = m0[k]["km2"][es0] + m[k]["km2"][es]
                for var in MEDIAS:
                    a0, a1 = m0[k][var][es0], m[k][var][es]
                    w0, w1 = m0[k]["km2"][es0], m[k]["km2"][es]
                    vals = [(a, wt) for a, wt in ((a0, w0), (a1, w1)) if not np.isnan(a) and wt > 0]
                    m0[k][var][es0] = sum(a * wt for a, wt in vals) / sum(wt for _, wt in vals) if vals else np.nan
                m0[k]["km2"][es0] = tot
                m0[k]["total"][es0] += m[k]["total"][es]
                for dim in DIMENSIONES:
                    c0[(k, dim)][es0] += c[(k, dim)][es]
        if nombre == "europa":
            cods_eu = codigos
            m_eu, c_eu = m, c
        rejilla += _rejilla_10km(nombre, pesos, s, prov)
        log.info("Suelos %s calculado en %.0f s", nombre, time.time() - t)
    fm, fc = _filas("pais", cods_eu, m_eu, c_eu, minimo_km2=50)
    medias += fm
    clases += fc
    res = {"suelos_medias": medias, "suelos_clases": clases, "suelos_rejilla": rejilla, "suelos_municipio": municipales}
    cache.write_text(json.dumps(res, ensure_ascii=False), encoding="utf-8")
    return res


@dlt.source(name="suelos", max_table_nesting=0)
def suelos():
    cache = {}

    def datos(tabla):
        if "res" not in cache:
            cache["res"] = calcular()
        return cache["res"][tabla]

    @dlt.resource(name="suelos_medias", write_disposition="replace")
    def r_medias():
        yield datos("suelos_medias")

    @dlt.resource(name="suelos_clases", write_disposition="replace")
    def r_clases():
        yield datos("suelos_clases")

    @dlt.resource(name="suelos_rejilla", write_disposition="replace")
    def r_rejilla():
        yield datos("suelos_rejilla")

    @dlt.resource(name="suelos_municipio", write_disposition="replace")
    def r_municipio():
        yield datos("suelos_municipio")

    return r_medias, r_clases, r_rejilla, r_municipio


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s")
    r = calcular()
    print({k: len(v) for k, v in r.items()})
