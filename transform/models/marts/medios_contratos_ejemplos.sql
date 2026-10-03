-- Los 50 mayores contratos de patrocinio y eventos (patrocinios, foros, jornadas,
-- congresos, premios, galas, desayunos, encuentros, aniversarios, giras...) adjudicados
-- cada año a empresas de medios. Fuente: PLACSP (Ministerio de Hacienda) y plataformas
-- autonómicas y municipales de contratos menores (fuente_plataforma), ver medios_contratos_base. Solo es_medio = 'si' (el padrón solo tiene personas
-- jurídicas) y sin importes sospechosos. Importe adjudicado sin IVA, en euros
-- corrientes y de 2025. url = enlace al expediente en la plataforma.
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
order by anio, rango
