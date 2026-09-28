---
title: Empleo público
description: "Cuántos empleados públicos hay en España, en qué administración y sector trabajan (sanidad, educación, ayuntamientos, fuerzas de seguridad...), cómo ha evolucionado su número, cuánto cobran frente al sector privado y cuánto cuestan."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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
SELECT anio, millones_eur, pct_pib, eur_por_habitante
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
WHERE jornada = 'Jornada a tiempo completo' AND decil = 0
GROUP BY anio
ORDER BY anio DESC
LIMIT 1
```

# 🏛️ Empleo público

Quién trabaja para las administraciones públicas en España: cuántos son, en qué administración y en qué servicios, dónde, cuánto cobran y cuánto cuestan.

<Grid cols=4>
    <KpiCard
        title="Empleados públicos"
        value={resumen[0]?.total}
        formattedValue={formatCompact(resumen[0]?.total, 2)}
        period="{formatNumber(por_1000[0]?.por_1000_hab, 0)} por cada 1.000 habitantes · {ultima[0]?.fecha_texto}"
        source="Registro Central de Personal"
    />
    <KpiCard
        title="En las comunidades autónomas"
        value={resumen[0]?.ccaa}
        formattedValue="{formatNumber(100 * resumen[0]?.ccaa / resumen[0]?.total, 0)} %"
        period="{formatCompact(resumen[0]?.ccaa, 2)}: sobre todo sanidad y educación"
        source="Registro Central de Personal"
    />
    <KpiCard
        title="Cuestan al año"
        value={coste_ultimo[0]?.millones_eur}
        formattedValue="{formatNumber(coste_ultimo[0]?.millones_eur / 1000, 1)} mil M€"
        period="{formatNumber(coste_ultimo[0]?.pct_pib, 1)} % del PIB · {formatNumber(coste_ultimo[0]?.eur_por_habitante, 0)} € por habitante · {coste_ultimo[0]?.anio}"
        source="Eurostat"
    />
    <KpiCard
        title="Salario medio (jornada completa)"
        value={salario_ultimo[0]?.publico}
        formattedValue="{formatNumber(salario_ultimo[0]?.publico, 0)} €/mes"
        period="frente a {formatNumber(salario_ultimo[0]?.privado, 0)} € en el sector privado · {salario_ultimo[0]?.anio}"
        source="INE (EPA)"
    />
</Grid>

## ¿Dónde trabajan?

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
    title="Empleados públicos por sector y administración"
/>

<p class="text-xs text-gray-500">Casi la mitad del empleo público está en la sanidad y la enseñanza no universitaria, que gestionan las comunidades autónomas desde los traspasos de los años ochenta a 2002. El Estado conserva sobre todo las Fuerzas Armadas, la Policía Nacional, la Guardia Civil, la Agencia Tributaria, las prisiones y los servicios de los ministerios.</p>

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
    <BarChart data={sexo_sector} x=sector y=cuota_mujeres swapXY=true sort=false yFmt=pct0 fillColor="#a78bfa" title="Porcentaje de mujeres por sector" />
</Grid>

<p class="text-xs text-gray-500">{formatNumber(100 * resumen[0]?.temporales / resumen[0]?.total, 0)} % son interinos o laborales temporales. Funcionario de carrera: plaza en propiedad tras oposición. Interino: ocupa una plaza vacante o una sustitución. Laboral: contrato de trabajo (fijo o temporal). En sanidad, el personal estatutario de los servicios de salud se cuenta como funcionario.</p>

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

<Details title="Organismos del Estado con más personal">

<DataTable data={organismos} rows=20 search=true>
    <Column id=puesto title="#" />
    <Column id=organismo title="Organismo" />
    <Column id=ministerio title="Ministerio de adscripción" />
    <Column id=efectivos title="Efectivos" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=cuota_mujeres title="Mujeres" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Ministerios, agencias y organismos del Estado con 100 efectivos o más en la última edición. En las comunidades autónomas y las entidades locales el registro no desglosa por consejería u organismo.</p>

</Details>

## ¿Cuántos hay por habitante en cada territorio?

```sql ccaa
SELECT
    t.cod AS cod_ccaa,
    c.nombre AS comunidad,
    c.ruta,
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

<AreaMap
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
    attribution="Tiles © Esri · Límites © Instituto Geográfico Nacional · Datos: Registro Central de Personal"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'por_1000_hab', title: 'Por 1.000 habitantes', fmt: 'num0'},
        {id: 'efectivos', title: 'Empleados públicos', fmt: 'num0'}
    ]}
/>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=efectivos title="Empleados públicos" fmt=num0 />
    <Column id=por_1000_hab title="Por 1.000 hab." fmt=num1 contentType=bar barColor="#bfdbfe" />
    <Column id=estado_1000 title="…del Estado" fmt=num1 />
    <Column id=ccaa_1000 title="…de la comunidad" fmt=num1 />
    <Column id=local_1000 title="…locales" fmt=num1 />
</DataTable>

