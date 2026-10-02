---
title: Marka eta modelo salduenak
description: "Espainian matrikulatutako auto, moto, furgoneta, kamioi eta autobusen marka, modelo eta taldeen hileko sailkapena, motor motaren eta kanalaren arabera iragazgarria: partikularrak, enpresak, rentinga eta alokairua."
i18n_origen: ae4008cde621
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql energias
SELECT DISTINCT energia, energia_etiqueta, energia_orden
FROM mother.movilidad_matriculaciones_mensual
ORDER BY energia_orden
```

```sql periodos
WITH meses AS (
    SELECT DISTINCT mes FROM mother.movilidad_modelos_mensual
)
SELECT valor, etiqueta, orden FROM (
    SELECT
        'M' || strftime(mes, '%Y-%m') AS valor,
        strftime(mes, '%m/%Y') AS etiqueta,
        -CAST(epoch(mes) AS BIGINT) AS orden
    FROM meses
    UNION ALL
    SELECT
        'A' || CAST(CAST(year(mes) AS INTEGER) AS VARCHAR) AS valor,
        'Año ' || CAST(CAST(year(mes) AS INTEGER) AS VARCHAR) || ' (' || CAST(count(*) AS VARCHAR) || ' meses)' AS etiqueta,
        -CAST(epoch(max(mes)) AS BIGINT) - 1 AS orden
    FROM meses
    GROUP BY year(mes)
)
ORDER BY orden
```

# 🚗 Marka eta modelo salduenak

Zer matrikulatzen den Espainian hilero, markaz marka eta modeloz modelo, Trafiko Zuzendaritza Nagusiaren mikrodatuen arabera. Iragazi motor motaren arabera, adibidez, **elektriko hutsak** soilik ikusteko, eta kanalaren arabera, **partikularrek** erosten dutena enpresen, rentingaren eta alokairuaren flotetatik bereizteko; turismoetan, flota horiek erdia baino gehiago dira.

<div class="not-prose flex flex-wrap gap-4 items-end my-4">
<ButtonGroup name=grupo title="Ibilgailua">
    <ButtonGroupItem valueLabel="Turismoak" value="turismo" default />
    <ButtonGroupItem valueLabel="Motoak" value="motocicleta" />
    <ButtonGroupItem valueLabel="Furgonetak" value="furgoneta" />
    <ButtonGroupItem valueLabel="Kamioiak" value="camion" />
    <ButtonGroupItem valueLabel="Autobusak" value="autobus" />
</ButtonGroup>

<Dropdown name=energia title="Motorra" data={energias} value=energia label=energia_etiqueta order=energia_orden>
    <DropdownOption value="todas" valueLabel="Motor guztiak" />
</Dropdown>

<Dropdown name=canal title="Kanala">
    <DropdownOption value="todos" valueLabel="Kanal guztiak" />
    <DropdownOption value="particular" valueLabel="Partikularrak" />
    <DropdownOption value="flotas" valueLabel="Flotak (partikularrak izan ezik guztiak)" />
    <DropdownOption value="empresa" valueLabel="Enpresak" />
    <DropdownOption value="renting" valueLabel="Renting" />
    <DropdownOption value="alquiler" valueLabel="Alokairua (rent a car)" />
    <DropdownOption value="servicio_publico" valueLabel="Taxia, VTCa eta beste zerbitzu batzuk" />
</Dropdown>

<Dropdown name=periodo title="Aldia" data={periodos} value=valor label=etiqueta order=orden>
    <DropdownOption value="ULTIMO" valueLabel="Argitaratutako azken hilabetea" />
</Dropdown>
</div>

```sql periodo_sel
-- "Último mes publicado" se traduce al código del mes más reciente (M2026-08)
SELECT CASE WHEN '${inputs.periodo.value}' = 'ULTIMO'
            THEN 'M' || strftime(max(mes), '%Y-%m')
            ELSE '${inputs.periodo.value}' END AS p
