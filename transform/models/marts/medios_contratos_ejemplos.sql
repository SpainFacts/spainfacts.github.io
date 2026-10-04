-- Los 50 mayores contratos de patrocinio y eventos (patrocinios, foros, jornadas,
-- congresos, premios, galas, desayunos, encuentros, aniversarios, giras...) adjudicados
-- cada año a empresas de medios. Fuente: PLACSP (Ministerio de Hacienda) y plataformas
-- autonómicas y municipales de contratos menores (fuente_plataforma), ver medios_contratos_base. Solo es_medio = 'si' (el padrón solo tiene personas
-- jurídicas) y sin importes sospechosos. Importe adjudicado sin IVA, en euros
-- corrientes y de 2025. url = enlace al expediente en la plataforma.
with muni as (
    select cod_mun, any_value(municipio) as municipio
    from {{ ref('poblacion_municipios') }}
    group by cod_mun
),

top as (
    select
        anio,
        row_number() over (partition by anio order by importe_adjudicado_sin_iva desc, expediente) as rango,
        objeto,
        organo,
        nivel,
        cod_ccaa,
        cod_municipio,
        adjudicatario,
        nif_adjudicatario,
        grupo,
        titularidad,
        importe_adjudicado_sin_iva as importe_eur_nominal,
        importe_eur_real,
        es_menor,
        fecha_adjudicacion,
        expediente,
        url,
        fuente_plataforma,
        metodo_casado
    from {{ ref('medios_contratos_base') }}
    where categoria = 'patrocinio_eventos' and es_medio = 'si' and not sospechoso
        and importe_adjudicado_sin_iva > 0 and anio >= 2018
    qualify rango <= 50
)

select
    top.anio,
    top.rango,
    top.objeto,
    top.organo,
    top.nivel,
    top.cod_ccaa,
    c.nombre as ccaa,
    top.cod_municipio,
    m.municipio,
    top.adjudicatario,
    top.nif_adjudicatario,
    top.grupo,
    top.titularidad,
    top.importe_eur_nominal,
    top.importe_eur_real,
    top.es_menor,
    top.fecha_adjudicacion,
    top.expediente,
    top.url,
    top.fuente_plataforma,
    top.metodo_casado
from top
left join {{ ref('territorios') }} c on c.nivel = 'ccaa' and c.cod = top.cod_ccaa
left join muni m on m.cod_mun = top.cod_municipio
order by top.anio, top.rango
