# partidos_familias: de etiqueta de partido a familia política

Los ficheros de alcaldes del Ministerio de Política Territorial traen la lista
por la que se eligió a cada alcalde tal cual (≈1.100 etiquetas distintas entre
1979 y 2026: `PSOE`, `PSC-CP`, `PSdeG-PSOE`, `EAJ-PNV`, `ERC - AM`, `CM`,
`ACORD PER GUANYAR`, agrupaciones de electores...). El seed las agrupa en
familias: los partidos estatales (con sus federaciones y antecedentes) y los
principales partidos autonómicos por separado. El resto son agrupaciones de
electores y candidaturas locales ('Independientes y locales').

## Cómo se genera

1. **Clave normalizada** (`partido_original`): mayúsculas, sin tildes y cualquier
   signo sustituido por un espacio. Es la misma expresión que `stg_alcaldes`:
   `trim(regexp_replace(upper(strip_accents(partido_original)), '[^A-Z0-9]+', ' ', 'g'))`.
2. **Reglas ordenadas**: se aplican las expresiones regulares de la tabla de abajo
   a cada clave; gana la primera que casa. Las marcas de coalición catalanas de
   2023 (sufijos `-CM`, `-AMUNT`, `-AM`, `-CP`) van primero porque acompañan a
   nombres de candidatura locales.
3. **Revisión**: se comprobaron a mano las etiquetas con más alcaldes y las
   ambiguas (con la provincia y el alcalde del mandato anterior). Todas las
   etiquetas presentes en la carga tienen fila en el seed: el 99,2 % de los
   periodos de alcalde casa con una regla con nombre (1-40) y el 0,8 % restante
   son etiquetas locales que caen en la regla por defecto (0).
4. **Excepciones**: filas con `mandato` y/o `cod_mun` rellenos, que tienen
   prioridad sobre la regla general de la etiqueta.
5. En dbt, una etiqueta que no esté en el seed (nuevas cargas) se trata como
   'Independientes y locales'.

Colores: los convencionales de cada partido; las familias que comparten
territorio tienen colores distintos.

## Reglas

