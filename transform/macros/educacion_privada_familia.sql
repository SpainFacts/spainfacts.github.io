{#
  Familia profesional de FP unificada entre cursos (tablas de EDUCAbase gen-ciclos-fp):
  quita el código numérico delante ('16 INFORMÁTICA...'), corrige erratas de la fuente
  (MANTEMIENTO, MÁRKETING, TURÍSMO...) y lleva las familias LOGSE de 2016-17 y 2017-18 a su
  equivalente LOE. Devuelve la familia en minúsculas con mayúscula inicial ('Sanidad').
#}
{% macro educacion_privada_familia_expr(columna) %}
    (case upper(trim(regexp_replace({{ columna }}, '^\d+\s*', '')))
        when 'MARITIMO PESQUERA' then 'Marítimo-pesquera'
        when 'MARITIMO-PESQUERA' then 'Marítimo-pesquera'
        when 'ACTIVIDADES MARÍTIMO PESQUERAS' then 'Marítimo-pesquera'
        when 'ACTIVIDADES MARÍTIMO-PESQUERAS' then 'Marítimo-pesquera'
        when 'ACTIVIDADES AGRARIAS' then 'Agraria'
        when 'ADMINISTRACIÓN' then 'Administración y gestión'
        when 'ARTESANÍAS' then 'Artes y artesanías'
        when 'COMERCIO Y MÁRKETING' then 'Comercio y marketing'
        when 'COMUNICACIÓN, IMAGEN Y SONIDO' then 'Imagen y sonido'
        when 'HOSTELERÍA Y TURÍSMO' then 'Hostelería y turismo'
        when 'MADERA Y MUEBLE' then 'Madera, mueble y corcho'
        when 'MANTENIMIENTO DE VEHÍCULOS AUTOPROPULSADOS' then 'Transporte y mantenimiento de vehículos'
        when 'TRANSPORTE Y MANTEMIENTO DE VEHÍCULOS' then 'Transporte y mantenimiento de vehículos'
        when 'MANTENIMIENTO Y SERVICIOS A LA PRODUCCIÓN' then 'Instalación y mantenimiento'
        when 'SERVICIOS SOCIOCULTURALES A LA COMUNIDAD' then 'Servicios socioculturales y a la comunidad'
        when 'TOTAL' then 'Total'
        else upper(left(trim(regexp_replace({{ columna }}, '^\d+\s*', '')), 1))
             || lower(substr(trim(regexp_replace({{ columna }}, '^\d+\s*', '')), 2))
    end)
{% endmacro %}
