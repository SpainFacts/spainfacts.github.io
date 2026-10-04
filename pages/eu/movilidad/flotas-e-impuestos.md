---
title: Flotentzako paradisu fiskalak
description: "Hamarka biztanleko herriak, non milaka enpresa-auto matrikulatzen diren: renting eta alokairuko flotak zirkulazio-zerga merkeena den tokian helbideratzen dira. DGTren eta Ogasunaren datuak."
i18n_origen: fb0421136c8a
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

# 🏝️ Flotentzako paradisu fiskalak

Auto bat bere jabeak helbidea duen udalerrian matrikulatzen da. Partikular batentzat, bere etxea da; renting edo auto-alokairuko enpresa batentzat, irekitzen duen edozein ordezkaritza. Eta zirkulazio-zerga (IVTM) udal bakoitzak ezartzen du: legeak gutxieneko tarifa bat zehazten du eta bider bi arte biderkatzeko aukera ematen du. Ondorioz, Madrilen, Bartzelonan edo turismo-guneetan zirkulatzen duten milaka enpresa-auto zerga baxuena duten hamarka edo ehunka biztanleko herrietan daude helbideratuta. Legezkoa da, baina udal horiek beren kaleetatik zirkulatzen ez duten autoengatik kobratzen dute zerga, eta benetan zirkulatzen duten hiriek ez dute kobratzen.

<Grid cols=3>
    <KpiCard
        title="Flota-autoak lehen 10 udalerrietan"
        value={resumen[0]?.cuota_top10}
        formattedValue={formatNumber(resumen[0]?.cuota_top10, 0)}
        unit="%"
        period="enpresen, rentingaren eta alokairuaren turismo berrietatik · {resumen[0]?.anio}"
        source="DGT"
    />
    <KpiCard
        title="5.000 biztanletik beherako herrietan"
        value={resumen[0]?.cuota_pueblos}
        formattedValue={formatNumber(resumen[0]?.cuota_pueblos, 0)}
        unit="%"
        period="{formatNumber(resumen[0]?.flota_pueblos, 0)} flota-auto biztanleriaren % {formatNumber(resumen[0]?.peso_pueblos * 100, 2)} bizi den udalerrietan · {resumen[0]?.anio}"
        source="DGT / INE"
    />
    <KpiCard
        title="Errekorra: {resumen[0]?.record_municipio}"
        value={resumen[0]?.record_por_hab}
        formattedValue="{formatNumber(resumen[0]?.record_por_hab, 0)} auto biztanleko"
        period="{formatNumber(resumen[0]?.record_flota, 0)} flota-auto berri {formatNumber(resumen[0]?.record_poblacion, 0)} bizilagunentzat · {resumen[0]?.anio}"
        source="DGT / INE"
    />
</Grid>

## Enpresa-autoak bizilagun bakoitzeko

<BarChart
    data={por_habitante}
    x=municipio
    y=flota_por_habitante
    swapXY=true
    sort=false
    yFmt=num1
    fillColor="#b91c1c"
    title="{resumen[0]?.anio}. urtean matrikulatutako flota-turismo berriak biztanle bakoitzeko (1.000 edo gehiago dituzten udalerriak)"
/>

## Flota-auto gehien matrikulatzen diren udalerriak

<DataTable data={municipios} rows=20 search=true>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=poblacion title="Biztanleak" fmt=num0 />
    <Column id=flota title="Flota-autoak" fmt=num0 contentType=bar barColor="#fecaca" />
    <Column id=flota_por_habitante title="Biztanleko" fmt=num1 />
    <Column id=cuota_flota_espana_pct title="Espainiako %" fmt=num1 />
    <Column id=ivtm_turismo title="IVTM (€/urte)" fmt=num2 />
    <Column id=ivtm_turismo_capital title="IVTM hiriburuan" fmt=num2 />
    <Column id=ahorro_estimado title="Aurrezki estimatua (€)" fmt=num0 />
</DataTable>

