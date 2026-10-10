---
title: Público e privado
description: "Canto da sanidade e da educación públicas se presta a través de empresas e centros privados, comunidade a comunidade: concertos sanitarios, hospitais de concesión, seguros privados, escola concertada, FP e universidades privadas."
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

# 🏥 Público e privado

A sanidade e a educación son públicas e gratuítas, pero unha parte crecente préstase a través de empresas e centros privados pagados con diñeiro público, e outra págana as familias do seu peto. Esta páxina mide, comunidade a comunidade, canto hai de cada cousa: concertos sanitarios, hospitais públicos xestionados por empresas, seguros privados, escola concertada, FP e universidades privadas. As cifras van por habitante ou en porcentaxe, e os euros, descontada a inflación.

<Grid cols=4>
    <KpiCard
        title="Madrid: sanidade pública pagada a centros privados"
        value={conc_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(conc_madrid.slice(-1)[0]?.valor, 1)} %"
        period="do gasto sanitario público en concertos en {conc_madrid.slice(-1)[0]?.anio} · {formatNumber(conc_madrid.slice(-1)[0]?.gasto_eur_hab_real, 0)} € por habitante (euros de {conc_madrid.slice(-1)[0]?.anio_base})"
        source="Ministerio de Sanidad (EGSP)"
        sparklineData={conc_madrid}
    />
    <KpiCard
        title="Madrid: poboación con hospital de xestión privada"
        value={cob_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(cob_madrid.slice(-1)[0]?.valor, 1)} %"
        period="en {cob_madrid.slice(-1)[0]?.anio} · {formatNumber(cob_hitos[0]?.mad_pob, 0)} persoas"
        source="SERMAS · memorias dos hospitais"
        sparklineData={cob_madrid}
    />
    <KpiCard
        title="Con seguro médico privado"
        value={seg_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(seg_es.slice(-1)[0]?.valor, 1)} %"
        period="da poboación en {seg_es.slice(-1)[0]?.anio} · Madrid: {formatNumber(seg_hitos[0]?.mad_ult, 1)} %"
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

<p class="text-xs text-gray-500">Centros privados de ensino: concertados (financiados con fondos públicos) e sen concerto. O seguro privado é a resposta dos enquisados do Barómetro Sanitario, que ten en conta o seguro individual e o de empresa.</p>

## Sanidade

### Canto paga a sanidade pública a centros privados

Todas as comunidades derivan pacientes a clínicas privadas para probas, operacións ou especialidades concretas: son os concertos. En {conc_hitos[0]?.anio_ult} o conxunto das comunidades dedicoulles o {formatNumber(conc_hitos[0]?.tot_pct_ult, 1)} % do seu gasto sanitario. Cataluña ({formatNumber(conc_hitos[0]?.cat_pct_ult, 1)} %) e Madrid ({formatNumber(conc_hitos[0]?.mad_pct_ult, 1)} %) son as que máis. A liña marca o 15 %, o limiar que o exconselleiro vasco e exdirectivo da OMS Rafael Bengoa sitúa como o máximo que os sistemas europeos adoitan querer contratar fóra.

<BarChart
    data={conc_ult}
    x=comunidad
    y=peso_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#0f766e']}
    title="Peso dos concertos no gasto sanitario público, {conc_ult[0]?.anio} (%)"
>
    <ReferenceLine y=15 label="15 %" color="#dc2626" />
</BarChart>

```sql conc_lineas
SELECT anio, CASE WHEN cod_ccaa = '00' THEN 'Total comunidades' ELSE ccaa END AS comunidad, gasto_eur_hab_real
FROM ${conc}
WHERE cod_ccaa IN ('00', '09', '10', '13')
ORDER BY anio
```

