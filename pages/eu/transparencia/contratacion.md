---
title: Kontratazio publikoa
description: "Kontratazio publikoaren bolumena Espainian, lizitatzaile bakarreko lizitazioak, publizitaterik gabeko prozedurak, ETEei esleitutakoa eta administrazioaren araberako banaketa OIReSconen arabera."
i18n_origen: 11662929b821
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../../../src/lib/components/KpiCard.svelte';
    import { formatNumber } from '../../../../../../../src/lib/utils.js';
</script>

```sql licitacion_anual
SELECT * FROM (
    VALUES
        (2019, 134.2, 58.4, 31.0, 4.8, 63.2, 742.0),
        (2020, 118.5, 51.2, 33.0, 8.2, 62.1, 615.0),
        (2021, 152.8, 72.6, 32.0, 3.6, 64.5, 698.0),
        (2022, 169.4, 83.9, 34.0, 2.9, 64.8, 754.0),
        (2023, 181.6, 91.5, 35.0, 2.6, 65.1, 790.0),
        (2024, 186.3, 95.8, 34.5, 2.4, 65.4, 812.0)
) AS t(anio, contratos_miles, importe_mm_eur, pct_un_licitador, pct_sin_publicidad, pymes_pct, contratos_menores_miles)
ORDER BY anio
```

```sql ultimo
SELECT * FROM ${licitacion_anual} ORDER BY anio DESC LIMIT 1
```

```sql competencia_serie
SELECT anio, 'Un solo licitador (%)' AS indicador, pct_un_licitador AS pct FROM ${licitacion_anual}
UNION ALL
SELECT anio, 'Negociado sin publicidad (%)' AS indicador, pct_sin_publicidad AS pct FROM ${licitacion_anual}
ORDER BY anio, indicador
```

```sql por_administracion
SELECT * FROM (
    VALUES
        ('Comunidades Autónomas', 40.8, 36.5, 39.1, 108),
        ('Entidades Locales (Ayuntamientos y Diputaciones)', 34.5, 48.2, 33.1, 96),
        ('Administración General del Estado', 24.7, 15.3, 23.6, 114)
) AS t(administracion, pct_importe, pct_contratos, importe_mm_eur, plazo_medio_dias)
ORDER BY pct_importe DESC
```

# <span aria-hidden="true">📑</span> Kontratazio publikoa

Kontratazio publikoak Espainiako BPGaren hamar eurotik bat xurgatzen du ia. **Kontratazioa Erregulatu eta Gainbegiratzeko Bulego Independenteak (OIReScon)** eta **Europako Batzordearen** Merkatu Bakarraren markagailuak lizitazioen benetako lehia ebaluatzen dute urtero: zenbat diru esleitzen den, zenbat kontratutan aurkezten den **enpresa bakarra** (lehia txikiko alerta), zenbat izapidetzen diren **aldez aurreko publizitaterik gabe** eta zein pisu duten **kontratu txikiek**.

<Grid cols=4>
    <KpiCard
        title="Esleitutako zenbatekoa"
        value={ultimo[0]?.importe_mm_eur}
        formattedValue="{formatNumber(ultimo[0]?.importe_mm_eur, 1)} mila M€"
        period="BEZik gabe {ultimo[0]?.anio}(e)n · {formatNumber(ultimo[0]?.contratos_miles, 1)} mila kontratu arrunt"
        direction="neutral"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.importe_mm_eur}))}
    />
    <KpiCard
        title="Lizitatzaile bakarrarekin"
        value={ultimo[0]?.pct_un_licitador}
        formattedValue="% {formatNumber(ultimo[0]?.pct_un_licitador, 1)}"
        period="{ultimo[0]?.anio}ko lizitazioetatik"
        direction="positive-down"
        source="OIReScon / Europako Batzordea"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_un_licitador}))}
    />
    <KpiCard
        title="Aldez aurreko publizitaterik gabe"
        value={ultimo[0]?.pct_sin_publicidad}
        formattedValue="% {formatNumber(ultimo[0]?.pct_sin_publicidad, 1)}"
        period="publizitaterik gabeko prozedura negoziatua ({ultimo[0]?.anio})"
        direction="positive-down"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pct_sin_publicidad}))}
    />
    <KpiCard
        title="ETEei esleituta"
        value={ultimo[0]?.pymes_pct}
        formattedValue="% {formatNumber(ultimo[0]?.pymes_pct, 1)}"
        period="{ultimo[0]?.anio}(e)n esleitutako kontratuetatik"
        direction="positive-up"
        source="OIReScon"
        sparklineData={licitacion_anual.map(d => ({...d, y: d.pymes_pct}))}
    />
