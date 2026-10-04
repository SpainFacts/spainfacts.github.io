-- Quién recibe qué: todo lo que cada medio de comunicación ha recibido de las
-- administraciones públicas, en formato largo (una fila por pago o concesión).
-- Une publicidad del Estado por grupo (2025), publicidad institucional de comunidades y
-- ayuntamientos por medio, contratos a empresas de medios (desde 2018) y subvenciones a
-- medios privados (desde 2022); ver medios_receptores_base para las fuentes y la
-- asignación a cada medio.
-- Sin los pagos duplicado_probable: contratos de publicidad de comunidades y ayuntamientos
-- cuya publicidad por medio ya está en la fuente territorial ese año. Esas filas están en
-- medios_receptores_duplicados, así que sum(importe_eur_real) de esta tabla es siempre
-- correcto sin filtrar nada.
select * exclude (duplicado_probable)
from {{ ref('medios_receptores_base') }}
where not duplicado_probable
