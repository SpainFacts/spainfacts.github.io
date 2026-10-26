---
description: "Catálogo das fontes oficiais que usa SpainFacts (INE, Eurostat, ministerios, REE...), coa súa metodoloxía, licenza e o código en GitHub para reconstruír cada dato."
title: Trazabilidade e Auditoría de Fontes
og:
  image: https://spainfacts.org/og-spainfacts.png
i18n_origen: a1d2b13b67a4
---

<script>
    import KpiCard from '../../../../../../src/lib/components/KpiCard.svelte';
    import CatalogoFuentes from '../../../../../../src/lib/components/CatalogoFuentes.svelte';
</script>

# Trazabilidade e Auditoría de Fontes Oficiais

En **SpainFacts** cada dato, gráfico e cálculo pódese seguir ata a súa publicación oficial orixinal. Non inventamos cifras: descargamos os datos de organismos públicos con código aberto e calquera pode repetir o proceso pola súa conta. As etiquetas de fonte das tarxetas de toda a web ligan aquí, á ficha da súa fonte.

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
    metodologia
FROM mother.trazabilidad_fuentes
ORDER BY organismo ASC, nombre_dataset ASC
```

```sql stats_organismos
SELECT
    count(distinct organismo) AS total_organismos,
    count(*) AS total_datasets
