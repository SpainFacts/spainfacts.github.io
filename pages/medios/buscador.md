---
title: Quién recibe qué
description: "Buscador de medios de comunicación: todo el dinero público que ha recibido cada medio (OKDiario, Libertad Digital, El País, la SER, La Vanguardia...) de todas las administraciones, por vía (publicidad institucional, contratos y subvenciones), año y administración que paga, en euros de hoy."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
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

# <span aria-hidden="true">🔎</span> Quién recibe qué

Elige un medio de comunicación y verás todo lo que ha cobrado de las administraciones públicas que publican el dato: el Estado y sus empresas, las comunidades autónomas, los ayuntamientos y las diputaciones. Se suman tres vías: **publicidad institucional** (campañas), **contratos** (patrocinios, inserciones, suscripciones, especiales) y **subvenciones**. Todas las cifras se dan **descontada la inflación**, en euros de 2025; los importes de cada año, tal como se pagaron, están en la tabla del detalle.

<Dropdown data={lista_medios} name=medio value=medio_id label=etiqueta title="Medio" defaultValue="okdiario" />

{#if sel.length}

## {sel[0].medio}

{#if sel[0].tipo_medio === 'grupo'}
<p>Esta entrada reúne lo que las fuentes atribuyen al grupo <strong>{sel[0].grupo}</strong> sin decir a qué cabecera va: el informe de publicidad del Estado, las sociedades que editan varias marcas a la vez o las campañas a nombre del grupo. Lo que sí se puede asignar a cada cabecera está en su propia entrada (abajo).</p>
{:else if sel[0].tipo_medio === 'plataforma'}
<p><strong>{sel[0].medio}</strong> no es un medio de comunicación sino una plataforma digital: aparece porque las administraciones compran publicidad en ella. No entra en el ranking de medios.</p>
{:else}
<p>Grupo: <strong>{sel[0].grupo}</strong>.{#if sel[0].titularidad === 'publica'} Es un <strong>medio público</strong>: lo que recibe por publicidad o contratos se suma a lo que ya le pagan sus presupuestos, que no se incluye aquí (está en <a href="/medios/dinero-publico">Dinero público en los medios</a>).{/if}</p>
{/if}

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 my-6">
    <KpiCard
        title="Total recibido"
        value={sel[0].total_eur_real}
        formattedValue={formatCompact(sel[0].total_eur_real, 2) + ' €'}
        unit="euros de 2025"
        period={`${sel[0].anio_min}-${sel[0].anio_max} · ${formatNumber(sel[0].n_pagos, 0)} pagos · ${formatCompact(sel[0].total_eur_nominal, 2)} € corrientes`}
        source="SpainFacts con datos de la CPCI, comunidades, ayuntamientos, PLACSP y BDNS"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.total}))}
    />
    <KpiCard
        title="Publicidad institucional"
        value={sel[0].publicidad_eur_real}
        formattedValue={formatCompact(sel[0].publicidad_eur_real, 2) + ' €'}
        unit="euros de 2025"
        period={`Estado: ${formatCompact(sel[0].estado_eur_real, 2)} € · comunidades y ayuntamientos: ${formatCompact(sel[0].territorial_eur_real, 2)} €`}
        source="CPCI (2025), comunidades y ayuntamientos"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.publicidad}))}
    />
    <KpiCard
        title="Contratos y subvenciones"
        value={sel[0].contratos_subv_eur_real}
        formattedValue={formatCompact(sel[0].contratos_subv_eur_real, 2) + ' €'}
        unit="euros de 2025"
        period={`Contratos: ${formatCompact(sel[0].contratos_eur_real, 2)} € · subvenciones: ${formatCompact(sel[0].subvenciones_eur_real, 2)} €`}
        source="PLACSP y BDNS"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.contratos_subv}))}
    />
    <KpiCard
        title="Administraciones que pagan"
        value={sel[0].n_admin}
        formattedValue={formatNumber(sel[0].n_admin, 0)}
        unit="órganos distintos"
        period={`de ${formatNumber(sel[0].n_gob, 0)} administraciones (Estado, comunidades, ayuntamientos...)`}
        source="SpainFacts"
        direction="positive-down"
        sparklineData={sel_serie.map(d => ({...d, y: d.n_admin}))}
    />
