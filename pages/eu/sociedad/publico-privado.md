---
title: Publikoa eta pribatua
description: "Osasun eta hezkuntza publikoen zein zati ematen den enpresa eta zentro pribatuen bidez, erkidegoz erkidego: osasun-itunak, emakida-ospitaleak, aseguru pribatuak, eskola itunpekoa, LH eta unibertsitate pribatuak."
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

# 🏥 Publikoa eta pribatua

Osasuna eta hezkuntza publikoak eta doakoak dira, baina gero eta zati handiagoa diru publikoarekin ordaindutako enpresa eta zentro pribatuen bidez ematen da, eta beste zati bat familiek beren poltsikotik ordaintzen dute. Orri honek erkidegoz erkidego neurtzen du zenbat dagoen bakoitzetik: osasun-itunak, enpresek kudeatutako ospitale publikoak, aseguru pribatuak, eskola itunpekoa, LH eta unibertsitate pribatuak. Zifrak biztanleko edo ehunekotan daude, eta euroak, inflazioa kenduta.

<Grid cols=4>
    <KpiCard
        title="Madril: zentro pribatuei ordaindutako osasun publikoa"
        value={conc_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(conc_madrid.slice(-1)[0]?.valor, 1)} %"
        period="osasun-gastu publikoarena itunetan, {conc_madrid.slice(-1)[0]?.anio} · {formatNumber(conc_madrid.slice(-1)[0]?.gasto_eur_hab_real, 0)} € biztanleko ({conc_madrid.slice(-1)[0]?.anio_base}ko euroak)"
        source="Osasun Ministerioa (EGSP)"
        sparklineData={conc_madrid}
    />
    <KpiCard
        title="Madril: kudeaketa pribatuko ospitalea duen biztanleria"
        value={cob_madrid.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(cob_madrid.slice(-1)[0]?.valor, 1)} %"
        period="{cob_madrid.slice(-1)[0]?.anio} · {formatNumber(cob_hitos[0]?.mad_pob, 0)} pertsona"
        source="SERMAS · ospitaleen memoriak"
        sparklineData={cob_madrid}
    />
    <KpiCard
        title="Mediku-aseguru pribatuarekin"
        value={seg_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(seg_es.slice(-1)[0]?.valor, 1)} %"
        period="biztanleriarena, {seg_es.slice(-1)[0]?.anio} · Madril: {formatNumber(seg_hitos[0]?.mad_ult, 1)} %"
        source="Osasun Barometroa"
        sparklineData={seg_es}
    />
    <KpiCard
        title="Ikasleak zentro pribatuetan"
        value={alu_es.slice(-1)[0]?.valor}
        formattedValue="{formatNumber(alu_es.slice(-1)[0]?.valor, 1)} %"
        period="haur hezkuntzatik LHra, {alu_hitos[0]?.curso_ult} ikasturtea · Madril: {formatNumber(alu_hitos[0]?.mad_priv, 1)} %"
        source="Hezkuntza Ministerioa"
        sparklineData={alu_es}
    />
</Grid>

<p class="text-xs text-gray-500">Irakaskuntzako zentro pribatuak: itunpekoak (funts publikoekin finantzatuak) eta itunik gabekoak. Aseguru pribatua Osasun Barometroko inkestatuen erantzuna da, eta aseguru indibiduala eta enpresakoa hartzen ditu kontuan.</p>

## Osasuna

### Zenbat ordaintzen dien osasun publikoak zentro pribatuei

Erkidego guztiek bideratzen dituzte pazienteak klinika pribatuetara proba, ebakuntza edo espezialitate jakin batzuetarako: horiek dira itunak. {conc_hitos[0]?.anio_ult}an erkidego guztiek, batera, beren osasun-gastuaren % {formatNumber(conc_hitos[0]?.tot_pct_ult, 1)} bideratu zuten horietara. Katalunia (% {formatNumber(conc_hitos[0]?.cat_pct_ult, 1)}) eta Madril (% {formatNumber(conc_hitos[0]?.mad_pct_ult, 1)}) dira gehien bideratzen dutenak. Lerroak % 15 markatzen du: Rafael Bengoa Eusko Jaurlaritzako sailburu ohiaren eta OMEko zuzendari ohiaren arabera, Europako sistemek kanpoan kontratatu nahi izaten duten gehienekoa da atalase hori.

<BarChart
    data={conc_ult}
    x=comunidad
    y=peso_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#0f766e']}
    title="Itunen pisua osasun-gastu publikoan, {conc_ult[0]?.anio} (%)"
>
    <ReferenceLine y=15 label="% 15" color="#dc2626" />
</BarChart>

```sql conc_lineas
SELECT anio, CASE WHEN cod_ccaa = '00' THEN 'Total comunidades' ELSE ccaa END AS comunidad, gasto_eur_hab_real
FROM ${conc}
WHERE cod_ccaa IN ('00', '09', '10', '13')
ORDER BY anio
```

