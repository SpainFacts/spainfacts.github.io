---
title: Indicador
description: "Serie histórica completa de un indicador oficial, con su último dato y un enlace a la fuente."
og:
  image: https://spainfacts.org/og-spainfacts.png
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
    pagina,
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
        title="Último dato ({ultimo[0].periodo_texto})"
        fmt='#,##0.0'
    />
    <p>{ultimo[0].unidad}</p>
</div>

<div>
    <p>
        <b>Fuente:</b> <a href="{ultimo[0].url_fuente}" target="_blank" rel="noopener noreferrer">{ultimo[0].fuente}<span class="sr-only"> (se abre en una pestaña nueva)</span></a><br/>
        <b>Frecuencia:</b> {ultimo[0].frecuencia}<br/>
        <b>Apartado:</b> <a href="{ultimo[0].pagina}">{ultimo[0].tema}</a> · <a href="/varios/indicadores/">Todos los indicadores</a><br/>
        <LastRefreshed prefix="Actualizado" />
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

<DataTable data={serie} title="Serie completa" rows=15>
    <Column id=etiqueta title="Periodo" />
    <Column id=valor title="Valor" fmt='#,##0.0' />
</DataTable>
