---
title: Etxebizitzaren prezioa
description: "Etxebizitzaren prezioa Espainian inflazioa kenduta: metro koadroko tasazio-balioa erkidego, probintzia eta udalerriaren arabera, eta INEren Etxebizitzaren Prezioen Indizea, berria eta bigarren eskukoa."
i18n_origen: 44b0921ad358
---

<script>
    import MapaEspana from '../../../../../../../src/lib/components/MapaEspana.svelte';
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
    // Urteen atzizkiak (euskara): 2021ean, 2022an, 2011n · 2021eko, 2022ko · 2010etik, 2020tik
    const urteK = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return [1, 5, 10, 15].includes(k); };
    const urteN = (y) => { const n = Number(y) % 100, k = n < 20 ? n : n % 20; return k === 11 || (n === 0 && Number(y) % 1000 === 0); };
    const urtean = (y) => (y == null ? String() : `${y}${urteN(y) ? 'n' : urteK(y) ? 'ean' : 'an'}`);
    const urteko = (y) => (y == null ? String() : `${y}${urteK(y) ? 'eko' : 'ko'}`);
    const urtetik = (y) => (y == null ? String() : `${y}${urteK(y) ? 'etik' : 'tik'}`);
    const urtera = (y) => (y == null ? String() : `${y}${urteK(y) ? 'era' : 'ra'}`);
</script>

```sql precio
SELECT fecha, periodo, anio, euros_m2, euros_m2_real, precio_90m2_real, interanual_real, interanual_nominal, anio_base
FROM mother.vivienda_precio_tasado
WHERE nivel = 'pais' AND euros_m2_real IS NOT NULL
ORDER BY fecha
```

```sql ipv
SELECT fecha, periodo, tipo, indice, indice_real, interanual_real, interanual_nominal
FROM mother.vivienda_ipv
WHERE nivel = 'pais'
ORDER BY fecha, tipo
```

```sql ipv_general
SELECT * FROM ${ipv} WHERE tipo = 'General' ORDER BY fecha
```

```sql ipv_interanual
SELECT fecha, 'Nominal' AS tipo, interanual_nominal AS variacion FROM ${ipv_general} WHERE interanual_nominal IS NOT NULL
UNION ALL
SELECT fecha, 'Real' AS tipo, interanual_real AS variacion FROM ${ipv_general} WHERE interanual_real IS NOT NULL
ORDER BY fecha, tipo
```

```sql ipv_hitos
SELECT
    arg_max(periodo, fecha) AS periodo_ult,
    arg_max(indice_real, fecha) AS real_ult,
    max(indice_real) AS real_max,
    arg_max(periodo, indice_real) AS periodo_max,
    100 * (arg_max(indice_real, fecha) / max(indice_real) - 1) AS vs_max,
    100 * (arg_max(indice, fecha) / max(indice) - 1) AS vs_max_nominal
FROM ${ipv_general}
```

```sql nueva_usada
SELECT
    max(interanual_real) FILTER (WHERE tipo = 'Nueva') AS nueva,
    max(interanual_real) FILTER (WHERE tipo = 'Segunda mano') AS usada,
    max(periodo) AS periodo
FROM ${ipv}
WHERE fecha = (SELECT max(fecha) FROM ${ipv})
```

```sql lista_ccaa
SELECT cod, nombre FROM mother.vivienda_resumen_territorios WHERE nivel = 'ccaa' ORDER BY nombre
```

<Dropdown name=ccaa_precio data={lista_ccaa} value=cod label=nombre defaultValue="13" title="Erkidegoa" />

```sql ccaa_serie
SELECT fecha, nombre, euros_m2_real
FROM mother.vivienda_precio_tasado
WHERE euros_m2_real IS NOT NULL
  AND ((nivel = 'ccaa' AND cod = '${inputs.ccaa_precio.value}') OR nivel = 'pais')
ORDER BY fecha, nombre
```

```sql provincias
SELECT r.cod AS cod_prov, r.nombre AS provincia, '/eu' || r.ruta AS ruta, r.precio_periodo, r.euros_m2_real, r.precio_90m2_real,
       r.precio_interanual_real, r.precio_vs_maximo_real, r.precio_periodo_maximo
FROM mother.vivienda_resumen_territorios r
WHERE r.nivel = 'provincia'
ORDER BY r.euros_m2_real DESC
```

```sql prov_extremos
SELECT
    arg_max(provincia, euros_m2_real) AS cara,
    max(euros_m2_real) AS cara_valor,
    arg_min(provincia, euros_m2_real) AS barata,
    min(euros_m2_real) AS barata_valor,
    max(euros_m2_real) / min(euros_m2_real) AS veces,
    count(*) FILTER (WHERE precio_vs_maximo_real >= 0) AS en_maximos,
    max(precio_periodo) AS periodo
FROM ${provincias}
```

