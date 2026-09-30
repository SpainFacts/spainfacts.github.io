---
title: El sistema elèctric, ara
description: "El sistema elèctric espanyol en directe: demanda, mix de generació, % renovable, intensitat de CO₂ i intercanvis amb França, Portugal, el Marroc, Andorra i les Balears cada 5 minuts."
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

# ⚡ El sistema elèctric, ara

Quanta electricitat s'està consumint en aquest moment a Espanya, amb quines tecnologies es produeix, quant CO₂ s'emet per cada kWh i per on entra i surt energia del país. Les dades són les que publica **Red Eléctrica (REE)**, l'operador del sistema, cada **5 minuts**, i la pàgina s'actualitza sola.

<DirectoSistemaElectrico fallback={electricidad_ultimas_24h} workerUrl={REE_DIRECTO_URL} />

Busques els màxims històrics? Consulta els [rècords del sistema elèctric](/ca/energia-clima/records): la demanda més alta, el percentatge renovable més alt o la intensitat de CO₂ més baixa mai registrats.

---

## Què mostra cada dada

**Cinc sistemes elèctrics, no un.** Espanya té cinc sistemes gestionats per separat: el **peninsular**, el **balear**, el **canari** i els de **Ceuta** i **Melilla**, dos sistemes aïllats molt petits que funcionen amb motors dièsel i turbines de gas. **Espanya (total)** és la suma de tots que publica Red Eléctrica. La Península i les Balears estan unides per un cable submarí; les Canàries estan completament aïllades i cada illa (o parella d'illes) funciona gairebé com un sistema propi, per això depenen tant del gasoil i el fuel.

**Demanda (MW).** Potència mitjana que es consumeix en el sistema durant l'interval de 5 minuts, mesurada en barres de central (inclou les pèrdues de la xarxa, no l'autoconsum solar de teulades, que redueix la demanda que veu REE).

**Renovable (%).** Percentatge de la generació del sistema que prové d'eòlica, solar fotovoltaica, solar tèrmica, hidràulica (sense bombament) i altres renovables (biomassa, biogàs, residus renovables). La turbinació de bombament i les bateries no es compten com a renovables perquè només retornen energia emmagatzemada abans.

**Intensitat de CO₂ (gCO₂/kWh).** Tones de CO₂ emeses per les centrals del sistema en aquella hora dividides per la generació total. Es calcula multiplicant la producció de cada tecnologia fòssil pel factor d'emissió que publica REE per a cada sistema (per exemple, un cicle combinat emet al voltant de 370 g per kWh a la Península, i un motor dièsel a les Canàries, uns 680 g). És una intensitat **de la producció**: no descompta les importacions ni suma les emissions de l'energia importada.

**Preu.** Espanya i Portugal formen el mercat ibèric (MIBEL), i **tota la Península és una única zona de preu**: no hi ha preus regionals com a Austràlia o els Estats Units. Es mostren dos preus:
- el **preu del mercat majorista (OMIE)** per al quart d'hora actual (des d'octubre del 2025 el mercat diari casa preus cada 15 minuts), que és el que cobren els generadors;
- el **PVPC** d'aquesta hora, la tarifa regulada per a consumidors amb menys de 10 kW, que inclou a més peatges, càrrecs i altres costos.

Les Balears i les Canàries tenen un règim econòmic especial i els seus consumidors paguen els mateixos preus que a la Península.

## Què signifiquen les fletxes

Cada fletxa és una **interconnexió** i el seu gruix és proporcional a la potència que la travessa en aquest moment. En **blau**, Espanya importa; en **vermell**, exporta. El número és el saldo net d'aquella frontera en MW.

- **França**: dos grans enllaços pels Pirineus (País Basc–Aquitània i Catalunya–Rosselló), amb uns 3.000 MW de capacitat. És la principal connexió amb la resta d'Europa i sol importar quan la nuclear francesa és barata i exportar en les hores de molt sol a Espanya.
- **Portugal**: la frontera més mallada. Amb el MIBEL, el flux sol seguir les diferències de producció renovable entre els dos països.
- **Marroc**: dos cables submarins per l'Estret. Espanya és gairebé sempre exportadora.
- **Andorra**: petita línia per la qual Espanya abasteix el Principat; el flux va gairebé sempre cap a Andorra.
- **Península–Balears** (en violeta): el cable Sagunt–Santa Ponça (400 MW), que sol cobrir una part important de la demanda de les illes, sobretot de Mallorca.

El **saldo exterior** de la Península suma totes les fronteres internacionals: si és positiu, Espanya està important.

## Metodologia

- **Dades en directe.** Un petit servei propi (un *worker* a Cloudflare) consulta cada 5 minuts les corbes de demanda i generació que REE publica per al seu visor de [demanda en temps real](https://demanda.ree.es/visiona/peninsula/demandaqh/tablas/), els factors d'emissió de cada sistema i els preus de [REData](https://www.ree.es/es/datos/apidatos). Les xifres es normalitzen amb les mateixes equivalències de tecnologies que fa servir la resta de SpainFacts.
- **Si el servei en directe no respon**, la pàgina mostra les últimes dades que es van carregar en actualitzar el lloc i ho indica amb l'etiqueta *No en directe*.
- **Horaris.** Totes les hores són peninsulars (CET/CEST); les Canàries van una hora per darrere. El gràfic de 24 hores es mostra amb un punt cada 15 minuts.
- **Dades provisionals.** Són mesures en temps real, subjectes a revisió: REE les consolida setmanes després. Poden faltar uns minuts al final de la sèrie o, excepcionalment, un sistema complet.
- **Desglossament per fronteres.** El visor de REE només desglossa l'intercanvi per país des de finals del 2024; abans només donava el saldo total.

## Fonts

| Organisme | Dada | Enllaç |
|:---|:---|:---|
| **Red Eléctrica (REE)** | Demanda i generació cada 5 minuts per sistema, factors d'emissió | [demanda.ree.es](https://demanda.ree.es/visiona/home) |
| **Red Eléctrica (REE)** | Preu del mercat spot i PVPC (REData) | [apidatos.ree.es](https://www.ree.es/es/datos/apidatos) |
| **OMIE** | Mercat diari ibèric | [omie.es](https://www.omie.es/) |

> Font: Red Eléctrica (REE). Els serveis de temps real de REE no tenen una documentació pública oficial i es fan servir "tal qual"; si canvien, aquesta pàgina es pot quedar temporalment sense dades en directe.