En euros por habitante e descontada a inflación, Madrid pasou de {formatNumber(conc_hitos[0]?.mad_ini, 0)} € en {conc_hitos[0]?.anio_ini} a {formatNumber(conc_hitos[0]?.mad_ult, 0)} € en {conc_hitos[0]?.anio_ult}; o conxunto de comunidades, de {formatNumber(conc_hitos[0]?.tot_ini, 0)} € a {formatNumber(conc_hitos[0]?.tot_ult, 0)} €. O salto de Madrid coincide coa apertura dos hospitais de concesión de Torrejón (2011), Rey Juan Carlos (2012) e Villalba (2014), que a estatística si conta como concertos.

<LineChart
    data={conc_lineas}
    x=anio
    y=gasto_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Gasto sanitario público en concertos por habitante (euros de {conc_hitos[0]?.anio_base})"
/>

<p class="text-xs text-gray-500">Estatística de Gasto Sanitario Público (Ministerio de Sanidad), gasto consolidado das comunidades autónomas. Concertos: asistencia comprada a centros alleos (hospitalaria, especializada, primaria, traslado de enfermos) e a outras administracións. Os dous últimos anos son provisionais. <b>Cataluña</b>: o seu peso alto vén da rede histórica de hospitais concertados sen ánimo de lucro (fundacións, ordes relixiosas, consorcios do SISCAT), non de empresas con ánimo de lucro. <b>Comunitat Valenciana</b>: a estatística non anota como concertos os pagamentos por habitante aos hospitais de concesión do modelo Alzira; o {formatNumber(conc_hitos[0]?.val_pct_ult, 1)} % de {conc_hitos[0]?.anio_ult} non significa pouca privatización (ver «Como se leron estes datos»).</p>

### Privatizar o aseguramento: hospitais que cobran por habitante

Máis alá dos concertos, Madrid e a Comunitat Valenciana son as únicas comunidades que entregaron a empresas a atención completa de zonas enteiras: a administración paga á concesionaria unha cantidade fixa por cada habitante asignado e a empresa faise responsable da súa saúde. José Manuel Freire, profesor emérito da Escola Nacional de Sanidade, chámalle privatizar o aseguramento. Na Comunitat Valenciana chegou a cubrir o {formatNumber(cob_hitos[0]?.val_max, 1)} % da poboación; tras as reversións iniciadas en 2018 queda o {formatNumber(cob_hitos[0]?.val_pct, 1)} % (só o Vinalopó, en Elche). En Madrid alcanza o {formatNumber(cob_hitos[0]?.mad_pct, 1)} % ({formatNumber(cob_hitos[0]?.mad_pob, 0)} persoas en {cob_hitos[0]?.anio_ult}, {formatNumber(cob_hitos[0]?.mad_concesion, 0)} delas en concesións por habitante e o resto na Fundación Jiménez Díaz, que cobra por acto).

<LineChart
    data={cob_graf}
    x=anio
    y=cuota
    series=comunidad
    yFmt=pct0
    xFmt="####"
    step=true
    colorPalette={['#f97316', '#dc2626']}
    title="Poboación con hospital de referencia de xestión privada (% da comunidade)"
/>

<DataTable data={hospitales_lista} rows=20>
    <Column id=comunidad title="Comunidade" />
    <Column id=hospital title="Hospital" />
    <Column id=modelo title="Modelo" />
    <Column id=empresa title="Empresa" />
    <Column id=inicio title="Desde" fmt="0" />
    <Column id=estado title="Situación" />
    <Column id=poblacion title="Poboación asignada" fmt="#,##0" />
</DataTable>

<p class="text-xs text-gray-500">Poboación asignada: a máis recente publicada por cada hospital ou consellería (memorias do SERMAS, decretos de reversión do DOGV); nos anos sen cifra oficial estímase mantendo o peso de cada hospital na súa comunidade, polo que a serie é aproximada. Ademais, o {formatNumber(cob_hitos[0]?.mad_pfi_pct, 1)} % dos madrileños ten como hospital un dos construídos desde 2008 por empresas que cobran un canon durante 30 anos e xestionan os servizos non sanitarios (limpeza, cociña, mantemento); o seu persoal sanitario é público e non se contan na gráfica. O Catálogo Nacional de Hospitales clasifica os hospitais de concesión como públicos.</p>

