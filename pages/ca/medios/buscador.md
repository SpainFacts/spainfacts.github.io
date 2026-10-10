---
title: Qui rep què
description: "Cercador de mitjans de comunicació: tots els diners públics que ha rebut cada mitjà (OKDiario, Libertad Digital, El País, la SER, La Vanguardia...) de totes les administracions, per via (publicitat institucional, contractes i subvencions), any i administració que paga, en euros d'avui."
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
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incomplet)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo, via, importe_eur_real, importe_eur_nominal, CAST(n_pagos AS INTEGER) AS pagos
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
SELECT CAST(anio AS INTEGER) AS anio, CASE WHEN anio >= year(current_date) THEN CAST(CAST(anio AS INTEGER) AS VARCHAR) || ' (incomplet)' ELSE CAST(CAST(anio AS INTEGER) AS VARCHAR) END AS periodo, coalesce(partido, 'Sin dato') AS partido, sum(importe_eur_real) AS importe_eur_real
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

# <span aria-hidden="true">🔎</span> Qui rep què

Tria un mitjà de comunicació i veuràs tot el que ha cobrat de les administracions públiques que publiquen la dada: l'Estat i les seves empreses, les comunitats autònomes, els ajuntaments i les diputacions. Se sumen tres vies: **publicitat institucional** (campanyes), **contractes** (patrocinis, insercions, subscripcions, especials) i **subvencions**. Totes les xifres es donen **descomptada la inflació**, en euros del 2025; els imports de cada any, tal com es van pagar, són a la taula del detall.

<Dropdown data={lista_medios} name=medio value=medio_id label=etiqueta title="Mitjà" defaultValue="okdiario" />

{#if sel.length}

## {sel[0].medio}

{#if sel[0].tipo_medio === 'grupo'}
<p>Aquesta entrada reuneix el que les fonts atribueixen al grup <strong>{sel[0].grupo}</strong> sense dir a quina capçalera va: l'informe de publicitat de l'Estat, les societats que editen diverses marques alhora o les campanyes a nom del grup. El que sí que es pot assignar a cada capçalera és a la seva pròpia entrada (a sota).</p>
{:else if sel[0].tipo_medio === 'plataforma'}
<p><strong>{sel[0].medio}</strong> no és un mitjà de comunicació sinó una plataforma digital: hi apareix perquè les administracions hi compren publicitat. No entra al rànquing de mitjans.</p>
{:else}
<p>Grup: <strong>{sel[0].grupo}</strong>.{#if sel[0].titularidad === 'publica'} És un <strong>mitjà públic</strong>: el que rep per publicitat o contractes se suma al que ja li paguen els seus pressupostos, que no s'inclou aquí (és a <a href="/ca/medios/dinero-publico">Diners públics als mitjans</a>).{/if}</p>
{/if}

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    <KpiCard
        title="Total rebut"
        value={sel[0].total_eur_real}
        formattedValue={formatCompact(sel[0].total_eur_real, 2) + ' €'}
        unit="euros del 2025"
        period={`${sel[0].anio_min}-${sel[0].anio_max} · ${formatNumber(sel[0].n_pagos, 0)} pagaments · ${formatCompact(sel[0].total_eur_nominal, 2)} € corrents`}
        source="SpainFacts amb dades de la CPCI, comunitats, ajuntaments, PLACSP i BDNS"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.total}))}
    />
    <KpiCard
        title="Publicitat institucional"
        value={sel[0].publicidad_eur_real}
        formattedValue={formatCompact(sel[0].publicidad_eur_real, 2) + ' €'}
        unit="euros del 2025"
        period={`Estat: ${formatCompact(sel[0].estado_eur_real, 2)} € · comunitats i ajuntaments: ${formatCompact(sel[0].territorial_eur_real, 2)} €`}
        source="CPCI (2025), comunitats i ajuntaments"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.publicidad}))}
    />
    <KpiCard
        title="Contractes i subvencions"
        value={sel[0].contratos_subv_eur_real}
        formattedValue={formatCompact(sel[0].contratos_subv_eur_real, 2) + ' €'}
        unit="euros del 2025"
        period={`Contractes: ${formatCompact(sel[0].contratos_eur_real, 2)} € · subvencions: ${formatCompact(sel[0].subvenciones_eur_real, 2)} €`}
        source="PLACSP i BDNS"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.contratos_subv}))}
    />
    <KpiCard
        title="Administracions que paguen"
        value={sel[0].n_admin}
        formattedValue={formatNumber(sel[0].n_admin, 0)}
        unit="òrgans diferents"
        period={`de ${formatNumber(sel[0].n_gob, 0)} administracions (Estat, comunitats, ajuntaments...)`}
        source="SpainFacts"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.n_admin}))}
    />
