---
description: "Todas las series de seguimiento de SpainFacts con su último dato, su valor hace un año y un enlace a la fuente oficial. Filtra por apartado o busca por nombre."
title: Indicadores
og:
  image: https://spainfacts.org/og-spainfacts.png
---

# 📋 Indicadores

Todas las series que seguimos en la web, en un solo sitio. Cada una procede de una fuente
oficial, se actualiza automáticamente y enlaza a su ficha con la serie completa. Los importes
van por habitante y en euros reales, como en el resto de SpainFacts.

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
    '/varios/indicadores/' || m.metrica_id AS enlace
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
<Value data={resumen} column=series /> series de <Value data={resumen} column=fuentes /> fuentes oficiales, repartidas en <Value data={resumen} column=apartados /> apartados.
</div>

<ButtonGroup data={temas} name=tema value=tema title="Apartado">
    <ButtonGroupItem valueLabel="Todos" value="Todos" default />
</ButtonGroup>

<Dropdown data={frecuencias} name=frecuencia value=frecuencia order=orden title="Frecuencia" defaultValue="Todas">
    <DropdownOption value="Todas" valueLabel="Todas" />
</Dropdown>

```sql indicadores
SELECT *
FROM ${indicadores_todos}
WHERE ('${inputs.tema}' = 'Todos' OR tema = '${inputs.tema}')
  AND ('${inputs.frecuencia.value}' = 'Todas' OR frecuencia = '${inputs.frecuencia.value}')
ORDER BY tema, nombre
```

<DataTable data={indicadores} link=enlace rowShading=true search=true rows=25>
    <Column id=nombre title="Indicador" wrap=true />
    <Column id=tema title="Apartado" />
    <Column id=ultimo_valor title="Último valor" fmt='#,##0.0' />
    <Column id=hace_un_anio title="Hace un año" fmt='#,##0.0' />
    <Column id=unidad title="Unidad" />
    <Column id=periodo_texto title="Periodo" />
    <Column id=frecuencia title="Frecuencia" />
    <Column id=fuente title="Fuente" />
</DataTable>

Pulsa en una fila para ver la serie completa, la gráfica y el enlace a la fuente.

<LastRefreshed prefix="Datos actualizados" />
