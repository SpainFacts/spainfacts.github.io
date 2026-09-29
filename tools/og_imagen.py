"""Genera static/og-spainfacts.png (1200x630), la imagen que ven las redes al compartir un enlace."""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ANCHO, ALTO = 1200, 630
AZUL, AZUL_CLARO, BLANCO = (29, 78, 216), (96, 165, 250), (255, 255, 255)
FONDO = (15, 23, 42)


def fuente(tam, negrita=False):
    for nombre in (["segoeuib.ttf", "arialbd.ttf", "DejaVuSans-Bold.ttf"] if negrita
                   else ["segoeui.ttf", "arial.ttf", "DejaVuSans.ttf"]):
        try:
            return ImageFont.truetype(nombre, tam)
        except OSError:
            continue
    return ImageFont.load_default()


img = Image.new("RGB", (ANCHO, ALTO), FONDO)
d = ImageDraw.Draw(img)

# Gráfica de barras decorativa a la derecha
alturas = [120, 170, 150, 210, 190, 260, 240, 310, 290, 360]
x0, base = 690, 520
for i, h in enumerate(alturas):
    color = AZUL_CLARO if i == len(alturas) - 1 else AZUL
    d.rounded_rectangle([x0 + i * 44, base - h, x0 + i * 44 + 30, base], radius=6, fill=color)
d.line([(x0 - 10, base + 4), (x0 + len(alturas) * 44, base + 4)], fill=(71, 85, 105), width=3)

d.text((80, 170), "Spain", font=fuente(96, True), fill=BLANCO)
ancho_spain = d.textlength("Spain", font=fuente(96, True))
d.text((80 + ancho_spain, 170), "Facts", font=fuente(96, True), fill=AZUL_CLARO)
d.text((82, 300), "El estado de España", font=fuente(40), fill=(203, 213, 225))
d.text((82, 352), "en datos oficiales", font=fuente(40), fill=(203, 213, 225))
d.text((82, 470), "spainfacts.org", font=fuente(30, True), fill=AZUL_CLARO)

salida = Path(__file__).resolve().parent.parent / "static" / "og-spainfacts.png"
img.save(salida, optimize=True)
print(salida)
