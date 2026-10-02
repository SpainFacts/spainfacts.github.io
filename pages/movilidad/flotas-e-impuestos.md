---
title: Los paraísos fiscales de las flotas
description: "Pueblos de unas decenas de habitantes donde se matriculan miles de coches de empresa: las flotas de renting y alquiler se domicilian donde el impuesto de circulación es más barato. Datos de la DGT y de Hacienda."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../src/lib/utils.js';
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

# 🏝️ Los paraísos fiscales de las flotas

Un coche se matricula en el municipio donde tiene el domicilio su dueño. Para un particular es su casa; para una empresa de renting o de alquiler de coches, cualquier delegación que abra. Y el impuesto de circulación (IVTM) lo fija cada ayuntamiento: la ley marca una tarifa mínima y permite multiplicarla hasta por dos. El resultado es que miles de coches de empresa que circulan por Madrid, Barcelona o las zonas turísticas están domiciliados en pueblos de unas decenas o cientos de habitantes con el impuesto más bajo. Es legal, pero esos ayuntamientos cobran un impuesto por coches que no circulan por sus calles, y las ciudades donde sí circulan no lo cobran.

<Grid cols=3>
    <KpiCard
        title="Coches de flota en los 10 primeros municipios"
        value={resumen[0]?.cuota_top10 * 100}
        formattedValue={formatNumber(resumen[0]?.cuota_top10 * 100, 0)}
        unit="%"
        period="de los turismos nuevos de empresas, renting y alquiler · {resumen[0]?.anio}"
        source="DGT"
    />
    <KpiCard
        title="En pueblos de menos de 5.000 habitantes"
        value={resumen[0]?.cuota_pueblos * 100}
        formattedValue={formatNumber(resumen[0]?.cuota_pueblos * 100, 0)}
        unit="%"
        period="{formatNumber(resumen[0]?.flota_pueblos, 0)} coches de flota en municipios donde vive el {formatNumber(resumen[0]?.peso_pueblos * 100, 2)} % de la población · {resumen[0]?.anio}"
        source="DGT / INE"
    />
    <KpiCard
        title="Récord: {resumen[0]?.record_municipio}"
        value={resumen[0]?.record_por_hab}
        formattedValue="{formatNumber(resumen[0]?.record_por_hab, 0)} coches por habitante"
        period="{formatNumber(resumen[0]?.record_flota, 0)} coches de flota nuevos para {formatNumber(resumen[0]?.record_poblacion, 0)} vecinos · {resumen[0]?.anio}"
        source="DGT / INE"
    />
</Grid>

## Coches de empresa por vecino

<BarChart
    data={por_habitante}
    x=municipio
    y=flota_por_habitante
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#b91c1c"
    title="Turismos nuevos de flota matriculados en {resumen[0]?.anio} por cada habitante (municipios con 1.000 o más)"
/>

## Los municipios donde más coches de flota se matriculan

<DataTable data={municipios} rows=20 search=true>
    <Column id=municipio title="Municipio" />
    <Column id=provincia title="Provincia" />
    <Column id=poblacion title="Habitantes" fmt=num0 />
    <Column id=flota title="Coches de flota" fmt=num0 contentType=bar barColor="#fecaca" />
    <Column id=flota_por_habitante title="Por habitante" fmt=num1 />
    <Column id=cuota_flota_espana title="% de España" fmt=pct1 />
    <Column id=ivtm_turismo title="IVTM (€/año)" fmt=num2 />
    <Column id=ivtm_turismo_capital title="IVTM en la capital" fmt=num2 />
    <Column id=ahorro_estimado title="Ahorro estimado (€)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Coches de flota: turismos nuevos matriculados a nombre de empresas (incluidas las automatriculaciones de concesionarios), de renting o de alquiler sin conductor. IVTM: cuota anual de un turismo de 8 a 11,99 caballos fiscales, el tramo de la mayoría de los coches actuales, según la ordenanza de cada municipio (sin bonificaciones por tipo de motor). Ahorro estimado: lo que esos coches pagan de menos el primer año frente a la capital de su provincia; el coche lo sigue ahorrando cada año que siga domiciliado allí. Solo hay tarifas para los municipios con más flotas y sus capitales.</p>

Solo con los coches de flota matriculados en {resumen[0]?.anio} en los municipios de la tabla, las empresas pagan unos **{formatNumber(resumen[0]?.ahorro_total / 1e6, 1)} millones de euros menos al año** de impuesto de circulación que si los hubieran domiciliado en la capital de su provincia.

## ¿Cómo ha evolucionado?

<LineChart
    data={evolucion}
    x=anio
    y={['cuota_pueblos', 'cuota_madrid_barcelona']}
    yFmt=pct0
    xFmt="####"
    markers=true
    colorPalette={['#b91c1c', '#2563eb']}
    seriesLabels={{cuota_pueblos: 'Pueblos de menos de 5.000 habitantes', cuota_madrid_barcelona: 'Madrid y Barcelona capitales'}}
    title="Peso en los turismos nuevos de flota de España"
/>

<p class="text-xs text-gray-500">Los pueblos pequeños pesan cada vez menos: parte de las flotas se ha ido a municipios grandes del entorno de Madrid con el impuesto también rebajado, como Alcobendas, Majadahonda o Boadilla del Monte. Solo cuentan los municipios con 100 o más coches de flota en el año. El último año está incompleto.</p>

## Por qué pasa

- **Es legal.** El vehículo tributa donde está domiciliado su titular, y una empresa puede domiciliar sus coches en cualquier sucursal. Desde que las matrículas dejaron de llevar la letra de la provincia (2000), nada distingue a simple vista dónde está registrado un coche.
- **Los grandes perjudicados son las ciudades**: soportan el tráfico, el aparcamiento y las emisiones de esos coches sin cobrar su impuesto. En cambio, pueblos con unas decenas de vecinos recaudan por coches que nunca pasan por sus calles, aunque con una tarifa baja.
- **Distorsiona las estadísticas**: las matriculaciones por provincia o municipio dicen más de dónde tienen la sede las flotas que de dónde se compran o circulan los coches. Por eso en [Coche eléctrico](/movilidad/coche-electrico) el mapa muestra por defecto solo los coches de particulares.
- La asociación de conductores AEA lleva años documentándolo: según su estudio de 2026, diez municipios concentran en torno al 35 % de las matriculaciones de vehículos de empresa.

---

## Fuentes y notas

- **[DGT – Microdatos de matriculaciones (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**: municipio del domicilio del titular, tipo de titular, renting y servicio de cada turismo nuevo.
- **[INE – Padrón municipal](https://www.ine.es/dynt3/inebase/index.htm?padre=517)**: habitantes de cada municipio (último año publicado para los más recientes).
- **[Ministerio de Hacienda – Consulta de información impositiva municipal](https://serviciostelematicosext.hacienda.gob.es/SGFAL/ConsultaTipos/html/portadaconsultasm.aspx)**: tarifas del IVTM aprobadas por cada ayuntamiento.
- **[AEA – Estudio sobre el IVTM y los «paraísos fiscales» del impuesto de circulación (2026)](https://aeaclub.org/ivtm-impuesto-municipal-vehiculos-paraisos-fiscales/)**.

<LastRefreshed prefix="Datos actualizados" />
