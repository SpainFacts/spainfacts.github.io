---
title: The electricity system, right now
description: "Spain's electricity system live: demand, generation mix, % renewable, CO₂ intensity and exchanges with France, Portugal, Morocco, Andorra and the Balearic Islands every 5 minutes."
i18n_origen: c2c14381050a
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import DirectoSistemaElectrico from '../../../../../../../src/lib/components/DirectoSistemaElectrico.svelte';
    import { REE_DIRECTO_URL } from '../../../../../../../src/lib/config/directo.js';
</script>

```sql electricidad_ultimas_24h
SELECT *
FROM mother.electricidad_ultimas_24h
ORDER BY sistema, ts_utc
```

# ⚡ The electricity system, right now

How much electricity Spain is consuming at this very moment, which technologies are producing it, how much CO₂ is emitted for each kWh and where energy is flowing into and out of the country. The data are those published by **Red Eléctrica (REE)**, the system operator, every **5 minutes**, and the page updates itself.

<DirectoSistemaElectrico fallback={electricidad_ultimas_24h} workerUrl={REE_DIRECTO_URL} />

Looking for all-time highs? See the [electricity system records](/en/energia-clima/records): the highest demand, the highest renewable share and the lowest CO₂ intensity ever recorded.

---

## What each figure shows

**Five electricity systems, not one.** Spain has five separately managed systems: the **mainland** (peninsular) system, the **Balearic** system, the **Canary Islands** system and those of **Ceuta** and **Melilla**, two very small isolated systems that run on diesel engines and gas turbines. **Spain (total)** is the sum of all of them as published by Red Eléctrica. The mainland and the Balearic Islands are linked by a subsea cable; the Canary Islands are completely isolated and each island (or pair of islands) works almost as a system of its own, which is why they depend so heavily on diesel and fuel oil.

**Demand (MW).** Average power consumed in the system during the 5-minute interval, measured at power-station busbars (it includes grid losses, but not rooftop solar self-consumption, which reduces the demand seen by REE).

**Renewable (%).** Share of the system's generation that comes from wind, solar photovoltaic, solar thermal, hydro (excluding pumped storage) and other renewables (biomass, biogas, renewable waste). Pumped-storage generation and batteries are not counted as renewable because they only return energy stored earlier.

**CO₂ intensity (gCO₂/kWh).** Tonnes of CO₂ emitted by the system's power stations in that hour divided by total generation. It is calculated by multiplying the output of each fossil technology by the emission factor REE publishes for each system (for example, a combined cycle plant emits around 370 g per kWh on the mainland, and a diesel engine in the Canary Islands around 680 g). It is a **production-based** intensity: it neither deducts imports nor adds the emissions of imported energy.

**Price.** Spain and Portugal form the Iberian market (MIBEL), and **the whole mainland is a single price zone**: there are no regional prices as in Australia or the United States. Two prices are shown:
- the **wholesale market price (OMIE)** for the current quarter-hour (since October 2025 the day-ahead market clears prices every 15 minutes), which is what generators are paid;
- the **PVPC** for this hour, the regulated tariff for consumers with less than 10 kW, which also includes network tolls, charges and other costs.

The Balearic and Canary Islands have a special economic regime and their consumers pay the same prices as on the mainland.

## What the arrows mean

Each arrow is an **interconnection** and its thickness is proportional to the power flowing through it at this moment. In **blue**, Spain is importing; in **red**, it is exporting. The number is the net balance across that border in MW.

- **France**: two large links across the Pyrenees (Basque Country–Aquitaine and Catalonia–Roussillon), with about 3,000 MW of capacity. It is the main connection with the rest of Europe; Spain tends to import when French nuclear power is cheap and to export during very sunny hours in Spain.
- **Portugal**: the most meshed border. Under MIBEL, the flow tends to follow the differences in renewable output between the two countries.
- **Morocco**: two subsea cables across the Strait of Gibraltar. Spain is almost always the exporter.
- **Andorra**: a small line through which Spain supplies the Principality; the flow almost always goes towards Andorra.
- **Mainland–Balearic Islands** (in violet): the Sagunto–Santa Ponsa cable (400 MW), which usually covers a significant share of the islands' demand, especially Majorca's.

The mainland's **external balance** adds up all the international borders: if it is positive, Spain is importing.

## Methodology

- **Live data.** A small in-house service (a Cloudflare *worker*) queries every 5 minutes the demand and generation curves that REE publishes for its [real-time demand](https://demanda.ree.es/visiona/peninsula/demandaqh/tablas/) viewer, the emission factors for each system and the prices from [REData](https://www.ree.es/es/datos/apidatos). The figures are normalised using the same technology mappings as the rest of SpainFacts.
- **If the live service does not respond**, the page shows the latest data loaded when the site was last updated and flags it with the label *No en directo* (not live).
- **Times.** All times are mainland Spanish time (CET/CEST); the Canary Islands are one hour behind. The 24-hour chart shows one point every 15 minutes.
- **Provisional data.** These are real-time measurements subject to revision: REE consolidates them weeks later. A few minutes may be missing at the end of the series or, exceptionally, an entire system.
- **Breakdown by border.** REE's viewer has only broken down exchanges by country since late 2024; before that it only gave the total balance.

## Sources

| Body | Data | Link |
|:---|:---|:---|
| **Red Eléctrica (REE)** | Demand and generation every 5 minutes by system, emission factors | [demanda.ree.es](https://demanda.ree.es/visiona/home) |
| **Red Eléctrica (REE)** | Spot market price and PVPC (REData) | [apidatos.ree.es](https://www.ree.es/es/datos/apidatos) |
| **OMIE** | Iberian day-ahead market | [omie.es](https://www.omie.es/) |

> Source: Red Eléctrica (REE). REE's real-time services have no official public documentation and are used "as is"; if they change, this page may temporarily be left without live data.
