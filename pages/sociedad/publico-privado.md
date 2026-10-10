---
title: Público y privado
description: "Cuánto de la sanidad y la educación públicas se presta a través de empresas y centros privados, comunidad a comunidad: conciertos sanitarios, hospitales de concesión, seguros privados, escuela concertada, FP y universidades privadas."
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../src/lib/utils.js';
</script>

```sql conc
-- Conciertos sanitarios (EGSP): peso en el gasto sanitario público y euros reales por habitante
SELECT CAST(anio AS INTEGER) AS anio, cod_ccaa, ccaa, peso_pct, gasto_eur_hab_real, gasto_meur, provisional, anio_base
FROM mother.sanidad_privada_gasto
WHERE clasificacion = 'economica' AND partida_id = 'conciertos'
ORDER BY anio
```

```sql conc_ult
SELECT c.*, t.ruta, CASE WHEN c.cod_ccaa = '00' THEN 'Total comunidades' ELSE c.ccaa END AS comunidad
FROM ${conc} c
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod_ccaa
WHERE c.anio = (SELECT max(anio) FROM ${conc})
ORDER BY c.peso_pct DESC
```

```sql conc_madrid
SELECT anio, peso_pct AS valor, gasto_eur_hab_real, anio_base FROM ${conc} WHERE cod_ccaa = '13' ORDER BY anio
```

```sql conc_hitos
SELECT
    min(anio) FILTER (WHERE cod_ccaa = '13') AS anio_ini,
    max(anio) FILTER (WHERE cod_ccaa = '13') AS anio_ult,
    arg_min(gasto_eur_hab_real, anio) FILTER (WHERE cod_ccaa = '13') AS mad_ini,
    arg_max(gasto_eur_hab_real, anio) FILTER (WHERE cod_ccaa = '13') AS mad_ult,
    arg_min(peso_pct, anio) FILTER (WHERE cod_ccaa = '13') AS mad_pct_ini,
    arg_max(peso_pct, anio) FILTER (WHERE cod_ccaa = '13') AS mad_pct_ult,
    arg_min(gasto_eur_hab_real, anio) FILTER (WHERE cod_ccaa = '00') AS tot_ini,
    arg_max(gasto_eur_hab_real, anio) FILTER (WHERE cod_ccaa = '00') AS tot_ult,
    arg_max(peso_pct, anio) FILTER (WHERE cod_ccaa = '00') AS tot_pct_ult,
    arg_max(peso_pct, anio) FILTER (WHERE cod_ccaa = '09') AS cat_pct_ult,
    arg_max(peso_pct, anio) FILTER (WHERE cod_ccaa = '10') AS val_pct_ult,
    max(anio_base) AS anio_base
FROM ${conc}
```

```sql cob
-- Población con hospital de referencia de gestión privada (concesión capitativa y concierto singular)
SELECT CAST(anio AS INTEGER) AS anio, cod_ccaa, ccaa, poblacion_gestion_privada_pct, poblacion_gestion_privada,
       poblacion_concesion, poblacion_concierto_singular, poblacion_pfi_pct, hospitales_gestion_privada
FROM mother.sanidad_privada_cobertura
ORDER BY anio
```

```sql cob_madrid
SELECT anio, poblacion_gestion_privada_pct AS valor FROM ${cob} WHERE cod_ccaa = '13' ORDER BY anio
```

```sql cob_hitos
SELECT
    max(anio) AS anio_ult,
    arg_max(poblacion_gestion_privada_pct, anio) FILTER (WHERE cod_ccaa = '13') AS mad_pct,
    arg_max(poblacion_gestion_privada, anio) FILTER (WHERE cod_ccaa = '13') AS mad_pob,
    arg_max(poblacion_concesion, anio) FILTER (WHERE cod_ccaa = '13') AS mad_concesion,
    arg_max(poblacion_pfi_pct, anio) FILTER (WHERE cod_ccaa = '13') AS mad_pfi_pct,
    max(poblacion_gestion_privada_pct) FILTER (WHERE cod_ccaa = '10') AS val_max,
    arg_max(poblacion_gestion_privada_pct, anio) FILTER (WHERE cod_ccaa = '10') AS val_pct
FROM ${cob}
```

```sql cob_graf
SELECT anio, ccaa AS comunidad, poblacion_gestion_privada_pct / 100 AS cuota
FROM ${cob}
ORDER BY anio
```

```sql hospitales_lista
SELECT ccaa AS comunidad, hospital, municipio,
       CASE modelo WHEN 'concesion_capitativa' THEN 'Concesión (pago por habitante)'
                   WHEN 'concierto_singular' THEN 'Concierto singular (pago por acto)'
                   ELSE 'Obra y servicios no sanitarios (PFI)' END AS modelo,
       empresa_actual AS empresa,
       CAST(anio_inicio AS INTEGER) AS inicio,
       CASE WHEN en_gestion_privada THEN 'Sigue' ELSE 'Revertido en ' || CAST(CAST(anio_reversion AS INTEGER) AS VARCHAR) END AS estado,
       poblacion_asignada AS poblacion
FROM mother.sanidad_privada_gestion_privada
WHERE anio_inicio IS NOT NULL
ORDER BY ccaa, CASE modelo WHEN 'pfi_no_sanitaria' THEN 2 ELSE 1 END, anio_inicio
```

```sql seg
-- Seguro privado (Barómetro Sanitario, Ministerio de Sanidad)
SELECT CAST(b.anio AS INTEGER) AS anio, b.cod_ccaa, coalesce(t.nombre, 'España') AS comunidad, t.ruta,
       b.seguro_privado_pct, b.seguro_individual_pct, b.seguro_empresa_pct
FROM mother.sanidad_privada_seguros_barometro b
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = b.cod_ccaa
ORDER BY anio
```

```sql seg_es
SELECT anio, seguro_privado_pct AS valor FROM ${seg} WHERE cod_ccaa = '00' ORDER BY anio
```

```sql seg_ult
SELECT * FROM ${seg} WHERE anio = (SELECT max(anio) FROM ${seg}) ORDER BY seguro_privado_pct DESC
```

```sql seg_hitos
SELECT
    min(anio) AS anio_ini, max(anio) AS anio_ult,
    arg_min(seguro_privado_pct, anio) FILTER (WHERE cod_ccaa = '00') AS es_ini,
    arg_max(seguro_privado_pct, anio) FILTER (WHERE cod_ccaa = '00') AS es_ult,
    arg_max(seguro_privado_pct, anio) FILTER (WHERE cod_ccaa = '13') AS mad_ult
FROM ${seg}
```

```sql hogares
SELECT CAST(h.anio AS INTEGER) AS anio, coalesce(t.nombre, 'España') AS comunidad, h.cod_ccaa,
       h.gasto_persona_eur_real, h.gasto_persona_eur
FROM mother.sanidad_privada_gasto_hogares h
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = h.cod_ccaa
WHERE h.serie_epf = 'ecoicop' AND h.cod_ccaa IN ('00', '09', '10', '13')
ORDER BY anio
```

```sql camas
-- Camas de hospitales privados (o de ONG) que trabajan como red pública: Catálogo Nacional de Hospitales
SELECT coalesce(t.nombre, 'España') AS comunidad, h.cod_ccaa, CAST(h.anio AS INTEGER) AS anio,
       sum(h.camas_pct) FILTER (WHERE h.privado_en_red_publica) / 100 AS cuota_red,
       sum(h.camas_pct) FILTER (WHERE NOT h.privado_en_red_publica AND h.dependencia_grupo <> 'publica') / 100 AS cuota_privada_sola
FROM mother.sanidad_privada_hospitales h
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = h.cod_ccaa
WHERE h.anio = (SELECT max(anio) FROM mother.sanidad_privada_hospitales)
GROUP BY ALL
ORDER BY cuota_red DESC
```

