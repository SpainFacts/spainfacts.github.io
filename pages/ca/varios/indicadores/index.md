---
description: "Totes les sèries de seguiment de SpainFacts amb l'última dada, el valor de fa un any i un enllaç a la font oficial. Filtra per apartat o cerca pel nom."
title: Indicadors
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 8987405fecb5
---

# 📋 Indicadors

Totes les sèries que seguim al web, en un sol lloc. Cadascuna prové d'una font
oficial, s'actualitza automàticament i enllaça a la seva fitxa amb la sèrie completa. Els imports
van per habitant i en euros reals, com a la resta de SpainFacts.

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
    '/ca/varios/indicadores/' || m.metrica_id AS enlace
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
<Value data={resumen} column=series /> sèries de <Value data={resumen} column=fuentes /> fonts oficials, repartides en <Value data={resumen} column=apartados /> apartats.
</div>

<ButtonGroup data={temas} name=tema value=tema title="Apartat">
    <ButtonGroupItem valueLabel="Tots" value="Todos" default />
</ButtonGroup>

<Dropdown data={frecuencias} name=frecuencia value=frecuencia order=orden title="Freqüència" defaultValue="Todas">
    <DropdownOption value="Todas" valueLabel="Totes" />
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
    <Column id=tema title="Apartat" />
    <Column id=ultimo_valor title="Últim valor" fmt='#,##0.0' />
    <Column id=hace_un_anio title="Fa un any" fmt='#,##0.0' />
    <Column id=unidad title="Unitat" />
    <Column id=periodo_texto title="Període" />
    <Column id=frecuencia title="Freqüència" />
    <Column id=fuente title="Font" />
</DataTable>

Fes clic en una fila per veure la sèrie completa, el gràfic i l'enllaç a la font.

<LastRefreshed prefix="Dades actualitzades" />
