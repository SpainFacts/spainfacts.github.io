// Genera static/geo/municipios-busqueda.json con los +8.100 municipios de España
// en formato compacto [cod_mun, municipio, provincia, poblacion] (~100 KB gzipped)
// para búsqueda instantánea en cliente en BuscadorGlobal y BuscadorInicio.
import { Database } from 'duckdb-async';
import { writeFileSync, statSync, existsSync } from 'node:fs';
import { resolve } from 'node:path';

const PROV = {
	'01': 'Álava', '02': 'Albacete', '03': 'Alicante', '04': 'Almería', '05': 'Ávila',
	'06': 'Badajoz', '07': 'Illes Balears', '08': 'Barcelona', '09': 'Burgos', '10': 'Cáceres',
	'11': 'Cádiz', '12': 'Castellón', '13': 'Ciudad Real', '14': 'Córdoba', '15': 'A Coruña',
	'16': 'Cuenca', '17': 'Girona', '18': 'Granada', '19': 'Guadalajara', '20': 'Gipuzkoa',
	'21': 'Huelva', '22': 'Huesca', '23': 'Jaén', '24': 'León', '25': 'Lleida',
	'26': 'La Rioja', '27': 'Lugo', '28': 'Madrid', '29': 'Málaga', '30': 'Murcia',
	'31': 'Navarra', '32': 'Ourense', '33': 'Asturias', '34': 'Palencia', '35': 'Las Palmas',
	'36': 'Pontevedra', '37': 'Salamanca', '38': 'Santa Cruz de Tenerife', '39': 'Cantabria',
	'40': 'Segovia', '41': 'Sevilla', '42': 'Soria', '43': 'Tarragona', '44': 'Teruel',
	'45': 'Toledo', '46': 'Valencia', '47': 'Valladolid', '48': 'Bizkaia', '49': 'Zamora',
	'50': 'Zaragoza', '51': 'Ceuta', '52': 'Melilla'
};

async function main() {
	const rutaParquet = resolve('data/parquets-integracion/mother/poblacion_municipios/poblacion_municipios.parquet');
	if (!existsSync(rutaParquet)) {
		console.warn('No se encontró el parquet de municipios en:', rutaParquet);
		return;
	}

	const db = await Database.create(':memory:');
	const rows = await db.all(`
		SELECT cod_mun, municipio, cod_prov, poblacion
		FROM read_parquet('${rutaParquet.replace(/\\/g, '/')}')
		WHERE anio = (SELECT max(anio) FROM read_parquet('${rutaParquet.replace(/\\/g, '/')}'))
		ORDER BY poblacion DESC
	`);

	const tuplas = rows.map((r) => [
		String(r.cod_mun).padStart(5, '0'),
		r.municipio,
		PROV[String(r.cod_prov).padStart(2, '0')] || '',
		Number(r.poblacion) || 0
	]);

	const destino = resolve('static/geo/municipios-busqueda.json');
	writeFileSync(destino, JSON.stringify(tuplas));
	const kb = (statSync(destino).size / 1024).toFixed(1);
	console.log(`Generado ${destino}: ${tuplas.length} municipios (${kb} KB)`);
}

main().catch(console.error);
