# Convenciones del modelo de datos publicado (mother.*)

Cómo deben quedar las tablas para que las páginas, el chat, el servidor MCP y quien descargue los datos las lean todas igual. **Valen para toda tabla nueva** (también las que añaden los agentes de temas nuevos) y para las que se limpian.

Una columna mal formada **se sustituye**, no se duplica: se cambia en el modelo y se cambian a la vez las páginas que la usan (y sus copias en `pages/en|ca|gl|eu`). La web está en desarrollo: se prefiere un modelo limpio a conservar columnas viejas.

## Territorio

- Tablas con varios niveles: `nivel` (`pais`, `ccaa`, `provincia`, `municipio`), `cod` (código INE: `00` España, `01`-`19` comunidades, `01`-`52` provincias, 5 cifras municipios) y `nombre` (el de `mother.territorios`).
- Tablas de un solo nivel: código y nombre juntos: `cod_ccaa` + `ccaa`, `cod_prov` + `provincia`, `cod_mun` + `municipio`. Nunca un código sin su nombre al lado.
- España como fila (`nivel = 'pais'`, `cod = '00'`, `nombre = 'España'`) cuando la tabla tenga totales nacionales, y una sola vez: si dos fuentes dan España, se elige una o se separan en tablas.
- Códigos de otras administraciones (Hacienda...) se traducen a INE en staging.
- Países: `cod_pais` (ISO 3166-1 alfa-2; `EU27_2020` la UE, `OECD` la OCDE) + `pais` en castellano, con el seed `paises_iso` (`transform/seeds/paises_iso.csv`). Nunca ISO3 ni códigos propios de cada fuente en la tabla publicada.

## Tiempo

- Datos anuales: `anio` INTEGER.
- Datos de periodo menor: `fecha` DATE con el primer día del periodo (mes, trimestre, semestre) y además `anio`.
- Año en curso incompleto en tablas que suman meses: columna `meses` (meses con dato) o `es_parcial` BOOLEAN.
- Nada de periodos especiales mezclados con los normales (trimestre 0 = media anual, decil 0 = media): van en otra tabla.

## Cifras

- Porcentajes en 0-100 con sufijo `_pct`. Nunca proporciones 0-1. Trampa de Evidence: una gráfica `type=stacked100` no admite una `y` acabada en `_pct` (añade y quita ese sufijo por dentro y falla con «'x' is not a column»); en la consulta de la página se renombra (`cuota_pct AS cuota`).
- Euros: `_eur` (corrientes), `_eur_real` (constantes), `_eur_hab`, `_eur_hab_real`; millones `_meur`, `_meur_real`. **Toda cifra en euros que se compare entre años lleva su versión real, y entre territorios su versión por habitante** (principio rector de la web). Real con `mother.deflactor` (España, desde 1996) o `mother.deflactor_paises` (IPCA por país de Eurostat); columna `anio_base` con el año de los euros constantes. Un año sin deflactor da NULL, nunca «sin inflación».
- Tasas por población: `_por_1000_hab` / `_por_100k_hab`. Población: `poblacion_territorios` (España), `poblacion_municipios`, población de países de Eurostat.
- Cifras que se enseñan en total y por habitante (emisiones, exportaciones, deuda local...): las dos columnas; la página enseña las dos. Las que solo tienen sentido en total (potencia de centrales) no llevan por habitante.
- Una columna, una unidad. Una tabla en formato largo (`indicador`, `valor`) lleva `unidad` en cada fila; mejor aún, una tabla por familia de unidades.
- Si una tabla mezcla fuentes que no se comparan entre sí (INE y Eurostat), se separa en tablas.

## Dimensiones

- Valor `Total` (o `Ambos sexos`, `Todas las edades`) cuando el total existe en la fuente.
- Si una dimensión distingue cosas que no se suman (estado de una central, serie original o desestacionalizada), la ficha semántica lleva `defecto`.
- Booleanos como BOOLEAN, no como texto.
- Sin filas basura (años imposibles, filas de prueba): se filtran en el modelo.

## Tablas

- Sin tablas duplicadas ni sin uso. De referencia: `territorios`, `deflactor`, `deflactor_paises`, `paises_iso`, `gobiernos_presidentes`. Auxiliares que leen las páginas pero no son datos para el público: `metricas`, `mapas_indicadores` (la ficha las marca `usar: false`).
- Toda tabla nueva: su `sources/mother/<tabla>.sql`, descripción de columnas en el `schema_*.yml` y su ficha en `tools/chat/semantica/lote-*.json` que pase `node tools/chat/semantica/validar.mjs`.
