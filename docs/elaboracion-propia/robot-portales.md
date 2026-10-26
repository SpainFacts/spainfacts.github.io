# Revisión automática de los portales de transparencia

**Elaboración propia de SpainFacts.** Medición sistemática y factual de los portales de transparencia y sedes electrónicas de todas las entidades locales de España (ayuntamientos y diputaciones provinciales, cabildos y consells insulares).

El código fuente del robot y sus analizadores reside en [`ingestion/transparencia_robot/`](../../ingestion/transparencia_robot/).

---

## 1. Comprobaciones de la base estatal común (C0–C15)

Se evalúa el cumplimiento de las obligaciones comunes exigibles por la legislación básica estatal (Ley 19/2013 de transparencia, Ley 7/1985 Reguladora de las Bases del Régimen Local, Ley 9/2017 de Contratos del Sector Público y Real Decreto 635/2014 de cálculo del PMP):

| Código | Obligación evaluada | Base legal | Umbral de actualidad |
|---|---|---|---|
| **C0** | Portal o sección de transparencia accesible | Ley 19/2013, arts. 5.4 y 10 | Permanente |
| **C1** | Organigrama y estructura organizativa | Ley 19/2013, art. 6.1 | Permanente |
| **C2** | Identificación y trayectoria de los cargos | Ley 19/2013, art. 6.1 | Permanente |
| **C3** | Retribuciones de cargos electos y altos cargos | Ley 19/2013, art. 8.1.f | 18 meses |
| **C4** | Presupuesto del año en curso (o su prórroga) | Ley 19/2013, art. 8.1.d | Anual |
| **C5** | Ejecución del presupuesto y estabilidad | Ley 19/2013, art. 8.1.d | 9 meses |
| **C6** | Cuentas anuales o liquidación | Ley 19/2013, art. 8.1.e | 30 meses |
| **C7** | Contratos o enlace al perfil del contratante | Ley 19/2013, art. 8.1.a; LCSP arts. 63 y 347 | Permanente |
| **C8** | Convenios y encomiendas de gestión | Ley 19/2013, art. 8.1.b | Permanente |
| **C9** | Subvenciones y ayudas públicas concedidas | Ley 19/2013, art. 8.1.c | 18 meses |
| **C10** | Actas de pleno y fecha de la última sesión | LBRL art. 70.1; ROF art. 229 | 6 meses |
| **C11** | Declaraciones de bienes y actividades de cargos | LBRL art. 75.7; Ley 19/2013, art. 8.1.h | 54 meses |
| **C12** | Relación de puestos de trabajo (RPT) o plantilla | LBRL art. 90; TRRL art. 127 | 18 meses |
| **C13** | Inventario de bienes inmuebles o patrimonio | Ley 19/2013, art. 8.3 | Permanente |
| **C14** | Normativa vigente (ordenanzas y reglamentos) | Ley 19/2013, art. 7.c y 7.e | Permanente |
| **C15** | Periodo medio de pago (PMP) publicado | RD 635/2014, art. 6 | 6 meses |

---

## 2. Censo unificado de entidades y descubrimiento de URLs

Debido a que ningún registro oficial estatal mantiene actualizadas todas las URLs de los portales de transparencia, SpainFacts construye un censo consolidado cruzando cuatro fuentes:

1. **BDGEL (Hacienda / SGFAL):** Censo primario de entidades, códigos INE, teléfonos y códigos postales (usados para desambiguar homónimos).
2. **DIR3 (Centro de Transferencia de Tecnología):** Código de unidad orgánica, NIF oficial y dirección de correo institucional.
3. **Wikidata (Propiedad P856 ligada a P772):** Repositorio colaborativo de sitios web oficiales por código municipal.
4. **Sondeo de subdominios de plataformas comunes:** Comprobación dirigida de sedes electrónicas (`*.sedelectronica.es`, `*.sedipualba.es`, `*.eadministracio.cat`), descartando respuestas comodín («Sede Indeterminada»).

El censo consolidado se almacena en `data/transparencia_robot_cache/censo_entidades.parquet`.

---

## 3. Jerarquía de fechas (5 reglas)

Para evitar falsos positivos derivados de cabeceras HTTP de páginas dinámicas (el `Last-Modified` de un HTML suele devolver la hora de la petición), las fechas se resuelven estrictamente en este orden:

1. `plataforma`: Fecha estructurada devuelta por la API JSON o atributos semánticos del CMS.
2. `contenido`: Fecha explícita dentro del texto del documento (ej. «sesión plenaria de 15 de marzo de 2024»).
3. `titulo`: Año o fecha en el título del enlace o nombre de archivo descargable (ej. «PRESUPUESTO_2024.pdf»).
4. `pdf`: Metadatos `/CreationDate` y `/ModDate` embebidos en el archivo PDF.
5. `last_modified`: Cabecera HTTP `Last-Modified` **exclusivamente aplicada a archivos estáticos descargables** (`.pdf`, `.xlsx`, `.csv`), nunca en documentos HTML ni endpoints dinámicos.

---

## 4. Estados y tratamiento factual

- **`consta`**: La información requerida fue localizada en el portal y su fecha está dentro del umbral de actualidad.
- **`consta_desactualizado`**: La información existe, pero la fecha más reciente supera el umbral legal fijado.
- **`no_consta`**: El portal fue evaluado y no se localizó la sección ni documento exigido.
- **`no_evaluable`**: El portal no pudo ser evaluado (servidor caído, error de certificado TLS no recuperable, dominio expirado o plataforma estatal fuera de servicio). **Nunca puntúa negativamente ni se publica como incumplimiento.**
- **`verificacion_humana`**: La petición fue interceptada por un cortafuegos de aplicaciones (WAF) o reto anti-robots (CAPTCHA). Pasa a la cola de verificación manual.

---

## 5. Ética técnica, cortesía y archivo de evidencias

- **Identificación:** Peticiones realizadas bajo el User-Agent `SpainFactsTransparenciaBot/1.0 (+https://spainfacts.org/robot-transparencia)`.
- **Límites de concurrencia:**
  - Máximo 1 petición cada 2 segundos por host individual.
  - Límite global de 1 petición por segundo para infraestructuras multi-inquilino compartidas (`*.sedelectronica.es`, `*.sedipualba.es`, `seu-e.cat`).
  - Respeto del `Crawl-delay` indicado en `robots.txt`.
- **Anotación de `robots.txt`:** Se analiza con el estándar RFC 9309 (Protego). La negativa de acceso se anota en `robots_prohibe` para transparencia metodológica.
- **Archivo WARC:** Las evidencias de rastreo se almacenan localmente en formato estándar ISO 28500 (`.warc.gz`) para permitir la trazabilidad y auditoría de cada resultado.

---

## 6. Ejecución del robot

```bash
# 1. Generar o actualizar el censo consolidado de entidades
python -m ingestion.transparencia_robot.ejecutar censo

# 2. Ejecutar rastreo (ronda trimestral, muestra de prueba o entidad específica)
python -m ingestion.transparencia_robot.ejecutar rastrear --ronda 2026T4 --muestra 100
python -m ingestion.transparencia_robot.ejecutar rastrear --cod-entidad 41091

# 3. Exportar resultados consolidados a Parquet y emitir métricas
python -m ingestion.transparencia_robot.ejecutar exportar --ronda 2026T4
```
