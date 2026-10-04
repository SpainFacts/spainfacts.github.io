---
i18n_origen: fb0421136c8a
title: Os paraísos fiscais das frotas
description: "Aldeas de unhas decenas de habitantes onde se matriculan miles de coches de empresa: as frotas de renting e aluguer domicílianse onde o imposto de circulación é máis barato. Datos da DGT e de Facenda."
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
    municipio, provincia, poblacion, flota, flota_por_habitante, cuota_flota_espana_pct,
    ivtm_turismo, capital, ivtm_turismo_capital, ahorro_por_coche, ahorro_estimado
FROM mother.movilidad_flotas_municipios
WHERE anio = (SELECT anio FROM ${ultimo_completo})
ORDER BY flota DESC
```

```sql resumen
WITH m AS (SELECT * FROM ${municipios})
SELECT
    (SELECT anio FROM ${ultimo_completo}) AS anio,
    (SELECT sum(cuota_flota_espana_pct) FROM (SELECT cuota_flota_espana_pct FROM m ORDER BY flota DESC LIMIT 10)) AS cuota_top10,
    sum(flota) FILTER (WHERE poblacion < 5000) AS flota_pueblos,
    sum(cuota_flota_espana_pct) FILTER (WHERE poblacion < 5000) AS cuota_pueblos,
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
    sum(cuota_flota_espana_pct) FILTER (WHERE poblacion < 5000) AS cuota_pueblos,
    sum(cuota_flota_espana_pct) FILTER (WHERE municipio IN ('Madrid', 'Barcelona')) AS cuota_madrid_barcelona