```sql alu
-- Alumnado no universitario por titularidad del centro (EDUCAbase)
SELECT CAST(anio AS INTEGER) AS anio, curso, cod_ccaa, ccaa, ensenanza, orden_ensenanza, titularidad, cuota_pct, alumnos
FROM mother.educacion_privada_alumnado
WHERE es_avance = false
```

```sql alu_ult
SELECT a.*, CASE WHEN a.cod_ccaa = '00' THEN 'España' ELSE a.ccaa END AS comunidad
FROM ${alu} a
WHERE a.anio = (SELECT max(anio) FROM ${alu} WHERE titularidad = 'Privada concertada')
  AND a.ensenanza = 'Total' AND a.titularidad IN ('Privada concertada', 'Privada no concertada')
```

```sql alu_rank
SELECT comunidad, cod_ccaa, max(curso) AS curso,
       sum(cuota_pct) FILTER (WHERE titularidad = 'Privada concertada') / 100 AS concertada,
       sum(cuota_pct) FILTER (WHERE titularidad = 'Privada no concertada') / 100 AS no_concertada,
       sum(cuota_pct) / 100 AS privada
FROM ${alu_ult}
GROUP BY ALL
ORDER BY privada DESC
```

```sql alu_graf
SELECT comunidad, 'Concertada' AS titularidad, concertada AS cuota, privada FROM ${alu_rank}
UNION ALL
SELECT comunidad, 'Privada sin concierto' AS titularidad, no_concertada AS cuota, privada FROM ${alu_rank}
ORDER BY privada DESC
```

```sql alu_es
SELECT anio, cuota_pct AS valor FROM ${alu}
WHERE cod_ccaa = '00' AND ensenanza = 'Total' AND titularidad = 'Privada'
ORDER BY anio
```

```sql alu_hitos
SELECT
    max(curso) AS curso_ult,
    arg_max(cuota_pct, anio) FILTER (WHERE cod_ccaa = '00' AND titularidad = 'Privada') AS es_priv,
    arg_max(cuota_pct, anio) FILTER (WHERE cod_ccaa = '00' AND titularidad = 'Privada no concertada') AS es_nc,
    arg_max(cuota_pct, anio) FILTER (WHERE cod_ccaa = '13' AND titularidad = 'Privada') AS mad_priv,
    arg_max(cuota_pct, anio) FILTER (WHERE cod_ccaa = '13' AND titularidad = 'Privada no concertada') AS mad_nc,
    arg_min(curso, anio) FILTER (WHERE cod_ccaa = '00' AND titularidad = 'Privada') AS curso_ini,
    arg_min(cuota_pct, anio) FILTER (WHERE cod_ccaa = '00' AND titularidad = 'Privada') AS es_priv_ini,
    arg_min(cuota_pct, anio) FILTER (WHERE cod_ccaa = '13' AND titularidad = 'Privada') AS mad_priv_ini
FROM ${alu}
WHERE ensenanza = 'Total' AND anio <= (SELECT max(anio) FROM ${alu} WHERE titularidad = 'Privada concertada')
```

```sql alu_etapa
SELECT ensenanza, orden_ensenanza, CASE WHEN cod_ccaa = '00' THEN 'España' ELSE 'Madrid' END AS zona,
       cuota_pct / 100 AS cuota
FROM ${alu}
WHERE cod_ccaa IN ('00', '13') AND titularidad = 'Privada no concertada' AND ensenanza <> 'Total'
  AND anio = (SELECT max(anio) FROM ${alu} WHERE titularidad = 'Privada no concertada')
ORDER BY orden_ensenanza
```

```sql conc_edu
-- Conciertos y subvenciones a la enseñanza privada (Estadística del Gasto Público en Educación)
SELECT CAST(anio AS INTEGER) AS anio, cod_ccaa, CASE WHEN cod_ccaa = '00' THEN 'España' ELSE ccaa END AS comunidad,
       conciertos_eur_hab_real, peso_pct, conciertos_eur_alumno_real, conciertos_meur, anio_base
FROM mother.educacion_privada_conciertos
ORDER BY anio
```

```sql conc_edu_ult
SELECT c.*, t.ruta FROM ${conc_edu} c
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = c.cod_ccaa
WHERE c.anio = (SELECT max(anio) FROM ${conc_edu})
ORDER BY conciertos_eur_hab_real DESC
```

```sql conc_edu_hitos
SELECT
    min(anio) AS anio_ini, max(anio) AS anio_ult, max(anio_base) AS anio_base,
    arg_min(conciertos_eur_hab_real, anio) FILTER (WHERE cod_ccaa = '00') AS es_ini,
    arg_max(conciertos_eur_hab_real, anio) FILTER (WHERE cod_ccaa = '00') AS es_ult,
    arg_min(conciertos_eur_hab_real, anio) FILTER (WHERE cod_ccaa = '13') AS mad_ini,
    arg_max(conciertos_eur_hab_real, anio) FILTER (WHERE cod_ccaa = '13') AS mad_ult,
    arg_max(peso_pct, anio) FILTER (WHERE cod_ccaa = '00') AS es_peso,
    arg_max(peso_pct, anio) FILTER (WHERE cod_ccaa = '13') AS mad_peso
FROM ${conc_edu}
WHERE anio >= 2000
```

```sql fp_dist
-- FP a distancia en centros privados, España
SELECT CAST(anio AS INTEGER) AS anio, curso, grado, cuota_pct / 100 AS cuota, alumnos
FROM mother.educacion_privada_fp
WHERE cod_ccaa = '00' AND familia = 'Total' AND modalidad = 'A distancia' AND titularidad = 'Privada' AND grado IN ('Medio', 'Superior')
ORDER BY anio
```

```sql fp_hitos
SELECT
    min(curso) AS curso_ini, max(curso) AS curso_ult,
    arg_min(alumnos, anio) FILTER (WHERE grado = 'Superior') AS sup_ini,
    arg_max(alumnos, anio) FILTER (WHERE grado = 'Superior') AS sup_ult,
    arg_min(cuota, anio) FILTER (WHERE grado = 'Superior') AS sup_cuota_ini,
    arg_max(cuota, anio) FILTER (WHERE grado = 'Superior') AS sup_cuota_ult
FROM ${fp_dist}
```

```sql fp_familia
-- Grado superior: cuota privada por familia profesional, España y Madrid, último curso
SELECT familia, CASE WHEN cod_ccaa = '00' THEN 'España' ELSE 'Madrid' END AS zona, cuota_pct / 100 AS cuota,
       max(cuota_pct) FILTER (WHERE cod_ccaa = '00') OVER (PARTITION BY familia) AS orden
FROM mother.educacion_privada_fp
WHERE cod_ccaa IN ('00', '13') AND grado = 'Superior' AND modalidad = 'Todas' AND titularidad = 'Privada' AND familia <> 'Total'
  AND anio = (SELECT max(anio) FROM mother.educacion_privada_fp)
QUALIFY max(alumnos) FILTER (WHERE cod_ccaa = '00') OVER (PARTITION BY familia) >= 5000
ORDER BY orden DESC
```

```sql uni
SELECT CAST(u.anio AS INTEGER) AS anio, u.curso, u.cod_ccaa, CASE WHEN u.cod_ccaa = '00' THEN 'España' ELSE u.ccaa END AS comunidad,
       u.nivel, u.modalidad, u.cuota_pct, u.estudiantes, u.es_provisional
FROM mother.educacion_privada_universidades u
WHERE u.tipo_universidad = 'Privada'
```

```sql uni_grado_ult
SELECT u.comunidad, u.cod_ccaa, u.curso, u.cuota_pct / 100 AS cuota, t.ruta
FROM ${uni} u
LEFT JOIN mother.territorios t ON t.nivel = 'ccaa' AND t.cod = u.cod_ccaa
WHERE u.nivel = 'Grado' AND u.modalidad = 'Presencial' AND NOT u.es_provisional
  AND u.anio = (SELECT max(anio) FROM ${uni} WHERE nivel = 'Grado' AND modalidad = 'Presencial' AND NOT es_provisional)
ORDER BY cuota DESC
```

