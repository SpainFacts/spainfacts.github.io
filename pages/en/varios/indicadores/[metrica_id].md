---
title: Indicator
description: "Full historical series of an official indicator, with its latest figure and a link to the source."
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: c01ba858333c
---

```sql serie
SELECT periodo, valor, nombre, unidad, fuente, url_fuente, tema, pagina, frecuencia,
    CASE frecuencia
        WHEN 'Anual' THEN strftime(periodo, '%Y')
        WHEN 'Trimestral' THEN strftime(periodo, '%Y') || '-T' || quarter(periodo)
        WHEN 'Semestral' THEN strftime(periodo, '%Y') || '-S' || CASE WHEN month(periodo) <= 6 THEN 1 ELSE 2 END
        WHEN 'Mensual' THEN strftime(periodo, '%Y-%m')
        ELSE strftime(periodo, '%d/%m/%Y')
    END AS etiqueta
FROM mother.metricas
WHERE metrica_id = '${params.metrica_id}'
ORDER BY periodo DESC
```

```sql ultimo
SELECT
    valor,
    unidad,
    etiqueta AS periodo_texto,
    nombre,
    fuente,
    url_fuente,
    tema,
    '/en' || pagina AS pagina,
    frecuencia
FROM ${serie}
ORDER BY periodo DESC
LIMIT 1
```

# {ultimo[0].nombre}

<Grid cols=2>

<div>
    <BigValue
        data={ultimo}
        value=valor
        title="Latest figure ({ultimo[0].periodo_texto})"
        fmt='#,##0.0'
    />
    <p>{ultimo[0].unidad}</p>
</div>

<div>
    <p>
        <b>Source:</b> <a href="{ultimo[0].url_fuente}" target="_blank" rel="noopener noreferrer">{ultimo[0].fuente}<span class="sr-only"> (opens in a new tab)</span></a><br/>
        <b>Frequency:</b> {ultimo[0].frecuencia}<br/>
        <b>Section:</b> <a href="{ultimo[0].pagina}">{ultimo[0].tema}</a> · <a href="/en/varios/indicadores/">All indicators</a><br/>
        <LastRefreshed prefix="Updated" />
    </p>
</div>

</Grid>

<LineChart
    data={serie}
    x=periodo
    y=valor
    yAxisTitle="{ultimo[0].unidad}"
    title="{ultimo[0].nombre}"
/>

<DataTable data={serie} title="Full series" rows=15>
    <Column id=etiqueta title="Period" />
    <Column id=valor title="Value" fmt='#,##0.0' />
</DataTable>
