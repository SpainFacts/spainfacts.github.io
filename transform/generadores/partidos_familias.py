"""Genera transform/seeds/partidos_familias.csv y el .md con las reglas.

Lee todas las etiquetas de partido de raw.alcaldes_* (MotherDuck), las
normaliza igual que dbt y aplica reglas regex ordenadas. Volver a ejecutarlo
tras cada carga de alcaldes con etiquetas nuevas (desde la raíz del repo, con
el .env cargado):

    .venv/Scripts/python transform/generadores/partidos_familias.py
"""
import csv
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path

import duckdb

# Raíz del repo (este fichero está en transform/generadores/)
REPO = str(Path(__file__).resolve().parents[2])

# familia: (siglas, color, ambito)
FAMILIAS = {
    "PSOE": ("PSOE", "#e30613", "estatal"),
    "PP": ("PP", "#1d84ce", "estatal"),
    "Vox": ("Vox", "#5ac035", "estatal"),
    "IU, Podemos y Sumar": ("IU-Podemos-Sumar", "#7b2d8e", "estatal"),
    "Ciudadanos": ("Cs", "#eb6109", "estatal"),
    "UCD": ("UCD", "#2f9c95", "estatal"),
    "CDS": ("CDS", "#9e9d24", "estatal"),
    "PNV": ("PNV", "#006b2d", "autonómico"),
    "EH Bildu (e izquierda abertzale)": ("EH Bildu", "#a8c81c", "autonómico"),
    "Eusko Alkartasuna": ("EA", "#c2185b", "autonómico"),
    "Junts / CiU": ("Junts", "#20c0b2", "autonómico"),
    "ERC": ("ERC", "#ffb232", "autonómico"),
    "CUP": ("CUP", "#f2e205", "autonómico"),
    "Coalición Canaria": ("CC", "#ffd700", "autonómico"),
    "BNG": ("BNG", "#76b3dd", "autonómico"),
    "UPN": ("UPN", "#3949ab", "autonómico"),
    "PAR": ("PAR", "#d4a017", "autonómico"),
    "CHA": ("CHA", "#1f7a4d", "autonómico"),
    "PRC": ("PRC", "#9acd32", "autonómico"),
    "Teruel Existe y España Vaciada": ("TE-EV", "#2e7d32", "autonómico"),
    "Foro Asturias": ("Foro", "#1565c0", "autonómico"),
    "UPL": ("UPL", "#8e2c48", "autonómico"),
    "Geroa Bai": ("GBai", "#e5503c", "autonómico"),
    "Partido Andalucista": ("PA", "#3cb371", "autonómico"),
    "Unió Valenciana": ("UV", "#0077b6", "autonómico"),
    "Compromís": ("Compromís", "#f29100", "autonómico"),
    "Otros partidos": ("Otros", "#6d4c41", "autonómico"),
    "Independientes y locales": ("Ind.", "#9ca3af", "local"),
    "Sin detalle en la fuente": ("S/D", "#d1d5db", "local"),
    "Comisión gestora": ("Gestora", "#4b5563", "local"),
}