<p class="text-xs text-gray-500">Por comunidad donde está el puesto de trabajo. Ceuta y Melilla destacan por los militares y policías destinados allí, y Madrid por los servicios centrales de los ministerios. Donde una comunidad presta servicios a través de conciertos, consorcios o empresas públicas (buena parte de la sanidad en Cataluña, por ejemplo), ese personal no figura en el registro y la tasa sale más baja. Pulsa en una comunidad para ver sus provincias.</p>

## ¿Cómo ha evolucionado?

```sql serie_registro
SELECT fecha, administracion, sum(efectivos) AS efectivos
FROM mother.empleo_efectivos
GROUP BY ALL
ORDER BY fecha
```

<BarChart
    data={serie_registro}
    x=fecha
    y=efectivos
    series=administracion
    type=stacked
    yFmt=num0
    xFmt="mmm yyyy"
    colorPalette={['#0f766e', '#f59e0b', '#1d4ed8']}
    title="Registro Central de Personal: efectivos a 1 de enero y 1 de julio"
/>

<p class="text-xs text-gray-500">Ojo al salto entre julio de 2022 y enero de 2023 (~+240.000): el Ministerio revisó en agosto de 2026 todas las ediciones desde 2023 con nuevas fuentes y diccionarios (sobre todo en las comunidades autónomas), así que parte del aumento es metodológico, no contrataciones. Antes de julio de 2019 no se publican los datos en formato abierto.</p>

```sql serie_epa
SELECT trimestre, administracion, asalariados
FROM mother.empleo_epa_administracion
WHERE administracion NOT IN ('Total', 'Otras / no sabe')
ORDER BY trimestre
```

<BarChart
    data={serie_epa}
    x=trimestre
    y=asalariados
    series=administracion
    type=stacked
    yFmt=num0
    xFmt="yyyy"
    title="Asalariados del sector público según la EPA (desde 2002)"
/>

<p class="text-xs text-gray-500">La Encuesta de Población Activa da una serie más larga (trimestral desde 2002) y cuenta también a las empresas e instituciones públicas, pero es una encuesta: por eso da más empleados públicos que el registro (unos 3,6 millones) y su dato trimestral tiene margen de error. Se aprecian el recorte de 2011-2014 (de 3,28 a 2,93 millones de media anual, con la crisis de la deuda) y el crecimiento posterior, más rápido desde 2018.</p>

```sql cuota_ccaa
SELECT e.trimestre, c.nombre AS comunidad, e.cuota_publico
FROM mother.empleo_epa_ccaa e
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = e.cod_ccaa
WHERE e.trimestre = (SELECT max(trimestre) FROM mother.empleo_epa_ccaa)
ORDER BY e.cuota_publico DESC
```

<BarChart
    data={cuota_ccaa}
    x=comunidad
    y=cuota_publico
    swapXY=true
    sort=false
    yFmt=pct0
    fillColor="#1d4ed8"
    title="Peso del empleo público sobre el total de asalariados (EPA, último trimestre)"
/>

## ¿Cuánto cobran?

```sql deciles
SELECT
    decil,
    'D' || CAST(decil AS VARCHAR) AS decil_txt,
    sector,
    salario_mensual
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo'
  AND anio = (SELECT max(anio) FROM mother.empleo_salarios_deciles)
  AND decil > 0
  AND sector IN ('Público', 'Privado')
ORDER BY decil
```