### Madrid: a lista de espera que non se publica

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

Cada mes a Comunidade de Madrid publica cantos pacientes esperan unha primeira consulta, unha proba ou unha operación. Esa cifra conta só a quen xa ten data: se o servizo ten a axenda pechada, o paciente queda pendente de citar e non aparece. A memoria anual do SERMAS si os conta. A 31 de decembro de {le_hitos[0]?.anio_ult} a lista completa era de {formatNumber(le_hitos[0]?.total_ult, 0)} pacientes, {formatNumber(le_hitos[0]?.total_1000_ult, 0)} por cada 1.000 habitantes, e {formatNumber(le_hitos[0]?.sin_cita_ult, 0)} deles non tiñan cita.

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
    title="Madrid: pacientes en lista de espera por 1.000 habitantes a 31 de decembro (consultas, probas e cirúrxica)"
/>

<DataTable data={le_esp} rows=10>
    <Column id=tipo title="Tipo" />
    <Column id=especialidad title="Especialidade ou proba" />
    <Column id=sin_cita_2021 title="Sen cita en 2021" fmt="#,##0" />
    <Column id=sin_cita_ult title="Sen cita, último ano" fmt="#,##0" />
    <Column id=veces title="Veces" fmt="0.0x" />
</DataTable>

Quen non ten cita tampouco entra na demora media. Se se compara a demora que declara cada comunidade coa que lle correspondería polo tamaño da súa lista (unha recta axustada coas demais comunidades), Madrid sepárase do resto desde 2023: no seu último corte declara {formatNumber(coh_ult[0]?.dias_declarados, 0)} días para unha primeira consulta cando a súa lista faría esperar uns {formatNumber(coh_ult[0]?.dias_esperados, 0)}, unha diferenza de {formatNumber(Math.abs(coh_ult[0]?.z), 1)} desviacións típicas.

<LineChart
    data={coh_graf}
    x=fecha
    y=dias
    series=demora
    yFmt=num0
    colorPalette={['#dc2626', '#94a3b8']}
    title="Madrid: demora media para primeira consulta, declarada e esperada (días)"
/>

<p class="text-xs text-gray-500">Memoria anual do SERMAS (capítulo de lista de espera: 2015-2020 do PDF da memoria completa, desde 2021 dos seus ficheiros de datos abertos) e informes mensuais da Consellería de Sanidade. Probas: as 8 técnicas que detalla a memoria. Ata 2022 o total da memoria era bastante menor que o publicado no informe mensual de decembro (en 2022, 394.347 fronte a 555.026); desde 2023 os pacientes con cita da memoria coinciden co informe mensual, así que o salto de 2023 reflicte en parte ese cambio de criterio e a serie non debe lerse como continua. Demora esperada: para cada corte semestral do SISLE-SNS (Ministerio de Sanidad) axústase unha recta entre a taxa de pacientes por 1.000 habitantes e a demora media das demais comunidades. A lista de Madrid é maior que a de calquera outra, así que a súa demora esperada é unha extrapolación desa recta.</p>

Ao non conseguir cita no seu hospital, moitos pacientes acaban noutro por libre elección, instaurada en 2009. O saldo (citas recibidas menos cedidas) dos hospitais de xestión privada pasou de {formatNumber(le_libre_hitos[0]?.saldo_priv_ini, 0)} citas en {le_libre_hitos[0]?.anio_ini} a {formatNumber(le_libre_hitos[0]?.saldo_priv_ult, 0)} en {le_libre_hitos[0]?.anio_ult}; os de xestión pública perden case as mesmas.

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
    title="Traumatoloxía: hospitais que máis pacientes gañan e perden por libre elección ({le_libre_hitos[0]?.anio_ult})"
/>

