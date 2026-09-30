// Nombres y unidades de los indicadores internacionales (mart internacional_ultimo),
// que vienen en castellano de la base de datos, para las páginas traducidas.
// [nombre, unidad] por idioma. Si falta una entrada se usa el texto de los datos.

export const INDICADORES_INT = {
    en: {
        vivienda_social_pct: ['Social rental housing', '% of total housing stock'],
        actividad_femenina: ['Female activity rate (15 and over)', '% of women aged 15 and over'],
        camas: ['Hospital beds', 'per 1,000 inhabitants'],
        co2_pc: ['CO2 emissions per capita (excl. LULUCF)', 't CO2 per capita'],
        consumo_electrico_pc: ['Electricity consumption per capita', 'kWh per capita'],
        crecimiento_pib: ['Real GDP growth', '% per year'],
        crecimiento_poblacion: ['Population growth', '% per year'],
        deuda_publica: ['General government gross debt', '% of GDP'],
        electricidad_renovable: ['Renewable electricity', '% of electricity generation'],
        esperanza_vida: ['Life expectancy at birth', 'years'],
        estudios_terciarios: ['Population aged 25-64 with tertiary education (ISCED 5-8)', '% of population aged 25-64'],
        estudios_terciarios_25mas: ['Population aged 25+ with at least short-cycle tertiary education', '% of population aged 25+'],
        exportaciones_pib: ['Exports of goods and services', '% of GDP'],
        fecundidad: ['Fertility', 'children per woman'],
        gasto_educacion_pib: ['Public spending on education', '% of GDP'],
        gasto_sanitario_pc_ppa: ['Current health expenditure per capita', 'current international dollars (PPP) per capita'],
        gasto_sanitario_pib: ['Current health expenditure', '% of GDP'],
        gei_pc: ['Greenhouse gas emissions per capita (excl. LULUCF)', 't CO2 equivalent per capita'],
        gini: ['Gini index of income', 'index 0-100'],
        homicidios: ['Intentional homicides', 'per 100,000 inhabitants'],
        id_pib: ['R&D expenditure', '% of GDP'],
        inflacion: ['Inflation (CPI)', '% per year'],
        internet: ['People using the internet', '% of population'],
        medicos: ['Doctors', 'per 1,000 inhabitants'],
        migrantes: ['Foreign-born population (migrant stock)', '% of population'],
        mortalidad_infantil: ['Infant mortality', 'deaths under age 1 per 1,000 live births'],
        paro: ['Unemployment rate', '% of labour force'],
        paro_juvenil: ['Youth unemployment rate (15-24)', '% of labour force aged 15-24'],
        pib_pc_ppa: ['GDP per capita at purchasing power parity', '2021 international dollars (PPP) per capita'],
        poblacion: ['Population', 'people'],
        poblacion_65: ['Population aged 65 and over', '% of population'],
        riesgo_pobreza: ['At-risk-of-poverty rate (60% of median)', '% of population'],
        suicidios: ['Suicide rate', 'per 100,000 inhabitants'],
        tasa_empleo: ['Employment rate (15 and over)', '% of population aged 15 and over'],
        turistas_por_habitante: ['International tourist arrivals per inhabitant', 'tourists per inhabitant'],
        electrificacion: ['Electricity in final energy consumption', '% of final energy consumption'],
        coche_electrico_cuota: ['Electric cars in new car sales', '% of new cars (battery electric and plug-in hybrids)']
    },
    ca: {
        vivienda_social_pct: 'Habitatge social de lloguer',
        actividad_femenina: "Taxa d'activitat femenina (15 anys o més)", camas: 'Llits hospitalaris',
        co2_pc: "Emissions de CO2 per habitant (sense LULUCF)", consumo_electrico_pc: 'Consum elèctric per habitant',
        crecimiento_pib: 'Creixement del PIB real', crecimiento_poblacion: 'Creixement de la població',
        deuda_publica: 'Deute públic brut de les administracions públiques', electricidad_renovable: "Electricitat d'origen renovable",
        esperanza_vida: 'Esperança de vida en néixer', estudios_terciarios: 'Població de 25 a 64 anys amb estudis superiors (CINE 5-8)',
        estudios_terciarios_25mas: 'Població de 25 anys o més amb almenys estudis superiors de cicle curt',
        exportaciones_pib: 'Exportacions de béns i serveis', fecundidad: 'Fecunditat', gasto_educacion_pib: 'Despesa pública en educació',
        gasto_sanitario_pc_ppa: 'Despesa sanitària corrent per habitant', gasto_sanitario_pib: 'Despesa sanitària corrent',
        gei_pc: "Emissions de gasos d'efecte d'hivernacle per habitant (sense LULUCF)", gini: 'Índex de Gini de la renda',
        homicidios: 'Homicidis intencionats', id_pib: 'Despesa en R+D', inflacion: 'Inflació (IPC)', internet: 'Persones que fan servir internet',
        medicos: 'Metges', migrantes: "Població nascuda a l'estranger (estoc de migrants)", mortalidad_infantil: 'Mortalitat infantil',
        paro: "Taxa d'atur", paro_juvenil: "Taxa d'atur juvenil (15-24 anys)", pib_pc_ppa: 'PIB per habitant en paritat de poder adquisitiu',
        poblacion: 'Població', poblacion_65: 'Població de 65 anys o més', riesgo_pobreza: 'Taxa de risc de pobresa (60 % de la mediana)',
        suicidios: 'Taxa de suïcidi', tasa_empleo: "Taxa d'ocupació (15 anys o més)", turistas_por_habitante: 'Arribades de turistes internacionals per habitant',
        electrificacion: ['Electricitat en el consum final d\'energia', '% del consum final d\'energia'],
        coche_electrico_cuota: ['Cotxes elèctrics en les vendes de turismes nous', '% dels turismes nous (elèctrics purs i híbrids endollables)']
    },
    gl: {
        vivienda_social_pct: 'Vivenda social en aluguer',
        actividad_femenina: 'Taxa de actividade feminina (15 anos ou máis)', camas: 'Camas de hospital',
        co2_pc: 'Emisións de CO2 por habitante (sen LULUCF)', consumo_electrico_pc: 'Consumo eléctrico por habitante',
        crecimiento_pib: 'Crecemento do PIB real', crecimiento_poblacion: 'Crecemento da poboación',
        deuda_publica: 'Débeda pública bruta das administracións públicas', electricidad_renovable: 'Electricidade de orixe renovable',
        esperanza_vida: 'Esperanza de vida ao nacer', estudios_terciarios: 'Poboación de 25 a 64 anos con estudos superiores (CINE 5-8)',
        estudios_terciarios_25mas: 'Poboación de 25 anos ou máis con polo menos estudos superiores de ciclo curto',
        exportaciones_pib: 'Exportacións de bens e servizos', fecundidad: 'Fecundidade', gasto_educacion_pib: 'Gasto público en educación',
        gasto_sanitario_pc_ppa: 'Gasto sanitario corrente por habitante', gasto_sanitario_pib: 'Gasto sanitario corrente',
        gei_pc: 'Emisións de gases de efecto invernadoiro por habitante (sen LULUCF)', gini: 'Índice de Gini da renda',
        homicidios: 'Homicidios intencionados', id_pib: 'Gasto en I+D', inflacion: 'Inflación (IPC)', internet: 'Persoas que usan internet',
        medicos: 'Médicos', migrantes: 'Poboación nada no estranxeiro (stock de migrantes)', mortalidad_infantil: 'Mortalidade infantil',
        paro: 'Taxa de paro', paro_juvenil: 'Taxa de paro xuvenil (15-24 anos)', pib_pc_ppa: 'PIB por habitante en paridade de poder adquisitivo',
        poblacion: 'Poboación', poblacion_65: 'Poboación de 65 anos ou máis', riesgo_pobreza: 'Taxa de risco de pobreza (60 % da mediana)',
        suicidios: 'Taxa de suicidio', tasa_empleo: 'Taxa de emprego (15 anos ou máis)', turistas_por_habitante: 'Chegadas de turistas internacionais por habitante',
        electrificacion: ['Electricidade no consumo final de enerxía', '% do consumo final de enerxía'],
        coche_electrico_cuota: ['Coches eléctricos nas vendas de turismos novos', '% dos turismos novos (eléctricos puros e híbridos enchufables)']
    },
    eu: {
        vivienda_social_pct: 'Alokairuko gizarte-etxebizitza',
        actividad_femenina: 'Emakumeen jarduera-tasa (15 urte edo gehiago)', camas: 'Ospitaleko oheak',
        co2_pc: 'CO2 isurketak biztanleko (LULUCF gabe)', consumo_electrico_pc: 'Elektrizitate-kontsumoa biztanleko',
        crecimiento_pib: 'BPG errealaren hazkundea', crecimiento_poblacion: 'Biztanleriaren hazkundea',
        deuda_publica: 'Administrazio publikoen zor publiko gordina', electricidad_renovable: 'Jatorri berriztagarriko elektrizitatea',
        esperanza_vida: 'Jaiotzean bizi-itxaropena', estudios_terciarios: 'Goi-mailako ikasketak dituzten 25-64 urteko biztanleak (CINE 5-8)',
        estudios_terciarios_25mas: 'Gutxienez ziklo laburreko goi-mailako ikasketak dituzten 25 urtetik gorakoak',
        exportaciones_pib: 'Ondasun eta zerbitzuen esportazioak', fecundidad: 'Ugalkortasuna', gasto_educacion_pib: 'Hezkuntzako gastu publikoa',
        gasto_sanitario_pc_ppa: 'Osasun-gastu arrunta biztanleko', gasto_sanitario_pib: 'Osasun-gastu arrunta',
        gei_pc: 'Berotegi-efektuko gasen isurketak biztanleko (LULUCF gabe)', gini: 'Errentaren Gini indizea',
        homicidios: 'Nahitako hilketak', id_pib: 'I+G gastua', inflacion: 'Inflazioa (KPI)', internet: 'Internet erabiltzen duten pertsonak',
        medicos: 'Medikuak', migrantes: 'Atzerrian jaiotako biztanleria (migratzaileak)', mortalidad_infantil: 'Haurren heriotza-tasa',
        paro: 'Langabezia-tasa', paro_juvenil: 'Gazteen langabezia-tasa (15-24 urte)', pib_pc_ppa: 'BPG biztanleko erosahalmen-parekotasunean',
        poblacion: 'Biztanleria', poblacion_65: '65 urte edo gehiagoko biztanleria', riesgo_pobreza: 'Pobrezia-arriskuaren tasa (medianaren % 60)',
        suicidios: 'Suizidio-tasa', tasa_empleo: 'Enplegu-tasa (15 urte edo gehiago)', turistas_por_habitante: 'Nazioarteko turisten etorrerak biztanleko',
        electrificacion: ['Elektrizitatea azken energia-kontsumoan', 'azken energia-kontsumoaren %'],
        coche_electrico_cuota: ['Auto elektrikoak turismo berrien salmentetan', 'turismo berrien % (elektriko hutsak eta hibrido entxufagarriak)']
    }
};

