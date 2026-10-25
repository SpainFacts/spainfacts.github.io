---
title: Immigrazioa
description: "Espainiako atzerritar biztanleria erkidegoaren eta nazionalitatearen arabera, migrazio-saldoa, etorrera irregularrak bidearen arabera, asilo-eskaerak eta naturalizazioak, datu ofizialekin."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: a376df7e1201
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import Comparativa from '../../../../../../../src/lib/components/Comparativa.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql pob_espana
SELECT anio, extranjeros, poblacion, extranjeros_pct AS valor
FROM mother.inmigracion_poblacion
WHERE nivel = 'pais'
ORDER BY anio
```

```sql flujos
SELECT * FROM mother.inmigracion_flujos_anuales ORDER BY anio
```

```sql llegadas_anual
SELECT CAST(year(mes) AS INTEGER) AS anio, via, sum(personas) AS personas, count(DISTINCT mes) AS meses
FROM mother.inmigracion_llegadas
GROUP BY ALL
ORDER BY anio
```

```sql llegadas_total
SELECT anio, sum(personas) AS valor, max(meses) AS meses
FROM ${llegadas_anual}
GROUP BY anio
ORDER BY anio
```

```sql asilo_anual
SELECT CAST(year(mes) AS INTEGER) AS anio, sum(solicitudes) AS valor, count(*) AS meses
FROM mother.inmigracion_asilo
GROUP BY 1
ORDER BY 1
```

```sql nacionalizaciones
SELECT anio, nacionalizaciones, por_1000_extranjeros AS valor
FROM mother.inmigracion_nacionalizaciones
WHERE cod = '00' AND nacionalidad_previa = 'Total'
ORDER BY anio
```

# 🌍 Immigrazioa

Zenbat atzerritar bizi diren Espainian, zenbat pertsona etortzen eta joaten diren urtero, nondik sartzen diren modu irregularrean sartzen direnak, zenbatek eskatzen duten asiloa eta zenbatek lortzen duten nazionalitatea.

<Grid cols=4>
    <KpiCard
        title="Atzerritar egoiliarrak"
        value={pob_espana.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(pob_espana.slice(-1)[0]?.valor, 1)} %"
        period="biztanleriarena · {formatCompact(pob_espana.slice(-1)[0]?.extranjeros, 2)} pertsona {urteko(pob_espana.slice(-1)[0]?.anio)} urtarrilaren 1ean"
        source="INE"
        sparklineData={pob_espana}
    />
    <KpiCard
        title="Atzerriarekiko migrazio-saldoa"
        value={flujos.slice(-1)[0]?.saldo_1000}
        formattedValue="+{formatNumber(flujos.slice(-1)[0]?.saldo_1000, 1)} 1.000 biz."
        period="{urtean(flujos.slice(-1)[0]?.anio)}, {formatNumber(flujos.slice(-1)[0]?.saldo, 0)} pertsona gehiago etorri ziren joan zirenak baino"
        source="INE"
        sparklineData={flujos.map(d => ({anio: d.anio, valor: d.saldo_1000}))}
    />
    <KpiCard
        title="Etorrera irregularrak"
        value={llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor}
        formattedValue={formatNumber(llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.valor, 0)}
        period="itsasoz eta lurrez {urtean(llegadas_total.filter(d => d.meses === 12).slice(-1)[0]?.anio)}"
        source="Barne Ministerioa / ACNUR"
        sparklineData={llegadas_total.filter(d => d.meses === 12)}
    />
    <KpiCard
        title="Naturalizazioak"
        value={nacionalizaciones.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(nacionalizaciones.slice(-1)[0]?.valor, 0)} 1.000 atzerritarreko"
        period="{urtean(nacionalizaciones.slice(-1)[0]?.anio)}, {formatNumber(nacionalizaciones.slice(-1)[0]?.nacionalizaciones, 0)} pertsonak lortu zuten nazionalitatea"
        source="INE"
        sparklineData={nacionalizaciones}
    />
</Grid>

```sql comparativa_internacional
SELECT * FROM mother.internacional_ultimo
WHERE indicador_id IN ('migrantes')
```

<Comparativa data={comparativa_internacional.filter(d => d.indicador_id === 'migrantes')} />


<p class="text-xs text-gray-500">Biztanleriaren tamainaren araberakoak diren zifrak biztanleko ematen dira. Etorrera irregularrak eta asilo-eskaerak pertsona kopurutan ematen dira, Espainiako biztanleriarekin batera hazten ez diren gertaerak direlako.</p>

## Atzerritar biztanleria

```sql grupos
SELECT anio, grupo, personas / poblacion AS cuota
FROM (
    SELECT anio, poblacion,
        unnest(['Unión Europea', 'Resto de Europa', 'África', 'Latinoamérica', 'Asia', 'América del Norte']) AS grupo,
        unnest([ue, resto_europa, africa, centroamerica_caribe + sudamerica, asia, america_norte]) AS personas
    FROM mother.inmigracion_poblacion
    WHERE nivel = 'pais'
)
ORDER BY anio
```

<BarChart
    data={grupos}
    x=anio
    y=cuota
    series=grupo
    type=stacked
    yFmt=pct0
    xFmt="####"
    colorPalette={['#1d4ed8', '#60a5fa', '#b45309', '#0f766e', '#a21caf', '#94a3b8']}
    title="Atzerritar egoiliarrak biztanleriaren ehunekotan, jatorriaren arabera"
/>

<p class="text-xs text-gray-500">Nazionalitatearen arabera, urtarrilaren 1ean (Biztanleriaren Estatistika Jarraitua). Atzerrian jaio eta dagoeneko Espainiako nazionalitatea duena espainiartzat zenbatzen da; beraz, atzerrian jaiotako biztanleria dezente handiagoa da. Krisi ekonomikoaren ondoren, atzerritarren kopurua 5,4 milioitik (2010) 4,4 milioira (2017) jaitsi zen; ordutik hazten ari da, batez ere latinoamerikarrekin, biztanleriaren 2,0 %-tik 4,9 %-ra igaro baitira.</p>

```sql ccaa
SELECT i.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta, i.extranjeros, i.extranjeros_pct
FROM mother.inmigracion_poblacion i
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = i.cod
WHERE i.nivel = 'ccaa' AND i.anio = (SELECT max(anio) FROM mother.inmigracion_poblacion)
ORDER BY i.extranjeros_pct DESC
```

<MapaEspana
    data={ccaa}
    geoJsonUrl="/geo/ccaa.geojson"
    geoId="cod_ccaa"
    areaCol="cod"
    value="extranjeros_pct"
    valueFmt='0.0"%"'
    link="ruta"
    colorPalette={['#f0fdfa', '#5eead4', '#0f766e']}
    height={440}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: INE"
    tooltip={[
        {id: 'comunidad', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'extranjeros_pct', title: 'Atzerritarrak', fmt: '0.0"%"'},
        {id: 'extranjeros', title: 'Pertsonak', fmt: 'num0'}
    ]}
/>

## Nor etortzen den eta nor joaten den

```sql flujos_grafico
SELECT anio, 'Llegadas desde el extranjero' AS flujo, inmigraciones_1000 AS por_1000 FROM ${flujos}
UNION ALL
SELECT anio, 'Salidas al extranjero', emigraciones_1000 FROM ${flujos}
ORDER BY anio
```

<BarChart
    data={flujos_grafico}
    x=anio
    y=por_1000
    series=flujo
    type=grouped
    yFmt=num1
    xFmt="####"
    colorPalette={['#0f766e', '#94a3b8']}
    yAxisTitle="1.000 biztanleko"
    title="Atzerriarekiko migrazioak 1.000 biztanleko (espainiarrak eta atzerritarrak)"
/>

```sql saldo_origen
SELECT nacionalidad, saldo_exterior, saldo_1000
FROM mother.inmigracion_saldos
WHERE nivel = 'pais' AND anio = (SELECT max(anio) FROM mother.inmigracion_saldos)
  AND nacionalidad IN ('Española', 'UE27_2020 sin España', 'Europa menos UE27_2020', 'África', 'América del Norte',
                       'Centro América y Caribe', 'Sudamérica', 'Asia')
