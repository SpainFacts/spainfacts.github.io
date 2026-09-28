// Prueba local SIN cuenta de Cloudflare: ejecuta la lógica del Worker con Node 20+
// contra los servicios reales de REE e imprime un resumen.
//   node test/probar.mjs            → resumen
//   node test/probar.mjs --json     → JSON completo (el mismo que devuelve el Worker)
import { construirSnapshot } from '../src/index.js';

const t0 = Date.now();
const s = await construirSnapshot();
if (process.argv.includes('--json')) {
    console.log(JSON.stringify(s, null, 2));
    process.exit(0);
}
console.log(`Generado en ${Date.now() - t0} ms · actualizado ${s.actualizado} · errores: ${s.errores.length ? s.errores.join('; ') : 'ninguno'}`);
console.log('Precios:', s.precios);
for (const [nombre, d] of Object.entries(s.sistemas)) {
    if (!d) { console.log(`${nombre}: SIN DATOS`); continue; }
    const u = d.ultimo;
    console.log(`\n${nombre.toUpperCase()} · ${u.ts_local} local (${u.ts_utc}) · ${d.serie24h.length} puntos en serie24h`);
    console.log(`  demanda ${u.demanda_mw} MW · generación ${u.generacion_total_mw} MW · renovable ${u.pct_renovable} % · ${u.intensidad_gco2_kwh} gCO2/kWh · ${u.co2_t_h} tCO2/h`);
    console.log(`  intercambio neto ${u.intercambio_neto} · FR +${u.imp_francia}/-${u.exp_francia} · PT +${u.imp_portugal}/-${u.exp_portugal} · MA +${u.imp_marruecos}/-${u.exp_marruecos} · AD +${u.imp_andorra}/-${u.exp_andorra} · enlace Baleares ${u.enlace_baleares}`);
    // null (sin desglose / no aplica) cuenta como 0; el enlace resta en la península y suma en Baleares
    const enlace = nombre === 'peninsula' ? -u.enlace_baleares : nombre === 'baleares' ? u.enlace_baleares : 0;
    const cierre = u.generacion_total_mw + (u.intercambio_neto ?? 0) - (u.consumo_bombeo ?? 0) - u.baterias_carga + enlace;
    console.log(`  balance: generación + intercambio − bombeo − baterías ± enlace = ${cierre.toFixed(0)} MW vs demanda ${u.demanda_mw} MW`);
}
const tam = JSON.stringify(s).length;
console.log(`\nTamaño JSON: ${(tam / 1024).toFixed(0)} KB (sin comprimir)`);
