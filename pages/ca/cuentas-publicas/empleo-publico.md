---
title: Ocupació pública
description: "Quants empleats públics hi ha a Espanya, en quina administració i sector treballen (sanitat, educació, ajuntaments, forces de seguretat...), com ha evolucionat el seu nombre, quant cobren davant del sector privat i quant costen."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 052b4d0e2fe9
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql ultima
SELECT
    max(fecha) AS fecha,
    strftime(max(fecha), '%d/%m/%Y') AS fecha_texto
FROM mother.empleo_efectivos
```

```sql resumen
SELECT
    sum(efectivos) AS total,
    sum(efectivos) FILTER (WHERE administracion = 'Estado') AS estado,
    sum(efectivos) FILTER (WHERE administracion = 'Comunidades autónomas') AS ccaa,
    sum(efectivos) FILTER (WHERE administracion = 'Entidades locales') AS local,
    sum(efectivos) FILTER (WHERE sexo = 'Mujeres') AS mujeres,
    sum(efectivos) FILTER (WHERE tipo_personal IN ('Funcionario interino', 'Laboral temporal')) AS temporales
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
```

```sql por_1000
SELECT por_1000_hab FROM mother.empleo_territorio
WHERE nivel = 'pais' AND administracion = 'Total' AND fecha = (SELECT fecha FROM ${ultima})
```

```sql coste_ultimo
SELECT anio, anio_base, millones_eur, pct_pib, eur_hab_real
FROM mother.empleo_coste
WHERE cod_sector = 'S13'
ORDER BY anio DESC
LIMIT 1
```

```sql salario_ultimo
SELECT
    anio,
    max(salario_mensual) FILTER (WHERE sector = 'Público') AS publico,
    max(salario_mensual) FILTER (WHERE sector = 'Privado') AS privado
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo' AND decil_nombre = 'Total'
GROUP BY anio
ORDER BY anio DESC
LIMIT 1
```

```sql serie_cuota_ccaa
SELECT
    fecha,
    100 * sum(efectivos) FILTER (WHERE administracion = 'Comunidades autónomas') / sum(efectivos) AS cuota_ccaa
