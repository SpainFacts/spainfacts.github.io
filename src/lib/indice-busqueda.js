// Índice global de búsqueda para SpainFacts (Omnibox de inicio y modal ⌘K en la cabecera).
// Cubre: (1) Temas siempre visibles y subsecciones, (2) Análisis y reportajes de datos (blog),
// (3) Indicadores clave y (4) Comunidades autónomas, provincias y principales municipios.

import { enlace } from './i18n.js';

export const normalizarTexto = (s) =>
	String(s ?? '')
		.toLowerCase()
		.normalize('NFD')
		.replace(/[\u0300-\u036f]/g, '')
		.trim();

export const ARTICULOS_ANALISIS = [
	{
		href: '/analisis',
		icono: '📰',
		fecha: '2026',
		etiqueta: { es: 'Portada de análisis', en: 'Analysis hub', ca: 'Portada d’anàlisi', gl: 'Portada de análise', eu: 'Analisien ataria' },
		titulo: {
			es: 'Análisis y reportajes en datos',
			en: 'Data analysis & investigative reports',
			ca: 'Anàlisis i reportatges en dades',
			gl: 'Análises e reportaxes en datos',
			eu: 'Datu-analisiak eta erreportajeak'
		},
		desc: {
			es: 'Investigaciones puntuales y reportajes a fondo con datos oficiales: vivienda, diputados, flotas, decretos-ley, energía y sanidad.',
			en: 'Timely deep dives and data investigations from official sources: housing, MPs, vehicle fleets, decrees, energy and healthcare.',
			ca: 'Investigacions puntuals i reportatges a fons amb dades oficials.',
			gl: 'Investigacións puntuais e reportaxes a fondo con datos oficiais.',
			eu: 'Datu ofizialekin egindako ikerketa eta erreportaje sakonak.'
		},
		claves: 'blog analisis reportajes investigaciones articulos actualidad especiales'
	},
	{
		href: '/varios/diputados-caseros',
		icono: '🏘️',
		fecha: '2026-04',
		etiqueta: { es: 'Vivienda y política', en: 'Housing & politics', ca: 'Habitatge i política', gl: 'Vivenda e política', eu: 'Etxebizitza eta politika' },
		titulo: {
			es: '¿Cuántos diputados son caseros?',
			en: 'How many MPs are landlords?',
			ca: 'Quants diputats són arrendadors?',
			gl: 'Cantos deputados son caseiros?',
			eu: 'Zenbat diputatu dira etxe-jabe errentatzaile?'
		},
		desc: {
			es: 'Quién declara ingresos por alquiler o varias viviendas en el Congreso, por partido y frente al conjunto de declarantes del IRPF.',
			en: 'Which MPs declare rental income or multiple properties in Congress, by party and compared with all income-tax payers.',
			ca: 'Qui declara lloguers o diversos habitatges al Congrés, per partit i davant l’IRPF.',
			gl: 'Quen declara alugueiros ou varias vivendas no Congreso, por partido e fronte ao IRPF.',
			eu: 'Nork aitortzen dituen alokairuak edo hainbat etxebizitza Kongresuan, alderdika.'
		},
		claves: 'diputados caseros alquileres congreso bienes rentas inmuebles viviendas pisos politicos partidos irpf patrimonio'
	},
	{
		href: '/analisis/brecha-vivienda-salarios',
		icono: '🔑',
		fecha: '2026-04',
		etiqueta: { es: 'Vivienda y salarios', en: 'Housing & wages', ca: 'Habitatge i salaris', gl: 'Vivenda e salarios', eu: 'Etxebizitza eta soldatak' },
		titulo: {
			es: 'La brecha de la vivienda: años de sueldo para comprar o alquilar un piso',
			en: 'The housing gap: years of salary needed to buy or rent a home',
			ca: 'La bretxa de l’habitatge: anys de sou per comprar o llogar un pis',
			gl: 'A fenda da vivenda: anos de soldo para mercar ou alugar un piso',
			eu: 'Etxebizitzaren arrakala: etxe bat erosi edo alokatzeko soldata-urteak'
		},
		desc: {
			es: 'Cómo se han separado los precios de compra y alquiler de los salarios reales en cada comunidad autónoma y frente a la burbuja de 2007.',
			en: 'How house prices and rents have diverged from real wages across Spanish regions and compared with the 2007 bubble.',
			ca: 'Com s’han separat els preus de compra i lloguer dels salaris reals a cada comunitat.',
			gl: 'Como se separaron os prezos de compra e alugueiro dos salarios reais en cada comunidade.',
			eu: 'Nola urrundu diren etxebizitzaren prezioak eta alokairuak soldata errealetatik.'
		},
		claves: 'brecha generacional vivienda salarios esfuerzo hipoteca alquiler jovenes burbuja precios sueldo'
	},
	{
		href: '/movilidad/flotas-e-impuestos',
		icono: '🏝️',
		fecha: '2026-03',
		etiqueta: { es: 'Movilidad y fiscalidad', en: 'Mobility & taxation', ca: 'Mobilitat i fiscalitat', gl: 'Mobilidade e fiscalidade', eu: 'Mugikortasuna eta zergak' },
		titulo: {
			es: 'Los paraísos fiscales de las flotas en España',
			en: 'The municipal tax havens for car fleets in Spain',
			ca: 'Els paradisos fiscals de les flotes a Espanya',
			gl: 'Os paraísos fiscais das frotas en España',
			eu: 'Floten zerga-paradisuak Espainian'
		},
		desc: {
			es: 'Pueblos de unas decenas de vecinos con miles de coches de empresa: dónde se matriculan las flotas para pagar menos impuesto de circulación (IVTM).',
			en: 'Villages of a few dozen residents with thousands of company cars: where fleets register to pay lower road tax (IVTM).',
			ca: 'Pobles d’unes desenes de veïns amb milers de cotxes d’empresa.',
			gl: 'Vilas dunhas decenas de veciños con milleiros de coches de empresa.',
			eu: 'Dozenaka bizilaguneko herriak milaka enpresa-autorekin.'
		},
		claves: 'paraisos fiscales flotas coches empresa renting alquiler ivtm numerito impuesto circulacion rozas de puerto real aguilar de segarra colmenar del arroyo'
	},
	{
		href: '/analisis/revolucion-renovable',
		icono: '☀️',
		fecha: '2026-03',
		etiqueta: { es: 'Energía y clima', en: 'Energy & climate', ca: 'Energia i clima', gl: 'Enerxía e clima', eu: 'Energia eta klima' },
		titulo: {
			es: 'La gran transformación eléctrica: cómo el sol y el viento desplazaron al carbón',
			en: 'The great power shift: how solar and wind displaced coal in Spain',
			ca: 'La gran transformació elèctrica: com el sol i el vent van desplaçar el carbó',
			gl: 'A gran transformación eléctrica: como o sol e o vento desprazaron o carbón',
			eu: 'Eraldaketa elektriko handia: eguzkiak eta haizeak ikatza nola ordezkatu zuten'
		},
		desc: {
			es: 'En quince años España pasó de quemar carbón a generar más de la mitad de su electricidad con renovables, pero el transporte sigue estancado.',
			en: 'In fifteen years Spain went from burning coal to generating over half its power from renewables, yet transport emissions remain stubbornly high.',
			ca: 'En quinze anys Espanya va passar del carbó a generar més de la meitat de l’electricitat amb renovables.',
			gl: 'En quince anos España pasou do carbón a xerar máis da metade da electricidade con renovables.',
			eu: 'Hamabost urtean Espainia ikatza erretzetik elektrizitatearen erdia baino gehiago berriztagarriekin sortzera igaro da.'
		},
		claves: 'revolucion renovable transformacion electrica solar eolica carbon emisiones descarbonizacion transporte electricidad'
	},
	{
		href: '/sociedad/publico-privado',
		icono: '🏥',
		fecha: '2026-03',
		etiqueta: { es: 'Servicios públicos', en: 'Public services', ca: 'Serveis públics', gl: 'Servizos públicos', eu: 'Zerbitzu publikoak' },
		titulo: {
			es: 'Público y privado en la sanidad y la educación',
			en: 'Public and private in healthcare and education',
			ca: 'Públic i privat en la sanitat i l’educació',
			gl: 'Público e privado na sanidade e na educación',
			eu: 'Publikoa eta pribatua osasunean eta hezkuntzan'
		},
		desc: {
			es: 'Cuánto de la sanidad y la educación públicas se presta a través de empresas y centros privados: conciertos, seguros, concertada, FP y universidades.',
			en: 'How much of public healthcare and education is delivered through private providers: outsourcing, private insurance, charter schools and universities.',
			ca: 'Quant de la sanitat i l’educació públiques es presta a través d’empreses i centres privats.',
			gl: 'Canto da sanidade e a educación públicas se presta a través de empresas e centros privados.',
			eu: 'Osasun eta hezkuntza publikoaren zenbat ematen den zentro pribatuen bidez.'
		},
		claves: 'publico privado sanidad educacion conciertos sanitarios colegios concertados universidades privadas fp seguros salud'
	},
	{
		href: '/transparencia/decretos-ley',
		icono: '📜',
		fecha: '2026-02',
		etiqueta: { es: 'Instituciones', en: 'Institutions', ca: 'Institucions', gl: 'Institucións', eu: 'Erakundeak' },
		titulo: {
			es: 'Gobernar por decreto: reales decretos-ley desde 1977 por presidente',
			en: 'Ruling by decree: royal decree-laws since 1977 by Prime Minister',
			ca: 'Governar per decret: reials decrets llei des del 1977 per president',
			gl: 'Gobernar por decreto: reais decretos-lei desde 1977 por presidente',
			eu: 'Dekretuz gobernatzea: errege lege-dekretuak 1977tik presidenteka'
		},
		desc: {
			es: 'Qué proporción de las normas con rango de ley aprueba cada Gobierno mediante Real Decreto-ley de urgencia frente a leyes ordinarias.',
			en: 'What share of primary legislation each government passes via emergency Royal Decree-Law versus ordinary parliamentary bills.',
			ca: 'Quina part de les normes amb rang de llei es fan per decret llei amb cada Govern.',
			gl: 'Que parte das normas con rango de lei se fan por decreto-lei con cada Goberno.',
			eu: 'Lege-mailako arauen zein zati onartzen duen Gobernu bakoitzak dekretu bidez.'
		},
		claves: 'decretos ley decretazo boe gobierno congreso leyes sanchez rajoy zapatero aznar gonzalez suarez'
	},
	{
		href: '/medios/dinero-publico',
		icono: '📢',
		fecha: '2026-02',
		etiqueta: { es: 'Medios y dinero público', en: 'Media & public money', ca: 'Mitjans i diners públics', gl: 'Medios e diñeiro público', eu: 'Hedabideak eta diru publikoa' },
		titulo: {
			es: '¿Cuánto dinero público reciben los medios en publicidad institucional?',
			en: 'How much public money do media outlets receive in institutional advertising?',
			ca: 'Quants diners públics reben els mitjans en publicitat institucional?',
			gl: 'Canto diñeiro público reciben os medios en publicidade institucional?',
			eu: 'Zenbat diru publiko jasotzen dute hedabideek publizitate instituzionalean?'
		},
		desc: {
			es: 'Campañas del Estado, comunidades y ayuntamientos: cuánto se gasta y qué cabeceras o grupos reciben más.',
			en: 'Central, regional and local government campaigns: total spending and which media groups receive the most.',
			ca: 'Campanyes de l’Estat, comunitats i ajuntaments i quins mitjans en reben més.',
			gl: 'Campañas do Estado, comunidades e concellos e que medios reciben máis.',
			eu: 'Estatuaren, erkidegoen eta udalen kanpainak eta zein hedabidek jasotzen duten gehien.'
		},
		claves: 'medios comunicacion publicidad institucional prensa periodicos televisiones subvenciones dinero publico'
	},
	{
		href: '/varios/observatorios',
		icono: '🔭',
		fecha: '2026-01',
		etiqueta: { es: 'Sector público', en: 'Public sector', ca: 'Sector públic', gl: 'Sector público', eu: 'Sektore publikoa' },
		titulo: {
			es: 'Radiografía de los observatorios públicos en España',
			en: 'X-ray of public observatories in Spain',
			ca: 'Radiografia dels observatoris públics a Espanya',
			gl: 'Radiografía dos observatorios públicos en España',
			eu: 'Espainiako behatoki publikoen erradiografia'
		},
		desc: {
			es: 'Cuántos observatorios han creado el Estado y las comunidades autónomas, cuántos siguen activos y cuántos llevan años sin publicar.',
			en: 'How many observatories central and regional governments have created, how many remain active and how many are dormant.',
			ca: 'Quants observatoris han creat l’Estat i les comunitats i quants segueixen actius.',
			gl: 'Cantos observatorios crearon o Estado e as comunidades e cantos seguen activos.',
			eu: 'Estatuak eta erkidegoek zenbat behatoki sortu dituzten eta zenbat dauden aktibo.'
		},
		claves: 'observatorios publicos chiringuitos organismos instituciones actividad estado comunidades'
	}
];

