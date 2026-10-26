"""Punto de entrada y orquestador del robot de portales de transparencia.

Uso por línea de comandos:
  python -m ingestion.transparencia_robot.ejecutar censo
  python -m ingestion.transparencia_robot.ejecutar rastrear --ronda 2026T4 --muestra 10
  python -m ingestion.transparencia_robot.ejecutar rastrear --cod-entidad 41091
  python -m ingestion.transparencia_robot.ejecutar exportar --ronda 2026T4
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
import time
from typing import List

import duckdb
import pyarrow as pa
import pyarrow.parquet as pq

from ingestion.transparencia_robot.analizadores import obtener_analizador
from ingestion.transparencia_robot.cliente import ClienteHttp
from ingestion.transparencia_robot.cola import ColaRastreo, GestorBloqueo, LockFileError
from ingestion.transparencia_robot.descubrir import (
    construir_censo,
    exportar_censo_parquet,
)
from ingestion.transparencia_robot.huella import detectar_plataforma
from ingestion.transparencia_robot.tipos import COMPROBACIONES, Entidad, Resultado

logger = logging.getLogger("transparencia_robot")


def cargar_entidades_censo(
    ruta_censo: str = "data/transparencia_robot_cache/censo_entidades.parquet",
) -> List[Entidad]:
    """Carga las entidades desde el archivo Parquet del censo."""
    if not os.path.exists(ruta_censo):
        logger.info("El censo no existe en %s. Construyendo nuevo censo...", ruta_censo)
        entidades = construir_censo()
        exportar_censo_parquet(entidades, ruta_censo)
        return entidades

    con = duckdb.connect()
    rows = con.execute(f"SELECT * FROM read_parquet('{ruta_censo.replace(chr(92), '/')}')").fetchall()
    cols = [desc[0] for desc in con.description]
    con.close()

    entidades: List[Entidad] = []
    for r in rows:
        d = dict(zip(cols, r))
        cands = json.loads(d.get("candidatas_json") or "[]")
        e = Entidad(
            tipo_entidad=d["tipo_entidad"],
            cod_entidad=d["cod_entidad"],
            nombre=d["nombre"],
            cod_mun=d.get("cod_mun"),
            cod_prov=d.get("cod_prov"),
            cod_ccaa=d.get("cod_ccaa"),
            nif=d.get("nif"),
            telefono=d.get("telefono"),
            cp=d.get("cp"),
            urls_candidatas=cands,
            url_web=d.get("url_web"),
            url_sede=d.get("url_sede"),
            url_transparencia=d.get("url_transparencia"),
            plataforma=d.get("plataforma"),
        )
        entidades.append(e)

    return entidades


def comando_censo(args: argparse.Namespace) -> None:
    """Genera o actualiza el censo consolidado de entidades locales."""
    print("Iniciando construcción del censo consolidado...")
    ee = construir_censo()
    exportar_censo_parquet(ee)
    print(f"Censo finalizado: {len(ee)} entidades en data/transparencia_robot_cache/censo_entidades.parquet.")


def comando_rastrear(args: argparse.Namespace) -> None:
    """Ejecuta el rastreo sobre las entidades seleccionadas o pendientes."""
    ronda = args.ronda
    warc_path = f"data/transparencia_robot_cache/{ronda}/warc/evidencias.warc.gz" if args.guardar_warc else None

    try:
        with GestorBloqueo():
            cola = ColaRastreo()
            entidades = cargar_entidades_censo()

            # Filtros por argumentos
            if args.cod_entidad:
                entidades = [e for e in entidades if e.cod_entidad == args.cod_entidad]
                if not entidades:
                    print(f"No se encontró la entidad {args.cod_entidad} en el censo.")
                    return
            elif args.plataforma:
                entidades = [e for e in entidades if (e.plataforma or "").lower() == args.plataforma.lower()]

            if args.muestra:
                entidades = entidades[: args.muestra]

            pendientes = cola.filtrar_pendientes(ronda, entidades)
            total = len(pendientes)
            print(f"Iniciando ronda {ronda}: {total} entidades pendientes de {len(entidades)} seleccionadas.")

            if total == 0:
                print("No hay entidades pendientes por procesar.")
                return

            cliente = ClienteHttp(
                pausa_host_segundos=args.pausa_host,
                pausa_plataforma_segundos=args.pausa_plataforma,
                warc_path=warc_path,
            )

            try:
                for idx, ent in enumerate(pendientes, 1):
                    cola.marcar_en_proceso(ronda, ent.cod_entidad)

                    # Si la plataforma no está definida, intentar detectarla por su URL o cabeceras
                    plataforma = ent.plataforma
                    if not plataforma:
                        url_sondeo = ent.url_sede or ent.url_transparencia or ent.url_web
                        if url_sondeo:
                            plataforma = detectar_plataforma(url_sondeo)

                    analizador = obtener_analizador(plataforma, ronda=ronda)
                    t0 = time.time()
                    try:
                        resultados = analizador.analizar(ent, cliente)
                        cola.guardar_resultados(ronda, ent.cod_entidad, resultados)
                        constan = sum(1 for r in resultados if r.estado in ("consta", "consta_desactualizado"))
                        t_seg = time.time() - t0
                        print(f"[{idx}/{total}] {ent.cod_entidad} {ent.nombre[:30]} ({plataforma or 'generico'}): {constan}/{len(COMPROBACIONES)} constan ({t_seg:.1f}s)")
                    except Exception as ex:
                        logger.exception("Error analizando entidad %s: %s", ent.cod_entidad, ex)
                        cola.marcar_error(ronda, ent.cod_entidad, str(ex))
                        print(f"[{idx}/{total}] {ent.cod_entidad} {ent.nombre[:30]}: ERROR {ex}")
            finally:
                cliente.close()

            print(f"Ronda {ronda} finalizada. Ejecuta 'exportar' para generar el archivo Parquet consolidado.")
    except LockFileError as e:
        print(f"Bloqueo activo: {e}", file=sys.stderr)
        sys.exit(1)


def comando_exportar(args: argparse.Namespace) -> None:
    """Exporta los resultados de la ronda desde SQLite a Parquet y muestra métricas."""
    ronda = args.ronda
    cola = ColaRastreo()
    filas = cola.obtener_todos_resultados(ronda)

    if not filas:
        print(f"No hay resultados registrados para la ronda {ronda}.")
        return

    out_dir = f"data/transparencia_robot_cache/{ronda}"
    os.makedirs(out_dir, exist_ok=True)
    out_parquet = os.path.join(out_dir, "resultados.parquet")

    table = pa.Table.from_pylist(filas)
    pq.write_table(table, out_parquet, compression="zstd")
    print(f"Resultados exportados: {len(filas)} filas en {out_parquet}")

    # Métricas agregadas usando DuckDB
    con = duckdb.connect()
    res_df = con.execute(f"""
        SELECT
            comprobacion,
            count(*) as total,
            sum(CASE WHEN estado = 'consta' THEN 1 ELSE 0 END) as consta,
            sum(CASE WHEN estado = 'consta_desactualizado' THEN 1 ELSE 0 END) as desactualizado,
            sum(CASE WHEN estado = 'no_consta' THEN 1 ELSE 0 END) as no_consta,
            sum(CASE WHEN estado = 'no_evaluable' THEN 1 ELSE 0 END) as no_evaluable,
            sum(CASE WHEN estado = 'verificacion_humana' THEN 1 ELSE 0 END) as verif_humana,
            sum(CASE WHEN robots_prohibe = 1 THEN 1 ELSE 0 END) as robots_bloquea
        FROM read_parquet('{out_parquet.replace(chr(92), '/')}')
        GROUP BY comprobacion
        ORDER BY comprobacion
    """).fetchall()
    cols = [d[0] for d in con.description]
    con.close()

    print("\nResumen de cumplimiento por comprobación:")
    print(f"{'Comp':<6} {'Total':<7} {'Consta':<8} {'Desact':<8} {'NoConsta':<9} {'NoEval':<8} {'VerifHum':<9} {'RobotsBloq':<10}")
    print("-" * 75)
    for row in res_df:
        d = dict(zip(cols, row))
        print(f"{d['comprobacion']:<6} {d['total']:<7} {d['consta']:<8} {d['desactualizado']:<8} {d['no_consta']:<9} {d['no_evaluable']:<8} {d['verif_humana']:<9} {d['robots_bloquea']:<10}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Robot de portales de transparencia de SpainFacts")
    subparsers = parser.add_subparsers(dest="comando", required=True)

    # Subcomando censo
    subparsers.add_parser("censo", help="Construir censo de entidades y sus URLs")

    # Subcomando rastrear
    p_rastrear = subparsers.add_parser("rastrear", help="Ejecutar rastreo sobre entidades")
    p_rastrear.add_argument("--ronda", default="2026T4", help="Código de ronda (ej. 2026T4)")
    p_rastrear.add_argument("--muestra", type=int, default=None, help="Limitar número de entidades a rastrear")
    p_rastrear.add_argument("--plataforma", type=str, default=None, help="Filtrar por plataforma (gestiona, dipucr, etc.)")
    p_rastrear.add_argument("--cod-entidad", type=str, default=None, help="Rastrear solo una entidad concreta")
    p_rastrear.add_argument("--guardar-warc", action="store_true", help="Guardar capturas completas en formato WARC")
    p_rastrear.add_argument("--pausa-host", type=float, default=2.0, help="Pausa mínima por host en segundos")
    p_rastrear.add_argument("--pausa-plataforma", type=float, default=1.0, help="Pausa mínima global por plataforma")

    # Subcomando exportar
    p_exportar = subparsers.add_parser("exportar", help="Exportar resultados a Parquet y ver resumen")
    p_exportar.add_argument("--ronda", default="2026T4", help="Código de ronda")

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%H:%M:%S",
    )

    if args.comando == "censo":
        comando_censo(args)
    elif args.comando == "rastrear":
        comando_rastrear(args)
    elif args.comando == "exportar":
        comando_exportar(args)


if __name__ == "__main__":
    main()
