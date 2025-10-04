select  * from main.poblacion_provincias
where Total is not null
order by Periodo desc
LIMIT 100;