<p class="text-xs text-gray-500">Flota-autoak: enpresen (kontzesionarioen automatrikulazioak barne), rentingaren edo gidaririk gabeko alokairuaren izenean matrikulatutako turismo berriak. IVTM: 8 eta 11,99 zaldi fiskal arteko turismo baten urteko kuota, gaur egungo auto gehienen tartea, udalerri bakoitzeko ordenantzaren arabera (motor motagatiko hobaririk gabe). Aurrezki estimatua: auto horiek lehen urtean beren probintziako hiriburuarekin alderatuta gutxiago ordaintzen dutena; autoak aurrezten jarraitzen du bertan helbideratuta dagoen urte bakoitzean. Flota gehien dituzten udalerrien eta haien hiriburuen tarifak baino ez daude.</p>

{resumen[0]?.anio}. urtean taulako udalerrietan matrikulatutako flota-autoekin bakarrik, enpresek **{formatNumber(resumen[0]?.ahorro_total / 1e6, 1)} milioi euro gutxiago ordaintzen dituzte urtean** zirkulazio-zergan, beren probintziako hiriburuan helbideratu izan balituzte baino.

## Nola aldatu da?

<LineChart
    data={evolucion}
    x=anio
    y={['cuota_pueblos', 'cuota_madrid_barcelona']}
    yFmt='0"%"'
    xFmt="####"
    markers=true
    colorPalette={['#b91c1c', '#2563eb']}
    seriesLabels={{cuota_pueblos: '5.000 biztanletik beherako herriak', cuota_madrid_barcelona: 'Madril eta Bartzelona hiriburuak'}}
    title="Pisua Espainiako flota-turismo berrietan"
/>

<p class="text-xs text-gray-500">Herri txikiek gero eta pisu txikiagoa dute: floten zati bat zerga ere jaitsita duten Madril inguruko udalerri handietara joan da, hala nola Alcobendas, Majadahonda edo Boadilla del Monte. Urtean 100 flota-auto edo gehiago dituzten udalerriak baino ez dira zenbatzen. Azken urtea osatu gabe dago.</p>

## Zergatik gertatzen den

- **Legezkoa da.** Ibilgailuak bere titularra helbideratuta dagoen tokian ordaintzen du zerga, eta enpresa batek bere autoak edozein sukurtsaletan helbidera ditzake. Matrikulek probintziaren letra eramateari utzi ziotenetik (2000), ezerk ez du begi-bistaz bereizten auto bat non dagoen erregistratuta.
- **Kalteturik handienak hiriak dira**: auto horien trafikoa, aparkalekua eta isuriak jasaten dituzte, haien zerga kobratu gabe. Aitzitik, hamarka bizilagun dituzten herriek inoiz beren kaleetatik igarotzen ez diren autoengatik biltzen dute zerga, tarifa baxuarekin bada ere.
- **Estatistikak desitxuratzen ditu**: probintzia edo udalerriko matrikulazioek gehiago esaten dute flotek egoitza non duten, autoak non erosten edo zirkulatzen diren baino. Horregatik, [Auto elektrikoa](/eu/movilidad/coche-electrico) orrian, mapak lehenespenez partikularren autoak soilik erakusten ditu.
- AEA gidarien elkarteak urteak daramatza hori dokumentatzen: 2026ko azterlanaren arabera, hamar udalerrik biltzen dituzte enpresa-ibilgailuen matrikulazioen % 35 inguru.

---

## Iturriak eta oharrak

- **[DGT – Matrikulazioen mikrodatuak (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html)**: titularraren helbideko udalerria, titular mota, rentinga eta turismo berri bakoitzaren zerbitzua.
- **[INE – Udal-errolda](https://www.ine.es/dynt3/inebase/index.htm?padre=517)**: udalerri bakoitzeko biztanleak (argitaratutako azken urtea, berrienentzat).
- **[Ogasun Ministerioa – Udal-zergen informazioaren kontsulta](https://serviciostelematicosext.hacienda.gob.es/SGFAL/ConsultaTipos/html/portadaconsultasm.aspx)**: udal bakoitzak onartutako IVTM tarifak.
- **[AEA – IVTMri eta zirkulazio-zergaren «paradisu fiskalei» buruzko azterlana (2026)](https://aeaclub.org/ivtm-impuesto-municipal-vehiculos-paraisos-fiscales/)**.

<LastRefreshed prefix="Datuak eguneratuta" />
