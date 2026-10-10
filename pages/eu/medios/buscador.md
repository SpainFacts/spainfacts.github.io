---
title: Nork zer jasotzen duen
description: "Komunikabideen bilatzailea: komunikabide bakoitzak (OKDiario, Libertad Digital, El País, SER, La Vanguardia...) administrazio guztietatik jaso duen diru publiko guztia, bidearen (erakunde-publizitatea, kontratuak eta diru-laguntzak), urtearen eta ordaintzen duen administrazioaren arabera, gaurko euroetan."
i18n_origen: 42aa55cbac73
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
</script>

```sql lista_medios
SELECT medio_id,
       medio || CASE WHEN titularidad = 'publica' THEN ' (medio público)'
                     WHEN es_plataforma THEN ' (plataforma digital)'
                     ELSE '' END AS etiqueta,
       total_eur_real
FROM mother.medios_receptores_totales
ORDER BY total_eur_real DESC
```

```sql sel
SELECT medio_id, medio, grupo, tipo_medio, titularidad, es_plataforma, en_ranking,
       total_eur_real, total_eur_nominal, total_2019_2025_eur_real,
       coalesce(estado_institucional_eur_real, 0) + coalesce(estado_comercial_eur_real, 0) AS estado_eur_real,
       coalesce(territorial_eur_real, 0) AS territorial_eur_real,
       coalesce(estado_institucional_eur_real, 0) + coalesce(estado_comercial_eur_real, 0) + coalesce(territorial_eur_real, 0) AS publicidad_eur_real,
       coalesce(contratos_eur_real, 0) AS contratos_eur_real,
       coalesce(subvenciones_eur_real, 0) AS subvenciones_eur_real,
       coalesce(contratos_eur_real, 0) + coalesce(subvenciones_eur_real, 0) AS contratos_subv_eur_real,
       CAST(n_pagos_total AS INTEGER) AS n_pagos,
       CAST(n_administraciones_total AS INTEGER) AS n_admin,
       CAST(n_gobiernos_total AS INTEGER) AS n_gob,
       CAST(anio_min AS INTEGER) AS anio_min,
       CAST(anio_max AS INTEGER) AS anio_max,
       CAST(rango_privados AS INTEGER) AS rango_privados,
       CAST(rango_publicos AS INTEGER) AS rango_publicos,
       niveles_asignacion,
       (SELECT count(*) FROM mother.medios_receptores_totales WHERE en_ranking) AS n_ranking
FROM mother.medios_receptores_totales
WHERE medio_id = '${inputs.medio.value}'
```

```sql sel_anual
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (osatu gabea)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo, via, importe_eur_real, importe_eur_nominal, CAST(n_pagos AS INTEGER) AS pagos
FROM mother.medios_receptores_resumen
WHERE medio_id = '${inputs.medio.value}'
ORDER BY anio, via
```

```sql sel_serie
SELECT CAST(anio AS INTEGER) AS anio,
       sum(importe_eur_real) AS total,
       coalesce(sum(importe_eur_real) FILTER (WHERE via LIKE 'Publicidad%'), 0) AS publicidad,
       coalesce(sum(importe_eur_real) FILTER (WHERE via IN ('Contrato', 'Subvención')), 0) AS contratos_subv,
       count(DISTINCT administracion) AS n_admin
FROM mother.medios_receptores
WHERE medio_id = '${inputs.medio.value}' AND anio < year(current_date)
GROUP BY 1
ORDER BY 1
```

```sql sel_mejor_anio
SELECT anio, total FROM ${sel_serie} ORDER BY total DESC LIMIT 1
```

```sql quien_paga
SELECT gobierno, administracion, via, string_agg(DISTINCT partido, ', ') AS partido,
       sum(importe_eur_real) AS importe_eur_real,
       sum(importe_eur_nominal) AS importe_eur_nominal,
       count(*) AS pagos,
       CAST(min(anio) AS INTEGER) AS desde,
       CAST(max(anio) AS INTEGER) AS hasta
FROM mother.medios_receptores
WHERE medio_id = '${inputs.medio.value}'
GROUP BY ALL
ORDER BY importe_eur_real DESC
```