ORDER BY saldo_1000 DESC
```

```sql saldo_paises
SELECT nacionalidad AS pais, saldo_exterior
FROM mother.inmigracion_saldos
WHERE nivel = 'pais' AND NOT es_grupo AND anio = (SELECT max(anio) FROM mother.inmigracion_saldos)
ORDER BY saldo_exterior DESC
LIMIT 12
```

<Grid cols=2>
    <BarChart
        data={saldo_origen}
        x=nacionalidad
        y=saldo_1000
        swapXY=true
        sort=false
        yFmt=num1
        fillColor="#0f766e"
        title="Migrazio-saldoa nazionalitatearen arabera (Espainiako 1.000 biztanleko)"
    />
    <BarChart
        data={saldo_paises}
        x=pais
        y=saldo_exterior
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Saldo handiena duten herrialdeak (pertsonak, {flujos.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Saldoa = atzerritik etortzen diren pertsonak ken atzerrira joaten direnak, urtean. INEren Migrazioen eta Bizileku Aldaketen Estatistika 2021ean hasten da egungo metodoarekin; 2021ean pandemiak eragina zuen oraindik. Kolonbia, Venezuela eta Maroko dira ekarpen handiena egiten duten nazionalitateak.</p>

```sql saldo_ccaa
SELECT s.cod, t.nombre AS comunidad, '/eu' || t.ruta AS ruta,
    max(s.saldo_1000) FILTER (WHERE s.nacionalidad = 'Total') AS total_1000,
    max(s.saldo_1000) FILTER (WHERE s.nacionalidad = 'Extranjera') AS extranjeros_1000,
    max(s.saldo_1000) FILTER (WHERE s.nacionalidad = 'Española') AS espanoles_1000,
    max(s.saldo_exterior) FILTER (WHERE s.nacionalidad = 'Total') AS saldo
