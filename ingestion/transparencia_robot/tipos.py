"""Tipos comunes del robot de portales de transparencia (elaboración propia de SpainFacts).

Una ronda revisa el portal de cada entidad (ayuntamiento, diputación, cabildo o consell,
comunidad autónoma) y produce un Resultado por entidad y comprobación. Los criterios
públicos están en docs/elaboracion-propia/robot-portales.md.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import date, datetime

# Comprobaciones sobre la base estatal común (Ley 19/2013, LBRL, LCSP, RD 635/2014), igual
# para todas las entidades. Las obligaciones que añade cada ley autonómica irán aparte.
# umbral_meses: a partir de cuántos meses sin actualizar un «consta» pasa a «consta_desactualizado»
# (None = no se mide la actualidad).
COMPROBACIONES = {
    "C0": {"nombre": "Portal o sección de transparencia accesible", "base_legal": "arts. 5.4 y 10 Ley 19/2013", "umbral_meses": None},
    "C1": {"nombre": "Organigrama y estructura", "base_legal": "art. 6.1 Ley 19/2013", "umbral_meses": None},
    "C2": {"nombre": "Identificación y trayectoria de los cargos", "base_legal": "art. 6.1 Ley 19/2013", "umbral_meses": None},
    "C3": {"nombre": "Retribuciones de cargos electos y altos cargos", "base_legal": "art. 8.1.f Ley 19/2013", "umbral_meses": 18},
    "C4": {"nombre": "Presupuesto del año en curso (o su prórroga)", "base_legal": "art. 8.1.d Ley 19/2013", "umbral_meses": None},
    "C5": {"nombre": "Ejecución del presupuesto y estabilidad", "base_legal": "art. 8.1.d Ley 19/2013", "umbral_meses": 9},
    "C6": {"nombre": "Cuentas anuales o liquidación", "base_legal": "art. 8.1.e Ley 19/2013", "umbral_meses": 30},
    "C7": {"nombre": "Contratos o enlace al perfil del contratante", "base_legal": "art. 8.1.a Ley 19/2013; arts. 63 y 347 LCSP", "umbral_meses": None},
    "C8": {"nombre": "Convenios y encomiendas", "base_legal": "art. 8.1.b Ley 19/2013", "umbral_meses": None},
    "C9": {"nombre": "Subvenciones y ayudas concedidas", "base_legal": "art. 8.1.c Ley 19/2013", "umbral_meses": 18},
    "C10": {"nombre": "Actas de pleno y fecha de la última", "base_legal": "art. 70.1 LBRL; art. 229 ROF", "umbral_meses": 6},
    "C11": {"nombre": "Declaraciones de bienes y actividades de los concejales", "base_legal": "art. 75.7 LBRL; art. 8.1.h Ley 19/2013", "umbral_meses": 54},
    "C12": {"nombre": "Relación de puestos de trabajo o plantilla", "base_legal": "art. 90 LBRL; art. 127 TRRL", "umbral_meses": 18},
    "C13": {"nombre": "Inventario de bienes inmuebles", "base_legal": "art. 8.3 Ley 19/2013", "umbral_meses": None},
    "C14": {"nombre": "Normativa vigente y en tramitación", "base_legal": "art. 7.c y 7.e Ley 19/2013", "umbral_meses": None},
    "C15": {"nombre": "Periodo medio de pago publicado", "base_legal": "art. 6 RD 635/2014", "umbral_meses": 6},
}

# Estados de un Resultado. Solo «no_consta» y «consta_desactualizado» pueden destacarse como
# incumplimiento, y solo si el indicador supera la validación manual (ver docs).
ESTADOS = (
    "consta",                 # encontrado y al día (o sin umbral de actualidad)
    "consta_desactualizado",  # encontrado, pero lo más reciente supera umbral_meses
    "no_consta",              # el portal se evaluó y no aparece
    "no_evaluable",           # no se pudo evaluar (red, TLS, plataforma caída, SPA...): nunca es incumplimiento
    "verificacion_humana",    # cortafuegos, CAPTCHA o reto anti-robots: pasa a la cola de revisión manual
)

# Reglas de fecha, en orden de fiabilidad (se guarda la que produjo cada fecha)
REGLAS_FECHA = (
    "plataforma",   # fecha estructurada de la plataforma (API, «últimas actualizaciones»)
    "contenido",    # fecha dentro del documento: sesión del acta, año del presupuesto
    "titulo",       # año o fecha en el título o el nombre del fichero
    "pdf",          # /CreationDate o /ModDate del PDF
    "last_modified",  # cabecera Last-Modified, solo en ficheros estáticos (nunca en HTML)
)


@dataclass
class Entidad:
    tipo_entidad: str            # Ayuntamiento | Diputación provincial | Cabildo o consell insular | Comunidad autónoma
    cod_entidad: str             # mismo código que el índice propio (cod_mun, D+prov, I+5, C+ccaa)
    nombre: str
    cod_mun: str | None = None
    cod_prov: str | None = None
    cod_ccaa: str | None = None
    poblacion: int | None = None
    nif: str | None = None
    telefono: str | None = None
    cp: str | None = None
    # descubrimiento: candidatas con su origen y la elegida
    urls_candidatas: list[dict] = field(default_factory=list)  # [{url, origen, puntuacion, motivo}]
    url_web: str | None = None
    url_sede: str | None = None
    url_transparencia: str | None = None
    plataforma: str | None = None


@dataclass
class Resultado:
    ronda: str                   # p. ej. «2026T4»
    cod_entidad: str
    tipo_entidad: str
    comprobacion: str            # C0..C15
    estado: str                  # uno de ESTADOS
    plataforma: str | None = None
    analizador: str | None = None
    url_evidencia: str | None = None     # URL exacta donde se vio (o se buscó)
    fecha_ultima: date | None = None     # fecha del elemento más reciente encontrado
    regla_fecha: str | None = None       # una de REGLAS_FECHA
    titulo_evidencia: str | None = None  # título del documento o sección encontrada
    n_elementos: int | None = None       # nº de documentos en la sección, si la plataforma lo da
    motivo: str | None = None            # por qué no_evaluable / verificacion_humana / no_consta
    robots_prohibe: bool | None = None   # lo que pedía robots.txt para esa URL (solo se anota)
    capturado: datetime | None = None
    confianza: str | None = None         # alta | media | baja (lo fija el analizador)

    def fila(self) -> dict:
        d = asdict(self)
        for k in ("fecha_ultima", "capturado"):
            if d[k] is not None:
                d[k] = d[k].isoformat()
        return d


class Bloqueado(Exception):
    """El servidor respondió con un cortafuegos, CAPTCHA o reto anti-robots. No se intenta
    saltar: la entidad pasa a la cola de verificación humana."""


class NoEvaluable(Exception):
    """Fallo que no depende de la entidad evaluada de forma imputable (red, TLS, caída)."""