FROM mother.empleo_efectivos
GROUP BY fecha
ORDER BY fecha
```

```sql serie_por_1000
SELECT fecha, por_1000_hab
FROM mother.empleo_territorio
WHERE nivel = 'pais' AND administracion = 'Total' AND por_1000_hab IS NOT NULL
ORDER BY fecha
```

```sql coste_serie_real
-- Para las mini-gráficas: euros por habitante a precios constantes (ya calculados en la tabla)
SELECT anio, eur_hab_real
FROM mother.empleo_coste
WHERE cod_sector = 'S13' AND eur_hab_real IS NOT NULL
ORDER BY anio
```

```sql salario_serie_real
SELECT anio, max(salario_mensual_real) AS publico_real
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo' AND decil_nombre = 'Total' AND sector = 'Público' AND salario_mensual_real IS NOT NULL
GROUP BY anio
ORDER BY anio
```

# 🏛️ Ocupació pública

Qui treballa per a les administracions públiques a Espanya: quants són, en quina administració i en quins serveis, on, quant cobren i quant costen.

<Grid cols=4>
    <KpiCard
        title="Empleats públics"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(por_1000[0]?.por_1000_hab, 1)} per 1.000 hab."
        period="{formatCompact(resumen[0]?.total, 2)} en total · {ultima[0]?.fecha_texto}"
        source="Registre Central de Personal"
        sparklineData={serie_por_1000.map(d => d.por_1000_hab)}
    />
    <KpiCard
        title="A les comunitats autònomes"
        value={resumen[0]?.ccaa}
        formattedValue="{formatNumber(resumen[0]?.ccaa / resumen[0]?.total / 0.01, 0)} %"
        period="{formatCompact(resumen[0]?.ccaa, 2)}: sobretot sanitat i educació"
        source="Registre Central de Personal"
        sparklineData={serie_cuota_ccaa.map(d => d.cuota_ccaa)}
    />
    <KpiCard
        title="Costen a l'any, per habitant"
        value={coste_ultimo[0]?.eur_hab_real}
        formattedValue="{formatNumber(coste_ultimo[0]?.eur_hab_real, 0)} €"
        period="{formatNumber(coste_ultimo[0]?.millones_eur / 1000, 1)} mil M€ en total · {formatNumber(coste_ultimo[0]?.pct_pib, 1)} % del PIB · {coste_ultimo[0]?.anio} (euros de {coste_ultimo[0]?.anio_base})"
        source="Eurostat"
        sparklineData={coste_serie_real.map(d => d.eur_hab_real)}
    />
    <KpiCard
        title="Salari mitjà (jornada completa)"
        value={salario_ultimo[0]?.publico}
        formattedValue="{formatNumber(salario_ultimo[0]?.publico, 0)} €/mes"
        period="davant de {formatNumber(salario_ultimo[0]?.privado, 0)} € al sector privat · {salario_ultimo[0]?.anio}"
        source="INE (EPA)"
        sparklineData={salario_serie_real.map(d => d.publico_real)}
    />
</Grid>

## On treballen?

```sql sectores
SELECT administracion, sector, sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
GROUP BY ALL
ORDER BY efectivos DESC
```

<BarChart
    data={sectores}
    x=sector
    y=efectivos
    series=administracion
    swapXY=true
    yFmt=num0
    sort=false
    colorPalette={['#1d4ed8', '#0f766e', '#f59e0b']}
    title="Empleats públics per sector i administració"
/>

<p class="text-xs text-gray-500">Gairebé la meitat de l'ocupació pública és a la sanitat i l'ensenyament no universitari, que gestionen les comunitats autònomes des dels traspassos dels anys vuitanta fins al 2002. L'Estat conserva sobretot les Forces Armades, la Policia Nacional, la Guàrdia Civil, l'Agència Tributària, les presons i els serveis dels ministeris.</p>

```sql tipos
SELECT tipo_personal, sum(efectivos) AS efectivos,
    CASE tipo_personal WHEN 'Funcionario de carrera' THEN 1 WHEN 'Funcionario interino' THEN 2 WHEN 'Laboral fijo' THEN 3 WHEN 'Laboral temporal' THEN 4 WHEN 'Laboral (sin detalle)' THEN 5 ELSE 6 END AS orden
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
GROUP BY ALL
ORDER BY orden
```

```sql sexo_sector
SELECT sector, sum(efectivos) FILTER (WHERE sexo = 'Mujeres') / sum(efectivos) AS cuota_mujeres, sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
WHERE fecha = (SELECT fecha FROM ${ultima})
GROUP BY sector
HAVING sum(efectivos) > 10000
ORDER BY cuota_mujeres DESC
```

<Grid cols=2>
    <BarChart data={tipos} x=tipo_personal y=efectivos sort=false yFmt=num0 fillColor="#0f766e" title="Per tipus de relació" />
    <BarChart data={sexo_sector} x=sector y=cuota_mujeres swapXY=true sort=false yFmt=pct0 fillColor="#a78bfa" title="Percentatge de dones per sector" />
</Grid>

<p class="text-xs text-gray-500">El {formatNumber(100 * resumen[0]?.temporales / resumen[0]?.total, 0)} % són interins o laborals temporals. Funcionari de carrera: plaça en propietat després d'unes oposicions. Interí: ocupa una plaça vacant o una substitució. Laboral: contracte de treball (fix o temporal). En sanitat, el personal estatutari dels serveis de salut es compta com a funcionari.</p>

```sql organismos
SELECT
    row_number() OVER (ORDER BY efectivos DESC) AS puesto,
    organismo,
    administracion,
    nullif(ministerio, '') AS ministerio,
    efectivos,
    mujeres / efectivos AS cuota_mujeres
FROM mother.empleo_organismos
ORDER BY efectivos DESC
```

<Details title="Organismes de l'Estat amb més personal">

<DataTable data={organismos} rows=20 search=true>
    <Column id=puesto title="#" />
    <Column id=organismo title="Organisme" />
    <Column id=ministerio title="Ministeri d'adscripció" />
    <Column id=efectivos title="Efectius" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_mujeres title="Dones" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Ministeris, agències i organismes de l'Estat amb 100 efectius o més en l'última edició. A les comunitats autònomes i les entitats locals el registre no desglossa per conselleria o organisme.</p>

</Details>

## Quants n'hi ha per habitant a cada territori?

```sql ccaa
SELECT
    t.cod AS cod_ccaa,
    c.nombre AS comunidad,
    '/ca' || c.ruta AS ruta,
    max(t.efectivos) FILTER (WHERE t.administracion = 'Total') AS efectivos,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Total') AS por_1000_hab,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Estado') AS estado_1000,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Comunidades autónomas') AS ccaa_1000,
    max(t.por_1000_hab) FILTER (WHERE t.administracion = 'Entidades locales') AS local_1000