FROM mother.movilidad_modelos_mensual
```

```sql filtro
SELECT *
FROM mother.movilidad_modelos_mensual
WHERE grupo = '${inputs.grupo}'
  AND ('${inputs.energia.value}' = 'todas' OR energia = '${inputs.energia.value}')
  AND ('${inputs.canal.value}' = 'todos' OR ('${inputs.canal.value}' = 'flotas' AND canal <> 'particular') OR canal = '${inputs.canal.value}')
  AND (
    ((SELECT p FROM ${periodo_sel}) LIKE 'M%' AND strftime(mes, '%Y-%m') = substr((SELECT p FROM ${periodo_sel}), 2))
    OR ((SELECT p FROM ${periodo_sel}) LIKE 'A%' AND CAST(year(mes) AS INTEGER) = TRY_CAST(substr((SELECT p FROM ${periodo_sel}), 2) AS INTEGER))
  )
```

```sql filtro_anterior
-- Mismo periodo un año antes, para la variación
SELECT marca, grupo_empresarial, modelo, sum(matriculaciones) AS unidades
FROM mother.movilidad_modelos_mensual
WHERE grupo = '${inputs.grupo}'
  AND ('${inputs.energia.value}' = 'todas' OR energia = '${inputs.energia.value}')
  AND ('${inputs.canal.value}' = 'todos' OR ('${inputs.canal.value}' = 'flotas' AND canal <> 'particular') OR canal = '${inputs.canal.value}')
  AND (
    ((SELECT p FROM ${periodo_sel}) LIKE 'M%' AND strftime(mes + INTERVAL 12 MONTH, '%Y-%m') = substr((SELECT p FROM ${periodo_sel}), 2))
    OR ((SELECT p FROM ${periodo_sel}) LIKE 'A%' AND CAST(year(mes) AS INTEGER) + 1 = TRY_CAST(substr((SELECT p FROM ${periodo_sel}), 2) AS INTEGER)
        AND month(mes) <= (SELECT max(month(mes)) FROM ${filtro}))
  )
GROUP BY marca, grupo_empresarial, modelo
```

```sql total
SELECT sum(matriculaciones) AS unidades, count(DISTINCT marca) AS marcas, count(DISTINCT marca || modelo) AS modelos
FROM ${filtro}
```

```sql marcas
WITH act AS (
    SELECT marca, sum(matriculaciones) AS unidades FROM ${filtro} GROUP BY marca
),
ant AS (
    SELECT marca, sum(unidades) AS unidades FROM ${filtro_anterior} GROUP BY marca
)
SELECT
    row_number() OVER (ORDER BY a.unidades DESC, a.marca) AS puesto,
    a.marca,
    a.unidades,
    a.unidades / sum(a.unidades) OVER () AS cuota,
    CASE WHEN p.unidades >= 20 THEN a.unidades / p.unidades - 1 END AS variacion
FROM act a
LEFT JOIN ant p ON p.marca = a.marca
ORDER BY a.unidades DESC, a.marca
```

```sql modelos
WITH act AS (
    SELECT marca, modelo, sum(matriculaciones) AS unidades FROM ${filtro} GROUP BY marca, modelo
)
SELECT
    row_number() OVER (ORDER BY a.unidades DESC, a.marca, a.modelo) AS puesto,
    a.marca,
    a.modelo,
    a.unidades,
    a.unidades / sum(a.unidades) OVER () AS cuota,
    CASE WHEN p.unidades >= 20 THEN a.unidades / p.unidades - 1 END AS variacion
FROM act a
LEFT JOIN ${filtro_anterior} p ON p.marca = a.marca AND p.modelo = a.modelo
ORDER BY a.unidades DESC, a.marca, a.modelo
```

```sql grupos
WITH act AS (
    SELECT grupo_empresarial AS grupo, marca, sum(matriculaciones) AS unidades
    FROM ${filtro} GROUP BY ALL
),
ant AS (
    SELECT grupo_empresarial AS grupo, sum(unidades) AS unidades FROM ${filtro_anterior} GROUP BY ALL
),
g AS (
    SELECT grupo, sum(unidades) AS unidades, count(*) AS n_marcas,
        string_agg(marca, ', ' ORDER BY unidades DESC) AS marcas
    FROM act GROUP BY grupo
)
SELECT
    row_number() OVER (ORDER BY g.unidades DESC, g.grupo) AS puesto,
    g.grupo, g.marcas, g.n_marcas, g.unidades,
    g.unidades / sum(g.unidades) OVER () AS cuota,
    CASE WHEN p.unidades >= 20 THEN g.unidades / p.unidades - 1 END AS variacion
