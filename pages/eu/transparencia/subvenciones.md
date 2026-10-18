---
title: Dirulaguntzak
description: "Zenbat diru publiko ematen den dirulaguntzetan Espainian, zein ehuneko esleitzen den zuzeneko edo izendun emakidaren bidez norgehiagokaren aldean, eta zein administraziok kudeatzen duen (BDNS / IGAE)."
i18n_origen: 9dbf4f2110e5
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql subvenciones_anual
SELECT * FROM (
    VALUES
        (2018, 19.8, 12.9, 6.9, 34.8, 920),
        (2019, 21.4, 13.7, 7.7, 36.0, 985),
        (2020, 31.6, 15.2, 16.4, 51.9, 1480),
        (2021, 35.8, 18.4, 17.4, 48.6, 1620),
        (2022, 38.2, 21.8, 16.4, 42.9, 1540),
        (2023, 39.5, 23.3, 16.2, 41.0, 1590),
        (2024, 37.9, 22.9, 15.0, 39.6, 1510)
) AS t(anio, importe_total_mm, concurrencia_mm, directa_mm, pct_directa, concesiones_miles)
ORDER BY anio
```

```sql ultimo
SELECT * FROM ${subvenciones_anual} ORDER BY anio DESC LIMIT 1
```

```sql modalidad_serie
SELECT anio, 'Concurrencia competitiva' AS modalidad, concurrencia_mm AS importe_mm FROM ${subvenciones_anual}
UNION ALL
SELECT anio, 'Concesión directa y nominativa' AS modalidad, directa_mm AS importe_mm FROM ${subvenciones_anual}
ORDER BY anio, modalidad
```

```sql subvenciones_admin
SELECT * FROM (
    VALUES
        ('Administración General del Estado', 19.4, 51.2, 43.5),
        ('Comunidades Autónomas', 14.2, 37.5, 36.8),
        ('Entidades Locales', 4.3, 11.3, 31.2)
) AS t(administracion, importe_mm, pct_total, pct_directa)
ORDER BY importe_mm DESC
```

# <span aria-hidden="true">💶</span> Dirulaguntza publikoak

Dirulaguntzei buruzko 38/2003 Lege Orokorrak **lehia askeko norgehiagoka** ezartzen du prozedura arrunt gisa (deialdi irekia, non eskaerak irizpide objektiboekin alderatu eta barematzen diren). Salbuespen gisa, legeak dirulaguntza **izendunak** (aurrekontuetan onuraduna zehaztuta dutenak) eta interes publiko, sozial edo ekonomikoko arrazoiengatik **zuzenean emandakoak** onartzen ditu. **Dirulaguntzen Datu-base Nazionaleko (BDNS / IGAE)** erregistroek bide bakoitzetik funtsen zein zati banatzen den neurtzeko aukera ematen dute.

<Grid cols=4>
    <KpiCard
        title="Emandako zenbateko osoa"
        value={ultimo[0]?.importe_total_mm}
        formattedValue="{formatNumber(ultimo[0]?.importe_total_mm, 1)} mila M€"
        period="BDNSn erregistratua {ultimo[0]?.anio}(e)n"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.importe_total_mm}))}
    />
    <KpiCard
        title="Norgehiagokarik gabe"
        value={ultimo[0]?.pct_directa}
        formattedValue="% {formatNumber(ultimo[0]?.pct_directa, 1)}"
        period="zuzeneko edo izendun emakida ({ultimo[0]?.anio}) · {formatNumber(ultimo[0]?.directa_mm, 1)} mila M€"
        direction="positive-down"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.pct_directa}))}
    />
    <KpiCard
        title="Norgehiagoka bidez"
        value={ultimo[0]?.concurrencia_mm}
        formattedValue="{formatNumber(ultimo[0]?.concurrencia_mm, 1)} mila M€"
        period="deialdi irekiak {ultimo[0]?.anio}(e)n (% {formatNumber(100 - ultimo[0]?.pct_directa, 1)})"
        direction="positive-up"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concurrencia_mm}))}
    />
    <KpiCard
        title="Erregistratutako emakidak"
        value={ultimo[0]?.concesiones_miles}
        formattedValue="{formatNumber(ultimo[0]?.concesiones_miles, 0)} mila"
        period="banakako ebazpenak {ultimo[0]?.anio}(e)n"
        direction="neutral"
        source="BDNS / IGAE"
        sparklineData={subvenciones_anual.map(d => ({...d, y: d.concesiones_miles}))}
    />
</Grid>

## 1. Norgehiagoka vs. zuzeneko emakida

Dirulaguntzetako hamar eurotik lau (**% {formatNumber(ultimo[0]?.pct_directa, 1)}** {ultimo[0]?.anio}(e)n) zuzeneko edo izendun prozeduren bidez esleitzen dira. Pandemia garaian (2020–2021), larrialdiko aparteko laguntzek zuzeneko bidea zenbateko osoaren erditik gora igo zuten aldi baterako; ordutik norgehiagokaren pisua berreskuratu egin da, baina dirulaguntzen bolumen osoa 2018koaren ia bikoitza da oraindik, PRTR Europako funtsen hedapenagatik.

<BarChart
    data={modalidad_serie}
    x=anio
    y=importe_mm
    series=modalidad
    type=stacked
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Milaka milioi €"
    title="Emandako dirulaguntzak prozeduraren arabera: norgehiagoka vs. zuzenekoa (milaka M€)"
/>

<LineChart
    data={subvenciones_anual}
    x=anio
    y=pct_directa
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="Zenbateko osoaren %a"
    startingAtZero={false}
    title="Norgehiagokarik gabe emandako dirulaguntzen zenbatekoaren ehunekoa (%)"
/>

## 2. Banaketa administrazio-mailaren arabera

Estatuko Administrazio Orokorrak BDNSn erregistratutako zenbatekoaren erdia baino zertxobait gehiago biltzen du (% {formatNumber(subvenciones_admin[0]?.pct_total, 1)}) eta zuzeneko zein izendun emakiden proportziorik handiena ere badu (% {formatNumber(subvenciones_admin[0]?.pct_directa, 1)}), ondoren autonomia-erkidegoak (guztizkoaren % {formatNumber(subvenciones_admin[1]?.pct_total, 1)}) eta udalak eta aldundiak (% {formatNumber(subvenciones_admin[2]?.pct_total, 1)}) daudelarik.

<DataTable data={subvenciones_admin} search=false>
    <Column id=administracion title="Administrazio emailea" />
    <Column id=importe_mm title="Zenbatekoa (mila M€)" fmt='0.0' />
    <Column id=pct_total title="Guztizko nazionalaren %a" fmt='0.0"%"' />
    <Column id=pct_directa title="% zuzeneko / izendun emakidan" fmt='0.0"%"' />
</DataTable>

---

**Iturriak eta metodologia:**
- [Dirulaguntzen Datu-base Nazionala (BDNS) — Estatuko Administrazioaren Kontu-hartzailetza Nagusia (IGAE)](https://www.infosubvenciones.es/bdnstrans/GE/es/index) eta IGAE / AIReFen dirulaguntzen ikuskaritza-txostenak (dirulaguntza publikoen *Spending Review*).
- Prentsa, irrati eta telebistara berariaz bideratutako dirulaguntzak eta publizitate instituzionala kontsultatzeko, bisitatu [Hedabideak eta diru publikoa](/eu/medios/dinero-publico) atala.
