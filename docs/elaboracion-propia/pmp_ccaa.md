# Pagar a proveedores en 30 días (PMP de comunidades, diputaciones y cabildos)

**Elaboración propia.** Indicadores `pmp_ccaa` (comunidades autónomas, mensual) y `pmp_entidades_locales` (diputaciones provinciales y forales, cabildos y consells insulares, trimestral).

## Bloque aparte: esto mide pagar, no publicar

El periodo medio de pago (PMP) mide **cuántos días tarda una administración en pagar sus facturas**, no si publica o remite información: las 17 comunidades comunican su PMP todos los meses y casi todas las diputaciones cada trimestre. Por eso va en un **bloque separado** del índice de remisión (`x_bloque = 'pagar'`). El modelo común no debe mezclarlo con las obligaciones de transparencia; si lo muestra, como «pagar a tiempo».

Los ayuntamientos ya están en `transparencia_pmp` (comunicación trimestral y PMP por encima de 30 días) y no se duplican aquí.

## Base legal

- **Plazo máximo de pago: 30 días** desde la conformidad de la factura: art. 4 de la Ley 3/2004 de medidas contra la morosidad y art. 198.4 de la Ley 9/2017 de Contratos del Sector Público.
- **Arts. 4.2 y 13.6 de la LO 2/2012 de Estabilidad Presupuestaria y Sostenibilidad Financiera** (redacción de la LO 9/2013, de control de la deuda comercial): hay sostenibilidad de la deuda comercial cuando el PMP «no supere el plazo máximo previsto en la normativa sobre morosidad»; las administraciones publican su PMP y, si lo superan, adoptan medidas (art. 13.6) y se activan las del art. 18.5.
- **RD 635/2014** (metodología de cálculo y publicación), modificado por el **RD 1040/2017**: desde abril de 2018 el PMP se cuenta desde la aprobación de la factura (antes descontaba 30 días y podía ser negativo). Solo se compara desde entonces.
- Entidades locales: comunicación trimestral (mensual en el modelo de cesión) antes del último día del mes siguiente, art. 16.8 de la Orden HAP/2105/2012.

## Fuente

- Comunidades: Central de Información de Hacienda, «Periodo medio de pago de las AAPP» (`https://www.hacienda.gob.es/es-es/cdi/paginas/periodomediopago/informacionaapps/pmpdelasaapp.aspx`), libro de series **`pmp-series-rd-1040-2017.xlsx`**, tablas 4.1-4.5 (ratio de operaciones pagadas, importe pagado, ratio de operaciones pendientes, importe pendiente y PMP) por comunidad y mes, abril 2018 → último mes publicado. Comprobado: Illes Balears, noviembre de 2025 = 55,78 días, la cifra que dio Hacienda en su nota de prensa.
- **Atención**: el `fichero1` de PMP_NET (`descarga.aspx?…&fichero=fichero1`) **no** es el de las comunidades, sino el informe mensual de las entidades locales del modelo de cesión. Lo comprobamos el 25-oct-2026.
- Diputaciones y cabildos: PMP_NET, `fichero2` trimestral (`raw.pmp_entidades`, tipo DD), ya cargado por `ingestion/hacienda_transparencia.py`.

## Cómo se calcula

| Estado | Regla |
|---|---|
| `fuera_plazo` | PMP del periodo > 30 días; `dias_retraso` = PMP − 30, redondeado |
| `en_plazo` | PMP ≤ 30 días (`dias_retraso` = 0) |
| `no_consta` | la entidad no figura en la publicación del periodo (en entidades locales: no lo ha comunicado) |
| `no_aplica` | ver exclusiones |

`periodo` = `AAAA-MM` (comunidades) o `AAAAT` + trimestre (entidades locales). `fecha_plazo` = último día del mes medido (comunidades) o del mes siguiente al trimestre (plazo de comunicación de las entidades locales). El PMP bruto va en `x_pmp_dias`.

## Universo y exclusiones

- 17 comunidades + Ceuta y Melilla. **Ceuta y Melilla → `no_aplica`**: comunican su PMP como entidad local (PMP_NET, tipo ZZ), no en la serie de comunidades.
- 41 diputaciones (38 provinciales, 3 forales) y 11 cabildos y consells. Las diputaciones forales comunican su PMP a PMP_NET todos los trimestres desde 2018, así que se incluyen. **Consell de Formentera → `no_aplica`**: comunica como ayuntamiento (07024, en `transparencia_pmp`).
- Desde 2018T2 / abril de 2018.

## Limitaciones

- El PMP es una media ponderada por importe: una comunidad puede pagar a tiempo casi todo y tardar mucho en unas pocas facturas grandes, o al revés.
- La cabecera del libro de Hacienda dice «miles €», pero las magnitudes son euros (Andalucía paga unos 600 millones al mes): se guardan tal cual en `x_importe_*`.
- Hacienda excluye del cálculo los PMP «anormales o desproporcionados» de algunas entidades.

## Código

- Ingesta: `ingestion/pa_registros.py`, recurso `pmp_ccaa` (source `pa_registros`); `ingestion/hacienda_transparencia.py`, recurso `pmp_entidades`.
- Modelos: `transform/models/marts/pa_ind_pmp_ccaa.sql` y `pa_ind_pmp_entidades_locales.sql`; pruebas en `schema_pa_registros.yml`.
