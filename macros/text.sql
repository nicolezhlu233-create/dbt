{# Cast ANY column type to text, then trim spaces, tabs, line breaks AND non-breaking spaces (U+00A0).
   to_varchar() makes the models work whether the upload created VARCHAR, NUMBER, TIMESTAMP or BOOLEAN columns. #}
{% macro trim_ws(col) -%}
    trim(to_varchar({{ col }}), ' ' || chr(9) || chr(10) || chr(13) || chr(160))
{%- endmacro %}

{# Trimmed text, with empty string turned into NULL. #}
{% macro clean_text(col) -%}
    nullif({{ trim_ws(col) }}, '')
{%- endmacro %}
