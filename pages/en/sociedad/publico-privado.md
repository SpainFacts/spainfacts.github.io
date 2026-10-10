---
title: Public and private
description: "How much of public healthcare and education is delivered through private companies and schools, region by region: healthcare contracts, concession hospitals, private insurance, state-funded private schools, vocational training and private universities."
i18n_origen: 7b3834633dd5
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber, formatCompact } from '../../../../../../../src/lib/utils.js';
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

# 🏥 Public and private

Healthcare and education are public and free, but a growing share is delivered through private companies and schools paid for with public money, and another share is paid by families out of their own pocket. This page measures, region by region, how much there is of each: healthcare contracts, public hospitals run by companies, private insurance, state-funded private schools, vocational training and private universities. Figures are per inhabitant or in percentages, and euros are adjusted for inflation.

<Grid cols=4>
    <KpiCard
        title="Madrid: public healthcare paid to private providers"
        value={conc_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(conc_madrid.slice(-1)[0]?.valor, 1)} %"
        period="of public healthcare spending went on contracts in {conc_madrid.slice(-1)[0]?.anio} · {formatNumber(conc_madrid.slice(-1)[0]?.gasto_eur_hab_real, 0)} € per inhabitant ({conc_madrid.slice(-1)[0]?.anio_base} euros)"
        source="Ministry of Health (EGSP)"
        sparklineData={conc_madrid}
    />
    <KpiCard
        title="Madrid: population with a privately run hospital"
        value={cob_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(cob_madrid.slice(-1)[0]?.valor, 1)} %"
        period="in {cob_madrid.slice(-1)[0]?.anio} · {formatNumber(cob_hitos[0]?.mad_pob, 0)} people"
        source="SERMAS · hospital annual reports"
        sparklineData={cob_madrid}
    />
    <KpiCard
        title="With private health insurance"
        value={seg_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(seg_es.slice(-1)[0]?.valor, 1)} %"
        period="of the population in {seg_es.slice(-1)[0]?.anio} · Madrid: {formatNumber(seg_hitos[0]?.mad_ult, 1)} %"
        source="Health Barometer"
        sparklineData={seg_es}
    />
    <KpiCard
        title="Pupils in private schools"
        value={alu_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(alu_es.slice(-1)[0]?.valor, 1)} %"
        period="from pre-primary to vocational training, school year {alu_hitos[0]?.curso_ult} · Madrid: {formatNumber(alu_hitos[0]?.mad_priv, 1)} %"
        source="Ministry of Education"
        sparklineData={alu_es}
    />
</Grid>

<p class="text-xs text-gray-500">Private schools: state-funded (concertados, financed with public money) and fully private. Private insurance is the answer given by respondents to the Health Barometer, which counts both individual and employer-provided insurance.</p>

## Healthcare

### How much public healthcare pays private providers

Every region refers patients to private clinics for tests, operations or specific specialties: these are the healthcare contracts (conciertos). In {conc_hitos[0]?.anio_ult} the regions as a whole spent {formatNumber(conc_hitos[0]?.tot_pct_ult, 1)} % of their healthcare budget on them. Catalonia ({formatNumber(conc_hitos[0]?.cat_pct_ult, 1)} %) and Madrid ({formatNumber(conc_hitos[0]?.mad_pct_ult, 1)} %) spend the most. The line marks 15 %, the threshold that Rafael Bengoa, former Basque health minister and former WHO director, sets as the most that European systems usually want to contract out.

<BarChart
    data={conc_ult}
    x=comunidad
    y=peso_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#0f766e']}
    title="Share of contracts in public healthcare spending, {conc_ult[0]?.anio} (%)"
>
    <ReferenceLine y=15 label="15 %" color="#dc2626" />
</BarChart>

```sql conc_lineas
SELECT anio, CASE WHEN cod_ccaa = '00' THEN 'Total comunidades' ELSE ccaa END AS comunidad, gasto_eur_hab_real
FROM ${conc}
WHERE cod_ccaa IN ('00', '09', '10', '13')
ORDER BY anio
```