export const TEMAS_Y_SECCIONES = [
	// Grandes temas (siempre visibles)
	{
		href: '/territorios',
		icono: '🗺️',
		titulo: { es: 'Territorios', en: 'Regions & Municipalities', ca: 'Territoris', gl: 'Territorios', eu: 'Lurraldeak' },
		desc: { es: '19 comunidades, 52 provincias y más de 8.100 municipios comparados', en: '19 regions, 52 provinces and 8,100+ municipalities compared', ca: '19 comunitats, 52 províncies i +8.100 municipis', gl: '19 comunidades, 52 provincias e +8.100 concellos', eu: '19 erkidego, 52 probintzia eta +8.100 udalerri' },
		claves: 'territorios comunidades autonomas provincias municipios pueblos españa mapa'
	},
	{
		href: '/territorios/municipios',
		icono: '🏘️',
		titulo: { es: 'Tu municipio en datos (+8.100 ayuntamientos)', en: 'Your municipality in data (8,100+ towns)', ca: 'El teu municipi en dades', gl: 'O teu concello en datos', eu: 'Zure udalerria datuetan' },
		desc: { es: 'Población, presupuesto, deuda, renta, alquiler, coches, delitos y alcalde de cada pueblo', en: 'Population, budget, debt, income, rent, cars, crime and mayor of every town', ca: 'Població, pressupost, deute, renda i alcalde de cada municipi', gl: 'Poboación, orzamento, débeda, renda e alcalde de cada concello', eu: 'Udalerri bakoitzeko biztanleria, aurrekontua, zorra, errenta eta alkatea' },
		claves: 'municipio ayuntamiento pueblo alcalde deuda municipal presupuesto padron habitantes barrios'
	},
	{
		href: '/varios/ciudades',
		icono: '🏙️',
		titulo: { es: 'Ciudades de España y Europa', en: 'Spanish & European cities', ca: 'Ciutats d’Espanya i d’Europa', gl: 'Cidades de España e de Europa', eu: 'Espainiako eta Europako hiriak' },
		desc: { es: 'Comparativa de grandes ciudades españolas y europeas en renta, vivienda, población y empleo', en: 'Comparative data on large Spanish and European cities: income, housing, population and jobs', ca: 'Comparativa de grans ciutats en renda, habitatge i ocupació', gl: 'Comparativa de grandes cidades en renda, vivenda e emprego', eu: 'Hiri handien alderaketa errentan, etxebizitzan eta enpleguan' },
		claves: 'ciudades grandes ciudades urbes comparativa municipios metropolis madrid barcelona valencia sevilla europa'
	},
	{
		href: '/demografia',
		icono: '👪',
		titulo: { es: 'Demografía y población', en: 'Demographics & Population', ca: 'Demografia i població', gl: 'Demografía e poboación', eu: 'Demografia eta biztanleria' },
		desc: { es: 'Evolución de la población, natalidad, envejecimiento, pirámides y hogares', en: 'Population trends, birth rates, ageing, pyramids and households', ca: 'Evolució de la població, natalitat, envelliment i llars', gl: 'Evolución da poboación, natalidade, envellecemento e fogares', eu: 'Biztanleriaren bilakaera, jaiotza-tasa, zahartzea eta etxeak' },
		claves: 'demografia poblacion habitantes padron nacimientos defunciones natalidad fecundidad envejecimiento hogares piramide'
	},
	{
		href: '/demografia/natalidad',
		icono: '👶',
		titulo: { es: 'Natalidad, fecundidad y mortalidad', en: 'Births, fertility & mortality', ca: 'Natalitat i fecunditat', gl: 'Natalidade e fecundidade', eu: 'Jaiotza-tasa eta ugalkortasuna' },
		desc: { es: 'Nacimientos y defunciones por 1.000 hab., hijos por mujer y edad media a la maternidad', en: 'Births and deaths per 1,000 people, fertility rate and age at motherhood', ca: 'Naixements, defuncions i fills per dona', gl: 'Nacementos, defuncións e fillos por muller', eu: 'Jaiotzak, heriotzak eta seme-alabak emakumeko' },
		claves: 'natalidad fecundidad nacimientos bebes hijos por mujer madres mortalidad defunciones crecimiento vegetativo'
	},
	{
		href: '/demografia/estructura-edades',
		icono: '🔺',
		titulo: { es: 'Edades, envejecimiento y pirámide de población', en: 'Age structure, ageing & population pyramid', ca: 'Edats i envelliment', gl: 'Idades e envellecemento', eu: 'Adinak eta zahartzea' },
		desc: { es: 'Pirámides de población desde 1971, mayores de 65 y 80 años y tasa de dependencia', en: 'Population pyramids since 1971, over-65s, over-80s and dependency ratio', ca: 'Piràmides de població, majors de 65 anys i dependència', gl: 'Pirámides de poboación, maiores de 65 anos e dependencia', eu: 'Biztanleria-piramideak, 65 urtetik gorakoak eta mendekotasuna' },
		claves: 'piramide poblacion edades envejecimiento mayores jubilados dependencia edad media centenarios'
	},
	{
		href: '/economia',
		icono: '📊',
		titulo: { es: 'Economía', en: 'Economy', ca: 'Economia', gl: 'Economía', eu: 'Ekonomia' },
		desc: { es: 'PIB por habitante, sectores, empleo, salarios reales, paro, inflación, turismo y empresas', en: 'GDP per capita, sectors, jobs, real wages, unemployment, inflation, tourism and business', ca: 'PIB per habitant, ocupació, salaris, atur i inflació', gl: 'PIB por habitante, emprego, salarios, paro e inflación', eu: 'BPGd biztanleko, enplegua, soldatak, langabezia eta inflazioa' },
		claves: 'economia pib paro empleo salarios inflacion ipc empresas turismo exportaciones industria'
	},
	{
		href: '/economia/pib',
		icono: '📈',
		titulo: { es: 'PIB por habitante y crecimiento económico', en: 'GDP per capita & economic growth', ca: 'PIB per habitant i creixement', gl: 'PIB por habitante e crecemento', eu: 'BPGd biztanleko eta hazkundea' },
		desc: { es: 'PIB real per cápita, crecimiento trimestral, componentes de la demanda y brecha con la UE', en: 'Real GDP per capita, quarterly growth, demand breakdown and EU comparison', ca: 'PIB real per càpita i comparació amb la UE', gl: 'PIB real per cápita e comparación coa UE', eu: 'BPGd erreala biztanleko eta EBrekin alderaketa' },
		claves: 'pib producto interior bruto renta per capita crecimiento economico recesion eurostat'
	},
	{
		href: '/economia/paro',
		icono: '👷',
		titulo: { es: 'Paro y mercado laboral (EPA)', en: 'Unemployment & labour market (EPA)', ca: 'Atur i mercat laboral', gl: 'Paro e mercado laboral', eu: 'Langabezia eta lan-merkatua' },
		desc: { es: 'Tasa de paro general y juvenil, evolución histórica desde 1976 y comparativa europea', en: 'Overall and youth unemployment rate, historical series and EU comparison', ca: 'Taxa d’atur general i juvenil (EPA)', gl: 'Taxa de paro xeral e xuvenil (EPA)', eu: 'Langabezia-tasa orokorra eta gazteena (EPA)' },
		claves: 'paro desempleo epa sepe empleo trabajo ocupados paro juvenil parados'
	},
	{
		href: '/economia/salarios',
		icono: '💶',
		titulo: { es: 'Salarios y poder adquisitivo', en: 'Wages & purchasing power', ca: 'Salaris i poder adquisitiu', gl: 'Salarios e poder adquisitivo', eu: 'Soldatak eta erosteko ahalmena' },
		desc: { es: 'Salario medio y mediano descontada la inflación, SMI, sectores y deciles salariales', en: 'Mean and median real wages adjusted for inflation, minimum wage, sectors and deciles', ca: 'Salari mitjà i medià descomptada la inflació i SMI', gl: 'Salario medio e mediano descontada a inflación e SMI', eu: 'Batez besteko soldata erreala eta LGS' },
		claves: 'salarios sueldos nomina poder adquisitivo smi salario minimo interprofesional coste laboral'
	},
	{
		href: '/economia/ipc',
		icono: '🛒',
		titulo: { es: 'Inflación y precios (IPC)', en: 'Inflation & consumer prices (CPI)', ca: 'Inflació i preus (IPC)', gl: 'Inflación e prezos (IPC)', eu: 'Inflazioa eta prezioak (KPI)' },
		desc: { es: 'IPC general y subyacente, cesta de la compra, alimentos y precios de la energía', en: 'Headline and core CPI, food prices and energy inflation', ca: 'IPC general, subjacent i cistella de la compra', gl: 'IPC xeral, subxacente e cesta da compra', eu: 'KPI orokorra, azpikoa eta erosketa-saskia' },
		claves: 'inflacion ipc precios cesta compra alimentos vida carestia deflactor'
	},
	{
		href: '/economia/turismo',
		icono: '🏖️',
		titulo: { es: 'Turismo y viviendas turísticas', en: 'Tourism & holiday rentals', ca: 'Turisme i pisos turístics', gl: 'Turismo e vivendas turísticas', eu: 'Turismoa eta etxebizitza turistikoak' },
		desc: { es: 'Turistas internacionales por habitante, gasto turístico real, hoteles y pisos turísticos', en: 'International tourists per capita, real tourism spending, hotels and holiday apartments', ca: 'Turistes per habitant, despesa i pisos turístics', gl: 'Turistas por habitante, gasto e pisos turísticos', eu: 'Turistak biztanleko, gastua eta pisu turistikoak' },
		claves: 'turismo turistas hoteles apartamentos viviendas turisticas airbnb frontur egatur'
	},
	{
		href: '/economia/empresas',
		icono: '🏢',
		titulo: { es: 'Empresas, autónomos e I+D', en: 'Businesses, self-employed & R&D', ca: 'Empreses, autònoms i R+D', gl: 'Empresas, autónomos e I+D', eu: 'Enpresak, autonomoak eta I+G' },
		desc: { es: 'Tejido empresarial por tamaño, creación y disolución de sociedades, autónomos e inversión en I+D', en: 'Firm size, company creations and insolvencies, self-employed workers and R&D spending', ca: 'Empreses per mida, autònoms i inversió en R+D', gl: 'Empresas por tamaño, autónomos e investimento en I+D', eu: 'Enpresak tamainaren arabera, autonomoak eta I+G inbertsioa' },
		claves: 'empresas pymes autonomos sociedades concursos quiebras investigacion innovacion i+d patentes'
	},
	{
		href: '/vivienda',
		icono: '🏠',
		titulo: { es: 'Vivienda', en: 'Housing', ca: 'Habitatge', gl: 'Vivenda', eu: 'Etxebizitza' },
		desc: { es: 'Precio de compra y alquiler real, años de salario, compraventas, hipotecas, obra nueva y vivienda pública', en: 'Real house prices and rents, affordability, sales, mortgages, new builds and social housing', ca: 'Preu de compra i lloguer real, esforç, compravendes i hipoteques', gl: 'Prezo de compra e alugueiro real, esforzo, compravendas e hipotecas', eu: 'Etxebizitzaren prezioa, alokairua, ahalegina eta hipotekak' },
		claves: 'vivienda pisos casas precios alquiler hipotecas compraventas obra nueva vivienda publica vpo'
	},
	{
		href: '/vivienda/alquiler',
		icono: '🔑',
		titulo: { es: 'Precio del alquiler por municipio y provincia', en: 'Rent prices by municipality and province', ca: 'Preu del lloguer per municipi', gl: 'Prezo do alugueiro por concello', eu: 'Alokairuaren prezioa udalerrika' },
		desc: { es: 'Alquiler mediano mensual según las declaraciones del IRPF (SERPAVI) descontada la inflación', en: 'Median monthly rent from tax records (SERPAVI) adjusted for inflation', ca: 'Lloguer medià mensual amb dades de l’IRPF (SERPAVI)', gl: 'Alugueiro mediano mensual con datos do IRPF (SERPAVI)', eu: 'Hileko alokairu medianoa PFEZ datuekin (SERPAVI)' },
		claves: 'alquiler renta mensual pisos arrendamiento serpavi caseros inquilinos'
	},
	{
		href: '/vivienda/vivienda-publica',
		icono: '🏘️',
		titulo: { es: 'Vivienda pública y social en alquiler', en: 'Public & social rental housing', ca: 'Habitatge públic de lloguer', gl: 'Vivenda pública en alugueiro', eu: 'Alokairuko etxebizitza publikoa' },
		desc: { es: 'Parque público de alquiler por 1.000 hab. por comunidad y municipio frente a Europa', en: 'Social rental housing stock per 1,000 inhabitants by region and municipality vs Europe', ca: 'Parc públic de lloguer per 1.000 hab. davant Europa', gl: 'Parque público de alugueiro por 1.000 hab. fronte a Europa', eu: 'Alokairuko etxebizitza publikoa 1.000 biztanleko Europarekin alderatuta' },
		claves: 'vivienda publica social vpo vpp alquiler social parque publico'
	},
	{
		href: '/cuentas-publicas',
		icono: '🏛️',
		titulo: { es: 'Cuentas públicas', en: 'Public Finances', ca: 'Comptes públics', gl: 'Contas públicas', eu: 'Kontu publikoak' },
		desc: { es: 'Ingresos, gastos, déficit, deuda pública, pensiones y empleo público con flujo Sankey', en: 'Revenue, spending, deficit, public debt, pensions and public employment with Sankey flow', ca: 'Ingressos, despeses, dèficit, deute, pensions i ocupació pública', gl: 'Ingresos, gastos, déficit, débeda, pensións e emprego público', eu: 'Diru-sarrerak, gastuak, defizita, zorra, pentsioak eta enplegu publikoa' },
		claves: 'cuentas publicas impuestos gasto publico deficit deuda hacienda presupuestos estado sankey'
	},
	{
		href: '/cuentas-publicas/pensiones',
		icono: '👵',
		titulo: { es: 'Pensiones y Seguridad Social', en: 'Pensions & Social Security', ca: 'Pensions i Seguretat Social', gl: 'Pensións e Seguridade Social', eu: 'Pentsioak eta Gizarte Segurantza' },
		desc: { es: 'Pensión media real, gasto en % del PIB, cotizantes por pensionista y brecha entre comunidades', en: 'Real average pension, spending as % of GDP, contributors per pensioner and regional gap', ca: 'Pensió mitjana real, despesa en % del PIB i cotitzants per pensionista', gl: 'Pensión media real, gasto en % do PIB e cotizantes por pensionista', eu: 'Batez besteko pentsio erreala, BPGd-aren % eta kotizatzaileak pentsioduneko' },
		claves: 'pensiones jubilacion pensionistas seguridad social cotizantes gasto pensiones'
	},
	{
		href: '/cuentas-publicas/empleo-publico',
		icono: '🪪',
		titulo: { es: 'Empleo público y funcionarios', en: 'Public sector employment & civil servants', ca: 'Ocupació pública i funcionaris', gl: 'Emprego público e funcionarios', eu: 'Enplegu publikoa eta funtzionarioak' },
		desc: { es: 'Empleados públicos por habitante y administración, salarios frente al sector privado y coste', en: 'Public employees per capita by administration, public vs private wages and total cost', ca: 'Empleats públics per habitant, administració i sou', gl: 'Empregados públicos por habitante, administración e soldo', eu: 'Enplegatu publikoak biztanleko, administrazioka eta soldata' },
		claves: 'empleo publico funcionarios interinos empleados publicos administracion sueldos publicos'
	},
	{
		href: '/energia-clima',
		icono: '⚡',
		titulo: { es: 'Energía y clima', en: 'Energy & Climate', ca: 'Energia i clima', gl: 'Enerxía e clima', eu: 'Energia eta klima' },
		desc: { es: 'Mix eléctrico, sistema en directo, récords, centrales, almacenamiento, emisiones, embalses, calor e incendios', en: 'Power mix, live grid, records, power plants, storage, emissions, reservoirs, heat and wildfires', ca: 'Mix elèctric, sistema en directe, emissions, embassaments, calor i incendis', gl: 'Mix eléctrico, sistema en directo, emisións, encoros, calor e incendios', eu: 'Mix elektrikoa, zuzenekoa, isuriak, urtegiak, beroa eta suteak' },
		claves: 'energia clima electricidad renovables nuclear gas carbon emisiones co2 embalses sequia incendios calor temperaturas'
	},
	{
		href: '/energia-clima/directo',
		icono: '📡',
		titulo: { es: 'El sistema eléctrico en directo (cada 5 min)', en: 'Live electricity grid (every 5 min)', ca: 'El sistema elèctric en directe', gl: 'O sistema eléctrico en directo', eu: 'Sistema elektrikoa zuzenean' },
		desc: { es: 'Demanda, generación por tecnología, intercambios internacionales y precio de la luz (OMIE y PVPC)', en: 'Live demand, generation mix, international exchanges and electricity prices (OMIE & PVPC)', ca: 'Demanda, generació i preu de la llum en temps real', gl: 'Demanda, xeración e prezo da luz en tempo real', eu: 'Eskaria, sorkuntza eta argindarraren prezioa denbora errealean' },
		claves: 'electricidad directo tiempo real precio luz hoy pvpc omie mwh kwh red electrica ree'
	},
	{
		href: '/energia-clima/embalses',
		icono: '💧',
		titulo: { es: 'Agua embalsada y sequía por cuencas', en: 'Water reservoirs & drought by basin', ca: 'Aigua embassada i sequera', gl: 'Auga embalsada e seca', eu: 'Urtegiak eta lehortea' },
		desc: { es: 'Estado semanal de cada embalse y cuenca hidrográfica frente a la media de 10 años', en: 'Weekly reservoir levels by river basin compared with the 10-year average', ca: 'Estat setmanal dels embassaments per conca', gl: 'Estado semanal dos encoros por bacía', eu: 'Urtegien asteroko egoera arroka' },
		claves: 'embalses agua pantanos reserva hidrica sequia cuencas miteco'
	},
	{
		href: '/energia-clima/incendios',
		icono: '🔥',
		titulo: { es: 'Incendios forestales y mapa satelital', en: 'Wildfires & satellite map', ca: 'Incendis forestals', gl: 'Incendios forestais', eu: 'Baso-suteak' },
		desc: { es: 'Hectáreas quemadas desde 2000, perímetros EFFIS y focos activos por satélite', en: 'Burned area since 2000, EFFIS perimeters and active satellite hotspots', ca: 'Hectàrees cremades i mapa d’incendis', gl: 'Hectáreas queimadas e mapa de incendios', eu: 'Erretako hektareak eta suteen mapa' },
		claves: 'incendios forestales fuego hectareas quemadas effis natura 2000'
	},
	{
		href: '/movilidad',
		icono: '🚦',
		titulo: { es: 'Movilidad y transporte', en: 'Mobility & Transport', ca: 'Mobilitat i transport', gl: 'Mobilidade e transporte', eu: 'Mugikortasuna eta garraioa' },
		desc: { es: 'Coche eléctrico, marcas y modelos, parque móvil, puntos de recarga, transporte público, tren, carreteras, aeropuertos y gasolineras', en: 'Electric cars, brands, vehicle fleet, EV chargers, public transit, rail, roads, airports and fuel prices', ca: 'Cotxe elèctric, parc de vehicles, recàrrega, transport públic, tren i aeroports', gl: 'Coche eléctrico, parque móbil, recarga, transporte público, tren e aeroportos', eu: 'Auto elektrikoa, ibilgailuak, garraio publikoa, trena eta aireportuak' },
		claves: 'movilidad coches vehiculos dgt electrico hibrido matriculaciones transporte publico metro ave tren aeropuertos aena carreteras gasolineras'
	},
	{
		href: '/movilidad/gasolineras',
		icono: '⛽',
		titulo: { es: 'Gasolineras y precio de los carburantes', en: 'Fuel stations & petrol/diesel prices', ca: 'Benzineres i preu dels carburants', gl: 'Gasolineiras e prezo dos carburantes', eu: 'Gasolindegiak eta erregaien prezioa' },
		desc: { es: 'Las 11.500 gasolineras por marca, municipios sin surtidor y precio real de gasolina y diésel desde 2007', en: '11,500 fuel stations by brand, towns without a pump and real petrol/diesel prices since 2007', ca: 'Les 11.500 benzineres i el preu real del gasoil i la gasolina', gl: 'As 11.500 gasolineiras e o prezo real do gasóleo e a gasolina', eu: '11.500 gasolindegiak eta gasolioaren zein gasolinaren prezio erreala' },
		claves: 'gasolineras gasolina diesel gasoleo carburantes combustible precio litro impuestos'
	},
	{
		href: '/sociedad',
		icono: '👥',
		titulo: { es: 'Sociedad', en: 'Society', ca: 'Societat', gl: 'Sociedade', eu: 'Gizartea' },
		desc: { es: 'Criminalidad, salud, inmigración, renta y desigualdad, educación y elecciones', en: 'Crime, health, immigration, income & inequality, education and elections', ca: 'Criminalitat, salut, immigració, renda, educació i eleccions', gl: 'Criminalidade, saúde, inmigración, renda, educación e eleccións', eu: 'Kriminalitatea, osasuna, immigrazioa, errenta, hezkuntza eta hauteskundeak' },
		claves: 'sociedad criminalidad delitos salud sanidad inmigracion extranjeros desigualdad pobreza educacion elecciones'
	},
	{
		href: '/sociedad/criminalidad',
		icono: '🚨',
		titulo: { es: 'Criminalidad y seguridad ciudadana', en: 'Crime & public safety', ca: 'Criminalitat i seguretat', gl: 'Criminalidade e seguridade', eu: 'Kriminalitatea eta segurtasuna' },
		desc: { es: 'Delitos conocidos por tipo, comunidad, provincia y municipio, cibercriminalidad y condenados', en: 'Recorded offences by type, region, province and municipality, cybercrime and convictions', ca: 'Delictes coneguts per tipus i municipi', gl: 'Delitos coñecidos por tipo e concello', eu: 'Ezagututako delituak motaren eta udalerriaren arabera' },
		claves: 'criminalidad delitos robos homicidios hurtos seguridad interior policia cibercriminalidad'
	},
	{
		href: '/sociedad/salud',
		icono: '🩺',
		titulo: { es: 'Salud, listas de espera y mortalidad', en: 'Health, waiting lists & mortality', ca: 'Salut i llistes d’espera', gl: 'Saúde e listas de espera', eu: 'Osasuna eta itxaron-zerrendak' },
		desc: { es: 'Esperanza de vida, causas de muerte, listas de espera quirúrgicas y de consultas, médicos y camas', en: 'Life expectancy, causes of death, surgical and specialist waiting lists, doctors and beds', ca: 'Esperança de vida, causes de mort i llistes d’espera', gl: 'Esperanza de vida, causas de morte e listas de espera', eu: 'Bizi-itxaropena, heriotza-kausak eta itxaron-zerrendak' },
		claves: 'salud sanidad esperanza de vida listas de espera medicos hospitales camas mortalidad suicidios tumores'
	},
	{
		href: '/sociedad/inmigracion',
		icono: '🌍',
		titulo: { es: 'Inmigración, asilo y nacionalizaciones', en: 'Immigration, asylum & naturalisations', ca: 'Immigració i nacionalitzacions', gl: 'Inmigración e nacionalizacións', eu: 'Immigrazioa eta nazionalizazioak' },
		desc: { es: 'Población extranjera por origen y provincia, saldo migratorio, llegadas irregulares y asilo', en: 'Foreign population by origin and province, net migration, irregular arrivals and asylum', ca: 'Població estrangera per origen, saldo migratori i asil', gl: 'Poboación estranxeira por orixe, saldo migratorio e asilo', eu: 'Atzerriko biztanleria jatorriaren arabera, migrazio-saldoa eta asiloa' },
		claves: 'inmigracion extranjeros migrantes nacionalidad asilo pateras llegadas irregulares'
	},
	{
		href: '/sociedad/desigualdad',
		icono: '⚖️',
		titulo: { es: 'Renta, pobreza y desigualdad (Atlas de renta)', en: 'Income, poverty & inequality', ca: 'Renda, pobresa i desigualtat', gl: 'Renda, pobreza e desigualdade', eu: 'Errenta, pobrezia eta desberdintasuna' },
		desc: { es: 'Renta media por persona, tasa AROPE de riesgo de pobreza, índice de Gini y S80/S20', en: 'Average income per person, AROPE poverty risk rate, Gini index and S80/S20 ratio', ca: 'Renda mitjana, pobresa AROPE i índex de Gini', gl: 'Renda media, pobreza AROPE e índice de Gini', eu: 'Batez besteko errenta, AROPE pobrezia eta Gini indizea' },
		claves: 'renta hogares pobreza arope desigualdad gini ingresos ricos pobres'
	},
	{
		href: '/sociedad/educacion',
		icono: '🎓',
		titulo: { es: 'Educación, abandono escolar y PISA', en: 'Education, early school leaving & PISA', ca: 'Educació, abandonament escolar i PISA', gl: 'Educación, abandono escolar e PISA', eu: 'Hezkuntza, eskola-uztea eta PISA' },
		desc: { es: 'Abandono educativo temprano, informe PISA, gasto por alumno, FP, ninis y nivel de estudios', en: 'Early school leaving, PISA scores, spending per student, vocational training and educational attainment', ca: 'Abandonament escolar, PISA, FP i despesa per alumne', gl: 'Abandono escolar, PISA, FP e gasto por alumno', eu: 'Eskola-uzte goiztiarra, PISA, LH eta ikasleko gastua' },
		claves: 'educacion colegios universidades pisa abandono escolar fp formacion profesional ninis alumnos profesores'
	},
	{
		href: '/sociedad/elecciones',
		icono: '🗳️',
		titulo: { es: 'Elecciones desde 1977 (generales, municipales y europeas)', en: 'Elections since 1977 (general, local & European)', ca: 'Eleccions des del 1977', gl: 'Eleccións desde 1977', eu: 'Hauteskundeak 1977tik' },
		desc: { es: 'Participación, voto por partido y bloque, escaños y partido más votado en cada provincia y municipio', en: 'Turnout, vote share by party and bloc, seats and winner in every province and municipality', ca: 'Participació, vot per partit i guanyador a cada municipi', gl: 'Participación, voto por partido e gañador en cada concello', eu: 'Parte-hartzea, alderdikako botoa eta irabazlea udalerri bakoitzean' },
		claves: 'elecciones votos escaños congreso generales municipales europeas psoe pp vox sumar podemos'
	},
	{
		href: '/medios',
		icono: '📰',
		titulo: { es: 'Medios de comunicación y dinero público', en: 'Media & public funding', ca: 'Mitjans de comunicació', gl: 'Medios de comunicación', eu: 'Hedabideak' },
		desc: { es: 'RTVE y televisiones autonómicas, publicidad institucional y subvenciones a la prensa', en: 'RTVE and regional public broadcasters, institutional advertising and press subsidies', ca: 'Televisions públiques, publicitat institucional i subvencions', gl: 'Televisións públicas, publicidade institucional e subvencións', eu: 'Telebista publikoak, publizitate instituzionala eta dirulaguntzak' },
		claves: 'medios comunicacion televisiones publicas rtve publicidad institucional subvenciones prensa'
	},
	{
		href: '/transparencia',
		icono: '🔍',
		titulo: { es: 'Transparencia y rendición de cuentas', en: 'Transparency & accountability', ca: 'Transparència i rendició de comptes', gl: 'Transparencia e rendición de contas', eu: 'Gardentasuna eta kontu-ematea' },
		desc: { es: 'Cuentas municipales, portales de transparencia, decretos-ley, indultos, presupuestos prorrogados, contratación y subvenciones', en: 'Local council accounts, transparency portals, decree-laws, pardons, budget rollovers, procurement and subsidies', ca: 'Comptes municipals, decrets llei, indults, pressupostos, contractació i subvencions', gl: 'Contas municipais, decretos-lei, indultos, orzamentos, contratación e subvencións', eu: 'Udal-kontuak, dekretuak, indultuak, aurrekontuak, kontratazioa eta dirulaguntzak' },
		claves: 'transparencia corrupcion indultos decretos presupuestos prorrogados contratacion publica subvenciones consejo transparencia'
	},
	{
		href: '/transparencia/contratacion',
		icono: '📑',
		titulo: { es: 'Contratación pública y contratos menores', en: 'Public procurement & minor contracts', ca: 'Contractació pública', gl: 'Contratación pública', eu: 'Kontratazio publikoa' },
		desc: { es: 'Volumen licitado, procedimientos abiertos frente a sin publicidad, único licitador y contratos menores', en: 'Procurement volume, open vs non-advertised tenders, single-bidder contracts and minor contracts', ca: 'Licitacions, contractes menors i procediments sense publicitat', gl: 'Licitacións, contratos menores e procedementos sen publicidade', eu: 'Lizitazioak, kontratu txikiak eta publizitaterik gabeko prozedurak' },
		claves: 'contratacion publica licitaciones adjudicaciones contratos menores a dedo oirescon plsp'
	},
	{
		href: '/transparencia/subvenciones',
		icono: '💶',
		titulo: { es: 'Subvenciones públicas y concesión directa', en: 'Public subsidies & direct grants', ca: 'Subvencions públiques', gl: 'Subvencións públicas', eu: 'Dirulaguntza publikoak' },
		desc: { es: 'Importe concedido por Estado, comunidades y ayuntamientos y peso de las subvenciones sin concurrencia (BDNS)', en: 'Subsidies granted by central, regional and local governments and share of direct grants (BDNS)', ca: 'Subvencions amb concurrència i de concessió directa (BDNS)', gl: 'Subvencións con concorrencia e de concesión directa (BDNS)', eu: 'Lehia bidezko eta zuzeneko dirulaguntzak (BDNS)' },
		claves: 'subvenciones ayudas publicas bdns concesion directa nominativas concurrencia igae'
	},
	{
		href: '/transparencia/consejo-transparencia',
		icono: '⚖️',
		titulo: { es: 'Reclamaciones al Consejo de Transparencia (CTBG)', en: 'Freedom of information appeals (CTBG)', ca: 'Reclamacions al Consell de Transparència', gl: 'Reclamacións ao Consello de Transparencia', eu: 'Gardentasun Kontseiluko erreklamazioak' },
		desc: { es: 'Solicitudes de acceso a la información pública, reclamaciones por denegación o silencio y ministerios más reclamados', en: 'FOI requests, appeals against denials or administrative silence and most-appealed ministries', ca: 'Sol·licituds d’accés a la informació i reclamacions al CTBG', gl: 'Solicitudes de acceso á información e reclamacións ao CTBG', eu: 'Informazio publikoa eskuratzeko eskaerak eta erreklamazioak' },
		claves: 'consejo transparencia ctbg derecho acceso informacion publica silencio administrativo reclamaciones ministerios'
	},
	{
		href: '/varios',
		icono: '🧭',
		titulo: { es: 'Explorar datos, mapas y comparativas', en: 'Explore data, maps & comparisons', ca: 'Explorar dades i mapes', gl: 'Explorar datos e mapas', eu: 'Datuak eta mapak esploratu' },
		desc: { es: 'España en Europa, España en el mundo, 900 ciudades europeas, catálogo de indicadores y explorador de mapas', en: 'Spain in Europe, Spain in the world, 900 European cities, indicator catalogue and map explorer', ca: 'Espanya a Europa, al món, ciutats, indicadors i explorador de mapes', gl: 'España en Europa, no mundo, cidades, indicadores e explorador de mapas', eu: 'Espainia Europan, munduan, hiriak, adierazleak eta mapak' },
		claves: 'explorar datos varios europa mundo ciudades mapas indicadores datos abiertos'
	},
	{
		href: '/varios/indicadores',
		icono: '📋',
		titulo: { es: 'Catálogo de todos los indicadores', en: 'Full indicator catalogue', ca: 'Catàleg d’indicadors', gl: 'Catálogo de indicadores', eu: 'Adierazleen katalogoa' },
		desc: { es: 'Todas las series estadísticas del sitio con su último valor, unidad y fuente oficial', en: 'All statistical series on the site with their latest value, unit and official source', ca: 'Totes les sèries estadístiques amb l’última dada i la font', gl: 'Todas as series estatísticas co último dato e a fonte', eu: 'Serie estatistiko guztiak azken datuarekin eta iturriarekin' },
		claves: 'indicadores metricas series catalogo tabla descargar'
	},
	{
		href: '/fuentes',
		icono: '📚',
		titulo: { es: 'Fuentes oficiales y trazabilidad', en: 'Official sources & data lineage', ca: 'Fonts oficials i traçabilitat', gl: 'Fontes oficiais e trazabilidade', eu: 'Iturri ofizialak eta trazabilitatea' },
		desc: { es: 'Más de 100 conjuntos de datos documentados: organismo, licencia, metodología y código de ingesta', en: '100+ documented datasets: agency, licence, methodology and ingestion code', ca: 'Més de 100 conjunts de dades documentats amb el seu llinatge', gl: 'Máis de 100 conxuntos de datos documentados coa súa liñaxe', eu: 'Dokumentatutako 100 datu-multzo baino gehiago' },
		claves: 'fuentes metodologia ine eurostat bde miteco dgt ree aemet licencias'
	}
];