FROM mother.empleo_territorio t
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = t.cod
WHERE t.nivel = 'ccaa' AND t.fecha = (SELECT fecha FROM ${ultima})
GROUP BY ALL
ORDER BY por_1000_hab DESC
```

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod_ccaa"
    value="por_1000_hab"
    valueFmt="num0"
    link="ruta"
    colorPalette={['#eff6ff', '#60a5fa', '#1e3a8a']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: Registre Central de Personal"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_1000_hab', title: 'Per 1.000 habitants', fmt: 'num0'},
        {id: 'efectivos', title: 'Empleats públics', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=efectivos title="Empleats públics" fmt=num0 />
    <Column id=por_1000_hab title="Per 1.000 hab." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=estado_1000 title="…de l'Estat" fmt=num1 />
    <Column id=ccaa_1000 title="…de la comunitat" fmt=num1 />
    <Column id=local_1000 title="…locals" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Per comunitat on hi ha el lloc de treball. Ceuta i Melilla destaquen pels militars i policies destinats allà, i Madrid pels serveis centrals dels ministeris. Quan una comunitat presta serveis a través de concerts, consorcis o empreses públiques (bona part de la sanitat a Catalunya, per exemple), aquest personal no figura al registre i la taxa surt més baixa. Fes clic en una comunitat per veure'n les províncies.</p>

## Com ha evolucionat?

```sql serie_registro
-- Empleados por 1.000 habitantes (padrón del año; el último disponible para los más recientes)
SELECT fecha, administracion, efectivos, por_1000_hab AS por_1000
FROM mother.empleo_territorio
WHERE nivel = 'pais' AND administracion <> 'Total'
ORDER BY fecha
```

<BarChart
    data={serie_registro}
    x=fecha
    y=por_1000
    series=administracion
    type=stacked
    yFmt=num1
    xFmt="mmm yyyy"
    yAxisTitle="per 1.000 habitants"
    colorPalette={['#0f766e', '#f59e0b', '#1d4ed8']}
    title="Empleats públics per 1.000 habitants (Registre Central de Personal, 1 de gener i 1 de juliol)"
/>

<p class="text-xs text-gray-500">Compte amb el salt entre el juliol del 2022 i el gener del 2023 (~+240.000): el Ministeri va revisar l'agost del 2026 totes les edicions des del 2023 amb noves fonts i diccionaris (sobretot a les comunitats autònomes), de manera que part de l'augment és metodològic, no contractacions. Abans del juliol del 2019 les dades no es publiquen en format obert.</p>

```sql serie_epa
WITH pob AS (
    SELECT CAST(anio AS INTEGER) AS anio, poblacion
    FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
)
SELECT e.trimestre, e.administracion, e.asalariados,
    1000.0 * e.asalariados / p.poblacion AS por_1000
FROM mother.empleo_epa_administracion e
JOIN pob p ON p.anio = greatest(least(CAST(year(e.trimestre) AS INTEGER), (SELECT max(anio) FROM pob)), (SELECT min(anio) FROM pob))
WHERE e.administracion NOT IN ('Total', 'Otras / no sabe')
ORDER BY e.trimestre
```

<BarChart
    data={serie_epa}
    x=trimestre
    y=por_1000
    series=administracion
    type=stacked
    yFmt=num1
    xFmt="yyyy"
    yAxisTitle="per 1.000 habitants"
    title="Assalariats del sector públic per 1.000 habitants segons l'EPA (des del 2002)"
/>

<p class="text-xs text-gray-500">L'Enquesta de Població Activa dona una sèrie més llarga (trimestral des del 2002) i compta també les empreses i institucions públiques, però és una enquesta: per això dona més empleats públics que el registre (uns 3,6 milions) i la seva dada trimestral té marge d'error. S'hi aprecien la retallada del 2011-2014 (de 3,28 a 2,93 milions de mitjana anual, amb la crisi del deute) i el creixement posterior, més ràpid des del 2018.</p>

```sql cuota_ccaa
SELECT e.fecha, e.nombre AS comunidad, e.cuota_publico_pct
FROM mother.empleo_epa_ccaa e
WHERE e.nivel = 'ccaa' AND e.fecha = (SELECT max(fecha) FROM mother.empleo_epa_ccaa)
ORDER BY e.cuota_publico_pct DESC
```

<BarChart
    data={cuota_ccaa}
    x=comunidad
    y=cuota_publico_pct
    swapXY=true
    sort=false
    yFmt='0"%"'
    fillColor="#1d4ed8"
    title="Pes de l'ocupació pública sobre el total d'assalariats (EPA, últim trimestre)"
/>

## Quant cobren?

```sql deciles
SELECT
    decil,
    decil_nombre AS decil_txt,
    sector,
    salario_mensual
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo'
  AND anio = (SELECT max(anio) FROM mother.empleo_salarios_deciles)
  AND decil IS NOT NULL
  AND sector IN ('Público', 'Privado')