Biztanleko eurotan eta inflazioa kenduta, Madril {conc_hitos[0]?.anio_ini}ko {formatNumber(conc_hitos[0]?.mad_ini, 0)} €-tik {conc_hitos[0]?.anio_ult}ko {formatNumber(conc_hitos[0]?.mad_ult, 0)} €-ra igaro da; erkidego guztiak batera, {formatNumber(conc_hitos[0]?.tot_ini, 0)} €-tik {formatNumber(conc_hitos[0]?.tot_ult, 0)} €-ra. Madrilen jauzia Torrejón (2011), Rey Juan Carlos (2012) eta Villalbako (2014) emakida-ospitaleak irekitzearekin bat dator; estatistikak itun gisa zenbatzen ditu horiek.

<LineChart
    data={conc_lineas}
    x=anio
    y=gasto_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Itunetako osasun-gastu publikoa biztanleko ({conc_hitos[0]?.anio_base}ko euroak)"
/>

<p class="text-xs text-gray-500">Osasun Gastu Publikoaren Estatistika (Osasun Ministerioa), autonomia-erkidegoen gastu bateratua. Itunak: kanpoko zentroei (ospitale-arreta, arreta espezializatua, lehen mailakoa, gaixoen garraioa) eta beste administrazio batzuei erositako laguntza. Azken bi urteak behin-behinekoak dira. <b>Katalunia</b>: bere pisu handia irabazi-asmorik gabeko ospitale itunpekoen sare historikotik dator (fundazioak, erlijio-ordenak, SISCATeko partzuergoak), ez irabazi-asmoko enpresetatik. <b>Valentziako Erkidegoa</b>: estatistikak ez ditu itun gisa jasotzen Alzira ereduko emakida-ospitaleei biztanleko egindako ordainketak; {conc_hitos[0]?.anio_ult}ko % {formatNumber(conc_hitos[0]?.val_pct_ult, 1)} horrek ez du esan nahi pribatizazio gutxi dagoenik (ikus «Nola irakurri diren datu hauek»).</p>

### Aseguramendua pribatizatzea: biztanleko kobratzen duten ospitaleak

Itunez gain, Madril eta Valentziako Erkidegoa dira eremu osoetako arreta osoa enpresen esku utzi duten erkidego bakarrak: administrazioak kopuru finko bat ordaintzen dio emakidadunari esleitutako biztanle bakoitzeko, eta enpresa haien osasunaren arduradun egiten da. José Manuel Freire Osasun Eskola Nazionaleko irakasle emerituak aseguramendua pribatizatzea deitzen dio horri. Valentziako Erkidegoan biztanleriaren % {formatNumber(cob_hitos[0]?.val_max, 1)} estaltzera iritsi zen; 2018an hasitako itzulketen ondoren % {formatNumber(cob_hitos[0]?.val_pct, 1)} geratzen da (Vinalopó bakarrik, Elchen). Madrilen % {formatNumber(cob_hitos[0]?.mad_pct, 1)} hartzen du ({formatNumber(cob_hitos[0]?.mad_pob, 0)} pertsona {cob_hitos[0]?.anio_ult}an; horietatik {formatNumber(cob_hitos[0]?.mad_concesion, 0)} biztanleko emakidetan, eta gainerakoak Fundación Jiménez Díazen, egintzako kobratzen baitu).

<LineChart
    data={cob_graf}
    x=anio
    y=cuota
    series=comunidad
    yFmt=pct0
    xFmt="####"
    step=true
    colorPalette={['#f97316', '#dc2626']}
    title="Kudeaketa pribatuko erreferentziako ospitalea duen biztanleria (erkidegoaren %)"
/>

<DataTable data={hospitales_lista} rows=20>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=hospital title="Ospitalea" />
    <Column id=modelo title="Eredua" />
    <Column id=empresa title="Enpresa" />
    <Column id=inicio title="Noiztik" fmt="0" />
    <Column id=estado title="Egoera" />
    <Column id=poblacion title="Esleitutako biztanleria" fmt="#,##0" />
</DataTable>

<p class="text-xs text-gray-500">Esleitutako biztanleria: ospitale edo kontseilaritza bakoitzak argitaratutako berriena (SERMASen memoriak, DOGVko itzulketa-dekretuak); zifra ofizialik gabeko urteetan, ospitale bakoitzak bere erkidegoan duen pisua mantenduz kalkulatzen da, eta, beraz, seriea gutxi gorabeherakoa da. Gainera, madrildarren % {formatNumber(cob_hitos[0]?.mad_pfi_pct, 1)}k 2008tik aurrera enpresek eraikitako ospitale bat du erreferentzia; enpresa horiek kanon bat kobratzen dute 30 urtez eta osasunekoak ez diren zerbitzuak kudeatzen dituzte (garbiketa, sukaldea, mantentze-lanak); haien osasun-langileak publikoak dira eta ez dira grafikoan zenbatzen. Ospitaleen Katalogo Nazionalak publiko gisa sailkatzen ditu emakida-ospitaleak.</p>