export const INDICADORES_CLAVE = [
	{ href: '/economia/paro', icono: '📉', nombre: { es: 'Tasa de paro (EPA)', en: 'Unemployment rate (EPA)', ca: 'Taxa d’atur (EPA)', gl: 'Taxa de paro (EPA)', eu: 'Langabezia-tasa (EPA)' }, fuente: 'INE', claves: 'paro desempleo epa' },
	{ href: '/economia/ipc', icono: '🛒', nombre: { es: 'Inflación interanual (IPC)', en: 'Annual inflation (CPI)', ca: 'Inflació interanual (IPC)', gl: 'Inflación interanual (IPC)', eu: 'Urte arteko inflazioa (KPI)' }, fuente: 'INE', claves: 'ipc inflacion precios subyacente' },
	{ href: '/economia/pib', icono: '💶', nombre: { es: 'PIB real por habitante', en: 'Real GDP per capita', ca: 'PIB real per habitant', gl: 'PIB real por habitante', eu: 'BPGd erreala biztanleko' }, fuente: 'Eurostat / INE', claves: 'pib per capita crecimiento riqueza' },
	{ href: '/economia/salarios', icono: '💼', nombre: { es: 'Salario medio real y SMI', en: 'Real average wage & minimum wage', ca: 'Salari mitjà real i SMI', gl: 'Salario medio real e SMI', eu: 'Batez besteko soldata erreala eta LGS' }, fuente: 'INE', claves: 'salario medio mediano smi sueldo' },
	{ href: '/cuentas-publicas', icono: '🏛️', nombre: { es: 'Deuda pública (% del PIB) y déficit fiscal', en: 'Public debt (% of GDP) & fiscal deficit', ca: 'Deute públic (% PIB) i dèficit', gl: 'Débeda pública (% PIB) e déficit', eu: 'Zor publikoa (% BPGd) eta defizita' }, fuente: 'Banco de España / Eurostat', claves: 'deuda publica deficit pib endeudamiento' },
	{ href: '/cuentas-publicas/pensiones', icono: '👵', nombre: { es: 'Gasto en pensiones y pensión media', en: 'Pension spending & average pension', ca: 'Despesa en pensions i pensió mitjana', gl: 'Gasto en pensións e pensión media', eu: 'Pentsio-gastua eta batez besteko pentsioa' }, fuente: 'Seguridad Social', claves: 'pensiones jubilacion cotizantes' },
	{ href: '/vivienda/precios', icono: '🏠', nombre: { es: 'Precio del m² de vivienda libre (real)', en: 'Real house price per m²', ca: 'Preu del m² d’habitatge (real)', gl: 'Prezo do m² de vivenda (real)', eu: 'Etxebizitzaren m²-ko prezio erreala' }, fuente: 'MIVAU / INE', claves: 'precio vivienda metro cuadrado tasado ipv' },
	{ href: '/vivienda/alquiler', icono: '🔑', nombre: { es: 'Alquiler mensual mediano (SERPAVI)', en: 'Median monthly rent (SERPAVI)', ca: 'Lloguer mensual medià (SERPAVI)', gl: 'Alugueiro mensual mediano (SERPAVI)', eu: 'Hileko alokairu medianoa (SERPAVI)' }, fuente: 'MIVAU / AEAT', claves: 'alquiler mediano mensual serpavi' },
	{ href: '/vivienda/esfuerzo', icono: '⚖️', nombre: { es: 'Años de salario para comprar una vivienda de 90 m²', en: 'Years of salary to buy a 90 m² home', ca: 'Anys de salari per comprar un pis de 90 m²', gl: 'Anos de salario para mercar un piso de 90 m²', eu: '90 m²-ko etxea erosteko soldata-urteak' }, fuente: 'MIVAU / INE', claves: 'esfuerzo vivienda años salario hipoteca' },
	{ href: '/energia-clima/mix-electrico', icono: '⚡', nombre: { es: 'Cuota de generación eléctrica renovable (%)', en: 'Renewable electricity generation share (%)', ca: 'Quota d’electricitat renovable (%)', gl: 'Cota de electricidade renovable (%)', eu: 'Sorkuntza elektriko berriztagarriaren kuota (%)' }, fuente: 'REE', claves: 'renovables solar eolica mix electrico' },
	{ href: '/energia-clima/embalses', icono: '💧', nombre: { es: 'Reserva de agua embalsada (%)', en: 'Water reservoir storage (%)', ca: 'Reserva d’aigua embassada (%)', gl: 'Reserva de auga embalsada (%)', eu: 'Urtegiratutako ur-erreserba (%)' }, fuente: 'MITECO', claves: 'embalses agua pantanos sequia' },
	{ href: '/movilidad/coche-electrico', icono: '🔌', nombre: { es: 'Cuota de turismos nuevos enchufables (BEV + PHEV)', en: 'New plug-in car share (BEV + PHEV)', ca: 'Quota de turismes nous endollables', gl: 'Cota de turismos novos enchufables', eu: 'Turismo berri entxufagarrien kuota' }, fuente: 'DGT', claves: 'coche electrico hibrido enchufable matriculaciones bev phev' },
	{ href: '/sociedad/criminalidad', icono: '🚨', nombre: { es: 'Tasa de criminalidad (infracciones por 1.000 hab.)', en: 'Crime rate (offences per 1,000 people)', ca: 'Taxa de criminalitat (per 1.000 hab.)', gl: 'Taxa de criminalidade (por 1.000 hab.)', eu: 'Kriminalitate-tasa (1.000 biztanleko)' }, fuente: 'Ministerio del Interior', claves: 'tasa criminalidad delitos seguridad' },
	{ href: '/sociedad/salud', icono: '🩺', nombre: { es: 'Esperanza de vida al nacer y listas de espera', en: 'Life expectancy at birth & waiting lists', ca: 'Esperança de vida i llistes d’espera', gl: 'Esperanza de vida e listas de espera', eu: 'Bizi-itxaropena eta itxaron-zerrendak' }, fuente: 'INE / Sanidad', claves: 'esperanza vida listas espera cirugia' },
	{ href: '/transparencia/comparacion-internacional', icono: '🔎', nombre: { es: 'Índice de Percepción de la Corrupción (IPC / CPI)', en: 'Corruption Perceptions Index (CPI)', ca: 'Índex de Percepció de la Corrupció', gl: 'Índice de Percepción da Corrupción', eu: 'Ustelkeriaren Pertzepzio Indizea' }, fuente: 'Transparency International', claves: 'corrupcion transparencia indice cpi' }
];

