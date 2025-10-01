---
title: SpainFacts - Datos sobre España
---

# Bienvenido a SpainFacts

SpainFacts es una iniciativa dedicada a proporcionar datos transparentes y objetivos sobre España. Inspirados en la visión de USAFacts, nuestro objetivo es ofrecer información precisa y accesible sobre la población, economía, salud y otros aspectos clave de la sociedad española, para fomentar una comprensión informada y basada en evidencia.

<LastRefreshed/>

## Población de España

Exploramos la composición demográfica de España, incluyendo datos sobre lugar de nacimiento y distribución poblacional.

```sql poblacion_por_nacionalidad
  select "Lugar de nacimiento" as Nacionalidad, sum(Total) as Total
  from test2.poblacion
  group by "Lugar de nacimiento"
  order by Total desc
```

<BarChart
    data={poblacion_por_nacionalidad}
    title="Población por Nacionalidad"
    x="Nacionalidad"
    y=Total
    xAxisTitle="Nacionalidad"
    yAxisTitle="Total de Personas"
/>

## Próximos Pasos

- Explorar más datos sobre economía y salud
- Conectar nuevas fuentes de datos oficiales
- Desarrollar visualizaciones interactivas adicionales

## Recursos

- [Instituto Nacional de Estadística (INE)](https://www.ine.es/)
- [Banco de España](https://www.bde.es/)
- [Ministerio de Sanidad](https://www.sanidad.gob.es/)
