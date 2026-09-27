select
    cod_mun,
    cod_prov,
    cod_ccaa,
    dc,
    nombre
from {{ source('raw_territorios', 'ine_municipios') }}
