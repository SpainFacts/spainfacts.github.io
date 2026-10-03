# Capa semántica del chat de datos

Una ficha por tabla que dice explícitamente lo que el traductor del chat (`src/lib/chat/decision.js`) tendría que adivinar: cuál es la cifra principal y su unidad, cómo se guarda el tiempo y el territorio, qué filtros van por defecto y si las cifras se pueden sumar.

`tools/chat/catalogo.mjs` mezcla las fichas en el catálogo (`t.semantica`). Si una tabla no tiene ficha, el traductor usa sus reglas generales.

Las fichas van en `lote-*.json` (un array de fichas por fichero). `node tools/chat/semantica/validar.mjs` comprueba contra los parquets que cada columna y cada valor citado existen.

## Formato

```json
{
  "tabla": "ccaa_deuda",
  "usar": true,
  "tema": "Deuda pública de cada comunidad autónoma",
  "preguntas": ["¿Cuánto debe Cataluña?", "¿Qué comunidad tiene más deuda sobre su PIB?", "¿Cómo ha evolucionado la deuda de Madrid?"],
  "medidas": [
    { "columna": "deuda_pct_pib", "nombre": "deuda en % del PIB regional", "unidad": "% del PIB", "tipo": "porcentaje", "principal": true },
    { "columna": "deuda_eur", "nombre": "deuda en euros", "unidad": "€", "tipo": "nivel" }
  ],
  "tiempo": { "columna": "fecha", "grano": "trimestral", "parcial": false },
  "territorio": {
    "niveles": ["ccaa"],
    "nivel": null,
    "codigo": "cod_ccaa",
    "nombre": "ccaa",
    "espana": null
  },
  "dimensiones": [
    { "columna": "sexo", "nombre": "sexo", "total": "Total" }
  ],
  "filtros": [],
  "notas": "Deuda PDE del Banco de España a fin de trimestre."
}
```

### Campos

| Campo | Qué es |
|---|---|
| `tabla` | Nombre exacto de la tabla (sin `mother.`). |
| `usar` | `false` si la tabla no sirve para responder preguntas de la gente: auxiliar, duplicada de otra mejor, técnica (colores, coordenadas, enlaces), o de metadatos. |
| `tema` | Una frase en castellano llano: de qué trata, como lo diría alguien que pregunta. |
| `preguntas` | 2 a 4 preguntas naturales y distintas que esta tabla responde bien (sirven para la búsqueda semántica). Variadas: dato actual, ranking, territorio, evolución. |
| `medidas` | Columnas numéricas que son cifras que alguien pediría (no códigos, años, órdenes, coordenadas). Para cada una: `nombre` (castellano llano, sin abreviaturas), `unidad` (€, millones de €, %, % del PIB, personas, habitantes, ha, MW, GWh, t CO2, años, €/m², por cada 1.000 habitantes...), `tipo` y `principal: true` en la cifra que mejor responde una pregunta genérica sobre el tema (solo una). |
| `medidas[].tipo` | `flujo` (cuenta cosas que pasan en un periodo y se puede sumar entre meses o entre categorías: matriculaciones, nacimientos, solicitudes, hectáreas quemadas, euros gastados en un año), `nivel` (foto en un momento, no se suma en el tiempo: población, parque, deuda, afiliados, paro registrado), `tasa`, `porcentaje`, `media`, `precio`, `indice`, `ratio` (estos nunca se suman). |
| `medidas[].real` | Opcional: nombre de la columna en euros reales equivalente a esta (si existe). |
| `tiempo` | `columna` con el periodo principal (la de grano más fino que identifica el periodo; no fechas de metadatos como `ultima_fecha`), `grano` (`diario`, `semanal`, `mensual`, `trimestral`, `semestral`, `anual`, `curso`, `sin_tiempo`) y `parcial: true` si el último periodo puede estar incompleto (p. ej. tablas anuales que suman meses del año en curso). `null` si la tabla no tiene tiempo. |
| `territorio` | Cómo se guarda el territorio. `niveles`: los que hay (`pais`, `ccaa`, `provincia`, `municipio`, `cuenca`, `pais_extranjero`...). `nivel`: columna que dice el nivel de cada fila (o `null`). `codigo`/`nombre`: columnas de código y de nombre (o `null`). `espana`: cómo es la fila de España si existe, `{ "columna": "...", "valor": "..." }`, o `null`. `null` todo el objeto si la tabla no tiene territorio. |
| `dimensiones` | Otras columnas de texto por las que se filtra o compara (sexo, edad, sector, grupo, país, partido, tipo...). `total`: el valor que agrupa todo (`Total`, `Ambos sexos`, `Todos`...) o `null` si no hay. `defecto` (opcional): si no hay total pero hay un valor que es el que se quiere cuando la pregunta no dice otro (p. ej. `estado_grupo` = `En operación`: lo que existe hoy, no lo que está en tramitación), ese valor; se aplica también en los rankings. No incluyas columnas de texto libre, enlaces, colores, notas ni las de territorio ya descritas. |
| `filtros` | Filtros que siempre hay que aplicar para no mezclar cosas (p. ej. una columna `serie` con variantes de las que solo una es la normal: `{ "columna": "serie", "valor": "..." }`). Normalmente vacío. |
| `notas` | Trampas o matices en una frase (fuente, si los datos son provisionales, si hay dos definiciones...). |

### Reglas

- Usa los valores exactos de los datos (comprueba con SQL). Las columnas tienen que existir.
- `principal` en una sola medida por tabla.
- Si dudas entre `flujo` y `nivel`, piensa: ¿tiene sentido sumar enero + febrero? Si sí, `flujo`.
- Preguntas en castellano natural, como las haría un ciudadano; sin nombres de columnas.
