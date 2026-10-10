-- Libre elección de hospital en la Comunidad de Madrid (Decreto 51/2010): citas de primera
-- consulta que un hospital recibe de pacientes asignados a otro (entradas) y las de sus
-- pacientes que se van a otro (salidas). saldo = entradas - salidas.
-- Fuentes (Consejería de Sanidad, comunidad.madrid):
--   especialidad 'Total': Memoria anual del SERMAS, «Balance de Libre Elección en hospitales»
--     (2014-2023; para cada año la memoria de ese año, y para 2014 la de 2015); 2024: fila TOTAL
--     de la hoja «Consultas Libre Elección» de la memoria de cada hospital.
--   resto de especialidades: memoria de cada hospital, hoja «Consultas Libre Elección» (2021-2024).
-- primeras_consultas: primeras consultas del hospital en esa especialidad (hoja «Consultas
-- Externas» de la memoria del hospital, 2021-2024); entradas_pct_primeras = qué parte de sus
-- primeras consultas son pacientes llegados por libre elección.
-- gestion (seed sermas_hospitales): publica; concesion (Rey Juan Carlos, Infanta Elena,
-- Villalba, Torrejón); concierto_singular (Fundación Jiménez Díaz); convenio (Hospital Central
-- de la Defensa Gómez Ulla). Las especialidades se normalizan a un nombre común (la memoria de
-- cada hospital las escribe de forma distinta: «C. Maxilofacial», «Cirugía Máxilofacial»...).
with hosp as (
    select * from {{ ref('sermas_hospitales') }}
),

{% set norm %}
    case
        when n like 'total%' then 'Total'
        when n like 'alerg%' then 'Alergología'
        when n like 'angiolog%' or n like '%vascular%' then 'Angiología y Cirugía Vascular'
        when n like 'cirugia general%' or n like 'c. general%' then 'Cirugía General y Digestivo'
        when n like '%aparato digestivo%' or n = 'digestivo' then 'Aparato Digestivo'
        when n like 'cardiolog%' then 'Cardiología'
        when n like '%maxilofacial%' then 'Cirugía Maxilofacial'
        when n like 'cirugia pediatrica%' or n like 'c. infantil%' then 'Cirugía Pediátrica'
        when n like 'dermatolog%' then 'Dermatología'
        when n like 'endocrino%' then 'Endocrinología'
        when n like 'ginecolog%' then 'Ginecología'
        when n like 'hematolog%' then 'Hematología'
        when n like 'medicina interna%' or n like 'm. interna%' then 'Medicina Interna'
        when n like 'nefrolog%' then 'Nefrología'
        when n like 'neumolog%' then 'Neumología'
        when n like 'neurocirug%' then 'Neurocirugía'
        when n like 'neurolog%' then 'Neurología'
        when n like 'obstetric%' then 'Obstetricia'
        when n like 'oftalmolog%' then 'Oftalmología'
        when n like 'otorrino%' or n = 'orl' then 'Otorrinolaringología'
        when n like 'pediatria%' then 'Pediatría'
        when n like 'rehabilitac%' then 'Rehabilitación'
        when n like 'reumatolog%' then 'Reumatología'
        when n like 'traumatolog%' then 'Traumatología'
        when n like 'urolog%' then 'Urología'
        when n like 'psiquiatr%' then 'Psiquiatría'
        else null
    end
{% endset %}

le_esp_raw as (
    select cast(anio as integer) as anio, hospital_informe, entrantes, salientes, fuente_url,
           lower(strip_accents(trim(especialidad))) as n
    from {{ source('raw_sermas', 'sermas_le_hospital') }}
),

le_esp as (
    select anio, hospital_informe, {{ norm }} as especialidad,
           sum(entrantes) as entradas, sum(salientes) as salidas, max(fuente_url) as fuente_url
    from le_esp_raw
    group by all
),

consultas_raw as (
    select cast(anio as integer) as anio, hospital_informe, primeras, fuente_url,
           lower(strip_accents(trim(especialidad))) as n,
           lower(strip_accents(hospital_informe)) as n_hosp
    from {{ source('raw_sermas', 'sermas_consultas_hospital') }}
),

