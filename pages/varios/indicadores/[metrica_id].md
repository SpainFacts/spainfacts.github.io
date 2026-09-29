---
title: Indicador
description: "Serie histórica completa de un indicador oficial, con su último dato y un enlace a la fuente."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

```sql serie
SELECT periodo, valor, nombre, unidad, fuente, url_fuente
FROM mother.metricas
WHERE metrica_id = '${params.metrica_id}'
ORDER BY periodo
```

```sql ultimo
SELECT
    valor,
    unidad,
    strftime(periodo, '%Y-%m') AS periodo,
    nombre,
    fuente,
    url_fuente
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
        title="Último dato ({ultimo[0].periodo})"
        fmt='#,##0.0'
    />
    <p>{ultimo[0].unidad}</p>
</div>

<div>
    <p>
        <b>Fuente:</b> <a href="{ultimo[0].url_fuente}" target="_blank">{ultimo[0].fuente}</a><br/>
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
    <Column id=periodo title="Periodo" fmt='yyyy-mm' />
    <Column id=valor title="Valor" fmt='#,##0.0' />
</DataTable>