```sql brecha
SELECT
    anio,
    max(salario_mensual) FILTER (WHERE sector = 'Público') AS publico,
    max(salario_mensual) FILTER (WHERE sector = 'Privado') AS privado
FROM mother.empleo_salarios_deciles
WHERE jornada = 'Jornada a tiempo completo' AND decil = 0
GROUP BY anio
ORDER BY anio
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
    yAxisTitle="€ brutos al mes"
    title="Salario medio bruto mensual, jornada completa"
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
    title="Salario medio de cada decil (del 10 % que menos cobra al 10 % que más)"
/>

<p class="text-xs text-gray-500">Dentro de cada decil (cada tramo del 10 % de asalariados ordenados por salario), el sector público y el privado cobran prácticamente lo mismo, y en el decil más alto el privado cobra más. La diferencia media viene de la composición: hay proporcionalmente muchos más empleados públicos en los tramos altos (médicos, profesores, titulados superiores, más antigüedad) y casi ninguno en los empleos peor pagados del sector privado (hostelería, comercio, agricultura). Salario bruto mensual del empleo principal a jornada completa, antes de impuestos y de las cotizaciones del trabajador.</p>

```sql salarios_ccaa
SELECT c.nombre AS comunidad, s.salario_publico, s.salario_privado, s.salario_publico / s.salario_privado - 1 AS diferencia
FROM mother.empleo_salarios_ccaa s
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = s.cod_ccaa
ORDER BY s.salario_publico DESC
```

<DataTable data={salarios_ccaa} rows=all>
    <Column id=comunidad title="Comunidad" />
    <Column id=salario_publico title="Público (€/año)" fmt=num0 />
    <Column id=salario_privado title="Privado (€/año)" fmt=num0 />
    <Column id=diferencia title="Diferencia" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Salario medio anual bruto en 2022 según la Encuesta Cuatrienal de Estructura Salarial del INE, por comunidad del centro de trabajo y según quién controla la empresa u organismo. Solo cubre a quienes cotizan al Régimen General: deja fuera a los funcionarios de mutualidades (MUFACE, ISFAS, MUGEJU).</p>

## ¿Cuánto cuestan?

```sql coste
SELECT anio, subsector, millones_eur / 1000 AS miles_millones, pct_pib
FROM mother.empleo_coste
WHERE cod_sector <> 'S13'
ORDER BY anio
```

```sql coste_total
SELECT anio, pct_pib FROM mother.empleo_coste WHERE cod_sector = 'S13' ORDER BY anio
```

<BarChart
    data={coste}
    x=anio
    y=miles_millones
    series=subsector
    type=stacked
    yFmt=num1
    xFmt="####"
    yAxisTitle="miles de millones de €"
    title="Remuneración de los empleados públicos por administración"
/>

<LineChart
    data={coste_total}
    x=anio
    y=pct_pib
    yFmt=num1
    xFmt="####"
    colorPalette={['#1d4ed8']}
    yAxisTitle="% del PIB"
    title="Coste del personal público sobre el PIB"
/>

<p class="text-xs text-gray-500">Remuneración de asalariados de las administraciones públicas (contabilidad nacional, Eurostat): sueldos y salarios más las cotizaciones sociales que paga la administración como empleador. Las transferencias entre administraciones no cuentan dos veces: cada una paga a su personal.</p>

```sql coste_ccaa
SELECT
    c.nombre AS comunidad,
    c.ruta,
    g.anio,
    g.gasto_personal_ccaa / 1e6 AS gasto_ccaa_millones,
    g.gasto_personal_ccaa_hab,
    g.gasto_personal_ayuntamientos_hab
FROM mother.empleo_gasto_personal_territorio g
JOIN mother.territorios c ON c.nivel = 'ccaa' AND c.cod = g.cod
WHERE g.nivel = 'ccaa'
  AND g.anio = (SELECT max(anio) FROM mother.empleo_gasto_personal_territorio WHERE nivel = 'ccaa' AND gasto_personal_ccaa IS NOT NULL AND gasto_personal_ayuntamientos IS NOT NULL)
ORDER BY g.gasto_personal_ccaa_hab DESC
```

### Gasto de personal de cada comunidad y de sus ayuntamientos ({coste_ccaa[0]?.anio})

<DataTable data={coste_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunidad" />
    <Column id=gasto_ccaa_millones title="Comunidad (M€)" fmt=num0 />
    <Column id=gasto_personal_ccaa_hab title="Comunidad (€/hab.)" fmt=num0 contentType=bar barColor="#bfdbfe" />
    <Column id=gasto_personal_ayuntamientos_hab title="Ayuntamientos (€/hab.)" fmt=num0 contentType=bar barColor="#fde68a" />
</DataTable>

<p class="text-xs text-gray-500">Capítulo 1 («gastos de personal») de las liquidaciones: el de la comunidad, de Hacienda; el de los ayuntamientos, suma de los que enviaron su liquidación a Hacienda (CONPREL), por habitante de esos municipios. País Vasco y Navarra cobran sus propios impuestos (régimen foral) y asumen más competencias, lo que eleva su gasto; en Álava y Navarra los ayuntamientos no aparecen en CONPREL. El gasto de personal de cada ayuntamiento está en su ficha de <a href="/territorios/municipios">municipios</a>.</p>

---

## Fuentes y notas

- **[Boletín Estadístico del Personal al Servicio de las Administraciones Públicas (Registro Central de Personal)](https://digital.gob.es/funcion-publica/dgfp/registro-central-personal/boletin.html)**, Ministerio para la Transformación Digital y de la Función Pública: efectivos a 1 de enero y 1 de julio desde 2019. No incluye empresas públicas ni fundaciones, ni llega al detalle de cada ayuntamiento (solo por tipo de entidad y provincia). El personal de las entidades locales procede de la afiliación a la Seguridad Social.
- **[INE – Encuesta de Población Activa](https://www.ine.es/jaxiT3/Tabla.htm?t=65193)**: asalariados públicos por administración (tabla 65193) y por comunidad (65327); salarios por decil (66250).
- **[INE – Encuesta de Estructura Salarial 2022](https://www.ine.es/jaxiT3/Tabla.htm?t=36887)**: salario anual por comunidad y control público o privado.
- **[Eurostat – gov_10a_main](https://ec.europa.eu/eurostat/databrowser/view/gov_10a_main/default/table)**: remuneración de asalariados (D1) de las administraciones públicas por subsector.
- **Ministerio de Hacienda**: liquidaciones de las comunidades autónomas y de las entidades locales (CONPREL), capítulo 1.
- Los tres recuentos miden cosas distintas: el registro cuenta personas con puesto en una administración; la EPA estima asalariados que dicen trabajar en el sector público (incluidas las empresas públicas); la contabilidad nacional mide el coste.

<LastRefreshed prefix="Datos actualizados" />
