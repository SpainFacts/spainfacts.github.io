---
title: Observatorios Públicos
sources:
  - mother.observatorios
---

# Observatorios Públicos en España

Este apartado presenta un análisis de los observatorios públicos en España, basado en los datos recopilados en [observatoriospublicos.es](https://observatoriospublicos.es/).

## Número de Observatorios Creados por Año

<BarChart
    data={data.mother_observatorios}
    x="creation_year"
    y="name"
    type=count
/>

## Estado de los Observatorios

<BarChart
    data={data.mother_observatorios}
    x="is_active"
    y="name"
    type=count
/>

## Alcance de los Observatorios

<BarChart
    data={data.mother_observatorios}
    x="scope"
    y="name"
    type=count
/>