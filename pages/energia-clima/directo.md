---
title: El sistema eléctrico, ahora
description: "El sistema eléctrico español en directo: demanda, mix de generación, % renovable, intensidad de CO₂ e intercambios con Francia, Portugal, Marruecos, Andorra y Baleares cada 5 minutos."
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import DirectoSistemaElectrico from '../../../../../../src/lib/components/DirectoSistemaElectrico.svelte';
    import { REE_DIRECTO_URL } from '../../../../../../src/lib/config/directo.js';
</script>

```sql electricidad_ultimas_24h
SELECT *
FROM mother.electricidad_ultimas_24h
ORDER BY sistema, ts_utc
```

# ⚡ El sistema eléctrico, ahora

Cuánta electricidad se está consumiendo en este momento en España, con qué tecnologías se produce, cuánto CO₂ se emite por cada kWh y por dónde entra y sale energía del país. Los datos son los que publica **Red Eléctrica (REE)**, el operador del sistema, cada **5 minutos**, y la página se actualiza sola.

<DirectoSistemaElectrico fallback={electricidad_ultimas_24h} workerUrl={REE_DIRECTO_URL} />

¿Buscas los máximos históricos? Consulta los [récords del sistema eléctrico](/energia-clima/records): la mayor demanda, el mayor porcentaje renovable o la menor intensidad de CO₂ jamás registrados.

---

## Qué muestra cada dato

**Tres sistemas eléctricos, no uno.** España tiene tres sistemas gestionados por separado: el **peninsular**, el **balear** y el **canario** (Ceuta y Melilla son otros dos sistemas aislados, muy pequeños, que no aparecen aquí). La Península y Baleares están unidas por un cable submarino; Canarias está completamente aislada y cada isla (o pareja de islas) funciona casi como un sistema propio, por eso depende tanto del gasóleo y el fuel.

**Demanda (MW).** Potencia media que se consume en el sistema durante el intervalo de 5 minutos, medida en barras de central (incluye las pérdidas de la red, no el autoconsumo solar de tejados, que reduce la demanda que ve REE).

**Renovable (%).** Porcentaje de la generación del sistema que procede de eólica, solar fotovoltaica, solar térmica, hidráulica (sin bombeo) y otras renovables (biomasa, biogás, residuos renovables). La turbinación de bombeo y las baterías no se cuentan como renovables porque solo devuelven energía almacenada antes.

**Intensidad de CO₂ (gCO₂/kWh).** Toneladas de CO₂ emitidas por las centrales del sistema en esa hora divididas entre la generación total. Se calcula multiplicando la producción de cada tecnología fósil por el factor de emisión que publica REE para cada sistema (por ejemplo, un ciclo combinado emite en torno a 370 g por kWh en la Península, y un motor diésel en Canarias, unos 680 g). Es una intensidad **de la producción**: no descuenta las importaciones ni suma las emisiones de la energía importada.

**Precio.** España y Portugal forman el mercado ibérico (MIBEL), y **toda la Península es una única zona de precio**: no hay precios regionales como en Australia o Estados Unidos. Se muestran dos precios:
- el **precio del mercado mayorista (OMIE)** para el cuarto de hora actual (desde octubre de 2025 el mercado diario casa precios cada 15 minutos), que es lo que cobran los generadores;
- el **PVPC** de esta hora, la tarifa regulada para consumidores con menos de 10 kW, que incluye además peajes, cargos y otros costes.

Baleares y Canarias tienen un régimen económico especial y sus consumidores pagan los mismos precios que en la Península.

## Qué significan las flechas

Cada flecha es una **interconexión** y su grosor es proporcional a la potencia que la atraviesa en este momento. En **azul**, España importa; en **rojo**, exporta. El número es el saldo neto de esa frontera en MW.

- **Francia**: dos grandes enlaces por los Pirineos (País Vasco–Aquitania y Cataluña–Rosellón), con unos 3.000 MW de capacidad. Es la principal conexión con el resto de Europa y suele importar cuando la nuclear francesa es barata y exportar en las horas de mucho sol en España.
- **Portugal**: la frontera más mallada. Con el MIBEL, el flujo suele seguir las diferencias de producción renovable entre los dos países.
- **Marruecos**: dos cables submarinos por el Estrecho. España es casi siempre exportadora.
- **Andorra**: pequeña línea por la que España abastece al Principado; el flujo va casi siempre hacia Andorra.
- **Península–Baleares** (en violeta): el cable Sagunto–Santa Ponsa (400 MW), que suele cubrir una parte importante de la demanda de las islas, sobre todo de Mallorca.

El **saldo exterior** de la Península suma todas las fronteras internacionales: si es positivo, España está importando.

## Metodología

- **Datos en directo.** Un pequeño servicio propio (un *worker* en Cloudflare) consulta cada 5 minutos las curvas de demanda y generación que REE publica para su visor de [demanda en tiempo real](https://demanda.ree.es/visiona/peninsula/demandaqh/tablas/), los factores de emisión de cada sistema y los precios de [REData](https://www.ree.es/es/datos/apidatos). Las cifras se normalizan con las mismas equivalencias de tecnologías que usa el resto de SpainFacts.
- **Si el servicio en directo no responde**, la página muestra los últimos datos que se cargaron al actualizar el sitio y lo indica con la etiqueta *No en directo*.
- **Horarios.** Todas las horas son peninsulares (CET/CEST); Canarias va una hora por detrás. El gráfico de 24 horas se muestra con un punto cada 15 minutos.
- **Datos provisionales.** Son medidas en tiempo real, sujetas a revisión: REE las consolida semanas después. Pueden faltar unos minutos al final de la serie o, excepcionalmente, un sistema completo.
- **Desglose por fronteras.** El visor de REE solo desglosa el intercambio por país desde finales de 2024; antes solo daba el saldo total.

## Fuentes

| Organismo | Dato | Enlace |
|:---|:---|:---|
| **Red Eléctrica (REE)** | Demanda y generación cada 5 minutos por sistema, factores de emisión | [demanda.ree.es](https://demanda.ree.es/visiona/home) |
| **Red Eléctrica (REE)** | Precio del mercado spot y PVPC (REData) | [apidatos.ree.es](https://www.ree.es/es/datos/apidatos) |
| **OMIE** | Mercado diario ibérico | [omie.es](https://www.omie.es/) |

> Fuente: Red Eléctrica (REE). Los servicios de tiempo real de REE no tienen una documentación pública oficial y se usan "tal cual"; si cambian, esta página puede quedarse temporalmente sin datos en directo.