```sql municipios
SELECT m.municipio, p.nombre AS provincia, m.poblacion, m.euros_m2_real, m.precio_90m2_real, m.variacion_real, m.tasaciones, m.anio
FROM mother.vivienda_precio_municipios m
LEFT JOIN mother.territorios p ON p.nivel = 'provincia' AND p.cod = m.cod_prov
WHERE m.anio = (SELECT max(anio) FROM mother.vivienda_precio_municipios WHERE trimestres = 4)
ORDER BY m.euros_m2_real DESC
```

# 💶 Etxebizitzaren prezioa

Zenbat balio duen Espainian etxebizitza bat erosteak eta nola aldatu den. Elkar osatzen duten bi iturri ofizial daude: Etxebizitza Ministerioaren **tasazio-balioa**, metro koadroko euroak ematen dituena eta probintzia eta udalerrietaraino iristen dena, eta INEren **Etxebizitzaren Prezioen Indizea**, eskrituratutako salerosketen prezioei kalitate konstantean jarraitzen diena. Dena **inflazioa kenduta** erakusten da, {urteko(precio[0]?.anio_base)} eurotan.

<Grid cols=4>
    <KpiCard
        title="Tasazio-balioa"
        value={precio.slice(-1)[0]?.euros_m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.euros_m2_real, 0)} €/m²"
        period="Espainia, {precio.slice(-1)[0]?.periodo} · {formatNumber(precio.slice(-1)[0]?.euros_m2, 0)} €/m² inflazioa kendu gabe"
        change={precio.slice(-1)[0]?.interanual_real?.toFixed(1)}
        changePeriod="erreala, urtebete lehenagorekiko"
        source="Etxebizitza Ministerioa"
        sparklineData={precio.map(d => ({...d, y: d.euros_m2_real}))}
    />
    <KpiCard
        title="Prezioen igoera erreala"
        value={ipv_general.slice(-1)[0]?.interanual_real}
        formattedValue="{ipv_general.slice(-1)[0]?.interanual_real >= 0 ? '+' : ''}{formatNumber(ipv_general.slice(-1)[0]?.interanual_real, 1)} %"
        period="IPV, {ipv_general.slice(-1)[0]?.periodo}, urtebete lehenagorekiko · {formatNumber(ipv_general.slice(-1)[0]?.interanual_nominal, 1)} % inflazioa kendu gabe"
        source="INE / IPV"
        sparklineData={ipv_general.filter(d => d.interanual_real != null).map(d => ({...d, y: d.interanual_real}))}
    />
    <KpiCard
        title="Burbuilaren gehienekoarekiko"
        value={ipv_hitos[0]?.vs_max}
        formattedValue="{ipv_hitos[0]?.vs_max >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max, 1)} %"
        period="prezio erreala, {ipv_hitos[0]?.periodo_max} aldiarekiko (IPV) · {ipv_hitos[0]?.vs_max_nominal >= 0 ? '+' : ''}{formatNumber(ipv_hitos[0]?.vs_max_nominal, 1)} % urte bakoitzeko eurotan"
        source="INE / IPV"
        sparklineData={ipv_general.map(d => ({...d, y: d.indice_real}))}
    />
    <KpiCard
        title="90 m²-ko pisua"
        value={precio.slice(-1)[0]?.precio_90m2_real}
        formattedValue="{formatNumber(precio.slice(-1)[0]?.precio_90m2_real / 1000, 0)} mila €"
        period="Espainiako batez besteko tasazio-balioan, {precio.slice(-1)[0]?.periodo}"
        source="Etxebizitza Ministerioa"
        sparklineData={precio.map(d => ({...d, y: d.precio_90m2_real}))}
    />
</Grid>

## Prezioaren bilakaera erreala

