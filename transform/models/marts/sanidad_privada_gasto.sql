-- Gasto sanitario público de cada comunidad autónoma por partidas: cuánto se va en personal
-- propio, en compras y servicios, en conciertos con centros ajenos, en farmacia de receta y en
-- inversión (Ministerio de Sanidad, Estadística de Gasto Sanitario Público, cuentas satélite,
-- XLS egspGastoReal, tablas 3.4.01-3.4.17 por comunidad y 2.4 para el sector Comunidades
-- Autónomas, cod_ccaa '00'). 2002-último año; los dos últimos, provisionales.
--
-- Tres clasificaciones (columna clasificacion), cada una con su fila partida_id = 'total':
--   economica  Clasificación económico-presupuestaria. Total = gasto consolidado del subsector.
--              'conciertos' = compras de asistencia a centros ajenos (servicios hospitalarios,
--              especializados y primarios concertados, traslado de enfermos) más las transferencias
--              a otras administraciones por servicios concertados: cuadra al euro con la suma de
--              esas rúbricas de la cuenta satélite. 'transferencias_corrientes' es sobre todo la
--              farmacia de receta.
--   funcional  Clasificación funcional. Total = aportación al gasto total consolidado (descontadas
--              las transferencias a otros sectores).
--   mercado    Compras a productores de mercado de la cuenta satélite («producción de mercado»):
--              hospitalarios, especializados, primaria y traslado concertados, prótesis, farmacia;
--              'conciertos_sin_aapp' = las cuatro primeras (conciertos sin los pagos a otras
--              administraciones) y 'total' = toda la producción de mercado (incluye farmacia).
--              peso_pct sobre el gasto consolidado del subsector (el total de 'economica').
--
-- OJO, qué cuenta como concierto (ver schema_sanidad_privada.yml): el EGSP mide el gasto de las
-- administraciones públicas (SEC). Lo que producen entes del sector público (consorcios y empresas
-- públicas catalanes, fundaciones públicas) es producción propia aunque su personal no sea
-- funcionario; lo que se compra a centros ajenos, con o sin ánimo de lucro, es concierto. En
-- Cataluña el peso alto de conciertos refleja la red histórica XHUP/SISCAT de hospitales de
-- fundaciones, órdenes religiosas y mutuas sin ánimo de lucro, no concesiones con ánimo de lucro.
-- En Madrid las concesiones capitativas y la Fundación Jiménez Díaz entran en conciertos (la serie
-- sube al abrir Torrejón 2011, Rey Juan Carlos 2012 y Villalba 2014). En la Comunitat Valenciana
-- los conciertos no recogen las cápitas del modelo Alzira: los hospitalarios concertados no pasan
-- de 130 M€ y no bajan con las reversiones; su consumo intermedio pesa 10 puntos más que en el
-- resto, señal de que la cápita se anota como compra de servicios dentro de la producción propia.
--
-- Euros: gasto_meur (millones corrientes); _real con el deflactor (IPC medio anual, euros de
-- anio_base); por habitante con la población a 1 de julio (media de la de 1 de enero del año y
-- del siguiente, poblacion_territorios; para '00' la suma de las 17 comunidades).
with raw as (
    select
        cast(cod_ccaa as varchar) as cod_ccaa,
        cast(anio as integer) as anio,
        clasificacion,
        trim(concepto) as concepto,
        padre,
        provisional,
        miles_eur / 1000.0 as meur
    from {{ source('raw_sanidad_privada', 'sanidad_privada_egsp') }}
    where clasificacion in ('economica', 'funcional', 'cuenta_satelite')
),

