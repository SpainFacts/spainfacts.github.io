---
title: Natalitat i fecunditat
description: "Naixements i defuncions per 1.000 habitants, fills per dona, edat mitjana de les mares i naixements de mare estrangera a Espanya, per comunitat i província des de 1975 (INE)."
i18n_origen: a59927850e3c
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql anual
SELECT CAST(anio AS INTEGER) AS anio, nacimientos, defunciones, crecimiento_vegetativo,
    tasa_natalidad, tasa_mortalidad, vegetativo_1000, fecundidad, fecundidad_espanolas,
    fecundidad_extranjeras, edad_maternidad, edad_primer_hijo, pct_madre_extranjera
FROM mother.demografia_anual
WHERE nivel = 'pais'
ORDER BY anio
```

```sql ultimo
SELECT a.*, p.anio AS anio_pico, p.nacimientos AS nacimientos_pico, p.tasa_natalidad AS tasa_pico,
    f.anio AS anio_icf_max, f.fecundidad AS icf_max
FROM ${anual} a
CROSS JOIN (SELECT anio, nacimientos, tasa_natalidad FROM ${anual} WHERE anio >= 2000 ORDER BY nacimientos DESC LIMIT 1) p
CROSS JOIN (SELECT anio, fecundidad FROM ${anual} WHERE anio >= 1990 ORDER BY fecundidad DESC LIMIT 1) f
ORDER BY a.anio DESC
LIMIT 1
```

```sql primero
SELECT * FROM ${anual} ORDER BY anio LIMIT 1
```

```sql vegetativo_negativo
SELECT min(anio) AS desde, count(*) AS anios
FROM ${anual}
WHERE anio > (SELECT max(anio) FROM ${anual} WHERE vegetativo_1000 >= 0)
```

# 👶 Natalitat i fecunditat

Quants infants neixen a Espanya en relació amb la seva població, quants fills té de mitjana cada dona, a quina edat i quants neixen de mare estrangera, juntament amb les defuncions que marquen el creixement natural de la població.

<Grid cols=4>
    <KpiCard
        title="Taxa de natalitat"
        value={ultimo[0]?.tasa_natalidad}
        formattedValue="{formatNumber(ultimo[0]?.tasa_natalidad, 2)} per 1.000 hab."
        period="{formatNumber(ultimo[0]?.nacimientos, 0)} naixements el {ultimo[0]?.anio} · {formatNumber(primero[0]?.tasa_natalidad, 1)} el {primero[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.tasa_natalidad}))}
    />
    <KpiCard
        title="Fills per dona"
        value={ultimo[0]?.fecundidad}
        formattedValue={formatNumber(ultimo[0]?.fecundidad, 2)}
        period="{ultimo[0]?.anio} · {formatNumber(ultimo[0]?.fecundidad_espanolas, 2)} les espanyoles i {formatNumber(ultimo[0]?.fecundidad_extranjeras, 2)} les estrangeres"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.fecundidad}))}
    />
    <KpiCard
        title="Edat mitjana de les mares"
        value={ultimo[0]?.edad_maternidad}
        formattedValue="{formatNumber(ultimo[0]?.edad_maternidad, 1)} anys"
        period="{formatNumber(ultimo[0]?.edad_primer_hijo, 1)} en tenir el primer fill, {ultimo[0]?.anio}"
        source="INE"
        sparklineData={anual.map(d => ({anio: d.anio, valor: d.edad_maternidad}))}
    />
    <KpiCard
        title="Naixements de mare estrangera"
        value={ultimo[0]?.pct_madre_extranjera}
        formattedValue="{formatNumber(ultimo[0]?.pct_madre_extranjera, 1)} %"
        period="dels nascuts el {ultimo[0]?.anio}"
        source="INE"
        sparklineData={anual.filter(d => d.pct_madre_extranjera !== null).map(d => ({anio: d.anio, valor: d.pct_madre_extranjera}))}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('fecundidad')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'fecundidad')} />


<p class="text-xs text-gray-500">Les taxes es calculen sobre la població mitjana de l'any. L'indicador conjuntural de fecunditat és el nombre mitjà de fills que tindria una dona al llarg de la seva vida si es mantinguessin les taxes de fecunditat per edat d'aquell any; perquè una població es mantingui sense migració en calen uns 2,1.</p>

## Naixements i defuncions

Des del {primero[0]?.anio} la taxa de natalitat ha passat de {formatNumber(primero[0]?.tasa_natalidad, 1)} a {formatNumber(ultimo[0]?.tasa_natalidad, 1)} naixements per 1.000 habitants. Moren més persones de les que neixen cada any des del {vegetativo_negativo[0]?.desde}.

```sql tasas
SELECT anio, 'Nacimientos' AS fenomeno, tasa_natalidad AS por_1000 FROM ${anual}
UNION ALL
SELECT anio, 'Defunciones', tasa_mortalidad FROM ${anual}
ORDER BY anio
```

<Grid cols=2>
    <LineChart
        data={tasas}
        x=anio
        y=por_1000
        series=fenomeno
        yFmt=num1
        xFmt="####"
        colorPalette={['#db2777', '#475569']}
        yAxisTitle="per 1.000 habitants"
        title="Naixements i defuncions per 1.000 habitants"
    />
    <BarChart
        data={anual}
        x=anio
        y=vegetativo_1000
        yFmt=num1
        xFmt="####"
        fillColor="#be185d"
        yAxisTitle="per 1.000 habitants"
        title="Creixement vegetatiu (naixements menys defuncions) per 1.000 hab."
    />
</Grid>

<p class="text-xs text-gray-500">El pic de defuncions del 2020 correspon a la pandèmia de COVID-19. En nombres absoluts, el {ultimo[0]?.anio} hi va haver {formatNumber(ultimo[0]?.nacimientos, 0)} naixements i {formatNumber(ultimo[0]?.defunciones, 0)} defuncions de residents a Espanya; el màxim de naixements d'aquest segle va ser el {ultimo[0]?.anio_pico}, amb {formatNumber(ultimo[0]?.nacimientos_pico, 0)}.</p>

## Fills per dona

```sql fecundidad_nac
SELECT anio, 'Total' AS madre, fecundidad AS hijos FROM ${anual}
UNION ALL
SELECT anio, 'Madres españolas', fecundidad_espanolas FROM ${anual} WHERE fecundidad_espanolas IS NOT NULL
UNION ALL
SELECT anio, 'Madres extranjeras', fecundidad_extranjeras FROM ${anual} WHERE fecundidad_extranjeras IS NOT NULL
ORDER BY anio
```

```sql edad_madres
SELECT anio, 'Todos los hijos' AS hijo, edad_maternidad AS edad FROM ${anual}
UNION ALL
SELECT anio, 'Primer hijo', edad_primer_hijo FROM ${anual}
ORDER BY anio
```

<Grid cols=2>
    <LineChart
        data={fecundidad_nac}
        x=anio
        y=hijos
        series=madre
        yFmt=num2
        xFmt="####"
        colorPalette={['#1e293b', '#db2777', '#0f766e']}
        yAxisTitle="fills per dona"
        title="Indicador conjuntural de fecunditat segons la nacionalitat de la mare"
    >
        <ReferenceLine y=2.1 label="Reemplaçament (2,1)" color="#94a3b8" />
    </LineChart>
    <LineChart
        data={edad_madres}
        x=anio
        y=edad
        series=hijo
        yFmt=num1
        xFmt="####"
        colorPalette={['#7c3aed', '#c4b5fd']}
        yAxisTitle="anys"
        yMin=24
        title="Edat mitjana a la maternitat"
    />
</Grid>

<p class="text-xs text-gray-500">La fecunditat per nacionalitat comença el 2002. El {ultimo[0]?.anio} cada dona tenia de mitjana {formatNumber(ultimo[0]?.fecundidad, 2)} fills, davant de {formatNumber(primero[0]?.fecundidad, 2)} el {primero[0]?.anio}; el valor més alt des del 1990 va ser {formatNumber(ultimo[0]?.icf_max, 2)} el {ultimo[0]?.anio_icf_max}. L'edat mitjana en el primer fill ha passat de {formatNumber(primero[0]?.edad_primer_hijo, 1)} a {formatNumber(ultimo[0]?.edad_primer_hijo, 1)} anys.</p>

```sql madre_extranjera
SELECT anio, pct_madre_extranjera / 100 AS cuota FROM ${anual} WHERE pct_madre_extranjera IS NOT NULL
```

<LineChart
    data={madre_extranjera}
    x=anio
    y=cuota
    yFmt=pct0
    xFmt="####"
    lineColor="#0f766e"
    title="Naixements de mare estrangera, en % del total"
/>

<p class="text-xs text-gray-500">Segons la nacionalitat de la mare en el moment del part; una mare nascuda fora que ja té la nacionalitat espanyola compta com a espanyola.</p>

## Per comunitat autònoma

```sql ccaa
SELECT a.cod, t.nombre AS comunidad, '/ca' || t.ruta AS ruta,
    a.tasa_natalidad, a.tasa_mortalidad, a.vegetativo_1000, a.fecundidad,
    a.edad_maternidad, a.pct_madre_extranjera / 100 AS madre_extranjera, a.nacimientos
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = a.cod
WHERE a.nivel = 'ccaa' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE tasa_natalidad IS NOT NULL)
ORDER BY a.fecundidad DESC
```

<Grid cols=2>
    <AreaMap
        data={ccaa}
        geoJsonUrl="/geo/ccaa.geojson"
        geoId="cod_ccaa"
        areaCol="cod"
        value="fecundidad"
        valueFmt="num2"
        link="ruta"
        colorPalette={['#fdf2f8', '#f472b6', '#9d174d']}
        height={400}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
        title="Fills per dona, {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'fecundidad', title: 'Fills per dona', fmt: 'num2'},
            {id: 'tasa_natalidad', title: 'Naixements per 1.000 hab.', fmt: 'num1'},
            {id: 'edad_maternidad', title: 'Edat mitjana de la mare', fmt: 'num1'}
        ]}
    />
    <AreaMap
        data={ccaa}
        geoJsonUrl="/geo/ccaa.geojson"
        geoId="cod_ccaa"
        areaCol="cod"
        value="vegetativo_1000"
        valueFmt="num1"
        link="ruta"
        colorPalette={['#b91c1c', '#f8fafc', '#15803d']}
        height={400}
        basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
        attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
        title="Naixements menys defuncions per 1.000 hab., {ultimo[0]?.anio}"
        tooltip={[
            {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
            {id: 'vegetativo_1000', title: 'Creixement vegetatiu per 1.000 hab.', fmt: 'num1'},
            {id: 'tasa_natalidad', title: 'Naixements per 1.000 hab.', fmt: 'num1'},
            {id: 'tasa_mortalidad', title: 'Defuncions per 1.000 hab.', fmt: 'num1'}
        ]}
    />
</Grid>

<DataTable data={ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Comunitat" />
    <Column id=fecundidad title="Fills per dona" fmt=num2 contentType=bar barColor="#fbcfe8" />
    <Column id=tasa_natalidad title="Naixements per 1.000 hab." fmt=num1 />
    <Column id=tasa_mortalidad title="Defuncions per 1.000 hab." fmt=num1 />
    <Column id=vegetativo_1000 title="Vegetatiu per 1.000 hab." fmt=num1 contentType=delta />
    <Column id=edad_maternidad title="Edat mitjana mare" fmt=num1 />
    <Column id=madre_extranjera title="Mare estrangera" fmt=pct1 />
    <Column id=nacimientos title="Naixements" fmt=num0 />
</DataTable>

## Per província

```sql provincias
SELECT a.cod AS cod_prov, t.nombre AS provincia, '/ca' || t.ruta AS ruta,
    a.tasa_natalidad, a.tasa_mortalidad, a.vegetativo_1000, a.fecundidad, a.edad_maternidad, a.nacimientos