```sql uni_serie
SELECT anio, curso, comunidad, comunidad || ' · ' || CASE WHEN nivel = 'Grado' THEN 'Grado presencial' ELSE 'Máster (todas las modalidades)' END AS serie,
       cuota_pct / 100 AS cuota
FROM ${uni}
WHERE cod_ccaa IN ('00', '13') AND ((nivel = 'Grado' AND modalidad = 'Presencial') OR (nivel = 'Máster' AND modalidad = 'Todas'))
  AND anio >= 2000
ORDER BY anio
```

```sql uni_hitos
SELECT
    arg_max(cuota_pct, anio) FILTER (WHERE cod_ccaa = '00' AND nivel = 'Grado' AND modalidad = 'Presencial' AND NOT es_provisional) AS es_grado,
    arg_max(cuota_pct, anio) FILTER (WHERE cod_ccaa = '13' AND nivel = 'Grado' AND modalidad = 'Presencial' AND NOT es_provisional) AS mad_grado,
    arg_max(curso, anio) FILTER (WHERE cod_ccaa = '00' AND nivel = 'Grado' AND modalidad = 'Presencial' AND NOT es_provisional) AS curso_grado,
    arg_max(cuota_pct, anio) FILTER (WHERE cod_ccaa = '00' AND nivel = 'Máster' AND modalidad = 'Todas') AS es_master,
    arg_max(curso, anio) FILTER (WHERE cod_ccaa = '00' AND nivel = 'Máster' AND modalidad = 'Todas') AS curso_master,
    arg_min(cuota_pct, anio) FILTER (WHERE cod_ccaa = '00' AND nivel = 'Máster' AND modalidad = 'Todas' AND anio >= 2011) AS es_master_2011
FROM ${uni}
```

```sql uni_es
SELECT anio, cuota_pct AS valor FROM ${uni}
WHERE cod_ccaa = '00' AND nivel = 'Grado y máster' AND modalidad = 'Todas' AND anio >= 2000
ORDER BY anio
```

```sql uni_num
SELECT CAST(anio AS INTEGER) AS anio, curso, universidades
FROM mother.educacion_privada_universidades_numero
WHERE cod_ccaa = '00' AND tipo_universidad = 'Privada' AND modalidad = 'Todas'
ORDER BY anio
```

# 🏥 Público y privado

La sanidad y la educación son públicas y gratuitas, pero una parte creciente se presta a través de empresas y centros privados pagados con dinero público, y otra la pagan las familias de su bolsillo. Esta página mide, comunidad a comunidad, cuánto hay de cada cosa: conciertos sanitarios, hospitales públicos gestionados por empresas, seguros privados, escuela concertada, FP y universidades privadas. Las cifras van por habitante o en porcentaje, y los euros, descontada la inflación.

<Grid cols=4>
    <KpiCard
        title="Madrid: sanidad pública pagada a centros privados"
        value={conc_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(conc_madrid.slice(-1)[0]?.valor, 1)} %"
        period="del gasto sanitario público en conciertos en {conc_madrid.slice(-1)[0]?.anio} · {formatNumber(conc_madrid.slice(-1)[0]?.gasto_eur_hab_real, 0)} € por habitante (euros de {conc_madrid.slice(-1)[0]?.anio_base})"
        source="Ministerio de Sanidad (EGSP)"
        sparklineData={conc_madrid}
    />
    <KpiCard
        title="Madrid: población con hospital de gestión privada"
        value={cob_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(cob_madrid.slice(-1)[0]?.valor, 1)} %"
        period="en {cob_madrid.slice(-1)[0]?.anio} · {formatNumber(cob_hitos[0]?.mad_pob, 0)} personas"
        source="SERMAS · memorias de los hospitales"
        sparklineData={cob_madrid}
    />
    <KpiCard
        title="Con seguro médico privado"
        value={seg_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(seg_es.slice(-1)[0]?.valor, 1)} %"
        period="de la población en {seg_es.slice(-1)[0]?.anio} · Madrid: {formatNumber(seg_hitos[0]?.mad_ult, 1)} %"
        source="Barómetro Sanitario"
        sparklineData={seg_es}
    />
    <KpiCard
        title="Alumnos en centros privados"
        value={alu_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(alu_es.slice(-1)[0]?.valor, 1)} %"
        period="de infantil a FP, curso {alu_hitos[0]?.curso_ult} · Madrid: {formatNumber(alu_hitos[0]?.mad_priv, 1)} %"
        source="Ministerio de Educación"
        sparklineData={alu_es}
    />
</Grid>

<p class="text-xs text-gray-500">Centros privados de enseñanza: concertados (financiados con fondos públicos) y sin concierto. El seguro privado es la respuesta de los encuestados del Barómetro Sanitario, que tiene en cuenta el seguro individual y el de empresa.</p>

## Sanidad

### Cuánto paga la sanidad pública a centros privados

Todas las comunidades derivan pacientes a clínicas privadas para pruebas, operaciones o especialidades concretas: son los conciertos. En {conc_hitos[0]?.anio_ult} el conjunto de las comunidades dedicó a ellos el {formatNumber(conc_hitos[0]?.tot_pct_ult, 1)} % de su gasto sanitario. Cataluña ({formatNumber(conc_hitos[0]?.cat_pct_ult, 1)} %) y Madrid ({formatNumber(conc_hitos[0]?.mad_pct_ult, 1)} %) son las que más. La línea marca el 15 %, el umbral que el exconsejero vasco y exdirectivo de la OMS Rafael Bengoa sitúa como el máximo que los sistemas europeos suelen querer contratar fuera.

<BarChart
    data={conc_ult}
    x=comunidad
    y=peso_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#0f766e']}
    title="Peso de los conciertos en el gasto sanitario público, {conc_ult[0]?.anio} (%)"
>
    <ReferenceLine y=15 label="15 %" color="#dc2626" />
</BarChart>

```sql conc_lineas
SELECT anio, CASE WHEN cod_ccaa = '00' THEN 'Total comunidades' ELSE ccaa END AS comunidad, gasto_eur_hab_real
FROM ${conc}
WHERE cod_ccaa IN ('00', '09', '10', '13')
ORDER BY anio
```

En euros por habitante y descontada la inflación, Madrid ha pasado de {formatNumber(conc_hitos[0]?.mad_ini, 0)} € en {conc_hitos[0]?.anio_ini} a {formatNumber(conc_hitos[0]?.mad_ult, 0)} € en {conc_hitos[0]?.anio_ult}; el conjunto de comunidades, de {formatNumber(conc_hitos[0]?.tot_ini, 0)} € a {formatNumber(conc_hitos[0]?.tot_ult, 0)} €. El salto de Madrid coincide con la apertura de los hospitales de concesión de Torrejón (2011), Rey Juan Carlos (2012) y Villalba (2014), que la estadística sí cuenta como conciertos.

<LineChart
    data={conc_lineas}
    x=anio
    y=gasto_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Gasto sanitario público en conciertos por habitante (euros de {conc_hitos[0]?.anio_base})"
/>

<p class="text-xs text-gray-500">Estadística de Gasto Sanitario Público (Ministerio de Sanidad), gasto consolidado de las comunidades autónomas. Conciertos: asistencia comprada a centros ajenos (hospitalaria, especializada, primaria, traslado de enfermos) y a otras administraciones. Los dos últimos años son provisionales. <b>Cataluña</b>: su peso alto viene de la red histórica de hospitales concertados sin ánimo de lucro (fundaciones, órdenes religiosas, consorcios del SISCAT), no de empresas con ánimo de lucro. <b>Comunitat Valenciana</b>: la estadística no anota como conciertos los pagos por habitante a los hospitales de concesión del modelo Alzira; el {formatNumber(conc_hitos[0]?.val_pct_ult, 1)} % de {conc_hitos[0]?.anio_ult} no significa poca privatización (ver «Cómo se han leído estos datos»).</p>

