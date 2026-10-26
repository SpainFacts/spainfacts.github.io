---
description: "Catálogo de las fuentes oficiales que usa SpainFacts (INE, Eurostat, ministerios, REE...), con su metodología, licencia y el código en GitHub para reconstruir cada dato."
title: Trazabilidad y Auditoría de Fuentes
og:
  image: https://spainfacts.org/og-spainfacts.png
---

<script>
    import KpiCard from '../../../../../src/lib/components/KpiCard.svelte';
    import CatalogoFuentes from '../../../../../src/lib/components/CatalogoFuentes.svelte';
</script>

# Trazabilidad y Auditoría de Fuentes Oficiales

En **SpainFacts** cada dato, gráfico y cálculo se puede seguir hasta su publicación oficial original. No inventamos cifras: descargamos los datos de organismos públicos con código abierto y cualquiera puede repetir el proceso por su cuenta. Las etiquetas de fuente de las tarjetas de toda la web enlazan aquí, a la ficha de su fuente.

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
        title="Conjuntos de datos"
        value={stats_organismos[0].total_datasets}
        formattedValue="{stats_organismos[0].total_datasets}"
        unit="en el catálogo"
        period="Cada uno con su ficha y su código"
        direction="neutral"
    />

    <KpiCard
        title="Organismos"
        value={stats_organismos[0].total_organismos}
        formattedValue="{stats_organismos[0].total_organismos}"
        unit="fuentes oficiales"
        period="INE, Eurostat, ministerios, REE…"
        direction="neutral"
    />
</Grid>

## Cómo reconstruir un dato

