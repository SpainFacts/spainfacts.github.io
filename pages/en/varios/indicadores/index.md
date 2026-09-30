---
description: "Every SpainFacts tracking series with its latest figure, its value a year earlier and a link to the official source. Filter by section or search by name."
title: Indicators
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 8987405fecb5
---

# 📋 Indicators

Every series we track on the site, in one place. Each comes from an official source,
is updated automatically and links to its own page with the full series. Monetary amounts
are per inhabitant and in real euros, as on the rest of SpainFacts.

```sql indicadores_todos
WITH ultimo AS (
    SELECT
        metrica_id,
        max(periodo) AS ultimo_periodo
    FROM mother.metricas
    GROUP BY metrica_id
)
SELECT
    m.metrica_id,
    any_value(m.nombre) AS nombre,
    any_value(m.tema) AS tema,
    any_value(m.frecuencia) AS frecuencia,
    max_by(m.valor, m.periodo) AS ultimo_valor,
    max_by(m.valor, m.periodo) FILTER (WHERE m.periodo <= u.ultimo_periodo - INTERVAL 1 YEAR) AS hace_un_anio,
    any_value(m.unidad) AS unidad,
    CASE any_value(m.frecuencia)
        WHEN 'Anual' THEN strftime(u.ultimo_periodo, '%Y')
        WHEN 'Trimestral' THEN strftime(u.ultimo_periodo, '%Y') || '-T' || quarter(u.ultimo_periodo)
        WHEN 'Semestral' THEN strftime(u.ultimo_periodo, '%Y') || '-S' || CASE WHEN month(u.ultimo_periodo) <= 6 THEN 1 ELSE 2 END
        WHEN 'Mensual' THEN strftime(u.ultimo_periodo, '%Y-%m')
        ELSE strftime(u.ultimo_periodo, '%d/%m/%Y')
    END AS periodo_texto,
    any_value(m.fuente) AS fuente,
    any_value(m.pagina) AS pagina,
    '/en/varios/indicadores/' || m.metrica_id AS enlace
FROM mother.metricas m
JOIN ultimo u USING (metrica_id)
GROUP BY m.metrica_id, u.ultimo_periodo
```

```sql resumen
SELECT
    count(*) AS series,
    count(DISTINCT tema) AS apartados,
    count(DISTINCT fuente) AS fuentes
FROM ${indicadores_todos}
```

```sql temas
SELECT tema, count(*) AS series
FROM ${indicadores_todos}
GROUP BY tema
ORDER BY series DESC
```

```sql frecuencias
SELECT frecuencia,
    CASE frecuencia WHEN 'Diaria' THEN 1 WHEN 'Semanal' THEN 2 WHEN 'Mensual' THEN 3
        WHEN 'Trimestral' THEN 4 WHEN 'Semestral' THEN 5 ELSE 6 END AS orden
FROM ${indicadores_todos}
GROUP BY frecuencia
```

<div class="text-sm text-gray-600 dark:text-gray-400 mb-2">
<Value data={resumen} column=series /> series from <Value data={resumen} column=fuentes /> official sources, spread across <Value data={resumen} column=apartados /> sections.
</div>

<ButtonGroup data={temas} name=tema value=tema title="Section">
    <ButtonGroupItem valueLabel="All" value="Todos" default />
</ButtonGroup>

<Dropdown data={frecuencias} name=frecuencia value=frecuencia order=orden title="Frequency" defaultValue="Todas">
    <DropdownOption value="Todas" valueLabel="All" />
</Dropdown>

```sql indicadores
SELECT *
FROM ${indicadores_todos}
WHERE ('${inputs.tema}' = 'Todos' OR tema = '${inputs.tema}')
  AND ('${inputs.frecuencia.value}' = 'Todas' OR frecuencia = '${inputs.frecuencia.value}')
ORDER BY tema, nombre
```

<DataTable data={indicadores} link=enlace rowShading=true search=true rows=25>
    <Column id=nombre title="Indicator" wrap=true />
    <Column id=tema title="Section" />
    <Column id=ultimo_valor title="Latest value" fmt='#,##0.0' />
    <Column id=hace_un_anio title="A year earlier" fmt='#,##0.0' />
    <Column id=unidad title="Unit" />
    <Column id=periodo_texto title="Period" />
    <Column id=frecuencia title="Frequency" />
    <Column id=fuente title="Source" />
</DataTable>

Click a row to see the full series, the chart and the link to the source.

<LastRefreshed prefix="Data updated" />
