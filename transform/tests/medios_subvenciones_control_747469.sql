-- Prueba de control de la ingesta de subvenciones a medios (BDNS): la convocatoria
-- 747469 (Generalitat de Catalunya, estructurales a publicaciones periódicas en
-- papel en catalán o aranés, 2024) debe sumar 4.093.195,73 €, la cifra de la
-- resolución publicada. Devuelve una fila (falla) si no cuadra.
select cod_bdns, round(sum(importe_concedido_eur), 2) as suma
from {{ ref('medios_subvenciones_concesiones') }}
where cod_bdns = '747469'
group by cod_bdns
having round(sum(importe_concedido_eur), 2) <> 4093195.73
union all
select '747469', null
where not exists (
    select 1 from {{ ref('medios_subvenciones_concesiones') }} where cod_bdns = '747469'
)