# Reglas ordenadas: (regex sobre la clave normalizada, familia, ambito o None, nota)
# La primera que casa gana. Clave = mayúsculas, sin tildes, signos -> espacio.
R = [
    # --- etiquetas genéricas / administrativas del SIL
    (r"^(OTROS|C ELECTORAL|NO CONSTA)$", "Sin detalle en la fuente", None,
     "Etiquetas genéricas del SIL: OTROS / C. ELECTORAL (coalición sin detallar) / NO CONSTA"),
    (r"^C GEST(ORA)?$", "Comisión gestora", None, "Comisión gestora (sin alcalde electo)"),
    (r"^(IND|N ADS)$", "Independientes y locales", None, "IND = independientes; N.ADS. = no adscritos"),
    # --- marcas catalanas de 2023 (sufijos de coalición) antes que las siglas sueltas
    (r"(^| )ARA PL$", "Otros partidos", "autonómico", "Ara Pacte Local (PDeCAT, 2023)"),
    (r"(^|.* )(CM|COMPROMIS MUNICIPAL)$", "Junts / CiU", None,
     "Junts per Catalunya - Compromís Municipal (2023; 'CM' verificado con Vic e Igualada)"),
    (r"(^|.* )(AMUNT)$", "CUP", None, "CUP - Amunt (2023)"),
    (r"(^|.* )(AM|ACORD MUNICIPAL)$|^ERC|ESQUERRA REPUBLICANA", "ERC", None, "ERC - Acord Municipal (2023)"),
    (r"(^|.* )(CP|CANDIDATURA DE PROGRES)$|^PSC( |$)|PARTIT DELS SOCIALISTES", "PSOE", None,
     "PSC - Candidatura de Progrés (2023)"),
    # --- PSOE y federaciones
    (r"(^| )PSOE( |$)|^(PSDEG|PSE EE|PSE|PSIB|PSPV|PSN|PSM PSOE)( |$)|^PARTIDO SOCIALISTA OBRERO", "PSOE", None,
     "PSOE y federaciones (PSOE-A, PSdeG, PSE-EE, PSIB, PSPV, PSN...)"),
    # --- PP y antecedentes (AP, Coalición Popular 1983, CD 1979, PDP, PDL, UL)
    (r"^PP( |$)|^P P$|^PPC$|^PARTIDO POPULAR", "PP", None, "Partido Popular y etiquetas regionales"),
    (r"^(AP|AP PDP UL|AP PDP|PDP|PDL|UL|CD)$", "PP", None,
     "Antecedentes: AP, Coalición Popular (AP-PDP-UL, 1983), Coalición Democrática (CD, 1979), PDP, PDL, UL"),
    (r"^VOX( |$)", "Vox", None, ""),
    (r"^(C S|CS|CIUDADANOS)( |$)", "Ciudadanos", None, "Cs y Cs-Tú Aragón"),
    (r"^UCD$", "UCD", None, ""),
    (r"^(CDS|UC CDS)$", "CDS", None, ""),
    # --- espacio IU / Podemos / Sumar
    (r"^(IU|I U|PCE|PSUC|EU|EUPV|EUIA|ICV|PODEMOS|UNIDAS|SUMAR|MAS MADRID|MAS PAIS|GUANYEM|CON ANDALUCIA|UI CON ANDALUCIA|IUSF)( |$)|(^| )IU$",
     "IU, Podemos y Sumar", None, "IU, PCE, PSUC, EU/EUPV, ICV, Podemos, Unidas Podemos, Sumar, Más Madrid, Guanyem (2015), Con Andalucía"),
    # --- nacionalistas / regionalistas con familia propia
    (r"^(PNV|EAJ PNV)( |$)", "PNV", None, "Incluye la coalición EAJ-PNV/EA de 1999"),
    (r"^(HB|EH|ANV|BILDU|EH BILDU|AMAIUR)( |$)", "EH Bildu (e izquierda abertzale)", None,
     "HB, EH, ANV, Bildu, Bildu-EA, EH Bildu"),
    (r"^EA$", "Eusko Alkartasuna", None, "EA hasta 2011 (después dentro de Bildu)"),
    (r"^(CIU|CDC|PDECAT|JXCAT|JUNTS|JXCAT JUNTS)( |$)|^JUNTS PER CATALUNYA", "Junts / CiU", None, "CiU, CDC, JxCat, Junts"),
    (r"^CUP( |$)|^C U P", "CUP", None, ""),
    (r"^(CC|CCA|CCA PNC|CC ATI|AIC|ATI|COALICION CANARIA)( |$)", "Coalición Canaria", None, "CC, CCa, AIC, ATI"),
    (r"^(BNG|B N G|BLOQUE NACIONALISTA GALEGO)( |$)", "BNG", None, ""),
    (r"^(UPN|U P N|NAVARRA SUMA)( |$)", "UPN", None, ""),
    (r"^(PAR|P A R|PARTIDO ARAGONES)$", "PAR", None, ""),
    (r"^(CHA|CHUNTA ARAGONESISTA)( |$)", "CHA", None, ""),
    (r"^(PRC|P R C|PARTIDO REGIONALISTA DE CANTABRIA)$", "PRC", None, ""),
    (r"EXISTE$|^ESPANA VACIADA|^SORIA YA", "Teruel Existe y España Vaciada", None, ""),
    (r"^(FAC|FORO|FORO ASTURIAS)$", "Foro Asturias", None, ""),
    (r"^(UPL|U P L)$", "UPL", None, ""),
    (r"^(GBAI|GEROA BAI|NABAI|NA BAI)$", "Geroa Bai", None, "Geroa Bai y Nafarroa Bai"),
    (r"^(PA|PSA|PSA PA|AXSI|PARTIDO ANDALUCISTA)$", "Partido Andalucista", None, "PSA/PA y Andalucía por Sí (AxSí)"),
    (r"^UV$", "Unió Valenciana", None, ""),
    (r"^(BLOC|COMPROMIS|UPV|ACORD PER GUANYAR)( |$)|^COMPROMIS PER", "Compromís", None,
     "Compromís, Bloc, UPV; 'Acord per Guanyar' = coalición de Compromís en 2023"),
    # --- otros partidos identificables (no locales)
    (r"^(PR|PR\+|P RIOJANO|PLRI)$", "Otros partidos", "autonómico", "Partido Riojano"),
    (r"^(EL PI|MES|PSM|UM)$", "Otros partidos", "autonómico", "Baleares: El Pi, Més, PSM, Unió Mallorquina"),
    (r"^(CG|CPG|CNG|CIGA)$", "Otros partidos", "autonómico", "Galicia: Coalición Galega, CPG, CNG, CIGA"),
    (r"^(NC|NC FAC|BNR NC|FD NC|ASG)$", "Otros partidos", "autonómico", "Canarias: Nueva Canarias, ASG"),
    (r"^(UPCA|EE|PCAL|URCL|UPSA|URAS|PREX CE|EXTREMENOS|XAV|PNTAV|PPSO|P P SO|ZSI|AHORA DECIDE|ARAGONESES PLATAFORMA ARAGONESISTA|EUPV ADELANTE|ADELANTE ANDALUCIA)$",
     "Otros partidos", "autonómico",
     "Otros regionalistas: UPCA, EE, PCAL, URCL, UPSA, URAS, PREx-CE, Extremeños, XAV, PNTAV, PPSO (Plataforma del Pueblo Soriano), ZSí, Ahora Decide, Aragoneses"),
    (r"^(UPYD|PTE|PL|PCC)$", "Otros partidos", "estatal", "UPyD, PTE, PL, PCC"),
]
DEFECTO = ("Independientes y locales", "local", "Resto: agrupaciones de electores y candidaturas locales")

