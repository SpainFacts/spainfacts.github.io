{{ config(materialized='ephemeral') }}
-- Equivalencia NUTS 2 (Eurostat, ISTAC) -> código INE de comunidad y nombre (territorios_ccaa).
-- 'ES' es España ('00'). Auxiliar de los marts construccion_*.
select m.nuts, m.cod_ccaa, coalesce(t.nombre, 'España') as nombre
from (values
    ('ES', '00'), ('ES11', '12'), ('ES12', '03'), ('ES13', '06'), ('ES21', '16'), ('ES22', '15'),
    ('ES23', '17'), ('ES24', '02'), ('ES30', '13'), ('ES41', '07'), ('ES42', '08'), ('ES43', '11'),
    ('ES51', '09'), ('ES52', '10'), ('ES53', '04'), ('ES61', '01'), ('ES62', '14'), ('ES63', '18'),
    ('ES64', '19'), ('ES70', '05')
) as m(nuts, cod_ccaa)
left join {{ ref('territorios_ccaa') }} t on t.cod_ccaa = m.cod_ccaa