// Las 19 comunidades autónomas y ciudades con estatuto de autonomía
const CCAA_BASE = [
	['Andalucía', 'andalucia', 'andalucia andaluz andaluza junta de andalucia sur'],
	['Aragón', 'aragon', 'aragon aragones aragonesa'],
	['Principado de Asturias', 'asturias', 'asturias asturiano asturiana principado oviedo gijon aviles'],
	['Illes Balears', 'illes-balears', 'illes balears islas baleares baleares balear mallorca menorca ibiza formentera palma'],
	['Canarias', 'canarias', 'canarias islas canarias canario canaria tenerife gran canaria las palmas'],
	['Cantabria', 'cantabria', 'cantabria cantabro santander torrelavega'],
	['Castilla y León', 'castilla-y-leon', 'castilla y leon cyl valladolid burgos leon salamanca palencia zamora avila segovia soria'],
	['Castilla-La Mancha', 'castilla-la-mancha', 'castilla la mancha clm toledo albacete ciudad real cuenca guadalajara'],
	['Cataluña', 'cataluna', 'cataluna catalunya catalan catalana generalitat barcelona girona lleida tarragona'],
	['Comunidad Valenciana', 'comunidad-valenciana', 'comunidad valenciana comunitat valenciana valencia valenciano alicante castellon generalitat'],
	['Extremadura', 'extremadura', 'extremadura extremeno badajoz caceres merida'],
	['Galicia', 'galicia', 'galicia galiza gallego galega xunta coruna vigo santiago lugo ourense pontevedra'],
	['Comunidad de Madrid', 'madrid', 'comunidad de madrid madrid cam region capital madrileno ciudad'],
	['Región de Murcia', 'murcia', 'region de murcia murcia murciano cartagena lorca'],
	['Comunidad Foral de Navarra', 'navarra', 'comunidad foral de navarra navarra nafarroa pamplona iruna navarro'],
	['País Vasco', 'pais-vasco', 'pais vasco euskadi euskal herria vasco bilbao donostia san sebastian vitoria gasteiz bizkaia gipuzkoa alava'],
	['La Rioja', 'la-rioja', 'la rioja rioja riojano logrono'],
	['Ceuta', 'ceuta', 'ceuta ciudad autonoma norte de africa'],
	['Melilla', 'melilla', 'melilla ciudad autonoma norte de africa']
];