// Unidades en catalán, gallego y euskera: sustituciones de las palabras frecuentes
const UNIDADES = {
    ca: [['% del parque total de viviendas', "% del parc total d'habitatges"], ['% de la población activa de 15 a 24 años', '% de la població activa de 15 a 24 anys'], ['% de la población activa', '% de la població activa'], ['% de las mujeres de 15 años o más', '% de les dones de 15 anys o més'], ['% de la población de 25 a 64 años', '% de la població de 25 a 64 anys'], ['% de la población de 25 años o más', '% de la població de 25 anys o més'], ['% de la población de 15 años o más', '% de la població de 15 anys o més'], ['% de la población', '% de la població'], ['% de la generación eléctrica', '% de la generació elèctrica'], ['% del PIB', '% del PIB'], ['% anual', '% anual'], ['por 1.000 habitantes', 'per 1.000 habitants'], ['por 100.000 habitantes', 'per 100.000 habitants'], ['por habitante', 'per habitant'], ['hijos por mujer', 'fills per dona'], ['años', 'anys'], ['personas', 'persones'], ['turistas', 'turistes'], ['muertes de menores de 1 año por 1.000 nacidos vivos', 'morts de menors d\'1 any per 1.000 nascuts vius'], ['dólares internacionales', 'dòlars internacionals'], ['corrientes', 'corrents'], ['índice', 'índex']],
    gl: [['% del parque total de viviendas', '% do parque total de vivendas'], ['% de la población activa de 15 a 24 años', '% da poboación activa de 15 a 24 anos'], ['% de la población activa', '% da poboación activa'], ['% de las mujeres de 15 años o más', '% das mulleres de 15 anos ou máis'], ['% de la población de 25 a 64 años', '% da poboación de 25 a 64 anos'], ['% de la población de 25 años o más', '% da poboación de 25 anos ou máis'], ['% de la población de 15 años o más', '% da poboación de 15 anos ou máis'], ['% de la población', '% da poboación'], ['% de la generación eléctrica', '% da xeración eléctrica'], ['por 1.000 habitantes', 'por 1.000 habitantes'], ['hijos por mujer', 'fillos por muller'], ['años', 'anos'], ['personas', 'persoas'], ['muertes de menores de 1 año por 1.000 nacidos vivos', 'mortes de menores de 1 ano por 1.000 nados vivos'], ['dólares internacionales', 'dólares internacionais'], ['corrientes', 'correntes']],
    eu: [['% del parque total de viviendas', 'etxebizitza-parke osoaren %'], ['% de la población activa de 15 a 24 años', '15-24 urteko biztanle aktiboen %'], ['% de la población activa', 'biztanle aktiboen %'], ['% de las mujeres de 15 años o más', '15 urte edo gehiagoko emakumeen %'], ['% de la población de 25 a 64 años', '25-64 urteko biztanleen %'], ['% de la población de 25 años o más', '25 urte edo gehiagoko biztanleen %'], ['% de la población de 15 años o más', '15 urte edo gehiagoko biztanleen %'], ['% de la población', 'biztanleriaren %'], ['% de la generación eléctrica', 'sorkuntza elektrikoaren %'], ['% del PIB', 'BPGaren %'], ['% anual', '% urtean'], ['por 1.000 habitantes', '1.000 biztanleko'], ['por 100.000 habitantes', '100.000 biztanleko'], ['por habitante', 'biztanleko'], ['hijos por mujer', 'seme-alaba emakumeko'], ['años', 'urte'], ['personas', 'pertsona'], ['turistas', 'turista'], ['muertes de menores de 1 año por 1.000 nacidos vivos', '1 urtetik beherakoen heriotzak 1.000 jaiotza biziko'], ['dólares internacionales', 'nazioarteko dolar'], ['corrientes', 'korronte'], ['índice', 'indizea']]
};

