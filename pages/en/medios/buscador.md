---
title: Who gets what
description: "Media search: all the public money each outlet (OKDiario, Libertad Digital, El País, Cadena SER, La Vanguardia...) has received from every administration, by channel (institutional advertising, contracts and subsidies), year and paying administration, in today's euros."
i18n_origen: 4e52a4100892
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
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incomplete)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo, via, importe_eur_real, importe_eur_nominal, CAST(n_pagos AS INTEGER) AS pagos
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
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incomplete)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo, coalesce(partido, 'Sin dato') AS partido, sum(importe_eur_real) AS importe_eur_real
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

# <span aria-hidden="true">🔎</span> Who gets what

Choose a media outlet and you will see everything it has been paid by the public administrations that publish the data: central government and its companies, the regional governments, town councils and provincial councils. Three channels are added up: **institutional advertising** (campaigns), **contracts** (sponsorships, insertions, subscriptions, special features) and **subsidies**. All figures are **adjusted for inflation**, in 2025 euros; each year's amounts as actually paid are in the detail table.

<Dropdown data={lista_medios} name=medio value=medio_id label=etiqueta title="Outlet" defaultValue="okdiario" />

{#if sel.length}

## {sel[0].medio}

{#if sel[0].tipo_medio === 'grupo'}
<p>This entry brings together what the sources attribute to the <strong>{sel[0].grupo}</strong> group without saying which title it goes to: the central government advertising report, companies that publish several brands at once or campaigns in the group's name. Whatever can be assigned to each title is in its own entry (below).</p>
{:else if sel[0].tipo_medio === 'plataforma'}
<p><strong>{sel[0].medio}</strong> is not a media outlet but a digital platform: it appears because administrations buy advertising on it. It is not included in the media ranking.</p>
{:else}
<p>Group: <strong>{sel[0].grupo}</strong>.{#if sel[0].titularidad === 'publica'} It is a <strong>public broadcaster or outlet</strong>: what it receives through advertising or contracts comes on top of what its budgets already pay it, which is not included here (it is in <a href="/en/medios/dinero-publico">Public money in the media</a>).{/if}</p>
{/if}

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    <KpiCard
        title="Total received"
        value={sel[0].total_eur_real}
        formattedValue={formatCompact(sel[0].total_eur_real, 2) + ' €'}
        unit="2025 euros"
        period={`${sel[0].anio_min}-${sel[0].anio_max} · ${formatNumber(sel[0].n_pagos, 0)} payments · ${formatCompact(sel[0].total_eur_nominal, 2)} € nominal`}
        source="SpainFacts with data from the CPCI, regions, town councils, PLACSP and BDNS"
        direction="positive-down"
        sparklineData={sel_serie.map(d => d.total)}
    />
    <KpiCard
        title="Institutional advertising"
        value={sel[0].publicidad_eur_real}
        formattedValue={formatCompact(sel[0].publicidad_eur_real, 2) + ' €'}
        unit="2025 euros"
        period={`Central government: ${formatCompact(sel[0].estado_eur_real, 2)} € · regions and town councils: ${formatCompact(sel[0].territorial_eur_real, 2)} €`}
        source="CPCI (2025), regions and town councils"
        direction="positive-down"
        sparklineData={sel_serie.map(d => d.publicidad)}
    />
    <KpiCard
        title="Contracts and subsidies"
        value={sel[0].contratos_subv_eur_real}
        formattedValue={formatCompact(sel[0].contratos_subv_eur_real, 2) + ' €'}
        unit="2025 euros"
        period={`Contracts: ${formatCompact(sel[0].contratos_eur_real, 2)} € · subsidies: ${formatCompact(sel[0].subvenciones_eur_real, 2)} €`}
        source="PLACSP and BDNS"
        direction="positive-down"
        sparklineData={sel_serie.map(d => d.contratos_subv)}
    />
    <KpiCard
        title="Paying administrations"
        value={sel[0].n_admin}
        formattedValue={formatNumber(sel[0].n_admin, 0)}
        unit="different bodies"
        period={`from ${formatNumber(sel[0].n_gob, 0)} administrations (central government, regions, town councils...)`}
        source="SpainFacts"
        direction="positive-down"
        sparklineData={sel_serie.map(d => d.n_admin)}
    />
</div>

{#if sel[0].en_ranking}
<p>Among {formatNumber(sel[0].n_ranking, 0)} private media outlets, it ranks number <strong>{sel[0].rango_privados}</strong> by public money received between 2019 and 2025 ({formatCompact(sel[0].total_2019_2025_eur_real, 2)} € in today's money). {#if sel_mejor_anio.length}The year it received most was {sel_mejor_anio[0].anio}, with {formatCompact(sel_mejor_anio[0].total, 2)} €.{/if}</p>
{:else if sel[0].titularidad === 'publica'}
<p>Among public media, it ranks number <strong>{sel[0].rango_publicos}</strong> by what it received between 2019 and 2025 through these channels.</p>
{/if}

### By year and channel

<BarChart
    data={sel_anual}
    x=periodo
    sort=false
    y=importe_eur_real
    series=via
    type=stacked
    yFmt='#,##0" €"'
    yAxisTitle="2025 euros"
    seriesColors={{'Publicidad institucional del Estado': '#1d4ed8', 'Publicidad comercial de empresas del Estado': '#60a5fa', 'Publicidad institucional autonómica/local': '#f59e0b', 'Contrato': '#10b981', 'Subvención': '#a855f7'}}
    title="Public money received by year and channel, 2025 euros"
/>

The bars cannot be compared from one year to the next as if they were complete: central government has only published the breakdown by outlet since 2025, and each region began publishing in a different year (see notes). The current year is marked as incomplete.

### Who pays

{#if por_gobierno.length}
<p>The biggest payer is <strong>{por_gobierno[0].gobierno}</strong>, with {formatCompact(por_gobierno[0].importe_eur_real, 2)} € ({formatNumber(por_gobierno[0].pct, 0)} % of the total) in {formatNumber(por_gobierno[0].pagos, 0)} payments.</p>
{/if}

<DataTable data={por_gobierno} rows=10>
    <Column id=gobierno title="Administration" />
    <Column id=partido title="Party in government" />
    <Column id=importe_eur_real title="2025 euros" fmt='#,##0' />
    <Column id=pct title="% of total" fmt='0.0' />
    <Column id=pagos title="Payments" fmt='#,##0' />
</DataTable>

Breakdown by paying body (regional ministry, town council, public company, ministry...) and channel:

<DataTable data={quien_paga} rows=15 search=true>
    <Column id=administracion title="Paying body" wrap=true />
    <Column id=gobierno title="Administration" wrap=true />
    <Column id=partido title="Party" wrap=true />
    <Column id=via title="Channel" wrap=true />
    <Column id=importe_eur_real title="2025 euros" fmt='#,##0' />
    <Column id=pagos title="Payments" fmt='#,##0' />
    <Column id=desde title="From" fmt='0' />
    <Column id=hasta title="To" fmt='0' />
</DataTable>

### By the party in government

Each payment is attributed to the party governing the paying administration on 1 July of that year: the Spanish Government for central government and its companies, the regional government for the regions and the mayor's office for town councils. Provincial councils, island councils and other local bodies have no data. It does not say who decided each campaign, only who was in government.

<DataTable data={por_partido} rows=8>
    <Column id=partido title="Party in government" />
    <Column id=importe_eur_real title="2025 euros" fmt='#,##0' />
    <Column id=pct title="% of total" fmt='0.0' />
    <Column id=pagos title="Payments" fmt='#,##0' />
    <Column id=administraciones title="Administrations" fmt='0' />
</DataTable>

<BarChart
    data={por_partido_anio}
    x=periodo
    sort=false
    y=importe_eur_real
    series=partido
    yFmt='#,##0'
    yAxisTitle="2025 euros"
    seriesColors={Object.fromEntries(por_partido.map(d => [d.partido.startsWith('Sin dato') ? 'Sin dato' : d.partido, d.color]))}
    title="Public money received each year, by the party governing the paying administration"
/>

### Every payment

One row per campaign, contract or subsidy, with the description as written by the source. Click a row with a link to go to the contract file or the subsidy call.

<DataTable data={detalle} rows=20 search=true link=url>
    <Column id=anio title="Year" fmt='0' />
    <Column id=administracion title="Who pays" wrap=true />
    <Column id=partido title="In government" />
    <Column id=via title="Channel" wrap=true />
    <Column id=concepto title="Description" wrap=true />
    <Column id=importe_eur_real title="2025 euros" fmt='#,##0' />
    <Column id=importe_eur_nominal title="Euros of the year" fmt='#,##0' />
    <Column id=iva title="VAT" />
    <Column id=nombre_fuente title="Name in the source" wrap=true />
    <Column id=asignado_por title="Identified by" />
</DataTable>

{#if duplicados.length && duplicados[0].n > 0}
<p>A further {formatNumber(duplicados[0].n, 0)} advertising contracts ({formatCompact(duplicados[0].importe_eur_real, 2)} €) are not added, from regions or town councils that already publish their advertising by outlet that year: they are almost certainly the same campaigns already in the table.</p>
{/if}

{#if relacionados.length && sel[0].tipo_medio !== 'plataforma'}
### Other entries from the same group

What the sources attribute to other titles of **{sel[0].grupo}**, to its companies or to the group as a whole. To know everything the group receives, they have to be added up.

<DataTable data={relacionados} rows=10>
    <Column id=medio title="Entry" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025, 2025 euros" fmt='#,##0' />
    <Column id=total_eur_real title="All years" fmt='#,##0' />
</DataTable>
{/if}

{/if}

## Ranking of private media

The {formatNumber(global[0]?.n_privados, 0)} private media outlets with at least one identified payment, ranked by what they received between 2019 and 2025 in today's euros. First is **{global[0]?.primero}** ({formatCompact(global[0]?.primero_eur, 2)} €) and the top ten take {formatNumber(global[0]?.pct_top10, 0)} % of the total. Some entries are a group or a company with several titles because the source does not separate them.

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=medio title="Outlet" wrap=true />
    <Column id=grupo title="Group" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Central government advertising" fmt='#,##0' />
    <Column id=territorial_eur_real title="Regional and local advertising" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contracts" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Subsidies" fmt='#,##0' />
    <Column id=administraciones title="Paying bodies" fmt='0' />
</DataTable>

### By group

Adding up all the entries of each group (titles, companies and whatever cannot be separated). The channels cover all years; the total, 2019 to 2025.

<DataTable data={ranking_grupos} rows=15>
    <Column id=grupo title="Group" wrap=true />
    <Column id=entradas title="Entries" fmt='0' />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Central government advertising" fmt='#,##0' />
    <Column id=territorial_eur_real title="Regional and local advertising" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contracts" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Subsidies" fmt='#,##0' />
</DataTable>

### Public media

RTVE, the regional and local broadcasters and the public news agencies also receive advertising and contracts from other administrations. They are listed separately because their main funding is the contribution from their budgets, which is analysed in [Public money in the media](/en/medios/dinero-publico).

<DataTable data={publicos} rows=10 search=true>
    <Column id=puesto title="Rank" fmt='0' />
    <Column id=medio title="Outlet" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Central government advertising" fmt='#,##0' />
    <Column id=territorial_eur_real title="Regional and local advertising" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contracts" fmt='#,##0' />
</DataTable>

## Notes: what is included and what is missing

Each source covers different things, so **a zero does not mean an outlet is not paid** and a total is not everything it receives:

<DataTable data={cobertura} rows=5>
    <Column id=via title="Channel" />
    <Column id=desde title="From" fmt='0' />
    <Column id=hasta title="To" fmt='0' />
    <Column id=pagos title="Payments" fmt='#,##0' />
    <Column id=importe_eur_real title="2025 euros" fmt='#,##0' />
</DataTable>

- **Central government advertising**: the breakdown by outlet only exists from the 2025 Report of the Institutional Advertising and Communication Commission, and by **group or company**, never by title or by campaign. That is why, for the big groups (Prisa, Atresmedia, Mediaset, Vocento...), it appears in the group's entry and not in that of each newspaper or station. The reports do not say whether the amounts include VAT; judging by how they are rounded, it is assumed they do.
- **Regional and town council advertising**: only from those that publish the outlet in which each campaign was paid for (Catalonia, Castile and León, Aragon, Navarre, Region of Murcia, Valencian Community, Basque Country and Madrid City Council, each from a different year). The other regions do not publish it or do so without a breakdown by outlet, and Barcelona does not give the outlet. VAT depends on the source: Catalonia, the Valencian Community and Madrid City Council give amounts excluding VAT; Aragon and Murcia, including VAT; the rest do not say. Aragon, Murcia and the Valencian Community give the amount contracted; the rest, the amount spent.
- **Media agencies**: much institutional advertising is contracted with a media agency that distributes it among outlets. Only what the source attributes to the final outlet appears here; whatever is only recorded as paid to the agency is not included.
- **Contracts**: amount awarded excluding VAT from the [Public Sector Procurement Platform](https://contrataciondelestado.es) and the regional platforms since 2018. It is a **documented minimum**: minor contracts from several regions and from many town councils that do not publish them are missing. Advertising contracts from a region or town council that already publishes its advertising by outlet are not added, so as not to count the same campaign twice.
- **Subsidies**: amount granted from the [National Subsidies Database](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones), since 2022, only from calls for aid to the media. Those granted to individuals are not shown.
- **How each outlet is identified**: by the tax ID (NIF) of the publishing company in contracts and subsidies (for example, Dos Mil Palabras, S.L. for OKDiario or Libertad Digital, S.A. for Libertad Digital and esRadio) and by the outlet's name in advertising. If a company publishes several brands and the source does not separate them, the money goes to the company or the group. The «Identified by» column in the detail says for each payment whether the source gave the title, the publishing company or only the group. Whatever could not be attributed to any outlet (mainly outdoor and programmatic advertising and agencies) does not appear.

## Sources

- [Institutional Advertising and Communication Commission, annual reports](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx): 2025 Report, annex IV (spending by group) and 2025 Commercial Advertising Report, annex III.
- Institutional advertising by outlet: open data from the [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), the [Junta de Castilla y León](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), the [Government of Aragon](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), the [Government of Navarre](https://datosabiertos.navarra.es/dataset/publicidad-institucional), the [Region of Murcia](https://transparencia.carm.es/publicidad-institucional) and [Madrid City Council](https://datos.madrid.es/dataset/300024-0-publicidad-institucional); reports from the [Generalitat Valenciana](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) and, for the Basque Country, the compilation by [gobiernovasco.marketing](https://gobiernovasco.marketing/) (Jaime Gómez-Obregón, CC BY 4.0).
- [Public Sector Procurement Platform](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) and the procurement platforms of Catalonia, Euskadi, Andalusia, Galicia, La Rioja and the city councils of Madrid and Barcelona.
- [National Subsidies Database](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE).
- Constant euros using the INE's CPI. SpainFacts table of outlets, publishing companies and groups (seeds medios_cabeceras and medios_cabeceras_alias).