In euros per inhabitant and adjusted for inflation, Madrid has gone from {formatNumber(conc_hitos[0]?.mad_ini, 0)} € in {conc_hitos[0]?.anio_ini} to {formatNumber(conc_hitos[0]?.mad_ult, 0)} € in {conc_hitos[0]?.anio_ult}; the regions as a whole, from {formatNumber(conc_hitos[0]?.tot_ini, 0)} € to {formatNumber(conc_hitos[0]?.tot_ult, 0)} €. Madrid's jump coincides with the opening of the concession hospitals of Torrejón (2011), Rey Juan Carlos (2012) and Villalba (2014), which the statistics do count as contracts.

<LineChart
    data={conc_lineas}
    x=anio
    y=gasto_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Public healthcare spending on contracts per inhabitant ({conc_hitos[0]?.anio_base} euros)"
/>

<p class="text-xs text-gray-500">Public Healthcare Expenditure Statistics (Ministry of Health), consolidated spending of the autonomous regions. Contracts: care bought from outside providers (hospital, specialist and primary care, patient transport) and from other administrations. The last two years are provisional. <b>Catalonia</b>: its high share comes from the historical network of non-profit contracted hospitals (foundations, religious orders, SISCAT consortia), not from for-profit companies. <b>Valencian Community</b>: the statistics do not record the per-inhabitant payments to the concession hospitals of the Alzira model as contracts; the {formatNumber(conc_hitos[0]?.val_pct_ult, 1)} % of {conc_hitos[0]?.anio_ult} does not mean little privatisation (see «How these data have been read»).</p>

### Privatising coverage: hospitals paid per inhabitant

Beyond the contracts, Madrid and the Valencian Community are the only regions that have handed companies the complete care of entire areas: the administration pays the concession holder a fixed amount for each assigned inhabitant and the company becomes responsible for their health. José Manuel Freire, professor emeritus at the National School of Public Health, calls this privatising coverage. In the Valencian Community it came to cover {formatNumber(cob_hitos[0]?.val_max, 1)} % of the population; after the reversals that began in 2018, {formatNumber(cob_hitos[0]?.val_pct, 1)} % remains (only Vinalopó, in Elche). In Madrid it reaches {formatNumber(cob_hitos[0]?.mad_pct, 1)} % ({formatNumber(cob_hitos[0]?.mad_pob, 0)} people in {cob_hitos[0]?.anio_ult}, {formatNumber(cob_hitos[0]?.mad_concesion, 0)} of them in per-inhabitant concessions and the rest at the Fundación Jiménez Díaz, which is paid per procedure).

<LineChart
    data={cob_graf}
    x=anio
    y=cuota
    series=comunidad
    yFmt=pct0
    xFmt="####"
    step=true
    colorPalette={['#f97316', '#dc2626']}
    title="Population whose reference hospital is privately run (% of the region)"
/>

<DataTable data={hospitales_lista} rows=20>
    <Column id=comunidad title="Region" />
    <Column id=hospital title="Hospital" />
    <Column id=modelo title="Model" />
    <Column id=empresa title="Company" />
    <Column id=inicio title="Since" fmt="0" />
    <Column id=estado title="Status" />
    <Column id=poblacion title="Assigned population" fmt="#,##0" />
</DataTable>

<p class="text-xs text-gray-500">Assigned population: the most recent figure published by each hospital or regional health department (SERMAS annual reports, DOGV reversal decrees); in years without an official figure it is estimated by keeping each hospital's share of its region, so the series is approximate. In addition, {formatNumber(cob_hitos[0]?.mad_pfi_pct, 1)} % of Madrid residents have as their hospital one of those built since 2008 by companies that collect a fee for 30 years and run the non-clinical services (cleaning, catering, maintenance); their clinical staff are public and they are not counted in the chart. The National Hospital Catalogue classifies concession hospitals as public.</p>

### Madrid: the waiting list that is not published

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

