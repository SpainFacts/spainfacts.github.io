-- Traduce las etiquetas de nacionalidad del INE (condenados 25645 y población 56942)
-- a las procedencias de crimen_condenados_edad: España, Total, Unión Europea,
-- Resto de Europa, África, América, Asia y Oceanía (NULL para lo demás).
{% macro procedencia_ine(columna) %}
    case
        when {{ columna }} = 'Española' then 'España'
        when {{ columna }} in ('Total', 'Extranjera') then 'Total'
        when {{ columna }} = 'País de la UE27_2020 sin España' then 'Unión Europea'
        when {{ columna }} = 'País de Europa menos UE27_2020' then 'Resto de Europa'
        when {{ columna }} = 'De Africa' then 'África'
        when {{ columna }} like 'De Am_rica%' or {{ columna }} in ('De Centro América y Caribe', 'De Sudamérica') then 'América'
        when {{ columna }} in ('De Asia', 'De Oceanía') then 'Asia y Oceanía'
    end
{% endmacro %}