| # | Expresión (sobre la clave) | Familia | Nota |
|---|---|---|---|
| 1 | `^(OTROS\|C ELECTORAL\|NO CONSTA)$` | Sin detalle en la fuente | Etiquetas genéricas del SIL: OTROS / C. ELECTORAL (coalición sin detallar) / NO CONSTA |
| 2 | `^C GEST(ORA)?$` | Comisión gestora | Comisión gestora (sin alcalde electo) |
| 3 | `^(IND\|N ADS)$` | Independientes y locales | IND = independientes; N.ADS. = no adscritos |
| 4 | `(^\| )ARA PL$` | Otros partidos | Ara Pacte Local (PDeCAT, 2023) |
| 5 | `(^\|.* )(CM\|COMPROMIS MUNICIPAL)$` | Junts / CiU | Junts per Catalunya - Compromís Municipal (2023; 'CM' verificado con Vic e Igualada) |
| 6 | `(^\|.* )(AMUNT)$` | CUP | CUP - Amunt (2023) |
| 7 | `(^\|.* )(AM\|ACORD MUNICIPAL)$\|^ERC\|ESQUERRA REPUBLICANA` | ERC | ERC - Acord Municipal (2023) |
| 8 | `(^\|.* )(CP\|CANDIDATURA DE PROGRES)$\|^PSC( \|$)\|PARTIT DELS SOCIALISTES` | PSOE | PSC - Candidatura de Progrés (2023) |
| 9 | `(^\| )PSOE( \|$)\|^(PSDEG\|PSE EE\|PSE\|PSIB\|PSPV\|PSN\|PSM PSOE)( \|$)\|^PARTIDO SOCIALISTA OBRERO` | PSOE | PSOE y federaciones (PSOE-A, PSdeG, PSE-EE, PSIB, PSPV, PSN...) |
| 10 | `^PP( \|$)\|^P P$\|^PPC$\|^PARTIDO POPULAR` | PP | Partido Popular y etiquetas regionales |
| 11 | `^(AP\|AP PDP UL\|AP PDP\|PDP\|PDL\|UL\|CD)$` | PP | Antecedentes: AP, Coalición Popular (AP-PDP-UL, 1983), Coalición Democrática (CD, 1979), PDP, PDL, UL |
| 12 | `^VOX( \|$)` | Vox |  |
| 13 | `^(C S\|CS\|CIUDADANOS)( \|$)` | Ciudadanos | Cs y Cs-Tú Aragón |
| 14 | `^UCD$` | UCD |  |
| 15 | `^(CDS\|UC CDS)$` | CDS |  |
| 16 | `^(IU\|I U\|PCE\|PSUC\|EU\|EUPV\|EUIA\|ICV\|PODEMOS\|UNIDAS\|SUMAR\|MAS MADRID\|MAS PAIS\|GUANYEM\|CON ANDALUCIA\|UI CON ANDALUCIA\|IUSF)( \|$)\|(^\| )IU$` | IU, Podemos y Sumar | IU, PCE, PSUC, EU/EUPV, ICV, Podemos, Unidas Podemos, Sumar, Más Madrid, Guanyem (2015), Con Andalucía |
| 17 | `^(PNV\|EAJ PNV)( \|$)` | PNV | Incluye la coalición EAJ-PNV/EA de 1999 |
| 18 | `^(HB\|EH\|ANV\|BILDU\|EH BILDU\|AMAIUR)( \|$)` | EH Bildu (e izquierda abertzale) | HB, EH, ANV, Bildu, Bildu-EA, EH Bildu |
| 19 | `^EA$` | Eusko Alkartasuna | EA hasta 2011 (después dentro de Bildu) |
| 20 | `^(CIU\|CDC\|PDECAT\|JXCAT\|JUNTS\|JXCAT JUNTS)( \|$)\|^JUNTS PER CATALUNYA` | Junts / CiU | CiU, CDC, JxCat, Junts |
| 21 | `^CUP( \|$)\|^C U P` | CUP |  |
| 22 | `^(CC\|CCA\|CCA PNC\|CC ATI\|AIC\|ATI\|COALICION CANARIA)( \|$)` | Coalición Canaria | CC, CCa, AIC, ATI |
| 23 | `^(BNG\|B N G\|BLOQUE NACIONALISTA GALEGO)( \|$)` | BNG |  |
| 24 | `^(UPN\|U P N\|NAVARRA SUMA)( \|$)` | UPN |  |
| 25 | `^(PAR\|P A R\|PARTIDO ARAGONES)$` | PAR |  |
| 26 | `^(CHA\|CHUNTA ARAGONESISTA)( \|$)` | CHA |  |
| 27 | `^(PRC\|P R C\|PARTIDO REGIONALISTA DE CANTABRIA)$` | PRC |  |
| 28 | `EXISTE$\|^ESPANA VACIADA\|^SORIA YA` | Teruel Existe y España Vaciada |  |
| 29 | `^(FAC\|FORO\|FORO ASTURIAS)$` | Foro Asturias |  |
| 30 | `^(UPL\|U P L)$` | UPL |  |
| 31 | `^(GBAI\|GEROA BAI\|NABAI\|NA BAI)$` | Geroa Bai | Geroa Bai y Nafarroa Bai |
| 32 | `^(PA\|PSA\|PSA PA\|AXSI\|PARTIDO ANDALUCISTA)$` | Partido Andalucista | PSA/PA y Andalucía por Sí (AxSí) |
| 33 | `^UV$` | Unió Valenciana |  |
| 34 | `^(BLOC\|COMPROMIS\|UPV\|ACORD PER GUANYAR)( \|$)\|^COMPROMIS PER` | Compromís | Compromís, Bloc, UPV; 'Acord per Guanyar' = coalición de Compromís en 2023 |
| 35 | `^(PR\|PR\+\|P RIOJANO\|PLRI)$` | Otros partidos | Partido Riojano |
| 36 | `^(EL PI\|MES\|PSM\|UM)$` | Otros partidos | Baleares: El Pi, Més, PSM, Unió Mallorquina |
| 37 | `^(CG\|CPG\|CNG\|CIGA)$` | Otros partidos | Galicia: Coalición Galega, CPG, CNG, CIGA |
| 38 | `^(NC\|NC FAC\|BNR NC\|FD NC\|ASG)$` | Otros partidos | Canarias: Nueva Canarias, ASG |
| 39 | `^(UPCA\|EE\|PCAL\|URCL\|UPSA\|URAS\|PREX CE\|EXTREMENOS\|XAV\|PNTAV\|PPSO\|P P SO\|ZSI\|AHORA DECIDE\|ARAGONESES PLATAFORMA ARAGONESISTA\|EUPV ADELANTE\|ADELANTE ANDALUCIA)$` | Otros partidos | Otros regionalistas: UPCA, EE, PCAL, URCL, UPSA, URAS, PREx-CE, Extremeños, XAV, PNTAV, PPSO (Plataforma del Pueblo Soriano), ZSí, Ahora Decide, Aragoneses |
| 40 | `^(UPYD\|PTE\|PL\|PCC)$` | Otros partidos | UPyD, PTE, PL, PCC |
| 0 | *(ninguna)* | Independientes y locales | Resto: agrupaciones de electores y candidaturas locales |

