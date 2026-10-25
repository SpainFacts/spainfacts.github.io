-- Visitantes no residentes adultos presentes en España en un día medio de cada año
-- (personas-año), estimados con Frontur (INE 23987): suma de las noches de todos los
-- visitantes no residentes / 365, con la noche media de cada tramo de estancia (1; 2,5;
-- 5,5; 11,5 y 25 para «más de 15») y media jornada para los excursionistas, por el 85 %
-- que se supone adulto (Frontur no publica la edad). Desde 2016.
-- `turistas` y `turistas_pais` (23984, por país de residencia) sirven para repartirlos
-- por procedencia suponiendo la misma estancia media para todas.
{% set noches_por_tramo = {
    'Ninguna noche': 0.5,
    '1 noche': 1,
    'De 2 a 3 noches': 2.5,
    'De 4 a 7 noches': 5.5,
    'De 8 a 15 noches': 11.5,
    'Más de 15 noches': 25,
} %}
{% set cuota_adultos_visitantes = 0.85 %}
select
    anyo as anio,
    {{ cuota_adultos_visitantes }} * sum(valor * case trim(split_part(serie, '. ', 3))
        {% for tramo, noches in noches_por_tramo.items() %}when '{{ tramo }}' then {{ noches }} {% endfor %}
    end) / 365 as presentes
from {{ source('raw_criminalidad', 'ine_frontur_duracion') }}
where serie like '%. Dato base.%' and split_part(serie, '. ', 2) = 'Total Nacional'
group by anyo