Every month the Community of Madrid publishes how many patients are waiting for a first consultation, a test or an operation. That figure only counts those who already have a date: if the department's schedule is closed, the patient is left pending an appointment and does not appear. The SERMAS annual report does count them. On 31 December {le_hitos[0]?.anio_ult} the full list stood at {formatNumber(le_hitos[0]?.total_ult, 0)} patients, {formatNumber(le_hitos[0]?.total_1000_ult, 0)} per 1,000 inhabitants, and {formatNumber(le_hitos[0]?.sin_cita_ult, 0)} of them had no appointment.

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
    title="Madrid: patients on the waiting list per 1,000 inhabitants on 31 December (consultations, tests and surgery)"
/>

<DataTable data={le_esp} rows=10>
    <Column id=tipo title="Type" />
    <Column id=especialidad title="Specialty or test" />
    <Column id=sin_cita_2021 title="No appointment in 2021" fmt="#,##0" />
    <Column id=sin_cita_ult title="No appointment, latest year" fmt="#,##0" />
    <Column id=veces title="Times" fmt="0.0x" />
</DataTable>

Those without an appointment are not included in the average waiting time either. If the waiting time each region reports is compared with the one that would correspond to the size of its list (a line fitted with the other regions), Madrid has diverged from the rest since 2023: in its latest cut-off it reports {formatNumber(coh_ult[0]?.dias_declarados, 0)} days for a first consultation when its list would imply a wait of about {formatNumber(coh_ult[0]?.dias_esperados, 0)}, a gap of {formatNumber(Math.abs(coh_ult[0]?.z), 1)} standard deviations.

<LineChart
    data={coh_graf}
    x=fecha
    y=dias
    series=demora
    yFmt=num0
    colorPalette={['#dc2626', '#94a3b8']}
    title="Madrid: average wait for a first consultation, reported and expected (days)"
/>

<p class="text-xs text-gray-500">SERMAS annual report (waiting-list chapter: 2015-2020 from the PDF of the full report, from 2021 from its open data files) and monthly reports of the Regional Health Department. Tests: the 8 procedures detailed in the report. Until 2022 the report's total was considerably lower than the one published in the December monthly report (in 2022, 394,347 versus 555,026); since 2023 the patients with an appointment in the report match the monthly report, so the 2023 jump partly reflects that change of criterion and the series should not be read as continuous. Expected wait: for each half-yearly cut-off of SISLE-SNS (Ministry of Health) a line is fitted between the rate of patients per 1,000 inhabitants and the average wait of the other regions. Madrid's list is larger than any other, so its expected wait is an extrapolation of that line.</p>

Unable to get an appointment at their own hospital, many patients end up at another through free choice, introduced in 2009. The balance (appointments received minus those transferred out) of privately run hospitals went from {formatNumber(le_libre_hitos[0]?.saldo_priv_ini, 0)} appointments in {le_libre_hitos[0]?.anio_ini} to {formatNumber(le_libre_hitos[0]?.saldo_priv_ult, 0)} in {le_libre_hitos[0]?.anio_ult}; publicly run hospitals lose almost as many.

<LineChart
    data={le_libre}
    x=anio
    y=saldo_por_1000_hab
    series=gestion
    yFmt=num0
    xFmt="####"
    colorPalette={['#2563eb', '#f97316', '#dc2626', '#94a3b8']}
    title="Madrid: balance of free-choice appointments by type of hospital (per 1,000 inhabitants)"
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
    title="Traumatology: hospitals that gain and lose the most patients through free choice ({le_libre_hitos[0]?.anio_ult})"
/>

<p class="text-xs text-gray-500">Free-choice balance from the SERMAS annual report and the «Consultas Libre Elección» sheets of each hospital's annual report. Privately run: concession hospitals (Rey Juan Carlos, Infanta Elena, Villalba, Torrejón) and Fundación Jiménez Díaz. The Regional Health Department does not publish the algorithm that offers alternative hospitals when booking an appointment, nor what each hospital bills for these patients.</p>

### Those who can afford it pay for insurance

Professor Rosa María Urbanos, the first director of the National Health System Observatory, points to two reasons for taking out private insurance: shorter waits and being able to see a specialist without going through the family doctor. According to the Health Barometer, the population with private insurance has gone from {formatNumber(seg_hitos[0]?.es_ini, 1)} % in {seg_hitos[0]?.anio_ini} to {formatNumber(seg_hitos[0]?.es_ult, 1)} % in {seg_hitos[0]?.anio_ult}; in Madrid, {formatNumber(seg_hitos[0]?.mad_ult, 1)} %.