ORDER BY decil
```

```sql brecha
-- En euros constantes del último año completo (descontada la inflación con el IPC)
SELECT
    s.anio,
    max(s.salario_mensual_real) FILTER (WHERE s.sector = 'Público') AS publico,
    max(s.salario_mensual_real) FILTER (WHERE s.sector = 'Privado') AS privado,
    any_value(s.anio_euros) AS anio_base
FROM mother.empleo_salarios_deciles s
WHERE s.jornada = 'Jornada a tiempo completo' AND s.decil_nombre = 'Total'
GROUP BY s.anio
ORDER BY s.anio
```

<LineChart
    data={brecha}
    x=anio
    y={['publico', 'privado']}
    yFmt=num0
    xFmt="####"
    colorPalette={['#1d4ed8', '#f59e0b']}
    seriesLabels={{publico: 'Sector públic', privado: 'Sector privat'}}
    legend=true
    yAxisTitle="€ bruts al mes (euros constants)"
    title="Salari mitjà brut mensual, jornada completa, en euros de {brecha[0]?.anio_base} descomptada la inflació"
/>

<BarChart
    data={deciles}
    x=decil_txt
    y=salario_mensual
    series=sector
    type=grouped
    yFmt=num0
    sort=false
    colorPalette={['#f59e0b', '#1d4ed8']}
    title="Salari mitjà de cada decil (del 10 % que menys cobra al 10 % que més)"
/>

<p class="text-xs text-gray-500">Dins de cada decil (cada tram del 10 % d'assalariats ordenats per salari), el sector públic i el privat cobren pràcticament el mateix, i en el decil més alt el privat cobra més. La diferència mitjana ve de la composició: hi ha proporcionalment molts més empleats públics als trams alts (metges, professors, titulats superiors, més antiguitat) i gairebé cap a les feines pitjor pagades del sector privat (hostaleria, comerç, agricultura). Salari brut mensual de l'ocupació principal a jornada completa, abans d'impostos i de les cotitzacions del treballador.</p>

```sql salarios_ccaa
SELECT nombre AS comunidad, salario_publico, salario_privado, brecha_publico_pct AS diferencia
FROM mother.empleo_salarios_ccaa
WHERE nivel = 'ccaa'
ORDER BY salario_publico DESC
```

<DataTable data={salarios_ccaa} rows=all>
    <Column id=comunidad title="Comunitat" />
    <Column id=salario_publico title="Públic (€/any)" fmt=num0 />
    <Column id=salario_privado title="Privat (€/any)" fmt=num0 />
    <Column id=diferencia title="Diferència" fmt='0"%"' />
</DataTable>

<p class="text-xs text-gray-500">Salari mitjà anual brut el 2022 segons l'Enquesta Quadriennal d'Estructura Salarial de l'INE, per comunitat del centre de treball i segons qui controla l'empresa o l'organisme. Només cobreix els qui cotitzen al Règim General: deixa fora els funcionaris de mutualitats (MUFACE, ISFAS, MUGEJU).</p>

## Quant costen?

```sql coste
-- Euros por habitante y constantes (descontada la inflación con el IPC; ya calculados en la tabla)
SELECT c.anio, c.subsector, c.millones_eur / 1000 AS miles_millones, c.pct_pib,
    c.eur_hab_real, c.anio_base