</Grid>

## 1. Kontratazio publikoaren urteko bolumena

2020ko geldialdiaren eta Berreskuratze Planeko Europako funtsen ondorengo exekuzioaren ostean, administrazio publiko guztiek esleitutako urteko zenbatekoa (zergarik gabe) **{formatNumber(ultimo[0]?.importe_mm_eur, 1)} mila milioi eurora** igo da {ultimo[0]?.anio}(e)n, {formatNumber(ultimo[0]?.contratos_miles, 1)} mila kontratu arruntetan eta erregistratutako {formatNumber(ultimo[0]?.contratos_menores_miles, 0)} mila kontratu txiki baino gehiagotan banatuta.

<BarChart
    data={licitacion_anual}
    x=anio
    y=importe_mm_eur
    xFmt='0'
    yFmt='#,##0.0'
    yAxisTitle="Milaka milioi € (BEZik gabe)"
    title="Kontratazio publiko arruntean urtero esleitutako zenbatekoa (milaka M€)"
/>

## 2. Lehia eraginkorra: kontratuen herenak eskaintza bakarra jasotzen du

Sektore Publikoko Kontratuen 9/2017 Legeak nabarmen murriztu zuen **publizitaterik gabeko prozedura negoziatuaren** erabilera (**% {formatNumber(ultimo[0]?.pct_sin_publicidad, 1)}ra** jaitsi zen {ultimo[0]?.anio}(e)n, 2020ko osasun-larrialdiko kontratuen igoera bereziaren ondoren). Hala ere, Europako Batzordearen alerta-adierazle nagusia —**eskaintzaile bakarra** aurkezten den lizitazio irekien proportzioa— **% {formatNumber(ultimo[0]?.pct_un_licitador, 1)}** inguruan mantentzen da.

<LineChart
    data={competencia_serie}
    x=anio
    y=pct
    series=indicador
    xFmt='0'
    yFmt='0.0"%"'
    yAxisTitle="Kontratuen %a"
    title="Eskaintzaile bakarreko lizitazioak eta publizitaterik gabeko prozedurak (%)"
/>

## 3. Nork kontratatzen duen: erkidegoek eta udalek hiru laurden biltzen dituzte

Autonomia-erkidegoek (zenbatekoaren % {formatNumber(por_administracion[0]?.pct_importe, 1)}) eta toki-erakundeek (% {formatNumber(por_administracion[1]?.pct_importe, 1)}) Espainian lizitatutako lau eurotik hiru kudeatzen dituzte; Estatuko Administrazio Orokorrak, berriz, % {formatNumber(por_administracion[2]?.pct_importe, 1)} ordezkatzen du.

<BarChart
    data={por_administracion}
    x=administracion
    y=pct_importe
    swapXY=true
    yFmt='0.0"%"'
    yAxisTitle="Esleitutako zenbatekoaren %a"
    title="Esleitutako zenbatekoaren banaketa administrazio-mailaren arabera (%)"
/>

<DataTable data={por_administracion} search=false>
    <Column id=administracion title="Administrazioa" />
    <Column id=importe_mm_eur title="Zenbatekoa (mila M€)" fmt='0.0' />
    <Column id=pct_importe title="Zenbatekoaren %a" fmt='0.0"%"' />
    <Column id=pct_contratos title="Kontratuen %a" fmt='0.0"%"' />
    <Column id=plazo_medio_dias title="Batez besteko esleipen-epea (egunak)" fmt='0' />
</DataTable>

---

**Iturriak eta metodologia:**
- [Kontratazioa Erregulatu eta Gainbegiratzeko Bulego Independentea (OIReScon)](https://www.hacienda.gob.es/es-ES/Oirescon/Paginas/ias.aspx) — *Espainiako Kontratazio Publikoaren Gainbegiratze Txosten Urterokoa* (Sektore Publikoko Kontratazio Plataformaren eta plataforma autonomikoen agregatu nazionala).
- [Europako Batzordea — Single Market Scoreboard (Public Procurement)](https://single-market-scoreboard.ec.europa.eu/policy_areas/public-procurement_en).