<BarChart
    data={seg_ult}
    x=comunidad
    y=seguro_privado_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#7c3aed']}
    title="Population with private health insurance, {seg_ult[0]?.anio} (%)"
/>

<LineChart
    data={hogares}
    x=anio
    y=gasto_persona_eur_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Household out-of-pocket health spending per person (constant euros)"
/>

<p class="text-xs text-gray-500">Health Barometer (table 1 of the Ministry of Health report «Evaluación de la sanidad privada en el sistema sanitario de España», December 2025), individual or employer insurance. Household spending: INE Household Budget Survey, Health group (medicines, dentist, optician, consultations and hospital care paid directly); it does not include insurance premiums.</p>

### Private hospitals within the public network

Many privately owned hospitals work almost exclusively for public healthcare: they are part of its network or replace it under contract. According to the Ministry of Health report of December 2025, between 2011 and 2023 their spending grew by 84.6 %, compared with 50.3 % for public hospitals.

<BarChart
    data={camas}
    x=comunidad
    y=cuota_red
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#0891b2']}
    title="Beds in private or non-profit hospitals integrated into the public network, {camas[0]?.anio} (% of beds)"
/>

<p class="text-xs text-gray-500">National Hospital Catalogue (Ministry of Health): privately owned, mutual or non-profit hospitals that belong to the public-use network or have a substitute contract. It does not include concession hospitals, which the catalogue counts as public.</p>

## Education

### State-funded and private schools

In the {alu_hitos[0]?.curso_ult} school year, {formatNumber(alu_hitos[0]?.es_priv, 1)} % of pupils from pre-primary to vocational training in Spain attended a private school, most of them state-funded. Madrid ({formatNumber(alu_hitos[0]?.mad_priv, 1)} %) is the region with the most pupils in fully private schools: {formatNumber(alu_hitos[0]?.mad_nc, 1)} %, compared with {formatNumber(alu_hitos[0]?.es_nc, 1)} % in Spain.

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
    title="Non-university pupils in private schools, school year {alu_rank[0]?.curso}"
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
    title="Pupils in fully private schools by stage: Madrid versus Spain"
/>

<p class="text-xs text-gray-500">Non-University Education Statistics (Ministry of Education). In the Basque Country and Navarre state-funded private schools have a historical origin (ikastolas, cooperatives) and their share is falling over time; in Madrid fully private schooling is growing. In the first cycle of pre-primary (ages 0-2), «state-funded» includes any private centre receiving some subsidy.</p>

### How much the regions pay state-funded private schools

```sql conc_edu_lineas
SELECT anio, comunidad, conciertos_eur_hab_real FROM ${conc_edu}
WHERE cod_ccaa IN ('00', '13', '15', '16', '10') AND anio >= 2000
ORDER BY anio
```

In {conc_edu_hitos[0]?.anio_ult} the education authorities spent {formatNumber(conc_edu_hitos[0]?.es_ult, 0)} € per inhabitant on contracts and subsidies to private schools ({conc_edu_hitos[0]?.anio_base} euros), {formatNumber(conc_edu_hitos[0]?.es_peso, 1)} % of their spending. In Madrid the figure has gone from {formatNumber(conc_edu_hitos[0]?.mad_ini, 0)} € in 2000 to {formatNumber(conc_edu_hitos[0]?.mad_ult, 0)} €, and its share is now {formatNumber(conc_edu_hitos[0]?.mad_peso, 1)} %.

<LineChart
    data={conc_edu_lineas}
    x=anio
    y=conciertos_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#16a34a', '#dc2626', '#0891b2', '#f97316']}
    title="Contracts and subsidies to private education per inhabitant (constant euros)"
/>

<p class="text-xs text-gray-500">Public Expenditure on Education Statistics (Ministry of Education), outturn spending. The item also includes subsidies to fully private schools and, since 2017, transfers to private universities.</p>

### Vocational training: private provision grows where public provision is lacking

