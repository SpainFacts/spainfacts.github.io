---
title: Garraio publikoa
description: "Metro, autobus, Cercanías (aldiriko trenak), AVE, distantzia ertaineko eta luzeko tren, hegazkin eta itsasontziko bidaiariak Espainian hilero 2012tik, eta metroa eta hiri-autobusa Madrilen, Bartzelonan, Valentzian, Bilbon, Sevillan, Malagan eta Palman."
i18n_origen: 19974c536a0b
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql modos
SELECT * FROM mother.movilidad_transporte_modos WHERE clave IS NOT NULL
```

```sql ultimo
WITH u AS (SELECT max(mes) AS mes FROM ${modos})
SELECT
    strftime(u.mes, '%m/%Y') AS mes_texto,
    (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total'
      ORDER BY anio DESC LIMIT 1) AS poblacion,
    sum(m.viajeros) FILTER (WHERE m.clave = 'total') AS total,
    sum(m.viajeros) FILTER (WHERE m.clave = 'metro') AS metro,
    sum(m.viajeros) FILTER (WHERE m.clave = 'alta_velocidad') AS ave,
    sum(m.viajeros) FILTER (WHERE m.clave = 'cercanias') AS cercanias
FROM ${modos} m, u
WHERE m.mes = u.mes
GROUP BY u.mes
```

```sql anual
-- Años completos
SELECT CAST(year(mes) AS INTEGER) AS anio, clave, modo, sum(viajeros) AS viajeros, count(*) AS meses
FROM ${modos}
GROUP BY ALL
HAVING count(*) = 12
```

```sql ultimo_anual
SELECT
    a.anio,
    sum(a.viajeros) FILTER (WHERE a.clave = 'total') AS total,
    sum(a.viajeros) FILTER (WHERE a.clave = 'alta_velocidad') AS ave,
    sum(p.viajeros) FILTER (WHERE p.clave = 'alta_velocidad') AS ave_2019,
    sum(p.viajeros) FILTER (WHERE p.clave = 'total') AS total_2019
FROM ${anual} a
LEFT JOIN ${anual} p ON p.clave = a.clave AND p.anio = 2019
WHERE a.anio = (SELECT max(anio) FROM ${anual})
GROUP BY a.anio
```

```sql poblacion
SELECT CAST(anio AS INTEGER) AS anio, poblacion
FROM mother.poblacion_territorios
WHERE nivel = 'pais' AND sexo = 'Total'
```

```sql serie_por_mil
-- Viajeros por cada 1.000 habitantes, últimos 36 meses
SELECT m.mes, m.clave, m.viajeros_por_1000_hab AS valor
FROM ${modos} AS m
WHERE m.clave IN ('total', 'metro')
  AND m.mes >= (SELECT max(mes) FROM ${modos}) - INTERVAL 35 MONTH