### Privatizar el aseguramiento: hospitales que cobran por habitante

Más allá de los conciertos, Madrid y la Comunitat Valenciana son las únicas comunidades que han entregado a empresas la atención completa de zonas enteras: la administración paga a la concesionaria una cantidad fija por cada habitante asignado y la empresa se hace responsable de su salud. José Manuel Freire, profesor emérito de la Escuela Nacional de Sanidad, lo llama privatizar el aseguramiento. En la Comunitat Valenciana llegó a cubrir al {formatNumber(cob_hitos[0]?.val_max, 1)} % de la población; tras las reversiones iniciadas en 2018 queda el {formatNumber(cob_hitos[0]?.val_pct, 1)} % (solo el Vinalopó, en Elche). En Madrid alcanza al {formatNumber(cob_hitos[0]?.mad_pct, 1)} % ({formatNumber(cob_hitos[0]?.mad_pob, 0)} personas en {cob_hitos[0]?.anio_ult}, {formatNumber(cob_hitos[0]?.mad_concesion, 0)} de ellas en concesiones por habitante y el resto en la Fundación Jiménez Díaz, que cobra por acto).

<LineChart
    data={cob_graf}
    x=anio
    y=cuota
    series=comunidad
    yFmt=pct0
    xFmt="####"
    step=true
    colorPalette={['#f97316', '#dc2626']}
    title="Población con hospital de referencia de gestión privada (% de la comunidad)"
/>

<DataTable data={hospitales_lista} rows=20>
    <Column id=comunidad title="Comunidad" />
    <Column id=hospital title="Hospital" />
    <Column id=modelo title="Modelo" />
    <Column id=empresa title="Empresa" />
    <Column id=inicio title="Desde" fmt="0" />
    <Column id=estado title="Situación" />
    <Column id=poblacion title="Población asignada" fmt="#,##0" />
</DataTable>

<p class="text-xs text-gray-500">Población asignada: la más reciente publicada por cada hospital o consejería (memorias del SERMAS, decretos de reversión del DOGV); en los años sin cifra oficial se estima manteniendo el peso de cada hospital en su comunidad, por lo que la serie es aproximada. Además, el {formatNumber(cob_hitos[0]?.mad_pfi_pct, 1)} % de los madrileños tiene como hospital uno de los construidos desde 2008 por empresas que cobran un canon durante 30 años y gestionan los servicios no sanitarios (limpieza, cocina, mantenimiento); su personal sanitario es público y no se cuentan en la gráfica. El Catálogo Nacional de Hospitales clasifica los hospitales de concesión como públicos.</p>

### Madrid: la lista de espera que no se publica

```sql le_anual
-- Lista de espera completa del SERMAS a 31 de diciembre (memoria anual): con y sin cita, por 1.000 habitantes
SELECT CAST(anio AS INTEGER) AS anio,
       sum(total) AS total, sum(sin_cita) AS sin_cita, sum(con_cita) AS con_cita,
       sum(total_por_1000_hab) AS total_1000, sum(sin_cita_por_1000_hab) AS sin_cita_1000
FROM mother.sermas_lista_espera
WHERE especialidad = 'Total'
GROUP BY ALL
ORDER BY anio
```

```sql le_graf
SELECT anio, 'Con cita' AS situacion, (total_1000 - sin_cita_1000) AS por_1000 FROM ${le_anual}
UNION ALL
SELECT anio, 'Sin cita' AS situacion, sin_cita_1000 AS por_1000 FROM ${le_anual}
ORDER BY anio
```

```sql le_hitos
SELECT
    max(anio) AS anio_ult,
    arg_max(total, anio) AS total_ult,
    arg_max(sin_cita, anio) AS sin_cita_ult,
    arg_max(total_1000, anio) AS total_1000_ult,
    arg_max(sin_cita_1000, anio) AS sin_cita_1000_ult,
    min(anio) AS anio_ini,
    arg_min(total_1000, anio) AS total_1000_ini
FROM ${le_anual}
```

```sql le_esp
-- Pacientes sin cita por especialidad o prueba: último año frente a 2021
SELECT CASE a.tipo WHEN 'consulta' THEN 'Consulta' ELSE 'Prueba' END AS tipo, a.especialidad,
       b.sin_cita AS sin_cita_2021, a.sin_cita AS sin_cita_ult, a.sin_cita / nullif(b.sin_cita, 0) AS veces
FROM mother.sermas_lista_espera a
JOIN mother.sermas_lista_espera b ON b.anio = 2021 AND b.tipo = a.tipo AND b.especialidad = a.especialidad
WHERE a.anio = (SELECT max(anio) FROM mother.sermas_lista_espera) AND a.tipo <> 'quirurgica' AND a.especialidad <> 'Total'
ORDER BY a.sin_cita DESC
LIMIT 10
```

```sql coh
-- Demora declarada frente a la esperada por su lista de espera (recta ajustada con las demás comunidades)
SELECT fecha, CAST(anio AS INTEGER) AS anio, tipo, tasa_1000, dias_declarados, dias_esperados, z
FROM mother.sermas_coherencia_demora
WHERE cod_ccaa = '13' AND tipo = 'consultas'
ORDER BY fecha
```

```sql coh_graf
SELECT fecha, 'Declarada' AS demora, dias_declarados AS dias FROM ${coh}
UNION ALL
SELECT fecha, 'Esperada según su lista de espera' AS demora, dias_esperados AS dias FROM ${coh}
ORDER BY fecha
```

```sql coh_ult
SELECT * FROM ${coh} ORDER BY fecha DESC LIMIT 1
```

```sql le_libre
-- Saldo de la libre elección (citas recibidas menos cedidas) por tipo de gestión del hospital, por 1.000 habitantes
SELECT CAST(anio AS INTEGER) AS anio,
       CASE gestion WHEN 'publica' THEN 'Gestión pública'
                    WHEN 'concesion' THEN 'Concesiones (Quirón, Ribera)'
                    WHEN 'concierto_singular' THEN 'Fundación Jiménez Díaz (Quirón)'
                    ELSE 'Otros convenios' END AS gestion,
       saldo_por_1000_hab, saldo
FROM mother.sermas_libre_eleccion_gestion
WHERE especialidad = 'Total'
ORDER BY anio
```

```sql le_libre_hitos
SELECT
    max(anio) AS anio_ult, min(anio) AS anio_ini,
    sum(saldo) FILTER (WHERE gestion_privada AND anio = (SELECT max(anio) FROM mother.sermas_libre_eleccion_gestion WHERE especialidad = 'Total')) AS saldo_priv_ult,
    sum(saldo) FILTER (WHERE gestion_privada AND anio = (SELECT min(anio) FROM mother.sermas_libre_eleccion_gestion WHERE especialidad = 'Total')) AS saldo_priv_ini
FROM mother.sermas_libre_eleccion_gestion
WHERE especialidad = 'Total'
```

```sql le_trauma
SELECT hospital, CASE WHEN gestion_privada THEN 'Gestión privada' ELSE 'Gestión pública' END AS gestion, saldo
FROM mother.sermas_libre_eleccion
WHERE especialidad = 'Traumatología' AND anio = (SELECT max(anio) FROM mother.sermas_libre_eleccion WHERE especialidad = 'Traumatología')
QUALIFY row_number() OVER (ORDER BY abs(saldo) DESC) <= 12
ORDER BY saldo DESC
```