```sql por_gobierno
SELECT gobierno, string_agg(DISTINCT partido, ', ') AS partido, sum(importe_eur_real) AS importe_eur_real, sum(pagos) AS pagos,
       100 * sum(importe_eur_real) / (SELECT sum(importe_eur_real) FROM ${quien_paga}) AS pct
FROM ${quien_paga}
GROUP BY gobierno
ORDER BY importe_eur_real DESC
```

```sql por_partido
SELECT coalesce(r.partido, 'Sin dato (diputaciones y otras entidades locales)') AS partido,
       coalesce(any_value(f.color), '#94a3b8') AS color,
       sum(r.importe_eur_real) AS importe_eur_real, count(*) AS pagos,
       count(DISTINCT r.gobierno) AS administraciones,
       100 * sum(r.importe_eur_real) / (SELECT sum(importe_eur_real) FROM mother.medios_receptores WHERE medio_id = '${inputs.medio.value}') AS pct
FROM mother.medios_receptores r
LEFT JOIN (SELECT familia, any_value(color) AS color FROM mother.alcaldes_historia WHERE color IS NOT NULL GROUP BY familia) f ON f.familia = r.partido
WHERE r.medio_id = '${inputs.medio.value}'
GROUP BY 1
ORDER BY importe_eur_real DESC
```

```sql por_partido_anio
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (osatu gabea)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo, coalesce(partido, 'Sin dato') AS partido, sum(importe_eur_real) AS importe_eur_real
FROM mother.medios_receptores
WHERE medio_id = '${inputs.medio.value}'
GROUP BY ALL
ORDER BY anio, partido
```

```sql detalle
SELECT CAST(anio AS INTEGER) AS anio, gobierno, coalesce(partido, '—') AS partido, administracion, via,
       coalesce(concepto, '(la fuente no indica la campaña)') AS concepto,
       importe_eur_real, importe_eur_nominal,
       CASE WHEN iva_incluido THEN 'Con IVA' WHEN NOT iva_incluido THEN 'Sin IVA' ELSE 'No consta' END AS iva,
       base, nombre_fuente,
       CASE nivel_asignacion WHEN 'cabecera' THEN 'Cabecera' WHEN 'sociedad' THEN 'Sociedad editora' ELSE 'Grupo' END AS asignado_por,
       url
FROM mother.medios_receptores
WHERE medio_id = '${inputs.medio.value}'
ORDER BY anio DESC, importe_eur_real DESC
```

```sql duplicados
SELECT count(*) AS n, coalesce(sum(importe_eur_real), 0) AS importe_eur_real
FROM mother.medios_receptores_duplicados
WHERE medio_id = '${inputs.medio.value}'
```

```sql relacionados
SELECT medio, tipo_medio, total_2019_2025_eur_real, total_eur_real
FROM mother.medios_receptores_totales
WHERE grupo = (SELECT grupo FROM ${sel}) AND medio_id <> '${inputs.medio.value}'
ORDER BY total_eur_real DESC
```

```sql ranking
SELECT CAST(rango_privados AS INTEGER) AS puesto, medio, grupo,
       total_2019_2025_eur_real, total_eur_real,
       coalesce(estado_institucional_eur_real, 0) + coalesce(estado_comercial_eur_real, 0) AS estado_eur_real,
       coalesce(territorial_eur_real, 0) AS territorial_eur_real,
       coalesce(contratos_eur_real, 0) AS contratos_eur_real,
       coalesce(subvenciones_eur_real, 0) AS subvenciones_eur_real,
       CAST(n_administraciones_total AS INTEGER) AS administraciones
FROM mother.medios_receptores_totales
WHERE en_ranking
ORDER BY puesto
```

```sql ranking_grupos
SELECT grupo, count(*) AS entradas, sum(total_2019_2025_eur_real) AS total_2019_2025_eur_real,
       sum(estado_eur_real) AS estado_eur_real, sum(territorial_eur_real) AS territorial_eur_real,
       sum(contratos_eur_real) AS contratos_eur_real, sum(subvenciones_eur_real) AS subvenciones_eur_real
FROM ${ranking}
GROUP BY grupo
ORDER BY total_2019_2025_eur_real DESC NULLS LAST
LIMIT 25
```