</div>

{#if sel[0].en_ranking}
<p>Entre {formatNumber(sel[0].n_ranking, 0)} mitjans privats, és el número <strong>{sel[0].rango_privados}</strong> per diners públics rebuts entre el 2019 i el 2025 ({formatCompact(sel[0].total_2019_2025_eur_real, 2)} € d'avui). {#if sel_mejor_anio.length}L'any en què més va rebre va ser el {sel_mejor_anio[0].anio}, amb {formatCompact(sel_mejor_anio[0].total, 2)} €.{/if}</p>
{:else if sel[0].titularidad === 'publica'}
<p>Entre els mitjans públics, és el número <strong>{sel[0].rango_publicos}</strong> pel que ha rebut entre el 2019 i el 2025 per aquestes vies.</p>
{/if}

### Per any i via

<BarChart
    data={sel_anual}
    x=periodo
    sort=false
    y=importe_eur_real
    series=via
    type=stacked
    yFmt='#,##0" €"'
    yAxisTitle="Euros del 2025"
    seriesColors={{'Publicidad institucional del Estado': '#1d4ed8', 'Publicidad comercial de empresas del Estado': '#60a5fa', 'Publicidad institucional autonómica/local': '#f59e0b', 'Contrato': '#10b981', 'Subvención': '#a855f7'}}
    title="Diners públics rebuts per any i via, euros del 2025"
/>

Les barres no són comparables d'un any a l'altre com si fossin completes: l'Estat només publica el repartiment per mitjà des del 2025 i cada comunitat va començar a publicar en un any diferent (vegeu els avisos). L'any en curs apareix marcat com a incomplet.

### Qui paga

{#if por_gobierno.length}
<p>El que més ha pagat és <strong>{por_gobierno[0].gobierno}</strong>, amb {formatCompact(por_gobierno[0].importe_eur_real, 2)} € ({formatNumber(por_gobierno[0].pct, 0)} % del total) en {formatNumber(por_gobierno[0].pagos, 0)} pagaments.</p>
{/if}

<DataTable data={por_gobierno} rows=10>
    <Column id=gobierno title="Administració" />
    <Column id=partido title="Partit que governava" />
    <Column id=importe_eur_real title="Euros del 2025" fmt='#,##0' />
    <Column id=pct title="% del total" fmt='0.0' />
    <Column id=pagos title="Pagaments" fmt='#,##0' />
</DataTable>

Desglossament per òrgan que paga (conselleria, ajuntament, empresa pública, ministeri...) i via:

<DataTable data={quien_paga} rows=15 search=true>
    <Column id=administracion title="Òrgan que paga" wrap=true />
    <Column id=gobierno title="Administració" wrap=true />
    <Column id=partido title="Partit" wrap=true />
    <Column id=via title="Via" wrap=true />
    <Column id=importe_eur_real title="Euros del 2025" fmt='#,##0' />
    <Column id=pagos title="Pagaments" fmt='#,##0' />
    <Column id=desde title="Des de" fmt='0' />
    <Column id=hasta title="Fins a" fmt='0' />
</DataTable>

### Segons el partit que governava

Cada pagament s'atribueix al partit que governava l'administració que paga l'1 de juliol d'aquell any: el Govern d'Espanya per a l'Estat i les seves empreses, el govern autonòmic per a les comunitats i l'alcaldia per als ajuntaments. Diputacions, cabildos i altres entitats locals queden sense dada. No diu qui va decidir cada campanya, només qui governava.

<DataTable data={por_partido} rows=8>
    <Column id=partido title="Partit que governava" />
    <Column id=importe_eur_real title="Euros del 2025" fmt='#,##0' />
    <Column id=pct title="% del total" fmt='0.0' />
    <Column id=pagos title="Pagaments" fmt='#,##0' />
    <Column id=administraciones title="Administracions" fmt='0' />
</DataTable>

<BarChart
    data={por_partido_anio}
    x=periodo
    sort=false
    y=importe_eur_real
    series=partido
    yFmt='#,##0'
    yAxisTitle="Euros del 2025"
    seriesColors={Object.fromEntries(por_partido.map(d => [d.partido.startsWith('Sin dato') ? 'Sin dato' : d.partido, d.color]))}
    title="Diners públics rebuts cada any, segons el partit que governava l'administració que paga"
/>

### Cada pagament

Una fila per campanya, contracte o subvenció, amb el concepte tal com l'escriu la font. Prem una fila amb enllaç per anar a l'expedient del contracte o a la convocatòria de la subvenció.

<DataTable data={detalle} rows=20 search=true link=url>
    <Column id=anio title="Any" fmt='0' />
    <Column id=administracion title="Qui paga" wrap=true />
    <Column id=partido title="Governava" />
    <Column id=via title="Via" wrap=true />
    <Column id=concepto title="Concepte" wrap=true />
    <Column id=importe_eur_real title="Euros del 2025" fmt='#,##0' />
    <Column id=importe_eur_nominal title="Euros de l'any" fmt='#,##0' />
    <Column id=iva title="IVA" />
    <Column id=nombre_fuente title="Nom a la font" wrap=true />
    <Column id=asignado_por title="Identificat per" />
</DataTable>

{#if duplicados.length && duplicados[0].n > 0}
<p>No se sumen uns altres {formatNumber(duplicados[0].n, 0)} contractes de publicitat ({formatCompact(duplicados[0].importe_eur_real, 2)} €) de comunitats o ajuntaments que ja publiquen la seva publicitat per mitjà aquell any: gairebé segur que són les mateixes campanyes que ja hi ha a la taula.</p>
{/if}

{#if relacionados.length && sel[0].tipo_medio !== 'plataforma'}
### Altres entrades del mateix grup

El que les fonts atribueixen a altres capçaleres de **{sel[0].grupo}**, a les seves societats o al grup sense separar. Per saber tot el que rep el grup cal sumar-les.

<DataTable data={relacionados} rows=10>
    <Column id=medio title="Entrada" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025, euros del 2025" fmt='#,##0' />
    <Column id=total_eur_real title="Tots els anys" fmt='#,##0' />
</DataTable>
{/if}

{/if}

## Rànquing de mitjans privats

Els {formatNumber(global[0]?.n_privados, 0)} mitjans privats amb algun pagament identificat, ordenats pel que han rebut entre el 2019 i el 2025 en euros d'avui. El primer és **{global[0]?.primero}** ({formatCompact(global[0]?.primero_eur, 2)} €) i els deu primers s'enduen el {formatNumber(global[0]?.pct_top10, 0)} % del total. Algunes entrades són un grup o una societat amb diverses capçaleres perquè la font no les separa.

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="Lloc" fmt='0' />
    <Column id=medio title="Mitjà" wrap=true />
    <Column id=grupo title="Grup" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Publicitat de l'Estat" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publicitat autonòmica i local" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contractes" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Subvencions" fmt='#,##0' />
    <Column id=administraciones title="Òrgans que paguen" fmt='0' />
</DataTable>

### Per grup

Sumant totes les entrades de cada grup (capçaleres, societats i el que no es pot separar). Les vies són de tots els anys; el total, del 2019 al 2025.

<DataTable data={ranking_grupos} rows=15>
    <Column id=grupo title="Grup" wrap=true />
    <Column id=entradas title="Entrades" fmt='0' />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Publicitat de l'Estat" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publicitat autonòmica i local" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contractes" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Subvencions" fmt='#,##0' />
</DataTable>

### Mitjans públics

RTVE, les ràdios i televisions autonòmiques i locals i les agències públiques també cobren publicitat i contractes d'altres administracions. Van a part perquè el seu finançament principal és l'aportació dels seus pressupostos, que s'analitza a [Diners públics als mitjans](/ca/medios/dinero-publico).

<DataTable data={publicos} rows=10 search=true>
    <Column id=puesto title="Lloc" fmt='0' />
    <Column id=medio title="Mitjà" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Publicitat de l'Estat" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publicitat autonòmica i local" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contractes" fmt='#,##0' />
</DataTable>

## Avisos: què hi ha i què hi falta

Cada font cobreix coses diferents, així que **un zero no vol dir que un mitjà no cobri** i un total no és tot el que rep:

<DataTable data={cobertura} rows=5>
    <Column id=via title="Via" />
    <Column id=desde title="Des de" fmt='0' />
    <Column id=hasta title="Fins a" fmt='0' />
    <Column id=pagos title="Pagaments" fmt='#,##0' />
    <Column id=importe_eur_real title="Euros del 2025" fmt='#,##0' />
</DataTable>

- **Publicitat de l'Estat**: el repartiment per mitjà només existeix des de l'Informe 2025 de la Comissió de Publicitat i Comunicació Institucional, i per **grup o societat**, mai per capçalera ni per campanya. Per això, per als grans grups (Prisa, Atresmedia, Mediaset, Vocento...) apareix a l'entrada del grup i no a la de cada diari o emissora. Els informes no diuen si els imports porten IVA; per com estan arrodonits, es considera que sí.
- **Publicitat de comunitats i ajuntaments**: només de les que publiquen el mitjà en què es va pagar cada campanya (Catalunya, Castella i Lleó, Aragó, Navarra, Regió de Múrcia, Comunitat Valenciana, País Basc i l'Ajuntament de Madrid, cadascun des d'un any diferent). Les altres comunitats no ho publiquen o ho fan sense desglossament per mitjà, i Barcelona no dona el mitjà. L'IVA depèn de la font: Catalunya, la Comunitat Valenciana i l'Ajuntament de Madrid donen imports sense IVA; Aragó i Múrcia, amb IVA; les altres no ho diuen. Aragó, Múrcia i la Comunitat Valenciana donen el que s'ha contractat; les altres, el que s'ha executat.
- **Agències de mitjans**: bona part de la publicitat institucional es contracta amb una agència de mitjans que la reparteix entre els mitjans. Aquí només apareix el que la font atribueix al mitjà final; el que només consta com a pagat a l'agència no hi és.
- **Contractes**: import adjudicat sense IVA de la [Plataforma de Contractació del Sector Públic](https://contrataciondelestado.es) i de les plataformes autonòmiques des del 2018. És un **mínim documentat**: hi falten els contractes menors de diverses comunitats i de molts ajuntaments que no els publiquen. Els contractes de publicitat d'una comunitat o ajuntament que ja publica la seva publicitat per mitjà no se sumen, per no comptar dues vegades la mateixa campanya.
- **Subvencions**: import concedit de la [Base de Dades Nacional de Subvencions](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones), des del 2022, només de convocatòries d'ajuts a mitjans. No es mostren les concedides a persones físiques.
- **Com s'identifica cada mitjà**: pel NIF de l'empresa editora en contractes i subvencions (per exemple, Dos Mil Palabras, S.L. per a OKDiario o Libertad Digital, S.A. per a Libertad Digital i esRadio) i pel nom del mitjà en la publicitat. Si una societat edita diverses marques i la font no les separa, els diners van a la societat o al grup. La columna «Identificat per» del detall diu en cada pagament si la font va donar la capçalera, la societat editora o només el grup. El que no s'ha pogut atribuir a cap mitjà (sobretot publicitat exterior, programàtica i agències) no hi apareix.

## Fonts

- [Comissió de Publicitat i Comunicació Institucional, informes anuals](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx): Informe 2025, annex IV (inversió per grups) i Informe 2025 de publicitat comercial, annex III.
- Publicitat institucional per mitjà: dades obertes de la [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), la [Junta de Castella i Lleó](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), el [Govern d'Aragó](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), el [Govern de Navarra](https://datosabiertos.navarra.es/dataset/publicidad-institucional), la [Regió de Múrcia](https://transparencia.carm.es/publicidad-institucional) i l'[Ajuntament de Madrid](https://datos.madrid.es/dataset/300024-0-publicidad-institucional); informes de la [Generalitat Valenciana](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) i, per al País Basc, el recull de [gobiernovasco.marketing](https://gobiernovasco.marketing/) (Jaime Gómez-Obregón, CC BY 4.0).
- [Plataforma de Contractació del Sector Públic](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) i plataformes de contractació de Catalunya, Euskadi, Andalusia, Galícia, La Rioja i els ajuntaments de Madrid i Barcelona.
- [Base de Dades Nacional de Subvencions](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE).
- Euros constants amb l'IPC de l'INE. Taula de mitjans, societats editores i grups de SpainFacts (seeds medios_cabeceras i medios_cabeceras_alias).
