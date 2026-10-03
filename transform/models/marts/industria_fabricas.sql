-- Fábricas de vehículos en España (seed industria_fabricas_coches, ANFAC «Mapa de fábricas con
-- modelos en producción y adjudicados», mayo 2025; coordenadas del municipio de Wikidata).
-- Añade n_modelos (modelos en producción, separados por «; » en el seed) y n_adjudicados.
-- El empleo va vacío: no hay fuente homogénea y abierta por planta.
select
    f.*,
    case when f.modelos is null or f.modelos = '' then 0 else len(string_split(f.modelos, '; ')) end as n_modelos,
    case when f.modelos_adjudicados is null or f.modelos_adjudicados = '' then 0
         else len(string_split(f.modelos_adjudicados, '; ')) end as n_adjudicados
from {{ ref('industria_fabricas_coches') }} f
