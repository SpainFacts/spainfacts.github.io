---
i18n_origen: e8ce24d9ad4d
title: Sectores económicos
description: "Canto produce e canta xente emprega cada sector da economía española, o seu crecemento real e a súa produtividade, desde 1995."
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

# 🏭 Sectores económicos

Que produce a economía española e quen o produce. O valor engadido de cada sector mídese en euros constantes de {ultimo[0]?.anio_euros}, e o emprego en ocupados por cada 1.000 habitantes, para que non medre só porque haxa máis poboación.

<Grid cols=4>
    <KpiCard
        title="Crecemento real da economía"
        value={total.slice(-1)[0]?.crecimiento_real}
        formattedValue="{formatNumber(total.slice(-1)[0]?.crecimiento_real, 1)} %"
        period="valor engadido total en {total.slice(-1)[0]?.anio}"
        source="Eurostat"
        sparklineData={total.filter(d => d.crecimiento_real != null).map(d => ({...d, y: d.crecimiento_real}))}
    />
    <KpiCard
        title="Ocupados por 1.000 habitantes"
        value={total.slice(-1)[0]?.ocupados_1000_hab}
        formattedValue={formatNumber(total.slice(-1)[0]?.ocupados_1000_hab, 0)}
        period="{formatNumber(total.slice(-1)[0]?.ocupados_miles / 1000, 1)} millóns de ocupados en {total.slice(-1)[0]?.anio}"
        source="Eurostat"
        sparklineData={total.map(d => ({...d, y: d.ocupados_1000_hab}))}
    />
    <KpiCard
        title="Produtividade por ocupado"
        value={total.slice(-1)[0]?.productividad_real}
        formattedValue="{formatNumber(total.slice(-1)[0]?.productividad_real, 0)} €"
        period="valor engadido por ocupado en {total.slice(-1)[0]?.anio}, euros de {ultimo[0]?.anio_euros}"
        source="Eurostat"
        sparklineData={total.map(d => ({...d, y: d.productividad_real}))}
    />
    <KpiCard
        title="Sector que máis medra desde 2019"
        value={ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.crec_desde_2019}
        formattedValue="+{formatNumber(ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.crec_desde_2019, 1)} %"
        period="{ultimo.filter(d => d.rama !== 'TOTAL' && !d.es_subrama).sort((a, b) => b.crec_desde_2019 - a.crec_desde_2019)[0]?.sector}, valor engadido real"
        source="Eurostat"
    />
</Grid>

## Radiografía de {ultimo[0]?.anio}

Peso de cada sector no que se produce e no emprego. Onde o peso en produción supera o do emprego, cada traballador xera máis valor (nas inmobiliarias sobre todo polos alugueres, incluídos os imputados a quen vive na súa propia casa).

<DataTable data={ultimo} rows=20>
    <Column id=sector title="Sector"/>
    <Column id=peso_vab title="% da produción" fmt='0.0'/>
    <Column id=peso_empleo title="% do emprego" fmt='0.0'/>
    <Column id=crecimiento_real title="Crecemento real (%)" fmt='0.0' contentType=delta/>
    <Column id=crec_desde_2019 title="Desde 2019 (%)" fmt='0.0' contentType=delta/>
    <Column id=ocupados_1000_hab title="Ocupados por 1.000 hab." fmt='0.0'/>
    <Column id=productividad_real title="Valor engadido por ocupado (€)" fmt='#,##0'/>
</DataTable>

Manufacturas é unha parte de Industria e enerxía; por iso non se suma á parte nas gráficas.

## Crecemento real por sector

Valor engadido de cada gran sector en euros constantes, con 2008 = 100. A construción aínda non recuperou o nivel previo ao estoupido da burbulla inmobiliaria.

<LineChart
    data={indice_vab}
    x=anio
    y=indice
    series=sector
    xFmt='0'
    yAxisTitle="2008 = 100"
    startingAtZero={false}
    title="Valor engadido real por sector (2008 = 100)"
/>

## Emprego por sector

Ocupados de cada sector por cada 1.000 habitantes; apilados, dan o total de ocupados por 1.000 habitantes. En {total.slice(-1)[0]?.anio} foron {formatNumber(total.slice(-1)[0]?.ocupados_1000_hab, 0)}, fronte a {formatNumber(total.find(d => d.anio === 2007)?.ocupados_1000_hab, 0)} en 2007.

<AreaChart
    data={sin_total}
    x=anio
    y=ocupados_1000_hab
    series=sector
    xFmt='0'
    yAxisTitle="Ocupados por 1.000 hab."
    title="Ocupados por 1.000 habitantes e sector"
/>

<LineChart
    data={sin_total}
    x=anio
    y=peso_empleo
    series=sector
    xFmt='0'
    yAxisTitle="% do emprego"
    yFmt='0.0"%"'
    title="Peso de cada sector no emprego (%)"
/>

## Produtividade

Valor engadido real por ocupado en toda a economía, en euros de {ultimo[0]?.anio_euros}.

<LineChart
    data={total}
    x=anio
    y=productividad_real
    xFmt='0'
    yFmt='#,##0" €"'
    yAxisTitle="€ por ocupado"
    startingAtZero={false}
    title="Produtividade aparente do traballo (euros de {ultimo[0]?.anio_euros})"
/>

---

**Fontes:** [Eurostat, nama_10_a10](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10/default/table) (valor engadido bruto por rama) e [nama_10_a10_e](https://ec.europa.eu/eurostat/databrowser/view/nama_10_a10_e/default/table) (ocupados por rama, concepto interior). Dez grandes ramas da clasificación NACE; poboación media anual de Eurostat.
