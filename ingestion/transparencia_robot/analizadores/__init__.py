"""Registro y selector de analizadores de portales de transparencia."""

from __future__ import annotations

from ingestion.transparencia_robot.analizadores.aoc_seue import AnalizadorAocSeue
from ingestion.transparencia_robot.analizadores.base import AnalizadorBase
from ingestion.transparencia_robot.analizadores.dipucr import AnalizadorDipuCR
from ingestion.transparencia_robot.analizadores.generico import AnalizadorGenerico
from ingestion.transparencia_robot.analizadores.gestiona import AnalizadorGestiona
from ingestion.transparencia_robot.analizadores.sedipualba import AnalizadorSedipualba

__all__ = [
    "AnalizadorBase",
    "AnalizadorGestiona",
    "AnalizadorDipuCR",
    "AnalizadorAocSeue",
    "AnalizadorSedipualba",
    "AnalizadorGenerico",
    "obtener_analizador",
]


def obtener_analizador(plataforma: str | None, ronda: str = "2026T4") -> AnalizadorBase:
    """Devuelve el analizador adecuado según la plataforma identificada."""
    p = (plataforma or "").lower()

    if p == "gestiona":
        return AnalizadorGestiona(ronda=ronda)
    if p == "dipucr":
        return AnalizadorDipuCR(ronda=ronda)
    if p == "aoc_seue":
        return AnalizadorAocSeue(ronda=ronda)
    if p == "sedipualba":
        return AnalizadorSedipualba(ronda=ronda)

    return AnalizadorGenerico(ronda=ronda)
