---
title: Emprego público
description: "Cantos empregados públicos hai en España, en que administración e sector traballan (sanidade, educación, concellos, forzas de seguridade...), como evolucionou o seu número, canto cobran fronte ao sector privado e canto custan."
i18n_origen: 052b4d0e2fe9
og:
  image: https://spainfacts.org/og-spainfacts.png
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

# 🏛️ Emprego público

Quen traballa para as administracións públicas en España: cantos son, en que administración e en que servizos, onde, canto cobran e canto custan.

<Grid cols=4>
    <KpiCard
        title="Empregados públicos"
        value={resumen[0]?.total}
        formattedValue="{formatNumber(por_1000[0]?.por_1000_hab, 1)} por 1.000 hab."
        period="{formatCompact(resumen[0]?.total, 2)} en total · {ultima[0]?.fecha_texto}"
        source="Rexistro Central de Persoal"
        sparklineData={serie_por_1000.map(d => d.por_1000_hab)}
    />
    <KpiCard
        title="Nas comunidades autónomas"
        value={resumen[0]?.ccaa}
        formattedValue="{formatNumber(resumen[0]?.ccaa / resumen[0]?.total / 0.01, 0)} %"
        period="{formatCompact(resumen[0]?.ccaa, 2)}: sobre todo sanidade e educación"
        source="Rexistro Central de Persoal"
        sparklineData={serie_cuota_ccaa.map(d => d.cuota_ccaa)}
    />
    <KpiCard
        title="Custan ao ano, por habitante"
        value={coste_ultimo[0]?.eur_hab_real}
        formattedValue="{formatNumber(coste_ultimo[0]?.eur_hab_real, 0)} €"
        period="{formatNumber(coste_ultimo[0]?.millones_eur / 1000, 1)} mil M€ en total · {formatNumber(coste_ultimo[0]?.pct_pib, 1)} % do PIB · {coste_ultimo[0]?.anio} (euros de {coste_ultimo[0]?.anio_base})"
        source="Eurostat"
        sparklineData={coste_serie_real.map(d => d.eur_hab_real)}
    />
    <KpiCard
        title="Salario medio (xornada completa)"
        value={salario_ultimo[0]?.publico}
        formattedValue="{formatNumber(salario_ultimo[0]?.publico, 0)} €/mes"
        period="fronte a {formatNumber(salario_ultimo[0]?.privado, 0)} € no sector privado · {salario_ultimo[0]?.anio}"
        source="INE (EPA)"
        sparklineData={salario_serie_real.map(d => d.publico_real)}
    />
</Grid>

## Onde traballan?

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
    title="Empregados públicos por sector e administración"
/>

<p class="text-xs text-gray-500">Case a metade do emprego público está na sanidade e no ensino non universitario, que xestionan as comunidades autónomas desde os traspasos dos anos oitenta a 2002. O Estado conserva sobre todo as Forzas Armadas, a Policía Nacional, a Garda Civil, a Axencia Tributaria, as prisións e os servizos dos ministerios.</p>

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
    <BarChart data={tipos} x=tipo_personal y=efectivos sort=false yFmt=num0 fillColor="#0f766e" title="Por tipo de relación" />
    <BarChart data={sexo_sector} x=sector y=cuota_mujeres swapXY=true sort=false yFmt=pct0 fillColor="#a78bfa" title="Porcentaxe de mulleres por sector" />
</Grid>

<p class="text-xs text-gray-500">{formatNumber(100 * resumen[0]?.temporales / resumen[0]?.total, 0)} % son interinos ou laborais temporais. Funcionario de carreira: praza en propiedade tras oposición. Interino: ocupa unha praza vacante ou unha substitución. Laboral: contrato de traballo (fixo ou temporal). En sanidade, o persoal estatutario dos servizos de saúde cóntase como funcionario.</p>

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

<Details title="Organismos do Estado con máis persoal">

<DataTable data={organismos} rows=20 search=true>
    <Column id=puesto title="#" />
    <Column id=organismo title="Organismo" />
    <Column id=ministerio title="Ministerio de adscrición" />
    <Column id=efectivos title="Efectivos" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_mujeres title="Mulleres" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Ministerios, axencias e organismos do Estado con 100 efectivos ou máis na última edición. Nas comunidades autónomas e nas entidades locais o rexistro non desagrega por consellería ou organismo.</p>