# Excepciones acotadas a un mandato (y opcionalmente a un municipio).
EXCEPCIONES = [
    # (clave, mandato, cod_mun, familia, ambito, nota)
    ("AM", "1983-1987", "", "Coalición Canaria", "autonómico", "Asamblea Majorera (Fuerteventura, 1983)"),
    ("CD", "2023-2027", "", "Independientes y locales", "local", "CD en 2023 no es Coalición Democrática"),
    ("AHORA", "2015-2019", "28079", "IU, Podemos y Sumar", "estatal", "Ahora Madrid (2015)"),
    # Grandes municipios con etiqueta genérica del SIL que la inferencia no resuelve
    ("C ELECTORAL", "2015-2019", "46250", "Compromís", "autonómico", "València: Joan Ribó (Compromís)"),
    ("C ELECTORAL", "2019-2023", "46250", "Compromís", "autonómico", "València: Joan Ribó (Compromís)"),
    ("OTROS", "2015-2019", "50297", "IU, Podemos y Sumar", "estatal", "Zaragoza en Común (2015)"),
    ("OTROS", "2015-2019", "15030", "IU, Podemos y Sumar", "estatal", "Marea Atlántica (2015)"),
    ("OTROS", "2015-2019", "15078", "IU, Podemos y Sumar", "estatal", "Compostela Aberta (2015)"),
    ("OTROS", "2015-2019", "11012", "IU, Podemos y Sumar", "estatal", "Por Cádiz Sí Se Puede (2015)"),
    ("C ELECTORAL", "2019-2023", "11012", "IU, Podemos y Sumar", "estatal", "Adelante Cádiz (2019)"),
    ("OTROS", "2015-2019", "07040", "Otros partidos", "autonómico", "Palma: MÉS per Mallorca (2015)"),
    ("C ELECTORAL", "2019-2023", "43148", "ERC", "autonómico", "Tarragona: ERC (2019)"),
    ("C ELECTORAL", "2019-2023", "25120", "ERC", "autonómico", "Lleida: ERC (2019)"),
    ("C ELECTORAL", "2015-2019", "08015", "PSOE", "estatal", "Badalona: PSC (2018)"),
    ("C ELECTORAL", "2019-2023", "08015", "PSOE", "estatal", "Badalona: PSC (2019-2021)"),
    ("C ELECTORAL", "2015-2019", "08279", "PSOE", "estatal", "Terrassa: PSC (2018)"),
    ("OTROS", "2015-2019", "30016", "Independientes y locales", "local", "Cartagena: MC Cartagena (partido local, 2015)"),
]


