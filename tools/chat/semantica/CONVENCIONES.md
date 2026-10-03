# Convenciones del modelo de datos publicado (mother.*)

Para que las páginas, el chat, el MCP y quien descargue los datos lean todas las tablas igual. Se aplican al añadir tablas nuevas y al limpiar las que hay, **sin quitar ni renombrar columnas que use alguna página** (se añaden las nuevas al lado; las viejas se retiran después, cuando ninguna página las use).

## Territorio

- Tablas con varios niveles: `nivel` (`pais`, `ccaa`, `provincia`, `municipio`), `cod` (código INE: `00` España, `01`-`19` comunidades, `01`-`52` provincias, 5 cifras municipios) y `nombre` (el de `mother.territorios`).
- Tablas de un solo nivel: código y nombre juntos: `cod_ccaa` + `ccaa`, `cod_prov` + `provincia`, `cod_mun` + `municipio`. Nunca un código sin su nombre al lado.
- España como fila (`nivel = 'pais'`, `cod = '00'`, `nombre = 'España'`) cuando la tabla tenga totales nacionales; nunca la misma España dos veces por venir de dos fuentes.
- Códigos de Hacienda u otros: se traducen a INE en staging (ver la trampa de códigos de comunidad en el plan de territorios).
- Países: `cod_pais` (ISO 3166-1 alfa-2, `EU27_2020` para la UE) + `pais` en castellano.

## Tiempo

- Datos anuales: `anio` INTEGER.
- Datos de periodo menor: `fecha` DATE con el primer día del periodo (mes, trimestre, semestre) y además `anio`.
- Año en curso incompleto en tablas anuales que suman meses: columna `meses` (número de meses con dato) o `es_parcial` BOOLEAN.
- Nada de periodos especiales mezclados con los normales (trimestre 0 = media anual, decil 0 = media): van en otra tabla o con una columna que los distinga y un valor `Total`/`Media` legible.

## Cifras

- Porcentajes en 0-100 con sufijo `_pct`. Nunca proporciones 0-1.
- Euros: `_eur` (corrientes), `_eur_real` (constantes del año base, con `mother.deflactor`), `_eur_hab`, `_eur_hab_real`. Millones: `_meur`, `_meur_real`. Toda tabla con euros que se compare entre años o territorios lleva la versión por habitante y la real (principio rector de la web).
- Tasas por población: `_por_1000_hab` / `_por_100k_hab`.
- Una columna, una unidad. Si una tabla junta indicadores con unidades distintas (formato largo), lleva `indicador` + `unidad` en cada fila y la página filtra por indicador; mejor aún, una tabla por familia de unidades.

## Dimensiones

- Valor `Total` (o `Ambos sexos`, `Todas las edades`) cuando el total existe en la fuente; si no existe y la cifra se puede sumar, no hace falta.
- Si una dimensión distingue cosas que no se mezclan (estado: en operación / en tramitación; fuente: INE / Eurostat), la ficha semántica lo dice con `defecto`; si casi siempre se usa un valor, considerar una tabla aparte para él.
- Booleanos como BOOLEAN, no como texto `'true'`/`'S'`.

## Tablas

- Sin tablas duplicadas ni auxiliares en mother.* salvo las de referencia (`territorios`, `deflactor`).
- Toda tabla nueva lleva su ficha en `tools/chat/semantica/lote-*.json` y pasa `validar.mjs`.
