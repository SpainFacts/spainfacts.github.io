---
title: Públic i privat
description: "Quina part de la sanitat i l'educació públiques es presta a través d'empreses i centres privats, comunitat a comunitat: concerts sanitaris, hospitals de concessió, assegurances privades, escola concertada, FP i universitats privades."
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

# 🏥 Públic i privat

La sanitat i l'educació són públiques i gratuïtes, però una part creixent es presta a través d'empreses i centres privats pagats amb diners públics, i una altra la paguen les famílies de la seva butxaca. Aquesta pàgina mesura, comunitat a comunitat, quant n'hi ha de cada cosa: concerts sanitaris, hospitals públics gestionats per empreses, assegurances privades, escola concertada, FP i universitats privades. Les xifres van per habitant o en percentatge, i els euros, descomptada la inflació.

<Grid cols=4>
    <KpiCard
        title="Madrid: sanitat pública pagada a centres privats"
        value={conc_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(conc_madrid.slice(-1)[0]?.valor, 1)} %"
        period="de la despesa sanitària pública en concerts el {conc_madrid.slice(-1)[0]?.anio} · {formatNumber(conc_madrid.slice(-1)[0]?.gasto_eur_hab_real, 0)} € per habitant (euros de {conc_madrid.slice(-1)[0]?.anio_base})"
        source="Ministeri de Sanitat (EGSP)"
        sparklineData={conc_madrid}
    />
    <KpiCard
        title="Madrid: població amb hospital de gestió privada"
        value={cob_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(cob_madrid.slice(-1)[0]?.valor, 1)} %"
        period="el {cob_madrid.slice(-1)[0]?.anio} · {formatNumber(cob_hitos[0]?.mad_pob, 0)} persones"
        source="SERMAS · memòries dels hospitals"
        sparklineData={cob_madrid}
    />
    <KpiCard
        title="Amb assegurança mèdica privada"
        value={seg_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(seg_es.slice(-1)[0]?.valor, 1)} %"
        period="de la població el {seg_es.slice(-1)[0]?.anio} · Madrid: {formatNumber(seg_hitos[0]?.mad_ult, 1)} %"
        source="Baròmetre Sanitari"
        sparklineData={seg_es}
    />
    <KpiCard
        title="Alumnes en centres privats"
        value={alu_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(alu_es.slice(-1)[0]?.valor, 1)} %"
        period="d'infantil a FP, curs {alu_hitos[0]?.curso_ult} · Madrid: {formatNumber(alu_hitos[0]?.mad_priv, 1)} %"
        source="Ministeri d'Educació"
        sparklineData={alu_es}
    />
</Grid>

<p class="text-xs text-gray-500">Centres privats d'ensenyament: concertats (finançats amb fons públics) i sense concert. L'assegurança privada és la resposta dels enquestats del Baròmetre Sanitari, que té en compte l'assegurança individual i la d'empresa.</p>

## Sanitat

### Quant paga la sanitat pública a centres privats

Totes les comunitats deriven pacients a clíniques privades per a proves, operacions o especialitats concretes: són els concerts. El {conc_hitos[0]?.anio_ult} el conjunt de les comunitats hi va dedicar el {formatNumber(conc_hitos[0]?.tot_pct_ult, 1)} % de la seva despesa sanitària. Catalunya ({formatNumber(conc_hitos[0]?.cat_pct_ult, 1)} %) i Madrid ({formatNumber(conc_hitos[0]?.mad_pct_ult, 1)} %) són les que més. La línia marca el 15 %, el llindar que l'exconseller basc i exdirectiu de l'OMS Rafael Bengoa situa com el màxim que els sistemes europeus solen voler contractar fora.

<BarChart
    data={conc_ult}
    x=comunidad
    y=peso_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#0f766e']}
    title="Pes dels concerts en la despesa sanitària pública, {conc_ult[0]?.anio} (%)"
>
    <ReferenceLine y=15 label="15 %" color="#dc2626" />
</BarChart>