```sql publicos
SELECT CAST(rango_publicos AS INTEGER) AS puesto, medio, total_2019_2025_eur_real, total_eur_real,
       coalesce(estado_institucional_eur_real, 0) + coalesce(estado_comercial_eur_real, 0) AS estado_eur_real,
       coalesce(territorial_eur_real, 0) AS territorial_eur_real,
       coalesce(contratos_eur_real, 0) AS contratos_eur_real
FROM mother.medios_receptores_totales
WHERE titularidad = 'publica'
ORDER BY puesto
```

```sql global
SELECT
    (SELECT count(*) FROM ${ranking}) AS n_privados,
    (SELECT sum(total_2019_2025_eur_real) FROM ${ranking}) AS total_privados,
    (SELECT medio FROM ${ranking} ORDER BY puesto LIMIT 1) AS primero,
    (SELECT total_2019_2025_eur_real FROM ${ranking} ORDER BY puesto LIMIT 1) AS primero_eur,
    (SELECT 100 * sum(total_2019_2025_eur_real) FILTER (WHERE puesto <= 10) / sum(total_2019_2025_eur_real) FROM ${ranking}) AS pct_top10
```

```sql cobertura
SELECT via, CAST(min(anio) AS INTEGER) AS desde, CAST(max(anio) AS INTEGER) AS hasta, count(*) AS pagos,
       sum(importe_eur_real) AS importe_eur_real
FROM mother.medios_receptores
GROUP BY via
ORDER BY importe_eur_real DESC
```
# <span aria-hidden="true">🔎</span> Nork zer jasotzen duen

Aukeratu komunikabide bat, eta datua argitaratzen duten administrazio publikoetatik kobratu duen guztia ikusiko duzu: Estatua eta haren enpresak, autonomia-erkidegoak, udalak eta aldundiak. Hiru bide batzen dira: **erakunde-publizitatea** (kanpainak), **kontratuak** (babesletzak, txertaketak, harpidetzak, bereziak) eta **diru-laguntzak**. Zifra guztiak **inflazioa kenduta** ematen dira, 2025eko euroetan; urte bakoitzeko zenbatekoak, ordaindu ziren bezala, xehetasunen taulan daude.

<Dropdown data={lista_medios} name=medio value=medio_id label=etiqueta title="Komunikabidea" defaultValue="okdiario" />

{#if sel.length}

## {sel[0].medio}

{#if sel[0].tipo_medio === 'grupo'}
<p>Sarrera honek iturriek <strong>{sel[0].grupo}</strong> taldeari egozten diotena biltzen du, zein buruari dagokion esan gabe: Estatuaren publizitate-txostena, hainbat marka batera argitaratzen dituzten sozietateak edo taldearen izenean egindako kanpainak. Buru bakoitzari esleitu dakiokeena haren sarreran dago (behean).</p>
{:else if sel[0].tipo_medio === 'plataforma'}
<p><strong>{sel[0].medio}</strong> ez da komunikabide bat, plataforma digital bat baizik: administrazioek bertan publizitatea erosten dutelako agertzen da. Ez dago komunikabideen rankingean.</p>
{:else}
<p>Taldea: <strong>{sel[0].grupo}</strong>.{#if sel[0].titularidad === 'publica'} <strong>Komunikabide publikoa</strong> da: publizitateagatik edo kontratuengatik jasotzen duena haren aurrekontuek dagoeneko ordaintzen diotenari gehitzen zaio, eta hori ez dago hemen sartuta (<a href="/eu/medios/dinero-publico">Diru publikoa komunikabideetan</a> orrian dago).{/if}</p>
{/if}

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    <KpiCard
        title="Jasotakoa guztira"
        value={sel[0].total_eur_real}
        formattedValue={formatCompact(sel[0].total_eur_real, 2) + ' €'}
        unit="2025eko euroak"
        period={`${sel[0].anio_min}-${sel[0].anio_max} · ${formatNumber(sel[0].n_pagos, 0)} ordainketa · ${formatCompact(sel[0].total_eur_nominal, 2)} € korronte`}
        source="SpainFacts, CPCI, erkidego, udal, PLACSP eta BDNSren datuekin"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.total}))}
    />
    <KpiCard
        title="Erakunde-publizitatea"
        value={sel[0].publicidad_eur_real}
        formattedValue={formatCompact(sel[0].publicidad_eur_real, 2) + ' €'}
        unit="2025eko euroak"
        period={`Estatua: ${formatCompact(sel[0].estado_eur_real, 2)} € · erkidegoak eta udalak: ${formatCompact(sel[0].territorial_eur_real, 2)} €`}
        source="CPCI (2025), erkidegoak eta udalak"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.publicidad}))}
    />
    <KpiCard
        title="Kontratuak eta diru-laguntzak"
        value={sel[0].contratos_subv_eur_real}
        formattedValue={formatCompact(sel[0].contratos_subv_eur_real, 2) + ' €'}
        unit="2025eko euroak"
        period={`Kontratuak: ${formatCompact(sel[0].contratos_eur_real, 2)} € · diru-laguntzak: ${formatCompact(sel[0].subvenciones_eur_real, 2)} €`}
        source="PLACSP eta BDNS"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.contratos_subv}))}
    />
    <KpiCard
        title="Ordaintzen duten administrazioak"
        value={sel[0].n_admin}
        formattedValue={formatNumber(sel[0].n_admin, 0)}
        unit="organo desberdin"
        period={`${formatNumber(sel[0].n_gob, 0)} administraziotakoak (Estatua, erkidegoak, udalak...)`}
        source="SpainFacts"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.n_admin}))}
    />