Cada mes la Comunidad de Madrid publica cuántos pacientes esperan una primera consulta, una prueba o una operación. Esa cifra cuenta solo a quien ya tiene fecha: si el servicio tiene la agenda cerrada, el paciente queda pendiente de citar y no aparece. La memoria anual del SERMAS sí los cuenta. A 31 de diciembre de {le_hitos[0]?.anio_ult} la lista completa era de {formatNumber(le_hitos[0]?.total_ult, 0)} pacientes, {formatNumber(le_hitos[0]?.total_1000_ult, 0)} por cada 1.000 habitantes, y {formatNumber(le_hitos[0]?.sin_cita_ult, 0)} de ellos no tenían cita.

<BarChart
    data={le_graf}
    x=anio
    y=por_1000
    series=situacion
    type=stacked
    sort=false
    xFmt="####"
    yFmt=num0
    colorPalette={['#60a5fa', '#dc2626']}
    title="Madrid: pacientes en lista de espera por 1.000 habitantes a 31 de diciembre (consultas, pruebas y quirúrgica)"
/>

<DataTable data={le_esp} rows=10>
    <Column id=tipo title="Tipo" />
    <Column id=especialidad title="Especialidad o prueba" />
    <Column id=sin_cita_2021 title="Sin cita en 2021" fmt="#,##0" />
    <Column id=sin_cita_ult title="Sin cita, último año" fmt="#,##0" />
    <Column id=veces title="Veces" fmt="0.0x" />
</DataTable>

Quien no tiene cita tampoco entra en la demora media. Si se compara la demora que declara cada comunidad con la que le correspondería por el tamaño de su lista (una recta ajustada con las demás comunidades), Madrid se separa del resto desde 2023: en su último corte declara {formatNumber(coh_ult[0]?.dias_declarados, 0)} días para una primera consulta cuando su lista haría esperar unos {formatNumber(coh_ult[0]?.dias_esperados, 0)}, una diferencia de {formatNumber(Math.abs(coh_ult[0]?.z), 1)} desviaciones típicas.

<LineChart
    data={coh_graf}
    x=fecha
    y=dias
    series=demora
    yFmt=num0
    colorPalette={['#dc2626', '#94a3b8']}
    title="Madrid: demora media para primera consulta, declarada y esperada (días)"
/>

<p class="text-xs text-gray-500">Memoria anual del SERMAS (capítulo de lista de espera: 2015-2020 del PDF de la memoria completa, desde 2021 de sus ficheros de datos abiertos) e informes mensuales de la Consejería de Sanidad. Pruebas: las 8 técnicas que detalla la memoria. Hasta 2022 el total de la memoria era bastante menor que el publicado en el informe mensual de diciembre (en 2022, 394.347 frente a 555.026); desde 2023 los pacientes con cita de la memoria coinciden con el informe mensual, así que el salto de 2023 refleja en parte ese cambio de criterio y la serie no debe leerse como continua. Demora esperada: para cada corte semestral del SISLE-SNS (Ministerio de Sanidad) se ajusta una recta entre la tasa de pacientes por 1.000 habitantes y la demora media de las demás comunidades. La lista de Madrid es mayor que la de cualquier otra, así que su demora esperada es una extrapolación de esa recta.</p>

Al no conseguir cita en su hospital, muchos pacientes acaban en otro por libre elección, instaurada en 2009. El saldo (citas recibidas menos cedidas) de los hospitales de gestión privada pasó de {formatNumber(le_libre_hitos[0]?.saldo_priv_ini, 0)} citas en {le_libre_hitos[0]?.anio_ini} a {formatNumber(le_libre_hitos[0]?.saldo_priv_ult, 0)} en {le_libre_hitos[0]?.anio_ult}; los de gestión pública pierden casi las mismas.

<LineChart
    data={le_libre}
    x=anio
    y=saldo_por_1000_hab
    series=gestion
    yFmt=num0
    xFmt="####"
    colorPalette={['#2563eb', '#f97316', '#dc2626', '#94a3b8']}
    title="Madrid: saldo de citas por libre elección por tipo de hospital (por 1.000 habitantes)"
>
    <ReferenceLine y=0 color="#6b7280" />
</LineChart>

<BarChart
    data={le_trauma}
    x=hospital
    y=saldo
    series=gestion
    swapXY=true
    sort=false
    yFmt=num0
    colorPalette={['#dc2626', '#2563eb']}
    title="Traumatología: hospitales que más pacientes ganan y pierden por libre elección ({le_libre_hitos[0]?.anio_ult})"
/>

<p class="text-xs text-gray-500">Balance de libre elección de la memoria del SERMAS y hojas «Consultas Libre Elección» de las memorias de cada hospital. Gestión privada: hospitales de concesión (Rey Juan Carlos, Infanta Elena, Villalba, Torrejón) y Fundación Jiménez Díaz. La Consejería no publica el algoritmo que ofrece los hospitales alternativos al pedir cita, ni lo que factura cada hospital por estos pacientes.</p>

### Quien puede, se paga un seguro

La catedrática Rosa María Urbanos, primera directora del Observatorio del SNS, señala dos motivos para contratar un seguro privado: esperar menos y poder ir al especialista sin pasar por el médico de familia. Según el Barómetro Sanitario, la población con seguro privado ha pasado del {formatNumber(seg_hitos[0]?.es_ini, 1)} % en {seg_hitos[0]?.anio_ini} al {formatNumber(seg_hitos[0]?.es_ult, 1)} % en {seg_hitos[0]?.anio_ult}; en Madrid, el {formatNumber(seg_hitos[0]?.mad_ult, 1)} %.

<BarChart
    data={seg_ult}
    x=comunidad
    y=seguro_privado_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#7c3aed']}
    title="Población con seguro médico privado, {seg_ult[0]?.anio} (%)"
/>

<LineChart
    data={hogares}
    x=anio
    y=gasto_persona_eur_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Gasto de los hogares en salud de su bolsillo, por persona (euros constantes)"
/>

<p class="text-xs text-gray-500">Barómetro Sanitario (tabla 1 del informe del Ministerio de Sanidad «Evaluación de la sanidad privada en el sistema sanitario de España», diciembre de 2025), seguro individual o de empresa. Gasto de los hogares: Encuesta de Presupuestos Familiares del INE, grupo Sanidad (medicamentos, dentista, óptica, consultas y hospitalización pagadas directamente); no incluye las primas de los seguros.</p>

### Hospitales privados dentro de la red pública

Muchos hospitales de titularidad privada trabajan casi en exclusiva para la sanidad pública: forman parte de su red o la sustituyen por concierto. Según el informe del Ministerio de Sanidad de diciembre de 2025, entre 2011 y 2023 su gasto creció un 84,6 %, frente al 50,3 % de los hospitales públicos.

<BarChart
    data={camas}
    x=comunidad
    y=cuota_red
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#0891b2']}
    title="Camas de hospitales privados o de entidades sin ánimo de lucro integrados en la red pública, {camas[0]?.anio} (% de las camas)"
/>

<p class="text-xs text-gray-500">Catálogo Nacional de Hospitales (Ministerio de Sanidad): hospitales de dependencia privada, mutua o sin ánimo de lucro que pertenecen a la red de utilización pública o tienen concierto sustitutorio. No incluye los hospitales de concesión, que el catálogo cuenta como públicos.</p>

## Educación

### Escuela concertada y privada

En el curso {alu_hitos[0]?.curso_ult} el {formatNumber(alu_hitos[0]?.es_priv, 1)} % de los alumnos de infantil a FP estudiaba en un centro privado en España, la mayoría en concertados. Madrid ({formatNumber(alu_hitos[0]?.mad_priv, 1)} %) es la comunidad con más alumnos en centros privados sin concierto: el {formatNumber(alu_hitos[0]?.mad_nc, 1)} %, frente al {formatNumber(alu_hitos[0]?.es_nc, 1)} % de España.

<BarChart
    data={alu_graf}
    x=comunidad
    y=cuota
    series=titularidad
    type=stacked
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#a78bfa', '#f59e0b']}
    title="Alumnado no universitario en centros privados, curso {alu_rank[0]?.curso}"