// Las 52 provincias españolas con sus rutas exactas
const PROVINCIAS_BASE = [
	['Álava / Araba', 'pais-vasco', 'alava'],
	['Albacete', 'castilla-la-mancha', 'albacete'],
	['Alicante / Alacant', 'comunidad-valenciana', 'alicante'],
	['Almería', 'andalucia', 'almeria'],
	['Asturias', 'asturias', 'asturias'],
	['Ávila', 'castilla-y-leon', 'avila'],
	['Badajoz', 'extremadura', 'badajoz'],
	['Barcelona', 'cataluna', 'barcelona'],
	['Burgos', 'castilla-y-leon', 'burgos'],
	['Cáceres', 'extremadura', 'caceres'],
	['Cádiz', 'andalucia', 'cadiz'],
	['Cantabria', 'cantabria', 'cantabria'],
	['Castellón / Castelló', 'comunidad-valenciana', 'castellon'],
	['Ceuta', 'ceuta', 'ceuta'],
	['Ciudad Real', 'castilla-la-mancha', 'ciudad-real'],
	['Córdoba', 'andalucia', 'cordoba'],
	['A Coruña', 'galicia', 'a-coruna'],
	['Cuenca', 'castilla-la-mancha', 'cuenca'],
	['Gipuzkoa', 'pais-vasco', 'gipuzkoa'],
	['Girona', 'cataluna', 'girona'],
	['Granada', 'andalucia', 'granada'],
	['Guadalajara', 'castilla-la-mancha', 'guadalajara'],
	['Huelva', 'andalucia', 'huelva'],
	['Huesca', 'aragon', 'huesca'],
	['Illes Balears', 'illes-balears', 'illes-balears'],
	['Jaén', 'andalucia', 'jaen'],
	['León', 'castilla-y-leon', 'leon'],
	['Lleida', 'cataluna', 'lleida'],
	['Lugo', 'galicia', 'lugo'],
	['Madrid', 'madrid', 'madrid'],
	['Málaga', 'andalucia', 'malaga'],
	['Melilla', 'melilla', 'melilla'],
	['Murcia', 'murcia', 'murcia'],
	['Navarra', 'navarra', 'navarra'],
	['Ourense', 'galicia', 'ourense'],
	['Palencia', 'castilla-y-leon', 'palencia'],
	['Las Palmas', 'canarias', 'las-palmas'],
	['Pontevedra', 'galicia', 'pontevedra'],
	['La Rioja', 'la-rioja', 'la-rioja'],
	['Salamanca', 'castilla-y-leon', 'salamanca'],
	['Santa Cruz de Tenerife', 'canarias', 'santa-cruz-de-tenerife'],
	['Segovia', 'castilla-y-leon', 'segovia'],
	['Sevilla', 'andalucia', 'sevilla'],
	['Soria', 'castilla-y-leon', 'soria'],
	['Tarragona', 'cataluna', 'tarragona'],
	['Teruel', 'aragon', 'teruel'],
	['Toledo', 'castilla-la-mancha', 'toledo'],
	['Valencia / València', 'comunidad-valenciana', 'valencia'],
	['Valladolid', 'castilla-y-leon', 'valladolid'],
	['Bizkaia', 'pais-vasco', 'bizkaia'],
	['Zamora', 'castilla-y-leon', 'zamora'],
	['Zaragoza', 'aragon', 'zaragoza']
];