### Madril: argitaratzen ez den itxaron-zerrenda

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

Hilero, Madrilgo Erkidegoak argitaratzen du zenbat paziente dauden lehen kontsulta, proba edo ebakuntza baten zain. Zifra horrek data dutenak bakarrik zenbatzen ditu: zerbitzuak agenda itxita badu, pazientea hitzordua emateko zain geratzen da eta ez da agertzen. SERMASen urteko memoriak, aldiz, zenbatzen ditu. {le_hitos[0]?.anio_ult}ko abenduaren 31n zerrenda osoa {formatNumber(le_hitos[0]?.total_ult, 0)} pazientekoa zen, {formatNumber(le_hitos[0]?.total_1000_ult, 0)} 1.000 biztanleko, eta horietatik {formatNumber(le_hitos[0]?.sin_cita_ult, 0)}k ez zuten hitzordurik.

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
    title="Madril: itxaron-zerrendako pazienteak 1.000 biztanleko abenduaren 31n (kontsultak, probak eta kirurgia)"
/>

<DataTable data={le_esp} rows=10>
    <Column id=tipo title="Mota" />
    <Column id=especialidad title="Espezialitatea edo proba" />
    <Column id=sin_cita_2021 title="Hitzordurik gabe 2021ean" fmt="#,##0" />
    <Column id=sin_cita_ult title="Hitzordurik gabe, azken urtea" fmt="#,##0" />
    <Column id=veces title="Aldiz" fmt="0.0x" />
</DataTable>

Hitzordurik ez duena ez da batez besteko itxaronaldian ere sartzen. Erkidego bakoitzak adierazten duen itxaronaldia bere zerrendaren tamainari legokiokeenarekin alderatuz gero (gainerako erkidegoekin doitutako zuzen bat), Madril gainerakoetatik bereizten da 2023tik: azken ebakian {formatNumber(coh_ult[0]?.dias_declarados, 0)} egun adierazten ditu lehen kontsulta baterako, bere zerrendak {formatNumber(coh_ult[0]?.dias_esperados, 0)} egun inguru itxaronarazi beharko lukeenean; {formatNumber(Math.abs(coh_ult[0]?.z), 1)} desbideratze estandarreko aldea.

<LineChart
    data={coh_graf}
    x=fecha
    y=dias
    series=demora
    yFmt=num0
    colorPalette={['#dc2626', '#94a3b8']}
    title="Madril: lehen kontsultarako batez besteko itxaronaldia, adierazitakoa eta espero zitekeena (egunak)"
/>

<p class="text-xs text-gray-500">SERMASen urteko memoria (itxaron-zerrendaren kapitulua: 2015-2020, memoria osoaren PDFtik; 2021etik, haren datu irekien fitxategietatik) eta Osasun Kontseilaritzaren hileko txostenak. Probak: memoriak zehazten dituen 8 teknikak. 2022ra arte memoriako guztizkoa abenduko hileko txostenean argitaratutakoa baino nabarmen txikiagoa zen (2022an, 394.347 eta 555.026); 2023tik memoriako hitzordudun pazienteak hileko txostenarekin bat datoz, eta, beraz, 2023ko jauziak irizpide-aldaketa hori islatzen du neurri batean, eta seriea ez da jarraitutzat irakurri behar. Espero zitekeen itxaronaldia: SISLE-SNSren (Osasun Ministerioa) seihileko ebaki bakoitzerako, zuzen bat doitzen da 1.000 biztanleko paziente-tasaren eta gainerako erkidegoen batez besteko itxaronaldiaren artean. Madrilgo zerrenda beste edozein erkidegotakoa baino handiagoa da; beraz, espero zitekeen itxaronaldia zuzen horren estrapolazioa da.</p>

Beren ospitalean hitzordurik lortu ezean, paziente askok beste batean amaitzen dute askatasunez aukeratzeko eskubideari esker, 2009an ezarria. Kudeaketa pribatuko ospitaleen saldoa (jasotako hitzorduak ken lagatakoak) {le_libre_hitos[0]?.anio_ini}ko {formatNumber(le_libre_hitos[0]?.saldo_priv_ini, 0)} hitzordutik {le_libre_hitos[0]?.anio_ult}ko {formatNumber(le_libre_hitos[0]?.saldo_priv_ult, 0)}ra igaro zen; kudeaketa publikokoek ia beste horrenbeste galtzen dituzte.

<LineChart
    data={le_libre}
    x=anio
    y=saldo_por_1000_hab
    series=gestion
    yFmt=num0
    xFmt="####"
    colorPalette={['#2563eb', '#f97316', '#dc2626', '#94a3b8']}
    title="Madril: askatasunez aukeratutako hitzorduen saldoa ospitale motaren arabera (1.000 biztanleko)"
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
    title="Traumatologia: askatasunez aukeratzeagatik paziente gehien irabazi eta galtzen dituzten ospitaleak ({le_libre_hitos[0]?.anio_ult})"
