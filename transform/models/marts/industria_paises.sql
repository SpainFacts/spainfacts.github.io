{{ config(materialized='ephemeral') }}
-- Nombres en español de los 27 países de la UE y del agregado (códigos Eurostat; Grecia = EL,
-- que ingestion/industria.py ya normaliza desde el GR de Comext). Auxiliar de los marts industria_*.
select * from (values
    ('AT', 'Austria'), ('BE', 'Bélgica'), ('BG', 'Bulgaria'), ('CY', 'Chipre'), ('CZ', 'Chequia'),
    ('DE', 'Alemania'), ('DK', 'Dinamarca'), ('EE', 'Estonia'), ('EL', 'Grecia'), ('ES', 'España'),
    ('FI', 'Finlandia'), ('FR', 'Francia'), ('HR', 'Croacia'), ('HU', 'Hungría'), ('IE', 'Irlanda'),
    ('IT', 'Italia'), ('LT', 'Lituania'), ('LU', 'Luxemburgo'), ('LV', 'Letonia'), ('MT', 'Malta'),
    ('NL', 'Países Bajos'), ('PL', 'Polonia'), ('PT', 'Portugal'), ('RO', 'Rumanía'), ('SE', 'Suecia'),
    ('SI', 'Eslovenia'), ('SK', 'Eslovaquia'), ('EU27_2020', 'Unión Europea (27)')
) as t(pais, pais_nombre)
