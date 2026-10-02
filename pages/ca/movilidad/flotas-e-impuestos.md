---
title: Els paradisos fiscals de les flotes
description: "Pobles d'unes desenes d'habitants on es matriculen milers de cotxes d'empresa: les flotes de rènting i lloguer es domicilien on l'impost de circulació és més barat. Dades de la DGT i d'Hisenda."
i18n_origen: ad7c7e41b297
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql anios
SELECT DISTINCT anio FROM mother.movilidad_flotas_municipios ORDER BY anio DESC
```

```sql ultimo_completo
-- Último año con los doce meses (el año en curso se queda fuera de los rankings)
SELECT max(anio) AS anio
FROM mother.movilidad_flotas_municipios
WHERE anio < (SELECT max(year(mes)) FROM mother.movilidad_matriculaciones_mensual)
```

```sql municipios
SELECT
    municipio, provincia, poblacion, flota, flota_por_habitante, cuota_flota_espana,
    ivtm_turismo, capital, ivtm_turismo_capital, ahorro_por_coche, ahorro_estimado
FROM mother.movilidad_flotas_municipios
WHERE anio = (SELECT anio FROM ${ultimo_completo})
ORDER BY flota DESC
```

```sql resumen
WITH m AS (SELECT * FROM ${municipios})
SELECT
    (SELECT anio FROM ${ultimo_completo}) AS anio,
    (SELECT sum(cuota_flota_espana) FROM (SELECT cuota_flota_espana FROM m ORDER BY flota DESC LIMIT 10)) AS cuota_top10,
    sum(flota) FILTER (WHERE poblacion < 5000) AS flota_pueblos,
    sum(cuota_flota_espana) FILTER (WHERE poblacion < 5000) AS cuota_pueblos,
    sum(poblacion) FILTER (WHERE poblacion < 5000) / (SELECT poblacion FROM mother.poblacion_territorios WHERE nivel = 'pais' AND sexo = 'Total' ORDER BY anio DESC LIMIT 1) AS peso_pueblos,
    arg_max(municipio, flota_por_habitante) FILTER (WHERE flota >= 1000) AS record_municipio,
    max(flota_por_habitante) FILTER (WHERE flota >= 1000) AS record_por_hab,
    arg_max(poblacion, flota_por_habitante) FILTER (WHERE flota >= 1000) AS record_poblacion,
    arg_max(flota, flota_por_habitante) FILTER (WHERE flota >= 1000) AS record_flota,
    sum(ahorro_estimado) FILTER (WHERE ahorro_estimado > 0) AS ahorro_total
FROM m
```

```sql por_habitante
SELECT municipio, flota_por_habitante, poblacion, flota
FROM ${municipios}
WHERE flota >= 1000
ORDER BY flota_por_habitante DESC
LIMIT 15
```

```sql evolucion
-- Peso de los pueblos de menos de 5.000 habitantes en las flotas matriculadas cada año
SELECT
    anio,
    sum(cuota_flota_espana) FILTER (WHERE poblacion < 5000) AS cuota_pueblos,
    sum(cuota_flota_espana) FILTER (WHERE municipio IN ('Madrid', 'Barcelona')) AS cuota_madrid_barcelona