</div>

{#if sel[0].en_ranking}
<p>Entre {formatNumber(sel[0].n_ranking, 0)} medios privados, es el número <strong>{sel[0].rango_privados}</strong> por dinero público recibido entre 2019 y 2025 ({formatCompact(sel[0].total_2019_2025_eur_real, 2)} € de hoy). {#if sel_mejor_anio.length}El año en que más recibió fue {sel_mejor_anio[0].anio}, con {formatCompact(sel_mejor_anio[0].total, 2)} €.{/if}</p>
{:else if sel[0].titularidad === 'publica'}
<p>Entre los medios públicos, es el número <strong>{sel[0].rango_publicos}</strong> por lo recibido entre 2019 y 2025 por estas vías.</p>
{/if}

### Por año y vía

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
    title="Dinero público recibido por año y vía, euros de 2025"
/>

Las barras no son comparables de un año a otro como si fueran completas: el Estado solo publica el reparto por medio desde 2025 y cada comunidad empezó a publicar en un año distinto (ver avisos). El año en curso aparece marcado como incompleto.

### Quién paga

{#if por_gobierno.length}
<p>El que más ha pagado es <strong>{por_gobierno[0].gobierno}</strong>, con {formatCompact(por_gobierno[0].importe_eur_real, 2)} € ({formatNumber(por_gobierno[0].pct, 0)} % del total) en {formatNumber(por_gobierno[0].pagos, 0)} pagos.</p>
{/if}

<DataTable data={por_gobierno} rows=10>
    <Column id=gobierno title="Administración" />
    <Column id=partido title="Partido que gobernaba" />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
    <Column id=pct title="% del total" fmt='0.0' />
    <Column id=pagos title="Pagos" fmt='#,##0' />
</DataTable>

Desglose por órgano que paga (consejería, ayuntamiento, empresa pública, ministerio...) y vía:

<DataTable data={quien_paga} rows=15 search=true>
    <Column id=administracion title="Órgano que paga" wrap=true />
    <Column id=gobierno title="Administración" wrap=true />
    <Column id=partido title="Partido" wrap=true />
    <Column id=via title="Vía" wrap=true />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
    <Column id=pagos title="Pagos" fmt='#,##0' />
    <Column id=desde title="Desde" fmt='0' />
    <Column id=hasta title="Hasta" fmt='0' />
</DataTable>

### Según el partido que gobernaba

Cada pago se atribuye al partido que gobernaba la administración que paga el 1 de julio de ese año: el Gobierno de España para el Estado y sus empresas, el gobierno autonómico para las comunidades y la alcaldía para los ayuntamientos. Diputaciones, cabildos y otras entidades locales quedan sin dato. No dice quién decidió cada campaña, solo quién gobernaba.

<DataTable data={por_partido} rows=8>
    <Column id=partido title="Partido que gobernaba" />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
    <Column id=pct title="% del total" fmt='0.0' />
    <Column id=pagos title="Pagos" fmt='#,##0' />
    <Column id=administraciones title="Administraciones" fmt='0' />
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
    title="Dinero público recibido cada año, según el partido que gobernaba la administración que paga"
/>

### Cada pago

Una fila por campaña, contrato o subvención, con el concepto tal como lo escribe la fuente. Pulsa una fila con enlace para ir al expediente del contrato o a la convocatoria de la subvención.

<DataTable data={detalle} rows=20 search=true link=url>
    <Column id=anio title="Año" fmt='0' />
    <Column id=administracion title="Quién paga" wrap=true />
    <Column id=partido title="Gobernaba" />
    <Column id=via title="Vía" wrap=true />
    <Column id=concepto title="Concepto" wrap=true />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
    <Column id=importe_eur_nominal title="Euros del año" fmt='#,##0' />
    <Column id=iva title="IVA" />
    <Column id=nombre_fuente title="Nombre en la fuente" wrap=true />
    <Column id=asignado_por title="Identificado por" />
</DataTable>

{#if duplicados.length && duplicados[0].n > 0}
<p>No se suman otros {formatNumber(duplicados[0].n, 0)} contratos de publicidad ({formatCompact(duplicados[0].importe_eur_real, 2)} €) de comunidades o ayuntamientos que ya publican su publicidad por medio ese año: casi seguro son las mismas campañas que ya están en la tabla.</p>
{/if}

{#if relacionados.length && sel[0].tipo_medio !== 'plataforma'}
### Otras entradas del mismo grupo

Lo que las fuentes atribuyen a otras cabeceras de **{sel[0].grupo}**, a sus sociedades o al grupo sin separar. Para saber todo lo que recibe el grupo hay que sumarlas.

<DataTable data={relacionados} rows=10>
    <Column id=medio title="Entrada" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025, euros de 2025" fmt='#,##0' />
    <Column id=total_eur_real title="Todos los años" fmt='#,##0' />
</DataTable>
{/if}

{/if}

## Ranking de medios privados

Los {formatNumber(global[0]?.n_privados, 0)} medios privados con algún pago identificado, ordenados por lo recibido entre 2019 y 2025 en euros de hoy. El primero es **{global[0]?.primero}** ({formatCompact(global[0]?.primero_eur, 2)} €) y los diez primeros se llevan el {formatNumber(global[0]?.pct_top10, 0)} % del total. Algunas entradas son un grupo o una sociedad con varias cabeceras porque la fuente no las separa.

<DataTable data={ranking} rows=25 search=true>
    <Column id=puesto title="Puesto" fmt='0' />
    <Column id=medio title="Medio" wrap=true />
    <Column id=grupo title="Grupo" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Publicidad del Estado" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publicidad autonómica y local" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contratos" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Subvenciones" fmt='#,##0' />
    <Column id=administraciones title="Órganos que pagan" fmt='0' />
</DataTable>

### Por grupo

Sumando todas las entradas de cada grupo (cabeceras, sociedades y lo que no se puede separar). Las vías son de todos los años; el total, de 2019 a 2025.

<DataTable data={ranking_grupos} rows=15>
    <Column id=grupo title="Grupo" wrap=true />
    <Column id=entradas title="Entradas" fmt='0' />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Publicidad del Estado" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publicidad autonómica y local" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contratos" fmt='#,##0' />
    <Column id=subvenciones_eur_real title="Subvenciones" fmt='#,##0' />
</DataTable>

### Medios públicos

RTVE, las radiotelevisiones autonómicas y locales y las agencias públicas también cobran publicidad y contratos de otras administraciones. Van aparte porque su financiación principal es la aportación de sus presupuestos, que se analiza en [Dinero público en los medios](/medios/dinero-publico).

<DataTable data={publicos} rows=10 search=true>
    <Column id=puesto title="Puesto" fmt='0' />
    <Column id=medio title="Medio" wrap=true />
    <Column id=total_2019_2025_eur_real title="2019-2025" fmt='#,##0' />
    <Column id=estado_eur_real title="Publicidad del Estado" fmt='#,##0' />
    <Column id=territorial_eur_real title="Publicidad autonómica y local" fmt='#,##0' />
    <Column id=contratos_eur_real title="Contratos" fmt='#,##0' />
</DataTable>

## Avisos: qué hay y qué falta

Cada fuente cubre cosas distintas, así que **un cero no significa que un medio no cobre** y un total no es todo lo que recibe:

<DataTable data={cobertura} rows=5>
    <Column id=via title="Vía" />
    <Column id=desde title="Desde" fmt='0' />
    <Column id=hasta title="Hasta" fmt='0' />
    <Column id=pagos title="Pagos" fmt='#,##0' />
    <Column id=importe_eur_real title="Euros de 2025" fmt='#,##0' />
</DataTable>

- **Publicidad del Estado**: el reparto por medio solo existe desde el Informe 2025 de la Comisión de Publicidad y Comunicación Institucional, y por **grupo o sociedad**, nunca por cabecera ni por campaña. Por eso, para los grandes grupos (Prisa, Atresmedia, Mediaset, Vocento...) aparece en la entrada del grupo y no en la de cada periódico o emisora. Los informes no dicen si los importes llevan IVA; por cómo están redondeados, se toma que sí.
- **Publicidad de comunidades y ayuntamientos**: solo de los que publican el medio en el que se pagó cada campaña (Cataluña, Castilla y León, Aragón, Navarra, Región de Murcia, Comunitat Valenciana, País Vasco y el Ayuntamiento de Madrid, cada uno desde un año distinto). Las demás comunidades no lo publican o lo hacen sin desglose por medio, y Barcelona no da el medio. El IVA depende de la fuente: Cataluña, la Comunitat Valenciana y el Ayuntamiento de Madrid dan importes sin IVA; Aragón y Murcia, con IVA; las demás no lo dicen. Aragón, Murcia y la Comunitat Valenciana dan lo contratado; las demás, lo ejecutado.
- **Agencias de medios**: buena parte de la publicidad institucional se contrata con una agencia de medios que la reparte entre los medios. Aquí solo aparece lo que la fuente atribuye al medio final; lo que solo consta como pagado a la agencia no está.
- **Contratos**: importe adjudicado sin IVA de la [Plataforma de Contratación del Sector Público](https://contrataciondelestado.es) y de las plataformas autonómicas desde 2018. Es un **mínimo documentado**: faltan los contratos menores de varias comunidades y de muchos ayuntamientos que no los publican. Los contratos de publicidad de una comunidad o ayuntamiento que ya publica su publicidad por medio no se suman, para no contar dos veces la misma campaña.
- **Subvenciones**: importe concedido de la [Base de Datos Nacional de Subvenciones](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones), desde 2022, solo de convocatorias de ayudas a medios. No se muestran las concedidas a personas físicas.
- **Cómo se identifica cada medio**: por el NIF de la empresa editora en contratos y subvenciones (por ejemplo, Dos Mil Palabras, S.L. para OKDiario o Libertad Digital, S.A. para Libertad Digital y esRadio) y por el nombre del medio en la publicidad. Si una sociedad edita varias marcas y la fuente no las separa, el dinero va a la sociedad o al grupo. La columna «Identificado por» del detalle dice en cada pago si la fuente dio la cabecera, la sociedad editora o solo el grupo. Lo que no se ha podido atribuir a ningún medio (sobre todo publicidad exterior, programática y agencias) no aparece.

## Fuentes

- [Comisión de Publicidad y Comunicación Institucional, informes anuales](https://www.lamoncloa.gob.es/serviciosdeprensa/cpci/paginas/planeseinformes.aspx): Informe 2025, anexo IV (inversión por grupos) e Informe 2025 de publicidad comercial, anexo III.
- Publicidad institucional por medio: datos abiertos de la [Generalitat de Catalunya](https://analisi.transparenciacatalunya.cat/Sector-P-blic/Campanyes-i-promoci-institucional-de-la-Generalita/8d5a-6vsk), la [Junta de Castilla y León](https://analisis.datosabiertos.jcyl.es/explore/dataset/publicidad-institucional/), el [Gobierno de Aragón](https://www.aragon.es/transparencia/gestion-fondos-publicos/campanas-publicidad-institucional), el [Gobierno de Navarra](https://datosabiertos.navarra.es/dataset/publicidad-institucional), la [Región de Murcia](https://transparencia.carm.es/publicidad-institucional) y el [Ayuntamiento de Madrid](https://datos.madrid.es/dataset/300024-0-publicidad-institucional); informes de la [Generalitat Valenciana](https://gvaoberta.gva.es/va/publicidad-y-promocion-institucional) y, para el País Vasco, la recopilación de [gobiernovasco.marketing](https://gobiernovasco.marketing/) (Jaime Gómez-Obregón, CC BY 4.0).
- [Plataforma de Contratación del Sector Público](https://www.hacienda.gob.es/es-ES/GobiernoAbierto/Datos%20Abiertos/Paginas/licitaciones_plataforma_contratacion.aspx) y plataformas de contratación de Cataluña, Euskadi, Andalucía, Galicia, La Rioja y los ayuntamientos de Madrid y Barcelona.
- [Base de Datos Nacional de Subvenciones](https://www.infosubvenciones.es/bdnstrans/GE/es/concesiones) (IGAE).
- Euros constantes con el IPC del INE. Tabla de medios, sociedades editoras y grupos de SpainFacts (seeds medios_cabeceras y medios_cabeceras_alias).