/>

<p class="text-xs text-gray-500">SERMASen memoriako askatasunez aukeratzearen balantzea eta ospitale bakoitzaren memorietako «Consultas Libre Elección» orriak. Kudeaketa pribatua: emakida-ospitaleak (Rey Juan Carlos, Infanta Elena, Villalba, Torrejón) eta Fundación Jiménez Díaz. Kontseilaritzak ez du argitaratzen hitzordua eskatzean ordezko ospitaleak eskaintzen dituen algoritmoa, ezta ospitale bakoitzak paziente horiengatik fakturatzen duena ere.</p>

### Ahal duenak, asegurua ordaintzen du

Rosa María Urbanos katedradunak, SNSren Behatokiko lehen zuzendariak, bi arrazoi aipatzen ditu aseguru pribatu bat kontratatzeko: gutxiago itxarotea eta espezialistarengana familia-medikutik pasatu gabe joan ahal izatea. Osasun Barometroaren arabera, aseguru pribatua duen biztanleria % {formatNumber(seg_hitos[0]?.es_ini, 1)} izatetik ({seg_hitos[0]?.anio_ini}) % {formatNumber(seg_hitos[0]?.es_ult, 1)} izatera ({seg_hitos[0]?.anio_ult}) igaro da; Madrilen, % {formatNumber(seg_hitos[0]?.mad_ult, 1)}.

<BarChart
    data={seg_ult}
    x=comunidad
    y=seguro_privado_pct
    swapXY=true
    sort=false
    yFmt='0.0"%"'
    colorPalette={['#7c3aed']}
    title="Mediku-aseguru pribatua duen biztanleria, {seg_ult[0]?.anio} (%)"
/>

<LineChart
    data={hogares}
    x=anio
    y=gasto_persona_eur_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#eab308', '#f97316', '#dc2626']}
    title="Etxeek osasunean beren poltsikotik egindako gastua, pertsonako (euro konstanteak)"
/>

<p class="text-xs text-gray-500">Osasun Barometroa (Osasun Ministerioaren «Evaluación de la sanidad privada en el sistema sanitario de España» txostenaren 1. taula, 2025eko abendua), aseguru indibiduala edo enpresakoa. Etxeen gastua: INEren Familia Aurrekontuen Inkesta, Osasuna taldea (botikak, dentista, optika, zuzenean ordaindutako kontsultak eta ospitaleratzeak); ez ditu aseguruen primak barne hartzen.</p>

### Ospitale pribatuak sare publikoaren barruan

Titulartasun pribatuko ospitale asko osasun publikorako ia soilik aritzen dira: haren sarearen parte dira edo itun bidez ordezkatzen dute. Osasun Ministerioaren 2025eko abenduko txostenaren arabera, 2011 eta 2023 artean haien gastua % 84,6 hazi zen, ospitale publikoen % 50,3aren aldean.

<BarChart
    data={camas}
    x=comunidad
    y=cuota_red
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#0891b2']}
    title="Sare publikoan integratutako ospitale pribatuetako edo irabazi-asmorik gabeko erakundeetako oheak, {camas[0]?.anio} (oheen %)"
/>

<p class="text-xs text-gray-500">Ospitaleen Katalogo Nazionala (Osasun Ministerioa): erabilera publikoko sarekoak diren edo itun ordezkatzailea duten mendekotasun pribatuko, mutualitateko edo irabazi-asmorik gabeko ospitaleak. Ez ditu barne hartzen emakida-ospitaleak, katalogoak publiko gisa zenbatzen baititu.</p>

## Hezkuntza

### Eskola itunpekoa eta pribatua

{alu_hitos[0]?.curso_ult} ikasturtean, Espainian haur hezkuntzatik LHra bitarteko ikasleen % {formatNumber(alu_hitos[0]?.es_priv, 1)} zentro pribatu batean ikasten ari zen, gehienak itunpekoetan. Madril (% {formatNumber(alu_hitos[0]?.mad_priv, 1)}) da itunik gabeko zentro pribatuetan ikasle gehien dituen erkidegoa: % {formatNumber(alu_hitos[0]?.mad_nc, 1)}, Espainiako % {formatNumber(alu_hitos[0]?.es_nc, 1)}aren aldean.

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
    title="Unibertsitatez kanpoko ikasleak zentro pribatuetan, {alu_rank[0]?.curso} ikasturtea"
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
    title="Itunik gabeko zentro pribatuetako ikasleak etaparen arabera: Madril eta Espainia"
/>

<p class="text-xs text-gray-500">Unibertsitatez kanpoko Irakaskuntzen Estatistika (Hezkuntza Ministerioa). Euskadin eta Nafarroan itunpekoak jatorri historikoa du (ikastolak, kooperatibak) eta haren pisua jaisten ari da urteekin; Madrilen itunik gabeko pribatua hazten ari da. Haur hezkuntzako lehen zikloan (0-2 urte), «itunpekoa» kategoriak diru-laguntzaren bat duen edozein zentro pribatu hartzen du barne.</p>