FROM mother.demografia_anual a
JOIN mother.territorios t ON t.nivel = 'provincia' AND t.cod = a.cod
WHERE a.nivel = 'provincia' AND a.anio = (SELECT max(anio) FROM mother.demografia_anual WHERE tasa_natalidad IS NOT NULL)
ORDER BY a.tasa_natalidad DESC
```

```sql provincias_resumen
SELECT count(*) FILTER (WHERE vegetativo_1000 < 0) AS negativas, count(*) AS total,
    arg_max(provincia, tasa_natalidad) AS max_prov, max(tasa_natalidad) AS max_tasa,
    arg_min(provincia, tasa_natalidad) AS min_prov, min(tasa_natalidad) AS min_tasa
FROM ${provincias}
```

El {ultimo[0]?.anio}, {provincias_resumen[0]?.negativas} de les {provincias_resumen[0]?.total} províncies van tenir més defuncions que naixements. La natalitat va de {formatNumber(provincias_resumen[0]?.max_tasa, 1)} naixements per 1.000 habitants a {provincias_resumen[0]?.max_prov} a {formatNumber(provincias_resumen[0]?.min_tasa, 1)} a {provincias_resumen[0]?.min_prov}.

<AreaMap
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="tasa_natalidad"
    valueFmt="num1"
    link="ruta"
    colorPalette={['#fdf2f8', '#f472b6', '#9d174d']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Tiles © Esri · Límits © Instituto Geográfico Nacional · Dades: INE"
    title="Naixements per 1.000 habitants a cada província, {ultimo[0]?.anio}"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'tasa_natalidad', title: 'Naixements per 1.000 hab.', fmt: 'num1'},
        {id: 'tasa_mortalidad', title: 'Defuncions per 1.000 hab.', fmt: 'num1'},
        {id: 'fecundidad', title: 'Fills per dona', fmt: 'num2'},
        {id: 'nacimientos', title: 'Naixements', fmt: 'num0'}
    ]}
/>

---

## Fonts i notes

- **[INE – Indicadors Demogràfics Bàsics](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254735573002)**: taxa bruta de natalitat (taules [1470](https://www.ine.es/jaxiT3/Tabla.htm?t=1470) i [1432](https://www.ine.es/jaxiT3/Tabla.htm?t=1432)) i de mortalitat ([1482](https://www.ine.es/jaxiT3/Tabla.htm?t=1482) i [1445](https://www.ine.es/jaxiT3/Tabla.htm?t=1445)), indicador conjuntural de fecunditat ([1478](https://www.ine.es/jaxiT3/Tabla.htm?t=1478) i [1441](https://www.ine.es/jaxiT3/Tabla.htm?t=1441)), edat mitjana a la maternitat ([1581](https://www.ine.es/jaxiT3/Tabla.htm?t=1581) i [1580](https://www.ine.es/jaxiT3/Tabla.htm?t=1580)) i nascuts segons la nacionalitat de la mare ([2777](https://www.ine.es/jaxiT3/Tabla.htm?t=2777)).
- **[INE – Moviment Natural de la Població](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177007)**: naixements per residència de la mare ([6524](https://www.ine.es/jaxiT3/Tabla.htm?t=6524)) i defuncions per residència ([6561](https://www.ine.es/jaxiT3/Tabla.htm?t=6561)). Dades definitives; l'últim any publicat és el {ultimo[0]?.anio}.
- Creixement vegetatiu per 1.000 hab. = taxa de natalitat menys taxa de mortalitat.

<LastRefreshed prefix="Dades actualitzades" />