FROM mother.movilidad_flotas_municipios
GROUP BY anio
ORDER BY anio
```

# 🏝️ Els paradisos fiscals de les flotes

Un cotxe es matricula al municipi on té el domicili el seu propietari. Per a un particular és casa seva; per a una empresa de rènting o de lloguer de cotxes, qualsevol delegació que obri. I l'impost de circulació (IVTM) el fixa cada ajuntament: la llei marca una tarifa mínima i permet multiplicar-la fins per dos. El resultat és que milers de cotxes d'empresa que circulen per Madrid, Barcelona o les zones turístiques estan domiciliats en pobles d'unes desenes o centenars d'habitants amb l'impost més baix. És legal, però aquests ajuntaments cobren un impost per cotxes que no circulen pels seus carrers, i les ciutats on sí que hi circulen no el cobren.

<Grid cols=3>
    <KpiCard
        title="Cotxes de flota als 10 primers municipis"
        value={resumen[0]?.cuota_top10 * 100}
        formattedValue={formatNumber(resumen[0]?.cuota_top10 * 100, 0)}
        unit="%"
        period="dels turismes nous d'empreses, rènting i lloguer · {resumen[0]?.anio}"
        source="DGT"
    />
    <KpiCard
        title="En pobles de menys de 5.000 habitants"
        value={resumen[0]?.cuota_pueblos * 100}
        formattedValue={formatNumber(resumen[0]?.cuota_pueblos * 100, 0)}
        unit="%"
        period="{formatNumber(resumen[0]?.flota_pueblos, 0)} cotxes de flota en municipis on viu el {formatNumber(resumen[0]?.peso_pueblos * 100, 2)} % de la població · {resumen[0]?.anio}"
        source="DGT / INE"
    />
    <KpiCard
        title="Rècord: {resumen[0]?.record_municipio}"
        value={resumen[0]?.record_por_hab}
        formattedValue="{formatNumber(resumen[0]?.record_por_hab, 0)} cotxes per habitant"
        period="{formatNumber(resumen[0]?.record_flota, 0)} cotxes de flota nous per a {formatNumber(resumen[0]?.record_poblacion, 0)} veïns · {resumen[0]?.anio}"
        source="DGT / INE"
    />
</Grid>

## Cotxes d'empresa per veí

<BarChart
    data={por_habitante}
    x=municipio
    y=flota_por_habitante
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#b91c1c"
    title="Turismes nous de flota matriculats el {resumen[0]?.anio} per cada habitant (municipis amb 1.000 o més)"
/>

## Els municipis on es matriculen més cotxes de flota

<DataTable data={municipios} rows=20 search=true>
    <Column id=municipio title="Municipi" />
    <Column id=provincia title="Província" />
    <Column id=poblacion title="Habitants" fmt=num0 />
    <Column id=flota title="Cotxes de flota" fmt=num0 contentType=bar barColor="#fecaca" />
    <Column id=flota_por_habitante title="Per habitant" fmt=num1 />
    <Column id=cuota_flota_espana title="% d'Espanya" fmt=pct1 />
    <Column id=ivtm_turismo title="IVTM (€/any)" fmt=num2 />
    <Column id=ivtm_turismo_capital title="IVTM a la capital" fmt=num2 />
    <Column id=ahorro_estimado title="Estalvi estimat (€)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Cotxes de flota: turismes nous matriculats a nom d'empreses (incloses les automatriculacions de concessionaris), de rènting o de lloguer sense conductor. IVTM: quota anual d'un turisme de 8 a 11,99 cavalls fiscals, el tram de la majoria dels cotxes actuals, segons l'ordenança de cada municipi (sense bonificacions per tipus de motor). Estalvi estimat: el que aquests cotxes paguen de menys el primer any respecte de la capital de la seva província; el cotxe ho continua estalviant cada any que continuï domiciliat allà. Només hi ha tarifes per als municipis amb més flotes i les seves capitals.</p>

Només amb els cotxes de flota matriculats el {resumen[0]?.anio} als municipis de la taula, les empreses paguen uns **{formatNumber(resumen[0]?.ahorro_total / 1e6, 1)} milions d'euros menys l'any** d'impost de circulació que si els haguessin domiciliat a la capital de la seva província.

## Com ha evolucionat?

<LineChart
    data={evolucion}
    x=anio
    y={['cuota_pueblos', 'cuota_madrid_barcelona']}
    yFmt=pct0
    xFmt="####"
    markers=true
    colorPalette={['#b91c1c', '#2563eb']}
    seriesLabels={{cuota_pueblos: 'Pobles de menys de 5.000 habitants', cuota_madrid_barcelona: 'Madrid i Barcelona capitals'}}
    title="Pes en els turismes nous de flota d'Espanya"
/>

<p class="text-xs text-gray-500">Els pobles petits pesen cada vegada menys: part de les flotes ha marxat a municipis grans de l'entorn de Madrid amb l'impost també rebaixat, com Alcobendas, Majadahonda o Boadilla del Monte. Només compten els municipis amb 100 o més cotxes de flota en l'any. L'últim any és incomplet.</p>

## Per què passa

- **És legal.** El vehicle tributa on està domiciliat el seu titular, i una empresa pot domiciliar els seus cotxes en qualsevol sucursal. Des que les matrícules van deixar de portar la lletra de la província (2000), res no distingeix a simple vista on està registrat un cotxe.
- **Els grans perjudicats són les ciutats**: suporten el trànsit, l'aparcament i les emissions d'aquests cotxes sense cobrar-ne l'impost. En canvi, pobles amb unes desenes de veïns recapten per cotxes que no passen mai pels seus carrers, encara que amb una tarifa baixa.
- **Distorsiona les estadístiques**: les matriculacions per província o municipi diuen més d'on tenen la seu les flotes que d'on es compren o circulen els cotxes. Per això a [Cotxe elèctric](/ca/movilidad/coche-electrico) el mapa mostra per defecte només els cotxes de particulars.
- L'associació de conductors AEA fa anys que ho documenta: segons el seu estudi del 2026, deu municipis concentren al voltant del 35 % de les matriculacions de vehicles d'empresa.

---

## Fonts i notes

- **[DGT – Microdades de matriculacions (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**: municipi del domicili del titular, tipus de titular, rènting i servei de cada turisme nou.
- **[INE – Padró municipal](https://www.ine.es/dynt3/inebase/index.htm?padre=517)**: habitants de cada municipi (últim any publicat per als més recents).
- **[Ministeri d'Hisenda – Consulta d'informació impositiva municipal](https://serviciostelematicosext.hacienda.gob.es/SGFAL/ConsultaTipos/html/portadaconsultasm.aspx)**: tarifes de l'IVTM aprovades per cada ajuntament.
- **[AEA – Estudi sobre l'IVTM i els «paradisos fiscals» de l'impost de circulació (2026)](https://aeaclub.org/ivtm-impuesto-municipal-vehiculos-paraisos-fiscales/)**.

<LastRefreshed prefix="Dades actualitzades" />