ORDER BY m.mes
```

```sql ave_por_mil
-- Viajeros de alta velocidad por cada 1.000 habitantes, años completos
SELECT a.anio, 1000 * a.viajeros / p.poblacion AS valor
FROM ${anual} AS a
JOIN ${poblacion} AS p ON p.anio = least(a.anio, (SELECT max(anio) FROM ${poblacion}))
WHERE a.clave = 'alta_velocidad'
ORDER BY a.anio
```

# 🚇 Garraio publikoa

Zenbat bidaiari mugitzen dituzten hilero metroak, autobusak, trenak eta hegazkinak Espainian, INEren Bidaiarien Garraioaren Estatistikaren arabera.

<Grid cols=3>
    <KpiCard
        title="Bidaiak garraio publikoan"
        value={ultimo[0]?.total / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.total / ultimo[0]?.poblacion, 1)} biztanleko"
        period="hilean · {formatCompact(ultimo[0]?.total, 1)} bidaiari guztira · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'total')}
    />
    <KpiCard
        title="Bidaiak metroan"
        value={ultimo[0]?.metro / ultimo[0]?.poblacion}
        formattedValue="{formatNumber(ultimo[0]?.metro / ultimo[0]?.poblacion, 1)} biztanleko"
        period="hilean (Espainiako batez bestekoa) · {formatCompact(ultimo[0]?.metro, 1)} guztira · {ultimo[0]?.mes_texto}"
        source="INE"
        sparklineData={serie_por_mil.filter(d => d.clave === 'metro')}
    />
    <KpiCard
        title="Bidaiak abiadura handian"
        value={ave_por_mil.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(ave_por_mil.slice(-1)[0]?.valor, 0)} 1.000 biztanleko"
        period={ultimo_anual[0]?.ave_2019
            ? `urtean · ${formatCompact(ultimo_anual[0].ave, 1)} bidaiari (${ultimo_anual[0].anio}) · ${ultimo_anual[0].ave > ultimo_anual[0].ave_2019 ? '+' : ''}${formatNumber(100 * (ultimo_anual[0].ave / ultimo_anual[0].ave_2019 - 1), 0)} % 2019arekin alderatuta`
            : `urtean · ${formatCompact(ultimo_anual[0]?.ave, 1)} bidaiari (${ultimo_anual[0]?.anio})`}
        source="INE"
        sparklineData={ave_por_mil}
    />
</Grid>

## Bidaiariak garraiobidearen arabera

<ButtonGroup name=grupo_modo title="Garraiobidea">
    <ButtonGroupItem valueLabel="Hirikoa" value="urbano" default />
    <ButtonGroupItem valueLabel="Trena" value="tren" />
    <ButtonGroupItem valueLabel="Hiriarteko autobusa, hegazkina eta itsasontzia" value="otros" />
</ButtonGroup>

```sql serie_modo
SELECT m.mes, m.modo, m.viajeros, m.viajeros_por_1000_hab AS por_1000
FROM ${modos} m
WHERE ('${inputs.grupo_modo}' = 'urbano' AND clave IN ('metro', 'autobus_urbano'))
   OR ('${inputs.grupo_modo}' = 'tren' AND clave IN ('cercanias', 'media_distancia', 'alta_velocidad', 'larga_distancia_convencional'))
   OR ('${inputs.grupo_modo}' = 'otros' AND clave IN ('autobus_interurbano', 'avion_interior', 'maritimo'))
ORDER BY m.mes
```

<LineChart
    data={serie_modo}
    x=mes
    y=por_1000
    series=modo
    yFmt=num0
    yAxisTitle="bidaiak hilean 1.000 biztanleko"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Bidaiak 1.000 biztanleko, biztanleriaren hazkundea garraioaren erabilera handiagoarekin nahas ez dadin. 2020ko amildegia COVID-19aren pandemia da. Hegazkina: barne-hegaldiak soilik; itsasontzia: kabotajea (Espainiako portuen artean).</p>

```sql recuperacion
-- Viajes por 1.000 habitantes: la población creció entre 2019 y el último año
SELECT
    a.modo,
    1000.0 * a.viajeros / pa.poblacion AS por_1000_ultimo,
    1000.0 * p.viajeros / p19.poblacion AS por_1000_2019,
    (a.viajeros / pa.poblacion) / (p.viajeros / p19.poblacion) - 1 AS variacion,
    a.viajeros AS viajeros_ultimo_anio
FROM ${anual} a
JOIN ${anual} p ON p.clave = a.clave AND p.anio = 2019
JOIN ${poblacion} pa ON pa.anio = least(a.anio, (SELECT max(anio) FROM ${poblacion}))
JOIN ${poblacion} p19 ON p19.anio = 2019
WHERE a.anio = (SELECT max(anio) FROM ${anual})
  AND a.clave NOT IN ('total', 'urbano', 'interurbano', 'ferrocarril', 'larga_distancia')
