-- Energía de los hogares por uso final (calefacción, agua caliente, cocina,
-- refrigeración, iluminación y electrodomésticos) y combustible, anual desde
-- 2010 (Eurostat nrg_d_hhq, TJ). Los combustibles se desglosan sin solaparse:
-- "otros" = total - suma de los listados.
with base as (
    select cast(anio as integer) as anio, uso, combustible, tj
    from {{ source('raw_eurostat_extra', 'eurostat_hogares_usos') }}
    where tj is not null
),

total as (
    select anio, uso, tj as total from base where combustible = 'TOTAL'
),

partes as (
    select
        b.anio, b.uso,
        case b.combustible
            when 'E7000' then 'Electricidad'
            when 'G3000' then 'Gas natural'
            when 'O4000' then 'Gasóleo, butano y otros derivados del petróleo'
            when 'R5110-5150_W6000RI' then 'Biomasa (leña, pellets)'
            when 'RA410' then 'Solar térmica'
            when 'RA600' then 'Calor ambiente (bombas de calor)'
            when 'H8000' then 'Calor de redes'
        end as combustible,
        b.tj
    from base b
    where b.combustible <> 'TOTAL'
),

todas as (
    select p.anio, p.uso, p.combustible, p.tj, 100.0 * p.tj / nullif(t.total, 0) as cuota_pct
    from partes p
    join total t using (anio, uso)
    union all
    select t.anio, t.uso, 'Otros', t.total - sum(p.tj), 100.0 * (t.total - sum(p.tj)) / nullif(t.total, 0)
    from total t
    join partes p using (anio, uso)
    group by t.anio, t.uso, t.total
    having t.total - sum(p.tj) > 0.5
)

select
    anio,
    uso as cod_uso,
    case uso
        when 'FC_OTH_HH_E' then 'Todos los usos'
        when 'FC_OTH_HH_E_SH' then 'Calefacción'
        when 'FC_OTH_HH_E_SC' then 'Refrigeración'
        when 'FC_OTH_HH_E_WH' then 'Agua caliente'
        when 'FC_OTH_HH_E_CK' then 'Cocina'
        when 'FC_OTH_HH_E_LE' then 'Iluminación y electrodomésticos'
        when 'FC_OTH_HH_E_OE' then 'Otros usos'
    end as uso,
    todas.uso = 'FC_OTH_HH_E' as es_total_uso,
    combustible,
    tj,
    cuota_pct
from todas
