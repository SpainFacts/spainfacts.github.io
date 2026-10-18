"""Linaje de cada fuente del catálogo: descarga -> script de ingesta -> tablas raw -> modelos dbt
-> consultas de Evidence -> páginas. Sirve a la página /fuentes para que cualquiera pueda
reconstruir los datos por su cuenta siguiendo el código en GitHub.

Entrada:
  transform/seeds/fuentes_catalogo.csv   (fuente_id, organismo, ...)
  transform/seeds/fuentes_ingesta.csv    (fuente_id, script_ingesta, tablas_raw «raw.x;seed.y»)
  transform/models/**/*.sql              (source() y ref() de dbt)
  sources/mother/*.sql                   (consultas que leen los marts)
  pages/**/*.md en el índice de git      (solo castellano; las traducciones repiten las consultas)
Salida:
  static/fuentes/linaje.json

Uso: python tools/fuentes/linaje.py
Se vuelve a correr al añadir fuentes, modelos o páginas, y el JSON se sube junto al cambio.
"""
import csv
import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
IDIOMAS = ("en", "ca", "gl", "eu")

RE_SOURCE = re.compile(r"source\(\s*['\"]([\w]+)['\"]\s*,\s*['\"]([\w]+)['\"]\s*\)")
RE_REF = re.compile(r"ref\(\s*['\"]([\w]+)['\"]\s*\)")
RE_FROM = re.compile(r"\b(?:from|join)\s+([a-z_][\w]*)", re.I)
RE_MOTHER = re.compile(r"\bmother\.([a-z0-9_]+)", re.I)
RE_TITULO = re.compile(r"^title:\s*[\"']?(.+?)[\"']?\s*$", re.M)


def leer_csv(ruta):
    with open(ruta, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def modelos_dbt():
    """nombre -> {ruta, entradas: {"raw.x", "ref.y", ...}}"""
    modelos = {}
    for ruta in sorted((RAIZ / "transform" / "models").rglob("*.sql")):
        sql = ruta.read_text(encoding="utf-8")
        entradas = {f"{a}.{b}" for a, b in RE_SOURCE.findall(sql)} | {f"ref.{m}" for m in RE_REF.findall(sql)}
        modelos[ruta.stem] = {"ruta": ruta.relative_to(RAIZ).as_posix(), "entradas": entradas}
    return modelos


def consultas_evidence():
    """consulta (sources/mother/x.sql) -> modelos que lee"""
    consultas = {}
    for ruta in sorted((RAIZ / "sources" / "mother").glob("*.sql")):
        sql = re.sub(r"--.*", "", ruta.read_text(encoding="utf-8"))
        consultas[ruta.stem] = {"ruta": ruta.relative_to(RAIZ).as_posix(), "lee": set(RE_FROM.findall(sql))}
    return consultas


def paginas():
    """Páginas en castellano del índice de git (el árbol de trabajo puede estar recortado): ruta -> (url, título, consultas)"""
    salida = subprocess.run(["git", "ls-files", "-z", "pages"], cwd=RAIZ, capture_output=True, check=True).stdout
    res = {}
    for ruta in salida.decode("utf-8").split("\0"):
        if not ruta.endswith(".md") or ruta.split("/")[1] in IDIOMAS:
            continue
        texto = subprocess.run(["git", "show", f":{ruta}"], cwd=RAIZ, capture_output=True, check=True).stdout.decode("utf-8")
        url = "/" + re.sub(r"(^|/)index$", "", ruta[len("pages/"):-len(".md")])
        if "[" in url:  # rutas con parámetros ([ccaa]): se enlaza la página índice de la sección
            url = url.split("/[")[0]
        url = url.rstrip("/") or "/"
        if url == "/":  # la portada lo resume todo: no dice nada de una fuente
            continue
        titulo = RE_TITULO.search(texto)
        res[ruta] = {"url": url, "titulo": titulo.group(1) if titulo else url.rsplit("/", 1)[-1].replace("-", " ").capitalize(),
                     "consultas": {m.lower() for m in RE_MOTHER.findall(texto)}}
    return res


def main():
    catalogo = leer_csv(RAIZ / "transform" / "seeds" / "fuentes_catalogo.csv")
    ingesta = {r["fuente_id"]: r for r in leer_csv(RAIZ / "transform" / "seeds" / "fuentes_ingesta.csv")}
    modelos = modelos_dbt()
    consultas = consultas_evidence()
    pags = paginas()

    # Grafo hacia abajo: entrada -> modelos que la usan
    usan = defaultdict(set)
    for nombre, m in modelos.items():
        for e in m["entradas"]:
            usan[e].add(nombre)

    linaje = {}
    for fila in catalogo:
        fid = fila["fuente_id"]
        ing = ingesta.get(fid, {})
        tablas = [t.strip() for t in (ing.get("tablas_raw") or "").split(";") if t.strip()]
        # Los seeds de dbt se leen con ref(): «seed.x» equivale a «ref.x»
        pendientes = [("ref." + t[5:]) if t.startswith("seed.") else t for t in tablas]
        directos = sorted({m for e in pendientes for m in usan.get(e, ())})
        vistos, orden = set(), []
        while pendientes:
            e = pendientes.pop(0)
            for m in sorted(usan.get(e, ())):
                if m not in vistos:
                    vistos.add(m)
                    orden.append(m)
                    pendientes.append("ref." + m)
        cons = sorted(c for c, d in consultas.items() if d["lee"] & vistos)
        pag = sorted({(p["url"], p["titulo"]) for p in pags.values() if p["consultas"] & set(cons)})
        # Una fuente puede venir de varios scripts («ingestion/a.py;ingestion/b.py») o de un seed hecho a mano
        scripts = [x.strip() for x in (ing.get("script_ingesta") or "").split(";") if x.strip()]
        # Los scripts con «if __name__ == "__main__"» se pueden lanzar solos: python -m ingestion.x
        modulos = [
            x[:-3].replace("/", ".") for x in scripts
            if x.endswith(".py") and (RAIZ / x).exists() and "__main__" in (RAIZ / x).read_text(encoding="utf-8")
        ]
        linaje[fid] = {
            "scripts": scripts,
            "modulos": modulos,
            "tablas": tablas,
            "directos": directos,
            "modelos": [{"nombre": m, "ruta": modelos[m]["ruta"]} for m in orden],
            "consultas": [{"nombre": c, "ruta": consultas[c]["ruta"]} for c in cons],
            "paginas": [{"url": u, "titulo": t} for u, t in pag],
        }

    destino = RAIZ / "static" / "fuentes" / "linaje.json"
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(json.dumps(linaje, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    con_script = sum(1 for v in linaje.values() if v["scripts"])
    con_pag = sum(1 for v in linaje.values() if v["paginas"])
    print(f"{len(linaje)} fuentes · {con_script} con script · {con_pag} con páginas -> {destino.relative_to(RAIZ)}")


if __name__ == "__main__":
    main()