FROM mother.empleo_coste c
WHERE c.cod_sector <> 'S13' AND c.eur_hab_real IS NOT NULL
ORDER BY c.anio
```

```sql coste_total
SELECT anio, pct_pib FROM mother.empleo_coste WHERE cod_sector = 'S13' ORDER BY anio
```

<BarChart
    data={coste}
    x=anio
    y=eur_hab_real
    series=subsector
    type=stacked
    yFmt=num0
    xFmt="####"
    yAxisTitle="€ per habitant (constants)"
    title="Cost del personal públic per habitant i administració, en euros de {coste[0]?.anio_base}"
/>

<LineChart
    data={coste_total}
    x=anio
    y=pct_pib
    yFmt=num1
    xFmt="####"
    colorPalette={['#1d4ed8']}
    yAxisTitle="% del PIB"
    title="Cost del personal públic sobre el PIB"
/>

<p class="text-xs text-gray-500">Per habitant i en euros constants, perquè l'evolució no reflecteixi només l'augment de la població i dels preus. Remuneració d'assalariats de les administracions públiques (comptabilitat nacional, Eurostat): sous i salaris més les cotitzacions socials que paga l'administració com a ocupadora. Les transferències entre administracions no compten dues vegades: cadascuna paga el seu personal.</p>

```sql coste_ccaa
SELECT
    c.nombre AS comunidad,
    '/ca' || c.ruta AS ruta,
    g.anio,
    g.anio_base,
    g.gasto_personal_ccaa / 1e6 AS gasto_ccaa_millones,
    g.gasto_personal_ccaa_eur_hab_real,
    g.gasto_personal_ayuntamientos_eur_hab_real
FROM mother.empleo_gasto_personal_territorio g
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = g.cod
WHERE g.nivel = 'ccaa'
  AND g.anio = (SELECT max(anio) FROM mother.empleo_gasto_personal_territorio WHERE nivel = 'ccaa' AND gasto_personal_ccaa IS NOT NULL AND gasto_personal_ayuntamientos IS NOT NULL)
ORDER BY g.gasto_personal_ccaa_eur_hab_real DESC
```

### Despesa de personal de cada comunitat i dels seus ajuntaments ({coste_ccaa[0]?.anio}, euros de {coste_ccaa[0]?.anio_base})

<DataTable data={coste_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=gasto_ccaa_millones title="Comunitat (M€)" fmt=num0 />
    <Column id=gasto_personal_ccaa_eur_hab_real title="Comunitat (€/hab.)" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=gasto_personal_ayuntamientos_eur_hab_real title="Ajuntaments (€/hab.)" fmt=num0 contentType=bar barColor="#fde68a" />
</DataTable>

<p class="text-xs text-gray-500">Capítol 1 («despeses de personal») de les liquidacions: el de la comunitat, d'Hisenda; el dels ajuntaments, suma dels que van enviar la liquidació a Hisenda (CONPREL), per habitant d'aquests municipis. El País Basc i Navarra recapten els seus propis impostos (règim foral) i assumeixen més competències, cosa que n'eleva la despesa; a Àlaba i Navarra els ajuntaments no apareixen a CONPREL. La despesa de personal de cada ajuntament és a la seva fitxa de <a href="/ca/territorios/municipios">municipis</a>.</p>

---

## Fonts i notes

- **[Butlletí Estadístic del Personal al Servei de les Administracions Públiques (Registre Central de Personal)](https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html)**, Ministeri per a la Transformació Digital i de la Funció Pública: efectius a 1 de gener i 1 de juliol des del 2019. No inclou empreses públiques ni fundacions, ni arriba al detall de cada ajuntament (només per tipus d'entitat i província). El personal de les entitats locals procedeix de l'afiliació a la Seguretat Social.
- **[INE – Enquesta de Població Activa](https://www.ine.es/jaxiT3/Tabla.htm?t=65193)**: assalariats públics per administració (taula 65193) i per comunitat (65327); salaris per decil (66250).
- **[INE – Enquesta d'Estructura Salarial 2022](https://www.ine.es/jaxiT3/Tabla.htm?t=36887)**: salari anual per comunitat i control públic o privat.
- **[Eurostat – gov_10a_main](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main/default/table)**: remuneració d'assalariats (D1) de les administracions públiques per subsector.
- **Ministeri d'Hisenda**: liquidacions de les comunitats autònomes i de les entitats locals (CONPREL), capítol 1.
- Els tres recomptes mesuren coses diferents: el registre compta persones amb lloc de treball en una administració; l'EPA estima assalariats que diuen treballar al sector públic (incloses les empreses públiques); la comptabilitat nacional en mesura el cost.

<LastRefreshed prefix="Dades actualitzades" />
