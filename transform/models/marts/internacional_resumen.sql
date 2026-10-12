-- Cómo queda España en cada indicador internacional: una fila por ámbito ('mundo' =
-- internacional_mundo, 'europa' = internacional_europa) e indicador, con el catálogo
-- (nombre, unidad, apartado, sentido, decimales, fuente) y, en el último año con dato de
-- España con datos de la mayoría de los países (anio_ref): su valor, el de la UE-27 y el del mundo, su puesto entre los países con
-- dato ese año (en Europa, entre los europeos; además, entre los de la UE-27), el mejor
-- país y cómo estaban España y la UE diez años antes.
-- puesto: 1 = el mejor (el más alto si sentido = 'positivo', el más bajo si 'negativo');
-- en los indicadores 'neutro', 1 = el valor más alto. Los agregados no cuentan.
with series as (
    select 'mundo' as ambito, indicador_id, cod_pais, pais, es_europa, es_ue, es_agregado, anio, valor
    from {{ ref('internacional_mundo') }}
    union all
    select 'europa', indicador_id, cod_pais, pais, true, es_ue, es_agregado, anio, valor
    from {{ ref('internacional_europa') }}
),

catalogo as (
    select * from {{ ref('internacional_indicadores') }}
),

-- países con dato cada año (las fuentes publican con distinto retraso: el último año de
-- España puede tener todavía muy pocos países)
cobertura as (
    select *, max(n) over (partition by ambito, indicador_id) as n_max
    from (
        select ambito, indicador_id, anio, count(*) as n
        from series
        where not es_agregado
        group by ambito, indicador_id, anio
    )
),

-- año de referencia: el último con dato de España y al menos el 70 % de los países del
-- año con más cobertura
referencia as (
    select s.ambito, s.indicador_id,
           max(s.anio) filter (where c.n >= 0.7 * c.n_max) as anio_ref,
           min(s.anio) as anio_inicio,
           max(s.anio) as anio_ultimo_espana
    from series s
    join cobertura c using (ambito, indicador_id, anio)
    where s.cod_pais = 'ES'
    group by all
),

-- países con dato en el año de referencia, ordenados según el sentido del indicador
ranking as (
    select
        s.ambito, s.indicador_id, s.cod_pais, s.pais, s.es_ue, s.valor,
        rank() over (partition by s.ambito, s.indicador_id
                     order by case when c.sentido = 'negativo' then s.valor else -s.valor end) as puesto,
        count(*) over (partition by s.ambito, s.indicador_id) as n_paises
    from series s
    join referencia r on r.ambito = s.ambito and r.indicador_id = s.indicador_id and r.anio_ref = s.anio
    join catalogo c on c.ambito = s.ambito and c.indicador_id = s.indicador_id
    where not s.es_agregado
),

ranking_ue as (
    select
        ambito, indicador_id, cod_pais,
        rank() over (partition by ambito, indicador_id
                     order by case when sentido = 'negativo' then valor else -valor end) as puesto_ue,
        count(*) over (partition by ambito, indicador_id) as n_ue
    from ranking
    join catalogo using (ambito, indicador_id)
    where es_ue
),

mejor as (
    select ambito, indicador_id, cod_pais as mejor_cod_pais, pais as mejor_pais, valor as mejor_valor
    from ranking
    qualify row_number() over (partition by ambito, indicador_id order by puesto, pais) = 1
),

valor_en as (
    -- valor de un país en un año (para la UE y el mundo en anio_ref y diez años antes)
    select s.ambito, s.indicador_id, s.cod_pais, s.anio, s.valor
    from series s
    where s.cod_pais in ('ES', 'EU27_2020', 'WLD')
)

select
    c.ambito,
    c.indicador_id,
    c.nombre,
    c.unidad,
    c.apartado,
    c.sentido,
    c.decimales,
    c.fuente,
    c.url_fuente,
    c.orden,
    r.anio_inicio,
    r.anio_ref,
    r.anio_ultimo_espana,
    es.valor as valor_espana,
    ue.valor as valor_ue,
    wld.valor as valor_mundo,
    k.puesto,
    k.n_paises,
    ku.puesto_ue,
    ku.n_ue,
    m.mejor_cod_pais,
    m.mejor_pais,
    m.mejor_valor,
    es10.valor as valor_espana_hace_10,
    ue10.valor as valor_ue_hace_10
from catalogo c
join referencia r using (ambito, indicador_id)
left join valor_en es on es.ambito = c.ambito and es.indicador_id = c.indicador_id and es.cod_pais = 'ES' and es.anio = r.anio_ref
left join valor_en ue on ue.ambito = c.ambito and ue.indicador_id = c.indicador_id and ue.cod_pais = 'EU27_2020' and ue.anio = r.anio_ref
left join valor_en wld on wld.ambito = c.ambito and wld.indicador_id = c.indicador_id and wld.cod_pais = 'WLD' and wld.anio = r.anio_ref
left join valor_en es10 on es10.ambito = c.ambito and es10.indicador_id = c.indicador_id and es10.cod_pais = 'ES' and es10.anio = r.anio_ref - 10
left join valor_en ue10 on ue10.ambito = c.ambito and ue10.indicador_id = c.indicador_id and ue10.cod_pais = 'EU27_2020' and ue10.anio = r.anio_ref - 10
left join ranking k on k.ambito = c.ambito and k.indicador_id = c.indicador_id and k.cod_pais = 'ES'
left join ranking_ue ku on ku.ambito = c.ambito and ku.indicador_id = c.indicador_id and ku.cod_pais = 'ES'
left join mejor m on m.ambito = c.ambito and m.indicador_id = c.indicador_id
-- fuera los que no tienen ningún año con la mayoría de los países (vivienda social de la OCDE)
where r.anio_ref is not null
