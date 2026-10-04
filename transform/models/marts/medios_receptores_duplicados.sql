-- Pagos de medios_receptores que se excluyen de los totales por ser duplicado probable:
-- contratos de publicidad o inserciones de una comunidad o ayuntamiento cuya publicidad por
-- medio ya está en la fuente territorial ese año (Castilla y León, Aragón, Cataluña,
-- C. Valenciana, Murcia, Navarra, País Vasco, Ayto. de Madrid). Mismas columnas que
-- medios_receptores. No se suman a medios_receptores: se publican para consulta y para
-- que la página diga cuánto se ha dejado fuera.
select * exclude (duplicado_probable)
from {{ ref('medios_receptores_base') }}
where duplicado_probable