<p class="text-xs text-gray-500">Balance de libre elección da memoria do SERMAS e follas «Consultas Libre Elección» das memorias de cada hospital. Xestión privada: hospitais de concesión (Rey Juan Carlos, Infanta Elena, Villalba, Torrejón) e Fundación Jiménez Díaz. A Consellería non publica o algoritmo que ofrece os hospitais alternativos ao pedir cita, nin o que factura cada hospital por estes pacientes.</p>

### Quen pode, págase un seguro

A catedrática Rosa María Urbanos, primeira directora do Observatorio do SNS, sinala dous motivos para contratar un seguro privado: esperar menos e poder ir ao especialista sen pasar polo médico de familia. Segundo o Barómetro Sanitario, a poboación con seguro privado pasou do {formatNumber(seg_hitos[0]?.es_ini, 1)} % en {seg_hitos[0]?.anio_ini} ao {formatNumber(seg_hitos[0]?.es_ult, 1)} % en {seg_hitos[0]?.anio_ult}; en Madrid, o {formatNumber(seg_hitos[0]?.mad_ult, 1)} %.

<BarChart
    data={seg_ult}
    x=comunidad
    y=seguro_privado_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#7c3aed']}
    title="Poboación con seguro médico privado, {seg_ult[0]?.anio} (%)"
/>

<LineChart
    data={hogares}
    x=anio
    y=gasto_persona_eur_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Gasto dos fogares en saúde do seu peto, por persoa (euros constantes)"
/>

<p class="text-xs text-gray-500">Barómetro Sanitario (táboa 1 do informe do Ministerio de Sanidad «Evaluación de la sanidad privada en el sistema sanitario de España», decembro de 2025), seguro individual ou de empresa. Gasto dos fogares: Enquisa de Orzamentos Familiares do INE, grupo Sanidade (medicamentos, dentista, óptica, consultas e hospitalización pagadas directamente); non inclúe as primas dos seguros.</p>

### Hospitais privados dentro da rede pública

Moitos hospitais de titularidade privada traballan case en exclusiva para a sanidade pública: forman parte da súa rede ou substitúena por concerto. Segundo o informe do Ministerio de Sanidad de decembro de 2025, entre 2011 e 2023 o seu gasto creceu un 84,6 %, fronte ao 50,3 % dos hospitais públicos.

<BarChart
    data={camas}
    x=comunidad
    y=cuota_red
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#0891b2']}
    title="Camas de hospitais privados ou de entidades sen ánimo de lucro integrados na rede pública, {camas[0]?.anio} (% das camas)"
/>

<p class="text-xs text-gray-500">Catálogo Nacional de Hospitales (Ministerio de Sanidad): hospitais de dependencia privada, mutua ou sen ánimo de lucro que pertencen á rede de utilización pública ou teñen concerto substitutorio. Non inclúe os hospitais de concesión, que o catálogo conta como públicos.</p>

## Educación

### Escola concertada e privada

No curso {alu_hitos[0]?.curso_ult} o {formatNumber(alu_hitos[0]?.es_priv, 1)} % dos alumnos de infantil a FP estudaba nun centro privado en España, a maioría en concertados. Madrid ({formatNumber(alu_hitos[0]?.mad_priv, 1)} %) é a comunidade con máis alumnos en centros privados sen concerto: o {formatNumber(alu_hitos[0]?.mad_nc, 1)} %, fronte ao {formatNumber(alu_hitos[0]?.es_nc, 1)} % de España.

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
    title="Alumnado non universitario en centros privados, curso {alu_rank[0]?.curso}"
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
    title="Alumnos en centros privados sen concerto por etapa: Madrid fronte a España"
/>

<p class="text-xs text-gray-500">Estatística das Ensinanzas non universitarias (Ministerio de Educación). No País Vasco e Navarra a concertada ten unha orixe histórica (ikastolas, cooperativas) e o seu peso baixa cos anos; en Madrid crece a privada sen concerto. No primeiro ciclo de infantil (0-2 anos), «concertado» inclúe calquera centro privado con algunha subvención.</p>

### Canto pagan as comunidades á concertada