</div>

{#if sel[0].en_ranking}
<p>{formatNumber(sel[0].n_ranking, 0)} komunikabide pribaturen artean, <strong>{sel[0].rango_privados}.</strong> postuan dago 2019 eta 2025 artean jasotako diru publikoagatik ({formatCompact(sel[0].total_2019_2025_eur_real, 2)} € gaurkoak). {#if sel_mejor_anio.length}Gehien jaso zuen urtea {sel_mejor_anio[0].anio} izan zen, {formatCompact(sel_mejor_anio[0].total, 2)} €-rekin.{/if}</p>
{:else if sel[0].titularidad === 'publica'}
<p>Komunikabide publikoen artean, <strong>{sel[0].rango_publicos}.</strong> postuan dago bide horietatik 2019 eta 2025 artean jasotakoagatik.</p>
{/if}

### Urteka eta bideka

<BarChart
    data={sel_anual}
    x=periodo
    sort=false
    y=importe_eur_real
    series=via
    type=stacked
    yFmt='#,##0" €"'
    yAxisTitle="2025eko euroak"
    seriesColors={{'Publicidad institucional del Estado': '#1d4ed8', 'Publicidad comercial de empresas del Estado': '#60a5fa', 'Publicidad institucional autonómica/local': '#f59e0b', 'Contrato': '#10b981', 'Subvención': '#a855f7'}}
    title="Jasotako diru publikoa urteka eta bideka, 2025eko euroak"
/>

Barrak ezin dira urte batetik bestera alderatu osoak balira bezala: Estatuak 2025etik bakarrik argitaratzen du komunikabideko banaketa, eta erkidego bakoitza urte desberdin batean hasi zen argitaratzen (ikus oharrak). Aurtengo urtea «osatu gabea» gisa markatuta agertzen da.

### Nork ordaintzen duen

{#if por_gobierno.length}
<p>Gehien ordaindu duena <strong>{por_gobierno[0].gobierno}</strong> da, {formatCompact(por_gobierno[0].importe_eur_real, 2)} €-rekin (guztizkoaren {formatNumber(por_gobierno[0].pct, 0)} %), {formatNumber(por_gobierno[0].pagos, 0)} ordainketatan.</p>
{/if}

<DataTable data={por_gobierno} rows=10>
    <Column id=gobierno title="Administrazioa" />
    <Column id=partido title="Gobernatzen zuen alderdia" />
    <Column id=importe_eur_real title="2025eko euroak" fmt='#,##0' />
    <Column id=pct title="Guztizkoaren %" fmt='0.0' />
    <Column id=pagos title="Ordainketak" fmt='#,##0' />
</DataTable>

Ordaintzen duen organoaren (sail, udal, enpresa publiko, ministerio...) eta bidearen araberako banakapena:

<DataTable data={quien_paga} rows=15 search=true>
    <Column id=administracion title="Ordaintzen duen organoa" wrap=true />
    <Column id=gobierno title="Administrazioa" wrap=true />
    <Column id=partido title="Alderdia" wrap=true />
    <Column id=via title="Bidea" wrap=true />
    <Column id=importe_eur_real title="2025eko euroak" fmt='#,##0' />
    <Column id=pagos title="Ordainketak" fmt='#,##0' />
    <Column id=desde title="Noiztik" fmt='0' />
    <Column id=hasta title="Noiz arte" fmt='0' />
</DataTable>

### Gobernatzen zuen alderdiaren arabera

Ordainketa bakoitza urte horretako uztailaren 1ean ordaintzen duen administrazioa gobernatzen zuen alderdiari egozten zaio: Espainiako Gobernuari Estatuarentzat eta haren enpresentzat, autonomia-gobernuari erkidegoentzat eta alkatetzari udalentzat. Aldundiak, kabildoak eta beste toki-erakunde batzuk daturik gabe geratzen dira. Ez du esaten nork erabaki zuen kanpaina bakoitza, nork gobernatzen zuen baizik.

<DataTable data={por_partido} rows=8>
    <Column id=partido title="Gobernatzen zuen alderdia" />
    <Column id=importe_eur_real title="2025eko euroak" fmt='#,##0' />
    <Column id=pct title="Guztizkoaren %" fmt='0.0' />
    <Column id=pagos title="Ordainketak" fmt='#,##0' />
    <Column id=administraciones title="Administrazioak" fmt='0' />
</DataTable>

<BarChart
    data={por_partido_anio}
    x=periodo
    sort=false
    y=importe_eur_real
    series=partido
    yFmt='#,##0'
    yAxisTitle="2025eko euroak"
    seriesColors={Object.fromEntries(por_partido.map(d => [d.partido.startsWith('Sin dato') ? 'Sin dato' : d.partido, d.color]))}
    title="Urtero jasotako diru publikoa, ordaintzen duen administrazioa gobernatzen zuen alderdiaren arabera"
/>

### Ordainketa bakoitza

Errenkada bat kanpaina, kontratu edo diru-laguntza bakoitzeko, iturriak idazten duen kontzeptuarekin. Sakatu esteka duen errenkada bat kontratuaren espedientera edo diru-laguntzaren deialdira joateko.

<DataTable data={detalle} rows=20 search=true link=url>
    <Column id=anio title="Urtea" fmt='0' />
    <Column id=administracion title="Nork ordaintzen duen" wrap=true />
    <Column id=partido title="Gobernatzen zuena" />
    <Column id=via title="Bidea" wrap=true />
    <Column id=concepto title="Kontzeptua" wrap=true />
    <Column id=importe_eur_real title="2025eko euroak" fmt='#,##0' />
    <Column id=importe_eur_nominal title="Urteko euroak" fmt='#,##0' />
    <Column id=iva title="BEZ" />
    <Column id=nombre_fuente title="Izena iturrian" wrap=true />
    <Column id=asignado_por title="Nola identifikatua" />
</DataTable>

{#if duplicados.length && duplicados[0].n > 0}
<p>Ez dira batzen beste {formatNumber(duplicados[0].n, 0)} publizitate-kontratu ({formatCompact(duplicados[0].importe_eur_real, 2)} €), urte horretan beren publizitatea komunikabideka argitaratzen duten erkidego edo udalenak: ia ziur taulan dauden kanpaina berak dira.</p>
{/if}

{#if relacionados.length && sel[0].tipo_medio !== 'plataforma'}
### Talde bereko beste sarrera batzuk

Iturriek **{sel[0].grupo}** taldearen beste buru batzuei, haren sozietateei edo taldeari bereizi gabe egozten dietena. Taldeak jasotzen duen guztia jakiteko, batu egin behar dira.

<DataTable data={relacionados} rows=10>
    <Column id=medio title="Sarrera" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025, 2025eko euroak" fmt='#,##0' />
    <Column id=total_eur_real title="Urte guztiak" fmt='#,##0' />
</DataTable>
{/if}

{/if}

## Komunikabide pribatuen rankinga

Ordainketaren bat identifikatuta duten {formatNumber(global[0]?.n_privados, 0)} komunikabide pribatuak, 2019 eta 2025 artean jasotakoaren arabera ordenatuta, gaurko euroetan. Lehena **{global[0]?.primero}** da ({formatCompact(global[0]?.primero_eur, 2)} €), eta lehen hamarrek guztizkoaren {formatNumber(global[0]?.pct_top10, 0)} % eramaten dute. Sarrera batzuk talde bat edo hainbat buru dituen sozietate bat dira, iturriak ez dituelako bereizten.

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=medio title="Komunikabidea" wrap=true />
    <Column id=grupo title="Taldea" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Estatuaren publizitatea" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publizitate autonomikoa eta lokala" fmt='#,##0' />
    <Column id=contratos_eur_real title="Kontratuak" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Diru-laguntzak" fmt='#,##0' />
    <Column id=administraciones title="Ordaintzen duten organoak" fmt='0' />
</DataTable>

### Taldeka

Talde bakoitzeko sarrera guztiak batuta (buruak, sozietateak eta bereizi ezin dena). Bideak urte guztietakoak dira; guztizkoa, 2019tik 2025era.

<DataTable data={ranking_grupos} rows=15>
    <Column id=grupo title="Taldea" wrap=true />
    <Column id=entradas title="Sarrerak" fmt='0' />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Estatuaren publizitatea" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publizitate autonomikoa eta lokala" fmt='#,##0' />
    <Column id=contratos_eur_real title="Kontratuak" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Diru-laguntzak" fmt='#,##0' />
</DataTable>

### Komunikabide publikoak

RTVEk, irrati-telebista autonomiko eta lokalek eta agentzia publikoek ere beste administrazio batzuen publizitatea eta kontratuak kobratzen dituzte. Aparte doaz, haien finantzaketa nagusia beren aurrekontuen ekarpena delako, eta hori [Diru publikoa komunikabideetan](/eu/medios/dinero-publico) orrian aztertzen da.

<DataTable data={publicos} rows=10 search=true>
    <Column id=puesto title="Postua" fmt='0' />
    <Column id=medio title="Komunikabidea" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Estatuaren publizitatea" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publizitate autonomikoa eta lokala" fmt='#,##0' />
    <Column id=contratos_eur_real title="Kontratuak" fmt='#,##0' />
</DataTable>

## Oharrak: zer dagoen eta zer falta den

Iturri bakoitzak gauza desberdinak hartzen ditu; beraz, **zero batek ez du esan nahi komunikabide batek ez duela kobratzen**, eta guztizko bat ez da jasotzen duen guztia:

<DataTable data={cobertura} rows=5>
    <Column id=via title="Bidea" />
    <Column id=desde title="Noiztik" fmt='0' />
    <Column id=hasta title="Noiz arte" fmt='0' />
    <Column id=pagos title="Ordainketak" fmt='#,##0' />
    <Column id=importe_eur_real title="2025eko euroak" fmt='#,##0' />
</DataTable>

- **Estatuaren publizitatea**: komunikabideko banaketa Erakunde Publizitate eta Komunikaziorako Batzordearen 2025eko Txostenetik bakarrik dago, eta **taldeka edo sozietateka**, inoiz ez buruka edo kanpainaka. Horregatik, talde handientzat (Prisa, Atresmedia, Mediaset, Vocento...) taldearen sarreran agertzen da, eta ez egunkari edo irrati-telebista bakoitzarenean. Txostenek ez dute esaten zenbatekoek BEZa duten; biribiltzeko moduagatik, baietz jotzen da.
- **Erkidegoen eta udalen publizitatea**: kanpaina bakoitza zein komunikabidetan ordaindu zen argitaratzen dutenena bakarrik (Katalunia, Gaztela eta Leon, Aragoi, Nafarroa, Murtziako Eskualdea, Valentziako Erkidegoa, Euskadi eta Madrilgo Udala, bakoitza urte desberdin batetik). Gainerako erkidegoek ez dute argitaratzen, edo komunikabideka banakatu gabe egiten dute, eta Bartzelonak ez du komunikabidea ematen. BEZa iturriaren araberakoa da: Kataluniak, Valentziako Erkidegoak eta Madrilgo Udalak BEZik gabeko zenbatekoak ematen dituzte; Aragoik eta Murtziak, BEZarekin; gainerakoek ez dute esaten. Aragoik, Murtziak eta Valentziako Erkidegoak kontratatutakoa ematen dute; gainerakoek, gauzatutakoa.
- **Komunikabide-agentziak**: erakunde-publizitatearen zati handi bat komunikabideen artean banatzen duen komunikabide-agentzia batekin kontratatzen da. Hemen iturriak azken komunikabideari egozten diona baino ez da agertzen; agentziari ordaindutako gisa bakarrik ageri dena ez dago.
- **Kontratuak**: [Sektore Publikoko Kontratazio Plataformaren](https://contrataciondelestado.es) eta plataforma autonomikoen BEZik gabeko esleipen-zenbatekoa, 2018tik. **Dokumentatutako gutxieneko bat** da: hainbat erkidegoren eta argitaratzen ez dituzten udal askoren kontratu txikiak falta dira. Beren publizitatea komunikabideka dagoeneko argitaratzen duen erkidego edo udal baten publizitate-kontratuak ez dira batzen, kanpaina bera bi aldiz ez zenbatzeko.
- **Diru-laguntzak**: [Diru-laguntzen Datu-base Nazionaleko](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) emandako zenbatekoa, 2022tik, komunikabideentzako laguntza-deialdietakoa bakarrik. Pertsona fisikoei emandakoak ez dira erakusten.
- **Nola identifikatzen den komunikabide bakoitza**: argitaletxearen IFZaren bidez kontratuetan eta diru-laguntzetan (adibidez, Dos Mil Palabras, S.L. OKDiariorentzat edo Libertad Digital, S.A. Libertad Digital eta esRadiorentzat) eta komunikabidearen izenaren bidez publizitatean. Sozietate batek hainbat marka argitaratzen baditu eta iturriak ez baditu bereizten, dirua sozietateari edo taldeari doakio. Xehetasuneko «Nola identifikatua» zutabeak ordainketa bakoitzean esaten du iturriak burua, sozietate argitaratzailea edo taldea bakarrik eman zuen. Inongo komunikabideri egotzi ezin izan zaiona (batez ere kanpoko publizitatea, programatikoa eta agentziak) ez da agertzen.

## Iturriak

- [Erakunde Publizitate eta Komunikaziorako Batzordea, urteko txostenak](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx): 2025eko Txostena, IV. eranskina (inbertsioa taldeka) eta merkataritza-publizitatearen 2025eko Txostena, III. eranskina.
- Erakunde-publizitatea komunikabideka: datu irekiak: [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), [Gaztela eta Leongo Junta](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), [Aragoiko Gobernua](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), [Nafarroako Gobernua](https://datosabiertos.navarra.es/dataset/publicidad-institucional), [Murtziako Eskualdea](https://transparencia.carm.es/publicidad-institucional) eta [Madrilgo Udala](https://datos.madrid.es/dataset/300024-0-publicidad-institucional); [Generalitat Valencianaren](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) txostenak eta, Euskadirako, [gobiernovasco.marketing](https://gobiernovasco.marketing/) webgunearen bilduma (Jaime Gómez-Obregón, CC BY 4.0).
- [Sektore Publikoko Kontratazio Plataforma](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) eta Kataluniako, Euskadiko, Andaluziako, Galiziako eta Errioxako kontratazio-plataformak, bai eta Madrilgo eta Bartzelonako udalenak ere.
- [Diru-laguntzen Datu-base Nazionala](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE).
- Euro konstanteak INEren KPIarekin. SpainFactsen komunikabide, sozietate argitaratzaile eta taldeen taula (medios_cabeceras eta medios_cabeceras_alias seed-ak).