### Zenbat ordaintzen dioten erkidegoek itunpekoari

```sql conc_edu_lineas
SELECT anio, comunidad, conciertos_eur_hab_real FROM ${conc_edu}
WHERE cod_ccaa IN ('00', '13', '15', '16', '10') AND anio >= 2000
ORDER BY anio
```

{conc_edu_hitos[0]?.anio_ult}an hezkuntza-administrazioek {formatNumber(conc_edu_hitos[0]?.es_ult, 0)} € bideratu zituzten biztanleko zentro pribatuentzako itun eta diru-laguntzetara ({conc_edu_hitos[0]?.anio_base}ko euroak), beren gastuaren % {formatNumber(conc_edu_hitos[0]?.es_peso, 1)}. Madrilen zifra 2000ko {formatNumber(conc_edu_hitos[0]?.mad_ini, 0)} €-tik {formatNumber(conc_edu_hitos[0]?.mad_ult, 0)} €-ra igaro da, eta haren pisua % {formatNumber(conc_edu_hitos[0]?.mad_peso, 1)} da dagoeneko.

<LineChart
    data={conc_edu_lineas}
    x=anio
    y=conciertos_eur_hab_real
    series=comunidad
    yFmt='#,##0" €"'
    xFmt="####"
    colorPalette={['#94a3b8', '#16a34a', '#dc2626', '#0891b2', '#f97316']}
    title="Irakaskuntza pribaturako itunak eta diru-laguntzak biztanleko (euro konstanteak)"
/>

<p class="text-xs text-gray-500">Hezkuntzako Gastu Publikoaren Estatistika (Hezkuntza Ministerioa), likidatutako gastua. Partidak itunik gabeko zentro pribatuentzako diru-laguntzak ere barne hartzen ditu eta, 2017tik, unibertsitate pribatuei egindako transferentziak.</p>

### LH: pribatua hazten da publikoa falta den lekuan

{fp_hitos[0]?.curso_ini} eta {fp_hitos[0]?.curso_ult} artean, zentro pribatuetan urrutiko goi-mailako LH egiten zuten ikasleak {formatNumber(fp_hitos[0]?.sup_ini, 0)} izatetik {formatNumber(fp_hitos[0]?.sup_ult, 0)} izatera igaro ziren: gaur egun urrutiko goi-mailako LH osoaren % {formatNumber(fp_hitos[0]?.sup_cuota_ult * 100, 1)} dira. Osasuna bezalako lanbide-arloetan goi-mailako ikasle gehienak pribatuan ari dira.

<LineChart
    data={fp_dist}
    x=anio
    y=cuota
    series=grado
    yFmt=pct0
    xFmt="####"
    colorPalette={['#fb923c', '#b91c1c']}
    title="Urrutiko LH: zentro pribatuetako ikasleak (guztizkoaren %), Espainia"
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
    title="Goi-mailako LH: zentro pribatuetako ikasleak lanbide-arloaren arabera"
/>

<p class="text-xs text-gray-500">Espainian goi-mailako gutxienez 5.000 ikasle dituzten lanbide-arloak. Pribatua: itunpekoa eta itunik gabekoa. Urrutiko ikasleak zentroaren egoitza dagoen erkidegoan zenbatzen dira; horregatik biltzen dute erkidego gutxi batzuek online LH.</p>

### Unibertsitate pribatuak

{uni_hitos[0]?.curso_grado} ikasturtean, Espainian aurrez aurreko graduko ikasleen % {formatNumber(uni_hitos[0]?.es_grado, 1)} unibertsitate pribatu batera joaten zen, eta Madrilen % {formatNumber(uni_hitos[0]?.mad_grado, 1)}. Masterrean, urrutiko irakaskuntza kontuan hartuta, pribatua gehiengoa da dagoeneko: % {formatNumber(uni_hitos[0]?.es_master, 1)} {uni_hitos[0]?.curso_master} ikasturtean, 2010-11ko % {formatNumber(uni_hitos[0]?.es_master_2011, 1)}aren aldean. Jardunean {uni_num.slice(-1)[0]?.universidades} unibertsitate pribatu daude, {uni_num[0]?.curso} ikasturtean baino {uni_num.slice(-1)[0]?.universidades - uni_num[0]?.universidades} gehiago.

<LineChart
    data={uni_serie}
    x=anio
    y=cuota
    series=serie
    yFmt=pct0
    xFmt="####"
    colorPalette={['#f87171', '#b91c1c', '#93c5fd', '#1d4ed8']}
    title="Unibertsitate pribatuetako ikasleak (guztizkoaren %), Espainia eta Madril"
/>