</Details>

## Cantos hai por habitante en cada territorio?

```sql ccaa
SELECT
    t.cod AS cod_ccaa,
    c.nombre AS comunidad,
    '/gl' || c.ruta AS ruta,
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
    attribution="Teselas © Esri · Límites © Instituto Geográfico Nacional · Datos: Rexistro Central de Persoal"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_1000_hab', title: 'Por 1.000 habitantes', fmt: 'num0'},
        {id: 'efectivos', title: 'Empregados públicos', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=efectivos title="Empregados públicos" fmt=num0 />
    <Column id=por_1000_hab title="Por 1.000 hab." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=estado_1000 title="…do Estado" fmt=num1 />
    <Column id=ccaa_1000 title="…da comunidade" fmt=num1 />
    <Column id=local_1000 title="…locais" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Por comunidade onde está o posto de traballo. Ceuta e Melilla destacan polos militares e policías destinados alí, e Madrid polos servizos centrais dos ministerios. Onde unha comunidade presta servizos a través de concertos, consorcios ou empresas públicas (boa parte da sanidade en Cataluña, por exemplo), ese persoal non figura no rexistro e a taxa sae máis baixa. Preme nunha comunidade para ver as súas provincias.</p>

## Como evolucionou?

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
    yAxisTitle="por 1.000 habitantes"
    colorPalette={['#0f766e', '#f59e0b', '#1d4ed8']}
    title="Empregados públicos por 1.000 habitantes (Rexistro Central de Persoal, 1 de xaneiro e 1 de xullo)"
/>

<p class="text-xs text-gray-500">Atención ao salto entre xullo de 2022 e xaneiro de 2023 (~+240.000): o Ministerio revisou en agosto de 2026 todas as edicións desde 2023 con novas fontes e dicionarios (sobre todo nas comunidades autónomas), así que parte do aumento é metodolóxico, non contratacións. Antes de xullo de 2019 non se publican os datos en formato aberto.</p>

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
    yAxisTitle="por 1.000 habitantes"
    title="Asalariados do sector público por 1.000 habitantes segundo a EPA (desde 2002)"
/>

<p class="text-xs text-gray-500">A Enquisa de Poboación Activa dá unha serie máis longa (trimestral desde 2002) e conta tamén as empresas e institucións públicas, pero é unha enquisa: por iso dá máis empregados públicos ca o rexistro (uns 3,6 millóns) e o seu dato trimestral ten marxe de erro. Apréciase o recorte de 2011-2014 (de 3,28 a 2,93 millóns de media anual, coa crise da débeda) e o crecemento posterior, máis rápido desde 2018.</p>

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
    title="Peso do emprego público sobre o total de asalariados (EPA, último trimestre)"
/>

## Canto cobran?

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
    seriesLabels={{publico: 'Sector público', privado: 'Sector privado'}}
    legend=true
    yAxisTitle="€ brutos ao mes (euros constantes)"
    title="Salario medio bruto mensual, xornada completa, en euros de {brecha[0]?.anio_base} descontada a inflación"
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
    title="Salario medio de cada decil (do 10 % que menos cobra ao 10 % que máis)"
/>

<p class="text-xs text-gray-500">Dentro de cada decil (cada tramo do 10 % de asalariados ordenados por salario), o sector público e o privado cobran practicamente o mesmo, e no decil máis alto o privado cobra máis. A diferenza media vén da composición: hai proporcionalmente moitos máis empregados públicos nos tramos altos (médicos, profesores, titulados superiores, máis antigüidade) e case ningún nos empregos peor pagados do sector privado (hostalaría, comercio, agricultura). Salario bruto mensual do emprego principal a xornada completa, antes de impostos e das cotizacións do traballador.</p>

```sql salarios_ccaa
SELECT nombre AS comunidad, salario_publico, salario_privado, brecha_publico_pct AS diferencia
FROM mother.empleo_salarios_ccaa
WHERE nivel = 'ccaa'
ORDER BY salario_publico DESC
```

<DataTable data={salarios_ccaa} rows=all>
    <Column id=comunidad title="Comunidade" />
    <Column id=salario_publico title="Público (€/ano)" fmt=num0 />
    <Column id=salario_privado title="Privado (€/ano)" fmt=num0 />
    <Column id=diferencia title="Diferenza" fmt='0"%"' />
</DataTable>

<p class="text-xs text-gray-500">Salario medio anual bruto en 2022 segundo a Enquisa Cuadrienal de Estrutura Salarial do INE, por comunidade do centro de traballo e segundo quen controla a empresa ou organismo. Só cobre a quen cotiza ao Réxime Xeral: deixa fóra os funcionarios de mutualidades (MUFACE, ISFAS, MUGEJU).</p>

## Canto custan?

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
    yAxisTitle="€ por habitante (constantes)"
    title="Custo do persoal público por habitante e administración, en euros de {coste[0]?.anio_base}"
/>

<LineChart
    data={coste_total}
    x=anio
    y=pct_pib
    yFmt=num1
    xFmt="####"
    colorPalette={['#1d4ed8']}
    yAxisTitle="% do PIB"
    title="Custo do persoal público sobre o PIB"
/>

<p class="text-xs text-gray-500">Por habitante e en euros constantes, para que a evolución non reflicta só o aumento da poboación e dos prezos. Remuneración de asalariados das administracións públicas (contabilidade nacional, Eurostat): soldos e salarios máis as cotizacións sociais que paga a administración como empregadora. As transferencias entre administracións non contan dúas veces: cada unha paga ao seu persoal.</p>

```sql coste_ccaa
SELECT
    c.nombre AS comunidad,
    '/gl' || c.ruta AS ruta,
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

