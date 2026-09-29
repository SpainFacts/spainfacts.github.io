"""Asegura que todas las páginas tengan imagen para redes (og.image) y avisa de las que no
tienen `description` en el frontmatter. Uso: python tools/frontmatter_seo.py [rutas a excluir...]"""
import sys
from pathlib import Path

IMAGEN = "https://spainfacts.org/og-spainfacts.png"
PAGINAS = Path(__file__).resolve().parent.parent / "pages"
excluir = [a.replace("\\", "/") for a in sys.argv[1:]]

for md in sorted(PAGINAS.rglob("*.md")):
    rel = md.relative_to(PAGINAS.parent).as_posix()
    if any(rel.startswith(e) for e in excluir):
        continue
    texto = md.read_text(encoding="utf-8")
    if not texto.startswith("---"):
        print("sin frontmatter:", rel)
        continue
    fin = texto.index("\n---", 3)
    cabecera, resto = texto[:fin], texto[fin:]
    if "description:" not in cabecera:
        print("sin description:", rel)
    if "\nog:" not in cabecera:
        cabecera += f"\nog:\n  image: {IMAGEN}"
        md.write_text(cabecera + resto, encoding="utf-8")