```sql conc_lineas
SELECT anio, CASE WHEN cod_ccaa = '00' THEN 'Total comunidades' ELSE ccaa END AS comunidad, gasto_eur_hab_real
FROM ${conc}
WHERE cod_ccaa IN ('00', '09', '10', '13')
ORDER BY anio
```

En euros per habitant i descomptada la inflació, Madrid ha passat de {formatNumber(conc_hitos[0]?.mad_ini, 0)} € el {conc_hitos[0]?.anio_ini} a {formatNumber(conc_hitos[0]?.mad_ult, 0)} € el {conc_hitos[0]?.anio_ult}; el conjunt de comunitats, de {formatNumber(conc_hitos[0]?.tot_ini, 0)} € a {formatNumber(conc_hitos[0]?.tot_ult, 0)} €. El salt de Madrid coincideix amb l'obertura dels hospitals de concessió de Torrejón (2011), Rey Juan Carlos (2012) i Villalba (2014), que l'estadística sí que compta com a concerts.

<LineChart
    data={conc_lineas}
    x=anio
    y=gasto_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Despesa sanitària pública en concerts per habitant (euros de {conc_hitos[0]?.anio_base})"
/>

<p class="text-xs text-gray-500">Estadística de Despesa Sanitària Pública (Ministeri de Sanitat), despesa consolidada de les comunitats autònomes. Concerts: assistència comprada a centres aliens (hospitalària, especialitzada, primària, trasllat de malalts) i a altres administracions. Els dos últims anys són provisionals. <b>Catalunya</b>: el seu pes alt ve de la xarxa històrica d'hospitals concertats sense ànim de lucre (fundacions, ordes religiosos, consorcis del SISCAT), no d'empreses amb ànim de lucre. <b>Comunitat Valenciana</b>: l'estadística no anota com a concerts els pagaments per habitant als hospitals de concessió del model Alzira; el {formatNumber(conc_hitos[0]?.val_pct_ult, 1)} % del {conc_hitos[0]?.anio_ult} no vol dir poca privatització (vegeu «Com s'han llegit aquestes dades»).</p>

### Privatitzar l'assegurament: hospitals que cobren per habitant

Més enllà dels concerts, Madrid i la Comunitat Valenciana són les úniques comunitats que han lliurat a empreses l'atenció completa de zones senceres: l'administració paga a la concessionària una quantitat fixa per cada habitant assignat i l'empresa es fa responsable de la seva salut. José Manuel Freire, professor emèrit de l'Escola Nacional de Sanitat, ho anomena privatitzar l'assegurament. A la Comunitat Valenciana va arribar a cobrir el {formatNumber(cob_hitos[0]?.val_max, 1)} % de la població; després de les reversions iniciades el 2018 en queda el {formatNumber(cob_hitos[0]?.val_pct, 1)} % (només el Vinalopó, a Elx). A Madrid arriba al {formatNumber(cob_hitos[0]?.mad_pct, 1)} % ({formatNumber(cob_hitos[0]?.mad_pob, 0)} persones el {cob_hitos[0]?.anio_ult}, {formatNumber(cob_hitos[0]?.mad_concesion, 0)} d'elles en concessions per habitant i la resta a la Fundación Jiménez Díaz, que cobra per acte).

<LineChart
    data={cob_graf}
    x=anio
    y=cuota
    series=comunidad
    yFmt=pct0
    xFmt="####"
    step=true
    colorPalette={['#f97316', '#dc2626']}
    title="Població amb hospital de referència de gestió privada (% de la comunitat)"
/>

<DataTable data={hospitales_lista} rows=20>
    <Column id=comunidad title="Comunitat" />
    <Column id=hospital title="Hospital" />
    <Column id=modelo title="Model" />
    <Column id=empresa title="Empresa" />
    <Column id=inicio title="Des de" fmt="0" />
    <Column id=estado title="Situació" />
    <Column id=poblacion title="Població assignada" fmt="#,##0" />
</DataTable>