```sql conc_edu_lineas
SELECT anio, comunidad, conciertos_eur_hab_real FROM ${conc_edu}
WHERE cod_ccaa IN ('00', '13', '15', '16', '10') AND anio >= 2000
ORDER BY anio
```

En {conc_edu_hitos[0]?.anio_ult} as administracións educativas dedicaron {formatNumber(conc_edu_hitos[0]?.es_ult, 0)} € por habitante a concertos e subvencións a centros privados (euros de {conc_edu_hitos[0]?.anio_base}), o {formatNumber(conc_edu_hitos[0]?.es_peso, 1)} % do seu gasto. En Madrid a cifra pasou de {formatNumber(conc_edu_hitos[0]?.mad_ini, 0)} € en 2000 a {formatNumber(conc_edu_hitos[0]?.mad_ult, 0)} €, e o seu peso é xa o {formatNumber(conc_edu_hitos[0]?.mad_peso, 1)} %.

<LineChart
    data={conc_edu_lineas}
    x=anio
    y=conciertos_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#16a34a', '#dc2626', '#0891b2', '#f97316']}
    title="Concertos e subvencións ao ensino privado por habitante (euros constantes)"
/>

<p class="text-xs text-gray-500">Estatística do Gasto Público en Educación (Ministerio de Educación), gasto liquidado. A partida inclúe tamén as subvencións a centros privados sen concerto e, desde 2017, as transferencias a universidades privadas.</p>

### FP: a privada crece onde falta a pública

Entre {fp_hitos[0]?.curso_ini} e {fp_hitos[0]?.curso_ult}, os alumnos de FP de grao superior a distancia en centros privados pasaron de {formatNumber(fp_hitos[0]?.sup_ini, 0)} a {formatNumber(fp_hitos[0]?.sup_ult, 0)}: hoxe son o {formatNumber(fp_hitos[0]?.sup_cuota_ult * 100, 1)} % de toda a FP superior a distancia. En familias como Sanidade a maioría dos alumnos de grao superior estuda na privada.

<LineChart
    data={fp_dist}
    x=anio
    y=cuota
    series=grado
    yFmt=pct0
    xFmt="####"
    colorPalette={['#fb923c', '#b91c1c']}
    title="FP a distancia: alumnos en centros privados (% do total), España"
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
    title="FP de grao superior: alumnos en centros privados por familia profesional"
/>

<p class="text-xs text-gray-500">Familias con polo menos 5.000 alumnos de grao superior en España. Privada: concertada e sen concerto. O alumnado a distancia cóntase na comunidade onde ten a sede o centro, por iso unhas poucas comunidades concentran a FP en liña.</p>

### Universidades privadas

No curso {uni_hitos[0]?.curso_grado} o {formatNumber(uni_hitos[0]?.es_grado, 1)} % dos estudantes de grao presencial ía a unha universidade privada en España, e o {formatNumber(uni_hitos[0]?.mad_grado, 1)} % en Madrid. No máster, contando o ensino a distancia, a privada xa é maioría: o {formatNumber(uni_hitos[0]?.es_master, 1)} % en {uni_hitos[0]?.curso_master}, fronte ao {formatNumber(uni_hitos[0]?.es_master_2011, 1)} % de 2010-11. Hai {uni_num.slice(-1)[0]?.universidades} universidades privadas con actividade, {uni_num.slice(-1)[0]?.universidades - uni_num[0]?.universidades} máis que en {uni_num[0]?.curso}.

<LineChart
    data={uni_serie}
    x=anio
    y=cuota
    series=serie
    yFmt=pct0
    xFmt="####"
    colorPalette={['#f87171', '#b91c1c', '#93c5fd', '#1d4ed8']}
    title="Estudantes en universidades privadas (% do total), España e Madrid"
/>

<BarChart
    data={uni_grado_ult}
    x=comunidad
    y=cuota
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#4f46e5']}
    title="Estudantes de grao presencial en universidades privadas, curso {uni_grado_ult[0]?.curso}"