FROM mother.inmigracion_saldos s
JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = s.cod
WHERE s.nivel = 'ccaa' AND s.anio = (SELECT max(anio) FROM mother.inmigracion_saldos)
GROUP BY ALL
ORDER BY total_1000 DESC
```

<DataTable data={saldo_ccaa} link=ruta rows=all showLinkCol=false>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=total_1000 title="Saldoa 1.000 biz." fmt=num1 contentType=bar barColor="#99f6e4" />
    <Column id=extranjeros_1000 title="…atzerritarrena" fmt=num1 />
    <Column id=espanoles_1000 title="…espainiarrena" fmt=num1 />
    <Column id=saldo title="Saldoa (pertsonak)" fmt=num0 />
</DataTable>

## Etorrera irregularrak

```sql llegadas_mes
SELECT mes, via, personas FROM mother.inmigracion_llegadas ORDER BY mes
```

<BarChart
    data={llegadas_anual}
    x=anio
    y=personas
    series=via
    type=stacked
    yFmt=num0
    xFmt="####"
    colorPalette={['#0f766e', '#1d4ed8', '#b45309']}
    title="Espainiara etorrera irregularrak bidearen arabera (pertsonak urtean)"
/>

<p class="text-xs text-gray-500">Itsasoz penintsulako eta Balear Uharteetako kostaldeetara edo Kanarietara iritsitako pertsonak, eta lurrez Ceutara eta Melillara muga-pasabideetatik kanpo iritsitakoak, Barne Ministerioaren arabera (ACNURek bildua). Azken urtea osatu gabe dago. Kanarietako bideak errekorra ezarri zuen 2024an, eta erdira baino gutxiagora jaitsi zen 2025ean. Immigrazioaren zati txiki bat dira: Espainiara bizitzera datozen gehien-gehienak aireportuetatik eta modu erregularrean etortzen dira (adibidez, ikasketa- edo turista-bisarekin, eta gero erregularizatuz).</p>

## Asiloa

```sql asilo_nac
SELECT nacionalidad, solicitudes
FROM mother.inmigracion_asilo_nacionalidad
WHERE anio = (SELECT max(anio) FROM mother.inmigracion_asilo_nacionalidad)
ORDER BY solicitudes DESC
LIMIT 10
```

<Grid cols=2>
    <BarChart
        data={asilo_anual.filter(d => d.meses === 12)}
        x=anio
        y=valor
        yFmt=num0
        xFmt="####"
        fillColor="#7c3aed"
        title="Lehen asilo-eskaerak urteko"
    />
    <BarChart
        data={asilo_nac}
        x=nacionalidad
        y=solicitudes
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#a78bfa"
        title="Asilo gehien eskatzen duten nazionalitateak ({asilo_nac.length > 0 ? 'azken urtea' : ''})"
    />
</Grid>

<p class="text-xs text-gray-500">Espainian erregistratutako nazioarteko babes-eskaera lehenak (Eurostat). Asiloa eskatzeak ez du esan nahi lortzen denik: zati handi bat ukatu egiten da. Venezuelarrek eta kolonbiarrek aurkezten dituzte eskaera gehienak.</p>

## Naturalizazioak

```sql nac_origen
SELECT nacionalidad_previa, nacionalizaciones
FROM mother.inmigracion_nacionalizaciones
WHERE nivel = 'pais' AND NOT es_grupo AND anio = (SELECT max(anio) FROM mother.inmigracion_nacionalizaciones)
ORDER BY nacionalizaciones DESC
LIMIT 12
```

<Grid cols=2>
    <LineChart
        data={nacionalizaciones}
        x=anio
        y=valor
        yFmt=num1
        xFmt="####"
        lineColor="#0f766e"
        yAxisTitle="1.000 atzerritar egoiliarreko"
        title="Naturalizazioak 1.000 atzerritar egoiliarreko"
    />
    <BarChart
        data={nac_origen}
        x=nacionalidad_previa
        y=nacionalizaciones
        swapXY=true
        sort=false
        yFmt=num0
        fillColor="#14b8a6"
        title="Naturalizatu zirenen aurreko nazionalitatea ({nacionalizaciones.slice(-1)[0]?.anio})"
    />
</Grid>

<p class="text-xs text-gray-500">Espainiako nazionalitatea egoitzagatik, aukeraz edo naturalizazio-gutunaz eskuratzea. Latinoamerikarrek bi urteko egoitza legalaren ondoren eska dezakete (oro har hamar urte behar dira), eta horregatik dira gehiengoa.</p>

---

## Integrazioa: Espainia Europan

```sql integracion_ultimo
SELECT i.*
FROM mother.inmigracion_integracion_europa i
WHERE i.anio = (SELECT max(anio) FROM mother.inmigracion_integracion_europa x WHERE x.indicador = i.indicador AND x.cod_pais = 'ES')
```

```sql integracion_espana
WITH ranking AS (
    SELECT indicador, cod_pais,
           rank() OVER (PARTITION BY indicador ORDER BY coalesce(brecha, extranjeros) * sentido DESC) AS puesto,
           count(*) OVER (PARTITION BY indicador) AS paises
    FROM ${integracion_ultimo}
    WHERE cod_pais <> 'EU27_2020'
)
SELECT e.nombre, e.anio, e.nacionales, e.extranjeros, e.extranjeros_no_ue, e.brecha,
       ue.extranjeros AS ue_extranjeros, ue.brecha AS ue_brecha,
       r.puesto || ' de ' || r.paises AS puesto