def clave(t):
    t = unicodedata.normalize("NFKD", t or "")
    t = "".join(c for c in t if not unicodedata.combining(c)).upper()
    return re.sub(r"[^A-Z0-9]+", " ", t).strip()


def main():
    con = duckdb.connect("md:SpainFacts")
    # misma expresión que la macro de dbt (clave_partido): la clave casa exactamente
    filas = con.sql("""
        select trim(regexp_replace(upper(strip_accents(partido_original)), '[^A-Z0-9]+', ' ', 'g')) k, count(*) n
        from (select partido_original from raw.alcaldes_historico
              union all select partido_original from raw.alcaldes_actuales)
        group by 1""").fetchall()
    n_por_clave = Counter({k: n for k, n in filas})
    salida, uso = [], Counter()
    explicito = 0
    for k, n in sorted(n_por_clave.items(), key=lambda x: (-x[1], x[0])):
        for i, (rx, fam, amb, _) in enumerate(R):
            if re.search(rx, k):
                regla = i + 1
                break
        else:
            fam, amb, regla = DEFECTO[0], DEFECTO[1], 0
        if regla:
            explicito += n
        uso[regla] += n
        s, c, a = FAMILIAS[fam]
        salida.append({"partido_original": k, "mandato": "", "cod_mun": "", "familia": fam,
                       "siglas_familia": s, "color": c, "ambito": amb or a, "regla": regla})
    for k, m, cm, fam, amb, nota in EXCEPCIONES:
        s, c, _ = FAMILIAS[fam]
        salida.append({"partido_original": k, "mandato": m, "cod_mun": cm, "familia": fam,
                       "siglas_familia": s, "color": c, "ambito": amb, "regla": "excepción"})
    total = sum(n_por_clave.values())
    with open(f"{REPO}/transform/seeds/partidos_familias.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(salida[0].keys()))
        w.writeheader()
        w.writerows(salida)
    print(f"claves={len(n_por_clave)} alcaldes={total} explícitos={explicito/total:.4%}")
    for regla, n in sorted(uso.items()):
        print(regla, n)
    # Tablas de reglas y excepciones en markdown, para pegar a mano en
    # transform/seeds/partidos_familias.md (opcional: primer argumento = fichero)
    if len(sys.argv) < 2:
        return
    with open(sys.argv[1], "w", encoding="utf-8") as f:
        for i, (rx, fam, amb, nota) in enumerate(R):
            f.write(f"| {i+1} | `{rx.replace('|', chr(92)+'|')}` | {fam} | {nota} |\n")
        f.write(f"| 0 | *(ninguna)* | {DEFECTO[0]} | {DEFECTO[2]} |\n")
        f.write("\n")
        for k, m, cm, fam, amb, nota in EXCEPCIONES:
            f.write(f"| `{k}` | {m} | {cm or '—'} | {fam} | {nota} |\n")


if __name__ == "__main__":
    main()
