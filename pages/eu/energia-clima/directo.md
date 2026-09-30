---
title: Sistema elektrikoa, orain
description: "Espainiako sistema elektrikoa zuzenean: eskaria, sorkuntza-mixa, % berriztagarria, CO₂ intentsitatea eta Frantzia, Portugal, Maroko, Andorra eta Balear Uharteekiko trukeak 5 minuturo."
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

# ⚡ Sistema elektrikoa, orain

Zenbat elektrizitate kontsumitzen ari den une honetan Espainian, zer teknologiarekin ekoizten den, zenbat CO₂ isurtzen den kWh bakoitzeko eta nondik sartzen eta ateratzen den energia herrialdetik. Datuak **Red Eléctrica (REE)** sistemaren operadoreak **5 minuturo** argitaratzen dituenak dira, eta orria bere kasa eguneratzen da.

<DirectoSistemaElectrico fallback={electricidad_ultimas_24h} workerUrl={REE_DIRECTO_URL} />

Maximo historikoen bila? Kontsultatu [sistema elektrikoaren errekorrak](/eu/energia-clima/records): inoiz erregistratutako eskaririk handiena, berriztagarrien ehunekorik handiena edo CO₂ intentsitaterik txikiena.

---

## Zer erakusten duen datu bakoitzak

**Bost sistema elektriko, ez bat.** Espainiak bost sistema ditu, bakoitza bere aldetik kudeatuta: **penintsulakoa**, **balearra**, **kanariarra** eta **Ceutakoa** eta **Melillakoa**, diesel-motorrekin eta gas-turbinekin dabiltzan bi sistema isolatu oso txiki. **Espainia (guztira)** Red Eléctricak argitaratzen duen guztien batura da. Penintsula eta Balear Uharteak itsaspeko kable batek lotzen ditu; Kanariak erabat isolatuta daude eta uharte bakoitza (edo uharte-bikote bakoitza) ia sistema propio gisa dabil, eta horregatik dago hain mendekoa gasolioarekiko eta fuelarekiko.

**Eskaria (MW).** Sisteman 5 minutuko tartean kontsumitzen den batez besteko potentzia, zentralen barretan neurtua (sareko galerak barne hartzen ditu, ez teilatuetako eguzki-autokontsumoa, REEk ikusten duen eskaria murrizten baitu).

**Berriztagarria (%).** Sistemaren sorkuntzaren zer ehuneko datorren energia eolikotik, eguzki-energia fotovoltaikotik, eguzki-energia termikotik, hidraulikotik (ponpaketarik gabe) eta beste berriztagarri batzuetatik (biomasa, biogasa, hondakin berriztagarriak). Ponpaketaren turbinazioa eta bateriak ez dira berriztagarritzat hartzen, lehenago biltegiratutako energia itzultzen baitute soilik.

**CO₂ intentsitatea (gCO₂/kWh).** Sistemako zentralek ordu horretan isuritako CO₂ tonak zati sorkuntza osoa. Teknologia fosil bakoitzaren ekoizpena REEk sistema bakoitzerako argitaratzen duen isuri-faktoreaz biderkatuz kalkulatzen da (adibidez, ziklo konbinatu batek 370 g inguru isurtzen ditu kWh bakoitzeko Penintsulan, eta diesel-motor batek Kanarietan, 680 g inguru). **Ekoizpenaren** intentsitatea da: ez ditu inportazioak kentzen, ezta inportatutako energiaren isuriak gehitzen ere.

**Prezioa.** Espainiak eta Portugalek iberiar merkatua (MIBEL) osatzen dute, eta **Penintsula osoa prezio-eremu bakarra da**: ez dago eskualdeko preziorik Australian edo Estatu Batuetan bezala. Bi prezio erakusten dira:
- uneko ordu-laurdeneko **handizkako merkatuaren prezioa (OMIE)** (2025eko urritik eguneko merkatuak 15 minuturo lotzen ditu prezioak), sortzaileek kobratzen dutena;
- ordu honetako **PVPC**, 10 kW baino gutxiagoko kontsumitzaileentzako tarifa arautua, bidesariak, kargak eta beste kostu batzuk ere barne hartzen dituena.

