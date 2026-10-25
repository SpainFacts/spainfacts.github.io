#!/usr/bin/env bash
# Teselas vectoriales del explorador de mapas: static-extra/geo/espana.pmtiles
# (capas «municipios», zoom 4-13, y «secciones», zoom 9-13). Necesita python3 y tippecanoe >= 2.17
# (escribe PMTiles):
#   Ubuntu / WSL:  sudo apt-get install -y tippecanoe
# En Windows, desde la raíz del repo:
#   wsl -d Ubuntu -- bash tools/geo/teselas_mapas.sh
# El despliegue de GitHub lo ejecuta también (con caché), así que el .pmtiles no va en git.
set -euo pipefail
cd "$(dirname "$0")/../.."

TMP="${TMPDIR:-/tmp}/teselas_mapas"
SALIDA="static-extra/geo/espana.pmtiles"
python3 tools/geo/teselas_mapas.py "$TMP"

# Cada capa con su rango de zoom y luego se juntan (la clave "tippecanoe": {"minzoom"} por
# polígono no sirve: tippecanoe 2.49 dejaba un solo polígono por tesela).
# - sin límites de tamaño ni de número de polígonos: en un coropletas no puede faltar ninguno
# - bordes compartidos detectados para que al simplificar no se abran huecos entre vecinos
# - se escribe en el disco de Linux y se copia al final (en WSL, escribir en /mnt/c es muy lento)
COMUN=(--force --detect-shared-borders --no-feature-limit --no-tile-size-limit --simplification=4 --simplify-only-low-zooms --quiet)
tippecanoe -o "$TMP/municipios.pmtiles" --minimum-zoom=4 --maximum-zoom=13 -L municipios:"$TMP/municipios.geojsonl" "${COMUN[@]}"
tippecanoe -o "$TMP/secciones.pmtiles" --minimum-zoom=9 --maximum-zoom=13 -L secciones:"$TMP/secciones.geojsonl" "${COMUN[@]}"
tile-join -o "$TMP/espana.pmtiles" --force --no-tile-size-limit --quiet "$TMP/municipios.pmtiles" "$TMP/secciones.pmtiles"

cp "$TMP/espana.pmtiles" "$SALIDA"
ls -lh "$SALIDA"
