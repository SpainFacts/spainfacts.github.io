---
title: Quen recibe que
description: "Buscador de medios de comunicación: todo o diñeiro público que recibiu cada medio (OKDiario, Libertad Digital, El País, a SER, La Vanguardia...) de todas as administracións, por vía (publicidade institucional, contratos e subvencións), ano e administración que paga, en euros de hoxe."
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
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incompleto)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo, via, importe_eur_real, importe_eur_nominal, CAST(n_pagos AS INTEGER) AS pagos
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
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incompleto)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo, coalesce(partido, 'Sin dato') AS partido, sum(importe_eur_real) AS importe_eur_real
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

# <span aria-hidden="true">🔎</span> Quen recibe que

Escolle un medio de comunicación e verás todo o que cobrou das administracións públicas que publican o dato: o Estado e as súas empresas, as comunidades autónomas, os concellos e as deputacións. Súmanse tres vías: **publicidade institucional** (campañas), **contratos** (patrocinios, insercións, subscricións, especiais) e **subvencións**. Todas as cifras danse **descontada a inflación**, en euros de 2025; os importes de cada ano, tal como se pagaron, están na táboa do detalle.

<Dropdown data={lista_medios} name=medio value=medio_id label=etiqueta title="Medio" defaultValue="okdiario" />

{#if sel.length}

## {sel[0].medio}

{#if sel[0].tipo_medio === 'grupo'}
<p>Esta entrada reúne o que as fontes lle atribúen ao grupo <strong>{sel[0].grupo}</strong> sen dicir a que cabeceira vai: o informe de publicidade do Estado, as sociedades que editan varias marcas á vez ou as campañas a nome do grupo. O que si se pode asignar a cada cabeceira está na súa propia entrada (abaixo).</p>
{:else if sel[0].tipo_medio === 'plataforma'}
<p><strong>{sel[0].medio}</strong> non é un medio de comunicación senón unha plataforma dixital: aparece porque as administracións compran publicidade nela. Non entra no ranking de medios.</p>
{:else}
<p>Grupo: <strong>{sel[0].grupo}</strong>.{#if sel[0].titularidad === 'publica'} É un <strong>medio público</strong>: o que recibe por publicidade ou contratos súmase ao que xa lle pagan os seus orzamentos, que non se inclúe aquí (está en <a href="/gl/medios/dinero-publico">Diñeiro público nos medios</a>).{/if}</p>
{/if}

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    <KpiCard
        title="Total recibido"
        value={sel[0].total_eur_real}
        formattedValue={formatCompact(sel[0].total_eur_real, 2) + ' €'}
        unit="euros de 2025"
        period={`${sel[0].anio_min}-${sel[0].anio_max} · ${formatNumber(sel[0].n_pagos, 0)} pagamentos · ${formatCompact(sel[0].total_eur_nominal, 2)} € correntes`}
        source="SpainFacts con datos da CPCI, comunidades, concellos, PLACSP e BDNS"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.total}))}
    />
    <KpiCard
        title="Publicidade institucional"
        value={sel[0].publicidad_eur_real}
        formattedValue={formatCompact(sel[0].publicidad_eur_real, 2) + ' €'}
        unit="euros de 2025"
        period={`Estado: ${formatCompact(sel[0].estado_eur_real, 2)} € · comunidades e concellos: ${formatCompact(sel[0].territorial_eur_real, 2)} €`}
        source="CPCI (2025), comunidades e concellos"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.publicidad}))}
    />
    <KpiCard
        title="Contratos e subvencións"
        value={sel[0].contratos_subv_eur_real}
        formattedValue={formatCompact(sel[0].contratos_subv_eur_real, 2) + ' €'}
        unit="euros de 2025"
        period={`Contratos: ${formatCompact(sel[0].contratos_eur_real, 2)} € · subvencións: ${formatCompact(sel[0].subvenciones_eur_real, 2)} €`}
        source="PLACSP e BDNS"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.contratos_subv}))}
    />
    <KpiCard
        title="Administracións que pagan"
        value={sel[0].n_admin}
        formattedValue={formatNumber(sel[0].n_admin, 0)}
        unit="órganos distintos"
        period={`de ${formatNumber(sel[0].n_gob, 0)} administracións (Estado, comunidades, concellos...)`}
        source="SpainFacts"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.n_admin}))}
    />
