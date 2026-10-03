// Estadísticas de visitas con Cloudflare Web Analytics, SIN proxy delante de la web
// (el proxy dejaría la web inaccesible en España durante los partidos de fútbol por
// los bloqueos de IPs de LaLiga). No usa cookies, así que no hace falta banner.
//
// Token: panel de Cloudflare > Analytics & Logs > Web Analytics > Add a site >
// spainfacts.org > opción de pegar el fragmento JS (no la automática, que exige proxy).
// Copia el valor de "token" del fragmento y pégalo aquí. No es un secreto: va en el HTML.
//
// Si queda vacío no se carga nada.
export const CLOUDFLARE_ANALITICA_TOKEN = '825ee3098a9b41c48a3a56fbdafda268';
