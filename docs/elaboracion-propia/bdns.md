# Subvenciones registradas en la BDNS a tiempo

**Elaboración propia de SpainFacts.** Indicador `bdns_concesiones` del [índice de publicidad activa](indice.md). Mide, para cada ayuntamiento, diputación, cabildo o consell insular y comunidad autónoma, cuántas de las subvenciones que concede cada año se registran en la Base de Datos Nacional de Subvenciones (BDNS) después del plazo legal, y cuántos días tarda en registrarlas.

## Qué se mide

Por entidad y año natural de concesión:

- **n_total**: concesiones de subvenciones y ayudas con fecha de concesión en el año, de todos los órganos concedentes de la entidad.
- **n_fuera_plazo**: de ellas, las registradas en la BDNS después del último día del mes siguiente al de la concesión.
- **mediana_dias**: mediana de los días entre la fecha de concesión y la fecha de alta en la BDNS.
- **x_n_convocatorias**: convocatorias que la entidad registró en la BDNS ese año (fecha de recepción). Sirve para leer los casos sin concesiones.
- También el percentil 90 de los días (`x_p90_dias`), las concesiones a personas físicas, el importe concedido (en euros corrientes y por habitante, solo de contexto) y el número de órganos que conceden.

## Base legal

- **Art. 5.2.b del Real Decreto 130/2019** ([BOE-A-2019-4671](https://www.boe.es/buscar/act.php?id=BOE-A-2019-4671)): las concesiones (y los pagos, reintegros y sanciones) se remiten a la BDNS «antes de que finalice el mes siguiente al de su producción».
- **Art. 20 de la Ley 38/2003, General de Subvenciones**: obligación de las administraciones de suministrar a la BDNS la información de las subvenciones que conceden.
- Art. 4.1.a del RD 130/2019: no hay que remitir las concesiones de 100 euros o menos al año al mismo beneficiario.
- Art. 7.8 del RD 130/2019: la información se publica durante los cuatro años naturales siguientes; la de personas físicas, solo el año de concesión y el siguiente.

## Fuente

Sistema Nacional de Publicidad de Subvenciones y Ayudas Públicas (SNPSAP), Intervención General de la Administración del Estado. API REST pública, sin clave: [infosubvenciones.es/bdnstrans/api](https://www.infosubvenciones.es/bdnstrans/api/) ([especificación](https://www.infosubvenciones.es/bdnstrans/estaticos/doc/snpsap-api.json)).

- `/concesiones/busqueda`, con `tipoAdministracion` = `L` (entidades locales) o `A` (comunidades autónomas) y la fecha de concesión de cada mes. Cada concesión trae `fechaConcesion`, `fechaAlta` (alta en la BDNS) y los nombres del órgano concedente (`nivel1`, `nivel2`, `nivel3`).
- `/convocatorias/busqueda`, con los mismos filtros y la fecha de recepción.
- `/organos` y `/organos/agrupacion`: árbol de órganos concedentes, con el código INE de cada municipio (6 cifras con dígito de control) o de cada comunidad.

Las concesiones no se guardan una a una ni se guarda ningún beneficiario: se agregan al descargarlas por órgano y mes.

## Cómo se calcula

Para cada concesión:

```
plazo        = último día del mes siguiente al de fechaConcesion
fuera_plazo  = fechaAlta > plazo
dias         = fechaAlta − fechaConcesion
```

Una concesión del 3 de marzo tiene de plazo hasta el 30 de abril; una del 31 de marzo, también.

Por entidad y año se suman las concesiones de **todos los órganos del nodo** de la BDNS: el ayuntamiento con sus áreas, distritos, organismos autónomos, fundaciones y sociedades municipales; la diputación con sus organismos y consorcios adscritos; la comunidad con todas sus consejerías y entes. La mediana es exacta: se calcula sobre el histograma de días de todas las concesiones.

**Estado** (año `periodo`, plazo del último elemento = 31 de enero del año siguiente):

| Estado | Cuándo |
|---|---|
| `con_registros` | La entidad tiene al menos una concesión registrada ese año. El modelo común convierte `n_fuera_plazo / n_total` en puntuación |
| `sin_registros` | Ninguna concesión registrada ese año. **No es por sí mismo un incumplimiento**: la entidad puede no conceder subvenciones, o concedérselas la diputación. `x_n_convocatorias` indica si la entidad sí convocó subvenciones ese año |
| `no_vencido` | Año en curso, o año cuyo último plazo (31 de enero siguiente) aún no había pasado el día de la medición |
| `no_aplica` | La fuente no mide a la entidad (ver exclusiones) |

## Universo

Todas las entidades de cada tipo, aparezcan o no en la BDNS:

- **Ayuntamientos**: todos los municipios del padrón del año (`poblacion_municipios`), sin Ceuta ni Melilla. Código `cod_mun` INE.
- **Diputaciones**: las 38 provinciales y las 3 forales (Álava, Bizkaia, Gipuzkoa). Código `D` + provincia.
- **Cabildos y consells insulares**: los 7 cabildos canarios y los consells de Mallorca, Menorca, Eivissa y Formentera. Código `I` + provincia + ordinal del DIR3 (L03380011 → `I38011`).
- **Comunidades autónomas**: las 17 y las ciudades autónomas de Ceuta y Melilla. Código `C` + código INE de la comunidad.

Casar cada concesión con su entidad:

1. Por el par (`nivel2`, `nivel3`) contra el árbol de órganos (99,97 % de las concesiones locales de 2025).
2. Si el órgano ya no está en el árbol, por el nodo (`nivel2`) cuando su nombre es único.
3. Los dos pares de nombres que se repiten en provincias distintas (Ayuntamiento de Cieza en Cantabria y en Murcia, de El Molar en Madrid y en Tarragona) se piden aparte a la API con el filtro `organos=<id>`.
4. El nodo es un **ayuntamiento** si su código de 6 cifras tiene el dígito de control válido del INE y el municipio existe en el padrón. Las mancomunidades, comarcas, consells comarcals, consorcios y entidades locales menores tienen códigos propios que no lo cumplen: no se atribuyen a ninguna entidad del índice (unas 11.000 concesiones de 840.000 en 2025).

## Exclusiones y trampas

- **Ventana de cuatro años.** La API solo enseña las concesiones desde el 1 de enero de hace cuatro años (hoy, desde 2022). Los datos se guardan en *merge*, nunca se reemplazan, para no perder los años que la BDNS deja de enseñar.
- **Personas físicas.** Sus concesiones solo se publican el año de concesión y el siguiente. Un año medido más tarde pierde esas filas: en las de 2024 medidas en 2026 no queda ninguna a personas físicas, y las de los ayuntamientos caen de 377.754 (2025) a 86.419 (2024). Por eso **el año N se mide durante N+1** y cada medición guarda su año (`x_anio_medicion`). Si un año solo tiene una medición posterior, se marca `x_medicion_tardia = true` y no es comparable con los años bien medidos. Los años 2022 a 2024 de la primera carga (octubre de 2026) son tardíos.
- **Régimen foral.** Los ayuntamientos de Álava, Bizkaia, Gipuzkoa y Navarra sí registran en la BDNS, con una cobertura parecida a la del resto (2025: 18-21 % de los municipios pequeños con registros, frente al 9 % del resto; 82-100 % de los de más de 20.000 habitantes, frente al 78 %), así que se miden. Las **diputaciones forales de Álava y Gipuzkoa** no registran sus concesiones (ninguna en Álava en 2022-2026; 17 y 30 en Gipuzkoa en 2022 y 2023), mientras que la de Bizkaia registra 212.675 en 2025: la BDNS no mide su actividad subvencional y figuran `no_aplica`. El **Gobierno Vasco** registra una parte mínima de sus concesiones (5.770 en 2025: 2,6 por 1.000 habitantes y 41 € por habitante, frente a 12-496 por 1.000 habitantes y 270-1.160 € en las demás comunidades; cae de 10.732 en 2022 a 521 en lo que va de 2026) y también figura `no_aplica`. El **Gobierno de Navarra** sí registra con normalidad (28.709 concesiones en 2025, 620 € por habitante) y se mide.
- **Consell de Formentera.** Es a la vez el ayuntamiento: la BDNS lo registra como Ayuntamiento de Formentera y se mide como ayuntamiento (07024). La fila del consell figura `no_aplica`.
- **Madrid** no registra como «Ayuntamiento de Madrid» (cero concesiones con ese órgano): lo hacen sus áreas y sus 21 distritos. Por eso se suman todos los órganos del nodo.
- **La diputación concede por los municipios pequeños.** Muchos municipios pequeños no tienen concesiones propias porque las ayudas de su territorio las concede la diputación. Por eso `sin_registros` no puntúa.
- **Concesiones no publicadas.** La ley excluye de la publicidad las concesiones cuya difusión pueda vulnerar el honor o la intimidad de los beneficiarios o afecte a personas en situación de protección (art. 20.8 LGS). Medimos lo que es público: puede haber concesiones registradas que no vemos. Un caso llamativo es el **Ayuntamiento de Sevilla**: 679 convocatorias registradas y ninguna concesión visible en 2022-2026, ni de sus organismos.
- **Cargas en bloque.** Algunas entidades registran las concesiones de todo un año de una vez, meses después (Zaragoza, 2025: mediana de 338 días). Es exactamente lo que mide el indicador.
- **«ERR_MANTENIMIENTO_BBDD».** La API devuelve este error también cuando una consulta tarda demasiado (por ejemplo, filtrar solo por fecha de registro). Por eso se pide por fecha de concesión y mes, con reintentos.

## Cifras de control (medición del 25-oct-2026)

| | Concesiones 2025 | Fuera de plazo | Entidades con registros 2025 |
|---|---|---|---|
| Ayuntamientos | 377.754 | 53,6 % | 1.067 de 8.130 (78 % de los de más de 20.000 habitantes; 9,5 % del resto) |
| Diputaciones | 415.176 | 50,2 % | 38 de 41 (2 `no_aplica`) |
| Cabildos y consells | 35.325 | 31,1 % | 9 de 11 (Formentera `no_aplica`) |
| Comunidades autónomas | 5.181.798 | 37,7 % | 18 de 19 (País Vasco `no_aplica`) |
| **Total** | **6.010.053** | **39,5 %** | |

- La API declara 839.221 concesiones locales y 5.187.568 autonómicas con fecha de concesión en 2025; se descargan todas (ninguna duplicada por `codConcesion`).
- 802 ayuntamientos sin ninguna concesión en 2025 sí registraron convocatorias ese año.
- Comprobación con casos conocidos (2025, solo el órgano «Ayuntamiento de…»): Valladolid 1.707 concesiones y mediana de 14 días; Tarancón 71 y 3 días; Dos Hermanas 247 y 16 días; Zaragoza 3.312 y 338 días; Pamplona 1.203 y 44 días. Coinciden con la consulta directa por órgano.

## Limitaciones

- Medimos lo que consta en la BDNS pública: no si se registraron todas las concesiones ni si la información es correcta. Una concesión que nunca se registró no aparece, ni en plazo ni fuera de plazo.
- `fechaAlta` es la fecha de alta del registro en la BDNS. Si una entidad da de baja y vuelve a registrar una concesión, la fecha nueva cuenta como retraso.
- No se miden los pagos, reintegros ni sanciones (misma obligación del art. 5.2.b), porque la API pública no da su fecha de registro.
- No se mide el plazo de las convocatorias (art. 6.2: se registran inmediatamente antes de publicarse): la propia BDNS envía el extracto al diario oficial, así que el retraso no tiene sentido.
- El importe es contexto, en euros corrientes y sin deflactar.
- La población de los cabildos y consells no se calcula (no hay correspondencia municipio-isla en el repositorio).

## Código

- Ingesta: [`ingestion/pa_bdns.py`](../../ingestion/pa_bdns.py), fuente dlt `pa_bdns` (recursos `pa_bdns_organos`, `pa_bdns_concesiones_mes`, `pa_bdns_control`, `pa_bdns_convocatorias_mes`, todos en *merge*). Caché del agregado mensual en `data/bdns_cache/pa_bdns/`.
- Modelo: [`transform/models/marts/pa_ind_bdns.sql`](../../transform/models/marts/pa_ind_bdns.sql) y su `schema_pa_bdns.yml`.
- Reproducir en local: `python -m ingestion.pa_bdns --tipos L,A --anios 2022-2026` (primera carga: unos 20 minutos las entidades locales y 85 las comunidades) y `dbt build --select pa_ind_bdns`. La ejecución mensual mide solo el año anterior y el actual.
