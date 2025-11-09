---
title: Observatorios Públicos
sources:
  - mother.observatorios
---

# Observatorios Públicos en España

Este apartado presenta un análisis de los observatorios públicos en España, basado en los datos recopilados en [observatoriospublicos.es](https://observatoriospublicos.es/).

## Número de Observatorios Creados por Año
```sql mother_observatorios
  SELECT count(*) AS count, creation_year
  FROM mother.observatorios
  where creation_year is not null
    GROUP BY creation_year
```

<BarChart
    data={mother_observatorios}
    x="creation_year"
    y="count"
    type=count
    yScale={true}
/>

## Estado de los Observatorios


```sql mother_observatorios_full
  SELECT *
  FROM mother.observatorios
```


```sql mother_observatorios_active
  SELECT  IF(is_active, 'Activo', 'Inactivo') as name,count(*) AS value
  FROM mother.observatorios
  GROUP BY is_active
```

<ECharts config={
    {
        tooltip: {
            formatter: '{b}: {c} ({d}%)'
        },
        series: [
        {
          type: 'pie',
          data: [...mother_observatorios_active],
        }
      ]
      }
    }
    />

## Alcance de los Observatorios
```sql mother_observatorios_scope
  SELECT count(*) AS count, scope
  FROM mother.observatorios
  GROUP BY scope    
```
<BarChart
    data={mother_observatorios_scope}
    x="scope"
    y="count"
    type=count
/>