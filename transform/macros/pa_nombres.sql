{#
  Claves para casar nombres de municipios y provincias escritos de formas
  distintas (ISPA, INE): «Coruña, A» = «A Coruña», «Ejido (El)» = «El Ejido»,
  «Alacant/Alicante» = «Alicante», «GETAFE» = «Getafe»...

  pa_clave(expr): minúsculas, sin tildes y sin nada que no sea letra o cifra.
  pa_claves_fuertes(col): lista de claves equivalentes sin perder información
    (nombre completo y artículo pospuesto movido delante).
  pa_claves_debiles(col): además, cada parte de un nombre bilingüe «A/B» y el
    nombre sin artículo. Solo se usan si la clave fuerte no casa, y desempatando
    por población.
#}

{% macro pa_clave(expr) -%}
regexp_replace(strip_accents(lower({{ expr }})), '[^a-z0-9]', '', 'g')
{%- endmacro %}

{% macro _pa_articulo() -%}
(el|la|los|las|lo|l''|els|les|o|a|os|as|es|sa|ses|s''|en|na)
{%- endmacro %}

{% macro _pa_formas_fuertes(p) -%}
[
    {{ pa_clave(p) }},
    {{ pa_clave("regexp_replace(lower(trim(" ~ p ~ ")), '^(.*?),\\s*" ~ _pa_articulo() ~ "$', '\\2 \\1')") }},
    {{ pa_clave("regexp_replace(lower(trim(" ~ p ~ ")), '^(.*?)\\s*\\(" ~ _pa_articulo() ~ "\\)$', '\\2 \\1')") }}
]
{%- endmacro %}

{% macro pa_claves_fuertes(col) -%}
list_distinct({{ _pa_formas_fuertes(col) }})
{%- endmacro %}

{% macro pa_claves_debiles(col) -%}
list_distinct(flatten(list_transform(list_append(string_split({{ col }}, '/'), {{ col }}), p -> list_concat(
    {{ _pa_formas_fuertes("p") }},
    [
        {{ pa_clave("regexp_replace(lower(trim(p)), '^(.*?),\\s*" ~ _pa_articulo() ~ "$', '\\1')") }},
        {{ pa_clave("regexp_replace(lower(trim(p)), '^(.*?)\\s*\\(" ~ _pa_articulo() ~ "\\)$', '\\1')") }},
        {{ pa_clave("regexp_replace(lower(trim(p)), '^(?:(el|la|los|las|lo|els|les|o|a|os|as|es|sa|ses|en|na)\\s+|l''|s'')', '')") }}
    ]
))))
{%- endmacro %}