Balear Uharteek eta Kanariek araubide ekonomiko berezia dute, eta haien kontsumitzaileek Penintsulako prezio berberak ordaintzen dituzte.

## Zer esan nahi duten geziek

Gezi bakoitza **interkonexio** bat da, eta haren lodiera une honetan zeharkatzen duen potentziaren proportzionala da. **Urdinez**, Espainiak inportatzen du; **gorriz**, esportatzen du. Zenbakia muga horren saldo garbia da, MWtan.

- **Frantzia**: bi lotura handi Pirinioetan zehar (Euskal Autonomia Erkidegoa–Akitania eta Katalunia–Rosellón), 3.000 MW inguruko ahalmenarekin. Europako gainerako herrialdeekiko lotura nagusia da, eta normalean inportatu egiten du Frantziako nuklearra merkea denean eta esportatu Espainian eguzki handiko orduetan.
- **Portugal**: sare-lotura gehien dituen muga. MIBELekin, fluxuak bi herrialdeen arteko ekoizpen berriztagarriaren aldeei jarraitzen die normalean.
- **Maroko**: bi itsaspeko kable Itsasartean zehar. Espainia ia beti da esportatzailea.
- **Andorra**: linea txiki bat, haren bidez Espainiak Printzerria hornitzen du; fluxua ia beti doa Andorrarantz.
- **Penintsula–Balear Uharteak** (morez): Sagunto–Santa Ponsa kablea (400 MW), normalean uharteetako eskariaren zati garrantzitsu bat estaltzen duena, batez ere Mallorcakoa.

Penintsulako **kanpo-saldoak** nazioarteko muga guztiak batzen ditu: positiboa bada, Espainia inportatzen ari da.

## Metodologia

- **Zuzeneko datuak.** Zerbitzu propio txiki batek (Cloudflareko *worker* bat) 5 minuturo kontsultatzen ditu REEk [denbora errealeko eskaria](https://demanda.ree.es/visiona/peninsula/demandaqh/tablas/) ikusteko tresnarako argitaratzen dituen eskari- eta sorkuntza-kurbak, sistema bakoitzaren isuri-faktoreak eta [REData](https://www.ree.es/es/datos/apidatos)-ren prezioak. Zifrak SpainFactsen gainerako atalek erabiltzen dituzten teknologia-baliokidetza berberekin normalizatzen dira.
- **Zuzeneko zerbitzuak erantzuten ez badu**, orriak webgunea eguneratzean kargatutako azken datuak erakusten ditu, eta *Ez zuzenean* etiketarekin adierazten du.
- **Ordutegiak.** Ordu guztiak penintsulakoak dira (CET/CEST); Kanariak ordubete atzeratuta daude. 24 orduko grafikoak puntu bat erakusten du 15 minuturo.
- **Behin-behineko datuak.** Denbora errealeko neurketak dira, berrikusteko modukoak: REEk aste batzuk geroago finkatzen ditu. Serieen amaieran minutu batzuk falta daitezke edo, salbuespenez, sistema oso bat.
- **Mugakako banakapena.** REEren tresnak 2024 amaieratik baino ez du banatzen trukea herrialdeka; lehenago saldo osoa baino ez zuen ematen.

## Iturriak

| Erakundea | Datua | Esteka |
|:---|:---|:---|
| **Red Eléctrica (REE)** | Eskaria eta sorkuntza 5 minuturo sistemaka, isuri-faktoreak | [demanda.ree.es](https://demanda.ree.es/visiona/home) |
| **Red Eléctrica (REE)** | Spot merkatuaren prezioa eta PVPC (REData) | [apidatos.ree.es](https://www.ree.es/es/datos/apidatos) |
| **OMIE** | Iberiar eguneko merkatua | [omie.es](https://www.omie.es/) |

> Iturria: Red Eléctrica (REE). REEren denbora errealeko zerbitzuek ez dute dokumentazio publiko ofizialik, eta "dauden bezala" erabiltzen dira; aldatzen badira, orri hau aldi baterako zuzeneko daturik gabe gera daiteke.
