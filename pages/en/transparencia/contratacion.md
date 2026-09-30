---
title: Public procurement
description: "Under construction: how much public administrations award without competition (minor contracts, procedures without publication, a single bidder), by administration, territory and party."
i18n_origen: cf8c43bfc9cf
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import EnConstruccion from '../../../../../../../src/lib/components/EnConstruccion.svelte';
</script>

# <span aria-hidden="true">📑</span> Public procurement

<EnConstruccion motivo="the data from the Public Sector Procurement Platform are published as thousands of monthly XML files (several gigabytes) in the CODICE format, which have to be downloaded, parsed and deduplicated before anything can be counted reliably." />

## What it will show

Competition in public contracts is one of the best signs of good management: when several
companies bid, the price goes down and so does the risk of favouritism. This section will measure, for each
administration (central government, autonomous communities, provincial councils and municipal councils):

- The weight of **minor contracts** (direct award without tendering below the thresholds
  of Law 9/2017) in the total amount contracted.
- Contracts awarded through a **negotiated procedure without publication**.
- Contracts with **a single bidder**, the indicator the European Commission uses to compare countries.
- The trend over time and the comparison **by party** of the government of each administration, using the
  same criteria as the rest of the transparency section.

## Where the data will come from

- [Public Sector Procurement Platform](https://contrataciondelsectorpublico.gob.es/): open data
  on tenders and awards (monthly ATOM syndication, with a specific feed for
  minor contracts).
- Regional platforms that do not upload all their contracts to the national one (they have to be integrated so as not to
  leave out entire autonomous communities).
- For comparison with other countries, the European Commission's procurement indicators (currently only
  published in interactive dashboards, with no download).

In the meantime, the [list of open data projects](/en/varios/datos-abiertos) includes these sources.