// Principales municipios y todas las capitales de provincia (+ciudades >40.000 hab.)
export const MUNICIPIOS_DESTACADOS = [
	{ cod_mun: '28079', municipio: 'Madrid', provincia: 'Madrid', poblacion: 3416771 },
	{ cod_mun: '08019', municipio: 'Barcelona', provincia: 'Barcelona', poblacion: 1702547 },
	{ cod_mun: '46250', municipio: 'València', provincia: 'Valencia', poblacion: 825948 },
	{ cod_mun: '41091', municipio: 'Sevilla', provincia: 'Sevilla', poblacion: 687488 },
	{ cod_mun: '50297', municipio: 'Zaragoza', provincia: 'Zaragoza', poblacion: 686986 },
	{ cod_mun: '29067', municipio: 'Málaga', provincia: 'Málaga', poblacion: 591637 },
	{ cod_mun: '30030', municipio: 'Murcia', provincia: 'Murcia', poblacion: 474617 },
	{ cod_mun: '07040', municipio: 'Palma', provincia: 'Illes Balears', poblacion: 431521 },
	{ cod_mun: '35016', municipio: 'Las Palmas de Gran Canaria', provincia: 'Las Palmas', poblacion: 380436 },
	{ cod_mun: '03014', municipio: 'Alicante / Alacant', provincia: 'Alicante', poblacion: 358720 },
	{ cod_mun: '48020', municipio: 'Bilbao', provincia: 'Bizkaia', poblacion: 348089 },
	{ cod_mun: '14021', municipio: 'Córdoba', provincia: 'Córdoba', poblacion: 322811 },
	{ cod_mun: '47186', municipio: 'Valladolid', provincia: 'Valladolid', poblacion: 300618 },
	{ cod_mun: '36057', municipio: 'Vigo', provincia: 'Pontevedra', poblacion: 293977 },
	{ cod_mun: '33024', municipio: 'Gijón', provincia: 'Asturias', poblacion: 268561 },
	{ cod_mun: '08101', municipio: "L'Hospitalet de Llobregat", provincia: 'Barcelona', poblacion: 279993 },
	{ cod_mun: '01059', municipio: 'Vitoria-Gasteiz', provincia: 'Álava', poblacion: 257968 },
	{ cod_mun: '15030', municipio: 'A Coruña', provincia: 'A Coruña', poblacion: 249261 },
	{ cod_mun: '03065', municipio: 'Elche / Elx', provincia: 'Alicante', poblacion: 243128 },
	{ cod_mun: '18087', municipio: 'Granada', provincia: 'Granada', poblacion: 232717 },
	{ cod_mun: '08279', municipio: 'Terrassa', provincia: 'Barcelona', poblacion: 225277 },
	{ cod_mun: '08015', municipio: 'Badalona', provincia: 'Barcelona', poblacion: 223506 },
	{ cod_mun: '33044', municipio: 'Oviedo', provincia: 'Asturias', poblacion: 220543 },
	{ cod_mun: '08187', municipio: 'Sabadell', provincia: 'Barcelona', poblacion: 216520 },
	{ cod_mun: '30016', municipio: 'Cartagena', provincia: 'Murcia', poblacion: 216961 },
	{ cod_mun: '11020', municipio: 'Jerez de la Frontera', provincia: 'Cádiz', poblacion: 213231 },
	{ cod_mun: '28092', municipio: 'Móstoles', provincia: 'Madrid', poblacion: 211265 },
	{ cod_mun: '38038', municipio: 'Santa Cruz de Tenerife', provincia: 'Santa Cruz de Tenerife', poblacion: 211359 },
	{ cod_mun: '31201', municipio: 'Pamplona / Iruña', provincia: 'Navarra', poblacion: 208243 },
	{ cod_mun: '04013', municipio: 'Almería', provincia: 'Almería', poblacion: 202675 },
	{ cod_mun: '28005', municipio: 'Alcalá de Henares', provincia: 'Madrid', poblacion: 199184 },
	{ cod_mun: '28058', municipio: 'Fuenlabrada', provincia: 'Madrid', poblacion: 190470 },
	{ cod_mun: '28074', municipio: 'Leganés', provincia: 'Madrid', poblacion: 190665 },
	{ cod_mun: '20069', municipio: 'Donostia / San Sebastián', provincia: 'Gipuzkoa', poblacion: 189093 },
	{ cod_mun: '28065', municipio: 'Getafe', provincia: 'Madrid', poblacion: 185810 },
	{ cod_mun: '09059', municipio: 'Burgos', provincia: 'Burgos', poblacion: 175821 },
	{ cod_mun: '02003', municipio: 'Albacete', provincia: 'Albacete', poblacion: 174137 },
	{ cod_mun: '39075', municipio: 'Santander', provincia: 'Cantabria', poblacion: 173635 },
	{ cod_mun: '12040', municipio: 'Castelló de la Plana', provincia: 'Castellón', poblacion: 180379 },
	{ cod_mun: '28007', municipio: 'Alcorcón', provincia: 'Madrid', poblacion: 171772 },
	{ cod_mun: '38023', municipio: 'San Cristóbal de La Laguna', provincia: 'Santa Cruz de Tenerife', poblacion: 159034 },
	{ cod_mun: '26089', municipio: 'Logroño', provincia: 'La Rioja', poblacion: 151164 },
	{ cod_mun: '06015', municipio: 'Badajoz', provincia: 'Badajoz', poblacion: 150190 },
	{ cod_mun: '29069', municipio: 'Marbella', provincia: 'Málaga', poblacion: 150725 },
	{ cod_mun: '37274', municipio: 'Salamanca', provincia: 'Salamanca', poblacion: 144866 },
	{ cod_mun: '21041', municipio: 'Huelva', provincia: 'Huelva', poblacion: 143290 },
	{ cod_mun: '25120', municipio: 'Lleida', provincia: 'Lleida', poblacion: 144739 },
	{ cod_mun: '43148', municipio: 'Tarragona', provincia: 'Tarragona', poblacion: 141151 },
	{ cod_mun: '41038', municipio: 'Dos Hermanas', provincia: 'Sevilla', poblacion: 138981 },
	{ cod_mun: '28106', municipio: 'Parla', provincia: 'Madrid', poblacion: 133004 },
	{ cod_mun: '28148', municipio: 'Torrejón de Ardoz', provincia: 'Madrid', poblacion: 137042 },
	{ cod_mun: '08121', municipio: 'Mataró', provincia: 'Barcelona', poblacion: 129870 },
	{ cod_mun: '24089', municipio: 'León', provincia: 'León', poblacion: 122243 },
	{ cod_mun: '11004', municipio: 'Algeciras', provincia: 'Cádiz', poblacion: 123639 },
	{ cod_mun: '08245', municipio: 'Santa Coloma de Gramenet', provincia: 'Barcelona', poblacion: 119862 },
	{ cod_mun: '28006', municipio: 'Alcobendas', provincia: 'Madrid', poblacion: 119416 },
	{ cod_mun: '11012', municipio: 'Cádiz', provincia: 'Cádiz', poblacion: 110914 },
	{ cod_mun: '23050', municipio: 'Jaén', provincia: 'Jaén', poblacion: 111888 },
	{ cod_mun: '32054', municipio: 'Ourense', provincia: 'Ourense', poblacion: 104891 },
	{ cod_mun: '43123', municipio: 'Reus', provincia: 'Tarragona', poblacion: 108479 },
	{ cod_mun: '35026', municipio: 'Telde', provincia: 'Las Palmas', poblacion: 103240 },
	{ cod_mun: '48013', municipio: 'Barakaldo', provincia: 'Bizkaia', poblacion: 100871 },
	{ cod_mun: '27028', municipio: 'Lugo', provincia: 'Lugo', poblacion: 99421 },
	{ cod_mun: '17079', municipio: 'Girona', provincia: 'Girona', poblacion: 107032 },
	{ cod_mun: '15078', municipio: 'Santiago de Compostela', provincia: 'A Coruña', poblacion: 99536 },
	{ cod_mun: '10037', municipio: 'Cáceres', provincia: 'Cáceres', poblacion: 96441 },
	{ cod_mun: '28127', municipio: 'Las Rozas de Madrid', provincia: 'Madrid', poblacion: 98086 },
	{ cod_mun: '30024', municipio: 'Lorca', provincia: 'Murcia', poblacion: 98447 },
	{ cod_mun: '11031', municipio: 'San Fernando', provincia: 'Cádiz', poblacion: 94867 },
	{ cod_mun: '08205', municipio: 'Sant Cugat del Vallès', provincia: 'Barcelona', poblacion: 97530 },
	{ cod_mun: '28134', municipio: 'San Sebastián de los Reyes', provincia: 'Madrid', poblacion: 94069 },
	{ cod_mun: '28123', municipio: 'Rivas-Vaciamadrid', provincia: 'Madrid', poblacion: 100275 },
	{ cod_mun: '08073', municipio: 'Cornellà de Llobregat', provincia: 'Barcelona', poblacion: 90303 },
	{ cod_mun: '11027', municipio: 'El Puerto de Santa María', provincia: 'Cádiz', poblacion: 89813 },
	{ cod_mun: '28115', municipio: 'Pozuelo de Alarcón', provincia: 'Madrid', poblacion: 88784 },
	{ cod_mun: '19130', municipio: 'Guadalajara', provincia: 'Guadalajara', poblacion: 89010 },
	{ cod_mun: '45168', municipio: 'Toledo', provincia: 'Toledo', poblacion: 86526 },
	{ cod_mun: '52001', municipio: 'Melilla', provincia: 'Melilla', poblacion: 85491 },
	{ cod_mun: '51001', municipio: 'Ceuta', provincia: 'Ceuta', poblacion: 83052 },
	{ cod_mun: '46244', municipio: 'Torrent', provincia: 'Valencia', poblacion: 87295 },
	{ cod_mun: '36038', municipio: 'Pontevedra', provincia: 'Pontevedra', poblacion: 83077 },
	{ cod_mun: '33004', municipio: 'Avilés', provincia: 'Asturias', poblacion: 75518 },
	{ cod_mun: '34120', municipio: 'Palencia', provincia: 'Palencia', poblacion: 76331 },
	{ cod_mun: '46131', municipio: 'Gandia', provincia: 'Valencia', poblacion: 78108 },
	{ cod_mun: '13034', municipio: 'Ciudad Real', provincia: 'Ciudad Real', poblacion: 75303 },
	{ cod_mun: '03031', municipio: 'Benidorm', provincia: 'Alicante', poblacion: 72342 },
	{ cod_mun: '49275', municipio: 'Zamora', provincia: 'Zamora', poblacion: 59259 },
	{ cod_mun: '40194', municipio: 'Segovia', provincia: 'Segovia', poblacion: 51011 },
	{ cod_mun: '22125', municipio: 'Huesca', provincia: 'Huesca', poblacion: 54136 },
	{ cod_mun: '16078', municipio: 'Cuenca', provincia: 'Cuenca', poblacion: 53512 },
	{ cod_mun: '42173', municipio: 'Soria', provincia: 'Soria', poblacion: 40096 },
	{ cod_mun: '44216', municipio: 'Teruel', provincia: 'Teruel', poblacion: 36267 },
	{ cod_mun: '05019', municipio: 'Ávila', provincia: 'Ávila', poblacion: 58083 }
];