## Excepciones

| Clave | Mandato | Municipio | Familia | Nota |
|---|---|---|---|---|
| `AM` | 1983-1987 | — | Coalición Canaria | Asamblea Majorera (Fuerteventura, 1983) |
| `CD` | 2023-2027 | — | Independientes y locales | CD en 2023 no es Coalición Democrática |
| `AHORA` | 2015-2019 | 28079 | IU, Podemos y Sumar | Ahora Madrid (2015) |
| `C ELECTORAL` | 2015-2019 | 46250 | Compromís | València: Joan Ribó (Compromís) |
| `C ELECTORAL` | 2019-2023 | 46250 | Compromís | València: Joan Ribó (Compromís) |
| `OTROS` | 2015-2019 | 50297 | IU, Podemos y Sumar | Zaragoza en Común (2015) |
| `OTROS` | 2015-2019 | 15030 | IU, Podemos y Sumar | Marea Atlántica (2015) |
| `OTROS` | 2015-2019 | 15078 | IU, Podemos y Sumar | Compostela Aberta (2015) |
| `OTROS` | 2015-2019 | 11012 | IU, Podemos y Sumar | Por Cádiz Sí Se Puede (2015) |
| `C ELECTORAL` | 2019-2023 | 11012 | IU, Podemos y Sumar | Adelante Cádiz (2019) |
| `OTROS` | 2015-2019 | 07040 | Otros partidos | Palma: MÉS per Mallorca (2015) |
| `C ELECTORAL` | 2019-2023 | 43148 | ERC | Tarragona: ERC (2019) |
| `C ELECTORAL` | 2019-2023 | 25120 | ERC | Lleida: ERC (2019) |
| `C ELECTORAL` | 2015-2019 | 08015 | PSOE | Badalona: PSC (2018) |
| `C ELECTORAL` | 2019-2023 | 08015 | PSOE | Badalona: PSC (2019-2021) |
| `C ELECTORAL` | 2015-2019 | 08279 | PSOE | Terrassa: PSC (2018) |
| `OTROS` | 2015-2019 | 30016 | Independientes y locales | Cartagena: MC Cartagena (partido local, 2015) |

## Limitaciones conocidas

- En los mandatos 2007-2023 el SIL resume muchas coaliciones como `C. ELECTORAL`
  u `OTROS` (por ejemplo PSC-CP, ERC-AM, JxCat, Compromís o las confluencias
  de 2015). Van a 'Sin detalle en la fuente'; `alcaldes_historia` las resuelve
  (`familia_inferida`) cuando la misma persona fue alcalde del mismo municipio
  con una etiqueta concreta en un mandato a 8 años o menos.
- La asignación es por etiqueta, no por municipio: una sigla usada por partidos
  distintos en sitios distintos (p. ej. `CP` en Cataluña frente a otra provincia)
  recibe la familia mayoritaria salvo que haya una excepción.
- `IND` (independientes) y `N.ADS.` (no adscritos) se agrupan con las candidaturas
  locales.