/>

<p class="text-xs text-gray-500">Estatística de Estudantes Universitarios (Ministerio de Ciencia, Innovación y Universidades). Os estudantes cóntanse na comunidade da universidade; as universidades a distancia (UNIR, VIU, UOC, UDIMA...) concéntranse en poucas comunidades, por iso a clasificación usa o ensino presencial. O último curso é provisional.</p>

## O gasto que non sae no orzamento

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

Un orzamento di canto pensa gastar un goberno; a conta xeral, canto gastou de verdade. En Madrid a diferenza concéntrase no que se paga aos hospitais privados. En {ejec_hitos[0]?.anio_ult} o SERMAS orzou {formatNumber(ejec_hitos[0]?.priv_ini, 0)} millóns para a Fundación Jiménez Díaz e os catro hospitais de concesión, e acabou pagando {formatNumber(ejec_hitos[0]?.priv_ejec, 0)}. En conxunto, o SERMAS gastou un {formatNumber(ejec_sermas_ult[0]?.desviacion_pct, 1)} % máis do orzado. A partida de xuros de demora, que se pagan cando as facturas e liquidacións se aboan tarde, tiña {formatNumber(intereses[0]?.inicial_meur, 1)} millóns e rematou en {formatNumber(intereses[0]?.ejecutado_meur, 1)}.

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
    title="SERMAS: Fundación Jiménez Díaz e hospitais de concesión, orzado e gastado por habitante (euros de {ejec_hitos[0]?.anio_base})"
/>

<LineChart
    data={ejec_salud}
    x=anio
    y=desviacion_pct
    series=servicio
    yFmt='0.0"%"'
    xFmt="####"
    colorPalette={['#eab308', '#dc2626']}
    title="Gasto real do servizo de saúde por riba do orzamento inicial (%)"
>
    <ReferenceLine y=0 color="#6b7280" />
</LineChart>

O diñeiro que falta cóbrese durante o ano con modificacións de crédito. En {recibe[0]?.anio} o SERMAS recibiu {formatNumber(recibe[0]?.transferencias_meur, 0)} millóns en transferencias de crédito. Ese ano, as partidas da Administración da Comunidade orzadas sen destino concreto, «imprevistos e insuficiencias» e o fondo de continxencia, cederon {formatNumber(imprev_ult[0]?.cedido_meur, 0)} millóns.

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
    title="Comunidade de Madrid: crédito cedido por imprevistos e fondo de continxencia (millóns de euros constantes)"
/>

Cando un servizo se presta sen contrato en vigor ou sen a fiscalización previa, o pagamento ten que legalizarse despois cunha convalidación do Consello de Goberno. A Cámara de Cuentas advirte que o seu abuso debilita o control. As referencias dos acordos recollen {formatNumber(conval_hitos[0]?.n_max, 0)} convalidacións en {conval_hitos[0]?.anio_max} e {formatNumber(conval_hitos[0]?.n_ult, 0)} en {conval_hitos[0]?.anio_ult}; entre {conval_sanidad[0]?.desde} e {conval_sanidad[0]?.hasta}, as de Sanidade sumaron {formatNumber(conval_sanidad[0]?.n, 0)} por {formatNumber(conval_sanidad[0]?.meur_real, 0)} millóns (euros de {conval_sanidad[0]?.anio_base}).

<BarChart
    data={conval}
    x=anio
    y=importe_eur_hab_real
    sort=false
    xFmt="####"
    yFmt='#,##0.0" €"'
    colorPalette={['#7c3aed']}
    title="Comunidade de Madrid: gasto convalidado polo Consello de Goberno por habitante (euros constantes)"
/>