<BarChart
    data={uni_grado_ult}
    x=comunidad
    y=cuota
    swapXY=true
    sort=false
    yFmt=pct0
    colorPalette={['#4f46e5']}
    title="Aurrez aurreko graduko ikasleak unibertsitate pribatuetan, {uni_grado_ult[0]?.curso} ikasturtea"
/>

<p class="text-xs text-gray-500">Unibertsitateko Ikasleen Estatistika (Zientzia, Berrikuntza eta Unibertsitate Ministerioa). Ikasleak unibertsitatearen erkidegoan zenbatzen dira; urrutiko unibertsitateak (UNIR, VIU, UOC, UDIMA...) erkidego gutxitan biltzen dira, eta horregatik sailkapenak aurrez aurreko irakaskuntza erabiltzen du. Azken ikasturtea behin-behinekoa da.</p>

## Aurrekontuan agertzen ez den gastua

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

Aurrekontu batek esaten du gobernu batek zenbat gastatzeko asmoa duen; kontu orokorrak, benetan zenbat gastatu zuen. Madrilen aldea ospitale pribatuei ordaintzen zaienean biltzen da. {ejec_hitos[0]?.anio_ult}an SERMASek {formatNumber(ejec_hitos[0]?.priv_ini, 0)} milioi aurrekontuan jarri zituen Fundación Jiménez Díazentzat eta lau emakida-ospitaleentzat, eta azkenean {formatNumber(ejec_hitos[0]?.priv_ejec, 0)} ordaindu zituen. Oro har, SERMASek aurrekontuan jarritakoa baino % {formatNumber(ejec_sermas_ult[0]?.desviacion_pct, 1)} gehiago gastatu zuen. Berandutze-interesen partidak, fakturak eta likidazioak berandu ordaintzen direnean ordaintzen direnak, {formatNumber(intereses[0]?.inicial_meur, 1)} milioi zituen eta {formatNumber(intereses[0]?.ejecutado_meur, 1)}ekin amaitu zuen.

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
    title="SERMAS: Fundación Jiménez Díaz eta emakida-ospitaleak, aurrekontuan jarritakoa eta gastatutakoa biztanleko ({ejec_hitos[0]?.anio_base}ko euroak)"
/>

<LineChart
    data={ejec_salud}
    x=anio
    y=desviacion_pct
    series=servicio
    yFmt='0.0"%"'
    xFmt="####"
    colorPalette={['#eab308', '#dc2626']}
    title="Osasun-zerbitzuaren benetako gastua hasierako aurrekontuaren gainetik (%)"
>
    <ReferenceLine y=0 color="#6b7280" />
</LineChart>

Falta den dirua urtean zehar kreditu-aldaketekin estaltzen da. {recibe[0]?.anio}an SERMASek {formatNumber(recibe[0]?.transferencias_meur, 0)} milioi jaso zituen kreditu-transferentzietan. Urte horretan, Erkidegoko Administrazioaren helburu zehatzik gabe aurrekontuan jarritako partidek, «ezustekoak eta urritasunak» eta kontingentzia-funtsak, {formatNumber(imprev_ult[0]?.cedido_meur, 0)} milioi laga zituzten.

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
    title="Madrilgo Erkidegoa: ezustekoek eta kontingentzia-funtsak lagatako kreditua (euro konstanteen milioiak)"
/>

Zerbitzu bat indarreko kontraturik gabe edo aurretiazko fiskalizaziorik gabe ematen denean, ordainketa gero legeztatu behar da Gobernu Kontseiluaren baliozkotze baten bidez. Kontuen Ganberak ohartarazten du haien gehiegizko erabilerak kontrola ahultzen duela. Akordioen erreferentziek {formatNumber(conval_hitos[0]?.n_max, 0)} baliozkotze jasotzen dituzte {conval_hitos[0]?.anio_max}an eta {formatNumber(conval_hitos[0]?.n_ult, 0)} {conval_hitos[0]?.anio_ult}an; {conval_sanidad[0]?.desde} eta {conval_sanidad[0]?.hasta} artean, Osasunekoak {formatNumber(conval_sanidad[0]?.n, 0)} izan ziren, {formatNumber(conval_sanidad[0]?.meur_real, 0)} milioiren truke ({conval_sanidad[0]?.anio_base}ko euroak).

<BarChart
    data={conval}
    x=anio
    y=importe_eur_hab_real
    sort=false
    xFmt="####"
    yFmt='#,##0.0" €"'
    colorPalette={['#7c3aed']}
    title="Madrilgo Erkidegoa: Gobernu Kontseiluak baliozkotutako gastua biztanleko (euro konstanteak)"
/>

