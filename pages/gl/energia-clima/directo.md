---
i18n_origen: c2c14381050a
title: O sistema eléctrico, agora
description: "O sistema eléctrico español en directo: demanda, mix de xeración, % renovable, intensidade de CO₂ e intercambios con Francia, Portugal, Marrocos, Andorra e Baleares cada 5 minutos."
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

# ⚡ O sistema eléctrico, agora

Canta electricidade se está a consumir neste momento en España, con que tecnoloxías se produce, canto CO₂ se emite por cada kWh e por onde entra e sae enerxía do país. Os datos son os que publica **Red Eléctrica (REE)**, o operador do sistema, cada **5 minutos**, e a páxina actualízase soa.

<DirectoSistemaElectrico fallback={electricidad_ultimas_24h} workerUrl={REE_DIRECTO_URL} />

Buscas os máximos históricos? Consulta os [récords do sistema eléctrico](/gl/energia-clima/records): a maior demanda, a maior porcentaxe renovable ou a menor intensidade de CO₂ nunca rexistrados.

---

## Que mostra cada dato

**Cinco sistemas eléctricos, non un.** España ten cinco sistemas xestionados por separado: o **peninsular**, o **balear**, o **canario** e os de **Ceuta** e **Melilla**, dous sistemas illados moi pequenos que funcionan con motores diésel e turbinas de gas. **España (total)** é a suma de todos que publica Red Eléctrica. A Península e Baleares están unidas por un cable submarino; Canarias está completamente illada e cada illa (ou parella de illas) funciona case como un sistema propio, por iso depende tanto do gasóleo e o fuel.

**Demanda (MW).** Potencia media que se consume no sistema durante o intervalo de 5 minutos, medida en barras de central (inclúe as perdas da rede, non o autoconsumo solar de tellados, que reduce a demanda que ve REE).

**Renovable (%).** Porcentaxe da xeración do sistema que procede de eólica, solar fotovoltaica, solar térmica, hidráulica (sen bombeo) e outras renovables (biomasa, biogás, residuos renovables). A turbinación de bombeo e as baterías non se contan como renovables porque só devolven enerxía almacenada antes.

**Intensidade de CO₂ (gCO₂/kWh).** Toneladas de CO₂ emitidas polas centrais do sistema nesa hora divididas entre a xeración total. Calcúlase multiplicando a produción de cada tecnoloxía fósil polo factor de emisión que publica REE para cada sistema (por exemplo, un ciclo combinado emite arredor de 370 g por kWh na Península, e un motor diésel en Canarias, uns 680 g). É unha intensidade **da produción**: non desconta as importacións nin suma as emisións da enerxía importada.

**Prezo.** España e Portugal forman o mercado ibérico (MIBEL), e **toda a Península é unha única zona de prezo**: non hai prezos rexionais como en Australia ou os Estados Unidos. Móstranse dous prezos:
- o **prezo do mercado maiorista (OMIE)** para o cuarto de hora actual (desde outubro de 2025 o mercado diario casa prezos cada 15 minutos), que é o que cobran os xeradores;
- o **PVPC** desta hora, a tarifa regulada para consumidores con menos de 10 kW, que inclúe ademais peaxes, cargos e outros custos.

Baleares e Canarias teñen un réxime económico especial e os seus consumidores pagan os mesmos prezos ca na Península.

## Que significan as frechas

Cada frecha é unha **interconexión** e o seu grosor é proporcional á potencia que a atravesa neste momento. En **azul**, España importa; en **vermello**, exporta. O número é o saldo neto desa fronteira en MW.

- **Francia**: dúas grandes ligazóns polos Pireneos (País Vasco–Aquitania e Cataluña–Rosellón), cuns 3.000 MW de capacidade. É a principal conexión co resto de Europa e adoita importar cando a nuclear francesa é barata e exportar nas horas de moito sol en España.
- **Portugal**: a fronteira máis mallada. Co MIBEL, o fluxo adoita seguir as diferenzas de produción renovable entre os dous países.
- **Marrocos**: dous cables submarinos polo Estreito. España é case sempre exportadora.
- **Andorra**: pequena liña pola que España abastece o Principado; o fluxo vai case sempre cara a Andorra.
- **Península–Baleares** (en violeta): o cable Sagunto–Santa Ponsa (400 MW), que adoita cubrir unha parte importante da demanda das illas, sobre todo de Mallorca.

O **saldo exterior** da Península suma todas as fronteiras internacionais: se é positivo, España está a importar.

## Metodoloxía

- **Datos en directo.** Un pequeno servizo propio (un *worker* en Cloudflare) consulta cada 5 minutos as curvas de demanda e xeración que REE publica para o seu visor de [demanda en tempo real](https://demanda.ree.es/visiona/peninsula/demandaqh/tablas/), os factores de emisión de cada sistema e os prezos de [REData](https://www.ree.es/es/datos/apidatos). As cifras normalízanse coas mesmas equivalencias de tecnoloxías que usa o resto de SpainFacts.
- **Se o servizo en directo non responde**, a páxina mostra os últimos datos que se cargaron ao actualizar o sitio e indícao coa etiqueta *Non en directo*.
- **Horarios.** Todas as horas son peninsulares (CET/CEST); Canarias vai unha hora por detrás. A gráfica de 24 horas móstrase cun punto cada 15 minutos.
- **Datos provisionais.** Son medidas en tempo real, suxeitas a revisión: REE consolídaas semanas despois. Poden faltar uns minutos ao final da serie ou, excepcionalmente, un sistema completo.
- **Desagregación por fronteiras.** O visor de REE só desagrega o intercambio por país desde finais de 2024; antes só daba o saldo total.

## Fontes

| Organismo | Dato | Ligazón |
|:---|:---|:---|
| **Red Eléctrica (REE)** | Demanda e xeración cada 5 minutos por sistema, factores de emisión | [demanda.ree.es](https://demanda.ree.es/visiona/home) |
| **Red Eléctrica (REE)** | Prezo do mercado spot e PVPC (REData) | [apidatos.ree.es](https://www.ree.es/es/datos/apidatos) |
| **OMIE** | Mercado diario ibérico | [omie.es](https://www.omie.es/) |

> Fonte: Red Eléctrica (REE). Os servizos de tempo real de REE non teñen unha documentación pública oficial e úsanse "tal cal"; se cambian, esta páxina pode quedar temporalmente sen datos en directo.