ORDER BY variacion DESC
```

## Berreskuratu al da garraio publikoa pandemiaren ondoren?

Bidaiak 1.000 biztanleko azken urte osoan ({ultimo_anual[0]?.anio}), 2019arekin alderatuta, COVID-19aren aurreko azken urtea.

<DataTable data={recuperacion} rows=all>
    <Column id=modo title="Garraiobidea" />
    <Column id=por_1000_2019 title="2019 (1.000 biztanleko)" fmt=num0 />
    <Column id=por_1000_ultimo title="Azken urtea (1.000 biztanleko)" fmt=num0 />
    <Column id=variacion title="Aldakuntza biztanleko" fmt=pct1 contentType=delta />
    <Column id=viajeros_ultimo_anio title="Bidaiariak guztira" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Abiadura handia liberalizazioarekin (Ouigo 2021etik eta Iryo 2022tik, Renfez gain) eta linea berriekin hazten da.</p>

## Metroa eta hiri-autobusa hiriaz hiri

```sql ciudades
-- Por habitante del municipio (padrón del año; el último para los más recientes)
WITH cod AS (
    SELECT * FROM (VALUES ('Madrid', '28079'), ('Barcelona', '08019'), ('València', '46250'), ('Bilbao', '48020'),
        ('Sevilla', '41091'), ('Málaga', '29067'), ('Palma', '07040')) AS t(ciudad, cod_mun)
),
pob AS (
    SELECT cod_mun, CAST(anio AS INTEGER) AS anio, poblacion FROM mother.poblacion_municipios
)
SELECT c.*, p.poblacion, c.viajeros / p.poblacion AS por_habitante
FROM mother.movilidad_transporte_ciudades c
JOIN cod ON cod.ciudad = c.ciudad
JOIN pob p ON p.cod_mun = cod.cod_mun
 AND p.anio = greatest(least(CAST(year(c.mes) AS INTEGER), (SELECT max(anio) FROM pob)), (SELECT min(anio) FROM pob))
ORDER BY c.mes
```

<ButtonGroup name=modo_ciudad title="Garraiobidea">
    <ButtonGroupItem valueLabel="Metroa" value="Metro" default />
    <ButtonGroupItem valueLabel="Hiri-autobusa" value="Autobús urbano" />
</ButtonGroup>

```sql serie_ciudad
SELECT mes, ciudad, viajeros, por_habitante FROM ${ciudades} WHERE modo = '${inputs.modo_ciudad}'
```

<LineChart
    data={serie_ciudad}
    x=mes
    y=por_habitante
    series=ciudad
    yFmt=num1
    yAxisTitle="bidaiak hilean udalerriko biztanleko"
    xFmt="mmm yyyy"
    legend=true
/>

<p class="text-xs text-gray-500">Bidaiak hilean udalerrian erroldatutako biztanle bakoitzeko. Madrilgo, Bartzelonako, Bilboko edo Valentziako metroak inguruko udalerriei ere ematen die zerbitzua; beraz, hiriko biztanleko zifrak pertsonako erabilera gainestimatzen du. Hiri bakoitzaren bilakaera ikusteko balio du, ez hainbeste hiriak elkarren artean alderatzeko.</p>

```sql ciudades_anual
WITH anual AS (
    SELECT ciudad, modo, CAST(year(mes) AS INTEGER) AS anio, sum(viajeros) AS viajeros, sum(viajeros) / any_value(poblacion) AS por_habitante, count(*) AS meses
    FROM ${ciudades}
    GROUP BY ALL
    HAVING count(*) = 12
)
SELECT
    a.ciudad,
    a.modo,
    a.anio,
    a.viajeros,
    a.por_habitante,
    a.por_habitante / p.por_habitante - 1 AS vs_2019
FROM anual a
LEFT JOIN anual p ON p.ciudad = a.ciudad AND p.modo = a.modo AND p.anio = 2019
WHERE a.anio = (SELECT max(anio) FROM anual)
ORDER BY a.modo DESC, a.por_habitante DESC
```

<DataTable data={ciudades_anual} rows=all>
    <Column id=ciudad title="Hiria" />
    <Column id=modo title="Garraiobidea" />
    <Column id=por_habitante title="Bidaiak biztanleko (azken urte osoa)" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=vs_2019 title="2019arekin alderatuta (biztanleko)" fmt=pct1 contentType=delta />
    <Column id=viajeros title="Bidaiariak guztira" fmt=num0 />
</DataTable>

---

## Iturriak eta oharrak

- **[INE – Bidaiarien Garraioaren Estatistika](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736176906&menu=ultiDatos&idp=1254735576820)**, [20239](https://www.ine.es/jaxiT3/Tabla.htm?t=20239) taula (Espainia, garraiobidearen arabera) eta [20193](https://www.ine.es/jaxiT3/Tabla.htm?t=20193) taula (metroa duten hiriak). Hilekoa 2012tik; INEk hilabete bakoitza amaitu eta 40 bat egunera argitaratzen du.
- Hiri-garraioa: metroa eta hiri-autobus erregularra. Cercanías trena hiriarteko garraiotzat hartzen da.

<LastRefreshed prefix="Datuak eguneratuta" />
