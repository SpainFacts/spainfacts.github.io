---
title: Sectors econòmics
description: "Quant produeix i quanta gent ocupa cada sector de l'economia espanyola, el seu creixement real i la seva productivitat, des del 1995."
i18n_origen: e8ce24d9ad4d
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql sectores
SELECT *
FROM mother.economia_sectores
ORDER BY anio, sector
```

```sql ultimo
SELECT
    s.sector,
    s.rama,
    s.es_subrama,
    s.peso_vab,
    s.crecimiento_real,
    s.ocupados_miles,
    s.ocupados_1000_hab,
    s.peso_empleo,
    s.productividad_real,
    100 * (s.vab_real_meur / b.vab_real_meur - 1) AS crec_desde_2019,
    s.anio,
    s.anio_euros
FROM mother.economia_sectores s
LEFT JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2019
WHERE s.anio = (SELECT max(anio) FROM mother.economia_sectores)
ORDER BY s.rama = 'TOTAL', s.peso_vab DESC
```

```sql total
SELECT anio, crecimiento_real, ocupados_1000_hab, productividad_real, ocupados_miles
FROM mother.economia_sectores
WHERE rama = 'TOTAL'
ORDER BY anio
```

```sql sin_total
SELECT *
FROM mother.economia_sectores
WHERE rama <> 'TOTAL' AND NOT es_subrama
ORDER BY anio, sector
```

```sql indice_vab
SELECT
    s.anio,
    s.sector,
    100 * s.vab_real_meur / b.vab_real_meur AS indice
FROM mother.economia_sectores s
JOIN mother.economia_sectores b ON b.rama = s.rama AND b.anio = 2008
WHERE s.rama IN ('B-E', 'F', 'G-I', 'J', 'M_N', 'O-Q', 'TOTAL')
ORDER BY s.anio, s.sector
```

# 🏭 Sectors econòmics

Què produeix l'economia espanyola i qui ho produeix. El valor afegit de cada sector es mesura en euros constants del {ultimo[0]?.anio_euros}, i l'ocupació en ocupats per cada 1.000 habitants, perquè no creixi només perquè hi hagi més població.

<Grid cols=4>
    <KpiCard
        title="Creixement real de l'economia"
        value={total.slice(-1)[0]?.crecimiento_real}
        formattedValue="{formatNumber(total.slice(-1)[0]?.crecimiento_real, 1)} %"
        period="valor afegit total el {total.slice(-1)[0]?.anio}"
        source="Eurostat"
        sparklineData={total.filter(d => d.crecimiento_real != null).map(d => ({...d, y: d.crecimiento_real}))}
    />
    <KpiCard
        title="Ocupats per 1.000 habitants"
        value={total.slice(-1)[0]?.ocupados_1000_hab}
        formattedValue={formatNumber(total.slice(-1)[0]?.ocupados_1000_hab, 0)}
        period="{formatNumber(total.slice(-1)[0]?.ocupados_miles / 1000, 1)} milions d'ocupats el {total.slice(-1)[0]?.anio}"
        source="Eurostat"
        sparklineData={total.map(d => ({...d, y: d.ocupados_1000_hab}))}
    />
    <KpiCard
        title="Productivitat per ocupat"
        value={total.slice(-1)[0]?.productividad_real}
        formattedValue="{formatNumber(total.slice(-1)[0]?.productividad_real, 0)} €"
        period="valor afegit per ocupat el {total.slice(-1)[0]?.anio}, euros del {ultimo[0]?.anio_euros}"
        source="Eurostat"
        sparklineData={total.map(d => ({...d, y: d.productividad_real}))}
    />
    <KpiCard
        title="Sector que més creix des del 2019"
        value={ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.crec_desde_2019}
        formattedValue="+{formatNumber(ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.crec_desde_2019, 1)} %"
        period="{ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.sector}, valor afegit real"
        source="Eurostat"
    />
</Grid>

## Radiografia del {ultimo[0]?.anio}

Pes de cada sector en el que es produeix i en l'ocupació. On el pes en la producció supera el de l'ocupació, cada treballador genera més valor (a les immobiliàries sobretot pels lloguers, inclosos els imputats a qui viu a casa seva).

<DataTable data={ultimo} rows=20>
    <Column id=sector title="Sector"/>
    <Column id=peso_vab title="% de la producció" fmt='0.0'/>
    <Column id=peso_empleo title="% de l'ocupació" fmt='0.0'/>
    <Column id=crecimiento_real title="Creixement real (%)" fmt='0.0' contentType=delta/>
    <Column id=crec_desde_2019 title="Des del 2019 (%)" fmt='0.0' contentType=delta/>
    <Column id=ocupados_1000_hab title="Ocupats per 1.000 hab." fmt='0.0'/>
    <Column id=productividad_real title="Valor afegit per ocupat (€)" fmt='#,##0'/>
</DataTable>

Manufactures és una part d'Indústria i energia; per això no se suma a part a les gràfiques.

## Creixement real per sector

Valor afegit de cada gran sector en euros constants, amb 2008 = 100. La construcció encara no ha recuperat el nivell previ a l'esclat de la bombolla immobiliària.

<LineChart
    data={indice_vab}
    x=anio
    y=indice
    series=sector
    xFmt='0'
    yAxisTitle="2008 = 100"
    startingAtZero={false}
    title="Valor afegit real per sector (2008 = 100)"
/>

## Ocupació per sector

Ocupats de cada sector per cada 1.000 habitants; apilats, donen el total d'ocupats per 1.000 habitants. El {total.slice(-1)[0]?.anio} van ser {formatNumber(total.slice(-1)[0]?.ocupados_1000_hab, 0)}, davant de {formatNumber(total.find(d => d.anio === 2007)?.ocupados_1000_hab, 0)} el 2007.

<AreaChart
    data={sin_total}
    x=anio
    y=ocupados_1000_hab
    series=sector
    xFmt='0'
    yAxisTitle="Ocupats per 1.000 hab."
    title="Ocupats per 1.000 habitants i sector"
/>

<LineChart
    data={sin_total}
    x=anio
    y=peso_empleo
    series=sector
    xFmt='0'
    yAxisTitle="% de l'ocupació"
    yFmt='0.0"%"'
    title="Pes de cada sector en l'ocupació (%)"
/>

## Productivitat

Valor afegit real per ocupat en tota l'economia, en euros del {ultimo[0]?.anio_euros}.

<LineChart
    data={total}
    x=anio
    y=productividad_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ per ocupat"
    startingAtZero={false}
    title="Productivitat aparent del treball (euros del {ultimo[0]?.anio_euros})"
/>

---

**Fonts:** [Eurostat, nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (valor afegit brut per branca) i [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (ocupats per branca, concepte interior). Deu grans branques de la classificació NACE; població mitjana anual d'Eurostat.