FROM mother.trazabilidad_fuentes
```

<Grid cols=2>
    <KpiCard
        title="Conxuntos de datos"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="no catálogo"
        period="Cada un coa súa ficha e o seu código"
        direction="neutral"
    />

    <KpiCard
        title="Organismos"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="fontes oficiais"
        period="INE, Eurostat, ministerios, REE…"
        direction="neutral"
    />
</Grid>

## Como reconstruír un dato

Todo o proceso está no [repositorio público de GitHub](https://github.com/SpainFacts/spainfacts.github.io). Cada dato pasa por cinco pasos e cada paso é un ficheiro que se pode ler:

1. **Descarga do organismo.** Os datos saen do portal oficial (a ligazón «Ver na orixe» de cada ficha).
2. **Inxestión** ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)). Scripts de Python con [dlt](https://dlthub.com) que chaman á API ou descargan o ficheiro e gárdano tal cal no esquema `raw`, sen tocar os valores.
3. **Transformación** ([`transform/models/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/models)). Modelos SQL de [dbt](https://www.getdbt.com) que limpan, unen e calculan (por habitante, en euros constantes…). Os datos feitos a man, como este catálogo, están en [`transform/seeds/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/seeds).
4. **Consultas da web** ([`sources/mother/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/sources/mother)). O que le cada páxina.
5. **Páxina** ([`pages/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/pages)). O texto, o SQL de cada gráfico e os cálculos finais.

Abre calquera conxunto de datos do catálogo para ver o seu script, as súas táboas, os seus modelos dbt e as páxinas que o usan, cos comandos para repetilo.

### Repetilo no teu ordenador

Non fai falta ningunha conta: todo funciona contra un ficheiro DuckDB local. Necesitas [Python con uv](https://docs.astral.sh/uv/), [Node.js](https://nodejs.org) e git.

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io.git
cd spainfacts.github.io
uv venv
uv pip install -r orchestration/requirements.txt

# escribir en data/spainfacts.duckdb en vez de na base de produción
export SPAINFACTS_DESTINO=local

# un script de inxestión (o de cada ficha) e os seus modelos dbt
uv run python -m ingestion.aena
uv run dbt build --project-dir transform --profiles-dir transform --select movilidad_aeropuertos_mensual+

# ou toda a cadea dunha vez
uv run dagster asset materialize -m orchestration.definitions --select "*"
```

A guía completa, coa web en local, está en [docs/desarrollo-local.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/desarrollo-local.md), e como se engade unha fonte nova en [docs/GUIA_INGESTA_Y_METRICAS.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/GUIA_INGESTA_Y_METRICAS.md).

```sql propia
SELECT *,
    'https://github.com/SpainFacts/spainfacts.github.io/blob/main/' || codigo_ingesta AS url_ingesta,
    'https://github.com/SpainFacts/spainfacts.github.io/blob/main/' || modelo AS url_modelo,
    'https://github.com/SpainFacts/spainfacts.github.io/blob/main/' || criterios AS url_criterios
FROM mother.elaboracion_propia_indicadores
ORDER BY bloque, nombre
```

## Datos de elaboración propia

Algúns datos non os publica ninguén, así que **medímolos nós**. O principal é o [índice de publicidade activa](/gl/transparencia/publicidad-activa#medición-propia-todas-as-administracións). Case ningún órgano de control di, entidade por entidade, se cada concello, deputación ou comunidade publica e remite a tempo o que lle obriga a lei. Así que o comprobamos nos rexistros oficiais que levan data: Facenda, Tribunal de Contas, Base de Datos Nacional de Subvencións, Plataforma de Contratación…

Unha medición propia ten que poder auditarse aínda máis ca un dato oficial. Por iso cada indicador publica a súa base legal, o seu prazo, como se calcula, que se exclúe e por que, e enlaza ao seu código:

- **Só rexistros oficiais.** Se algo non consta no rexistro, dise «non consta en [fonte]», nunca «non o fixo»: pode terse remitido por outra canle.
- **Todas as entidades.** Quen non aparece na fonte conta como «non consta», agás que a fonte non o mida. Por exemplo, os territorios forais que remiten pola súa propia canle non contan como incumpridores.
- **Atribución ao goberno do día do prazo**, non ao actual.
- **Comparación coas do seu tamaño**, en España e na súa provincia.
- **Erros**: se ves un, [abre unha incidencia](https://github.com/SpainFacts/spainfacts.github.io/issues) coa ligazón á fonte. Corrixímolo e deixámolo anotado.

O método completo está en [docs/elaboracion-propia](https://github.com/SpainFacts/spainfacts.github.io/tree/main/docs/elaboracion-propia).

{#each [...new Set(propia.map(d => d.bloque))] as bloque}
<h3 class="mt-6 mb-2 text-lg font-semibold">{bloque}</h3>
{#each propia.filter(d => d.bloque === bloque) as d}
<details class="my-2 rounded-lg border border-gray-200 dark:border-gray-800 p-3 text-sm">
<summary class="cursor-pointer font-semibold">{d.nombre} <span class="font-normal text-gray-500">· {d.tipos_entidad}{d.en_indice ? '' : ' · informativo, fóra do índice'}</span></summary>
<dl class="mt-2 grid grid-cols-1 sm:grid-cols-[10rem_1fr] gap-x-3 gap-y-1">
<dt class="text-gray-500">Que mide</dt><dd>{d.que_mide}</dd>
<dt class="text-gray-500">Base legal</dt><dd>{d.base_legal}</dd>
<dt class="text-gray-500">Prazo</dt><dd>{d.plazo}</dd>
<dt class="text-gray-500">Cálculo</dt><dd>{d.calculo}</dd>
<dt class="text-gray-500">Exclusións</dt><dd>{d.exclusiones}</dd>
<dt class="text-gray-500">Fonte oficial</dt><dd><a href={d.url_fuente} target="_blank" rel="noopener">{d.fuente_oficial} ↗</a></dd>
<dt class="text-gray-500">Código</dt><dd><a href={d.url_ingesta} target="_blank" rel="noopener">inxestión</a> · <a href={d.url_modelo} target="_blank" rel="noopener">cálculo</a> · <a href={d.url_criterios} target="_blank" rel="noopener">criterios</a></dd>
</dl>
</details>
{/each}
{/each}

## Catálogo de fontes

Busca por organismo, nome, código oficial ou palabras da metodoloxía. Cada ficha ten ligazón propia para compartila.

<CatalogoFuentes data={fuentes_list} />

## Marco dos principais organismos

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

## Garantías de calidade

1. **Os valores non se tocan ao cargalos.** Os scripts de inxestión gardan a resposta do organismo tal cal; os cálculos (por habitante, deflactados…) fanse despois, en SQL á vista.
2. **Tests en cada actualización.** A cadea actualízase soa cada día ás 06:00 (hora de Madrid) con [Dagster](https://dagster.io). Os modelos dbt levan tests de valores non nulos, unicidade e coherencia de datas; se fallan, a actualización detense antes de publicar.
3. **Probas da web.** Antes de cada publicación, unhas probas automáticas abren as páxinas e comproban que cargan e amosan datos.
4. **Código aberto.** Inxestión, transformacións, consultas e páxinas están en [GitHub](https://github.com/SpainFacts/spainfacts.github.io). Se ves un erro, podes [abrir unha incidencia](https://github.com/SpainFacts/spainfacts.github.io/issues).

<LastRefreshed prefix="Catálogo de fontes verificado" />