<p class="text-xs text-gray-500">Conta Xeral da Comunidade de Madrid (Intervención General): liquidación do orzamento de gastos de cada entidade por subconcepto (2016 en diante; 2015 non se publica en PDF) e nota de modificacións de crédito. As transferencias de crédito suman cero no conxunto da Comunidade: o que recibe unha partida cédeo outra. Cataluña: execución mensual do orzamento da Generalitat (datos abertos). Convalidacións: referencias oficiais dos acordos do Consello de Goberno desde 2004, co importe que cita cada acordo; son un resumo e quedan algo curtas (189 en 2024, fronte ás 209 que conta a Cámara de Cuentas no seu informe da Conta Xeral). A Agencia Madrileña de Atención Social e a Agencia de Vivienda Social non publican a súa nota de modificacións.</p>

Os contratos menores (ata 15.000 euros sen IVE en servizos e subministracións) adxudícanse sen concurso. Comprar o mesmo ao mesmo provedor en varios contratos menores dentro do mesmo ano pode ser unha forma de esquivar o concurso. A Comunidade de Madrid só permite descargar os seus tras un captcha, así que a táboa usa os datos abertos dos servizos de saúde de Andalucía e Cataluña: a porcentaxe do importe que está en grupos do mesmo órgano, mesmo provedor e obxecto parecido que superan o limiar.

<DataTable data={menores} rows=20>
    <Column id=comunidad title="Comunidade" />
    <Column id=anio title="Ano" fmt="0" />
    <Column id=contratos title="Contratos menores" fmt="#,##0" />
    <Column id=importe_meur title="Importe (M€ constantes)" fmt="#,##0.0" />
    <Column id=troceo title="En grupos que superan o limiar" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Plataforma de Contratación da Junta de Andalucía (órganos sanitarios; o Servicio Andaluz de Salud sepárase por provincia) e Plataforma de servizos de contratación pública de Cataluña (Departament de Salut e ICS, con detalle desde 2023). Obxecto parecido: mesmas primeiras palabras do título en Andalucía e mesmo CPV de tres cifras en Cataluña; limiar de 15.000 euros (40.000 en obras) sen IVE, segundo a Lei de Contratos do Sector Público de 2017. É un sinal para revisar, non unha proba de fraccionamento: un órgano que compra para moitos hospitais (SAS, ICS) acumula compras lexítimas ao mesmo provedor. Informes oficiais: <a href="https://www.camaradecuentasmadrid.org/admin/uploads/informe-contratacion-menor-spm-2017-aprobado-cjo-290519.pdf">Cámara de Cuentas de Madrid sobre contratación menor</a> e <a href="https://www.camaradecuentasmadrid.org/admin/uploads/if-sellado-ctagral2024-aprobadocjo23122025.pdf">sobre a Conta Xeral de 2024</a>.</p>

## Como se leron estes datos

As administracións publican cifras resumidas que a miúdo deixan fóra o importante. Nesta páxina seguiuse un método para non quedar na superficie, con documentos oficiais en todos os casos:

- **Ir ao documento completo.** A estatística de gasto sanitario dá unha porcentaxe de concertos; as súas táboas por comunidade e partida ensinan que na Comunitat Valenciana os pagamentos ás concesións non están aí: as súas compras de bens e servizos pesan uns 10 puntos máis que a media do resto, da orde do que custaban as concesións, e en 2018, ao volver La Ribera á xestión pública, o gasto en persoal subiu de golpe sen que baixase esa partida. É un indicio que só confirmarían o orzamento liquidado da Conselleria ou un informe da Sindicatura de Comptes.
- **Ler a definición de cada indicador.** O Catálogo Nacional de Hospitales chama públicos aos hospitais de concesión; a partida educativa de concertos inclúe subvencións a centros sen concerto; a FP e a universidade a distancia cóntanse onde está a sede.
- **Comparar cun ano base**, en euros constantes e por habitante, para separar o crecemento real do que só reflicte prezos e poboación.
- **Desagregar.** O total de FP agocha familias como Sanidade, onde a privada é maioría; o total universitario agocha o máster.
- **Comparar o informe de difusión coa rendición de contas.** O informe mensual de listas de espera de Madrid conta só a quen ten cita; a memoria anual do SERMAS conta tamén a quen espera sen ela.
- **Contrastar coas demais comunidades.** Se a demora media dunha comunidade non casa co tamaño da súa lista de espera, algo queda fóra do cálculo.
- **Orzamento fronte a conta xeral.** As partidas que se orzan curtas a sabendas complétanse durante o ano con modificacións de crédito, e a conta xeral di de onde sae o diñeiro.
- **Seguir os fluxos, non só os totais.** O saldo da libre elección di que hospitais gañan pacientes e cales os perden; as convalidacións e os contratos menores repetidos sinalan gasto feito fóra do procedemento ordinario.