INEren Etxebizitzaren Prezioen Indizea, inflazioa kenduta (2015 = 100). 2007an hasten den seriearen gehieneko erreala {ipv_hitos[0]?.periodo_max} aldikoa da; {ipv_hitos[0]?.periodo_ult} aldian, prezio erreala {#if ipv_hitos[0]?.vs_max < 0}{formatNumber(-ipv_hitos[0]?.vs_max, 1)} % azpitik dago{:else}gehienekoetan dago{/if}. Azken hiruhilekoan, etxebizitza berria {formatNumber(nueva_usada[0]?.nueva, 1)} % igo zen termino errealetan, eta bigarren eskukoa {formatNumber(nueva_usada[0]?.usada, 1)} %.

<LineChart
    data={ipv}
    x=fecha
    y=indice_real
    series=tipo
    yFmt='0.0'
    yAxisTitle="indize erreala, 2015 = 100"
    startingAtZero={false}
    title="Etxebizitzaren Prezioen Indizea, inflazioa kenduta (2015 = 100)"
/>

<BarChart
    data={ipv_interanual}
    x=fecha
    y=variacion
    series=tipo
    type=grouped
    yFmt='0.0"%"'
    yAxisTitle="urte arteko %"
    title="Etxebizitzaren prezioaren urte arteko aldaketa: nominala eta erreala (IPV orokorra)"
/>

## Erkidegoka

Aukeratutako erkidegoaren metro koadroko tasazio-balioa Espainiarekin alderatuta, {urteko(precio[0]?.anio_base)} eurotan.

<LineChart
    data={ccaa_serie}
    x=fecha
    y=euros_m2_real
    series=nombre
    yFmt='#,##0" €"'
    yAxisTitle="€/m² (errealak)"
    startingAtZero={false}
    title="Tasazio-balio erreala: erkidegoa Espainiarekin alderatuta"
/>

## Probintziaka

{prov_extremos[0]?.periodo} aldian, metro koadro garestiena duen probintzia {prov_extremos[0]?.cara} da ({formatNumber(prov_extremos[0]?.cara_valor, 0)} €/m²), eta merkeena, {prov_extremos[0]?.barata} ({formatNumber(prov_extremos[0]?.barata_valor, 0)} €/m²): lehenengoan metro koadroak {formatNumber(prov_extremos[0]?.veces, 1)} aldiz gehiago balio du. {#if prov_extremos[0]?.en_maximos == 1}Probintzia bakar bat dago{:else}{prov_extremos[0]?.en_maximos} probintzia daude{/if} 2002az geroztiko bere gehieneko errealean.

<MapaEspana
    data={provincias}
    geoJsonUrl="/geo/provincias.geojson"
    geoId="cod_prov"
    areaCol="cod_prov"
    value="euros_m2_real"
    valueFmt='#,##0" €"'
    link="ruta"
    colorPalette={['#fef3c7', '#f59e0b', '#92400e']}
    height={460}
    basemap="https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{'{z}'}/{'{y}'}/{'{x}'}"
    attribution="Lauzak © Esri · Mugak © Instituto Geográfico Nacional · Datuak: Etxebizitza Ministerioa"
    tooltip={[
        {id: 'provincia', showColumnName: false, valueClass: 'text-base font-semibold'},
        {id: 'euros_m2_real', title: '€/m²', fmt: '#,##0'},
        {id: 'precio_interanual_real', title: 'Urteko aldaketa erreala (%)', fmt: '0.0'},
        {id: 'precio_vs_maximo_real', title: 'Bere gehieneko errealarekiko (%)', fmt: '0.0'}
    ]}
/>

<DataTable data={provincias} rows=10 search=true link=ruta>
    <Column id=provincia title="Probintzia" />
    <Column id=euros_m2_real title="€/m² (erreala)" fmt='#,##0' />
    <Column id=precio_90m2_real title="90 m²-ko pisua (€)" fmt='#,##0' />
    <Column id=precio_interanual_real title="Urteko aldaketa erreala %" fmt='0.0' contentType=delta />
    <Column id=precio_vs_maximo_real title="Gehieneko errealarekiko %" fmt='0.0' />
    <Column id=precio_periodo_maximo title="Gehieneko erreala" />
</DataTable>

## 25.000 biztanletik gorako udalerriak

{urteko(municipios[0]?.anio)} batez besteko tasazio-balioa (lau hiruhilekoen batez bestekoa, tasazio kopuruaren arabera haztatua), {urteko(precio[0]?.anio_base)} eurotan. Tasazio gutxirekin, datua ez da hain fidagarria.

<DataTable data={municipios} rows=15 search=true>
    <Column id=municipio title="Udalerria" />
    <Column id=provincia title="Probintzia" />
    <Column id=euros_m2_real title="€/m² (erreala)" fmt='#,##0' />
    <Column id=precio_90m2_real title="90 m²-ko pisua (€)" fmt='#,##0' />
    <Column id=variacion_real title="Urteko aldaketa erreala %" fmt='0.0' contentType=delta />
    <Column id=tasaciones title="Tasazioak" fmt='#,##0' />
    <Column id=poblacion title="Biztanleak" fmt='#,##0' />
</DataTable>

---

**Iturriak:** [Garraio eta Hiri Agendako Ministerioa, etxebizitza libreen tasazio-balioa](https://apps.fomento.gob.es/BoletinOnline2/?nivel=2&orden=35000000) (1. eta 5. taulak, hipoteka-tasazioetatik abiatuta; etxebizitza libre guztien batez besteko balioa, berria eta erabilia) eta [INE, Etxebizitzaren Prezioen Indizea, 25171 taula](https://www.ine.es/jaxiT3/Tabla.htm?t=25171) (2015 oinarria, notario-salerosketetatik abiatuta). INEren KPI orokorrarekin deflaktatuak (2025 oinarria), hiruhilekoz hiruhileko.