/>

<BarChart
    data={alu_etapa}
    x=ensenanza
    y=cuota
    series=zona
    type=grouped
    sort=false
    yFmt=pct0
    colorPalette={['#94a3b8', '#dc2626']}
    title="Alumnos en centros privados sin concierto por etapa: Madrid frente a España"
/>

<p class="text-xs text-gray-500">Estadística de las Enseñanzas no universitarias (Ministerio de Educación). En el País Vasco y Navarra la concertada tiene un origen histórico (ikastolas, cooperativas) y su peso baja con los años; en Madrid crece la privada sin concierto. En el primer ciclo de infantil (0-2 años), «concertado» incluye cualquier centro privado con alguna subvención.</p>

### Cuánto pagan las comunidades a la concertada

```sql conc_edu_lineas
SELECT anio, comunidad, conciertos_eur_hab_real FROM ${conc_edu}
WHERE cod_ccaa IN ('00', '13', '15', '16', '10') AND anio >= 2000
ORDER BY anio
```

En {conc_edu_hitos[0]?.anio_ult} las administraciones educativas dedicaron {formatNumber(conc_edu_hitos[0]?.es_ult, 0)} € por habitante a conciertos y subvenciones a centros privados (euros de {conc_edu_hitos[0]?.anio_base}), el {formatNumber(conc_edu_hitos[0]?.es_peso, 1)} % de su gasto. En Madrid la cifra ha pasado de {formatNumber(conc_edu_hitos[0]?.mad_ini, 0)} € en 2000 a {formatNumber(conc_edu_hitos[0]?.mad_ult, 0)} €, y su peso es ya el {formatNumber(conc_edu_hitos[0]?.mad_peso, 1)} %.

<LineChart
    data={conc_edu_lineas}
    x=anio
    y=conciertos_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#16a34a', '#dc2626', '#0891b2', '#f97316']}
    title="Conciertos y subvenciones a la enseñanza privada por habitante (euros constantes)"
/>

<p class="text-xs text-gray-500">Estadística del Gasto Público en Educación (Ministerio de Educación), gasto liquidado. La partida incluye también las subvenciones a centros privados sin concierto y, desde 2017, las transferencias a universidades privadas.</p>

### FP: la privada crece donde falta la pública

Entre {fp_hitos[0]?.curso_ini} y {fp_hitos[0]?.curso_ult}, los alumnos de FP de grado superior a distancia en centros privados pasaron de {formatNumber(fp_hitos[0]?.sup_ini, 0)} a {formatNumber(fp_hitos[0]?.sup_ult, 0)}: hoy son el {formatNumber(fp_hitos[0]?.sup_cuota_ult * 100, 1)} % de toda la FP superior a distancia. En familias como Sanidad la mayoría de los alumnos de grado superior estudia en la privada.

<LineChart
    data={fp_dist}
    x=anio
    y=cuota
    series=grado
    yFmt=pct0
    xFmt="####"
    colorPalette={['#fb923c', '#b91c1c']}
    title="FP a distancia: alumnos en centros privados (% del total), España"
/>

<BarChart
    data={fp_familia}
    x=familia
    y=cuota
    series=zona
    type=grouped
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#94a3b8', '#dc2626']}
    title="FP de grado superior: alumnos en centros privados por familia profesional"
/>

<p class="text-xs text-gray-500">Familias con al menos 5.000 alumnos de grado superior en España. Privada: concertada y sin concierto. El alumnado a distancia se cuenta en la comunidad donde tiene la sede el centro, por eso unas pocas comunidades concentran la FP online.</p>

### Universidades privadas

En el curso {uni_hitos[0]?.curso_grado} el {formatNumber(uni_hitos[0]?.es_grado, 1)} % de los estudiantes de grado presencial iba a una universidad privada en España, y el {formatNumber(uni_hitos[0]?.mad_grado, 1)} % en Madrid. En el máster, contando la enseñanza a distancia, la privada ya es mayoría: el {formatNumber(uni_hitos[0]?.es_master, 1)} % en {uni_hitos[0]?.curso_master}, frente al {formatNumber(uni_hitos[0]?.es_master_2011, 1)} % de 2010-11. Hay {uni_num.slice(-1)[0]?.universidades} universidades privadas con actividad, {uni_num.slice(-1)[0]?.universidades - uni_num[0]?.universidades} más que en {uni_num[0]?.curso}.

<LineChart
    data={uni_serie}
    x=anio
    y=cuota
    series=serie
    yFmt=pct0
    xFmt="####"
    colorPalette={['#f87171', '#b91c1c', '#93c5fd', '#1d4ed8']}
    title="Estudiantes en universidades privadas (% del total), España y Madrid"
/>

<BarChart
    data={uni_grado_ult}
    x=comunidad
    y=cuota
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#4f46e5']}
    title="Estudiantes de grado presencial en universidades privadas, curso {uni_grado_ult[0]?.curso}"
/>

<p class="text-xs text-gray-500">Estadística de Estudiantes Universitarios (Ministerio de Ciencia, Innovación y Universidades). Los estudiantes se cuentan en la comunidad de la universidad; las universidades a distancia (UNIR, VIU, UOC, UDIMA...) se concentran en pocas comunidades, por eso el ranking usa la enseñanza presencial. El último curso es provisional.</p>

## El gasto que no sale en el presupuesto

```sql ejec_salud
-- Servicios de salud de Madrid y Cataluña: lo presupuestado frente a lo gastado (obligaciones reconocidas)
SELECT CAST(anio AS INTEGER) AS anio,
       CASE WHEN entidad ILIKE '%SERMAS%' THEN 'Madrid (SERMAS)' ELSE 'Cataluña (CatSalut)' END AS servicio,
       100 * (sum(obligaciones_eur) / sum(credito_inicial_eur) - 1) AS desviacion_pct,
       sum(credito_inicial_eur) / 1e6 AS inicial_meur, sum(obligaciones_eur) / 1e6 AS ejecutado_meur
FROM mother.gasto_oculto_ejecucion
WHERE (entidad ILIKE '%SERMAS%' OR entidad = 'CatSalut') AND NOT es_parcial
GROUP BY ALL
ORDER BY anio
```

```sql ejec_priv
-- SERMAS: partidas pagadas a hospitales privados, presupuesto inicial y gasto real por habitante (euros constantes)
SELECT CAST(anio AS INTEGER) AS anio,
       CASE WHEN partida ILIKE '%concesiones%' THEN 'Hospitales de concesión' ELSE 'Fundación Jiménez Díaz' END AS partida,
       sum(credito_inicial_eur_hab_real) AS presupuestado, sum(obligaciones_eur_hab_real) AS gastado,
       sum(credito_inicial_eur) / 1e6 AS inicial_meur, sum(obligaciones_eur) / 1e6 AS ejecutado_meur,
       max(anio_base) AS anio_base
FROM mother.gasto_oculto_ejecucion
WHERE entidad ILIKE '%SERMAS%' AND (partida ILIKE '%concesiones%' OR partida ILIKE '%Jiménez Díaz%')
GROUP BY ALL
ORDER BY anio
```

```sql ejec_priv_graf
SELECT anio, 'Presupuestado' AS momento, sum(presupuestado) AS eur_hab FROM ${ejec_priv} GROUP BY ALL
UNION ALL
SELECT anio, 'Gastado' AS momento, sum(gastado) AS eur_hab FROM ${ejec_priv} GROUP BY ALL
ORDER BY anio
```

```sql ejec_hitos
SELECT
    max(anio) AS anio_ult,
    sum(inicial_meur) FILTER (WHERE anio = (SELECT max(anio) FROM ${ejec_priv})) AS priv_ini,
    sum(ejecutado_meur) FILTER (WHERE anio = (SELECT max(anio) FROM ${ejec_priv})) AS priv_ejec,
    max(anio_base) AS anio_base
FROM ${ejec_priv}
```