---

## Fontes e notas

- **[Ministerio de Sanidad – Estadística de Gasto Sanitario Público](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm)** (contas satélite, clasificación económica e funcional por comunidade).
- **[Ministerio de Sanidad – Catálogo Nacional de Hospitales](https://www.sanidad.gob.es/estadEstudios/estadisticas/sisInfSanSNS/ofertaRecursos/hospitales/home.htm)**.
- **[Ministerio de Sanidad – Evaluación de la sanidad privada en el sistema sanitario de España](https://vsf-iwsold-pro-portal.sanidad.gob.es/gabinetePrensa/notaPrensa/pdf/20251091225131137451.pdf)** (decembro de 2025), co Barómetro Sanitario.
- **Hospitais de xestión privada**: táboa elaborada para SpainFacts cos decretos de reversión do DOGV, as memorias dos hospitais do SERMAS e, cando non hai dato oficial, prensa con cita; cada fila leva a súa fonte na táboa descargable.
- **[Comunidad de Madrid – Memorias del Servicio Madrileño de Salud](https://www.comunidad.madrid/salud/memorias-e-informes-servicio-madrileno-salud)** (lista de espera a 31 de decembro e libre elección, tamén nas memorias de cada hospital) e **[informes mensuais de listas de espera](https://www.comunidad.madrid/salud/lista-espera-consultas-externas)**; **SISLE-SNS** (Ministerio de Sanidad) para comparar coas demais comunidades.
- **[Comunidad de Madrid – Cuenta General](https://www.comunidad.madrid/gobierno/hacienda/cuentas-generales)** (Intervención General: liquidación do orzamento e modificacións de crédito por entidade), **[referencias dos acordos do Consello de Goberno](https://www.comunidad.madrid/acuerdos-consejo-gobierno)** e **[Generalitat de Catalunya – execución do orzamento](https://analisi.transparenciacatalunya.cat/d/ajns-4mi7)**.
- Contratos menores: **[Junta de Andalucía – contratación menor](https://www.juntadeandalucia.es/datosabiertos/portal/)** e **[Generalitat de Catalunya – Plataforma de serveis de contractació pública](https://analisi.transparenciacatalunya.cat/d/ybgg-dgi6)**.
- **[INE – Enquisa de Orzamentos Familiares](https://www.ine.es/jaxiT3/Tabla.htm?t=73991)** (gasto en sanidade por persoa).
- **[Ministerio de Educación – EDUCAbase](https://estadisticas.educacion.gob.es/EducaDynPx/educabase/index.htm)**: Estatística das Ensinanzas non universitarias e Estatística do Gasto Público en Educación.
- **[Ministerio de Ciencia, Innovación y Universidades – Estadística de Estudiantes Universitarios](https://estadisticas.ciencia.gob.es/)** e **[Registro de Universidades, Centros y Títulos](https://www.educacion.gob.es/ruct/listauniversidades?consulta=1)**.
- Contexto: reportaxes de elDiario.es «De pacientes a clientes» (14-02-2026) e «El Gobierno trata de levantar un muro contra la privatización desaforada en sanidad y educación» (13-02-2026); as declaracións de Freire, Bengoa e Urbanos proceden da primeira. Ningunha cifra da páxina sae delas.
- Deflactor: IPC medio anual do INE. Poboación: INE.

<LastRefreshed prefix="Datos actualizados" />