<p class="text-xs text-gray-500">Població assignada: la més recent publicada per cada hospital o conselleria (memòries del SERMAS, decrets de reversió del DOGV); en els anys sense xifra oficial s'estima mantenint el pes de cada hospital a la seva comunitat, per la qual cosa la sèrie és aproximada. A més, el {formatNumber(cob_hitos[0]?.mad_pfi_pct, 1)} % dels madrilenys té com a hospital un dels construïts des del 2008 per empreses que cobren un cànon durant 30 anys i gestionen els serveis no sanitaris (neteja, cuina, manteniment); el seu personal sanitari és públic i no es compten a la gràfica. El Catàleg Nacional d'Hospitals classifica els hospitals de concessió com a públics.</p>

### Madrid: la llista d'espera que no es publica

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

Cada mes la Comunitat de Madrid publica quants pacients esperen una primera consulta, una prova o una operació. Aquesta xifra només compta qui ja té data: si el servei té l'agenda tancada, el pacient queda pendent de citar i no hi apareix. La memòria anual del SERMAS sí que els compta. A 31 de desembre de {le_hitos[0]?.anio_ult} la llista completa era de {formatNumber(le_hitos[0]?.total_ult, 0)} pacients, {formatNumber(le_hitos[0]?.total_1000_ult, 0)} per cada 1.000 habitants, i {formatNumber(le_hitos[0]?.sin_cita_ult, 0)} d'ells no tenien cita.

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
    title="Madrid: pacients en llista d'espera per 1.000 habitants a 31 de desembre (consultes, proves i quirúrgica)"
/>

<DataTable data={le_esp} rows=10>
    <Column id=tipo title="Tipus" />
    <Column id=especialidad title="Especialitat o prova" />
    <Column id=sin_cita_2021 title="Sense cita el 2021" fmt="#,##0" />
    <Column id=sin_cita_ult title="Sense cita, últim any" fmt="#,##0" />
    <Column id=veces title="Vegades" fmt="0.0x" />
</DataTable>

Qui no té cita tampoc entra en la demora mitjana. Si es compara la demora que declara cada comunitat amb la que li correspondria per la mida de la seva llista (una recta ajustada amb les altres comunitats), Madrid se separa de la resta des del 2023: en el seu últim tall declara {formatNumber(coh_ult[0]?.dias_declarados, 0)} dies per a una primera consulta quan la seva llista faria esperar uns {formatNumber(coh_ult[0]?.dias_esperados, 0)}, una diferència de {formatNumber(Math.abs(coh_ult[0]?.z), 1)} desviacions típiques.

<LineChart
    data={coh_graf}
    x=fecha
    y=dias
    series=demora
    yFmt=num0
    colorPalette={['#dc2626', '#94a3b8']}
    title="Madrid: demora mitjana per a primera consulta, declarada i esperada (dies)"
/>

