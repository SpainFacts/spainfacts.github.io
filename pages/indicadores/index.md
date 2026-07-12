---
title: Indicadores
---

# Indicadores

Cada indicador proviene de una fuente oficial, se actualiza automáticamente a
diario y enlaza a su serie original. Pulsa en cualquiera para ver su ficha.

```sql indicadores
SELECT
    metrica_id,
    nombre,
    max_by(valor, periodo) AS ultimo_valor,
    any_value(unidad) AS unidad,
    max(periodo) AS ultimo_periodo,
    any_value(fuente) AS fuente,
    '/indicadores/' || metrica_id AS enlace
FROM mother.metricas
GROUP BY metrica_id, nombre
ORDER BY nombre
```

<DataTable data={indicadores} link=enlace rowShading=true>
    <Column id=nombre title="Indicador" />
    <Column id=ultimo_valor title="Último valor" fmt='#,##0.0' />
    <Column id=unidad title="Unidad" />
    <Column id=ultimo_periodo title="Periodo" fmt='yyyy-mm' />
    <Column id=fuente title="Fuente" />
</DataTable>

<LastRefreshed prefix="Datos actualizados" />