Between {fp_hitos[0]?.curso_ini} and {fp_hitos[0]?.curso_ult}, students of higher-level distance vocational training in private centres went from {formatNumber(fp_hitos[0]?.sup_ini, 0)} to {formatNumber(fp_hitos[0]?.sup_ult, 0)}: they now account for {formatNumber(fp_hitos[0]?.sup_cuota_ult * 100, 1)} % of all higher-level distance vocational training. In fields such as Health, most higher-level students study in private centres.

<LineChart
    data={fp_dist}
    x=anio
    y=cuota
    series=grado
    yFmt=pct0
    xFmt="####"
    colorPalette={['#fb923c', '#b91c1c']}
    title="Distance vocational training: students in private centres (% of total), Spain"
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
    title="Higher-level vocational training: students in private centres by professional field"
/>

<p class="text-xs text-gray-500">Fields with at least 5,000 higher-level students in Spain. Private: state-funded and fully private. Distance students are counted in the region where the centre has its headquarters, which is why a few regions concentrate online vocational training.</p>

### Private universities

In the {uni_hitos[0]?.curso_grado} academic year, {formatNumber(uni_hitos[0]?.es_grado, 1)} % of on-campus bachelor's students attended a private university in Spain, and {formatNumber(uni_hitos[0]?.mad_grado, 1)} % in Madrid. At master's level, counting distance learning, private universities are already the majority: {formatNumber(uni_hitos[0]?.es_master, 1)} % in {uni_hitos[0]?.curso_master}, compared with {formatNumber(uni_hitos[0]?.es_master_2011, 1)} % in 2010-11. There are {uni_num.slice(-1)[0]?.universidades} active private universities, {uni_num.slice(-1)[0]?.universidades - uni_num[0]?.universidades} more than in {uni_num[0]?.curso}.

<LineChart
    data={uni_serie}
    x=anio
    y=cuota
    series=serie
    yFmt=pct0
    xFmt="####"
    colorPalette={['#f87171', '#b91c1c', '#93c5fd', '#1d4ed8']}
    title="Students at private universities (% of total), Spain and Madrid"
/>

<BarChart
    data={uni_grado_ult}
    x=comunidad
    y=cuota
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#4f46e5']}
    title="On-campus bachelor's students at private universities, academic year {uni_grado_ult[0]?.curso}"
/>

<p class="text-xs text-gray-500">University Student Statistics (Ministry of Science, Innovation and Universities). Students are counted in the region of the university; distance universities (UNIR, VIU, UOC, UDIMA...) are concentrated in a few regions, which is why the ranking uses on-campus teaching. The last academic year is provisional.</p>

## The spending that does not appear in the budget

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

A budget says how much a government plans to spend; the general account, how much it actually spent. In Madrid the difference is concentrated in what is paid to private hospitals. In {ejec_hitos[0]?.anio_ult} SERMAS budgeted {formatNumber(ejec_hitos[0]?.priv_ini, 0)} million for the Fundación Jiménez Díaz and the four concession hospitals, and ended up paying {formatNumber(ejec_hitos[0]?.priv_ejec, 0)}. Overall, SERMAS spent {formatNumber(ejec_sermas_ult[0]?.desviacion_pct, 1)} % more than budgeted. The item for late-payment interest, paid when invoices and settlements are paid late, had {formatNumber(intereses[0]?.inicial_meur, 1)} million and ended at {formatNumber(intereses[0]?.ejecutado_meur, 1)}.

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
    title="SERMAS: Fundación Jiménez Díaz and concession hospitals, budgeted and spent per inhabitant ({ejec_hitos[0]?.anio_base} euros)"
/>

<LineChart
    data={ejec_salud}
    x=anio
    y=desviacion_pct
    series=servicio
    yFmt='0.0"%"'
    xFmt="####"
    colorPalette={['#eab308', '#dc2626']}
    title="Actual spending of the health service above the initial budget (%)"
>
    <ReferenceLine y=0 color="#6b7280" />
</LineChart>

