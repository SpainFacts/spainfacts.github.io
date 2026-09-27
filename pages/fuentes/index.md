---
title: Trazabilidad y Auditoría de Fuentes
---

<script>
    import { formatNumber } from '../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
</script>

# Trazabilidad y Auditoría de Fuentes Oficiales

En **SpainFacts**, cada dato, gráfico y cálculo es **100% verificable y trazable** hasta su publicación oficial original. No generamos estimaciones propias ni manipulamos las series: los datos provienen de organismos públicos y se extraen mediante pipelines automatizados y auditables.

```sql fuentes_list
SELECT
    fuente_id,
    organismo,
    nombre_dataset,
    cod_oficial,
    frecuencia,
    formato_ingesta,
    tipo_licencia,
    url_oficial,
    metodologia,
    estado_pipeline
FROM mother.trazabilidad_fuentes
ORDER BY organismo ASC, nombre_dataset ASC
```

```sql stats_organismos
SELECT
    count(distinct organismo) AS total_organismos,
    count(*) AS total_datasets
FROM mother.trazabilidad_fuentes
```

<Grid cols=4>
    <KpiCard
        title="Datasets Oficiales"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="fuentes activas"
        period="Catálogo actual"
        direction="neutral"
        source="MotherDuck"
    />

    <KpiCard
        title="Organismos Conectados"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="instituciones"
        period="INE, Eurostat, IGAE, BdE"
        direction="neutral"
        source="Catálogo Oficial"
    />

    <KpiCard
        title="Tipo de Licencia"
        value="100%"
        formattedValue="100%"
        unit="Datos Abiertos"
        period="Ley 37/2007 / CC-BY 4.0"
        direction="positive-up"
        source="Sector Público"
    />

    <KpiCard
        title="Sincronización"
        value="Diaria"
        formattedValue="Diaria"
        unit="Automática"
        period="06:00 Madrid (Dagster)"
        direction="positive-up"
        source="GitHub Actions"
    />
</Grid>

---

## 1. Directorio Completo de Fuentes y Datasets

A continuación se detallan todas las fuentes integradas en la base de datos de SpainFacts, incluyendo el código oficial del dataset, la frecuencia de publicación, la metodología y el enlace directo al portal emisor:

<DataTable data={fuentes_list} search=true rows=10>
    <Column id=organismo title="Organismo" />
    <Column id=nombre_dataset title="Nombre del Dataset" />
    <Column id=cod_oficial title="Código Oficial" />
    <Column id=frecuencia title="Frecuencia" />
    <Column id=formato_ingesta title="Formato API" />
    <Column id=tipo_licencia title="Licencia de Uso" />
    <Column id=url_oficial title="Fuente Oficial" contentType=link linkText="Ver en origen ↗" />
</DataTable>

---

## 2. Metodología de las Fuentes Oficiales

Cada organismo utiliza marcos estadísticos rigurosos y estandarizados a nivel nacional e internacional:

<Accordion>
  <AccordionItem title="Instituto Nacional de Estadística (INE)">
    <p><b>Marco legal y metodológico:</b> Regulado por la Ley de la Función Estadística Pública (Ley 12/1989). Todas las operaciones forman parte del Plan Estadístico Nacional.</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>IPC (Índice de Precios de Consumo):</b> Ponderación de una cesta de más de 400 artículos basada en la Encuesta de Presupuestos Familiares. Base 2021.</li>
      <li><b>EPA (Encuesta de Población Activa):</b> Muestreo trimestral sobre 65.000 hogares (aprox. 160.000 personas) siguiendo las directrices de la Organización Internacional del Trabajo (OIT).</li>
      <li><b>Padrón Continuo:</b> Registro administrativo consolidado a 1 de enero con la información remitida por los 8.131 ayuntamientos de España.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="Eurostat (Oficina Estadística de la Unión Europea)">
    <p><b>Marco legal y metodológico:</b> Estadísticas armonizadas según el Sistema Europeo de Cuentas Nacionales y Regionales (SEC 2010).</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>Cuentas de las Administraciones Públicas (gov_10a_main):</b> Registro de operaciones no financieras de ingresos y gastos de los estados miembros de la UE.</li>
      <li><b>Clasificación Funcional COFOG (gov_10a_exp):</b> Desglose del gasto público en 10 divisiones funcionales acordadas internacionalmente por la ONU y la OCDE.</li>
      <li><b>Deuda según el PDE (gov_10q_ggdebt):</b> Deuda bruta consolidada de las AAPP valorada a valor nominal según el Protocolo de Déficit Excesivo del Tratado de Maastricht.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="Intervención General de la Administración del Estado (IGAE)">
    <p><b>Marco legal y metodológico:</b> Órgano de control interno del sector público estatal y centro gestor de la contabilidad pública, dependiente del Ministerio de Hacienda.</p>
    <p class="mt-1">Publica mensualmente la ejecución presupuestaria de la Administración Central, Comunidades Autónomas, Seguridad Social y Corporaciones Locales.</p>
  </AccordionItem>

  <AccordionItem title="Banco de España (BdE)">
    <p><b>Marco legal y metodológico:</b> Integrado en el Sistema Europeo de Bancos Centrales (SEBC). Responsable de la elaboración de las Cuentas Financieras de la economía española y la deuda pública por instrumentos y plazos.</p>
  </AccordionItem>
</Accordion>

---

## 3. Garantía de Calidad y No Manipulación

SpainFacts aplica un estricto protocolo de integridad técnica:

1. **Ingesta Idempotente:** Los scripts de Python ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)) descargan las respuestas directas de las APIs públicas sin modificar los valores numéricos.
2. **Validación Automática con dbt (`dbt test`):** Cada transformación pasa tests automáticos de valores no nulos, unicidad y coherencia de fechas. Si una fuente externa devuelve datos corruptos, el despliegue se detiene automáticamente.
3. **Código 100% Abierto:** Toda la infraestructura, consultas SQL y modelos de transformación están disponibles públicamente en [GitHub](https://github.com/SpainFacts/spainfacts.github.io).

<LastRefreshed prefix="Catálogo de fuentes verificado" />