export const TERRITORIOS_ESTATICOS = [
	...CCAA_BASE.map(([nombre, slug, alias = '']) => ({
		href: `/territorios/${slug}`,
		icono: '🗺️',
		nombre,
		tipo: { es: 'Comunidad autónoma', en: 'Autonomous community', ca: 'Comunitat autònoma', gl: 'Comunidade autónoma', eu: 'Autonomia-erkidegoa' },
		claves: `${nombre} ${slug.replace(/-/g, ' ')} ${alias} comunidad autonoma ccaa region territorio`
	})),
	...PROVINCIAS_BASE.map(([nombre, ccaaSlug, slug]) => ({
		href: ccaaSlug === slug ? `/territorios/${slug}` : `/territorios/${ccaaSlug}/${slug}`,
		icono: '📍',
		nombre,
		tipo: {
			es: ['ceuta', 'melilla'].includes(slug) ? 'Ciudad autónoma' : 'Provincia',
			en: ['ceuta', 'melilla'].includes(slug) ? 'Autonomous city' : 'Province',
			ca: ['ceuta', 'melilla'].includes(slug) ? 'Ciutat autònoma' : 'Província',
			gl: ['ceuta', 'melilla'].includes(slug) ? 'Cidade autónoma' : 'Provincia',
			eu: ['ceuta', 'melilla'].includes(slug) ? 'Hiri autonomoa' : 'Probintzia'
		},
		claves: `${nombre} ${slug.replace(/-/g, ' ')} ${ccaaSlug.replace(/-/g, ' ')} provincia territorio diputacion`
	}))
];