Todo el proceso está en el [repositorio público de GitHub](https://github.com/SpainFacts/spainfacts.github.io). Cada dato pasa por cinco pasos y cada paso es un fichero que se puede leer:

1. **Descarga del organismo.** Los datos salen del portal oficial (el enlace «Ver en origen» de cada ficha).
2. **Ingesta** ([`ingestion/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/ingestion)). Scripts de Python con [dlt](https://dlthub.com) que llaman a la API o descargan el fichero y lo guardan tal cual en el esquema `raw`, sin tocar los valores.
3. **Transformación** ([`transform/models/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/models)). Modelos SQL de [dbt](https://www.getdbt.com) que limpian, unen y calculan (por habitante, en euros constantes…). Los datos hechos a mano, como este catálogo, están en [`transform/seeds/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/transform/seeds).
4. **Consultas de la web** ([`sources/mother/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/sources/mother)). Lo que lee cada página.
5. **Página** ([`pages/`](https://github.com/SpainFacts/spainfacts.github.io/tree/main/pages)). El texto, el SQL de cada gráfico y los cálculos finales.

Abre cualquier conjunto de datos del catálogo para ver su script, sus tablas, sus modelos dbt y las páginas que lo usan, con los comandos para repetirlo.

### Repetirlo en tu ordenador

No hace falta ninguna cuenta: todo funciona contra un fichero DuckDB local. Necesitas [Python con uv](https://docs.astral.sh/uv/), [Node.js](https://nodejs.org) y git.

```bash
git clone https://github.com/SpainFacts/spainfacts.github.io.git
cd spainfacts.github.io
uv venv
uv pip install -r orchestration/requirements.txt

# escribir en data/spainfacts.duckdb en vez de en la base de producción
export SPAINFACTS_DESTINO=local

# un script de ingesta (el de cada ficha) y sus modelos dbt
uv run python -m ingestion.aena
uv run dbt build --project-dir transform --profiles-dir transform --select movilidad_aeropuertos_mensual+

# o toda la cadena de una vez
uv run dagster asset materialize -m orchestration.definitions --select "*"
```

La guía completa, con la web en local, está en [docs/desarrollo-local.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/desarrollo-local.md), y cómo se añade una fuente nueva en [docs/GUIA_INGESTA_Y_METRICAS.md](https://github.com/SpainFacts/spainfacts.github.io/blob/main/docs/GUIA_INGESTA_Y_METRICAS.md).

```sql propia
SELECT *,
    'https://github.com/SpainFacts/spainfacts.github.io/blob/main/' || codigo_ingesta AS url_ingesta,
    'https://github.com/SpainFacts/spainfacts.github.io/blob/main/' || modelo AS url_modelo,
    'https://github.com/SpainFacts/spainfacts.github.io/blob/main/' || criterios AS url_criterios
FROM mother.elaboracion_propia_indicadores
ORDER BY bloque, nombre
```

## Datos de elaboración propia

Algunos datos no los publica nadie, así que **los medimos nosotros**. El principal es el [índice de publicidad activa](/transparencia/publicidad-activa#medición-propia-todas-las-administraciones). Casi ningún órgano de control dice, entidad por entidad, si cada ayuntamiento, diputación o comunidad publica y remite a tiempo lo que le obliga la ley. Así que lo comprobamos en los registros oficiales que traen fecha: Hacienda, Tribunal de Cuentas, Base de Datos Nacional de Subvenciones, Plataforma de Contratación…

Una medición propia tiene que poder auditarse aún más que un dato oficial. Por eso cada indicador publica su base legal, su plazo, cómo se calcula, qué se excluye y por qué, y enlaza a su código:

- **Solo registros oficiales.** Si algo no consta en el registro, se dice «no consta en [fuente]», nunca «no lo ha hecho»: puede haberse remitido por otro cauce.
- **Todas las entidades.** Quien no aparece en la fuente cuenta como «no consta», salvo que la fuente no lo mida. Por ejemplo, los territorios forales que remiten por su propio cauce no cuentan como incumplidores.
- **Atribución al gobierno del día del plazo**, no al actual.
- **Comparación con las de su tamaño**, en España y en su provincia.
- **Errores**: si ves uno, [abre una incidencia](https://github.com/SpainFacts/spainfacts.github.io/issues) con el enlace a la fuente. Lo corregimos y lo dejamos anotado.

El método completo está en [docs/elaboracion-propia](https://github.com/SpainFacts/spainfacts.github.io/tree/main/docs/elaboracion-propia).

{#each [...new Set(propia.map(d => d.bloque))] as bloque}
<h3 class="mt-6 mb-2 text-lg font-semibold">{bloque}</h3>
{#each propia.filter(d => d.bloque === bloque) as d}
<details class="my-2 rounded-lg border border-gray-200 dark:border-gray-800 p-3 text-sm">
<summary class="cursor-pointer font-semibold">{d.nombre} <span class="font-normal text-gray-500">· {d.tipos_entidad}{d.en_indice ? '' : ' · informativo, fuera del índice'}</span></summary>
<dl class="mt-2 grid grid-cols-1 sm:grid-cols-[10rem_1fr] gap-x-3 gap-y-1">
<dt class="text-gray-500">Qué mide</dt><dd>{d.que_mide}</dd>
<dt class="text-gray-500">Base legal</dt><dd>{d.base_legal}</dd>
<dt class="text-gray-500">Plazo</dt><dd>{d.plazo}</dd>
<dt class="text-gray-500">Cálculo</dt><dd>{d.calculo}</dd>
<dt class="text-gray-500">Exclusiones</dt><dd>{d.exclusiones}</dd>
<dt class="text-gray-500">Fuente oficial</dt><dd><a href={d.url_fuente} target="_blank" rel="noopener">{d.fuente_oficial} ↗</a></dd>
<dt class="text-gray-500">Código</dt><dd><a href={d.url_ingesta} target="_blank" rel="noopener">ingesta</a> · <a href={d.url_modelo} target="_blank" rel="noopener">cálculo</a> · <a href={d.url_criterios} target="_blank" rel="noopener">criterios</a></dd>
</dl>
</details>
{/each}
{/each}

## Catálogo de fuentes

Busca por organismo, nombre, código oficial o palabras de la metodología. Cada ficha tiene enlace propio para compartirla.

<CatalogoFuentes data={fuentes_list} />

## Marco de los principales organismos

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

## Garantías de calidad

1. **Los valores no se tocan al cargarlos.** Los scripts de ingesta guardan la respuesta del organismo tal cual; los cálculos (por habitante, deflactados…) se hacen después, en SQL a la vista.
2. **Tests en cada actualización.** La cadena se actualiza sola cada día a las 06:00 (hora de Madrid) con [Dagster](https://dagster.io). Los modelos dbt llevan tests de valores no nulos, unicidad y coherencia de fechas; si fallan, la actualización se detiene antes de publicar.
3. **Pruebas de la web.** Antes de cada publicación, unas pruebas automáticas abren las páginas y comprueban que cargan y muestran datos.
4. **Código abierto.** Ingesta, transformaciones, consultas y páginas están en [GitHub](https://github.com/SpainFacts/spainfacts.github.io). Si ves un error, puedes [abrir una incidencia](https://github.com/SpainFacts/spainfacts.github.io/issues).

<LastRefreshed prefix="Catálogo de fuentes verificado" />