```sql ejec_sermas_ult
SELECT * FROM ${ejec_salud} WHERE servicio = 'Madrid (SERMAS)' ORDER BY anio DESC LIMIT 1
```

```sql intereses
SELECT CAST(anio AS INTEGER) AS anio, sum(credito_inicial_eur) / 1e6 AS inicial_meur, sum(obligaciones_eur) / 1e6 AS ejecutado_meur
FROM mother.gasto_oculto_ejecucion
WHERE entidad ILIKE '%SERMAS%' AND partida = 'Intereses de demora'
GROUP BY ALL
ORDER BY anio DESC
LIMIT 1
```

```sql imprevistos
-- Crédito cedido por las partidas sin destino de la Administración de la Comunidad de Madrid
SELECT CAST(anio AS INTEGER) AS anio,
       CASE WHEN subconcepto = '22900' THEN 'Imprevistos e insuficiencias (22900)' ELSE 'Fondo de contingencia' END AS partida,
       -transferencias_eur_real / 1e6 AS cedido_meur_real
FROM mother.gasto_oculto_modificaciones_aplicacion
WHERE cod_ccaa = '13' AND entidad = 'Administración de la Comunidad de Madrid'
  AND (subconcepto = '22900' OR descripcion ILIKE '%FONDO DE CONTINGENCIA%')
ORDER BY anio
```

```sql imprev_ult
SELECT CAST(anio AS INTEGER) AS anio, -sum(transferencias_eur) / 1e6 AS cedido_meur
FROM mother.gasto_oculto_modificaciones_aplicacion
WHERE cod_ccaa = '13' AND entidad = 'Administración de la Comunidad de Madrid'
  AND (subconcepto = '22900' OR descripcion ILIKE '%FONDO DE CONTINGENCIA%')
  AND anio = (SELECT max(anio) FROM mother.gasto_oculto_modificaciones WHERE cod_ccaa = '13' AND entidad ILIKE '%SERMAS%')
GROUP BY ALL
```

```sql recibe
SELECT CAST(anio AS INTEGER) AS anio, sum(transferencias_eur) / 1e6 AS transferencias_meur
FROM mother.gasto_oculto_modificaciones
WHERE cod_ccaa = '13' AND entidad ILIKE '%SERMAS%'
GROUP BY ALL
ORDER BY anio DESC
LIMIT 1
```

```sql conval
SELECT CAST(anio AS INTEGER) AS anio, n_convalidaciones, importe_eur_hab_real, importe_eur / 1e6 AS importe_meur
FROM mother.gasto_oculto_convalidaciones
WHERE area = 'Total' AND NOT es_parcial AND anio >= 2010
ORDER BY anio
```

```sql conval_hitos
SELECT max(anio) FILTER (WHERE n_convalidaciones = (SELECT max(n_convalidaciones) FROM ${conval})) AS anio_max,
       max(n_convalidaciones) AS n_max,
       arg_max(n_convalidaciones, anio) AS n_ult, max(anio) AS anio_ult
FROM ${conval}
```

```sql conval_sanidad
SELECT sum(n_convalidaciones) AS n, sum(importe_eur_real) / 1e6 AS meur_real, min(anio) AS desde, max(anio) AS hasta, max(anio_base) AS anio_base
FROM mother.gasto_oculto_convalidaciones
WHERE area = 'Sanidad' AND anio BETWEEN 2019 AND 2025
```

```sql menores
SELECT ccaa AS comunidad, CAST(anio AS INTEGER) AS anio, sum(n_contratos) AS contratos, sum(importe_eur_real) / 1e6 AS importe_meur,
       sum(importe_posible_troceo_objeto_eur) / sum(importe_eur) AS troceo
FROM mother.gasto_oculto_contratos_menores
WHERE NOT es_parcial
GROUP BY ALL
ORDER BY comunidad, anio
```

Un presupuesto dice cuánto piensa gastar un gobierno; la cuenta general, cuánto gastó de verdad. En Madrid la diferencia se concentra en lo que se paga a los hospitales privados. En {ejec_hitos[0]?.anio_ult} el SERMAS presupuestó {formatNumber(ejec_hitos[0]?.priv_ini, 0)} millones para la Fundación Jiménez Díaz y los cuatro hospitales de concesión, y acabó pagando {formatNumber(ejec_hitos[0]?.priv_ejec, 0)}. En conjunto, el SERMAS gastó un {formatNumber(ejec_sermas_ult[0]?.desviacion_pct, 1)} % más de lo presupuestado. La partida de intereses de demora, que se pagan cuando las facturas y liquidaciones se abonan tarde, tenía {formatNumber(intereses[0]?.inicial_meur, 1)} millones y terminó en {formatNumber(intereses[0]?.ejecutado_meur, 1)}.

<BarChart
    data={ejec_priv_graf}
    x=anio
    y=eur_hab
    series=momento
    type=grouped
    sort=false
    xFmt="####"
    yFmt='#,##0" €"'
    colorPalette={['#94a3b8', '#dc2626']}
    title="SERMAS: Fundación Jiménez Díaz y hospitales de concesión, presupuestado y gastado por habitante (euros de {ejec_hitos[0]?.anio_base})"
/>

<LineChart
    data={ejec_salud}
    x=anio
    y=desviacion_pct
    series=servicio
    yFmt='0.0"%"'
    xFmt="####"
    colorPalette={['#eab308', '#dc2626']}
    title="Gasto real del servicio de salud por encima del presupuesto inicial (%)"
>
    <ReferenceLine y=0 color="#6b7280" />
</LineChart>

El dinero que falta se cubre durante el año con modificaciones de crédito. En {recibe[0]?.anio} el SERMAS recibió {formatNumber(recibe[0]?.transferencias_meur, 0)} millones en transferencias de crédito. Ese año, las partidas de la Administración de la Comunidad presupuestadas sin destino concreto, «imprevistos e insuficiencias» y el fondo de contingencia, cedieron {formatNumber(imprev_ult[0]?.cedido_meur, 0)} millones.

<BarChart
    data={imprevistos}
    x=anio
    y=cedido_meur_real
    series=partida
    type=stacked
    sort=false
    xFmt="####"
    yFmt='#,##0" M€"'
    colorPalette={['#f97316', '#fbbf24']}
    title="Comunidad de Madrid: crédito cedido por imprevistos y fondo de contingencia (millones de euros constantes)"
/>

Cuando un servicio se presta sin contrato en vigor o sin la fiscalización previa, el pago tiene que legalizarse después con una convalidación del Consejo de Gobierno. La Cámara de Cuentas advierte que su abuso debilita el control. Las referencias de los acuerdos recogen {formatNumber(conval_hitos[0]?.n_max, 0)} convalidaciones en {conval_hitos[0]?.anio_max} y {formatNumber(conval_hitos[0]?.n_ult, 0)} en {conval_hitos[0]?.anio_ult}; entre {conval_sanidad[0]?.desde} y {conval_sanidad[0]?.hasta}, las de Sanidad sumaron {formatNumber(conval_sanidad[0]?.n, 0)} por {formatNumber(conval_sanidad[0]?.meur_real, 0)} millones (euros de {conval_sanidad[0]?.anio_base}).

<BarChart
    data={conval}
    x=anio
    y=importe_eur_hab_real
    sort=false
    xFmt="####"
    yFmt='#,##0.0" €"'
    colorPalette={['#7c3aed']}
    title="Comunidad de Madrid: gasto convalidado por el Consejo de Gobierno por habitante (euros constantes)"
/>