FROM g
LEFT JOIN ant p ON p.grupo = g.grupo
ORDER BY g.unidades DESC, g.grupo
```

```sql top_grupos_grafico
SELECT grupo, unidades FROM ${grupos} WHERE puesto <= 15 ORDER BY unidades DESC
```

```sql top_marcas_grafico
SELECT marca, unidades FROM ${marcas} WHERE puesto <= 20 ORDER BY unidades DESC
```

<p class="text-sm text-gray-600 dark:text-gray-400">Matrikulatutako unitate berriak: {formatNumber(total[0]?.unidades, 0)}; markak: {formatNumber(total[0]?.marcas, 0)}; modeloak: {formatNumber(total[0]?.modelos, 0)} (aukeratutako iragazkiekin).</p>

## Taldeak

Marka asko fabrikatzaile berarenak dira eta plataformak, motorrak eta lantegiak partekatzen dituzte: Peugeot, Citroën, Opel, Fiat edo Jeep **Stellantis**enak dira; Seat, Cupra, Skoda edo Audi, **Volkswagen**enak; Volvo, Polestar edo Lynk & Co, **Geely** txinatarrarenak; eta MG, **SAIC**enak. Jabearen arabera multzokatuta, merkatuaren banaketa nabarmen aldatzen da.

<BarChart
    data={top_grupos_grafico}
    x=grupo
    y=unidades
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#7c3aed"
    title="Matrikulazio gehien dituzten 15 taldeak"
/>

<DataTable data={grupos} rows=15 search=true>
    <Column id=puesto title="#" />
    <Column id=grupo title="Taldea" />
    <Column id=marcas title="Markak (salmenta gehienetik gutxienera)" wrap=true />
    <Column id=unidades title="Unitateak" fmt=num0 contentType=bar barColor="#ddd6fe" />
    <Column id=cuota title="Kuota" fmt=pct1 />
    <Column id=variacion title="Duela urtebeterekin alderatuta" fmt=pct0 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">Taldea, marka bakoitzaren jabe nagusiaren arabera. % 50eko edo gutxiagoko partaidetzak ez dira kontuan hartzen: Smart (% 50 Mercedes-Benz eta % 50 Geely) Geelyrekin doa, eta Leapmotor (% 21 Stellantisena) bere talde propioa da. Beste batek fabrikatutako auto bati logoa besterik jartzen ez dioten markak, hala nola Ebro (Cheryren autoak) edo DR (Cheryrenak eta beste fabrikatzaile txinatar batzuenak), talde propiotzat hartzen dira, enpresa beste bat delako. Kamioietan eta autobusetan, Volvo eta Renault AB Volvo taldekoak dira, eta Mercedes-Benz, Daimler Truckekoa, autoetakoez bestelako enpresak. Taulan talderik gabe agertzen diren markak beren talde propioa dira.</p>

## Markak

<BarChart
    data={top_marcas_grafico}
    x=marca
    y=unidades
    swapXY=true
    sort=false
    yFmt=num0
    fillColor="#0f766e"
    title="Matrikulazio gehien dituzten 20 markak"
/>

<DataTable data={marcas} rows=20 search=true>
    <Column id=puesto title="#" />
    <Column id=marca title="Marka" />
    <Column id=unidades title="Unitateak" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Kuota" fmt=pct1 />
    <Column id=variacion title="Duela urtebeterekin alderatuta" fmt=pct0 contentType=delta />
</DataTable>

## Modeloak

<DataTable data={modelos} rows=25 search=true>
    <Column id=puesto title="#" />
    <Column id=marca title="Marka" />
    <Column id=modelo title="Modeloa" />
    <Column id=unidades title="Unitateak" fmt=num0 contentType=bar barColor="#99f6e4" />
    <Column id=cuota title="Kuota" fmt=pct1 />
    <Column id=variacion title="Duela urtebeterekin alderatuta" fmt=pct0 contentType=delta />
</DataTable>

<p class="text-xs text-gray-500">Ibilgailu berriak soilik (inportatutako erabilitakoak ez dira zenbatzen). Aldakuntzak aurreko urteko aldi berarekin alderatzen du, eta ez da erakusten orduan 20 unitate baino gutxiago zeudenean. Modeloaren izena fitxa teknikokoa da: auto batzuk aldaerekin agertzen dira (adib. «SANDERO» eta «SANDERO STEPWAY»). Karrozagile batek amaitzen dituen ibilgailuetan (kamioiak, autobusak, furgoneta kanperizatuak) txasiaren marka zenbatzen da, ez karrozagilearena.</p>

<p class="text-xs text-gray-500">Kanala: partikularren autoak pertsona fisiko baten izenean (autonomoak barne) rentingik gabe matrikulatutakoak dira; enpresenak, pertsona juridikoenak, gero «zero kilometroko» gisa saltzen diren kontzesionarioen eta marken automatrikulazioak barne; alokairukoak, gidaririk gabeko alokairu-zerbitzukoak (rent a car); eta taxia, VTCa eta beste batzuk, zerbitzu publikokoak.</p>

```sql mix_marcas
-- Mezcla de motores de las 15 primeras marcas (sin filtrar por motor)
WITH base AS (
    SELECT m.marca, m.energia, sum(m.matriculaciones) AS unidades
    FROM mother.movilidad_modelos_mensual m
    WHERE m.grupo = '${inputs.grupo}'
  AND ('${inputs.canal.value}' = 'todos' OR ('${inputs.canal.value}' = 'flotas' AND m.canal <> 'particular') OR m.canal = '${inputs.canal.value}')
      AND (
        ((SELECT p FROM ${periodo_sel}) LIKE 'M%' AND strftime(m.mes, '%Y-%m') = substr((SELECT p FROM ${periodo_sel}), 2))
        OR ((SELECT p FROM ${periodo_sel}) LIKE 'A%' AND CAST(year(m.mes) AS INTEGER) = TRY_CAST(substr((SELECT p FROM ${periodo_sel}), 2) AS INTEGER))
      )
    GROUP BY ALL
),
top AS (
    SELECT marca FROM base GROUP BY marca ORDER BY sum(unidades) DESC LIMIT 15
)
SELECT b.marca, e.energia_etiqueta AS motor, e.energia_orden, b.unidades / sum(b.unidades) OVER (PARTITION BY b.marca) AS cuota
FROM base b
JOIN top t ON t.marca = b.marca
JOIN ${energias} e ON e.energia = b.energia
ORDER BY e.energia_orden
```

## Zer motorrekin saltzen du marka bakoitzak?

Aukeratutako aldian gehien saltzen duten 15 markak, motor motaren arabera banatuta (motor-iragazkia kontuan hartu gabe).

<BarChart
    data={mix_marcas}
    x=marca
    y=cuota
    series=motor
    swapXY=true
    type=stacked100
    yFmt=pct0
    seriesOrder={energias.map(d => d.energia_etiqueta)}
    colorPalette={['#0f766e', '#14b8a6', '#a3e635', '#38bdf8', '#a78bfa', '#f59e0b', '#78716c', '#d1d5db']}
/>

---

**Iturria:** [DGT – Ibilgailuen matrikulazioen mikrodatuak (MATRABA)](https://www.dgt.es/menusecundario/dgt-en-cifras/matraba-listados/matriculaciones-automoviles-mensual.html). Motor mota ibilgailu elektrikoaren kategoriaren eta fitxa teknikoko propultsioaren arabera: hibrido ez-entxufagarriek (HEV) *mild hybrid* direlakoak barne hartzen dituzte; autonomia hedatukoak (REEV) entxufagarriekin batera zenbatzen dira. Xehetasun gehiago: [Auto elektrikoa](/eu/movilidad/coche-electrico).

<LastRefreshed prefix="Datuak eguneratuta" />