FROM ${integracion_ultimo} e
LEFT JOIN ${integracion_ultimo} ue ON ue.indicador = e.indicador AND ue.cod_pais = 'EU27_2020'
LEFT JOIN ranking r ON r.indicador = e.indicador AND r.cod_pais = e.cod_pais
WHERE e.cod_pais = 'ES'
ORDER BY e.orden
```

```sql integracion_resumen
SELECT
    max(anio) AS anio,
    max(extranjeros) FILTER (WHERE indicador = 'empleo') AS empleo_ext,
    max(nacionales) FILTER (WHERE indicador = 'empleo') AS empleo_nac,
    max(extranjeros) FILTER (WHERE indicador = 'arope') AS arope_ext,
    max(nacionales) FILTER (WHERE indicador = 'arope') AS arope_nac,
    max(extranjeros) FILTER (WHERE indicador = 'abandono_escolar') AS abandono_ext,
    max(nacionales) FILTER (WHERE indicador = 'abandono_escolar') AS abandono_nac,
    max(extranjeros) FILTER (WHERE indicador = 'nacionalizaciones') AS nacionalizaciones
FROM ${integracion_ultimo}
WHERE cod_pais = 'ES'
```

```sql integracion_arope
SELECT pais, brecha, CASE WHEN cod_pais = 'ES' THEN 'España' WHEN cod_pais = 'EU27_2020' THEN 'Media de la UE' ELSE 'Otros países' END AS grupo
FROM ${integracion_ultimo}
WHERE indicador = 'arope' AND brecha IS NOT NULL
ORDER BY brecha DESC
```

```sql integracion_empleo
SELECT pais, brecha, CASE WHEN cod_pais = 'ES' THEN 'España' WHEN cod_pais = 'EU27_2020' THEN 'Media de la UE' ELSE 'Otros países' END AS grupo
FROM ${integracion_ultimo}
WHERE indicador = 'empleo' AND brecha IS NOT NULL
ORDER BY brecha
```

Eurostat-ek nazionalak eta atzerritarrak alderatzen ditu enpleguan, pobrezian, ikasketetan eta etxebizitzan Europako herrialde guztietan. Espainian, {urtean(integracion_resumen[0]?.anio)} 20 eta 64 urte arteko atzerritarren % {formatNumber(integracion_resumen[0]?.empleo_ext, 0)} ari zen lanean, espainiarren % {formatNumber(integracion_resumen[0]?.empleo_nac, 0)}ren aldean. Aldea askoz handiagoa da bizi-baldintzetan: atzerritar helduen % {formatNumber(integracion_resumen[0]?.arope_ext, 0)} pobrezia- edo bazterketa-arriskuan zegoen (espainiarren % {formatNumber(integracion_resumen[0]?.arope_nac, 0)}), eta gazte atzerritarren % {formatNumber(integracion_resumen[0]?.abandono_ext, 0)}k goiz utzi zituen ikasketak (espainiarren % {formatNumber(integracion_resumen[0]?.abandono_nac, 0)}). Urtero, bertako 100 atzerritar egoiliarretik {formatNumber(integracion_resumen[0]?.nacionalizaciones, 1)} inguruk hartzen dute nazionalitatea, eta ordutik espainiartzat zenbatzen dira estatistika guztietan.

<DataTable data={integracion_espana} rows=all>
    <Column id=nombre title="Adierazlea" />
    <Column id=anio title="Urtea" fmt="####" />
    <Column id=nacionales title="Espainiarrak" fmt='0.0"%"' />
    <Column id=extranjeros title="Atzerritarrak" fmt='0.0"%"' />
    <Column id=extranjeros_no_ue title="EBtik kanpokoak" fmt='0.0"%"' />
    <Column id=brecha title="Aldea (puntuak)" fmt='+0.0;-0.0' />
    <Column id=ue_brecha title="EBko batez besteko aldea" fmt='+0.0;-0.0' />
    <Column id=puesto title="Espainiaren postua" />
</DataTable>

<p class="text-xs text-gray-500">«Espainiaren postua»: datua duten Europako herrialdeen artean duen tokia, atzerritarren eta nazionalen arteko alderik txikienetik (1) handienera; nazionalizazioetan, tasa altuenetik baxuenera. Eurostat, Espainiak datua duen azken urtea.</p>

<BarChart
    data={integracion_arope}
    x=pais
    y=brecha
    series=grupo
    swapXY=true
    sort=false
    yFmt='+0.0;-0.0'
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#f59e0b', 'Otros países': '#9ca3af'}}
    yAxisTitle="alde-puntuak, atzerritarrak - nazionalak"
    title="Pobrezia- edo bazterketa-arriskua: atzerritarren eta nazionalen arteko aldea ({integracion_resumen[0]?.anio})"
/>

<BarChart
    data={integracion_empleo}
    x=pais
    y=brecha
    series=grupo
    swapXY=true
    sort=false
    yFmt='+0.0;-0.0'
    seriesColors={{'España': '#b91c1c', 'Media de la UE': '#f59e0b', 'Otros países': '#9ca3af'}}
    yAxisTitle="alde-puntuak, atzerritarrak - nazionalak"
    title="Enplegu-tasa (20-64 urte): atzerritarren eta nazionalen arteko aldea ({integracion_resumen[0]?.anio})"
/>

<p class="text-xs text-gray-500">Eurostat-en integrazio-adierazleak nazionalitatearen arabera (herrialde bakoitzeko Biztanleria Aktiboaren Inkesta eta Bizi-baldintzen Inkesta). Nazionalitatea alderatzen dute, ez jaiotza-herrialdea: nazionalitatea hartu duten etorkinak nazionaltzat zenbatzen dira, eta horrek pisu handiagoa du jende gehiagok nazionalitatea hartzen duen herrialdeetan. Eurostat-en estatistikak EBko atzerritarrak eta EBtik kanpokoak baino ez ditu bereizten; jatorriaren araberako delinkuentzia <a class="underline" href="/eu/sociedad/criminalidad/#jatorriaren-arabera">Kriminalitatea</a> orrian dago.</p>

## Iturriak eta oharrak

- **[INE – Biztanleriaren Estatistika Jarraitua](https://www.ine.es/jaxiT3/Tabla.htm?t=56942)** (56942 taula): biztanleria nazionalitatearen arabera, urtarrilaren 1ean.
- **[INE – Migrazioen eta Bizileku Aldaketen Estatistika](https://www.ine.es/dyngs/INEbase/es/operacion.htm?c=Estadistica_C&cid=1254736177000)** (69687, 69702, 69758 eta 69762 taulak): immigrazioak, emigrazioak eta saldoak 2021etik.
- **Barne Ministerioa**, immigrazio irregularrari buruzko hamabosteroko txostena, **[ACNURen datu-atariaren](https://data.unhcr.org/en/situations/europe-sea-arrivals/location/24522)** bidez.
- **[Eurostat – migr_asyappctzm eta migr_asyappctza](https://ec.europa.eu/eurostat/databrowser/view/migr_asyappctzm/default/table)**: lehen asilo-eskaerak.
- **[INE – Egoiliarrek Espainiako nazionalitatea eskuratzea](https://www.ine.es/jaxiT3/Tabla.htm?t=70012)** (70012 taula).
- **[Eurostat – Migratzaileen integrazioa](https://ec.europa.eu/eurostat/web/migrant-integration)**: enplegua (lfsa_ergan), langabezia (lfsa_urgan), pobrezia- edo bazterketa-arriskua (ilc_peps05n), eskola-uztea (edat_lfse_01), gaikualifikazioa (lfsa_eoqgan) eta pilaketa (ilc_lvho15) nazionalitatearen arabera, eta nazionalitate-eskurapenak (migr_acq) atzerritar biztanleriaren artean (migr_pop1ctz).
- Kriminalitateari buruzko datuak nazionalitatearen arabera hemen daude: [Kriminalitatea](/eu/sociedad/criminalidad), haien testuinguruarekin.

<LastRefreshed prefix="Datuak eguneratuta" />