<p class="text-xs text-gray-500">Madrilgo Erkidegoaren Kontu Orokorra (Intervención General): erakunde bakoitzaren gastu-aurrekontuaren likidazioa azpikontzeptuka (2016tik aurrera; 2015ekoa ez da PDFn argitaratzen) eta kreditu-aldaketen oharra. Kreditu-transferentziek zero batzen dute Erkidego osoan: partida batek jasotzen duena beste batek lagatzen du. Katalunia: Generalitateko aurrekontuaren hileko betearazpena (datu irekiak). Baliozkotzeak: Gobernu Kontseiluaren akordioen erreferentzia ofizialak 2004tik, akordio bakoitzak aipatzen duen zenbatekoarekin; laburpen bat dira eta zertxobait laburrak geratzen dira (189 2024an, Kontuen Ganberak Kontu Orokorrari buruzko txostenean zenbatzen dituen 209en aldean). Agencia Madrileña de Atención Social eta Agencia de Vivienda Social erakundeek ez dute beren kreditu-aldaketen oharra argitaratzen.</p>

Kontratu txikiak (zerbitzu eta horniduretan 15.000 euro arte, BEZik gabe) lehiaketarik gabe esleitzen dira. Gauza bera hornitzaile berari urte berean kontratu txiki batzuetan erostea lehiaketa saihesteko modu bat izan daiteke. Madrilgo Erkidegoak captcha baten ondoren bakarrik uzten ditu bereak deskargatzen; horregatik, taulak Andaluziako eta Kataluniako osasun-zerbitzuen datu irekiak erabiltzen ditu: atalasea gainditzen duten organo, hornitzaile eta antzeko xede bereko taldeetan dagoen zenbatekoaren ehunekoa.

<DataTable data={menores} rows=20>
    <Column id=comunidad title="Erkidegoa" />
    <Column id=anio title="Urtea" fmt="0" />
    <Column id=contratos title="Kontratu txikiak" fmt="#,##0" />
    <Column id=importe_meur title="Zenbatekoa (M€ konstanteak)" fmt="#,##0.0" />
    <Column id=troceo title="Atalasea gainditzen duten taldeetan" fmt=pct0 />
</DataTable>

<p class="text-xs text-gray-500">Andaluziako Juntaren Kontratazio Plataforma (osasun-organoak; Servicio Andaluz de Salud probintziaka bereizten da) eta Kataluniako kontratazio publikoko zerbitzuen plataforma (Departament de Salut eta ICS, xehetasunarekin 2023tik). Antzeko xedea: tituluaren lehen hitz berak Andaluzian eta hiru zifrako CPV bera Katalunian; 15.000 euroko atalasea (40.000 obretan) BEZik gabe, 2017ko Sektore Publikoko Kontratuen Legearen arabera. Berrikusteko seinale bat da, ez zatikatzearen froga: ospitale askorentzat erosten duen organo batek (SAS, ICS) hornitzaile berari egindako erosketa legitimoak metatzen ditu. Txosten ofizialak: <a href="https://www.camaradecuentasmadrid.org/admin/uploads/informe-contratacion-menor-spm-2017-aprobado-cjo-290519.pdf">Madrilgo Kontuen Ganbera kontratazio txikiari buruz</a> eta <a href="https://www.camaradecuentasmadrid.org/admin/uploads/if-sellado-ctagral2024-aprobadocjo23122025.pdf">2024ko Kontu Orokorrari buruz</a>.</p>

## Nola irakurri diren datu hauek

Administrazioek zifra laburtuak argitaratzen dituzte, eta askotan garrantzitsuena kanpoan uzten dute. Orri honetan metodo bat jarraitu da azalean ez geratzeko, kasu guztietan dokumentu ofizialekin:

- **Dokumentu osora jotzea.** Osasun-gastuaren estatistikak itunen ehuneko bat ematen du; erkidego eta partidaka dituen taulek erakusten dute Valentziako Erkidegoan emakidei egindako ordainketak ez daudela hor: haren ondasun eta zerbitzuen erosketek gainerakoen batez bestekoak baino 10 puntu inguru gehiago pisatzen dute, emakidek kostatzen zutenaren parekoa, eta 2018an, La Ribera kudeaketa publikora itzultzean, langile-gastua bat-batean igo zen partida hori jaitsi gabe. Zantzu bat da, Conselleriaren aurrekontu likidatuak edo Sindicatura de Comptesen txosten batek bakarrik baieztatuko luketena.
- **Adierazle bakoitzaren definizioa irakurtzea.** Ospitaleen Katalogo Nazionalak publiko deitzen die emakida-ospitaleei; hezkuntzako itunen partidak itunik gabeko zentroentzako diru-laguntzak barne hartzen ditu; urrutiko LH eta unibertsitatea egoitza dagoen lekuan zenbatzen dira.
- **Oinarri-urte batekin alderatzea**, euro konstanteetan eta biztanleko, benetako hazkundea prezioak eta biztanleria soilik islatzen dituenetik bereizteko.
- **Banakatzea.** LHko guztizkoak Osasuna bezalako arloak ezkutatzen ditu, non pribatua gehiengoa den; unibertsitateko guztizkoak masterra ezkutatzen du.
- **Zabalkunde-txostena kontu-ematearekin alderatzea.** Madrilgo itxaron-zerrenden hileko txostenak hitzordua dutenak bakarrik zenbatzen ditu; SERMASen urteko memoriak hitzordurik gabe zain daudenak ere zenbatzen ditu.
- **Gainerako erkidegoekin kontrastatzea.** Erkidego baten batez besteko itxaronaldia bere itxaron-zerrendaren tamainarekin bat ez badator, zerbait kalkulutik kanpo geratzen da.
- **Aurrekontua eta kontu orokorra.** Jakinaren gainean motz aurrekontuan jartzen diren partidak urtean zehar osatzen dira kreditu-aldaketekin, eta kontu orokorrak esaten du nondik ateratzen den dirua.
- **Fluxuei jarraitzea, ez guztizkoei bakarrik.** Askatasunez aukeratzearen saldoak esaten du zein ospitalek irabazten dituzten pazienteak eta zeinek galtzen dituzten; baliozkotzeek eta errepikatutako kontratu txikiek ohiko prozeduratik kanpo egindako gastua seinalatzen dute.

