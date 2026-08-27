-- Modelo de trazabilidad y auditoría de fuentes oficiales almacenado en MotherDuck
with fuentes as (
    select * from {{ ref('fuentes_catalogo') }}
)

select
    fuente_id,
    organismo,
    nombre_dataset,
    cod_oficial,
    frecuencia,
    formato_ingesta,
    tipo_licencia,
    url_oficial,
    metodologia,
    'Sincronizado / Activo' as estado_pipeline
from fuentes
order by organismo, nombre_dataset
