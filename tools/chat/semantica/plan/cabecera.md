# Plan de limpieza del modelo de datos (mother.*)

Plan por tabla de las 180 tablas publicadas que tienen algún problema o ninguna página usa (de 268). Lo escribieron seis agentes leyendo cada modelo dbt, el SQL de las páginas que la usan y los datos; nada se ha cambiado todavía. Cómo deben quedar las tablas: [CONVENCIONES.md](CONVENCIONES.md). Inventario de partida: `node tools/chat/semantica/inventario.mjs`.

**Decidido por el dueño (2026-10-03):** se hacen las fases 0 a 4. Las columnas mal formadas **se sustituyen** (no se añaden al lado) y se cambian a la vez las páginas que las usan y sus traducciones: la web está en desarrollo y se prefiere un modelo limpio. Decisiones 1, 2, 3, 5, 6 y 7: como se proponen (6 hecho: seed paises_iso, deflactor_paises, poblacion_paises y deflactor desde 1996). Decisión 4: potencia de centrales por comunidad en totales; emisiones, exportaciones y deuda local con las dos cifras (por habitante y total).

## Fases

| Fase | Qué | Tablas | Toca páginas | Necesita |
|---|---|---|---|---|
| 0 | Errores que ya se ven en la web (abajo) | 4 | no (salvo 1 línea) | — |
| 1 | Columnas por habitante, euros reales y nombres de territorio en las de prioridad 1 | 35 | no | extracción completa `[datos]` |
| 2 | Lo mismo en las de prioridad 2 (proporciones a `_pct`, unidades, totales, España) | 62 | no | `[datos]` |
| 3 | Pasar páginas a las columnas nuevas (gráficas absolutas a por habitante, nominal a real) | por grupos | sí, con traducciones | tu visto bueno por grupo |
| 4 | Borrar tablas y partir las que mezclan fuentes o periodos | 8 + ~4 | sí en las partidas | tu visto bueno |
| 5 | Cosmético (prioridad 3) | 53 | no | — |

Cada fase acaba con: `dbt build` de los modelos tocados, extracción, fichas semánticas actualizadas (`validar.mjs` a 0 errores), build y pruebas (i18n, estática, humo), y la batería del chat.

## Fase 0: errores que ya se ven en la web

- **`mercado_paro_territorios` no tiene fila de España**: las páginas de comunidad y provincia la piden (`e.nivel = 'pais'`) y la tasa de paro de España sale siempre vacía. Se arregla añadiendo la fila en el modelo, sin tocar páginas.
- **`[ccaa]` deflacta con `coalesce(f.factor, 1)`**: un año sin deflactor cuenta como si no hubiera inflación. Mejor vacío.
- **`pages/territorios/municipios.md` (línea ~455, y sus 4 traducciones)** antepone «Distrito » a un valor que ya lo lleva: sale «Distrito Distrito 01».
- **`gobierno_indultos_mensual` tiene una fila del año 1200** que se cuela en rankings y evoluciones: se filtra en el modelo.
- Ya corregido en las fichas del chat (sin tocar datos): tasas de criminalidad y recuentos que el chat multiplicaba por 100, ceros de turismo, `defecto: PRACT` de sanidad, `es_ue` de renta_ue.

## Decisiones que necesitan tu visto bueno

1. **Euros reales y por habitante dentro de cada tabla** (fase 1, 35 tablas): columnas `*_real`, `*_hab`, `*_hab_real` y `anio_base`, con `mother.deflactor` y `poblacion_territorios`. Hoy muchas páginas lo calculan a mano, cada una a su manera (empleo público reconstruye el IPC por su cuenta). Propuesta: un año sin deflactor da vacío (no «sin inflación»), y el nombre estándar es `anio_base` (hoy conviven `anio_base` y `anio_euros`).
2. **Alargar `mother.deflactor` hasta 1996** con el IPCA de Eurostat (hoy empieza en 2002; `construccion_deflactor` ya lo hace solo para construcción). Sin esto, la deuda autonómica (desde 1994) y otras series largas no tienen euros reales antes de 2002.
3. **Borrar 8 tablas que nadie usa**: `alcaldes_resumen_familias` (es `alcaldes_familias_territorio` con nivel país), `ipc` (la cubren `mercado_ipc_*`), `observatorios` (la sustituye `observatorios_detalle`), `totalAno`, `totalAnoProvincia`, `totalAnoSexo`, `totalAnoSexoEdad` (la primera versión; las sustituye `poblacion_territorios`) y `unemployment`. Con `unemployment` se pierde el cruce sexo × edad del paro; la alternativa es rehacerla limpia como `mercado_paro_sexo_edad`.
4. **Gráficas que hoy enseñan totales** y deberían enseñar por habitante (fase 3): potencia eléctrica por comunidad (GW a W por habitante), emisiones por sector, mix eléctrico, exportaciones, deuda local, matriculaciones; y tarjetas que comparan euros nominales entre décadas (esfuerzo de vivienda, PIE). Cada una toca la página y sus 4 traducciones.
5. **Partir tablas que mezclan fuentes o periodos** (fase 4, rompe consultas de páginas): `construccion_permisos` (UE / comunidades / serie larga de España, con España tres veces), `industria_ipi` (Eurostat / INE / INE por división), `empresas_autonomos` (trimestre 0 = media anual). La fase 2 solo les añade columnas para distinguirlas; partirlas es opcional.
6. **Países**: un seed común `paises_iso` (ISO3 → ISO2, `EUU` → `EU27_2020`) para las tablas internacionales, que hoy usan tres codificaciones. Y, si quieres euros reales de otros países, ingerir el IPCA por país de Eurostat (`prc_hicp_aind`), que hoy no se descarga.
7. **Tablas auxiliares que usan las páginas** (`metricas`, `mapas_indicadores`): quedarse en mother.* marcadas como auxiliares (el chat ya las ignora) en vez de moverlas a otro esquema, que obligaría a tocar todas las páginas que las leen.

## Recetas comunes (ya usadas en el repo)

- **Euros reales:** `left join {{ ref('deflactor') }} d on d.anio = x.anio` → `importe * d.factor as importe_real`, `d.anio_base` (ejemplos: `sanidad_gasto_ccaa`, `renta_distritos`, `construccion_ccaa`).
- **Por habitante:** `{{ ref('poblacion_territorios') }}` (`sexo = 'Total'`, año acotado al rango disponible) o `poblacion_municipios`; países UE en `raw_industria.eurostat_industria_poblacion`, extranjeros en `internacional_comparativa` (indicador `poblacion`).
- **Nombre de territorio:** `left join {{ ref('territorios') }} t on t.nivel = x.nivel and t.cod = x.cod` (ejemplo: `pensiones_territorio`). `poblacion_territorios` no puede usar `territorios` (ciclo): sale de `territorios_ccaa`/`territorios_provincias`.
- Si `sources/mother/<tabla>.sql` enumera columnas en vez de `SELECT *`, hay que añadir ahí las nuevas.
- En el parquet publicado los números salen como DOUBLE (también `anio`); las páginas ya hacen `CAST(anio AS INTEGER)`.