---

## Iturriak eta oharrak

- **[Osasun Ministerioa – Estadística de Gasto Sanitario Público](https://www.sanidad.gob.es/estadEstudios/estadisticas/inforRecopilaciones/gastoSanitario2005/home.htm)** (satelite-kontuak, sailkapen ekonomikoa eta funtzionala erkidegoka).
- **[Osasun Ministerioa – Catálogo Nacional de Hospitales](https://www.sanidad.gob.es/estadEstudios/estadisticas/sisInfSanSNS/ofertaRecursos/hospitales/home.htm)**.
- **[Osasun Ministerioa – Evaluación de la sanidad privada en el sistema sanitario de España](https://vsf-iwsold-pro-portal.sanidad.gob.es/gabinetePrensa/notaPrensa/pdf/20251091225131137451.pdf)** (2025eko abendua), Osasun Barometroarekin.
- **Kudeaketa pribatuko ospitaleak**: SpainFactsentzat egindako taula, DOGVko itzulketa-dekretuekin, SERMASeko ospitaleen memoriekin eta, datu ofizialik ez dagoenean, aipua duen prentsarekin; errenkada bakoitzak bere iturria du taula deskargagarrian.
- **[Madrilgo Erkidegoa – Memorias del Servicio Madrileño de Salud](https://www.comunidad.madrid/salud/memorias-e-informes-servicio-madrileno-salud)** (itxaron-zerrenda abenduaren 31n eta askatasunez aukeratzea, ospitale bakoitzaren memorietan ere) eta **[itxaron-zerrenden hileko txostenak](https://www.comunidad.madrid/salud/lista-espera-consultas-externas)**; **SISLE-SNS** (Osasun Ministerioa) gainerako erkidegoekin alderatzeko.
- **[Madrilgo Erkidegoa – Cuenta General](https://www.comunidad.madrid/gobierno/hacienda/cuentas-generales)** (Intervención General: aurrekontuaren likidazioa eta kreditu-aldaketak erakundeka), **[Gobernu Kontseiluaren akordioen erreferentziak](https://www.comunidad.madrid/acuerdos-consejo-gobierno)** eta **[Generalitat de Catalunya – aurrekontuaren betearazpena](https://analisi.transparenciacatalunya.cat/d/ajns-4mi7)**.
- Kontratu txikiak: **[Andaluziako Junta – kontratazio txikia](https://www.juntadeandalucia.es/datosabiertos/portal/)** eta **[Generalitat de Catalunya – Plataforma de serveis de contractació pública](https://analisi.transparenciacatalunya.cat/d/ybgg-dgi6)**.
- **[INE – Familia Aurrekontuen Inkesta](https://www.ine.es/jaxiT3/Tabla.htm?t=73991)** (osasun-gastua pertsonako).
- **[Hezkuntza Ministerioa – EDUCAbase](https://estadisticas.educacion.gob.es/EducaDynPx/educabase/index.htm)**: Unibertsitatez kanpoko Irakaskuntzen Estatistika eta Hezkuntzako Gastu Publikoaren Estatistika.
- **[Zientzia, Berrikuntza eta Unibertsitate Ministerioa – Estadística de Estudiantes Universitarios](https://estadisticas.ciencia.gob.es/)** eta **[Registro de Universidades, Centros y Títulos](https://www.educacion.gob.es/ruct/listauniversidades?consulta=1)**.
- Testuingurua: elDiario.es-en «De pacientes a clientes» (2026-02-14) eta «El Gobierno trata de levantar un muro contra la privatización desaforada en sanidad y educación» (2026-02-13) erreportajeak; Freire, Bengoa eta Urbanosen adierazpenak lehenengotik datoz. Orriko zifra bat ere ez dator haietatik.
- Deflatzailea: INEren urteko batez besteko KPIa. Biztanleria: INE.

<LastRefreshed prefix="Datuak eguneratuta" />