mapa as (
    select * from (values
        ('economica', 'Remuneración del personal', 'remuneracion_personal', 'Remuneración del personal', 1),
        ('economica', 'Consumo intermedio', 'consumo_intermedio', 'Consumo intermedio', 2),
        ('economica', 'Consumo de capital fijo', 'consumo_capital_fijo', 'Consumo de capital fijo', 3),
        ('economica', 'Conciertos', 'conciertos', 'Conciertos', 4),
        ('economica', 'Transferencias corrientes', 'transferencias_corrientes', 'Transferencias corrientes (sobre todo farmacia de receta)', 5),
        ('economica', 'Gasto de capital', 'gasto_capital', 'Gasto de capital', 6),
        ('economica', 'GASTO PÚBLICO EN SANIDAD GASTO CONSOLIDADO DEL SUBSECTOR', 'total', 'Total (gasto consolidado)', 9),
        ('economica', 'GASTO PÚBLICO EN SANIDAD GASTO CONSOLIDADO DEL SECTOR', 'total', 'Total (gasto consolidado)', 9),
        ('funcional', 'Servicios hospitalarios y especializados', 'hospitalarios_especializados', 'Servicios hospitalarios y especializados', 1),
        ('funcional', 'Servicios primarios de salud', 'primaria', 'Servicios primarios de salud', 2),
        ('funcional', 'Servicios de salud pública', 'salud_publica', 'Servicios de salud pública', 3),
        ('funcional', 'Servicios colectivos de salud', 'servicios_colectivos', 'Servicios colectivos de salud', 4),
        ('funcional', 'Farmacia', 'farmacia', 'Farmacia', 5),
        ('funcional', 'Traslado, protesis y aparatos terapéuticos', 'traslado_protesis', 'Traslado, prótesis y aparatos terapéuticos', 6),
        ('funcional', 'Gasto de capital', 'gasto_capital', 'Gasto de capital', 7),
        ('funcional', 'APORTACION AL GASTO PÚBLICO EN SANIDAD TOTAL CONSOLIDADO', 'total', 'Total (aportación al gasto consolidado)', 9),
        ('mercado', '2.2.1.1 - Servicios hospitalarios', 'hospitalarios', 'Servicios hospitalarios concertados', 1),
        ('mercado', '2.2.1.2 - Servicios especializados', 'especializados', 'Servicios especializados concertados', 2),
        ('mercado', '2.2.2 - Servicios primarios de salud', 'primaria', 'Servicios primarios concertados', 3),
        ('mercado', '2.2.4 - Traslado de enfermos', 'traslado', 'Traslado de enfermos', 4),
        ('mercado', '2.2.5 - Protesis y aparatos terapéuticos', 'protesis', 'Prótesis y aparatos terapéuticos', 5),
        ('mercado', '2.2.3 - Farmacia', 'farmacia', 'Farmacia de receta', 6),
        ('mercado', '2.2 PRODUCCIÓN DE MERCADO', 'total', 'Total compras a productores de mercado', 9)
    ) as m (clasificacion, concepto, partida_id, partida, orden)
),

partidas as (
    select r.cod_ccaa, r.anio, m.clasificacion, m.partida_id, m.partida, m.orden, r.provisional, r.meur
    from raw r
    join mapa m
        on m.concepto = r.concepto
       and m.clasificacion = case when r.clasificacion = 'cuenta_satelite' then 'mercado' else r.clasificacion end
    where r.padre is null
),

-- Conciertos con centros ajenos sin los pagos a otras administraciones públicas
sin_aapp as (
    select cod_ccaa, anio, 'mercado' as clasificacion, 'conciertos_sin_aapp' as partida_id,
        'Conciertos sin pagos a otras administraciones (hospitalarios + especializados + primaria + traslado)' as partida,
        8 as orden, bool_or(provisional) as provisional, sum(meur) as meur
    from partidas
    where clasificacion = 'mercado' and partida_id in ('hospitalarios', 'especializados', 'primaria', 'traslado')
    group by all
),

todas as (
    select * from partidas
    union all
    select * from sin_aapp
),

totales as (
    select cod_ccaa, anio,
        max(case when clasificacion = 'economica' and partida_id = 'total' then meur end) as total_economica,
        max(case when clasificacion = 'funcional' and partida_id = 'total' then meur end) as total_funcional
    from partidas
    group by all
),

pob_enero as (
    select cast(cod as varchar) as cod_ccaa, cast(anio as integer) as anio, poblacion
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total' and cod between '01' and '17'
    union all
    select '00', cast(anio as integer), sum(poblacion)
    from {{ ref('poblacion_territorios') }}
    where nivel = 'ccaa' and sexo = 'Total' and cod between '01' and '17'
    group by anio
),

pob_julio as (
    select a.cod_ccaa, a.anio, coalesce((a.poblacion + b.poblacion) / 2.0, a.poblacion) as poblacion
    from pob_enero a
    left join pob_enero b on b.cod_ccaa = a.cod_ccaa and b.anio = a.anio + 1
)

select
    t.cod_ccaa,
    case when t.cod_ccaa = '00' then 'Total comunidades autónomas' else ter.nombre end as ccaa,
    t.anio,
    t.clasificacion,
    t.partida_id,
    t.partida,
    t.orden,
    t.meur as gasto_meur,
    t.meur * d.factor as gasto_meur_real,
    t.meur * 1e6 / p.poblacion as gasto_eur_hab,
    t.meur * 1e6 * d.factor / p.poblacion as gasto_eur_hab_real,
    100.0 * t.meur / case when t.clasificacion = 'funcional' then tot.total_funcional
                          else tot.total_economica end as peso_pct,
    t.provisional,
    d.anio_base
from todas t
join totales tot on tot.cod_ccaa = t.cod_ccaa and tot.anio = t.anio
left join pob_julio p on p.cod_ccaa = t.cod_ccaa and p.anio = t.anio
left join {{ ref('deflactor') }} d on d.anio = t.anio
left join {{ ref('territorios') }} ter on ter.nivel = 'ccaa' and ter.cod = t.cod_ccaa