let cacheTodosMunicipios = null;
let cargandoMunicipios = null;

/**
 * Carga bajo demanda en segundo plano el índice estático con los +8.100 municipios de España
 * (~100 KB gzipped). Se descarga una sola vez y queda en memoria/caché.
 */
export async function cargarTodosMunicipios() {
	if (cacheTodosMunicipios) return cacheTodosMunicipios;
	if (cargandoMunicipios) return cargandoMunicipios;
	if (typeof window === 'undefined') return [];

	cargandoMunicipios = (async () => {
		try {
			const res = await fetch('/geo/municipios-busqueda.json');
			if (!res.ok) return [];
			const tuplas = await res.json();
			cacheTodosMunicipios = tuplas.map(([cod_mun, municipio, provincia, poblacion]) => ({
				cod_mun,
				municipio,
				provincia,
				poblacion
			}));
			return cacheTodosMunicipios;
		} catch (e) {
			console.warn('No se pudo cargar el índice de municipios:', e);
			return [];
		} finally {
			cargandoMunicipios = null;
		}
	})();

	return cargandoMunicipios;
}

export function obtenerMunicipiosCargados() {
	return cacheTodosMunicipios;
}

function puntuarTexto(tokens, principal, secundario = '') {
	const p = normalizarTexto(principal);
	const s = normalizarTexto(`${principal} ${secundario}`);
	for (const tok of tokens) {
		if (!s.includes(tok)) return 0;
	}
	const frase = tokens.join(' ');
	if (p === frase) return 100;
	if (p.startsWith(frase)) return 80;
	if (p.includes(frase)) return 60;
	return 40;
}

export function buscarGlobal(consulta, { lang = 'es', municipios = [] } = {}) {
	const q = normalizarTexto(consulta);
	if (q.length < 2) {
		return {
			vacio: true,
			analisis: ARTICULOS_ANALISIS.slice(1, 5).map((a) => ({
				categoria: 'analisis',
				href: enlace(a.href, lang),
				icono: a.icono,
				titulo: a.titulo[lang] ?? a.titulo.es,
				subtitulo: a.etiqueta[lang] ?? a.etiqueta.es
			})),
			temas: TEMAS_Y_SECCIONES.slice(0, 6).map((t) => ({
				categoria: 'temas',
				href: enlace(t.href, lang),
				icono: t.icono,
				titulo: t.titulo[lang] ?? t.titulo.es,
				subtitulo: t.desc[lang] ?? t.desc.es
			})),
			indicadores: [],
			territorios: [],
			municipios: []
		};
	}

	const tokens = q.split(/\s+/).filter(Boolean);

	const analisis = ARTICULOS_ANALISIS.map((a) => {
		const titulo = a.titulo[lang] ?? a.titulo.es;
		const subtitulo = a.desc[lang] ?? a.desc.es;
		const puntos = puntuarTexto(tokens, titulo, `${a.titulo.es} ${subtitulo} ${a.claves}`);
		return {
			categoria: 'analisis',
			href: enlace(a.href, lang),
			icono: a.icono,
			titulo,
			subtitulo: a.etiqueta[lang] ?? a.etiqueta.es,
			puntos
		};
	})
		.filter((x) => x.puntos > 0)
		.sort((a, b) => b.puntos - a.puntos)
		.slice(0, 4);

	const temas = TEMAS_Y_SECCIONES.map((t) => {
		const titulo = t.titulo[lang] ?? t.titulo.es;
		const subtitulo = t.desc[lang] ?? t.desc.es;
		const puntos = puntuarTexto(tokens, titulo, `${t.titulo.es} ${subtitulo} ${t.claves}`);
		return {
			categoria: 'temas',
			href: enlace(t.href, lang),
			icono: t.icono,
			titulo,
			subtitulo,
			puntos
		};
	})
		.filter((x) => x.puntos > 0)
		.sort((a, b) => b.puntos - a.puntos)
		.slice(0, 5);

	const indicadores = INDICADORES_CLAVE.map((ind) => {
		const titulo = ind.nombre[lang] ?? ind.nombre.es;
		const puntos = puntuarTexto(tokens, titulo, `${ind.nombre.es} ${ind.fuente} ${ind.claves}`);
		return {
			categoria: 'indicadores',
			href: enlace(ind.href, lang),
			icono: ind.icono,
			titulo,
			subtitulo: ind.fuente,
			puntos
		};
	})
		.filter((x) => x.puntos > 0)
		.sort((a, b) => b.puntos - a.puntos)
		.slice(0, 4);

	const territorios = TERRITORIOS_ESTATICOS.map((tr) => {
		const puntos = puntuarTexto(tokens, tr.nombre, tr.claves);
		return {
			categoria: 'territorios',
			href: enlace(tr.href, lang),
			icono: tr.icono,
			titulo: tr.nombre,
			subtitulo: tr.tipo[lang] ?? tr.tipo.es,
			puntos
		};
	})
		.filter((x) => x.puntos > 0)
		.sort((a, b) => b.puntos - a.puntos)
		.slice(0, 5);

	const listaMun =
		Array.from(municipios ?? []).length
			? Array.from(municipios)
			: cacheTodosMunicipios && cacheTodosMunicipios.length
			  ? cacheTodosMunicipios
			  : MUNICIPIOS_DESTACADOS;

	const resMunicipios = [];
	for (let i = 0; i < listaMun.length; i++) {
		const m = listaMun[i];
		const puntos = puntuarTexto(tokens, m.municipio, `${m.provincia} ciudad municipio ayuntamiento`);
		if (puntos > 0) {
			resMunicipios.push({
				categoria: 'municipios',
				href: `${enlace('/territorios/municipios', lang)}?m=${m.cod_mun}`,
				icono: '🏘️',
				titulo: m.municipio,
				subtitulo: m.provincia,
				poblacion: Number(m.poblacion) || 0,
				puntos
			});
		}
	}
	resMunicipios.sort((a, b) => b.puntos - a.puntos || b.poblacion - a.poblacion);
	const resMunicipiosSlice = resMunicipios.slice(0, 6);

	return {
		vacio: false,
		analisis,
		temas,
		indicadores,
		territorios,
		municipios: resMunicipiosSlice
	};
}
