// Mientras la ficha de municipio enseña los datos prerenderizados del municipio por defecto
// y espera los del municipio de la URL, BuscadorMunicipio marca
// <html data-municipio-pendiente="<código por defecto>">. Los componentes que descargan
// ficheros por municipio (mapas) no bajan los del municipio por defecto, que nadie va a ver.
const ATRIBUTO = 'data-municipio-pendiente';

/** true si la URL es de un fichero del municipio por defecto y la página espera otro */
export function esDelMunicipioPorDefecto(url) {
    if (typeof document === 'undefined' || !url) return false;
    const defecto = document.documentElement.getAttribute(ATRIBUTO);
    return !!defecto && String(url).includes(`/${defecto}.`);
}