FROM mother.movilidad_flotas_municipios
GROUP BY anio
ORDER BY anio
```

# 🏝️ Os paraísos fiscais das frotas

Un coche matricúlase no concello onde ten o domicilio o seu dono. Para un particular é a súa casa; para unha empresa de renting ou de aluguer de coches, calquera delegación que abra. E o imposto de circulación (IVTM) fíxao cada concello: a lei marca unha tarifa mínima e permite multiplicala ata por dous. O resultado é que miles de coches de empresa que circulan por Madrid, Barcelona ou as zonas turísticas están domiciliados en vilas e aldeas de unhas decenas ou centos de habitantes co imposto máis baixo. É legal, pero eses concellos cobran un imposto por coches que non circulan polas súas rúas, e as cidades onde si circulan non o cobran.

<Grid cols=3>
    <KpiCard
        title="Coches de frota nos 10 primeiros concellos"
        value={resumen[0]?.cuota_top10}
        formattedValue={formatNumber(resumen[0]?.cuota_top10, 0)}
        unit="%"
        period="dos turismos novos de empresas, renting e aluguer · {resumen[0]?.anio}"
        source="DGT"
    />
    <KpiCard
        title="En concellos de menos de 5.000 habitantes"
        value={resumen[0]?.cuota_pueblos}
        formattedValue={formatNumber(resumen[0]?.cuota_pueblos, 0)}
        unit="%"
        period="{formatNumber(resumen[0]?.flota_pueblos, 0)} coches de frota en concellos onde vive o {formatNumber(resumen[0]?.peso_pueblos * 100, 2)} % da poboación · {resumen[0]?.anio}"
        source="DGT / INE"
    />
    <KpiCard
        title="Récord: {resumen[0]?.record_municipio}"
        value={resumen[0]?.record_por_hab}
        formattedValue="{formatNumber(resumen[0]?.record_por_hab, 0)} coches por habitante"
        period="{formatNumber(resumen[0]?.record_flota, 0)} coches de frota novos para {formatNumber(resumen[0]?.record_poblacion, 0)} veciños · {resumen[0]?.anio}"
        source="DGT / INE"
    />
</Grid>

## Coches de empresa por veciño

<BarChart
    data={por_habitante}
    x=municipio
    y=flota_por_habitante
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#b91c1c"
    title="Turismos novos de frota matriculados en {resumen[0]?.anio} por cada habitante (concellos con 1.000 ou máis)"
/>

## Os concellos onde máis coches de frota se matriculan

<DataTable data={municipios} rows=20 search=true>
    <Column id=municipio title="Concello" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=flota title="Coches de frota" fmt=num0 contentType=bar barColor="#fecaca" />
    <Column id=flota_por_habitante title="Por habitante" fmt=num1 />
    <Column id=cuota_flota_espana_pct title="% de España" fmt=num1 />
    <Column id=ivtm_turismo title="IVTM (€/ano)" fmt=num2 />
    <Column id=ivtm_turismo_capital title="IVTM na capital" fmt=num2 />
    <Column id=ahorro_estimado title="Aforro estimado (€)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Coches de frota: turismos novos matriculados a nome de empresas (incluídas as automatriculacións de concesionarios), de renting ou de aluguer sen condutor. IVTM: cota anual dun turismo de 8 a 11,99 cabalos fiscais, o tramo da maioría dos coches actuais, segundo a ordenanza de cada concello (sen bonificacións por tipo de motor). Aforro estimado: o que eses coches pagan de menos o primeiro ano fronte á capital da súa provincia; o coche segue aforrándoo cada ano que siga domiciliado alí. Só hai tarifas para os concellos con máis frotas e as súas capitais.</p>

Só cos coches de frota matriculados en {resumen[0]?.anio} nos concellos da táboa, as empresas pagan uns **{formatNumber(resumen[0]?.ahorro_total / 1e6, 1)} millóns de euros menos ao ano** de imposto de circulación que se os domiciliasen na capital da súa provincia.

## Como evolucionou?

<LineChart
    data={evolucion}
    x=anio
    y={['cuota_pueblos', 'cuota_madrid_barcelona']}
    yFmt='0"%"'
    xFmt="####"
    markers=true
    colorPalette={['#b91c1c', '#2563eb']}
    seriesLabels={{cuota_pueblos: 'Concellos de menos de 5.000 habitantes', cuota_madrid_barcelona: 'Madrid e Barcelona capitais'}}
    title="Peso nos turismos novos de frota de España"
/>

<p class="text-xs text-gray-500">As vilas pequenas pesan cada vez menos: parte das frotas marchou a concellos grandes do contorno de Madrid co imposto tamén rebaixado, como Alcobendas, Majadahonda ou Boadilla del Monte. Só contan os concellos con 100 ou máis coches de frota no ano. O último ano está incompleto.</p>

## Por que pasa

- **É legal.** O vehículo tributa onde está domiciliado o seu titular, e unha empresa pode domiciliar os seus coches en calquera sucursal. Desde que as matrículas deixaron de levar a letra da provincia (2000), nada distingue a simple vista onde está rexistrado un coche.
- **As grandes prexudicadas son as cidades**: soportan o tráfico, o aparcamento e as emisións deses coches sen cobrar o seu imposto. En cambio, aldeas con unhas decenas de veciños recadan por coches que nunca pasan polas súas rúas, aínda que cunha tarifa baixa.
- **Distorsiona as estatísticas**: as matriculacións por provincia ou concello din máis de onde teñen a sede as frotas que de onde se compran ou circulan os coches. Por iso en [Coche eléctrico](/gl/movilidad/coche-electrico) o mapa mostra por defecto só os coches de particulares.
- A asociación de condutores AEA leva anos documentándoo: segundo o seu estudo de 2026, dez concellos concentran arredor do 35 % das matriculacións de vehículos de empresa.

---

## Fontes e notas

- **[DGT – Microdatos de matriculacións (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**: concello do domicilio do titular, tipo de titular, renting e servizo de cada turismo novo.
- **[INE – Padrón municipal](https://www.ine.es/dynt3/inebase/index.htm?padre=517)**: habitantes de cada concello (último ano publicado para os máis recentes).
- **[Ministerio de Facenda – Consulta de información impositiva municipal](https://serviciostelematicosext.hacienda.gob.es/SGFAL/ConsultaTipos/html/portadaconsultasm.aspx)**: tarifas do IVTM aprobadas por cada concello.
- **[AEA – Estudo sobre o IVTM e os «paraísos fiscais» do imposto de circulación (2026)](https://aeaclub.org/ivtm-impuesto-municipal-vehiculos-paraisos-fiscales/)**.

<LastRefreshed prefix="Datos actualizados" />