const FUENTES = {
    en: [['OCDE', 'OECD'], ['Banco Mundial', 'World Bank'], ['estimación modelizada OIT', 'ILO modelled estimate'], ['FMI', 'IMF'], ['AIE', 'IEA']],
    ca: [['Banco Mundial', 'Banc Mundial'], ['estimación modelizada OIT', 'estimació modelitzada OIT']],
    gl: [['Banco Mundial', 'Banco Mundial'], ['estimación modelizada OIT', 'estimación modelizada OIT']],
    eu: [['OCDE', 'ELGA'], ['Banco Mundial', 'Munduko Bankua'], ['estimación modelizada OIT', 'LANEren eredu-estimazioa'], ['FMI', 'NDF'], ['AIE', 'IEA']]
};

const sustituir = (texto, pares) => (pares ?? []).reduce((t, [a, b]) => t.split(a).join(b), texto ?? '');

/** { nombre, unidad, fuente } traducidos para una fila de internacional_ultimo */
export function textosIndicador(fila, lang) {
    if (!fila || lang === 'es') return { nombre: fila?.nombre, unidad: fila?.unidad, fuente: fila?.fuente };
    const e = INDICADORES_INT[lang]?.[fila.indicador_id];
    const nombre = Array.isArray(e) ? e[0] : e ?? fila.nombre;
    const unidad = Array.isArray(e) ? e[1] : sustituir(fila.unidad, UNIDADES[lang]);
    return { nombre, unidad, fuente: sustituir(fila.fuente, FUENTES[lang]) };
}
