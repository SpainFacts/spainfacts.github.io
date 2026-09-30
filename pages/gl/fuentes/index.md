---
description: "Catálogo das fontes oficiais que usa SpainFacts (INE, Eurostat, ministerios, REE...), coa súa frecuencia, licenza e metodoloxía."
title: Trazabilidade e Auditoría de Fontes
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: 238721c8a7b0
---

<script>
    import { formatNumber } from '../../../../../../src/lib/utils.js';
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
</script>

# Trazabilidade e Auditoría de Fontes Oficiais

En **SpainFacts**, cada dato, gráfico e cálculo é **100% verificable e trazable** ata a súa publicación oficial orixinal. Non xeramos estimacións propias nin manipulamos as series: os datos proveñen de organismos públicos e extráense mediante pipelines automatizados e auditables.

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
        title="Datasets Oficiais"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="fontes activas"
        period="Catálogo actual"
        direction="neutral"
        source="MotherDuck"
    />

    <KpiCard
        title="Organismos Conectados"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="institucións"
        period="INE, Eurostat, IGAE, BdE"
        direction="neutral"
        source="Catálogo Oficial"
    />

    <KpiCard
        title="Tipo de Licenza"
        value="100%"
        formattedValue="100%"
        unit="Datos Abertos"
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

## 1. Directorio Completo de Fontes e Datasets

A continuación detállanse todas as fontes integradas na base de datos de SpainFacts, incluído o código oficial do dataset, a frecuencia de publicación, a metodoloxía e a ligazón directa ao portal emisor:

<DataTable data={fuentes_list} search=true rows=10>
    <Column id=organismo title="Organismo" />
    <Column id=nombre_dataset title="Nome do Dataset" />
    <Column id=cod_oficial title="Código Oficial" />
    <Column id=frecuencia title="Frecuencia" />
    <Column id=formato_ingesta title="Formato API" />
    <Column id=tipo_licencia title="Licenza de Uso" />
    <Column id=url_oficial title="Fonte Oficial" contentType=link linkText="Ver na orixe ↗" />
</DataTable>

---

## 2. Metodoloxía das Fontes Oficiais

Cada organismo utiliza marcos estatísticos rigorosos e estandarizados a nivel nacional e internacional:

<Accordion>
  <AccordionItem title="Instituto Nacional de Estatística (INE)">
    <p><b>Marco legal e metodolóxico:</b> Regulado pola Lei da Función Estatística Pública (Lei 12/1989). Todas as operacións forman parte do Plan Estatístico Nacional.</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>IPC (Índice de Prezos de Consumo):</b> Ponderación dunha cesta de máis de 400 artigos baseada na Enquisa de Orzamentos Familiares. Base 2021.</li>
      <li><b>EPA (Enquisa de Poboación Activa):</b> Mostraxe trimestral sobre 65.000 fogares (aprox. 160.000 persoas) seguindo as directrices da Organización Internacional do Traballo (OIT).</li>
      <li><b>Padrón Continuo:</b> Rexistro administrativo consolidado a 1 de xaneiro coa información remitida polos 8.131 concellos de España.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="Eurostat (Oficina Estatística da Unión Europea)">
    <p><b>Marco legal e metodolóxico:</b> Estatísticas harmonizadas segundo o Sistema Europeo de Contas Nacionais e Rexionais (SEC 2010).</p>
    <ul class="list-disc pl-5 mt-2 space-y-1">
      <li><b>Contas das Administracións Públicas (gov_10a_main):</b> Rexistro de operacións non financeiras de ingresos e gastos dos estados membros da UE.</li>
      <li><b>Clasificación Funcional COFOG (gov_10a_exp):</b> Desagregación do gasto público en 10 divisións funcionais acordadas internacionalmente pola ONU e a OCDE.</li>
      <li><b>Débeda segundo o PDE (gov_10q_ggdebt):</b> Débeda bruta consolidada das AAPP valorada a valor nominal segundo o Protocolo de Déficit Excesivo do Tratado de Maastricht.</li>
    </ul>
  </AccordionItem>

  <AccordionItem title="Intervención Xeral da Administración do Estado (IGAE)">
    <p><b>Marco legal e metodolóxico:</b> Órgano de control interno do sector público estatal e centro xestor da contabilidade pública, dependente do Ministerio de Facenda.</p>
    <p class="mt-1">Publica mensualmente a execución orzamentaria da Administración Central, comunidades autónomas, Seguridade Social e corporacións locais.</p>
  </AccordionItem>

  <AccordionItem title="Banco de España (BdE)">
    <p><b>Marco legal e metodolóxico:</b> Integrado no Sistema Europeo de Bancos Centrais (SEBC). Responsable da elaboración das Contas Financeiras da economía española e da débeda pública por instrumentos e prazos.</p>
  </AccordionItem>
</Accordion>

---

## 3. Garantía de Calidade e Non Manipulación

SpainFacts aplica un estrito protocolo de integridade técnica:

1. **Inxestión Idempotente:** Os scripts de Python ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)) descargan as respostas directas das API públicas sen modificar os valores numéricos.
2. **Validación Automática con dbt (`dbt test`):** Cada transformación pasa tests automáticos de valores non nulos, unicidade e coherencia de datas. Se unha fonte externa devolve datos corruptos, o despregamento detense automaticamente.
3. **Código 100% Aberto:** Toda a infraestrutura, consultas SQL e modelos de transformación están dispoñibles publicamente en [GitHub](https://github.com/SpainFacts/spainfacts.github.io).

<LastRefreshed prefix="Catálogo de fontes verificado" />