</div>

{#if sel[0].en_ranking}
<p>Entre {formatNumber(sel[0].n_ranking, 0)} medios privados, é o número <strong>{sel[0].rango_privados}</strong> por diñeiro público recibido entre 2019 e 2025 ({formatCompact(sel[0].total_2019_2025_eur_real, 2)} € de hoxe). {#if sel_mejor_anio.length}O ano en que máis recibiu foi {sel_mejor_anio[0].anio}, con {formatCompact(sel_mejor_anio[0].total, 2)} €.{/if}</p>
{:else if sel[0].titularidad === 'publica'}
<p>Entre os medios públicos, é o número <strong>{sel[0].rango_publicos}</strong> polo recibido entre 2019 e 2025 por estas vías.</p>
{/if}

### Por ano e vía

<BarChart
    data={sel_anual}
    x=periodo
    sort=false
    y=importe_eur_real
    series=via
    type=stacked
    yFmt='#,##0" €"'
    yAxisTitle="Euros de 2025"
    seriesColors={{'Publicidad institucional del Estado': '#1d4ed8', 'Publicidad comercial de empresas del Estado': '#60a5fa', 'Publicidad institucional autonómica/local': '#f59e0b', 'Contrato': '#10b981', 'Subvención': '#a855f7'}}
    title="Diñeiro público recibido por ano e vía, euros de 2025"
/>

As barras non son comparables dun ano a outro coma se fosen completas: o Estado só publica o reparto por medio desde 2025 e cada comunidade empezou a publicar nun ano distinto (ver avisos). O ano en curso aparece marcado como incompleto.

### Quen paga

{#if por_gobierno.length}
<p>O que máis pagou é <strong>{por_gobierno[0].gobierno}</strong>, con {formatCompact(por_gobierno[0].importe_eur_real, 2)} € ({formatNumber(por_gobierno[0].pct, 0)} % do total) en {formatNumber(por_gobierno[0].pagos, 0)} pagamentos.</p>
{/if}

<DataTable data={por_gobierno} rows=10>
    <Column id=gobierno title="Administración" />
    <Column id=partido title="Partido que gobernaba" />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
    <Column id=pct title="% do total" fmt='0.0' />
    <Column id=pagos title="Pagamentos" fmt='#,##0' />
</DataTable>

Desagregación por órgano que paga (consellería, concello, empresa pública, ministerio...) e vía:

<DataTable data={quien_paga} rows=15 search=true>
    <Column id=administracion title="Órgano que paga" wrap=true />
    <Column id=gobierno title="Administración" wrap=true />
    <Column id=partido title="Partido" wrap=true />
    <Column id=via title="Vía" wrap=true />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
    <Column id=pagos title="Pagamentos" fmt='#,##0' />
    <Column id=desde title="Desde" fmt='0' />
    <Column id=hasta title="Ata" fmt='0' />
</DataTable>

### Segundo o partido que gobernaba

Cada pagamento atribúeselle ao partido que gobernaba a administración que paga o 1 de xullo dese ano: o Goberno de España para o Estado e as súas empresas, o goberno autonómico para as comunidades e a alcaldía para os concellos. Deputacións, cabidos e outras entidades locais quedan sen dato. Non di quen decidiu cada campaña, só quen gobernaba.

<DataTable data={por_partido} rows=8>
    <Column id=partido title="Partido que gobernaba" />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
    <Column id=pct title="% do total" fmt='0.0' />
    <Column id=pagos title="Pagamentos" fmt='#,##0' />
    <Column id=administraciones title="Administracións" fmt='0' />
</DataTable>

<BarChart
    data={por_partido_anio}
    x=periodo
    sort=false
    y=importe_eur_real
    series=partido
    yFmt='#,##0'
    yAxisTitle="Euros de 2025"
    seriesColors={Object.fromEntries(por_partido.map(d => [d.partido.startsWith('Sin dato') ? 'Sin dato' : d.partido, d.color]))}
    title="Diñeiro público recibido cada ano, segundo o partido que gobernaba a administración que paga"
/>

### Cada pagamento

Unha fila por campaña, contrato ou subvención, co concepto tal como o escribe a fonte. Preme nunha fila con ligazón para ir ao expediente do contrato ou á convocatoria da subvención.

<DataTable data={detalle} rows=20 search=true link=url>
    <Column id=anio title="Ano" fmt='0' />
    <Column id=administracion title="Quen paga" wrap=true />
    <Column id=partido title="Gobernaba" />
    <Column id=via title="Vía" wrap=true />
    <Column id=concepto title="Concepto" wrap=true />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
    <Column id=importe_eur_nominal title="Euros do ano" fmt='#,##0' />
    <Column id=iva title="IVE" />
    <Column id=nombre_fuente title="Nome na fonte" wrap=true />
    <Column id=asignado_por title="Identificado por" />
</DataTable>

{#if duplicados.length && duplicados[0].n > 0}
<p>Non se suman outros {formatNumber(duplicados[0].n, 0)} contratos de publicidade ({formatCompact(duplicados[0].importe_eur_real, 2)} €) de comunidades ou concellos que xa publican a súa publicidade por medio ese ano: case seguro que son as mesmas campañas que xa están na táboa.</p>
{/if}

{#if relacionados.length && sel[0].tipo_medio !== 'plataforma'}
### Outras entradas do mesmo grupo

O que as fontes lles atribúen a outras cabeceiras de **{sel[0].grupo}**, ás súas sociedades ou ao grupo sen separar. Para saber todo o que recibe o grupo hai que sumalas.

<DataTable data={relacionados} rows=10>
    <Column id=medio title="Entrada" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025, euros de 2025" fmt='#,##0' />
    <Column id=total_eur_real title="Todos os anos" fmt='#,##0' />
</DataTable>
{/if}

{/if}

## Ranking de medios privados

Os {formatNumber(global[0]?.n_privados, 0)} medios privados con algún pagamento identificado, ordenados polo recibido entre 2019 e 2025 en euros de hoxe. O primeiro é **{global[0]?.primero}** ({formatCompact(global[0]?.primero_eur, 2)} €) e os dez primeiros lévanse o {formatNumber(global[0]?.pct_top10, 0)} % do total. Algunhas entradas son un grupo ou unha sociedade con varias cabeceiras porque a fonte non as separa.

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=medio title="Medio" wrap=true />
    <Column id=grupo title="Grupo" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Publicidade do Estado" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publicidade autonómica e local" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contratos" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Subvencións" fmt='#,##0' />
    <Column id=administraciones title="Órganos que pagan" fmt='0' />
</DataTable>

### Por grupo

Sumando todas as entradas de cada grupo (cabeceiras, sociedades e o que non se pode separar). As vías son de todos os anos; o total, de 2019 a 2025.

<DataTable data={ranking_grupos} rows=15>
    <Column id=grupo title="Grupo" wrap=true />
    <Column id=entradas title="Entradas" fmt='0' />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Publicidade do Estado" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publicidade autonómica e local" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contratos" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Subvencións" fmt='#,##0' />
</DataTable>

### Medios públicos

RTVE, as radiotelevisións autonómicas e locais e as axencias públicas tamén cobran publicidade e contratos doutras administracións. Van á parte porque o seu financiamento principal é a achega dos seus orzamentos, que se analiza en [Diñeiro público nos medios](/gl/medios/dinero-publico).

<DataTable data={publicos} rows=10 search=true>
    <Column id=puesto title="Posto" fmt='0' />
    <Column id=medio title="Medio" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Publicidade do Estado" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publicidade autonómica e local" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contratos" fmt='#,##0' />
</DataTable>

## Avisos: que hai e que falta

Cada fonte cobre cousas distintas, así que **un cero non significa que un medio non cobre** e un total non é todo o que recibe:

<DataTable data={cobertura} rows=5>
    <Column id=via title="Vía" />
    <Column id=desde title="Desde" fmt='0' />
    <Column id=hasta title="Ata" fmt='0' />
    <Column id=pagos title="Pagamentos" fmt='#,##0' />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
</DataTable>

- **Publicidade do Estado**: o reparto por medio só existe desde o Informe 2025 da Comisión de Publicidade e Comunicación Institucional, e por **grupo ou sociedade**, nunca por cabeceira nin por campaña. Por iso, para os grandes grupos (Prisa, Atresmedia, Mediaset, Vocento...) aparece na entrada do grupo e non na de cada xornal ou emisora. Os informes non din se os importes levan IVE; polo xeito en que están redondeados, tómase que si.
- **Publicidade de comunidades e concellos**: só dos que publican o medio no que se pagou cada campaña (Cataluña, Castela e León, Aragón, Navarra, Rexión de Murcia, Comunidade Valenciana, País Vasco e o Concello de Madrid, cada un desde un ano distinto). As demais comunidades non o publican ou fano sen desagregación por medio, e Barcelona non dá o medio. O IVE depende da fonte: Cataluña, a Comunidade Valenciana e o Concello de Madrid dan importes sen IVE; Aragón e Murcia, con IVE; as demais non o din. Aragón, Murcia e a Comunidade Valenciana dan o contratado; as demais, o executado.
- **Axencias de medios**: boa parte da publicidade institucional contrátase cunha axencia de medios que a reparte entre os medios. Aquí só aparece o que a fonte lle atribúe ao medio final; o que só consta como pagado á axencia non está.
- **Contratos**: importe adxudicado sen IVE da [Plataforma de Contratación do Sector Público](https://contrataciondelestado.es) e das plataformas autonómicas desde 2018. É un **mínimo documentado**: faltan os contratos menores de varias comunidades e de moitos concellos que non os publican. Os contratos de publicidade dunha comunidade ou concello que xa publica a súa publicidade por medio non se suman, para non contar dúas veces a mesma campaña.
- **Subvencións**: importe concedido da [Base de Datos Nacional de Subvencións](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones), desde 2022, só de convocatorias de axudas a medios. Non se mostran as concedidas a persoas físicas.
- **Como se identifica cada medio**: polo NIF da empresa editora en contratos e subvencións (por exemplo, Dos Mil Palabras, S.L. para OKDiario ou Libertad Digital, S.A. para Libertad Digital e esRadio) e polo nome do medio na publicidade. Se unha sociedade edita varias marcas e a fonte non as separa, o diñeiro vai á sociedade ou ao grupo. A columna «Identificado por» do detalle di en cada pagamento se a fonte deu a cabeceira, a sociedade editora ou só o grupo. O que non se puido atribuír a ningún medio (sobre todo publicidade exterior, programática e axencias) non aparece.

## Fontes

- [Comisión de Publicidade e Comunicación Institucional, informes anuais](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx): Informe 2025, anexo IV (investimento por grupos) e Informe 2025 de publicidade comercial, anexo III.
- Publicidade institucional por medio: datos abertos da [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), da [Junta de Castilla y León](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), do [Goberno de Aragón](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), do [Goberno de Navarra](https://datosabiertos.navarra.es/dataset/publicidad-institucional), da [Rexión de Murcia](https://transparencia.carm.es/publicidad-institucional) e do [Concello de Madrid](https://datos.madrid.es/dataset/300024-0-publicidad-institucional); informes da [Generalitat Valenciana](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) e, para o País Vasco, a recompilación de [gobiernovasco.marketing](https://gobiernovasco.marketing/) (Jaime Gómez-Obregón, CC BY 4.0).
- [Plataforma de Contratación do Sector Público](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) e plataformas de contratación de Cataluña, Euskadi, Andalucía, Galicia, A Rioxa e os concellos de Madrid e Barcelona.
- [Base de Datos Nacional de Subvencións](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE).
- Euros constantes co IPC do INE. Táboa de medios, sociedades editoras e grupos de SpainFacts (seeds medios_cabeceras e medios_cabeceras_alias).