The missing money is covered during the year through budget amendments. In {recibe[0]?.anio} SERMAS received {formatNumber(recibe[0]?.transferencias_meur, 0)} million in credit transfers. That year, the items of the Administration of the Community budgeted without a specific purpose, «unforeseen expenses and shortfalls» and the contingency fund, gave up {formatNumber(imprev_ult[0]?.cedido_meur, 0)} million.

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
    title="Community of Madrid: credit given up by unforeseen expenses and the contingency fund (millions of constant euros)"
/>

When a service is provided without a contract in force or without prior audit, the payment has to be legalised afterwards through a validation by the Governing Council. The Chamber of Accounts warns that its overuse weakens oversight. The summaries of the agreements record {formatNumber(conval_hitos[0]?.n_max, 0)} validations in {conval_hitos[0]?.anio_max} and {formatNumber(conval_hitos[0]?.n_ult, 0)} in {conval_hitos[0]?.anio_ult}; between {conval_sanidad[0]?.desde} and {conval_sanidad[0]?.hasta}, those for Health totalled {formatNumber(conval_sanidad[0]?.n, 0)} for {formatNumber(conval_sanidad[0]?.meur_real, 0)} million ({conval_sanidad[0]?.anio_base} euros).

<BarChart
    data={conval}
    x=anio
    y=importe_eur_hab_real
    sort=false
    xFmt="####"
    yFmt='#,##0.0" €"'
    colorPalette={['#7c3aed']}
    title="Community of Madrid: spending validated by the Governing Council per inhabitant (constant euros)"
/>

<p class="text-xs text-gray-500">General Account of the Community of Madrid (General Comptroller): outturn of each entity's expenditure budget by sub-item (2016 onwards; 2015 is not published in PDF) and note on budget amendments. Credit transfers add up to zero across the Community as a whole: what one item receives, another gives up. Catalonia: monthly execution of the Generalitat budget (open data). Validations: official summaries of the Governing Council agreements since 2004, with the amount cited in each agreement; they are a summary and fall somewhat short (189 in 2024, compared with the 209 counted by the Chamber of Accounts in its report on the General Account). The Madrid Social Care Agency and the Social Housing Agency do not publish their note on budget amendments.</p>

Minor contracts (up to 15,000 euros excluding VAT for services and supplies) are awarded without a tender. Buying the same thing from the same supplier through several minor contracts within the same year can be a way of avoiding a tender. The Community of Madrid only allows its own to be downloaded after a captcha, so the table uses the open data of the health services of Andalusia and Catalonia: the percentage of the amount that falls in groups from the same body, same supplier and similar subject that exceed the threshold.

<DataTable data={menores} rows=20>
    <Column id=comunidad title="Region" />
    <Column id=anio title="Year" fmt="0" />
    <Column id=contratos title="Minor contracts" fmt="#,##0" />
    <Column id=importe_meur title="Amount (constant M€)" fmt="#,##0.0" />
    <Column id=troceo title="In groups above the threshold" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Procurement Platform of the Junta de Andalucía (health bodies; the Andalusian Health Service is split by province) and Public Procurement Services Platform of Catalonia (Departament de Salut and ICS, with detail since 2023). Similar subject: same first words of the title in Andalusia and same three-digit CPV code in Catalonia; threshold of 15,000 euros (40,000 for works) excluding VAT, under the 2017 Public Sector Contracts Act. It is a signal to review, not proof of contract splitting: a body that buys for many hospitals (SAS, ICS) accumulates legitimate purchases from the same supplier. Official reports: <a href="https://www.camaradecuentasmadrid.org/admin/uploads/informe-contratacion-menor-spm-2017-aprobado-cjo-290519.pdf">Madrid Chamber of Accounts on minor contracts</a> and <a href="https://www.camaradecuentasmadrid.org/admin/uploads/if-sellado-ctagral2024-aprobadocjo23122025.pdf">on the 2024 General Account</a>.</p>

## How these data have been read

Administrations publish summary figures that often leave out what matters. This page has followed a method to avoid staying on the surface, using official documents in every case:

- **Go to the full document.** The healthcare spending statistics give a percentage for contracts; their tables by region and item show that in the Valencian Community the payments to the concessions are not there: its purchases of goods and services weigh about 10 points more than the average of the rest, roughly what the concessions cost, and in 2018, when La Ribera returned to public management, staff spending jumped suddenly without that item falling. It is an indication that only the Conselleria's outturn budget or a report by the Sindicatura de Comptes could confirm.
- **Read the definition of each indicator.** The National Hospital Catalogue calls concession hospitals public; the education item for contracts includes subsidies to fully private schools; distance vocational training and universities are counted where their headquarters are.
- **Compare against a base year**, in constant euros and per inhabitant, to separate real growth from growth that only reflects prices and population.
- **Break down the figures.** The vocational training total hides fields such as Health, where private provision is the majority; the university total hides master's degrees.
- **Compare the publicity report with the accountability report.** Madrid's monthly waiting-list report only counts those with an appointment; the SERMAS annual report also counts those waiting without one.
- **Check against the other regions.** If a region's average wait does not match the size of its waiting list, something is being left out of the calculation.
- **Budget versus general account.** Items that are knowingly under-budgeted are topped up during the year through budget amendments, and the general account says where the money comes from.
- **Follow the flows, not just the totals.** The free-choice balance shows which hospitals gain patients and which lose them; validations and repeated minor contracts point to spending made outside the ordinary procedure.

---

## Sources and notes

- **[Ministry of Health – Public Healthcare Expenditure Statistics](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm)** (satellite accounts, economic and functional classification by region).
- **[Ministry of Health – National Hospital Catalogue](https://www.sanidad.gob.es/estadEstudios/estadisticas/sisInfSanSNS/ofertaRecursos/hospitales/home.htm)**.
- **[Ministry of Health – Evaluación de la sanidad privada en el sistema sanitario de España](https://vsf-iwsold-pro-portal.sanidad.gob.es/gabinetePrensa/notaPrensa/pdf/20251091225131137451.pdf)** (December 2025), with the Health Barometer.
- **Privately run hospitals**: table compiled for SpainFacts from the DOGV reversal decrees, the SERMAS hospital annual reports and, where there is no official figure, press reports with attribution; each row carries its source in the downloadable table.
- **[Community of Madrid – Annual reports of the Madrid Health Service](https://www.comunidad.madrid/salud/memorias-e-informes-servicio-madrileno-salud)** (waiting list on 31 December and free choice, also in each hospital's annual report) and **[monthly waiting-list reports](https://www.comunidad.madrid/salud/lista-espera-consultas-externas)**; **SISLE-SNS** (Ministry of Health) for comparison with the other regions.
- **[Community of Madrid – General Account](https://www.comunidad.madrid/gobierno/hacienda/cuentas-generales)** (General Comptroller: budget outturn and budget amendments by entity), **[summaries of the Governing Council agreements](https://www.comunidad.madrid/acuerdos-consejo-gobierno)** and **[Generalitat de Catalunya – budget execution](https://analisi.transparenciacatalunya.cat/d/ajns-4mi7)**.
- Minor contracts: **[Junta de Andalucía – minor contracts](https://www.juntadeandalucia.es/datosabiertos/portal/)** and **[Generalitat de Catalunya – Plataforma de serveis de contractació pública](https://analisi.transparenciacatalunya.cat/d/ybgg-dgi6)**.
- **[INE – Household Budget Survey](https://www.ine.es/jaxiT3/Tabla.htm?t=73991)** (health spending per person).
- **[Ministry of Education – EDUCAbase](https://estadisticas.educacion.gob.es/EducaDynPx/educabase/index.htm)**: Non-University Education Statistics and Public Expenditure on Education Statistics.
- **[Ministry of Science, Innovation and Universities – University Student Statistics](https://estadisticas.ciencia.gob.es/)** and **[Register of Universities, Centres and Degrees](https://www.educacion.gob.es/ruct/listauniversidades?consulta=1)**.
- Context: elDiario.es reports «De pacientes a clientes» (14-02-2026) and «El Gobierno trata de levantar un muro contra la privatización desaforada en sanidad y educación» (13-02-2026); the statements by Freire, Bengoa and Urbanos come from the former. None of the figures on this page come from them.
- Deflator: INE annual average CPI. Population: INE.

<LastRefreshed prefix="Data updated" />