consultas as (
    -- primeras consultas por hospital_id (un hospital puede venir con dos nombres: se toma el mayor;
    -- la fila total puede venir dos veces, tabla y cuadro resumen: max, no suma)
    select anio, hospital_id, especialidad, max(primeras_consultas) as primeras_consultas
    from (
        select anio, hospital_id, hospital_informe, especialidad,
               case when especialidad = 'Total' then max(primeras) else sum(primeras) end as primeras_consultas
        from (
            select c.anio, h.hospital_id, c.hospital_informe, c.primeras, {{ norm }} as especialidad
            from consultas_raw c
            join hosp h on regexp_matches(c.n_hosp, h.patron)
        )
        group by anio, hospital_id, hospital_informe, especialidad
    )
    group by all
),

-- Total de cada hospital: memoria del SERMAS (el año de la propia memoria; 2014 de la de 2015)
balance as (
    select cast(anio as integer) as anio, hospital_informe, entrantes as entradas, salientes as salidas,
           fuente_url,
           row_number() over (partition by anio, hospital_informe
                              order by case when memoria_anio = anio then 0 else 1 end, memoria_anio desc) as rn
    from {{ source('raw_sermas', 'sermas_le_balance') }}
),

totales as (
    select anio, hospital_informe, 'Total' as especialidad, entradas, salidas,
           'memoria_sermas' as fuente, fuente_url
    from balance where rn = 1
    union all
    select e.anio, e.hospital_informe, 'Total', e.entradas, e.salidas, 'memoria_hospital', e.fuente_url
    from le_esp e
    where e.especialidad = 'Total'
      and e.anio not in (select distinct anio from balance)
    union all
    -- memoria de hospital sin fila TOTAL (El Escorial 2024): suma de sus especialidades
    select e.anio, e.hospital_informe, 'Total', sum(e.entradas), sum(e.salidas), 'memoria_hospital', max(e.fuente_url)
    from le_esp e
    where e.especialidad is not null and e.especialidad <> 'Total'
      and e.anio not in (select distinct anio from balance)
      and not exists (select 1 from le_esp t where t.anio = e.anio and t.hospital_informe = e.hospital_informe
                      and t.especialidad = 'Total')
    group by e.anio, e.hospital_informe
),

especialidades as (
    select anio, hospital_informe, especialidad, entradas, salidas, 'memoria_hospital' as fuente, fuente_url
    from le_esp
    where especialidad is not null and especialidad <> 'Total'
),

unido as (
    select * from totales
    union all
    select * from especialidades
),

con_hospital as (
    select
        u.*,
        h.hospital_id, h.hospital, h.gestion, h.grupo_empresarial
    from unido u
    join hosp h on regexp_matches(lower(strip_accents(u.hospital_informe)), h.patron)
),

pob as (
    select cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and cod = '13' and sexo = 'Total'
),

agregado as (
    -- un hospital puede salir con dos nombres el mismo año (p. ej. dos ZIP): se suma una vez
    select anio, hospital_id, hospital, gestion, grupo_empresarial, especialidad,
           max(entradas) as entradas, max(salidas) as salidas, min(fuente) as fuente, max(fuente_url) as fuente_url,
           max(hospital_informe) as hospital_informe
    from con_hospital
    group by all
)

select
    '13' as cod_ccaa,
    'Comunidad de Madrid' as ccaa,
    a.anio,
    a.hospital_id,
    a.hospital,
    a.gestion,
    a.gestion in ('concesion', 'concierto_singular') as gestion_privada,
    a.grupo_empresarial,
    a.especialidad,
    cast(a.entradas as integer) as entradas,
    cast(a.salidas as integer) as salidas,
    cast(a.entradas - a.salidas as integer) as saldo,
    cast(c.primeras_consultas as integer) as primeras_consultas,
    round(100.0 * a.entradas / nullif(c.primeras_consultas, 0), 2) as entradas_pct_primeras,
    round(1000.0 * (a.entradas - a.salidas) / p.poblacion, 3) as saldo_por_1000_hab_madrid,
    a.fuente,
    a.hospital_informe,
    a.fuente_url
from agregado a
left join consultas c
    on c.anio = a.anio and c.hospital_id = a.hospital_id and c.especialidad = a.especialidad
left join pob p on p.anio = a.anio
order by a.anio, a.especialidad, (a.entradas - a.salidas) desc