### Gasto de persoal de cada comunidade e dos seus concellos ({coste_ccaa[0]?.anio}, euros de {coste_ccaa[0]?.anio_base})

<DataTable data={coste_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidade" />
    <Column id=gasto_ccaa_millones title="Comunidade (M€)" fmt=num0 />
    <Column id=gasto_personal_ccaa_eur_hab_real title="Comunidade (€/hab.)" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=gasto_personal_ayuntamientos_eur_hab_real title="Concellos (€/hab.)" fmt=num0 contentType=bar barColor="#fde68a" />
</DataTable>

<p class="text-xs text-gray-500">Capítulo 1 («gastos de persoal») das liquidacións: o da comunidade, de Facenda; o dos concellos, suma dos que enviaron a súa liquidación a Facenda (CONPREL), por habitante deses municipios. O País Vasco e Navarra cobran os seus propios impostos (réxime foral) e asumen máis competencias, o que eleva o seu gasto; en Álava e Navarra os concellos non aparecen en CONPREL. O gasto de persoal de cada concello está na súa ficha de <a href="/gl/territorios/municipios">municipios</a>.</p>

---

## Fontes e notas

- **[Boletín Estatístico do Persoal ao Servizo das Administracións Públicas (Rexistro Central de Persoal)](https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html)**, Ministerio para a Transformación Dixital e da Función Pública: efectivos a 1 de xaneiro e 1 de xullo desde 2019. Non inclúe empresas públicas nin fundacións, nin chega ao detalle de cada concello (só por tipo de entidade e provincia). O persoal das entidades locais procede da afiliación á Seguridade Social.
- **[INE – Enquisa de Poboación Activa](https://www.ine.es/jaxiT3/Tabla.htm?t=65193)**: asalariados públicos por administración (táboa 65193) e por comunidade (65327); salarios por decil (66250).
- **[INE – Enquisa de Estrutura Salarial 2022](https://www.ine.es/jaxiT3/Tabla.htm?t=36887)**: salario anual por comunidade e control público ou privado.
- **[Eurostat – gov_10a_main](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main/default/table)**: remuneración de asalariados (D1) das administracións públicas por subsector.
- **Ministerio de Facenda**: liquidacións das comunidades autónomas e das entidades locais (CONPREL), capítulo 1.
- Os tres recontos miden cousas distintas: o rexistro conta persoas con posto nunha administración; a EPA estima asalariados que din traballar no sector público (incluídas as empresas públicas); a contabilidade nacional mide o custo.

<LastRefreshed prefix="Datos actualizados" />
