"""Clase base para los analizadores de portales de transparencia."""

from __future__ import annotations

from abc import ABC, abstractmethod
from datetime import date
from typing import Any, List

from ingestion.transparencia_robot.cliente import ClienteHttp
from ingestion.transparencia_robot.tipos import COMPROBACIONES, Entidad, Resultado


class AnalizadorBase(ABC):
    """Interfaz común para todos los analizadores de plataforma."""

    def __init__(self, ronda: str = "2026T4") -> None:
        self.ronda = ronda

    @abstractmethod
    def analizar(
        self,
        entidad: Entidad,
        cliente: ClienteHttp,
        url_transparencia: str | None = None,
    ) -> List[Resultado]:
        """Ejecuta las comprobaciones de transparencia sobre la entidad."""
        pass

    def evaluar_estado_actualidad(
        self,
        comprobacion: str,
        fecha_ultima: date | None,
    ) -> str:
        """Determina si un hallazgo está actualizado o consta desactualizado."""
        if not fecha_ultima:
            return "consta"

        info = COMPROBACIONES.get(comprobacion, {})
        umbral_meses = info.get("umbral_meses")
        if umbral_meses is None:
            return "consta"

        # Calcular diferencia en meses aproximada
        hoy = date.today()
        meses = (hoy.year - fecha_ultima.year) * 12 + (hoy.month - fecha_ultima.month)
        if meses > umbral_meses:
            return "consta_desactualizado"
        return "consta"

    def crear_resultado(
        self,
        entidad: Entidad,
        comprobacion: str,
        estado: str,
        analizador: str,
        plataforma: str | None = None,
        url_evidencia: str | None = None,
        fecha_ultima: date | None = None,
        regla_fecha: str | None = None,
        titulo_evidencia: str | None = None,
        n_elementos: int | None = None,
        motivo: str | None = None,
        robots_prohibe: bool | None = None,
        confianza: str = "media",
    ) -> Resultado:
        """Construye un objeto Resultado validado."""
        if estado == "consta" and fecha_ultima:
            estado = self.evaluar_estado_actualidad(comprobacion, fecha_ultima)

        return Resultado(
            ronda=self.ronda,
            cod_entidad=entidad.cod_entidad,
            tipo_entidad=entidad.tipo_entidad,
            comprobacion=comprobacion,
            estado=estado,
            plataforma=plataforma or entidad.plataforma,
            analizador=analizador,
            url_evidencia=url_evidencia,
            fecha_ultima=fecha_ultima,
            regla_fecha=regla_fecha,
            titulo_evidencia=titulo_evidencia,
            n_elementos=n_elementos,
            motivo=motivo,
            robots_prohibe=robots_prohibe,
            confianza=confianza,
        )