<p class="text-xs text-gray-500">Cuenta General de la Comunidad de Madrid (Intervención General): liquidación del presupuesto de gastos de cada entidad por subconcepto (2016 en adelante; 2015 no se publica en PDF) y nota de modificaciones de crédito. Las transferencias de crédito suman cero en el conjunto de la Comunidad: lo que recibe una partida lo cede otra. Cataluña: ejecución mensual del presupuesto de la Generalitat (datos abiertos). Convalidaciones: referencias oficiales de los acuerdos del Consejo de Gobierno desde 2004, con el importe que cita cada acuerdo; son un resumen y se quedan algo cortas (189 en 2024, frente a las 209 que cuenta la Cámara de Cuentas en su informe de la Cuenta General). Agencia Madrileña de Atención Social y Agencia de Vivienda Social no publican su nota de modificaciones.</p>

Los contratos menores (hasta 15.000 euros sin IVA en servicios y suministros) se adjudican sin concurso. Comprar lo mismo al mismo proveedor en varios contratos menores dentro del mismo año puede ser una forma de esquivar el concurso. La Comunidad de Madrid solo permite descargar los suyos tras un captcha, así que la tabla usa los datos abiertos de los servicios de salud de Andalucía y Cataluña: el porcentaje del importe que está en grupos del mismo órgano, mismo proveedor y objeto parecido que superan el umbral.

<DataTable data={menores} rows=20>
    <Column id=comunidad title="Comunidad" />
    <Column id=anio title="Año" fmt="0" />
    <Column id=contratos title="Contratos menores" fmt="#,##0" />
    <Column id=importe_meur title="Importe (M€ constantes)" fmt="#,##0.0" />
    <Column id=troceo title="En grupos que superan el umbral" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Plataforma de Contratación de la Junta de Andalucía (órganos sanitarios; el Servicio Andaluz de Salud se separa por provincia) y Plataforma de servicios de contratación pública de Cataluña (Departament de Salut e ICS, con detalle desde 2023). Objeto parecido: mismas primeras palabras del título en Andalucía y mismo CPV de tres cifras en Cataluña; umbral de 15.000 euros (40.000 en obras) sin IVA, según la Ley de Contratos del Sector Público de 2017. Es una señal para revisar, no una prueba de fraccionamiento: un órgano que compra para muchos hospitales (SAS, ICS) acumula compras legítimas al mismo proveedor. Informes oficiales: <a href="https://www.camaradecuentasmadrid.org/admin/uploads/informe-contratacion-menor-spm-2017-aprobado-cjo-290519.pdf">Cámara de Cuentas de Madrid sobre contratación menor</a> y <a href="https://www.camaradecuentasmadrid.org/admin/uploads/if-sellado-ctagral2024-aprobadocjo23122025.pdf">sobre la Cuenta General de 2024</a>.</p>

## Cómo se han leído estos datos

Las administraciones publican cifras resumidas que a menudo dejan fuera lo importante. En esta página se ha seguido un método para no quedarse en la superficie, con documentos oficiales en todos los casos:

- **Ir al documento completo.** La estadística de gasto sanitario da un porcentaje de conciertos; sus tablas por comunidad y partida enseñan que en la Comunitat Valenciana los pagos a las concesiones no están ahí: sus compras de bienes y servicios pesan unos 10 puntos más que la media del resto, del orden de lo que costaban las concesiones, y en 2018, al volver La Ribera a la gestión pública, el gasto en personal subió de golpe sin que bajara esa partida. Es un indicio que solo confirmarían el presupuesto liquidado de la Conselleria o un informe de la Sindicatura de Comptes.
- **Leer la definición de cada indicador.** El Catálogo Nacional de Hospitales llama públicos a los hospitales de concesión; la partida educativa de conciertos incluye subvenciones a centros sin concierto; la FP y la universidad a distancia se cuentan donde está la sede.
- **Comparar contra un año base**, en euros constantes y por habitante, para separar el crecimiento real del que solo refleja precios y población.
- **Desagregar.** El total de FP esconde familias como Sanidad, donde la privada es mayoría; el total universitario esconde el máster.
- **Comparar el informe de difusión con la rendición de cuentas.** El informe mensual de listas de espera de Madrid cuenta solo a quien tiene cita; la memoria anual del SERMAS cuenta también a quien espera sin ella.
- **Contrastar con las demás comunidades.** Si la demora media de una comunidad no casa con el tamaño de su lista de espera, algo queda fuera del cálculo.
- **Presupuesto frente a cuenta general.** Las partidas que se presupuestan cortas a sabiendas se completan durante el año con modificaciones de crédito, y la cuenta general dice de dónde sale el dinero.
- **Seguir los flujos, no solo los totales.** El saldo de la libre elección dice qué hospitales ganan pacientes y cuáles los pierden; las convalidaciones y los contratos menores repetidos señalan gasto hecho fuera del procedimiento ordinario.

---

## Fuentes y notas

- **[Ministerio de Sanidad – Estadística de Gasto Sanitario Público](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm)** (cuentas satélite, clasificación económica y funcional por comunidad).
- **[Ministerio de Sanidad – Catálogo Nacional de Hospitales](https://www.sanidad.gob.es/estadEstudios/estadisticas/sisInfSanSNS/ofertaRecursos/hospitales/home.htm)**.
- **[Ministerio de Sanidad – Evaluación de la sanidad privada en el sistema sanitario de España](https://vsf-iwsold-pro-portal.sanidad.gob.es/gabinetePrensa/notaPrensa/pdf/20251091225131137451.pdf)** (diciembre de 2025), con el Barómetro Sanitario.
- **Hospitales de gestión privada**: tabla elaborada para SpainFacts con los decretos de reversión del DOGV, las memorias de los hospitales del SERMAS y, cuando no hay dato oficial, prensa con cita; cada fila lleva su fuente en la tabla descargable.
- **[Comunidad de Madrid – Memorias del Servicio Madrileño de Salud](https://www.comunidad.madrid/salud/memorias-e-informes-servicio-madrileno-salud)** (lista de espera a 31 de diciembre y libre elección, también en las memorias de cada hospital) e **[informes mensuales de listas de espera](https://www.comunidad.madrid/salud/lista-espera-consultas-externas)**; **SISLE-SNS** (Ministerio de Sanidad) para comparar con las demás comunidades.
- **[Comunidad de Madrid – Cuenta General](https://www.comunidad.madrid/gobierno/hacienda/cuentas-generales)** (Intervención General: liquidación del presupuesto y modificaciones de crédito por entidad), **[referencias de los acuerdos del Consejo de Gobierno](https://www.comunidad.madrid/acuerdos-consejo-gobierno)** y **[Generalitat de Catalunya – ejecución del presupuesto](https://analisi.transparenciacatalunya.cat/d/ajns-4mi7)**.
- Contratos menores: **[Junta de Andalucía – contratación menor](https://www.juntadeandalucia.es/datosabiertos/portal/)** y **[Generalitat de Catalunya – Plataforma de serveis de contractació pública](https://analisi.transparenciacatalunya.cat/d/ybgg-dgi6)**.
- **[INE – Encuesta de Presupuestos Familiares](https://www.ine.es/jaxiT3/Tabla.htm?t=73991)** (gasto en sanidad por persona).
- **[Ministerio de Educación – EDUCAbase](https://estadisticas.educacion.gob.es/EducaDynPx/educabase/index.htm)**: Estadística de las Enseñanzas no universitarias y Estadística del Gasto Público en Educación.
- **[Ministerio de Ciencia, Innovación y Universidades – Estadística de Estudiantes Universitarios](https://estadisticas.ciencia.gob.es/)** y **[Registro de Universidades, Centros y Títulos](https://www.educacion.gob.es/ruct/listauniversidades?consulta=1)**.
- Contexto: reportajes de elDiario.es «De pacientes a clientes» (14-02-2026) y «El Gobierno trata de levantar un muro contra la privatización desaforada en sanidad y educación» (13-02-2026); las declaraciones de Freire, Bengoa y Urbanos proceden del primero. Ninguna cifra de la página sale de ellos.
- Deflactor: IPC medio anual del INE. Población: INE.

<LastRefreshed prefix="Datos actualizados" />
