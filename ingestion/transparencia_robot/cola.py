"""Gestión de cola de rastreo y persistencia reanudable para el robot de transparencia.

Garantiza que una ronda de rastreo masivo (8.182 entidades) pueda pausarse, cancelarse
o reanudarse en cualquier momento sin perder progreso ni repetir peticiones.
Utiliza SQLite para transacciones seguras y fichero de bloqueo para proceso único.
"""

from __future__ import annotations

import logging
import os
import sqlite3
import time
from datetime import datetime
from typing import Dict, List, Set

from ingestion.transparencia_robot.tipos import Entidad, Resultado

logger = logging.getLogger("transparencia_robot.cola")


class ColaRastreo:
    """Cola de rastreo persistente con estado transaccional en SQLite."""

    def __init__(self, db_path: str = "data/transparencia_robot_cache/cola_rastreo.sqlite") -> None:
        self.db_path = db_path
        os.makedirs(os.path.dirname(os.path.abspath(db_path)), exist_ok=True)
        self._inicializar_bd()

    def _get_connection(self) -> sqlite3.Connection:
        con = sqlite3.connect(self.db_path, timeout=30.0)
        con.row_factory = sqlite3.Row
        return con

    def _inicializar_bd(self) -> None:
        with self._get_connection() as con:
            con.execute("""
                CREATE TABLE IF NOT EXISTS cola_estado (
                    ronda TEXT NOT NULL,
                    cod_entidad TEXT NOT NULL,
                    estado TEXT NOT NULL, -- PENDIENTE, EN_PROCESO, COMPLETADO, ERROR
                    intentos INTEGER DEFAULT 0,
                    ultimo_error TEXT,
                    actualizado_en TEXT NOT NULL,
                    PRIMARY KEY (ronda, cod_entidad)
                )
            """)
            con.execute("""
                CREATE TABLE IF NOT EXISTS cola_resultados (
                    ronda TEXT NOT NULL,
                    cod_entidad TEXT NOT NULL,
                    comprobacion TEXT NOT NULL,
                    estado TEXT NOT NULL,
                    plataforma TEXT,
                    analizador TEXT,
                    url_evidencia TEXT,
                    fecha_ultima TEXT,
                    regla_fecha TEXT,
                    titulo_evidencia TEXT,
                    n_elementos INTEGER,
                    motivo TEXT,
                    robots_prohibe INTEGER,
                    confianza TEXT,
                    capturado_en TEXT NOT NULL,
                    PRIMARY KEY (ronda, cod_entidad, comprobacion)
                )
            """)
            con.commit()

    def obtener_entidades_completadas(self, ronda: str) -> Set[str]:
        """Devuelve el conjunto de códigos de entidades ya completadas en esta ronda."""
        with self._get_connection() as con:
            cur = con.execute("SELECT cod_entidad FROM cola_estado WHERE ronda = ? AND estado = 'COMPLETADO'", (ronda,))
            return {row["cod_entidad"] for row in cur.fetchall()}

    def filtrar_pendientes(self, ronda: str, entidades: List[Entidad]) -> List[Entidad]:
        """Filtra una lista de entidades dejando solo las que no han sido completadas."""
        completadas = self.obtener_entidades_completadas(ronda)
        return [e for e in entidades if e.cod_entidad not in completadas]

    def marcar_en_proceso(self, ronda: str, cod_entidad: str) -> None:
        """Marca una entidad como en proceso e incrementa sus intentos."""
        now = datetime.now().isoformat()
        with self._get_connection() as con:
            con.execute("""
                INSERT INTO cola_estado (ronda, cod_entidad, estado, intentos, actualizado_en)
                VALUES (?, ?, 'EN_PROCESO', 1, ?)
                ON CONFLICT(ronda, cod_entidad) DO UPDATE SET
                    estado = 'EN_PROCESO',
                    intentos = intentos + 1,
                    actualizado_en = excluded.actualizado_en
            """, (ronda, cod_entidad, now))
            con.commit()

    def guardar_resultados(self, ronda: str, cod_entidad: str, resultados: List[Resultado]) -> None:
        """Guarda atómicamente los resultados de una entidad y la marca como COMPLETADA."""
        now = datetime.now().isoformat()
        with self._get_connection() as con:
            for res in resultados:
                f_str = res.fecha_ultima.isoformat() if res.fecha_ultima else None
                rob_val = 1 if res.robots_prohibe else (0 if res.robots_prohibe is False else None)
                con.execute("""
                    INSERT OR REPLACE INTO cola_resultados (
                        ronda, cod_entidad, comprobacion, estado, plataforma, analizador,
                        url_evidencia, fecha_ultima, regla_fecha, titulo_evidencia,
                        n_elementos, motivo, robots_prohibe, confianza, capturado_en
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    ronda,
                    cod_entidad,
                    res.comprobacion,
                    res.estado,
                    res.plataforma,
                    res.analizador,
                    res.url_evidencia,
                    f_str,
                    res.regla_fecha,
                    res.titulo_evidencia,
                    res.n_elementos,
                    res.motivo,
                    rob_val,
                    res.confianza,
                    now,
                ))

            con.execute("""
                INSERT INTO cola_estado (ronda, cod_entidad, estado, actualizado_en)
                VALUES (?, ?, 'COMPLETADO', ?)
                ON CONFLICT(ronda, cod_entidad) DO UPDATE SET
                    estado = 'COMPLETADO',
                    actualizado_en = excluded.actualizado_en
            """, (ronda, cod_entidad, now))
            con.commit()

    def marcar_error(self, ronda: str, cod_entidad: str, error_msg: str) -> None:
        """Registra un error no recuperable en el procesamiento de la entidad."""
        now = datetime.now().isoformat()
        with self._get_connection() as con:
            con.execute("""
                INSERT INTO cola_estado (ronda, cod_entidad, estado, ultimo_error, actualizado_en)
                VALUES (?, ?, 'ERROR', ?, ?)
                ON CONFLICT(ronda, cod_entidad) DO UPDATE SET
                    estado = 'ERROR',
                    ultimo_error = excluded.ultimo_error,
                    actualizado_en = excluded.actualizado_en
            """, (ronda, cod_entidad, error_msg[:500], now))
            con.commit()

    def obtener_todos_resultados(self, ronda: str) -> List[Dict]:
        """Recupera todos los resultados guardados para una ronda."""
        with self._get_connection() as con:
            cur = con.execute("SELECT * FROM cola_resultados WHERE ronda = ? ORDER BY cod_entidad, comprobacion", (ronda,))
            return [dict(row) for row in cur.fetchall()]


class LockFileError(RuntimeError):
    pass


class GestorBloqueo:
    """Fichero de bloqueo para asegurar que solo una instancia del robot se ejecuta a la vez."""

    def __init__(self, lock_path: str = "data/transparencia_robot_cache/robot.lock") -> None:
        self.lock_path = lock_path

    def __enter__(self) -> GestorBloqueo:
        if os.path.exists(self.lock_path):
            try:
                with open(self.lock_path, "r", encoding="utf-8") as f:
                    pid_str = f.read().strip()
                # Verificar si el proceso sigue vivo
                pid = int(pid_str)
                # En windows comprobamos si existe
                import ctypes
                kernel32 = getattr(ctypes, "windll", None)
                if kernel32:
                    handle = kernel32.kernel32.OpenProcess(1, False, pid)
                    if handle:
                        kernel32.kernel32.CloseHandle(handle)
                        raise LockFileError(f"El robot ya está ejecutándose en PID {pid}.")
            except (ValueError, OSError):
                pass

        os.makedirs(os.path.dirname(os.path.abspath(self.lock_path)), exist_ok=True)
        with open(self.lock_path, "w", encoding="utf-8") as f:
            f.write(str(os.getpid()))
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        try:
            if os.path.exists(self.lock_path):
                os.remove(self.lock_path)
        except Exception:
            pass