<p class="text-xs text-gray-500">Memòria anual del SERMAS (capítol de llista d'espera: 2015-2020 del PDF de la memòria completa, des del 2021 dels seus fitxers de dades obertes) i informes mensuals de la Conselleria de Sanitat. Proves: les 8 tècniques que detalla la memòria. Fins al 2022 el total de la memòria era força inferior al publicat a l'informe mensual de desembre (el 2022, 394.347 davant 555.026); des del 2023 els pacients amb cita de la memòria coincideixen amb l'informe mensual, de manera que el salt del 2023 reflecteix en part aquest canvi de criteri i la sèrie no s'ha de llegir com a contínua. Demora esperada: per a cada tall semestral del SISLE-SNS (Ministeri de Sanitat) s'ajusta una recta entre la taxa de pacients per 1.000 habitants i la demora mitjana de les altres comunitats. La llista de Madrid és més gran que la de qualsevol altra, així que la seva demora esperada és una extrapolació d'aquesta recta.</p>

En no aconseguir cita al seu hospital, molts pacients acaben en un altre per lliure elecció, instaurada el 2009. El saldo (cites rebudes menys cedides) dels hospitals de gestió privada va passar de {formatNumber(le_libre_hitos[0]?.saldo_priv_ini, 0)} cites el {le_libre_hitos[0]?.anio_ini} a {formatNumber(le_libre_hitos[0]?.saldo_priv_ult, 0)} el {le_libre_hitos[0]?.anio_ult}; els de gestió pública en perden gairebé les mateixes.

<LineChart
    data={le_libre}
    x=anio
    y=saldo_por_1000_hab
    series=gestion
    yFmt=num0
    xFmt="####"
    colorPalette={['#2563eb', '#f97316', '#dc2626', '#94a3b8']}
    title="Madrid: saldo de cites per lliure elecció per tipus d'hospital (per 1.000 habitants)"
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
    title="Traumatologia: hospitals que més pacients guanyen i perden per lliure elecció ({le_libre_hitos[0]?.anio_ult})"
/>

<p class="text-xs text-gray-500">Balanç de lliure elecció de la memòria del SERMAS i fulls «Consultas Libre Elección» de les memòries de cada hospital. Gestió privada: hospitals de concessió (Rey Juan Carlos, Infanta Elena, Villalba, Torrejón) i Fundación Jiménez Díaz. La Conselleria no publica l'algorisme que ofereix els hospitals alternatius en demanar cita, ni el que factura cada hospital per aquests pacients.</p>

### Qui pot, es paga una assegurança

La catedràtica Rosa María Urbanos, primera directora de l'Observatori del SNS, assenyala dos motius per contractar una assegurança privada: esperar menys i poder anar a l'especialista sense passar pel metge de família. Segons el Baròmetre Sanitari, la població amb assegurança privada ha passat del {formatNumber(seg_hitos[0]?.es_ini, 1)} % el {seg_hitos[0]?.anio_ini} al {formatNumber(seg_hitos[0]?.es_ult, 1)} % el {seg_hitos[0]?.anio_ult}; a Madrid, el {formatNumber(seg_hitos[0]?.mad_ult, 1)} %.

<BarChart
    data={seg_ult}
    x=comunidad
    y=seguro_privado_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#7c3aed']}
    title="Població amb assegurança mèdica privada, {seg_ult[0]?.anio} (%)"
/>

<LineChart
    data={hogares}
    x=anio
    y=gasto_persona_eur_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Despesa de les llars en salut de la seva butxaca, per persona (euros constants)"
/>

<p class="text-xs text-gray-500">Baròmetre Sanitari (taula 1 de l'informe del Ministeri de Sanitat «Evaluación de la sanidad privada en el sistema sanitario de España», desembre del 2025), assegurança individual o d'empresa. Despesa de les llars: Enquesta de Pressupostos Familiars de l'INE, grup Sanitat (medicaments, dentista, òptica, consultes i hospitalització pagades directament); no inclou les primes de les assegurances.</p>

### Hospitals privats dins de la xarxa pública

Molts hospitals de titularitat privada treballen gairebé en exclusiva per a la sanitat pública: formen part de la seva xarxa o la substitueixen per concert. Segons l'informe del Ministeri de Sanitat de desembre del 2025, entre el 2011 i el 2023 la seva despesa va créixer un 84,6 %, davant el 50,3 % dels hospitals públics.

<BarChart
    data={camas}
    x=comunidad
    y=cuota_red
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#0891b2']}
    title="Llits d'hospitals privats o d'entitats sense ànim de lucre integrats a la xarxa pública, {camas[0]?.anio} (% dels llits)"
/>

<p class="text-xs text-gray-500">Catàleg Nacional d'Hospitals (Ministeri de Sanitat): hospitals de dependència privada, mútua o sense ànim de lucre que pertanyen a la xarxa d'utilització pública o tenen concert substitutori. No inclou els hospitals de concessió, que el catàleg compta com a públics.</p>

## Educació

### Escola concertada i privada

El curs {alu_hitos[0]?.curso_ult} el {formatNumber(alu_hitos[0]?.es_priv, 1)} % dels alumnes d'infantil a FP estudiava en un centre privat a Espanya, la majoria en concertats. Madrid ({formatNumber(alu_hitos[0]?.mad_priv, 1)} %) és la comunitat amb més alumnes en centres privats sense concert: el {formatNumber(alu_hitos[0]?.mad_nc, 1)} %, davant el {formatNumber(alu_hitos[0]?.es_nc, 1)} % d'Espanya.

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
    title="Alumnat no universitari en centres privats, curs {alu_rank[0]?.curso}"
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
    title="Alumnes en centres privats sense concert per etapa: Madrid davant Espanya"
/>

<p class="text-xs text-gray-500">Estadística dels Ensenyaments no universitaris (Ministeri d'Educació). Al País Basc i Navarra la concertada té un origen històric (ikastoles, cooperatives) i el seu pes baixa amb els anys; a Madrid creix la privada sense concert. En el primer cicle d'infantil (0-2 anys), «concertat» inclou qualsevol centre privat amb alguna subvenció.</p>

### Quant paguen les comunitats a la concertada

```sql conc_edu_lineas
SELECT anio, comunidad, conciertos_eur_hab_real FROM ${conc_edu}
WHERE cod_ccaa IN ('00', '13', '15', '16', '10') AND anio >= 2000
ORDER BY anio
```

El {conc_edu_hitos[0]?.anio_ult} les administracions educatives van dedicar {formatNumber(conc_edu_hitos[0]?.es_ult, 0)} € per habitant a concerts i subvencions a centres privats (euros de {conc_edu_hitos[0]?.anio_base}), el {formatNumber(conc_edu_hitos[0]?.es_peso, 1)} % de la seva despesa. A Madrid la xifra ha passat de {formatNumber(conc_edu_hitos[0]?.mad_ini, 0)} € el 2000 a {formatNumber(conc_edu_hitos[0]?.mad_ult, 0)} €, i el seu pes ja és el {formatNumber(conc_edu_hitos[0]?.mad_peso, 1)} %.

<LineChart
    data={conc_edu_lineas}
    x=anio
    y=conciertos_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#16a34a', '#dc2626', '#0891b2', '#f97316']}
    title="Concerts i subvencions a l'ensenyament privat per habitant (euros constants)"
/>

<p class="text-xs text-gray-500">Estadística de la Despesa Pública en Educació (Ministeri d'Educació), despesa liquidada. La partida inclou també les subvencions a centres privats sense concert i, des del 2017, les transferències a universitats privades.</p>

### FP: la privada creix on falta la pública

Entre {fp_hitos[0]?.curso_ini} i {fp_hitos[0]?.curso_ult}, els alumnes d'FP de grau superior a distància en centres privats van passar de {formatNumber(fp_hitos[0]?.sup_ini, 0)} a {formatNumber(fp_hitos[0]?.sup_ult, 0)}: avui són el {formatNumber(fp_hitos[0]?.sup_cuota_ult * 100, 1)} % de tota l'FP superior a distància. En famílies com Sanitat la majoria dels alumnes de grau superior estudia a la privada.

<LineChart
    data={fp_dist}
    x=anio
    y=cuota
    series=grado
    yFmt=pct0
    xFmt="####"
    colorPalette={['#fb923c', '#b91c1c']}
    title="FP a distància: alumnes en centres privats (% del total), Espanya"
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
    title="FP de grau superior: alumnes en centres privats per família professional"
/>

<p class="text-xs text-gray-500">Famílies amb almenys 5.000 alumnes de grau superior a Espanya. Privada: concertada i sense concert. L'alumnat a distància es compta a la comunitat on té la seu el centre, per això unes poques comunitats concentren l'FP en línia.</p>

### Universitats privades

El curs {uni_hitos[0]?.curso_grado} el {formatNumber(uni_hitos[0]?.es_grado, 1)} % dels estudiants de grau presencial anava a una universitat privada a Espanya, i el {formatNumber(uni_hitos[0]?.mad_grado, 1)} % a Madrid. En el màster, comptant l'ensenyament a distància, la privada ja és majoria: el {formatNumber(uni_hitos[0]?.es_master, 1)} % el {uni_hitos[0]?.curso_master}, davant el {formatNumber(uni_hitos[0]?.es_master_2011, 1)} % del 2010-11. Hi ha {uni_num.slice(-1)[0]?.universidades} universitats privades amb activitat, {uni_num.slice(-1)[0]?.universidades - uni_num[0]?.universidades} més que el {uni_num[0]?.curso}.

<LineChart
    data={uni_serie}
    x=anio
    y=cuota
    series=serie
    yFmt=pct0
    xFmt="####"
    colorPalette={['#f87171', '#b91c1c', '#93c5fd', '#1d4ed8']}
    title="Estudiants en universitats privades (% del total), Espanya i Madrid"
/>

<BarChart
    data={uni_grado_ult}
    x=comunidad
    y=cuota
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#4f46e5']}
    title="Estudiants de grau presencial en universitats privades, curs {uni_grado_ult[0]?.curso}"
/>

<p class="text-xs text-gray-500">Estadística d'Estudiants Universitaris (Ministeri de Ciència, Innovació i Universitats). Els estudiants es compten a la comunitat de la universitat; les universitats a distància (UNIR, VIU, UOC, UDIMA...) es concentren en poques comunitats, per això el rànquing fa servir l'ensenyament presencial. L'últim curs és provisional.</p>

## La despesa que no surt al pressupost

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

Un pressupost diu quant pensa gastar un govern; el compte general, quant va gastar de debò. A Madrid la diferència es concentra en el que es paga als hospitals privats. El {ejec_hitos[0]?.anio_ult} el SERMAS va pressupostar {formatNumber(ejec_hitos[0]?.priv_ini, 0)} milions per a la Fundación Jiménez Díaz i els quatre hospitals de concessió, i va acabar pagant-ne {formatNumber(ejec_hitos[0]?.priv_ejec, 0)}. En conjunt, el SERMAS va gastar un {formatNumber(ejec_sermas_ult[0]?.desviacion_pct, 1)} % més del pressupostat. La partida d'interessos de demora, que es paguen quan les factures i liquidacions s'abonen tard, tenia {formatNumber(intereses[0]?.inicial_meur, 1)} milions i va acabar en {formatNumber(intereses[0]?.ejecutado_meur, 1)}.

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
    title="SERMAS: Fundación Jiménez Díaz i hospitals de concessió, pressupostat i gastat per habitant (euros de {ejec_hitos[0]?.anio_base})"
/>

<LineChart
    data={ejec_salud}
    x=anio
    y=desviacion_pct
    series=servicio
    yFmt='0.0"%"'
    xFmt="####"
    colorPalette={['#eab308', '#dc2626']}
    title="Despesa real del servei de salut per sobre del pressupost inicial (%)"
>
    <ReferenceLine y=0 color="#6b7280" />
</LineChart>

Els diners que falten es cobreixen durant l'any amb modificacions de crèdit. El {recibe[0]?.anio} el SERMAS va rebre {formatNumber(recibe[0]?.transferencias_meur, 0)} milions en transferències de crèdit. Aquell any, les partides de l'Administració de la Comunitat pressupostades sense destinació concreta, «imprevistos i insuficiències» i el fons de contingència, van cedir {formatNumber(imprev_ult[0]?.cedido_meur, 0)} milions.

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
    title="Comunitat de Madrid: crèdit cedit per imprevistos i fons de contingència (milions d'euros constants)"
/>

Quan un servei es presta sense contracte en vigor o sense la fiscalització prèvia, el pagament s'ha de legalitzar després amb una convalidació del Consell de Govern. La Cámara de Cuentas adverteix que el seu abús debilita el control. Les referències dels acords recullen {formatNumber(conval_hitos[0]?.n_max, 0)} convalidacions el {conval_hitos[0]?.anio_max} i {formatNumber(conval_hitos[0]?.n_ult, 0)} el {conval_hitos[0]?.anio_ult}; entre el {conval_sanidad[0]?.desde} i el {conval_sanidad[0]?.hasta}, les de Sanitat van sumar {formatNumber(conval_sanidad[0]?.n, 0)} per {formatNumber(conval_sanidad[0]?.meur_real, 0)} milions (euros de {conval_sanidad[0]?.anio_base}).

<BarChart
    data={conval}
    x=anio
    y=importe_eur_hab_real
    sort=false
    xFmt="####"
    yFmt='#,##0.0" €"'
    colorPalette={['#7c3aed']}
    title="Comunitat de Madrid: despesa convalidada pel Consell de Govern per habitant (euros constants)"
/>

<p class="text-xs text-gray-500">Compte General de la Comunitat de Madrid (Intervenció General): liquidació del pressupost de despeses de cada entitat per subconcepte (del 2016 endavant; el 2015 no es publica en PDF) i nota de modificacions de crèdit. Les transferències de crèdit sumen zero en el conjunt de la Comunitat: el que rep una partida ho cedeix una altra. Catalunya: execució mensual del pressupost de la Generalitat (dades obertes). Convalidacions: referències oficials dels acords del Consell de Govern des del 2004, amb l'import que cita cada acord; són un resum i es queden una mica curtes (189 el 2024, davant les 209 que compta la Cámara de Cuentas en el seu informe del Compte General). L'Agència Madrilenya d'Atenció Social i l'Agència d'Habitatge Social no publiquen la seva nota de modificacions.</p>

Els contractes menors (fins a 15.000 euros sense IVA en serveis i subministraments) s'adjudiquen sense concurs. Comprar el mateix al mateix proveïdor en diversos contractes menors dins del mateix any pot ser una manera d'esquivar el concurs. La Comunitat de Madrid només permet descarregar els seus després d'un captcha, així que la taula fa servir les dades obertes dels serveis de salut d'Andalusia i Catalunya: el percentatge de l'import que és en grups del mateix òrgan, mateix proveïdor i objecte semblant que superen el llindar.

<DataTable data={menores} rows=20>
    <Column id=comunidad title="Comunitat" />
    <Column id=anio title="Any" fmt="0" />
    <Column id=contratos title="Contractes menors" fmt="#,##0" />
    <Column id=importe_meur title="Import (M€ constants)" fmt="#,##0.0" />
    <Column id=troceo title="En grups que superen el llindar" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Plataforma de Contratación de la Junta de Andalucía (òrgans sanitaris; el Servei Andalús de Salut se separa per província) i Plataforma de serveis de contractació pública de Catalunya (Departament de Salut i ICS, amb detall des del 2023). Objecte semblant: mateixes primeres paraules del títol a Andalusia i mateix CPV de tres xifres a Catalunya; llindar de 15.000 euros (40.000 en obres) sense IVA, segons la Llei de Contractes del Sector Públic del 2017. És un senyal per revisar, no una prova de fraccionament: un òrgan que compra per a molts hospitals (SAS, ICS) acumula compres legítimes al mateix proveïdor. Informes oficials: <a href="https://www.camaradecuentasmadrid.org/admin/uploads/informe-contratacion-menor-spm-2017-aprobado-cjo-290519.pdf">Cámara de Cuentas de Madrid sobre contractació menor</a> i <a href="https://www.camaradecuentasmadrid.org/admin/uploads/if-sellado-ctagral2024-aprobadocjo23122025.pdf">sobre el Compte General del 2024</a>.</p>

## Com s'han llegit aquestes dades

Les administracions publiquen xifres resumides que sovint deixen fora el que és important. En aquesta pàgina s'ha seguit un mètode per no quedar-se a la superfície, amb documents oficials en tots els casos:

- **Anar al document complet.** L'estadística de despesa sanitària dona un percentatge de concerts; les seves taules per comunitat i partida mostren que a la Comunitat Valenciana els pagaments a les concessions no hi són: les seves compres de béns i serveis pesen uns 10 punts més que la mitjana de la resta, de l'ordre del que costaven les concessions, i el 2018, en tornar La Ribera a la gestió pública, la despesa en personal va pujar de cop sense que baixés aquesta partida. És un indici que només confirmarien el pressupost liquidat de la Conselleria o un informe de la Sindicatura de Comptes.
- **Llegir la definició de cada indicador.** El Catàleg Nacional d'Hospitals anomena públics els hospitals de concessió; la partida educativa de concerts inclou subvencions a centres sense concert; l'FP i la universitat a distància es compten on hi ha la seu.
- **Comparar amb un any base**, en euros constants i per habitant, per separar el creixement real del que només reflecteix preus i població.
- **Desagregar.** El total d'FP amaga famílies com Sanitat, on la privada és majoria; el total universitari amaga el màster.
- **Comparar l'informe de difusió amb la rendició de comptes.** L'informe mensual de llistes d'espera de Madrid compta només qui té cita; la memòria anual del SERMAS compta també qui espera sense.
- **Contrastar amb les altres comunitats.** Si la demora mitjana d'una comunitat no lliga amb la mida de la seva llista d'espera, alguna cosa queda fora del càlcul.
- **Pressupost davant compte general.** Les partides que es pressuposten curtes a consciència es completen durant l'any amb modificacions de crèdit, i el compte general diu d'on surten els diners.
- **Seguir els fluxos, no només els totals.** El saldo de la lliure elecció diu quins hospitals guanyen pacients i quins en perden; les convalidacions i els contractes menors repetits assenyalen despesa feta fora del procediment ordinari.

---

## Fonts i notes

- **[Ministeri de Sanitat – Estadística de Despesa Sanitària Pública](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm)** (comptes satèl·lit, classificació econòmica i funcional per comunitat).
- **[Ministeri de Sanitat – Catàleg Nacional d'Hospitals](https://www.sanidad.gob.es/estadEstudios/estadisticas/sisInfSanSNS/ofertaRecursos/hospitales/home.htm)**.
- **[Ministeri de Sanitat – Evaluación de la sanidad privada en el sistema sanitario de España](https://vsf-iwsold-pro-portal.sanidad.gob.es/gabinetePrensa/notaPrensa/pdf/20251091225131137451.pdf)** (desembre del 2025), amb el Baròmetre Sanitari.
- **Hospitals de gestió privada**: taula elaborada per a SpainFacts amb els decrets de reversió del DOGV, les memòries dels hospitals del SERMAS i, quan no hi ha dada oficial, premsa amb cita; cada fila porta la seva font a la taula descarregable.
- **[Comunitat de Madrid – Memòries del Servicio Madrileño de Salud](https://www.comunidad.madrid/salud/memorias-e-informes-servicio-madrileno-salud)** (llista d'espera a 31 de desembre i lliure elecció, també a les memòries de cada hospital) i **[informes mensuals de llistes d'espera](https://www.comunidad.madrid/salud/lista-espera-consultas-externas)**; **SISLE-SNS** (Ministeri de Sanitat) per comparar amb les altres comunitats.
- **[Comunitat de Madrid – Compte General](https://www.comunidad.madrid/gobierno/hacienda/cuentas-generales)** (Intervenció General: liquidació del pressupost i modificacions de crèdit per entitat), **[referències dels acords del Consell de Govern](https://www.comunidad.madrid/acuerdos-consejo-gobierno)** i **[Generalitat de Catalunya – execució del pressupost](https://analisi.transparenciacatalunya.cat/d/ajns-4mi7)**.
- Contractes menors: **[Junta de Andalucía – contractació menor](https://www.juntadeandalucia.es/datosabiertos/portal/)** i **[Generalitat de Catalunya – Plataforma de serveis de contractació pública](https://analisi.transparenciacatalunya.cat/d/ybgg-dgi6)**.
- **[INE – Enquesta de Pressupostos Familiars](https://www.ine.es/jaxiT3/Tabla.htm?t=73991)** (despesa en sanitat per persona).
- **[Ministeri d'Educació – EDUCAbase](https://estadisticas.educacion.gob.es/EducaDynPx/educabase/index.htm)**: Estadística dels Ensenyaments no universitaris i Estadística de la Despesa Pública en Educació.
- **[Ministeri de Ciència, Innovació i Universitats – Estadística d'Estudiants Universitaris](https://estadisticas.ciencia.gob.es/)** i **[Registre d'Universitats, Centres i Títols](https://www.educacion.gob.es/ruct/listauniversidades?consulta=1)**.
- Context: reportatges d'elDiario.es «De pacientes a clientes» (14-02-2026) i «El Gobierno trata de levantar un muro contra la privatización desaforada en sanidad y educación» (13-02-2026); les declaracions de Freire, Bengoa i Urbanos procedeixen del primer. Cap xifra de la pàgina no en surt.
- Deflactor: IPC mitjà anual de l'INE. Població: INE.

<LastRefreshed prefix="Dades actualitzades" />
